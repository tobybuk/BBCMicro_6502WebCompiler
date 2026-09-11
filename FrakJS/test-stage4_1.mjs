import './test-browser-host.mjs';
const F=globalThis.window.FRAK;
F.newGame();
const before=F.state.objectSprite[0];
F.markPlayerDead('regression');
if(!F.state.playerDead) throw new Error('death flag not set');
if(F.state.objectSprite[0]!==before) throw new Error('death bubble incorrectly replaced Trogg sprite');
// &5B must remain the documented overlay descriptor.
if(globalThis.FRAK_DATA.constants.SPRITE_TROGG_DEATH!==0x5b) throw new Error('death overlay descriptor changed');
F.runtimeGameEntry();
if(F.state.mode!=='titleCast') throw new Error('cast entry mode lost');
console.log('PASS: Stage 4.1 death-bubble overlay and VDU-title entry regressions.');
