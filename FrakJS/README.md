# Stage 4.7 high-score entry parity fix

Stage 4.7 replaces the browser-only initials-entry overlay with the original HighScoreInsert presentation: the existing gameplay raster is retained outside the title panel, the original two instruction strings are drawn at BBC VDU positions (9,17) and (9,19), and the live candidate character appears directly in the qualifying initials field. The selected character now carries forward to the next initial exactly as the 6502 routine does, and after the third initial the completed screen is held for &50 ticks with no invented "New high score" message.

# Stage 4.6 control remap

Browser keyboard controls are now **Z** left, **X** right, **'** up/jump, **/** down, and **Return** for the yo-yo. Up/Down Arrow remain convenience aliases. The Stage 4.5 short-tap input latch is retained for the new vertical keys.

# Stage 4.5 input-latch correction

Stage 4.5 retains Stage 4.5 gameplay and presentation, and fixes short vertical key taps being lost between Frak's 4-tick player updates. Up/Down (and new `'`/`/`) are now latched by the browser host until the next player update consumes them. This does not change the original jump, ladder, or 50 Hz/4-tick movement cadence.

Stage 4.5

- Adjusted the copyright line on the title/high-score panel from row 24 to row 23 to prevent clipping against the panel lower border.

# Frak! BBC Micro → JavaScript browser port — Stage 4.3

This is a parity-oriented JavaScript port of the reverse-engineered BBC Micro **Frak!** program. The documented Stage 10 6502 source remains the specification. The browser version deliberately keeps the original data formats, routine boundaries, state machines, timing relationships and oddities visible instead of redesigning Frak around a modern game engine.

## Stage 4.3 attract/title parity corrections

- The final attract frame now retains Trogg and overlays sprite `&5B` as the `FRAK!` speech bubble, matching the original draw order instead of replacing Trogg.
- The central attract/high-score panel is calibrated to the supplied BBC emulator reference frame (`x=24..276`, `y=58..198` in the 320×256 framebuffer).
- Title/banner text positions were tightened against the reference frame while remaining on the BBC 8×8 bitmap grid.
- High-score printing now reproduces `PrintPackedBCD` carry semantics: leading zero nibbles are suppressed, so the stock `&00,&01,&00` score displays as `1000`, not `0001000`.
- Transition actors are layered after the fixed title/high-score overlay, matching the original `PrintTitleBanner` → transition animation ordering.

## Run

Open `index.html` directly in a modern browser. There are no libraries, build tools or network dependencies.

For the easiest single-file build, open:

`Frak_Stage4_2_STANDALONE.html`

The program begins at the original cast/credits entry. Press **Space** or **Return** to start. Browsers normally require that first user gesture before audio can become audible.

## Stage 4.3 bitmap-font correction

Stage 4.3 fixes the remaining corrupted/host-dependent title and high-score lettering seen in Stage 4.1. All BBC-screen text in the cast/title/high-score path now bypasses Canvas text APIs entirely. Printable characters are rendered as deterministic 8×8 BBC bitmap glyphs directly into the 320×256 framebuffer.

This means:

- exactly 8 pixels per character cell and 8 pixels per row;
- no browser font substitution or platform-dependent monospace metrics;
- no anti-aliasing, hinting or sub-pixel colour fringes;
- VDU 31 positions map literally to BBC character cells;
- the high-score table uses the same bitmap glyph path as the cast screen;
- Stage 4.1's yellow credit window, title panel geometry and death speech-bubble fix are retained unchanged.

A dedicated regression checks both the canonical `A` glyph bytes and pixels from `The Cast` in the rendered framebuffer.

## Stage 4.1 VDU/title corrections

Stage 4.1 is a visual-fidelity correction driven by direct comparison with BBC Micro screenshots. It keeps the Stage 4 gameplay/audio code unchanged and corrects three presentation details:

- `RuntimeGameEntry` now follows the original cast-screen VDU layout: black 8-column-cell text, exact VDU 31 positions, yellow rows 25-31 credit window, and the black separator plotted at scanline 199.
- `PrintTitleBanner` now recreates the original central text window at columns 6-33 / rows 8-22, clears that area to green, draws the one-pixel black PLOT border, and positions the banner/high scores using the original full-screen/window-relative coordinates. The extra browser-only start prompt has been removed from the BBC display.
- Player death now leaves Trogg's current sprite in place and draws `SPRITE_TROGG_DEATH` (`&5B`) as an overlay, matching `CommitPlayer_DeathEffects`. Descriptor `&5B` is the FRAK! speech-bubble composite; it is not a replacement Trogg frame.

## Stage 4.1 additions

Stage 4.1 retains all Stage 2.1 gameplay corrections and all Stage 3 cast/high-score/music work, then tightens two remaining fidelity areas.

### BBC sound fidelity

The browser no longer treats a BBC pitch byte as a generic exponential frequency and no longer substitutes a simple ADSR ramp for ENVELOPE.

Stage 4.1 now implements the subset of BBC MOS/SN76489 behaviour that Frak actually uses:

- the BBC MOS 1.20 quarter-semitone pitch lookup algorithm;
- conversion to the SN76489 10-bit tone period;
- the SN76489's 16 attenuation levels at approximately 2 dB per step;
- Frak's original OSWORD 7 blocks, including channel-flush semantics;
- the original four OSWORD 8 ENVELOPE records;
- the MOS amplitude envelope state machine at **100 Hz**;
- all three pitch-envelope sections, section repeat/termination and signed pitch steps;
- the original **40 Hz** Frak music-stream scheduler remains separate from the MOS 100 Hz envelope service;
- SOUND duration `&FF` is retained as the effectively indefinite Frak block duration;
- muting gates output but does not destroy voice/envelope state or stop tune-stream progression.

Frak uses only the three tone channels in these four live SOUND blocks, so Stage 4.1 intentionally does not add an unused BBC noise-channel emulator just to claim a larger subsystem. Web Audio square oscillators remain the final physical browser output layer; the game-facing pitch, attenuation and envelope state are now BBC-derived rather than approximate ramps.

### Original title transition choreography

The attract sequence is now much closer to the 6502 flow:

1. draw 125 copies of one randomly selected original Frak sprite;
2. print the title/high-score overlay on that existing backdrop;
3. run `TransitionFromLeft`: Trogg starts at logical X=0, Y=&52 and moves +1 for 31 frames;
4. each frame is separated by the original four game ticks and Trogg uses the original delimiter-driven `&34,&35,&36,&37` animation stream;
5. run `TransitionFromRight`: Scrubbly starts at logical X=&50 and moves -1 for 31 frames;
6. respect the original title clipping window (`&0C..&44` logical columns);
7. wait the original 75 ticks;
8. show Trogg's final/death frame at Y=&52 for 250 ticks;
9. restart the attract sequence directly, rather than incorrectly replaying the one-time cast screen.

The high-score display also now uses the original row table `9,11,12,13,14,15` and reproduces the three parenthesised pseudo-random characters generated from each packed-BCD score by `PrintPseudoRandomTitleChar`.

## Controls

| BBC/original meaning | Browser |
|---|---|
| Z — left | `Z` or Left Arrow |
| X — right | `X` or Right Arrow |
| ' — up / jump | `'` or Up Arrow |
| / — down | `/` or Down Arrow |
| RETURN — yo-yo | Return or Space while playing |
| Q — sound off | `Q` |
| S — sound on | `S` |
| DELETE — freeze | Delete |
| COPY/unfreeze equivalent | `C` continue |
| ESCAPE | Escape returns to the attract/title loop |
| Start from title | Space or Return |

Debug/navigation retained for parity work: `1/2/3` selects A/B/C and `[` / `]` changes the transform cycle.

During high-score initials entry, `Z`/Left moves backward through characters, `X`/Right moves forward and `'`/Up commits the current character.

## Mapping

`MAPPING.md` and `MAPPING.csv` are first-class project outputs. Stage 4.3 tracks **60** original routines rather than hiding newly recovered title work under one generic browser function.

New explicit mappings include:

```text
&18F9  TransitionFromRight       -> beginTitleTransitionRight()
&1904  TransitionFromLeft        -> beginTitleTransitionLeft()
&1922  RunTransitionAnimation    -> advanceTitleTransitionFrame()
&1A52  ShowHighScores            -> showHighScores()
&1AF9  PrintPseudoRandomTitleChar-> titlePseudoRandomChars()
```

The sound side retains:

```text
&186B  MusicStep                 -> musicStep()
&18A9  SoundOSWORD7              -> playSoundBlock()
&18B4  SelectTune                -> selectTune()
&0D69  SoundIRQ                  -> soundIRQ()
```

Browser Canvas, keyboard, Web Audio and host scheduling remain explicitly marked as host replacements where BBC hardware has no useful direct browser equivalent.

## Original data retained

`frak-data.js` is generated from the documented assembly by `tools/extract_stage10_data.py`. Stage 4.3 extracts and retains:

- A/B/C encoded level streams;
- C/J/G theme maps;
- six × 92 sprite descriptor arrays;
- original bitmap/composite sprite data;
- display palette tables;
- all five encoded tune/effect streams;
- all four eight-byte SOUND parameter blocks, now including their `&00FF` duration words;
- all four 14-byte ENVELOPE definitions;
- six initial high-score records;
- title transition sprite stream;
- title transition timing/clip constants;
- exact six-row high-score position table;
- 36-byte title character map and the three random-character seeds.

## Regression tests

Run:

```bash
npm test
```

The suite now covers five layers:

- original A/B/C level counts and all 92 sprite descriptors;
- browser title-first startup followed by explicit gameplay entry;
- Stage 2.1 transformed-sprite orientation and downward ladder traversal;
- player physics, yo-yo, collisions, hazards, PRNG and 24-screen progression;
- Stage 3 tune-stream/high-score behaviour;
- Stage 4.1 known BBC MOS pitch periods, envelope evolution, mute state retention and complete title-transition timing/distances.

## Remaining fidelity work

The remaining gaps are increasingly narrow:

- Canvas still represents the final MODE 1 result rather than rotating a literal 20 KiB BBC framebuffer through CRTC registers 12/13;
- Web Audio generates the final square waves rather than a sample-by-sample SN76489 chip core;
- BBC VDU graphics/window commands are represented semantically rather than interpreted byte-for-byte;
- joystick selection and analogue BBC joystick paths remain browser-host work;
- `TypeDispatch` still has one explicitly partial mapping because not every object-type path is represented independently;
- deterministic frame/state traces have not yet been automatically compared against a simultaneously driven jsbeeb reference run.

The project rule remains: **prefer an explicit semantic/host-replaced/partial label over invented behaviour.**
