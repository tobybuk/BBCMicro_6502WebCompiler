import './frak-data.js';
const nodes = new Map();
function node(id){ if(!nodes.has(id)) nodes.set(id,{textContent:'',dataset:{},addEventListener(){}}); return nodes.get(id); }
const ctx={imageSmoothingEnabled:false,createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},putImageData(){}};
globalThis.document={
  getElementById(id){ if(id==='screen') return {getContext(){return ctx;}}; return node(id); },
  querySelectorAll(){return [];}
};
globalThis.window={addEventListener(){}};
globalThis.performance={now(){return 0;}};
globalThis.requestAnimationFrame=()=>0;
await import('./frak.js');
if(!globalThis.window.FRAK) throw new Error('FRAK diagnostic API missing');
const f=globalThis.window.FRAK;
if(f.state.mode!=='titleCast') throw new Error(`Stage 3 should enter titleCast, got ${f.state.mode}`);
f.newGame();
if(f.countObjectsOfType('T')!==1 || f.countObjectsOfType('F')!==42) throw new Error('Level A state mismatch');
f.startScreen('B');
if(f.countObjectsOfType('K')!==7 || f.countObjectsOfType('L')!==19) throw new Error('Level B state mismatch');
f.startScreen('C');
if(f.countObjectsOfType('M')!==10 || f.countObjectsOfType('F')!==45) throw new Error('Level C state mismatch');
console.log('PASS: browser host enters title then initialises/renders A/B/C without runtime exceptions.');
