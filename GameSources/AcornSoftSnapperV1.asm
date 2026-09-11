; Acornsoft Snapper V1 - documented reverse-engineering snapshot
; Original game by Jonathan Griffiths / Acornsoft, 1982
;
; STAGE 8: ghost-AI pseudocode / exact junction probes / sprite atlas / build-residue analysis
;
; This single file represents the exact relocated runtime image at &0E00-&33FF.
; Original $.Snappe3 loads at &1E00; its &4400 loader copies &1E00-&43FF to &0E00-&33FF.
; BASIC then CALLs &3283.  &3283 copies &3000-&32FF down to &0400-&06FF and jumps to &064F.
;
; Runtime baseline SHA-256: 625cc46d77986279275bd346ab52a9d48b1d1d963fa91813f38a3a7d6269b1fc
;
; ORIGINAL BASIC START-UP ENVIRONMENT
; -----------------------------------
; These commands are copied from the original Acornsoft BASIC loader.  They are
; represented as web-assembler @basic metadata so they reproduce the original
; MOS/VDU/sound environment while emitting no bytes into the machine-code image.
; @basic VDU23;10,32,0;0;0;
; @basic ENVELOPE1,4,6,-3,-3,4,2,2,0,0,-1,0,63,58
; @basic ENVELOPE2,3,-4,-1,2,6,6,28,81,-4,-5,-1,126,63
; ENVELOPE 1 is selected by the energizer sound; ENVELOPE 2 by fruit/ghost-eaten effects.
;
; Stage 8 resolved systems/data formats:
;   * Parallel object arrays: ghosts 0..3 and Snapper in fixed slot 4.
;   * Ghost states: NORMAL=&00, FRIGHTENED=&80, EATEN=&FF, including return-to-home recovery.
;   * Normal ghost rendering = animated body mask AND per-ghost colour mask OR directional eye overlay.
;   * Frightened ghosts use two direct sprite frames; eaten ghosts draw the eye overlay alone.
;   * Sprite IDs &18-&1F are Snapper's two animation phases; player-facing order is LEFT,DOWN,UP,RIGHT.
;   * Three distinct direction encodings are separated: ghost facing, Snapper facing and eaten-ghost route codes.
;   * Maze = 19 rows x 25 tile IDs.  Tile &07 is a power pellet and tile &0F is an ordinary pellet.
;   * The packed maze contains EXACTLY &CE/206 tile-&0F cells, proving why INITIAL_PELLETS is &CE.
;   * The four tile-&07 cells are the four corner energizers at rows 2/14, columns 0/24.
;   * Ordinary pellets have no separate map: screen RAM plus a 32-entry temporary occlusion cache is the pellet state.
;   * Moving sprites erase covered pellet pixels, remember their screen addresses, then restore uneaten pellets afterward.
;   * Mode-2 collision samplers reconstruct a four-bit logical colour from interleaved bitmap bitplanes.
;   * Eaten-ghost return map = 20 rows x 28 two-bit direction codes, 7 bytes per row.
;   * Hardware pacing uses User VIA Timer-1 in continuous PB7-toggle mode; later levels shorten its period.
;   * The programmed T1 latch is effectively &D1D1 at level 0 and &9595 at level 15+, about 18.6 to 26.1 ticks/sec.
;   * Frightened/tunnel ghosts use one PB7 phase only, giving half-normal movement cadence.
;   * &46 is the per-level ENERGIZER DURATION, not the main frame delay: it falls from &AF to a floor of &64.
;   * READY tune = 43 packed note bytes: bit 0 rest, bit 1 duration selector, bits 2..7 pitch.
;   * Sound call sites are classified: envelope 1=energizer, envelope 2=fruit/ghost eat; pellet/death use direct volume.
;   * Chained frightened-ghost awards are 200, 400, 800 and 1600 displayed points.
;   * Score = three packed-BCD bytes (six variable digits) plus a fixed trailing zero drawn in Mode 2 screen RAM.
;   * Top-Eight records are initially seeded to 1000 displayed points with blank CR-filled names.
;   * Logical colour &09 is deliberately palette-mapped to BLACK and used as an invisible ghost-house gate/collision marker.
;   * The gate is installed after READY at logical x=39..42, y=37 using Mode-2 byte &C3 (= colour 9 in both pixels).
;   * The nine-entry maze palette is fully decoded, including maze blue/white, frightened blue/white and pellet flash colours.
;   * Normal ghost body masks resolve to green, magenta, cyan and red for object slots 0..3 respectively.
;   * Masked-sprite headers are decoded: byte 0 = height-1; byte 1 selects 2/4/6/8-pixel width in &08 steps.
;   * Standard actors/fruits are 8x16 pixels; trail erasers are 2x16 and 8x4; death frames are 8x16,8x8,8x8,8x8,8x16.
;   * Maze tiles render as 6x12 pixels: only 36 of each fixed &30/48-byte record are consumed; 12 bytes are stride padding.
;   * The complete 16-tile visual atlas is documented in ASCII beside the tile graphics.
;   * Patrol script phases are decoded into the actual mirrored direction sequences followed by each ghost pair.
;   * Fruit progression by level is explicitly mapped: cherry, strawberry, orange, apple, melon, galaxian, bell, key.
;   * The central ghost-house region has a separate randomized exit rule before normal patrol/chase junction logic.
;   * Ordinary/power pellets are proven to award 10/50 points; all reachable score-award call sites are classified.
;   * Player/ghost collision is a +/-1 logical-coordinate box, with a special wrap-safe tunnel collision rule.
;   * No bonus-life award exists: spare_lives has only initialise/display/decrement references in reachable code.
;   * Ghost pursuit is now expressed as high-level pseudocode: all four ghosts share one player-relative heuristic, not four Pac-Man personalities.
;   * Junction probes are mapped exactly around the 8x16 actor box and onto the 3-unit maze decision lattice.
;   * Timer-1 "random" values are timing entropy, not a uniform PRNG; old 1/256 and 7/8 wording is corrected to byte/bit tests.
;   * A complete ASCII sprite atlas is generated from the exact bytes actually consumed by the compositor.
;   * Sprite storage has a six-byte unused trailer after headered records (eight after most raw eye planes), explaining many code-like tail bytes.
;   * Death frame &27 is corrected to 8x16; only middle death frames &24-&26 are 8x8.
;   * READY tune structure is resolved as A, A+4-pitch-units, A again, then a 13-note coda; post-tune bytes resemble an abandoned alternate coda.
;   * Paired stale wrappers at &2642/&2661 both jump to now-overwritten &2362, strong evidence of an earlier memory layout.
;   * The unreferenced &2666 modulo-three helper is an older one-opcode variant (BPL instead of live BCS), consistent with abandoned code.
;   * Several unreachable data blocks contain probable legacy implementation residue; they remain EQUB, never guessed live.
;
; Reverse-engineering rules used in this snapshot:
;   * Proven reachable machine code is emitted as 6502 instructions.
;   * Unresolved graphics/tables/text remain EQUB, never guessed into bogus instructions.
;   * Meaningful zero-page variables and routines are named where behaviour is supported by the code.
;   * MOD: comments identify deliberately useful tuning points without changing original behaviour.
;
; HIGH-LEVEL EXECUTION FLOW
; -------------------------
;   BASIC CALL &3283 / start:
;       relocate stored &3000-&32FF -> executable &0400-&06FF
;       initialise Top-Eight score/name workspace and SOUND parameter block
;       JMP &064F low_entry_after_relocation
;           -> start_new_game (&0FAE)
;           -> start_level (&0FD4): draw maze, reset pellets, program User VIA frame timer
;           -> start_life (&0FFD): draw lives/history, initialise actors, READY sequence
;           -> main_game_loop (&10CB): frame wait -> fruit/pellets -> draw -> collision -> input/AI -> movement
;              -> pellet/power-pellet consumption -> repeat
;       death with no spare lives returns into relocated Top-Eight qualification/name-entry/display code.
;
; -----------------------------------------------------------------------------
; MOS / hardware
; -----------------------------------------------------------------------------
OSWRCH                         = &FFEE
OSWORD                         = &FFF1
OSBYTE                         = &FFF4
OSBYTE_FLUSH_INPUT             = &0F       ; used before READY tune/name entry
OSBYTE_ACK_ESCAPE              = &7E       ; acknowledge/clear an Escape condition
OSBYTE_NEGATIVE_INKEY          = &81       ; keyboard test with negative internal key number
SYSVIA_ORB                     = &FE41
SYSVIA_IFR                     = &FE4D
USERVIA_ORB                    = &FE60
USERVIA_T1CL                   = &FE64
USERVIA_T1CH                   = &FE65
USERVIA_ACR                    = &FE6B
USERVIA_IER                    = &FE6E

; -----------------------------------------------------------------------------
; Game constants
; -----------------------------------------------------------------------------
RUNTIME_BASE                   = &0E00       ; relocated game base
BASIC_CALL_ENTRY               = &3283       ; BASIC CALL entry (main_entry label is emitted at this address)
PLAYER_INDEX                   = &04       ; object-array index for Snapper
GHOST_COUNT                    = &04       ; number of ghosts
OBJECT_COUNT                   = &05       ; four ghosts + Snapper
WALL_COLOUR                    = &08       ; playfield colour treated as solid
PELLET_BITMAP_BYTE             = &04       ; raw Mode-2 byte used for one half of an ordinary pellet (NOT logical colour 4)
GHOST_GATE_COLOUR               = &09       ; logical colour mapped to black: invisible one-way ghost-house collision gate
MODE2_LOGICAL9_PAIR             = &C3       ; both Mode-2 pixels decode as logical colour 9
MODE2_LOGICAL13_PAIR            = &F3       ; both Mode-2 pixels decode as logical colour 13 (magenta here)
INITIAL_SPARE_LIVES            = &02       ; MOD: 2 gives three total lives including current life
INITIAL_PELLETS                = &CE       ; MOD: ordinary pellets required per level
POWER_PELLETS_CLEARED_MASK     = &55       ; bits 1,3,5,7 cleared from initial &FF
INITIAL_ENERGIZER_DURATION      = &AF       ; MOD: frightened duration on level 1
ENERGIZER_DURATION_STEP         = &10       ; MOD: amount removed from frightened duration after each level
MIN_ENERGIZER_DURATION          = &64       ; MOD: shortest frightened duration
MAX_DIFFICULTY_LEVEL           = &10       ; level counter / tables cap at level 16
GHOST_EAT_SCORE_SEED           = &10       ; MOD: pre-double seed; awards become 200/400/800/1600 displayed points
PELLET_SCORE_BCD                = &01       ; internal units of ten -> 10 displayed points
POWER_PELLET_SCORE_BCD          = &05       ; internal units of ten -> 50 displayed points
COLLISION_AXIS_WINDOW           = &03       ; after +1 bias, accepts deltas -1,0,+1 on each axis
KEY_LEFT_Z                     = &9E       ; BBC negative-INKEY code for Z
KEY_RIGHT_X                    = &BD       ; BBC negative-INKEY code for X
KEY_DOWN_QUESTION              = &B7       ; BBC negative-INKEY code for ?
KEY_UP_ASTERISK                = &97       ; BBC negative-INKEY code for *
KEY_SPACE                      = &9D       ; BBC negative-INKEY code for SPACE

; BBC SOUND/OSWORD 7 channel values used by Snapper.  Bit &10 requests a flush of
; that channel before the new sound.  Positive amplitudes 1/2 select the two BASIC
; ENVELOPE definitions above; negative amplitudes are direct volume.
SOUND_CHANNEL_1                = &01
SOUND_CHANNEL_3                = &03
SOUND_CHANNEL_NOISE_FLUSH      = &10
SOUND_CHANNEL_1_FLUSH          = &11
SOUND_CHANNEL_2_FLUSH          = &12
SOUND_ENVELOPE_1               = &01
SOUND_ENVELOPE_2               = &02
SOUND_DIRECT_VOLUME_8          = &F8       ; signed -8
SOUND_DIRECT_VOLUME_12         = &F4       ; signed -12

; Cell / state values used by movement and collision code.
GHOST_STATE_NORMAL             = &00
GHOST_STATE_FRIGHTENED         = &80
GHOST_STATE_EATEN              = &FF
POWER_PELLET_CELL_VALUE        = &06
GHOST_HOME_X                   = &27
GHOST_HOME_Y                   = &28
GHOST_GATE_LEFT_X              = &27       ; x=39
GHOST_GATE_RIGHT_X             = &2A       ; x=42
GHOST_GATE_Y                   = &25       ; y=37
GHOST0_START_X                 = &2D       ; slots 0..2 begin across the pen at x=45,39,33 / y=31
GHOST1_START_X                 = &27
GHOST2_START_X                 = &21
GHOST012_START_Y               = &1F
GHOST3_START_X                 = &27       ; slot 3 starts at x=39,y=38
GHOST3_START_Y                 = &26
GHOST0_BODY_COLOUR_MASK        = &FF       ; Mode-2 pair logical &F -> palette physical green
GHOST1_BODY_COLOUR_MASK        = &33       ; Mode-2 pair logical &5 -> default magenta
GHOST2_BODY_COLOUR_MASK        = &FC       ; Mode-2 pair logical &E -> palette physical cyan
GHOST3_BODY_COLOUR_MASK        = &03       ; Mode-2 pair logical &1 -> default red
GHOST_HOME_ROUTE_BYTE_INDEX          = &42
PATROL_COUNT_BASE              = &0F       ; MOD: patrol-script steps at level 0; one fewer per level
ENERGIZER_FLASH_THRESHOLD      = &32       ; frightened colour begins flashing below this timer value
GHOST_EAT_PAUSE_FRAMES         = &0F       ; pause other actors after a frightened ghost is eaten

; Snapper actually uses THREE compact direction encodings.  Keeping them separate
; avoids a subtle but important decompilation error:
;   ghost facing / ghost sprite:  0=LEFT, 1=RIGHT, 2=DOWN, 3=UP
;   Snapper facing / sprite:      0=LEFT, 1=DOWN,  2=UP,   3=RIGHT
;   eaten-ghost return map:       0=DOWN, 1=RIGHT, 2=UP,   3=LEFT
; The player's unusual ordering falls naturally out of the very compact key-handling code.
; The return-map encoding is translated to dx/dy by route_dx_table/route_dy_table.
GHOST_FACING_LEFT              = &00
GHOST_FACING_RIGHT             = &01
GHOST_FACING_DOWN              = &02
GHOST_FACING_UP                = &03
PLAYER_FACING_LEFT             = &00
PLAYER_FACING_DOWN             = &01
PLAYER_FACING_UP               = &02
PLAYER_FACING_RIGHT            = &03
ROUTE_DOWN                     = &00
ROUTE_RIGHT                    = &01
ROUTE_UP                       = &02
ROUTE_LEFT                     = &03

; User VIA Timer-1 is configured to free-run and toggle PB7.  The main loop waits
; for PB7 to change, making this the game's frame clock.  Level 0 starts at &D1;
; each level reduces the timer byte by 4 until level 15 reaches &95.
VIA_ACR_T1_CONTINUOUS_PB7      = &C0
MAX_TIMER_SPEED_LEVEL          = &0F       ; MOD: level at which frame-speed increase stops
FRAME_TIMER_BASE               = &95       ; MOD: lower = faster at every level; higher = slower
FRAME_TIMER_LEVEL_SCALE        = &04       ; MOD: controls speed difference between early and late levels


; Fixed logical object/maze coordinates recovered from the initialisation and tile map.
PLAYER_START_X                 = &26
PLAYER_START_Y                 = &11
FRUIT_X                        = &27
FRUIT_Y                        = &11
POWER_PELLET_SPLIT_X           = &28       ; x below/above this selects left/right energizer pair
POWER_PELLET_SPLIT_Y           = &20       ; y below/above this selects top/bottom pair
POWER_PELLET_LEFT_X            = &03
POWER_PELLET_RIGHT_X           = &4B
POWER_PELLET_TOP_Y             = &10
POWER_PELLET_BOTTOM_Y          = &34
TUNNEL_Y                       = &20
TUNNEL_HALF_SPEED_LEFT_X       = &14
TUNNEL_HALF_SPEED_RIGHT_X      = &3C
TUNNEL_WRAP_LEFT_SENTINEL      = &FB
TUNNEL_WRAP_LEFT_DEST          = &54
TUNNEL_WRAP_RIGHT_SENTINEL     = &55
TUNNEL_WRAP_RIGHT_DEST         = &FC

; Packed values passed to set_palette_colour (high nibble = logical colour, low nibble
; becomes physical colour after XOR 7).  BBC physical colours are 0 black,1 red,2 green,3 yellow,
; 4 blue,5 magenta,6 cyan,7 white.  The important dynamic logical colours are therefore:
;   logical 8  -> blue (&83) / white (&80): level-complete maze flash
;   logical 9  -> black (&97): invisible ghost-house gate collision pixels
;   logical C  -> blue (&C3) / white (&C0): frightened-ghost late warning flash
;   logical 6  -> green (&65) / black (&67): power-pellet flash
; These palette changes animate already-drawn pixels without touching bitmap RAM.
PALETTE_MAZE_WHITE             = &80
PALETTE_MAZE_BLUE              = &83
PALETTE_FRIGHTENED_WHITE       = &C0
PALETTE_FRIGHTENED_BLUE        = &C3
PALETTE_LOGICAL6_GREEN          = &65
PALETTE_LOGICAL6_BLACK          = &67
PALETTE_POWER_PELLET_ON        = PALETTE_LOGICAL6_GREEN
PALETTE_POWER_PELLET_OFF       = PALETTE_LOGICAL6_BLACK

; Power-pellet state bits.  The four active bits start set in &FF and are cleared
; as pellets are eaten; completion therefore leaves POWER_PELLETS_CLEARED_MASK=&55.
POWER_PELLET_TOP_LEFT_BIT      = &02
POWER_PELLET_TOP_RIGHT_BIT     = &08
POWER_PELLET_BOTTOM_RIGHT_BIT  = &20
POWER_PELLET_BOTTOM_LEFT_BIT   = &80
POWER_PELLET_TOP_LEFT_CLEAR     = &FD
POWER_PELLET_TOP_RIGHT_CLEAR    = &F7
POWER_PELLET_BOTTOM_RIGHT_CLEAR = &DF
POWER_PELLET_BOTTOM_LEFT_CLEAR  = &7F

; Map/tile formats.
MAZE_ROW_COUNT                 = &13       ; 19 rows
MAZE_COLUMN_COUNT              = &19       ; 25 tile positions per row
MAZE_PACKED_BYTES_PER_ROW      = &0D       ; 13 bytes: 12 pairs + final high nibble
MAZE_LAST_PACKED_BYTE_OFFSET    = &0C
MAZE_TILE_COUNT                = &10       ; 16 tile definitions
MAZE_TILE_BYTES                = &30       ; 48-byte fixed stride per tile record
MAZE_TILE_GRID_STEP            = &03       ; logical x/y spacing between adjacent maze cells
MAZE_TILE_DRAW_WIDTH_PIXELS    = &06       ; three Mode-2 bytes x two pixels
MAZE_TILE_DRAW_HEIGHT          = &0C       ; 12 raster lines
MAZE_TILE_RENDERED_BYTES       = &24       ; 36 bytes actually consumed by draw_tile_block
MAZE_TILE_PADDING_BYTES        = &0C       ; 12 bytes skipped inside each 48-byte fixed-stride record
TILE_BLANK                     = &00
TILE_POWER_PELLET              = &07
TILE_PELLET                    = &0F       ; ordinary pellet; occurs exactly &CE (206) times in the 19x25 maze

; Eaten-ghost return-routing field: 20 rows x 28 cells.  Each byte stores four
; 2-bit directions in screen order, high pair first: DOWN,RIGHT,UP,LEFT = 0..3.
GHOST_ROUTE_ROW_COUNT          = &14       ; 20 rows
GHOST_ROUTE_COLUMNS            = &1C       ; 28 cells
GHOST_ROUTE_BYTES_PER_ROW      = &07

; Masked sprite ID map.  For a sprite used as the REQUESTED plane, its first two bytes are a compact header:
;   byte 0 = height minus one (so &0F => 16 scanlines, &07 => 8, &03 => 4)
;   byte 1 = final Mode-2 byte offset in &08 steps; width = 2 * (byte1/8 + 1) pixels.
; Thus the common &0F,&18 header is 8x16 pixels.  The requested plane skips this header; OR/source
; planes such as eyes and blank_sprite_source are raw pixel planes and intentionally have no header skip.
; IDs &00-&07 are the two normal-ghost body-mask phases; IDs &08-&0B are directional eye overlays;
; &0C/&0D are frightened frames.
SPRITE_GHOST_BODY_PHASE0_BASE  = &00
SPRITE_GHOST_BODY_PHASE1_BASE  = &04
SPRITE_GHOST_EYES_BASE         = &08
SPRITE_EYES_LEFT               = &08
SPRITE_EYES_RIGHT              = &09
SPRITE_EYES_DOWN               = &0A
SPRITE_EYES_UP                 = &0B
SPRITE_FRIGHTENED_FRAME0       = &0C
SPRITE_FRIGHTENED_FRAME1       = &0D
SPRITE_ERASE_HORIZONTAL_TRAIL  = &16
SPRITE_ERASE_VERTICAL_TRAIL    = &17
SPRITE_SNAPPER_BASE            = &18
SPRITE_PHASE_OFFSET            = &04
SPRITE_BLANK_SOURCE            = &21
SPRITE_BLANK_FULL              = &22
SPRITE_DEATH_FRAME0            = &23
SPRITE_DEATH_FRAME1            = &24
SPRITE_DEATH_FRAME2            = &25
SPRITE_DEATH_FRAME3            = &26
SPRITE_DEATH_FRAME4            = &27
SPRITE_POINTER_COUNT           = &28       ; IDs &00-&27

; READY tune byte format.
READY_TUNE_NOTE_COUNT          = &2B       ; 43 packed notes/rests
READY_TUNE_REST_BIT            = &01
READY_TUNE_LONG_NOTE_BIT       = &02
READY_TUNE_PITCH_MASK          = &FC
READY_TUNE_HARMONY_OFFSET      = &30

; Hidden pellet restoration table: 32 little-endian screen addresses.
HIDDEN_PELLET_SLOT_COUNT       = &20
HIDDEN_PELLET_ENTRY_BYTES      = &02
HIDDEN_PELLET_LAST_OFFSET      = &3E
HIDDEN_PELLET_CLEAR_LAST_BYTE   = &3F

; Mode 2 score bitmap.  Six packed-BCD digits are redrawn directly into screen
; RAM; a seventh, fixed zero is copied once per life because internal scores are
; stored in units of ten points.
MODE2_SCREEN_BASE              = &3000
SCORE_SCREEN_DIGITS            = &3320
SCORE_DIGIT_BYTES              = &20
SCORE_VARIABLE_DIGIT_COUNT     = &06
SCORE_FIXED_ZERO_SCREEN_CELL   = &33E0

; Fruit sprite numbers.  The score table proves the classic 100/300/500/700/
; 1000/2000/3000/5000 progression.
FRUIT_STRAWBERRY               = &0E       ; 300 points
FRUIT_CHERRY                   = &0F       ; 100 points
FRUIT_ORANGE                   = &10       ; 500 points
FRUIT_APPLE                    = &11       ; 700 points
FRUIT_MELON                    = &12       ; 1000 points
FRUIT_KEY                      = &13       ; 5000 points
FRUIT_BELL                     = &14       ; 3000 points
FRUIT_GALAXIAN                 = &15       ; 2000 points
FIRST_FRUIT_SPRITE             = FRUIT_STRAWBERRY

; Sprite &27 deliberately begins at &1DB6, the high-byte operand of the JMP at
; &1DB4.  The byte &0F doubles as the final death frame's width header.
sprite_death_frame4_data       = &1DB6

; Top-Eight workspace created by the &3283 bootstrap after relocation.
HIGH_SCORE_ENTRY_BYTES         = &03       ; three packed-BCD bytes per score
HIGH_SCORE_DISPLAY_COUNT       = &08
HIGH_SCORE_INSERTION_OFFSET    = &00       ; temporary candidate record
HIGH_SCORE_LOWEST_OFFSET       = &03       ; displayed rank 8, used as qualification threshold
HIGH_SCORE_DISPLAY_FIRST       = &18       ; byte offset 24 = highest displayed entry
HIGH_SCORE_SORT_END            = &1B       ; byte offset 27 terminates the insertion pass
HIGH_SCORE_NAME_BYTES          = &14       ; 20 bytes reserved per name
INITIAL_HIGH_SCORE_BCD_MID     = &01       ; records start as 000100 internal -> displayed as 1000 points
HIGH_SCORE_INPUT_BLOCK         = &07E0
HIGH_SCORE_INPUT_BUFFER        = &07E5
HIGH_SCORE_MAX_NAME_CHARS      = &13       ; OSWORD 0 accepts at most 19 typed chars
ASCII_SPACE                    = &20
ASCII_TILDE                    = &7E
ASCII_CR                       = &0D

; -----------------------------------------------------------------------------
; Zero-page / game workspace
; Arrays use object index 0..3 = ghosts, 4 = Snapper unless noted otherwise.
; -----------------------------------------------------------------------------
scratch0                       = &00
scratch1                       = &01
object_x                       = &02 ; 5-byte X-position array
object_y                       = &07 ; 5-byte Y-position array
object_sprite_base              = &0C ; base sprite ID: ghosts=&00, Snapper=&18
sprite_and_mask                = &13
scratch14                      = &14
legacy_workspace_11            = &11 ; cleared at each life but no proven read in reachable code
legacy_workspace_12            = &12 ; cleared at each life but no proven read in reachable code
object_colour_mask              = &15 ; per-object AND mask; gives the four ghosts distinct body colours
sprite_id                      = &1A
object_facing                  = &1F       ; ghosts: L,R,D,U = 0,1,2,3; slot 4 (Snapper): L,D,U,R = 0,1,2,3
object_dx                      = &24 ; signed horizontal step per object
object_dy                      = &29 ; signed vertical step per object
object_probe_offset            = &2E
scratch33                      = &33
score_bcd_lo                   = &34 ; packed BCD score byte
score_bcd_mid                  = &35 ; packed BCD score byte
score_bcd_hi                   = &36 ; packed BCD score byte
score_leading_zero_state       = &37
fruit_sprite_id                = &38
animation_counter              = &39
palette_phase                  = &3A
fruit_timer_lo                 = &3B
fruit_timer_hi                 = &3C
level_number                   = &3D
pellets_remaining              = &3E ; ordinary pellets only
power_pellet_flags             = &3F ; starts &FF; four pellet bits are cleared as eaten
energizer_timer                = &40 ; vulnerable-ghost duration timer
object_state                   = &41 ; ghost normal/vulnerable/eaten state; slot 4 also initialised
energizer_duration_for_level    = &46 ; copied to energizer_timer when a power pellet is eaten
frightened_sprite_phase         = &47
energizer_flash_phase          = &48
ghost_eat_score_bcd            = &49
movement_pause_timer           = &4A
ghost_route_direction          = &4B
ready_sequence_done            = &4F
spare_lives                    = &50 ; decremented after death; negative = game over
ghost_patrol_counter           = &51 ; per-ghost corner-patrol/chase countdown
ghost_route_phase              = &55
object_move_bypass              = &59 ; nonzero forces next move past half-speed PB7 throttle
sound_channel_lo               = &5D
sound_channel_hi               = &5E
sound_amplitude_lo             = &5F
sound_amplitude_hi             = &60
sound_pitch_lo                 = &61
sound_pitch_hi                 = &62
sound_duration_lo              = &63
sound_duration_hi              = &64
sound_sweep_pitch              = &65
delay_last_clock_tick          = &66
delay_ticks_remaining          = &67
pellet_addr_lo                 = &68
pellet_addr_hi                 = &69
ready_tune_played              = &6A
coord_x                        = &70
coord_y                        = &71
scratch72                      = &72
saved_y                        = &73
screen_y_work                  = &74
screen_addr_work_lo            = &75
screen_addr_work_hi            = &76
source_ptr_lo                  = &7E
source_ptr_hi                  = &7F
sprite_ptr_lo                  = &80
sprite_ptr_hi                  = &81
screen_ptr_lo                  = &82
screen_ptr_hi                  = &83
requested_sprite_id            = &84

; Fixed aliases for object slot 4 (Snapper).  These make direct accesses to the
; fifth element of the parallel object arrays readable without changing layout.
player_x                       = object_x + PLAYER_INDEX
player_y                       = object_y + PLAYER_INDEX
player_sprite_base                    = object_sprite_base + PLAYER_INDEX
player_colour_mask              = object_colour_mask + PLAYER_INDEX
player_facing                  = object_facing + PLAYER_INDEX
player_dx                      = object_dx + PLAYER_INDEX
player_dy                      = object_dy + PLAYER_INDEX
player_probe_offset            = object_probe_offset + PLAYER_INDEX

ghost3_x                       = object_x + 3
ghost3_y                       = object_y + 3
ghost0_colour_mask             = object_colour_mask + 0
ghost1_colour_mask             = object_colour_mask + 1
ghost2_colour_mask             = object_colour_mask + 2
ghost3_colour_mask             = object_colour_mask + 3

; Low-memory execution addresses after the &3000-&32FF copy.
high_score_messages_exec       = &0400
high_score_congratulations_exec = &0401
high_score_scores_length_exec  = &048B
high_score_scores_text_exec    = &048C
high_score_not_qualifying_exec = &04A7
high_score_handler_exec        = &04AA
high_score_sort_loop_exec      = &052D
display_high_scores_exec       = &05B7
wait_for_space_after_scores_exec = &0648
low_entry_after_relocation     = &064F
print_bcd_byte_exec            = &0655
high_score_bcd_table           = &06D0
high_score_name_pointer_table  = &06EE
high_score_swap_temp           = &070C
high_score_input_block_addr    = HIGH_SCORE_INPUT_BLOCK
high_score_input_buffer_addr   = HIGH_SCORE_INPUT_BUFFER
high_score_source_page1        = &3100
high_score_source_page2        = &3200
high_score_exec_page1          = &0500
high_score_exec_page2          = &0600
high_score_name_storage_base   = &070B

; Deliberate/legacy overlapping-entry points in the original binary.
; &0FEE starts in the operand bytes of the normal &0FED "STA USERVIA_T1CH".
; Entered from hidden-pellet-cache overflow it decodes instead as:
;     ADC &FE
;     STA USERVIA_T1CL
; then falls into the normal table-clear code at &0FF3 and ultimately start_life.
; This bizarre overlapping emergency path is original code and is retained exactly.
hidden_pellet_overflow_recovery = &0FEE
; This branch target is the &00 operand byte inside the LDA at &1C32.  It is a
; BRK if ever reached.  The branch is retained exactly: it appears to be a dead/impossible-state trap in the original.
ghost_tunnel_dead_brk_entry    = &1C34

ORG RUNTIME_BASE


; =============================================================================
; SCREEN ADDRESSING, SPRITE COMPOSITION AND CORE GAME CODE
; =============================================================================

    EQUB &0D,&FF                                                         ; &0E00  ..
; -----------------------------------------------------------------------------
; Convert logical playfield X/Y in coord_x/coord_y to the BBC bitmap address in screen_ptr.
; Carry is set on an out-of-range X coordinate.
; -----------------------------------------------------------------------------
screen_address_from_xy:
    LDA coord_x                        ; &0E02  A5 70
    CMP #&50                           ; &0E04  C9 50
    BCS screen_address_done                       ; &0E06  B0 45
    LDA #&0C                           ; &0E08  A9 0C
    STA screen_ptr_hi                  ; &0E0A  85 83
    LDA coord_x                        ; &0E0C  A5 70
    ASL A                              ; &0E0E  0A
    STA screen_ptr_lo                  ; &0E0F  85 82
    ROL screen_ptr_lo                  ; &0E11  26 82
    ROL screen_ptr_hi                  ; &0E13  26 83
    ROL screen_ptr_lo                  ; &0E15  26 82
    ROL screen_ptr_hi                  ; &0E17  26 83
    LDA coord_y                        ; &0E19  A5 71
    ASL A                              ; &0E1B  0A
    ASL A                              ; &0E1C  0A
    EOR #&FF                           ; &0E1D  49 FF
    STA screen_y_work                  ; &0E1F  85 74
    INC screen_y_work                  ; &0E21  E6 74
    INC screen_y_work                  ; &0E23  E6 74
    LDA screen_y_work                  ; &0E25  A5 74
finish_screen_address_calculation:
    AND #&07                           ; &0E27  29 07
    ASL A                              ; &0E29  0A
    STA screen_addr_work_lo            ; &0E2A  85 75
    LDA screen_y_work                  ; &0E2C  A5 74
    AND #&F8                           ; &0E2E  29 F8
    LSR A                              ; &0E30  4A
    LSR A                              ; &0E31  4A
    STA screen_addr_work_hi            ; &0E32  85 76
    LSR A                              ; &0E34  4A
    LSR A                              ; &0E35  4A
    ROR screen_addr_work_lo            ; &0E36  66 75
    CLC                                ; &0E38  18
    ADC screen_addr_work_hi            ; &0E39  65 76
    CLC                                ; &0E3B  18
    ADC screen_ptr_hi                  ; &0E3C  65 83
    STA screen_ptr_hi                  ; &0E3E  85 83
    CLC                                ; &0E40  18
    LDA screen_addr_work_lo            ; &0E41  A5 75
    ADC screen_ptr_lo                  ; &0E43  65 82
    STA screen_ptr_lo                  ; &0E45  85 82
    LDA screen_ptr_hi                  ; &0E47  A5 83
    ADC #&00                           ; &0E49  69 00
    STA screen_ptr_hi                  ; &0E4B  85 83
screen_address_done:
    RTS                                ; &0E4D  60
pixel_bit_masks:
    EQUB &01,&02,&04,&08                                                 ; &0E4E  ....
return_zero:
    LDA #&00                           ; &0E52  A9 00
    RTS                                ; &0E54  60
; -----------------------------------------------------------------------------
; Sample the logical colour/occupancy encoded in Mode 2 bitmap RAM at coord_x/coord_y.
; Mode 2 interleaves the four colour bits across one byte.  This routine proves the exact packing:
;   first sampled pixel     = raw bits 1,3,5,7 -> logical bits 0,1,2,3
;   companion sampled pixel = raw bits 0,2,4,6 -> logical bits 0,1,2,3
; Thus raw &C3 decodes as logical 9/9, while raw &04 is 0/2 (the half-pellet byte).
; The first loop shifts the byte while gathering one bitplane into scratch72; if that is WALL_COLOUR it returns
; immediately.  Otherwise the routine backs the screen pointer by eight bytes and
; reconstructs the companion pixel's four-bit logical colour.
; Movement treats logical colour WALL_COLOUR (&08) as an impassable maze wall.
; -----------------------------------------------------------------------------
read_playfield_colour:
    JSR screen_address_from_xy         ; &0E55  20 02 0E
    BCS return_zero                    ; &0E58  B0 F8
    STY saved_y                        ; &0E5A  84 73
    LDY #&00                           ; &0E5C  A0 00
    STY scratch72                      ; &0E5E  84 72
    LDA (screen_ptr_lo),Y              ; &0E60  B1 82
sample_first_mode2_pixel_bits:
    LSR A                              ; &0E62  4A
    STA scratch14                      ; &0E63  85 14
    AND pixel_bit_masks,Y              ; &0E65  39 4E 0E
    ORA scratch72                      ; &0E68  05 72
    STA scratch72                      ; &0E6A  85 72
    LDA scratch14                      ; &0E6C  A5 14
    INY                                ; &0E6E  C8
    CPY #&04                           ; &0E6F  C0 04
    BNE sample_first_mode2_pixel_bits    ; &0E71  D0 EF
    LDY saved_y                        ; &0E73  A4 73
    LDA scratch72                      ; &0E75  A5 72
    CMP #&08                           ; &0E77  C9 08
    BNE sample_companion_mode2_pixel     ; &0E79  D0 01
    RTS                                ; &0E7B  60
sample_companion_mode2_pixel:
    LDA screen_ptr_lo                  ; &0E7C  A5 82
    SEC                                ; &0E7E  38
    SBC #&08                           ; &0E7F  E9 08
    STA screen_ptr_lo                  ; &0E81  85 82
    BCS begin_companion_mode2_sample     ; &0E83  B0 02
    DEC screen_ptr_hi                  ; &0E85  C6 83
begin_companion_mode2_sample:
    LDY #&00                           ; &0E87  A0 00
    STY scratch72                      ; &0E89  84 72
    LDA (screen_ptr_lo),Y              ; &0E8B  B1 82
sample_companion_mode2_pixel_bits:
    STA scratch14                      ; &0E8D  85 14
    AND pixel_bit_masks,Y              ; &0E8F  39 4E 0E
    ORA scratch72                      ; &0E92  05 72
    STA scratch72                      ; &0E94  85 72
    LDA scratch14                      ; &0E96  A5 14
    LSR A                              ; &0E98  4A
    INY                                ; &0E99  C8
    CPY #&04                           ; &0E9A  C0 04
    BNE sample_companion_mode2_pixel_bits ; &0E9C  D0 EF
    LDY saved_y                        ; &0E9E  A4 73
    LDA scratch72                      ; &0EA0  A5 72
    RTS                                ; &0EA2  60
; -----------------------------------------------------------------------------
; Play the short READY/start-of-life tune from 43 packed bytes.
; bit 0=rest (amplitude 0 instead of fixed -12), bit 1 selects duration 1/2,
; bits 2..7 are pitch.  Channel 3 mirrors channel 1 one octave-like interval
; lower (pitch - &30).
; -----------------------------------------------------------------------------
play_ready_tune:
    LDX #&00                           ; &0EA3  A2 00
    STX sound_duration_hi              ; &0EA5  86 64
    DEX                                ; &0EA7  CA
    STX sound_amplitude_hi             ; &0EA8  86 60
    INX                                ; &0EAA  E8
    LDA #OSBYTE_FLUSH_INPUT             ; &0EAB  A9 0F
    JSR OSBYTE                         ; &0EAD  20 F4 FF
    LDY #&00                           ; &0EB0  A0 00
ready_tune_next_note:
    STY scratch14                      ; &0EB2  84 14
    LDA ready_tune_notes,Y              ; &0EB4  B9 B8 2F
    STA scratch33                      ; &0EB7  85 33
    LDX #SOUND_DIRECT_VOLUME_12          ; &0EB9  A2 F4
    AND #READY_TUNE_REST_BIT          ; &0EBB  29 01
    BEQ ready_tune_decode_duration                       ; &0EBD  F0 02
    LDX #&00                           ; &0EBF  A2 00
ready_tune_decode_duration:
    LDA scratch33                      ; &0EC1  A5 33
    AND #READY_TUNE_LONG_NOTE_BIT     ; &0EC3  29 02
    LSR A                              ; &0EC5  4A
    ADC #&01                           ; &0EC6  69 01
    STA sound_duration_lo              ; &0EC8  85 63
    LDA scratch33                      ; &0ECA  A5 33
    AND #READY_TUNE_PITCH_MASK        ; &0ECC  29 FC
    LDY #SOUND_CHANNEL_1                 ; &0ECE  A0 01
    JSR play_sound                     ; &0ED0  20 6D 1D
    LDX sound_amplitude_lo             ; &0ED3  A6 5F
    LDY #SOUND_CHANNEL_3                 ; &0ED5  A0 03
    LDA sound_pitch_lo                 ; &0ED7  A5 61
    SEC                                ; &0ED9  38
    SBC #READY_TUNE_HARMONY_OFFSET    ; &0EDA  E9 30
    JSR play_sound                     ; &0EDC  20 6D 1D
    LDY scratch14                      ; &0EDF  A4 14
    INY                                ; &0EE1  C8
    CPY #READY_TUNE_NOTE_COUNT        ; &0EE2  C0 2B
    BNE ready_tune_next_note                       ; &0EE4  D0 CC
    DEC sound_duration_hi              ; &0EE6  C6 64
    INC sound_amplitude_hi             ; &0EE8  E6 60
    LDA #&FF                           ; &0EEA  A9 FF
    STA sound_duration_lo              ; &0EEC  85 63
    STA ready_tune_played              ; &0EEE  85 6A
    RTS                                ; &0EF0  60
; -----------------------------------------------------------------------------
; Test one BBC keyboard key using OSBYTE &81 (INKEY-style negative key number).
; Input: X = negative key code.  Returns Z set when the key is not pressed.
; -----------------------------------------------------------------------------
test_key:
    PHA                                ; &0EF1  48
    TYA                                ; &0EF2  98
    PHA                                ; &0EF3  48
    LDA #OSBYTE_NEGATIVE_INKEY          ; &0EF4  A9 81
    LDY #&FF                           ; &0EF6  A0 FF
    JSR OSBYTE                         ; &0EF8  20 F4 FF
    PLA                                ; &0EFB  68
    TAY                                ; &0EFC  A8
    PLA                                ; &0EFD  68
    CPX #&00                           ; &0EFE  E0 00
shared_sprite_key_return:
    RTS                                ; &0F00  60
; -----------------------------------------------------------------------------
; Generic sprite compositor.  The requested sprite supplies the geometry and first pixel plane;
; output byte = (requested_plane AND sprite_and_mask) OR source_plane.
; Normal ghosts use body-mask IDs &00-&07, AND with object_colour_mask, then OR directional eye IDs &08-&0B.
; Snapper/frightened/death graphics instead use a blank source plane.  Eaten ghosts use blank requested geometry plus
; an eye overlay.  If drawing covers a pellet byte, its address is remembered so the pellet can be restored afterward.
; -----------------------------------------------------------------------------
draw_masked_sprite:
    STA requested_sprite_id            ; &0F01  85 84
    CMP #&16                           ; &0F03  C9 16
    BEQ sprite_check_narrow_x_limit                       ; &0F05  F0 09
    LDA coord_x                        ; &0F07  A5 70
    CMP #&4C                           ; &0F09  C9 4C
    BCS shared_sprite_key_return                       ; &0F0B  B0 F3
    JMP sprite_begin_composition                       ; &0F0D  4C 16 0F
sprite_check_narrow_x_limit:
    LDA coord_x                        ; &0F10  A5 70
    CMP #&50                           ; &0F12  C9 50
    BCS shared_sprite_key_return                       ; &0F14  B0 EA
sprite_begin_composition:
    STY saved_y                        ; &0F16  84 73
    JSR screen_address_from_xy         ; &0F18  20 02 0E
    LDA requested_sprite_id            ; &0F1B  A5 84
    ASL A                              ; &0F1D  0A
    TAX                                ; &0F1E  AA
    LDA masked_sprite_pointer_table,X  ; &0F1F  BD 60 25
    STA sprite_ptr_lo                  ; &0F22  85 80
    LDA masked_sprite_pointer_table+1,X  ; &0F24  BD 61 25
    STA sprite_ptr_hi                  ; &0F27  85 81
    LDA sprite_id                      ; &0F29  A5 1A
    ASL A                              ; &0F2B  0A
    TAX                                ; &0F2C  AA
    LDA masked_sprite_pointer_table,X  ; &0F2D  BD 60 25
    STA source_ptr_lo                  ; &0F30  85 7E
    LDA masked_sprite_pointer_table+1,X  ; &0F32  BD 61 25
    STA source_ptr_hi                  ; &0F35  85 7F
    LDY #&00                           ; &0F37  A0 00
    LDA (sprite_ptr_lo),Y              ; &0F39  B1 80
    TAX                                ; &0F3B  AA
    INY                                ; &0F3C  C8
    LDA (sprite_ptr_lo),Y              ; &0F3D  B1 80
    TAY                                ; &0F3F  A8
    STY scratch14                      ; &0F40  84 14
    INY                                ; &0F42  C8
    STY scratch33                      ; &0F43  84 33
    INC sprite_ptr_lo                  ; &0F45  E6 80
    BNE advance_requested_sprite_past_header                       ; &0F47  D0 02
    INC sprite_ptr_hi                  ; &0F49  E6 81
advance_requested_sprite_past_header:
    INC sprite_ptr_lo                  ; &0F4B  E6 80
    BNE begin_sprite_column                       ; &0F4D  D0 02
    INC sprite_ptr_hi                  ; &0F4F  E6 81
begin_sprite_column:
    LDY scratch14                      ; &0F51  A4 14
sprite_column_scanline_loop:
    LDA (screen_ptr_lo),Y              ; &0F53  B1 82
    CMP #PELLET_BITMAP_BYTE             ; &0F55  C9 04
    BNE sprite_compose_pixel_byte                       ; &0F57  D0 03
    JSR remember_pellet_under_sprite   ; &0F59  20 7C 1D
sprite_compose_pixel_byte:
    LDA (sprite_ptr_lo),Y              ; &0F5C  B1 80
    AND sprite_and_mask                ; &0F5E  25 13
    ORA (source_ptr_lo),Y              ; &0F60  11 7E
    STA (screen_ptr_lo),Y              ; &0F62  91 82
    TYA                                ; &0F64  98
    SEC                                ; &0F65  38
    SBC #&08                           ; &0F66  E9 08
    TAY                                ; &0F68  A8
    BPL sprite_column_scanline_loop                       ; &0F69  10 E8
    DEX                                ; &0F6B  CA
    BMI sprite_draw_done                       ; &0F6C  30 3B
    INC source_ptr_lo                  ; &0F6E  E6 7E
    INC sprite_ptr_lo                  ; &0F70  E6 80
    LDY sprite_ptr_lo                  ; &0F72  A4 80
    TYA                                ; &0F74  98
    AND #&07                           ; &0F75  29 07
    BNE sprite_advance_screen_column                       ; &0F77  D0 18
    DEY                                ; &0F79  88
    TYA                                ; &0F7A  98
    CLC                                ; &0F7B  18
    ADC scratch33                      ; &0F7C  65 33
    STA sprite_ptr_lo                  ; &0F7E  85 80
    BCC adjust_source_plane_after_row_boundary                       ; &0F80  90 02
    INC sprite_ptr_hi                  ; &0F82  E6 81
adjust_source_plane_after_row_boundary:
    LDY source_ptr_lo                  ; &0F84  A4 7E
    DEY                                ; &0F86  88
    TYA                                ; &0F87  98
    CLC                                ; &0F88  18
    ADC scratch33                      ; &0F89  65 33
    STA source_ptr_lo                  ; &0F8B  85 7E
    BCC sprite_advance_screen_column                       ; &0F8D  90 02
    INC source_ptr_hi                  ; &0F8F  E6 7F
sprite_advance_screen_column:
    INC screen_ptr_lo                  ; &0F91  E6 82
    LDY screen_ptr_lo                  ; &0F93  A4 82
    TYA                                ; &0F95  98
    AND #&07                           ; &0F96  29 07
    BNE begin_sprite_column                       ; &0F98  D0 B7
    DEY                                ; &0F9A  88
    TYA                                ; &0F9B  98
    CLC                                ; &0F9C  18
    ADC #&79                           ; &0F9D  69 79
    STA screen_ptr_lo                  ; &0F9F  85 82
    LDA screen_ptr_hi                  ; &0FA1  A5 83
    ADC #&02                           ; &0FA3  69 02
    STA screen_ptr_hi                  ; &0FA5  85 83
    BCC begin_sprite_column                       ; &0FA7  90 A8
sprite_draw_done:
    LDY saved_y                        ; &0FA9  A4 73
    LDA #&00                           ; &0FAB  A9 00
    RTS                                ; &0FAD  60
; -----------------------------------------------------------------------------
; New-game initialisation. Clears score/level state, establishes three lives, draws the maze and enters the first life.
; -----------------------------------------------------------------------------
start_new_game:
    LDA #&C0                           ; &0FAE  A9 C0
    STA USERVIA_ACR                    ; &0FB0  8D 6B FE
    LDA #&00                           ; &0FB3  A9 00
    STA USERVIA_IER                    ; &0FB5  8D 6E FE
    LDA #&00                           ; &0FB8  A9 00
    STA ready_tune_played              ; &0FBA  85 6A
    LDY #INITIAL_ENERGIZER_DURATION     ; &0FBC  A0 AF  | MOD: Initial frightened-ghost duration; larger lasts longer.
    STY energizer_duration_for_level              ; &0FBE  84 46
    LDY #&00                           ; &0FC0  A0 00
    STY movement_pause_timer           ; &0FC2  84 4A
    STY frightened_sprite_phase         ; &0FC4  84 47
    STY energizer_flash_phase          ; &0FC6  84 48
    STY score_bcd_lo                   ; &0FC8  84 34
    STY score_bcd_mid                  ; &0FCA  84 35
    STY score_bcd_hi                   ; &0FCC  84 36
    STY level_number                   ; &0FCE  84 3D
    LDA #INITIAL_SPARE_LIVES           ; &0FD0  A9 02  | MOD: Spare lives; 2 means three lives including the life currently in play.
    STA spare_lives                    ; &0FD2  85 50
start_level:
    JSR draw_maze_and_screen           ; &0FD4  20 60 19
    LDA #&FF                           ; &0FD7  A9 FF
    STA power_pellet_flags             ; &0FD9  85 3F
    LDA #INITIAL_PELLETS               ; &0FDB  A9 CE  | MOD: Number of ordinary pellets required before a level can finish.
    STA pellets_remaining              ; &0FDD  85 3E
    LDA level_number                   ; &0FDF  A5 3D
    CMP #MAX_DIFFICULTY_LEVEL                           ; &0FE1  C9 10
    BCC program_level_frame_timer                       ; &0FE3  90 02
    LDA #MAX_TIMER_SPEED_LEVEL                           ; &0FE5  A9 0F
program_level_frame_timer:
    ; Timer byte = &95 + 4*(15-min(level,15)).  After the two register writes the
    ; continuous reload latch is effectively VV, so level 0 settles at &D1D1 (~53.7 ms,
    ; ~18.6 PB7 transitions/sec) and level 15+ at &9595 (~38.3 ms, ~26.1/sec).
    ; The very first interval can inherit the old low latch; steady-state gameplay uses VV.
    EOR #MAX_TIMER_SPEED_LEVEL                           ; &0FE7  49 0F
    ASL A                              ; &0FE9  0A
    ASL A                              ; &0FEA  0A
    ADC #FRAME_TIMER_BASE                           ; &0FEB  69 95
    STA USERVIA_T1CH                   ; &0FED  8D 65 FE
    STA USERVIA_T1CL                   ; &0FF0  8D 64 FE
    LDA #&00                           ; &0FF3  A9 00
    LDY #HIDDEN_PELLET_CLEAR_LAST_BYTE                           ; &0FF5  A0 3F
clear_hidden_pellet_table:
    STA hidden_pellet_address_table,Y  ; &0FF7  99 C0 25
    DEY                                ; &0FFA  88
    BPL clear_hidden_pellet_table                       ; &0FFB  10 FA
start_life:
    LDA #&21                           ; &0FFD  A9 21
    STA sprite_id                      ; &0FFF  85 1A
    LDA #&FF                           ; &1001  A9 FF
    STA sprite_and_mask                ; &1003  85 13
    LDA #&40                           ; &1005  A9 40
    STA coord_y                        ; &1007  85 71
    LDA #&31                           ; &1009  A9 31
    STA coord_x                        ; &100B  85 70
    LDA #&22                           ; &100D  A9 22
    JSR draw_masked_sprite             ; &100F  20 01 0F
    LDA #&36                           ; &1012  A9 36
    STA coord_x                        ; &1014  85 70
    LDA #&22                           ; &1016  A9 22
    JSR draw_masked_sprite             ; &1018  20 01 0F
    LDY spare_lives                    ; &101B  A4 50
    BEQ draw_fruit_history                       ; &101D  F0 19
    CPY #&02                           ; &101F  C0 02
    BCC draw_next_spare_life                       ; &1021  90 02
    LDY #&02                           ; &1023  A0 02
draw_next_spare_life:
    TYA                                ; &1025  98
    STA scratch14                      ; &1026  85 14
    ASL A                              ; &1028  0A
    ASL A                              ; &1029  0A
    ADC scratch14                      ; &102A  65 14
    ADC #&2C                           ; &102C  69 2C
    STA coord_x                        ; &102E  85 70
    LDA #SPRITE_SNAPPER_BASE                           ; &1030  A9 18
    JSR draw_masked_sprite             ; &1032  20 01 0F
    DEY                                ; &1035  88
    BNE draw_next_spare_life                       ; &1036  D0 ED
draw_fruit_history:
    LDY level_number                   ; &1038  A4 3D
    LDA #&3C                           ; &103A  A9 3C
    STA coord_x                        ; &103C  85 70
    LDX #&04                           ; &103E  A2 04
    STX scratch0                       ; &1040  86 00
draw_next_fruit_history_icon:
    LDA level_fruit_sprite_table,Y     ; &1042  B9 47 26
    JSR draw_masked_sprite             ; &1045  20 01 0F
    LDA coord_x                        ; &1048  A5 70
    CLC                                ; &104A  18
    ADC #&05                           ; &104B  69 05
    STA coord_x                        ; &104D  85 70
    DEY                                ; &104F  88
    BMI initialise_life_state                       ; &1050  30 04
    DEC scratch0                       ; &1052  C6 00
    BNE draw_next_fruit_history_icon                       ; &1054  D0 EC
initialise_life_state:
    LDA #&00                           ; &1056  A9 00
    STA energizer_timer                ; &1058  85 40
    STA legacy_workspace_11             ; &105A  85 11
    STA legacy_workspace_12             ; &105C  85 12
    LDY #&04                           ; &105E  A0 04
clear_object_states:
    STA object_state,Y                 ; &1060  99 41 00
    DEY                                ; &1063  88
    BPL clear_object_states                       ; &1064  10 FA
    STA ready_sequence_done            ; &1066  85 4F
    STA fruit_sprite_id                ; &1068  85 38
    STA palette_phase                  ; &106A  85 3A
    STA animation_counter              ; &106C  85 39
    STA player_facing                  ; &106E  85 23
    STA player_dy                      ; &1070  85 2D
    LDY #&1F                           ; &1072  A0 1F
copy_fixed_score_zero:
    LDA score_digit_graphics,Y         ; &1074  B9 00 24
    STA score_fixed_trailing_zero_screen_cell,Y    ; &1077  99 E0 33
    DEY                                ; &107A  88
    BPL copy_fixed_score_zero                       ; &107B  10 F7
    LDA #PLAYER_START_Y                 ; &107D  A9 11
    STA player_y                       ; &107F  85 0B
    LDA #SPRITE_SNAPPER_BASE                           ; &1081  A9 18
    STA player_sprite_base                    ; &1083  85 10
    LDY #&02                           ; &1085  A0 02
    LDX #&1B                           ; &1087  A2 1B
initialise_central_ghosts:
    ; Y counts 2,1,0 while X advances by six: slot2=(33,31), slot1=(39,31), slot0=(45,31).
    ; Slot3 is then placed separately at (39,38), directly below/above the central pen depending screen orientation.
    LDA #GHOST012_START_Y               ; &1089  A9 1F
    STA object_y,Y                     ; &108B  99 07 00
    TXA                                ; &108E  8A
    CLC                                ; &108F  18
    ADC #&06                           ; &1090  69 06
    TAX                                ; &1092  AA
    STA object_x,Y                     ; &1093  99 02 00
    DEY                                ; &1096  88
    BPL initialise_central_ghosts                       ; &1097  10 F0
    STY player_dx                      ; &1099  84 28
    STY object_colour_mask              ; &109B  84 15  | Y=&FF = GHOST0_BODY_COLOUR_MASK
    STY player_colour_mask              ; &109D  84 19
    LDX #PLAYER_START_X                 ; &109F  A2 26
    STX ghost3_y                            ; &10A1  86 0A
    STX player_x                       ; &10A3  86 06
    INX                                ; &10A5  E8
    STX ghost3_x                            ; &10A6  86 05
    LDA #GHOST1_BODY_COLOUR_MASK        ; &10A8  A9 33
    STA ghost1_colour_mask                            ; &10AA  85 16
    LDY #&04                           ; &10AC  A0 04
    STY player_probe_offset            ; &10AE  84 32
    DEY                                ; &10B0  88
    STY ghost3_colour_mask                            ; &10B1  84 18  | Y=&03 = GHOST3_BODY_COLOUR_MASK
initialise_ghost_motion:
    LDX #&02                           ; &10B3  A2 02
    STX object_facing,Y                ; &10B5  96 1F
    DEX                                ; &10B7  CA
    STX object_dy,Y                    ; &10B8  96 29
    DEX                                ; &10BA  CA
    STX ghost_patrol_counter,Y         ; &10BB  96 51
    STX object_dx,Y                    ; &10BD  96 24
    STX object_sprite_base,Y                  ; &10BF  96 0C
    LDA #GHOST2_BODY_COLOUR_MASK        ; &10C1  A9 FC
    STA object_probe_offset,Y          ; &10C3  99 2E 00
    STA ghost2_colour_mask                            ; &10C6  85 17
    DEY                                ; &10C8  88
    BPL initialise_ghost_motion                       ; &10C9  10 E8
; -----------------------------------------------------------------------------
; Main per-frame game loop.  User VIA Timer-1 is free-running with PB7 toggle enabled; the wait below blocks until
; PB7 changes state.  The same PB7 phase is later used to halve frightened/tunnel ghost movement speed.
; After the hardware frame tick: update fruit/power pellets, draw, collide, read input/AI, move, eat pellets, repeat.
; -----------------------------------------------------------------------------
main_game_loop:
    ; Acknowledge any Escape condition once per frame.  This prevents an Escape key
    ; event from being left pending in MOS while the game owns the keyboard loop.
    LDA #OSBYTE_ACK_ESCAPE              ; &10CB  A9 7E
    JSR OSBYTE                         ; &10CD  20 F4 FF
    LDA USERVIA_ORB                    ; &10D0  AD 60 FE
wait_for_frame_timer_toggle:
    ; PB7 is Timer-1's hardware output because ACR=&C0.  Other user-port bits are
    ; not used here; waiting for ORB to differ is effectively a PB7 frame wait.
    CMP USERVIA_ORB                    ; &10D3  CD 60 FE
    BEQ wait_for_frame_timer_toggle                       ; &10D6  F0 FB
    LDY #&03                           ; &10D8  A0 03
refresh_ghost_patrol_state:
    LDA object_x,Y                     ; &10DA  B9 02 00
    CMP #GHOST_HOME_X                           ; &10DD  C9 27
    BNE next_ghost_patrol_refresh                       ; &10DF  D0 1D
    LDA object_y,Y                     ; &10E1  B9 07 00
    CMP #GHOST_HOME_Y                           ; &10E4  C9 28
    BNE next_ghost_patrol_refresh                       ; &10E6  D0 16
    SEC                                ; &10E8  38
    LDA #PATROL_COUNT_BASE                           ; &10E9  A9 0F  | MOD: Raises/lowers the number of scripted patrol decisions on level 1; one is removed each level.
    SBC level_number                   ; &10EB  E5 3D
    BCS store_ghost_patrol_count                       ; &10ED  B0 02
    LDA #&00                           ; &10EF  A9 00
store_ghost_patrol_count:
    STA ghost_patrol_counter,Y         ; &10F1  99 51 00
    TYA                                ; &10F4  98
    AND #&02                           ; &10F5  29 02
    BEQ store_ghost_route_phase                       ; &10F7  F0 02
    LDA #&0A                           ; &10F9  A9 0A
store_ghost_route_phase:
    STA ghost_route_phase,Y            ; &10FB  99 55 00
next_ghost_patrol_refresh:
    DEY                                ; &10FE  88
    BPL refresh_ghost_patrol_state                       ; &10FF  10 D9
; -----------------------------------------------------------------------------
; Fruit appears at fixed (FRUIT_X,FRUIT_Y).  If Snapper reaches it, the level-selected sprite ID is
; normalised against FIRST_FRUIT_SPRITE, doubled to index the two-byte packed-BCD score table, and awarded.
; Fruit spawning is not pellet-count based: while absent, it requires a Timer-1 low-counter sample to equal zero.
; -----------------------------------------------------------------------------
update_fruit_item:
    LDA fruit_sprite_id                ; &1101  A5 38
    BEQ update_fruit_spawn_timer       ; &1103  F0 40
    LDA #&21                           ; &1105  A9 21
    STA sprite_id                      ; &1107  85 1A
    LDA #&FF                           ; &1109  A9 FF
    STA sprite_and_mask                ; &110B  85 13
    LDA #FRUIT_X                        ; &110D  A9 27
    STA coord_x                        ; &110F  85 70
    LDA #FRUIT_Y                        ; &1111  A9 11
    STA coord_y                        ; &1113  85 71
    LDA player_x                       ; &1115  A5 06
    CMP coord_x                        ; &1117  C5 70
    BNE tick_fruit_lifetime                       ; &1119  D0 46
    LDA player_y                       ; &111B  A5 0B
    CMP coord_y                        ; &111D  C5 71
    BNE tick_fruit_lifetime                       ; &111F  D0 40
    LDY level_number                   ; &1121  A4 3D
    LDA level_fruit_sprite_table,Y     ; &1123  B9 47 26
    SEC                                ; &1126  38
    SBC #FIRST_FRUIT_SPRITE             ; &1127  E9 0E
    ASL A                              ; &1129  0A
    TAY                                ; &112A  A8
    LDA fruit_score_bcd_table,Y        ; &112B  B9 60 1F
    TAX                                ; &112E  AA
    LDA fruit_score_bcd_table+1,Y       ; &112F  B9 61 1F
    JSR add_score_bcd_and_redraw       ; &1132  20 DC 17
    LDX #SOUND_ENVELOPE_2                ; &1135  A2 02
    LDY #SOUND_CHANNEL_1_FLUSH           ; &1137  A0 11
    LDA #&30                           ; &1139  A9 30
    JSR play_sound                     ; &113B  20 6D 1D
erase_fruit:
    LDA #&22                           ; &113E  A9 22
    JSR draw_masked_sprite             ; &1140  20 01 0F
    STA fruit_sprite_id                ; &1143  85 38
; -----------------------------------------------------------------------------
 ; When no fruit is active, the current User-VIA Timer-1 low byte must be exactly zero.  This is NOT a
; statistically uniform 1/256 PRNG test: execution is frame-synchronised to the same Timer-1, so sampled
; values are timing-dependent.  A second sample seeds the low lifetime byte and a third supplies two high bits.
; Note the original ADC #1 deliberately/accidentally has NO preceding CLC: the low seed is sample+1
; or sample+2 depending on the inherited carry.  Countdown semantics yield roughly 1..1024 frames.
; This probabilistic mechanism is independent of how many pellets have been eaten.
; -----------------------------------------------------------------------------
update_fruit_spawn_timer:
    JSR random_byte                    ; &1145  20 CA 17
    BNE draw_power_pellets             ; &1148  D0 24  | MOD: Fruit spawn gate; requires the sampled T1 low byte to be exactly zero.
    JSR random_byte                    ; &114A  20 CA 17
    ADC #&01                           ; &114D  69 01
    STA fruit_timer_lo                 ; &114F  85 3B
    JSR random_byte                    ; &1151  20 CA 17
    AND #&03                           ; &1154  29 03
    STA fruit_timer_hi                 ; &1156  85 3C
    LDX level_number                   ; &1158  A6 3D
    LDA level_fruit_sprite_table,X     ; &115A  BD 47 26
    STA fruit_sprite_id                ; &115D  85 38
    BNE draw_power_pellets             ; &115F  D0 0D
tick_fruit_lifetime:
    DEC fruit_timer_lo                 ; &1161  C6 3B
    BNE draw_active_fruit                       ; &1163  D0 04
    DEC fruit_timer_hi                 ; &1165  C6 3C
    BMI erase_fruit                       ; &1167  30 D5
draw_active_fruit:
    LDA fruit_sprite_id                ; &1169  A5 38
    JSR draw_masked_sprite             ; &116B  20 01 0F
draw_power_pellets:
    LDY #TILE_POWER_PELLET                           ; &116E  A0 07
    LDX #POWER_PELLET_LEFT_X            ; &1170  A2 03
    STX coord_x                        ; &1172  86 70
    LDX #POWER_PELLET_BOTTOM_Y          ; &1174  A2 34
    STX coord_y                        ; &1176  86 71
    LDA power_pellet_flags             ; &1178  A5 3F
    BPL blank_bottom_left_power_pellet                       ; &117A  10 03
    TYA                                ; &117C  98
    BNE draw_bottom_left_power_pellet                       ; &117D  D0 02
blank_bottom_left_power_pellet:
    LDA #&00                           ; &117F  A9 00
draw_bottom_left_power_pellet:
    JSR draw_tile_block                ; &1181  20 07 19
    LDX #POWER_PELLET_RIGHT_X           ; &1184  A2 4B
    STX coord_x                        ; &1186  86 70
    LDA power_pellet_flags             ; &1188  A5 3F
    AND #POWER_PELLET_BOTTOM_RIGHT_BIT                           ; &118A  29 20
    BEQ blank_bottom_right_power_pellet                       ; &118C  F0 03
    TYA                                ; &118E  98
    BNE draw_bottom_right_power_pellet                       ; &118F  D0 02
blank_bottom_right_power_pellet:
    LDA #&00                           ; &1191  A9 00
draw_bottom_right_power_pellet:
    JSR draw_tile_block                ; &1193  20 07 19
    LDX #POWER_PELLET_TOP_Y             ; &1196  A2 10
    STX coord_y                        ; &1198  86 71
    LDA power_pellet_flags             ; &119A  A5 3F
    AND #POWER_PELLET_TOP_RIGHT_BIT                           ; &119C  29 08
    BEQ blank_top_right_power_pellet                       ; &119E  F0 03
    TYA                                ; &11A0  98
    BNE draw_top_right_power_pellet                       ; &11A1  D0 02
blank_top_right_power_pellet:
    LDA #&00                           ; &11A3  A9 00
draw_top_right_power_pellet:
    JSR draw_tile_block                ; &11A5  20 07 19
    LDX #POWER_PELLET_LEFT_X            ; &11A8  A2 03
    STX coord_x                        ; &11AA  86 70
    LDA power_pellet_flags             ; &11AC  A5 3F
    AND #POWER_PELLET_TOP_LEFT_BIT                           ; &11AE  29 02
    BEQ blank_top_left_power_pellet                       ; &11B0  F0 03
    TYA                                ; &11B2  98
    BNE draw_top_left_power_pellet                       ; &11B3  D0 02
blank_top_left_power_pellet:
    LDA #&00                           ; &11B5  A9 00
draw_top_left_power_pellet:
    JSR draw_tile_block                ; &11B7  20 07 19
    INC animation_counter              ; &11BA  E6 39
    LDA animation_counter              ; &11BC  A5 39
    AND #&07                           ; &11BE  29 07
    BNE tick_ghost_eat_pause                       ; &11C0  D0 22
    LDA #PALETTE_POWER_PELLET_ON        ; &11C2  A9 65
    ORA palette_phase                  ; &11C4  05 3A
    JSR set_palette_colour             ; &11C6  20 47 1A
    LDA palette_phase                  ; &11C9  A5 3A
    EOR #&02                           ; &11CB  49 02
    STA palette_phase                  ; &11CD  85 3A
    ; Every eighth animation frame the power-pellet logical colour toggles green/black.
    ; During energizer mode the same cadence drives the late warning: below &32 frames, logical C
    ; alternates white/blue.  This is all palette animation; pellet/ghost bitmap pixels are unchanged.
    LDA energizer_timer                ; &11CF  A5 40
    BEQ tick_ghost_eat_pause                       ; &11D1  F0 11
    CMP #ENERGIZER_FLASH_THRESHOLD                           ; &11D3  C9 32  | MOD: Increase to begin frightened-mode flashing earlier; decrease to flash later.
    BCS tick_ghost_eat_pause                       ; &11D5  B0 0D
    LDA energizer_flash_phase          ; &11D7  A5 48
    EOR #&03                           ; &11D9  49 03
    STA energizer_flash_phase          ; &11DB  85 48
    LDA #PALETTE_FRIGHTENED_WHITE       ; &11DD  A9 C0
    EOR energizer_flash_phase          ; &11DF  45 48
    JSR set_palette_colour             ; &11E1  20 47 1A
tick_ghost_eat_pause:
    LDY movement_pause_timer           ; &11E4  A4 4A
    BEQ draw_all_objects               ; &11E6  F0 0E
    DEC movement_pause_timer           ; &11E8  C6 4A
    BNE draw_all_objects               ; &11EA  D0 0A
    LDA #&FF                           ; &11EC  A9 FF
    STA object_move_bypass                ; &11EE  85 59
    STA object_move_bypass+1                            ; &11F0  85 5A
    STA object_move_bypass+2                            ; &11F2  85 5B
    STA object_move_bypass+3                            ; &11F4  85 5C
draw_all_objects:
    LDY #&04                           ; &11F6  A0 04
draw_next_object:
    LDA object_state,Y                 ; &11F8  B9 41 00
    CMP #&FF                           ; &11FB  C9 FF
    BNE erase_object_trailing_edge                       ; &11FD  D0 03
    JMP choose_ghost_direction         ; &11FF  4C 15 1C
erase_object_trailing_edge:
    LDA #SPRITE_BLANK_SOURCE          ; &1202  A9 21
    STA sprite_id                      ; &1204  85 1A
    CLC                                ; &1206  18
    LDA #&00                           ; &1207  A9 00
    STA sprite_and_mask                ; &1209  85 13
    LDA object_dx,Y                    ; &120B  B9 24 00
    BEQ erase_vertical_trailing_edge                       ; &120E  F0 14
    LDA object_x,Y                     ; &1210  B9 02 00
    ADC object_probe_offset,Y          ; &1213  79 2E 00
    STA coord_x                        ; &1216  85 70
    LDA object_y,Y                     ; &1218  B9 07 00
    STA coord_y                        ; &121B  85 71
    LDA #SPRITE_ERASE_HORIZONTAL_TRAIL                           ; &121D  A9 16
    JSR draw_masked_sprite             ; &121F  20 01 0F
    BEQ draw_object_at_current_position                       ; &1222  F0 12
erase_vertical_trailing_edge:
    LDA object_y,Y                     ; &1224  B9 07 00
    ADC object_probe_offset,Y          ; &1227  79 2E 00
    STA coord_y                        ; &122A  85 71
    LDA object_x,Y                     ; &122C  B9 02 00
    STA coord_x                        ; &122F  85 70
    LDA #SPRITE_ERASE_VERTICAL_TRAIL                           ; &1231  A9 17
    JSR draw_masked_sprite             ; &1233  20 01 0F
draw_object_at_current_position:
    LDA object_x,Y                     ; &1236  B9 02 00
    STA coord_x                        ; &1239  85 70
    LDA object_y,Y                     ; &123B  B9 07 00
    STA coord_y                        ; &123E  85 71
    LDA object_colour_mask,Y            ; &1240  B9 15 00
    STA sprite_and_mask                ; &1243  85 13
    CPY #&04                           ; &1245  C0 04
    BMI select_ghost_rendering                       ; &1247  30 04
    LDA #SPRITE_BLANK_SOURCE                           ; &1249  A9 21
    BNE store_object_overlay_sprite                       ; &124B  D0 1B
select_ghost_rendering:
    LDA object_state,Y                 ; &124D  B9 41 00
    BEQ select_normal_ghost_eye_overlay                       ; &1250  F0 0E
    LDA #&FF                           ; &1252  A9 FF
    STA sprite_and_mask                ; &1254  85 13
    LDA #SPRITE_BLANK_SOURCE                           ; &1256  A9 21
    STA sprite_id                      ; &1258  85 1A
    LDA #SPRITE_FRIGHTENED_FRAME0                           ; &125A  A9 0C
    ORA frightened_sprite_phase         ; &125C  05 47
    BNE compose_selected_object_sprite                       ; &125E  D0 1F
select_normal_ghost_eye_overlay:
    ; object_colour_mask supplies body colour while the requested body sprite supplies shape/mask:
    ; slot0 &FF -> logical15 -> green; slot1 &33 -> logical5 -> magenta;
    ; slot2 &FC -> logical14 -> cyan; slot3 &03 -> logical1 -> red.  Eyes are ORed afterward.
    LDA object_sprite_base,Y                  ; &1260  B9 0C 00
    ORA object_facing,Y                ; &1263  19 1F 00
    ORA #&08                           ; &1266  09 08
store_object_overlay_sprite:
    STA sprite_id                      ; &1268  85 1A
    LDA object_sprite_base,Y                  ; &126A  B9 0C 00
    ORA object_facing,Y                ; &126D  19 1F 00
    STA scratch14                      ; &1270  85 14
    LDA object_x,Y                     ; &1272  B9 02 00
    CLC                                ; &1275  18
    ADC object_y,Y                     ; &1276  79 07 00
    AND #&01                           ; &1279  29 01
    ASL A                              ; &127B  0A
    ASL A                              ; &127C  0A
    ORA scratch14                      ; &127D  05 14
compose_selected_object_sprite:
    JSR draw_masked_sprite             ; &127F  20 01 0F
    LDA frightened_sprite_phase         ; &1282  A5 47
    EOR #&01                           ; &1284  49 01
    STA frightened_sprite_phase         ; &1286  85 47
advance_to_next_draw_object:
    DEY                                ; &1288  88
    BMI show_ready_sequence            ; &1289  30 03
    JMP draw_next_object                       ; &128B  4C F8 11
show_ready_sequence:
    ; ready_message contains VDU 18 (GCOL) action 3 = XOR, so outputting the same
    ; text/control stream a second time removes "READY!" without storing/restoring glyph pixels.
    LDA ready_sequence_done            ; &128E  A5 4F
    BNE remove_ready_message           ; &1290  D0 29
    LDY #&00                           ; &1292  A0 00
print_ready_message:
    LDA ready_message,Y                ; &1294  B9 B8 1E
    JSR OSWRCH                         ; &1297  20 EE FF
    INY                                ; &129A  C8
    CPY #&11                           ; &129B  C0 11
    BNE print_ready_message                       ; &129D  D0 F5
    LDA ready_tune_played              ; &129F  A5 6A
    BNE ready_message_delay_loop                       ; &12A1  D0 05
    JSR play_ready_tune                ; &12A3  20 A3 0E
    LDY #&05                           ; &12A6  A0 05
ready_message_delay_loop:
    JSR delay_ten_clock_ticks          ; &12A8  20 21 1B
    DEY                                ; &12AB  88
    BNE ready_message_delay_loop                       ; &12AC  D0 FA
xor_erase_ready_message:
    LDA ready_message,Y                ; &12AE  B9 B8 1E
    JSR OSWRCH                         ; &12B1  20 EE FF
    INY                                ; &12B4  C8
    CPY #&11                           ; &12B5  C0 11
    BNE xor_erase_ready_message                       ; &12B7  D0 F5
    STY ready_sequence_done            ; &12B9  84 4F
remove_ready_message:
    ; Install the ghost-house gate after READY.  &C3 is logical colour 9 in BOTH Mode-2 pixels, and
    ; maze_palette_sequence maps logical 9 to physical BLACK.  It is therefore invisible on screen but
    ; read_playfield_colour still sees value 9.  The four writes correspond to logical x=39..42,y=37.
    ; Player upward-turn logic treats 9 as blocked; ghost junction logic recognises it separately, making
    ; this a collision/topology marker rather than a visible wall.
    LDA #MODE2_LOGICAL9_PAIR          ; &12BB  A9 C3
    STA &51BD                          ; &12BD  8D BD 51
    STA &51C5                          ; &12C0  8D C5 51
    STA &51CD                          ; &12C3  8D CD 51
    STA &51D5                          ; &12C6  8D D5 51
    LDA #MODE2_LOGICAL13_PAIR         ; &12C9  A9 F3
    STA &51BF                          ; &12CB  8D BF 51
    STA &51C7                          ; &12CE  8D C7 51
    STA &51CF                          ; &12D1  8D CF 51
    STA &51D7                          ; &12D4  8D D7 51
    LDY #&02                           ; &12D7  A0 02
restore_ready_background_patch_loop:
    STA &5438,Y                        ; &12D9  99 38 54
    STA &5440,Y                        ; &12DC  99 40 54
    STA &5448,Y                        ; &12DF  99 48 54
    STA &5450,Y                        ; &12E2  99 50 54
    DEY                                ; &12E5  88
    BPL restore_ready_background_patch_loop                       ; &12E6  10 F1
    LDA movement_pause_timer           ; &12E8  A5 4A
    BEQ check_player_ghost_collisions  ; &12EA  F0 03
    JMP check_level_completion         ; &12EC  4C E4 13
check_player_ghost_collisions:
    ; Normal collision is a 3x3 logical-coordinate box: each axis accepts ghost-player delta -1,0,+1.
    ; In the tunnel/wrap zone (player_x >= &4F), coordinates deliberately use a simpler rule: any ghost
    ; also at x>=&4F is considered colliding, avoiding unsigned wrap-distance problems at the screen edge.
    LDA player_x                       ; &12EF  A5 06
    CMP #&4F                           ; &12F1  C9 4F
    BCC check_normal_collision_distances                       ; &12F3  90 12
    LDY #&03                           ; &12F5  A0 03
check_tunnel_collision_ghost:
    LDA object_x,Y                     ; &12F7  B9 02 00
    CMP #&4F                           ; &12FA  C9 4F
    BCC next_tunnel_collision_ghost                       ; &12FC  90 03
    JMP handle_player_ghost_collision  ; &12FE  4C A8 13
next_tunnel_collision_ghost:
    DEY                                ; &1301  88
    BPL check_tunnel_collision_ghost                       ; &1302  10 F3
    JMP check_level_completion         ; &1304  4C E4 13
check_normal_collision_distances:
    LDY #&03                           ; &1307  A0 03
check_next_collision_ghost:
    SEC                                ; &1309  38
    LDA player_x                       ; &130A  A5 06
    SBC object_x,Y                     ; &130C  F9 02 00
    TAX                                ; &130F  AA
    INX                                ; &1310  E8
    CPX #COLLISION_AXIS_WINDOW          ; &1311  E0 03
    BCS next_collision_ghost                       ; &1313  B0 0F
    SEC                                ; &1315  38
    LDA player_y                       ; &1316  A5 0B
    SBC object_y,Y                     ; &1318  F9 07 00
    TAX                                ; &131B  AA
    INX                                ; &131C  E8
    CPX #COLLISION_AXIS_WINDOW          ; &131D  E0 03
    BCS next_collision_ghost                       ; &131F  B0 03
    JMP handle_player_ghost_collision  ; &1321  4C A8 13
next_collision_ghost:
    DEY                                ; &1324  88
    BPL check_next_collision_ghost                       ; &1325  10 E2
    JMP check_level_completion         ; &1327  4C E4 13
; -----------------------------------------------------------------------------
; Snapper death sequence: stop current sound, animate the multi-frame death graphic, play descending/sweeping sound,
; consume one spare life and either restart the life or return to the high-score system.
; -----------------------------------------------------------------------------
player_death_sequence:
    LDA #&00                           ; &132A  A9 00
    TAX                                ; &132C  AA
    LDY #SOUND_CHANNEL_2_FLUSH           ; &132D  A0 12
    JSR play_sound                     ; &132F  20 6D 1D
    LDA #PALETTE_LOGICAL6_GREEN         ; &1332  A9 65
    JSR set_palette_colour             ; &1334  20 47 1A
    LDY #&78                           ; &1337  A0 78
    STY sound_sweep_pitch              ; &1339  84 65
    LDX #&64                           ; &133B  A2 64
    JSR delay_clock_ticks_from_x       ; &133D  20 23 1B
    LDY #&18                           ; &1340  A0 18
    JSR redraw_all_objects             ; &1342  20 47 1B
    JSR restore_hidden_pellets         ; &1345  20 BA 1C
    LDA player_x                       ; &1348  A5 06
    STA coord_x                        ; &134A  85 70
    LDA player_y                       ; &134C  A5 0B
    STA coord_y                        ; &134E  85 71
    DEC sprite_and_mask                ; &1350  C6 13
    LDA #SPRITE_DEATH_FRAME0                           ; &1352  A9 23
    JSR draw_masked_sprite             ; &1354  20 01 0F
    JSR play_death_sound_sweep         ; &1357  20 ED 1C
    INC sprite_and_mask                ; &135A  E6 13
    LDA #&22                           ; &135C  A9 22
    JSR draw_masked_sprite             ; &135E  20 01 0F
    DEC sprite_and_mask                ; &1361  C6 13
    DEC coord_y                        ; &1363  C6 71
    DEC coord_y                        ; &1365  C6 71
    LDA #SPRITE_DEATH_FRAME1                           ; &1367  A9 24
    JSR draw_masked_sprite             ; &1369  20 01 0F
    JSR play_death_sound_sweep         ; &136C  20 ED 1C
    LDA #SPRITE_DEATH_FRAME2                           ; &136F  A9 25
    JSR draw_masked_sprite             ; &1371  20 01 0F
    JSR play_death_sound_sweep         ; &1374  20 ED 1C
    LDA #SPRITE_DEATH_FRAME3                           ; &1377  A9 26
    JSR draw_masked_sprite             ; &1379  20 01 0F
    JSR play_death_sound_sweep         ; &137C  20 ED 1C
    INC coord_y                        ; &137F  E6 71
    INC coord_y                        ; &1381  E6 71
    LDA #SPRITE_DEATH_FRAME4                           ; &1383  A9 27
    JSR draw_masked_sprite             ; &1385  20 01 0F
    JSR play_death_sound_sweep         ; &1388  20 ED 1C
    INC sprite_and_mask                ; &138B  E6 13
    LDA #&22                           ; &138D  A9 22
    JSR draw_masked_sprite             ; &138F  20 01 0F
    JSR restore_hidden_pellets         ; &1392  20 BA 1C
    LDX #&00                           ; &1395  A2 00
    LDA #&00                           ; &1397  A9 00
    LDY #SOUND_CHANNEL_1_FLUSH           ; &1399  A0 11
    JSR play_sound                     ; &139B  20 6D 1D
    ; No score-based bonus-life path exists in the reachable game code: spare_lives is only
    ; initialised at start_new_game, displayed at start_life, and decremented here.
    DEC spare_lives                    ; &139E  C6 50
    BMI game_over_return                       ; &13A0  30 03
    JMP start_life                     ; &13A2  4C FD 0F
game_over_return:
    JMP shared_return_rts                       ; &13A5  4C 1F 1D
; -----------------------------------------------------------------------------
; Resolve a collision with ghost Y. Normal ghosts kill the player; frightened ghosts are marked eaten.
; ghost_eat_score_bcd starts at &10 but is ASL'd BEFORE each award, so the actual displayed ladder is
; 200, 400, 800, then 1600 points (scores are internally stored in units of ten).  The fourth shift
; carries; that path forces BCD 0160 and sets energizer_timer=1 so the frightened period expires.
; -----------------------------------------------------------------------------
handle_player_ghost_collision:
    LDA object_state,Y                 ; &13A8  B9 41 00
    BNE collision_with_non_normal_ghost                       ; &13AB  D0 03
    JMP player_death_sequence          ; &13AD  4C 2A 13
collision_with_non_normal_ghost:
    CMP #GHOST_STATE_EATEN                           ; &13B0  C9 FF
    BNE eat_frightened_ghost                       ; &13B2  D0 03
    JMP next_collision_ghost                       ; &13B4  4C 24 13
eat_frightened_ghost:
    LDA #GHOST_STATE_EATEN                           ; &13B7  A9 FF
    STA object_state,Y                 ; &13B9  99 41 00
    JSR handle_eaten_ghost             ; &13BC  20 C8 1B
    LDX #&00                           ; &13BF  A2 00
    LDA ghost_eat_score_bcd            ; &13C1  A5 49
    ASL A                              ; &13C3  0A
    STA ghost_eat_score_bcd            ; &13C4  85 49
    BCC award_current_ghost_score        ; &13C6  90 07
    INX                                ; &13C8  E8
    LDA #&01                           ; &13C9  A9 01
    STA energizer_timer                ; &13CB  85 40
    LDA #&60                           ; &13CD  A9 60
award_current_ghost_score:
    JSR add_score_bcd_and_redraw       ; &13CF  20 DC 17
    LDA #&48                           ; &13D2  A9 48
    LDX #SOUND_ENVELOPE_2                ; &13D4  A2 02
    LDY #SOUND_CHANNEL_1_FLUSH           ; &13D6  A0 11
    JSR play_sound                     ; &13D8  20 6D 1D
    LDA #&00                           ; &13DB  A9 00
    LDX #&00                           ; &13DD  A2 00
    LDY #SOUND_CHANNEL_2_FLUSH           ; &13DF  A0 12
    JSR play_sound                     ; &13E1  20 6D 1D
; -----------------------------------------------------------------------------
; Level ends only when all ordinary pellets are gone and all four power-pellet flag bits have been cleared.
; -----------------------------------------------------------------------------
check_level_completion:
    LDA pellets_remaining              ; &13E4  A5 3E
    BNE continue_current_level_frame                       ; &13E6  D0 09
    LDA power_pellet_flags             ; &13E8  A5 3F
    CMP #POWER_PELLETS_CLEARED_MASK    ; &13EA  C9 55  | Four power pellets are complete when the original &FF flag has become &55.
    BNE continue_current_level_frame                       ; &13EC  D0 03
    JMP level_complete                 ; &13EE  4C 7A 1B
continue_current_level_frame:
    JSR restore_hidden_pellets         ; &13F1  20 BA 1C
    LDA movement_pause_timer           ; &13F4  A5 4A
    BEQ read_player_controls           ; &13F6  F0 03
    JMP move_objects_horizontally      ; &13F8  4C C2 16
; -----------------------------------------------------------------------------
; Read Z/X/?/* and update the player's requested movement direction when the destination path is open.
; -----------------------------------------------------------------------------
read_player_controls:
    ; Negative-key OSBYTE &81 returns X=&FF when the requested key is down.  The
    ; original code exploits that value directly: for LEFT/UP it becomes -1 movement,
    ; while INX steps cheaply produce 0/+1 and the player's compact facing codes.
    ; Note that PLAYER_FACING_* deliberately differs from GHOST_FACING_*.
    LDA energizer_timer                ; &13FB  A5 40
    BEQ check_player_horizontal_turns                       ; &13FD  F0 12
    AND #&07                           ; &13FF  29 07
    BNE check_player_horizontal_turns                       ; &1401  D0 0E
    ; Energizer hum is retriggered every 8 energizer frames.  Pitch = (~energizer_timer)-&40,
    ; so the pitch rises as the countdown approaches zero; ENVELOPE 1 supplies the timbre.
    LDX #SOUND_ENVELOPE_1                ; &1403  A2 01
    LDY #SOUND_CHANNEL_2_FLUSH           ; &1405  A0 12
    LDA energizer_timer                ; &1407  A5 40
    EOR #&FF                           ; &1409  49 FF
    SEC                                ; &140B  38
    SBC #&40                           ; &140C  E9 40
    JSR play_sound                     ; &140E  20 6D 1D
check_player_horizontal_turns:
    LDA player_y                       ; &1411  A5 0B
    CLC                                ; &1413  18
    ADC #&01                           ; &1414  69 01
    JSR modulo_three                   ; &1416  20 C2 17
    BNE check_player_vertical_turns                       ; &1419  D0 42
    LDA player_x                       ; &141B  A5 06
    STA coord_x                        ; &141D  85 70
    LDY #&04                           ; &141F  A0 04
    JSR probe_horizontal_path_at_x     ; &1421  20 96 17
    CMP #&08                           ; &1424  C9 08
    BEQ check_player_turn_right                       ; &1426  F0 12
    LDX #KEY_LEFT_Z                    ; &1428  A2 9E  | MOD: Left key (Z).
    JSR test_key                       ; &142A  20 F1 0E
    BEQ check_player_turn_right                       ; &142D  F0 0B
    STX player_dx                      ; &142F  86 28
    INX                                ; &1431  E8
    STX player_dy                      ; &1432  86 2D
    STX player_facing                  ; &1434  86 23
    LDA #&04                           ; &1436  A9 04
    STA player_probe_offset            ; &1438  85 32
check_player_turn_right:
    LDA player_x                       ; &143A  A5 06
    CLC                                ; &143C  18
    ADC #&04                           ; &143D  69 04
    STA coord_x                        ; &143F  85 70
    JSR probe_horizontal_path_at_x     ; &1441  20 96 17
    CMP #&08                           ; &1444  C9 08
    BEQ check_player_vertical_turns                       ; &1446  F0 15
    LDX #KEY_RIGHT_X                   ; &1448  A2 BD  | MOD: Right key (X).
    JSR test_key                       ; &144A  20 F1 0E
    BEQ check_player_vertical_turns                       ; &144D  F0 0E
    LDX #&01                           ; &144F  A2 01
    STX player_dx                      ; &1451  86 28
    DEX                                ; &1453  CA
    STX player_dy                      ; &1454  86 2D
    LDA #&03                           ; &1456  A9 03
    STA player_facing                  ; &1458  85 23
    DEX                                ; &145A  CA
    STX player_probe_offset            ; &145B  86 32
check_player_vertical_turns:
    LDA player_x                       ; &145D  A5 06
    CMP #&4C                           ; &145F  C9 4C
    BCS begin_ghost_ai_update                       ; &1461  B0 4B
    CMP #&02                           ; &1463  C9 02
    BCC begin_ghost_ai_update                       ; &1465  90 47
    JSR modulo_three                   ; &1467  20 C2 17
    BNE begin_ghost_ai_update                       ; &146A  D0 42
    LDA player_y                       ; &146C  A5 0B
    STA coord_y                        ; &146E  85 71
    JSR probe_vertical_path_at_y       ; &1470  20 BC 17
    CMP #&08                           ; &1473  C9 08
    BEQ check_player_turn_up                       ; &1475  F0 13
    LDX #KEY_DOWN_QUESTION             ; &1477  A2 B7  | MOD: Down key (?).
    JSR test_key                       ; &1479  20 F1 0E
    BEQ check_player_turn_up                       ; &147C  F0 0C
    INX                                ; &147E  E8
    STX player_dx                      ; &147F  86 28
    INX                                ; &1481  E8
    STX player_dy                      ; &1482  86 2D
    STX player_facing                  ; &1484  86 23
    LDA #&FC                           ; &1486  A9 FC
    STA player_probe_offset            ; &1488  85 32
check_player_turn_up:
    LDA player_y                       ; &148A  A5 0B
    SEC                                ; &148C  38
    SBC #&04                           ; &148D  E9 04
    STA coord_y                        ; &148F  85 71
    JSR probe_vertical_path_at_y       ; &1491  20 BC 17
    CMP #&08                           ; &1494  C9 08
    BEQ begin_ghost_ai_update                       ; &1496  F0 16
    CMP #GHOST_GATE_COLOUR              ; &1498  C9 09
    BEQ begin_ghost_ai_update                       ; &149A  F0 12
    LDX #KEY_UP_ASTERISK               ; &149C  A2 97  | MOD: Up key (*).
    JSR test_key                       ; &149E  20 F1 0E
    BEQ begin_ghost_ai_update                       ; &14A1  F0 0B
    STX player_dy                      ; &14A3  86 2D
    INX                                ; &14A5  E8
    STX player_dx                      ; &14A6  86 28
    INX                                ; &14A8  E8
    STX player_probe_offset            ; &14A9  86 32
    INX                                ; &14AB  E8
    STX player_facing                  ; &14AC  86 23
begin_ghost_ai_update:
    LDY #&03                           ; &14AE  A0 03
; -----------------------------------------------------------------------------
; Ghost AI update. Chooses turns from maze topology plus patrol/chase state and the player's relative position.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; Four ghosts are processed from index 3 down to 0.  At maze decision points they use either the scripted
; patrol route or a shared player-relative pursuit heuristic.  There are NO four distinct Pac-Man-style
; targeting personalities in the reachable code: ghost index matters for start position/colour/patrol mirroring,
; but all four eventually enter this same pursuit logic.  Frightened ghosts suppress selected pursuit turns;
; eaten ghosts skip this routine and use the separate packed return-home field.
;
; HIGH-LEVEL PSEUDOCODE (faithful to the byte-level branches):
;
;   for ghost = 3 downto 0:
;       if state == EATEN: continue
;       if (x + y + 1) mod 3 != 0 or x >= &4E: continue
;
;       if patrol_counter != 0 and route_phase is 0 or 10:
;           advance route_phase
;           force initial outward horizontal turn (even ghost RIGHT, odd ghost LEFT)
;
;       if x in 29..46 and y in 24..35:
;           if (T1CL & 7) != 0: turn DOWN
;           else: choose LEFT/RIGHT from the sign bit of another T1CL sample
;           continue
;
;       if moving vertically:
;           L = probe left edge; R = probe right edge; F = probe forward
;           if both side branches blocked: continue straight
;           if F blocked:
;               take sole open side, else patrol step, else turn toward player's X
;           else if patrol_counter != 0:
;               take next scripted patrol direction
;           else:
;               choose an available side candidate (T1CL sign bit if both are open)
;               only take that side if player is BEHIND on the current Y axis,
;               a fresh T1CL sample is non-zero, and state is not FRIGHTENED
;
;       else moving horizontally:
;           D = lower vertical probe; U = upper vertical probe; F = probe forward
;           if both vertical branches blocked: continue straight
;           if F blocked:
;               take sole open branch, else patrol step, else turn toward player's Y
;           else if patrol_counter != 0:
;               take next scripted patrol direction
;           else:
;               the original logic is deliberately asymmetric: at a fully open junction,
;               a non-zero T1CL sample immediately selects UP; zero falls into the more
;               detailed player-relative test.  Other branch cases compare player Y/current dy.
;               Direct pursuit turns are suppressed while FRIGHTENED.
;
; This is therefore a cheap axis/branch heuristic rather than shortest-path search: with a blocked
; forward path it chooses the side nearer the player on the perpendicular axis; with forward open
; it usually continues unless the player's relative position and timing tests encourage a turn.
; -----------------------------------------------------------------------------
update_ghost_ai:
    LDA object_state,Y                 ; &14B0  B9 41 00
    CMP #GHOST_STATE_EATEN                           ; &14B3  C9 FF
    BNE check_ghost_decision_point                       ; &14B5  D0 03
next_ghost_ai:
    JMP advance_to_next_ghost                       ; &14B7  4C 99 16
check_ghost_decision_point:
    ; A ghost only reconsiders direction on the 3-unit maze grid.  (x+y+1) mod 3
    ; is a compact alignment test matching the tile/corridor spacing used elsewhere.
    LDA object_y,Y                     ; &14BA  B9 07 00
    CLC                                ; &14BD  18
    ADC #&01                           ; &14BE  69 01
    ADC object_x,Y                     ; &14C0  79 02 00
    JSR modulo_three                   ; &14C3  20 C2 17
    BNE next_ghost_ai                       ; &14C6  D0 EF
    LDA object_x,Y                     ; &14C8  B9 02 00
    CMP #&4E                           ; &14CB  C9 4E
    BCS next_ghost_ai                       ; &14CD  B0 E8
    LDA ghost_patrol_counter,Y         ; &14CF  B9 51 00
    BEQ ghost_chase_or_patrol_decision                       ; &14D2  F0 15
    LDX ghost_route_phase,Y            ; &14D4  B6 55
    BEQ begin_patrol_route_segment                       ; &14D6  F0 04
    CPX #&0A                           ; &14D8  E0 0A
    BNE ghost_chase_or_patrol_decision                       ; &14DA  D0 0D
begin_patrol_route_segment:
    INX                                ; &14DC  E8
    TXA                                ; &14DD  8A
    STA ghost_route_phase,Y            ; &14DE  99 55 00
    TYA                                ; &14E1  98
    AND #&01                           ; &14E2  29 01
    BNE turn_ghost_left                       ; &14E4  D0 6A
    JMP turn_ghost_right                       ; &14E6  4C 9F 15
ghost_chase_or_patrol_decision:
    ; Special central/ghost-house region test before normal junction AI.  The X test accepts 29..46.
    ; Because the preceding CMP leaves carry CLEAR on that accepted path, the following SBC #&17
    ; actually computes y-&18, so the Y range is 24..35.  Inside this 18x12 logical box the ghost
    ; overwhelmingly turns DOWN (7/8); only the remaining 1/8 chooses LEFT/RIGHT randomly.  This is
    ; a compact randomized pen/centre-exit rule, separate from the normal player-relative chase logic.
    LDA object_x,Y                     ; &14E9  B9 02 00
    SEC                                ; &14EC  38
    SBC #&1D                           ; &14ED  E9 1D
    CMP #&12                           ; &14EF  C9 12
    BCS choose_turn_for_vertical_mover                       ; &14F1  B0 1B
    LDA object_y,Y                     ; &14F3  B9 07 00
    SBC #&17                           ; &14F6  E9 17
    CMP #&0C                           ; &14F8  C9 0C
    BCS choose_turn_for_vertical_mover                       ; &14FA  B0 12
    JSR random_byte                    ; &14FC  20 CA 17
    AND #&07                           ; &14FF  29 07
    BEQ choose_random_centre_horizontal_turn                       ; &1501  F0 03
    JMP turn_ghost_down                       ; &1503  4C 6F 16
choose_random_centre_horizontal_turn:
    JSR random_byte                    ; &1506  20 CA 17
    BMI turn_ghost_left                       ; &1509  30 45
    JMP turn_ghost_right                       ; &150B  4C 9F 15
choose_turn_for_vertical_mover:
    ; Axis-specific junction logic: when dx=0 the ghost is travelling vertically,
    ; so left/right are probed first.  A horizontal mover jumps to the mirrored
    ; block at choose_turn_for_horizontal_mover, which probes down/up first.
    LDA object_dx,Y                    ; &150E  B9 24 00
    BEQ probe_horizontal_options                       ; &1511  F0 03
    JMP choose_turn_for_horizontal_mover                       ; &1513  4C F9 15
probe_horizontal_options:
    LDA object_x,Y                     ; &1516  B9 02 00
    STA coord_x                        ; &1519  85 70
    JSR probe_horizontal_path_at_x     ; &151B  20 96 17
    STA scratch1                       ; &151E  85 01
    LDA object_x,Y                     ; &1520  B9 02 00
    CLC                                ; &1523  18
    ADC #&04                           ; &1524  69 04
    STA coord_x                        ; &1526  85 70
    JSR probe_horizontal_path_at_x     ; &1528  20 96 17
    STA scratch0                       ; &152B  85 00
    CMP #WALL_COLOUR                           ; &152D  C9 08
    BEQ vertical_mover_right_branch_blocked                       ; &152F  F0 22
evaluate_vertical_mover_forward_path:
    JSR probe_vertical_path            ; &1531  20 9F 17
    CMP #WALL_COLOUR                           ; &1534  C9 08
    BNE vertical_mover_forward_open                       ; &1536  D0 24
    LDA scratch0                       ; &1538  A5 00
    CMP #WALL_COLOUR                           ; &153A  C9 08
    BEQ turn_ghost_left                       ; &153C  F0 12
    LDA scratch1                       ; &153E  A5 01
    CMP #WALL_COLOUR                           ; &1540  C9 08
    BEQ turn_ghost_right                       ; &1542  F0 5B
    LDA ghost_patrol_counter,Y         ; &1544  B9 51 00
    BNE follow_scripted_patrol_route                       ; &1547  D0 79
    LDA player_x                       ; &1549  A5 06
    CMP object_x,Y                     ; &154B  D9 02 00
    BCS turn_ghost_right                       ; &154E  B0 4F
turn_ghost_left:
    JMP set_direction_left             ; &1550  4C 20 1D
vertical_mover_right_branch_blocked:
    LDA scratch1                       ; &1553  A5 01
    CMP #WALL_COLOUR                           ; &1555  C9 08
    BNE evaluate_vertical_mover_forward_path                       ; &1557  D0 D8
no_ghost_turn_this_frame:
    JMP advance_to_next_ghost                       ; &1559  4C 99 16
vertical_mover_forward_open:
    LDA ghost_patrol_counter,Y         ; &155C  B9 51 00
    BNE follow_scripted_patrol_route                       ; &155F  D0 61
    LDA scratch0                       ; &1561  A5 00
    CMP #WALL_COLOUR                           ; &1563  C9 08
    BEQ consider_left_turn_from_vertical                       ; &1565  F0 0B
    LDA scratch1                       ; &1567  A5 01
    CMP #WALL_COLOUR                           ; &1569  C9 08
    BEQ consider_right_turn_from_vertical                       ; &156B  F0 1F
    JSR random_byte                    ; &156D  20 CA 17
    BMI consider_right_turn_from_vertical                       ; &1570  30 1A
consider_left_turn_from_vertical:
    JSR random_byte                    ; &1572  20 CA 17
    BEQ no_ghost_turn_this_frame                       ; &1575  F0 E2
    LDA player_y                       ; &1577  A5 0B
    CMP object_y,Y                     ; &1579  D9 07 00
    BCS left_turn_player_below_ghost                       ; &157C  B0 07
    LDA object_dy,Y                    ; &157E  B9 29 00
    BPL take_left_turn_if_not_frightened                       ; &1581  10 26
    BMI no_ghost_turn_this_frame                       ; &1583  30 D4
left_turn_player_below_ghost:
    LDA object_dy,Y                    ; &1585  B9 29 00
    BMI take_left_turn_if_not_frightened                       ; &1588  30 1F
    BPL no_ghost_turn_this_frame                       ; &158A  10 CD
consider_right_turn_from_vertical:
    JSR random_byte                    ; &158C  20 CA 17
    BEQ no_ghost_turn_this_frame                       ; &158F  F0 C8
    LDA player_y                       ; &1591  A5 0B
    CMP object_y,Y                     ; &1593  D9 07 00
    BCS right_turn_player_below_ghost                       ; &1596  B0 0A
    LDA object_dy,Y                    ; &1598  B9 29 00
    BPL take_right_turn_if_not_frightened                       ; &159B  10 14
    BMI no_ghost_turn_this_frame                       ; &159D  30 BA
turn_ghost_right:
    JMP set_direction_right            ; &159F  4C 33 1D
right_turn_player_below_ghost:
    LDA object_dy,Y                    ; &15A2  B9 29 00
    BMI take_right_turn_if_not_frightened                       ; &15A5  30 0A
    BPL no_ghost_turn_this_frame                       ; &15A7  10 B0
take_left_turn_if_not_frightened:
    ; FRIGHTENED=&80 is negative, so this candidate chase turn is suppressed while
    ; frightened; NORMAL=&00 may take it.  EATEN ghosts never enter this AI block.
    LDA object_state,Y                 ; &15A9  B9 41 00
    BMI no_ghost_turn_this_frame                       ; &15AC  30 AB
    JMP set_direction_left             ; &15AE  4C 20 1D
take_right_turn_if_not_frightened:
    ; Symmetric suppression of the chase-selected right turn while frightened.
    LDA object_state,Y                 ; &15B1  B9 41 00
    BMI no_ghost_turn_this_frame                       ; &15B4  30 A3
    JMP set_direction_right            ; &15B6  4C 33 1D
horizontal_mover_one_vertical_branch_blocked:
    LDA scratch0                       ; &15B9  A5 00
    CMP #WALL_COLOUR                           ; &15BB  C9 08
    BNE evaluate_horizontal_mover_junction                       ; &15BD  D0 55
    JMP advance_to_next_ghost                       ; &15BF  4C 99 16
; -----------------------------------------------------------------------------
; Patrol mode consumes one step from ghost_patrol_counter and a direction from ghost_route_script.
; PATROL_COUNT_BASE-level_number therefore shortens the scripted phase as levels advance; at level 16 it is zero.
; -----------------------------------------------------------------------------
follow_scripted_patrol_route:
    TYA                                ; &15C2  98
    TAX                                ; &15C3  AA
    DEC ghost_patrol_counter,X         ; &15C4  D6 51
    LDX ghost_route_phase,Y            ; &15C6  B6 55
    LDA ghost_route_script,X           ; &15C8  BD 30 26
    STA scratch14                      ; &15CB  85 14
    INX                                ; &15CD  E8
    CPX #&12                           ; &15CE  E0 12
    BNE wrap_second_patrol_script                       ; &15D0  D0 02
    LDX #&0C                           ; &15D2  A2 0C
wrap_second_patrol_script:
    CPX #&0A                           ; &15D4  E0 0A
    BNE store_next_patrol_script_phase                       ; &15D6  D0 02
    LDX #&05                           ; &15D8  A2 05
store_next_patrol_script_phase:
    TXA                                ; &15DA  8A
    STA ghost_route_phase,Y            ; &15DB  99 55 00
    LDA scratch14                      ; &15DE  A5 14
    TAX                                ; &15E0  AA
    AND #&01                           ; &15E1  29 01
    BEQ apply_patrol_vertical_code                       ; &15E3  F0 0D
    TYA                                ; &15E5  98
    AND #&01                           ; &15E6  29 01
    ASL A                              ; &15E8  0A
    EOR scratch14                      ; &15E9  45 14
    CMP #&03                           ; &15EB  C9 03
    BEQ turn_ghost_right                       ; &15ED  F0 B0
    JMP turn_ghost_left                       ; &15EF  4C 50 15
apply_patrol_vertical_code:
    CPX #&02                           ; &15F2  E0 02
    BEQ turn_ghost_up                       ; &15F4  F0 3D
    JMP turn_ghost_down                       ; &15F6  4C 6F 16
choose_turn_for_horizontal_mover:
    ; Mirror of the vertical-mover decision block: probe the two vertical branches,
    ; then decide whether to continue horizontally or turn.
    LDA object_y,Y                     ; &15F9  B9 07 00
    STA coord_y                        ; &15FC  85 71
    JSR probe_vertical_path_at_y       ; &15FE  20 BC 17
    STA scratch0                       ; &1601  85 00
    LDA object_y,Y                     ; &1603  B9 07 00
    SEC                                ; &1606  38
    SBC #&04                           ; &1607  E9 04
    STA coord_y                        ; &1609  85 71
    JSR probe_vertical_path_at_y       ; &160B  20 BC 17
    STA scratch1                       ; &160E  85 01
    CMP #WALL_COLOUR                           ; &1610  C9 08
    BEQ horizontal_mover_one_vertical_branch_blocked                       ; &1612  F0 A5
evaluate_horizontal_mover_junction:
    JSR probe_horizontal_path          ; &1614  20 86 17
    CMP #WALL_COLOUR                           ; &1617  C9 08
    BNE horizontal_mover_has_forward_path                       ; &1619  D0 1B
    LDA scratch0                       ; &161B  A5 00
    CMP #WALL_COLOUR                           ; &161D  C9 08
    BEQ turn_ghost_up                       ; &161F  F0 12
    LDA scratch1                       ; &1621  A5 01
    CMP #WALL_COLOUR                           ; &1623  C9 08
    BEQ turn_ghost_down                       ; &1625  F0 48
    LDA ghost_patrol_counter,Y         ; &1627  B9 51 00
    BNE follow_scripted_patrol_route                       ; &162A  D0 96
    LDA player_y                       ; &162C  A5 0B
    CMP object_y,Y                     ; &162E  D9 07 00
    BCC turn_ghost_down                       ; &1631  90 3C
turn_ghost_up:
    JMP set_direction_up               ; &1633  4C 59 1D
horizontal_mover_has_forward_path:
    LDA ghost_patrol_counter,Y         ; &1636  B9 51 00
    BNE follow_scripted_patrol_route                       ; &1639  D0 87
    LDA scratch1                       ; &163B  A5 01
    CMP #GHOST_GATE_COLOUR              ; &163D  C9 09
    BEQ consider_down_turn_from_horizontal                       ; &163F  F0 39
    CMP #WALL_COLOUR                           ; &1641  C9 08
    BEQ consider_down_turn_from_horizontal                       ; &1643  F0 35
    LDA scratch0                       ; &1645  A5 00
    CMP #WALL_COLOUR                           ; &1647  C9 08
    BEQ consider_up_turn_from_horizontal                       ; &1649  F0 05
    JSR random_byte                    ; &164B  20 CA 17
    BNE turn_ghost_up                       ; &164E  D0 E3
consider_up_turn_from_horizontal:
    JSR random_byte                    ; &1650  20 CA 17
    BEQ advance_to_next_ghost                       ; &1653  F0 44
    LDA player_y                       ; &1655  A5 0B
    CMP object_y,Y                     ; &1657  D9 07 00
    BCC up_turn_player_above_ghost                       ; &165A  90 07
    LDA object_dy,Y                    ; &165C  B9 29 00
    BMI take_up_turn_if_not_frightened                       ; &165F  30 11
    BPL advance_to_next_ghost                       ; &1661  10 36
up_turn_player_above_ghost:
    LDA object_dy,Y                    ; &1663  B9 29 00
    BPL take_up_turn_if_not_frightened                       ; &1666  10 0A
    BMI advance_to_next_ghost                       ; &1668  30 2F
take_down_turn_if_not_frightened:
    ; Negative FRIGHTENED state suppresses this direct chase turn, adding evasive/random behaviour.
    LDA object_state,Y                 ; &166A  B9 41 00
    BMI advance_to_next_ghost                       ; &166D  30 2A
turn_ghost_down:
    JMP set_direction_down             ; &166F  4C 44 1D
take_up_turn_if_not_frightened:
    ; Negative FRIGHTENED state suppresses this direct chase turn.
    LDA object_state,Y                 ; &1672  B9 41 00
    BMI advance_to_next_ghost                       ; &1675  30 22
    JMP set_direction_up               ; &1677  4C 59 1D
consider_down_turn_from_horizontal:
    JSR random_byte                    ; &167A  20 CA 17
    AND #&07                           ; &167D  29 07
    BEQ take_down_turn_if_not_frightened                       ; &167F  F0 E9
    LDA player_y                       ; &1681  A5 0B
    CMP object_y,Y                     ; &1683  D9 07 00
    BEQ advance_to_next_ghost                       ; &1686  F0 11
    BCS down_turn_player_below_ghost                       ; &1688  B0 0A
    LDA object_dy,Y                    ; &168A  B9 29 00
    BMI take_down_turn_if_not_frightened                       ; &168D  30 DB
    BPL advance_to_next_ghost                       ; &168F  10 08
    JMP turn_ghost_down                       ; &1691  4C 6F 16
down_turn_player_below_ghost:
    LDA object_dy,Y                    ; &1694  B9 29 00
    BPL take_down_turn_if_not_frightened                       ; &1697  10 D1
advance_to_next_ghost:
    DEY                                ; &1699  88
    BMI tick_energizer_countdown                       ; &169A  30 03
    JMP update_ghost_ai                ; &169C  4C B0 14
tick_energizer_countdown:
    LDA energizer_timer                ; &169F  A5 40
    BEQ move_objects_horizontally      ; &16A1  F0 1F
    DEC energizer_timer                ; &16A3  C6 40
    BNE move_objects_horizontally      ; &16A5  D0 1B
    LDY #SOUND_CHANNEL_2_FLUSH           ; &16A7  A0 12
    LDA #&00                           ; &16A9  A9 00
    LDX #&00                           ; &16AB  A2 00
    JSR play_sound                     ; &16AD  20 6D 1D
    LDY #&03                           ; &16B0  A0 03
    LDX #&00                           ; &16B2  A2 00
restore_ghosts_after_energizer:
    LDA object_state,Y                 ; &16B4  B9 41 00
    AND #&40                           ; &16B7  29 40
    BNE next_ghost_state_restore                       ; &16B9  D0 04
    TXA                                ; &16BB  8A
    STA object_state,Y                 ; &16BC  99 41 00
next_ghost_state_restore:
    DEY                                ; &16BF  88
    BPL restore_ghosts_after_energizer                       ; &16C0  10 F2
move_objects_horizontally:
    LDY #&04                           ; &16C2  A0 04
next_horizontal_object:
    LDA movement_pause_timer           ; &16C4  A5 4A
    BEQ try_horizontal_move                       ; &16C6  F0 07
    LDA object_state,Y                 ; &16C8  B9 41 00
    CMP #GHOST_STATE_EATEN                           ; &16CB  C9 FF
    BNE advance_horizontal_object                       ; &16CD  D0 60
try_horizontal_move:
    JSR probe_horizontal_path          ; &16CF  20 86 17
    CMP #WALL_COLOUR                           ; &16D2  C9 08
    BEQ advance_horizontal_object                       ; &16D4  F0 59
    JSR sample_object_horizontal_cell  ; &16D6  20 90 1A
    CMP #POWER_PELLET_CELL_VALUE                           ; &16D9  C9 06
    BNE check_horizontal_ghost_speed_rules                       ; &16DB  D0 15
    CPY #&04                           ; &16DD  C0 04
    BNE check_horizontal_ghost_speed_rules                       ; &16DF  D0 11
    JSR check_power_pellet             ; &16E1  20 A7 1A
    BPL perform_horizontal_move                       ; &16E4  10 2E
apply_half_speed_horizontal_throttle:
    ; Frightened ghosts, and normal ghosts in the horizontal tunnel, move only on
    ; one PB7 phase.  A non-zero bypass flag guarantees the first step after a turn.
    LDA object_move_bypass,Y              ; &16E6  B9 59 00
    BNE perform_horizontal_move                       ; &16E9  D0 29
    LDA USERVIA_ORB                    ; &16EB  AD 60 FE
    BMI advance_horizontal_object                       ; &16EE  30 3F
    BPL perform_horizontal_move                       ; &16F0  10 22
check_horizontal_ghost_speed_rules:
    CPY #&04                           ; &16F2  C0 04
    BEQ perform_horizontal_move                       ; &16F4  F0 1E
    LDA object_dx,Y                    ; &16F6  B9 24 00
    BEQ advance_horizontal_object                       ; &16F9  F0 34
    LDA object_state,Y                 ; &16FB  B9 41 00
    CMP #GHOST_STATE_FRIGHTENED                           ; &16FE  C9 80
    BEQ apply_half_speed_horizontal_throttle                       ; &1700  F0 E4
    LDA object_y,Y                     ; &1702  B9 07 00
    CMP #TUNNEL_Y                      ; &1705  C9 20
    BNE perform_horizontal_move                       ; &1707  D0 0B
    LDA object_x,Y                     ; &1709  B9 02 00
    CMP #TUNNEL_HALF_SPEED_LEFT_X      ; &170C  C9 14
    BCC apply_half_speed_horizontal_throttle                       ; &170E  90 D6
    CMP #TUNNEL_HALF_SPEED_RIGHT_X     ; &1710  C9 3C
    BCS apply_half_speed_horizontal_throttle                       ; &1712  B0 D2
perform_horizontal_move:
    LDA #&00                           ; &1714  A9 00
    STA object_move_bypass,Y              ; &1716  99 59 00
    CLC                                ; &1719  18
    LDA object_x,Y                     ; &171A  B9 02 00
    ADC object_dx,Y                    ; &171D  79 24 00
    CMP #TUNNEL_WRAP_LEFT_SENTINEL     ; &1720  C9 FB
    BNE check_right_tunnel_wrap                       ; &1722  D0 02
    LDA #TUNNEL_WRAP_LEFT_DEST         ; &1724  A9 54
check_right_tunnel_wrap:
    CMP #TUNNEL_WRAP_RIGHT_SENTINEL    ; &1726  C9 55
    BNE store_horizontal_position                       ; &1728  D0 02
    LDA #TUNNEL_WRAP_RIGHT_DEST        ; &172A  A9 FC
store_horizontal_position:
    STA object_x,Y                     ; &172C  99 02 00
advance_horizontal_object:
    DEY                                ; &172F  88
    BMI move_objects_vertically        ; &1730  30 03
    JMP next_horizontal_object                       ; &1732  4C C4 16
move_objects_vertically:
    LDY #&04                           ; &1735  A0 04
next_vertical_object:
    LDA movement_pause_timer           ; &1737  A5 4A
    BEQ try_vertical_move                       ; &1739  F0 07
    LDA object_state,Y                 ; &173B  B9 41 00
    CMP #GHOST_STATE_EATEN                           ; &173E  C9 FF
    BNE advance_vertical_object                       ; &1740  D0 3B
try_vertical_move:
    JSR probe_vertical_path            ; &1742  20 9F 17
    CMP #WALL_COLOUR                           ; &1745  C9 08
    BEQ advance_vertical_object                       ; &1747  F0 34
    JSR sample_object_vertical_cell    ; &1749  20 9A 1A
    CMP #POWER_PELLET_CELL_VALUE                           ; &174C  C9 06
    BNE check_vertical_ghost_speed_rules                       ; &174E  D0 09
    CPY #&04                           ; &1750  C0 04
    BNE check_vertical_ghost_speed_rules                       ; &1752  D0 05
    JSR check_power_pellet             ; &1754  20 A7 1A
    BPL perform_vertical_move                       ; &1757  10 15
check_vertical_ghost_speed_rules:
    ; Vertical half-speed throttling applies to frightened ghosts.  As above,
    ; PB7's alternating sign supplies the every-other-frame cadence.
    CPY #&04                           ; &1759  C0 04
    BEQ perform_vertical_move                       ; &175B  F0 11
    LDA object_state,Y                 ; &175D  B9 41 00
    CMP #GHOST_STATE_FRIGHTENED                           ; &1760  C9 80
    BNE perform_vertical_move                       ; &1762  D0 0A
    LDA object_move_bypass,Y              ; &1764  B9 59 00
    BNE perform_vertical_move                       ; &1767  D0 05
    LDA USERVIA_ORB                    ; &1769  AD 60 FE
    BMI advance_vertical_object                       ; &176C  30 0F
perform_vertical_move:
    LDA #&00                           ; &176E  A9 00
    STA object_move_bypass,Y              ; &1770  99 59 00
    LDA object_y,Y                     ; &1773  B9 07 00
    CLC                                ; &1776  18
    ADC object_dy,Y                    ; &1777  79 29 00
    STA object_y,Y                     ; &177A  99 07 00
advance_vertical_object:
    DEY                                ; &177D  88
    BPL next_vertical_object                       ; &177E  10 B7
    JSR check_player_eats_pellet       ; &1780  20 24 18
    JMP main_game_loop                 ; &1783  4C CB 10
; -----------------------------------------------------------------------------
; EXACT ACTOR/JUNCTION PROBE GEOMETRY
;
; For an actor at top-left logical coordinate (x,y), the four maze-side tests are:
;
;                         U = read_playfield_colour_alt(x+2, y-4)
;                                      |
;                 L = read_playfield_colour(x,   y-2)
;                        [       8x16 actor       ]
;                 R = read_playfield_colour(x+4, y-2)
;                                      |
;                         D = read_playfield_colour_alt(x+2, y)
;
; probe_horizontal_path selects L or R by dx; probe_vertical_path selects U or D by dy.
; The two colour readers deliberately sample a pair of Mode-2 pixels across the relevant leading edge,
; so a turn is rejected if either sampled pixel is WALL_COLOUR.
;
; The rendered maze tile origins are x = 3+3*column, y = 58-3*row.  Once a ghost is on the normal
; 3-unit decision lattice, its junction position is x = 3+3*column, y = 59-3*row; substituting this
; gives (x+y+1) mod 3 = 0, exactly matching check_ghost_decision_point.  Ghost 3 starts directly on
; this lattice at (39,38) = row 7, column 12; the other central ghosts reach it after their first move.
; The invisible gate is encountered at lattice row 6,column 12: its U probe returns logical colour 9.
; -----------------------------------------------------------------------------
probe_horizontal_path:
    LDA object_x,Y                     ; &1786  B9 02 00
compute_horizontal_probe_coords:
    CLC                                ; &1789  18
    ADC object_dx,Y                    ; &178A  79 24 00
    CLC                                ; &178D  18
    ADC object_dx,Y                    ; &178E  79 24 00
    TAX                                ; &1791  AA
    INX                                ; &1792  E8
    INX                                ; &1793  E8
    STX coord_x                        ; &1794  86 70
probe_horizontal_path_at_x:
    LDX object_y,Y                     ; &1796  B6 07
    DEX                                ; &1798  CA
    DEX                                ; &1799  CA
    STX coord_y                        ; &179A  86 71
    JMP read_playfield_colour          ; &179C  4C 55 0E
probe_vertical_path:
    LDA object_y,Y                     ; &179F  B9 07 00
    JSR set_vertical_probe_coords      ; &17A2  20 A8 17
    JMP read_playfield_colour_alt      ; &17A5  4C A5 18
set_vertical_probe_coords:
    CLC                                ; &17A8  18
    ADC object_dy,Y                    ; &17A9  79 29 00
    CLC                                ; &17AC  18
    ADC object_dy,Y                    ; &17AD  79 29 00
    TAX                                ; &17B0  AA
    DEX                                ; &17B1  CA
    DEX                                ; &17B2  CA
    STX coord_y                        ; &17B3  86 71
set_vertical_probe_x:
    LDX object_x,Y                     ; &17B5  B6 02
    INX                                ; &17B7  E8
    INX                                ; &17B8  E8
    STX coord_x                        ; &17B9  86 70
    RTS                                ; &17BB  60
probe_vertical_path_at_y:
    JSR set_vertical_probe_x                       ; &17BC  20 B5 17
    JMP read_playfield_colour_alt      ; &17BF  4C A5 18
modulo_three:
    SEC                                ; &17C2  38
modulo_three_subtract_loop:
    SBC #&03                           ; &17C3  E9 03
    BCS modulo_three_subtract_loop       ; &17C5  B0 FC
    ADC #&03                           ; &17C7  69 03
    RTS                                ; &17C9  60
; -----------------------------------------------------------------------------
 ; Timing-entropy source: read the continuously running User VIA Timer-1 low counter.
; This is not a stateful PRNG and must not be assumed uniformly distributed: the main loop is itself
; synchronised to Timer-1 PB7, so values depend on instruction-path timing within the current frame.
; -----------------------------------------------------------------------------
random_byte:
    LDA USERVIA_T1CL                   ; &17CA  AD 64 FE
    RTS                                ; &17CD  60
skip_blank_high_score_digit:
    TXA                                ; &17CE  8A
    CLC                                ; &17CF  18
    ADC #&20                           ; &17D0  69 20
    TAX                                ; &17D2  AA
    BCC render_low_score_nibble                       ; &17D3  90 35
skip_blank_low_score_digit:
    TXA                                ; &17D5  8A
    CLC                                ; &17D6  18
    ADC #&20                           ; &17D7  69 20
    TAX                                ; &17D9  AA
    BCC advance_score_bcd_byte                       ; &17DA  90 40
; -----------------------------------------------------------------------------
; Add A (lowest two decimal digits, packed BCD) and X (next two) to the three-byte score.
; Internal units are tens of displayed points: six variable digits are rendered into Mode 2 screen RAM at &3320,
; while &33E0 contains a permanently drawn zero, giving the displayed score its trailing 0.
; -----------------------------------------------------------------------------
add_score_bcd_and_redraw:
    STY scratch72                      ; &17DC  84 72
    SED                                ; &17DE  F8
    CLC                                ; &17DF  18
    ADC score_bcd_lo                   ; &17E0  65 34
    STA score_bcd_lo                   ; &17E2  85 34
    TXA                                ; &17E4  8A
    ADC score_bcd_mid                  ; &17E5  65 35
    STA score_bcd_mid                  ; &17E7  85 35
    LDA score_bcd_hi                   ; &17E9  A5 36
    ADC #&00                           ; &17EB  69 00
    STA score_bcd_hi                   ; &17ED  85 36
    CLD                                ; &17EF  D8
    LDX #&00                           ; &17F0  A2 00
    STX score_leading_zero_state       ; &17F2  86 37
    LDY #&02                           ; &17F4  A0 02
render_next_score_bcd_byte:
    STY scratch14                      ; &17F6  84 14
    LDA score_bcd_lo,Y                 ; &17F8  B9 34 00
    LSR A                              ; &17FB  4A
    LSR A                              ; &17FC  4A
    LSR A                              ; &17FD  4A
    LSR A                              ; &17FE  4A
    ORA score_leading_zero_state       ; &17FF  05 37
    BEQ skip_blank_high_score_digit                       ; &1801  F0 CB
    LDY #&F0                           ; &1803  A0 F0
    STY score_leading_zero_state       ; &1805  84 37
    JSR copy_score_digit_graphic       ; &1807  20 7D 18
render_low_score_nibble:
    LDY scratch14                      ; &180A  A4 14
    LDA score_bcd_lo,Y                 ; &180C  B9 34 00
    AND #&0F                           ; &180F  29 0F
    ORA score_leading_zero_state       ; &1811  05 37
    BEQ skip_blank_low_score_digit                       ; &1813  F0 C0
    LDY #&F0                           ; &1815  A0 F0
    STY score_leading_zero_state       ; &1817  84 37
    JSR copy_score_digit_graphic       ; &1819  20 7D 18
advance_score_bcd_byte:
    LDY scratch14                      ; &181C  A4 14
    DEY                                ; &181E  88
    BPL render_next_score_bcd_byte                       ; &181F  10 D5
    LDY scratch72                      ; &1821  A4 72
pellet_check_return:
    RTS                                ; &1823  60
; -----------------------------------------------------------------------------
; Detect an ordinary pellet eaten by Snapper.
; IMPORTANT: there is no independent pellet bitmap.  The maze itself initially draws all 206 TILE_PELLET (&0F)
; cells into Mode 2 screen RAM.  When a moving sprite temporarily covers a pellet, draw_masked_sprite removes
; its &04/&04 pixel pair and remember_pellet_under_sprite caches that screen address.  This routine computes
; Snapper's mouth/probe screen address and consumes a matching cache entry.  restore_hidden_pellets redraws
; every other cached pellet after sprite movement.  pellets_remaining is therefore only the level-completion count.
; -----------------------------------------------------------------------------
check_player_eats_pellet:
    LDX player_x                       ; &1824  A6 06
    INX                                ; &1826  E8
    STX coord_x                        ; &1827  86 70
    LDX player_y                       ; &1829  A6 0B
    DEX                                ; &182B  CA
    DEX                                ; &182C  CA
    STX coord_y                        ; &182D  86 71
    JSR screen_address_from_xy         ; &182F  20 02 0E
    BCS pellet_check_return                       ; &1832  B0 EF
    DEC screen_ptr_lo                  ; &1834  C6 82
    LDX #HIDDEN_PELLET_LAST_OFFSET                           ; &1836  A2 3E
    STX scratch33                      ; &1838  86 33
scan_hidden_pellet_table:
    LDA hidden_pellet_address_table,X  ; &183A  BD C0 25
    CMP screen_ptr_lo                  ; &183D  C5 82
    BNE scan_previous_hidden_pellet_entry                       ; &183F  D0 13
    LDA hidden_pellet_address_table+1,X  ; &1841  BD C1 25
    SEC                                ; &1844  38
    SBC screen_ptr_hi                  ; &1845  E5 83
    BNE scan_previous_hidden_pellet_entry                       ; &1847  D0 0B
    TAY                                ; &1849  A8
    STA (screen_ptr_lo),Y              ; &184A  91 82
    INY                                ; &184C  C8
    STA (screen_ptr_lo),Y              ; &184D  91 82
    STA scratch33                      ; &184F  85 33
    STA hidden_pellet_address_table+1,X  ; &1851  9D C1 25
scan_previous_hidden_pellet_entry:
    DEX                                ; &1854  CA
    DEX                                ; &1855  CA
    BPL scan_hidden_pellet_table                       ; &1856  10 E2
    LDX scratch33                      ; &1858  A6 33
    BNE pellet_check_return                       ; &185A  D0 C7
    DEC pellets_remaining              ; &185C  C6 3E
    LDA #PELLET_SCORE_BCD              ; &185E  A9 01
    JSR add_score_bcd_and_redraw       ; &1860  20 DC 17
    LDY #SOUND_CHANNEL_NOISE_FLUSH       ; &1863  A0 10
    DEC sound_amplitude_hi             ; &1865  C6 60
    LDA #&01                           ; &1867  A9 01
    STA sound_duration_lo              ; &1869  85 63
    INC sound_duration_hi              ; &186B  E6 64
    LDX #SOUND_DIRECT_VOLUME_8           ; &186D  A2 F8
    LDA #&FA                           ; &186F  A9 FA
    JSR play_sound                     ; &1871  20 6D 1D
    INC sound_amplitude_hi             ; &1874  E6 60
    LDA #&FF                           ; &1876  A9 FF
    STA sound_duration_lo              ; &1878  85 63
    DEC sound_duration_hi              ; &187A  C6 64
    RTS                                ; &187C  60
copy_score_digit_graphic:
    LDY #&00                           ; &187D  A0 00
    STA scratch33                      ; &187F  85 33
    ASL A                              ; &1881  0A
    ASL A                              ; &1882  0A
    ASL A                              ; &1883  0A
    ASL A                              ; &1884  0A
    ASL A                              ; &1885  0A
    STA sprite_ptr_lo                  ; &1886  85 80
    LDA scratch33                      ; &1888  A5 33
    AND #&08                           ; &188A  29 08
    BNE select_score_digit_page_25                       ; &188C  D0 04
    LDA #&24                           ; &188E  A9 24
    BNE copy_score_digit_from_page                       ; &1890  D0 02
select_score_digit_page_25:
    LDA #&25                           ; &1892  A9 25
copy_score_digit_from_page:
    STA sprite_ptr_hi                  ; &1894  85 81
copy_score_digit_byte:
    LDA (sprite_ptr_lo),Y              ; &1896  B1 80
    STA SCORE_SCREEN_DIGITS,X                        ; &1898  9D 20 33
    INX                                ; &189B  E8
    INY                                ; &189C  C8
    CPY #&20                           ; &189D  C0 20
    BNE copy_score_digit_byte                       ; &189F  D0 F5
    RTS                                ; &18A1  60
return_zero_alt:
    LDA #&00                           ; &18A2  A9 00
    RTS                                ; &18A4  60
read_playfield_colour_alt:
    JSR screen_address_from_xy_alt     ; &18A5  20 EB 18
    BCS return_zero_alt                ; &18A8  B0 F8
    STY saved_y                        ; &18AA  84 73
    LDY #&00                           ; &18AC  A0 00
    STY scratch72                      ; &18AE  84 72
    LDA (screen_ptr_lo),Y              ; &18B0  B1 82
sample_alt_first_mode2_pixel_bits:
    LSR A                              ; &18B2  4A
    STA scratch14                      ; &18B3  85 14
    AND pixel_bit_masks,Y              ; &18B5  39 4E 0E
    ORA scratch72                      ; &18B8  05 72
    STA scratch72                      ; &18BA  85 72
    LDA scratch14                      ; &18BC  A5 14
    INY                                ; &18BE  C8
    CPY #&04                           ; &18BF  C0 04
    BNE sample_alt_first_mode2_pixel_bits ; &18C1  D0 EF
    LDY saved_y                        ; &18C3  A4 73
    LDA scratch72                      ; &18C5  A5 72
    CMP #&08                           ; &18C7  C9 08
    BNE sample_alt_companion_mode2_pixel ; &18C9  D0 01
    RTS                                ; &18CB  60
sample_alt_companion_mode2_pixel:
    JSR screen_address_from_xy         ; &18CC  20 02 0E
    LDY #&00                           ; &18CF  A0 00
    STY scratch72                      ; &18D1  84 72
    LDA (screen_ptr_lo),Y              ; &18D3  B1 82
sample_alt_companion_mode2_pixel_bits:
    LSR A                              ; &18D5  4A
    STA scratch14                      ; &18D6  85 14
    AND pixel_bit_masks,Y              ; &18D8  39 4E 0E
    ORA scratch72                      ; &18DB  05 72
    STA scratch72                      ; &18DD  85 72
    LDA scratch14                      ; &18DF  A5 14
    INY                                ; &18E1  C8
    CPY #&04                           ; &18E2  C0 04
    BNE sample_alt_companion_mode2_pixel_bits ; &18E4  D0 EF
    LDY saved_y                        ; &18E6  A4 73
    LDA scratch72                      ; &18E8  A5 72
    RTS                                ; &18EA  60
screen_address_from_xy_alt:
    LDA #&0C                           ; &18EB  A9 0C
    STA screen_ptr_hi                  ; &18ED  85 83
    LDA coord_x                        ; &18EF  A5 70
    ASL A                              ; &18F1  0A
    STA screen_ptr_lo                  ; &18F2  85 82
    ROL screen_ptr_lo                  ; &18F4  26 82
    ROL screen_ptr_hi                  ; &18F6  26 83
    ROL screen_ptr_lo                  ; &18F8  26 82
    ROL screen_ptr_hi                  ; &18FA  26 83
    LDA coord_y                        ; &18FC  A5 71
    ASL A                              ; &18FE  0A
    ASL A                              ; &18FF  0A
    EOR #&FF                           ; &1900  49 FF
    STA screen_y_work                  ; &1902  85 74
    JMP finish_screen_address_calculation ; &1904  4C 27 0E
; -----------------------------------------------------------------------------
; Draw one maze tile selected through tile_graphics_pointer_table.
; The X loop executes 12 times = 12 raster scanlines.  On each scanline Y visits &10,&08,&00,
; copying three Mode-2 bytes = six pixels.  The source pointer's 8-line boundary adjustment jumps
; over four padding bytes per 8-byte plane block; consequently only 36 bytes of the fixed 48-byte
; MAZE_TILE_BYTES stride are rendered and 12 bytes are padding.  Final tile size: 6 x 12 pixels.
; -----------------------------------------------------------------------------
draw_tile_block:
    ASL A                              ; &1907  0A
    STA requested_sprite_id            ; &1908  85 84
    TYA                                ; &190A  98
    PHA                                ; &190B  48
    TXA                                ; &190C  8A
    PHA                                ; &190D  48
    JSR screen_address_from_xy_alt     ; &190E  20 EB 18
    LDX requested_sprite_id            ; &1911  A6 84
    LDA tile_graphics_pointer_table,X  ; &1913  BD 40 25
    STA sprite_ptr_lo                  ; &1916  85 80
    LDA tile_graphics_pointer_table+1,X  ; &1918  BD 41 25
    STA sprite_ptr_hi                  ; &191B  85 81
    LDX #&0B                           ; &191D  A2 0B
draw_tile_next_column:
    LDY #&10                           ; &191F  A0 10
draw_tile_scan_bytes:
    LDA (sprite_ptr_lo),Y              ; &1921  B1 80
    STA (screen_ptr_lo),Y              ; &1923  91 82
    TYA                                ; &1925  98
    SEC                                ; &1926  38
    SBC #&08                           ; &1927  E9 08
    TAY                                ; &1929  A8
    BPL draw_tile_scan_bytes                       ; &192A  10 F5
    DEX                                ; &192C  CA
    BMI tile_draw_done                       ; &192D  30 2C
    INC sprite_ptr_lo                  ; &192F  E6 80
    LDY sprite_ptr_lo                  ; &1931  A4 80
    TYA                                ; &1933  98
    AND #&07                           ; &1934  29 07
    BNE advance_tile_screen_column                       ; &1936  D0 0B
    DEY                                ; &1938  88
    TYA                                ; &1939  98
    CLC                                ; &193A  18
    ADC #&11                           ; &193B  69 11
    STA sprite_ptr_lo                  ; &193D  85 80
    BCC advance_tile_screen_column                       ; &193F  90 02
    INC sprite_ptr_hi                  ; &1941  E6 81
advance_tile_screen_column:
    INC screen_ptr_lo                  ; &1943  E6 82
    LDY screen_ptr_lo                  ; &1945  A4 82
    TYA                                ; &1947  98
    AND #&07                           ; &1948  29 07
    BNE draw_tile_next_column                       ; &194A  D0 D3
    DEY                                ; &194C  88
    TYA                                ; &194D  98
    CLC                                ; &194E  18
    ADC #&79                           ; &194F  69 79
    STA screen_ptr_lo                  ; &1951  85 82
    LDA screen_ptr_hi                  ; &1953  A5 83
    ADC #&02                           ; &1955  69 02
    STA screen_ptr_hi                  ; &1957  85 83
    BCC draw_tile_next_column                       ; &1959  90 C4
tile_draw_done:
    PLA                                ; &195B  68
    TAX                                ; &195C  AA
    PLA                                ; &195D  68
    TAY                                ; &195E  A8
    RTS                                ; &195F  60
; -----------------------------------------------------------------------------
; Initial maze/screen construction: emit the VDU setup stream, patch fixed bitmap details, configure CRTC registers,
; then draw the encoded maze/tile map.
; -----------------------------------------------------------------------------
draw_maze_and_screen:
    LDY #&00                           ; &1960  A0 00
emit_screen_setup_vdu_stream:
    LDA screen_setup_vdu_stream,Y      ; &1962  B9 80 1F
    JSR OSWRCH                         ; &1965  20 EE FF
    INY                                ; &1968  C8
    CPY #&78                           ; &1969  C0 78
    BNE emit_screen_setup_vdu_stream                       ; &196B  D0 F5
    ; These direct screen-RAM writes repair/complete a set of isolated maze-edge pixels
    ; after the VDU outline is drawn.  They are fixed bitmap addresses, not game state.
    LDA #&C0                           ; &196D  A9 C0
    LDY #&01                           ; &196F  A0 01
patch_static_maze_pixels_loop:
    STA &5591,Y                        ; &1971  99 91 55
    STA &5D11,Y                        ; &1974  99 11 5D
    STA &5F71,Y                        ; &1977  99 71 5F
    STA &52F5,Y                        ; &197A  99 F5 52
    STA &57F1,Y                        ; &197D  99 F1 57
    STA &57F9,Y                        ; &1980  99 F9 57
    STA &5F79,Y                        ; &1983  99 79 5F
    STA &61F5,Y                        ; &1986  99 F5 61
    STA &70F5,Y                        ; &1989  99 F5 70
    STA &5573,Y                        ; &198C  99 73 55
    STA &6473,Y                        ; &198F  99 73 64
    STA &7373,Y                        ; &1992  99 73 73
    DEY                                ; &1995  88
    BPL patch_static_maze_pixels_loop                       ; &1996  10 D9
    STA &5D17                          ; &1998  8D 17 5D
    STA &5F90                          ; &199B  8D 90 5F
    STA &5597                          ; &199E  8D 97 55
    STA &5810                          ; &19A1  8D 10 58
    STA &5F77                          ; &19A4  8D 77 5F
    STA &61F0                          ; &19A7  8D F0 61
    STA &5F7F                          ; &19AA  8D 7F 5F
    STA &61F8                          ; &19AD  8D F8 61
    STA &57FF                          ; &19B0  8D FF 57
    STA &5A70                          ; &19B3  8D 70 5A
    STA &5A78                          ; &19B6  8D 78 5A
    STA &57F7                          ; &19B9  8D F7 57
    STA &57FF                          ; &19BC  8D FF 57
    LDA #&80                           ; &19BF  A9 80
    STA &3644                          ; &19C1  8D 44 36
    STA &3645                          ; &19C4  8D 45 36
    STA &3646                          ; &19C7  8D 46 36
    STA &557B                          ; &19CA  8D 7B 55
    STA &61FE                          ; &19CD  8D FE 61
    LDA #&40                           ; &19D0  A9 40
    STA &364C                          ; &19D2  8D 4C 36
    STA &364D                          ; &19D5  8D 4D 36
    STA &364E                          ; &19D8  8D 4E 36
    STA &5F96                          ; &19DB  8D 96 5F
    STA &5313                          ; &19DE  8D 13 53
    LDY #&08                           ; &19E1  A0 08
set_next_maze_palette_entry:
    LDA maze_palette_sequence,Y        ; &19E3  B9 58 26
    JSR set_palette_colour             ; &19E6  20 47 1A
    DEY                                ; &19E9  88
    BPL set_next_maze_palette_entry                       ; &19EA  10 F7
    LDA #&08                           ; &19EC  A9 08
    LDX #&00                           ; &19EE  A2 00
    JSR write_crtc_register            ; &19F0  20 69 1A
    LDA #&0A                           ; &19F3  A9 0A
    LDX #&20                           ; &19F5  A2 20
    JSR write_crtc_register            ; &19F7  20 69 1A
    LDA #&3A                           ; &19FA  A9 3A
    STA coord_y                        ; &19FC  85 71
    LDA #&00                           ; &19FE  A9 00
    STA source_ptr_lo                  ; &1A00  85 7E
    LDA #&23                           ; &1A02  A9 23
    STA source_ptr_hi                  ; &1A04  85 7F
    LDX #MAZE_ROW_COUNT                           ; &1A06  A2 13
draw_next_maze_row:
    LDA #&4E                           ; &1A08  A9 4E
    STA coord_x                        ; &1A0A  85 70
    LDY #MAZE_LAST_PACKED_BYTE_OFFSET                           ; &1A0C  A0 0C
draw_next_packed_maze_byte:
    LDA (source_ptr_lo),Y              ; &1A0E  B1 7E
    STA scratch14                      ; &1A10  85 14
    AND #&0F                           ; &1A12  29 0F
    CPY #MAZE_LAST_PACKED_BYTE_OFFSET                           ; &1A14  C0 0C
    BEQ draw_high_nibble_tile                       ; &1A16  F0 03
    JSR draw_tile_block                ; &1A18  20 07 19
draw_high_nibble_tile:
    DEC coord_x                        ; &1A1B  C6 70
    DEC coord_x                        ; &1A1D  C6 70
    DEC coord_x                        ; &1A1F  C6 70
    LDA scratch14                      ; &1A21  A5 14
    LSR A                              ; &1A23  4A
    LSR A                              ; &1A24  4A
    LSR A                              ; &1A25  4A
    LSR A                              ; &1A26  4A
    JSR draw_tile_block                ; &1A27  20 07 19
    DEC coord_x                        ; &1A2A  C6 70
    DEC coord_x                        ; &1A2C  C6 70
    DEC coord_x                        ; &1A2E  C6 70
    DEY                                ; &1A30  88
    BPL draw_next_packed_maze_byte                       ; &1A31  10 DB
    DEC coord_y                        ; &1A33  C6 71
    DEC coord_y                        ; &1A35  C6 71
    DEC coord_y                        ; &1A37  C6 71
    LDA source_ptr_lo                  ; &1A39  A5 7E
    CLC                                ; &1A3B  18
    ADC #MAZE_PACKED_BYTES_PER_ROW                           ; &1A3C  69 0D
    STA source_ptr_lo                  ; &1A3E  85 7E
    DEX                                ; &1A40  CA
    BNE draw_next_maze_row                       ; &1A41  D0 C5
    TXA                                ; &1A43  8A
    JMP add_score_bcd_and_redraw       ; &1A44  4C DC 17
; Input A packs [logical-colour:physical-selector].  VDU 19 receives the high nibble
; as logical colour; the low nibble is XORed with 7 before being emitted as BBC physical
; colour.  The remaining three VDU 19 bytes are zero.  Palette animation therefore costs
; only this short OSWRCH sequence and never redraws maze/ghost pixels.
set_palette_colour:
    PHA                                ; &1A47  48
    LDA #&13                           ; &1A48  A9 13
    JSR OSWRCH                         ; &1A4A  20 EE FF
    PLA                                ; &1A4D  68
    PHA                                ; &1A4E  48
    LSR A                              ; &1A4F  4A
    LSR A                              ; &1A50  4A
    LSR A                              ; &1A51  4A
    LSR A                              ; &1A52  4A
    JSR OSWRCH                         ; &1A53  20 EE FF
    PLA                                ; &1A56  68
    AND #&0F                           ; &1A57  29 0F
    EOR #&07                           ; &1A59  49 07
    JSR OSWRCH                         ; &1A5B  20 EE FF
    LDA #&00                           ; &1A5E  A9 00
    JSR OSWRCH                         ; &1A60  20 EE FF
    JSR OSWRCH                         ; &1A63  20 EE FF
    JMP OSWRCH                         ; &1A66  4C EE FF
write_crtc_register:
    PHA                                ; &1A69  48
    LDA #&17                           ; &1A6A  A9 17
    JSR OSWRCH                         ; &1A6C  20 EE FF
    LDA #&00                           ; &1A6F  A9 00
    JSR OSWRCH                         ; &1A71  20 EE FF
    PLA                                ; &1A74  68
    JSR OSWRCH                         ; &1A75  20 EE FF
    TXA                                ; &1A78  8A
    JSR OSWRCH                         ; &1A79  20 EE FF
    LDA #&00                           ; &1A7C  A9 00
    JSR OSWRCH                         ; &1A7E  20 EE FF
    JSR OSWRCH                         ; &1A81  20 EE FF
    JSR OSWRCH                         ; &1A84  20 EE FF
    JSR OSWRCH                         ; &1A87  20 EE FF
    JSR OSWRCH                         ; &1A8A  20 EE FF
    JMP OSWRCH                         ; &1A8D  4C EE FF
sample_object_horizontal_cell:
    LDA object_x,Y                     ; &1A90  B9 02 00
    CLC                                ; &1A93  18
    ADC object_dx,Y                    ; &1A94  79 24 00
    JMP compute_horizontal_probe_coords                       ; &1A97  4C 89 17
sample_object_vertical_cell:
    LDA object_y,Y                     ; &1A9A  B9 07 00
    CLC                                ; &1A9D  18
    ADC object_dy,Y                    ; &1A9E  79 29 00
    JSR set_vertical_probe_coords      ; &1AA1  20 A8 17
    JMP read_playfield_colour          ; &1AA4  4C 55 0E
; -----------------------------------------------------------------------------
; Recognise the four power-pellet quadrants and clear their state bits:
;   top-left=&02, top-right=&08, bottom-right=&20, bottom-left=&80.
; Start energizer mode using energizer_duration_for_level, reset the chained ghost score and frighten NORMAL ghosts.
; -----------------------------------------------------------------------------
check_power_pellet:
    ; The movement sampler has already established that Snapper is on a power-pellet
    ; cell.  Exact coordinate equality is unnecessary: x/y halves identify which of
    ; the four corner bits must be cleared.
    LDA player_x                       ; &1AA7  A5 06
    CMP #POWER_PELLET_SPLIT_X           ; &1AA9  C9 28
    BCS select_right_power_pellet_pair                       ; &1AAB  B0 1E
    LDA player_y                       ; &1AAD  A5 0B
    CMP #POWER_PELLET_SPLIT_Y           ; &1AAF  C9 20
    BCS select_bottom_left_power_pellet                       ; &1AB1  B0 0E
    LDA power_pellet_flags             ; &1AB3  A5 3F
    TAX                                ; &1AB5  AA
    AND #POWER_PELLET_TOP_LEFT_BIT                           ; &1AB6  29 02
    BEQ enable_irqs_and_return                       ; &1AB8  F0 65
    TXA                                ; &1ABA  8A
    AND #POWER_PELLET_TOP_LEFT_CLEAR                           ; &1ABB  29 FD
    STA power_pellet_flags             ; &1ABD  85 3F
    BCC activate_energizer_mode                       ; &1ABF  90 2A
select_bottom_left_power_pellet:
    LDA power_pellet_flags             ; &1AC1  A5 3F
    BPL enable_irqs_and_return                       ; &1AC3  10 5A
    AND #POWER_PELLET_BOTTOM_LEFT_CLEAR                           ; &1AC5  29 7F
    STA power_pellet_flags             ; &1AC7  85 3F
    BCS activate_energizer_mode                       ; &1AC9  B0 20
select_right_power_pellet_pair:
    LDA player_y                       ; &1ACB  A5 0B
    CMP #POWER_PELLET_SPLIT_Y           ; &1ACD  C9 20
    BCS select_bottom_right_power_pellet                       ; &1ACF  B0 0E
    LDA power_pellet_flags             ; &1AD1  A5 3F
    TAX                                ; &1AD3  AA
    AND #POWER_PELLET_TOP_RIGHT_BIT                           ; &1AD4  29 08
    BEQ enable_irqs_and_return                       ; &1AD6  F0 47
    TXA                                ; &1AD8  8A
    AND #POWER_PELLET_TOP_RIGHT_CLEAR                           ; &1AD9  29 F7
    STA power_pellet_flags             ; &1ADB  85 3F
    BCC activate_energizer_mode                       ; &1ADD  90 0C
select_bottom_right_power_pellet:
    LDA power_pellet_flags             ; &1ADF  A5 3F
    TAX                                ; &1AE1  AA
    AND #POWER_PELLET_BOTTOM_RIGHT_BIT                           ; &1AE2  29 20
    BEQ enable_irqs_and_return                       ; &1AE4  F0 39
    TXA                                ; &1AE6  8A
    AND #POWER_PELLET_BOTTOM_RIGHT_CLEAR                           ; &1AE7  29 DF
    STA power_pellet_flags             ; &1AE9  85 3F
activate_energizer_mode:
    LDA #&80                           ; &1AEB  A9 80
    LDY #&03                           ; &1AED  A0 03
frighten_next_normal_ghost:
    LDX object_state,Y                 ; &1AEF  B6 41
    BNE next_ghost_to_frighten                       ; &1AF1  D0 03
    STA object_state,Y                 ; &1AF3  99 41 00
next_ghost_to_frighten:
    DEY                                ; &1AF6  88
    BPL frighten_next_normal_ghost                       ; &1AF7  10 F6
    LDA energizer_duration_for_level              ; &1AF9  A5 46
    STA energizer_timer                ; &1AFB  85 40
    LDA #GHOST_EAT_SCORE_SEED            ; &1AFD  A9 10  | MOD: Seed is doubled before each award -> 200/400/800/1600 displayed points.
    STA ghost_eat_score_bcd            ; &1AFF  85 49
    LDA #PALETTE_FRIGHTENED_BLUE        ; &1B01  A9 C3
    JSR set_palette_colour             ; &1B03  20 47 1A
    LDY #&04                           ; &1B06  A0 04
    LDA #POWER_PELLET_SCORE_BCD        ; &1B08  A9 05
    LDX #&00                           ; &1B0A  A2 00
    JMP add_score_bcd_and_redraw       ; &1B0C  4C DC 17
; -----------------------------------------------------------------------------
; Wait for ten vertical-sync events by polling the System VIA CA1/IFR bit.
; -----------------------------------------------------------------------------
wait_ten_vsyncs:
    SEI                                ; &1B0F  78
    LDX #&09                           ; &1B10  A2 09
wait_next_vsync:
    LDA SYSVIA_ORB                     ; &1B12  AD 41 FE
wait_for_vsync_flag:
    LDA SYSVIA_IFR                     ; &1B15  AD 4D FE
    AND #&02                           ; &1B18  29 02
    BEQ wait_for_vsync_flag                       ; &1B1A  F0 F9
    DEX                                ; &1B1C  CA
    BPL wait_next_vsync                       ; &1B1D  10 F3
enable_irqs_and_return:
    CLI                                ; &1B1F  58
    RTS                                ; &1B20  60
delay_ten_clock_ticks:
    LDX #&09                           ; &1B21  A2 09
; -----------------------------------------------------------------------------
; Clock-based delay using OSWORD 1. X controls the number of clock ticks waited; registers are preserved.
; -----------------------------------------------------------------------------
delay_clock_ticks_from_x:
    PHA                                ; &1B23  48
    TXA                                ; &1B24  8A
    PHA                                ; &1B25  48
    TYA                                ; &1B26  98
    PHA                                ; &1B27  48
    INX                                ; &1B28  E8
    STX delay_ticks_remaining          ; &1B29  86 67
wait_for_next_mos_clock_tick:
    LDX #&B8                           ; &1B2B  A2 B8
    LDY #&25                           ; &1B2D  A0 25
    LDA #&01                           ; &1B2F  A9 01
    JSR OSWORD                         ; &1B31  20 F1 FF
    LDA clock_read_buffer              ; &1B34  AD B8 25
    CMP delay_last_clock_tick          ; &1B37  C5 66
    BEQ wait_for_next_mos_clock_tick                       ; &1B39  F0 F0
    STA delay_last_clock_tick          ; &1B3B  85 66
    DEC delay_ticks_remaining          ; &1B3D  C6 67
    BPL wait_for_next_mos_clock_tick                       ; &1B3F  10 EA
    PLA                                ; &1B41  68
    TAY                                ; &1B42  A8
    PLA                                ; &1B43  68
    TAX                                ; &1B44  AA
    PLA                                ; &1B45  68
    RTS                                ; &1B46  60
redraw_all_objects:
    LDA #&21                           ; &1B47  A9 21
    STA sprite_id                      ; &1B49  85 1A
    LDA #&00                           ; &1B4B  A9 00
    STA sprite_and_mask                ; &1B4D  85 13
    LDY #&03                           ; &1B4F  A0 03
redraw_next_ghost_clear_area:
    LDA object_x,Y                     ; &1B51  B9 02 00
    BPL clamp_redraw_ghost_right_edge                       ; &1B54  10 02
    LDA #&00                           ; &1B56  A9 00
clamp_redraw_ghost_right_edge:
    CMP #&4C                           ; &1B58  C9 4C
    BMI draw_redraw_ghost_clear_area                       ; &1B5A  30 02
    LDA #&4B                           ; &1B5C  A9 4B
draw_redraw_ghost_clear_area:
    STA coord_x                        ; &1B5E  85 70
    LDA object_y,Y                     ; &1B60  B9 07 00
    STA coord_y                        ; &1B63  85 71
    LDA #&22                           ; &1B65  A9 22
    JSR draw_masked_sprite             ; &1B67  20 01 0F
    DEY                                ; &1B6A  88
    BPL redraw_next_ghost_clear_area                       ; &1B6B  10 E4
    LDA #FRUIT_X                        ; &1B6D  A9 27
    STA coord_x                        ; &1B6F  85 70
    LDA #FRUIT_Y                        ; &1B71  A9 11
    STA coord_y                        ; &1B73  85 71
    LDA #&22                           ; &1B75  A9 22
    JMP draw_masked_sprite             ; &1B77  4C 01 0F
; -----------------------------------------------------------------------------
; Level-complete sequence. Increment/cap difficulty, flash the maze, then shorten the *next power pellet's frightened
; duration* by ENERGIZER_DURATION_STEP down to MIN_ENERGIZER_DURATION.  Main frame speed is controlled separately by
; the User VIA Timer-1 value programmed in start_level.
; -----------------------------------------------------------------------------
level_complete:
    LDA #&00                           ; &1B7A  A9 00
    LDX #&00                           ; &1B7C  A2 00
    LDY #SOUND_CHANNEL_2_FLUSH           ; &1B7E  A0 12
    JSR play_sound                     ; &1B80  20 6D 1D
    INC level_number                   ; &1B83  E6 3D
    LDA level_number                   ; &1B85  A5 3D
    CMP #MAX_DIFFICULTY_LEVEL          ; &1B87  C9 10
    BCC begin_level_complete_flash                       ; &1B89  90 04
    LDA #MAX_DIFFICULTY_LEVEL          ; &1B8B  A9 10
    STA level_number                   ; &1B8D  85 3D
begin_level_complete_flash:
    JSR redraw_all_objects             ; &1B8F  20 47 1B
    DEC sprite_and_mask                ; &1B92  C6 13
    LDA player_x                       ; &1B94  A5 06
    STA coord_x                        ; &1B96  85 70
    LDA player_y                       ; &1B98  A5 0B
    STA coord_y                        ; &1B9A  85 71
    LDA player_sprite_base                    ; &1B9C  A5 10
    ORA player_facing                  ; &1B9E  05 23
    JSR draw_masked_sprite             ; &1BA0  20 01 0F
    LDY #&07                           ; &1BA3  A0 07
level_complete_flash_loop:
    ; Y starts at 7 and loops through zero: eight white/blue cycles.  Each colour is held for
    ; ten VSYNCs, so the sequence consumes 160 VSYNC periods (about 3.2 s on a 50 Hz BBC display).
    LDA #PALETTE_MAZE_WHITE             ; &1BA5  A9 80
    JSR set_palette_colour             ; &1BA7  20 47 1A
    JSR wait_ten_vsyncs                ; &1BAA  20 0F 1B
    LDA #PALETTE_MAZE_BLUE              ; &1BAD  A9 83
    JSR set_palette_colour             ; &1BAF  20 47 1A
    JSR wait_ten_vsyncs                ; &1BB2  20 0F 1B
    DEY                                ; &1BB5  88
    BPL level_complete_flash_loop                       ; &1BB6  10 ED
    LDA energizer_duration_for_level              ; &1BB8  A5 46
    SEC                                ; &1BBA  38
    SBC #ENERGIZER_DURATION_STEP              ; &1BBB  E9 10  | MOD: Reduce frightened duration after each completed level.
    CMP #MIN_ENERGIZER_DURATION         ; &1BBD  C9 64  | MOD: Floor for frightened duration; does not control frame speed.
    BCS store_next_energizer_duration                       ; &1BBF  B0 02
    LDA #MIN_ENERGIZER_DURATION         ; &1BC1  A9 64
store_next_energizer_duration:
    STA energizer_duration_for_level              ; &1BC3  85 46
    JMP start_level                       ; &1BC5  4C D4 0F
handle_eaten_ghost:
    LDA #&00                           ; &1BC8  A9 00
    STA sprite_and_mask                ; &1BCA  85 13
    LDA #&21                           ; &1BCC  A9 21
    STA sprite_id                      ; &1BCE  85 1A
    LDA object_x,Y                     ; &1BD0  B9 02 00
    STA coord_x                        ; &1BD3  85 70
    LDA object_y,Y                     ; &1BD5  B9 07 00
    STA coord_y                        ; &1BD8  85 71
    LDA #&22                           ; &1BDA  A9 22
    JSR draw_masked_sprite             ; &1BDC  20 01 0F
    DEC sprite_and_mask                ; &1BDF  C6 13
    LDA player_x                       ; &1BE1  A5 06
    STA coord_x                        ; &1BE3  85 70
    LDA player_y                       ; &1BE5  A5 0B
    STA coord_y                        ; &1BE7  85 71
    LDA #&22                           ; &1BE9  A9 22
    JSR draw_masked_sprite             ; &1BEB  20 01 0F
    LDA object_x,Y                     ; &1BEE  B9 02 00
    JSR divide_by_three                ; &1BF1  20 B0 1C
    STA scratch14                      ; &1BF4  85 14
    ASL A                              ; &1BF6  0A
    ADC scratch14                      ; &1BF7  65 14
    STA object_x,Y                     ; &1BF9  99 02 00
    LDA object_y,Y                     ; &1BFC  B9 07 00
    SEC                                ; &1BFF  38
    SBC #&05                           ; &1C00  E9 05
    JSR divide_by_three                ; &1C02  20 B0 1C
    STA scratch14                      ; &1C05  85 14
    ASL A                              ; &1C07  0A
    ADC scratch14                      ; &1C08  65 14
    ADC #&05                           ; &1C0A  69 05
    STA object_y,Y                     ; &1C0C  99 07 00
    LDA #GHOST_EAT_PAUSE_FRAMES                           ; &1C0F  A9 0F  | MOD: Number of frames other actors remain paused after a ghost is eaten.
    STA movement_pause_timer           ; &1C11  85 4A
    BNE calculate_eaten_ghost_route_cell                       ; &1C13  D0 1D
choose_ghost_direction:
    ; Eaten ghosts are first snapped to the 3-unit maze grid.  The packed routing
    ; byte index is row*7 + floor(column/4); two bits selected by column&3 then
    ; yield ROUTE_DOWN/RIGHT/UP/LEFT.  This is a precomputed 20x28 "route home" field.
    LDX ghost_route_direction,Y        ; &1C15  B6 4B
    LDA object_x,Y                     ; &1C17  B9 02 00
    CMP #&4E                           ; &1C1A  C9 4E
    BCC check_eaten_ghost_grid_alignment                       ; &1C1C  90 04
    LDA #&4B                           ; &1C1E  A9 4B
    BNE ghost_tunnel_dead_brk_entry                       ; &1C20  D0 12
check_eaten_ghost_grid_alignment:
    JSR modulo_three                   ; &1C22  20 C2 17
    BNE draw_eaten_ghost_eyes                       ; &1C25  D0 5C
    LDA object_y,Y                     ; &1C27  B9 07 00
    CLC                                ; &1C2A  18
    ADC #&01                           ; &1C2B  69 01
    JSR modulo_three                   ; &1C2D  20 C2 17
    BNE draw_eaten_ghost_eyes                       ; &1C30  D0 51
calculate_eaten_ghost_route_cell:
    LDA object_x,Y                     ; &1C32  B9 02 00
    JSR divide_by_three                ; &1C35  20 B0 1C
    STA scratch1                       ; &1C38  85 01
    LSR A                              ; &1C3A  4A
    LSR A                              ; &1C3B  4A
    STA scratch14                      ; &1C3C  85 14
    LDA object_y,Y                     ; &1C3E  B9 07 00
    SEC                                ; &1C41  38
    SBC #&05                           ; &1C42  E9 05
    JSR divide_by_three                ; &1C44  20 B0 1C
    STA scratch0                       ; &1C47  85 00
    ASL A                              ; &1C49  0A
    ASL A                              ; &1C4A  0A
    ASL A                              ; &1C4B  0A
    ADC scratch14                      ; &1C4C  65 14
    SEC                                ; &1C4E  38
    SBC scratch0                       ; &1C4F  E5 00
    TAX                                ; &1C51  AA
    CPX #GHOST_HOME_ROUTE_BYTE_INDEX                           ; &1C52  E0 42
    BEQ ghost_reached_home_cell                       ; &1C54  F0 48
    LDA scratch1                       ; &1C56  A5 01
    AND #&03                           ; &1C58  29 03
    EOR #&03                           ; &1C5A  49 03
    STA scratch1                       ; &1C5C  85 01
    LDA ghost_junction_direction_table,X ; &1C5E  BD D0 1E
    LDX scratch1                       ; &1C61  A6 01
    BEQ apply_packed_route_direction                       ; &1C63  F0 05
shift_packed_route_direction:
    LSR A                              ; &1C65  4A
    LSR A                              ; &1C66  4A
    DEX                                ; &1C67  CA
    BNE shift_packed_route_direction                       ; &1C68  D0 FB
apply_packed_route_direction:
    AND #&03                           ; &1C6A  29 03
    TAX                                ; &1C6C  AA
    STA ghost_route_direction,Y        ; &1C6D  99 4B 00
    LDA route_dx_table,X               ; &1C70  BD C8 1E
    STA object_dx,Y                    ; &1C73  99 24 00
    LDA route_dy_table,X               ; &1C76  BD CC 1E
    STA object_dy,Y                    ; &1C79  99 29 00
    LDA movement_pause_timer           ; &1C7C  A5 4A
    CMP #GHOST_EAT_PAUSE_FRAMES                           ; &1C7E  C9 0F
    BNE draw_eaten_ghost_eyes                       ; &1C80  D0 01
    RTS                                ; &1C82  60
draw_eaten_ghost_eyes:
    LDA object_x,Y                     ; &1C83  B9 02 00
    STA coord_x                        ; &1C86  85 70
    LDA object_y,Y                     ; &1C88  B9 07 00
    STA coord_y                        ; &1C8B  85 71
    LDA #GHOST_STATE_EATEN                           ; &1C8D  A9 FF
    STA sprite_and_mask                ; &1C8F  85 13
    LDA eaten_ghost_sprite_ids,X  ; &1C91  BD 5C 1F
    STA sprite_id                      ; &1C94  85 1A
    LDA #&22                           ; &1C96  A9 22
    JSR draw_masked_sprite             ; &1C98  20 01 0F
    JMP advance_to_next_draw_object                       ; &1C9B  4C 88 12
; -----------------------------------------------------------------------------
; The eaten-ghost return path has reached packed route-table BYTE index &42.  &42 = row 9, byte-group 3,
; i.e. the four-cell column group 12..15 of the 20x28 routing field.  The test happens before selecting
; the individual 2-bit cell, so this is deliberately a four-cell-wide home/re-entry band, not one exact point.
; Restore NORMAL state and give the ghost a downward initial direction so it rejoins ordinary movement;
; later, passing exact object coordinate (&27,&28) refreshes its level-dependent patrol counter/phase.
; -----------------------------------------------------------------------------
ghost_reached_home_cell:
    LDA #&FC                           ; &1C9E  A9 FC
    STA object_probe_offset,Y          ; &1CA0  99 2E 00
    LDX #GHOST_STATE_NORMAL                           ; &1CA3  A2 00
    STX object_state,Y                 ; &1CA5  96 41
    INX                                ; &1CA7  E8
    STX object_dy,Y                    ; &1CA8  96 29
    INX                                ; &1CAA  E8
    STX object_facing,Y                ; &1CAB  96 1F
    JMP advance_to_next_draw_object                       ; &1CAD  4C 88 12
divide_by_three:
    LDX #&FF                           ; &1CB0  A2 FF
    SEC                                ; &1CB2  38
divide_by_three_loop:
    INX                                ; &1CB3  E8
    SBC #&03                           ; &1CB4  E9 03
    BPL divide_by_three_loop                       ; &1CB6  10 FB
    TXA                                ; &1CB8  8A
    RTS                                ; &1CB9  60
; -----------------------------------------------------------------------------
; Restore ordinary pellets temporarily hidden by sprite drawing.
; Each non-zero table entry is a little-endian Mode 2 screen address.  A still-covered address is left
; pending; an exposed address is redrawn as the two &04 bytes used by TILE_PELLET.  If the cache entry
; was cleared by check_player_eats_pellet, that pellet is permanently gone for the current level.
; -----------------------------------------------------------------------------
restore_hidden_pellets:
    LDX #HIDDEN_PELLET_LAST_OFFSET                           ; &1CBA  A2 3E
restore_next_hidden_pellet:
    LDY #&00                           ; &1CBC  A0 00
    LDA hidden_pellet_address_table+1,X                        ; &1CBE  BD C1 25
    BEQ advance_hidden_pellet_restore                       ; &1CC1  F0 25
    STA coord_y                        ; &1CC3  85 71
    LDA hidden_pellet_address_table,X  ; &1CC5  BD C0 25
    STA coord_x                        ; &1CC8  85 70
    LDA (coord_x),Y                    ; &1CCA  B1 70
    BEQ restore_hidden_pellet_pixels                       ; &1CCC  F0 12
    CMP #PELLET_BITMAP_BYTE             ; &1CCE  C9 04
    BNE advance_hidden_pellet_restore                       ; &1CD0  D0 16
    INY                                ; &1CD2  C8
    LDA (coord_x),Y                    ; &1CD3  B1 70
    BEQ restore_hidden_pellet_pixels                       ; &1CD5  F0 09
    CMP #PELLET_BITMAP_BYTE             ; &1CD7  C9 04
    BNE advance_hidden_pellet_restore                       ; &1CD9  D0 0D
    LDA #&00                           ; &1CDB  A9 00
    STA hidden_pellet_address_table+1,X                        ; &1CDD  9D C1 25
restore_hidden_pellet_pixels:
    TAY                                ; &1CE0  A8
    LDA #PELLET_BITMAP_BYTE             ; &1CE1  A9 04
    STA (coord_x),Y                    ; &1CE3  91 70
    INY                                ; &1CE5  C8
    STA (coord_x),Y                    ; &1CE6  91 70
advance_hidden_pellet_restore:
    DEX                                ; &1CE8  CA
    DEX                                ; &1CE9  CA
    BPL restore_next_hidden_pellet                       ; &1CEA  10 D0
    RTS                                ; &1CEC  60
play_death_sound_sweep:
    LDX #&08                           ; &1CED  A2 08
    STX scratch14                      ; &1CEF  86 14
death_sound_sweep_step:
    LDY #SOUND_CHANNEL_1_FLUSH           ; &1CF1  A0 11
    LDX #SOUND_DIRECT_VOLUME_8           ; &1CF3  A2 F8
    DEC sound_amplitude_hi             ; &1CF5  C6 60
    LDA scratch14                      ; &1CF7  A5 14
    AND #&01                           ; &1CF9  29 01
    BNE death_sound_adjust_pitch                       ; &1CFB  D0 04
    INC sound_sweep_pitch              ; &1CFD  E6 65
    INC sound_sweep_pitch              ; &1CFF  E6 65
death_sound_adjust_pitch:
    DEC sound_sweep_pitch              ; &1D01  C6 65
    LDA scratch14                      ; &1D03  A5 14
    AND #&02                           ; &1D05  29 02
    BNE death_sound_emit_tone                       ; &1D07  D0 07
    LDA sound_sweep_pitch              ; &1D09  A5 65
    SEC                                ; &1D0B  38
    SBC #&04                           ; &1D0C  E9 04
    STA sound_sweep_pitch              ; &1D0E  85 65
death_sound_emit_tone:
    LDA sound_sweep_pitch              ; &1D10  A5 65
    ASL A                              ; &1D12  0A
    JSR play_sound                     ; &1D13  20 6D 1D
    LDX #&01                           ; &1D16  A2 01
    JSR delay_clock_ticks_from_x       ; &1D18  20 23 1B
    DEC scratch14                      ; &1D1B  C6 14
    BPL death_sound_sweep_step                       ; &1D1D  10 D2
shared_return_rts:
    RTS                                ; &1D1F  60
; -----------------------------------------------------------------------------
; Force object Y to move left (dx=-1, dy=0) and update its facing/probe offsets.
; -----------------------------------------------------------------------------
set_direction_left:
    LDX #&FF                           ; &1D20  A2 FF
    STX object_move_bypass,Y              ; &1D22  96 59
    STX object_dx,Y                    ; &1D24  96 24
    INX                                ; &1D26  E8
    STX object_dy,Y                    ; &1D27  96 29
    STX object_facing,Y                ; &1D29  96 1F
    LDA #&04                           ; &1D2B  A9 04
    STA object_probe_offset,Y          ; &1D2D  99 2E 00
    JMP advance_to_next_ghost                       ; &1D30  4C 99 16
; -----------------------------------------------------------------------------
; Force object Y to move right (dx=+1, dy=0) and update its facing/probe offsets.
; -----------------------------------------------------------------------------
set_direction_right:
    LDX #&01                           ; &1D33  A2 01
    STX object_dx,Y                    ; &1D35  96 24
    STX object_facing,Y                ; &1D37  96 1F
    DEX                                ; &1D39  CA
    STX object_dy,Y                    ; &1D3A  96 29
    DEX                                ; &1D3C  CA
    STX object_move_bypass,Y              ; &1D3D  96 59
    STX object_probe_offset,Y          ; &1D3F  96 2E
    JMP advance_to_next_ghost                       ; &1D41  4C 99 16
; -----------------------------------------------------------------------------
; Force object Y to move down (dx=0, dy=+1) and update its facing/probe offsets.
; -----------------------------------------------------------------------------
set_direction_down:
    LDX #&00                           ; &1D44  A2 00
    STX object_dx,Y                    ; &1D46  96 24
    INX                                ; &1D48  E8
    STX object_dy,Y                    ; &1D49  96 29
    INX                                ; &1D4B  E8
    STX object_facing,Y                ; &1D4C  96 1F
    LDA #&FC                           ; &1D4E  A9 FC
    STA object_move_bypass,Y              ; &1D50  99 59 00
    STA object_probe_offset,Y          ; &1D53  99 2E 00
    JMP advance_to_next_ghost                       ; &1D56  4C 99 16
; -----------------------------------------------------------------------------
; Force object Y to move up (dx=0, dy=-1) and update its facing/probe offsets.
; -----------------------------------------------------------------------------
set_direction_up:
    LDX #&FF                           ; &1D59  A2 FF
    STX object_dy,Y                    ; &1D5B  96 29
    STX object_move_bypass,Y              ; &1D5D  96 59
    LDA #&03                           ; &1D5F  A9 03
    STA object_facing,Y                ; &1D61  99 1F 00
    INX                                ; &1D64  E8
    STX object_dx,Y                    ; &1D65  96 24
    INX                                ; &1D67  E8
    STX object_probe_offset,Y          ; &1D68  96 2E
    JMP advance_to_next_ghost                       ; &1D6A  4C 99 16
; -----------------------------------------------------------------------------
; Central sound wrapper. Builds the OSWORD 7 SOUND control block at &5D and tail-calls OSWORD.
; Call-site map now resolved:
;   READY tune      channels 1 + 3, direct volume -12, packed pitches/durations
;   fruit eaten     channel 1 flush, ENVELOPE 2, pitch &30
;   ghost eaten     channel 1 flush, ENVELOPE 2, pitch &48; channel 2 is then silenced
;   energizer hum   channel 2 flush, ENVELOPE 1, pitch sweeps from energizer_timer
;   ordinary pellet noise channel flush, direct volume -8, pitch/noise value &FA
;   death sweep     channel 1 flush, direct volume -8, generated pitch sequence
; Calls with channel &12 and amplitude 0 silence/flush the energizer channel at transitions.
; -----------------------------------------------------------------------------
play_sound:
    STA sound_pitch_lo                 ; &1D6D  85 61
    STY sound_channel_lo               ; &1D6F  84 5D
    STX sound_amplitude_lo             ; &1D71  86 5F
    LDA #&07                           ; &1D73  A9 07
    LDX #&5D                           ; &1D75  A2 5D
    LDY #&00                           ; &1D77  A0 00
    JMP OSWORD                         ; &1D79  4C F1 FF
; -----------------------------------------------------------------------------
; A moving masked sprite has covered an ordinary pellet.
; Snap the screen pointer to the pellet's two-byte Mode 2 cell, clear those bytes, and insert the
; address into the 32-entry transient occlusion cache.  This is how pellets survive ghosts passing over
; them without needing a second pellet map.  The strange full-cache path enters &0FEE in the middle of
; another instruction stream; it is retained exactly and documented below rather than "fixed".
; -----------------------------------------------------------------------------
remember_pellet_under_sprite:
    LDA screen_ptr_lo                  ; &1D7C  A5 82
    AND #&FE                           ; &1D7E  29 FE
    STA pellet_addr_lo                 ; &1D80  85 68
    LDA screen_ptr_hi                  ; &1D82  A5 83
    STA pellet_addr_hi                 ; &1D84  85 69
    INY                                ; &1D86  C8
    LDA #&00                           ; &1D87  A9 00
    STA (pellet_addr_lo),Y             ; &1D89  91 68
    DEY                                ; &1D8B  88
    TXA                                ; &1D8C  8A
    PHA                                ; &1D8D  48
    TYA                                ; &1D8E  98
    CLC                                ; &1D8F  18
    ADC pellet_addr_lo                 ; &1D90  65 68
    PHA                                ; &1D92  48
    LDA pellet_addr_hi                 ; &1D93  A5 69
    ADC #&00                           ; &1D95  69 00
    PHA                                ; &1D97  48
    LDX #HIDDEN_PELLET_LAST_OFFSET                           ; &1D98  A2 3E
find_free_hidden_pellet_slot:
    LDA hidden_pellet_address_table+1,X                        ; &1D9A  BD C1 25
    BNE try_previous_hidden_pellet_slot                       ; &1D9D  D0 0B
    PLA                                ; &1D9F  68
    STA hidden_pellet_address_table+1,X                        ; &1DA0  9D C1 25
    PLA                                ; &1DA3  68
    STA hidden_pellet_address_table,X  ; &1DA4  9D C0 25
    PLA                                ; &1DA7  68
    TAX                                ; &1DA8  AA
    RTS                                ; &1DA9  60
try_previous_hidden_pellet_slot:
    DEX                                ; &1DAA  CA
    DEX                                ; &1DAB  CA
    BPL find_free_hidden_pellet_slot                       ; &1DAC  10 EC
    PLA                                ; &1DAE  68
    PLA                                ; &1DAF  68
    PLA                                ; &1DB0  68
    TAX                                ; &1DB1  AA
    LDA #&2A                           ; &1DB2  A9 2A
    JMP hidden_pellet_overflow_recovery                       ; &1DB4  4C EE 0F
; -----------------------------------------------------------------------------
 ; Final death frame (&27), geometry &0F,&18 = 8x16.  Its first header byte is NOT emitted here: the pointer is &1DB6,
; which is the high-byte operand (&0F) of the JMP immediately above.  Thus the original saves
; one byte by sharing executable code with sprite data.  Bytes below begin at header byte 2.
; -----------------------------------------------------------------------------
death_sprite_frame_4_body:
    EQUB &18,&0A,&0A,&05,&05,&00,&00,&00,&0F,&00,&00,&00,&05,&0A,&00,&00 ; &1DB7
    EQUB &0A,&0A,&0A,&0A,&00,&05,&00,&00,&05,&05,&05,&0A,&0A,&00,&00,&00 ; &1DC7
    EQUB &0F,&0F,&00,&00,&00,&05,&05,&0A,&0A,&0A,&00,&00,&0A,&00,&05,&05 ; &1DD7
    EQUB &05,&05,&00,&00,&05,&0A,&00,&00,&00,&0F,&00,&00,&00,&0A,&0A,&05 ; &1DE7
    EQUB &05,&00,&00,&00,&00,&00,&0F                                     ; &1DF7
; -----------------------------------------------------------------------------
; Death animation frame &26.
; -----------------------------------------------------------------------------
death_sprite_frame_3:
    EQUB &07,&18,&00,&00,&00,&00,&00,&05,&00,&00,&00,&00,&00,&00,&0A,&0F ; &1DFE
    EQUB &0F,&05,&00,&00,&00,&00,&0A,&0F,&0A,&00,&00,&00,&00,&00,&00,&00 ; &1E0E
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &1E1E
; -----------------------------------------------------------------------------
; Death animation frame &25.
; -----------------------------------------------------------------------------
death_sprite_frame_2:
    EQUB &07,&18,&00,&00,&00,&00,&0F,&05,&05,&00,&00,&00,&00,&00,&0A,&0F ; &1E26
    EQUB &0F,&0F,&00,&00,&00,&00,&0F,&0F,&0F,&0A,&00,&00,&00,&00,&0A,&00 ; &1E36
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &1E46
; -----------------------------------------------------------------------------
; Death animation frame &24.
; -----------------------------------------------------------------------------
death_sprite_frame_1:
    EQUB &07,&18,&00,&0A,&0A,&0F,&0F,&05,&05,&00,&00,&00,&00,&00,&0A,&0F ; &1E4E
    EQUB &0F,&0F,&00,&00,&00,&05,&0F,&0F,&0F,&0A,&00,&0A,&0A,&0A,&0A,&00 ; &1E5E
    EQUB &00,&00,&00,&00,&00,&00,&00,&0F                                 ; &1E6E
; -----------------------------------------------------------------------------
; Death animation frame &23 (first frame shown).
; -----------------------------------------------------------------------------
death_sprite_frame_0:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&0A,&0A,&0F,&00,&00,&00,&00,&00,&00 ; &1E76
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&05,&00,&00,&00,&00,&00,&0A ; &1E86
    EQUB &0A,&0A,&0F,&0F,&0F,&0F,&0F,&05,&05,&00,&00,&00,&0A,&0A,&0F,&0F ; &1E96
    EQUB &0F,&0F,&05,&05,&0F,&0F,&0F,&0F,&0F,&0A,&0A,&0A,&0A,&0A,&0A,&00 ; &1EA6
    EQUB &00,&00                                                         ; &1EB6
; -----------------------------------------------------------------------------
; READY message/control-code stream.  The draw loop outputs &11 bytes: the first 16 are below,
; and the 17th byte is the &00 at route_dx_table (&1EC8).  This is another deliberate byte share.
; -----------------------------------------------------------------------------
ready_message:
    EQUB &05,&19,&04,&DC,&01,&76,&02,&12,&03,&03,&52,&45,&41,&44,&59,&21 ; &1EB8
; -----------------------------------------------------------------------------
; Direction X deltas indexed by ROUTE_*: down=0, right=+1, up=0, left=-1.
; -----------------------------------------------------------------------------
route_dx_table:
    EQUB &00,&01,&00,&FF                                                 ; &1EC8
; -----------------------------------------------------------------------------
; Direction Y deltas indexed by ROUTE_*: down=+1, right=0, up=-1, left=0.
; -----------------------------------------------------------------------------
route_dy_table:
    EQUB &01,&00,&FF,&00                                                 ; &1ECC
; -----------------------------------------------------------------------------
; EATEN-GHOST RETURN-HOME ROUTING FIELD
; 20 rows x 28 cells.  Each byte packs four 2-bit direction codes in bits 7:6,5:4,3:2,1:0.
; Code 0=D, 1=R, 2=U, 3=L.  choose_ghost_direction computes row*7+floor(col/4).
; The decoded direction rows below are documentation only; EQUB bytes remain original.
; -----------------------------------------------------------------------------
ghost_junction_direction_table:
    ; route row 00: DDRRRRRRRRRRDLDLLLLLLLLLLDDD
    EQUB &05,&55,&55,&33,&FF,&FF,&C0 ; &1ED0
    ; route row 01: DDDDDDDDDDDDDDDDDDDDDDDDDDDD
    EQUB &00,&00,&00,&00,&00,&00,&00 ; &1ED7
    ; route row 02: RRRDRRRDDDLLLDRRRDDDLLLDLLDD
    EQUB &54,&54,&0F,&C5,&40,&FC,&F0 ; &1EDE
    ; route row 03: DDDDDDDDDDDDDDDDDDDDDDDDDDDD
    EQUB &00,&00,&00,&00,&00,&00,&00 ; &1EE5
    ; route row 04: DDLLDDLRRRRRDLDLLLLLRDDRRDDD
    EQUB &0F,&0D,&55,&33,&FF,&41,&40 ; &1EEC
    ; route row 05: DDDDDDDDDDDDDDDDDDDDDDDDDDDD
    EQUB &00,&00,&00,&00,&00,&00,&00 ; &1EF3
    ; route row 06: RRRRRRRDRDLLLDRRRDLDLLLLLLDD
    EQUB &55,&54,&4F,&C5,&4C,&FF,&F0 ; &1EFA
    ; route row 07: DDDDDDDDDDDDDDDDDDDDDDDDDDDD
    EQUB &00,&00,&00,&00,&00,&00,&00 ; &1F01
    ; route row 08: DDDDDDDDDDDDDUDDDDDDDDDDDDDD
    EQUB &00,&00,&00,&20,&00,&00,&00 ; &1F08
    ; route row 09: RRRRRRRRRDDDDUDDDDLLLLLLLLDD
    EQUB &55,&55,&40,&20,&0F,&FF,&F0 ; &1F0F
    ; route row 10: DDDDDDDUDDDDDUDDDDDUDDDDDDDD
    EQUB &00,&02,&00,&20,&02,&00,&00 ; &1F16
    ; route row 11: DDDDDDDUDDDDDUDDDDDUDDDDDDDD
    EQUB &00,&02,&00,&20,&02,&00,&00 ; &1F1D
    ; route row 12: RRRRRDRUDRRRRULLLLDULDLLLLDD
    EQUB &55,&46,&15,&6F,&F2,&CF,&F0 ; &1F24
    ; route row 13: UUDDDDDDDDDDUDUDDDDDDDDDDUDD
    EQUB &A0,&00,&00,&88,&00,&00,&20 ; &1F2B
    ; route row 14: RRRRRRRRRRRRUDULLLLLLLLLLLDD
    EQUB &55,&55,&55,&8B,&FF,&FF,&F0 ; &1F32
    ; route row 15: UUDDDUDDDUDDDDDDDUDDDUDDDUDD
    EQUB &A0,&20,&20,&00,&20,&20,&20 ; &1F39
    ; route row 16: UUDDDUDDDULLLLRRRUDDDUDDDUDD
    EQUB &A0,&20,&2F,&F5,&60,&20,&20 ; &1F40
    ; route row 17: UUDDDUDDDDDDUDUDDDDDDUDDDUDD
    EQUB &A0,&20,&00,&88,&00,&20,&20 ; &1F47
    ; route row 18: UURRRURRRRRRUDULLLLLLULLLUDD
    EQUB &A5,&65,&55,&8B,&FF,&EF,&E0 ; &1F4E
    ; route row 19: DDDDDDRLDDDDDDUUDDDDDRRDDDDD
    EQUB &00,&07,&00,&0A,&00,&14,&00 ; &1F55
; -----------------------------------------------------------------------------
; Eye-overlay sprite IDs indexed by ROUTE_*; this table translates return-map direction to the eye sprite using the separate facing/sprite encoding.
; -----------------------------------------------------------------------------
eaten_ghost_sprite_ids:
    EQUB &0A,&09,&0B,&08                                                 ; &1F5C
; -----------------------------------------------------------------------------
; Eight two-byte packed-BCD score increments indexed by fruit sprite &0E..&15.
; Stored order follows sprite IDs: strawberry 300, cherry 100, orange 500, apple 700,
; melon 1000, key 5000, bell 3000, galaxian 2000.
; -----------------------------------------------------------------------------
fruit_score_bcd_table:
    EQUB &00,&30,&00,&10,&00,&50,&00,&70,&01,&00,&05,&00,&03,&00,&02,&00 ; &1F60
; -----------------------------------------------------------------------------
; 16 bytes with no direct reference from proven reachable code.
; Bytes &1F72-&1F79 are conspicuous: &0F,&0E,&10,&11,&12,&13,&14,&15 are all eight
; fruit sprite IDs, in the canonical score-progression set.  This strongly looks like an
; abandoned/legacy fruit catalogue, but because no live reference has been proved it remains raw EQUB.
; -----------------------------------------------------------------------------
legacy_unreferenced_fruit_catalogue_data:
    EQUB &05,&00,&0F,&0E,&10,&11,&12,&13,&14,&15,&42,&43,&23,&33,&3A,&42 ; &1F70
; -----------------------------------------------------------------------------
; STATIC SCREEN/MAZE FRAME VDU STREAM - exactly &78 bytes emitted by draw_maze_and_screen.
; Decoded: MODE 2; GCOL 0,8; PLOT commands draw outer and inner rectangular frames;
; final VDU 10 then text "Score:".  Bytes &1FF8-&1FFF are NOT emitted.
; PLOT sequence (mode,x,y):
;   4,32,4   5,32,384   4,32,564   5,32,950   5,1272,950
;   5,1272,560   4,1272,384   5,1272,4   5,32,4
;   4,40,8   5,40,384   4,40,560   5,40,946   5,1264,946
;   5,1264,560   4,1264,384   5,1264,8   5,40,8
; -----------------------------------------------------------------------------
screen_setup_vdu_stream:
    EQUB &16,&02,&12,&00,&08,&19,&04,&20,&00,&04,&00,&19,&05,&20,&00,&80 ; &1F80
    EQUB &01,&19,&04,&20,&00,&34,&02,&19,&05,&20,&00,&B6,&03,&19,&05,&F8 ; &1F90
    EQUB &04,&B6,&03,&19,&05,&F8,&04,&30,&02,&19,&04,&F8,&04,&80,&01,&19 ; &1FA0
    EQUB &05,&F8,&04,&04,&00,&19,&05,&20,&00,&04,&00,&19,&04,&28,&00,&08 ; &1FB0
    EQUB &00,&19,&05,&28,&00,&80,&01,&19,&04,&28,&00,&30,&02,&19,&05,&28 ; &1FC0
    EQUB &00,&B2,&03,&19,&05,&F0,&04,&B2,&03,&19,&05,&F0,&04,&30,&02,&19 ; &1FD0
    EQUB &04,&F0,&04,&80,&01,&19,&05,&F0,&04,&08,&00,&19,&05,&28,&00,&08 ; &1FE0
    EQUB &00,&0A,&53,&63,&6F,&72,&65,&3A                                 ; &1FF0
; -----------------------------------------------------------------------------
; Eight zero padding bytes between VDU stream and tile set; never emitted by the stream loop.
; -----------------------------------------------------------------------------
screen_setup_padding:
    EQUB &00,&00,&00,&00,&00,&18,&00,&00                                 ; &1FF8
; =============================================================================
; 16 MAZE TILE GRAPHICS - &30 bytes each
; =============================================================================
; Decoded 6x12-pixel atlas.  # = logical wall colour 8, O = power-pellet pixels, . = ordinary pellet.
; This is generated directly from the exact bitmap bytes consumed by draw_tile_block; it is not an artistic guess.
;   TILE &0
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;   TILE &1
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  ####|
;     |   ## |
;     |      |
;     |      |
;   TILE &2
;     |      |
;     |      |
;     |   ###|
;     |  ####|
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #   |
;     |  ####|
;     |   ###|
;     |      |
;     |      |
;   TILE &3
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #   |
;     |  ####|
;     |   ###|
;     |      |
;     |      |
;   TILE &4
;     |      |
;     |      |
;     |   ## |
;     |  ####|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;   TILE &5
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;     |  #  #|
;   TILE &6
;     |      |
;     |      |
;     |   ###|
;     |  ####|
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #   |
;     |  #  #|
;     |  #  #|
;     |  #  #|
;   TILE &7
;     |      |
;     |      |
;     |      |
;     |   O  |
;     |  OOO |
;     |  OOO |
;     | OOOOO|
;     |  OOO |
;     |  OOO |
;     |   O  |
;     |      |
;     |      |
;   TILE &8
;     |      |
;     |      |
;     |##### |
;     |######|
;     |     #|
;     |     #|
;     |     #|
;     |     #|
;     |######|
;     |##### |
;     |      |
;     |      |
;   TILE &9
;     |  #  #|
;     |  #  #|
;     |###  #|
;     |##   #|
;     |     #|
;     |     #|
;     |     #|
;     |     #|
;     |######|
;     |##### |
;     |      |
;     |      |
;   TILE &A
;     |      |
;     |      |
;     |######|
;     |######|
;     |      |
;     |      |
;     |      |
;     |      |
;     |######|
;     |######|
;     |      |
;     |      |
;   TILE &B
;     |  #  #|
;     |  #  #|
;     |###  #|
;     |##    |
;     |      |
;     |      |
;     |      |
;     |      |
;     |######|
;     |######|
;     |      |
;     |      |
;   TILE &C
;     |      |
;     |      |
;     |##### |
;     |######|
;     |     #|
;     |     #|
;     |     #|
;     |     #|
;     |##   #|
;     |###  #|
;     |  #  #|
;     |  #  #|
;   TILE &D
;     |  #  #|
;     |  #  #|
;     |###  #|
;     |##   #|
;     |     #|
;     |     #|
;     |     #|
;     |     #|
;     |##   #|
;     |###  #|
;     |  #  #|
;     |  #  #|
;   TILE &E
;     |      |
;     |      |
;     |######|
;     |######|
;     |      |
;     |      |
;     |      |
;     |      |
;     |##    |
;     |###  #|
;     |  #  #|
;     |  #  #|
;   TILE &F
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
;     |   .  |
;     |   .  |
;     |      |
;     |      |
;     |      |
;     |      |
;     |      |
; -----------------------------------------------------------------------------
; Tile ID &00, selected by a nibble in maze_layout_data.
; Blank tile.
; -----------------------------------------------------------------------------
maze_tile_blank:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2000
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2010
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2020
; -----------------------------------------------------------------------------
; Tile ID &01, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_01:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&80,&80,&80,&80,&80,&80,&80,&80 ; &2030
    EQUB &40,&40,&40,&40,&40,&40,&40,&40,&00,&00,&00,&00,&00,&00,&00,&00 ; &2040
    EQUB &C0,&40,&00,&00,&00,&00,&00,&00,&C0,&80,&00,&00,&00,&00,&00,&00 ; &2050
; -----------------------------------------------------------------------------
; Tile ID &02, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_02:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&40,&C0,&80,&80,&80,&80 ; &2060
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2070
    EQUB &C0,&40,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2080
; -----------------------------------------------------------------------------
; Tile ID &03, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_03:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&80,&80,&80,&80,&80,&80,&80,&80 ; &2090
    EQUB &40,&40,&40,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &20A0
    EQUB &C0,&40,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &20B0
; -----------------------------------------------------------------------------
; Tile ID &04, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_04:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&40,&C0,&80,&80,&80,&80 ; &20C0
    EQUB &00,&00,&80,&C0,&40,&40,&40,&40,&00,&00,&00,&00,&00,&00,&00,&00 ; &20D0
    EQUB &80,&80,&80,&80,&00,&00,&00,&00,&40,&40,&40,&40,&00,&00,&00,&00 ; &20E0
; -----------------------------------------------------------------------------
; Tile ID &05, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_05:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&80,&80,&80,&80,&80,&80,&80,&80 ; &20F0
    EQUB &40,&40,&40,&40,&40,&40,&40,&40,&00,&00,&00,&00,&00,&00,&00,&00 ; &2100
    EQUB &80,&80,&80,&80,&00,&00,&00,&00,&40,&40,&40,&40,&00,&00,&00,&00 ; &2110
; -----------------------------------------------------------------------------
; Tile ID &06, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_06:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&40,&C0,&80,&80,&80,&80 ; &2120
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2130
    EQUB &80,&80,&80,&80,&00,&00,&00,&00,&00,&40,&40,&40,&00,&00,&00,&00 ; &2140
; -----------------------------------------------------------------------------
; Tile ID &07, selected by a nibble in maze_layout_data.
; Power-pellet tile; draw_power_pellets explicitly selects ID &07.
; -----------------------------------------------------------------------------
maze_tile_power_pellet:
    EQUB &00,&00,&00,&00,&00,&00,&14,&00,&00,&00,&00,&14,&3C,&3C,&3C,&3C ; &2150
    EQUB &00,&00,&00,&00,&28,&28,&3C,&28,&00,&00,&00,&00,&00,&00,&00,&00 ; &2160
    EQUB &3C,&14,&00,&00,&00,&00,&00,&00,&28,&00,&00,&00,&00,&00,&00,&00 ; &2170
; -----------------------------------------------------------------------------
; Tile ID &08, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_08:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00 ; &2180
    EQUB &00,&00,&80,&C0,&40,&40,&40,&40,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2190
    EQUB &C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&80,&00,&00,&00,&00,&00,&00 ; &21A0
; -----------------------------------------------------------------------------
; Tile ID &09, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_09:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&80,&80,&80,&00,&00,&00,&00,&00 ; &21B0
    EQUB &40,&40,&40,&40,&40,&40,&40,&40,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &21C0
    EQUB &C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&80,&00,&00,&00,&00,&00,&00 ; &21D0
; -----------------------------------------------------------------------------
; Tile ID &0A, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_0A:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00 ; &21E0
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &21F0
    EQUB &C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2200
; -----------------------------------------------------------------------------
; Tile ID &0B, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_0B:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&80,&80,&80,&00,&00,&00,&00,&00 ; &2210
    EQUB &40,&40,&40,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2220
    EQUB &C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2230
; -----------------------------------------------------------------------------
; Tile ID &0C, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_0C:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00 ; &2240
    EQUB &00,&00,&80,&C0,&40,&40,&40,&40,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2250
    EQUB &00,&80,&80,&80,&00,&00,&00,&00,&40,&40,&40,&40,&00,&00,&00,&00 ; &2260
; -----------------------------------------------------------------------------
; Tile ID &0D, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_0D:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&80,&80,&80,&00,&00,&00,&00,&00 ; &2270
    EQUB &40,&40,&40,&40,&40,&40,&40,&40,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &2280
    EQUB &00,&80,&80,&80,&00,&00,&00,&00,&40,&40,&40,&40,&00,&00,&00,&00 ; &2290
; -----------------------------------------------------------------------------
; Tile ID &0E, selected by a nibble in maze_layout_data.
; -----------------------------------------------------------------------------
maze_tile_0E:
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00 ; &22A0
    EQUB &00,&00,&C0,&C0,&00,&00,&00,&00,&C0,&C0,&00,&00,&00,&00,&00,&00 ; &22B0
    EQUB &00,&80,&80,&80,&00,&00,&00,&00,&00,&40,&40,&40,&00,&00,&00,&00 ; &22C0
; -----------------------------------------------------------------------------
; Tile ID &0F: ORDINARY PELLET.
; The graphic is otherwise blank except for two raw &04 Mode-2 bytes recognised by sprite/pellet code.
; Crucially, tile &0F occurs exactly 206 (&CE) times in maze_layout_data, exactly matching
; INITIAL_PELLETS.  This proves the maze tile stream itself is the ordinary-pellet placement map.
; -----------------------------------------------------------------------------
maze_tile_pellet:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&04,&04,&00 ; &22D0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &22E0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &22F0
; =============================================================================
; PACKED MAZE LAYOUT - 19 rows x 25 tile IDs
; =============================================================================
; Each row is 13 bytes.  Bytes 0..11 store high-nibble then low-nibble tile IDs;
; byte 12 contributes only its high nibble.  The renderer reads bytes backward because
; coord_x is drawn right-to-left, but the decoded row comments below are screen left-to-right.
;
; PROVEN CONTENT COUNTS across all 475 cells:
;   TILE_PELLET (&0F)       = 206 cells = &CE = INITIAL_PELLETS
;   TILE_POWER_PELLET (&07) =   4 cells
; The four power pellets are at (row,column) (2,0), (2,24), (14,0), (14,24).
; Using the renderer's x=3+3*column / y=58-3*row geometry gives the same four logical
; positions redrawn by draw_power_pellets, independently validating the map orientation.
maze_layout_data:
    ; maze row 00: FFFFFFFFFFFF5FFFFFFFFFFFF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&5F,&FF,&FF,&FF,&FF,&FF,&F0 ; &2300
    ; maze row 01: F6ACF6AEAA8F1F2AAEACF6ACF
    EQUB &F6,&AC,&F6,&AE,&AA,&8F,&1F,&2A,&AE,&AC,&F6,&AC,&F0 ; &230D
    ; maze row 02: 7505F505FFFFFFFFF505F5057
    EQUB &75,&05,&F5,&05,&FF,&FF,&FF,&FF,&F5,&05,&F5,&05,&70 ; &231A
    ; maze row 03: F3A9F3A9F2AAEAA8F3A9F3A9F
    EQUB &F3,&A9,&F3,&A9,&F2,&AA,&EA,&A8,&F3,&A9,&F3,&A9,&F0 ; &2327
    ; maze row 04: FFFFFFFFFFFF5FFFFFFFFFFFF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&5F,&FF,&FF,&FF,&FF,&FF,&F0 ; &2334
    ; maze row 05: F2A8F2AEAA80102AAEA8F2A8F
    EQUB &F2,&A8,&F2,&AE,&AA,&80,&10,&2A,&AE,&A8,&F2,&A8,&F0 ; &2341
    ; maze row 06: FFFFFFF50000000005FFFFFFF
    EQUB &FF,&FF,&FF,&F5,&00,&00,&00,&00,&05,&FF,&FF,&FF,&F0 ; &234E
    ; maze row 07: AAAAACF506A802AC05F6AAAAA
    EQUB &AA,&AA,&AC,&F5,&06,&A8,&02,&AC,&05,&F6,&AA,&AA,&A0 ; &235B
    ; maze row 08: AAAAA9F10500000501F3AAAAA
    EQUB &AA,&AA,&A9,&F1,&05,&00,&00,&05,&01,&F3,&AA,&AA,&A0 ; &2368
    ; maze row 09: 000000F00500000500F000000
    EQUB &00,&00,&00,&F0,&05,&00,&00,&05,&00,&F0,&00,&00,&00 ; &2375
    ; maze row 10: AAAAACF40500000504F6AAAAA
    EQUB &AA,&AA,&AC,&F4,&05,&00,&00,&05,&04,&F6,&AA,&AA,&A0 ; &2382
    ; maze row 11: AAAAA9F103AAEAA901F3AAAAA
    EQUB &AA,&AA,&A9,&F1,&03,&AA,&EA,&A9,&01,&F3,&AA,&AA,&A0 ; &238F
    ; maze row 12: FFFFFFFFFFFF5FFFFFFFFFFFF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&5F,&FF,&FF,&FF,&FF,&FF,&F0 ; &239C
    ; maze row 13: F2ACF2AAAA8F1F2AAAA8F6A8F
    EQUB &F2,&AC,&F2,&AA,&AA,&8F,&1F,&2A,&AA,&A8,&F6,&A8,&F0 ; &23A9
    ; maze row 14: 7FF5FFFFFFFF0FFFFFFFF5FF7
    EQUB &7F,&F5,&FF,&FF,&FF,&FF,&0F,&FF,&FF,&FF,&F5,&FF,&70 ; &23B6
    ; maze row 15: A8F3A8F4F2AAEAA8F4F2A9F2A
    EQUB &A8,&F3,&A8,&F4,&F2,&AA,&EA,&A8,&F4,&F2,&A9,&F2,&A0 ; &23C3
    ; maze row 16: FFFFFFF5FFFF5FFFF5FFFFFFF
    EQUB &FF,&FF,&FF,&F5,&FF,&FF,&5F,&FF,&F5,&FF,&FF,&FF,&F0 ; &23D0
    ; maze row 17: F2AAAAABAA8F1F2AABAAAAA8F
    EQUB &F2,&AA,&AA,&AB,&AA,&8F,&1F,&2A,&AB,&AA,&AA,&A8,&F0 ; &23DD
    ; maze row 18: FFFFFFFFFFFFFFFFFFFFFFFFF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&F0 ; &23EA
; -----------------------------------------------------------------------------
; Nine trailing bytes not consumed by the 19 x 13-byte maze loop.
; They contain tile-like nibbles but the renderer stops after exactly 247 bytes, so they are
; not part of the live 19x25 maze.  Likely layout/editor residue; retained byte-exact.
; -----------------------------------------------------------------------------
maze_layout_padding:
    EQUB &BA,&AA,&AA,&8F,&50,&5F,&FF,&FF,&FF                             ; &23F7
; =============================================================================
; SCORE DIGIT BITMAPS - ten digits x &20 bytes
; =============================================================================
score_digit_graphics:
score_digit_0:
    EQUB &00,&15,&15,&15,&15,&15,&15,&00,&3F,&2A,&2A,&2A,&2A,&2A,&2A,&3F ; &2400
    EQUB &3F,&15,&15,&15,&15,&15,&15,&3F,&00,&2A,&2A,&2A,&2A,&2A,&2A,&00 ; &2410
score_digit_1:
    EQUB &00,&00,&00,&00,&00,&00,&00,&15,&15,&3F,&15,&15,&15,&15,&15,&3F ; &2420
    EQUB &2A,&2A,&2A,&2A,&2A,&2A,&2A,&3F,&00,&00,&00,&00,&00,&00,&00,&2A ; &2430
score_digit_2:
    EQUB &00,&15,&00,&00,&00,&00,&15,&15,&3F,&2A,&00,&00,&15,&3F,&2A,&3F ; &2440
    EQUB &3F,&15,&15,&3F,&2A,&00,&00,&3F,&00,&2A,&2A,&00,&00,&00,&00,&2A ; &2450
score_digit_3:
    EQUB &00,&15,&00,&00,&00,&00,&15,&00,&3F,&2A,&00,&15,&00,&00,&2A,&3F ; &2460
    EQUB &3F,&15,&15,&3F,&15,&15,&15,&3F,&00,&2A,&2A,&00,&2A,&2A,&2A,&00 ; &2470
score_digit_4:
    EQUB &00,&00,&00,&15,&15,&00,&00,&00,&00,&15,&3F,&2A,&3F,&00,&00,&00 ; &2480
    EQUB &3F,&3F,&3F,&3F,&3F,&3F,&3F,&3F,&00,&00,&00,&00,&2A,&00,&00,&00 ; &2490
score_digit_5:
    EQUB &15,&15,&15,&15,&00,&00,&15,&00,&3F,&2A,&2A,&3F,&00,&00,&2A,&3F ; &24A0
    EQUB &3F,&00,&00,&3F,&15,&15,&15,&3F,&2A,&00,&00,&00,&2A,&2A,&2A,&00 ; &24B0
score_digit_6:
    EQUB &00,&00,&15,&15,&15,&15,&15,&00,&15,&3F,&2A,&3F,&2A,&2A,&2A,&3F ; &24C0
    EQUB &3F,&00,&00,&3F,&15,&15,&15,&3F,&00,&00,&00,&00,&2A,&2A,&2A,&00 ; &24D0
score_digit_7:
    EQUB &15,&15,&00,&00,&00,&00,&00,&00,&3F,&00,&00,&00,&15,&3F,&3F,&3F ; &24E0
    EQUB &3F,&15,&15,&3F,&2A,&00,&00,&00,&2A,&2A,&2A,&00,&00,&00,&00,&00 ; &24F0
score_digit_8:
    EQUB &00,&15,&15,&00,&15,&15,&15,&00,&3F,&2A,&2A,&3F,&2A,&2A,&2A,&3F ; &2500
    EQUB &3F,&15,&15,&3F,&15,&15,&15,&3F,&00,&2A,&2A,&00,&2A,&2A,&2A,&00 ; &2510
score_digit_9:
    EQUB &00,&15,&15,&00,&00,&00,&00,&00,&3F,&2A,&2A,&3F,&00,&00,&00,&3F ; &2520
    EQUB &3F,&15,&15,&3F,&15,&15,&3F,&2A,&00,&2A,&2A,&2A,&2A,&2A,&00,&00 ; &2530
; -----------------------------------------------------------------------------
; 16 little-endian tile pointers.  They are exactly &30 bytes apart (&2000..&22D0).
; -----------------------------------------------------------------------------
tile_graphics_pointer_table:
    EQUB &00,&20                                                 ; &2540  tile &00 -> &2000
    EQUB &30,&20                                                 ; &2542  tile &01 -> &2030
    EQUB &60,&20                                                 ; &2544  tile &02 -> &2060
    EQUB &90,&20                                                 ; &2546  tile &03 -> &2090
    EQUB &C0,&20                                                 ; &2548  tile &04 -> &20C0
    EQUB &F0,&20                                                 ; &254A  tile &05 -> &20F0
    EQUB &20,&21                                                 ; &254C  tile &06 -> &2120
    EQUB &50,&21                                                 ; &254E  tile &07 -> &2150
    EQUB &80,&21                                                 ; &2550  tile &08 -> &2180
    EQUB &B0,&21                                                 ; &2552  tile &09 -> &21B0
    EQUB &E0,&21                                                 ; &2554  tile &0A -> &21E0
    EQUB &10,&22                                                 ; &2556  tile &0B -> &2210
    EQUB &40,&22                                                 ; &2558  tile &0C -> &2240
    EQUB &70,&22                                                 ; &255A  tile &0D -> &2270
    EQUB &A0,&22                                                 ; &255C  tile &0E -> &22A0
    EQUB &D0,&22                                                 ; &255E  tile &0F -> &22D0
; -----------------------------------------------------------------------------
; SPRITE RECORD ANATOMY / UNUSED TRAILERS
; The compositor proves that an 8x16 headered sprite consumes exactly 2+64=66 bytes.
; Most asset records are spaced &48/72 bytes apart, leaving SIX trailing bytes that are never read.
; Raw 8x16 eye/source planes consume 64 bytes and normally leave EIGHT bytes in the same 72-byte slot.
; This explains the apparently instruction-like garbage at many sprite tails: it is slot slack/build residue,
; not hidden pixels.  The table below records the exact ignored trailer bytes up to the next pointer.
;
; ID   start  role                         bytes used  ignored trailer
; 00   &2716  ghost body LEFT phase 0       66        00 65 6D 70 00 8C
; 01   &275E  ghost body RIGHT phase 0      66        00 23 00 00 43 21
; 02   &27A6  ghost body DOWN phase 0       66        00 6F 6F 70 00 8E
; 03   &27EE  ghost body UP phase 0         66        00 10 20 00 00 00
; 04   &2836  ghost body LEFT phase 1       66        00 74 00 8E 12 B0
; 05   &287E  ghost body RIGHT phase 1      66        00 73 00 8E 16 3C
; 06   &28C6  ghost body DOWN phase 1       66        00 00 55 22 65 74
; 07   &290E  ghost body UP phase 1         66        00 00 00 00 00 00 0F 18
; 08   &2958  eye overlay LEFT              64        00 00 00 00 00 00 0F 18
; 09   &29A0  eye overlay RIGHT             64        00 00 00 00 00 00 0F 18
; 0A   &29E8  eye overlay DOWN              64        00 82 26 83 A5 71 0F 18
; 0B   &2A30  eye overlay UP                64        00 82 A4 73 68 60
; 0C   &2A76  frightened ghost phase 0      66        00 BD 13 0C 85 81
; 0D   &2ABE  frightened ghost phase 1      66        00 98 29 07 D0 18
; 0E   &2B06  strawberry                    66        00 6B FE A9 30 8D
; 0F   &2B4E  cherry                        66        00 FC 8D 58 0C A9
; 10   &2B96  orange                        66        00 40 40 40 40 40
; 11   &2BDE  apple                         66        00 07 0C 85 71 B9
; 12   &2C26  melon                         66        00 C0 C0 00 00 00
; 13   &2C6E  key                           66        00 00 00 00 00 00
; 14   &2CB6  bell                          66        00 00 0C 18 6D 5D
; 15   &2CFE  galaxian                      66        00 5C 23 A9 55 8D
; 16   &2D46  horizontal trail eraser       18        00 00 00 00 00 00
; 17   &2D5E  vertical trail eraser         18        00 00 00 00 00 00
; 18   &2D76  Snapper LEFT phase 0          66        00 23 4C AC 25 AD
; 19   &2DBE  Snapper DOWN phase 0          66        00 00 00 00 00 00
; 1A   &2E06  Snapper UP phase 0            66        00 AA FF FF FF FF
; 1B   &2E4E  Snapper RIGHT phase 0         66        00 AA FF 00 00 00
; 1C   &2E96  Snapper LEFT phase 1          66        00 AA 55 55 55 55
; 1D   &2EDE  Snapper DOWN phase 1          66        00 AA FF FF 55 55
; 1E   &2F26  Snapper UP phase 1            66        00 AA FF FF FF FF
; 1F   &2F6E  Snapper RIGHT phase 1         66        00 AA FF 00 00 00
;
; The same six-byte slack pattern is also present after the blank/erase and several death-sprite records.
; Crucially, ID &27 begins with shared header &0F,&18 and therefore consumes a full 8x16 payload;
; Stage 7 incorrectly grouped it with the 8x8 middle death frames.  That is corrected here.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; MASKED SPRITE POINTER TABLE - 40 IDs (&00-&27).
; Geometry of IDs used as REQUESTED sprites (from their 2-byte headers):
;   &00-&07 normal ghost bodies: 8x16      &0C-&15 frightened/fruits: 8x16
;   &16 horizontal trail erase: 2x16       &17 vertical trail erase: 8x4
;   &18-&1F Snapper: 8x16                  &22 full blank erase: 8x16
;   &23 death frame 0: 8x16                &24-&26 middle death frames: 8x8; &27 final burst: 8x16
; IDs &08-&0B (eyes) and &21 (blank source) are OR/source planes: their first bytes are pixels, not headers.
; -----------------------------------------------------------------------------
masked_sprite_pointer_table:
    EQUB &16,&27                                                 ; &2560  ID &00: ghost body mask left phase 0 -> &2716
    EQUB &5E,&27                                                 ; &2562  ID &01: ghost body mask right phase 0 -> &275E
    EQUB &A6,&27                                                 ; &2564  ID &02: ghost body mask down phase 0 -> &27A6
    EQUB &EE,&27                                                 ; &2566  ID &03: ghost body mask up phase 0 -> &27EE
    EQUB &36,&28                                                 ; &2568  ID &04: ghost body mask left phase 1 -> &2836
    EQUB &7E,&28                                                 ; &256A  ID &05: ghost body mask right phase 1 -> &287E
    EQUB &C6,&28                                                 ; &256C  ID &06: ghost body mask down phase 1 -> &28C6
    EQUB &0E,&29                                                 ; &256E  ID &07: ghost body mask up phase 1 -> &290E
    EQUB &58,&29                                                 ; &2570  ID &08: eye overlay left -> &2958
    EQUB &A0,&29                                                 ; &2572  ID &09: eye overlay right -> &29A0
    EQUB &E8,&29                                                 ; &2574  ID &0A: eye overlay down -> &29E8
    EQUB &30,&2A                                                 ; &2576  ID &0B: eye overlay up -> &2A30
    EQUB &76,&2A                                                 ; &2578  ID &0C: frightened ghost frame 0 -> &2A76
    EQUB &BE,&2A                                                 ; &257A  ID &0D: frightened ghost frame 1 -> &2ABE
    EQUB &06,&2B                                                 ; &257C  ID &0E: strawberry -> &2B06
    EQUB &4E,&2B                                                 ; &257E  ID &0F: cherry -> &2B4E
    EQUB &96,&2B                                                 ; &2580  ID &10: orange -> &2B96
    EQUB &DE,&2B                                                 ; &2582  ID &11: apple -> &2BDE
    EQUB &26,&2C                                                 ; &2584  ID &12: melon -> &2C26
    EQUB &6E,&2C                                                 ; &2586  ID &13: key -> &2C6E
    EQUB &B6,&2C                                                 ; &2588  ID &14: bell -> &2CB6
    EQUB &FE,&2C                                                 ; &258A  ID &15: galaxian -> &2CFE
    EQUB &46,&2D                                                 ; &258C  ID &16: horizontal trailing-edge erase geometry -> &2D46
    EQUB &5E,&2D                                                 ; &258E  ID &17: vertical trailing-edge erase geometry -> &2D5E
    ; Snapper uses PLAYER_FACING_* order here: LEFT, DOWN, UP, RIGHT (not ghost-facing order).
    EQUB &76,&2D                                                 ; &2590  ID &18: Snapper left phase 0 -> &2D76
    EQUB &BE,&2D                                                 ; &2592  ID &19: Snapper down phase 0 -> &2DBE
    EQUB &06,&2E                                                 ; &2594  ID &1A: Snapper up phase 0 -> &2E06
    EQUB &4E,&2E                                                 ; &2596  ID &1B: Snapper right phase 0 -> &2E4E
    EQUB &96,&2E                                                 ; &2598  ID &1C: Snapper left phase 1 -> &2E96
    EQUB &DE,&2E                                                 ; &259A  ID &1D: Snapper down phase 1 -> &2EDE
    EQUB &26,&2F                                                 ; &259C  ID &1E: Snapper up phase 1 -> &2F26
    EQUB &6E,&2F                                                 ; &259E  ID &1F: Snapper right phase 1 -> &2F6E
    EQUB &D0,&FE                                                 ; &25A0  ID &20: unused/external &FED0 pointer (no proven reachable sprite-ID &20 use) -> &FED0
    EQUB &CE,&26                                                 ; &25A2  ID &21: blank OR/source plane -> &26CE
    EQUB &86,&26                                                 ; &25A4  ID &22: full-size blank erase sprite -> &2686
    EQUB &76,&1E                                                 ; &25A6  ID &23: death frame 0 -> &1E76
    EQUB &4E,&1E                                                 ; &25A8  ID &24: death frame 1 -> &1E4E
    EQUB &26,&1E                                                 ; &25AA  ID &25: death frame 2 -> &1E26
    EQUB &FE,&1D                                                 ; &25AC  ID &26: death frame 3 -> &1DFE
    EQUB &B6,&1D                                                 ; &25AE  ID &27: death frame 4 (overlaps JMP operand at &1DB6) -> &1DB6
; -----------------------------------------------------------------------------
; Eight bytes with no direct reference from proven reachable code.  The tail can be
; decoded as "LDA #1 / STA &0C5C", but no reachable branch enters it and the target does
; not form part of the proven game state.  Kept as legacy/orphan bytes.
; -----------------------------------------------------------------------------
legacy_unreferenced_fragment_25B0:
    EQUB &00,&00,&0C,&A9,&01,&8D,&5C,&0C                                 ; &25B0
; -----------------------------------------------------------------------------
; Eight-byte OSWORD 1 system-clock buffer.  Only the low byte is compared by delay_clock_ticks_from_x.
; -----------------------------------------------------------------------------
clock_read_buffer:
    EQUB &46,&2F,&08,&00,&00,&AD,&01,&0C                                 ; &25B8
; -----------------------------------------------------------------------------
; 32 little-endian Mode 2 screen addresses.  Sprite drawing records pellets temporarily covered by moving objects;
; restore_hidden_pellets later redraws them unless Snapper has eaten them.
; -----------------------------------------------------------------------------
hidden_pellet_address_table:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &25C0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &25D0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &25E0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &25F0
; -----------------------------------------------------------------------------
; VDU/control-code string "Press SPACE BAR to play again", terminated by CR at &2620.
; -----------------------------------------------------------------------------
play_again_message:
    EQUB &1F,&05,&16,&50,&72,&65,&73,&73,&20,&53,&50,&41,&43,&45,&20,&42 ; &2600
    EQUB &41,&52,&20,&74,&6F,&20,&70,&6C,&61,&79,&20,&61,&67,&61,&69,&6E ; &2610
    EQUB &0D                                                             ; &2620
; -----------------------------------------------------------------------------
; 15 bytes after the CR; no direct reference from proven reachable code.  Several
; instruction-like subsequences jump into score graphics or MOS entry points without a
; coherent entry path, another sign of stale code/data residue rather than live logic.
; -----------------------------------------------------------------------------
legacy_unreferenced_fragment_2621:
    EQUB &03,&4C,&AA,&24,&A9,&0F,&4C,&F4,&FF,&AD,&00,&0C,&18,&6D,&5D     ; &2621
; -----------------------------------------------------------------------------
; 18 compact direction/control codes used during scripted patrol.  Ghosts 0/1 start at index 0;
; ghosts 2/3 at index 10.  Path A runs 0..9 then loops 5..9; path B runs 10..17 then loops 12..17.
; IMPORTANT: this script is not simply object_facing and is not the eaten-ghost ROUTE_* encoding.
; Even codes are unambiguous: 0=DOWN and 2=UP.  Odd codes choose a horizontal direction:
; for even-numbered ghosts 1=LEFT / 3=RIGHT, while odd-numbered ghosts mirror them
; (1=RIGHT / 3=LEFT).  That mirroring lets paired ghosts follow symmetric patrol paths.
; Decoded paths (after each pair's separately forced initial outward turn):
;   ghost 0: initial R; phases 1..9 R,U,R,R,R,R,D,R,R; repeat phases 5..9 = R,R,D,R,R
;   ghost 1: initial L; phases 1..9 L,U,L,L,L,L,D,L,L; repeat phases 5..9 = L,L,D,L,L
;   ghost 2: initial R; phases 11..17 D,D,D,R,U,D,L; repeat phases 12..17 = D,D,R,U,D,L
;   ghost 3: initial L; phases 11..17 D,D,D,L,U,D,R; repeat phases 12..17 = D,D,L,U,D,R
; The shared table plus parity mirroring therefore encodes four symmetric patrols in only 18 bytes.
; -----------------------------------------------------------------------------
ghost_route_script:
    EQUB &03,&03,&02,&03,&03,&03,&03,&00,&03,&03,&03,&00,&00,&00,&03,&02 ; &2630
    EQUB &00,&01                                                         ; &2640
; -----------------------------------------------------------------------------
 ; Five unreferenced bytes between patrol script and level fruit table.  They decode EXACTLY as:
;     STY coord_y : JMP &2362
; A second stale block at &2661 begins with the symmetric "STY coord_x : JMP &2362".
; Two paired coordinate wrappers targeting the same address are extremely unlikely to be accidental data.
; In the final binary &2362 has been overwritten by packed maze bytes, strongly indicating these are
; orphan entry stubs from an earlier memory layout/routine that was moved or deleted.
; -----------------------------------------------------------------------------
legacy_unreferenced_fragment_2642:
    EQUB &84,&71,&4C,&62,&23                                             ; &2642
; -----------------------------------------------------------------------------
; 17 entries for level_number 0..16.  Values are fruit sprite IDs; levels 16+ are capped at 16.
; Exact level progression (level_number is zero-based):
;   0 cherry 100; 1 strawberry 300; 2-3 orange 500; 4-5 apple 700; 6-7 melon 1000;
;   8-9 galaxian 2000; 10-12 bell 3000; 13-16 key 5000.
; -----------------------------------------------------------------------------
level_fruit_sprite_table:
    EQUB &0F,&0E,&10,&10,&11,&11,&12,&12,&15,&15,&14,&14,&14,&13,&13,&13 ; &2647
    EQUB &13                                                             ; &2657
; -----------------------------------------------------------------------------
; Nine packed logical/physical colour pairs consumed by draw_maze_and_screen.
; set_palette_colour sends the high nibble as the logical colour and (low nibble XOR 7)
; as the physical colour.  Later gameplay changes only selected palette entries:
; logical 8 flashes maze blue/white, logical C flashes frightened ghosts blue/white,
; and logical 6 alternates the power-pellet colour/on-off appearance.
; -----------------------------------------------------------------------------
maze_palette_sequence:
    ; logical 8 -> physical 4 BLUE
    ; logical 9 -> physical 0 BLACK     (invisible ghost-house gate)
    ; logical A -> physical 4 BLUE
    ; logical B -> physical 7 WHITE
    ; logical C -> physical 4 BLUE      (frightened ghost base colour)
    ; logical D -> physical 5 MAGENTA
    ; logical E -> physical 6 CYAN      (ghost slot 2 body)
    ; logical F -> physical 2 GREEN     (ghost slot 0 body)
    ; logical 6 -> physical 2 GREEN     (power pellet; toggled to black with &67)
    EQUB &83,&97,&A3,&B0,&C3,&D2,&E1,&F5,&65                             ; &2658
; -----------------------------------------------------------------------------
 ; 37 bytes with no direct reference from proven reachable code.
; The first five bytes are the paired stale wrapper "STY coord_x : JMP &2362" described above.
; Bytes &2666-&266D are even stronger evidence of an earlier implementation:
;     legacy: SEC : SBC #3 : BPL back : ADC #3 : RTS
;     live:   SEC : SBC #3 : BCS back : ADC #3 : RTS   (at modulo_three, &17C2)
; Only the branch opcode differs.  The legacy BPL version is signed-range-sensitive; the live BCS
; version performs the intended unsigned repeated subtraction robustly.  It is best classified as
; an abandoned predecessor/buggy draft of the live modulo-three helper, not executable current code.
; -----------------------------------------------------------------------------
legacy_unreferenced_fragment_2661:
    EQUB &84,&70,&4C,&62,&23,&38,&E9,&03,&10,&FC,&69,&03,&60,&0F,&0F,&0F ; &2661
    EQUB &05,&00,&00,&0A,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&00,&0A,&0A ; &2671
    EQUB &0A,&31,&23,&00,&05                                             ; &2681
; -----------------------------------------------------------------------------
; Sprite ID &22.  Header &0F,&18 gives full object geometry; all pixel bytes are zero, so it erases a full sprite area.
; -----------------------------------------------------------------------------
blank_full_sprite:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2686
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2696
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26A6
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26B6
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &26C6
; -----------------------------------------------------------------------------
; Sprite ID &21.  All-zero OR/source plane used when a requested sprite should be drawn directly.
; -----------------------------------------------------------------------------
blank_sprite_source:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26CE
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26DE
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26EE
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &26FE
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &270E
; =============================================================================
; EXACT SPRITE ATLAS - generated only from bytes the live compositor actually reads
; =============================================================================
; For normal ghost body-mask IDs &00-&07, # means a non-zero mask pixel (colour is supplied separately).
; Eye overlays use B/W for blue/white source pixels.  Other sprites show physical colour after the maze palette:
;   R=red G=green Y=yellow B=blue M=magenta C=cyan W=white, k=logical-9 black/invisible, space=black/zero.
; Eraser IDs &16/&17 are intentionally blank.  Only renderer-consumed bytes are shown; slot trailers above are excluded.
;
; ID &00  ghost body LEFT phase 0  @2716  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |  ##  ##|
;   |  ##  ##|
;   |  ##  ##|
;   |  ##  ##|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   |# # # # |
;   |# # # # |
;
; ID &01  ghost body RIGHT phase 0  @275E  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |##  ##  |
;   |##  ##  |
;   |##  ##  |
;   |##  ##  |
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   | # # # #|
;   | # # # #|
;
; ID &02  ghost body DOWN phase 0  @27A6  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   |# # # # |
;   |# # # # |
;
; ID &03  ghost body UP phase 0  @27EE  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |########|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |########|
;   |########|
;   |########|
;   |########|
;   | # # # #|
;   | # # # #|
;
; ID &04  ghost body LEFT phase 1  @2836  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |  ##  ##|
;   |  ##  ##|
;   |  ##  ##|
;   |  ##  ##|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   | # # # #|
;   | # # # #|
;
; ID &05  ghost body RIGHT phase 1  @287E  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |##  ##  |
;   |##  ##  |
;   |##  ##  |
;   |##  ##  |
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   |# # # # |
;   |# # # # |
;
; ID &06  ghost body DOWN phase 1  @28C6  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   |########|
;   | # # # #|
;   | # # # #|
;
; ID &07  ghost body UP phase 1  @290E  8x16 headered
;   |        |
;   |   ##   |
;   |  ####  |
;   | ###### |
;   |########|
;   |########|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |#  ##  #|
;   |########|
;   |########|
;   |########|
;   |########|
;   |# # # # |
;   |# # # # |
;
; ID &08  eye overlay LEFT  @2958  8x16 raw source plane
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |WW  WW  |
;   |BW  BW  |
;   |BW  BW  |
;   |WW  WW  |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;
; ID &09  eye overlay RIGHT  @29A0  8x16 raw source plane
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |  WW  WW|
;   |  WB  WB|
;   |  WB  WB|
;   |  WW  WW|
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;
; ID &0A  eye overlay DOWN  @29E8  8x16 raw source plane
;   |        |
;   |        |
;   |        |
;   |        |
;   | WB  BW |
;   | WB  BW |
;   | WW  WW |
;   | WW  WW |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;
; ID &0B  eye overlay UP  @2A30  8x16 raw source plane
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   | WW  WW |
;   | WW  WW |
;   | WB  BW |
;   | WB  BW |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;
; ID &0C  frightened ghost phase 0  @2A76  8x16 headered
;   |        |
;   |   BB   |
;   |  BBBB  |
;   | BBBBBB |
;   |BBBBBBBB|
;   |BBMBBMBB|
;   |BBMBBMBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   |BBMBMBMB|
;   |BMBMBMBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   | B B B B|
;   | B B B B|
;
; ID &0D  frightened ghost phase 1  @2ABE  8x16 headered
;   |        |
;   |   BB   |
;   |  BBBB  |
;   | BBBBBB |
;   |BBBBBBBB|
;   |BBMBBMBB|
;   |BBMBBMBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   |BBMBMBMB|
;   |BMBMBMBB|
;   |BBBBBBBB|
;   |BBBBBBBB|
;   |B B B B |
;   |B B B B |
;
; ID &0E  strawberry  @2B06  8x16 headered
;   |GG   GG |
;   | GG GG  |
;   |   GG   |
;   |  RGRR  |
;   | RWRWRR |
;   |RRRRRRRR|
;   |RRWRRWRW|
;   |WRRRRRRR|
;   |RRWRWRWR|
;   | RRRRRRR|
;   | WRWRRW |
;   | RRRRRR |
;   |  RWRW  |
;   |  RRRR  |
;   |   RW   |
;   |   RR   |
;
; ID &0F  cherry  @2B4E  8x16 headered
;   |     GG |
;   |    GG  |
;   |    G   |
;   |    G   |
;   |   GGG  |
;   |   G G  |
;   |  GG G  |
;   |  G  G  |
;   |  G RRR |
;   | RRRRRRR|
;   |RRRRRRRR|
;   |RRRRRRWR|
;   |RRWRRRWR|
;   |RRWR RR |
;   | RR     |
;   |        |
;
; ID &10  orange  @2B96  8x16 headered
;   |      G |
;   |     GGG|
;   |   YGGGG|
;   |   R   G|
;   |   R    |
;   | GRR RR |
;   |YGGGRRRR|
;   |GRGRYGRR|
;   |GGYGRRRR|
;   |YGGRGRRR|
;   |GGYGRGRR|
;   |GRGRGRRR|
;   |YGGGRGRR|
;   | GRYGRR |
;   | GGRRRR |
;   |  YRGR  |
;
; ID &11  apple  @2BDE  8x16 headered
;   | GG     |
;   |   G    |
;   |    G   |
;   | R GGGR |
;   |RRRRGRRR|
;   |RWRRRRRR|
;   |RWRRRRRR|
;   |RWRRRRRR|
;   |RWRRRRRR|
;   |RRWRRRRR|
;   |RRWRRRRR|
;   | RWRRRRR|
;   | RRWRRR |
;   |  RWRRR |
;   |  RRRR  |
;   |   RR   |
;
; ID &12  melon  @2C26  8x16 headered
;   |  GGG GG|
;   |   GGGG |
;   |     G  |
;   |   MMC  |
;   |  CMCMM |
;   | MMMMCM |
;   | CMCMMM |
;   | MMMMMC |
;   |MMMMCMM |
;   |CMCMMM  |
;   |MMMMMC  |
;   |MCMCM   |
;   |MMMM    |
;   |CMC     |
;   | M      |
;   |        |
;
; ID &13  key  @2C6E  8x16 headered
;   |   G    |
;   |  GGG   |
;   |  GGG   |
;   | GGGGG  |
;   | GGGGG  |
;   | GGGGG  |
;   |GGGGGGG |
;   |GGGGGGG |
;   |GGGGGGG |
;   |        |
;   |GGGGGGG |
;   | GGGGG  |
;   | GGGGG  |
;   |R  G    |
;   | RRRR   |
;   |    RRR |
;
; ID &14  bell  @2CB6  8x16 headered
;   |        |
;   |        |
;   |        |
;   |   Y    |
;   |  YYY   |
;   |  Y Y   |
;   | Y YYY  |
;   | Y YYY  |
;   | Y YWY  |
;   | Y YWY  |
;   | Y YWY  |
;   | Y YWY  |
;   |Y YYYWY |
;   |YYYYYYY |
;   |   Y    |
;   |        |
;
; ID &15  galaxian  @2CFE  8x16 headered
;   | GG GG  |
;   |  GGG   |
;   |   B    |
;   |  BBB   |
;   | BBBBB  |
;   | BMBBB  |
;   |BBMBBBB |
;   |BBBMBBB |
;   |BBBBMBB |
;   |BBBBMBB |
;   | BBBMB  |
;   | BBBBB  |
;   |  BBB   |
;   |  BBB   |
;   |   B    |
;   |        |
;
; ID &16  horizontal trail eraser  @2D46  2x16 headered
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;   |  |
;
; ID &17  vertical trail eraser  @2D5E  8x4 headered
;   |        |
;   |        |
;   |        |
;   |       #|
;
; ID &18  Snapper LEFT phase 0  @2D76  8x16 headered
;   |        |
;   |        |
;   |  YYY   |
;   | YYYYY  |
;   |YYYYYY  |
;   | YYYYYY |
;   |  YYYYY |
;   |   YYYY |
;   |    YYY |
;   |   YYYY |
;   |  YYYYY |
;   | YYYYYY |
;   |YYYYYY  |
;   | YYYYY  |
;   |  YYY   |
;   |        |
;
; ID &19  Snapper DOWN phase 0  @2DBE  8x16 headered
;   |        |
;   |        |
;   | Y   Y  |
;   | Y   Y  |
;   | Y   Y  |
;   |YY   YY |
;   |YYY YYY |
;   |YYY YYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;   |        |
;
; ID &1A  Snapper UP phase 0  @2E06  8x16 headered
;   |        |
;   |  YYY   |
;   | YYYYY  |
;   | YYYYY  |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYY YYY |
;   |YYY YYY |
;   |YYY YYY |
;   |YY   YY |
;   | Y   Y  |
;   | Y   Y  |
;   | Y   Y  |
;   |        |
;   |        |
;
; ID &1B  Snapper RIGHT phase 0  @2E4E  8x16 headered
;   |        |
;   |        |
;   |   YYY  |
;   |  YYYYY |
;   |  YYYYYY|
;   | YYYYYY |
;   | YYYYY  |
;   | YYYY   |
;   | YYY    |
;   | YYYY   |
;   | YYYYY  |
;   | YYYYYY |
;   |  YYYYYY|
;   |  YYYYY |
;   |   YYY  |
;   |        |
;
; ID &1C  Snapper LEFT phase 1  @2E96  8x16 headered
;   |        |
;   |        |
;   |  YYY   |
;   | YYYYY  |
;   | YYYYY  |
;   |YYYYYYY |
;   |YYYYYYY |
;   |  YYYYY |
;   |    YYY |
;   |  YYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;   |        |
;
; ID &1D  Snapper DOWN phase 1  @2EDE  8x16 headered
;   |        |
;   |        |
;   |  Y Y   |
;   | YY YY  |
;   | YY YY  |
;   |YYY YYY |
;   |YYY YYY |
;   |YYY YYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;   |        |
;
; ID &1E  Snapper UP phase 1  @2F26  8x16 headered
;   |        |
;   |  YYY   |
;   | YYYYY  |
;   | YYYYY  |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYYYYYY |
;   |YYY YYY |
;   |YYY YYY |
;   |YYY YYY |
;   | YY YY  |
;   | YY YY  |
;   |  Y Y   |
;   |        |
;   |        |
;
; ID &1F  Snapper RIGHT phase 1  @2F6E  8x16 headered
;   |        |
;   |        |
;   |   YYY  |
;   |  YYYYY |
;   |  YYYYY |
;   | YYYYYYY|
;   | YYYYYYY|
;   | YYYYY  |
;   | YYY    |
;   | YYYYY  |
;   | YYYYYYY|
;   | YYYYYYY|
;   |  YYYYY |
;   |  YYYYY |
;   |   YYY  |
;   |        |
;
; ID &23  death frame 0  @1E76  8x16 headered
;   |        |
;   |        |
;   |        |
;   |        |
;   |        |
;   |Y     Y |
;   |Y     Y |
;   |YY   YY |
;   |YY   YY |
;   |YY   YY |
;   |YYY YYY |
;   |YYY YYY |
;   |YYYYYYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;
; ID &24  death frame 1  @1E4E  8x8 headered
;   |        |
;   |Y     Y |
;   |Y     Y |
;   |YY   YY |
;   |YYY YYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;
; ID &25  death frame 2  @1E26  8x8 headered
;   |        |
;   |        |
;   |        |
;   |        |
;   |YYY YYY |
;   | YYYYY  |
;   | YYYYY  |
;   |  YYY   |
;
; ID &26  death frame 3  @1DFE  8x8 headered
;   |        |
;   |        |
;   |        |
;   |        |
;   |  Y Y   |
;   | YYYYY  |
;   |  YYY   |
;   |   Y    |
;
; ID &27  death frame 4  @1DB6  8x16 headered
;   |Y   Y  Y|
;   |Y   Y  Y|
;   | Y  Y Y |
;   | Y Y  Y |
;   |  Y  Y  |
;   |        |
;   |        |
;   |YYY  YYY|
;   |YYY  YYY|
;   |        |
;   |        |
;   |  Y  Y  |
;   | Y  Y Y |
;   | Y Y  Y |
;   |Y  Y   Y|
;   |Y  Y   Y|
;
; =============================================================================
; SPRITE GRAPHICS / PLANES REFERENCED BY IDs &00-&1F
; =============================================================================
; Requested sprites read a two-byte geometry header then pixel data.  Eye IDs &08-&0B are used as OR source planes
; and their table pointers intentionally start after the neighbouring geometry header bytes.
; -----------------------------------------------------------------------------
; Masked sprite ID &00: ghost body mask left phase 0.
; -----------------------------------------------------------------------------
sprite_ghost_body_left_phase0:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&00,&00,&00,&00,&55,&FF,&FF,&FF,&FF ; &2716
    EQUB &FF,&FF,&00,&AA,&FF,&FF,&FF,&00,&00,&00,&00,&00,&00,&AA,&FF,&FF ; &2726
    EQUB &FF,&FF,&00,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF ; &2736
    EQUB &AA,&AA,&00,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF ; &2746
    EQUB &AA,&AA,&00,&65,&6D,&70,&00,&8C                                 ; &2756
; -----------------------------------------------------------------------------
; Masked sprite ID &01: ghost body mask right phase 0.
; -----------------------------------------------------------------------------
sprite_ghost_body_right_phase0:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&FF,&FF,&FF,&00,&55,&FF,&FF,&FF,&00 ; &275E
    EQUB &00,&00,&00,&AA,&FF,&FF,&FF,&FF,&FF,&FF,&00,&00,&00,&AA,&FF,&00 ; &276E
    EQUB &00,&00,&FF,&FF,&FF,&FF,&FF,&FF,&55,&55,&00,&FF,&FF,&FF,&FF,&FF ; &277E
    EQUB &55,&55,&FF,&FF,&FF,&FF,&FF,&FF,&55,&55,&00,&FF,&FF,&FF,&FF,&FF ; &278E
    EQUB &55,&55,&00,&23,&00,&00,&43,&21                                 ; &279E
; -----------------------------------------------------------------------------
; Masked sprite ID &02: ghost body mask down phase 0.
; -----------------------------------------------------------------------------
sprite_ghost_body_down_phase0:
    EQUB &0F,&18,&00,&00,&00,&55,&AA,&AA,&AA,&AA,&00,&55,&FF,&FF,&55,&55 ; &27A6
    EQUB &55,&55,&00,&AA,&FF,&FF,&AA,&AA,&AA,&AA,&00,&00,&00,&AA,&55,&55 ; &27B6
    EQUB &55,&55,&FF,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF ; &27C6
    EQUB &AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF ; &27D6
    EQUB &AA,&AA,&00,&6F,&6F,&70,&00,&8E                                 ; &27E6
; -----------------------------------------------------------------------------
; Masked sprite ID &03: ghost body mask up phase 0.
; -----------------------------------------------------------------------------
sprite_ghost_body_up_phase0:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&FF,&AA,&AA,&00,&55,&FF,&FF,&FF,&FF ; &27EE
    EQUB &55,&55,&00,&AA,&FF,&FF,&FF,&FF,&AA,&AA,&00,&00,&00,&AA,&FF,&FF ; &27FE
    EQUB &55,&55,&AA,&AA,&FF,&FF,&FF,&FF,&55,&55,&55,&55,&FF,&FF,&FF,&FF ; &280E
    EQUB &55,&55,&AA,&AA,&FF,&FF,&FF,&FF,&55,&55,&55,&55,&FF,&FF,&FF,&FF ; &281E
    EQUB &55,&55,&00,&10,&20,&00,&00,&00                                 ; &282E
; -----------------------------------------------------------------------------
; Masked sprite ID &04: ghost body mask left phase 1.
; -----------------------------------------------------------------------------
sprite_ghost_body_left_phase1:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&00,&00,&00,&00,&55,&FF,&FF,&FF,&FF ; &2836
    EQUB &FF,&FF,&00,&AA,&FF,&FF,&FF,&00,&00,&00,&00,&00,&00,&AA,&FF,&FF ; &2846
    EQUB &FF,&FF,&00,&FF,&FF,&FF,&FF,&FF,&55,&55,&FF,&FF,&FF,&FF,&FF,&FF ; &2856
    EQUB &55,&55,&00,&FF,&FF,&FF,&FF,&FF,&55,&55,&FF,&FF,&FF,&FF,&FF,&FF ; &2866
    EQUB &55,&55,&00,&74,&00,&8E,&12,&B0                                 ; &2876
; -----------------------------------------------------------------------------
; Masked sprite ID &05: ghost body mask right phase 1.
; -----------------------------------------------------------------------------
sprite_ghost_body_right_phase1:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&FF,&FF,&FF,&00,&55,&FF,&FF,&FF,&00 ; &287E
    EQUB &00,&00,&00,&AA,&FF,&FF,&FF,&FF,&FF,&FF,&00,&00,&00,&AA,&FF,&00 ; &288E
    EQUB &00,&00,&FF,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&00,&FF,&FF,&FF,&FF,&FF ; &289E
    EQUB &AA,&AA,&FF,&FF,&FF,&FF,&FF,&FF,&AA,&AA,&00,&FF,&FF,&FF,&FF,&FF ; &28AE
    EQUB &AA,&AA,&00,&73,&00,&8E,&16,&3C                                 ; &28BE
; -----------------------------------------------------------------------------
; Masked sprite ID &06: ghost body mask down phase 1.
; -----------------------------------------------------------------------------
sprite_ghost_body_down_phase1:
    EQUB &0F,&18,&00,&00,&00,&55,&AA,&AA,&AA,&AA,&00,&55,&FF,&FF,&55,&55 ; &28C6
    EQUB &55,&55,&00,&AA,&FF,&FF,&AA,&AA,&AA,&AA,&00,&00,&00,&AA,&55,&55 ; &28D6
    EQUB &55,&55,&FF,&FF,&FF,&FF,&FF,&FF,&55,&55,&FF,&FF,&FF,&FF,&FF,&FF ; &28E6
    EQUB &55,&55,&FF,&FF,&FF,&FF,&FF,&FF,&55,&55,&FF,&FF,&FF,&FF,&FF,&FF ; &28F6
    EQUB &55,&55,&00,&00,&55,&22,&65,&74                                 ; &2906
; -----------------------------------------------------------------------------
; Masked sprite ID &07: ghost body mask up phase 1.
; -----------------------------------------------------------------------------
sprite_ghost_body_up_phase1:
    EQUB &0F,&18,&00,&00,&00,&55,&FF,&FF,&AA,&AA,&00,&55,&FF,&FF,&FF,&FF ; &290E
    EQUB &55,&55,&00,&AA,&FF,&FF,&FF,&FF,&AA,&AA,&00,&00,&00,&AA,&FF,&FF ; &291E
    EQUB &55,&55,&AA,&AA,&FF,&FF,&FF,&FF,&AA,&AA,&55,&55,&FF,&FF,&FF,&FF ; &292E
    EQUB &AA,&AA,&AA,&AA,&FF,&FF,&FF,&FF,&AA,&AA,&55,&55,&FF,&FF,&FF,&FF ; &293E
    EQUB &AA,&AA,&00,&00,&00,&00,&00,&00,&0F,&18                         ; &294E
; -----------------------------------------------------------------------------
; Masked sprite ID &08: eye overlay left.
; -----------------------------------------------------------------------------
sprite_eyes_left_overlay:
    EQUB &00,&00,&00,&00,&00,&3F,&35,&35,&00,&00,&00,&00,&00,&00,&00,&00 ; &2958
    EQUB &00,&00,&00,&00,&00,&3F,&35,&35,&00,&00,&00,&00,&00,&00,&00,&00 ; &2968
    EQUB &3F,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2978
    EQUB &3F,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2988
    EQUB &00,&00,&00,&00,&00,&00,&0F,&18                                 ; &2998
; -----------------------------------------------------------------------------
; Masked sprite ID &09: eye overlay right.
; -----------------------------------------------------------------------------
sprite_eyes_right_overlay:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&3F,&3A,&3A ; &29A0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&3F,&3A,&3A ; &29B0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&3F,&00,&00,&00,&00,&00,&00,&00 ; &29C0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&3F,&00,&00,&00,&00,&00,&00,&00 ; &29D0
    EQUB &00,&00,&00,&00,&00,&00,&0F,&18                                 ; &29E0
; -----------------------------------------------------------------------------
; Masked sprite ID &0A: eye overlay down.
; -----------------------------------------------------------------------------
sprite_eyes_down_overlay:
    EQUB &00,&00,&00,&00,&15,&15,&15,&15,&00,&00,&00,&00,&20,&20,&2A,&2A ; &29E8
    EQUB &00,&00,&00,&00,&10,&10,&15,&15,&00,&00,&00,&00,&2A,&2A,&2A,&2A ; &29F8
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2A08
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2A18
    EQUB &00,&82,&26,&83,&A5,&71,&0F,&18                                 ; &2A28
; -----------------------------------------------------------------------------
; Masked sprite ID &0B: eye overlay up.
; -----------------------------------------------------------------------------
sprite_eyes_up_overlay:
    EQUB &00,&00,&00,&00,&00,&00,&15,&15,&00,&00,&00,&00,&00,&00,&2A,&2A ; &2A30
    EQUB &00,&00,&00,&00,&00,&00,&15,&15,&00,&00,&00,&00,&00,&00,&2A,&2A ; &2A40
    EQUB &15,&15,&00,&00,&00,&00,&00,&00,&20,&20,&00,&00,&00,&00,&00,&00 ; &2A50
    EQUB &10,&10,&00,&00,&00,&00,&00,&00,&2A,&2A,&00,&00,&00,&00,&00,&00 ; &2A60
    EQUB &00,&82,&A4,&73,&68,&60                                         ; &2A70
; -----------------------------------------------------------------------------
; Masked sprite ID &0C: frightened ghost frame 0.
; -----------------------------------------------------------------------------
sprite_data_frightened_frame0:
    EQUB &0F,&18,&00,&00,&00,&50,&F0,&F0,&F0,&F0,&00,&50,&F0,&F0,&F0,&F2 ; &2A76
    EQUB &F2,&F0,&00,&A0,&F0,&F0,&F0,&F1,&F1,&F0,&00,&00,&00,&A0,&F0,&F0 ; &2A86
    EQUB &F0,&F0,&F0,&F0,&F0,&F1,&F0,&F0,&50,&50,&F0,&F0,&F2,&F1,&F0,&F0 ; &2A96
    EQUB &50,&50,&F0,&F0,&F2,&F1,&F0,&F0,&50,&50,&F0,&F0,&F2,&F0,&F0,&F0 ; &2AA6
    EQUB &50,&50,&00,&BD,&13,&0C,&85,&81                                 ; &2AB6
; -----------------------------------------------------------------------------
; Masked sprite ID &0D: frightened ghost frame 1.
; -----------------------------------------------------------------------------
sprite_data_frightened_frame1:
    EQUB &0F,&18,&00,&00,&00,&50,&F0,&F0,&F0,&F0,&00,&50,&F0,&F0,&F0,&F2 ; &2ABE
    EQUB &F2,&F0,&00,&A0,&F0,&F0,&F0,&F1,&F1,&F0,&00,&00,&00,&A0,&F0,&F0 ; &2ACE
    EQUB &F0,&F0,&F0,&F0,&F0,&F1,&F0,&F0,&A0,&A0,&F0,&F0,&F2,&F1,&F0,&F0 ; &2ADE
    EQUB &A0,&A0,&F0,&F0,&F2,&F1,&F0,&F0,&A0,&A0,&F0,&F0,&F2,&F0,&F0,&F0 ; &2AEE
    EQUB &A0,&A0,&00,&98,&29,&07,&D0,&18                                 ; &2AFE
; -----------------------------------------------------------------------------
; Masked sprite ID &0E: strawberry.
; -----------------------------------------------------------------------------
sprite_fruit_strawberry:
    EQUB &0F,&18,&0C,&55,&00,&00,&01,&03,&03,&2B,&00,&08,&55,&06,&2B,&03 ; &2B06
    EQUB &2B,&03,&55,&0C,&08,&03,&2B,&03,&17,&03,&08,&00,&00,&00,&02,&03 ; &2B16
    EQUB &17,&03,&03,&01,&15,&01,&00,&00,&00,&00,&2B,&03,&17,&03,&17,&03 ; &2B26
    EQUB &01,&01,&2B,&03,&03,&03,&17,&03,&2A,&02,&2B,&03,&2A,&02,&00,&00 ; &2B36
    EQUB &00,&00,&00,&6B,&FE,&A9,&30,&8D                                 ; &2B46
; -----------------------------------------------------------------------------
; Masked sprite ID &0F: cherry.
; -----------------------------------------------------------------------------
sprite_fruit_cherry:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&55,&55 ; &2B4E
    EQUB &0C,&08,&55,&0C,&08,&08,&0C,&55,&55,&55,&08,&00,&00,&00,&00,&00 ; &2B5E
    EQUB &00,&00,&00,&01,&03,&03,&03,&03,&01,&00,&08,&03,&03,&03,&2B,&2B ; &2B6E
    EQUB &02,&00,&03,&03,&03,&03,&03,&01,&00,&00,&02,&03,&03,&2B,&2B,&02 ; &2B7E
    EQUB &00,&00,&00,&FC,&8D,&58,&0C,&A9                                 ; &2B8E
; -----------------------------------------------------------------------------
; Masked sprite ID &10: orange.
; -----------------------------------------------------------------------------
sprite_fruit_orange:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&55,&5F,&AB,&00,&00,&05,&01,&01,&03 ; &2B96
    EQUB &FF,&AB,&00,&55,&FF,&00,&00,&01,&03,&0E,&AA,&FF,&FF,&55,&00,&02 ; &2BA6
    EQUB &03,&03,&FF,&5F,&FF,&AB,&5F,&55,&55,&00,&5F,&AB,&5F,&AB,&FF,&07 ; &2BB6
    EQUB &AB,&0B,&03,&AB,&57,&AB,&57,&AB,&03,&AB,&03,&03,&03,&03,&03,&02 ; &2BC6
    EQUB &02,&00,&00,&40,&40,&40,&40,&40                                 ; &2BD6
; -----------------------------------------------------------------------------
; Masked sprite ID &11: apple.
; -----------------------------------------------------------------------------
sprite_fruit_apple:
    EQUB &0F,&18,&55,&00,&00,&01,&03,&17,&17,&17,&08,&55,&00,&55,&03,&03 ; &2BDE
    EQUB &03,&03,&00,&00,&08,&0C,&09,&03,&03,&03,&00,&00,&00,&02,&03,&03 ; &2BEE
    EQUB &03,&03,&17,&03,&03,&01,&01,&00,&00,&00,&03,&2B,&2B,&2B,&17,&17 ; &2BFE
    EQUB &03,&01,&03,&03,&03,&03,&03,&03,&03,&02,&03,&03,&03,&03,&02,&02 ; &2C0E
    EQUB &00,&00,&00,&07,&0C,&85,&71,&B9                                 ; &2C1E
; -----------------------------------------------------------------------------
; Masked sprite ID &12: melon.
; -----------------------------------------------------------------------------
sprite_fruit_melon:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&11,&54,&11,&FF,&55,&00,&11,&B9,&33 ; &2C26
    EQUB &76,&33,&AA,&FF,&55,&76,&B9,&76,&33,&33,&FF,&AA,&00,&00,&22,&22 ; &2C36
    EQUB &22,&A8,&33,&B9,&33,&76,&33,&B9,&11,&00,&33,&B9,&33,&76,&33,&A8 ; &2C46
    EQUB &00,&00,&B9,&33,&76,&22,&00,&00,&00,&00,&22,&00,&00,&00,&00,&00 ; &2C56
    EQUB &00,&00,&00,&C0,&C0,&00,&00,&00                                 ; &2C66
; -----------------------------------------------------------------------------
; Masked sprite ID &13: key.
; -----------------------------------------------------------------------------
sprite_fruit_key:
    EQUB &0F,&18,&00,&00,&00,&55,&55,&55,&FF,&FF,&55,&FF,&FF,&FF,&FF,&FF ; &2C6E
    EQUB &FF,&FF,&00,&AA,&AA,&FF,&FF,&FF,&FF,&FF,&00,&00,&00,&00,&00,&00 ; &2C7E
    EQUB &AA,&AA,&FF,&00,&FF,&55,&55,&02,&01,&00,&FF,&00,&FF,&FF,&FF,&55 ; &2C8E
    EQUB &03,&00,&FF,&00,&FF,&FF,&FF,&00,&02,&03,&AA,&00,&AA,&00,&00,&00 ; &2C9E
    EQUB &00,&02,&00,&00,&00,&00,&00,&00                                 ; &2CAE
; -----------------------------------------------------------------------------
; Masked sprite ID &14: bell.
; -----------------------------------------------------------------------------
sprite_fruit_bell:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&00,&05,&05,&00,&00,&00,&05,&0F,&0A ; &2CB6
    EQUB &05,&05,&00,&00,&00,&00,&0A,&0A,&0F,&0F,&00,&00,&00,&00,&00,&00 ; &2CC6
    EQUB &00,&00,&05,&05,&05,&05,&0A,&0F,&00,&00,&05,&05,&05,&05,&0F,&0F ; &2CD6
    EQUB &05,&00,&2F,&2F,&2F,&2F,&1F,&0F,&00,&00,&00,&00,&00,&00,&0A,&0A ; &2CE6
    EQUB &00,&00,&00,&00,&0C,&18,&6D,&5D                                 ; &2CF6
; -----------------------------------------------------------------------------
; Masked sprite ID &15: galaxian.
; -----------------------------------------------------------------------------
sprite_fruit_galaxian:
    EQUB &0F,&18,&55,&00,&00,&00,&10,&10,&30,&30,&08,&0C,&10,&30,&30,&32 ; &2CFE
    EQUB &32,&31,&0C,&08,&00,&20,&30,&30,&30,&30,&00,&00,&00,&00,&00,&00 ; &2D0E
    EQUB &20,&20,&30,&30,&10,&10,&00,&00,&00,&00,&30,&30,&30,&30,&30,&30 ; &2D1E
    EQUB &10,&00,&32,&32,&32,&30,&20,&20,&00,&00,&20,&20,&00,&00,&00,&00 ; &2D2E
    EQUB &00,&00,&00,&5C,&23,&A9,&55,&8D                                 ; &2D3E
; -----------------------------------------------------------------------------
; Masked sprite ID &16: horizontal trailing-edge erase geometry.
; -----------------------------------------------------------------------------
sprite_data_erase_horizontal_trail:
    EQUB &0F,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2D46
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &2D56
; -----------------------------------------------------------------------------
; Masked sprite ID &17: vertical trailing-edge erase geometry.
; -----------------------------------------------------------------------------
sprite_data_erase_vertical_trail:
    EQUB &03,&18,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &2D5E
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &2D6E
; -----------------------------------------------------------------------------
; Masked sprite ID &18: Snapper left phase 0.
; -----------------------------------------------------------------------------
sprite_snapper_left_phase0:
    EQUB &0F,&18,&00,&00,&00,&05,&0F,&05,&00,&00,&00,&00,&0F,&0F,&0F,&0F ; &2D76
    EQUB &0F,&05,&00,&00,&0A,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&00,&0A ; &2D86
    EQUB &0A,&0A,&00,&00,&00,&05,&0F,&05,&00,&00,&00,&05,&0F,&0F,&0F,&0F ; &2D96
    EQUB &0F,&00,&0F,&0F,&0F,&0F,&0F,&0F,&0A,&00,&0A,&0A,&0A,&0A,&00,&00 ; &2DA6
    EQUB &00,&00,&00,&23,&4C,&AC,&25,&AD                                 ; &2DB6
; -----------------------------------------------------------------------------
; Masked sprite ID &19: Snapper down phase 0.
; -----------------------------------------------------------------------------
sprite_snapper_down_phase0:
    EQUB &0F,&18,&00,&00,&05,&05,&05,&0F,&0F,&0F,&00,&00,&00,&00,&00,&00 ; &2DBE
    EQUB &0A,&0A,&00,&00,&05,&05,&05,&05,&0F,&0F,&00,&00,&00,&00,&00,&0A ; &2DCE
    EQUB &0A,&0A,&0F,&0F,&0F,&0F,&05,&05,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F ; &2DDE
    EQUB &0F,&00,&0F,&0F,&0F,&0F,&0F,&0F,&0A,&00,&0A,&0A,&0A,&0A,&00,&00 ; &2DEE
    EQUB &00,&00,&00,&00,&00,&00,&00,&00                                 ; &2DFE
; -----------------------------------------------------------------------------
; Masked sprite ID &1A: Snapper up phase 0.
; -----------------------------------------------------------------------------
sprite_snapper_up_phase0:
    EQUB &0F,&18,&00,&00,&05,&05,&0F,&0F,&0F,&0F,&00,&0F,&0F,&0F,&0F,&0F ; &2E06
    EQUB &0F,&0A,&00,&0A,&0F,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&0A,&0A ; &2E16
    EQUB &0A,&0A,&0F,&0F,&0F,&05,&05,&05,&00,&00,&0A,&0A,&00,&00,&00,&00 ; &2E26
    EQUB &00,&00,&0F,&0F,&05,&05,&05,&05,&00,&00,&0A,&0A,&0A,&00,&00,&00 ; &2E36
    EQUB &00,&00,&00,&AA,&FF,&FF,&FF,&FF                                 ; &2E46
; -----------------------------------------------------------------------------
; Masked sprite ID &1B: Snapper right phase 0.
; -----------------------------------------------------------------------------
sprite_snapper_right_phase0:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&05,&05,&05,&00,&00,&05,&0F,&0F,&0F ; &2E4E
    EQUB &0F,&0F,&00,&00,&0F,&0F,&0F,&0F,&0F,&0A,&00,&00,&00,&0A,&0F,&0A ; &2E5E
    EQUB &00,&00,&05,&05,&05,&05,&00,&00,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F ; &2E6E
    EQUB &05,&00,&00,&0A,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&0A,&0F,&0A ; &2E7E
    EQUB &00,&00,&00,&AA,&FF,&00,&00,&00                                 ; &2E8E
; -----------------------------------------------------------------------------
; Masked sprite ID &1C: Snapper left phase 1.
; -----------------------------------------------------------------------------
sprite_snapper_left_phase1:
    EQUB &0F,&18,&00,&00,&00,&05,&05,&0F,&0F,&00,&00,&00,&0F,&0F,&0F,&0F ; &2E96
    EQUB &0F,&0F,&00,&00,&0A,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&00,&0A ; &2EA6
    EQUB &0A,&0A,&00,&00,&0F,&0F,&05,&05,&00,&00,&00,&0F,&0F,&0F,&0F,&0F ; &2EB6
    EQUB &0F,&00,&0F,&0F,&0F,&0F,&0F,&0F,&0A,&00,&0A,&0A,&0A,&0A,&00,&00 ; &2EC6
    EQUB &00,&00,&00,&AA,&55,&55,&55,&55                                 ; &2ED6
; -----------------------------------------------------------------------------
; Masked sprite ID &1D: Snapper down phase 1.
; -----------------------------------------------------------------------------
sprite_snapper_down_phase1:
    EQUB &0F,&18,&00,&00,&00,&05,&05,&0F,&0F,&0F,&00,&00,&0A,&0A,&0A,&0A ; &2EDE
    EQUB &0A,&0A,&00,&00,&0A,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&00,&0A ; &2EEE
    EQUB &0A,&0A,&0F,&0F,&0F,&0F,&05,&05,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F ; &2EFE
    EQUB &0F,&00,&0F,&0F,&0F,&0F,&0F,&0F,&0A,&00,&0A,&0A,&0A,&0A,&00,&00 ; &2F0E
    EQUB &00,&00,&00,&AA,&FF,&FF,&55,&55                                 ; &2F1E
; -----------------------------------------------------------------------------
; Masked sprite ID &1E: Snapper up phase 1.
; -----------------------------------------------------------------------------
sprite_snapper_up_phase1:
    EQUB &0F,&18,&00,&00,&05,&05,&0F,&0F,&0F,&0F,&00,&0F,&0F,&0F,&0F,&0F ; &2F26
    EQUB &0F,&0F,&00,&0A,&0F,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&00,&0A,&0A ; &2F36
    EQUB &0A,&0A,&0F,&0F,&0F,&05,&05,&00,&00,&00,&0A,&0A,&0A,&0A,&0A,&0A ; &2F46
    EQUB &00,&00,&0F,&0F,&0F,&0F,&0F,&0A,&00,&00,&0A,&0A,&0A,&00,&00,&00 ; &2F56
    EQUB &00,&00,&00,&AA,&FF,&FF,&FF,&FF                                 ; &2F66
; -----------------------------------------------------------------------------
; Masked sprite ID &1F: Snapper right phase 1.
; -----------------------------------------------------------------------------
sprite_snapper_right_phase1:
    EQUB &0F,&18,&00,&00,&00,&00,&00,&05,&05,&05,&00,&00,&05,&0F,&0F,&0F ; &2F6E
    EQUB &0F,&0F,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&0A,&0A,&0F ; &2F7E
    EQUB &0F,&00,&05,&05,&05,&05,&00,&00,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F ; &2F8E
    EQUB &05,&00,&00,&0F,&0F,&0F,&0F,&0F,&0F,&00,&00,&00,&0F,&0F,&0A,&0A ; &2F9E
    EQUB &00,&00,&00,&AA,&FF,&00,&00,&00                                 ; &2FAE
; -----------------------------------------------------------------------------
; Unreferenced &0F,&18 geometry-header pair immediately before READY tune data.
; It sits exactly at the natural &48-byte boundary after sprite &1F (&2F6E+&48=&2FB6),
; i.e. where another full-size sprite would normally begin.  The live ID-&20 pointer instead
; points to &FED0, so this looks like the abandoned header of a removed sprite slot.
; -----------------------------------------------------------------------------
orphan_sprite_header_2FB6:
    EQUB &0F,&18                                                         ; &2FB6
; -----------------------------------------------------------------------------
; 43 packed READY-tune entries consumed by play_ready_tune.  bit0=rest, bit1=duration 2 instead of 1, bits2..7=pitch.
; Structural decode (byte-for-byte):
;   notes 00..09 = phrase A
;   notes 10..19 = the same ten control patterns with every packed byte +&04 (pitch transposition by 4 units)
;   notes 20..29 = phrase A repeated exactly
;   notes 30..42 = 13-note ascending/final coda
; This repeated form makes the following post-tune note-like residue particularly suggestive of an abandoned alternate ending.
; -----------------------------------------------------------------------------
ready_tune_notes:
    EQUB &62,&92,&7E,&72,&92,&7C,&7D,&72,&73,&71,&66,&96,&82,&76,&96,&80 ; &2FB8
    EQUB &81,&76,&77,&75,&62,&92,&7E,&72,&92,&7C,&7D,&72,&73,&71,&6C,&70 ; &2FC8
    EQUB &74,&77,&78,&7C,&80,&83,&84,&88,&8C,&BF,&92                     ; &2FD8
; -----------------------------------------------------------------------------
; 29 bytes after the 43-note tune; no direct reference from proven reachable code.
; The first 12 bytes ALL satisfy the READY-note format and form a coherent rising sequence:
;   &76,&78,&7C,&80,&81,&82,&84,&88,&8C,&BD,&BE,&92
; It overlaps the live coda's &78,&7C,&80,...,&84,&88,&8C contour but changes rest/duration bits
; and introduces two &BC-pitch records.  This is strong structural evidence for a discarded
; alternate coda/continuation, although no reachable code consumes it, so it remains raw EQUB.
; -----------------------------------------------------------------------------
legacy_unreferenced_post_tune_data:
    EQUB &76,&78,&7C,&80,&81,&82,&84,&88,&8C,&BD,&BE,&92,&00,&0A,&0A,&86 ; &2FE3
    EQUB &0B,&01,&00,&00,&00,&55,&00,&00,&00,&0A,&00,&00,&00             ; &2FF3

; =============================================================================
; HIGH-SCORE MODULE (STORED HERE, EXECUTES AT &0400-&06FF)
; =============================================================================

high_score_messages_source:
high_score_congratulations_length:
    EQUB &89                                                             ; &3000  message length = &89
; -----------------------------------------------------------------------------
; VDU/control-code message shown only when the new score reaches the Top Eight.
; -----------------------------------------------------------------------------
high_score_congratulations_text:
    EQUB &16,&07,&1F,&07,&03,&86,&9D,&84,&8D,&43,&6F,&6E,&67,&72,&61     ; &3001  .........Congra
    EQUB &74,&75,&6C,&61,&74,&69,&6F,&6E,&73,&21,&21,&20,&20,&20,&9C,&1F ; &3010  tulations!!   ..
    EQUB &07,&04,&86,&9D,&84,&8D,&43,&6F,&6E,&67,&72,&61,&74,&75,&6C,&61 ; &3020  ......Congratula
    EQUB &74,&69,&6F,&6E,&73,&21,&21,&20,&20,&20,&9C,&0D,&0A,&0A,&0A,&82 ; &3030  tions!!   ......
    EQUB &20,&20,&20,&59,&6F,&75,&72,&20,&73,&63,&6F,&72,&65,&20,&69,&73 ; &3040     Your score is
    EQUB &20,&69,&6E,&20,&74,&68,&65,&20,&54,&6F,&70,&20,&45,&69,&67,&68 ; &3050   in the Top Eigh
    EQUB &74,&2E,&1F,&07,&0A,&81,&50,&6C,&65,&61,&73,&65,&20,&65,&6E,&74 ; &3060  t.....Please ent
    EQUB &65,&72,&20,&79,&6F,&75,&72,&20,&6E,&61,&6D,&65,&3A,&1F,&07,&0F ; &3070  er your name:...
    EQUB &86,&9D,&84,&1F,&1F,&0F,&9C,&1F,&0A,&0F,&30                     ; &3080  ..........0
; Length byte for the score-table heading/control-code stream copied to execution address &048B.
high_score_scores_screen_length:
    EQUB &1B                                                             ; &308B  message length = &1B
high_score_scores_screen_text:
    EQUB &16,&07,&1F,&0E                                                 ; &308C  ....
    EQUB &01,&81,&8D,&53,&63,&6F,&72,&65,&73,&1F,&0E,&02,&81,&8D,&53,&63 ; &3090  ...Scores.....Sc
    EQUB &6F,&72,&65,&73,&0A,&0A,&0D                                     ; &30A0  ores...
high_score_not_qualifying_source:
    JMP display_high_scores_exec       ; &30A7 -> exec &04A7  4C B7 05
; -----------------------------------------------------------------------------
; Top-Eight insertion handler, executing at &04AA after the &3000-&32FF relocation.  The score table
; uses 3-byte packed BCD records.  A qualifying score reads up to 19 printable characters with OSWORD 0, then
; performs an insertion/bubble pass; the display routine prints the best eight records in descending order.
; -----------------------------------------------------------------------------
high_score_handler_source:
    ; Entry 0 at &06D0 is a temporary insertion slot.  The persistent Top Eight are
    ; entries 1..8 (offsets 3..24); the bubble/insertion pass moves a qualifying new
    ; score upward and swaps its parallel two-byte name pointer at the same offset.
    LDX #&64                           ; &30AA -> exec &04AA  A2 64
    JSR delay_clock_ticks_from_x       ; &30AC -> exec &04AC  20 23 1B
    LDA score_bcd_hi                   ; &30AF -> exec &04AF  A5 36
    CMP high_score_bcd_table+HIGH_SCORE_LOWEST_OFFSET+2 ; &30B1 -> exec &04B1  CD D5 06
    BCC high_score_not_qualifying_source ; &30B4 -> exec &04B4  90 F1
    BNE high_score_qualifies                       ; &30B6 -> exec &04B6  D0 10
    LDA score_bcd_mid                  ; &30B8 -> exec &04B8  A5 35
    CMP high_score_bcd_table+HIGH_SCORE_LOWEST_OFFSET+1 ; &30BA -> exec &04BA  CD D4 06
    BCC high_score_not_qualifying_source ; &30BD -> exec &04BD  90 E8
    BNE high_score_qualifies                       ; &30BF -> exec &04BF  D0 07
    LDA score_bcd_lo                   ; &30C1 -> exec &04C1  A5 34
    CMP high_score_bcd_table+HIGH_SCORE_LOWEST_OFFSET ; &30C3 -> exec &04C3  CD D3 06
    BCC high_score_not_qualifying_source ; &30C6 -> exec &04C6  90 DF
high_score_qualifies:
    LDY #&00                           ; &30C8 -> exec &04C8  A0 00
    LDA high_score_messages_exec       ; &30CA -> exec &04CA  AD 00 04
    STA scratch14                      ; &30CD -> exec &04CD  85 14
print_high_score_congratulations:
    LDA high_score_congratulations_exec,Y ; &30CF -> exec &04CF  B9 01 04
    JSR OSWRCH                         ; &30D2 -> exec &04D2  20 EE FF
    INY                                ; &30D5 -> exec &04D5  C8
    CPY scratch14                      ; &30D6 -> exec &04D6  C4 14
    BNE print_high_score_congratulations                       ; &30D8 -> exec &04D8  D0 F5
    LDX #&00                           ; &30DA -> exec &04DA  A2 00
    LDA #OSBYTE_FLUSH_INPUT             ; &30DC -> exec &04DC  A9 0F
    JSR OSBYTE                         ; &30DE -> exec &04DE  20 F4 FF
    LDY #&07                           ; &30E1 -> exec &04E1  A0 07
    LDX #&E0                           ; &30E3 -> exec &04E3  A2 E0
    LDA #&E5                           ; &30E5 -> exec &04E5  A9 E5
    STA high_score_input_block_addr                     ; &30E7 -> exec &04E7  8D E0 07
    STY high_score_input_block_addr+1                          ; &30EA -> exec &04EA  8C E1 07
    LDA #HIGH_SCORE_MAX_NAME_CHARS                           ; &30ED -> exec &04ED  A9 13
    STA high_score_input_block_addr+2                          ; &30EF -> exec &04EF  8D E2 07
    LDA #ASCII_SPACE                           ; &30F2 -> exec &04F2  A9 20
    STA high_score_input_block_addr+3                          ; &30F4 -> exec &04F4  8D E3 07
    LDA #ASCII_TILDE                           ; &30F7 -> exec &04F7  A9 7E
    STA high_score_input_block_addr+4                          ; &30F9 -> exec &04F9  8D E4 07
    LDA #&00                           ; &30FC -> exec &04FC  A9 00
    JSR OSWORD                         ; &30FE -> exec &04FE  20 F1 FF
    BCC store_entered_name                       ; &3101 -> exec &0501  90 05
    LDA #&0D                           ; &3103 -> exec &0503  A9 0D
    STA high_score_input_buffer_addr                     ; &3105 -> exec &0505  8D E5 07
store_entered_name:
    LDA high_score_name_pointer_table                          ; &3108 -> exec &0508  AD EE 06
    STA coord_x                        ; &310B -> exec &050B  85 70
    LDA high_score_name_pointer_table+1                          ; &310D -> exec &050D  AD EF 06
    STA coord_y                        ; &3110 -> exec &0510  85 71
    LDY #&13                           ; &3112 -> exec &0512  A0 13
copy_entered_name_to_insertion_slot:
    LDA high_score_input_buffer_addr,Y                        ; &3114 -> exec &0514  B9 E5 07
    STA (coord_x),Y                    ; &3117 -> exec &0517  91 70
    DEY                                ; &3119 -> exec &0519  88
    BPL copy_entered_name_to_insertion_slot                       ; &311A -> exec &051A  10 F8
    LDA score_bcd_lo                   ; &311C -> exec &051C  A5 34
    STA high_score_bcd_table           ; &311E -> exec &051E  8D D0 06
    LDA score_bcd_mid                  ; &3121 -> exec &0521  A5 35
    STA high_score_bcd_table+1         ; &3123 -> exec &0523  8D D1 06
    LDA score_bcd_hi                   ; &3126 -> exec &0526  A5 36
    STA high_score_bcd_table+2         ; &3128 -> exec &0528  8D D2 06
    LDX #HIGH_SCORE_ENTRY_BYTES                           ; &312B -> exec &052B  A2 03
    STX scratch1                       ; &312D -> exec &052D  86 01
    DEC scratch1                       ; &312F -> exec &052F  C6 01
    DEC scratch1                       ; &3131 -> exec &0531  C6 01
    DEC scratch1                       ; &3133 -> exec &0533  C6 01
    LDY scratch1                       ; &3135 -> exec &0535  A4 01
    LDA high_score_bcd_table+2,Y                        ; &3137 -> exec &0537  B9 D2 06
    CMP high_score_bcd_table+2,X                        ; &313A -> exec &053A  DD D2 06
    BCC advance_high_score_sort                       ; &313D -> exec &053D  90 6E
    BNE swap_high_score_entries                       ; &313F -> exec &053F  D0 12
    LDA high_score_bcd_table+1,Y                        ; &3141 -> exec &0541  B9 D1 06
    CMP high_score_bcd_table+1,X                        ; &3144 -> exec &0544  DD D1 06
    BCC advance_high_score_sort                       ; &3147 -> exec &0547  90 64
    BNE swap_high_score_entries                       ; &3149 -> exec &0549  D0 08
    LDA high_score_bcd_table,Y                        ; &314B -> exec &054B  B9 D0 06
    CMP high_score_bcd_table,X                        ; &314E -> exec &054E  DD D0 06
    BCC advance_high_score_sort                       ; &3151 -> exec &0551  90 5A
swap_high_score_entries:
    LDA high_score_bcd_table,X                        ; &3153 -> exec &0553  BD D0 06
    STA high_score_swap_temp                          ; &3156 -> exec &0556  8D 0C 07
    LDA high_score_bcd_table+1,X                        ; &3159 -> exec &0559  BD D1 06
    STA high_score_swap_temp+1                          ; &315C -> exec &055C  8D 0D 07
    LDA high_score_bcd_table+2,X                        ; &315F -> exec &055F  BD D2 06
    STA high_score_swap_temp+2                          ; &3162 -> exec &0562  8D 0E 07
    LDA high_score_bcd_table,Y                        ; &3165 -> exec &0565  B9 D0 06
    STA high_score_bcd_table,X                        ; &3168 -> exec &0568  9D D0 06
    LDA high_score_bcd_table+1,Y                        ; &316B -> exec &056B  B9 D1 06
    STA high_score_bcd_table+1,X                        ; &316E -> exec &056E  9D D1 06
    LDA high_score_bcd_table+2,Y                        ; &3171 -> exec &0571  B9 D2 06
    STA high_score_bcd_table+2,X                        ; &3174 -> exec &0574  9D D2 06
    LDA high_score_swap_temp                          ; &3177 -> exec &0577  AD 0C 07
    STA high_score_bcd_table,Y                        ; &317A -> exec &057A  99 D0 06
    LDA high_score_swap_temp+1                          ; &317D -> exec &057D  AD 0D 07
    STA high_score_bcd_table+1,Y                        ; &3180 -> exec &0580  99 D1 06
    LDA high_score_swap_temp+2                          ; &3183 -> exec &0583  AD 0E 07
    STA high_score_bcd_table+2,Y                        ; &3186 -> exec &0586  99 D2 06
    LDA high_score_name_pointer_table,X                        ; &3189 -> exec &0589  BD EE 06
    STA high_score_swap_temp                          ; &318C -> exec &058C  8D 0C 07
    LDA high_score_name_pointer_table+1,X                        ; &318F -> exec &058F  BD EF 06
    STA high_score_swap_temp+1                          ; &3192 -> exec &0592  8D 0D 07
    LDA high_score_name_pointer_table,Y                        ; &3195 -> exec &0595  B9 EE 06
    STA high_score_name_pointer_table,X                        ; &3198 -> exec &0598  9D EE 06
    LDA high_score_name_pointer_table+1,Y                        ; &319B -> exec &059B  B9 EF 06
    STA high_score_name_pointer_table+1,X                        ; &319E -> exec &059E  9D EF 06
    LDA high_score_swap_temp                          ; &31A1 -> exec &05A1  AD 0C 07
    STA high_score_name_pointer_table,Y                        ; &31A4 -> exec &05A4  99 EE 06
    LDA high_score_swap_temp+1                          ; &31A7 -> exec &05A7  AD 0D 07
    STA high_score_name_pointer_table+1,Y                        ; &31AA -> exec &05AA  99 EF 06
advance_high_score_sort:
    INX                                ; &31AD -> exec &05AD  E8
    INX                                ; &31AE -> exec &05AE  E8
    INX                                ; &31AF -> exec &05AF  E8
    CPX #HIGH_SCORE_SORT_END                           ; &31B0 -> exec &05B0  E0 1B
    BEQ display_high_scores_source     ; &31B2 -> exec &05B2  F0 03
    JMP high_score_sort_loop_exec      ; &31B4 -> exec &05B4  4C 2D 05
; -----------------------------------------------------------------------------
; Render the Top Eight screen.  Scores are stored internally in units of ten points, so a literal final
; ASCII zero is appended after the three packed-BCD bytes.  Names are reached through the parallel pointer table.
; -----------------------------------------------------------------------------
display_high_scores_source:
    LDY #&00                           ; &31B7 -> exec &05B7  A0 00
    LDA high_score_scores_length_exec  ; &31B9 -> exec &05B9  AD 8B 04
    STA scratch14                      ; &31BC -> exec &05BC  85 14
print_high_score_heading:
    LDA high_score_scores_text_exec,Y  ; &31BE -> exec &05BE  B9 8C 04
    JSR OSWRCH                         ; &31C1 -> exec &05C1  20 EE FF
    INY                                ; &31C4 -> exec &05C4  C8
    CPY scratch14                      ; &31C5 -> exec &05C5  C4 14
    BNE print_high_score_heading                       ; &31C7 -> exec &05C7  D0 F5
    LDA #&0A                           ; &31C9 -> exec &05C9  A9 0A
    LDX #&20                           ; &31CB -> exec &05CB  A2 20
    JSR write_crtc_register            ; &31CD -> exec &05CD  20 69 1A
    LDX #HIGH_SCORE_DISPLAY_FIRST                           ; &31D0 -> exec &05D0  A2 18
    LDY #&01                           ; &31D2 -> exec &05D2  A0 01
    STY scratch14                      ; &31D4 -> exec &05D4  84 14
display_next_high_score:
    LDA #&20                           ; &31D6 -> exec &05D6  A9 20
    LDY #&03                           ; &31D8 -> exec &05D8  A0 03
print_rank_leading_spaces:
    JSR OSWRCH                         ; &31DA -> exec &05DA  20 EE FF
    DEY                                ; &31DD -> exec &05DD  88
    BPL print_rank_leading_spaces                       ; &31DE -> exec &05DE  10 FA
    LDA scratch14                      ; &31E0 -> exec &05E0  A5 14
    ORA #&30                           ; &31E2 -> exec &05E2  09 30
    JSR OSWRCH                         ; &31E4 -> exec &05E4  20 EE FF
    LDA #&2E                           ; &31E7 -> exec &05E7  A9 2E
    LDY #&03                           ; &31E9 -> exec &05E9  A0 03
print_rank_score_separator:
    JSR OSWRCH                         ; &31EB -> exec &05EB  20 EE FF
    DEY                                ; &31EE -> exec &05EE  88
    BPL print_rank_score_separator                       ; &31EF -> exec &05EF  10 FA
    LDA #&FF                           ; &31F1 -> exec &05F1  A9 FF
    STA scratch33                      ; &31F3 -> exec &05F3  85 33
    LDA high_score_bcd_table+2,X                        ; &31F5 -> exec &05F5  BD D2 06
    JSR print_bcd_byte_exec            ; &31F8 -> exec &05F8  20 55 06
    LDA high_score_bcd_table+1,X                        ; &31FB -> exec &05FB  BD D1 06
    JSR print_bcd_byte_exec            ; &31FE -> exec &05FE  20 55 06
    LDA high_score_bcd_table,X                        ; &3201 -> exec &0601  BD D0 06
    JSR print_bcd_byte_exec            ; &3204 -> exec &0604  20 55 06
    LDA #&30                           ; &3207 -> exec &0607  A9 30
    JSR OSWRCH                         ; &3209 -> exec &0609  20 EE FF
    LDA #&2E                           ; &320C -> exec &060C  A9 2E
    LDY #&03                           ; &320E -> exec &060E  A0 03
print_name_separator:
    JSR OSWRCH                         ; &3210 -> exec &0610  20 EE FF
    DEY                                ; &3213 -> exec &0613  88
    BNE print_name_separator                       ; &3214 -> exec &0614  D0 FA
    LDA high_score_name_pointer_table,X                        ; &3216 -> exec &0616  BD EE 06
    STA coord_x                        ; &3219 -> exec &0619  85 70
    LDA high_score_name_pointer_table+1,X                        ; &321B -> exec &061B  BD EF 06
    STA coord_y                        ; &321E -> exec &061E  85 71
print_high_score_name:
    LDA (coord_x),Y                    ; &3220 -> exec &0620  B1 70
    JSR OSWRCH                         ; &3222 -> exec &0622  20 EE FF
    INY                                ; &3225 -> exec &0625  C8
    CMP #&0D                           ; &3226 -> exec &0626  C9 0D
    BNE print_high_score_name                       ; &3228 -> exec &0628  D0 F6
    LDA #&0A                           ; &322A -> exec &062A  A9 0A
    JSR OSWRCH                         ; &322C -> exec &062C  20 EE FF
    JSR OSWRCH                         ; &322F -> exec &062F  20 EE FF
    INC scratch14                      ; &3232 -> exec &0632  E6 14
    DEX                                ; &3234 -> exec &0634  CA
    DEX                                ; &3235 -> exec &0635  CA
    DEX                                ; &3236 -> exec &0636  CA
    BNE display_next_high_score                       ; &3237 -> exec &0637  D0 9D
    LDY #&00                           ; &3239 -> exec &0639  A0 00
print_play_again_message:
    LDA play_again_message,Y           ; &323B -> exec &063B  B9 00 26
    JSR OSWRCH                         ; &323E -> exec &063E  20 EE FF
    CMP #&0D                           ; &3241 -> exec &0641  C9 0D
    BEQ wait_for_space_after_scores_source ; &3243 -> exec &0643  F0 03
    INY                                ; &3245 -> exec &0645  C8
    BNE print_play_again_message                       ; &3246 -> exec &0646  D0 F3
wait_for_space_after_scores_source:
    LDX #KEY_SPACE                           ; &3248 -> exec &0648  A2 9D
    JSR test_key                       ; &324A -> exec &064A  20 F1 0E
    BEQ wait_for_space_after_scores_source ; &324D -> exec &064D  F0 F9
low_entry_after_relocation_source:
    JSR start_new_game                 ; &324F -> exec &064F  20 AE 0F
    JMP high_score_handler_exec        ; &3252 -> exec &0652  4C AA 04
print_bcd_byte_source:
    PHA                                ; &3255 -> exec &0655  48
    LSR A                              ; &3256 -> exec &0656  4A
    LSR A                              ; &3257 -> exec &0657  4A
    LSR A                              ; &3258 -> exec &0658  4A
    LSR A                              ; &3259 -> exec &0659  4A
    BNE print_nonblank_high_bcd_digit                       ; &325A -> exec &065A  D0 08
    LDY scratch33                      ; &325C -> exec &065C  A4 33
    BEQ print_nonblank_high_bcd_digit                       ; &325E -> exec &065E  F0 04
    LDA #&2E                           ; &3260 -> exec &0660  A9 2E
    BNE emit_high_bcd_character                       ; &3262 -> exec &0662  D0 06
print_nonblank_high_bcd_digit:
    LDY #&00                           ; &3264 -> exec &0664  A0 00
    STY scratch33                      ; &3266 -> exec &0666  84 33
    ORA #&30                           ; &3268 -> exec &0668  09 30
emit_high_bcd_character:
    JSR OSWRCH                         ; &326A -> exec &066A  20 EE FF
    PLA                                ; &326D -> exec &066D  68
    AND #&0F                           ; &326E -> exec &066E  29 0F
    BNE print_nonblank_low_bcd_digit                       ; &3270 -> exec &0670  D0 08
    LDY scratch33                      ; &3272 -> exec &0672  A4 33
    BEQ print_nonblank_low_bcd_digit                       ; &3274 -> exec &0674  F0 04
    LDA #&2E                           ; &3276 -> exec &0676  A9 2E
    BNE emit_low_bcd_character                       ; &3278 -> exec &0678  D0 06
print_nonblank_low_bcd_digit:
    LDY #&00                           ; &327A -> exec &067A  A0 00
    STY scratch33                      ; &327C -> exec &067C  84 33
    ORA #&30                           ; &327E -> exec &067E  09 30
emit_low_bcd_character:
    JMP OSWRCH                         ; &3280 -> exec &0680  4C EE FF

; =============================================================================
; SECOND-STAGE RELOCATION / HIGH-SCORE INITIALISATION BOOTSTRAP
; =============================================================================

; -----------------------------------------------------------------------------
; Second-stage bootstrap. Copy stored pages &3000-&32FF to execution pages &0400-&06FF, initialise the high-score
; tables/name buffers, then jump to low_entry_after_relocation at &064F.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; Bootstrap for the low-memory high-score system.  Besides copying the three pages, it initialises packed-BCD
; score records, 20-byte name buffers/pointers and the SOUND parameter workspace before entering &064F.
; -----------------------------------------------------------------------------
; Web-assembler boot entry.  The boot-disk builder automatically prefers a
; symbol named "start"; it must enter here at the original BASIC CALL &3283,
; not at the beginning of the relocated image (&0E00), which is data/routine
; material and is not a legal program entry point.  This second label emits no
; bytes, so the assembled image remains byte-for-byte identical.
start:
main_entry:
    ; Y=0 followed by DEY/BNE is the classic 256-byte loop: all three source pages
    ; (&3000,&3100,&3200) are copied in parallel to &0400,&0500,&0600.
    LDY #&00                           ; &3283  A0 00
copy_high_score_module_to_low_memory:
    LDA high_score_messages_source,Y   ; &3285  B9 00 30
    STA high_score_messages_exec,Y       ; &3288  99 00 04
    LDA high_score_source_page1,Y        ; &328B  B9 00 31
    STA high_score_exec_page1,Y          ; &328E  99 00 05
    LDA high_score_source_page2,Y        ; &3291  B9 00 32
    STA high_score_exec_page2,Y          ; &3294  99 00 06
    DEY                                ; &3297  88
    BNE copy_high_score_module_to_low_memory                       ; &3298  D0 EB
    LDY #&1E                           ; &329A  A0 1E
initialise_high_score_score_records:
    ; Seed 11 three-byte slots (offsets &1E..0) in one compact backwards loop.
    ; The value is 00:01:00 internally; because display appends a fixed trailing zero,
    ; the visible Top Eight therefore start at 1000 points with blank names.  Only candidate
    ; offset 0 and displayed offsets 3..24 participate in sorting; the pointer-table build
    ; immediately reuses the upper score-workspace bytes at &06EE onward.
    LDA #&00                           ; &329C  A9 00
    STA high_score_bcd_table,Y                        ; &329E  99 D0 06
    STA high_score_bcd_table+2,Y                        ; &32A1  99 D2 06
    LDA #INITIAL_HIGH_SCORE_BCD_MID      ; &32A4  A9 01
    STA high_score_bcd_table+1,Y                        ; &32A6  99 D1 06
    DEY                                ; &32A9  88
    DEY                                ; &32AA  88
    DEY                                ; &32AB  88
    BPL initialise_high_score_score_records                       ; &32AC  10 EE
    LDA #&0D                           ; &32AE  A9 0D
    LDY #&C9                           ; &32B0  A0 C9
fill_high_score_name_storage_with_cr:
    STA high_score_name_storage_base,Y   ; &32B2  99 0B 07
    DEY                                ; &32B5  88
    BNE fill_high_score_name_storage_with_cr                       ; &32B6  D0 FA
    LDX #&0C                           ; &32B8  A2 0C
    LDY #&1B                           ; &32BA  A0 1B
build_high_score_name_pointer_table:
    ; Ten pointer records are stored three bytes apart, parallel with score offsets.
    ; Pointers run through 20-byte CR-filled name slots in page &07.
    TXA                                ; &32BC  8A
    STA high_score_name_pointer_table,Y                        ; &32BD  99 EE 06
    CLC                                ; &32C0  18
    ADC #&14                           ; &32C1  69 14
    TAX                                ; &32C3  AA
    LDA #&07                           ; &32C4  A9 07
    STA high_score_name_pointer_table+1,Y                        ; &32C6  99 EF 06
    DEY                                ; &32C9  88
    DEY                                ; &32CA  88
    DEY                                ; &32CB  88
    BPL build_high_score_name_pointer_table                       ; &32CC  10 EE
    LDA #&00                           ; &32CE  A9 00
    LDY #&07                           ; &32D0  A0 07
clear_sound_parameter_block:
    STA sound_channel_lo,Y             ; &32D2  99 5D 00
    DEY                                ; &32D5  88
    BPL clear_sound_parameter_block                       ; &32D6  10 FA
    DEC sound_duration_lo              ; &32D8  C6 63
    DEC sound_duration_hi              ; &32DA  C6 64
    JMP low_entry_after_relocation     ; &32DC  4C 4F 06
; -----------------------------------------------------------------------------
; Unreached after main_entry jumps to relocated low-memory code.  These original bytes lie in Mode 2 screen RAM;
; no proven reachable instruction reads them as game data.
; -----------------------------------------------------------------------------
post_bootstrap_screen_seed_data:
    EQUB &C9,&25,&29,&3A,&F8,&20,&20,&0D,&18,&5B,&1C,&E7,&A4,&52,&50,&28 ; &32DF
    EQUB &35,&30,&2C,&31,&29,&F2,&4D,&28,&31,&38,&30,&29,&3A,&47,&25,&3D ; &32EF
    EQUB &31,&3A,&F8,&0D,&18,&60,&1D,&E7,&A4,&48,&28,&34,&29,&5A,&25,&3D ; &32FF
    EQUB &30,&3A,&F2,&4D,&28,&31,&38,&31,&29,&3A,&47,&25,&3D,&39,&3A,&F8 ; &330F
    EQUB &0D                                                             ; &331F
; -----------------------------------------------------------------------------
; Six x &20-byte Mode 2 score cells.  add_score_bcd_and_redraw overwrites these with digit graphics during play.
; -----------------------------------------------------------------------------
score_screen_digits_initial_bytes:
    EQUB &18,&65,&21,&E7,&AC,&A4,&48,&28,&31,&37,&29,&5A,&25,&3D,&31,&3A ; &3320
    EQUB &F2,&4D,&28,&31,&38,&31,&29,&3A,&47,&25,&3D,&39,&3A,&F8,&20,&20 ; &3330
    EQUB &0D,&18,&6A,&22,&E7,&AC,&A4,&48,&28,&31,&39,&29,&84,&AC,&A4,&48 ; &3340
    EQUB &28,&31,&32,&29,&F2,&4D,&28,&31,&38,&35,&29,&3A,&47,&25,&3D,&31 ; &3350
    EQUB &3A,&F8,&0D,&18,&6F,&10,&5A,&25,&3D,&32,&3A,&F2,&4D,&28,&31,&38 ; &3360
    EQUB &31,&29,&0D,&18,&74,&27,&E7,&AC,&A4,&48,&28,&31,&31,&29,&80,&A4 ; &3370
    EQUB &53,&28,&31,&31,&29,&3D,&31,&F2,&4D,&28,&31,&38,&36,&29,&3A,&F2 ; &3380
    EQUB &4F,&53,&53,&28,&31,&31,&2C,&30,&29,&00,&00,&00,&00,&00,&00,&00 ; &3390
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &33A0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&11,&11,&11,&11,&11 ; &33B0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &33C0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &33D0
; -----------------------------------------------------------------------------
; One &20-byte Mode 2 score cell.  start_life copies digit 0 here, providing the displayed trailing zero.
; -----------------------------------------------------------------------------
score_fixed_trailing_zero_screen_cell:
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &33E0
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00 ; &33F0

; End of exact runtime image (&0E00-&33FF).
; Stage 6 additionally proves the ordinary-pellet tile/count/map, documents the screen-RAM pellet
; occlusion-cache design, decodes the Mode-2 bitplane samplers, pins down the 200/400/800/1600
; ghost-score ladder and 1000-point initial Top-Eight seed, maps the sound/envelope call sites,
; adds exact AI pseudocode/probe geometry, a renderer-true sprite atlas, and stronger legacy-layout evidence.
; Raw/unreferenced regions remain byte-exact rather than being promoted to code without reachability proof.
