import './frak-data.js';
const nodes=new Map();
function node(id){if(!nodes.has(id))nodes.set(id,{textContent:'',dataset:{},addEventListener(){}});return nodes.get(id);}
const ctx={imageSmoothingEnabled:false,createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},putImageData(){}};
globalThis.document={getElementById(id){if(id==='screen')return{getContext(){return ctx;}};return node(id);},querySelectorAll(){return[];}};
globalThis.window={addEventListener(){}};
globalThis.performance={now(){return 0;}};
globalThis.requestAnimationFrame=()=>0;
await import('./frak.js');
const f=window.FRAK, s=f.state, d=globalThis.FRAK_DATA;
function assert(c,m){if(!c)throw new Error(m);}

// Source data added for the Stage 4 fidelity paths.
assert(d.soundBlocks.music.duration===0xff && d.soundBlocks.collect.duration===0xff,'OSWORD7 duration fields');
assert(d.title.transitionSequence.join(',')==='255,52,53,54,55,255,18,255','transition sprite stream');
assert(d.title.highScoreRows.join(',')==='9,11,12,13,14,15','high-score row table');
assert(d.title.characterMap.length===36,'title random character map');

// MOS 1.20 pitch conversion / SN76489 periods. These known values exercise
// semitone, octave and channel-offset paths rather than the old exponential approximation.
assert(f.bbcPitchPeriod(52,3)===477,'pitch 52/channel3 period');
assert(f.bbcPitchPeriod(89,3)===280,'pitch 89/channel3 period');
assert(Math.abs(f.bbcPitchHz(89,3)-(125000/280))<1e-9,'pitch period->Hz conversion');

// Frak's SOUND calls are flush-channel calls. A voice should exist and its
// genuine envelope state must evolve at 100 Hz even when WebAudio is absent.
f.playSoundBlock('yoyoHit');
let voices=f.audioDebugState();
assert(voices.length===1 && voices[0].basePitch===120,'yoyo voice did not initialise');
const initialVol=voices[0].volume;
for(let i=0;i<8;i++)f.mosEnvelopeTick();
voices=f.audioDebugState();
assert(voices[0].volume!==initialVol,'MOS amplitude envelope did not advance');
assert(voices[0].actualPitch!==120,'MOS pitch envelope did not advance');

// Mute is output gating, not state destruction.
f.setSoundMuted(true);
const mutedVoiceCount=f.audioDebugState().length;
for(let i=0;i<4;i++)f.mosEnvelopeTick();
assert(f.audioDebugState().length===mutedVoiceCount,'mute destroyed MOS voice state');
f.setSoundMuted(false);

// Original title choreography: 125 random draws -> left transition, 31 frames
// spaced four game ticks apart -> right transition -> 75 tick hold -> final
// Trogg death frame for 250 ticks -> another attract sequence (not cast screen).
f.runtimeGameEntry();
for(let i=0;i<d.title.timeoutTicks;i++)f.parityTick();
assert(s.mode==='titleScatter','cast timeout -> scatter');
for(let i=0;i<d.title.randomDrawCount;i++)f.parityTick();
assert(s.mode==='titleTransitionLeft','scatter -> left transition');
const leftStart=s.objectX[0];
for(let i=0;i<d.title.transitionFrames*d.title.transitionFrameDelay;i++)f.parityTick();
assert(s.mode==='titleTransitionRight','left -> right transition');
assert(s.objectX[0]===leftStart+d.title.transitionFrames,'left transition distance');
for(let i=0;i<d.title.transitionFrames*d.title.transitionFrameDelay;i++)f.parityTick();
assert(s.mode==='titleTransitionDelay','right -> transition delay');
assert(s.objectX[1]===0x50-d.title.transitionFrames,'right transition distance');
for(let i=0;i<d.title.transitionDelay;i++)f.parityTick();
assert(s.mode==='titleFinalWait','delay -> final Trogg frame');
for(let i=0;i<d.title.finalWait;i++)f.parityTick();
assert(s.mode==='titleScatter','final wait should loop the attract sequence, not replay cast');

console.log('PASS: Stage 4 MOS/SN pitch-envelope fidelity and original title transition choreography.');
