from pathlib import Path
import csv,re
ROOT=Path(__file__).resolve().parents[1]

KNOWN_ADDRESSES = {
    'GameInitialise':'&3000','RuntimeGameEntry':'&0380','GameStartTitleLoop':'&0B4C','NewGame':'&0B5A','StartScreen':'&0B6A','MainGameFrame':'&0BC7',
    'TimerAndKeys':'&0C2C','PrintInlineStream':'&0D21','TickIRQ':'&0D44','SoundIRQ':'&0D69',
    'RandomUpToA':'&0DB6','ClearObjectTables':'&0DDB','TestLadderCollision':'&0E0B','TryAttachLadder':'&0E2F',
    'TestFloorCollision':'&0E5F','UpdateYoyoAttack':'&0E8F','UpdatePlayerMotion':'&0FEB','StartPlayerJump':'&10CB',
    'TestPlayerMove':'&1085','UpdateAirbornePlayer':'&10DE','UpdateClimbingPlayer':'&113B','UpdatePlayerFrame':'&11AC',
    'TypeDispatch':'&12D1','CollisionScan':'&1472','AddScoreBCD':'&15B8','HighScoreInsert':'&164D',
    'LoadLevelStream':'&17B8','ScreenComplete':'&18CC','TransitionFromRight':'&18F9','TransitionFromLeft':'&1904','RunTransitionAnimation':'&1922','TitleStartSequence':'&1977','ShowHighScores':'&1A52','PollAttractInput':'&1AD7','PrintPseudoRandomTitleChar':'&1AF9','CountObjectsOfType':'&1B7E','SpawnHazard':'&1BA2',
    'FindFreeSlot':'&1C97','DirectSpriteRenderer':'&1E36'
}

src=Path('/mnt/data/frak_port/Frak.asm').read_text(errors='replace').splitlines()
rowspec=[
('GameInitialise','runtimeGameEntry','host-replaced','startup','BBC vector/VIA/MOS installation is replaced by browser initialisation; Frak-visible title/state entry is preserved.'),
('RuntimeGameEntry','runtimeGameEntry','translated-semantic','title','Original cast/credits entry, five cast sprites and timeout into attract flow.'),
('TitleStartSequence','titleStartSequence/titleTick','translated-semantic','title','125 random sprite draws followed by the recovered left/right/final transition phases and timed attract loop.'),
('TransitionFromLeft','beginTitleTransitionLeft','translated-semantic','title','Original slot 0, X=0, DX=+1, Y=&52, sequence index 1 and 31-frame setup.'),
('TransitionFromRight','beginTitleTransitionRight','translated-semantic','title','Original slot 1, X=&50, DX=-1, Y=&52, sequence index 6 and 31-frame setup.'),
('RunTransitionAnimation','advanceTitleTransitionFrame','translated-semantic','title','Four-tick frame cadence, shared sprite-sequence delimiter logic and 31-frame movement retained.'),
('ShowHighScores','showHighScores','translated-semantic','title','Original six row positions, packed-BCD display and generated parenthesised three-character suffixes.'),
('PrintPseudoRandomTitleChar','titlePseudoRandomChars','translated','title','6502 ADC/SBC/carry reduction over duplicated score bytes and original 36-character map.'),
('PollAttractInput','startFromTitle','translated-semantic','input','SPACE/RETURN start path retained; browser keyboard replaces BBC negative-INKEY/joystick scan.'),
('GameStartTitleLoop','gameStartTitleLoop/titleTick','translated-semantic','title','Initial cast timeout then repeated attract sequences without incorrectly replaying the cast screen.'),
('NewGame','newGame','translated','game','Lives, score, base screen and transform reset preserved.'),
('StartScreen','startScreen','translated-semantic','game','A/B/C level/timer/object/hazard initialisation plus original A/B/C tune selection.'),
('MainGameFrame','parityTick','translated-semantic','game','50 Hz host runs player, hazards, death/restart, completion and game-over/high-score transitions.'),
('TimerAndKeys','parityTick/key handlers','translated-semantic','game','Countdown plus Q/S mute, freeze/continue and Escape-to-title browser equivalents; muted tunes keep advancing.'),
('ScreenComplete','beginScreenComplete/screenCompleteTick','translated-semantic','game','60-frame/four-tick Trogg transition cadence, remaining-time BCD bonus and A/B/C→transform progression; BBC text/tune/raster details omitted.'),
('ClearObjectTables','clearObjectTables','translated','objects','123 sprite slots plus 23 DX/DY slots; DY reset to original &FF.'),
('LoadLevelStream','loadLevelStream','translated','levels','Original tagged stream grammar, theme maps and fixed queue ranges.'),
('CountObjectsOfType','countObjectsOfType','translated','objects','Original fixed queue ranges.'),
('FindFreeSlot','findFreeSlot','translated','objects','Finds first &FF object slot in selected fixed queue.'),
('TypeDispatch','collectObject/updateDynamicQueue','translated-partial','objects','Collectible and dynamic-hazard behaviours are live; full table dispatch is not yet exhaustive.'),
('SpawnHazard','spawnHazard','translated-semantic','objects','Original 1-in-4 dagger / 3-in-4 balloon choice and reload structure; browser tick substitutes for VIA entropy.'),
('UpdateDynamicQueue','updateDynamicQueue','translated-semantic','objects','Balloon/dagger delay, motion and despawn lifecycle.'),
('UpdatePlayerFrame','updatePlayerFrame','translated-semantic','player','Original motion→scroll→commit→collectible/hazard order; BBC raster/erase plumbing omitted.'),
('UpdatePlayerMotion','updatePlayerMotion','translated-semantic','player','Ground walking, animation, jump-history and climb/air/yo-yo dispatch translated.'),
('UpdateAirbornePlayer','updateAirbornePlayer','translated-semantic','player','Velocity, gravity, top boundary, ladder attempt, floor landing and fatal-fall threshold.'),
('UpdateClimbingPlayer','updateClimbingPlayer','translated-semantic','player','Ladder attachment/movement/correction/floor detach represented semantically.'),
('UpdateYoyoAttack','updateYoyoAttack/continueYoyoAttack','translated-semantic','player','Original slots 1/2, head/string phases, two-X-step extension, RETURN hold window, retraction, collision and five-tick monster knockback.'),
('TryAttachLadder','tryAttachLadder','translated-semantic','player','Ladder probe and attach state represented; side-relation bit trick expressed as geometry.'),
('StartPlayerJump','startPlayerJump','translated','player','Initial DY=5, airborne flag and directional jump frame selection.'),
('ReadHorizontal','readHorizontal','host-replaced','input','Original Z/X meanings retained; arrows are optional aliases.'),
('ReadVertical','readVertical','host-replaced','input','Original */? meanings and transform-direction reversal retained; arrows are aliases.'),
('ReadYoyoControl','readYoyoControl','host-replaced','input','Original RETURN retained; Space is an optional browser alias.'),
('TestPlayerMove','testPlayerMove','translated-semantic','collision','Original proposed-X / swept vertical floor probe and fast-fall branch represented.'),
('TestFloorCollision','testFloorCollision','translated','collision','One-logical-X-wide floor probe.'),
('TestLadderCollision','testLadderCollision','translated','collision','Narrow ladder probe using documented vertical geometry.'),
('CollisionScan','collisionScan','translated-semantic','collision','Queue-mask filtering plus recursive primitive-vs-primitive bounds.'),
('ScanObjectCollisions','scanObjectCollisions','translated-semantic','collision','CollisionScan wrapper contract.'),
('ComputePrimitiveBounds','primitiveBoundsForSprite','translated','collision','Descriptor offsets/width/height become primitive bounds.'),
('ProcessSprite','spriteTraversal','translated-semantic','graphics','Draw path translated; collision modes are represented by bounds traversal rather than 6502 renderer modes.'),
('SpriteTraversal','spriteTraversal','translated','graphics','Original recursive primitive/composite descriptor traversal.'),
('DirectSpriteRenderer','directSpriteRenderer','translated','graphics','Original MODE 1 bitmap bytes, column-major rows and descriptor/transform reversal; Stage 2 fixes Stage 1 upside-down rows.'),
('SpriteRenderSetup','directSpriteRenderer','host-replaced','graphics','Self-modifying eight-JSR pixel stub replaced by direct Canvas pixel result.'),
('Mode1Address','putLogicalPixel','host-replaced','graphics','BBC circular framebuffer address calculation replaced by logical Canvas placement.'),
('DrawSpriteAt','drawSpriteAt','translated','graphics','Same sprite/X/Y contract.'),
('DrawAllObjects','drawAllObjects','translated','graphics','Original slot 122→0 order.'),
('DisplayInit','applyDisplayTransform','translated-semantic','display','Viewport/palette transform state represented; MOS/CRTC setup removed.'),
('ApplyDisplayTransform','applyDisplayTransform','translated-semantic','display','Original palette families plus vertical transform semantics.'),
('ScrollViewportLeft','updatePlayerFrame','translated-semantic','display','Logical one-column viewport offset; CRTC memory rotation is unnecessary in Canvas.'),
('ScrollViewportRight','updatePlayerFrame','translated-semantic','display','Logical one-column viewport offset; CRTC memory rotation is unnecessary in Canvas.'),
('AddScoreBCD','addScoreBCD','translated','score','Three packed-BCD bytes and original bit-5 extra-life boundary test.'),
('DrawStatus','updateInfo','host-replaced','score','Browser diagnostics currently expose score/lives/time instead of BBC status-line VDU output.'),
('HighScoreInsert','highScoreInsert','translated-semantic','score','Six-record packed-BCD ranking, table shift and three-character initials entry.'),
('PrintInlineStream','drawTitleText/title renderers','host-replaced','display','BBC VDU byte streams are rendered as equivalent browser text/graphics rather than MOS VDU control bytes.'),
('RandomUpToA','randomUpToA','translated-semantic','prng','Original mask/rejection 0..A-inclusive shape; tick counter substitutes for VIA timer entropy.'),
('TickIRQ','parityTick','translated-semantic','timing','50 Hz browser tick preserves player divisor/countdown cadence; MOS event-vector mechanics omitted.'),
('SoundIRQ','soundIRQ','translated-semantic','sound','Original 40 Hz Timer-1 music cadence retained alongside the 100 Hz MOS envelope service; browser scheduler replaces VIA IRQ.'),
('MusicStep','musicStep','translated','sound','Original bit7 terminator, bits2..6 pitch and bits0..1 duration decoder over retained stream bytes.'),
('SelectTune','selectTune','translated','sound','Original five stream selections and reset/inhibit state represented directly.'),
('OSBYTEWrapper','browserHost','host-replaced','mos','Only Frak-observable host effects will be represented.'),
('OSWORDWrapper','playSoundBlock/mosEnvelopeTick','host-replaced','mos','Browser host now reproduces the Frak-used MOS SOUND subset: flush channels, 100 Hz ENVELOPE state, MOS pitch lookup and SN76489 attenuation; Web Audio remains the physical output layer.'),
]

def find_label(name):
    pat=re.compile(r'^'+re.escape(name)+r':\s*$')
    for i,line in enumerate(src):
        if pat.match(line.strip()):
            addr=''
            for ln in src[i:i+30]:
                m=re.search(r';\s*&([0-9A-Fa-f]{4}):',ln)
                if m: addr='&'+m.group(1).upper(); break
            return i+1,addr
    return '', ''
rows=[]
for sym,js,status,subsystem,note in rowspec:
    line,addr=find_label(sym)
    addr = KNOWN_ADDRESSES.get(sym, addr)
    rows.append(dict(symbol_6502=sym,address=addr,source_line=line,js_symbol=js,status=status,subsystem=subsystem,notes=note))
with (ROOT/'MAPPING.csv').open('w',newline='',encoding='utf8') as f:
    w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
counts={}
for r in rows:counts[r['status']]=counts.get(r['status'],0)+1
md=['# Frak! 6502 → JavaScript mapping','',
'Stage 4 keeps this mapping as part of the implementation contract. A routine is not promoted merely because the browser looks similar; the documented Stage 10 state/data semantics must be represented.', '',
'Current status counts: '+', '.join(f'**{v} {k}**' for k,v in sorted(counts.items()))+'.','',
'| 6502 symbol | Runtime | JavaScript | Status | Subsystem | Notes |','|---|---:|---|---|---|---|']
for r in rows: md.append(f"| `{r['symbol_6502']}` | `{r['address'] or '—'}` | `{r['js_symbol']}` | **{r['status']}** | {r['subsystem']} | {r['notes']} |")
md += ['', '## Data mapping','', '| Original data | Browser representation | Fidelity rule |','|---|---|---|',
'| `LevelA`, `LevelB`, `LevelC` | `FRAK_DATA.levels` | Original encoded bytes; decoded at runtime. |',
'| Six 92-entry descriptor arrays | `FRAK_DATA.spriteTables` | Retained byte-for-byte. |',
'| Sprite/composite/bitmap region | `FRAK_DATA.spriteRegion` | Original bytes; no PNG sprite conversion. |',
'| Theme C/J/G maps | `FRAK_DATA.themeMaps` | Same theme-local variant→descriptor mapping. |',
'| Object arrays (123 slots; DX/DY 23) | typed arrays in `state` | Same queue boundaries and `&FF` empty marker; Stage 4 preserves initial DY=`&FF`. |',
'| Five encoded tune/effect streams | `FRAK_DATA.soundStreams` | Original bytes and bit-field decoder retained. |',
'| Four BBC SOUND blocks | `FRAK_DATA.soundBlocks` | Original channel/envelope/pitch/duration values; all four retain duration `&00FF`. |',
'| Four BBC ENVELOPE definitions | `FRAK_DATA.envelopes` | Original 14-byte records drive the Stage 4 100 Hz MOS envelope state. |',
'| Title transition stream/timing | `FRAK_DATA.title.transition*` | Original delimiter stream, 31-frame count, 4-tick cadence, clipping window and hold times. |',
'| Title character map / row table | `FRAK_DATA.title.characterMap/highScoreRows` | Original pseudo-random suffix map and six row positions. |',
'| Six high-score records | `state.highScores` | Original 36-byte table copied into writable browser state. |',
'', '## Renderer correction retained from Stage 2.1','',
'Stage 1 had the logical objects in the right world coordinates but fetched each primitive bitmap column from the wrong end. The original forward pixel operator begins at `definition + height - 1` and decrements through the column. Stage 4 retains the corrected `height - 1 - row` normal source traversal, with descriptor reverse and display vertical-flip combined exactly as opposing reversal flags.',
'', '## Rule for future work','',
'Prefer an explicit `pending`/`translated-partial` status over invented browser-game behaviour. Where BBC hardware mechanisms have no useful browser analogue, preserve the Frak-facing contract and mark them `host-replaced` or `translated-semantic`.']
(ROOT/'MAPPING.md').write_text('\n'.join(md)+'\n',encoding='utf8')
print('wrote',len(rows),'rows',counts)
