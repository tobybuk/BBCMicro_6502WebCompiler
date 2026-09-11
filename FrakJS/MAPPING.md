# Frak! 6502 → JavaScript mapping

Stage 4.3 keeps this mapping as part of the implementation contract. A routine is not promoted merely because the browser looks similar; the documented Stage 10 state/data semantics must be represented.

Current status counts: **9 host-replaced**, **17 translated**, **1 translated-partial**, **33 translated-semantic**.

| 6502 symbol | Runtime | JavaScript | Status | Subsystem | Notes |
|---|---:|---|---|---|---|
| `GameInitialise` | `&3000` | `runtimeGameEntry` | **host-replaced** | startup | BBC vector/VIA/MOS installation is replaced by browser initialisation; Frak-visible title/state entry is preserved. |
| `RuntimeGameEntry` | `&0380` | `runtimeGameEntry` | **translated-semantic** | title | Original cast/credits entry, five cast sprites and timeout into attract flow. |
| `TitleStartSequence` | `&1977` | `titleStartSequence/titleTick` | **translated-semantic** | title | 125 random sprite draws followed by the recovered left/right/final transition phases and timed attract loop. |
| `TransitionFromLeft` | `&1904` | `beginTitleTransitionLeft` | **translated-semantic** | title | Original slot 0, X=0, DX=+1, Y=&52, sequence index 1 and 31-frame setup. |
| `TransitionFromRight` | `&18F9` | `beginTitleTransitionRight` | **translated-semantic** | title | Original slot 1, X=&50, DX=-1, Y=&52, sequence index 6 and 31-frame setup. |
| `RunTransitionAnimation` | `&1922` | `advanceTitleTransitionFrame` | **translated-semantic** | title | Four-tick frame cadence, shared sprite-sequence delimiter logic and 31-frame movement retained. |
| `ShowHighScores` | `&1A52` | `showHighScores` | **translated-semantic** | title | Original six row positions, PrintPackedBCD leading-zero suppression, and generated parenthesised three-character suffixes. |
| `PrintPseudoRandomTitleChar` | `&1AF9` | `titlePseudoRandomChars` | **translated** | title | 6502 ADC/SBC/carry reduction over duplicated score bytes and original 36-character map. |
| `PollAttractInput` | `&1AD7` | `startFromTitle` | **translated-semantic** | input | SPACE/RETURN start path retained; browser keyboard replaces BBC negative-INKEY/joystick scan. |
| `GameStartTitleLoop` | `&0B4C` | `gameStartTitleLoop/titleTick` | **translated-semantic** | title | Initial cast timeout then repeated attract sequences without incorrectly replaying the cast screen. |
| `NewGame` | `&0B5A` | `newGame` | **translated** | game | Lives, score, base screen and transform reset preserved. |
| `StartScreen` | `&0B6A` | `startScreen` | **translated-semantic** | game | A/B/C level/timer/object/hazard initialisation plus original A/B/C tune selection. |
| `MainGameFrame` | `&0BC7` | `parityTick` | **translated-semantic** | game | 50 Hz host runs player, hazards, death/restart, completion and game-over/high-score transitions. |
| `TimerAndKeys` | `&0C2C` | `parityTick/key handlers` | **translated-semantic** | game | Countdown plus Q/S mute, freeze/continue and Escape-to-title browser equivalents; muted tunes keep advancing. |
| `ScreenComplete` | `&18CC` | `beginScreenComplete/screenCompleteTick` | **translated-semantic** | game | 60-frame/four-tick Trogg transition cadence, remaining-time BCD bonus and A/B/C→transform progression; BBC text/tune/raster details omitted. |
| `ClearObjectTables` | `&0DDB` | `clearObjectTables` | **translated** | objects | 123 sprite slots plus 23 DX/DY slots; DY reset to original &FF. |
| `LoadLevelStream` | `&17B8` | `loadLevelStream` | **translated** | levels | Original tagged stream grammar, theme maps and fixed queue ranges. |
| `CountObjectsOfType` | `&1B7E` | `countObjectsOfType` | **translated** | objects | Original fixed queue ranges. |
| `FindFreeSlot` | `&1C97` | `findFreeSlot` | **translated** | objects | Finds first &FF object slot in selected fixed queue. |
| `TypeDispatch` | `&12D1` | `collectObject/updateDynamicQueue` | **translated-partial** | objects | Collectible and dynamic-hazard behaviours are live; full table dispatch is not yet exhaustive. |
| `SpawnHazard` | `&1BA2` | `spawnHazard` | **translated-semantic** | objects | Original 1-in-4 dagger / 3-in-4 balloon choice and reload structure; browser tick substitutes for VIA entropy. |
| `UpdateDynamicQueue` | `&1BFB` | `updateDynamicQueue` | **translated-semantic** | objects | Balloon/dagger delay, motion and despawn lifecycle. |
| `UpdatePlayerFrame` | `&11AC` | `updatePlayerFrame` | **translated-semantic** | player | Original motion→scroll→commit→collectible/hazard order; BBC raster/erase plumbing omitted. |
| `UpdatePlayerMotion` | `&0FEB` | `updatePlayerMotion` | **translated-semantic** | player | Ground walking, animation, jump-history and climb/air/yo-yo dispatch translated. |
| `UpdateAirbornePlayer` | `&10DE` | `updateAirbornePlayer` | **translated-semantic** | player | Velocity, gravity, top boundary, ladder attempt, floor landing and fatal-fall threshold. |
| `UpdateClimbingPlayer` | `&113B` | `updateClimbingPlayer` | **translated-semantic** | player | Ladder attachment/movement/correction/floor detach represented semantically. |
| `UpdateYoyoAttack` | `&0E8F` | `updateYoyoAttack/continueYoyoAttack` | **translated-semantic** | player | Original slots 1/2, head/string phases, two-X-step extension, RETURN hold window, retraction, collision and five-tick monster knockback. |
| `TryAttachLadder` | `&0E2F` | `tryAttachLadder` | **translated-semantic** | player | Ladder probe and attach state represented; side-relation bit trick expressed as geometry. |
| `StartPlayerJump` | `&10CB` | `startPlayerJump` | **translated** | player | Initial DY=5, airborne flag and directional jump frame selection. |
| `ReadHorizontal` | `&12F9` | `readHorizontal` | **host-replaced** | input | Original Z/X meanings retained; arrows are optional aliases. |
| `ReadVertical` | `&131D` | `readVertical` | **host-replaced** | input | Original */? meanings and transform-direction reversal retained; arrows are aliases. Browser host latches brief vertical taps until the next 4-tick player sample so key presses cannot vanish between samples. |
| `ReadYoyoControl` | `&1359` | `readYoyoControl` | **host-replaced** | input | Original RETURN retained; Space is an optional browser alias. |
| `TestPlayerMove` | `&1085` | `testPlayerMove` | **translated-semantic** | collision | Original proposed-X / swept vertical floor probe and fast-fall branch represented. |
| `TestFloorCollision` | `&0E5F` | `testFloorCollision` | **translated** | collision | One-logical-X-wide floor probe. |
| `TestLadderCollision` | `&0E0B` | `testLadderCollision` | **translated** | collision | Narrow ladder probe using documented vertical geometry. |
| `CollisionScan` | `&1472` | `collisionScan` | **translated-semantic** | collision | Queue-mask filtering plus recursive primitive-vs-primitive bounds. |
| `ScanObjectCollisions` | `&1CBD` | `scanObjectCollisions` | **translated-semantic** | collision | CollisionScan wrapper contract. |
| `ComputePrimitiveBounds` | `&1592` | `primitiveBoundsForSprite` | **translated** | collision | Descriptor offsets/width/height become primitive bounds. |
| `ProcessSprite` | `&1CDF` | `spriteTraversal` | **translated-semantic** | graphics | Draw path translated; collision modes are represented by bounds traversal rather than 6502 renderer modes. |
| `SpriteTraversal` | `&1D44` | `spriteTraversal` | **translated** | graphics | Original recursive primitive/composite descriptor traversal. |
| `DirectSpriteRenderer` | `&1E36` | `directSpriteRenderer` | **translated** | graphics | Original MODE 1 bitmap bytes, column-major rows and descriptor/transform reversal; Stage 2 fixes Stage 1 upside-down rows. |
| `SpriteRenderSetup` | `—` | `directSpriteRenderer` | **host-replaced** | graphics | Self-modifying eight-JSR pixel stub replaced by direct Canvas pixel result. |
| `Mode1Address` | `&1FA9` | `putLogicalPixel` | **host-replaced** | graphics | BBC circular framebuffer address calculation replaced by logical Canvas placement. |
| `DrawSpriteAt` | `—` | `drawSpriteAt` | **translated** | graphics | Same sprite/X/Y contract. |
| `DrawAllObjects` | `&13FF` | `drawAllObjects` | **translated** | graphics | Original slot 122→0 order. |
| `DisplayInit` | `&14CD` | `applyDisplayTransform` | **translated-semantic** | display | Viewport/palette transform state represented; MOS/CRTC setup removed. |
| `ApplyDisplayTransform` | `&14D1` | `applyDisplayTransform` | **translated-semantic** | display | Original palette families plus vertical transform semantics. |
| `ScrollViewportLeft` | `&13CB` | `updatePlayerFrame` | **translated-semantic** | display | Logical one-column viewport offset; CRTC memory rotation is unnecessary in Canvas. |
| `ScrollViewportRight` | `&13E5` | `updatePlayerFrame` | **translated-semantic** | display | Logical one-column viewport offset; CRTC memory rotation is unnecessary in Canvas. |
| `AddScoreBCD` | `&15B8` | `addScoreBCD` | **translated** | score | Three packed-BCD bytes and original bit-5 extra-life boundary test. |
| `DrawStatus` | `&15DB` | `updateInfo` | **host-replaced** | score | Browser diagnostics currently expose score/lives/time instead of BBC status-line VDU output. |
| `HighScoreInsert` | `&164D` | `highScoreInsert` | **translated-semantic** | score | Six-record packed-BCD ranking, table shift and three-character initials entry. |
| `PrintInlineStream` | `&0D21` | `drawTitleText/title renderers` | **translated-semantic** | display | Frak's relevant VDU cursor/window semantics are represented and printable characters are rasterised from a fixed BBC 8×8 bitmap table directly into the 320×256 framebuffer; no Canvas/browser fonts are used. |
| `RandomUpToA` | `&0DB6` | `randomUpToA` | **translated-semantic** | prng | Original mask/rejection 0..A-inclusive shape; tick counter substitutes for VIA timer entropy. |
| `TickIRQ` | `&0D44` | `parityTick` | **translated-semantic** | timing | 50 Hz browser tick preserves player divisor/countdown cadence; MOS event-vector mechanics omitted. |
| `SoundIRQ` | `&0D69` | `soundIRQ` | **translated-semantic** | sound | Original 40 Hz Timer-1 music cadence retained alongside the 100 Hz MOS envelope service; browser scheduler replaces VIA IRQ. |
| `MusicStep` | `&186B` | `musicStep` | **translated** | sound | Original bit7 terminator, bits2..6 pitch and bits0..1 duration decoder over retained stream bytes. |
| `SelectTune` | `&18B4` | `selectTune` | **translated** | sound | Original five stream selections and reset/inhibit state represented directly. |
| `OSBYTEWrapper` | `—` | `browserHost` | **host-replaced** | mos | Only Frak-observable host effects will be represented. |
| `OSWORDWrapper` | `&0E0B` | `playSoundBlock/mosEnvelopeTick` | **host-replaced** | mos | Browser host now reproduces the Frak-used MOS SOUND subset: flush channels, 100 Hz ENVELOPE state, MOS pitch lookup and SN76489 attenuation; Web Audio remains the physical output layer. |

## Data mapping

| Original data | Browser representation | Fidelity rule |
|---|---|---|
| `LevelA`, `LevelB`, `LevelC` | `FRAK_DATA.levels` | Original encoded bytes; decoded at runtime. |
| Six 92-entry descriptor arrays | `FRAK_DATA.spriteTables` | Retained byte-for-byte. |
| Sprite/composite/bitmap region | `FRAK_DATA.spriteRegion` | Original bytes; no PNG sprite conversion. |
| Theme C/J/G maps | `FRAK_DATA.themeMaps` | Same theme-local variant→descriptor mapping. |
| Object arrays (123 slots; DX/DY 23) | typed arrays in `state` | Same queue boundaries and `&FF` empty marker; Stage 4.3 preserves initial DY=`&FF`. |
| Five encoded tune/effect streams | `FRAK_DATA.soundStreams` | Original bytes and bit-field decoder retained. |
| Four BBC SOUND blocks | `FRAK_DATA.soundBlocks` | Original channel/envelope/pitch/duration values; all four retain duration `&00FF`. |
| Four BBC ENVELOPE definitions | `FRAK_DATA.envelopes` | Original 14-byte records drive the Stage 4.1 100 Hz MOS envelope state. |
| Title transition stream/timing | `FRAK_DATA.title.transition*` | Original delimiter stream, 31-frame count, 4-tick cadence, clipping window and hold times. |
| Title character map / row table | `FRAK_DATA.title.characterMap/highScoreRows` | Original pseudo-random suffix map and six row positions. |
| Six high-score records | `state.highScores` | Original 36-byte table copied into writable browser state. |

## Renderer correction retained from Stage 2.1

Stage 1 had the logical objects in the right world coordinates but fetched each primitive bitmap column from the wrong end. The original forward pixel operator begins at `definition + height - 1` and decrements through the column. Stage 4.3 retains the corrected `height - 1 - row` normal source traversal, with descriptor reverse and display vertical-flip combined exactly as opposing reversal flags.

## Rule for future work

Prefer an explicit `pending`/`translated-partial` status over invented browser-game behaviour. Where BBC hardware mechanisms have no useful browser analogue, preserve the Frak-facing contract and mark them `host-replaced` or `translated-semantic`.


## Stage 4.3 BBC bitmap-text correction

Stage 4.3 removes Canvas `fillText` from the BBC display path. Cast, title/high-score and initials-entry text is now drawn from a fixed 96-character 8×8 BBC bitmap table directly into `framePixels`. This makes every character exactly one BBC 8×8 cell, with no browser font substitution, font hinting, kerning, antialiasing or host-dependent metrics. The VDU 31 coordinates and Stage 4.1 title/text-window geometry remain unchanged.

## Stage 4.1 visual parity corrections

- `RuntimeGameEntry`: cast/credits text now uses the literal BBC VDU cursor positions and the original yellow lower text window/separator.
- `PrintTitleBanner`: the original window `(6,8)-(33,22)`, VDU 12 clear and PLOT rectangle are represented explicitly before `ShowHighScores`.
- `CommitPlayer_DeathEffects`: `SPRITE_TROGG_DEATH` is now rendered as an additional overlay over Trogg, preserving the speech bubble semantics of composite descriptor `&5B`.
