# Binary/data formats reconstructed from the game

## Queue descriptors

The seven queue descriptors at `QueueDescriptors` are compact overlapping four-byte records:

```
+0 first slot
+1 collision/selection flags
+2 ASCII queue tag
+3 exclusive end slot   ; physically the +0 byte of the next descriptor
```

The final `OBJECT_SLOT_END` supplies the last record's end slot. This is why only three new bytes are emitted for each named descriptor.

Queues are T/D/B/K/M/F/L = Trogg, daggers, balloons, collectibles, monsters, floors and ladders/ropes.

## Level streams

Each level begins with a one-byte theme selector (`C`, `J`, or `G`). It is followed by queue blocks. Each queue block begins with its ASCII queue tag, then one or more records:

```
record = (count << 3) | variant
followed by count pairs of {X,Y}
```

Record zero ends the current queue block; `&FF` ends the complete level. The low three-bit variant is **theme-local**, not a universal object ID. `ThemeCMap`, `ThemeJMap` or `ThemeGMap` maps `{queue,variant}` to the actual sprite ID.

This explains why Scrubbly and Hooter both use monster variant 0 while Poglet uses variant 1 in its theme.

## Theme maps

A theme map is a series of variable-length variant lists:

```
queueDescriptorOffset, spriteForVariant0, spriteForVariant1, ... , &FF
...
&FF                         ; end entire theme map
```

## Type-dispatch table

`ObjectTypeDispatchTable` uses fixed three-byte records:

```
spriteID, handlerLo, handlerHi
```

It dispatches keys, gems, bulbs and the two dynamic hazard types to their specialised handlers.

## High-score record

Six records of six bytes are stored at `HighScores`:

```
+0..+2  initials
+3      score high packed-BCD byte
+4      score middle packed-BCD byte
+5      score low packed-BCD byte
```

The status display prints an additional literal zero, so a score increment of packed BCD `&25` represents 250 displayed points.

## OSWORD 7 sound block

Each eight-byte sound parameter block is four little-endian words:

```
channel, amplitude/envelope, pitch, duration
```

Frak keeps four live blocks at `&01A4`: music, yo-yo hit, player movement and collection sound. Music and movement patch their pitch fields at runtime.

## Music byte

`MusicStep` interprets one byte as:

```
bit 7       stream terminator / loop marker
bits 6..2   pitch field (written as byte & &7C)
bits 1..0   duration code
```

Nominal duration units are `(durationCode + 1) * 4`. See `MUSIC_DECODE.md` for every decoded stream item.

## Sprite descriptor

There are six parallel 92-entry arrays:

```
X offset
Y offset
definition low
definition high
width/flags
height-or-child-count
```

`width/flags == 0` marks a composite sprite. Its definition word is an offset from `SpriteXOffsets` to child records, each three bytes `{childSprite, signed dX, signed dY}`, and height/count is the number of children.

For primitive sprites, low seven width bits give the width and bit 7 requests horizontal reversal. If definition-high is negative, definition-low is a solid fill byte; otherwise the definition word points to bitmap bytes relative to `SpriteXOffsets`. See `SPRITE_CATALOG.md`.

## Primitive collision records

Composite bounds traversal stores four-byte primitive rectangles in the low hardware stack page:

```
left, right, bottom, top
```

`PrimitiveBoundsByteCount` advances by four for each primitive. Collision traversal tests the other sprite's primitives against these records.

## Inline VDU stream

`JSR PrintInlineStream` is followed immediately by bytes ending with `INLINE_STREAM_END` (`&EA`). The routine consumes the caller return address, prints bytes through OSWRCH, then resumes execution immediately after the terminator. These embedded byte runs are data, not executable code.

## Stage 4 browser-retained title/sound fields

The browser extractor now retains the complete Frak-side values needed by the higher-fidelity host layer rather than re-deriving them from browser constants:

- each SOUND block includes its original 16-bit duration (`&00FF` in all four live blocks);
- `TransitionSpriteSequence = &FF,&34,&35,&36,&37,&FF,&12,&FF`;
- title transition frame count `&1F`, frame delay `4`, logical Y `&52` and clip window `&0C..&44`;
- title post-transition delay `&4B` and final wait `&FA`;
- `HighScorePositionRowTable = 9,11,12,13,14,15`;
- the 36-byte `TitleCharacterMap` and the three pseudo-random seeds `&63,&2A,&F7`.

Stage 4 uses the original ENVELOPE byte layout directly at 100 Hz: `T`, three pitch increments, three pitch-section lengths, four amplitude increments, attack target and decay target. The final browser oscillator is still a host replacement; the state driving it now follows the Frak-used MOS envelope path rather than a generic ADSR approximation.
