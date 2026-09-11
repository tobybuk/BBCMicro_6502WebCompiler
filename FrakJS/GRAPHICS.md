# Graphics and sprite engine

## Descriptor system

The graphics region beginning at `&1FFD` contains six parallel descriptor arrays, each with 92 entries:

- `SpriteXOffsets`;
- `SpriteYOffsets`;
- `SpriteDefLo`;
- `SpriteDefHi`;
- `SpriteWidthFlags`;
- `SpriteHeightCount`.

`GameInitialise` installs zero-page pointers to those arrays, allowing compact indexed access throughout the renderer.

A descriptor can represent either a bitmap primitive or a composite sprite. Composite sprites recursively reference component sprites with local X/Y offsets. Trogg's animation frames and long structural objects use this mechanism.

## Recursive traversal

`SpriteTraversal` (`&1D2E`) handles both primitive and composite descriptors. Three traversal modes share the same recursion machinery:

- bounds accumulation;
- collision testing;
- render/conditional-bounds processing.

`SpriteTraversalReturnTable` stores synthetic return addresses (handler minus one); the walker pushes the selected address and uses `RTS` as a compact dispatch mechanism.

The live recursive state uses zero-page `&1E-&20`. Those bytes were formerly mistaken for object-type values because their numeric addresses overlap sprite IDs; Stage 7 names them as renderer scratch instead.

## Collision geometry

`ResetSpriteBounds`, `AccumulateSpriteBounds`, `ComputePrimitiveBounds` and `TestPrimitiveBounds` build/test bounding ranges for composite sprites. `CollisionScan` filters object queues by collision mask before performing per-sprite geometry checks.

## MODE 1 renderer

`Mode1Address` converts Frak's logical X/Y to the BBC MODE 1 screen address, accounting for the game's circular/hardware-scrolled screen arrangement.

The live renderer stub at `&01C4` contains eight explicit:

`JSR &FFFF`

instructions. `SpriteRenderSetup` patches all eight operands to one of six pixel operation routines. This is intentional self-modifying code and is retained because it is part of the real renderer, not copy protection.

The six operations are:

1. `PixelOpMaskedForward`;
2. `PixelOpMaskedReverse`;
3. `PixelOpSolid`;
4. `PixelOpEraseForward`;
5. `PixelOpEraseReverse`;
6. `PixelOpClear`.

`PixelOperationTable` at `&1F9D` is a six-word address table. Earlier linear disassembly had incorrectly interpreted these bytes as executable instructions; Stage 7 restores them as `EQUW` data.

Likewise, the row-dispatch/table structures around `&1F2E` and the synthetic-return table near `&1CAB` are data/control tables rather than ordinary linear code.

## Scrolling

Frak uses CRTC origin manipulation rather than moving the whole display. `SetCrtcOrigin` updates CRTC registers 12/13. `RefreshScrollBuffer` rebuilds the newly exposed strip from backing data, while `ScrollViewportLeft` / `ScrollViewportRight` and the edge redraw routines maintain the world window.
