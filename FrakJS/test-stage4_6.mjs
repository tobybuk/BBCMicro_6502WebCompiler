import './frak-data.js';
const listeners={};
const nodes=new Map();
function node(id){if(!nodes.has(id))nodes.set(id,{textContent:'',dataset:{},addEventListener(){}});return nodes.get(id);}
const ctx={
  imageSmoothingEnabled:false,
  createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},
  putImageData(){}
};
globalThis.document={getElementById(id){if(id==='screen')return{getContext(){return ctx;}};return node(id);},querySelectorAll(){return[];}};
globalThis.window={addEventListener(type,cb){listeners[type]=cb;}};
globalThis.performance={now(){return 0;}};
globalThis.requestAnimationFrame=()=>0;
await import('./frak.js');
const f=window.FRAK, s=f.state;
function assert(c,m){if(!c)throw new Error(m);}
function ev(key){return {key,preventDefault(){}};}

// Quick-tap UP between player samples must survive until the next 4-tick update.
f.startScreen('A');
s.objectX[0]=8; s.objectY[0]=48; s.objectSprite[0]=0x34;
s.playerAirborne=false; s.playerClimbing=false; s.objectDY[0]=0xff; s.jumpInputHistory=0;
// Prime the original jump-history edge logic with one neutral player update.
for(let i=0;i<4;i++) f.parityTick();
listeners.keydown(ev("'"));
listeners.keyup(ev("'"));
for(let i=0;i<4;i++) f.parityTick();
assert(s.playerAirborne===true,'quick UP tap was lost before jump sample');
assert(s.objectY[0]>48,`quick UP tap did not start jump; y=${s.objectY[0]}`);
assert(s.inputLatchUp===false,'UP latch was not consumed after player update');

// Quick-tap DOWN on an established ladder must advance exactly one climb step.
f.startScreen('A');
s.objectX[0]=10; s.objectY[0]=90; s.objectSprite[0]=0x13;
s.playerClimbing=true; s.playerAirborne=false; s.playerFrameSprite=0x34;
listeners.keydown(ev('/'));
listeners.keyup(ev('/'));
for(let i=0;i<4;i++) f.parityTick();
assert(s.playerClimbing===true,'quick DOWN tap detached from ladder');
assert(s.objectY[0]===87,`quick DOWN tap should descend one 3-unit step; got y=${s.objectY[0]}`);
assert(s.inputLatchDown===false,'DOWN latch was not consumed after player update');

// Held-key path still works and does not depend on latching.
listeners.keydown(ev("'"));
for(let i=0;i<4;i++) f.parityTick();
listeners.keyup(ev("'"));
assert(s.objectY[0]===90,`held UP should climb back one step; got y=${s.objectY[0]}`);

console.log("PASS: Stage 4.6 apostrophe-up and slash-down controls are buffered to the next Frak player update; held controls unchanged.");
