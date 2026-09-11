# Major routine contracts

The most important contracts are now embedded directly above the corresponding labels in `Frak.asm`. This page is a subsystem index.

## Startup / title

- `GameInitialise` — one-shot vector, zero-page, envelope, pointer and VIA setup; jumps to runtime title entry.
- `RuntimeGameEntry` — starts title/attract presentation after startup is complete.
- `TitleStartSequence` — animated attract/title sequence and start-input polling.
- `PollAttractInput` — scans keyboard then joystick, remembering the selected control scheme.

## Main game

- `StartScreen` — selects map, transform, time and tune; decodes/draws level and resets screen state.
- `MainGameFrame` — top-level live frame loop.
- `TimerAndKeys` — countdown plus sound/freeze/escape control service.
- `ScreenComplete` — completion tune/text and animated transition.

## Player / yo-yo

- `UpdatePlayerFrame` — one tick of movement, scrolling, redraw and collision handling.
- `UpdatePlayerMotion` — ground/special-state dispatcher and walking animation.
- `UpdateAirbornePlayer` — jump/fall/gravity/landing path.
- `UpdateClimbingPlayer` — ladder/rope attachment and movement.
- `UpdateYoyoAttack` — deployment, extension, collision, knockback and retraction.
- `TestPlayerMove`, `TestFloorCollision`, `TestLadderCollision` — player geometry/collision helpers.

## Objects / levels

- `LoadLevelStream` — tagged level decoder and theme map application.
- `TypeDispatch` — sprite/type handler dispatch.
- `SpawnHazard` / `UpdateDynamicQueue` — dynamic balloon/dagger lifecycle.
- `CountObjectsOfType` / `FindFreeSlot` — compact object-pool helpers.

## Score / UI

- `AddScoreBCD` — packed-BCD add plus extra-life boundary detection.
- `DrawStatus` — time/lives/score status line.
- `HighScoreInsert` — ranking, table shift and initials entry.
- `PrintInlineStream` — compact inline VDU/text stream mechanism.

## Graphics

- `ProcessSprite` — high-level draw/erase/collision request.
- `SpriteTraversal` — recursive primitive/composite traversal.
- `DirectSpriteRenderer` — derive one primitive render operation.
- `SpriteRenderSetup` — patch and run eight-call MODE 1 renderer.
- `Mode1Address` — logical coordinate to circular MODE 1 address.
- `CollisionScan` — queue filtering and sprite collision scan.

## Sound / IRQ

- `TickIRQ` — 50 Hz tick/countdown event path.
- `SoundIRQ` — scroll refresh and tune stepping, then chain old IRQ1V.
- `MusicStep` — decode one music byte and issue OSWORD 7.
- `SelectTune` — select stream, reset music timer/state.
- `OSBYTEWrapper` / `OSWORDWrapper` — MOS calls protected from sound-IRQ re-entry.

## Stage 4 title/audio fidelity mappings

- `TransitionFromLeft` / `TransitionFromRight` — initialise the two 31-frame title actors using the original object slots, X/Y positions, velocities and sprite-sequence indices.
- `RunTransitionAnimation` — advances one title actor every four game ticks and interprets negative bytes in `TransitionSpriteSequence` as delimiters/loop points.
- `ShowHighScores` — uses the original six row positions and packed-BCD table.
- `PrintPseudoRandomTitleChar` — browser translation retains the 6502 carry chain through LSR/ADC/SBC/EOR before reducing into the 36-character title map.
- `SoundOSWORD7` / OSWORD 7 host — Frak's flush-channel SOUND calls now start a MOS envelope voice with the original channel/envelope/pitch/duration fields.
- MOS ENVELOPE host — services amplitude and pitch sections at 100 Hz while `MusicStep` remains on Frak's separate 40 Hz Timer-1 cadence.
