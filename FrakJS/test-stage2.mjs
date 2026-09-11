import './frak-data.js';
const nodes=new Map();
function node(id){if(!nodes.has(id))nodes.set(id,{textContent:'',dataset:{},addEventListener(){}});return nodes.get(id);}
let lastImage=null;
const ctx={
  imageSmoothingEnabled:false,
  createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},
  putImageData(image){lastImage=image;}
};
globalThis.document={getElementById(id){if(id==='screen')return{getContext(){return ctx;}};return node(id);},querySelectorAll(){return[];}};
globalThis.window={addEventListener(){}};
globalThis.performance={now(){return 0;}};
globalThis.requestAnimationFrame=()=>0;
await import('./frak.js');
const f=window.FRAK, s=f.state, d=globalThis.FRAK_DATA;
const signed=v=>(v&0x80)?v-256:v;
const mode1=byte=>[0,1,2,3].map(i=>((((byte>>(7-i))&1)<<1)|((byte>>(3-i))&1)));
const rgb=['#000000','#ff0000','#00ff00','#ffff00','#0000ff','#ff00ff','#00ffff','#ffffff'].map(h=>[parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)]);
function px(x,y){let o=(y*320+x)*4;return Array.from(lastImage.data.slice(o,o+3));}
function assert(c,m){if(!c)throw new Error(m);}

// Renderer regression: normal primitive traversal starts at definition+height-1.
f.startScreen('A');
s.objectSprite.fill(0xff); s.objectX.fill(0); s.objectY.fill(0);
s.objectSprite[0]=1; s.objectX[0]=10; s.objectY[0]=100;
f.renderFrame();
const tab=d.spriteTables, h=tab.SpriteHeightCount[1], off=tab.SpriteDefLo[1]|(tab.SpriteDefHi[1]<<8);
const bx=(10+signed(tab.SpriteXOffsets[1]))*4;
const logicalBottom=mode1(d.spriteRegion[off+h-1]);
const palette=[6,5,3,0];
for(let i=0;i<4;i++)assert(px(bx+i,155).join(',')===rgb[palette[logicalBottom[i]]].join(','),`normal renderer row order mismatch at pixel ${i}`);

// Transform bit 0 mirrors both placement AND bitmap orientation.  Stage 2 moved
// primitives to the right mirrored Y position but also reversed their source rows,
// cancelling the visual inversion and leaving the sprite upright.
s.transformCycle=1;
f.renderFrame();
const transformedTop=mode1(d.spriteRegion[off+h-1]);
const transformedBottom=mode1(d.spriteRegion[off]);
for(let i=0;i<4;i++){
  assert(px(bx+i,100).join(',')===rgb[palette[transformedTop[i]]].join(','),`upside-down transform top row mismatch at pixel ${i}`);
  assert(px(bx+i,100+h-1).join(',')===rgb[palette[transformedBottom[i]]].join(','),`upside-down transform bottom row mismatch at pixel ${i}`);
}

// Level/player geometry regression: initial Trogg is supported by the real floor sprite.
f.startScreen('A');
assert(f.testPlayerMove(0)===true,'initial Trogg should be supported by floor geometry');
assert(s.collidedQueueTag==='F','initial support should be from floor queue');
const x0=s.objectX[0];
f.pressed.add('x'); f.updatePlayerFrame(); f.pressed.delete('x');
assert(s.objectX[0]===x0+1,'X should advance Trogg by one logical column');
assert(!s.playerDead,'one walking step should not kill Trogg');

// 50 Hz host / 4-tick player divider regression.
f.startScreen('A'); const before=s.objectX[0]; f.pressed.add('x');
for(let i=0;i<3;i++)f.parityTick();
assert(s.objectX[0]===before,'player moved before 4-tick divisor');
f.parityTick(); f.pressed.delete('x');
assert(s.objectX[0]===before+1,'player did not move on 4th tick');

// Ladder descent regression.  Put Trogg on the long real level-A ladder at X=10,
// well away from its end, and verify DOWN advances by -3 without detaching/snapping
// back to a floor.  This exercises the original ladder-origin branch structure.
s.transformCycle=0; f.startScreen('A');
s.objectX[0]=10; s.objectY[0]=90; s.objectSprite[0]=0x13;
s.playerClimbing=true; s.playerAirborne=false; s.playerFrameSprite=0x34;
f.pressed.add('/');
const climbDown=f.updateClimbingPlayer(s.objectSprite[0]);
f.pressed.delete('/');
assert(s.playerClimbing===true,'DOWN incorrectly detached Trogg from ladder');
assert(climbDown.y===87,`DOWN should descend from Y=90 to 87, got ${climbDown.y}`);

// PRNG contract is inclusive and bounded.
for(const limit of [0,1,2,3,7,15,80,255]) for(let i=0;i<100;i++){const v=f.randomUpToA(limit);assert(v>=0&&v<=limit,`RandomUpToA(${limit}) => ${v}`);}
// Yo-yo regression: RETURN deploys slots 1/2, extends, retracts and restores Trogg.
f.startScreen('A');
const normalSprite=s.objectSprite[0];
f.pressed.add('enter'); f.updatePlayerFrame();
assert(s.yoyoActive && s.objectSprite[2]!==0xff,'RETURN did not deploy yo-yo head');
for(let i=0;i<5;i++) f.updatePlayerFrame();
f.pressed.delete('enter');
for(let i=0;i<20 && s.yoyoActive;i++) f.updatePlayerFrame();
assert(!s.yoyoActive && s.objectSprite[1]===0xff && s.objectSprite[2]===0xff,'yo-yo did not retract/clear component slots');
assert(s.objectSprite[0]===normalSprite,'Trogg sprite was not restored after yo-yo');

// Non-monster yo-yo hit: remove the object and award packed BCD &25.
f.startScreen('A'); s.scoreLo=0; s.scoreMid=0; s.scoreHi=0;
s.objectSprite[3]=d.constants.SPRITE_DAGGER; s.objectX[3]=13; s.objectY[3]=59;
f.pressed.add('enter'); f.updatePlayerFrame(); f.pressed.delete('enter');
assert(s.objectSprite[3]===0xff && s.scoreLo===0x25,'yo-yo hazard hit did not remove/score target');

// Screen-complete lifecycle regression: 60 transition frames * 4 ticks, then A -> B.
f.startScreen('A'); s.timeHiBCD=0; s.timeLoBCD=0; f.beginScreenComplete();
for(let i=0;i<60*4;i++) f.parityTick();
assert(s.selectedLevel==='B' && s.baseScreen===1,'screen completion did not advance A to B');
// C wraps to A and increments the transform cycle.
f.startScreen('C'); s.baseScreen=2; s.transformCycle=3; s.timeHiBCD=0; s.timeLoBCD=0; f.beginScreenComplete();
for(let i=0;i<60*4;i++) f.parityTick();
assert(s.selectedLevel==='A' && s.baseScreen===0 && s.transformCycle===4,'screen C did not wrap and increment transform');
console.log('PASS: Stage 2.1 transformed sprite orientation, ladder descent, player physics, yo-yo, timing/PRNG and screen progression.');
