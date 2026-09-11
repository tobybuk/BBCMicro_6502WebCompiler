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

// Original immutable Stage 3 data surfaced by the extractor.
assert(d.soundStreams.screenA.length===70,'screen A tune length');
assert(d.soundStreams.screenB.length===56,'screen B tune length');
assert(d.soundStreams.screenC.length===56,'screen C tune length');
assert(d.soundStreams.death.length===6 && d.soundStreams.complete.length===17,'one-shot tune lengths');
assert(d.highScores.length===36,'high-score table length');
assert(Object.values(d.envelopes).every(e=>e.length===14),'envelope length');

// Runtime entry -> cast timeout -> random attract -> score/banner phase.
f.runtimeGameEntry();
assert(s.mode==='titleCast','runtime entry should show cast');
for(let i=0;i<d.title.timeoutTicks;i++)f.parityTick();
assert(s.mode==='titleScatter','cast timeout should enter scatter attract');
for(let i=0;i<d.title.randomDrawCount;i++)f.parityTick();
assert(s.mode==='titleTransitionLeft','scatter should enter the original left-hand title transition');

// MusicStep timing: first 0x21 note => duration code 1 => 8 Timer-1 ticks.
f.newGame();
f.selectTune('screenA');
f.soundIRQ();
assert(s.tunePosition===1,'first music IRQ did not consume a stream byte');
assert(s.musicDurationCounter===7,'0x21 should reload duration counter to 7 after entry at -1');
for(let i=0;i<7;i++)f.soundIRQ();
assert(s.tunePosition===1,'music advanced before eight 40Hz units');
f.soundIRQ();
assert(s.tunePosition===2,'music did not advance on eighth 40Hz unit');

// Looping tunes wrap without inhibiting; death/complete terminate and inhibit.
f.selectTune('screenA'); s.tunePosition=d.soundStreams.screenA.length-1; f.musicStep();
assert(s.tunePosition===0 && !s.musicInhibit,'screen tune should loop at bit-7 terminator');
f.selectTune('death'); s.tunePosition=d.soundStreams.death.length-1; f.musicStep();
assert(s.tunePosition===0 && s.musicInhibit,'death tune should inhibit after final encoded item');

// High-score insertion and original three-character entry model.
f.newGame(); s.scoreHi=0; s.scoreMid=0x02; s.scoreLo=0; // above released 000100 entries
assert(f.highScoreInsert()===true && s.mode==='highScoreEntry' && s.highScoreRank===0,'high score did not rank at top');
f.cycleHighScoreChar(1); // B
f.commitHighScoreChar();
f.cycleHighScoreChar(2); // B -> D: original carries the selected char forward
f.commitHighScoreChar();
f.cycleHighScoreChar(3); // D -> G
f.commitHighScoreChar();
assert(String.fromCharCode(...s.highScores.slice(0,3))==='BDG','initials entry carry-forward mismatch');
assert(s.mode==='titleScores','completed initials should return to title scores');

f.setSoundMuted(true); assert(s.soundMuted,'Q/sound mute state failed');
// BBC sound-off suppresses OSWORD output but does not freeze the tune stream.
f.selectTune('screenA'); s.musicDurationCounter=0; const mutedPos=s.tunePosition; f.soundIRQ();
assert(s.tunePosition===mutedPos+1,'muting must not freeze music stream progression');
f.setSoundMuted(false); assert(!s.soundMuted,'S/sound enable state failed');
console.log('PASS: Stage 3 subsystems retained under Stage 4 title/audio fidelity changes.');
