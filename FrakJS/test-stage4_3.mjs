import './test-browser-host.mjs';
const F=globalThis.window.FRAK;
const D=globalThis.FRAK_DATA;
const assert=(c,m)=>{if(!c)throw new Error(m);};

// PrintPackedBCD enters ShowHighScores with CLC, so leading zero nibbles vanish.
assert(F.formatHighScoreBcd(0x00,0x01,0x00)==='1000','high-score leading-zero suppression');
assert(F.formatHighScoreBcd(0x12,0x34,0x56)==='1234560','full BCD score formatting');

// Reference BBC raster panel geometry recovered from the supplied emulator frame.
const r=F.TITLE_PANEL_RECT;
assert(r.left===24 && r.top===58 && r.right===276 && r.bottom===198,'title panel geometry');

// Final title frame must retain Trogg and overlay &5B (FRAK!) rather than replacing him.
F.runtimeGameEntry();
F.state.objectSprite[0]=D.constants.SPRITE_TROGG_FRAME0;
F.state.objectX[0]=31; F.state.objectY[0]=D.title.finalY;
F.state.objectSprite[1]=0xff;
F.renderTitleTransitionScene(false);
const body=new Uint8ClampedArray(F.framePixels);
F.renderTitleTransitionScene(true);
const final=F.framePixels;
let retained=0, added=0;
for(let y=120;y<210;y++) for(let x=70;x<180;x++) {
  const i=(y*320+x)*4;
  const bodyNonGreen = !(body[i]===0 && body[i+1]===255 && body[i+2]===0);
  const finalNonGreen = !(final[i]===0 && final[i+1]===255 && final[i+2]===0);
  if(bodyNonGreen && finalNonGreen && body[i]===final[i] && body[i+1]===final[i+1] && body[i+2]===final[i+2]) retained++;
  if(!bodyNonGreen && finalNonGreen) added++;
}
assert(retained>80,`final title lost Trogg body pixels (${retained})`);
assert(added>20,`final title did not add FRAK bubble pixels (${added})`);
console.log('PASS: Stage 4.3 title geometry, BCD score formatting, and Trogg + FRAK final overlay.');
