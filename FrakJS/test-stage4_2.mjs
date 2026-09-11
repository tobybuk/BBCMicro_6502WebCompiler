import './test-browser-host.mjs';
const F=globalThis.window.FRAK;
if(!F.BBC_MOS_FONT_8X8 || F.BBC_MOS_FONT_8X8.length!==768) throw new Error('BBC 8x8 font table missing');
const A=Array.from(F.BBC_MOS_FONT_8X8.slice((65-32)*8,(65-31)*8));
const expectedA=[0x3c,0x66,0x66,0x7e,0x66,0x66,0x66,0x00];
if(A.some((v,i)=>v!==expectedA[i])) throw new Error(`BBC glyph A mismatch: ${A}`);
// runtimeGameEntry rendered "The Cast" at col 16,row 3. BBC T top row is 0x7e,
// so x=129..134 on y=24 must be black while x=128 remains green background.
F.runtimeGameEntry();
const px=(x,y)=>Array.from(F.framePixels.slice((y*320+x)*4,(y*320+x)*4+3));
const black=px(129,24), green=px(128,24);
if(black.join(',')!=='0,0,0') throw new Error(`bitmap text foreground is not black: ${black}`);
if(green.join(',')!=='0,255,0') throw new Error(`bitmap text background is not green: ${green}`);
console.log('PASS: Stage 4.2 BBC 8x8 bitmap font renders directly into framebuffer without Canvas text.');
