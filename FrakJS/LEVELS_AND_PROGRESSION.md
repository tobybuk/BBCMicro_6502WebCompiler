# Levels and progression

## Packed level format

Frak has three base level streams at:

- `LevelA` `&05D4` — theme byte `"C"`, Scrubblies;
- `LevelB` `&0689` — theme byte `"J"`, Poglets;
- `LevelC` `&073C` — theme byte `"G"`, Hooters.

After the theme byte, the stream is queue-tagged. Queue tags are the same letters as the runtime queue descriptors: `T`, `D`, `B`, `K`, `M`, `F`, `L`.

Within a queue block, a record byte is:

`(count << 3) | variant`

It is followed by `count` X/Y coordinate pairs. A zero record ends that queue block. `&FF` ends the level.

The `variant` is not directly a sprite number. `LoadLevelStream` selects the theme's mapping table, which converts queue+variant to the actual sprite/type.

## Theme maps

`ThemeCMap` (Level A) selects Scrubblies plus its own floor/ladder artwork.

`ThemeJMap` (Level B) selects Poglets plus a second floor/ladder set.

`ThemeGMap` (Level C) selects Hooters plus a third floor/ladder set.

All three map collectible variants consistently:

- 0 → key (`&17`);
- 1 → light bulb (`&23`);
- 2 → gem (`&16`).

## Level object counts

| Level | Trogg | Monsters | Collectibles | Floors | Ladders/ropes | Total placed |
|---|---:|---:|---:|---:|---:|---:|
| A | 1 | 7 Scrubblies | 9 | 42 | 19 | 78 |
| B | 1 | 8 Poglets | 7 | 41 | 19 | 76 |
| C | 1 | 10 Hooters | 12 | 45 | 16 | 84 |

Dynamic balloons and daggers are spawned at runtime and therefore are not counted in the base level streams.

## Progression

There are three base screens and an eight-state transformation cycle:

**3 × 8 = 24 gameplay states** before the transformation value wraps.

After Level C, `BaseScreen` returns to 0 and `TransformCycle` advances modulo 8.

Initial timers are:

- Level A: 2:00;
- Level B: 3:00;
- Level C: 4:00.

Each screen also selects its own tune and foreground/palette value from compact tables adjacent to the level pointer tables.

## Hazard rate

At screen start:

`HazardReload = (11 - TransformCycle) * 4`

so hazards become more frequent as the transform cycle advances.

When time reaches zero the game alters countdown/difficulty state and subtracts a further 10 from `HazardReload`, increasing hazard pressure again. The expired-time presentation varies with the current transform pattern.

## Completion

Keys are counted from the collectible queue after level loading. Once the key count is exhausted, the screen-complete path runs, remaining time is converted into score, then the base screen/transform cycle is advanced.
