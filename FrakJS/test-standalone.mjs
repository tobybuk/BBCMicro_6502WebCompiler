import fs from 'node:fs';
import vm from 'node:vm';
const html=fs.readFileSync(new URL('./Frak_Stage4_7_STANDALONE.html',import.meta.url),'utf8');
const scripts=[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m=>m[1]);
if(scripts.length<2) throw new Error(`expected 2 inline scripts, got ${scripts.length}`);
const nodes=new Map();
function node(id){if(!nodes.has(id))nodes.set(id,{textContent:'',dataset:{},addEventListener(){}});return nodes.get(id);}
const ctx={imageSmoothingEnabled:false,createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4),width:w,height:h};},putImageData(){},save(){},restore(){},fillText(){},font:'',textBaseline:'',textAlign:'',fillStyle:''};
globalThis.document={getElementById(id){if(id==='screen')return{getContext(){return ctx;}};return node(id);},querySelectorAll(){return[];}};
globalThis.window={addEventListener(){}};
globalThis.requestAnimationFrame=()=>0;
for(const script of scripts) vm.runInThisContext(script,{filename:'Frak_Stage4_7_STANDALONE.html'});
if(!window.FRAK) throw new Error('standalone did not publish window.FRAK');
if(window.FRAK.state.mode!=='titleCast') throw new Error('standalone did not enter cast/title entry');
console.log('PASS: Stage 4.7 standalone HTML is self-contained and initialises the browser port.');
