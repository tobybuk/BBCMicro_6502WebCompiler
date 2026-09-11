; STAGE 13 - FINAL ARCHIVAL / BYTE-EXACT DOCUMENTED SOURCE
; @default-origin &0E00
;
; ARCHIVAL INVARIANT
; ------------------
; The canonical &0E00 build MUST emit the exact 10,112 bytes of the original
; Acornsoft $.RAIDOBJ file.  All Stage 13 work is non-emitting documentation,
; labels/aliases, or symbolic expressions which encode to the original bytes.
; No optimisation, cleanup, dead-byte removal, algorithm rewrite or data
; normalisation is permitted in this file.  Even overwritten build/source
; residue is retained at its original physical position.
;
; Relocation remains an assembly-time option for the persistent core, but the
; archival reference build is always Origin=&0E00.  Byte-exact verification is
; against that canonical build.
;
; Based on the byte-exact, relocation-safe Stage 11 baseline.
;
; Stage 12 concentrates on the last large opaque subsystem: the terrain language.
; It preserves every original byte while making the packed command/delta streams
; readable and editable:
;   * command bit 6 is proven to mean "suppress fixed scenery on this flat run";
;   * every terrain command is decoded in-place with run length, signed delta,
;     section-local columns, feature class and scenery eligibility;
;   * exact upper-section and lower-stream phase labels are added;
;   * the cavern/maze lower-stream consumption and discarded tail samples are
;     documented precisely;
;   * the final city is resolved as three identical 479-column blocks, each with
;     one final dustbin at the same block-relative position;
;   * section command budgets 0..4 are derived from labels rather than magic counts;
;   * scenery spawning/stamping is documented as a distinct pipeline;
;   * recovered original BASIC/assembler source lines are exported separately.
;
; No game logic or payload bytes are changed.
; Based on the verified Stage 10 relocation-ready source.
;
; Stage 11 is a semantic/documentation pass.  It does not alter game bytes.
; In particular it:
;   * resolves the object-state bitfield used by the shared object arrays;
;   * documents the exact MODE-2 screen-address calculation and sprite layout;
;   * documents the two 24-bit RNGs and the period observed from the game's seed;
;   * splits the fixed scenery script at the six exact section boundaries;
;   * records the exact per-section scenery counts and final-target positions;
;   * documents Hall-of-Fame scratch/display/sentinel entries precisely;
;   * recovers additional original author symbols from surviving assembler text;
;   * marks genuinely dead/unreferenced bytes instead of inventing meanings;
;   * completes the archival pass without changing a single canonical byte;
;   * keeps all relocatable core references label-relative.
; Based on the compile-safe, byte-exact Stage 9.1 baseline.
;
; Stage 10 makes the persistent game core genuinely relocatable at assembly time:
;   * the first segment has NO ORG directive, so the web assembler Origin field owns it;
;   * &0E00 remains the default through @default-origin, preserving the original build;
;   * persistent internal addresses are labels/label expressions, not hard-coded &xxxx;
;   * low/high address bytes use the assembler's unary <label / >label operators;
;   * the transient copied controller image remains at &3000 and startup remains &3400;
;   * the original DFS loader remains a separate archival segment at &4500.
;
; PRACTICAL RELOCATION RULE: use a PAGE-ALIGNED core origin.  With the original
; MODE-2 screen beginning at &3000 and low controller/workspace occupying &0400-&07FF,
; the useful conservative window is approximately &0800..&0E00.  The original &0E00
; remains the canonical byte-exact build.  Moving the core above &0E00 would push
; persistent sprite/data bytes into MODE-2 screen RAM and is not safe without a larger
; memory-layout redesign.
;
; This stage also restores more of Jonathan Griffiths' surviving original labels and
; labels the internal HUD/workspace buffers that were previously represented by raw
; addresses.
;
; VERIFICATION RULE: every source change in this stage is checked by independently
; re-encoding the emitted 6502 and comparing it to the original RAIDOBJ.  The intended
; archival build is therefore byte-for-byte identical to Acornsoft's original payload.
;
; IMPORTANT: data bytes that merely happen to equal a zero-page address are left as
; numeric bytes.  Earlier annotation passes accidentally turned ASCII/source-residue
; bytes such as &41 into names such as bullet_cooldown.  Stage 9 never performs blind
; numeric replacement inside data blocks.

; Rocket Raid (Acornsoft, 1982) - Stage 10 relocation-ready symbolic reverse-engineering baseline
; Source image: Disc001-RocketRaid.ssd
;
; DFS file $.RAIDOBJ
;   load address: &1E00
;   exec address: &4500
;   length:       &2780 (10112 bytes)
;
; -----------------------------------------------------------------------------
; Generated boot-disc BASIC: original Rocket Raid instruction screen
; -----------------------------------------------------------------------------
; The web assembler reads these @basic directives and emits them into the BASIC
; bootstrap before the relocation/entry transfer.  They deliberately reproduce
; the instruction display from the original $.RAID2 program, but do NOT load
; RAIDOBJ again and do NOT CALL &3400 themselves: the generated boot mover owns
; relocation and transfers control to the selected `start` entry at &3400.
;
; The machine code at &0664 then waits for SPACE or joystick fire exactly as the
; original game did, so the displayed instruction remains visible while waiting.
;
; Original RAID2 source used PROCs/DATA to lay this out.  These direct BASIC
; commands generate the same Mode 7 screen without requiring support procedures
; in the bootstrap.  Keeping them here (rather than hard-coding UI in the boot
; creator) makes the per-game startup presentation part of the game's source.
;
; @basic MODE 7
; @basic *TAPE
; *TAPE is required: the Hall-of-Fame OSWORD 0 input path fails if DFS remains active.
; @basic VDU 23;10,32,0;0;0;
; @basic VDU 31,0,0,129,157,131,141,31,9,0
; @basic PRINT "Acornsoft Rocket Raid"
; @basic VDU 31,0,1,129,157,131,141,31,9,1
; @basic PRINT "Acornsoft Rocket Raid"
; @basic VDU 31,11,2,141,134
; @basic PRINT "Instructions  "
; @basic VDU 31,11,3,141,134
; @basic PRINT "Instructions  "
; @basic VDU 31,6,4
; @basic PRINT "Keys:"
; @basic VDU 31,17,5
; @basic PRINT "A - Up"
; @basic VDU 31,17,6
; @basic PRINT "Z - Down"
; @basic VDU 31,9,7
; @basic PRINT "SPACE BAR - Back"
; @basic VDU 31,13,8
; @basic PRINT "SHIFT - Forwards"
; @basic VDU 31,15,9
; @basic PRINT "TAB - Bomb"
; @basic VDU 31,12,10
; @basic PRINT "RETURN - Fire"
; @basic VDU 31,12,11
; @basic PRINT "ESCAPE - Restart"
; @basic VDU 31,7,13,130
; @basic PRINT "Use Joystick with"
; @basic VDU 131
; @basic PRINT "EITHER"
; @basic VDU 31,3,14,130
; @basic PRINT "Fire Button"
; @basic VDU 131
; @basic PRINT "OR"
; @basic VDU 130
; @basic PRINT "Shift and Return"
; @basic VDU 31,11,15,130
; @basic PRINT "to Bomb and Fire"
; @basic VDU 31,7,17,133
; @basic PRINT "Use 'S' and 'Q' to turn"
; @basic VDU 31,11,18,133
; @basic PRINT "sound on and off"
; @basic VDU 31,4,20,135
; @basic PRINT "Press SPACE BAR or Fire Button"
; @basic VDU 31,9,21,135
; @basic PRINT "on Joystick to Start"
; @basic VDU 31,4,23,134
; @basic PRINT " Copyright (C) Acornsoft 1982 "
;
; Runtime relocation performed by entry code at &4500:
;   &1E00-&44FF -> &0E00-&34FF (exactly &2700 bytes)
;   &4550-&457F -> &03B0-&03DF (48-byte OSFILE control block / workspace data)
;
; The main game is subsequently entered by BASIC with CALL &3400.
;
;
; IMPORTANT ENTRY-POINT REQUIREMENT
; ---------------------------------
; The one-time game startup entry is &3400, labelled "start" below.
; When using the BBC 6502 Web Assembler's Save boot disk... feature, select:
;
;       Entry point: start
;
; DO NOT enter the generated disk at &0E00.  &0E00 is the per-game/per-life
; engine entry reached later by JSR from the controller copied to &0400-&06FF.
; Calling &0E00 directly skips essential startup at &3400, including:
;   - copying &3000-&32FF to &0400-&06FF;
;   - constructing low-memory controller tables;
;   - defining the six sound envelopes with OSWORD 8;
;   - setting initial control/state bytes before jumping to &0664.
;
; The original Acornsoft BASIC loader uses PAGE=&5000 and CALL &3400 because
; it keeps BASIC resident while the game is running.  The web assembler boot
; bootstrap instead displays the @basic screen above *before* relocation, then
; its video-RAM mover relocates the image and JMPs to `start` at &3400.  BASIC
; therefore need not survive the move, while the original instruction screen
; remains on screen for the game's own SPACE/fire wait loop.
;
; Game-over return chain when started correctly:
;   &0664...                 copied controller/start loop
;   JSR &0E00               enters one game/life and leaves return address
;   &0E00  TSX / STX &0E    saves that caller stack pointer
;   &178C  LDX &0E / TXS    restores it after ship destruction
;   &178F  DEC &3D          decrement lives
;   &1791  BMI &1796        no lives remain
;   &1793  JMP &0E09        continue/restart with lives remaining
;   &1796  RTS              returns to the controller, NOT BASIC
;
; Entering at &0E00 from the generated boot disk leaves no valid JSR return
; address for that final RTS and is the reason the incorrect build eventually
; falls into BASIC with "Bad program".
;
; This Stage 1 file deliberately preserves the runtime payload byte-for-byte.
; Known code is annotated below; the large payload remains EQUB data until each
; region is classified as code, tables, graphics or workspace.


; -----------------------------------------------------------------------------
; Stage 2: resolved symbols / original-source archaeology
; -----------------------------------------------------------------------------
; A useful accident of the original build has preserved fragments of the BASIC
; assembler source inside the saved object image.  Those fragments expose a
; number of the author's original symbol names.  The names below are therefore
; not guesses unless explicitly marked as inferred.
;
; Original names recovered from the embedded assembler text:
;   game             = &0E00       main game entry
;   checkhi_score    = &0502       copied high-score controller
;   inkey            = &1C21       OSBYTE &81 keyboard wrapper
;   adval            = &1BCD       analogue/joystick read helper
;   soundflag        = &75
;   joyflag          = &6E
;   temp             = &1B
;   stringptr        = &00/&01     scratch pointer in UI/high-score code
;   ladder           = &06D0       30-byte high-score ladder (10 x 3-byte scores)
;   string           = &06EE       30-byte table used by score/name display
;   name             = &070C       200-byte high-score name store (10 x 20)
;   tempsc           = &07D4       3-byte temporary score
;   microsoftstring  = &069B       length-prefixed string printer
;   atomstring       = &06B1       CR-terminated string printer
;   fourdots         = &06C2       prints four full stops
;
; Further symbols now resolved from behaviour/data flow:
;   lives            = &3D         initialised to 2 => current ship + 2 spares
;   score_lo         = &3E         three-byte score, least-significant byte
;   score_mid        = &3F
;   score_hi         = &40
;   stage_bcd        = &76         BCD stage/raid counter; incremented in SED
;   startup_flag     = &7B         set once by &3400 before controller entry
;
; BBC key numbers used by the original game (OSBYTE &81 / INKEY negative codes):
;   Q      = &EF (-17)     sound off
;   S      = &AE (-82)     sound on
;   A      = &BE (-66)     up
;   Z      = &9E (-98)     down
;   SHIFT  = &FF (-1)      forwards
;   SPACE  = &9D (-99)     back / keyboard-start selection
;   TAB    = &9F (-97)     bomb
;   RETURN = &B6 (-74)     fire
;
; The &3000-&32FF block is not executed at those addresses during play. &3400
; copies it to &0400-&06FF.  Consequently labels in that block have two useful
; addresses: their image address and their runtime address, offset by -&2C00.
; Examples: &3264 -> &0664 (start/control loop), &329B -> &069B, etc.
;
; High-score workspace layout recovered from the original source:
;   &06D0 ladder   30 bytes
;   &06EE string   30 bytes
;   &070C name    200 bytes
;   &07D4 tempsc    3 bytes
;
; The preserved source text around &1D9D-&24AD is build-time residue, not live
; game code.  It is extremely valuable for reconstruction but should eventually
; be separated from genuine runtime code/data in the fully annotated source.
;


; =============================================================================
; STAGE 4 - DEEP SOURCE RESOLUTION
; =============================================================================
; This version deliberately moves beyond a commented hex dump.  Confirmed code
; regions are now expressed as 6502 mnemonics and carry address-level labels.
; The untouched data/graphics regions remain EQUB until their record formats are
; established.  This avoids the common reverse-engineering mistake of turning
; sprite/table bytes into plausible-looking but false instructions.
;
; Search for `MOD:` for safe experimentation points and `INFERRED:` where a name
; is behavioural rather than recovered from the author's surviving source text.
;
; Object workspace is structure-of-arrays, 20 slots:
;   &2B50+slot  type
;   &2B64+slot  state/flags/animation
;   &2B78+slot  X / active coordinate
;   &2B8C+slot  Y
; Slot 0 is the player.  Projectile/enemy routines reuse later slots.
;
; =============================================================================
; STAGE 10 RELOCATION CONFIGURATION
; =============================================================================
; Only these fixed layout anchors should normally contain absolute RAM addresses.
; The persistent core itself begins at the assembler Origin field (default &0E00).
;
; CONTROLLER_RUNTIME_BASE:
;   Low-memory copy target for the three-page &3000 controller image.  This area also
;   contains Hall-of-Fame state/workspace through just below &0800.
;
; CONTROLLER_IMAGE_ORIGIN / STARTUP_ORIGIN:
;   Deliberately remain in MODE-2 screen RAM.  They are used only before MODE 2 takes
;   ownership of that RAM, so they are transient by design.
;
; ORIGINAL_DFS_LOADER_ORIGIN:
;   Archival entry from $.RAIDOBJ.  Modern generated boot disks enter `start` directly
;   and do not need to execute this loader.
;
CONTROLLER_RUNTIME_BASE    = &0400
CONTROLLER_IMAGE_ORIGIN    = &3000
STARTUP_ORIGIN             = CONTROLLER_IMAGE_ORIGIN + &0400
ORIGINAL_DFS_LOADER_ORIGIN = &4500
ORIGINAL_RUNTIME_ORIGIN    = &0E00      ; archival $.RAIDOBJ loader destination only
ORIGINAL_DFS_FILE_LOAD     = &1E00
ORIGINAL_DFS_FILE_END      = ORIGINAL_DFS_FILE_LOAD + &2700 ; exclusive end of original source copy
LOW_WORKSPACE_DEST         = &03B0
LOW_WORKSPACE_BYTES        = &30

CONTROLLER_RELOCATION_DELTA = CONTROLLER_RUNTIME_BASE - CONTROLLER_IMAGE_ORIGIN
CONTROLLER_RUNTIME_PAGE0    = CONTROLLER_RUNTIME_BASE
CONTROLLER_RUNTIME_PAGE1    = CONTROLLER_RUNTIME_BASE + &0100
CONTROLLER_RUNTIME_PAGE2    = CONTROLLER_RUNTIME_BASE + &0200

; =============================================================================
; NAMED CONSTANTS - Stage 8/10
; =============================================================================
; The aim is the same as the mature Frak source: code should state WHAT a value
; means rather than forcing the reader to remember that (for example) &4B means
; the right-edge spawn X coordinate or &0F means OSBYTE Flush Buffer.
;
; MOS / hardware entry points
osrdch                    = &FFE0
oswrch                    = &FFEE
osword                    = &FFF1
osbyte                    = &FFF4
crtc_address              = &FE00
crtc_data                 = &FE01
video_ula_palette         = &FE21
sysvia_ifr                = &FE4D
sysvia_ier                = &FE4E

; MOS call numbers
OSBYTE_CURSOR_KEYS        = &04
OSBYTE_FLUSH_BUFFER       = &0F
OSBYTE_ACK_ESCAPE         = &7E
OSBYTE_ADVAL              = &80
OSBYTE_INKEY              = &81
OSBYTE_SELECT_TAPE_FS    = &8C
OSWORD_READ_LINE          = &00
OSWORD_READ_SYSTEM_CLOCK  = &01
OSWORD_SOUND              = &07
OSWORD_DEFINE_ENVELOPE    = &08

; VDU / CRTC / MODE 2
VDU_SET_MODE              = &16
SCREEN_MODE_2             = &02
ASCII_CR                  = &0D
SCREEN_BASE_HI            = &30
SCREEN_WRAP_HIGH_DELTA    = &50
MODE2_SCANLINES_PER_CHAR  = &08
MODE2_SCANLINE_MASK       = &07
MODE2_SCANLINE_CLEAR_MASK = &F8
MODE2_CHAR_ROW_STRIDE_LO  = &80       ; low/high of &0280
MODE2_CHAR_ROW_STRIDE_HI  = &02
MODE2_CHAR_ROW_STRIDE     = &0280      ; 80 MODE-2 byte-columns x 8 scanlines
SCROLL_STEP_BYTES         = &08
LANDSCAPE_COPY_OFFSET_LO  = &78       ; scroll base + &0278
LANDSCAPE_COPY_OFFSET_HI  = &02
LANDSCAPE_COPY_OFFSET     = &0278
CRTC_CURSOR_START_REG     = &0A
CRTC_SCREEN_START_HI_REG  = &0C
CRTC_SCREEN_START_LO_REG  = &0D
CRTC_CURSOR_DISABLED      = &20
CRTC_INTERLACE_DELAY_REG  = &08
CRTC_INTERLACE_NORMAL     = &00
VSYNC_INTERRUPT_FLAG      = &02

; BBC logical/physical colour values
COLOUR_BLACK              = 0
COLOUR_RED                = 1
COLOUR_GREEN              = 2
COLOUR_YELLOW             = 3
COLOUR_BLUE               = 4
COLOUR_MAGENTA            = 5
COLOUR_CYAN               = 6
COLOUR_WHITE              = 7
LOGICAL_TERRAIN_COLOUR    = 4
LOGICAL_COLOUR_LAST       = 15

; Player / lives / movement
STARTING_SPARES           = 2         ; MOD: total ships = this + current ship
PLAYER_START_X            = &06
PLAYER_START_Y            = &BB
PLAYER_Y_MIN              = &13       ; MOD: smaller lets the ship move further toward the upper limit
PLAYER_Y_MAX              = &DD       ; MOD: larger lets the ship move further toward the lower limit
PLAYER_X_MIN              = &06       ; MOD: rearward movement limit
PLAYER_X_MAX              = &1E       ; MOD: forward movement limit
PLAYER_VERTICAL_STEP      = 2         ; MOD: player vertical speed per accepted input update
PLAYER_HORIZONTAL_STEP    = 1         ; MOD: player horizontal speed per accepted input update
LIFE_ICONS_MAX_DISPLAYED  = 2

; Score / bonus life (packed BCD)
EXTRA_LIFE_SCORE_HI       = &01       ; MOD: 15,000
EXTRA_LIFE_SCORE_MID      = &50
BCD_HIGH_NIBBLE_MASK      = &F0
BCD_LOW_NIBBLE_MASK       = &0F
SCORE_LEADING_BLANK_PATTERN = &A0

; Object score table values (packed BCD, low byte + middle byte).
; MOD: changing these constants changes the award for the named target while
; preserving the table structure.  Values are packed BCD, not binary integers.
GROUND_MISSILE_SCORE_LO  = &50       ; 50
GROUND_MISSILE_SCORE_MID = &00
FUEL_TANK_SCORE_LO       = &50       ; 150
FUEL_TANK_SCORE_MID      = &01
FINAL_BASE_SCORE_LO      = &00       ; 800
FINAL_BASE_SCORE_MID     = &08
PHIZZER_SCORE_LO         = &00       ; 100
PHIZZER_SCORE_MID        = &01
LAUNCHED_MISSILE_SCORE_LO  = &80     ; 80
LAUNCHED_MISSILE_SCORE_MID = &00
MYSTERY_SCORE_200_LO     = &00
MYSTERY_SCORE_200_MID    = &02
MYSTERY_SCORE_350_LO     = &50
MYSTERY_SCORE_350_MID    = &03
MYSTERY_SCORE_450_LO     = &50
MYSTERY_SCORE_450_MID    = &04
MYSTERY_SCORE_600_LO     = &00
MYSTERY_SCORE_600_MID    = &06

; Projectiles
BOMB_COOLDOWN_FRAMES      = 6         ; MOD: larger = slower bomb repeat
BULLET_COOLDOWN_FRAMES    = 1         ; MOD: larger = slower bullet repeat
BOMB_SPAWN_X_OFFSET       = 3
BOMB_SPAWN_Y_GAP          = 1
BOMB_INITIAL_VELOCITY     = &20       ; MOD: initial bomb trajectory accumulator/velocity
BOMB_DESPAWN_Y            = &DD
BULLET_SPAWN_Y_OFFSET     = 4
BULLET_DESPAWN_X          = &46
BULLET_X_STEP             = 2         ; MOD: bullet horizontal speed
BULLET_STATE_INITIAL      = &A0       ; active + custom renderer
PROJECTILE_HIT_X_TOLERANCE = &10
PROJECTILE_HIT_Y_TOLERANCE = &18
COLLISION_SOLID_BITS      = &C0

; Object slots
OBJECT_SLOT_COUNT         = 20
OBJECT_LAST_SLOT          = 19
PLAYER_SLOT               = 0
BOMB_FIRST_SLOT           = 1
BOMB_SLOT_COUNT           = 2
BULLET_FIRST_SLOT         = 3
BULLET_SLOT_COUNT         = 4
DYNAMIC_HAZARD_SLOT_0     = 7
DYNAMIC_HAZARD_SLOT_1     = 8
SCENERY_FIRST_SLOT        = 9
SCENERY_LAST_SLOT         = 19
LANDSCAPE_OBJECT_ENTRY_X  = &4F
; Object state byte (&2B64+slot) - Stage 11 semantics.
; Bits 0..4 are a Phizzer path/animation index.  Bit 7 means the object is
; active/drawable.  Bit 6 temporarily suppresses the object for this frame;
; the missile/Phizzer/meteorite update code uses it to time-slice paired slots.
; Bit 5 selects the projectile's bespoke renderer/eraser path (bullets use A0).
OBJECT_STATE_PATH_INDEX_MASK = &1F
OBJECT_STATE_CUSTOM_RENDER   = &20
OBJECT_STATE_FRAME_SUPPRESSED = &40
OBJECT_STATE_ACTIVE          = &80
OBJECT_STATE_ACTIVE_SUPPRESSED = &C0       ; active + frame-suppressed

; Compatibility aliases for earlier notes; live code below uses semantic names.
OBJECT_STATE_PATH_MASK    = OBJECT_STATE_PATH_INDEX_MASK
OBJECT_STATE_BIT5         = OBJECT_STATE_CUSTOM_RENDER
OBJECT_STATE_BIT6         = OBJECT_STATE_FRAME_SUPPRESSED
OBJECT_STATE_BIT7         = OBJECT_STATE_ACTIVE
OBJECT_STATE_INACTIVE     = OBJECT_STATE_ACTIVE
COLLISION_LOWEST_OBJECT_SLOT = 7

; Joystick thresholds / channels
JOY_BUTTON_CHANNEL        = 0
JOY_HORIZONTAL_CHANNEL    = 1
JOY_VERTICAL_CHANNEL      = 2
JOY_BUTTON_MASK           = 1
JOY_LOW_THRESHOLD         = &32
JOY_HIGH_THRESHOLD        = &CE

; Dynamic hazards
MISSILE_LAUNCH_X_THRESHOLD = &4C     ; MOD: latest X at which a ground missile may launch
HAZARD_ENTRY_X            = &4B
HAZARD_RANDOM_MASK        = &07       ; MOD: spawn chance 1/(mask+1) for 2^n-1 masks
PHIZZER_RESPAWN_FRAMES    = &28       ; MOD: delay between Phizzer spawn attempts
PHIZZER_PATH_MASK         = &1F
METEORITE_Y_RANDOM_MASK   = &7F
METEORITE_Y_BASE          = &64
LAUNCHED_MISSILE_Y_STEP   = 3         ; MOD: launched-missile vertical speed on its selected update
METEORITE_X_STEP          = 2         ; MOD: meteorite horizontal speed on its selected update

; Terrain bytecode / rolling profiles
TERRAIN_CMD_END_BIT         = &80
TERRAIN_CMD_END_MARKER      = &FF       ; shipped terminator byte; remaining bits are don't-care
TERRAIN_CMD_NO_SCENERY_BIT  = &40       ; original data only sets this on delta=0 runs
TERRAIN_CMD_RUN_MASK        = &1F
; Compatibility name from earlier reverse-engineering passes.  The DEC in the
; decoder is an implementation trick: zero becomes &FF so scenery gating fails.
TERRAIN_CMD_DELTA_DEC_BIT   = TERRAIN_CMD_NO_SCENERY_BIT
TERRAIN_JITTER_MASK       = &03       ; MOD: controls roughness magnitude on non-zero slopes
; MOD: To suppress fixed targets on an otherwise flat UPPER command, set
; TERRAIN_CMD_NO_SCENERY_BIT in that command byte.  To permit targets, clear it.
; Do not use bit 6 as a general slope flag: the original only uses it with delta=0.
UPPER_EDGE_INITIAL        = &28
LOWER_EDGE_FLAT           = &E0
PROFILE_NEWEST_INDEX      = &20
LOWER_TERRAIN_ENABLED     = &00
LOWER_TERRAIN_DISABLED    = &FF
SECTION_ENVELOPE_DEFAULT   = 0
SECTION_ENVELOPE_CAVERN    = 1
SECTION_ENVELOPE_METEOR    = 2
SECTION0_COMMAND_BUDGET   = 75        ; documentation/compatibility value
SECTION1_COMMAND_BUDGET   = 60
SECTION2_COMMAND_BUDGET   = 72
SECTION3_COMMAND_BUDGET   = 96
SECTION4_COMMAND_BUDGET   = 72
SECTION5_TERMINATOR_BUDGET = &80       ; deliberately larger than the 110 real commands
SECTION5_COMMAND_BUDGET   = SECTION5_TERMINATOR_BUDGET

; Fuel
FUEL_MAX_HI               = &02
FUEL_MAX_LO               = &40
FUEL_TANK_REFILL          = &40       ; MOD: fuel added per destroyed tank
FUEL_TICK_FRAMES          = 3         ; MOD: larger = slower fuel consumption
FUEL_QUANTUM              = &08
FUEL_REFILL_QUANTA        = 8
FUEL_GAUGE_FILL_PATTERN   = &2D
FUEL_GAUGE_BORDER_PATTERN = &3F
FUEL_GAUGE_EDGE_PATTERN   = &15

; Sound / envelope records
SOUND_BLOCK_BYTES         = 8
ENVELOPE_RECORD_BYTES     = 14
ENVELOPE_RECORD_COUNT     = 6
noenv                     = ENVELOPE_RECORD_COUNT ; ORIGINAL author symbol recovered from startup source

; Timing
PLAYER_DEATH_FLASH_FRAMES = &32      ; MOD: explosion/palette-flash duration
EXTRA_LIFE_BEEP_COUNT     = 5         ; MOD: number of extra-life beeps
EXTRA_LIFE_BEEP_FIRST_DELAY = 1
EXTRA_LIFE_BEEP_PERIOD    = &1E       ; MOD: spacing between extra-life beeps
RAID_COMPLETE_DELAY_TICKS = &64       ; MOD: delay before/after Well Done message

; Hall of Fame
HIGH_SCORE_ENTRIES        = 10
HIGH_SCORE_BYTES_PER_ENTRY = 3
HIGH_SCORE_NAME_BYTES     = 20
HIGH_SCORE_LADDER_BYTES   = 30
HIGH_SCORE_NAMES_BYTES    = 200
ASCII_ZERO                = &30
HIGH_SCORE_INPUT_MAX      = 19        ; MOD: maximum Hall-of-Fame name length
HIGH_SCORE_INPUT_MIN_ASCII = &20
HIGH_SCORE_INPUT_MAX_ASCII = &7E
HIGH_SCORE_SORT_FIRST_OFFSET = HIGH_SCORE_BYTES_PER_ENTRY
HIGH_SCORE_SORT_STOP_OFFSET  = &1B       ; allocated but never compared: unused guard record at offset 27

; Loader / relocation

; General state / source-format constants
BYTE_FALSE                 = &00
BYTE_TRUE                  = &FF
ASCII_LF                   = &0A
ASCII_SPACE                = &20
ASCII_DOT                  = &2E
BCD_ONE                    = &01
RNG_INITIAL_SEED           = &57
RNG_STATE_BYTE_COUNT       = 6
SECTION_COUNT              = 6
PALETTE_ENTRY_COUNT        = 16
DRAWABLE_X_MIN_COORD       = 1
SECTION_SPAWN_INITIAL_DELAY = &14
ORIGINAL_CORE_SIZE         = &2200     ; original &0E00-&2FFF persistent segment
CONTROLLER_IMAGE_BYTES     = &0300     ; three pages copied from transient image
CONTROLLER_PAGE_BYTES      = 256       ; one complete 6502 page
CONTROLLER_PAGE1_OFFSET    = CONTROLLER_PAGE_BYTES
CONTROLLER_PAGE2_OFFSET    = CONTROLLER_PAGE_BYTES*2
PLAYER_ERASE_SCREEN_PAGE_OFFSET_HI = &05
SCROLL_GUARD_LAST_Y        = &07
TERRAIN_PREFILL_EDGE_TOGGLE = &01
LIFE_ICON_SPACING_BYTES    = &08
LANDSCAPE_MASK_LAST_INDEX  = &FF
BYTE_INVERT_MASK           = &FF
INKEY_POLL_Y               = &FF       ; OSBYTE &81 negative-key polling convention

; Additional named values recovered during the Stage 9 literal sweep
BONUS_LIFE_NOT_AWARDED    = &00
BONUS_LIFE_BEEPER_ACTIVE  = &FF
BONUS_LIFE_AWARDED_DONE   = &7F
STARTUP_IER_VALUE         = &01
KEYBOARD_INPUT_BUFFER     = &01
DEFAULT_NAME_LAST_INDEX   = 9          ; "Acornsoft" + CR occupies 10 bytes
SYSTEM_CLOCK_BLOCK_LAST_INDEX = 4      ; OSWORD 1 workspace is five bytes
CURSOR_KEYS_RETURN_ASCII  = 1          ; *FX 4,1 behaviour
FOUR_DOTS_COUNT           = 4
SMC_ABSOLUTE_PLACEHOLDER   = &FFFF     ; 16-bit operand overwritten before use
SMC_PAGE_PLACEHOLDER       = &FF00     ; high byte overwritten before store executes

; Terrain stream addresses are taken directly from labels with <label / >label.

; Initial screen / scroll state
SCROLL_INITIAL_LO          = &80
SCROLL_INITIAL_HI          = &2D
SCREEN_PAGE_OFFSET_HI      = &05

; Collision-mask byte patterns.  These are the MODE-2 bit patterns written into
; the 256-byte landscape collision strip by build_landscape_collision_mask.
LANDSCAPE_MASK_EMPTY       = &00
LANDSCAPE_MASK_SOLID       = &30
LANDSCAPE_MASK_EDGE_BOTH   = &0C
LANDSCAPE_MASK_EDGE_A      = &08
LANDSCAPE_MASK_EDGE_B      = &04
LOWER_PROFILE_LAST_SOLID   = &E0
LOWER_PROFILE_OFFSCREEN    = &E1
PROJECTILE_XOR_PATTERN     = &0F
RNG_FEEDBACK_MASK          = &48
RNG_FEEDBACK_BIAS          = &38
HUD_UPPER_X_START          = &80
HUD_LOWER_X_START          = &B0
HUD_UPPER_SCROLL_OFFSET_LO = &08
HUD_UPPER_SCROLL_OFFSET_HI = &00
HUD_LOWER_SCROLL_OFFSET_LO = &F8
HUD_LOWER_SCROLL_OFFSET_HI = &01
FUEL_GAUGE_FILL_SCANLINES  = 6
FUEL_GAUGE_BORDER_LAST_Y   = 7
FUEL_GAUGE_CLEAR_SCANLINES = 6
FUEL_GAUGE_BODY_OFFSET_LO  = &50
FUEL_GAUGE_MARKER_OFFSET_LO = &48
FUEL_GAUGE_PAGE_OFFSET_HI  = &07
FUEL_GAUGE_BODY_OFFSET     = &0750
FUEL_GAUGE_MARKER_OFFSET   = &0748

; Addresses of operand bytes deliberately changed by self-modifying graphics code.

; Hall-of-Fame / copied-controller constants
HIGH_SCORE_DEFAULT_MID     = &10
HIGH_SCORE_LAST_OFFSET     = (HIGH_SCORE_ENTRIES-1)*HIGH_SCORE_BYTES_PER_ENTRY
HALL_DISPLAY_START_OFFSET  = &18       ; display offsets &18,&15,...,&03 (8 rows)
HALL_RANK_FIRST            = 1
BCD_LEADING_DOTS_FLAG      = &FF

; Low-memory Hall-of-Fame workspace.  These relationships come directly from the
; recovered original source: ladder (10x3), string (10x3), name (10x20), tempsc.
; Only CONTROLLER_RUNTIME_BASE is fixed; the rest follows symbolically.
ladder                     = CONTROLLER_RUNTIME_BASE + &02D0
score_string_table         = ladder + HIGH_SCORE_LADDER_BYTES
highscore_names            = score_string_table + HIGH_SCORE_LADDER_BYTES
tempsc                     = highscore_names + HIGH_SCORE_NAMES_BYTES
HIGH_SCORE_OSWORD_BLOCK    = tempsc + &0C
HIGH_SCORE_INPUT_BUFFER    = HIGH_SCORE_OSWORD_BLOCK + 5
life_icon_draw_buffer      = lives_buffer_base + MODE2_SCANLINES_PER_CHAR
LIVES_BUFFER_CLEAR_LAST    = landscape_mask - lives_buffer_base

; Original author aliases recovered from the embedded assembler text.
string                     = score_string_table
name                       = highscore_names

; Runtime aliases for routines/data emitted in the transient &3000 controller image.
; They are derived from image labels rather than frozen &04xx/&06xx addresses, so the
; controller runtime base may also be changed later if desired.
high_score_entry_message   = high_score_entry_message_image + CONTROLLER_RELOCATION_DELTA
hall_of_fame_header        = hall_of_fame_header_image + CONTROLLER_RELOCATION_DELTA
hall_of_fame_start_prompt  = hall_of_fame_start_prompt_image + CONTROLLER_RELOCATION_DELTA
hall_of_fame_display       = hall_of_fame_display_image + CONTROLLER_RELOCATION_DELTA
checkhi_score              = checkhi_score_image + CONTROLLER_RELOCATION_DELTA
high_score_sort_pass_runtime = high_score_sort_pass_image + CONTROLLER_RELOCATION_DELTA
space                      = space_image + CONTROLLER_RELOCATION_DELTA
microsoftstring            = microsoftstring_image + CONTROLLER_RELOCATION_DELTA
atomstring                 = atomstring_image + CONTROLLER_RELOCATION_DELTA
fourdots                   = fourdots_image + CONTROLLER_RELOCATION_DELTA
repeat_four_chars          = repeat_four_chars_image + CONTROLLER_RELOCATION_DELTA
stringdollar               = stringdollar_image + CONTROLLER_RELOCATION_DELTA
printscores                = printscores_image + CONTROLLER_RELOCATION_DELTA
spacestring                 = spacestring_image + CONTROLLER_RELOCATION_DELTA

; Self-modifying operand addresses are derived from the instructions they modify.
SPRITE_FETCH_OPERAND_LO       = renderer_sprite_fetch + 1
SPRITE_FETCH_OPERAND_HI       = renderer_sprite_fetch + 2
LANDSCAPE_STAMP_OPERAND_LO    = landscape_stamp_sprite_fetch + 1
LANDSCAPE_STAMP_OPERAND_HI    = landscape_stamp_sprite_fetch + 2
HUD_UPPER_STORE_HI_OPERAND    = hud_upper_store_instruction + 2
HUD_LOWER_STORE_HI_OPERAND    = hud_lower_store_instruction + 2

; Indexed HUD source bases are addressing biases, not independent data addresses.
; At X=&80, score_display_buffer-&80,X begins exactly at score_display_buffer;
; at X=&B0, lives_buffer_base-&B0,X begins exactly at lives_buffer_base.
HUD_UPPER_SOURCE_BASE = score_display_buffer - HUD_UPPER_X_START
HUD_LOWER_SOURCE_BASE = lives_buffer_base - HUD_LOWER_X_START

; =============================================================================
; STAGE 3 ANNOTATION MAP
; =============================================================================
; This pass documents the game at subsystem level without changing the original
; RAIDOBJ runtime bytes.  Where the author's original symbol survives in the
; embedded source residue, that name is used.  Names marked [inferred] describe
; behaviour established from control/data flow but are not known author names.
;
; EXECUTION OVERVIEW
; ------------------
;   &3400  one-time startup: copy &3000-&32FF -> &0400-&06FF, initialise
;          Hall of Fame, install envelopes, then enter copied controller.
;   &0664  title/controller: Q/S sound, SPACE/joystick selection, JSR game.
;   &0E00  game: initialise new game -> new raid -> new life, then frame loop.
;   &0502  checkhi_score: called when game finally returns after all lives.
;
; MAIN FRAME LOOP (&0E0C)
; -----------------------
;   1. escape/restart check                  &1B9E
;   2. keyboard/joystick player controls     &13CA
;   3. update bombs/bullets/enemies          &1A18
;   4. stage-specific enemy generation       &1321 -> &1964
;   5. wait for vertical sync                &1C47
;   6. erase/move object sprites             &1266/&129B
;   7. update scrolling landscape buffers    &1063
;   8. player/terrain/object collisions       &1579
;   9. advance landscape command stream      &0EA3
;  10. repeat
;
; PLAYER CONTROLS
; ---------------
; Keyboard mode uses OSBYTE &81 through `inkey`; joystick mode uses OSBYTE &80
; through `adval`.  Both routes converge on four movement helpers and two
; projectile creation routines.
;
;     A       -> &1436  player Y += 2, capped at &DD
;     Z       -> &1447  player Y -= 2, floored at &13
;     SHIFT   -> &1466  player X += 1, capped at &1E
;     SPACE   -> &1458  player X -= 1, floored at &06
;     TAB     -> &1907  drop bomb (two bomb slots)
;     RETURN  -> &1938  fire bullet (four bullet slots)
;
; Object/player coordinates are held in the labelled parallel tables
; object_x_table and object_y_table.  Slot 0 is the player's ship.  Slots above it are reused
; for projectiles and enemies; &2B50 holds the object type.
;
; SCORE / LIVES
; -------------
;   &3D       spare-lives counter.  Initial value 2 = current ship + 2 spares.
;   &3E-&40   three packed-BCD score bytes, low -> high.
;   &17B1     adds a packed-BCD score value (A low byte, X middle byte).
;   &17C3     updates score display and awards the one extra life at 15,000.
;   &178C     death/game-over path: restore saved stack, decrement lives.
;
; STAGE / LANDSCAPE SYSTEM
; ------------------------
;   &76       BCD raid counter displayed to the player.
;   &4E       current landscape/section index within a raid [inferred].
;   &04/&05   landscape command stream pointer A [inferred].
;   &06/&07   landscape delta/spacing stream pointer A [inferred].
;   &08/&09   companion landscape command stream pointer B [inferred].
;   &0A/&0B   companion delta/spacing stream pointer B [inferred].
;   &0F1B     decode next command from stream A.
;   &0F69     decode next command from stream B.
;   &0EA3     section-stream progression; increments &4E at section boundary.
; A negative command byte is an end marker and re-enters &0E06 to initialise
; the next raid/section.  The five landscapes described by the instructions are
; therefore data driven rather than five independent game loops.
;
; GRAPHICS / OBJECTS
; ------------------
;   &0FB7     convert game X/Y coordinates to MODE 2 screen address.
;   &1000     generic XOR sprite renderer; sprite address operands at &102A/B
;             are self-modified from object-type metadata.
;   &1063     copy/update the scrolling landscape strip on screen.
;   &109D     build the collision/landscape mask buffer at &2320 [inferred].
;   &1266     erase/redraw selected object slots [inferred].
;   &129B     draw active object slots [inferred].
;   &1CA7     allocate/populate an object slot.
;   &1CD7     select sprite geometry from the object-type descriptor tables.
;   &1BD4     erase/deactivate an object slot.
;
; PROJECTILES / COLLISION
; -----------------------
;   &1907     create bomb; at most two bomb slots (&2B79-object_x_table+BOMB_FIRST_SLOT+1).
;   &1938     create bullet; at most four bullet slots (&2B7B-&2B7E).
;   &1579     player/terrain/object collision controller [inferred].
;   &1627     compare sprite/collision bytes and resolve an object hit.
;   &1698     object-hit award/removal path.
;   &174D     player destroyed: explosion, palette flash, life decrement.
;
; SOUND
; -----
;   envelope_section_0  six 14-byte ENVELOPE blocks installed by startup.
;   sound_table          OSWORD 7 SOUND blocks, 8 bytes per effect.
;   &1BBC     play_sound(A=effect number), gated by soundflag.
; Confirmed by call context:
;     effect 1 = player bullet fired
;     effect 2 = bomb dropped
;     effect 8 = player explosion/death
; Effects 3-7 and 9-12 are associated with enemy/object events; keep numeric
; names until every object type is positively identified rather than guessing.
;
; HALL OF FAME / HIGH SCORE
; -------------------------
;   &0400-&04FE  display strings/data copied from image &3000.
;   &0502        checkhi_score
;   &0528        qualifying-score / name-entry path
;   &0551        OSWORD 0 line input, max 19 printable characters
;   &0580        sort score/name entries into descending order
;   &0605        render Hall Of Fame
;   &06D0        ladder: 10 x 3-byte BCD scores
;   &06EE        score/name pointer records
;   &070C        name: 10 x 20-byte name slots
;   &07D4        tempsc: temporary 3-byte score
;
; IMPORTANT BOOT ENVIRONMENT
; --------------------------
; The generated BASIC front-end now executes *TAPE before entering the game.
; This reproduces the filing-system state required by the original program.
; Leaving DFS active causes MOS line input at the Hall Of Fame to page DFS in,
; start the disc drive and fail.  *TAPE is therefore functional, not cosmetic.
;
; STAGE 6 DEEP-DIVE FINDINGS
; --------------------------
; * All 13 sprite descriptor records are decoded into pixel dimensions.
; * Types 1/2/3/4/5/6/8/9/10/11/12 now have functional identities.
; * The six internal terrain sections and their hazard dispatch are mapped.
; * Fuel is fully traced: &48:&47, 3-frame tick, &0240 maximum, +&40 per tank.
; * The dual 24-bit PRNG state at &2C-&31 is identified.
; * The HUD/fuel code &1843-&1906 is converted from EQUB bytes into mnemonics.
; * The renderer's descriptor parameters are resolved as height and byte count.
; * Fixed projectile slots explain type 9 (bullet) and type 10 (bomb).
; * Type 11 is the spare-life icon; type 8 is the player explosion.
; * Section 0/3 missile conversion proves type 12 is the airborne missile.
;
; STAGE 9.1 COMPILE-SAFE SYMBOLIC PASS
; --------------------------------------
; Stage 9.1 fixes case-insensitive namespace collisions found by the web assembler.
; SOUND_* names remain effect-number constants; sound_record_* names are table addresses.
; DRAWABLE_X_MIN_COORD is a literal, while minimum_drawable_x is the &1D scratch byte.
; No emitted game bytes are changed.
;
; STAGE 9 SYMBOLIC PASS
; ---------------------
; This version takes the earlier deep analysis into the source itself: all live
; branch/JMP/JSR destinations now have symbolic labels, frequently reused literals
; are named, context-specific zero-page aliases are used, and data records are split
; at their exact binary boundaries.  No game logic or data bytes are changed.
;
; MODIFICATION NOTES
; ------------------
; Search for "MOD:" to find deliberately documented tweak points.  These are
; comments only; the baseline values remain the original Acornsoft values.
;
; Semantic aliases.  Runtime code/data aliases are label-derived; only true
; zero-page/state bytes remain absolute because they are intentionally fixed workspace.
len                = &02         ; ORIGINAL author symbol used by microsoftstring

soundflag           = &75
joyflag             = &6E
lives               = &3D
score_lo            = &3E
score_mid           = &3F
score_hi            = &40
stage_bcd           = &76
startup_flag        = &7B

; Additional Stage 3 semantic aliases [inferred unless noted].  Internal tables
; are derived from labels, so moving the core moves them automatically.
current_section      = &4E
player_x             = object_x_table
player_y             = object_y_table
bomb_slot_table      = object_x_table + BOMB_FIRST_SLOT
bullet_slot_table    = object_x_table + BULLET_FIRST_SLOT

; Frequently used game-state aliases.  These are address aliases only
; and therefore do not alter a single emitted byte.
saved_caller_sp       = &0E
player_lives_spares   = &3D
bomb_cooldown         = &3A
bullet_cooldown       = &41
section_index         = &4E
section_spawn_timer   = &54
phizzer_update_phase        = &64       ; alternates which dynamic slot advances the Phizzer path
meteorite_update_phase        = &65       ; alternates which dynamic slot gets the meteorite extra -2 X step
warning_beeps_left    = &73
warning_beep_timer    = &74
launched_missile_slot_a = &77
launched_missile_slot_b = &78
bonus_life_awarded    = &79

; Stage 8 zero-page / scratch map.  Many of these bytes are deliberately reused
; by non-overlapping subsystems; names describe the live purpose at the call sites
; documented below.
temp                    = &1B       ; ORIGINAL author symbol
terrain_command_flags   = &1C
life_icons_to_draw      = &1C
minimum_drawable_x      = &1D
render_bytes_remaining  = &1E
render_sprite_ptr_lo    = &1F
render_sprite_ptr_hi    = &20
render_height           = &21
collision_upper_far     = &24
collision_upper_near    = &25
collision_upper_direction = &26
landscape_stamp_height  = &34
landscape_stamp_src_index = &35
collision_sprite_offset = &36
collision_screen_scanline = &37
bomb_velocity_table     = &38
bomb_phase_table        = &3B
last_bomb_key_state     = &42
last_fire_key_state     = &43
score_leading_zero_flag = &44
zeroflag                = score_leading_zero_flag ; ORIGINAL author symbol fragment
cyclecount              = stage_bcd                ; ORIGINAL author symbol fragment
collision_xor_result    = &45
collision_projectile_x  = &46
missile_update_phase    = &4A       ; alternates between the two tracked launched-missile slots
collision_projectile_slot = &4C
lower_edge_direction    = &4F
saved_rng_state         = &5E
clock_previous_low      = &66
delay_counter           = &67
timespace               = &68       ; ORIGINAL author symbol: OSWORD 1 block
joystick_fire_state     = &6F
collision_projectile_y  = &71
unused_life_state_3c = &3C       ; write-only in this build: cleared at new-life init, never read


; Shared zero-page pointers/counters.  The original is very economical with ZP,
; so several addresses legitimately have multiple context-specific names.
stringptr_lo             = &00       ; ORIGINAL source: stringptr
stringptr_hi             = &01
work_ptr_lo              = &00
work_ptr_hi              = &01
screen_ptr_lo            = &02       ; sprite/collision/circular-screen pointer
screen_ptr_hi            = &03
string_length            = &02       ; ORIGINAL source: len in microsoftstring
render_scanlines_left    = &0F
collision_pattern_ptr_lo = &14
collision_pattern_ptr_hi = &15
fuel_gauge_ptr_lo        = &14       ; same ZP pair, fuel-gauge rendering context
fuel_gauge_ptr_hi        = &15
envelope_install_ptr_lo  = &00       ; startup-only alias while installing OSWORD 8 records
envelope_install_ptr_hi  = &01
object_scan_slot         = &16
score_draw_ptr_lo        = &17
score_draw_ptr_hi        = &18

; Object descriptor / scoring tables.  Object type is the index (0..12).
; The sprite address pair is proven by draw_object_by_type self-modifying the
; absolute LDA at &1029 from these two tables.  The two draw-parameter tables
; are deliberately named neutrally until their exact geometry units are proven.

; Sprite descriptor values by type.  Heights are scanlines; byte counts are total
; column-major MODE-2 bytes.  Width pixels = 2 * (bytes / height).
PLAYER_SPRITE_HEIGHT = 10
PLAYER_SPRITE_BYTES = 70              ; 7 byte-columns = 14 pixels
GROUND_MISSILE_SPRITE_HEIGHT = 20
GROUND_MISSILE_SPRITE_BYTES = 60      ; 3 byte-columns = 6 pixels
FUEL_TANK_SPRITE_HEIGHT = 16
FUEL_TANK_SPRITE_BYTES = 96           ; 6 byte-columns = 12 pixels
FINAL_DUSTBIN_SPRITE_HEIGHT = 16
FINAL_DUSTBIN_SPRITE_BYTES = 96       ; 6 byte-columns = 12 pixels
PHIZZER_SPRITE_HEIGHT = 6
PHIZZER_SPRITE_BYTES = 18             ; 3 byte-columns = 6 pixels
MYSTERY_TARGET_SPRITE_HEIGHT = 16
MYSTERY_TARGET_SPRITE_BYTES = 96      ; 6 byte-columns = 12 pixels
METEORITE_SPRITE_HEIGHT = 10
METEORITE_SPRITE_BYTES = 40           ; 4 byte-columns = 8 pixels
UNUSED_7_SPRITE_HEIGHT = 6
UNUSED_7_SPRITE_BYTES = 18             ; 3 byte-columns = 6 pixels
PLAYER_EXPLOSION_SPRITE_HEIGHT = 14
PLAYER_EXPLOSION_SPRITE_BYTES = 126   ; 9 byte-columns = 18 pixels
BULLET_SPRITE_HEIGHT = 2
BULLET_SPRITE_BYTES = 2                ; 1 byte-column = 2 pixels
BOMB_SPRITE_HEIGHT = 7
BOMB_SPRITE_BYTES = 14                 ; 2 byte-columns = 4 pixels
LIFE_ICON_SPRITE_HEIGHT = 8
LIFE_ICON_SPRITE_BYTES = 32            ; 4 byte-columns = 8 pixels
LAUNCHED_MISSILE_SPRITE_HEIGHT = 23
LAUNCHED_MISSILE_SPRITE_BYTES = 69    ; 3 byte-columns = 6 pixels

; object_trigger_offset is only meaningful as scenery spacing for object types
; that actually occur in the fixed scenery stream.  Entry 0 is repurposed by
; bullet creation as the player's projectile X offset.
PLAYER_PROJECTILE_X_OFFSET = 7
GROUND_MISSILE_SCENERY_PERIOD = 3
FUEL_TANK_SCENERY_PERIOD = 6
FINAL_DUSTBIN_SCENERY_PERIOD = 25
MYSTERY_TARGET_SCENERY_PERIOD = 7
TRIGGER_UNUSED_TYPE4 = 3
TRIGGER_UNUSED_TYPE6 = 4
TRIGGER_UNUSED_TYPE7 = 3
TRIGGER_UNUSED_TYPE8 = 9
TRIGGER_UNUSED_TYPE9 = 1
TRIGGER_UNUSED_TYPE10 = 2
TRIGGER_UNUSED_TYPE11 = 4
TRIGGER_UNUSED_TYPE12 = 3

; Object type IDs - Stage 6 identification.
; These names are now supported by several independent pieces of evidence:
;   * object sprite shape and geometry,
;   * the fixed landscape object stream at &2A00,
;   * section-specific spawn/update code,
;   * packed-BCD score tables, and
;   * contemporary descriptions of Rocket Raid/Scramble gameplay.
;
; The score values are particularly diagnostic: stationary missile=50, fuel
; tank=150, final base=800, Phizzer=100, meteorite=0 (indestructible), and the
; launched missile=80.  Type 5 is deliberately random-score, exactly matching
; the mystery-target role.
TYPE_PLAYER             = 0
TYPE_GROUND_MISSILE     = 1      ; 50 points; landscape object; can launch
TYPE_FUEL_TANK          = 2      ; 150 points; restores fuel in &16A3-&16E6
TYPE_FINAL_DUSTBIN      = 3      ; 800 points; contemporary review identifies final target as a dustbin
TYPE_FINAL_BASE         = TYPE_FINAL_DUSTBIN ; compatibility/descriptive alias
TYPE_PHIZZER             = 4      ; 100 points; cavern convoy/path-following enemy
TYPE_MYSTERY_TARGET      = 5      ; random 200/350/450/600 point award
TYPE_METEORITE           = 6      ; 0 points; fast section-2 hazard
TYPE_UNUSED_SPRITE_7      = 7      ; descriptor/sprite exists, but full live-code xref finds no allocator
TYPE_AUXILIARY_7         = TYPE_UNUSED_SPRITE_7 ; compatibility alias for earlier stages
TYPE_PLAYER_EXPLOSION    = 8      ; drawn explicitly at &1768 after player death
TYPE_BULLET              = 9      ; fixed object slots 3..6 are initialised to type 9
TYPE_BOMB                = 10     ; fixed object slots 1..2 are initialised to type 10
TYPE_LIFE_ICON           = 11     ; descriptor 11 is copied for spare-life display
TYPE_LAUNCHED_MISSILE    = 12     ; transformed type 1; 80 points

; Deprecated neutral aliases retained only for compatibility with earlier notes.
TYPE_STAGE_OBJECT_1    = TYPE_GROUND_MISSILE
TYPE_HIT_SPECIAL_2     = TYPE_FUEL_TANK
TYPE_RAID_COMPLETION   = TYPE_FINAL_BASE
TYPE_MOVING_OBJECT_4   = TYPE_PHIZZER
TYPE_RANDOM_SCORE_5    = TYPE_MYSTERY_TARGET
TYPE_FAST_OBJECT_6     = TYPE_METEORITE
TYPE_TRANSFORMED_12    = TYPE_LAUNCHED_MISSILE

; SIX internal terrain sections.
; ------------------------------
; The game is usually described in terms of five principal landscapes, but the
; machine code has six section states.  Section 5 is the dedicated final/base
; approach.  This is proven by the six-entry tables at &2C0C/&2C12/&2C20/&2C26
; and by the exact command-stream boundaries recovered in Stage 7.
;
; Upper-terrain command ranges and generated horizontal columns:
;   0  &2600-&264A   75 commands   1025 columns   Fuel depot / mountains
;   1  &264B-&2686   60 commands   1022 columns   Cavern
;   2  &2687-&26CE   72 commands   1629 columns   Meteorites
;   3  &26CF-&272E   96 commands    805 columns   Skyscrapers
;   4  &272F-&2776   72 commands   1328 columns   Maze
;   5  &2777-&27E4  110 commands   1794 columns   Final base / raid target
;      &27E5 = &FF terminator -> new raid
;
; The nominal section-5 command budget table contains &80 (128), but the stream
; reaches its explicit &FF terminator after 110 commands.  The terminator wins.
SECTION_FUEL_DEPOT      = 0
SECTION_CAVERN          = 1
SECTION_METEORITES      = 2
SECTION_SKYSCRAPERS     = 3
SECTION_MAZE            = 4
SECTION_FINAL_BASE      = 5

; BBC key constants used by the game
KEY_Q                 = &EF
KEY_S                 = &AE
KEY_UP_A              = &BE
KEY_DOWN_Z            = &9E
KEY_FORWARD_SHIFT     = &FF
KEY_BACK_SPACE        = &9D
KEY_BOMB_TAB          = &9F
KEY_FIRE_RETURN       = &B6
KEY_ESCAPE            = &8F
KEY_PAUSE_DELETE       = &A6       ; INKEY(-90): hidden pause/wait-for-key path
qkey                  = KEY_Q      ; ORIGINAL author symbol
skey                  = KEY_S      ; ORIGINAL author symbol

; Sound effect IDs.  1,2,8 are directly proven by action call sites; 3-6
; become identifiable once the Stage 6 object mapping is applied.
SOUND_FIRE_BULLET       = 1
SOUND_DROP_BOMB         = 2
SOUND_MISSILE_LAUNCH    = 3
SOUND_PHIZZER_SPAWN     = 4
SOUND_METEORITE_SPAWN   = 5
SOUND_TARGET_DESTROYED  = 6
SOUND_TERRAIN_IMPACT    = 7      ; collision without an object-slot hit
SOUND_PLAYER_DEATH      = 8
SOUND_QUIET_CHANNEL_2   = 9      ; OSWORD7 block is channel 18, amplitude 0
SOUND_EXTRA_LIFE_BEEP   = 10
SOUND_QUIET_CHANNEL_1   = 11     ; OSWORD7 block is channel 17, amplitude 0
SOUND_RAID_COMPLETE     = 12     ; called only by raid_complete; channel 1 amplitude 0 => quiet/control, not an audible tune

; Stage 6 state recovery -------------------------------------------------------
; Fuel is a 16-bit countdown in &48:&47.  A new life starts at &0240.  Every
; third frame the counter is decremented.  Destroying a fuel tank adds &0040,
; capped at &0240.  Once it reaches zero, &7A becomes negative and the control
; path forces the ship downwards until it crashes.
fuel_low               = &47
fuel_high              = &48
fuel_tick_divider      = &49
out_of_fuel_flag       = &7A

; Two independent 24-bit pseudo-random states.  The helpers at &1C4F/&1C60
; rotate/feedback these values; &1C71 returns the first generator's low byte.
rng_a_lo               = &2C
rng_a_mid              = &2D
rng_a_hi               = &2E
rng_b_lo               = &2F
rng_b_mid              = &30
rng_b_hi               = &31

; Scrolling screen-memory base.  The BBC display wraps at &8000; helpers in
; the renderer subtract/add &5000 to map the circular screen into &3000-&7FFF.
scroll_screen_lo        = &0C
scroll_screen_hi        = &0D
; Surviving source fragment contains "LDAtop+1" in the fuel-gauge path.  Its
; data flow maps `top` to this 16-bit circular screen base.
top                     = scroll_screen_lo          ; probable ORIGINAL author symbol
; Surviving source fragment: "mpz:LDAtop+1:ADC#`gaugesiz".  In the finished
; code this maps exactly to the high-byte part of the &0750 gauge-body offset.
; `gaugesiz` is therefore retained as a probable original-source alias.
gaugesiz                = FUEL_GAUGE_BODY_OFFSET    ; probable ORIGINAL author symbol (&0750)

; Landscape command/data stream pointers.  &0F1B consumes the first pair and
; &0F69 the second.  Saved copies at &55-&5C allow a life restart to restore the
; exact beginning of the current section rather than restart the whole raid.
upper_shape_cmd_lo      = &04
upper_shape_cmd_hi      = &05
upper_shape_delta_lo    = &06
upper_shape_delta_hi    = &07
lower_shape_cmd_lo      = &08
lower_shape_cmd_hi      = &09
lower_shape_delta_lo    = &0A
lower_shape_delta_hi    = &0B

; Object descriptor geometry is now proven by sprite boundaries: param_1 is
; sprite height in scanlines; param_2 is total bytes.  Since MODE 2 encodes two
; horizontal pixels per byte, width = 2 * (total_bytes / height).

; Stage 7: complete parallel-object-array map.
; There are 20 slots (0..19). Slot 0 is the player; 1..2 bombs; 3..6 bullets;
; later slots are landscape and dynamic enemy objects. The first four arrays
; hold current/previous screen addresses used by XOR erase/redraw.

; Two 33-byte rolling terrain edge buffers. Index &20 is the newest generated
; column; values move through the visible playfield as the hardware display
; origin scrolls.


; Six-entry section-control tables.

; Terrain bytecode streams. Command and signed-delta streams are parallel.

; Fixed landscape-object sequence: 160 entries then &FF.
; Distribution: 48 missiles, 69 fuel tanks, 40 mystery targets, 3 final bases.

; Zero-page terrain decoder state.
upper_run_remaining     = &27
lower_run_remaining     = &28
upper_delta             = &29       ; signed profile delta while decoding
upper_scenery_gate      = &29       ; post-decode: 0 allows fixed scenery, nonzero blocks it
upper_edge_value        = &2A
lower_edge_value        = &2B
landscape_object_index  = &32
landscape_stamp_bytes_left = &33
section_cmds_remaining  = &4D
current_lower_edge      = &50
previous_lower_edge     = &51
collision_lower_near    = &52
collision_lower_far     = &53
current_upper_edge      = &22
previous_upper_edge     = &23
lower_delta             = &70
landscape_object_bottom = &72

; Saved section restart state (&55-&5D). A lost life resumes at the beginning
; of the current section, not the start of the complete raid.
saved_upper_cmd_lo      = &55
saved_upper_cmd_hi      = &56
saved_upper_delta_lo    = &57
saved_upper_delta_hi    = &58
saved_lower_cmd_lo      = &59
saved_lower_cmd_hi      = &5A
saved_lower_delta_lo    = &5B
saved_lower_delta_hi    = &5C
saved_landscape_object_index = &5D

; -----------------------------------------------------------------------------
; TERRAIN BYTECODE FORMAT (resolved Stage 7)
; -----------------------------------------------------------------------------
; Upper command stream: &2600..&27E5, &FF terminator at &27E5.
; Upper delta stream:   &2800..&29E4, exactly 485 signed bytes.
; Lower command stream: &24C0..&2544, &FF terminator at &2544.
; Lower delta stream:   &2560..&25E3, exactly 132 signed bytes.
;
; Command byte:
;   bit 7     end-of-raid marker when set (live streams use &FF)
;   bit 6     post-generation delta-adjust flag; decoder DEC's active delta
;   bit 5     ignored
;   bits 0-4  run length, 1..31 columns
;
; Each command reads one signed delta. Starting from the current edge value,
; the decoder generates run_length samples into the rolling profile. delta=0
; gives a perfectly flat run. A non-zero delta also receives a small PRNG
; perturbation (-4..+3) for each generated sample, roughening sloped terrain.
;
; Lower terrain is active only in sections 1 (cavern) and 4 (maze):
; section_lower_mode = FF,00,FF,FF,00,FF.
; Other sections hold the lower edge at its flat baseline &E0.
; -----------------------------------------------------------------------------

runtime_payload_start:                 ; assembler Origin field; default supplied by @default-origin
core_image_start:
game:                                  ; ORIGINAL author symbol
; NOTE: trailing ; &xxxx comments throughout the movable core record the ORIGINAL
; &0E00 build addresses for archaeology. When Origin changes, labels/listing are truth.
; Keep the core origin page-aligned. Several compact pointer calculations intentionally
; rely on the same low-byte geometry as the original page-aligned &0E00 layout.
caller_stack_save_and_game_entry:

; -----------------------------------------------------------------------------
; CORE GAME ENTRY, FRAME LOOP, LANDSCAPE, RENDERER AND MASK BUILDER
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
    TSX                                ; &0E00
    STX saved_caller_sp                            ; &0E01  saved_caller_sp
    JSR new_game_init                  ; &0E03
restart_raid_entry:                    ; re-entry preserves original nested JSR stack structure
    JSR new_raid_init                  ; &0E06
restart_life_entry:                    ; death with a spare returns here via restored stack
    JSR new_life_init                  ; &0E09
main_frame_loop:
    LDA startup_flag                            ; &0E0C
    STA sysvia_ier                          ; &0E0E
    JSR check_escape_restart           ; &0E11
    JSR read_keyboard_controls         ; &0E14
    JSR update_active_objects          ; &0E17
    JSR prepare_object_frame_and_spawn_hazards                          ; &0E1A
    SEI                                ; &0E1D
    JSR wait_vsync                     ; &0E1E
    JSR erase_player_previous_and_current                          ; &0E21
    JSR copy_landscape_mask_to_screen                          ; &0E24
    JSR erase_dynamic_objects_and_projectiles                          ; &0E27
    CLI                                ; &0E2A
    JSR collision_controller                          ; &0E2B
    JSR advance_landscape_stream                          ; &0E2E
    JMP main_frame_loop                ; &0E31
setup_section_environment:
    LDA upper_shape_cmd_lo                            ; &0E34
    STA saved_upper_cmd_lo                            ; &0E36
    LDA upper_shape_delta_lo                            ; &0E38
    STA saved_upper_delta_lo                            ; &0E3A
    LDA lower_shape_cmd_lo                            ; &0E3C
    STA saved_lower_cmd_lo                            ; &0E3E
    LDA lower_shape_delta_lo                            ; &0E40
    STA saved_lower_delta_lo                            ; &0E42
    LDA landscape_object_index                            ; &0E44
    STA saved_landscape_object_index                            ; &0E46
    LDA upper_shape_cmd_hi                            ; &0E48
    STA saved_upper_cmd_hi                            ; &0E4A
    LDA upper_shape_delta_hi                            ; &0E4C
    STA saved_upper_delta_hi                            ; &0E4E
    LDA lower_shape_cmd_hi                            ; &0E50
    STA saved_lower_cmd_hi                            ; &0E52
    LDA lower_shape_delta_hi                            ; &0E54
    STA saved_lower_delta_hi                            ; &0E56
    LDY #RNG_STATE_BYTE_COUNT-1          ; &0E58: save both 24-bit PRNG states
save_rng_state_loop:
    LDA rng_a_lo,Y                       ; &0E5A
    STA saved_rng_state,Y                        ; &0E5D
    DEY                                ; &0E60
    BPL save_rng_state_loop                          ; &0E61
load_section_parameters:
    LDY section_index                            ; &0E63  current_section
    LDA section_upper_cmd_budget,Y                        ; &0E65
    STA section_cmds_remaining                            ; &0E68
    LDA section_lower_mode,Y                        ; &0E6A
    STA lower_run_remaining                            ; &0E6D
    TYA                                ; &0E6F
    PHA                                ; &0E70
    LDA section_envelope_index,Y                        ; &0E71
    TAY                                ; &0E74
    LDA #ENVELOPE_RECORD_BYTES                           ; &0E75
    JSR multiply_a_by_y_slow                          ; &0E77
    CLC                                ; &0E7A
    ADC #<envelope_section_0           ; &0E7B
    TAX                                ; &0E7D
    LDY #>envelope_section_0           ; &0E7E
    BCC define_section_envelope                          ; &0E80
    INY                                ; &0E82
define_section_envelope:
    LDA #OSWORD_DEFINE_ENVELOPE                           ; &0E83
    JSR osword                          ; &0E85
    PLA                                ; &0E88
    TAY                                ; &0E89
    LDA section_colour_code,Y                        ; &0E8A
    LDY #LOGICAL_TERRAIN_COLOUR                           ; &0E8D
    JSR set_palette                    ; &0E8F
    LDA #LOWER_EDGE_FLAT                           ; &0E92
    STA lower_edge_value                            ; &0E94
    STA current_lower_edge                            ; &0E96
    STA previous_lower_edge                            ; &0E98
    LDA #UPPER_EDGE_INITIAL                           ; &0E9A
    STA upper_edge_value                            ; &0E9C
    LDA #BYTE_FALSE                     ; &0E9E
    STA landscape_stamp_bytes_left                            ; &0EA0
    RTS                                ; &0EA2
advance_landscape_stream:
    LDX upper_run_remaining                            ; &0EA3
    BNE update_lower_terrain                          ; &0EA5
    LDA section_cmds_remaining                            ; &0EA7
    BNE consume_section_command_budget                          ; &0EA9
    INC section_index                            ; &0EAB  current_section
    JSR setup_section_environment                          ; &0EAD
consume_section_command_budget:
    DEC section_cmds_remaining                            ; &0EB0
    JSR decode_upper_landscape_command                          ; &0EB2
update_lower_terrain:
    LDX lower_run_remaining                            ; &0EB5
    BMI scroll_and_render_landscape                          ; &0EB7
    BNE sample_lower_terrain                          ; &0EB9
    JSR decode_lower_landscape_command                          ; &0EBB
sample_lower_terrain:
    LDX lower_run_remaining                            ; &0EBE
    LDY lower_terrain_profile,X                        ; &0EC0
    STY current_lower_edge                            ; &0EC3
    DEC lower_run_remaining                            ; &0EC5
scroll_and_render_landscape:
    JSR copy_hud_upper_strip           ; &0EC7
    JSR advance_scroll_position        ; &0ECA
    LDA scroll_screen_lo                            ; &0ECD
    STA temp                            ; &0ECF
    LDA scroll_screen_hi                            ; &0ED1
    LSR A                              ; &0ED3
    ROR temp                            ; &0ED4
    LSR A                              ; &0ED6
    ROR temp                            ; &0ED7
    LSR A                              ; &0ED9
    ROR temp                            ; &0EDA
    LDX #CRTC_SCREEN_START_HI_REG                           ; &0EDC
    JSR write_crtc_register            ; &0EDE
    LDX #CRTC_SCREEN_START_LO_REG                           ; &0EE1
    LDA temp                            ; &0EE3
    JSR write_crtc_register            ; &0EE5
    JSR build_landscape_collision_mask                          ; &0EE8
    LDA landscape_stamp_bytes_left                            ; &0EEB
    BEQ consider_landscape_object                          ; &0EED
    JSR continue_landscape_object_stamp ; &0EEF: continue scenery stamp
    JMP consume_upper_profile_column                          ; &0EF2
consider_landscape_object:
    ; Fixed scenery can only begin when the current upper command deliberately
    ; leaves upper_scenery_gate at zero.  A normal delta=0 command does this.
    ; TERRAIN_CMD_NO_SCENERY_BIT causes the decoder to turn that zero into &FF,
    ; preventing scenery even though the visible terrain remains perfectly flat.
    LDA upper_scenery_gate                            ; &0EF5
    BNE consume_upper_profile_column                          ; &0EF7
    LDX landscape_object_index                            ; &0EF9
    LDY landscape_object_stream,X                        ; &0EFB
    LDA object_trigger_offset,Y                    ; &0EFE: type-specific scenery trigger offset
    TAY                                ; &0F01
    LDA upper_run_remaining                            ; &0F02
    JSR wrap_delta                     ; &0F04
    BNE consume_upper_profile_column                          ; &0F07
    JSR spawn_landscape_object                          ; &0F09
consume_upper_profile_column:
    LDX upper_run_remaining                            ; &0F0C
    LDY upper_terrain_profile,X                        ; &0F0E
    CPY current_upper_edge                            ; &0F11
    BNE commit_upper_edge                          ; &0F13
    DEY                                ; &0F15
commit_upper_edge:
    STY current_upper_edge                            ; &0F16
    DEC upper_run_remaining                            ; &0F18
    RTS                                ; &0F1A
decode_upper_landscape_command:
    LDY #&00                           ; &0F1B
    LDA (upper_shape_cmd_lo),Y                        ; &0F1D
    STA terrain_command_flags           ; &0F1F
    BPL decode_upper_command_body                          ; &0F21
    LDX saved_caller_sp                            ; &0F23  saved_caller_sp
    TXS                                ; &0F25
    JMP restart_raid_entry             ; &0F26: terrain terminator -> next raid through original call chain
decode_upper_command_body:
    AND #TERRAIN_CMD_RUN_MASK                           ; &0F29
    STA upper_run_remaining                            ; &0F2B
    TAX                                ; &0F2D
    LDA (upper_shape_delta_lo),Y                        ; &0F2E
    STA upper_delta                            ; &0F30
    INC upper_shape_cmd_lo                            ; &0F32
    BNE advance_upper_delta_pointer                          ; &0F34
    INC upper_shape_cmd_hi                            ; &0F36
advance_upper_delta_pointer:
    INC upper_shape_delta_lo                            ; &0F38
    BNE generate_upper_profile_loop                          ; &0F3A
    INC upper_shape_delta_hi                            ; &0F3C
generate_upper_profile_loop:
    LDA upper_edge_value                  ; &0F3E
    CLC                                ; &0F40
    ADC upper_delta                            ; &0F41
    STA temp                            ; &0F43
    LDY upper_delta                            ; &0F45
    BEQ store_upper_profile_sample                          ; &0F47
    JSR step_rng_a                          ; &0F49
    LSR A                              ; &0F4C
    BCS upper_jitter_positive                          ; &0F4D
    AND #TERRAIN_JITTER_MASK                           ; &0F4F
    EOR #&FF                           ; &0F51
    BMI apply_upper_jitter                          ; &0F53
upper_jitter_positive:
    AND #TERRAIN_JITTER_MASK                           ; &0F55
apply_upper_jitter:
    CLC                                ; &0F57
    ADC temp                            ; &0F58
store_upper_profile_sample:
    STA upper_terrain_profile,X                        ; &0F5A
    STA upper_edge_value                  ; &0F5D
    DEX                                ; &0F5F
    BNE generate_upper_profile_loop                          ; &0F60
    ASL terrain_command_flags           ; &0F62: command bit 6 -> N flag
    BPL upper_command_done                          ; &0F64
    ; All 129 bit-6 commands in the shipped upper stream have raw delta=0.
    ; DEC therefore changes the *post-generation* delta from 0 to &FF.  The
    ; already-generated flat profile is untouched, but consider_landscape_object
    ; now sees a non-zero scenery gate.  Bit 6 is therefore a NO-SCENERY flag.
    DEC upper_scenery_gate                        ; &0F66: 0 -> &FF, suppress fixed scenery
upper_command_done:
    RTS                                ; &0F68
decode_lower_landscape_command:
    LDY #&00                           ; &0F69
    LDA (lower_shape_cmd_lo),Y                        ; &0F6B
    STA terrain_command_flags           ; &0F6D
    BPL decode_lower_command_body                          ; &0F6F
    LDX saved_caller_sp                            ; &0F71  saved_caller_sp
    TXS                                ; &0F73
    JMP restart_raid_entry             ; &0F74: lower-stream terminator -> next raid through original call chain
decode_lower_command_body:
    AND #TERRAIN_CMD_RUN_MASK                           ; &0F77
    STA lower_run_remaining                            ; &0F79
    TAX                                ; &0F7B
    LDA (lower_shape_delta_lo),Y                        ; &0F7C
    STA lower_delta                       ; &0F7E
    INC lower_shape_cmd_lo                            ; &0F80
    BNE advance_lower_delta_pointer                          ; &0F82
    INC lower_shape_cmd_hi                            ; &0F84
advance_lower_delta_pointer:
    INC lower_shape_delta_lo                            ; &0F86
    BNE generate_lower_profile_loop                          ; &0F88
    INC lower_shape_delta_hi                            ; &0F8A
generate_lower_profile_loop:
    LDA lower_edge_value                  ; &0F8C
    CLC                                ; &0F8E
    ADC lower_delta                       ; &0F8F
    STA temp                            ; &0F91
    LDY lower_delta                       ; &0F93
    BEQ store_lower_profile_sample                          ; &0F95
    JSR step_rng_a                          ; &0F97
    LSR A                              ; &0F9A
    BCS lower_jitter_positive                          ; &0F9B
    AND #TERRAIN_JITTER_MASK                           ; &0F9D
    EOR #&FF                           ; &0F9F
    BMI apply_lower_jitter                          ; &0FA1
lower_jitter_positive:
    AND #TERRAIN_JITTER_MASK                           ; &0FA3
apply_lower_jitter:
    CLC                                ; &0FA5
    ADC temp                            ; &0FA6
store_lower_profile_sample:
    STA lower_terrain_profile,X                        ; &0FA8
    STA lower_edge_value                  ; &0FAB
    DEX                                ; &0FAD
    BNE generate_lower_profile_loop                          ; &0FAE
    ASL terrain_command_flags           ; &0FB0: same decoder shape as upper stream
    BPL lower_command_done                          ; &0FB2
    DEC lower_delta                       ; &0FB4
    ; No command in the shipped lower stream sets bit 6, so this path is dormant.
lower_command_done:
    RTS                                ; &0FB6
; -----------------------------------------------------------------------------
; screen_address_from_xy
; -----------------------------------------------------------------------------
; IN:  X = game horizontal byte-column coordinate
;      Y = game vertical pixel coordinate
; OUT: screen_ptr = address of that pixel row in the circular MODE-2 framebuffer
;      screen_ptr_hi=0 if X < minimum_drawable_x (caller treats as clipped)
;
; Exact mapping derived from the shifts below:
;   v        = 255 - Y
;   char_row = v >> 3
;   scanline = v & 7
;   address  = scroll_screen + char_row*&0280 + X*8 + scanline
;
; MODE 2 has 80 byte-columns and 8 scanlines per character row, hence &0280.
; The display is circular: addresses crossing &8000 are mapped back to &3000 by
; subtracting &50 from the high byte.  Sprite data is column-major, so moving one
; horizontal MODE-2 byte column advances the screen pointer by eight bytes.
; -----------------------------------------------------------------------------
screen_address_from_xy:
    LDA #&00                           ; &0FB7
    STA screen_ptr_hi                   ; &0FB9
    CPX minimum_drawable_x              ; &0FBB
    BCC screen_address_done                          ; &0FBD
    TYA                                ; &0FBF
    EOR #&FF                           ; &0FC0
    PHA                                ; &0FC2
    LSR A                              ; &0FC3
    LSR A                              ; &0FC4
    LSR A                              ; &0FC5
    TAY                                ; &0FC6
    LSR A                              ; &0FC7
    STA temp                            ; &0FC8
    LDA #&00                           ; &0FCA
    ROR A                              ; &0FCC
    ADC scroll_screen_lo                            ; &0FCD
    PHP                                ; &0FCF
    STA screen_ptr_lo                   ; &0FD0
    TYA                                ; &0FD2
    ASL A                              ; &0FD3
    ADC temp                            ; &0FD4
    PLP                                ; &0FD6
    ADC scroll_screen_hi                            ; &0FD7
    STA screen_ptr_hi                   ; &0FD9
    LDA #&00                           ; &0FDB
    STA temp                            ; &0FDD
    TXA                                ; &0FDF
    ASL A                              ; &0FE0
    ROL temp                            ; &0FE1
    ASL A                              ; &0FE3
    ROL temp                            ; &0FE4
    ASL A                              ; &0FE6
    ROL temp                            ; &0FE7
    ADC screen_ptr_lo                   ; &0FE9
    STA screen_ptr_lo                   ; &0FEB
    LDA temp                            ; &0FED
    ADC screen_ptr_hi                   ; &0FEF
    BPL screen_address_store_hi                          ; &0FF1
    SEC                                ; &0FF3
    SBC #SCREEN_WRAP_HIGH_DELTA                           ; &0FF4
screen_address_store_hi:
    STA screen_ptr_hi                   ; &0FF6
    PLA                                ; &0FF8
    AND #MODE2_SCANLINE_MASK                           ; &0FF9
    ORA screen_ptr_lo                   ; &0FFB
    STA screen_ptr_lo                   ; &0FFD
screen_address_done:
    RTS                                ; &0FFF
; -----------------------------------------------------------------------------
; xor_sprite_renderer
; -----------------------------------------------------------------------------
; XOR renderer used for both DRAW and ERASE.  `render_height` is the number of
; scanline bytes per sprite column and `render_bytes_remaining` is total bytes.
; Thus sprite width in MODE-2 byte-columns = total_bytes / height, and visible
; pixel width = 2 * that value.  The renderer is intentionally self-modifying:
; `renderer_sprite_fetch` has its absolute operand patched to the chosen sprite.
; -----------------------------------------------------------------------------
xor_sprite_renderer:
    LDA screen_ptr_hi                   ; &1000
    BNE renderer_begin                          ; &1002
    RTS                                ; &1004
renderer_begin:
    LDA render_sprite_ptr_lo            ; &1005
    STA SPRITE_FETCH_OPERAND_LO        ; &1007
    LDA render_sprite_ptr_hi            ; &100A
    STA SPRITE_FETCH_OPERAND_HI        ; &100C
    LDA render_bytes_remaining          ; &100F
    PHA                                ; &1011
    LDX #&00                           ; &1012
renderer_next_column:
    LDA screen_ptr_hi                   ; &1014
    PHA                                ; &1016
    LDA screen_ptr_lo                   ; &1017
    PHA                                ; &1019
    LDA render_height                   ; &101A
    STA render_scanlines_left           ; &101C
    LDA screen_ptr_lo                   ; &101E
    AND #MODE2_SCANLINE_MASK                           ; &1020
    TAY                                ; &1022
    LDA screen_ptr_lo                   ; &1023
    AND #MODE2_SCANLINE_CLEAR_MASK                           ; &1025
    STA screen_ptr_lo                   ; &1027
renderer_xor_byte:
renderer_sprite_fetch:                 ; operand bytes are patched from object sprite pointer tables
    LDA SMC_ABSOLUTE_PLACEHOLDER,X     ; &1029
    INX                                ; &102C
    EOR (screen_ptr_lo),Y                        ; &102D
    STA (screen_ptr_lo),Y                        ; &102F
    INY                                ; &1031
    CPY #MODE2_SCANLINES_PER_CHAR                           ; &1032
    BEQ renderer_cross_char_row                          ; &1034
renderer_next_scanline:
    DEC render_scanlines_left           ; &1036
    BEQ renderer_advance_column                          ; &1038
    DEC render_bytes_remaining          ; &103A
    BNE renderer_xor_byte                          ; &103C
    PLA                                ; &103E
    PLA                                ; &103F
    PLA                                ; &1040
    STA render_bytes_remaining          ; &1041
    RTS                                ; &1043
renderer_cross_char_row:
    LDY #&00                           ; &1044
    JSR advance_collision_char_row_pointer ; &1046
    BNE renderer_next_scanline                          ; &1049
renderer_advance_column:
    CLC                                ; &104B
    PLA                                ; &104C
    ADC #SCROLL_STEP_BYTES                           ; &104D
    STA screen_ptr_lo                   ; &104F
    PLA                                ; &1051
    ADC #&00                           ; &1052
    BPL renderer_store_screen_hi                          ; &1054
    SEC                                ; &1056
    SBC #SCREEN_WRAP_HIGH_DELTA                           ; &1057
renderer_store_screen_hi:
    STA screen_ptr_hi                   ; &1059
    DEC render_bytes_remaining          ; &105B
    BNE renderer_next_column                          ; &105D
    PLA                                ; &105F
    STA render_bytes_remaining          ; &1060
    RTS                                ; &1062
copy_landscape_mask_to_screen:
    LDX #LANDSCAPE_MASK_LAST_INDEX    ; &1063
    LDY #&00                           ; &1065
    LDA scroll_screen_lo                            ; &1067
    CLC                                ; &1069
    ADC #LANDSCAPE_COPY_OFFSET_LO                           ; &106A
    STA work_ptr_lo                     ; &106C
    LDA scroll_screen_hi                            ; &106E
    ADC #LANDSCAPE_COPY_OFFSET_HI                           ; &1070
    BPL mask_copy_store_hi                          ; &1072
    SEC                                ; &1074
    SBC #SCREEN_WRAP_HIGH_DELTA                           ; &1075
mask_copy_store_hi:
    STA work_ptr_hi                     ; &1077
mask_copy_byte_loop:
    LDA landscape_mask,X                        ; &1079
    STA (&00),Y                        ; &107C
    DEX                                ; &107E
    INY                                ; &107F
    CPY #MODE2_SCANLINES_PER_CHAR                           ; &1080
    BNE mask_copy_byte_loop                          ; &1082
    LDY #&00                           ; &1084
    LDA work_ptr_lo                     ; &1086
    CLC                                ; &1088
    ADC #MODE2_CHAR_ROW_STRIDE_LO                           ; &1089
    STA work_ptr_lo                     ; &108B
    LDA work_ptr_hi                     ; &108D
    ADC #MODE2_CHAR_ROW_STRIDE_HI                           ; &108F
    BPL mask_copy_next_row                          ; &1091
    SEC                                ; &1093
    SBC #SCREEN_WRAP_HIGH_DELTA                           ; &1094
mask_copy_next_row:
    STA work_ptr_hi                     ; &1096
    CPX #LANDSCAPE_MASK_LAST_INDEX    ; &1098
    BNE mask_copy_byte_loop                          ; &109A
    RTS                                ; &109C
build_landscape_collision_mask:
    LDA previous_upper_edge                            ; &109D
    CMP current_upper_edge                            ; &109F
    BCC upper_edge_rising                          ; &10A1
    STA collision_upper_far                            ; &10A3
    LDA #&00                           ; &10A5
    STA collision_upper_direction                            ; &10A7
    LDA current_upper_edge                            ; &10A9
    STA collision_upper_near                            ; &10AB
    JMP classify_lower_edge                          ; &10AD
upper_edge_rising:
    LDA #&FF                           ; &10B0
    STA collision_upper_direction                            ; &10B2
    LDA current_upper_edge                            ; &10B4
    STA collision_upper_far                            ; &10B6
    LDA previous_upper_edge                            ; &10B8
    STA collision_upper_near                            ; &10BA
classify_lower_edge:
    LDA previous_lower_edge                            ; &10BC
    CMP current_lower_edge                            ; &10BE
    BCC lower_edge_rising                          ; &10C0
    STA collision_lower_far                            ; &10C2
    LDA #&FF                           ; &10C4
    STA lower_edge_direction                            ; &10C6
    LDA current_lower_edge                            ; &10C8
    STA collision_lower_near                            ; &10CA
    JMP build_lower_mask                          ; &10CC
lower_edge_rising:
    LDA #&00                           ; &10CF
    STA lower_edge_direction                            ; &10D1
    LDA current_lower_edge                            ; &10D3
    STA collision_lower_far                            ; &10D5
    LDA previous_lower_edge                            ; &10D7
    STA collision_lower_near                            ; &10D9
build_lower_mask:
    LDX #&00                           ; &10DB
    LDA lower_run_remaining                            ; &10DD
    BPL lower_mask_enabled                          ; &10DF
    JMP clear_between_boundaries                          ; &10E1
lower_mask_enabled:
    LDA collision_lower_far                            ; &10E4
    CMP #LOWER_PROFILE_OFFSCREEN       ; &10E6
    BCC clear_below_lower_edge                          ; &10E8
    JMP clear_between_boundaries                          ; &10EA
clear_below_lower_edge:
    LDA #&00                           ; &10ED
clear_lower_mask_loop:
    STA landscape_mask,X                        ; &10EF
    CPX #LOWER_PROFILE_LAST_SOLID      ; &10F2
    BEQ fill_lower_solid                          ; &10F4
    DEX                                ; &10F6
    JMP clear_lower_mask_loop                          ; &10F7
fill_lower_solid:
    LDA #LANDSCAPE_MASK_SOLID            ; &10FA
fill_lower_solid_loop:
    STA landscape_mask,X                        ; &10FC
    CPX collision_lower_far                            ; &10FF
    BEQ write_lower_boundary                          ; &1101
    DEX                                ; &1103
    JMP fill_lower_solid_loop                          ; &1104
write_lower_boundary:
    LDA #LANDSCAPE_MASK_EDGE_BOTH        ; &1107
    STA landscape_mask,X                        ; &1109
    DEX                                ; &110C
    LDA lower_edge_direction                            ; &110D
    BNE lower_boundary_pattern_b                          ; &110F
    LDA #LANDSCAPE_MASK_EDGE_A           ; &1111
    JMP write_lower_slope_loop                          ; &1113
lower_boundary_pattern_b:
    LDA #LANDSCAPE_MASK_EDGE_B           ; &1116
write_lower_slope_loop:
    STA landscape_mask,X                        ; &1118
    CPX collision_lower_near                            ; &111B
    BCC clear_between_boundaries                          ; &111D
    DEX                                ; &111F
    JMP write_lower_slope_loop                          ; &1120
clear_between_boundaries:
    LDA #&00                           ; &1123
clear_middle_loop:
    STA landscape_mask,X                        ; &1125
    CPX collision_upper_far                            ; &1128
    BEQ write_upper_slope                          ; &112A
    DEX                                ; &112C
    JMP clear_middle_loop                          ; &112D
write_upper_slope:
    LDA collision_upper_direction                            ; &1130
    BNE upper_boundary_pattern_b                          ; &1132
    LDA #LANDSCAPE_MASK_EDGE_A           ; &1134
    JMP write_upper_slope_loop                          ; &1136
upper_boundary_pattern_b:
    LDA #LANDSCAPE_MASK_EDGE_B           ; &1139
write_upper_slope_loop:
    STA landscape_mask,X                        ; &113B
    CPX collision_upper_near                            ; &113E
    BEQ write_upper_boundary                          ; &1140
    DEX                                ; &1142
    JMP write_upper_slope_loop                          ; &1143
write_upper_boundary:
    LDA #LANDSCAPE_MASK_EDGE_BOTH        ; &1146
    STA landscape_mask,X                        ; &1148
    DEX                                ; &114B
    LDA #LANDSCAPE_MASK_SOLID            ; &114C
fill_upper_solid_loop:
    STA landscape_mask,X                        ; &114E
    CPX #&00                           ; &1151
    BEQ save_previous_edges                          ; &1153
    DEX                                ; &1155
    JMP fill_upper_solid_loop                          ; &1156
save_previous_edges:
    LDA current_upper_edge                            ; &1159
    STA previous_upper_edge                            ; &115B
    LDA current_lower_edge                            ; &115D
    STA previous_lower_edge                            ; &115F
    RTS                                ; &1161

; -----------------------------------------------------------------------------
; NEW GAME / RAID / LIFE INITIALISATION
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
new_game_init:
    LDA #VDU_SET_MODE                   ; &1162
    JSR oswrch                          ; &1164
    LDA #SCREEN_MODE_2                  ; &1167
    JSR oswrch                          ; &1169
    LDA #CRTC_CURSOR_DISABLED           ; &116C
    LDX #CRTC_CURSOR_START_REG          ; &116E
    JSR write_crtc_register            ; &1170
    LDX #CRTC_INTERLACE_DELAY_REG       ; &1173
    LDA #CRTC_INTERLACE_NORMAL          ; &1175
    JSR write_crtc_register            ; &1177
    LDA #STARTING_SPARES                           ; &117A
    STA player_lives_spares                            ; &117C  lives
    LDA #BYTE_FALSE                    ; &117E
    STA score_lo                            ; &1180  score_lo
    STA score_mid                            ; &1182  score_mid
    STA score_hi                            ; &1184  score_hi
    STA stage_bcd                            ; &1186  stage_bcd
    STA bonus_life_awarded                            ; &1188  bonus_life_awarded
    RTS                                ; &118A
new_raid_init:
next_stage_init:                       ; original/semantic alias
    LDA #RNG_INITIAL_SEED               ; &118B
    LDY #RNG_STATE_BYTE_COUNT-1         ; &118D
seed_rng_loop:
    STA rng_a_lo,Y                      ; &118F: seeds RNG A and RNG B
    DEY                                ; &1192
    BPL seed_rng_loop                          ; &1193
    LDA #>upper_section0_commands       ; &1195
    STA upper_shape_cmd_hi                            ; &1197
    LDA #<upper_section0_commands       ; &1199
    STA upper_shape_cmd_lo                            ; &119B
    LDA #>upper_section0_deltas         ; &119D
    STA upper_shape_delta_hi                            ; &119F
    LDA #<upper_section0_deltas         ; &11A1
    STA upper_shape_delta_lo                            ; &11A3
    LDA #>lower_cavern_commands       ; &11A5
    STA lower_shape_cmd_hi                            ; &11A7
    LDA #<lower_cavern_commands       ; &11A9
    STA lower_shape_cmd_lo                            ; &11AB
    LDA #>lower_cavern_deltas         ; &11AD
    STA lower_shape_delta_hi                            ; &11AF
    LDA #<lower_cavern_deltas         ; &11B1
    STA lower_shape_delta_lo                            ; &11B3
    SED                                ; &11B5
    CLC                                ; &11B6
    LDA stage_bcd                            ; &11B7  stage_bcd
    ADC #BCD_ONE                        ; &11B9: increment displayed raid number
    STA stage_bcd                            ; &11BB  stage_bcd
    CLD                                ; &11BD
    LDA #BYTE_FALSE                    ; &11BE
    STA landscape_object_index                            ; &11C0
    STA section_index                            ; &11C2  current_section
    STA joystick_fire_state                            ; &11C4
    JMP setup_section_environment                          ; &11C6
new_life_init:
    JSR flush_input_and_quiet_sound              ; &11C9
    LDA #FUEL_MAX_HI                    ; &11CC
    STA fuel_high                     ; &11CE
    LDA #FUEL_MAX_LO                    ; &11D0
    STA fuel_low                      ; &11D2
    LDA #FUEL_TICK_FRAMES               ; &11D4
    STA fuel_tick_divider             ; &11D6
    JSR player_screen_setup            ; &11D8
    LDY #PALETTE_ENTRY_COUNT-1          ; &11DB
restore_palette_loop:
    LDA initial_palette_table,Y          ; &11DD
    JSR set_palette                    ; &11E0
    DEY                                ; &11E3
    BPL restore_palette_loop                          ; &11E4
    LDA #BYTE_FALSE                    ; &11E6
    STA missile_update_phase                            ; &11E8
    STA phizzer_update_phase                            ; &11EA
    STA meteorite_update_phase                            ; &11EC
    STA bomb_cooldown                            ; &11EE
    STA bullet_cooldown                            ; &11F0
    STA out_of_fuel_flag                            ; &11F2
    LDY #OBJECT_LAST_SLOT               ; &11F4: clear all 20 object slots
clear_object_slots_loop:
    STA object_screen_lo,Y                        ; &11F6
    STA object_screen_hi,Y                        ; &11F9
    STA object_prev_screen_lo,Y                        ; &11FC
    STA object_prev_screen_hi,Y                        ; &11FF
    STA object_y_table,Y                        ; &1202  object_y_table
    STA object_x_table,Y                        ; &1205  object_x_table
    DEY                                ; &1208
    BPL clear_object_slots_loop                          ; &1209
    STA bomb_phase_table                            ; &120B
    STA unused_life_state_3c                 ; &120D
    STA upper_run_remaining                            ; &120F
    STA launched_missile_slot_a                            ; &1211
    STA launched_missile_slot_b                            ; &1213
    LDA saved_upper_cmd_lo                            ; &1215
    STA upper_shape_cmd_lo                            ; &1217
    LDA saved_upper_delta_lo                            ; &1219
    STA upper_shape_delta_lo                            ; &121B
    LDA saved_lower_cmd_lo                            ; &121D
    STA lower_shape_cmd_lo                            ; &121F
    LDA saved_lower_delta_lo                            ; &1221
    STA lower_shape_delta_lo                            ; &1223
    LDA saved_landscape_object_index                            ; &1225
    STA landscape_object_index                            ; &1227
    LDA saved_upper_cmd_hi                            ; &1229
    STA upper_shape_cmd_hi                            ; &122B
    LDA saved_upper_delta_hi                            ; &122D
    STA upper_shape_delta_hi                            ; &122F
    LDA saved_lower_cmd_hi                            ; &1231
    STA lower_shape_cmd_hi                            ; &1233
    LDA saved_lower_delta_hi                            ; &1235
    STA lower_shape_delta_hi                            ; &1237
    LDY #SCENERY_FIRST_SLOT             ; &1239: mark slots 0..9 inactive
    LDA #OBJECT_STATE_ACTIVE            ; &123B: pre-arm fixed slots; X=0 is the true inactive marker
mark_low_slots_inactive_loop:
    STA object_state_table,Y                        ; &123D  object_state_table
    DEY                                ; &1240
    BPL mark_low_slots_inactive_loop                          ; &1241
    LDA #SECTION_SPAWN_INITIAL_DELAY    ; &1243
    STA section_spawn_timer                            ; &1245
    LDA #DRAWABLE_X_MIN_COORD             ; &1247
    STA minimum_drawable_x              ; &1249
    LDY #RNG_STATE_BYTE_COUNT-1         ; &124B
restore_rng_loop:
    LDA saved_rng_state,Y                        ; &124D
    STA rng_a_lo,Y                      ; &1250
    DEY                                ; &1253
    BPL restore_rng_loop                          ; &1254
    LDA #PLAYER_START_X                 ; &1256
    STA object_x_table                          ; &1258  object_x_table
    LDA #PLAYER_START_Y                 ; &125B
    STA object_y_table                          ; &125D  object_y_table
    JSR build_landscape_collision_mask                          ; &1260
    JMP load_section_parameters                          ; &1263

; -----------------------------------------------------------------------------
; OBJECT ERASE/REDRAW, SLOT PROCESSING AND JOYSTICK CONTROL
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
erase_player_previous_and_current:
    LDA scroll_screen_hi                            ; &1266
    CLC                                ; &1268
    ADC #PLAYER_ERASE_SCREEN_PAGE_OFFSET_HI ; &1269
    STA work_ptr_hi                    ; &126B
    LDA scroll_screen_lo                            ; &126D
    STA work_ptr_lo                    ; &126F
    LDY #SCROLL_GUARD_LAST_Y          ; &1271
    LDA #&00                           ; &1273
clear_scroll_guard_loop:
    STA (work_ptr_lo),Y               ; &1275
    DEY                                ; &1277
    BPL clear_scroll_guard_loop                          ; &1278
    LDY #&00                           ; &127A
    LDA object_screen_hi                          ; &127C
    BEQ erase_player_previous_position                          ; &127F
    STA screen_ptr_hi                   ; &1281
    LDA object_screen_lo                          ; &1283
    STA screen_ptr_lo                   ; &1286
    JSR erase_object_by_type           ; &1288
erase_player_previous_position:
    LDA object_prev_screen_hi                          ; &128B
    BEQ erase_player_done                          ; &128E
    STA screen_ptr_hi                   ; &1290
    LDA object_prev_screen_lo                          ; &1292
    STA screen_ptr_lo                   ; &1295
    JMP erase_object_by_type           ; &1297
erase_player_done:
    RTS                                ; &129A
erase_dynamic_objects_and_projectiles:
    LDY #BOMB_FIRST_SLOT              ; &129B
erase_low_object_slots_loop:
    LDA object_state_table,Y                        ; &129D  object_state_table
    ASL A                              ; &12A0
    BMI next_low_object_slot                          ; &12A1
    ASL A                              ; &12A3
    BMI next_low_object_slot                          ; &12A4
    LDA object_screen_hi,Y                        ; &12A6
    BEQ erase_low_slot_previous_position                          ; &12A9
    STA screen_ptr_hi                   ; &12AB
    LDA object_screen_lo,Y                        ; &12AD
    STA screen_ptr_lo                   ; &12B0
    JSR erase_object_by_type           ; &12B2
erase_low_slot_previous_position:
    LDA object_prev_screen_hi,Y                        ; &12B5
    BEQ next_low_object_slot                          ; &12B8
    STA screen_ptr_hi                   ; &12BA
    LDA object_prev_screen_lo,Y                        ; &12BC
    STA screen_ptr_lo                   ; &12BF
    JSR erase_object_by_type           ; &12C1
next_low_object_slot:
    INY                                ; &12C4
    CPY #SCENERY_FIRST_SLOT            ; &12C5
    BNE erase_low_object_slots_loop                          ; &12C7
erase_scenery_slots_loop:
    LDA object_state_table,Y                        ; &12C9  object_state_table
    BPL next_scenery_slot                          ; &12CC
    ASL A                              ; &12CE
    BMI next_scenery_slot                          ; &12CF
    LDA object_prev_screen_hi,Y                        ; &12D1
    BEQ next_scenery_slot                          ; &12D4
    STA screen_ptr_hi                   ; &12D6
    LDA object_prev_screen_lo,Y                        ; &12D8
    STA screen_ptr_lo                   ; &12DB
    JSR erase_object_by_type           ; &12DD
next_scenery_slot:
    INY                                ; &12E0
    CPY #OBJECT_LAST_SLOT              ; &12E1
    BNE erase_scenery_slots_loop                          ; &12E3
    LDX #BULLET_SLOT_COUNT-1           ; &12E5
erase_bullet_slots_loop:
    LDY #&00                           ; &12E7
    LDA object_screen_hi+BULLET_FIRST_SLOT,X                        ; &12E9
    BEQ erase_bullet_previous_position                          ; &12EC
    STA screen_ptr_hi                   ; &12EE
    LDA object_screen_lo+BULLET_FIRST_SLOT,X                        ; &12F0
    STA screen_ptr_lo                   ; &12F3
    LDA #PROJECTILE_XOR_PATTERN        ; &12F5
    EOR (screen_ptr_lo),Y                        ; &12F7
    STA (screen_ptr_lo),Y                        ; &12F9
    INY                                ; &12FB
    LDA #PROJECTILE_XOR_PATTERN        ; &12FC
    EOR (screen_ptr_lo),Y                        ; &12FE
    STA (screen_ptr_lo),Y                        ; &1300
erase_bullet_previous_position:
    LDY #&00                           ; &1302
    LDA object_prev_screen_hi+BULLET_FIRST_SLOT,X                        ; &1304
    BEQ next_bullet_slot                          ; &1307
    STA screen_ptr_hi                   ; &1309
    LDA object_prev_screen_lo+BULLET_FIRST_SLOT,X                        ; &130B
    STA screen_ptr_lo                   ; &130E
    LDA #PROJECTILE_XOR_PATTERN        ; &1310
    EOR (screen_ptr_lo),Y                        ; &1312
    STA (screen_ptr_lo),Y                        ; &1314
    INY                                ; &1316
    LDA #PROJECTILE_XOR_PATTERN        ; &1317
    EOR (screen_ptr_lo),Y                        ; &1319
    STA (screen_ptr_lo),Y                        ; &131B
next_bullet_slot:
    DEX                                ; &131D
    BPL erase_bullet_slots_loop                          ; &131E
    RTS                                ; &1320
prepare_object_frame_and_spawn_hazards:
    LDA bonus_life_awarded                            ; &1321  bonus_life_awarded
    BPL snapshot_low_slot_positions                          ; &1323
    JSR update_extra_life_beeper       ; &1325
    LDA warning_beeps_left                            ; &1328
    BNE snapshot_low_slot_positions                          ; &132A
    LDA #BONUS_LIFE_AWARDED_DONE       ; &132C
    STA bonus_life_awarded                            ; &132E  bonus_life_awarded
snapshot_low_slot_positions:
    LDY #SCENERY_FIRST_SLOT            ; &1330
snapshot_low_slots_loop:
    LDA object_prev_screen_lo,Y                        ; &1332
    STA object_screen_lo,Y                        ; &1335
    LDA object_prev_screen_hi,Y                        ; &1338
    STA object_screen_hi,Y                        ; &133B
    DEY                                ; &133E
    BPL snapshot_low_slots_loop                          ; &133F
    LDY #OBJECT_LAST_SLOT              ; &1341
calculate_object_screen_positions_loop:
    STY object_scan_slot               ; &1343
    LDA object_state_table,Y                        ; &1345  object_state_table
    BPL next_object_screen_slot                          ; &1348
    ASL A                              ; &134A
    BMI next_object_screen_slot                          ; &134B
    LDA object_x_table,Y                        ; &134D  object_x_table
    TAX                                ; &1350
    LDA object_y_table,Y                        ; &1351  object_y_table
    TAY                                ; &1354
    JSR screen_address_from_xy                          ; &1355
    LDY object_scan_slot               ; &1358
    LDA screen_ptr_lo                   ; &135A
    STA object_prev_screen_lo,Y                        ; &135C
    LDA screen_ptr_hi                   ; &135F
    STA object_prev_screen_hi,Y                        ; &1361
next_object_screen_slot:
    DEY                                ; &1364
    BPL calculate_object_screen_positions_loop                          ; &1365
    DEC fuel_tick_divider             ; &1367
    BNE fuel_update_done                          ; &1369
    LDA #FUEL_TICK_FRAMES               ; &136B
    STA fuel_tick_divider             ; &136D
    LDA fuel_low                      ; &136F
    BNE decrement_fuel_low                          ; &1371
    DEC fuel_high                     ; &1373
decrement_fuel_low:
    DEC fuel_low                      ; &1375
    BNE fuel_update_done                          ; &1377
    LDA fuel_high                     ; &1379
    BNE fuel_update_done                          ; &137B
    LDA #BYTE_TRUE                      ; &137D: fuel exhausted
    STA out_of_fuel_flag              ; &137F
fuel_update_done:
    JMP spawn_section_hazards          ; &1381
read_joystick_controls:
    LDX #JOY_VERTICAL_CHANNEL           ; &1384
    JSR adval                          ; &1386
    CPY #JOY_LOW_THRESHOLD              ; &1389
    BCS joystick_check_up                          ; &138B
    JSR move_player_down               ; &138D
joystick_check_up:
    CPY #JOY_HIGH_THRESHOLD             ; &1390
    BCC joystick_horizontal_axis                          ; &1392
    JSR move_player_up                 ; &1394
joystick_horizontal_axis:
    LDX #JOY_HORIZONTAL_CHANNEL         ; &1397
    JSR adval                          ; &1399
    CPY #JOY_LOW_THRESHOLD              ; &139C
    BCS joystick_check_back                          ; &139E
    JSR move_player_forward            ; &13A0
joystick_check_back:
    CPY #JOY_HIGH_THRESHOLD             ; &13A3
    BCC joystick_fire_button                          ; &13A5
    JSR move_player_back               ; &13A7
joystick_fire_button:
    LDX #JOY_BUTTON_CHANNEL             ; &13AA
    JSR adval                          ; &13AC
    TXA                                ; &13AF
    AND #JOY_BUTTON_MASK                ; &13B0
    TAX                                ; &13B2
    PHP                                ; &13B3
    LDA joystick_fire_state                            ; &13B4
    STX joystick_fire_state                            ; &13B6
    PLP                                ; &13B8
    BEQ joystick_input_done                          ; &13B9
    EOR joystick_fire_state                            ; &13BB
    BEQ joystick_input_done                          ; &13BD
    JSR fire_bullet                    ; &13BF
    JSR drop_bomb                      ; &13C2
joystick_input_done:
    LDX #BYTE_TRUE                      ; &13C5
    JMP poll_bomb_key_state             ; &13C7: share keyboard edge/latch bookkeeping

; -----------------------------------------------------------------------------
; KEYBOARD CONTROL AND PLAYER MOVEMENT
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
read_keyboard_controls:
    LDA out_of_fuel_flag              ; &13CA
    BEQ select_control_method                          ; &13CC
    JMP move_player_down               ; &13CE
select_control_method:
    LDA joyflag                            ; &13D1  joyflag
    BNE read_joystick_controls         ; &13D3
    LDX #KEY_UP_A                       ; &13D5
    JSR inkey                          ; &13D7
    BEQ keyboard_check_down                          ; &13DA
    JSR move_player_up                 ; &13DC
keyboard_check_down:
    LDX #KEY_DOWN_Z                     ; &13DF
    JSR inkey                          ; &13E1
    BEQ keyboard_check_forward                          ; &13E4
    JSR move_player_down               ; &13E6
keyboard_check_forward:
    LDX #KEY_FORWARD_SHIFT              ; &13E9
    JSR inkey                          ; &13EB
    BEQ keyboard_check_back                          ; &13EE
    JSR move_player_forward            ; &13F0
keyboard_check_back:
    LDX #KEY_BACK_SPACE                 ; &13F3
    JSR inkey                          ; &13F5
    BEQ keyboard_bomb_cooldown                          ; &13F8
    JSR move_player_back               ; &13FA
keyboard_bomb_cooldown:
    LDA bomb_cooldown                            ; &13FD
    BEQ keyboard_poll_bomb                          ; &13FF
    DEC bomb_cooldown                            ; &1401
    BNE keyboard_fire_cooldown                          ; &1403
keyboard_poll_bomb:
    LDX #KEY_BOMB_TAB                   ; &1405
poll_bomb_key_state:
    JSR inkey                          ; &1407
    PHP                                ; &140A
    LDA last_bomb_key_state                            ; &140B
    STX last_bomb_key_state                            ; &140D
    PLP                                ; &140F
    BEQ keyboard_fire_cooldown                          ; &1410
    EOR last_bomb_key_state                            ; &1412
    BEQ keyboard_fire_cooldown                          ; &1414
    JSR drop_bomb                      ; &1416
keyboard_fire_cooldown:
    LDA bullet_cooldown                            ; &1419
    BEQ keyboard_poll_fire                          ; &141B
    DEC bullet_cooldown                            ; &141D
    BNE keyboard_controls_done                          ; &141F
keyboard_poll_fire:
    LDX #KEY_FIRE_RETURN                ; &1421
    JSR inkey                          ; &1423
    PHP                                ; &1426
    LDA last_fire_key_state                            ; &1427
    STX last_fire_key_state                            ; &1429
    PLP                                ; &142B
    BEQ keyboard_controls_done                          ; &142C
    EOR last_fire_key_state                            ; &142E
    BEQ keyboard_controls_done                          ; &1430
    JSR fire_bullet                    ; &1432
keyboard_controls_done:
    RTS                                ; &1435
move_player_up:
    INC object_y_table                          ; &1436  object_y_table
    INC object_y_table                          ; &1439  object_y_table
    LDX #PLAYER_Y_MAX                   ; &143C
    CPX object_y_table                          ; &143E  object_y_table
    BCS move_up_done                          ; &1441
    STX object_y_table                          ; &1443  object_y_table
move_up_done:
    RTS                                ; &1446
move_player_down:
    DEC object_y_table                          ; &1447  object_y_table
    DEC object_y_table                          ; &144A  object_y_table
    LDX #PLAYER_Y_MIN                   ; &144D
    CPX object_y_table                          ; &144F  object_y_table
    BCC move_down_done                          ; &1452
    STX object_y_table                          ; &1454  object_y_table
move_down_done:
    RTS                                ; &1457
move_player_back:
    DEC object_x_table                          ; &1458  object_x_table
    LDX #PLAYER_X_MIN                   ; &145B
    CPX object_x_table                          ; &145D  object_x_table
    BCC move_back_done                          ; &1460
    STX object_x_table                          ; &1462  object_x_table
move_back_done:
    RTS                                ; &1465
move_player_forward:
    INC object_x_table                          ; &1466  object_x_table
    LDX #PLAYER_X_MAX                   ; &1469
    CPX object_x_table                          ; &146B  object_x_table
    BCS move_forward_done                          ; &146E
    STX object_x_table                          ; &1470  object_x_table
move_forward_done:
    RTS                                ; &1473
pause_until_keypress:
    ; Orphaned/hidden DELETE pause helper.  No direct live caller has yet been found,
    ; so do not assume normal gameplay reaches it.  If entered, a held DELETE flushes
    ; the keyboard input buffer and OSRDCH blocks until the next key.
    LDX #KEY_PAUSE_DELETE               ; &1474
    JSR inkey                          ; &1476
    BEQ pause_helper_done                          ; &1479
    LDA #OSBYTE_FLUSH_BUFFER            ; &147B
    LDX #KEYBOARD_INPUT_BUFFER          ; &147D
    JSR osbyte                          ; &147F
    LDA #BYTE_TRUE                      ; &1482
    STA sysvia_ier                          ; &1484
    JSR osrdch                          ; &1487
pause_helper_done:
    RTS                                ; &148A

; -----------------------------------------------------------------------------
; PLAYER SETUP, COLLISION ENGINE AND OBJECT HIT PROCESSING
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
player_screen_setup:
    JSR black_out_palette              ; &148B
    LDA #SCROLL_INITIAL_HI              ; &148E
    STA scroll_screen_hi                            ; &1490
    LDA #SCROLL_INITIAL_LO              ; &1492
    STA scroll_screen_lo                            ; &1494
    LDA #UPPER_EDGE_INITIAL             ; &1496
    STA upper_edge_value                            ; &1498
    STA current_upper_edge                            ; &149A
    STA previous_upper_edge                            ; &149C
    LDA #BYTE_TRUE                      ; &149E: lower terrain disabled during prefill
    STA lower_run_remaining                            ; &14A0
prefill_screen_loop:
    JSR advance_scroll_position        ; &14A2
    LDA current_upper_edge                            ; &14A5
    EOR #TERRAIN_PREFILL_EDGE_TOGGLE ; &14A7
    STA current_upper_edge                            ; &14A9
    JSR build_landscape_collision_mask                          ; &14AB
    JSR copy_landscape_mask_to_screen                          ; &14AE
    JSR draw_fuel_gauge                          ; &14B1
    LDA scroll_screen_hi                            ; &14B4
    CMP #SCREEN_BASE_HI                 ; &14B6
    BNE prefill_screen_loop                          ; &14B8
    LDA scroll_screen_lo                            ; &14BA
    STA temp                            ; &14BC
    LDA scroll_screen_hi                            ; &14BE
    LSR A                              ; &14C0
    ROR temp                            ; &14C1
    LSR A                              ; &14C3
    ROR temp                            ; &14C4
    LSR A                              ; &14C6
    ROR temp                            ; &14C7
    LDX #CRTC_SCREEN_START_HI_REG       ; &14C9
    JSR write_crtc_register            ; &14CB
    LDX #CRTC_SCREEN_START_LO_REG       ; &14CE
    LDA temp                            ; &14D0
    JSR write_crtc_register            ; &14D2
    JSR draw_spare_lives_icons                          ; &14D5
    JSR draw_raid_number               ; &14D8
    JSR update_score_and_bonus_life    ; &14DB
    JMP wait_vsync                     ; &14DE
draw_spare_lives_icons:
    LDX #LIVES_BUFFER_CLEAR_LAST        ; &14E1
    LDA #BYTE_FALSE                    ; &14E3
clear_lives_buffer_loop:
    STA lives_buffer_base,X             ; &14E5 HUD/lives backing buffer
    DEX                                ; &14E8
    BPL clear_lives_buffer_loop                          ; &14E9
    LDA player_lives_spares                            ; &14EB  lives
    BEQ spare_lives_done                          ; &14ED
    CMP #LIFE_ICONS_MAX_DISPLAYED       ; &14EF
    BCC store_life_icon_count                          ; &14F1
    LDA #LIFE_ICONS_MAX_DISPLAYED       ; &14F3
store_life_icon_count:
    STA life_icons_to_draw              ; &14F5
    BEQ spare_lives_done                          ; &14F7
    LDA #<life_icon_draw_buffer        ; &14F9
    STA screen_ptr_lo                   ; &14FB
    LDA #>life_icon_draw_buffer        ; &14FD
    STA screen_ptr_hi                   ; &14FF
    LDA object_sprite_lo+TYPE_LIFE_ICON                          ; &1501
    STA render_sprite_ptr_lo             ; &1504
    LDA object_sprite_hi+TYPE_LIFE_ICON                          ; &1506
    STA render_sprite_ptr_hi             ; &1509
draw_next_life_icon:
    LDY #&00                           ; &150B
    LDX object_sprite_bytes+TYPE_LIFE_ICON                          ; &150D
copy_life_icon_byte:
    LDA (render_sprite_ptr_lo),Y                        ; &1510
    STA (screen_ptr_lo),Y                        ; &1512
    INY                                ; &1514
    DEX                                ; &1515
    BNE copy_life_icon_byte                          ; &1516
    TYA                                ; &1518
    CLC                                ; &1519
    ADC screen_ptr_lo                  ; &151A
    ADC #LIFE_ICON_SPACING_BYTES      ; &151C
    STA screen_ptr_lo                   ; &151E
    BCC advance_life_icon                          ; &1520
    INC screen_ptr_hi                  ; &1522
advance_life_icon:
    DEC life_icons_to_draw              ; &1524
    BNE draw_next_life_icon                          ; &1526
spare_lives_done:
    RTS                                ; &1528
; -----------------------------------------------------------------------------
; spawn_landscape_object / continue_landscape_object_stamp
; -----------------------------------------------------------------------------
; A fixed scenery object is considered only on an upper-terrain run whose
; post-decode scenery gate is zero.  The *next* object type in the global script
; supplies a trigger period from object_trigger_offset[type]; a spawn happens
; when upper_run_remaining MOD period = 0.
;
; The logical object is allocated immediately at X=&4F.  Independently, its
; sprite bytes are copied into the newly generated right-edge landscape mask one
; byte-column per frame.  This is why landscape_stamp_bytes_left prevents another
; scenery object from starting until the current sprite has been completely
; stamped.  The collision silhouette therefore scrolls in synchrony with the
; visible XOR-rendered object.
; -----------------------------------------------------------------------------
spawn_landscape_object:
    LDY landscape_object_index                            ; &1529
    INC landscape_object_index                            ; &152B
    LDA landscape_object_stream,Y                        ; &152D
    PHA                                ; &1530
    TAY                                ; &1531
    LDX #LANDSCAPE_OBJECT_ENTRY_X                  ; &1532
    LDA upper_terrain_profile+1                          ; &1534
    CLC                                ; &1537
    ADC object_height_pixels,Y                        ; &1538
    TAY                                ; &153B
    DEY                                ; &153C
    STY landscape_object_bottom                            ; &153D
    PLA                                ; &153F
    PHA                                ; &1540
    JSR allocate_object_slot           ; &1541
    PLA                                ; &1544
    TAY                                ; &1545
    LDA object_sprite_lo,Y                        ; &1546
    STA LANDSCAPE_STAMP_OPERAND_LO     ; &1549
    LDA object_sprite_hi,Y                        ; &154C
    STA LANDSCAPE_STAMP_OPERAND_HI     ; &154F
    LDA object_sprite_bytes,Y                        ; &1552
    STA landscape_stamp_bytes_left                            ; &1555
    LDA object_height_pixels,Y                        ; &1557
    STA landscape_stamp_height                            ; &155A
    LDX #BYTE_FALSE                     ; &155C
    STX landscape_stamp_src_index                            ; &155E
continue_landscape_object_stamp:
    LDX landscape_stamp_src_index                            ; &1560
    LDA landscape_stamp_height                            ; &1562
    STA render_scanlines_left           ; &1564
    LDY landscape_object_bottom                            ; &1566
stamp_landscape_sprite_byte:
landscape_stamp_sprite_fetch:          ; operand patched from selected scenery sprite address
    LDA SMC_ABSOLUTE_PLACEHOLDER,X     ; &1568
    INX                                ; &156B
    STA landscape_mask,Y                        ; &156C
    DEY                                ; &156F
    DEC landscape_stamp_bytes_left                            ; &1570
    DEC render_scanlines_left           ; &1572
    BNE stamp_landscape_sprite_byte                          ; &1574
    STX landscape_stamp_src_index                            ; &1576
    RTS                                ; &1578
collision_controller:
    LDA object_screen_hi                          ; &1579
    BNE prepare_player_collision_pattern                          ; &157C
    RTS                                ; &157E
prepare_player_collision_pattern:
    LDA object_sprite_lo                          ; &157F
    STA collision_pattern_ptr_lo        ; &1582
    LDA object_sprite_hi                          ; &1584
    STA collision_pattern_ptr_hi        ; &1587
    LDA object_prev_screen_lo                          ; &1589
    STA screen_ptr_lo                   ; &158C
    LDA object_prev_screen_hi                          ; &158E
    STA screen_ptr_hi                   ; &1591
    LDY #&00                           ; &1593
    STY collision_sprite_offset                            ; &1595
    JSR compare_player_collision_mask                          ; &1597
    LDY object_height_pixels                          ; &159A
    DEY                                ; &159D
    STY collision_sprite_offset                            ; &159E
    LDX object_x_table                          ; &15A0  object_x_table
    LDA object_y_table                          ; &15A3  object_y_table
    SEC                                ; &15A6
    SBC collision_sprite_offset                            ; &15A7
    TAY                                ; &15A9
    JSR screen_address_from_xy                          ; &15AA
    JSR compare_player_collision_mask                          ; &15AD
    LDA object_height_pixels                          ; &15B0
    LSR A                              ; &15B3
    STA collision_sprite_offset                            ; &15B4
    LDX object_x_table                          ; &15B6  object_x_table
    LDA object_y_table                          ; &15B9  object_y_table
    SEC                                ; &15BC
    SBC collision_sprite_offset                            ; &15BD
    TAY                                ; &15BF
    JSR screen_address_from_xy                          ; &15C0
    JSR compare_player_collision_mask                          ; &15C3
    LDA object_sprite_lo+TYPE_BOMB                          ; &15C6
    STA collision_pattern_ptr_lo        ; &15C9
    LDA object_sprite_hi+TYPE_BOMB                          ; &15CB
    STA collision_pattern_ptr_hi        ; &15CE
    LDX #BOMB_SLOT_COUNT-1             ; &15D0
    STX collision_projectile_slot                            ; &15D2
check_next_bomb_collision:
    LDA object_prev_screen_hi+BOMB_FIRST_SLOT,X                        ; &15D4
    BEQ next_bomb_collision_slot                          ; &15D7
    STA screen_ptr_hi                   ; &15D9
    LDA object_prev_screen_lo+BOMB_FIRST_SLOT,X                        ; &15DB
    PHA                                ; &15DE
    AND #MODE2_SCANLINE_MASK            ; &15DF
    STA collision_screen_scanline                            ; &15E1
    PLA                                ; &15E3
    AND #MODE2_SCANLINE_CLEAR_MASK      ; &15E4
    STA screen_ptr_lo                   ; &15E6
    LDA object_height_pixels+TYPE_BOMB                          ; &15E8
    STA temp                            ; &15EB
    JSR compare_collision_bytes                          ; &15ED
next_bomb_collision_slot:
    DEC collision_projectile_slot                            ; &15F0
    LDX collision_projectile_slot                            ; &15F2
    BPL check_next_bomb_collision                          ; &15F4
    LDA object_sprite_lo+TYPE_BULLET                          ; &15F6
    STA collision_pattern_ptr_lo        ; &15F9
    LDA object_sprite_hi+TYPE_BULLET                          ; &15FB
    STA collision_pattern_ptr_hi        ; &15FE
    LDX #BULLET_SLOT_COUNT-1           ; &1600
    STX collision_projectile_slot                            ; &1602
check_next_bullet_collision:
    LDA object_prev_screen_hi+BULLET_FIRST_SLOT,X                        ; &1604
    BEQ next_bullet_collision_slot                          ; &1607
    STA screen_ptr_hi                   ; &1609
    LDA object_prev_screen_lo+BULLET_FIRST_SLOT,X                        ; &160B
    PHA                                ; &160E
    AND #MODE2_SCANLINE_MASK            ; &160F
    STA collision_screen_scanline                            ; &1611
    PLA                                ; &1613
    AND #MODE2_SCANLINE_CLEAR_MASK      ; &1614
    STA screen_ptr_lo                   ; &1616
    LDA object_height_pixels+TYPE_BULLET                          ; &1618
    STA temp                            ; &161B
    JSR compare_collision_bytes                          ; &161D
next_bullet_collision_slot:
    DEC collision_projectile_slot                            ; &1620
    LDX collision_projectile_slot                            ; &1622
    BPL check_next_bullet_collision                          ; &1624
    RTS                                ; &1626
compare_collision_bytes:
    LDY #&00                           ; &1627
    STY collision_sprite_offset                            ; &1629
compare_collision_byte_loop:
    LDY collision_screen_scanline                            ; &162B
    LDA (&02),Y                        ; &162D
    LDY collision_sprite_offset                            ; &162F
    EOR (collision_pattern_ptr_lo),Y                        ; &1631
    STA collision_xor_result                            ; &1633
    BNE collision_byte_did_hit                          ; &1635
    JSR advance_collision_scan_row                          ; &1637
    INC collision_sprite_offset                            ; &163A
    LDY collision_sprite_offset                            ; &163C
    CPY temp                            ; &163E
    BNE compare_collision_byte_loop                          ; &1640
    RTS                                ; &1642
collision_byte_did_hit:
    LDA temp                            ; &1643
    CMP object_height_pixels+TYPE_BOMB                          ; &1645
    BNE collision_choose_projectile_y                          ; &1648
    LDA object_y_table+BOMB_FIRST_SLOT,X                        ; &164A
    STA collision_projectile_y                            ; &164D
    LDA bomb_slot_table,X                        ; &164F
    STA collision_projectile_x                            ; &1652
    LDA #BYTE_FALSE                    ; &1654
    STA bomb_slot_table,X                        ; &1656
    BEQ collision_check_projectile_overlap                          ; &1659
collision_choose_projectile_y:
    LDA object_y_table+BULLET_FIRST_SLOT,X                        ; &165B
    STA collision_projectile_y                            ; &165E
    LDA bullet_slot_table,X                        ; &1660
    STA collision_projectile_x                            ; &1663
    LDA #BYTE_FALSE                    ; &1665
    STA bullet_slot_table,X                        ; &1667
collision_check_projectile_overlap:
    LDA collision_xor_result                            ; &166A
    AND #COLLISION_SOLID_BITS           ; &166C
    BEQ terrain_impact                          ; &166E
    LDX #OBJECT_LAST_SLOT               ; &1670
scan_collision_objects:
    LDA object_x_table,X                        ; &1672  object_x_table
    BEQ next_collision_object                          ; &1675
    LDA collision_projectile_x                            ; &1677
    SEC                                ; &1679
    SBC object_x_table,X                        ; &167A  object_x_table
    CMP #PROJECTILE_HIT_X_TOLERANCE     ; &167D
    BCS next_collision_object                          ; &167F
    LDA object_y_table,X                        ; &1681  object_y_table
    SEC                                ; &1684
    SBC collision_projectile_y                            ; &1685
    JSR abs_a                          ; &1687
    CMP #PROJECTILE_HIT_Y_TOLERANCE     ; &168A
    BCC resolve_object_hit                          ; &168C
next_collision_object:
    DEX                                ; &168E
    CPX #COLLISION_LOWEST_OBJECT_SLOT-1 ; &168F: scan slots 19 down through 7
    BNE scan_collision_objects                          ; &1691
terrain_impact:
    LDA #SOUND_TERRAIN_IMPACT          ; &1693
    JMP play_sound_effect              ; &1695
resolve_object_hit:
; X = object slot that overlapped the player's projectile/collision probe.
; Behaviour is selected by object type:
;   type 2  -> FUEL TANK: refill fuel by &40 up to &0240 and redraw segments
;   type 5  -> MYSTERY TARGET: random one-of-four score award
;   type 3  -> FINAL BASE: completes the raid immediately
;   type 6  -> METEORITE: score table is zero; effectively a pure hazard
;   others  -> table-driven packed-BCD score, then SOUND_TARGET_DESTROYED
    JSR erase_and_remove_object                          ; &1698
    LDA object_type_table,X                        ; &169B  object_type_table
    PHA                                ; &169E
    CMP #TYPE_FUEL_TANK             ; &169F
    BNE check_mystery_target                          ; &16A1
    LDA fuel_low                            ; &16A3
    AND #MODE2_SCANLINE_CLEAR_MASK      ; &16A5: round fuel to gauge quantum
    STA fuel_low                            ; &16A7
    LDX #FUEL_REFILL_QUANTA             ; &16A9
fuel_refill_loop:
    LDA fuel_high                            ; &16AB
    CMP #FUEL_MAX_HI                    ; &16AD
    BNE draw_fuel_refill_quantum                          ; &16AF
    LDA fuel_low                            ; &16B1
    CMP #FUEL_MAX_LO                    ; &16B3
    BEQ check_final_base                          ; &16B5
draw_fuel_refill_quantum:
    LDA fuel_low                            ; &16B7
    AND #MODE2_SCANLINE_CLEAR_MASK      ; &16B9
    CLC                                ; &16BB
    ADC scroll_screen_lo                            ; &16BC
    STA collision_pattern_ptr_lo         ; &16BE
    LDA scroll_screen_hi                            ; &16C0
    ADC #SCREEN_PAGE_OFFSET_HI          ; &16C2
    ADC fuel_high                            ; &16C4
    BPL fuel_refill_pointer_ready                          ; &16C6
    SEC                                ; &16C8
    SBC #SCREEN_WRAP_HIGH_DELTA         ; &16C9
fuel_refill_pointer_ready:
    STA collision_pattern_ptr_hi         ; &16CB
    LDY #FUEL_TICK_FRAMES*2             ; &16CD: six gauge scanline bytes
    LDA #FUEL_GAUGE_FILL_PATTERN        ; &16CF
fuel_refill_draw_loop:
    STA (collision_pattern_ptr_lo),Y                        ; &16D1
    DEY                                ; &16D3
    BNE fuel_refill_draw_loop                          ; &16D4
    CLC                                ; &16D6
    LDA fuel_low                            ; &16D7
    ADC #FUEL_QUANTUM                   ; &16D9
    STA fuel_low                            ; &16DB
    LDA fuel_high                            ; &16DD
    ADC #&00                           ; &16DF
    STA fuel_high                            ; &16E1
    DEX                                ; &16E3
    BNE fuel_refill_loop                          ; &16E4
    JMP check_final_base                          ; &16E6
check_mystery_target:
    CMP #TYPE_MYSTERY_TARGET            ; &16E9
    BNE check_final_base                          ; &16EB
    PLA                                ; &16ED
    JSR read_rng_a                      ; &16EE
    AND #TERRAIN_JITTER_MASK            ; &16F1: choose one of 4 mystery awards
    TAY                                ; &16F3
    LDA special_score_mid,Y                        ; &16F4
    TAX                                ; &16F7
    LDA special_score_lo,Y                        ; &16F8
    JMP award_object_score                          ; &16FB
check_final_base:
    CMP #TYPE_FINAL_BASE           ; &16FE
    BNE score_normal_object                          ; &1700
    JMP raid_complete                  ; &1702
score_normal_object:
    PLA                                ; &1705
    TAY                                ; &1706
    LDA object_score_mid,Y                        ; &1707
    TAX                                ; &170A
    LDA object_score_lo,Y                        ; &170B
award_object_score:
    JSR add_score_bcd                  ; &170E
    LDA #SOUND_TARGET_DESTROYED        ; &1711
    JMP play_sound_effect              ; &1713
advance_collision_scan_row:
    LDA collision_screen_scanline                            ; &1716
    AND #MODE2_SCANLINE_MASK            ; &1718
    CMP #MODE2_SCANLINE_MASK            ; &171A
    BEQ collision_advance_char_row                          ; &171C
    INC collision_screen_scanline                            ; &171E
    RTS                                ; &1720
collision_advance_char_row:
    LDA #&00                           ; &1721
    STA collision_screen_scanline                            ; &1723
advance_collision_char_row_pointer:
    LDA screen_ptr_lo                   ; &1725
    CLC                                ; &1727
    ADC #MODE2_CHAR_ROW_STRIDE_LO       ; &1728
    STA screen_ptr_lo                   ; &172A
    LDA screen_ptr_hi                   ; &172C
    ADC #MODE2_CHAR_ROW_STRIDE_HI       ; &172E
    BPL collision_store_screen_hi                          ; &1730
    SEC                                ; &1732
    SBC #SCREEN_WRAP_HIGH_DELTA         ; &1733
collision_store_screen_hi:
    STA screen_ptr_hi                   ; &1735
    RTS                                ; &1737
compare_player_collision_mask:
compare_player_mask_loop:
    LDY collision_sprite_offset                            ; &1738
    LDA (collision_pattern_ptr_lo),Y  ; &173A
    LDY #&00                           ; &173C
    CMP (screen_ptr_lo),Y             ; &173E
    BNE player_destroyed               ; &1740
    JSR advance_collision_screen_ptr                          ; &1742
    LDY collision_sprite_offset                            ; &1745
    CPY object_sprite_bytes                          ; &1747
    BCC compare_player_mask_loop                          ; &174A
    RTS                                ; &174C

; -----------------------------------------------------------------------------
; PLAYER DEATH, BCD SCORING, EXTRA LIFE AND SCORE DISPLAY
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
player_destroyed:
    LDA object_prev_screen_lo                          ; &174D
    STA screen_ptr_lo                   ; &1750
    LDA object_prev_screen_hi                          ; &1752
    STA screen_ptr_hi                   ; &1755
    LDA #TYPE_PLAYER                    ; &1757
    JSR draw_object_by_type            ; &1759
    LDX object_x_table                          ; &175C  object_x_table
    DEX                                ; &175F
    LDY object_y_table                          ; &1760  object_y_table
    INY                                ; &1763
    INY                                ; &1764
    JSR screen_address_from_xy                          ; &1765
    LDA #TYPE_PLAYER_EXPLOSION          ; &1768
    JSR draw_object_by_type            ; &176A
    JSR flush_input_and_quiet_sound              ; &176D
    LDA #SOUND_PLAYER_DEATH             ; &1770
    JSR play_sound_effect              ; &1772
    LDX #PLAYER_DEATH_FLASH_FRAMES      ; &1775
death_flash_frame:
    SEI                                ; &1777
    JSR wait_vsync                     ; &1778
    CLI                                ; &177B
    LDY #LOGICAL_COLOUR_LAST            ; &177C
death_flash_colour_loop:
    JSR step_rng_b                          ; &177E
    AND #COLOUR_WHITE                   ; &1781: random physical colour 0..7
    JSR set_palette                    ; &1783
    DEY                                ; &1786
    BNE death_flash_colour_loop                          ; &1787
    DEX                                ; &1789
    BPL death_flash_frame                          ; &178A
finish_player_death:
    LDX saved_caller_sp                            ; &178C  saved_caller_sp
    TXS                                ; &178E
    DEC player_lives_spares                            ; &178F  lives
    BMI game_over_return               ; &1791
    JMP restart_life_entry             ; &1793: another spare remains; re-enter life setup through game entry
game_over_return:
    RTS                                ; &1796
advance_collision_screen_ptr:
    LDA collision_sprite_offset                            ; &1797
    CLC                                ; &1799
    ADC object_height_pixels                          ; &179A
    STA collision_sprite_offset                            ; &179D
    LDA screen_ptr_lo                   ; &179F
    CLC                                ; &17A1
    ADC #SCROLL_STEP_BYTES              ; &17A2
    STA screen_ptr_lo                   ; &17A4
    BCC collision_pointer_done                          ; &17A6
    INC screen_ptr_hi                   ; &17A8
    BPL collision_pointer_done                          ; &17AA
    LDA #SCREEN_BASE_HI                 ; &17AC
    STA screen_ptr_hi                   ; &17AE
collision_pointer_done:
    RTS                                ; &17B0
add_score_bcd:
    SED                                ; &17B1
    CLC                                ; &17B2
    ADC score_lo                            ; &17B3  score_lo
    STA score_lo                            ; &17B5  score_lo
    TXA                                ; &17B7
    ADC score_mid                            ; &17B8  score_mid
    STA score_mid                            ; &17BA  score_mid
    LDA score_hi                            ; &17BC  score_hi
    ADC #&00                           ; &17BE
    STA score_hi                            ; &17C0  score_hi
    CLD                                ; &17C2
update_score_and_bonus_life:
    LDA bonus_life_awarded                            ; &17C3  bonus_life_awarded
    BNE draw_score                          ; &17C5
    LDA score_hi                            ; &17C7  score_hi
    CMP #EXTRA_LIFE_SCORE_HI            ; &17C9
    BCC draw_score                          ; &17CB
    LDA score_mid                            ; &17CD  score_mid
    CMP #EXTRA_LIFE_SCORE_MID           ; &17CF
    BCC draw_score                          ; &17D1
    INC player_lives_spares                            ; &17D3  lives
    JSR draw_spare_lives_icons                          ; &17D5
    LDA #BONUS_LIFE_BEEPER_ACTIVE      ; &17D8
    STA bonus_life_awarded                            ; &17DA  bonus_life_awarded
    JSR start_extra_life_beeper           ; &17DC
draw_score:
    LDA #<score_display_buffer         ; &17DF
    STA score_draw_ptr_lo               ; &17E1
    LDA #>score_display_buffer         ; &17E3
    STA score_draw_ptr_hi               ; &17E5
    LDA #BCD_LEADING_DOTS_FLAG          ; &17E7
    STA score_leading_zero_flag                            ; &17E9
    LDA score_hi                            ; &17EB  score_hi
    JSR print_bcd_byte                 ; &17ED
    LDA score_mid                            ; &17F0  score_mid
    JSR print_bcd_byte                 ; &17F2
    LDA #BYTE_FALSE                    ; &17F5
    STA score_leading_zero_flag                            ; &17F7
    LDA score_lo                            ; &17F9  score_lo
getdigits:                              ; ORIGINAL author symbol recovered from source residue
print_bcd_byte:
    PHA                                ; &17FB
    AND #BCD_HIGH_NIBBLE_MASK          ; &17FC
    JSR print_score_digit              ; &17FE
    PLA                                ; &1801
    ASL A                              ; &1802
    ASL A                              ; &1803
    ASL A                              ; &1804
    ASL A                              ; &1805
print_score_digit:
    BNE score_digit_zero                          ; &1806
    LDA score_leading_zero_flag                            ; &1808
    BNE score_digit_blank_pattern                          ; &180A
score_digit_zero:
    LDY #&00                           ; &180C
    STY score_leading_zero_flag                            ; &180E
score_digit_render_start:
    LDY #&00                           ; &1810
    TAX                                ; &1812
score_digit_copy_loop:
    LDA score_digit_font,X                        ; &1813
    STA (score_draw_ptr_lo),Y          ; &1816
    INC score_draw_ptr_lo               ; &1818
    BNE score_digit_next_column                          ; &181A
    INC score_draw_ptr_hi               ; &181C
    BPL score_digit_next_column                          ; &181E
    LDA score_draw_ptr_hi               ; &1820
    SEC                                ; &1822
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &1823
    STA score_draw_ptr_hi               ; &1825
score_digit_next_column:
    INX                                ; &1827
    TXA                                ; &1828
    AND #BCD_LOW_NIBBLE_MASK           ; &1829
    BNE score_digit_copy_loop                          ; &182B
    RTS                                ; &182D
score_digit_blank_pattern:
    LDA #SCORE_LEADING_BLANK_PATTERN  ; &182E
    BNE score_digit_render_start                          ; &1830
draw_raid_number:
    LDA #<raid_display_buffer          ; &1832
    STA score_draw_ptr_lo               ; &1834
    LDA #>raid_display_buffer          ; &1836
    STA score_draw_ptr_hi               ; &1838
    LDA #BCD_LEADING_DOTS_FLAG          ; &183A
    STA score_leading_zero_flag                            ; &183C
    LDA stage_bcd                            ; &183E  stage_bcd
    JMP print_bcd_byte                 ; &1840
; -----------------------------------------------------------------------------
; STATIC HUD COPY + FUEL GAUGE (&1843-&1906)
; -----------------------------------------------------------------------------
; Two self-modifying copy loops transfer the fixed HUD artwork from &21D0 and
; &2220 into the circular MODE 2 screen.  &18A7 then redraws the live fuel gauge.
; The operand high bytes at &186E and &18A0 are deliberately modified as the
; destination crosses a 256-byte page; when the BBC screen wraps above &7FFF,
; the code remaps it to &3000 by substituting high byte &30.
copy_hud_upper_strip:
    LDA scroll_screen_lo               ; &1843
    CLC                                ; &1845
    ADC #HUD_UPPER_SCROLL_OFFSET_LO    ; &1846
    TAY                                ; &1848
    LDA scroll_screen_hi               ; &1849
    ADC #HUD_UPPER_SCROLL_OFFSET_HI    ; &184B
    BPL hud_upper_wrap_store                          ; &184D
    SEC                                ; &184F
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &1850
hud_upper_wrap_store:
    STA HUD_UPPER_STORE_HI_OPERAND     ; &1852 self-modifies STA destination high byte
    LDX #HUD_UPPER_X_START             ; &1855
    JMP hud_upper_copy_loop                          ; &1857
hud_upper_copy_row:
    LDY #&00                           ; &185A
    INC HUD_UPPER_STORE_HI_OPERAND     ; &185C
    BPL hud_upper_next_byte                          ; &185F
    LDA #SCREEN_BASE_HI                ; &1861 screen wrap -> screen base page
    STA HUD_UPPER_STORE_HI_OPERAND     ; &1863
    JMP hud_upper_next_byte                          ; &1866
hud_upper_copy_loop:
    LDA HUD_UPPER_SOURCE_BASE,X         ; &1869 indexed bias resolves to score/HUD backing data
hud_upper_store_instruction:
    STA SMC_PAGE_PLACEHOLDER,Y         ; &186C destination high byte is self-modified
    INY                                ; &186F
    BEQ hud_upper_copy_row                          ; &1870
hud_upper_next_byte:
    INX                                ; &1872
    BNE hud_upper_copy_loop                          ; &1873

copy_hud_lower_strip:
    LDA scroll_screen_lo               ; &1875
    CLC                                ; &1877
    ADC #HUD_LOWER_SCROLL_OFFSET_LO    ; &1878
    TAY                                ; &187A
    LDA scroll_screen_hi               ; &187B
    ADC #HUD_LOWER_SCROLL_OFFSET_HI    ; &187D
    BPL hud_lower_wrap_store                          ; &187F
    SEC                                ; &1881
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &1882
hud_lower_wrap_store:
    STA HUD_LOWER_STORE_HI_OPERAND     ; &1884 self-modifies STA destination high byte
    LDX #HUD_LOWER_X_START             ; &1887
    JMP hud_lower_copy_loop                          ; &1889
hud_lower_copy_row:
    LDY #&00                           ; &188C
    INC HUD_LOWER_STORE_HI_OPERAND     ; &188E
    BPL hud_lower_next_byte                          ; &1891
    LDA #SCREEN_BASE_HI                ; &1893 screen wrap -> &3000
    STA HUD_LOWER_STORE_HI_OPERAND     ; &1895
    JMP hud_lower_next_byte                          ; &1898
hud_lower_copy_loop:
    LDA HUD_LOWER_SOURCE_BASE,X         ; &189B indexed bias resolves to lives/lower HUD backing data
hud_lower_store_instruction:
    STA SMC_PAGE_PLACEHOLDER,Y         ; &189E destination high byte is self-modified
    INY                                ; &18A1
    BEQ hud_lower_copy_row                          ; &18A2
hud_lower_next_byte:
    INX                                ; &18A4
    BNE hud_lower_copy_loop                          ; &18A5

draw_fuel_gauge:
; fuel = fuel_high:fuel_low.  The low byte is quantised to 8-unit steps.
; Each visible segment is six scanline bytes of &2D.  The routine also redraws
; the fixed gauge border/marker bytes below it.
    LDA fuel_high                      ; &18A7
    BMI draw_fuel_gauge_frame                          ; &18A9
    LDA fuel_low                       ; &18AB
    AND #MODE2_SCANLINE_CLEAR_MASK     ; &18AD
    CLC                                ; &18AF
    ADC scroll_screen_lo               ; &18B0
    STA fuel_gauge_ptr_lo         ; &18B2
    LDA scroll_screen_hi               ; &18B4
    ADC #SCREEN_PAGE_OFFSET_HI         ; &18B6
    ADC fuel_high                      ; &18B8
    BPL fuel_fill_pointer_ready                          ; &18BA
    SEC                                ; &18BC
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &18BD
fuel_fill_pointer_ready:
    STA fuel_gauge_ptr_hi         ; &18BF
    LDY #FUEL_GAUGE_FILL_SCANLINES     ; &18C1
    LDA #FUEL_GAUGE_FILL_PATTERN       ; &18C3 gauge fill pattern
fuel_fill_loop:
    STA (fuel_gauge_ptr_lo),Y                        ; &18C5
    DEY                                ; &18C7
    BNE fuel_fill_loop                          ; &18C8
draw_fuel_gauge_frame:
    LDA scroll_screen_lo               ; &18CA
    CLC                                ; &18CC
    ADC #FUEL_GAUGE_BODY_OFFSET_LO     ; &18CD
    STA fuel_gauge_ptr_lo         ; &18CF
mpz:                                    ; probable ORIGINAL label from surviving source fragment
    LDA scroll_screen_hi               ; &18D1  original source: LDAtop+1
    ADC #FUEL_GAUGE_PAGE_OFFSET_HI     ; &18D3  original source: ADC#`gaugesiz
    BPL fuel_frame_pointer_ready                          ; &18D5
    SEC                                ; &18D7
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &18D8
fuel_frame_pointer_ready:
    STA fuel_gauge_ptr_hi         ; &18DA
    LDY #FUEL_GAUGE_BORDER_LAST_Y      ; &18DC
    LDA #FUEL_GAUGE_BORDER_PATTERN     ; &18DE
fuel_frame_loop:
    STA (fuel_gauge_ptr_lo),Y                        ; &18E0
    LDA #FUEL_GAUGE_EDGE_PATTERN       ; &18E2
    DEY                                ; &18E4
    BNE fuel_frame_loop                          ; &18E5
    LDA #FUEL_GAUGE_BORDER_PATTERN     ; &18E7
    STA (fuel_gauge_ptr_lo),Y                        ; &18E9
    LDA scroll_screen_lo               ; &18EB
    CLC                                ; &18ED
    ADC #FUEL_GAUGE_MARKER_OFFSET_LO   ; &18EE
    STA fuel_gauge_ptr_lo         ; &18F0
    LDA scroll_screen_hi               ; &18F2
    ADC #FUEL_GAUGE_PAGE_OFFSET_HI     ; &18F4
    BPL fuel_marker_pointer_ready                          ; &18F6
    SEC                                ; &18F8
    SBC #SCREEN_WRAP_HIGH_DELTA        ; &18F9
fuel_marker_pointer_ready:
    STA fuel_gauge_ptr_hi         ; &18FB
    LDY #FUEL_GAUGE_CLEAR_SCANLINES    ; &18FD
    LDA #BYTE_FALSE                    ; &18FF
fuel_marker_clear_loop:
    STA (fuel_gauge_ptr_lo),Y                        ; &1901
    DEY                                ; &1903
    BNE fuel_marker_clear_loop                          ; &1904
    RTS                                ; &1906

; -----------------------------------------------------------------------------
; &1907 DROP BOMB / &1938 FIRE BULLET
; Bomb creation uses two fixed object slots (types 10); bullet creation uses four
; fixed slots (types 9).
; MOD: bomb cooldown at &192E is &06 frames; bullet cooldown at &195B is &01.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; PROJECTILES, SECTION HAZARDS, ACTIVE OBJECT UPDATE AND RAID COMPLETE CODE
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
drop_bomb:
    LDY #BOMB_SLOT_COUNT-1             ; &1907
    LDA bomb_slot_table,Y                        ; &1909
    BEQ find_free_bomb_slot_loop                          ; &190C
    DEY                                ; &190E
    LDA bomb_slot_table,Y                        ; &190F
    BNE drop_bomb_done                          ; &1912
find_free_bomb_slot_loop:
    LDA object_x_table                          ; &1914  object_x_table
    CLC                                ; &1917
    ADC #BOMB_SPAWN_X_OFFSET           ; &1918
    STA bomb_slot_table,Y                        ; &191A
    LDA object_y_table                          ; &191D  object_y_table
    SEC                                ; &1920
    SBC object_height_pixels                          ; &1921
    SBC #BOMB_SPAWN_Y_GAP              ; &1924
    STA object_y_table+BOMB_FIRST_SLOT,Y                        ; &1926
    LDA #BOMB_INITIAL_VELOCITY         ; &1929
    STA bomb_velocity_table,Y          ; &192B
    LDA #BOMB_COOLDOWN_FRAMES                           ; &192E
    STA bomb_cooldown                            ; &1930
    LDA #SOUND_DROP_BOMB               ; &1932
    JMP play_sound_effect              ; &1934
drop_bomb_done:
    RTS                                ; &1937
fire_bullet:
    LDY #BULLET_SLOT_COUNT-1           ; &1938
find_free_bullet_slot_loop:
    LDA bullet_slot_table,Y                        ; &193A
    BEQ create_bullet                          ; &193D
    DEY                                ; &193F
    BPL find_free_bullet_slot_loop                          ; &1940
    RTS                                ; &1942
create_bullet:
    LDA object_x_table                          ; &1943  object_x_table
    CLC                                ; &1946
    ADC object_trigger_offset                          ; &1947
    STA bullet_slot_table,Y                        ; &194A
    LDA object_y_table                          ; &194D  object_y_table
    SEC                                ; &1950
    SBC #BULLET_SPAWN_Y_OFFSET                           ; &1951
    STA object_y_table+BULLET_FIRST_SLOT,Y                        ; &1953
    LDA #BULLET_STATE_INITIAL                           ; &1956
    STA object_state_table+BULLET_FIRST_SLOT,Y                        ; &1958
    LDA #BULLET_COOLDOWN_FRAMES                           ; &195B
    STA bullet_cooldown                            ; &195D
    LDA #SOUND_FIRE_BULLET             ; &195F
    JMP play_sound_effect              ; &1961
spawn_section_hazards:
; Section-specific object generator. section_index is the six-state terrain
; phase recovered in Stage 7:
;   0 FUEL DEPOT/MOUNTAINS -> stationary missiles may launch (type 1 -> 12)
;   1 CAVERN               -> Phizzers (type 4) spawn on a 32-step Y path
;   2 METEORITES           -> type 6 hazards enter rapidly from the right
;   3 SKYSCRAPERS          -> missiles may launch again
;   4 MAZE                 -> no extra spawned enemy; terrain is the hazard
;   5 FINAL BASE           -> falls through to missile-launch behaviour
; This dispatch is one of the strongest confirmations of the object identities.
;
; section_index dispatches between four
; spawn behaviours.  Confirmed event sounds from these paths:
;   sound 3  - TYPE_GROUND_MISSILE transforms into TYPE_LAUNCHED_MISSILE
;   sound 4  - TYPE_PHIZZER spawn event
;   sound 5  - TYPE_METEORITE spawn event
; MOD: changing the AND masks at &198D/&19D2/&19E7 changes spawn frequency.
    LDY section_index                            ; &1964  current_section
    BEQ scan_ground_missiles_from_end                          ; &1966
    DEY                                ; &1968
    BEQ phizzer_spawn_timer                          ; &1969
    DEY                                ; &196B
    BEQ spawn_meteorite_attempt                          ; &196C
    DEY                                ; &196E
    DEY                                ; &196F
    BEQ missile_launch_done                          ; &1970
scan_ground_missiles_from_end:
    LDY #OBJECT_LAST_SLOT                           ; &1972
missile_launch_scan_loop:
    LDA object_type_table,Y                        ; &1974  object_type_table
    CMP #TYPE_GROUND_MISSILE            ; &1977
    BNE missile_launch_next_slot                          ; &1979
    LDA object_x_table,Y                        ; &197B  object_x_table
    BEQ missile_launch_next_slot                          ; &197E
    CMP #MISSILE_LAUNCH_X_THRESHOLD                           ; &1980
    BCC try_launch_ground_missile                          ; &1982
missile_launch_next_slot:
    DEY                                ; &1984
    CPY #DYNAMIC_HAZARD_SLOT_1                           ; &1985
    BNE missile_launch_scan_loop                          ; &1987
missile_launch_done:
    RTS                                ; &1989
try_launch_ground_missile:
    JSR read_rng_a                      ; &198A
    AND #HAZARD_RANDOM_MASK                           ; &198D
    BNE missile_launch_next_slot                          ; &198F
    LDA #OBJECT_STATE_ACTIVE_SUPPRESSED               ; &1991: launched missile active but initially frame-suppressed
    STA object_state_table,Y                        ; &1993  object_state_table
    LDA #TYPE_LAUNCHED_MISSILE            ; &1996
    STA object_type_table,Y                        ; &1998  object_type_table
    TYA                                ; &199B
    LDX launched_missile_slot_a                            ; &199C
    BNE record_second_launched_missile                          ; &199E
    STA launched_missile_slot_a                            ; &19A0
    JMP activate_launched_missile                          ; &19A2
record_second_launched_missile:
    STA launched_missile_slot_b                            ; &19A5
activate_launched_missile:
    TAX                                ; &19A7
    INC object_x_table,X                        ; &19A8  object_x_table
    LDA #SOUND_MISSILE_LAUNCH          ; &19AB
    JMP play_sound_effect              ; &19AD
phizzer_spawn_timer:
    DEC section_spawn_timer                            ; &19B0
    BNE section_hazards_done                          ; &19B2
    LDX object_x_table+DYNAMIC_HAZARD_SLOT_1                          ; &19B4
    BNE try_spawn_phizzer                          ; &19B7
    LDX object_x_table+DYNAMIC_HAZARD_SLOT_0                          ; &19B9
    BNE try_spawn_phizzer                          ; &19BC
    LDA #SOUND_PHIZZER_SPAWN           ; &19BE
    JSR play_sound_effect              ; &19C0
try_spawn_phizzer:
    LDY #DYNAMIC_HAZARD_SLOT_1                           ; &19C3
    LDA object_x_table,Y                        ; &19C5  object_x_table
    BEQ set_phizzer_respawn                          ; &19C8
    DEY                                ; &19CA
set_phizzer_respawn:
    LDA #PHIZZER_RESPAWN_FRAMES                           ; &19CB
    STA section_spawn_timer                            ; &19CD
    JSR read_rng_a                      ; &19CF
    AND #PHIZZER_PATH_MASK                           ; &19D2
    ORA #OBJECT_STATE_FRAME_SUPPRESSED                           ; &19D4
    STA object_state_table,Y                        ; &19D6  object_state_table
    LDA #HAZARD_ENTRY_X                           ; &19D9
    STA object_x_table,Y                        ; &19DB  object_x_table
    LDA #TYPE_PHIZZER           ; &19DE
    STA object_type_table,Y                        ; &19E0  object_type_table
section_hazards_done:
    RTS                                ; &19E3
spawn_meteorite_attempt:
    JSR step_rng_b                          ; &19E4
    AND #HAZARD_RANDOM_MASK                           ; &19E7
    BNE meteorite_spawn_done           ; &19E9
    LDY #DYNAMIC_HAZARD_SLOT_1                           ; &19EB
    LDA object_x_table,Y                        ; &19ED  object_x_table
    BEQ choose_meteorite_y                          ; &19F0
    DEY                                ; &19F2
    LDA object_x_table,Y                        ; &19F3  object_x_table
    BNE meteorite_spawn_done           ; &19F6
choose_meteorite_y:
    JSR step_rng_b                          ; &19F8
    AND #METEORITE_Y_RANDOM_MASK                           ; &19FB
    CLC                                ; &19FD
    ADC #METEORITE_Y_BASE                           ; &19FE
    STA object_y_table,Y                        ; &1A00  object_y_table
    LDA #OBJECT_STATE_FRAME_SUPPRESSED                           ; &1A03
    STA object_state_table,Y                        ; &1A05  object_state_table
    LDA #HAZARD_ENTRY_X                           ; &1A08
    STA object_x_table,Y                        ; &1A0A  object_x_table
    LDA #TYPE_METEORITE             ; &1A0D
    STA object_type_table,Y                        ; &1A0F  object_type_table
    LDA #SOUND_METEORITE_SPAWN         ; &1A12
    JMP play_sound_effect              ; &1A14
meteorite_spawn_done:
    RTS                                ; &1A17
update_active_objects:
    LDX #BOMB_SLOT_COUNT-1             ; &1A18
update_bombs_loop:
    LDA bomb_slot_table,X                        ; &1A1A
    BEQ next_bomb_update                          ; &1A1D
    LDA bomb_phase_table,X                          ; &1A1F
    EOR #BYTE_INVERT_MASK             ; &1A21: toggle bomb phase 00<->FF
    STA bomb_phase_table,X                          ; &1A23
    BEQ update_bomb_position                          ; &1A25
    INC bomb_slot_table,X                        ; &1A27
update_bomb_position:
    LDA object_y_table+BOMB_FIRST_SLOT,X                        ; &1A2A
    TAY                                ; &1A2D
    LDA bomb_velocity_table,X                          ; &1A2E
    LSR A                              ; &1A30
    LSR A                              ; &1A31
    LSR A                              ; &1A32
    LSR A                              ; &1A33
    STA temp                            ; &1A34
    TYA                                ; &1A36
    SEC                                ; &1A37
    SBC temp                            ; &1A38
    STA object_y_table+BOMB_FIRST_SLOT,X                        ; &1A3A
    INC bomb_velocity_table,X                          ; &1A3D
    LDA object_y_table+BOMB_FIRST_SLOT,X                        ; &1A3F
    CMP #BOMB_DESPAWN_Y                           ; &1A42
    BCC next_bomb_update                          ; &1A44
    LDA #BYTE_FALSE                    ; &1A46
    STA bomb_slot_table,X                        ; &1A48
next_bomb_update:
    DEX                                ; &1A4B
    BPL update_bombs_loop                          ; &1A4C
    LDA bomb_slot_table                          ; &1A4E
    BNE update_bullets_start                          ; &1A51
    LDA object_x_table+BOMB_FIRST_SLOT+1                          ; &1A53
    BNE update_bullets_start                          ; &1A56
    LDA #SOUND_QUIET_CHANNEL_2         ; &1A58: no active bombs -> silence/flush channel 2
    JSR play_sound_effect              ; &1A5A
update_bullets_start:
    LDX #BULLET_SLOT_COUNT-1           ; &1A5D
update_bullets_loop:
    LDA bullet_slot_table,X                        ; &1A5F
    BEQ next_bullet_update                          ; &1A62
    INC bullet_slot_table,X                        ; &1A64
    INC bullet_slot_table,X                        ; &1A67
    CMP #BULLET_DESPAWN_X                           ; &1A6A
    BCC next_bullet_update                          ; &1A6C
    LDA #BYTE_FALSE                    ; &1A6E
    STA bullet_slot_table,X                        ; &1A70
next_bullet_update:
    DEX                                ; &1A73
    BPL update_bullets_loop                          ; &1A74
    ; Both tracked launched missiles are kept active, but bit 6 suppresses both
    ; before one slot is selected this frame.  `missile_update_phase` alternates
    ; the selected slot, so with two missiles each missile moves/draws every other
    ; frame while still remaining logically alive in its object slot.
    LDY #1                             ; &1A76: two missile-tracking slots, indices 1 then 0
    LDA #OBJECT_STATE_ACTIVE_SUPPRESSED               ; &1A78: pre-arm both tracked missiles, suppress this frame
update_section_objects_loop:
    LDX launched_missile_slot_a,Y                          ; &1A7A
    BEQ next_section_object                          ; &1A7C
    STA object_state_table,X                        ; &1A7E  object_state_table
next_section_object:
    DEY                                ; &1A81
    BPL update_section_objects_loop                          ; &1A82
    LDX launched_missile_slot_b                            ; &1A84
    LDA missile_update_phase                            ; &1A86
    EOR #OBJECT_STATE_FRAME_SUPPRESSED             ; &1A88
    STA missile_update_phase                            ; &1A8A
    BEQ missile_still_on_screen                          ; &1A8C
    LDX launched_missile_slot_a                            ; &1A8E
missile_still_on_screen:
    CPX #&00                           ; &1A90
    BEQ update_dynamic_hazard_1                          ; &1A92
    LDA #OBJECT_STATE_ACTIVE                           ; &1A94
    STA object_state_table,X                        ; &1A96  object_state_table
    LDA object_y_table,X                        ; &1A99  object_y_table
    CLC                                ; &1A9C
    ADC #LAUNCHED_MISSILE_Y_STEP       ; &1A9D
    STA object_y_table,X                        ; &1A9F  object_y_table
    CMP #BOMB_DESPAWN_Y                ; &1AA2: same lower screen threshold
    BCC update_dynamic_hazard_1                          ; &1AA4
    JSR erase_and_remove_object                          ; &1AA6
update_dynamic_hazard_1:
    ; Dynamic slots 7/8 are similarly time-sliced.  Both are first marked
    ; frame-suppressed; the Phizzer phase chooses which path index/Y is advanced.
    LDA object_state_table+DYNAMIC_HAZARD_SLOT_1                          ; &1AA9
    ORA #OBJECT_STATE_FRAME_SUPPRESSED             ; &1AAC
    STA object_state_table+DYNAMIC_HAZARD_SLOT_1                          ; &1AAE
    LDA object_state_table+DYNAMIC_HAZARD_SLOT_0                          ; &1AB1
    ORA #OBJECT_STATE_FRAME_SUPPRESSED             ; &1AB4
    STA object_state_table+DYNAMIC_HAZARD_SLOT_0                          ; &1AB6
    LDX #DYNAMIC_HAZARD_SLOT_1                           ; &1AB9
    LDA phizzer_update_phase                            ; &1ABB
    EOR #OBJECT_STATE_FRAME_SUPPRESSED                           ; &1ABD
    STA phizzer_update_phase                            ; &1ABF
    BEQ update_dynamic_object_by_type                          ; &1AC1
    DEX                                ; &1AC3
update_dynamic_object_by_type:
    LDA object_type_table,X                        ; &1AC4  object_type_table
    CMP #TYPE_PHIZZER           ; &1AC7
    BNE update_hazard_slot_1                          ; &1AC9
    INC object_state_table,X                        ; &1ACB  object_state_table
    LDA object_state_table,X                        ; &1ACE  object_state_table
    AND #OBJECT_STATE_PATH_INDEX_MASK                           ; &1AD1
    TAY                                ; &1AD3
    ORA #OBJECT_STATE_ACTIVE                           ; &1AD4
    STA object_state_table,X                        ; &1AD6  object_state_table
    LDA phizzer_y_path,Y                        ; &1AD9
    STA object_y_table,X                        ; &1ADC  object_y_table
update_hazard_slot_1:
    ; Meteorites receive a common -1 X step later for every frame, plus an extra
    ; -2 X step here on the selected alternating phase: motion therefore follows
    ; -3,-1,-3,-1... (average -2 game X units per frame).
    LDX #DYNAMIC_HAZARD_SLOT_1                           ; &1ADF
    LDA meteorite_update_phase                            ; &1AE1
    EOR #OBJECT_STATE_FRAME_SUPPRESSED                           ; &1AE3
    STA meteorite_update_phase                            ; &1AE5
    BEQ update_hazard_type                          ; &1AE7
    DEX                                ; &1AE9
update_hazard_type:
    LDA object_type_table,X                        ; &1AEA  object_type_table
    CMP #TYPE_METEORITE             ; &1AED
    BNE update_hazard_slot_0                          ; &1AEF
    LDA #OBJECT_STATE_ACTIVE                           ; &1AF1
    STA object_state_table,X                        ; &1AF3  object_state_table
    DEC object_x_table,X                        ; &1AF6  object_x_table
    DEC object_x_table,X                        ; &1AF9  object_x_table
    BPL update_hazard_slot_0                          ; &1AFC
    JSR remove_object_slot                          ; &1AFE
update_hazard_slot_0:
    LDX #DYNAMIC_HAZARD_SLOT_0                           ; &1B01
move_hazard_left_loop:
    LDA object_x_table,X                        ; &1B03  object_x_table
    BEQ next_hazard_slot                          ; &1B06
    DEC object_x_table,X                        ; &1B08  object_x_table
    BNE next_hazard_slot                          ; &1B0B
    JSR remove_object_slot                          ; &1B0D
next_hazard_slot:
    INX                                ; &1B10
    CPX #OBJECT_LAST_SLOT                           ; &1B11
    BNE move_hazard_left_loop                          ; &1B13
    RTS                                ; &1B15
raid_complete:
    JSR flush_input_and_quiet_sound              ; &1B16
    LDA #SOUND_RAID_COMPLETE           ; &1B19
    JSR play_sound_effect              ; &1B1B
    LDX #RAID_COMPLETE_DELAY_TICKS                           ; &1B1E
    JSR delay_ticks                    ; &1B20
    LDY #LOGICAL_COLOUR_LAST                           ; &1B23
    LDA #COLOUR_BLACK                  ; &1B25
raid_complete_palette_loop:
    JSR set_palette                    ; &1B27
    DEY                                ; &1B2A
    BPL raid_complete_palette_loop                          ; &1B2B
    LDX #<raid_complete_message        ; &1B2D
    LDY #>raid_complete_message        ; &1B2F
    JSR atomstring                     ; &1B31
    LDX #RAID_COMPLETE_DELAY_TICKS                           ; &1B34
    JSR delay_ticks                    ; &1B36
    LDX #RAID_COMPLETE_DELAY_TICKS                           ; &1B39
    JSR delay_ticks                    ; &1B3B
    LDX saved_caller_sp                            ; &1B3E  saved_caller_sp
    TXS                                ; &1B40: discard current game/life call frames
    JMP restart_raid_entry             ; &1B41: immediately begin the next raid through original call chain
raid_complete_message:                 ; &1B44, CR-terminated Mode-7/VDU string
    EQUB &0C, &14, &1F, &04, &08, &11, &08, &57, &65, &6C, &6C, &20
    EQUB &44, &6F, &6E, &65, &20, &21, &21, &1F, &06, &0C, &11, &05, &59, &6F, &75, &20    ; &1B50
    EQUB &48, &61, &76, &65, &1F, &04, &0E, &53, &75, &63, &63, &65, &73, &73, &66, &75    ; &1B60
    EQUB &6C, &6C, &79, &1F, &03, &10, &43, &6F, &6D, &70, &6C, &65, &74, &65, &64, &20    ; &1B70
    EQUB &59, &6F, &75, &72, &1F, &08, &12, &52, &61, &69, &64, &1F, &03, &1A, &11, &01    ; &1B80
    EQUB &4E, &6F, &77, &20, &54, &72, &79, &20, &41, &67, &61, &69, &6E, &0D    ; &1B90-&1B9D preceding bytes retained

; -----------------------------------------------------------------------------
; ESCAPE, SOUND, INPUT, VIDEO AND GENERAL MOS HELPERS
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; check_escape_restart
; -----------------------------------------------------------------------------
; ESCAPE is a clean abort of the current game, not a same-life restart.  The
; routine zeroes the score, restores the controller's saved stack pointer and
; RTSes through the original `JSR game` return address.  The copied controller
; then immediately JMPs checkhi_score; score zero fails qualification and the
; Hall-of-Fame/start screen is shown again.
; -----------------------------------------------------------------------------
check_escape_restart:
    LDX #KEY_ESCAPE                           ; &1B9E
    JSR inkey                          ; &1BA0
    BEQ escape_check_done                          ; &1BA3
    LDA #BYTE_FALSE                    ; &1BA5
    STA score_hi                            ; &1BA7  score_hi
    STA score_mid                            ; &1BA9  score_mid
    STA score_lo                            ; &1BAB  score_lo
    LDX saved_caller_sp                            ; &1BAD  saved_caller_sp
    TXS                                ; &1BAF
escape_check_done:
sound_effect_disabled_return:
    RTS                                ; &1BB0
black_out_palette:
    LDY #LOGICAL_COLOUR_LAST                           ; &1BB1
black_out_palette_loop:
    LDA #COLOUR_BLACK                  ; &1BB3
    JSR set_palette                    ; &1BB5
    DEY                                ; &1BB8
    BPL black_out_palette_loop                          ; &1BB9
    RTS                                ; &1BBB
play_sound_effect:
play_sound:                            ; ORIGINAL source name recovered as play_sound
    LDX soundflag                            ; &1BBC  soundflag
    BEQ sound_effect_disabled_return             ; &1BBE
    ASL A                              ; &1BC0
    ASL A                              ; &1BC1
    ASL A                              ; &1BC2
    ADC #<sound_table                   ; &1BC3
    TAX                                ; &1BC5
    LDY #>sound_table                   ; &1BC6
    LDA #OSWORD_SOUND                           ; &1BC8
    JMP osword                          ; &1BCA
adval:
    LDY #&00                           ; &1BCD
    LDA #OSBYTE_ADVAL                           ; &1BCF
    JMP osbyte                          ; &1BD1
erase_and_remove_object:
    LDA object_prev_screen_lo,X                        ; &1BD4
    STA screen_ptr_lo                   ; &1BD7
    LDA object_prev_screen_hi,X                        ; &1BD9
    STA screen_ptr_hi                   ; &1BDC
    LDA object_type_table,X                        ; &1BDE  object_type_table
    CMP #TYPE_LAUNCHED_MISSILE            ; &1BE1
    BNE erase_object_using_display_type                          ; &1BE3
    LDA #TYPE_GROUND_MISSILE           ; &1BE5: transformed missile erases with its ground-missile image
erase_object_using_display_type:
    STX temp                            ; &1BE7
    JSR draw_object_by_type            ; &1BE9
    LDX temp                            ; &1BEC
remove_object_slot:
    LDA object_x_table+DYNAMIC_HAZARD_SLOT_1                          ; &1BEE
    BNE clear_removed_object_fields                          ; &1BF1
    LDA object_x_table+DYNAMIC_HAZARD_SLOT_0                          ; &1BF3
    BNE clear_removed_object_fields                          ; &1BF6
    TXA                                ; &1BF8
    PHA                                ; &1BF9
    LDA #SOUND_QUIET_CHANNEL_1         ; &1BFA: dynamic missile slots now empty
    JSR play_sound_effect              ; &1BFC
    PLA                                ; &1BFF
    TAX                                ; &1C00
clear_removed_object_fields:
    LDA #BYTE_FALSE                    ; &1C01
    STA object_x_table,X                        ; &1C03  object_x_table
    STA object_screen_hi,X                        ; &1C06
    STA object_screen_lo,X                        ; &1C09
    STA object_prev_screen_lo,X                        ; &1C0C
    STA object_prev_screen_hi,X                        ; &1C0F
    TAY                                ; &1C12
    CPX launched_missile_slot_a                            ; &1C13
    BEQ clear_removed_object_loop                          ; &1C15
    INY                                ; &1C17
    CPX launched_missile_slot_b                            ; &1C18
    BEQ clear_removed_object_loop                          ; &1C1A
    RTS                                ; &1C1C
clear_removed_object_loop:
    STA launched_missile_slot_a,Y      ; &1C1D: clear matching &77/&78 slot reference
    RTS                                ; &1C20
inkey:
    PHA                                ; &1C21
    TYA                                ; &1C22
    PHA                                ; &1C23
    LDY #INKEY_POLL_Y                 ; &1C24
    LDA #OSBYTE_INKEY                           ; &1C26
    JSR osbyte                          ; &1C28
    PLA                                ; &1C2B
    TAY                                ; &1C2C
    PLA                                ; &1C2D
    CPX #&00                           ; &1C2E
    RTS                                ; &1C30
set_palette:
    STA temp                            ; &1C31
    TYA                                ; &1C33
    ASL A                              ; &1C34
    ASL A                              ; &1C35
    ASL A                              ; &1C36
    ASL A                              ; &1C37
    ORA temp                            ; &1C38
    EOR #COLOUR_WHITE                           ; &1C3A
    STA video_ula_palette                          ; &1C3C
    RTS                                ; &1C3F
write_crtc_register:
    STX crtc_address                          ; &1C40
    STA crtc_data                          ; &1C43
    RTS                                ; &1C46
wait_vsync:
    LDA #VSYNC_INTERRUPT_FLAG                           ; &1C47
    BIT sysvia_ifr                          ; &1C49
    BEQ wait_vsync                     ; &1C4C
    RTS                                ; &1C4E
; -----------------------------------------------------------------------------
; 24-bit pseudo-random generators
; -----------------------------------------------------------------------------
; RNG A and B use the same recurrence but advance independently.  The arithmetic
; before the three ROLs synthesises a single feedback bit equivalent to
; (old_low bit 6 XOR old_low bit 3), shifted into the high byte while the 24-bit
; state rotates toward the low byte.  Both states are seeded 57:57:57 at raid
; start.  From that game seed the recurrence repeats after 32767 steps (2^15-1).
; The returned A is the *old* low byte; callers often mask it for probabilities.
; -----------------------------------------------------------------------------
step_rng_b:
    LDA rng_b_lo                            ; &1C4F
    PHA                                ; &1C51
    AND #RNG_FEEDBACK_MASK             ; &1C52
    ADC #RNG_FEEDBACK_BIAS             ; &1C54
    ASL A                              ; &1C56
    ASL A                              ; &1C57
    ROL rng_b_hi                            ; &1C58
    ROL rng_b_mid                            ; &1C5A
    ROL rng_b_lo                            ; &1C5C
    PLA                                ; &1C5E
    RTS                                ; &1C5F
step_rng_a:
    LDA rng_a_lo                            ; &1C60
    PHA                                ; &1C62
    AND #RNG_FEEDBACK_MASK             ; &1C63
    ADC #RNG_FEEDBACK_BIAS             ; &1C65
    ASL A                              ; &1C67
    ASL A                              ; &1C68
    ROL rng_a_hi                            ; &1C69
    ROL rng_a_mid                            ; &1C6B
    ROL rng_a_lo                            ; &1C6D
    PLA                                ; &1C6F
    RTS                                ; &1C70
read_rng_a:
    ; Stage 7 temporarily called this multiply_a_by_y.  It does NOT multiply:
    ; it simply returns rng_a_lo.  The real repeated-add multiply is the next routine.
    LDA rng_a_lo                            ; &1C71
    RTS                                ; &1C73
multiply_a_by_y_slow:
    STA temp                            ; &1C74
    LDA #&00                           ; &1C76
    CPY #&00                           ; &1C78
    BEQ multiply_done                          ; &1C7A
multiply_add_loop:
    CLC                                ; &1C7C
    ADC temp                            ; &1C7D
    DEY                                ; &1C7F
    BNE multiply_add_loop                          ; &1C80
multiply_done:
    RTS                                ; &1C82
advance_scroll_position:
    LDA scroll_screen_lo                            ; &1C83
    CLC                                ; &1C85
    ADC #SCROLL_STEP_BYTES                           ; &1C86
    STA scroll_screen_lo                            ; &1C88
    LDA scroll_screen_hi                            ; &1C8A
    ADC #&00                           ; &1C8C
    BPL scroll_store_hi                          ; &1C8E
    LDA #SCREEN_BASE_HI                           ; &1C90
scroll_store_hi:
    STA scroll_screen_hi                            ; &1C92
    RTS                                ; &1C94
; A mod Y by repeated subtraction.  The terrain-object trigger path uses this
; as: upper_run_remaining MOD object_trigger_offset[type].  A zero remainder is
; the exact condition for stamping the next fixed scenery object on a flat run.
wrap_delta:
    STY temp                            ; &1C95
    SEC                                ; &1C97
wrap_delta_subtract_loop:
    SBC temp                            ; &1C98
    BCS wrap_delta_subtract_loop                          ; &1C9A
    ADC temp                            ; &1C9C
    RTS                                ; &1C9E
abs_a:
    BPL abs_done                          ; &1C9F
    EOR #BYTE_INVERT_MASK             ; &1CA1: two-complement absolute value
    CLC                                ; &1CA3
    ADC #&01                           ; &1CA4
abs_done:
    RTS                                ; &1CA6
allocate_object_slot:
    PHA                                ; &1CA7
    TYA                                ; &1CA8
    PHA                                ; &1CA9
    TXA                                ; &1CAA
    PHA                                ; &1CAB
    JSR screen_address_from_xy                          ; &1CAC
    LDX #SCENERY_FIRST_SLOT                           ; &1CAF
find_free_object_slot_loop:
    LDA object_x_table,X                        ; &1CB1  object_x_table
    BEQ allocate_object_slot_here                          ; &1CB4
    INX                                ; &1CB6
    CPX #OBJECT_LAST_SLOT                           ; &1CB7
    BNE find_free_object_slot_loop                          ; &1CB9
allocate_object_slot_here:
    LDA screen_ptr_lo                   ; &1CBB
    STA object_prev_screen_lo,X                        ; &1CBD
    LDA screen_ptr_hi                   ; &1CC0
    STA object_prev_screen_hi,X                        ; &1CC2
    PLA                                ; &1CC5
    STA object_x_table,X                        ; &1CC6  object_x_table
    PLA                                ; &1CC9
    STA object_y_table,X                        ; &1CCA  object_y_table
    LDA #BYTE_FALSE                    ; &1CCD
    STA object_state_table,X                        ; &1CCF  object_state_table
    PLA                                ; &1CD2
    STA object_type_table,X                        ; &1CD3  object_type_table
    RTS                                ; &1CD6
draw_object_by_type:
    TAY                                ; &1CD7
    LDA object_sprite_lo,Y                        ; &1CD8
    STA render_sprite_ptr_lo             ; &1CDB
    LDA object_sprite_hi,Y                        ; &1CDD
    STA render_sprite_ptr_hi             ; &1CE0
    LDA object_sprite_bytes,Y                        ; &1CE2
    STA render_bytes_remaining         ; &1CE5
    LDA object_height_pixels,Y                        ; &1CE7
    STA render_height                  ; &1CEA
    JMP xor_sprite_renderer                          ; &1CEC
erase_object_by_type:
    TYA                                ; &1CEF
    PHA                                ; &1CF0
    LDA object_type_table,Y                        ; &1CF1  object_type_table
    JSR draw_object_by_type            ; &1CF4
    PLA                                ; &1CF7
    TAY                                ; &1CF8
    RTS                                ; &1CF9
start_extra_life_beeper:
    LDA #EXTRA_LIFE_BEEP_COUNT                           ; &1CFA
    STA warning_beeps_left                            ; &1CFC
    LDA #EXTRA_LIFE_BEEP_FIRST_DELAY                           ; &1CFE
    STA warning_beep_timer                            ; &1D00
update_extra_life_beeper:
    LDA warning_beeps_left                            ; &1D02
    BEQ extra_life_beeper_done                          ; &1D04
    DEC warning_beep_timer                            ; &1D06
    BNE extra_life_beeper_done                          ; &1D08
    LDA #EXTRA_LIFE_BEEP_PERIOD                           ; &1D0A
    STA warning_beep_timer                            ; &1D0C
    LDA #SOUND_EXTRA_LIFE_BEEP         ; &1D0E
    JSR play_sound_effect              ; &1D10
    DEC warning_beeps_left                            ; &1D13
extra_life_beeper_done:
    RTS                                ; &1D15
flush_input_and_quiet_sound:
    ; OSBYTE &0F with X=0 flushes input buffers, then effect 11 silences channel 1.
    ; Stage 7 called this read_system_clock; the actual clock read is OSWORD 1 in delay_ticks.
    LDX #BYTE_FALSE                    ; &1D16
    LDA #OSBYTE_FLUSH_BUFFER                           ; &1D18
    JSR osbyte                          ; &1D1A
    LDA #SOUND_QUIET_CHANNEL_1         ; &1D1D: reset/quiet channel before timing sequence
    JMP play_sound_effect              ; &1D1F
delay_ticks:
    PHA                                ; &1D22
    TYA                                ; &1D23
    PHA                                ; &1D24
    INX                                ; &1D25
    STX delay_counter                            ; &1D26
delay_tick_loop:
    LDX #timespace                     ; &1D28
    LDY #BYTE_FALSE                    ; &1D2A
    LDA #OSWORD_READ_SYSTEM_CLOCK                           ; &1D2C
    JSR osword                          ; &1D2E
    LDA timespace                            ; &1D31
    CMP clock_previous_low                            ; &1D33
    BEQ delay_tick_loop                          ; &1D35
    STA clock_previous_low                            ; &1D37
    DEC delay_counter                            ; &1D39
    BPL delay_tick_loop                          ; &1D3B
    PLA                                ; &1D3D
    TAY                                ; &1D3E
    PLA                                ; &1D3F
    RTS                                ; &1D40
print_packed_bcd_byte:
    ; A contains two packed-BCD digits.  High nibble is printed first; Y carries
    ; the leading-dot state used by the Hall-of-Fame score formatter.
    PHA                                ; &1D41
    LSR A                              ; &1D42
    LSR A                              ; &1D43
    LSR A                              ; &1D44
    LSR A                              ; &1D45
    JSR print_bcd_nibble               ; &1D46
    PLA                                ; &1D49
    AND #BCD_LOW_NIBBLE_MASK                           ; &1D4A
print_bcd_nibble:
    BNE emit_bcd_digit                          ; &1D4C
    TYA                                ; &1D4E
    BNE emit_leading_dot                          ; &1D4F
emit_bcd_digit:
    LDY #&00                           ; &1D51
    ORA #ASCII_ZERO                           ; &1D53
    JMP oswrch                          ; &1D55
emit_leading_dot:
    LDA #ASCII_DOT                     ; &1D58
    JMP oswrch                          ; &1D5A
    EQUB &4C, &44, &41    ; &1D5D-&1D5F following bytes retained
    EQUB &73, &74, &72, &69, &6E, &67, &2C, &58, &3A, &54, &41, &58, &3A, &4A, &53, &52    ; &1D60
    EQUB &61, &74, &6F, &6D, &73, &74, &72, &69, &6E, &67, &3A, &50, &4C, &41, &3A, &54    ; &1D70
    EQUB &41, &58, &3A, &4C, &44, &41, &23, &31, &30, &3A, &4A, &53, &52, &6F, &73, &77    ; &1D80
    EQUB &72, &63, &68, &3A, &4A, &53, &52, &6F, &73, &77, &72, &63, &68, &0D, &11, &30    ; &1D90
    EQUB &26, &49, &4E, &43, &74, &65, &6D, &70, &3A, &44, &45, &58, &3A, &44, &45, &58    ; &1DA0
    EQUB &3A, &44, &45, &58, &3A, &42, &4E, &45, &70, &72, &69, &6E, &74, &73, &63, &6F    ; &1DB0
    EQUB &72, &65, &73, &0D, &11, &94, &3B, &4C, &44, &58, &23, &73, &70, &61, &63, &65    ; &1DC0
    EQUB &73, &74, &72, &69, &6E, &67, &20, &80, &26, &46, &46, &3A, &4C, &44, &59, &23    ; &1DD0
    EQUB &73, &70, &61, &63, &65, &73, &74, &72, &69, &6E, &67, &20, &81, &32, &35, &36    ; &1DE0
    EQUB &3A, &4A, &53, &52, &61, &74, &6F, &6D, &73, &74, &72, &69, &6E, &67, &0D, &11    ; &1DF0
    EQUB &F8, &82, &2E, &73, &70, &61, &63, &65, &20, &4C, &44, &41, &23, &26, &37, &45    ; &1E00
    EQUB &3A, &4A, &53, &52, &6F, &73, &62, &79, &74, &65, &3A, &4C, &44, &58, &23, &71    ; &1E10
    EQUB &6B, &65, &79, &3A, &4A, &53, &52, &69, &6E, &6B, &65, &79, &3A, &42, &45, &51    ; &1E20
    EQUB &6E, &6F, &71, &6B, &65, &79, &3A, &49, &4E, &58, &3A, &53, &54, &58, &73, &6F    ; &1E30
    EQUB &75, &6E, &64, &66, &6C, &61, &67, &3A, &2E, &6E, &6F, &71, &6B, &65, &79, &20    ; &1E40
    EQUB &4C, &44, &58, &23, &73, &6B, &65, &79, &3A, &4A, &53, &52, &69, &6E, &6B, &65    ; &1E50
    EQUB &79, &3A, &42, &45, &51, &6E, &6F, &73, &6B, &65, &79, &3A, &53, &54, &58, &73    ; &1E60
    EQUB &6F, &75, &6E, &64, &66, &6C, &61, &67, &3A, &2E, &6E, &6F, &73, &6B, &65, &79    ; &1E70
    EQUB &0D, &12, &5C, &7F, &4C, &44, &41, &23, &30, &3A, &53, &54, &41, &6A, &6F, &79    ; &1E80
    EQUB &66, &6C, &61, &67, &3A, &4C, &44, &58, &23, &26, &39, &44, &3A, &4A, &53, &52    ; &1E90
    EQUB &69, &6E, &6B, &65, &79, &3A, &42, &4E, &45, &68, &65, &72, &65, &3A, &4C, &44    ; &1EA0
    EQUB &41, &23, &26, &46, &46, &3A, &53, &54, &41, &6A, &6F, &79, &66, &6C, &61, &67    ; &1EB0
    EQUB &3A, &4C, &44, &58, &23, &30, &3A, &4A, &53, &52, &61, &64, &76, &61, &6C, &3A    ; &1EC0
    EQUB &54, &58, &41, &3A, &80, &23, &31, &3A, &42, &45, &51, &73, &70, &61, &63, &65    ; &1ED0
    EQUB &3A, &2E, &68, &65, &72, &65, &20, &4A, &53, &52, &67, &61, &6D, &65, &3A, &4A    ; &1EE0
    EQUB &4D, &50, &63, &68, &65, &63, &6B, &68, &69, &5F, &73, &63, &6F, &72, &65, &0D    ; &1EF0
    EQUB &12, &C0, &05, &20, &0D, &13, &24, &14, &2E, &6D, &69, &63, &72, &6F, &73, &6F    ; &1F00
    EQUB &66, &74, &73, &74, &72, &69, &6E, &67, &0D, &13, &88, &85, &53, &54, &58, &73    ; &1F10
    EQUB &74, &72, &69, &6E, &67, &70, &74, &72, &3A, &53, &54, &59, &73, &74, &72, &69    ; &1F20
    EQUB &6E, &67, &70, &74, &72, &2B, &31, &3A, &4C, &44, &59, &23, &30, &3A, &4C, &44    ; &1F30
    EQUB &41, &28, &73, &74, &72, &69, &6E, &67, &70, &74, &72, &29, &2C, &59, &3A, &53    ; &1F40
    EQUB &54, &41, &6C, &65, &6E, &3A, &49, &4E, &59, &3A, &2E, &73, &74, &72, &69, &6E    ; &1F50
    EQUB &67, &6C, &6F, &6F, &70, &20, &4C, &44, &41, &28, &73, &74, &72, &69, &6E, &67    ; &1F60
    EQUB &70, &74, &72, &29, &2C, &59, &3A, &4A, &53, &52, &6F, &73, &77, &72, &63, &68    ; &1F70
    EQUB &3A, &49, &4E, &59, &3A, &43, &50, &59, &6C, &65, &6E, &3A, &42, &4E, &45, &73    ; &1F80
    EQUB &74, &72, &69, &6E, &67, &6C, &6F, &6F, &70, &3A, &52, &54, &53, &0D, &13, &EC    ; &1F90
    EQUB &05, &20, &0D, &14, &50, &0F, &2E, &61, &74, &6F, &6D, &73, &74, &72, &69, &6E    ; &1FA0
    EQUB &67, &0D, &14, &B4, &71, &53, &54, &58, &73, &74, &72, &69, &6E, &67, &70, &74    ; &1FB0
    EQUB &72, &3A, &53, &54, &59, &73, &74, &72, &69, &6E, &67, &70, &74, &72, &2B, &31    ; &1FC0
    EQUB &3A, &4C, &44, &59, &23, &30, &3A, &2E, &61, &74, &6F, &6D, &73, &74, &72, &69    ; &1FD0
    EQUB &6E, &67, &6C, &6F, &6F, &70, &20, &4C, &44, &41, &28, &73, &74, &72, &69, &6E    ; &1FE0
    EQUB &67, &70, &74, &72, &29, &2C, &59, &3A, &4A, &53, &52, &6F, &73, &77, &72, &63    ; &1FF0
    EQUB &68, &3A, &49, &4E, &59, &3A, &43, &4D, &50, &23, &31, &33, &3A, &42, &4E, &45    ; &2000
    EQUB &61, &74, &6F, &6D, &73, &74, &72, &69, &6E, &67, &6C, &6F, &6F, &70, &3A, &52    ; &2010
    EQUB &54, &53, &0D, &15, &18, &05, &20, &0D, &15, &7C, &1C, &2E, &66, &6F, &75, &72    ; &2020
    EQUB &64, &6F, &74, &73, &20, &4C, &44, &41, &23, &97, &22, &2E, &22, &3A, &4C, &44    ; &2030
    EQUB &59, &23, &34, &0D, &15, &E0, &05, &20, &0D, &16, &44, &11, &2E, &73, &74, &72    ; &2040
    EQUB &69, &6E, &67, &64, &6F, &6C, &6C, &61, &72, &0D, &16, &A8, &25, &4A, &53, &52    ; &2050
    EQUB &6F, &73, &77, &72, &63, &68, &3A, &44, &45, &59, &3A, &42, &4E, &45, &73, &74    ; &2060
    EQUB &72, &69, &6E, &67, &64, &6F, &6C, &6C, &61, &72, &3A, &52, &54, &53, &0D, &17    ; &2070
    EQUB &0C, &05, &20, &0D, &17, &70, &39, &5D, &3A, &E7, &A6, &2D, &31, &20, &F1, &27    ; &2080
    EQUB &27, &22, &53, &70, &61, &63, &65, &20, &6C, &65, &66, &74, &20, &69, &6E, &20    ; &2090
    EQUB &68, &69, &73, &63, &6F, &72, &65, &20, &72, &6F, &75, &74, &69, &6E, &65, &20    ; &20A0
    EQUB &3D, &26, &22, &3B, &7E, &26, &36, &44, &30, &2D, &50, &25, &0D, &17, &D4, &14    ; &20B0
    EQUB &50, &25, &3D, &26, &36, &44, &30, &3A, &5B, &4F, &50, &54, &49, &25, &84, &34    ; &20C0
    EQUB &0D, &18, &38, &55, &2E, &6C, &61, &64, &64, &65, &72, &20, &45, &51, &55, &53    ; &20D0
    EQUB &20, &C4, &33, &30, &2C, &BD, &30, &29, &3A, &2E, &73, &74, &72, &69, &6E, &67    ; &20E0
    EQUB &20, &45, &51, &55, &53, &20, &C4, &33, &30, &2C, &BD, &30, &29, &3A, &2E, &6E    ; &20F0
    EQUB &61, &6D, &65, &20, &45, &51, &55, &53, &20, &C4, &32, &30, &30, &2C, &BD, &30    ; &2100
    EQUB &29, &3A, &2E, &74, &65, &6D, &70, &73, &63, &20, &45, &51, &55, &53, &20, &C4    ; &2110
    EQUB &33, &2C, &BD, &30, &29, &0D, &18, &9C, &05, &20, &0D, &19, &00, &15, &5D, &3A    ; &2120
    EQUB &50, &25, &3D, &26, &33, &34, &30, &30, &3A, &5B, &4F, &50, &54, &49, &25, &0D    ; &2130
    EQUB &19, &64, &24, &5C, &4F, &72, &69, &67, &69, &6E, &61, &6C, &20, &65, &6E, &74    ; &2140
    EQUB &72, &79, &20, &70, &6F, &69, &6E, &74, &20, &66, &6F, &72, &20, &65, &6E, &74    ; &2150
    EQUB &69, &72, &65, &0D, &19, &C8, &23, &5C, &70, &72, &6F, &67, &72, &61, &6D, &2E    ; &2160
    EQUB &20, &20, &4F, &6E, &6C, &79, &20, &63, &61, &6C, &6C, &65, &64, &20, &6F, &6E    ; &2170
    EQUB &63, &65, &2C, &20, &73, &6F, &0D, &1A, &2C, &1C, &5C, &6D, &61, &79, &20, &62    ; &2180
    EQUB &65, &20, &69, &6E, &20, &67, &72, &61, &70, &68, &69, &63, &73, &20, &72, &61    ; &2190
    EQUB &6D, &2E, &0D, &1A, &90, &7C, &2E, &65, &6E, &74, &65, &72, &20, &4C, &44, &59    ; &21A0
    EQUB &23, &30, &3A, &2E, &74, &72, &61, &6E, &73, &6C, &6F, &6F, &70, &20, &4C, &44    ; &21B0
    EQUB &41, &26, &33, &30, &30, &30, &2C, &59, &3A, &53, &54, &41, &26, &34, &30, &30    ; &21C0
    EQUB &2C, &59, &3A, &4C, &44, &41, &26, &33, &31, &30, &30, &2C, &59, &3A, &53, &54    ; &21D0
    EQUB &41, &26, &35, &30, &30, &2C, &59, &3A, &4C, &44, &41, &26, &33, &32, &30, &30    ; &21E0

; Sound envelope parameter blocks used by the startup routine at &3468-&348A.
; OSWORD 8 consumes exactly 14 bytes per record:
;   ENV,T,PI1,PI2,PI3,PN1,PN2,PN3,AA,AD,AS,AR,ALA,ALD
; The first three records are alternative definitions of envelope 4 selected by
; terrain section; the final three define envelopes 1, 2 and 3 used by effects.
; Keeping the records individually split is important: original assembler-source
; residue begins immediately at &2244 and is NOT part of envelope 3.
; -----------------------------------------------------------------------------
envbuff:
envelope_section_0:                    ; &21F0 - envelope 4 variant used by sections 0/3/4/5
    EQUB &04, &01, &00, &00, &00, &00, &00, &00, &0C, &00, &F6, &FF, &78, &3C
envelope_section_1:                    ; &21FE - envelope 4 variant selected by cavern
    EQUB &04, &05, &01, &FF, &00, &0C, &0C, &01, &78, &00, &00, &00, &78, &00
envelope_section_2:                    ; &220C - envelope 4 variant selected by meteorites
    EQUB &04, &82, &FE, &FE, &FE, &14, &14, &28, &79, &FF, &FE, &FE, &78, &78
envelope_1:                            ; &221A - used by bullet effect
    EQUB &01, &01, &FD, &FD, &FD, &14, &14, &14, &5A, &FF, &FF, &FD, &7E, &3F
envelope_2:                            ; &2228 - used by bomb effect
    EQUB &02, &04, &FF, &FF, &FF, &14, &14, &14, &5A, &FF, &FF, &FD, &7E, &3F
envelope_3:                            ; &2236 - used by extra-life beep
    EQUB &03, &01, &00, &00, &00, &01, &01, &01, &7E, &FC, &FF, &FC, &7E, &00

; Preserved original assembler/source residue resumes at exactly &2244.
    EQUB &59, &3A, &53, &54, &41, &6C, &61, &64, &64, &65, &72, &2B    ; &2244  "Y:STAladder+"
score_display_buffer:                  ; original &2250; live MODE-2 HUD backing buffer overlays source residue
    EQUB &32, &2C, &59, &3A, &4C, &44, &41, &23, &26, &31, &30, &3A, &53, &54, &41, &6C    ; &2250
    EQUB &61, &64, &64, &65, &72, &2B, &31, &2C, &59, &3A, &44, &45, &59, &3A, &44, &45    ; &2260
    EQUB &59, &3A, &44, &45, &59, &3A, &42, &50, &4C, &73, &63, &6F, &72, &65, &69, &6E    ; &2270
    EQUB &69, &74, &0D, &1B, &58, &6A, &4C, &44, &59, &23, &28, &31, &30, &2A, &32, &30    ; &2280
    EQUB &29, &3A, &2E, &6E, &61, &6D, &65, &69, &6E, &69, &74, &20, &4C, &44, &58, &23    ; &2290
    EQUB &39, &3A, &2E, &69, &6E, &6E, &65, &72, &6E, &61, &6D, &65, &20, &4C, &44, &41    ; &22A0
raid_display_buffer:                   ; original &22B0; live raid-number HUD backing buffer
    EQUB &61, &63, &6F, &72, &6E, &73, &6F, &66, &74, &2C, &58, &3A, &53, &54, &41, &6E    ; &22B0
    EQUB &61, &6D, &65, &2D, &31, &2C, &59, &3A, &44, &45, &59, &3A, &44, &45, &58, &3A    ; &22C0
lives_buffer_base:                     ; original &22D0; live lower-HUD/life-icon backing buffer
    EQUB &42, &50, &4C, &69, &6E, &6E, &65, &72, &6E, &61, &6D, &65, &3A, &54, &59, &41    ; &22D0
    EQUB &3A, &42, &4E, &45, &6E, &61, &6D, &65, &69, &6E, &69, &74, &0D, &1B, &BC, &71    ; &22E0
    EQUB &4C, &44, &58, &23, &6E, &61, &6D, &65, &20, &80, &26, &46, &46, &3A, &4C, &44    ; &22F0
    EQUB &59, &23, &32, &37, &3A, &2E, &73, &74, &72, &69, &6E, &67, &69, &6E, &69, &74    ; &2300
    EQUB &20, &54, &58, &41, &3A, &53, &54, &41, &73, &74, &72, &69, &6E, &67, &2C, &59    ; &2310
landscape_mask:                        ; original &2320; 256-byte live collision strip overlays source residue
    EQUB &3A, &43, &4C, &43, &3A, &41, &44, &43, &23, &32, &30, &3A, &54, &41, &58, &3A    ; &2320
    EQUB &4C, &44, &41, &23, &37, &3A, &53, &54, &41, &73, &74, &72, &69, &6E, &67, &2B    ; &2330
    EQUB &31, &2C, &59, &3A, &44, &45, &59, &3A, &44, &45, &59, &3A, &44, &45, &59, &3A    ; &2340
    EQUB &42, &50, &4C, &73, &74, &72, &69, &6E, &67, &69, &6E, &69, &74, &0D, &1C, &20    ; &2350
    EQUB &3C, &4C, &44, &58, &23, &34, &3A, &2E, &63, &6C, &65, &61, &72, &74, &69, &6D    ; &2360
    EQUB &65, &6C, &6F, &6F, &70, &20, &53, &54, &41, &74, &69, &6D, &65, &73, &70, &61    ; &2370
    EQUB &63, &65, &2C, &58, &3A, &44, &45, &58, &3A, &42, &50, &4C, &63, &6C, &65, &61    ; &2380
    EQUB &72, &74, &69, &6D, &65, &6C, &6F, &6F, &70, &0D, &1C, &84, &2A, &4C, &44, &41    ; &2390
    EQUB &23, &34, &3A, &4C, &44, &58, &23, &31, &3A, &4A, &53, &52, &6F, &73, &62, &79    ; &23A0
    EQUB &74, &65, &3A, &4C, &44, &41, &23, &31, &33, &3A, &4A, &53, &52, &6F, &73, &77    ; &23B0
    EQUB &72, &63, &68, &0D, &1C, &E8, &D7, &4C, &44, &41, &23, &6E, &6F, &65, &6E, &76    ; &23C0
    EQUB &3A, &53, &54, &41, &74, &65, &6D, &70, &3A, &4C, &44, &41, &23, &65, &6E, &76    ; &23D0
    EQUB &62, &75, &66, &66, &20, &80, &26, &46, &46, &3A, &53, &54, &41, &73, &74, &72    ; &23E0
    EQUB &69, &6E, &67, &70, &74, &72, &3A, &4C, &44, &41, &23, &65, &6E, &76, &62, &75    ; &23F0
    EQUB &66, &66, &20, &81, &32, &35, &36, &3A, &53, &54, &41, &73, &74, &72, &69, &6E    ; &2400
    EQUB &67, &70, &74, &72, &2B, &31, &3A, &2E, &65, &6E, &76, &6C, &6F, &6F, &70, &20    ; &2410
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; OSWORD 7 SOUND PARAMETER BLOCKS - 13 records x 8 bytes
; channel, amplitude/envelope, pitch, duration are little-endian words.
; -----------------------------------------------------------------------------
sound_table:
sound_record_unused_0: ; effect 0: unused/zero record
    EQUB &00, &00, &00, &00, &00, &00, &00, &00    ; &2420
sound_record_fire_bullet: ; effect 1: bullet: channel 3 + envelope 1
    EQUB &13, &00, &01, &00, &96, &00, &01, &00    ; &2428
sound_record_drop_bomb: ; effect 2: bomb: channel 2 + envelope 2
    EQUB &12, &00, &02, &00, &96, &00, &01, &00    ; &2430
sound_record_missile_launch: ; effect 3: missile launch: channel 0 + envelope 4
    EQUB &10, &00, &04, &00, &64, &00, &0A, &00    ; &2438
sound_record_phizzer_spawn: ; effect 4: Phizzer: channel 1 + envelope 4
    EQUB &11, &00, &04, &00, &C0, &00, &FF, &FF    ; &2440
sound_record_meteorite_spawn: ; effect 5: meteorite: channel 1 + envelope 4
    EQUB &11, &00, &04, &00, &BC, &00, &14, &00    ; &2448
sound_record_target_destroyed: ; effect 6: target destroyed: fixed amplitude
    EQUB &10, &00, &F1, &FF, &05, &00, &05, &00    ; &2450
sound_record_terrain_impact: ; effect 7: terrain impact: fixed amplitude
    EQUB &10, &00, &F1, &FF, &04, &00, &02, &00    ; &2458
sound_record_player_death: ; effect 8: player destruction: fixed amplitude
    EQUB &10, &00, &F1, &FF, &06, &00, &32, &00    ; &2460
sound_record_quiet_channel_2: ; effect 9: zero amplitude / quiet channel 2
    EQUB &12, &00, &00, &00, &00, &00, &00, &00    ; &2468
sound_record_extra_life_beep: ; effect 10: extra-life beep: envelope 3
    EQUB &13, &00, &03, &00, &B4, &00, &01, &00    ; &2470
sound_record_quiet_channel_1: ; effect 11: zero amplitude / quiet channel 1
    EQUB &11, &00, &00, &00, &00, &00, &00, &00    ; &2478
sound_record_raid_complete_quiet:
sound_record_raid_complete: ; effect 12: raid-complete path, zero-amplitude channel-1 control record
    EQUB &01, &00, &00, &00, &72, &2B, &31, &3A    ; &2480
; Preserved original build/source residue following effect 12.
    EQUB &44, &45, &43, &74, &65, &6D, &70, &3A    ; &2488
    EQUB &42, &4E, &45, &65, &6E, &76, &6C, &6F    ; &2490
    EQUB &6F, &70, &0D, &1D, &4C, &14, &4C, &44    ; &2498
; 32-step vertical flight path used by TYPE_PHIZZER.
phizzer_y_path:
    EQUB &6E, &78, &81, &8A, &91, &98, &9C, &9F, &A0, &9F, &9C, &98, &91, &8A, &81, &78    ; &24A0
    EQUB &6E, &64, &5B, &52, &4B, &44, &40, &3D, &3C, &3D, &40, &44, &4B, &52, &5B, &64    ; &24B0
; -----------------------------------------------------------------------------
; TERRAIN STREAMS AND LANDSCAPE-OBJECT SCRIPT (&24C0-&2AA0)
; -----------------------------------------------------------------------------
; The streams below are deliberately emitted as literal bytes: these are game
; data, not code or variable references.  Stage 7 separates the live bytecode
; from the fragments of the original assembler source that happen to survive
; between the packed tables.
;
; LOWER TERRAIN COMMAND STREAM (&24C0-&2544 original layout)
; -----------------------------------------------------------------------------
; Only cavern and maze enable the lower edge.  Crucially, section transitions
; can discard the unused remainder of the currently generated lower profile:
;   cavern: commands 0..55 decoded; command 55 generates 21 samples, 18 shown,
;           final 3 samples discarded when section 2 disables lower terrain.
;   maze:   resumes at command 56; commands 56..129 decoded; command 129
;           generates 30 samples, 12 shown, final 18 samples discarded.
;   commands 130..131 and the &FF terminator are never decoded by this build.
; Each line below shows the paired signed delta and generated run length.
lower_terrain_commands:
lower_cavern_commands:
    EQUB 10 ; original &24C0 | cavern cmd 00 | run=10 | delta=  -2 @ &2560 | generated cols    0..   9 
    EQUB 10 ; original &24C1 | cavern cmd 01 | run=10 | delta=  -1 @ &2561 | generated cols   10..  19 
    EQUB 5  ; original &24C2 | cavern cmd 02 | run= 5 | delta=  -3 @ &2562 | generated cols   20..  24 
    EQUB 10 ; original &24C3 | cavern cmd 03 | run=10 | delta=  +2 @ &2563 | generated cols   25..  34 
    EQUB 15 ; original &24C4 | cavern cmd 04 | run=15 | delta=  +1 @ &2564 | generated cols   35..  49 
    EQUB 20 ; original &24C5 | cavern cmd 05 | run=20 | delta=  -1 @ &2565 | generated cols   50..  69 
    EQUB 15 ; original &24C6 | cavern cmd 06 | run=15 | delta=  +1 @ &2566 | generated cols   70..  84 
    EQUB 5  ; original &24C7 | cavern cmd 07 | run= 5 | delta=  -1 @ &2567 | generated cols   85..  89 
    EQUB 18 ; original &24C8 | cavern cmd 08 | run=18 | delta=  +1 @ &2568 | generated cols   90.. 107 
    EQUB 20 ; original &24C9 | cavern cmd 09 | run=20 | delta=  -1 @ &2569 | generated cols  108.. 127 
    EQUB 10 ; original &24CA | cavern cmd 10 | run=10 | delta=  +2 @ &256A | generated cols  128.. 137 
    EQUB 30 ; original &24CB | cavern cmd 11 | run=30 | delta=  +1 @ &256B | generated cols  138.. 167 
    EQUB 5  ; original &24CC | cavern cmd 12 | run= 5 | delta=  -1 @ &256C | generated cols  168.. 172 
    EQUB 10 ; original &24CD | cavern cmd 13 | run=10 | delta=  +1 @ &256D | generated cols  173.. 182 
    EQUB 15 ; original &24CE | cavern cmd 14 | run=15 | delta=  +1 @ &256E | generated cols  183.. 197 
    EQUB 13 ; original &24CF | cavern cmd 15 | run=13 | delta=  -1 @ &256F | generated cols  198.. 210 
    EQUB 25 ; original &24D0 | cavern cmd 16 | run=25 | delta=  +1 @ &2570 | generated cols  211.. 235 
    EQUB 30 ; original &24D1 | cavern cmd 17 | run=30 | delta=  +1 @ &2571 | generated cols  236.. 265 
    EQUB 15 ; original &24D2 | cavern cmd 18 | run=15 | delta=  -1 @ &2572 | generated cols  266.. 280 
    EQUB 25 ; original &24D3 | cavern cmd 19 | run=25 | delta=  +1 @ &2573 | generated cols  281.. 305 
    EQUB 4  ; original &24D4 | cavern cmd 20 | run= 4 | delta=  -1 @ &2574 | generated cols  306.. 309 
    EQUB 30 ; original &24D5 | cavern cmd 21 | run=30 | delta=  +1 @ &2575 | generated cols  310.. 339 
    EQUB 20 ; original &24D6 | cavern cmd 22 | run=20 | delta=  +1 @ &2576 | generated cols  340.. 359 
    EQUB 7  ; original &24D7 | cavern cmd 23 | run= 7 | delta=  -2 @ &2577 | generated cols  360.. 366 
    EQUB 10 ; original &24D8 | cavern cmd 24 | run=10 | delta=  +1 @ &2578 | generated cols  367.. 376 
    EQUB 20 ; original &24D9 | cavern cmd 25 | run=20 | delta=  +1 @ &2579 | generated cols  377.. 396 
    EQUB 20 ; original &24DA | cavern cmd 26 | run=20 | delta=  +1 @ &257A | generated cols  397.. 416 
    EQUB 5  ; original &24DB | cavern cmd 27 | run= 5 | delta=  -1 @ &257B | generated cols  417.. 421 
    EQUB 30 ; original &24DC | cavern cmd 28 | run=30 | delta=  +1 @ &257C | generated cols  422.. 451 
    EQUB 20 ; original &24DD | cavern cmd 29 | run=20 | delta=  -1 @ &257D | generated cols  452.. 471 
    EQUB 25 ; original &24DE | cavern cmd 30 | run=25 | delta=  +1 @ &257E | generated cols  472.. 496 
    EQUB 7  ; original &24DF | cavern cmd 31 | run= 7 | delta=  -2 @ &257F | generated cols  497.. 503 
    EQUB 30 ; original &24E0 | cavern cmd 32 | run=30 | delta=  +1 @ &2580 | generated cols  504.. 533 
    EQUB 30 ; original &24E1 | cavern cmd 33 | run=30 | delta=  -1 @ &2581 | generated cols  534.. 563 
    EQUB 20 ; original &24E2 | cavern cmd 34 | run=20 | delta=  +1 @ &2582 | generated cols  564.. 583 
    EQUB 30 ; original &24E3 | cavern cmd 35 | run=30 | delta=  +1 @ &2583 | generated cols  584.. 613 
    EQUB 10 ; original &24E4 | cavern cmd 36 | run=10 | delta=  -1 @ &2584 | generated cols  614.. 623 
    EQUB 10 ; original &24E5 | cavern cmd 37 | run=10 | delta=  -1 @ &2585 | generated cols  624.. 633 
    EQUB 30 ; original &24E6 | cavern cmd 38 | run=30 | delta=  +1 @ &2586 | generated cols  634.. 663 
    EQUB 20 ; original &24E7 | cavern cmd 39 | run=20 | delta=  -1 @ &2587 | generated cols  664.. 683 
    EQUB 10 ; original &24E8 | cavern cmd 40 | run=10 | delta=  +1 @ &2588 | generated cols  684.. 693 
    EQUB 15 ; original &24E9 | cavern cmd 41 | run=15 | delta=  +2 @ &2589 | generated cols  694.. 708 
    EQUB 20 ; original &24EA | cavern cmd 42 | run=20 | delta=  -1 @ &258A | generated cols  709.. 728 
    EQUB 30 ; original &24EB | cavern cmd 43 | run=30 | delta=  +1 @ &258B | generated cols  729.. 758 
    EQUB 10 ; original &24EC | cavern cmd 44 | run=10 | delta=  +1 @ &258C | generated cols  759.. 768 
    EQUB 20 ; original &24ED | cavern cmd 45 | run=20 | delta=  -1 @ &258D | generated cols  769.. 788 
    EQUB 30 ; original &24EE | cavern cmd 46 | run=30 | delta=  +1 @ &258E | generated cols  789.. 818 
    EQUB 15 ; original &24EF | cavern cmd 47 | run=15 | delta=  -1 @ &258F | generated cols  819.. 833 
    EQUB 30 ; original &24F0 | cavern cmd 48 | run=30 | delta=  +1 @ &2590 | generated cols  834.. 863 
    EQUB 15 ; original &24F1 | cavern cmd 49 | run=15 | delta=  -1 @ &2591 | generated cols  864.. 878 
    EQUB 20 ; original &24F2 | cavern cmd 50 | run=20 | delta=  +1 @ &2592 | generated cols  879.. 898 
    EQUB 30 ; original &24F3 | cavern cmd 51 | run=30 | delta=  +1 @ &2593 | generated cols  899.. 928 
    EQUB 20 ; original &24F4 | cavern cmd 52 | run=20 | delta=  -1 @ &2594 | generated cols  929.. 948 
    EQUB 25 ; original &24F5 | cavern cmd 53 | run=25 | delta=  +1 @ &2595 | generated cols  949.. 973 
    EQUB 30 ; original &24F6 | cavern cmd 54 | run=30 | delta=  +2 @ &2596 | generated cols  974..1003 
    EQUB 21 ; original &24F7 | cavern cmd 55 | run=21 | delta=  +2 @ &2597 | generated cols 1004..1024 ; only first 18 visible, 3 discarded
lower_maze_commands:
    EQUB 1  ; original &24F8 | maze cmd 00 | run= 1 | delta= -10 @ &2598 | generated cols    0..   0 
    EQUB 30 ; original &24F9 | maze cmd 01 | run=30 | delta=  +0 @ &2599 | generated cols    1..  30 
    EQUB 30 ; original &24FA | maze cmd 02 | run=30 | delta=  +0 @ &259A | generated cols   31..  60 
    EQUB 30 ; original &24FB | maze cmd 03 | run=30 | delta=  +0 @ &259B | generated cols   61..  90 
    EQUB 30 ; original &24FC | maze cmd 04 | run=30 | delta=  +0 @ &259C | generated cols   91.. 120 
    EQUB 1  ; original &24FD | maze cmd 05 | run= 1 | delta=-100 @ &259D | generated cols  121.. 121 
    EQUB 20 ; original &24FE | maze cmd 06 | run=20 | delta=  +0 @ &259E | generated cols  122.. 141 
    EQUB 1  ; original &24FF | maze cmd 07 | run= 1 | delta= -30 @ &259F | generated cols  142.. 142 
    EQUB 30 ; original &2500 | maze cmd 08 | run=30 | delta=  +0 @ &25A0 | generated cols  143.. 172 
    EQUB 1  ; original &2501 | maze cmd 09 | run= 1 | delta= +90 @ &25A1 | generated cols  173.. 173 
    EQUB 30 ; original &2502 | maze cmd 10 | run=30 | delta=  +0 @ &25A2 | generated cols  174.. 203 
    EQUB 30 ; original &2503 | maze cmd 11 | run=30 | delta=  +0 @ &25A3 | generated cols  204.. 233 
    EQUB 30 ; original &2504 | maze cmd 12 | run=30 | delta=  +0 @ &25A4 | generated cols  234.. 263 
    EQUB 30 ; original &2505 | maze cmd 13 | run=30 | delta=  +0 @ &25A5 | generated cols  264.. 293 
    EQUB 30 ; original &2506 | maze cmd 14 | run=30 | delta=  +0 @ &25A6 | generated cols  294.. 323 
    EQUB 1  ; original &2507 | maze cmd 15 | run= 1 | delta= -60 @ &25A7 | generated cols  324.. 324 
    EQUB 30 ; original &2508 | maze cmd 16 | run=30 | delta=  +0 @ &25A8 | generated cols  325.. 354 
    EQUB 1  ; original &2509 | maze cmd 17 | run= 1 | delta= -30 @ &25A9 | generated cols  355.. 355 
    EQUB 30 ; original &250A | maze cmd 18 | run=30 | delta=  +0 @ &25AA | generated cols  356.. 385 
    EQUB 1  ; original &250B | maze cmd 19 | run= 1 | delta= +90 @ &25AB | generated cols  386.. 386 
    EQUB 30 ; original &250C | maze cmd 20 | run=30 | delta=  +0 @ &25AC | generated cols  387.. 416 
    EQUB 30 ; original &250D | maze cmd 21 | run=30 | delta=  +0 @ &25AD | generated cols  417.. 446 
    EQUB 30 ; original &250E | maze cmd 22 | run=30 | delta=  +0 @ &25AE | generated cols  447.. 476 
    EQUB 20 ; original &250F | maze cmd 23 | run=20 | delta=  +0 @ &25AF | generated cols  477.. 496 
    EQUB 1  ; original &2510 | maze cmd 24 | run= 1 | delta= -50 @ &25B0 | generated cols  497.. 497 
    EQUB 30 ; original &2511 | maze cmd 25 | run=30 | delta=  +0 @ &25B1 | generated cols  498.. 527 
    EQUB 1  ; original &2512 | maze cmd 26 | run= 1 | delta= -50 @ &25B2 | generated cols  528.. 528 
    EQUB 20 ; original &2513 | maze cmd 27 | run=20 | delta=  +0 @ &25B3 | generated cols  529.. 548 
    EQUB 1  ; original &2514 | maze cmd 28 | run= 1 | delta= +50 @ &25B4 | generated cols  549.. 549 
    EQUB 30 ; original &2515 | maze cmd 29 | run=30 | delta=  +0 @ &25B5 | generated cols  550.. 579 
    EQUB 1  ; original &2516 | maze cmd 30 | run= 1 | delta= +60 @ &25B6 | generated cols  580.. 580 
    EQUB 30 ; original &2517 | maze cmd 31 | run=30 | delta=  +0 @ &25B7 | generated cols  581.. 610 
    EQUB 30 ; original &2518 | maze cmd 32 | run=30 | delta=  +0 @ &25B8 | generated cols  611.. 640 
    EQUB 20 ; original &2519 | maze cmd 33 | run=20 | delta=  +0 @ &25B9 | generated cols  641.. 660 
    EQUB 1  ; original &251A | maze cmd 34 | run= 1 | delta=-110 @ &25BA | generated cols  661.. 661 
    EQUB 30 ; original &251B | maze cmd 35 | run=30 | delta=  +0 @ &25BB | generated cols  662.. 691 
    EQUB 1  ; original &251C | maze cmd 36 | run= 1 | delta=+120 @ &25BC | generated cols  692.. 692 
    EQUB 30 ; original &251D | maze cmd 37 | run=30 | delta=  +0 @ &25BD | generated cols  693.. 722 
    EQUB 30 ; original &251E | maze cmd 38 | run=30 | delta=  +0 @ &25BE | generated cols  723.. 752 
    EQUB 30 ; original &251F | maze cmd 39 | run=30 | delta=  +0 @ &25BF | generated cols  753.. 782 
    EQUB 20 ; original &2520 | maze cmd 40 | run=20 | delta=  +0 @ &25C0 | generated cols  783.. 802 
    EQUB 1  ; original &2521 | maze cmd 41 | run= 1 | delta=-107 @ &25C1 | generated cols  803.. 803 
    EQUB 5  ; original &2522 | maze cmd 42 | run= 5 | delta=  +0 @ &25C2 | generated cols  804.. 808 
    EQUB 1  ; original &2523 | maze cmd 43 | run= 1 | delta=+117 @ &25C3 | generated cols  809.. 809 
    EQUB 30 ; original &2524 | maze cmd 44 | run=30 | delta=  +0 @ &25C4 | generated cols  810.. 839 
    EQUB 1  ; original &2525 | maze cmd 45 | run= 1 | delta= -70 @ &25C5 | generated cols  840.. 840 
    EQUB 30 ; original &2526 | maze cmd 46 | run=30 | delta=  +0 @ &25C6 | generated cols  841.. 870 
    EQUB 1  ; original &2527 | maze cmd 47 | run= 1 | delta= +40 @ &25C7 | generated cols  871.. 871 
    EQUB 30 ; original &2528 | maze cmd 48 | run=30 | delta=  +0 @ &25C8 | generated cols  872.. 901 
    EQUB 30 ; original &2529 | maze cmd 49 | run=30 | delta=  +0 @ &25C9 | generated cols  902.. 931 
    EQUB 30 ; original &252A | maze cmd 50 | run=30 | delta=  +0 @ &25CA | generated cols  932.. 961 
    EQUB 1  ; original &252B | maze cmd 51 | run= 1 | delta=-100 @ &25CB | generated cols  962.. 962 
    EQUB 10 ; original &252C | maze cmd 52 | run=10 | delta=  +0 @ &25CC | generated cols  963.. 972 
    EQUB 1  ; original &252D | maze cmd 53 | run= 1 | delta= +50 @ &25CD | generated cols  973.. 973 
    EQUB 30 ; original &252E | maze cmd 54 | run=30 | delta=  +0 @ &25CE | generated cols  974..1003 
    EQUB 30 ; original &252F | maze cmd 55 | run=30 | delta=  +0 @ &25CF | generated cols 1004..1033 
    EQUB 1  ; original &2530 | maze cmd 56 | run= 1 | delta= +50 @ &25D0 | generated cols 1034..1034 
    EQUB 30 ; original &2531 | maze cmd 57 | run=30 | delta=  +0 @ &25D1 | generated cols 1035..1064 
    EQUB 30 ; original &2532 | maze cmd 58 | run=30 | delta=  +0 @ &25D2 | generated cols 1065..1094 
    EQUB 30 ; original &2533 | maze cmd 59 | run=30 | delta=  +0 @ &25D3 | generated cols 1095..1124 
    EQUB 1  ; original &2534 | maze cmd 60 | run= 1 | delta=-100 @ &25D4 | generated cols 1125..1125 
    EQUB 30 ; original &2535 | maze cmd 61 | run=30 | delta=  +0 @ &25D5 | generated cols 1126..1155 
    EQUB 1  ; original &2536 | maze cmd 62 | run= 1 | delta= +40 @ &25D6 | generated cols 1156..1156 
    EQUB 25 ; original &2537 | maze cmd 63 | run=25 | delta=  +0 @ &25D7 | generated cols 1157..1181 
    EQUB 1  ; original &2538 | maze cmd 64 | run= 1 | delta= +60 @ &25D8 | generated cols 1182..1182 
    EQUB 30 ; original &2539 | maze cmd 65 | run=30 | delta=  +0 @ &25D9 | generated cols 1183..1212 
    EQUB 30 ; original &253A | maze cmd 66 | run=30 | delta=  +0 @ &25DA | generated cols 1213..1242 
    EQUB 30 ; original &253B | maze cmd 67 | run=30 | delta=  +0 @ &25DB | generated cols 1243..1272 
    EQUB 1  ; original &253C | maze cmd 68 | run= 1 | delta=-100 @ &25DC | generated cols 1273..1273 
    EQUB 30 ; original &253D | maze cmd 69 | run=30 | delta=  +0 @ &25DD | generated cols 1274..1303 
    EQUB 1  ; original &253E | maze cmd 70 | run= 1 | delta=+100 @ &25DE | generated cols 1304..1304 
    EQUB 10 ; original &253F | maze cmd 71 | run=10 | delta=  +0 @ &25DF | generated cols 1305..1314 
    EQUB 1  ; original &2540 | maze cmd 72 | run= 1 | delta= +60 @ &25E0 | generated cols 1315..1315 
    EQUB 30 ; original &2541 | maze cmd 73 | run=30 | delta=  +0 @ &25E1 | generated cols 1316..1345 ; only first 12 visible, 18 discarded
lower_unused_tail_commands:
    EQUB 6  ; original &2542 | unused_tail cmd 00 | run= 6 | delta=  -6 @ &25E2 | generated cols    0..   5 ; unreachable tail in shipped section schedule
    EQUB 6  ; original &2543 | unused_tail cmd 01 | run= 6 | delta=  +6 @ &25E3 | generated cols    6..  11 ; unreachable tail in shipped section schedule
lower_terrain_end_marker:
    EQUB TERRAIN_CMD_END_MARKER ; original &2544 - physically present, but never reached
; &2545-&255F: preserved original build/source residue (not terrain).
    EQUB &34, &26, &DD, &F2, &73, &61, &76, &65, &20, &FF, &28, &22, &53, &2E, &53, &52    ; original &2545
    EQUB &43, &45, &20, &22, &2B, &C3, &7E, &90, &2B, &22, &20    ; original &2555
; LOWER TERRAIN SIGNED DELTAS (&2560-&25E3)
lower_terrain_deltas:
lower_cavern_deltas:
    EQUB &FE ; original &2560 | signed -2 | paired command &24C0
    EQUB &FF ; original &2561 | signed -1 | paired command &24C1
    EQUB &FD ; original &2562 | signed -3 | paired command &24C2
    EQUB &02 ; original &2563 | signed +2 | paired command &24C3
    EQUB &01 ; original &2564 | signed +1 | paired command &24C4
    EQUB &FF ; original &2565 | signed -1 | paired command &24C5
    EQUB &01 ; original &2566 | signed +1 | paired command &24C6
    EQUB &FF ; original &2567 | signed -1 | paired command &24C7
    EQUB &01 ; original &2568 | signed +1 | paired command &24C8
    EQUB &FF ; original &2569 | signed -1 | paired command &24C9
    EQUB &02 ; original &256A | signed +2 | paired command &24CA
    EQUB &01 ; original &256B | signed +1 | paired command &24CB
    EQUB &FF ; original &256C | signed -1 | paired command &24CC
    EQUB &01 ; original &256D | signed +1 | paired command &24CD
    EQUB &01 ; original &256E | signed +1 | paired command &24CE
    EQUB &FF ; original &256F | signed -1 | paired command &24CF
    EQUB &01 ; original &2570 | signed +1 | paired command &24D0
    EQUB &01 ; original &2571 | signed +1 | paired command &24D1
    EQUB &FF ; original &2572 | signed -1 | paired command &24D2
    EQUB &01 ; original &2573 | signed +1 | paired command &24D3
    EQUB &FF ; original &2574 | signed -1 | paired command &24D4
    EQUB &01 ; original &2575 | signed +1 | paired command &24D5
    EQUB &01 ; original &2576 | signed +1 | paired command &24D6
    EQUB &FE ; original &2577 | signed -2 | paired command &24D7
    EQUB &01 ; original &2578 | signed +1 | paired command &24D8
    EQUB &01 ; original &2579 | signed +1 | paired command &24D9
    EQUB &01 ; original &257A | signed +1 | paired command &24DA
    EQUB &FF ; original &257B | signed -1 | paired command &24DB
    EQUB &01 ; original &257C | signed +1 | paired command &24DC
    EQUB &FF ; original &257D | signed -1 | paired command &24DD
    EQUB &01 ; original &257E | signed +1 | paired command &24DE
    EQUB &FE ; original &257F | signed -2 | paired command &24DF
    EQUB &01 ; original &2580 | signed +1 | paired command &24E0
    EQUB &FF ; original &2581 | signed -1 | paired command &24E1
    EQUB &01 ; original &2582 | signed +1 | paired command &24E2
    EQUB &01 ; original &2583 | signed +1 | paired command &24E3
    EQUB &FF ; original &2584 | signed -1 | paired command &24E4
    EQUB &FF ; original &2585 | signed -1 | paired command &24E5
    EQUB &01 ; original &2586 | signed +1 | paired command &24E6
    EQUB &FF ; original &2587 | signed -1 | paired command &24E7
    EQUB &01 ; original &2588 | signed +1 | paired command &24E8
    EQUB &02 ; original &2589 | signed +2 | paired command &24E9
    EQUB &FF ; original &258A | signed -1 | paired command &24EA
    EQUB &01 ; original &258B | signed +1 | paired command &24EB
    EQUB &01 ; original &258C | signed +1 | paired command &24EC
    EQUB &FF ; original &258D | signed -1 | paired command &24ED
    EQUB &01 ; original &258E | signed +1 | paired command &24EE
    EQUB &FF ; original &258F | signed -1 | paired command &24EF
    EQUB &01 ; original &2590 | signed +1 | paired command &24F0
    EQUB &FF ; original &2591 | signed -1 | paired command &24F1
    EQUB &01 ; original &2592 | signed +1 | paired command &24F2
    EQUB &01 ; original &2593 | signed +1 | paired command &24F3
    EQUB &FF ; original &2594 | signed -1 | paired command &24F4
    EQUB &01 ; original &2595 | signed +1 | paired command &24F5
    EQUB &02 ; original &2596 | signed +2 | paired command &24F6
    EQUB &02 ; original &2597 | signed +2 | paired command &24F7
lower_maze_deltas:
    EQUB &F6 ; original &2598 | signed -10 | paired command &24F8
    EQUB &00 ; original &2599 | signed +0 | paired command &24F9
    EQUB &00 ; original &259A | signed +0 | paired command &24FA
    EQUB &00 ; original &259B | signed +0 | paired command &24FB
    EQUB &00 ; original &259C | signed +0 | paired command &24FC
    EQUB &9C ; original &259D | signed -100 | paired command &24FD
    EQUB &00 ; original &259E | signed +0 | paired command &24FE
    EQUB &E2 ; original &259F | signed -30 | paired command &24FF
    EQUB &00 ; original &25A0 | signed +0 | paired command &2500
    EQUB &5A ; original &25A1 | signed +90 | paired command &2501
    EQUB &00 ; original &25A2 | signed +0 | paired command &2502
    EQUB &00 ; original &25A3 | signed +0 | paired command &2503
    EQUB &00 ; original &25A4 | signed +0 | paired command &2504
    EQUB &00 ; original &25A5 | signed +0 | paired command &2505
    EQUB &00 ; original &25A6 | signed +0 | paired command &2506
    EQUB &C4 ; original &25A7 | signed -60 | paired command &2507
    EQUB &00 ; original &25A8 | signed +0 | paired command &2508
    EQUB &E2 ; original &25A9 | signed -30 | paired command &2509
    EQUB &00 ; original &25AA | signed +0 | paired command &250A
    EQUB &5A ; original &25AB | signed +90 | paired command &250B
    EQUB &00 ; original &25AC | signed +0 | paired command &250C
    EQUB &00 ; original &25AD | signed +0 | paired command &250D
    EQUB &00 ; original &25AE | signed +0 | paired command &250E
    EQUB &00 ; original &25AF | signed +0 | paired command &250F
    EQUB &CE ; original &25B0 | signed -50 | paired command &2510
    EQUB &00 ; original &25B1 | signed +0 | paired command &2511
    EQUB &CE ; original &25B2 | signed -50 | paired command &2512
    EQUB &00 ; original &25B3 | signed +0 | paired command &2513
    EQUB &32 ; original &25B4 | signed +50 | paired command &2514
    EQUB &00 ; original &25B5 | signed +0 | paired command &2515
    EQUB &3C ; original &25B6 | signed +60 | paired command &2516
    EQUB &00 ; original &25B7 | signed +0 | paired command &2517
    EQUB &00 ; original &25B8 | signed +0 | paired command &2518
    EQUB &00 ; original &25B9 | signed +0 | paired command &2519
    EQUB &92 ; original &25BA | signed -110 | paired command &251A
    EQUB &00 ; original &25BB | signed +0 | paired command &251B
    EQUB &78 ; original &25BC | signed +120 | paired command &251C
    EQUB &00 ; original &25BD | signed +0 | paired command &251D
    EQUB &00 ; original &25BE | signed +0 | paired command &251E
    EQUB &00 ; original &25BF | signed +0 | paired command &251F
    EQUB &00 ; original &25C0 | signed +0 | paired command &2520
    EQUB &95 ; original &25C1 | signed -107 | paired command &2521
    EQUB &00 ; original &25C2 | signed +0 | paired command &2522
    EQUB &75 ; original &25C3 | signed +117 | paired command &2523
    EQUB &00 ; original &25C4 | signed +0 | paired command &2524
    EQUB &BA ; original &25C5 | signed -70 | paired command &2525
    EQUB &00 ; original &25C6 | signed +0 | paired command &2526
    EQUB &28 ; original &25C7 | signed +40 | paired command &2527
    EQUB &00 ; original &25C8 | signed +0 | paired command &2528
    EQUB &00 ; original &25C9 | signed +0 | paired command &2529
    EQUB &00 ; original &25CA | signed +0 | paired command &252A
    EQUB &9C ; original &25CB | signed -100 | paired command &252B
    EQUB &00 ; original &25CC | signed +0 | paired command &252C
    EQUB &32 ; original &25CD | signed +50 | paired command &252D
    EQUB &00 ; original &25CE | signed +0 | paired command &252E
    EQUB &00 ; original &25CF | signed +0 | paired command &252F
    EQUB &32 ; original &25D0 | signed +50 | paired command &2530
    EQUB &00 ; original &25D1 | signed +0 | paired command &2531
    EQUB &00 ; original &25D2 | signed +0 | paired command &2532
    EQUB &00 ; original &25D3 | signed +0 | paired command &2533
    EQUB &9C ; original &25D4 | signed -100 | paired command &2534
    EQUB &00 ; original &25D5 | signed +0 | paired command &2535
    EQUB &28 ; original &25D6 | signed +40 | paired command &2536
    EQUB &00 ; original &25D7 | signed +0 | paired command &2537
    EQUB &3C ; original &25D8 | signed +60 | paired command &2538
    EQUB &00 ; original &25D9 | signed +0 | paired command &2539
    EQUB &00 ; original &25DA | signed +0 | paired command &253A
    EQUB &00 ; original &25DB | signed +0 | paired command &253B
    EQUB &9C ; original &25DC | signed -100 | paired command &253C
    EQUB &00 ; original &25DD | signed +0 | paired command &253D
    EQUB &64 ; original &25DE | signed +100 | paired command &253E
    EQUB &00 ; original &25DF | signed +0 | paired command &253F
    EQUB &3C ; original &25E0 | signed +60 | paired command &2540
    EQUB &00 ; original &25E1 | signed +0 | paired command &2541
lower_unused_tail_deltas:
    EQUB &FA ; original &25E2 | signed -6 | paired command &2542
    EQUB &06 ; original &25E3 | signed +6 | paired command &2543
; &25E4-&25FF: preserved source/build residue.
    EQUB &FF, &20, &0D, &27, &D8, &0E, &2E, &67, &65, &74, &64, &69, &67, &69, &74, &73    ; original &25E4
    EQUB &0D, &28, &3C, &2E, &50, &48, &41, &3A, &80, &23, &26, &46    ; original &25F4

; UPPER TERRAIN COMMAND STREAM (&2600-&27E5 original layout)
; -----------------------------------------------------------------------------
; Command format:
;   bit 7      end-of-raid marker (&FF in shipped stream)
;   bit 6      NO FIXED SCENERY on this flat run (proven: all 129 uses have delta=0)
;   bit 5      unused by decoder
;   bits 0..4  run length, 1..31 generated columns
;
; Each command has a byte-for-byte parallel signed delta in &2800-&29E4.
; Non-zero deltas receive per-sample PRNG jitter.  Zero-delta runs are exact flats.
; Fixed scenery can start only on a zero-delta flat with bit 6 CLEAR.
; -----------------------------------------------------------------------------
upper_terrain_commands:
upper_section0_commands:
; SECTION 0 - FUEL DEPOT / MOUNTAINS | 75 commands | 1025 generated columns
    EQUB 30                                 ; original &2600 | cmd 000 | cols    0..  29 | delta=  +4 @ &2800 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2601 | cmd 001 | cols   30..  39 | delta=  -3 @ &2801 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 31                                 ; original &2602 | cmd 002 | cols   40..  70 | delta=  +0 @ &2802 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2603 | cmd 003 | cols   71..  80 | delta=  +3 @ &2803 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2604 | cmd 004 | cols   81.. 110 | delta=  -2 @ &2804 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2605 | cmd 005 | cols  111.. 130 | delta=  -2 @ &2805 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2606 | cmd 006 | cols  131.. 150 | delta=  +0 @ &2806 | flat plateau; scenery eligible | scenery-ok
    EQUB 14                                 ; original &2607 | cmd 007 | cols  151.. 164 | delta=  +2 @ &2807 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 14                                 ; original &2608 | cmd 008 | cols  165.. 178 | delta=  -2 @ &2808 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2609 | cmd 009 | cols  179.. 208 | delta=  +0 @ &2809 | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &260A | cmd 010 | cols  209.. 223 | delta=  +3 @ &280A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &260B | cmd 011 | cols  224.. 238 | delta=  +0 @ &280B | flat plateau; scenery eligible | scenery-ok
    EQUB 12                                 ; original &260C | cmd 012 | cols  239.. 250 | delta=  +2 @ &280C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &260D | cmd 013 | cols  251.. 270 | delta=  +0 @ &280D | flat plateau; scenery eligible | scenery-ok
    EQUB 12                                 ; original &260E | cmd 014 | cols  271.. 282 | delta=  +2 @ &280E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 13                                 ; original &260F | cmd 015 | cols  283.. 295 | delta=  +0 @ &280F | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &2610 | cmd 016 | cols  296.. 315 | delta=  +3 @ &2810 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2611 | cmd 017 | cols  316.. 335 | delta=  +3 @ &2811 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2612 | cmd 018 | cols  336.. 350 | delta=  -4 @ &2812 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 4                                  ; original &2613 | cmd 019 | cols  351.. 354 | delta=  +0 @ &2813 | flat plateau; scenery eligible | scenery-ok
    EQUB 8                                  ; original &2614 | cmd 020 | cols  355.. 362 | delta=  +4 @ &2814 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 4                                  ; original &2615 | cmd 021 | cols  363.. 366 | delta=  +0 @ &2815 | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &2616 | cmd 022 | cols  367.. 381 | delta=  -3 @ &2816 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 8                                  ; original &2617 | cmd 023 | cols  382.. 389 | delta=  +0 @ &2817 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &2618 | cmd 024 | cols  390.. 409 | delta=  +4 @ &2818 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2619 | cmd 025 | cols  410.. 439 | delta=  -4 @ &2819 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &261A | cmd 026 | cols  440.. 459 | delta=  +0 @ &281A | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &261B | cmd 027 | cols  460.. 469 | delta=  +2 @ &281B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &261C | cmd 028 | cols  470.. 479 | delta=  +4 @ &281C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 8                                  ; original &261D | cmd 029 | cols  480.. 487 | delta=  +0 @ &281D | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &261E | cmd 030 | cols  488.. 507 | delta=  -3 @ &281E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &261F | cmd 031 | cols  508.. 517 | delta=  +0 @ &281F | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &2620 | cmd 032 | cols  518.. 532 | delta=  +1 @ &2820 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2621 | cmd 033 | cols  533.. 542 | delta=  +3 @ &2821 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2622 | cmd 034 | cols  543.. 562 | delta=  -1 @ &2822 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2623 | cmd 035 | cols  563.. 572 | delta=  +0 @ &2823 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2624 | cmd 036 | cols  573.. 582 | delta=  +3 @ &2824 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2625 | cmd 037 | cols  583.. 592 | delta=  +0 @ &2825 | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &2626 | cmd 038 | cols  593.. 607 | delta=  +4 @ &2826 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2627 | cmd 039 | cols  608.. 612 | delta=  +0 @ &2827 | flat plateau; scenery eligible | scenery-ok
    EQUB 12                                 ; original &2628 | cmd 040 | cols  613.. 624 | delta=  +2 @ &2828 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 16                                 ; original &2629 | cmd 041 | cols  625.. 640 | delta=  +0 @ &2829 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &262A | cmd 042 | cols  641.. 650 | delta=  -3 @ &282A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &262B | cmd 043 | cols  651.. 660 | delta=  +0 @ &282B | flat plateau; scenery eligible | scenery-ok
    EQUB 14                                 ; original &262C | cmd 044 | cols  661.. 674 | delta=  -1 @ &282C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 12                                 ; original &262D | cmd 045 | cols  675.. 686 | delta=  +0 @ &282D | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &262E | cmd 046 | cols  687.. 701 | delta=  +1 @ &282E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 12                                 ; original &262F | cmd 047 | cols  702.. 713 | delta=  +0 @ &282F | flat plateau; scenery eligible | scenery-ok
    EQUB 5                                  ; original &2630 | cmd 048 | cols  714.. 718 | delta=  -2 @ &2830 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2631 | cmd 049 | cols  719.. 723 | delta=  +0 @ &2831 | flat plateau; scenery eligible | scenery-ok
    EQUB 30                                 ; original &2632 | cmd 050 | cols  724.. 753 | delta=  +2 @ &2832 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2633 | cmd 051 | cols  754.. 768 | delta=  +0 @ &2833 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2634 | cmd 052 | cols  769.. 778 | delta=  +2 @ &2834 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2635 | cmd 053 | cols  779.. 808 | delta=  +0 @ &2835 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2636 | cmd 054 | cols  809.. 818 | delta=  -3 @ &2836 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2637 | cmd 055 | cols  819.. 823 | delta=  +0 @ &2837 | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &2638 | cmd 056 | cols  824.. 838 | delta=  +3 @ &2838 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2639 | cmd 057 | cols  839.. 853 | delta=  +0 @ &2839 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &263A | cmd 058 | cols  854.. 863 | delta=  +2 @ &283A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &263B | cmd 059 | cols  864.. 873 | delta=  +0 @ &283B | flat plateau; scenery eligible | scenery-ok
    EQUB 13                                 ; original &263C | cmd 060 | cols  874.. 886 | delta=  +4 @ &283C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 12                                 ; original &263D | cmd 061 | cols  887.. 898 | delta=  +0 @ &283D | flat plateau; scenery eligible | scenery-ok
    EQUB 13                                 ; original &263E | cmd 062 | cols  899.. 911 | delta=  +4 @ &283E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &263F | cmd 063 | cols  912.. 916 | delta=  +0 @ &283F | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2640 | cmd 064 | cols  917.. 926 | delta=  -4 @ &2840 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2641 | cmd 065 | cols  927.. 931 | delta=  +0 @ &2841 | flat plateau; scenery eligible | scenery-ok
    EQUB 7                                  ; original &2642 | cmd 066 | cols  932.. 938 | delta=  +3 @ &2842 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2643 | cmd 067 | cols  939.. 943 | delta=  +0 @ &2843 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2644 | cmd 068 | cols  944.. 953 | delta=  -3 @ &2844 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2645 | cmd 069 | cols  954.. 968 | delta=  -2 @ &2845 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2646 | cmd 070 | cols  969.. 978 | delta=  +0 @ &2846 | flat plateau; scenery eligible | scenery-ok
    EQUB 15                                 ; original &2647 | cmd 071 | cols  979.. 993 | delta=  -1 @ &2847 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 6                                  ; original &2648 | cmd 072 | cols  994.. 999 | delta=  -1 @ &2848 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2649 | cmd 073 | cols 1000..1009 | delta=  -1 @ &2849 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &264A | cmd 074 | cols 1010..1024 | delta=  +2 @ &284A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
upper_section1_commands:
; SECTION 1 - CAVERN | 60 commands | 1022 generated columns
    EQUB 15                                 ; original &264B | cmd 000 | cols    0..  14 | delta=  -1 @ &284B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &264C | cmd 001 | cols   15..  24 | delta=  +2 @ &284C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &264D | cmd 002 | cols   25..  44 | delta=  +1 @ &284D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &264E | cmd 003 | cols   45..  74 | delta=  -1 @ &284E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &264F | cmd 004 | cols   75.. 104 | delta=  +1 @ &284F | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2650 | cmd 005 | cols  105.. 114 | delta=  +2 @ &2850 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2651 | cmd 006 | cols  115.. 124 | delta=  +1 @ &2851 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2652 | cmd 007 | cols  125.. 144 | delta=  +1 @ &2852 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2653 | cmd 008 | cols  145.. 154 | delta=  -1 @ &2853 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2654 | cmd 009 | cols  155.. 169 | delta=  +2 @ &2854 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2655 | cmd 010 | cols  170.. 179 | delta=  -1 @ &2855 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2656 | cmd 011 | cols  180.. 189 | delta=  +1 @ &2856 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2657 | cmd 012 | cols  190.. 209 | delta=  +1 @ &2857 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &2658 | cmd 013 | cols  210.. 224 | delta=  -1 @ &2858 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2659 | cmd 014 | cols  225.. 229 | delta=  +1 @ &2859 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &265A | cmd 015 | cols  230.. 234 | delta=  +2 @ &285A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &265B | cmd 016 | cols  235.. 254 | delta=  +1 @ &285B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &265C | cmd 017 | cols  255.. 264 | delta=  -1 @ &285C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &265D | cmd 018 | cols  265.. 294 | delta=  +1 @ &285D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &265E | cmd 019 | cols  295.. 324 | delta=  +1 @ &285E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &265F | cmd 020 | cols  325.. 334 | delta=  -1 @ &285F | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2660 | cmd 021 | cols  335.. 364 | delta=  +1 @ &2860 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2661 | cmd 022 | cols  365.. 394 | delta=  +1 @ &2861 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2662 | cmd 023 | cols  395.. 414 | delta=  +1 @ &2862 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2663 | cmd 024 | cols  415.. 434 | delta=  +1 @ &2863 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2664 | cmd 025 | cols  435.. 444 | delta=  -1 @ &2864 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2665 | cmd 026 | cols  445.. 474 | delta=  +1 @ &2865 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2666 | cmd 027 | cols  475.. 494 | delta=  -1 @ &2866 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2667 | cmd 028 | cols  495.. 524 | delta=  +1 @ &2867 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2668 | cmd 029 | cols  525.. 534 | delta=  -1 @ &2868 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2669 | cmd 030 | cols  535.. 564 | delta=  +1 @ &2869 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &266A | cmd 031 | cols  565.. 574 | delta=  -1 @ &286A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &266B | cmd 032 | cols  575.. 579 | delta=  +2 @ &286B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &266C | cmd 033 | cols  580.. 609 | delta=  +1 @ &286C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &266D | cmd 034 | cols  610.. 619 | delta=  -1 @ &286D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &266E | cmd 035 | cols  620.. 639 | delta=  +1 @ &286E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &266F | cmd 036 | cols  640.. 649 | delta=  -1 @ &286F | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2670 | cmd 037 | cols  650.. 679 | delta=  +1 @ &2870 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2671 | cmd 038 | cols  680.. 689 | delta=  -1 @ &2871 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2672 | cmd 039 | cols  690.. 719 | delta=  +1 @ &2872 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &2673 | cmd 040 | cols  720.. 724 | delta=  -1 @ &2873 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2674 | cmd 041 | cols  725.. 754 | delta=  +1 @ &2874 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2675 | cmd 042 | cols  755.. 764 | delta=  -1 @ &2875 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2676 | cmd 043 | cols  765.. 794 | delta=  +1 @ &2876 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2677 | cmd 044 | cols  795.. 814 | delta=  -1 @ &2877 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2678 | cmd 045 | cols  815.. 844 | delta=  +1 @ &2878 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2679 | cmd 046 | cols  845.. 854 | delta=  +1 @ &2879 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &267A | cmd 047 | cols  855.. 869 | delta=  -1 @ &287A | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &267B | cmd 048 | cols  870.. 899 | delta=  +1 @ &287B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &267C | cmd 049 | cols  900.. 909 | delta=  -1 @ &287C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &267D | cmd 050 | cols  910.. 914 | delta=  +3 @ &287D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 5                                  ; original &267E | cmd 051 | cols  915.. 919 | delta=  -2 @ &287E | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 14                                 ; original &267F | cmd 052 | cols  920.. 933 | delta=  +0 @ &287F | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &2680 | cmd 053 | cols  934.. 953 | delta=  +2 @ &2880 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2681 | cmd 054 | cols  954.. 963 | delta=  -2 @ &2881 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 10                                 ; original &2682 | cmd 055 | cols  964.. 973 | delta=  +0 @ &2882 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2683 | cmd 056 | cols  974.. 983 | delta=  +0 @ &2883 | flat plateau; scenery eligible | scenery-ok
    EQUB 10                                 ; original &2684 | cmd 057 | cols  984.. 993 | delta=  +0 @ &2884 | flat plateau; scenery eligible | scenery-ok
    EQUB 19                                 ; original &2685 | cmd 058 | cols  994..1012 | delta=  +3 @ &2885 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 9                                  ; original &2686 | cmd 059 | cols 1013..1021 | delta=  -1 @ &2886 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
upper_section2_commands:
; SECTION 2 - METEORITES | 72 commands | 1629 generated columns
meteorite_wave_train_commands:
; First 44 commands are eleven repeats of a 4-command terrain wave motif.
    EQUB 20                                 ; original &2687 | cmd 000 | cols    0..  19 | delta=  +1 @ &2887 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2688 | cmd 001 | cols   20..  49 | delta=  +1 @ &2888 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2689 | cmd 002 | cols   50..  69 | delta=  -1 @ &2889 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &268A | cmd 003 | cols   70..  89 | delta=  +0 @ &288A | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &268B | cmd 004 | cols   90.. 109 | delta=  +1 @ &288B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &268C | cmd 005 | cols  110.. 139 | delta=  +1 @ &288C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &268D | cmd 006 | cols  140.. 159 | delta=  -1 @ &288D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &268E | cmd 007 | cols  160.. 179 | delta=  +0 @ &288E | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &268F | cmd 008 | cols  180.. 199 | delta=  +1 @ &288F | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2690 | cmd 009 | cols  200.. 229 | delta=  +1 @ &2890 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2691 | cmd 010 | cols  230.. 249 | delta=  -1 @ &2891 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2692 | cmd 011 | cols  250.. 269 | delta=  +0 @ &2892 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &2693 | cmd 012 | cols  270.. 289 | delta=  +1 @ &2893 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2694 | cmd 013 | cols  290.. 319 | delta=  +1 @ &2894 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2695 | cmd 014 | cols  320.. 339 | delta=  -1 @ &2895 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2696 | cmd 015 | cols  340.. 359 | delta=  +0 @ &2896 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &2697 | cmd 016 | cols  360.. 379 | delta=  +1 @ &2897 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &2698 | cmd 017 | cols  380.. 409 | delta=  +1 @ &2898 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &2699 | cmd 018 | cols  410.. 429 | delta=  -1 @ &2899 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &269A | cmd 019 | cols  430.. 449 | delta=  +0 @ &289A | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &269B | cmd 020 | cols  450.. 469 | delta=  +1 @ &289B | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &269C | cmd 021 | cols  470.. 499 | delta=  +1 @ &289C | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &269D | cmd 022 | cols  500.. 519 | delta=  -1 @ &289D | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &269E | cmd 023 | cols  520.. 539 | delta=  +0 @ &289E | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &269F | cmd 024 | cols  540.. 559 | delta=  +1 @ &289F | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26A0 | cmd 025 | cols  560.. 589 | delta=  +1 @ &28A0 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26A1 | cmd 026 | cols  590.. 609 | delta=  -1 @ &28A1 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26A2 | cmd 027 | cols  610.. 629 | delta=  +0 @ &28A2 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26A3 | cmd 028 | cols  630.. 649 | delta=  +1 @ &28A3 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26A4 | cmd 029 | cols  650.. 679 | delta=  +1 @ &28A4 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26A5 | cmd 030 | cols  680.. 699 | delta=  -1 @ &28A5 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26A6 | cmd 031 | cols  700.. 719 | delta=  +0 @ &28A6 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26A7 | cmd 032 | cols  720.. 739 | delta=  +1 @ &28A7 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26A8 | cmd 033 | cols  740.. 769 | delta=  +1 @ &28A8 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26A9 | cmd 034 | cols  770.. 789 | delta=  -1 @ &28A9 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26AA | cmd 035 | cols  790.. 809 | delta=  +0 @ &28AA | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26AB | cmd 036 | cols  810.. 829 | delta=  +1 @ &28AB | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26AC | cmd 037 | cols  830.. 859 | delta=  +1 @ &28AC | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26AD | cmd 038 | cols  860.. 879 | delta=  -1 @ &28AD | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26AE | cmd 039 | cols  880.. 899 | delta=  +0 @ &28AE | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26AF | cmd 040 | cols  900.. 919 | delta=  +1 @ &28AF | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26B0 | cmd 041 | cols  920.. 949 | delta=  +1 @ &28B0 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26B1 | cmd 042 | cols  950.. 969 | delta=  -1 @ &28B1 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26B2 | cmd 043 | cols  970.. 989 | delta=  +0 @ &28B2 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26B3 | cmd 044 | cols  990..1009 | delta=  +1 @ &28B3 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26B4 | cmd 045 | cols 1010..1039 | delta=  +1 @ &28B4 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26B5 | cmd 046 | cols 1040..1059 | delta=  +0 @ &28B5 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26B6 | cmd 047 | cols 1060..1079 | delta=  +1 @ &28B6 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26B7 | cmd 048 | cols 1080..1109 | delta=  +1 @ &28B7 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26B8 | cmd 049 | cols 1110..1129 | delta=  -1 @ &28B8 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26B9 | cmd 050 | cols 1130..1149 | delta=  +0 @ &28B9 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26BA | cmd 051 | cols 1150..1169 | delta=  +1 @ &28BA | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26BB | cmd 052 | cols 1170..1199 | delta=  +1 @ &28BB | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26BC | cmd 053 | cols 1200..1219 | delta=  -1 @ &28BC | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26BD | cmd 054 | cols 1220..1239 | delta=  +0 @ &28BD | flat plateau; scenery eligible | scenery-ok
    EQUB 30                                 ; original &26BE | cmd 055 | cols 1240..1269 | delta=  +1 @ &28BE | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26BF | cmd 056 | cols 1270..1299 | delta=  +1 @ &28BF | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 15                                 ; original &26C0 | cmd 057 | cols 1300..1314 | delta=  -1 @ &28C0 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26C1 | cmd 058 | cols 1315..1334 | delta=  +0 @ &28C1 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26C2 | cmd 059 | cols 1335..1354 | delta=  +1 @ &28C2 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26C3 | cmd 060 | cols 1355..1384 | delta=  +1 @ &28C3 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26C4 | cmd 061 | cols 1385..1404 | delta=  -1 @ &28C4 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26C5 | cmd 062 | cols 1405..1424 | delta=  +0 @ &28C5 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26C6 | cmd 063 | cols 1425..1444 | delta=  +1 @ &28C6 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26C7 | cmd 064 | cols 1445..1474 | delta=  +1 @ &28C7 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26C8 | cmd 065 | cols 1475..1494 | delta=  -1 @ &28C8 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26C9 | cmd 066 | cols 1495..1514 | delta=  +0 @ &28C9 | flat plateau; scenery eligible | scenery-ok
    EQUB 20                                 ; original &26CA | cmd 067 | cols 1515..1534 | delta=  +1 @ &28CA | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 30                                 ; original &26CB | cmd 068 | cols 1535..1564 | delta=  +1 @ &28CB | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26CC | cmd 069 | cols 1565..1584 | delta=  -1 @ &28CC | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 20                                 ; original &26CD | cmd 070 | cols 1585..1604 | delta=  +0 @ &28CD | flat plateau; scenery eligible | scenery-ok
    EQUB 24                                 ; original &26CE | cmd 071 | cols 1605..1628 | delta=  +1 @ &28CE | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
upper_section3_commands:
; SECTION 3 - SKYSCRAPERS | 96 commands | 805 generated columns
skyscraper_profile_commands:
; 96 commands = 48 (one-column vertical jump + flat rooftop) pairs.
    EQUB 1                                  ; original &26CF | cmd 000 | cols    0..   0 | delta=+127 @ &28CF | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &26D0 | cmd 001 | cols    1..  15 | delta=  +0 @ &28D0 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26D1 | cmd 002 | cols   16..  16 | delta= -20 @ &28D1 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26D2 | cmd 003 | cols   17..  36 | delta=  +0 @ &28D2 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26D3 | cmd 004 | cols   37..  37 | delta= +40 @ &28D3 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &26D4 | cmd 005 | cols   38..  47 | delta=  +0 @ &28D4 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26D5 | cmd 006 | cols   48..  48 | delta= -40 @ &28D5 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26D6 | cmd 007 | cols   49..  68 | delta=  +0 @ &28D6 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26D7 | cmd 008 | cols   69..  69 | delta= +20 @ &28D7 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &26D8 | cmd 009 | cols   70..  84 | delta=  +0 @ &28D8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26D9 | cmd 010 | cols   85..  85 | delta= +30 @ &28D9 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &26DA | cmd 011 | cols   86..  95 | delta=  +0 @ &28DA | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26DB | cmd 012 | cols   96..  96 | delta= -35 @ &28DB | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26DC | cmd 013 | cols   97.. 116 | delta=  +0 @ &28DC | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26DD | cmd 014 | cols  117.. 117 | delta= -70 @ &28DD | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &26DE | cmd 015 | cols  118.. 147 | delta=  +0 @ &28DE | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26DF | cmd 016 | cols  148.. 148 | delta= +20 @ &28DF | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &26E0 | cmd 017 | cols  149.. 163 | delta=  +0 @ &28E0 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26E1 | cmd 018 | cols  164.. 164 | delta= -30 @ &28E1 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26E2 | cmd 019 | cols  165.. 184 | delta=  +0 @ &28E2 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26E3 | cmd 020 | cols  185.. 185 | delta= -10 @ &28E3 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+25      ; original &26E4 | cmd 021 | cols  186.. 210 | delta=  +0 @ &28E4 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26E5 | cmd 022 | cols  211.. 211 | delta= +80 @ &28E5 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26E6 | cmd 023 | cols  212.. 231 | delta=  +0 @ &28E6 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26E7 | cmd 024 | cols  232.. 232 | delta= +10 @ &28E7 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &26E8 | cmd 025 | cols  233.. 247 | delta=  +0 @ &28E8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26E9 | cmd 026 | cols  248.. 248 | delta= -20 @ &28E9 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &26EA | cmd 027 | cols  249.. 258 | delta=  +0 @ &28EA | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26EB | cmd 028 | cols  259.. 259 | delta= +25 @ &28EB | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &26EC | cmd 029 | cols  260.. 269 | delta=  +0 @ &28EC | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26ED | cmd 030 | cols  270.. 270 | delta= -10 @ &28ED | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &26EE | cmd 031 | cols  271.. 285 | delta=  +0 @ &28EE | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26EF | cmd 032 | cols  286.. 286 | delta= -30 @ &28EF | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &26F0 | cmd 033 | cols  287.. 306 | delta=  +0 @ &28F0 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26F1 | cmd 034 | cols  307.. 307 | delta= +40 @ &28F1 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &26F2 | cmd 035 | cols  308.. 327 | delta=  +0 @ &28F2 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26F3 | cmd 036 | cols  328.. 328 | delta=-100 @ &28F3 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &26F4 | cmd 037 | cols  329.. 338 | delta=  +0 @ &28F4 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26F5 | cmd 038 | cols  339.. 339 | delta= +30 @ &28F5 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &26F6 | cmd 039 | cols  340.. 349 | delta=  +0 @ &28F6 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26F7 | cmd 040 | cols  350.. 350 | delta= +10 @ &28F7 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &26F8 | cmd 041 | cols  351.. 380 | delta=  +0 @ &28F8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26F9 | cmd 042 | cols  381.. 381 | delta= +20 @ &28F9 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &26FA | cmd 043 | cols  382.. 391 | delta=  +0 @ &28FA | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &26FB | cmd 044 | cols  392.. 392 | delta= -15 @ &28FB | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &26FC | cmd 045 | cols  393.. 402 | delta=  +0 @ &28FC | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26FD | cmd 046 | cols  403.. 403 | delta= +25 @ &28FD | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 5                                  ; original &26FE | cmd 047 | cols  404.. 408 | delta=  +0 @ &28FE | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &26FF | cmd 048 | cols  409.. 409 | delta= -30 @ &28FF | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2700 | cmd 049 | cols  410.. 429 | delta=  +0 @ &2900 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2701 | cmd 050 | cols  430.. 430 | delta= +10 @ &2901 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 5                                  ; original &2702 | cmd 051 | cols  431.. 435 | delta=  +0 @ &2902 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2703 | cmd 052 | cols  436.. 436 | delta= -60 @ &2903 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &2704 | cmd 053 | cols  437.. 451 | delta=  +0 @ &2904 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2705 | cmd 054 | cols  452.. 452 | delta= +20 @ &2905 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 15                                 ; original &2706 | cmd 055 | cols  453.. 467 | delta=  +0 @ &2906 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2707 | cmd 056 | cols  468.. 468 | delta= +30 @ &2907 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2708 | cmd 057 | cols  469.. 488 | delta=  +0 @ &2908 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2709 | cmd 058 | cols  489.. 489 | delta= +40 @ &2909 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &270A | cmd 059 | cols  490.. 499 | delta=  +0 @ &290A | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &270B | cmd 060 | cols  500.. 500 | delta= -20 @ &290B | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &270C | cmd 061 | cols  501.. 510 | delta=  +0 @ &290C | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &270D | cmd 062 | cols  511.. 511 | delta= +15 @ &290D | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 30                                 ; original &270E | cmd 063 | cols  512.. 541 | delta=  +0 @ &290E | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &270F | cmd 064 | cols  542.. 542 | delta= -40 @ &290F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &2710 | cmd 065 | cols  543.. 562 | delta=  +0 @ &2910 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2711 | cmd 066 | cols  563.. 563 | delta= -20 @ &2911 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2712 | cmd 067 | cols  564.. 593 | delta=  +0 @ &2912 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2713 | cmd 068 | cols  594.. 594 | delta= +30 @ &2913 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &2714 | cmd 069 | cols  595.. 604 | delta=  +0 @ &2914 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2715 | cmd 070 | cols  605.. 605 | delta= +30 @ &2915 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2716 | cmd 071 | cols  606.. 625 | delta=  +0 @ &2916 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2717 | cmd 072 | cols  626.. 626 | delta= +30 @ &2917 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &2718 | cmd 073 | cols  627.. 636 | delta=  +0 @ &2918 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2719 | cmd 074 | cols  637.. 637 | delta= -17 @ &2919 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 5                                  ; original &271A | cmd 075 | cols  638.. 642 | delta=  +0 @ &291A | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &271B | cmd 076 | cols  643.. 643 | delta= +20 @ &291B | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &271C | cmd 077 | cols  644.. 658 | delta=  +0 @ &291C | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &271D | cmd 078 | cols  659.. 659 | delta= -20 @ &291D | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &271E | cmd 079 | cols  660.. 669 | delta=  +0 @ &291E | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &271F | cmd 080 | cols  670.. 670 | delta= +17 @ &291F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2720 | cmd 081 | cols  671.. 690 | delta=  +0 @ &2920 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2721 | cmd 082 | cols  691.. 691 | delta=-127 @ &2921 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 20                                 ; original &2722 | cmd 083 | cols  692.. 711 | delta=  +0 @ &2922 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2723 | cmd 084 | cols  712.. 712 | delta= +20 @ &2923 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &2724 | cmd 085 | cols  713.. 722 | delta=  +0 @ &2924 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2725 | cmd 086 | cols  723.. 723 | delta= -20 @ &2925 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &2726 | cmd 087 | cols  724.. 733 | delta=  +0 @ &2926 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2727 | cmd 088 | cols  734.. 734 | delta= +30 @ &2927 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 10                                 ; original &2728 | cmd 089 | cols  735.. 744 | delta=  +0 @ &2928 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2729 | cmd 090 | cols  745.. 745 | delta= -20 @ &2929 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB 7                                  ; original &272A | cmd 091 | cols  746.. 752 | delta=  +0 @ &292A | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &272B | cmd 092 | cols  753.. 753 | delta= +20 @ &292B | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &272C | cmd 093 | cols  754.. 773 | delta=  +0 @ &292C | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &272D | cmd 094 | cols  774.. 774 | delta= -30 @ &292D | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &272E | cmd 095 | cols  775.. 804 | delta=  +0 @ &292E | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
upper_section4_commands:
; SECTION 4 - MAZE | 72 commands | 1328 generated columns
maze_profile_commands:
; Upper wall of the maze; the lower wall is generated simultaneously from lower_maze_commands.
    EQUB 5                                  ; original &272F | cmd 000 | cols    0..   4 | delta=  +0 @ &292F | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2730 | cmd 001 | cols    5..   5 | delta=+120 @ &2930 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2731 | cmd 002 | cols    6..  35 | delta=  +0 @ &2931 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &2732 | cmd 003 | cols   36..  65 | delta=  +0 @ &2932 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2733 | cmd 004 | cols   66..  66 | delta=-100 @ &2933 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2734 | cmd 005 | cols   67..  96 | delta=  +0 @ &2934 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2735 | cmd 006 | cols   97.. 126 | delta=  +0 @ &2935 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2736 | cmd 007 | cols  127.. 156 | delta=  +0 @ &2936 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2737 | cmd 008 | cols  157.. 186 | delta=  +0 @ &2937 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 20                                 ; original &2738 | cmd 009 | cols  187.. 206 | delta=  +0 @ &2938 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2739 | cmd 010 | cols  207.. 207 | delta=+100 @ &2939 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &273A | cmd 011 | cols  208.. 237 | delta=  +0 @ &293A | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &273B | cmd 012 | cols  238.. 257 | delta=  +0 @ &293B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &273C | cmd 013 | cols  258.. 258 | delta= -50 @ &293C | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &273D | cmd 014 | cols  259.. 288 | delta=  +0 @ &293D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &273E | cmd 015 | cols  289.. 308 | delta=  +0 @ &293E | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &273F | cmd 016 | cols  309.. 309 | delta= -40 @ &293F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2740 | cmd 017 | cols  310.. 339 | delta=  +0 @ &2940 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2741 | cmd 018 | cols  340.. 340 | delta= -30 @ &2941 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2742 | cmd 019 | cols  341.. 370 | delta=  +0 @ &2942 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2743 | cmd 020 | cols  371.. 400 | delta=  +0 @ &2943 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 20                                 ; original &2744 | cmd 021 | cols  401.. 420 | delta=  +0 @ &2944 | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &2745 | cmd 022 | cols  421.. 421 | delta=+100 @ &2945 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2746 | cmd 023 | cols  422.. 451 | delta=  +0 @ &2946 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2747 | cmd 024 | cols  452.. 452 | delta= -50 @ &2947 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2748 | cmd 025 | cols  453.. 482 | delta=  +0 @ &2948 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2749 | cmd 026 | cols  483.. 483 | delta= -50 @ &2949 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &274A | cmd 027 | cols  484.. 513 | delta=  +0 @ &294A | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &274B | cmd 028 | cols  514.. 543 | delta=  +0 @ &294B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &274C | cmd 029 | cols  544.. 573 | delta=  +0 @ &294C | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &274D | cmd 030 | cols  574.. 574 | delta= +50 @ &294D | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &274E | cmd 031 | cols  575.. 604 | delta=  +0 @ &294E | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &274F | cmd 032 | cols  605.. 605 | delta= +60 @ &294F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2750 | cmd 033 | cols  606.. 635 | delta=  +0 @ &2950 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2751 | cmd 034 | cols  636.. 636 | delta=-100 @ &2951 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2752 | cmd 035 | cols  637.. 666 | delta=  +0 @ &2952 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2753 | cmd 036 | cols  667.. 696 | delta=  +0 @ &2953 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2754 | cmd 037 | cols  697.. 726 | delta=  +0 @ &2954 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &2755 | cmd 038 | cols  727.. 736 | delta=  +0 @ &2955 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2756 | cmd 039 | cols  737.. 737 | delta=+100 @ &2956 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &2757 | cmd 040 | cols  738.. 747 | delta=  +0 @ &2957 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2758 | cmd 041 | cols  748.. 748 | delta=-100 @ &2958 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2759 | cmd 042 | cols  749.. 778 | delta=  +0 @ &2959 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &275A | cmd 043 | cols  779.. 808 | delta=  +0 @ &295A | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &275B | cmd 044 | cols  809.. 838 | delta=  +0 @ &295B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &275C | cmd 045 | cols  839.. 839 | delta= +70 @ &295C | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &275D | cmd 046 | cols  840.. 869 | delta=  +0 @ &295D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 20                                 ; original &275E | cmd 047 | cols  870.. 889 | delta=  +0 @ &295E | flat plateau; scenery eligible | scenery-ok
    EQUB 1                                  ; original &275F | cmd 048 | cols  890.. 890 | delta= +40 @ &295F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2760 | cmd 049 | cols  891.. 910 | delta=  +0 @ &2960 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2761 | cmd 050 | cols  911.. 911 | delta=-100 @ &2961 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2762 | cmd 051 | cols  912.. 941 | delta=  +0 @ &2962 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2763 | cmd 052 | cols  942.. 971 | delta=  +0 @ &2963 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2764 | cmd 053 | cols  972..1001 | delta=  +0 @ &2964 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2765 | cmd 054 | cols 1002..1002 | delta= +50 @ &2965 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2766 | cmd 055 | cols 1003..1032 | delta=  +0 @ &2966 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2767 | cmd 056 | cols 1033..1062 | delta=  +0 @ &2967 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2768 | cmd 057 | cols 1063..1063 | delta= +50 @ &2968 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &2769 | cmd 058 | cols 1064..1073 | delta=  +0 @ &2969 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &276A | cmd 059 | cols 1074..1074 | delta=-100 @ &296A | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &276B | cmd 060 | cols 1075..1104 | delta=  +0 @ &296B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &276C | cmd 061 | cols 1105..1134 | delta=  +0 @ &296C | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &276D | cmd 062 | cols 1135..1164 | delta=  +0 @ &296D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &276E | cmd 063 | cols 1165..1174 | delta=  +0 @ &296E | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &276F | cmd 064 | cols 1175..1175 | delta= +40 @ &296F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2770 | cmd 065 | cols 1176..1205 | delta=  +0 @ &2970 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2771 | cmd 066 | cols 1206..1206 | delta= +60 @ &2971 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2772 | cmd 067 | cols 1207..1236 | delta=  +0 @ &2972 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2773 | cmd 068 | cols 1237..1237 | delta=-100 @ &2973 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2774 | cmd 069 | cols 1238..1267 | delta=  +0 @ &2974 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2775 | cmd 070 | cols 1268..1297 | delta=  +0 @ &2975 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &2776 | cmd 071 | cols 1298..1327 | delta=  +0 @ &2976 | flat plateau; scenery eligible | scenery-ok
upper_section5_commands:
; SECTION 5 - FINAL CITY / DUSTBIN APPROACH | 110 commands | 1794 generated columns
final_city_lead_in_commands:
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+15      ; original &2777 | cmd 000 | cols    0..  14 | delta=  +0 @ &2977 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
final_city_block_1_commands:
; 32-command / 479-column city block; each copy contains one final dustbin at block column 93.
    EQUB 1                                  ; original &2778 | cmd 001 | cols   15..  15 | delta=+100 @ &2978 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2779 | cmd 002 | cols   16..  45 | delta=  +0 @ &2979 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &277A | cmd 003 | cols   46..  46 | delta= -50 @ &297A | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &277B | cmd 004 | cols   47..  76 | delta=  +0 @ &297B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &277C | cmd 005 | cols   77..  77 | delta= -60 @ &297C | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+25      ; original &277D | cmd 006 | cols   78.. 102 | delta=  +0 @ &297D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &277E | cmd 007 | cols  103.. 132 | delta=  +0 @ &297E | flat plateau; scenery eligible | scenery-ok | FINAL DUSTBIN is triggered 5 columns into this 30-column flat (remaining=25)
    EQUB 1                                  ; original &277F | cmd 008 | cols  133.. 133 | delta=+120 @ &297F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2780 | cmd 009 | cols  134.. 163 | delta=  +0 @ &2980 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2781 | cmd 010 | cols  164.. 164 | delta= +60 @ &2981 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2782 | cmd 011 | cols  165.. 184 | delta=  +0 @ &2982 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2783 | cmd 012 | cols  185.. 185 | delta= -50 @ &2983 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2784 | cmd 013 | cols  186.. 205 | delta=  +0 @ &2984 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2785 | cmd 014 | cols  206.. 206 | delta=-100 @ &2985 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &2786 | cmd 015 | cols  207.. 226 | delta=  +0 @ &2986 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2787 | cmd 016 | cols  227.. 227 | delta= -20 @ &2987 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2788 | cmd 017 | cols  228.. 257 | delta=  +0 @ &2988 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2789 | cmd 018 | cols  258.. 258 | delta=+100 @ &2989 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &278A | cmd 019 | cols  259.. 268 | delta=  +0 @ &298A | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &278B | cmd 020 | cols  269.. 269 | delta= +60 @ &298B | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &278C | cmd 021 | cols  270.. 299 | delta=  +0 @ &298C | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &278D | cmd 022 | cols  300.. 319 | delta=  +0 @ &298D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &278E | cmd 023 | cols  320.. 320 | delta= -20 @ &298E | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &278F | cmd 024 | cols  321.. 340 | delta=  +0 @ &298F | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2790 | cmd 025 | cols  341.. 341 | delta= -40 @ &2990 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2791 | cmd 026 | cols  342.. 371 | delta=  +0 @ &2991 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2792 | cmd 027 | cols  372.. 372 | delta= -50 @ &2992 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2793 | cmd 028 | cols  373.. 402 | delta=  +0 @ &2993 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &2794 | cmd 029 | cols  403.. 403 | delta= -50 @ &2994 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2795 | cmd 030 | cols  404.. 433 | delta=  +0 @ &2995 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2796 | cmd 031 | cols  434.. 463 | delta=  +0 @ &2996 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2797 | cmd 032 | cols  464.. 493 | delta=  +0 @ &2997 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
final_city_block_2_commands:
; 32-command / 479-column city block; each copy contains one final dustbin at block column 93.
    EQUB 1                                  ; original &2798 | cmd 033 | cols  494.. 494 | delta=+100 @ &2998 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &2799 | cmd 034 | cols  495.. 524 | delta=  +0 @ &2999 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &279A | cmd 035 | cols  525.. 525 | delta= -50 @ &299A | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &279B | cmd 036 | cols  526.. 555 | delta=  +0 @ &299B | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &279C | cmd 037 | cols  556.. 556 | delta= -60 @ &299C | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+25      ; original &279D | cmd 038 | cols  557.. 581 | delta=  +0 @ &299D | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &279E | cmd 039 | cols  582.. 611 | delta=  +0 @ &299E | flat plateau; scenery eligible | scenery-ok | FINAL DUSTBIN is triggered 5 columns into this 30-column flat (remaining=25)
    EQUB 1                                  ; original &279F | cmd 040 | cols  612.. 612 | delta=+120 @ &299F | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27A0 | cmd 041 | cols  613.. 642 | delta=  +0 @ &29A0 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27A1 | cmd 042 | cols  643.. 643 | delta= +60 @ &29A1 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27A2 | cmd 043 | cols  644.. 663 | delta=  +0 @ &29A2 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27A3 | cmd 044 | cols  664.. 664 | delta= -50 @ &29A3 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27A4 | cmd 045 | cols  665.. 684 | delta=  +0 @ &29A4 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27A5 | cmd 046 | cols  685.. 685 | delta=-100 @ &29A5 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27A6 | cmd 047 | cols  686.. 705 | delta=  +0 @ &29A6 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27A7 | cmd 048 | cols  706.. 706 | delta= -20 @ &29A7 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27A8 | cmd 049 | cols  707.. 736 | delta=  +0 @ &29A8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27A9 | cmd 050 | cols  737.. 737 | delta=+100 @ &29A9 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &27AA | cmd 051 | cols  738.. 747 | delta=  +0 @ &29AA | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27AB | cmd 052 | cols  748.. 748 | delta= +60 @ &29AB | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27AC | cmd 053 | cols  749.. 778 | delta=  +0 @ &29AC | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27AD | cmd 054 | cols  779.. 798 | delta=  +0 @ &29AD | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27AE | cmd 055 | cols  799.. 799 | delta= -20 @ &29AE | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27AF | cmd 056 | cols  800.. 819 | delta=  +0 @ &29AF | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27B0 | cmd 057 | cols  820.. 820 | delta= -40 @ &29B0 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B1 | cmd 058 | cols  821.. 850 | delta=  +0 @ &29B1 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27B2 | cmd 059 | cols  851.. 851 | delta= -50 @ &29B2 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B3 | cmd 060 | cols  852.. 881 | delta=  +0 @ &29B3 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27B4 | cmd 061 | cols  882.. 882 | delta= -50 @ &29B4 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B5 | cmd 062 | cols  883.. 912 | delta=  +0 @ &29B5 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B6 | cmd 063 | cols  913.. 942 | delta=  +0 @ &29B6 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B7 | cmd 064 | cols  943.. 972 | delta=  +0 @ &29B7 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
final_city_block_3_commands:
; 32-command / 479-column city block; each copy contains one final dustbin at block column 93.
    EQUB 1                                  ; original &27B8 | cmd 065 | cols  973.. 973 | delta=+100 @ &29B8 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27B9 | cmd 066 | cols  974..1003 | delta=  +0 @ &29B9 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27BA | cmd 067 | cols 1004..1004 | delta= -50 @ &29BA | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27BB | cmd 068 | cols 1005..1034 | delta=  +0 @ &29BB | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27BC | cmd 069 | cols 1035..1035 | delta= -60 @ &29BC | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+25      ; original &27BD | cmd 070 | cols 1036..1060 | delta=  +0 @ &29BD | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 30                                 ; original &27BE | cmd 071 | cols 1061..1090 | delta=  +0 @ &29BE | flat plateau; scenery eligible | scenery-ok | FINAL DUSTBIN is triggered 5 columns into this 30-column flat (remaining=25)
    EQUB 1                                  ; original &27BF | cmd 072 | cols 1091..1091 | delta=+120 @ &29BF | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27C0 | cmd 073 | cols 1092..1121 | delta=  +0 @ &29C0 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27C1 | cmd 074 | cols 1122..1122 | delta= +60 @ &29C1 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27C2 | cmd 075 | cols 1123..1142 | delta=  +0 @ &29C2 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27C3 | cmd 076 | cols 1143..1143 | delta= -50 @ &29C3 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27C4 | cmd 077 | cols 1144..1163 | delta=  +0 @ &29C4 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27C5 | cmd 078 | cols 1164..1164 | delta=-100 @ &29C5 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27C6 | cmd 079 | cols 1165..1184 | delta=  +0 @ &29C6 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27C7 | cmd 080 | cols 1185..1185 | delta= -20 @ &29C7 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27C8 | cmd 081 | cols 1186..1215 | delta=  +0 @ &29C8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27C9 | cmd 082 | cols 1216..1216 | delta=+100 @ &29C9 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+10      ; original &27CA | cmd 083 | cols 1217..1226 | delta=  +0 @ &29CA | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27CB | cmd 084 | cols 1227..1227 | delta= +60 @ &29CB | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27CC | cmd 085 | cols 1228..1257 | delta=  +0 @ &29CC | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27CD | cmd 086 | cols 1258..1277 | delta=  +0 @ &29CD | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27CE | cmd 087 | cols 1278..1278 | delta= -20 @ &29CE | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+20      ; original &27CF | cmd 088 | cols 1279..1298 | delta=  +0 @ &29CF | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27D0 | cmd 089 | cols 1299..1299 | delta= -40 @ &29D0 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D1 | cmd 090 | cols 1300..1329 | delta=  +0 @ &29D1 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27D2 | cmd 091 | cols 1330..1330 | delta= -50 @ &29D2 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D3 | cmd 092 | cols 1331..1360 | delta=  +0 @ &29D3 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB 1                                  ; original &27D4 | cmd 093 | cols 1361..1361 | delta= -50 @ &29D4 | vertical/near-vertical edge jump | scenery-blocked-by-slope
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D5 | cmd 094 | cols 1362..1391 | delta=  +0 @ &29D5 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D6 | cmd 095 | cols 1392..1421 | delta=  +0 @ &29D6 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D7 | cmd 096 | cols 1422..1451 | delta=  +0 @ &29D7 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
final_city_departure_commands:
; 330-column scenery-suppressed flat departure (11 x 30-column commands).
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D8 | cmd 097 | cols 1452..1481 | delta=  +0 @ &29D8 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27D9 | cmd 098 | cols 1482..1511 | delta=  +0 @ &29D9 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DA | cmd 099 | cols 1512..1541 | delta=  +0 @ &29DA | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DB | cmd 100 | cols 1542..1571 | delta=  +0 @ &29DB | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DC | cmd 101 | cols 1572..1601 | delta=  +0 @ &29DC | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DD | cmd 102 | cols 1602..1631 | delta=  +0 @ &29DD | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DE | cmd 103 | cols 1632..1661 | delta=  +0 @ &29DE | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27DF | cmd 104 | cols 1662..1691 | delta=  +0 @ &29DF | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27E0 | cmd 105 | cols 1692..1721 | delta=  +0 @ &29E0 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27E1 | cmd 106 | cols 1722..1751 | delta=  +0 @ &29E1 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
    EQUB TERRAIN_CMD_NO_SCENERY_BIT+30      ; original &27E2 | cmd 107 | cols 1752..1781 | delta=  +0 @ &29E2 | flat plateau; FIXED SCENERY DISABLED | NO-SCENERY
final_city_exit_slopes:
    EQUB 6                                  ; original &27E3 | cmd 108 | cols 1782..1787 | delta=  +6 @ &29E3 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
    EQUB 6                                  ; original &27E4 | cmd 109 | cols 1788..1793 | delta=  -6 @ &29E4 | rough slope (PRNG jitter applied) | scenery-blocked-by-slope
upper_terrain_end_marker:
    EQUB TERRAIN_CMD_END_MARKER ; original &27E5 = &FF, end raid
; &27E6-&27FF: preserved source/build residue.
    EQUB &65, &72, &6F, &66, &6C, &61, &67, &3A, &4C, &44, &41, &63, &79, &63, &6C, &65    ; original &27E6
    EQUB &63, &6F, &75, &6E, &74, &3A, &4A, &4D, &50, &67    ; original &27F6
; UPPER TERRAIN SIGNED DELTAS (&2800-&29E4)
upper_terrain_deltas:
upper_section0_deltas:
    EQUB &04 ; original &2800 | signed   +4 | paired command &2600
    EQUB &FD ; original &2801 | signed   -3 | paired command &2601
    EQUB &00 ; original &2802 | signed   +0 | paired command &2602
    EQUB &03 ; original &2803 | signed   +3 | paired command &2603
    EQUB &FE ; original &2804 | signed   -2 | paired command &2604
    EQUB &FE ; original &2805 | signed   -2 | paired command &2605
    EQUB &00 ; original &2806 | signed   +0 | paired command &2606
    EQUB &02 ; original &2807 | signed   +2 | paired command &2607
    EQUB &FE ; original &2808 | signed   -2 | paired command &2608
    EQUB &00 ; original &2809 | signed   +0 | paired command &2609
    EQUB &03 ; original &280A | signed   +3 | paired command &260A
    EQUB &00 ; original &280B | signed   +0 | paired command &260B
    EQUB &02 ; original &280C | signed   +2 | paired command &260C
    EQUB &00 ; original &280D | signed   +0 | paired command &260D
    EQUB &02 ; original &280E | signed   +2 | paired command &260E
    EQUB &00 ; original &280F | signed   +0 | paired command &260F
    EQUB &03 ; original &2810 | signed   +3 | paired command &2610
    EQUB &03 ; original &2811 | signed   +3 | paired command &2611
    EQUB &FC ; original &2812 | signed   -4 | paired command &2612
    EQUB &00 ; original &2813 | signed   +0 | paired command &2613
    EQUB &04 ; original &2814 | signed   +4 | paired command &2614
    EQUB &00 ; original &2815 | signed   +0 | paired command &2615
    EQUB &FD ; original &2816 | signed   -3 | paired command &2616
    EQUB &00 ; original &2817 | signed   +0 | paired command &2617
    EQUB &04 ; original &2818 | signed   +4 | paired command &2618
    EQUB &FC ; original &2819 | signed   -4 | paired command &2619
    EQUB &00 ; original &281A | signed   +0 | paired command &261A
    EQUB &02 ; original &281B | signed   +2 | paired command &261B
    EQUB &04 ; original &281C | signed   +4 | paired command &261C
    EQUB &00 ; original &281D | signed   +0 | paired command &261D
    EQUB &FD ; original &281E | signed   -3 | paired command &261E
    EQUB &00 ; original &281F | signed   +0 | paired command &261F
    EQUB &01 ; original &2820 | signed   +1 | paired command &2620
    EQUB &03 ; original &2821 | signed   +3 | paired command &2621
    EQUB &FF ; original &2822 | signed   -1 | paired command &2622
    EQUB &00 ; original &2823 | signed   +0 | paired command &2623
    EQUB &03 ; original &2824 | signed   +3 | paired command &2624
    EQUB &00 ; original &2825 | signed   +0 | paired command &2625
    EQUB &04 ; original &2826 | signed   +4 | paired command &2626
    EQUB &00 ; original &2827 | signed   +0 | paired command &2627
    EQUB &02 ; original &2828 | signed   +2 | paired command &2628
    EQUB &00 ; original &2829 | signed   +0 | paired command &2629
    EQUB &FD ; original &282A | signed   -3 | paired command &262A
    EQUB &00 ; original &282B | signed   +0 | paired command &262B
    EQUB &FF ; original &282C | signed   -1 | paired command &262C
    EQUB &00 ; original &282D | signed   +0 | paired command &262D
    EQUB &01 ; original &282E | signed   +1 | paired command &262E
    EQUB &00 ; original &282F | signed   +0 | paired command &262F
    EQUB &FE ; original &2830 | signed   -2 | paired command &2630
    EQUB &00 ; original &2831 | signed   +0 | paired command &2631
    EQUB &02 ; original &2832 | signed   +2 | paired command &2632
    EQUB &00 ; original &2833 | signed   +0 | paired command &2633
    EQUB &02 ; original &2834 | signed   +2 | paired command &2634
    EQUB &00 ; original &2835 | signed   +0 | paired command &2635
    EQUB &FD ; original &2836 | signed   -3 | paired command &2636
    EQUB &00 ; original &2837 | signed   +0 | paired command &2637
    EQUB &03 ; original &2838 | signed   +3 | paired command &2638
    EQUB &00 ; original &2839 | signed   +0 | paired command &2639
    EQUB &02 ; original &283A | signed   +2 | paired command &263A
    EQUB &00 ; original &283B | signed   +0 | paired command &263B
    EQUB &04 ; original &283C | signed   +4 | paired command &263C
    EQUB &00 ; original &283D | signed   +0 | paired command &263D
    EQUB &04 ; original &283E | signed   +4 | paired command &263E
    EQUB &00 ; original &283F | signed   +0 | paired command &263F
    EQUB &FC ; original &2840 | signed   -4 | paired command &2640
    EQUB &00 ; original &2841 | signed   +0 | paired command &2641
    EQUB &03 ; original &2842 | signed   +3 | paired command &2642
    EQUB &00 ; original &2843 | signed   +0 | paired command &2643
    EQUB &FD ; original &2844 | signed   -3 | paired command &2644
    EQUB &FE ; original &2845 | signed   -2 | paired command &2645
    EQUB &00 ; original &2846 | signed   +0 | paired command &2646
    EQUB &FF ; original &2847 | signed   -1 | paired command &2647
    EQUB &FF ; original &2848 | signed   -1 | paired command &2648
    EQUB &FF ; original &2849 | signed   -1 | paired command &2649
    EQUB &02 ; original &284A | signed   +2 | paired command &264A
upper_section1_deltas:
    EQUB &FF ; original &284B | signed   -1 | paired command &264B
    EQUB &02 ; original &284C | signed   +2 | paired command &264C
    EQUB &01 ; original &284D | signed   +1 | paired command &264D
    EQUB &FF ; original &284E | signed   -1 | paired command &264E
    EQUB &01 ; original &284F | signed   +1 | paired command &264F
    EQUB &02 ; original &2850 | signed   +2 | paired command &2650
    EQUB &01 ; original &2851 | signed   +1 | paired command &2651
    EQUB &01 ; original &2852 | signed   +1 | paired command &2652
    EQUB &FF ; original &2853 | signed   -1 | paired command &2653
    EQUB &02 ; original &2854 | signed   +2 | paired command &2654
    EQUB &FF ; original &2855 | signed   -1 | paired command &2655
    EQUB &01 ; original &2856 | signed   +1 | paired command &2656
    EQUB &01 ; original &2857 | signed   +1 | paired command &2657
    EQUB &FF ; original &2858 | signed   -1 | paired command &2658
    EQUB &01 ; original &2859 | signed   +1 | paired command &2659
    EQUB &02 ; original &285A | signed   +2 | paired command &265A
    EQUB &01 ; original &285B | signed   +1 | paired command &265B
    EQUB &FF ; original &285C | signed   -1 | paired command &265C
    EQUB &01 ; original &285D | signed   +1 | paired command &265D
    EQUB &01 ; original &285E | signed   +1 | paired command &265E
    EQUB &FF ; original &285F | signed   -1 | paired command &265F
    EQUB &01 ; original &2860 | signed   +1 | paired command &2660
    EQUB &01 ; original &2861 | signed   +1 | paired command &2661
    EQUB &01 ; original &2862 | signed   +1 | paired command &2662
    EQUB &01 ; original &2863 | signed   +1 | paired command &2663
    EQUB &FF ; original &2864 | signed   -1 | paired command &2664
    EQUB &01 ; original &2865 | signed   +1 | paired command &2665
    EQUB &FF ; original &2866 | signed   -1 | paired command &2666
    EQUB &01 ; original &2867 | signed   +1 | paired command &2667
    EQUB &FF ; original &2868 | signed   -1 | paired command &2668
    EQUB &01 ; original &2869 | signed   +1 | paired command &2669
    EQUB &FF ; original &286A | signed   -1 | paired command &266A
    EQUB &02 ; original &286B | signed   +2 | paired command &266B
    EQUB &01 ; original &286C | signed   +1 | paired command &266C
    EQUB &FF ; original &286D | signed   -1 | paired command &266D
    EQUB &01 ; original &286E | signed   +1 | paired command &266E
    EQUB &FF ; original &286F | signed   -1 | paired command &266F
    EQUB &01 ; original &2870 | signed   +1 | paired command &2670
    EQUB &FF ; original &2871 | signed   -1 | paired command &2671
    EQUB &01 ; original &2872 | signed   +1 | paired command &2672
    EQUB &FF ; original &2873 | signed   -1 | paired command &2673
    EQUB &01 ; original &2874 | signed   +1 | paired command &2674
    EQUB &FF ; original &2875 | signed   -1 | paired command &2675
    EQUB &01 ; original &2876 | signed   +1 | paired command &2676
    EQUB &FF ; original &2877 | signed   -1 | paired command &2677
    EQUB &01 ; original &2878 | signed   +1 | paired command &2678
    EQUB &01 ; original &2879 | signed   +1 | paired command &2679
    EQUB &FF ; original &287A | signed   -1 | paired command &267A
    EQUB &01 ; original &287B | signed   +1 | paired command &267B
    EQUB &FF ; original &287C | signed   -1 | paired command &267C
    EQUB &03 ; original &287D | signed   +3 | paired command &267D
    EQUB &FE ; original &287E | signed   -2 | paired command &267E
    EQUB &00 ; original &287F | signed   +0 | paired command &267F
    EQUB &02 ; original &2880 | signed   +2 | paired command &2680
    EQUB &FE ; original &2881 | signed   -2 | paired command &2681
    EQUB &00 ; original &2882 | signed   +0 | paired command &2682
    EQUB &00 ; original &2883 | signed   +0 | paired command &2683
    EQUB &00 ; original &2884 | signed   +0 | paired command &2684
    EQUB &03 ; original &2885 | signed   +3 | paired command &2685
    EQUB &FF ; original &2886 | signed   -1 | paired command &2686
upper_section2_deltas:
    EQUB &01 ; original &2887 | signed   +1 | paired command &2687
    EQUB &01 ; original &2888 | signed   +1 | paired command &2688
    EQUB &FF ; original &2889 | signed   -1 | paired command &2689
    EQUB &00 ; original &288A | signed   +0 | paired command &268A
    EQUB &01 ; original &288B | signed   +1 | paired command &268B
    EQUB &01 ; original &288C | signed   +1 | paired command &268C
    EQUB &FF ; original &288D | signed   -1 | paired command &268D
    EQUB &00 ; original &288E | signed   +0 | paired command &268E
    EQUB &01 ; original &288F | signed   +1 | paired command &268F
    EQUB &01 ; original &2890 | signed   +1 | paired command &2690
    EQUB &FF ; original &2891 | signed   -1 | paired command &2691
    EQUB &00 ; original &2892 | signed   +0 | paired command &2692
    EQUB &01 ; original &2893 | signed   +1 | paired command &2693
    EQUB &01 ; original &2894 | signed   +1 | paired command &2694
    EQUB &FF ; original &2895 | signed   -1 | paired command &2695
    EQUB &00 ; original &2896 | signed   +0 | paired command &2696
    EQUB &01 ; original &2897 | signed   +1 | paired command &2697
    EQUB &01 ; original &2898 | signed   +1 | paired command &2698
    EQUB &FF ; original &2899 | signed   -1 | paired command &2699
    EQUB &00 ; original &289A | signed   +0 | paired command &269A
    EQUB &01 ; original &289B | signed   +1 | paired command &269B
    EQUB &01 ; original &289C | signed   +1 | paired command &269C
    EQUB &FF ; original &289D | signed   -1 | paired command &269D
    EQUB &00 ; original &289E | signed   +0 | paired command &269E
    EQUB &01 ; original &289F | signed   +1 | paired command &269F
    EQUB &01 ; original &28A0 | signed   +1 | paired command &26A0
    EQUB &FF ; original &28A1 | signed   -1 | paired command &26A1
    EQUB &00 ; original &28A2 | signed   +0 | paired command &26A2
    EQUB &01 ; original &28A3 | signed   +1 | paired command &26A3
    EQUB &01 ; original &28A4 | signed   +1 | paired command &26A4
    EQUB &FF ; original &28A5 | signed   -1 | paired command &26A5
    EQUB &00 ; original &28A6 | signed   +0 | paired command &26A6
    EQUB &01 ; original &28A7 | signed   +1 | paired command &26A7
    EQUB &01 ; original &28A8 | signed   +1 | paired command &26A8
    EQUB &FF ; original &28A9 | signed   -1 | paired command &26A9
    EQUB &00 ; original &28AA | signed   +0 | paired command &26AA
    EQUB &01 ; original &28AB | signed   +1 | paired command &26AB
    EQUB &01 ; original &28AC | signed   +1 | paired command &26AC
    EQUB &FF ; original &28AD | signed   -1 | paired command &26AD
    EQUB &00 ; original &28AE | signed   +0 | paired command &26AE
    EQUB &01 ; original &28AF | signed   +1 | paired command &26AF
    EQUB &01 ; original &28B0 | signed   +1 | paired command &26B0
    EQUB &FF ; original &28B1 | signed   -1 | paired command &26B1
    EQUB &00 ; original &28B2 | signed   +0 | paired command &26B2
    EQUB &01 ; original &28B3 | signed   +1 | paired command &26B3
    EQUB &01 ; original &28B4 | signed   +1 | paired command &26B4
    EQUB &00 ; original &28B5 | signed   +0 | paired command &26B5
    EQUB &01 ; original &28B6 | signed   +1 | paired command &26B6
    EQUB &01 ; original &28B7 | signed   +1 | paired command &26B7
    EQUB &FF ; original &28B8 | signed   -1 | paired command &26B8
    EQUB &00 ; original &28B9 | signed   +0 | paired command &26B9
    EQUB &01 ; original &28BA | signed   +1 | paired command &26BA
    EQUB &01 ; original &28BB | signed   +1 | paired command &26BB
    EQUB &FF ; original &28BC | signed   -1 | paired command &26BC
    EQUB &00 ; original &28BD | signed   +0 | paired command &26BD
    EQUB &01 ; original &28BE | signed   +1 | paired command &26BE
    EQUB &01 ; original &28BF | signed   +1 | paired command &26BF
    EQUB &FF ; original &28C0 | signed   -1 | paired command &26C0
    EQUB &00 ; original &28C1 | signed   +0 | paired command &26C1
    EQUB &01 ; original &28C2 | signed   +1 | paired command &26C2
    EQUB &01 ; original &28C3 | signed   +1 | paired command &26C3
    EQUB &FF ; original &28C4 | signed   -1 | paired command &26C4
    EQUB &00 ; original &28C5 | signed   +0 | paired command &26C5
    EQUB &01 ; original &28C6 | signed   +1 | paired command &26C6
    EQUB &01 ; original &28C7 | signed   +1 | paired command &26C7
    EQUB &FF ; original &28C8 | signed   -1 | paired command &26C8
    EQUB &00 ; original &28C9 | signed   +0 | paired command &26C9
    EQUB &01 ; original &28CA | signed   +1 | paired command &26CA
    EQUB &01 ; original &28CB | signed   +1 | paired command &26CB
    EQUB &FF ; original &28CC | signed   -1 | paired command &26CC
    EQUB &00 ; original &28CD | signed   +0 | paired command &26CD
    EQUB &01 ; original &28CE | signed   +1 | paired command &26CE
upper_section3_deltas:
    EQUB &7F ; original &28CF | signed +127 | paired command &26CF
    EQUB &00 ; original &28D0 | signed   +0 | paired command &26D0
    EQUB &EC ; original &28D1 | signed  -20 | paired command &26D1
    EQUB &00 ; original &28D2 | signed   +0 | paired command &26D2
    EQUB &28 ; original &28D3 | signed  +40 | paired command &26D3
    EQUB &00 ; original &28D4 | signed   +0 | paired command &26D4
    EQUB &D8 ; original &28D5 | signed  -40 | paired command &26D5
    EQUB &00 ; original &28D6 | signed   +0 | paired command &26D6
    EQUB &14 ; original &28D7 | signed  +20 | paired command &26D7
    EQUB &00 ; original &28D8 | signed   +0 | paired command &26D8
    EQUB &1E ; original &28D9 | signed  +30 | paired command &26D9
    EQUB &00 ; original &28DA | signed   +0 | paired command &26DA
    EQUB &DD ; original &28DB | signed  -35 | paired command &26DB
    EQUB &00 ; original &28DC | signed   +0 | paired command &26DC
    EQUB &BA ; original &28DD | signed  -70 | paired command &26DD
    EQUB &00 ; original &28DE | signed   +0 | paired command &26DE
    EQUB &14 ; original &28DF | signed  +20 | paired command &26DF
    EQUB &00 ; original &28E0 | signed   +0 | paired command &26E0
    EQUB &E2 ; original &28E1 | signed  -30 | paired command &26E1
    EQUB &00 ; original &28E2 | signed   +0 | paired command &26E2
    EQUB &F6 ; original &28E3 | signed  -10 | paired command &26E3
    EQUB &00 ; original &28E4 | signed   +0 | paired command &26E4
    EQUB &50 ; original &28E5 | signed  +80 | paired command &26E5
    EQUB &00 ; original &28E6 | signed   +0 | paired command &26E6
    EQUB &0A ; original &28E7 | signed  +10 | paired command &26E7
    EQUB &00 ; original &28E8 | signed   +0 | paired command &26E8
    EQUB &EC ; original &28E9 | signed  -20 | paired command &26E9
    EQUB &00 ; original &28EA | signed   +0 | paired command &26EA
    EQUB &19 ; original &28EB | signed  +25 | paired command &26EB
    EQUB &00 ; original &28EC | signed   +0 | paired command &26EC
    EQUB &F6 ; original &28ED | signed  -10 | paired command &26ED
    EQUB &00 ; original &28EE | signed   +0 | paired command &26EE
    EQUB &E2 ; original &28EF | signed  -30 | paired command &26EF
    EQUB &00 ; original &28F0 | signed   +0 | paired command &26F0
    EQUB &28 ; original &28F1 | signed  +40 | paired command &26F1
    EQUB &00 ; original &28F2 | signed   +0 | paired command &26F2
    EQUB &9C ; original &28F3 | signed -100 | paired command &26F3
    EQUB &00 ; original &28F4 | signed   +0 | paired command &26F4
    EQUB &1E ; original &28F5 | signed  +30 | paired command &26F5
    EQUB &00 ; original &28F6 | signed   +0 | paired command &26F6
    EQUB &0A ; original &28F7 | signed  +10 | paired command &26F7
    EQUB &00 ; original &28F8 | signed   +0 | paired command &26F8
    EQUB &14 ; original &28F9 | signed  +20 | paired command &26F9
    EQUB &00 ; original &28FA | signed   +0 | paired command &26FA
    EQUB &F1 ; original &28FB | signed  -15 | paired command &26FB
    EQUB &00 ; original &28FC | signed   +0 | paired command &26FC
    EQUB &19 ; original &28FD | signed  +25 | paired command &26FD
    EQUB &00 ; original &28FE | signed   +0 | paired command &26FE
    EQUB &E2 ; original &28FF | signed  -30 | paired command &26FF
    EQUB &00 ; original &2900 | signed   +0 | paired command &2700
    EQUB &0A ; original &2901 | signed  +10 | paired command &2701
    EQUB &00 ; original &2902 | signed   +0 | paired command &2702
    EQUB &C4 ; original &2903 | signed  -60 | paired command &2703
    EQUB &00 ; original &2904 | signed   +0 | paired command &2704
    EQUB &14 ; original &2905 | signed  +20 | paired command &2705
    EQUB &00 ; original &2906 | signed   +0 | paired command &2706
    EQUB &1E ; original &2907 | signed  +30 | paired command &2707
    EQUB &00 ; original &2908 | signed   +0 | paired command &2708
    EQUB &28 ; original &2909 | signed  +40 | paired command &2709
    EQUB &00 ; original &290A | signed   +0 | paired command &270A
    EQUB &EC ; original &290B | signed  -20 | paired command &270B
    EQUB &00 ; original &290C | signed   +0 | paired command &270C
    EQUB &0F ; original &290D | signed  +15 | paired command &270D
    EQUB &00 ; original &290E | signed   +0 | paired command &270E
    EQUB &D8 ; original &290F | signed  -40 | paired command &270F
    EQUB &00 ; original &2910 | signed   +0 | paired command &2710
    EQUB &EC ; original &2911 | signed  -20 | paired command &2711
    EQUB &00 ; original &2912 | signed   +0 | paired command &2712
    EQUB &1E ; original &2913 | signed  +30 | paired command &2713
    EQUB &00 ; original &2914 | signed   +0 | paired command &2714
    EQUB &1E ; original &2915 | signed  +30 | paired command &2715
    EQUB &00 ; original &2916 | signed   +0 | paired command &2716
    EQUB &1E ; original &2917 | signed  +30 | paired command &2717
    EQUB &00 ; original &2918 | signed   +0 | paired command &2718
    EQUB &EF ; original &2919 | signed  -17 | paired command &2719
    EQUB &00 ; original &291A | signed   +0 | paired command &271A
    EQUB &14 ; original &291B | signed  +20 | paired command &271B
    EQUB &00 ; original &291C | signed   +0 | paired command &271C
    EQUB &EC ; original &291D | signed  -20 | paired command &271D
    EQUB &00 ; original &291E | signed   +0 | paired command &271E
    EQUB &11 ; original &291F | signed  +17 | paired command &271F
    EQUB &00 ; original &2920 | signed   +0 | paired command &2720
    EQUB &81 ; original &2921 | signed -127 | paired command &2721
    EQUB &00 ; original &2922 | signed   +0 | paired command &2722
    EQUB &14 ; original &2923 | signed  +20 | paired command &2723
    EQUB &00 ; original &2924 | signed   +0 | paired command &2724
    EQUB &EC ; original &2925 | signed  -20 | paired command &2725
    EQUB &00 ; original &2926 | signed   +0 | paired command &2726
    EQUB &1E ; original &2927 | signed  +30 | paired command &2727
    EQUB &00 ; original &2928 | signed   +0 | paired command &2728
    EQUB &EC ; original &2929 | signed  -20 | paired command &2729
    EQUB &00 ; original &292A | signed   +0 | paired command &272A
    EQUB &14 ; original &292B | signed  +20 | paired command &272B
    EQUB &00 ; original &292C | signed   +0 | paired command &272C
    EQUB &E2 ; original &292D | signed  -30 | paired command &272D
    EQUB &00 ; original &292E | signed   +0 | paired command &272E
upper_section4_deltas:
    EQUB &00 ; original &292F | signed   +0 | paired command &272F
    EQUB &78 ; original &2930 | signed +120 | paired command &2730
    EQUB &00 ; original &2931 | signed   +0 | paired command &2731
    EQUB &00 ; original &2932 | signed   +0 | paired command &2732
    EQUB &9C ; original &2933 | signed -100 | paired command &2733
    EQUB &00 ; original &2934 | signed   +0 | paired command &2734
    EQUB &00 ; original &2935 | signed   +0 | paired command &2735
    EQUB &00 ; original &2936 | signed   +0 | paired command &2736
    EQUB &00 ; original &2937 | signed   +0 | paired command &2737
    EQUB &00 ; original &2938 | signed   +0 | paired command &2738
    EQUB &64 ; original &2939 | signed +100 | paired command &2739
    EQUB &00 ; original &293A | signed   +0 | paired command &273A
    EQUB &00 ; original &293B | signed   +0 | paired command &273B
    EQUB &CE ; original &293C | signed  -50 | paired command &273C
    EQUB &00 ; original &293D | signed   +0 | paired command &273D
    EQUB &00 ; original &293E | signed   +0 | paired command &273E
    EQUB &D8 ; original &293F | signed  -40 | paired command &273F
    EQUB &00 ; original &2940 | signed   +0 | paired command &2740
    EQUB &E2 ; original &2941 | signed  -30 | paired command &2741
    EQUB &00 ; original &2942 | signed   +0 | paired command &2742
    EQUB &00 ; original &2943 | signed   +0 | paired command &2743
    EQUB &00 ; original &2944 | signed   +0 | paired command &2744
    EQUB &64 ; original &2945 | signed +100 | paired command &2745
    EQUB &00 ; original &2946 | signed   +0 | paired command &2746
    EQUB &CE ; original &2947 | signed  -50 | paired command &2747
    EQUB &00 ; original &2948 | signed   +0 | paired command &2748
    EQUB &CE ; original &2949 | signed  -50 | paired command &2749
    EQUB &00 ; original &294A | signed   +0 | paired command &274A
    EQUB &00 ; original &294B | signed   +0 | paired command &274B
    EQUB &00 ; original &294C | signed   +0 | paired command &274C
    EQUB &32 ; original &294D | signed  +50 | paired command &274D
    EQUB &00 ; original &294E | signed   +0 | paired command &274E
    EQUB &3C ; original &294F | signed  +60 | paired command &274F
    EQUB &00 ; original &2950 | signed   +0 | paired command &2750
    EQUB &9C ; original &2951 | signed -100 | paired command &2751
    EQUB &00 ; original &2952 | signed   +0 | paired command &2752
    EQUB &00 ; original &2953 | signed   +0 | paired command &2753
    EQUB &00 ; original &2954 | signed   +0 | paired command &2754
    EQUB &00 ; original &2955 | signed   +0 | paired command &2755
    EQUB &64 ; original &2956 | signed +100 | paired command &2756
    EQUB &00 ; original &2957 | signed   +0 | paired command &2757
    EQUB &9C ; original &2958 | signed -100 | paired command &2758
    EQUB &00 ; original &2959 | signed   +0 | paired command &2759
    EQUB &00 ; original &295A | signed   +0 | paired command &275A
    EQUB &00 ; original &295B | signed   +0 | paired command &275B
    EQUB &46 ; original &295C | signed  +70 | paired command &275C
    EQUB &00 ; original &295D | signed   +0 | paired command &275D
    EQUB &00 ; original &295E | signed   +0 | paired command &275E
    EQUB &28 ; original &295F | signed  +40 | paired command &275F
    EQUB &00 ; original &2960 | signed   +0 | paired command &2760
    EQUB &9C ; original &2961 | signed -100 | paired command &2761
    EQUB &00 ; original &2962 | signed   +0 | paired command &2762
    EQUB &00 ; original &2963 | signed   +0 | paired command &2763
    EQUB &00 ; original &2964 | signed   +0 | paired command &2764
    EQUB &32 ; original &2965 | signed  +50 | paired command &2765
    EQUB &00 ; original &2966 | signed   +0 | paired command &2766
    EQUB &00 ; original &2967 | signed   +0 | paired command &2767
    EQUB &32 ; original &2968 | signed  +50 | paired command &2768
    EQUB &00 ; original &2969 | signed   +0 | paired command &2769
    EQUB &9C ; original &296A | signed -100 | paired command &276A
    EQUB &00 ; original &296B | signed   +0 | paired command &276B
    EQUB &00 ; original &296C | signed   +0 | paired command &276C
    EQUB &00 ; original &296D | signed   +0 | paired command &276D
    EQUB &00 ; original &296E | signed   +0 | paired command &276E
    EQUB &28 ; original &296F | signed  +40 | paired command &276F
    EQUB &00 ; original &2970 | signed   +0 | paired command &2770
    EQUB &3C ; original &2971 | signed  +60 | paired command &2771
    EQUB &00 ; original &2972 | signed   +0 | paired command &2772
    EQUB &9C ; original &2973 | signed -100 | paired command &2773
    EQUB &00 ; original &2974 | signed   +0 | paired command &2774
    EQUB &00 ; original &2975 | signed   +0 | paired command &2775
    EQUB &00 ; original &2976 | signed   +0 | paired command &2776
upper_section5_deltas:
final_city_lead_in_deltas:
    EQUB &00 ; original &2977 | signed   +0 | paired command &2777
final_city_block_1_deltas:
    EQUB &64 ; original &2978 | signed +100 | paired command &2778
    EQUB &00 ; original &2979 | signed   +0 | paired command &2779
    EQUB &CE ; original &297A | signed  -50 | paired command &277A
    EQUB &00 ; original &297B | signed   +0 | paired command &277B
    EQUB &C4 ; original &297C | signed  -60 | paired command &277C
    EQUB &00 ; original &297D | signed   +0 | paired command &277D
    EQUB &00 ; original &297E | signed   +0 | paired command &277E
    EQUB &78 ; original &297F | signed +120 | paired command &277F
    EQUB &00 ; original &2980 | signed   +0 | paired command &2780
    EQUB &3C ; original &2981 | signed  +60 | paired command &2781
    EQUB &00 ; original &2982 | signed   +0 | paired command &2782
    EQUB &CE ; original &2983 | signed  -50 | paired command &2783
    EQUB &00 ; original &2984 | signed   +0 | paired command &2784
    EQUB &9C ; original &2985 | signed -100 | paired command &2785
    EQUB &00 ; original &2986 | signed   +0 | paired command &2786
    EQUB &EC ; original &2987 | signed  -20 | paired command &2787
    EQUB &00 ; original &2988 | signed   +0 | paired command &2788
    EQUB &64 ; original &2989 | signed +100 | paired command &2789
    EQUB &00 ; original &298A | signed   +0 | paired command &278A
    EQUB &3C ; original &298B | signed  +60 | paired command &278B
    EQUB &00 ; original &298C | signed   +0 | paired command &278C
    EQUB &00 ; original &298D | signed   +0 | paired command &278D
    EQUB &EC ; original &298E | signed  -20 | paired command &278E
    EQUB &00 ; original &298F | signed   +0 | paired command &278F
    EQUB &D8 ; original &2990 | signed  -40 | paired command &2790
    EQUB &00 ; original &2991 | signed   +0 | paired command &2791
    EQUB &CE ; original &2992 | signed  -50 | paired command &2792
    EQUB &00 ; original &2993 | signed   +0 | paired command &2793
    EQUB &CE ; original &2994 | signed  -50 | paired command &2794
    EQUB &00 ; original &2995 | signed   +0 | paired command &2795
    EQUB &00 ; original &2996 | signed   +0 | paired command &2796
    EQUB &00 ; original &2997 | signed   +0 | paired command &2797
final_city_block_2_deltas:
    EQUB &64 ; original &2998 | signed +100 | paired command &2798
    EQUB &00 ; original &2999 | signed   +0 | paired command &2799
    EQUB &CE ; original &299A | signed  -50 | paired command &279A
    EQUB &00 ; original &299B | signed   +0 | paired command &279B
    EQUB &C4 ; original &299C | signed  -60 | paired command &279C
    EQUB &00 ; original &299D | signed   +0 | paired command &279D
    EQUB &00 ; original &299E | signed   +0 | paired command &279E
    EQUB &78 ; original &299F | signed +120 | paired command &279F
    EQUB &00 ; original &29A0 | signed   +0 | paired command &27A0
    EQUB &3C ; original &29A1 | signed  +60 | paired command &27A1
    EQUB &00 ; original &29A2 | signed   +0 | paired command &27A2
    EQUB &CE ; original &29A3 | signed  -50 | paired command &27A3
    EQUB &00 ; original &29A4 | signed   +0 | paired command &27A4
    EQUB &9C ; original &29A5 | signed -100 | paired command &27A5
    EQUB &00 ; original &29A6 | signed   +0 | paired command &27A6
    EQUB &EC ; original &29A7 | signed  -20 | paired command &27A7
    EQUB &00 ; original &29A8 | signed   +0 | paired command &27A8
    EQUB &64 ; original &29A9 | signed +100 | paired command &27A9
    EQUB &00 ; original &29AA | signed   +0 | paired command &27AA
    EQUB &3C ; original &29AB | signed  +60 | paired command &27AB
    EQUB &00 ; original &29AC | signed   +0 | paired command &27AC
    EQUB &00 ; original &29AD | signed   +0 | paired command &27AD
    EQUB &EC ; original &29AE | signed  -20 | paired command &27AE
    EQUB &00 ; original &29AF | signed   +0 | paired command &27AF
    EQUB &D8 ; original &29B0 | signed  -40 | paired command &27B0
    EQUB &00 ; original &29B1 | signed   +0 | paired command &27B1
    EQUB &CE ; original &29B2 | signed  -50 | paired command &27B2
    EQUB &00 ; original &29B3 | signed   +0 | paired command &27B3
    EQUB &CE ; original &29B4 | signed  -50 | paired command &27B4
    EQUB &00 ; original &29B5 | signed   +0 | paired command &27B5
    EQUB &00 ; original &29B6 | signed   +0 | paired command &27B6
    EQUB &00 ; original &29B7 | signed   +0 | paired command &27B7
final_city_block_3_deltas:
    EQUB &64 ; original &29B8 | signed +100 | paired command &27B8
    EQUB &00 ; original &29B9 | signed   +0 | paired command &27B9
    EQUB &CE ; original &29BA | signed  -50 | paired command &27BA
    EQUB &00 ; original &29BB | signed   +0 | paired command &27BB
    EQUB &C4 ; original &29BC | signed  -60 | paired command &27BC
    EQUB &00 ; original &29BD | signed   +0 | paired command &27BD
    EQUB &00 ; original &29BE | signed   +0 | paired command &27BE
    EQUB &78 ; original &29BF | signed +120 | paired command &27BF
    EQUB &00 ; original &29C0 | signed   +0 | paired command &27C0
    EQUB &3C ; original &29C1 | signed  +60 | paired command &27C1
    EQUB &00 ; original &29C2 | signed   +0 | paired command &27C2
    EQUB &CE ; original &29C3 | signed  -50 | paired command &27C3
    EQUB &00 ; original &29C4 | signed   +0 | paired command &27C4
    EQUB &9C ; original &29C5 | signed -100 | paired command &27C5
    EQUB &00 ; original &29C6 | signed   +0 | paired command &27C6
    EQUB &EC ; original &29C7 | signed  -20 | paired command &27C7
    EQUB &00 ; original &29C8 | signed   +0 | paired command &27C8
    EQUB &64 ; original &29C9 | signed +100 | paired command &27C9
    EQUB &00 ; original &29CA | signed   +0 | paired command &27CA
    EQUB &3C ; original &29CB | signed  +60 | paired command &27CB
    EQUB &00 ; original &29CC | signed   +0 | paired command &27CC
    EQUB &00 ; original &29CD | signed   +0 | paired command &27CD
    EQUB &EC ; original &29CE | signed  -20 | paired command &27CE
    EQUB &00 ; original &29CF | signed   +0 | paired command &27CF
    EQUB &D8 ; original &29D0 | signed  -40 | paired command &27D0
    EQUB &00 ; original &29D1 | signed   +0 | paired command &27D1
    EQUB &CE ; original &29D2 | signed  -50 | paired command &27D2
    EQUB &00 ; original &29D3 | signed   +0 | paired command &27D3
    EQUB &CE ; original &29D4 | signed  -50 | paired command &27D4
    EQUB &00 ; original &29D5 | signed   +0 | paired command &27D5
    EQUB &00 ; original &29D6 | signed   +0 | paired command &27D6
    EQUB &00 ; original &29D7 | signed   +0 | paired command &27D7
final_city_departure_deltas:
    EQUB &00 ; original &29D8 | signed   +0 | paired command &27D8
    EQUB &00 ; original &29D9 | signed   +0 | paired command &27D9
    EQUB &00 ; original &29DA | signed   +0 | paired command &27DA
    EQUB &00 ; original &29DB | signed   +0 | paired command &27DB
    EQUB &00 ; original &29DC | signed   +0 | paired command &27DC
    EQUB &00 ; original &29DD | signed   +0 | paired command &27DD
    EQUB &00 ; original &29DE | signed   +0 | paired command &27DE
    EQUB &00 ; original &29DF | signed   +0 | paired command &27DF
    EQUB &00 ; original &29E0 | signed   +0 | paired command &27E0
    EQUB &00 ; original &29E1 | signed   +0 | paired command &27E1
    EQUB &00 ; original &29E2 | signed   +0 | paired command &27E2
final_city_exit_deltas:
    EQUB &06 ; original &29E3 | signed   +6 | paired command &27E3
    EQUB &FA ; original &29E4 | signed   -6 | paired command &27E4
; &29E5-&29FF: preserved source/build residue.
    EQUB &FF, &6D, &70, &7A, &3A, &4C, &44, &41, &74, &6F, &70, &2B, &31, &3A, &41, &44    ; original &29E5
    EQUB &43, &23, &60, &67, &61, &75, &67, &65, &73, &69, &7A    ; original &29F5
; LANDSCAPE OBJECT SCRIPT (&2A00-&2AA0)
; 160 object-type bytes then &FF.  The stream contains only scenery targets:
;   48 TYPE_GROUND_MISSILE, 69 TYPE_FUEL_TANK,
;   40 TYPE_MYSTERY_TARGET, and 3 TYPE_FINAL_BASE entries.
; Objects are stamped/spawned when upper_delta reaches zero and the current
; terrain run reaches the per-type horizontal trigger offset at &2C62.
; -----------------------------------------------------------------------------
; FIXED LANDSCAPE OBJECT SCRIPT - 160 object types + &FF terminator
; Dynamic Phizzers/meteorites are NOT here; section code spawns them separately.
; -----------------------------------------------------------------------------
landscape_object_stream:
; Stage 11 exact scenery-script partition.  Section transitions are determined
; by terrain command budgets; the object stream itself carries no section markers.
; These labels therefore document where the global object index has reached at
; each proven section boundary without inserting/removing any bytes.
section0_scenery_script:
; object indices 0..46 (47 entries): 18 TYPE_GROUND_MISSILE, 16 TYPE_FUEL_TANK, 13 TYPE_MYSTERY_TARGET
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A00
    EQUB TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE    ; original &2A08
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET    ; original &2A10
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET    ; original &2A18
    EQUB TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE    ; original &2A20
    EQUB TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_GROUND_MISSILE, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A28
section1_scenery_script:
; object indices 47..53 (7 entries): 3 TYPE_GROUND_MISSILE, 3 TYPE_FUEL_TANK, 1 TYPE_MYSTERY_TARGET
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A2F
section2_scenery_script:
; object indices 54..97 (44 entries): 16 TYPE_GROUND_MISSILE, 15 TYPE_FUEL_TANK, 13 TYPE_MYSTERY_TARGET
    EQUB TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE    ; original &2A36
    EQUB TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET    ; original &2A3E
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE    ; original &2A46
    EQUB TYPE_GROUND_MISSILE, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A4E
    EQUB TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A56
    EQUB TYPE_MYSTERY_TARGET, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK    ; original &2A5E
section3_scenery_script:
; object indices 98..132 (35 entries): 11 TYPE_GROUND_MISSILE, 11 TYPE_FUEL_TANK, 13 TYPE_MYSTERY_TARGET
    EQUB TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_FUEL_TANK    ; original &2A62
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_MYSTERY_TARGET    ; original &2A6A
    EQUB TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET    ; original &2A72
    EQUB TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE, TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE    ; original &2A7A
    EQUB TYPE_FUEL_TANK, TYPE_MYSTERY_TARGET, TYPE_GROUND_MISSILE    ; original &2A82
section4_scenery_script:
; object indices 133..156 (24 entries): 24 TYPE_FUEL_TANK
    EQUB TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK    ; original &2A85
    EQUB TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK    ; original &2A8D
    EQUB TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK, TYPE_FUEL_TANK    ; original &2A95
section5_scenery_script:
; object indices 157..159 (3 entries): 3 TYPE_FINAL_BASE
    EQUB TYPE_FINAL_BASE, TYPE_FINAL_BASE, TYPE_FINAL_BASE    ; original &2A9D
landscape_object_stream_end:
    EQUB &FF    ; original &2AA0 - end marker; all 160 scenery entries consumed

; IMPORTANT: &2AA1-&2AFF is preserved original build/source residue.
; It is not part of the scenery stream, but its 95 bytes MUST remain physically
; present so that object workspace begins at the absolute address &2B00.
    EQUB &24, &41, &25, &2C, &41, &24, &29, &F1, &5A, &25, &3F, &31, &2A, &32, &35, &36    ; &2AA1
    EQUB &2B, &5A, &25, &3F, &32, &3B, &0D, &33, &2C, &1A, &5A, &25, &3D, &5A, &25, &2B    ; &2AB1
    EQUB &5A, &25, &3F, &33, &3A, &FD, &5A, &25, &3F, &31, &3E, &26, &37, &46, &3A, &E1    ; &2AC1
    EQUB &0D, &33, &90, &05, &20, &0D, &33, &F4, &26, &DD, &F2, &73, &61, &76, &65, &20    ; &2AD1
    EQUB &FF, &28, &22, &53, &2E, &53, &52, &43, &42, &20, &22, &2B, &C3, &7E, &90, &2B    ; &2AE1
    EQUB &22, &20, &22, &2B, &C3, &7E, &B8, &50, &29, &3A, &E1, &0D, &FF, &9C, &00    ; &2AF1
; -----------------------------------------------------------------------------
; RUNTIME OBJECT ARRAYS / TERRAIN PROFILES
; Initial bytes are preserved exactly although most are overwritten during init.
; -----------------------------------------------------------------------------
object_screen_lo: ; &2B00, 20 bytes - current screen address, low byte
    EQUB &73, &61, &76, &65, &00, &E0, &2A, &91, &99, &AE    ; &2B00
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &2B0A
object_screen_hi: ; &2B14, 20 bytes - current screen address, high byte
    EQUB &49, &00, &00, &00, &00, &00, &00, &00, &00, &77    ; &2B14
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &2B1E
object_prev_screen_lo: ; &2B28, 20 bytes - previous screen address, low byte
    EQUB &F4, &A1, &A1, &A1, &A1, &A1, &A1, &A1, &99, &AE    ; &2B28
    EQUB &06, &1C, &A1, &00, &00, &00, &00, &00, &00, &00    ; &2B32
object_prev_screen_hi: ; &2B3C, 20 bytes - previous screen address, high byte
    EQUB &49, &00, &00, &00, &00, &00, &00, &00, &00, &77    ; &2B3C
    EQUB &78, &79, &00, &00, &00, &00, &00, &00, &00, &00    ; &2B46
object_type_table: ; &2B50, 20 bytes - object type ID
    EQUB &00, &0A, &0A, &09, &09, &09, &09, &FF, &04, &02    ; &2B50
    EQUB &05, &01, &0C, &01, &02, &32, &20, &22, &2B, &C3    ; &2B5A
object_state_table: ; &2B64, 20 bytes - state / animation / flags
    EQUB &80, &80, &80, &80, &80, &80, &80, &9D, &DC, &00    ; &2B64
    EQUB &00, &00, &80, &00, &00, &FF, &00, &00, &73, &61    ; &2B6E
object_x_table: ; &2B78, 20 bytes - game X coordinate; zero means inactive
    EQUB &06, &00, &00, &00, &00, &00, &00, &00, &00, &1C    ; &2B78
    EQUB &27, &4A, &00, &00, &00, &00, &00, &00, &00, &00    ; &2B82
object_y_table: ; &2B8C, 20 bytes - game Y coordinate
    EQUB &BB, &00, &00, &00, &00, &00, &00, &52, &4B, &29    ; &2B8C
    EQUB &29, &2B, &DF, &00, &00, &00, &00, &00, &00, &00    ; &2B96
upper_terrain_profile: ; &2BA0, 33 bytes - rolling upper/ceiling edge profile
    EQUB &08, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18    ; &2BA0
    EQUB &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18    ; &2BAB
    EQUB &18, &18, &18, &18, &18, &18, &18, &18, &18, &90, &0E    ; &2BB6
lower_terrain_profile: ; &2BC1, 33 bytes - rolling lower/floor edge profile
    EQUB &D8, &A6, &A7, &AB, &B0, &B0, &AF, &B2, &B3, &B5, &B7    ; &2BC1
    EQUB &BB, &C0, &BE, &BE, &BD, &C0, &C1, &C3, &C5, &C7, &B0    ; &2BCC
    EQUB &B3, &B1, &B0, &B2, &B5, &B3, &B2, &B4, &B5, &15, &18    ; &2BD7
; -----------------------------------------------------------------------------
; GAMEPLAY DESCRIPTOR TABLES
; Index is section or object type as documented on each label.
; -----------------------------------------------------------------------------
initial_palette_table: ; &2BE2 - 16 logical-colour -> physical-colour entries
    EQUB &00, &01, &07, &03, &01, &05, &06, &07, &00, &01, &02, &03, &04    ; &2BE2
    EQUB &05, &06, &07    ; &2BEF
object_score_lo: ; &2BF2 - packed-BCD score low byte by object type 0..12
    EQUB &00, GROUND_MISSILE_SCORE_LO, FUEL_TANK_SCORE_LO, FINAL_BASE_SCORE_LO
    EQUB PHIZZER_SCORE_LO, &00, &00, &00, &00, &00, &00, &00, LAUNCHED_MISSILE_SCORE_LO
object_score_mid: ; &2BFF - packed-BCD score middle byte by object type 0..12
    EQUB &00, GROUND_MISSILE_SCORE_MID, FUEL_TANK_SCORE_MID, FINAL_BASE_SCORE_MID
    EQUB PHIZZER_SCORE_MID, &05, &00, &00, &00, &00, &00, &00, LAUNCHED_MISSILE_SCORE_MID
    ; Type 5's &0500 nominal entry is not the live award: resolve_object_hit uses
    ; special_score_lo/mid below to choose 200/350/450/600 pseudo-randomly.
section_upper_cmd_budget: ; original &2C0C - command count by section
    ; Sections 0..4 derive their budgets directly from labelled command ranges,
    ; eliminating five magic counts.  Section 5 is intentionally &80: the &FF
    ; command terminator ends the raid after 110 real commands before the budget.
    EQUB upper_section1_commands-upper_section0_commands
    EQUB upper_section2_commands-upper_section1_commands
    EQUB upper_section3_commands-upper_section2_commands
    EQUB upper_section4_commands-upper_section3_commands
    EQUB upper_section5_commands-upper_section4_commands
    EQUB SECTION5_TERMINATOR_BUDGET
section_lower_mode: ; &2C12 - only cavern (1) and maze (4) generate a lower edge
    EQUB LOWER_TERRAIN_DISABLED, LOWER_TERRAIN_ENABLED, LOWER_TERRAIN_DISABLED
    EQUB LOWER_TERRAIN_DISABLED, LOWER_TERRAIN_ENABLED, LOWER_TERRAIN_DISABLED
special_score_lo: ; &2C18 - mystery-target random award low BCD
    EQUB MYSTERY_SCORE_200_LO, MYSTERY_SCORE_350_LO, MYSTERY_SCORE_450_LO, MYSTERY_SCORE_600_LO
special_score_mid: ; &2C1C - mystery-target random award middle BCD
    EQUB MYSTERY_SCORE_200_MID, MYSTERY_SCORE_350_MID, MYSTERY_SCORE_450_MID, MYSTERY_SCORE_600_MID
section_colour_code: ; &2C20 - terrain physical colour by section
    EQUB COLOUR_MAGENTA, COLOUR_RED, COLOUR_GREEN, COLOUR_BLUE, COLOUR_YELLOW, COLOUR_CYAN
section_envelope_index: ; original &2C26 - selects one 14-byte envelope record
    EQUB SECTION_ENVELOPE_DEFAULT, SECTION_ENVELOPE_CAVERN, SECTION_ENVELOPE_METEOR
    EQUB SECTION_ENVELOPE_DEFAULT, SECTION_ENVELOPE_DEFAULT, SECTION_ENVELOPE_DEFAULT
dead_bytes_2c2c:                       ; proven no live code/data xrefs in released build
unreferenced_descriptor_prefix:        ; compatibility label; original &2C2C = &23,&28
    EQUB &23, &28    ; &2C2C
object_height_pixels: ; original &2C2E - sprite height in scanlines by type
    EQUB PLAYER_SPRITE_HEIGHT, GROUND_MISSILE_SPRITE_HEIGHT, FUEL_TANK_SPRITE_HEIGHT
    EQUB FINAL_DUSTBIN_SPRITE_HEIGHT, PHIZZER_SPRITE_HEIGHT, MYSTERY_TARGET_SPRITE_HEIGHT
    EQUB METEORITE_SPRITE_HEIGHT, UNUSED_7_SPRITE_HEIGHT, PLAYER_EXPLOSION_SPRITE_HEIGHT
    EQUB BULLET_SPRITE_HEIGHT, BOMB_SPRITE_HEIGHT, LIFE_ICON_SPRITE_HEIGHT, LAUNCHED_MISSILE_SPRITE_HEIGHT
object_sprite_bytes: ; original &2C3B - total sprite bytes by type
    EQUB PLAYER_SPRITE_BYTES, GROUND_MISSILE_SPRITE_BYTES, FUEL_TANK_SPRITE_BYTES
    EQUB FINAL_DUSTBIN_SPRITE_BYTES, PHIZZER_SPRITE_BYTES, MYSTERY_TARGET_SPRITE_BYTES
    EQUB METEORITE_SPRITE_BYTES, UNUSED_7_SPRITE_BYTES, PLAYER_EXPLOSION_SPRITE_BYTES
    EQUB BULLET_SPRITE_BYTES, BOMB_SPRITE_BYTES, LIFE_ICON_SPRITE_BYTES, LAUNCHED_MISSILE_SPRITE_BYTES
object_sprite_hi: ; original &2C48 - high byte of sprite address by object type
    EQUB >sprite_player, >sprite_ground_missile, >sprite_fuel_tank, >sprite_final_base
    EQUB >sprite_phizzer, >sprite_mystery_target, >sprite_meteorite, >sprite_unused_7
    EQUB >sprite_player_explosion, >sprite_bullet, >sprite_bomb, >sprite_life_icon
    EQUB >sprite_launched_missile
object_sprite_lo: ; original &2C55 - low byte of sprite address by object type
    EQUB <sprite_player, <sprite_ground_missile, <sprite_fuel_tank, <sprite_final_base
    EQUB <sprite_phizzer, <sprite_mystery_target, <sprite_meteorite, <sprite_unused_7
    EQUB <sprite_player_explosion, <sprite_bullet, <sprite_bomb, <sprite_life_icon
    EQUB <sprite_launched_missile
object_trigger_offset: ; original &2C62 - mixed-use per-type auxiliary table
    EQUB PLAYER_PROJECTILE_X_OFFSET, GROUND_MISSILE_SCENERY_PERIOD, FUEL_TANK_SCENERY_PERIOD
    EQUB FINAL_DUSTBIN_SCENERY_PERIOD, TRIGGER_UNUSED_TYPE4, MYSTERY_TARGET_SCENERY_PERIOD
    EQUB TRIGGER_UNUSED_TYPE6, TRIGGER_UNUSED_TYPE7, TRIGGER_UNUSED_TYPE8
    EQUB TRIGGER_UNUSED_TYPE9, TRIGGER_UNUSED_TYPE10, TRIGGER_UNUSED_TYPE11, TRIGGER_UNUSED_TYPE12
; -----------------------------------------------------------------------------
; SCORE/RAID NUMERIC FONT - 11 glyphs x 16 bytes
; -----------------------------------------------------------------------------
; print_score_digit uses the high nibble as a direct 16-byte offset. Digits
; therefore live at offsets &00,&10,...,&90.  &A0 is the special leading-zero
; blank/dot pattern selected while score_leading_zero_flag is still non-zero.
score_digit_font:
score_glyph_0: ; original &2C6F
    EQUB &15, &15, &15, &15, &15, &15, &15, &15, &3F, &15, &15, &15, &15, &15, &15, &3F
score_glyph_1: ; original &2C7F
    EQUB &00, &15, &00, &00, &00, &00, &00, &15, &2A, &2A, &2A, &2A, &2A, &2A, &2A, &3F
score_glyph_2: ; original &2C8F
    EQUB &15, &00, &00, &00, &15, &15, &15, &15, &3F, &15, &15, &15, &3F, &00, &00, &3F
score_glyph_3: ; original &2C9F
    EQUB &15, &00, &00, &00, &15, &00, &00, &15, &3F, &15, &15, &15, &3F, &15, &15, &3F
score_glyph_4: ; original &2CAF
    EQUB &15, &15, &15, &15, &15, &00, &00, &00, &00, &00, &15, &15, &3F, &15, &15, &15
score_glyph_5: ; original &2CBF
    EQUB &15, &15, &15, &15, &00, &00, &00, &15, &3F, &00, &00, &3F, &15, &15, &15, &3F
score_glyph_6: ; original &2CCF
    EQUB &15, &15, &15, &15, &15, &15, &15, &15, &00, &00, &00, &3F, &15, &15, &15, &3F
score_glyph_7: ; original &2CDF
    EQUB &15, &00, &00, &00, &00, &00, &00, &00, &3F, &15, &15, &15, &3F, &15, &15, &15
score_glyph_8: ; original &2CEF
    EQUB &15, &15, &15, &15, &15, &15, &15, &15, &3F, &15, &15, &3F, &15, &15, &15, &3F
score_glyph_9: ; original &2CFF
    EQUB &15, &15, &15, &15, &00, &00, &00, &15, &3F, &15, &15, &3F, &15, &15, &15, &3F
score_glyph_leading_blank: ; original &2D0F
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00
; =============================================================================
; SPRITE DATA - descriptor-address order
; All sprites are XOR-rendered MODE 2 byte streams. Dimensions are decoded from
; object_height_pixels and object_sprite_bytes.
; =============================================================================
sprite_launched_missile: ; &2D1F - TYPE_LAUNCHED_MISSILE, 6 x 23 pixels, 69 bytes
    EQUB &00, &00, &00, &41, &55, &55, &14, &00, &14, &14, &14, &00    ; &2D1F
    EQUB &00, &00, &AA, &AA, &EB, &41, &41, &00, &AA, &AA, &AA, &82    ; &2D2B
    EQUB &82, &82, &41, &41, &41, &00, &00, &00, &00, &00, &00, &00    ; &2D37
    EQUB &00, &82, &82, &C3, &41, &41, &00, &00, &00, &00, &00, &00    ; &2D43
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &2D4F
    EQUB &AA, &AA, &AA, &00, &00, &00, &AA, &AA, &AA    ; &2D5B
sprite_player_explosion: ; &2D64 - TYPE_PLAYER_EXPLOSION, 18 x 14 pixels, 126 bytes
    EQUB &00, &22, &33, &00, &44, &44, &00, &22, &33, &44, &00, &00    ; &2D64
    EQUB &11, &22, &00, &00, &22, &66, &33, &CC, &99, &33, &CC, &CC    ; &2D70
    EQUB &33, &22, &00, &00, &00, &00, &CC, &CC, &33, &CC, &66, &99    ; &2D7C
    EQUB &CC, &66, &CC, &44, &11, &11, &22, &33, &99, &33, &99, &CC    ; &2D88
    EQUB &99, &CC, &CC, &99, &33, &22, &00, &00, &00, &00, &CC, &99    ; &2D94
    EQUB &99, &33, &CC, &99, &CC, &CC, &CC, &00, &00, &00, &11, &11    ; &2DA0
    EQUB &66, &66, &CC, &CC, &99, &66, &CC, &CC, &66, &22, &22, &11    ; &2DAC
    EQUB &22, &00, &88, &CC, &99, &33, &66, &CC, &33, &CC, &22, &11    ; &2DB8
    EQUB &00, &00, &00, &00, &00, &33, &22, &88, &88, &99, &66, &00    ; &2DC4
    EQUB &00, &33, &11, &00, &00, &00, &22, &00, &00, &00, &11, &33    ; &2DD0
    EQUB &00, &00, &00, &00, &33, &00    ; &2DDC
sprite_bullet: ; &2DE2 - TYPE_BULLET, 2 x 2 pixels, 2 bytes
    EQUB &0F, &0F    ; &2DE2
sprite_bomb: ; &2DE4 - TYPE_BOMB, 4 x 7 pixels, 14 bytes
    EQUB &15, &15, &15, &3F, &15, &15, &15, &00, &00, &00, &2A, &00    ; &2DE4
    EQUB &00, &00    ; &2DF0
sprite_life_icon: ; &2DF2 - TYPE_LIFE_ICON, 8 x 8 pixels, 32 bytes
    EQUB &33, &2A, &3F, &15, &3F, &2A, &33, &00, &00, &15, &2B, &3F    ; &2DF2
    EQUB &2B, &15, &00, &00, &00, &2A, &2B, &3F, &2B, &2A, &00, &00    ; &2DFE
    EQUB &00, &00, &2A, &3F, &2A, &00, &00, &00    ; &2E0A
sprite_player: ; &2E12 - TYPE_PLAYER, 14 x 10 pixels, 70 bytes
    EQUB &33, &15, &15, &00, &00, &00, &00, &15, &15, &33, &33, &2A    ; &2E12
    EQUB &2A, &3F, &3F, &3F, &3F, &2A, &2A, &33, &22, &00, &15, &2B    ; &2E1E
    EQUB &3F, &3F, &2B, &15, &00, &22, &00, &3F, &2B, &2B, &3F, &3F    ; &2E2A
    EQUB &2B, &2B, &3F, &00, &00, &2A, &2B, &2B, &3F, &3F, &2B, &2B    ; &2E36
    EQUB &2A, &00, &00, &00, &2A, &2B, &3F, &3F, &2B, &2A, &00, &00    ; &2E42
    EQUB &00, &00, &00, &00, &3F, &3F, &00, &00, &00, &00    ; &2E4E
sprite_ground_missile: ; &2E58 - TYPE_GROUND_MISSILE, 6 x 20 pixels, 60 bytes
    EQUB &00, &00, &00, &41, &55, &55, &55, &55, &41, &41, &41, &41    ; &2E58
    EQUB &41, &41, &EB, &EB, &AA, &AA, &AA, &AA, &82, &82, &82, &C3    ; &2E64
    EQUB &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &41, &41    ; &2E70
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &2E7C
    EQUB &00, &00, &00, &00, &00, &00, &AA, &AA, &AA, &AA, &AA, &AA    ; &2E88
sprite_fuel_tank: ; &2E94 - TYPE_FUEL_TANK, 12 x 16 pixels, 96 bytes
    EQUB &00, &44, &CC, &CC, &CC, &CC, &CC, &44, &00, &00, &00, &00    ; &2E94
    EQUB &00, &51, &51, &51, &CC, &CC, &F3, &E6, &F3, &E6, &E6, &CC    ; &2EA0
    EQUB &CC, &51, &51, &F3, &A2, &F3, &00, &00, &CC, &CC, &C6, &C6    ; &2EAC
    EQUB &C6, &C6, &C3, &CC, &CC, &F3, &00, &F3, &00, &F3, &00, &00    ; &2EB8
    EQUB &CC, &CC, &D3, &D3, &D3, &D3, &D3, &CC, &CC, &F3, &00, &F3    ; &2EC4
    EQUB &00, &F3, &00, &00, &CC, &CC, &E3, &C9, &E3, &C9, &E3, &CC    ; &2ED0
    EQUB &CC, &A2, &A2, &F3, &51, &F3, &00, &00, &00, &88, &CC, &CC    ; &2EDC
    EQUB &CC, &CC, &C6, &88, &00, &00, &00, &00, &00, &A2, &A2, &A2    ; &2EE8
sprite_final_base: ; &2EF4 - TYPE_FINAL_BASE, 12 x 16 pixels, 96 bytes
    EQUB &00, &00, &50, &CC, &CC, &CC, &44, &44, &51, &51, &51, &51    ; &2EF4
    EQUB &F3, &F3, &F3, &51, &44, &C9, &C9, &E4, &D8, &CC, &DC, &DC    ; &2F00
    EQUB &DC, &44, &00, &00, &A2, &A2, &A2, &00, &CC, &C9, &C9, &CC    ; &2F0C
    EQUB &F0, &CC, &EC, &EC, &EC, &CC, &CC, &51, &F3, &F3, &F3, &51    ; &2F18
    EQUB &CC, &C9, &C9, &CC, &F0, &CC, &FC, &FC, &FC, &CC, &88, &00    ; &2F24
    EQUB &A2, &A2, &A2, &00, &00, &88, &D8, &E4, &CC, &CC, &CC, &CC    ; &2F30
    EQUB &D9, &51, &51, &51, &F3, &F3, &F3, &51, &00, &00, &00, &88    ; &2F3C
    EQUB &88, &88, &00, &00, &00, &00, &00, &00, &A2, &A2, &A2, &00    ; &2F48
sprite_mystery_target: ; &2F54 - TYPE_MYSTERY_TARGET, 12 x 16 pixels, 96 bytes
    EQUB &00, &00, &00, &41, &C3, &C3, &C3, &C3, &C3, &C3, &41, &51    ; &2F54
    EQUB &41, &C3, &C3, &41, &00, &41, &00, &41, &E3, &E3, &E3, &E3    ; &2F60
    EQUB &E3, &41, &41, &00, &00, &82, &82, &00, &C3, &C3, &E9, &C3    ; &2F6C
    EQUB &C7, &CF, &CF, &DA, &DA, &DA, &DA, &C3, &41, &C3, &C3, &41    ; &2F78
    EQUB &82, &C3, &A8, &C3, &E1, &E1, &E1, &E1, &E1, &E1, &C3, &82    ; &2F84
    EQUB &00, &82, &82, &00, &00, &00, &00, &41, &E3, &E3, &E3, &E3    ; &2F90
    EQUB &E3, &41, &41, &51, &41, &C3, &C3, &41, &00, &00, &00, &00    ; &2F9C
    EQUB &82, &82, &82, &82, &82, &82, &00, &00, &00, &82, &82, &00    ; &2FA8
sprite_phizzer: ; &2FB4 - TYPE_PHIZZER, 6 x 6 pixels, 18 bytes
    EQUB &44, &CC, &C9, &C9, &CC, &44, &CC, &CC, &CC, &CC, &CC, &CC    ; &2FB4
    EQUB &88, &CC, &C6, &C6, &CC, &88    ; &2FC0
sprite_meteorite: ; &2FC6 - TYPE_METEORITE, 8 x 10 pixels, 40 bytes
    EQUB &00, &00, &00, &01, &01, &07, &03, &17, &01, &00, &00, &01    ; &2FC6
    EQUB &03, &03, &07, &0B, &03, &15, &03, &03, &03, &03, &07, &0B    ; &2FD2
    EQUB &03, &01, &03, &03, &3F, &03, &00, &02, &2B, &0F, &17, &0B    ; &2FDE
    EQUB &07, &0B, &02, &00    ; &2FEA
sprite_unused_7: ; original &2FEE - TYPE_UNUSED_SPRITE_7, 6 x 6 pixels, 18 bytes
    ; Complete static xref: the descriptor pointer table references this graphic,
    ; but no live instruction assigns object type 7 to a slot.  Treat as an
    ; unused/abandoned sprite unless runtime evidence proves otherwise.
    EQUB &00, &01, &17, &01, &00, &00, &00, &0B, &07, &2B, &05, &00    ; &2FEE
    EQUB &03, &3F, &0B, &2F, &02, &00    ; &2FFA
; FINAL ARCHIVAL STATUS FOR REMAINING ODDITIES
;   &3C          write-only life-state byte: cleared, never read in released code
;   &2C2C-&2C2D no live xrefs; preserved as dead/orphan bytes &23,&28
;   object type 7 has valid descriptor/sprite but no live allocator/xref
; These are deliberately NOT assigned invented gameplay meanings.
core_image_end:                         ; original &3000; persistent core size = &2200 bytes
; -----------------------------------------------------------------------------
; TRANSIENT COPIED UI / HALL-OF-FAME / CONTROLLER BLOCK
; -----------------------------------------------------------------------------
; Fixed at CONTROLLER_IMAGE_ORIGIN.  Keeping this block independent of the movable
; core is the key to safe relocation: MODE 2 later reclaims this RAM as screen memory.
ORG CONTROLLER_IMAGE_ORIGIN
controller_image_start:
; Original address range &3000-&32FF.
;
; The first &FF bytes are display data followed immediately by executable code.
; The three labels below are at the EXACT image/runtime boundaries used by the
; copied controller, avoiding the misleading mid-row label used in Stage 7/8.
; Runtime address = image label + CONTROLLER_RELOCATION_DELTA.
; -----------------------------------------------------------------------------
high_score_entry_message_image:        ; &3000 -> runtime &0400
; Mode-7/VDU stream: congratulations + "Top Eight" + name-entry prompt.
    EQUB &86, &16, &07, &1F, &07, &03, &86, &9D, &84, &8D, &43, &6F, &6E, &67, &72, &61    ; &3000
    EQUB &74, &75, &6C, &61, &74, &69, &6F, &6E, &73, &21, &21, &20, &20, &20, &9C, &1F    ; &3010
    EQUB &07, &04, &86, &9D, &84, &8D, &43, &6F, &6E, &67, &72, &61, &74, &75, &6C, &61    ; &3020
    EQUB &74, &69, &6F, &6E, &73, &21, &21, &20, &20, &20, &9C, &1F, &03, &07, &82, &59    ; &3030
    EQUB &6F, &75, &72, &20, &73, &63, &6F, &72, &65, &20, &69, &73, &20, &69, &6E, &20    ; &3040
    EQUB &74, &68, &65, &20, &54, &6F, &70, &20, &45, &69, &67, &68, &74, &2E, &1F, &07    ; &3050
    EQUB &0A, &81, &50, &6C, &65, &61, &73, &65, &20, &65, &6E, &74, &65, &72, &20, &79    ; &3060
    EQUB &6F, &75, &72, &20, &6E, &61, &6D, &65, &3A, &1F, &07, &0F, &86, &9D, &84, &1F    ; &3070
    EQUB &1F, &0F, &9C, &1F, &0A, &0F    ; &3080

hall_of_fame_header_image:             ; &3086 -> runtime &0486
; CR-terminated stream that clears/positions the display and prints the
; double-height "Rocket Raid Hall Of Fame" heading.
    EQUB &16, &07, &1F, &06, &01, &81, &8D, &52, &6F, &63, &6B, &65, &74, &20, &52, &61    ; &3086
    EQUB &69, &64, &20, &48, &61, &6C, &6C, &20, &4F, &66, &20, &46, &61, &6D, &65, &1F    ; &3096
    EQUB &06, &02, &81, &8D, &52, &6F, &63, &6B, &65, &74, &20, &52, &61, &69, &64, &20    ; &30A6
    EQUB &48, &61, &6C, &6C, &20, &4F, &66, &20, &46, &61, &6D, &65, &0A, &0A, &0A, &0D    ; &30B6

spacestring_image:
hall_of_fame_start_prompt_image:       ; &30C6 -> runtime &04C6, ORIGINAL source label spacestring
; CR-terminated "Press SPACE BAR or Fire Button / On Joystick To Start".
    EQUB &1F, &05, &16, &50, &72, &65, &73, &73, &20, &53, &50, &41, &43, &45, &20, &42    ; &30C6
    EQUB &41, &52, &20, &6F, &72, &20, &46, &69, &72, &65, &20, &42, &75, &74, &74, &6F    ; &30D6
    EQUB &6E, &1F, &0A, &17, &4F, &6E, &20, &4A, &6F, &79, &73, &74, &69, &63, &6B, &20    ; &30E6
    EQUB &54, &6F, &20, &53, &74, &61, &72, &74, &0D    ; &30F6

; -----------------------------------------------------------------------------
; COPIED HALL-OF-FAME CODE - image &30FF-&3263, runtime &04FF-&0663
; -----------------------------------------------------------------------------
; This code is stored in the main image but executed only after &3400 has copied
; &3000-&32FF down by &2C00.  Relative branches can use image labels normally;
; absolute JSR/JMP operands use the runtime aliases (&05xx/&06xx).
;
hall_of_fame_fallback_image:           ; &30FF -> runtime &04FF
    JMP hall_of_fame_display            ; score did not qualify: display table

checkhi_score_image:                    ; &3102 -> runtime &0502 (checkhi_score)
    JSR flush_input_and_quiet_sound     ; clear input and silence channel 1
    LDX #RAID_COMPLETE_DELAY_TICKS
    JSR delay_ticks                     ; short pause before score test
    LDA #BYTE_TRUE
    STA sysvia_ier                      ; restore VIA interrupt enables used by controller

    ; The ladder is stored low/mid/high at ladder+0/+1/+2.  Compare against the
    ; lowest qualifying entry at offset 3 (ladder+3..+5), high byte first.
    LDA score_hi
    CMP ladder+5
    BCC hall_of_fame_fallback_image
    BNE high_score_qualifies_image
    LDA score_mid
    CMP ladder+4
    BCC hall_of_fame_fallback_image
    BNE high_score_qualifies_image
    LDA score_lo
    CMP ladder+3
    BCC hall_of_fame_fallback_image

high_score_qualifies_image:             ; &3128 -> runtime &0528
    ; &0400 is a length-prefixed Mode-7 "Congratulations / enter your name" block.
    LDX #<high_score_entry_message
    LDY #>high_score_entry_message
    JSR microsoftstring

    ; Clear Escape state, then construct the standard OSWORD 0 line-input block:
    ;   +0/+1 buffer &07E5, +2 max=19, +3 min=&20, +4 max=&7E.
    LDA #OSBYTE_ACK_ESCAPE
    JSR osbyte
    LDY #>HIGH_SCORE_OSWORD_BLOCK
    LDX #<HIGH_SCORE_OSWORD_BLOCK
    LDA #<HIGH_SCORE_INPUT_BUFFER
    STA HIGH_SCORE_OSWORD_BLOCK+0
    STY HIGH_SCORE_OSWORD_BLOCK+1
    LDA #HIGH_SCORE_INPUT_MAX
    STA HIGH_SCORE_OSWORD_BLOCK+2
    LDA #HIGH_SCORE_INPUT_MIN_ASCII
    STA HIGH_SCORE_OSWORD_BLOCK+3
    LDA #HIGH_SCORE_INPUT_MAX_ASCII
    STA HIGH_SCORE_OSWORD_BLOCK+4
    LDA #OSWORD_READ_LINE
    JSR osword
    BCC high_score_name_received_image

    ; Escape/cancel: force an empty CR-terminated name rather than entering the
    ; MOS error path.  This is original behaviour; *TAPE in the BASIC bootstrap
    ; is still required for the original MOS environment to behave correctly.
    LDA #ASCII_CR
    STA HIGH_SCORE_INPUT_BUFFER

high_score_name_received_image:         ; &315B -> runtime &055B
    ; string[0] points at name[0].  Copy exactly 20 bytes of the line-input
    ; buffer into that first name slot; subsequent sorting moves the pointer.
    LDA score_string_table
    STA stringptr_lo
    LDA score_string_table+1
    STA stringptr_hi
    LDY #HIGH_SCORE_NAME_BYTES-1
copy_entered_name_image:
    LDA HIGH_SCORE_INPUT_BUFFER,Y
    STA (stringptr_lo),Y
    DEY
    BPL copy_entered_name_image

    ; Insert the current 3-byte packed-BCD score into ladder entry 0.
    LDA score_lo
    STA ladder+0
    LDA score_mid
    STA ladder+1
    LDA score_hi
    STA ladder+2

    ; Bubble the newly inserted entry upward.  Entry 0 is scratch/current score;
    ; offsets 3..24 are the eight displayed Hall-of-Fame entries.  The allocated
    ; tenth score record at offset 27 is an unused guard: X reaches &1B and exits
    ; BEFORE comparing that record.  X is a byte offset, Y=X-3 is its neighbour.
    LDX #HIGH_SCORE_SORT_FIRST_OFFSET
high_score_sort_pass_image:             ; &3180 -> runtime &0580
    TXA
    TAY
    DEY
    DEY
    DEY
    LDA ladder+2,Y
    CMP ladder+2,X
    BCC high_score_sort_next_image
    BNE high_score_swap_entries_image
    LDA ladder+1,Y
    CMP ladder+1,X
    BCC high_score_sort_next_image
    BNE high_score_swap_entries_image
    LDA ladder+0,Y
    CMP ladder+0,X
    BCC high_score_sort_next_image

high_score_swap_entries_image:          ; &31A1 -> runtime &05A1
    ; Swap the 3-byte scores using tempsc, then swap the associated two-byte
    ; name pointers in score_string_table so score and player name stay paired.
    LDA ladder+0,X
    STA tempsc+0
    LDA ladder+1,X
    STA tempsc+1
    LDA ladder+2,X
    STA tempsc+2
    LDA ladder+0,Y
    STA ladder+0,X
    LDA ladder+1,Y
    STA ladder+1,X
    LDA ladder+2,Y
    STA ladder+2,X
    LDA tempsc+0
    STA ladder+0,Y
    LDA tempsc+1
    STA ladder+1,Y
    LDA tempsc+2
    STA ladder+2,Y

    LDA score_string_table+0,X
    STA tempsc+0
    LDA score_string_table+1,X
    STA tempsc+1
    LDA score_string_table+0,Y
    STA score_string_table+0,X
    LDA score_string_table+1,Y
    STA score_string_table+1,X
    LDA tempsc+0
    STA score_string_table+0,Y
    LDA tempsc+1
    STA score_string_table+1,Y

high_score_sort_next_image:             ; &31FB -> runtime &05FB
    INX
    INX
    INX
    CPX #HIGH_SCORE_SORT_STOP_OFFSET
    BEQ hall_of_fame_display_image
    JMP high_score_sort_pass_runtime   ; runtime address of image label above

hall_of_fame_display_image:             ; &3205 -> runtime &0605
    ; Clear screen / draw "Rocket Raid Hall Of Fame" header from &0486.
    LDX #<hall_of_fame_header
    LDY #>hall_of_fame_header
    JSR atomstring
    LDX #CRTC_CURSOR_START_REG
    LDA #CRTC_CURSOR_DISABLED
    JSR write_crtc_register

    ; Display exactly eight scores: offsets &18,&15,...,&03.  Offset 0 is the
    ; non-displayed insertion/sentinel end of this one-pass ladder arrangement.
    LDX #HALL_DISPLAY_START_OFFSET
    LDY #HALL_RANK_FIRST
    STY temp
printscores_image:
hall_of_fame_row_image:                 ; &3219 -> runtime &0619, ORIGINAL source label .printscores
    LDA #ASCII_SPACE
    JSR repeat_four_chars
    LDA temp
    ORA #ASCII_ZERO
    JSR oswrch
    JSR fourdots

    ; Packed BCD score: high, middle, low.  Y=&FF requests dots for leading zero
    ; nibbles until the first non-zero digit has been emitted.
    LDY #BCD_LEADING_DOTS_FLAG
    LDA ladder+2,X
    JSR print_packed_bcd_byte           ; packed-BCD byte printer used by Hall of Fame
    LDA ladder+1,X
    JSR print_packed_bcd_byte
    LDA ladder+0,X
    JSR print_packed_bcd_byte
    JSR fourdots

    ; score_string_table holds a two-byte pointer for each 3-byte score offset.
    TXA
    PHA
    LDA score_string_table+1,X
    TAY
    LDA score_string_table+0,X
    TAX
    JSR atomstring
    PLA
    TAX
    LDA #ASCII_LF
    JSR oswrch
    JSR oswrch
    INC temp
    DEX
    DEX
    DEX
    BNE hall_of_fame_row_image

    ; Footer prompt: "Press SPACE BAR or Fire Button / On Joystick To Start".
    LDX #<hall_of_fame_start_prompt
    LDY #>hall_of_fame_start_prompt
    JSR atomstring

; -----------------------------------------------------------------------------
; COPIED TITLE/START CONTROLLER - image &3264, runtime &0664 (.space)
; -----------------------------------------------------------------------------
space_image:                            ; &3264 -> runtime &0664, ORIGINAL .space
    LDA #OSBYTE_ACK_ESCAPE
    JSR osbyte

    ; `inkey` wraps OSBYTE &81.  When the requested key is held MOS returns
    ; X=&FF; otherwise X=0.  Q therefore does INX -> 0 and disables sound, while
    ; S stores &FF and enables sound.  This is why play_sound_effect can simply
    ; return when soundflag is zero.
    LDX #KEY_Q
    JSR inkey
    BEQ controller_no_q_image
    INX
    STX soundflag
controller_no_q_image:
noqkey_image:                          ; ORIGINAL .noqkey
    LDX #KEY_S
    JSR inkey
    BEQ controller_no_s_image
    STX soundflag
controller_no_s_image:
noskey_image:                          ; ORIGINAL .noskey

    ; SPACE selects keyboard control.  If SPACE is not held, switch to joystick
    ; mode and remain here until joystick fire is detected.
    LDA #BYTE_FALSE
    STA joyflag
    LDX #KEY_BACK_SPACE
    JSR inkey
    BNE controller_start_game_image
    LDA #BYTE_TRUE
    STA joyflag
    LDX #JOY_BUTTON_CHANNEL
    JSR adval
    TXA
    AND #JOY_BUTTON_MASK
    BEQ space_image

controller_start_game_image:            ; &3295 -> runtime &0695
here_image:                            ; ORIGINAL .here
    JSR game
    JMP checkhi_score

; -----------------------------------------------------------------------------
; ORIGINAL COPIED STRING HELPERS
; -----------------------------------------------------------------------------
microsoftstring_image:                  ; &329B -> runtime &069B, ORIGINAL symbol
    STX stringptr_lo
    STY stringptr_hi
    LDY #BYTE_FALSE
    LDA (stringptr_lo),Y
    STA string_length
    INY
microsoftstring_loop_image:
stringloop_image:                      ; ORIGINAL .stringloop
    LDA (stringptr_lo),Y
    JSR oswrch
    INY
    CPY string_length
    BNE microsoftstring_loop_image
    RTS

atomstring_image:                       ; &32B1 -> runtime &06B1, ORIGINAL symbol
    STX stringptr_lo
    STY stringptr_hi
    LDY #BYTE_FALSE
atomstring_loop_image:
atomstringloop_image:                  ; ORIGINAL .atomstringloop
    LDA (stringptr_lo),Y
    JSR oswrch
    INY
    CMP #ASCII_CR
    BNE atomstring_loop_image
    RTS

fourdots_image:                         ; &32C2 -> runtime &06C2, ORIGINAL symbol
    LDA #ASCII_DOT
repeat_four_chars_image:                ; &32C4 -> runtime &06C4
stringdollar_image:                    ; ORIGINAL .stringdollar - output A, Y times
    LDY #FOUR_DOTS_COUNT
repeat_four_chars_loop_image:
    JSR oswrch
    DEY
    BNE repeat_four_chars_loop_image
    RTS

    ; &32CD-&32CF are three original zero bytes after fourdots.
    EQUB &00, &00, &00
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32F0
controller_image_end:                  ; exclusive: exactly 3 pages copied to low RAM
transient_screen_seed_and_padding:     ; &3300-&33FF, retained for byte-exact archival build
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3300
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3310
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3320
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3330
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3340
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3350
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3360
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3370
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3380
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &3390
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &33A0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &33B0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &33C0
    EQUB &00, &00, &00, &00, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30    ; &33D0
    EQUB &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30    ; &33E0
    EQUB &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30, &30    ; &33F0

ORG STARTUP_ORIGIN
startup_image_start:
start:      ; REQUIRED entry symbol for generated boot disks (original &3400)
game_entry: ; original BASIC RAID2 eventually CALLs this startup entry

; Original source label recovered as .enter.
; Copy the &3000-&32FF UI/high-score/controller block into its runtime home
; at &0400-&06FF.  The descending-Y loop copies exactly 256 bytes per page.
enter:
    LDY #BYTE_FALSE
copy_controller_pages:
transloop:                              ; ORIGINAL .transloop
    LDA controller_image_start,Y
    STA CONTROLLER_RUNTIME_PAGE0,Y
    LDA controller_image_start+CONTROLLER_PAGE1_OFFSET,Y
    STA CONTROLLER_RUNTIME_PAGE1,Y
    LDA controller_image_start+CONTROLLER_PAGE2_OFFSET,Y
    STA CONTROLLER_RUNTIME_PAGE2,Y
    DEY
    BNE copy_controller_pages

    ; Y is zero here.  One more DEY creates &FF, the original default for
    ; soundflag before Q/S are sampled in the controller at runtime &0664.
    DEY
    STY soundflag

    ; Initialise ten 3-byte score entries in the high-score ladder.
    ; Recovered original source name: .scoreinit
    LDY #HIGH_SCORE_LADDER_BYTES
scoreinit:
    LDA #BYTE_FALSE
    STA ladder,Y
    STA ladder+2,Y
    LDA #HIGH_SCORE_DEFAULT_MID
    STA ladder+1,Y
    DEY
    DEY
    DEY
    BPL scoreinit

    ; Fill all ten 20-character name slots with "Acornsoft".  The original
    ; source uses name-1,Y so that Y=200 addresses the last byte of the array.
    LDY #HIGH_SCORE_NAMES_BYTES ; 10 * 20 bytes
nameinit:
    LDX #DEFAULT_NAME_LAST_INDEX      ; "Acornsoft" + CR = 10 bytes
innername:
    LDA acornsoft,X
    STA highscore_names-1,Y
    DEY
    DEX
    BPL innername
    TYA
    BNE nameinit

    ; Build the ten display pointers held in the 30-byte string table.
    ; Low byte advances by 20 for each name; all names live in page &07.
    LDX #<highscore_names              ; original source built low-byte name pointers
    LDY #HIGH_SCORE_LAST_OFFSET
stringinit:
    TXA
    STA score_string_table,Y
    CLC
    ADC #HIGH_SCORE_NAME_BYTES
    TAX
    LDA #>highscore_names              ; all names share this page in original layout
    STA score_string_table+1,Y
    DEY
    DEY
    DEY
    BPL stringinit

    ; Original source name: .cleartimeloop.  A is still &07 here.
    LDX #SYSTEM_CLOCK_BLOCK_LAST_INDEX
cleartimeloop:
    STA timespace,X
    DEX
    BPL cleartimeloop

    ; *FX 4,1 then CR.  This is original initialisation, not boot-loader code.
    LDA #OSBYTE_CURSOR_KEYS
    LDX #CURSOR_KEYS_RETURN_ASCII
    JSR osbyte
    LDA #ASCII_CR
    JSR oswrch

    ; Install the six 14-byte sound envelopes stored at &21F0-&2243.
    LDA #ENVELOPE_RECORD_COUNT
    STA temp                    ; original source symbol: temp
    LDA #<envelope_section_0
    STA envelope_install_ptr_lo ; original source used stringptr as this startup pointer
    LDA #>envelope_section_0
    STA envelope_install_ptr_hi
install_envelopes:
envloop:                                ; ORIGINAL .envloop
    LDX envelope_install_ptr_lo
    LDY envelope_install_ptr_hi
    LDA #OSWORD_DEFINE_ENVELOPE ; define envelope
    JSR osword
    LDA envelope_install_ptr_lo
    CLC
    ADC #ENVELOPE_RECORD_BYTES
    STA envelope_install_ptr_lo
    BCC envelope_pointer_ok
    INC envelope_install_ptr_hi
envelope_pointer_ok:
    DEC temp
    BNE install_envelopes

    LDA #STARTUP_IER_VALUE
    STA startup_flag
    JMP space                  ; copied controller: wait for SPACE/fire

; Original source label: acornsoft
acornsoft:
    EQUB &41,&63,&6F,&72,&6E,&73,&6F,&66,&74,ASCII_CR ; "Acornsoft", CR

; Three original zero bytes complete &349D-&349F.  Earlier annotated stages relied
; on the boot builder's padding here; Stage 8 emits the original &2700-byte runtime
; image explicitly, so the source itself is byte-for-byte complete.
    EQUB &00, &00, &00    ; &349D-&349F
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34A0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34B0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34C0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34F0


startup_image_end:
runtime_payload_end:                   ; archival original ends at &3500 with default origin

; Loader-only zero-page aliases (same physical bytes are reused by gameplay later).
loader_dest_lo           = &70
loader_dest_hi           = &71
loader_source_lo         = &72
loader_source_hi         = &73

; ------------------------------------------------------------
; DFS execution entry. This is NOT part of the relocated runtime payload.
; It copies the payload down by &1000 and returns to BASIC.
; ------------------------------------------------------------
ORG ORIGINAL_DFS_LOADER_ORIGIN
raidobj_loader:
    LDA #OSBYTE_SELECT_TAPE_FS ; OSBYTE &8C used by original loader
    LDX #BYTE_FALSE
    LDY #BYTE_FALSE
    JSR osbyte

    LDA #<ORIGINAL_RUNTIME_ORIGIN
    STA loader_dest_lo   ; archival loader always reconstructs original &0E00 layout
    STA loader_source_lo ; original $.RAIDOBJ source is page-aligned at &1E00
    LDA #>ORIGINAL_RUNTIME_ORIGIN
    STA loader_dest_hi
    LDA #>ORIGINAL_DFS_FILE_LOAD
    STA loader_source_hi
    LDY #BYTE_FALSE

copy_payload_page:
    LDA (loader_source_lo),Y
    STA (loader_dest_lo),Y
    INY
    BNE copy_payload_page
    INC loader_dest_hi
    INC loader_source_hi
    LDA loader_source_hi
    CMP #>ORIGINAL_DFS_FILE_END ; copied source through byte before exclusive end
    BNE copy_payload_page

    LDX #BYTE_FALSE
copy_low_workspace:
    LDA low_workspace_image,X
    STA LOW_WORKSPACE_DEST,X
    INX
    CPX #LOW_WORKSPACE_BYTES
    BNE copy_low_workspace
    RTS

; Original padding &4538-&454F
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00

low_workspace_image: ; original bytes at &4550-&457F copied to &03B0-&03DF
    EQUB &00, &00, &52, &41, &49, &44, &4F, &42, &4A, &00, &00, &00, &00, &00, &00, &0E    ; source &4550
    EQUB &00, &00, &00, &0E, &00, &00, &26, &00, &9D, &00, &80, &00, &00, &00, &00, &89    ; source &4560
    EQUB &7B, &19, &52, &41, &49, &44, &4F, &42, &4A, &00, &00, &00, &00, &00, &00, &80    ; source &4570
