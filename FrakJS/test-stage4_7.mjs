import './frak-data.js';
const listeners={}; const nodes=new Map();
function node(id){if(!nodes.has(id))nodes.set(id,{textContent:'',dataset:{},addEventListener(){}});return nodes.get(id);}
const ctx={imageSmoothingEnabled:false,createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},putImageData(){}};
globalThis.document={getElementById(id){if(id==='screen')return{getContext(){return ctx;}};return node(id);},querySelectorAll(){return[];}};
globalThis.window={addEventListener(type,cb){listeners[type]=cb;}};
globalThis.performance={now(){return 0;}}; globalThis.requestAnimationFrame=()=>0;
await import('./frak.js');
const f=window.FRAK,s=f.state;
function assert(c,m){if(!c)throw new Error(m);}
function ev(key){return {key,preventDefault(){}};}

// Force a qualifying score and enter initials.
f.startScreen('A');
s.scoreHi=0x01; s.scoreMid=0x42; s.scoreLo=0x50;
assert(f.highScoreInsert()===true,'high-score insertion did not qualify');
assert(s.mode==='highScoreEntry','did not enter high-score mode');
assert(s.highScoreEntryChar===0x41,'entry did not begin at A');

// Z/X selection and apostrophe commit; selected character must carry forward.
listeners.keydown(ev('x'));
assert(s.highScoreEntryChar===0x42,'X did not select B');
listeners.keydown(ev("'"));
assert(s.highScores[s.highScoreRank*6]===0x42,'first initial not committed');
assert(s.highScoreEntryChar===0x42,'original carries selected character to next initial');
listeners.keydown(ev("'"));
listeners.keydown(ev("'"));
assert(s.mode==='titleScores','third initial should enter final &50-tick hold');
assert(s.highScores[s.highScoreRank*6+1]===0x42 && s.highScores[s.highScoreRank*6+2]===0x42,'remaining initials not committed');
assert(s.titleTicksRemaining===0x50,'final high-score hold must be &50 ticks');

console.log('PASS: Stage 4.7 original-style high-score initials flow, carry-forward character and final &50-tick hold.');
