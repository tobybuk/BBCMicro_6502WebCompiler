# Frak source walkthrough

Stage 10 keeps the original algorithms and data intact and adds navigation comments directly to `Frak.asm`. This file mirrors those comments at a higher level.

## Startup and runtime flow

1. BBC 6502 Web Assembler scatter-loads the sparse multi-`ORG` image.
2. `start` / `GameInitialise` at `&3000` performs one-shot machine setup.
3. It jumps to `RuntimeGameEntry` at `&0380` for the cast/credits screen.
4. `GameStartTitleLoop` / `TitleStartSequence` run attract/high-score presentation until start input.
5. `NewGame` initialises lives, score, base screen and transform cycle.
6. `StartScreen` selects the A/B/C level stream, timer, tune, palette/transform, decodes objects and starts play.
7. `MainGameFrame` repeats player update, death/completion checks, timer/key service and dynamic hazard update.
8. `ScreenComplete` converts remaining time to score, advances A/B/C and then advances the 0..7 transform cycle after screen C.

## Emitted regions

- `&01A4-&01FF`: four OSWORD 7 sound blocks and the self-modifying eight-call renderer stub.
- `&0380-&048F`: cast/credits entry. Disposable: gameplay object arrays later overwrite this memory.
- `&0507-&07FE`: five music/effect streams followed by levels A, B and C.
- `&0880-&08A3`: six writable high-score records.
- `&0A00-&0AFF`: page-aligned MODE 1 mask lookup table.
- `&0B00-&0CF2`: object queue descriptors and top-level game lifecycle.
- `&0D01-&1FFC`: main engine.
- `&1FFD-&2FFF`: 92 sprite descriptors, composite definitions and bitmap data.
- `&3000+`: transient startup; overwritten by MODE 1 screen use after entry.

## Main-engine order

- `&0Dxx`: tick/raster waits, inline VDU printer, EVENTV/IRQ1V handlers, INKEY and PRNG.
- `&0Exx-&11xx`: player physics, ladder attachment, jumping/falling and yo-yo state.
- `&11xx-&13xx`: player frame commit, collectibles/hazards and control readers.
- `&13xx-&15xx`: scroll-strip handling, CRTC origin, collision scan and display transforms.
- `&15xx-&17xx`: score/status display and high-score insertion.
- `&17xx`: theme/level stream decoder.
- `&18xx`: IRQ-driven music and screen/title transition animation.
- `&19xx-&1Bxx`: attract/title/high-score presentation and dynamic hazard spawner.
- `&1Cxx-&1Fxx`: dynamic object update, collision bounds, recursive sprite traversal and MODE 1 renderer.

## Shared zero-page names

Names beginning `Shared...` are deliberate, not unresolved. Frak aggressively reuses zero page. The source supplies context aliases such as `RandomLimit`, `LevelThemeCode`, `LadderSavedX`, `HighScoreRankNumber`, `CrtcStartAddressLo`, etc., so each live use states its actual meaning.

## Original oddities retained and explained

- The compact draw/erase entries around `&0B18` overlap opcodes to save bytes.
- `&11AB` is an unreferenced original `RTS` byte/padding and is retained exactly.
- The renderer at `&01C4` contains eight `JSR &FFFF` instructions patched to pixel routines at runtime.
- The title code at `&0380` is intentionally sacrificed when gameplay object arrays occupy `&0368` onward.
- The upper hardware-stack page is deliberately used for live game data after startup lowers SP to `&A2`.

## Browser Stage 4 fidelity notes

The Stage 4 browser port now follows the attract sequence beyond `PrintTitleBanner`: the 125-sprite backdrop is retained, `TransitionFromLeft` and `TransitionFromRight` run for 31 frames each at the original four-tick cadence, and the final Trogg frame is held for `&FA` ticks before `TitleStartSequence` repeats. The one-time `RuntimeGameEntry` cast screen is no longer incorrectly replayed on every attract loop.

The browser sound layer also separates Frak's 40 Hz music stream clock from the BBC MOS 100 Hz ENVELOPE service. BBC pitch bytes are converted through the MOS lookup-table algorithm to SN76489 tone periods, and envelope amplitude is quantised through the chip's 16 attenuation steps before being passed to Web Audio.
