#!/usr/bin/env python3
"""Extract immutable Frak data tables from the documented 6502 source.

This deliberately extracts data, not renderer/gameplay code.  The browser port
keeps the original symbolic names and translates algorithms separately.
"""
from pathlib import Path
import ast, json, re, sys

SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('Frak_STAGE10.asm')
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('frak-data.js')
text = SRC.read_text(encoding='utf-8', errors='replace')
lines = text.splitlines()

# A small expression evaluator for the assembler syntax used in constants/EQUB.
const = {}

def asm_to_py(s):
    s = s.strip()
    s = re.sub(r'&([0-9A-Fa-f]+)', r'0x\1', s)
    return s

def safe_eval(expr):
    expr = asm_to_py(expr)
    node = ast.parse(expr, mode='eval')
    allowed = (ast.Expression, ast.Constant, ast.Name, ast.BinOp, ast.UnaryOp,
               ast.Add, ast.Sub, ast.Mult, ast.FloorDiv, ast.Mod, ast.LShift,
               ast.RShift, ast.BitOr, ast.BitAnd, ast.BitXor, ast.Invert,
               ast.USub, ast.UAdd, ast.Load)
    for n in ast.walk(node):
        if not isinstance(n, allowed):
            raise ValueError(f'unsupported expression node {type(n).__name__}: {expr}')
        if isinstance(n, ast.Name) and n.id not in const:
            raise KeyError(n.id)
    return int(eval(compile(node, '<asm>', 'eval'), {'__builtins__': {}}, const))

# Resolve simple constants iteratively.
pending = []
for ln in lines:
    code = ln.split(';',1)[0].strip()
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$', code)
    if m:
        pending.append((m.group(1), m.group(2).strip()))
for _ in range(30):
    next_pending=[]; progress=False
    for name, expr in pending:
        try:
            const[name]=safe_eval(expr) & 0xFFFFFFFF
            progress=True
        except Exception:
            next_pending.append((name,expr))
    pending=next_pending
    if not progress: break

def split_args(s):
    out=[]; cur=''; depth=0; quote=None
    for ch in s:
        if quote:
            cur += ch
            if ch == quote: quote=None
        elif ch in ('"', "'"):
            quote=ch; cur += ch
        elif ch=='(':
            depth+=1; cur+=ch
        elif ch==')':
            depth-=1; cur+=ch
        elif ch==',' and depth==0:
            out.append(cur.strip()); cur=''
        else: cur+=ch
    if cur.strip(): out.append(cur.strip())
    return out

def eval_bytes(tok):
    tok=tok.strip()
    if len(tok)>=2 and tok[0]=='"' and tok[-1]=='"':
        s=ast.literal_eval(tok)
        return [ord(ch)&0xFF for ch in s]
    if tok.startswith('<') or tok.startswith('>'):
        raise ValueError('address low/high not supported in immutable data extraction')
    return [safe_eval(tok)&0xFF]

def section_bytes(label, end_labels=(), stop_on_org=False):
    start=None
    for i,ln in enumerate(lines):
        if re.match(rf'^{re.escape(label)}:\s*', ln.strip()): start=i+1; break
    if start is None: raise KeyError(label)
    data=[]
    for ln in lines[start:]:
        st=ln.strip()
        if any(re.match(rf'^{re.escape(e)}:\s*', st) for e in end_labels): break
        if stop_on_org and st.startswith('ORG '): break
        code=ln.split(';',1)[0].strip()
        if not code: continue
        m=re.match(r'^EQUB\s+(.+)$', code, re.I)
        if m:
            for t in split_args(m.group(1)):
                data.extend(eval_bytes(t))
    return data

# Individual immutable tables.
sprite_names=['SpriteXOffsets','SpriteYOffsets','SpriteDefLo','SpriteDefHi','SpriteWidthFlags','SpriteHeightCount']
sprite_tables={}
for i,n in enumerate(sprite_names):
    nxt=sprite_names[i+1] if i+1<len(sprite_names) else 'SpriteDefinitionData'
    sprite_tables[n]=section_bytes(n,[nxt])
    if len(sprite_tables[n]) != 92:
        raise RuntimeError(f'{n}: expected 92 entries, got {len(sprite_tables[n])}')
sprite_def=section_bytes('SpriteDefinitionData', stop_on_org=True)
sprite_region=[]
for n in sprite_names: sprite_region += sprite_tables[n]
sprite_region += sprite_def

levels={
 'A': section_bytes('LevelA',['LevelB']),
 'B': section_bytes('LevelB',['LevelC']),
 'C': section_bytes('LevelC', stop_on_org=True),
}
# Level C extractor stops at next ORG; source has no ORG immediately, so trim after LEVEL_END.
# Decode first complete stream using grammar so any later EQUB data is excluded.
def trim_level(data):
    i=1
    while i < len(data):
        tag=data[i]; i+=1
        if tag==0xFF: return data[:i]
        while i < len(data):
            rec=data[i]; i+=1
            if rec==0: break
            cnt=rec>>3; i += cnt*2
    raise RuntimeError('unterminated level')
levels={k:trim_level(v) for k,v in levels.items()}

# Theme maps are represented semantically using the same sprite constants.
C=const
maps={
 'C': {'T':[C['SPRITE_TROGG_FRAME0']], 'M':[C['SPRITE_SCRUBBLY']],
       'K':[C['SPRITE_KEY'],C['SPRITE_BULB'],C['SPRITE_GEM']],
       'L':[C[f'SPRITE_THEME_C_LADDER{i}'] for i in range(5)],
       'F':[C[f'SPRITE_THEME_C_FLOOR{i}'] for i in range(7)]},
 'J': {'T':[C['SPRITE_TROGG_FRAME0']], 'M':[0,C['SPRITE_POGLET']],
       'K':[C['SPRITE_KEY'],C['SPRITE_BULB'],C['SPRITE_GEM']],
       'L':[C[f'SPRITE_THEME_J_LADDER{i}'] for i in range(4)],
       'F':[C[f'SPRITE_THEME_J_FLOOR{i}'] for i in range(6)]},
 'G': {'T':[C['SPRITE_TROGG_FRAME0']], 'M':[C['SPRITE_HOOTER']],
       'K':[C['SPRITE_KEY'],C['SPRITE_BULB'],C['SPRITE_GEM']],
       'L':[C[f'SPRITE_THEME_G_LADDER{i}'] for i in range(4)],
       'F':[C[f'SPRITE_THEME_G_FLOOR{i}'] for i in range(7)]},
}

# Selected constants that are part of the browser-side semantic contract.
want_consts = [
 'SPRITE_HIDDEN','SPRITE_DESCRIPTOR_COUNT','SPRITE_FRAK_LOGO','SPRITE_TROGG_DEATH','SPRITE_TROGG_FRAME0','SPRITE_TROGG_FRAME1',
 'SPRITE_TROGG_FRAME2','SPRITE_TROGG_FRAME3','SPRITE_TROGG_FRAME4','SPRITE_TROGG_FRAME5',
 'SPRITE_TROGG_FRAME6','SPRITE_TROGG_FRAME7','SPRITE_KEY','SPRITE_BULB','SPRITE_GEM',
 'SPRITE_SCRUBBLY','SPRITE_POGLET','SPRITE_HOOTER','SPRITE_DAGGER','SPRITE_DAGGER_FLIPPED',
 'SPRITE_BALLOON','INITIAL_LIVES','BASE_SCREEN_COUNT','TRANSFORM_MASK','HAZARD_BASE_RELOAD',
 'PLAYER_UPDATE_DIVISOR','COUNTDOWN_TICKS_PER_SEC','PRNG_INCREMENT','PRNG_TOP_BIT',
 'MODE1_VIEWPORT_COLUMNS','MODE1_SCANLINES_PER_CHAR'
]
selected={k:C[k] for k in want_consts if k in C}

# Persistent sound/high-score/title data used by Stage 3.
sound_streams={
 'screenA': section_bytes('TuneScreenA',['TuneScreenB']),
 'screenB': section_bytes('TuneScreenB',['TuneScreenC']),
 'screenC': section_bytes('TuneScreenC',['TuneDeath']),
 'death': section_bytes('TuneDeath',['TuneScreenComplete']),
 'complete': section_bytes('TuneScreenComplete',['LevelA']),
}
high_scores=section_bytes('HighScores',['Mode1Masks'])[:36]
if len(high_scores)!=36:
    raise RuntimeError(f'HighScores: expected 36 bytes, got {len(high_scores)}')
envelopes={
 'music': section_bytes('EnvelopeMusicDefinition',['EnvelopeMoveDefinition'])[:14],
 'move': section_bytes('EnvelopeMoveDefinition',['EnvelopeYoyoHitDefinition'])[:14],
 'yoyoHit': section_bytes('EnvelopeYoyoHitDefinition',['EnvelopeCollectDefinition'])[:14],
 'collect': section_bytes('EnvelopeCollectDefinition',['EndOfImage'])[:14],
}
title={
 'logoX': C.get('TITLE_LOGO_X',0x22), 'logoY': C.get('TITLE_LOGO_Y',0xEA),
 'troggX': C.get('TITLE_TROGG_X',0x16), 'troggY': C.get('TITLE_TROGG_Y',0xB7),
 'scrubblyX': C.get('TITLE_SCRUBBLY_X',0x15), 'scrubblyY': C.get('TITLE_SCRUBBLY_Y',0x85),
 'hooterX': C.get('TITLE_HOOTER_X',0x15), 'hooterY': C.get('TITLE_HOOTER_Y',0x6B),
 'pogletX': C.get('TITLE_POGLET_X',0x16), 'pogletY': C.get('TITLE_POGLET_Y',0x58),
 'timeoutTicks': C.get('TITLE_TIMEOUT_CHUNKS',7)*256,
 'randomDrawCount': C.get('TITLE_RANDOM_DRAW_COUNT',0x7D),
 'randomSprites': [C.get('SPRITE_FRAK_LOGO',0x22),C.get('SPRITE_TROGG_FRAME0',0x34),C.get('SPRITE_SCRUBBLY',0x12),C.get('SPRITE_HOOTER',0x1D)],
 'transitionSequence': section_bytes('TransitionSpriteSequence',['ScreenColourTable'])[:8],
 'transitionFrameDelay': C.get('TRANSITION_FRAME_DELAY',4),
 'transitionFrames': C.get('TRANSITION_TITLE_FRAMES',0x1F),
 'transitionY': C.get('TRANSITION_Y',0x52),
 'transitionDelay': C.get('TITLE_TRANSITION_DELAY',0x4B),
 'finalY': C.get('TITLE_FINAL_Y',0x52),
 'finalWait': C.get('TITLE_FINAL_WAIT',0xFA),
 'clipLeft': C.get('TITLE_CLIP_LEFT',0x0C),
 'clipRight': C.get('TITLE_CLIP_RIGHT',0x44),
 'highScoreRows': section_bytes('HighScorePositionRowTable',['WaitFramesOrInput'])[:6],
 'characterMap': section_bytes('TitleCharacterMap',['TitleCharacterMapEnd'])[:36],
 'randomCharSeeds': [C.get('TITLE_RANDOM_CHAR_SEED_1',0x63), C.get('TITLE_RANDOM_CHAR_SEED_2',0x2A), C.get('TITLE_RANDOM_CHAR_SEED_3',0xF7)],
}
sound_blocks={
 'music': {'channel': C.get('SOUND_CHANNEL_MUSIC',0x13), 'envelope': C.get('SOUND_ENVELOPE_MUSIC',1), 'pitch':0, 'duration':C.get('SOUND_DURATION_DEFAULT',0xFF)},
 'move': {'channel': C.get('SOUND_CHANNEL_MOVE',0x12), 'envelope': C.get('SOUND_ENVELOPE_MOVE',2), 'pitch':0, 'duration':C.get('SOUND_DURATION_DEFAULT',0xFF)},
 'yoyoHit': {'channel': C.get('SOUND_CHANNEL_YOYO',0x11), 'envelope': C.get('SOUND_ENVELOPE_YOYO_HIT',3), 'pitch':0x78, 'duration':C.get('SOUND_DURATION_DEFAULT',0xFF)},
 'collect': {'channel': C.get('SOUND_CHANNEL_YOYO',0x11), 'envelope': C.get('SOUND_ENVELOPE_COLLECT',4), 'pitch':0x5A, 'duration':C.get('SOUND_DURATION_DEFAULT',0xFF)},
}

payload={
 'constants': selected,
 'spriteTables': sprite_tables,
 'spriteRegion': sprite_region,
 'levels': levels,
 'themeMaps': maps,
 'screenColours': [6,2,1], # cyan, green, red from ScreenColourTable
 'initialMinutesBCD': [0x02,0x03,0x04],
 'soundStreams': sound_streams,
 'soundBlocks': sound_blocks,
 'envelopes': envelopes,
 'highScores': high_scores,
 'title': title,
}
js='// Generated from the documented Frak 6502 source. Do not hand edit.\n' \
   + 'globalThis.FRAK_DATA = ' + json.dumps(payload, separators=(',',':')) + ';\n'
OUT.write_text(js, encoding='utf-8')
print(f'wrote {OUT}: spriteRegion={len(sprite_region)} bytes, levels=' + ', '.join(f'{k}:{len(v)}' for k,v in levels.items()))
