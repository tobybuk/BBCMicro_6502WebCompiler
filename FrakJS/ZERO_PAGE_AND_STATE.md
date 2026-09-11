# Zero page and live state

Frak uses zero page aggressively. Some bytes have one stable meaning for the whole game; others are deliberately reused by mutually exclusive subsystems. `Frak.asm` therefore gives heavily reused bytes conservative base names plus context aliases.

## Stable renderer/display pointers

| Address | Symbol | Meaning |
|---:|---|---|
| `&00-&01` | `SpriteXOffsetPtrLo/Hi` | pointer to sprite X-offset descriptor array |
| `&02-&03` | `SpriteYOffsetPtrLo/Hi` | pointer to sprite Y-offset array |
| `&04-&05` | `SpriteDefLoPtrLo/Hi` | pointer to descriptor definition-low array |
| `&06-&07` | `SpriteDefHiPtrLo/Hi` | pointer to descriptor definition-high array |
| `&08-&09` | `SpriteWidthPtrLo/Hi` | pointer to width/flags array |
| `&0A-&0B` | `SpriteHeightPtrLo/Hi` | pointer to height/child-count array |
| `&0C-&0D` | `ScreenOriginLo/Hi` | logical/hardware-scrolled MODE 1 display origin |
| `&0E-&0F` | `ClipLeft/ClipRight` | horizontal rendering clip bounds |
| `&10` | `ViewportXOffset` | world-to-screen horizontal offset |
| `&11-&12` | `CurrentSpriteX/Y` | current sprite logical origin |

## Sprite-renderer workspace

| Address | Symbol | Meaning |
|---:|---|---|
| `&13-&14` | `RendererDataPtrLo/Hi` | bitmap/composite data pointer |
| `&15` | `RendererScreenBaseLo` | current MODE 1 screen-column base low byte |
| `&16` | `Mode1XHigh` | high-byte contribution during screen-address calculation |
| `&17` | `RendererWidth` | primitive width after clearing mirror flag |
| `&18` | `RendererHeight` | primitive height |
| `&19-&1A` | `ScreenPtrLo/Hi` | live renderer screen pointer |
| `&1B` | `PixelOpIndex` | word offset into `PixelOperationTable` |
| `&1C-&1D` | `RowRoutineLo/Hi` | indirect entry into eight-row renderer stub |
| `&1E-&20` | `SpriteTraversalCount/PtrLo/PtrHi` | saved recursive composite traversal state |
| `&21-&23` | `RendererX/RendererY/Mode1RowOffset` | primitive render coordinates and row offset |

`&1E-&20` are especially important: the original protected loader pre-seeded these bytes. They are renderer recursion scratch, not sprite IDs despite their numeric overlap with sprite numbers.

## General game state

| Address | Symbol | Meaning |
|---:|---|---|
| `&28` | `RandomState` | evolving PRNG state |
| `&2F` | `MusicInhibitFlag` | negative inhibits IRQ music stepping; `SelectTune` clears it |
| `&32` | `WalkAnimationPhase` | 0..3 walking frame phase |
| `&33` | `SavedObjectIndex` | object slot preserved across helper calls |
| `&34` | `SharedAnimationCounter` | short animation loop counter |
| `&35` | `LevelObjectSprite` | mapped sprite while decoding level objects |
| `&38-&3A` | `ScoreLo/Mid/Hi` | three packed-BCD score bytes; display adds trailing zero |
| `&3B` | `Lives` | current life count |
| `&3C` | `BaseScreen` | 0=A, 1=B, 2=C |
| `&3D` | `TransformCycle` | 0..7 display/difficulty cycle |
| `&44` | `TickCounter` | 50 Hz/event tick counter |
| `&4B` | `SoundMutedFlag` | negative means muted |
| `&4C-&4F` | saved vector bytes | previous `KEYV` and `IRQ1V` |
| `&52` | `ScrollDirectionFlags` | `SCROLL_LEFT`, `SCROLL_RIGHT`, or zero |
| `&53` | `PlayerAirborneFlag` | 0 grounded; negative while jumping/falling |
| `&54` | `PlayerClimbingFlag` | 0 normal; negative while attached to ladder/rope |
| `&55` | `YoyoActiveFlag` | 0 inactive; negative while yo-yo state machine owns player update |
| `&57` | `PlayerHorizontalStep` | signed unit direction (`+1` / `-1`) |
| `&58` | `PlayerFrameSprite` | current/proposed Trogg sprite |
| `&5A` | `CollisionMask` | queue mask used by collision scanner |
| `&5B` | `ActiveQueueDescriptor` | current queue descriptor offset |
| `&5C` | `LevelQueueDescriptor` | queue descriptor selected by level decoder |
| `&5D` | `JumpInputHistory` | compact jump/up-input history/debounce bits |
| `&5E` | `SpriteOperationMode` | draw/erase/collision mode flags |
| `&5F` | `SpriteCollisionDrawFlag` | tells collision traversal whether to render an intersecting primitive |
| `&60` | `SharedObjectCount` | generic object/result counter |
| `&64` | `CollidedObjectSlot` | slot found by collision scan |
| `&65-&67` | yo-yo state | base X, segment phase, extension count |
| `&68-&6A` | object snapshot | temporary sprite/X/Y during dynamic updates and player commit |
| `&6B-&6E` | level decoder | theme-map and stream pointers |
| `&6F` | `PrimitiveBoundsByteCount` | number of bytes occupied by 4-byte primitive bound records |
| `&70` | `ScrollRefreshRequestFlag` | negative requests Timer-2 IRQ to rebuild exposed screen strip |
| `&71` | `LastTick` | previous player-update tick |
| `&74` | `VerticalFlipFlag` | vertical render transform/control byte |
| `&75-&76` | `SpriteBoundsMinX/MaxX` | accumulated composite bounds |
| `&77` | `SupportObjectSlot` | floor/support slot associated with player |
| `&78-&79` | yo-yo animation | animation index and signed extension direction |
| `&7A` | `KeysRemainingMinusOne` | initial keys-minus-one; becomes negative after final key |
| `&7B` | `PlayerDeadFlag` | 0 alive; negative means death detected |
| `&7C-&7E` | title/high-score abort state | random sprite, draw count, saved stack pointer |
| `&80-&81` | `MaskLookupPtrLo/Hi` | pointer into page-aligned MODE 1 mask table |
| `&82-&83` | `TimeLoBCD/TimeHiBCD` | packed-BCD countdown |
| `&84` | `CountdownDivider` | 50 Hz divider to one-second events |
| `&85` | `CountdownFlags` | running / second-pending / stopped state encoding |
| `&86` | `ControlScheme` | live keyboard/joystick selector, or negative during attract delay |
| `&87` | `SelectedControlScheme` | remembered user scheme |
| `&88-&89` | hazard timing | current spawn counter and reload value |
| `&8A` | `CurrentTuneOffsetSlot` | ZP address of selected tune-offset byte |
| `&8B-&8F` | tune offsets | cached offsets of the five encoded streams |
| `&90-&91` | music state | stream position and delay counter |
| `&92` | `PauseFlag` | 0 running; negative while frozen |
| `&93` | `MosCallInProgressFlag` | prevents IRQ sound code re-entering MOS |
| `&94-&95` | collision queue state | collided and current scan descriptor offsets |

## Deliberately reused scratch

`&26` (`SharedScratch26`) is the clearest example of intentional lifetime reuse. Depending on the active routine it is `RandomLimit`, `LevelThemeCode`, `LevelObjectRemaining`, `RequestedObjectType`, `HighScoreInsertOffset`, `MovementObjectSlot`, `PreviousScoreMid`, `SavedSpriteIndex` or primitive-bound scratch. These uses do not overlap in time, so retaining a conservative base name plus aliases is more accurate than forcing one global semantic name.

Likewise `&3F/&40` are a general two-byte work pair used by time-bonus loops, screen clearing, level variant lookup and high-score name handling.
