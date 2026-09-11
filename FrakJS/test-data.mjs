import './frak-data.js';
const { FRAK_DATA } = globalThis;

const QUEUES={T:[0,3],D:[3,13],B:[13,23],K:[23,38],M:[38,48],F:[48,93],L:[93,123]};
function decode(level){
 const spr=new Uint8Array(123); spr.fill(0xff); const bytes=FRAK_DATA.levels[level]; let p=0;
 const theme=String.fromCharCode(bytes[p++]); const maps=FRAK_DATA.themeMaps[theme];
 while(p<bytes.length){const tb=bytes[p++]; if(tb===0xff) break; const tag=String.fromCharCode(tb); let slot=QUEUES[tag][0],end=QUEUES[tag][1];
  for(;;){const rec=bytes[p++], count=rec>>3; if(!count) break; const v=rec&7, s=maps[tag][v]; if(s===undefined) throw new Error(`${level} bad ${tag}/${v}`);
   for(let i=0;i<count;i++){while(slot<end&&spr[slot]!==0xff)slot++; if(slot>=end)throw new Error(`${level} ${tag} overflow`); p+=2; spr[slot++]=s;}
  }
 }
 const counts={}; for(const [tag,[a,b]] of Object.entries(QUEUES)){let n=0;for(let i=a;i<b;i++)if(spr[i]!==0xff)n++;counts[tag]=n;}
 return {theme,counts};
}
const expected={A:{T:1,D:0,B:0,K:9,M:7,F:42,L:19},B:{T:1,D:0,B:0,K:7,M:8,F:41,L:19},C:{T:1,D:0,B:0,K:12,M:10,F:45,L:16}};
for(const level of ['A','B','C']){const got=decode(level); for(const k of Object.keys(expected[level])) if(got.counts[k]!==expected[level][k]) throw new Error(`${level}/${k}: ${got.counts[k]} != ${expected[level][k]}`); console.log(level,got.theme,got.counts);}
for(const [name,a] of Object.entries(FRAK_DATA.spriteTables)) if(a.length!==92) throw new Error(`${name}: ${a.length}`);
for(let s=0;s<92;s++){const w=FRAK_DATA.spriteTables.SpriteWidthFlags[s]&0x7f; const lo=FRAK_DATA.spriteTables.SpriteDefLo[s],hi=FRAK_DATA.spriteTables.SpriteDefHi[s], n=FRAK_DATA.spriteTables.SpriteHeightCount[s]; const off=lo|(hi<<8); if(w===0){if(off+n*3>FRAK_DATA.spriteRegion.length)throw new Error(`composite ${s} out of bounds`);} else if((hi&0x80)===0 && off+w*n>FRAK_DATA.spriteRegion.length) throw new Error(`primitive ${s} out of bounds`);}
console.log('PASS: level counts and 92 sprite descriptors are structurally valid.');
