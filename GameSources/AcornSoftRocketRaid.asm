; Rocket Raid (Acornsoft, 1982) - fully annotated reverse-engineering baseline (Stage 3)
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
; Confirmed gameplay constants:
STARTING_SPARES         = 2      ; MOD: total ships = this + current ship
EXTRA_LIFE_SCORE_HI     = &01    ; MOD: packed BCD 15,000 threshold
EXTRA_LIFE_SCORE_MID    = &50
BOMB_COOLDOWN_FRAMES    = 6      ; MOD
BULLET_COOLDOWN_FRAMES  = 1      ; MOD
PLAYER_Y_MIN            = &13    ; MOD
PLAYER_Y_MAX            = &DD    ; MOD
PLAYER_X_MIN            = &06    ; MOD
PLAYER_X_MAX            = &1E    ; MOD

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
; Object/player coordinates are held in parallel tables beginning at &2B78
; (X) and &2B8C (Y).  Slot 0 is the player's ship.  Slots above it are reused
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
;   &1907     create bomb; at most two bomb slots (&2B79-&2B7A).
;   &1938     create bullet; at most four bullet slots (&2B7B-&2B7E).
;   &1579     player/terrain/object collision controller [inferred].
;   &1627     compare sprite/collision bytes and resolve an object hit.
;   &1698     object-hit award/removal path.
;   &174D     player destroyed: explosion, palette flash, life decrement.
;
; SOUND
; -----
;   &21F0     six 14-byte ENVELOPE blocks installed by startup.
;   &2420     OSWORD 7 SOUND blocks, 8 bytes per effect.
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
; MODIFICATION NOTES
; ------------------
; Search for "MOD:" to find deliberately documented tweak points.  These are
; comments only; the baseline values remain the original Acornsoft values.
;
; Semantic address aliases (no emitted bytes)
oswrch             = &FFEE
osword             = &FFF1
osbyte             = &FFF4

game               = &0E00
checkhi_score      = &0502
inkey               = &1C21
adval               = &1BCD
play_sound          = &1BBC
set_palette         = &1C31
write_crtc_register = &1C40
wait_vsync          = &1C47
new_game_init       = &1162
next_stage_init     = &118B
new_life_init       = &11C9

soundflag           = &75
joyflag             = &6E
lives               = &3D
score_lo            = &3E
score_mid           = &3F
score_hi            = &40
stage_bcd           = &76
startup_flag        = &7B

; Additional Stage 3 semantic aliases [inferred unless noted]
current_section      = &4E
player_x             = &2B78
player_y             = &2B8C
object_x_table       = &2B78
object_y_table       = &2B8C
object_type_table    = &2B50
object_state_table   = &2B64
bomb_slot_table      = &2B79
bullet_slot_table    = &2B7B
landscape_mask       = &2320
sound_table          = &2420
envelope_table       = &21F0

; BBC key constants used by the game
KEY_Q                 = &EF
KEY_S                 = &AE
KEY_UP_A              = &BE
KEY_DOWN_Z            = &9E
KEY_FORWARD_SHIFT     = &FF
KEY_BACK_SPACE        = &9D
KEY_BOMB_TAB          = &9F
KEY_FIRE_RETURN       = &B6

; Confirmed sound effect IDs
SOUND_FIRE_BULLET     = 1
SOUND_DROP_BOMB       = 2
SOUND_PLAYER_DEATH    = 8

ladder              = &06D0
score_string_table  = &06EE
highscore_names     = &070C
tempsc              = &07D4

ORG &0E00
runtime_payload_start:
caller_stack_save_and_game_entry:

; -----------------------------------------------------------------------------
; CORE GAME ENTRY, FRAME LOOP, LANDSCAPE, RENDERER AND MASK BUILDER
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
    TSX                                ; &0E00
    STX &0E                            ; &0E01  saved_caller_sp
    JSR new_game_init                  ; &0E03
    JSR new_raid_init                  ; &0E06
    JSR new_life_init                  ; &0E09
    LDA &7B                            ; &0E0C
    STA &FE4E                          ; &0E0E
    JSR check_escape_restart           ; &0E11
    JSR read_keyboard_controls         ; &0E14
    JSR update_active_objects          ; &0E17
    JSR &1321                          ; &0E1A
    SEI                                ; &0E1D
    JSR wait_vsync                     ; &0E1E
    JSR &1266                          ; &0E21
    JSR &1063                          ; &0E24
    JSR &129B                          ; &0E27
    CLI                                ; &0E2A
    JSR &1579                          ; &0E2B
    JSR &0EA3                          ; &0E2E
    JMP &0E0C                          ; &0E31
    LDA &04                            ; &0E34
    STA &55                            ; &0E36
    LDA &06                            ; &0E38
    STA &57                            ; &0E3A
    LDA &08                            ; &0E3C
    STA &59                            ; &0E3E
    LDA &0A                            ; &0E40
    STA &5B                            ; &0E42
    LDA &32                            ; &0E44
    STA &5D                            ; &0E46
    LDA &05                            ; &0E48
    STA &56                            ; &0E4A
    LDA &07                            ; &0E4C
    STA &58                            ; &0E4E
    LDA &09                            ; &0E50
    STA &5A                            ; &0E52
    LDA &0B                            ; &0E54
    STA &5C                            ; &0E56
    LDY #&05                           ; &0E58
    LDA &002C,Y                        ; &0E5A
    STA &005E,Y                        ; &0E5D
    DEY                                ; &0E60
    BPL &0E5A                          ; &0E61
    LDY &4E                            ; &0E63  current_section
    LDA &2C0C,Y                        ; &0E65
    STA &4D                            ; &0E68
    LDA &2C12,Y                        ; &0E6A
    STA &28                            ; &0E6D
    TYA                                ; &0E6F
    PHA                                ; &0E70
    LDA &2C26,Y                        ; &0E71
    TAY                                ; &0E74
    LDA #&0E                           ; &0E75
    JSR &1C74                          ; &0E77
    CLC                                ; &0E7A
    ADC #&F0                           ; &0E7B
    TAX                                ; &0E7D
    LDY #&21                           ; &0E7E
    BCC &0E83                          ; &0E80
    INY                                ; &0E82
    LDA #&08                           ; &0E83
    JSR &FFF1                          ; &0E85
    PLA                                ; &0E88
    TAY                                ; &0E89
    LDA &2C20,Y                        ; &0E8A
    LDY #&04                           ; &0E8D
    JSR set_palette                    ; &0E8F
    LDA #&E0                           ; &0E92
    STA &2B                            ; &0E94
    STA &50                            ; &0E96
    STA &51                            ; &0E98
    LDA #&28                           ; &0E9A
    STA &2A                            ; &0E9C
    LDA #&00                           ; &0E9E
    STA &33                            ; &0EA0
    RTS                                ; &0EA2
    LDX &27                            ; &0EA3
    BNE &0EB5                          ; &0EA5
    LDA &4D                            ; &0EA7
    BNE &0EB0                          ; &0EA9
    INC &4E                            ; &0EAB  current_section
    JSR &0E34                          ; &0EAD
    DEC &4D                            ; &0EB0
    JSR &0F1B                          ; &0EB2
    LDX &28                            ; &0EB5
    BMI &0EC7                          ; &0EB7
    BNE &0EBE                          ; &0EB9
    JSR &0F69                          ; &0EBB
    LDX &28                            ; &0EBE
    LDY &2BC1,X                        ; &0EC0
    STY &50                            ; &0EC3
    DEC &28                            ; &0EC5
    JSR &1843                          ; &0EC7
    JSR advance_scroll_position        ; &0ECA
    LDA &0C                            ; &0ECD
    STA &1B                            ; &0ECF
    LDA &0D                            ; &0ED1
    LSR A                              ; &0ED3
    ROR &1B                            ; &0ED4
    LSR A                              ; &0ED6
    ROR &1B                            ; &0ED7
    LSR A                              ; &0ED9
    ROR &1B                            ; &0EDA
    LDX #&0C                           ; &0EDC
    JSR write_crtc_register            ; &0EDE
    LDX #&0D                           ; &0EE1
    LDA &1B                            ; &0EE3
    JSR write_crtc_register            ; &0EE5
    JSR &109D                          ; &0EE8
    LDA &33                            ; &0EEB
    BEQ &0EF5                          ; &0EED
    JSR &1560                          ; &0EEF
    JMP &0F0C                          ; &0EF2
    LDA &29                            ; &0EF5
    BNE &0F0C                          ; &0EF7
    LDX &32                            ; &0EF9
    LDY &2A00,X                        ; &0EFB
    LDA &2C62,Y                        ; &0EFE
    TAY                                ; &0F01
    LDA &27                            ; &0F02
    JSR wrap_delta                     ; &0F04
    BNE &0F0C                          ; &0F07
    JSR &1529                          ; &0F09
    LDX &27                            ; &0F0C
    LDY &2BA0,X                        ; &0F0E
    CPY &22                            ; &0F11
    BNE &0F16                          ; &0F13
    DEY                                ; &0F15
    STY &22                            ; &0F16
    DEC &27                            ; &0F18
    RTS                                ; &0F1A
    LDY #&00                           ; &0F1B
    LDA (&04),Y                        ; &0F1D
    STA &1C                            ; &0F1F
    BPL &0F29                          ; &0F21
    LDX &0E                            ; &0F23  saved_caller_sp
    TXS                                ; &0F25
    JMP &0E06                          ; &0F26
    AND #&1F                           ; &0F29
    STA &27                            ; &0F2B
    TAX                                ; &0F2D
    LDA (&06),Y                        ; &0F2E
    STA &29                            ; &0F30
    INC &04                            ; &0F32
    BNE &0F38                          ; &0F34
    INC &05                            ; &0F36
    INC &06                            ; &0F38
    BNE &0F3E                          ; &0F3A
    INC &07                            ; &0F3C
    LDA &2A                            ; &0F3E
    CLC                                ; &0F40
    ADC &29                            ; &0F41
    STA &1B                            ; &0F43
    LDY &29                            ; &0F45
    BEQ &0F5A                          ; &0F47
    JSR &1C60                          ; &0F49
    LSR A                              ; &0F4C
    BCS &0F55                          ; &0F4D
    AND #&03                           ; &0F4F
    EOR #&FF                           ; &0F51
    BMI &0F57                          ; &0F53
    AND #&03                           ; &0F55
    CLC                                ; &0F57
    ADC &1B                            ; &0F58
    STA &2BA0,X                        ; &0F5A
    STA &2A                            ; &0F5D
    DEX                                ; &0F5F
    BNE &0F3E                          ; &0F60
    ASL &1C                            ; &0F62
    BPL &0F68                          ; &0F64
    DEC &29                            ; &0F66
    RTS                                ; &0F68
    LDY #&00                           ; &0F69
    LDA (&08),Y                        ; &0F6B
    STA &1C                            ; &0F6D
    BPL &0F77                          ; &0F6F
    LDX &0E                            ; &0F71  saved_caller_sp
    TXS                                ; &0F73
    JMP &0E06                          ; &0F74
    AND #&1F                           ; &0F77
    STA &28                            ; &0F79
    TAX                                ; &0F7B
    LDA (&0A),Y                        ; &0F7C
    STA &70                            ; &0F7E
    INC &08                            ; &0F80
    BNE &0F86                          ; &0F82
    INC &09                            ; &0F84
    INC &0A                            ; &0F86
    BNE &0F8C                          ; &0F88
    INC &0B                            ; &0F8A
    LDA &2B                            ; &0F8C
    CLC                                ; &0F8E
    ADC &70                            ; &0F8F
    STA &1B                            ; &0F91
    LDY &70                            ; &0F93
    BEQ &0FA8                          ; &0F95
    JSR &1C60                          ; &0F97
    LSR A                              ; &0F9A
    BCS &0FA3                          ; &0F9B
    AND #&03                           ; &0F9D
    EOR #&FF                           ; &0F9F
    BMI &0FA5                          ; &0FA1
    AND #&03                           ; &0FA3
    CLC                                ; &0FA5
    ADC &1B                            ; &0FA6
    STA &2BC1,X                        ; &0FA8
    STA &2B                            ; &0FAB
    DEX                                ; &0FAD
    BNE &0F8C                          ; &0FAE
    ASL &1C                            ; &0FB0
    BPL &0FB6                          ; &0FB2
    DEC &70                            ; &0FB4
    RTS                                ; &0FB6
    LDA #&00                           ; &0FB7
    STA &03                            ; &0FB9
    CPX &1D                            ; &0FBB
    BCC &0FFF                          ; &0FBD
    TYA                                ; &0FBF
    EOR #&FF                           ; &0FC0
    PHA                                ; &0FC2
    LSR A                              ; &0FC3
    LSR A                              ; &0FC4
    LSR A                              ; &0FC5
    TAY                                ; &0FC6
    LSR A                              ; &0FC7
    STA &1B                            ; &0FC8
    LDA #&00                           ; &0FCA
    ROR A                              ; &0FCC
    ADC &0C                            ; &0FCD
    PHP                                ; &0FCF
    STA &02                            ; &0FD0
    TYA                                ; &0FD2
    ASL A                              ; &0FD3
    ADC &1B                            ; &0FD4
    PLP                                ; &0FD6
    ADC &0D                            ; &0FD7
    STA &03                            ; &0FD9
    LDA #&00                           ; &0FDB
    STA &1B                            ; &0FDD
    TXA                                ; &0FDF
    ASL A                              ; &0FE0
    ROL &1B                            ; &0FE1
    ASL A                              ; &0FE3
    ROL &1B                            ; &0FE4
    ASL A                              ; &0FE6
    ROL &1B                            ; &0FE7
    ADC &02                            ; &0FE9
    STA &02                            ; &0FEB
    LDA &1B                            ; &0FED
    ADC &03                            ; &0FEF
    BPL &0FF6                          ; &0FF1
    SEC                                ; &0FF3
    SBC #&50                           ; &0FF4
    STA &03                            ; &0FF6
    PLA                                ; &0FF8
    AND #&07                           ; &0FF9
    ORA &02                            ; &0FFB
    STA &02                            ; &0FFD
    RTS                                ; &0FFF
    LDA &03                            ; &1000
    BNE &1005                          ; &1002
    RTS                                ; &1004
    LDA &1F                            ; &1005
    STA &102A                          ; &1007
    LDA &20                            ; &100A
    STA &102B                          ; &100C
    LDA &1E                            ; &100F
    PHA                                ; &1011
    LDX #&00                           ; &1012
    LDA &03                            ; &1014
    PHA                                ; &1016
    LDA &02                            ; &1017
    PHA                                ; &1019
    LDA &21                            ; &101A
    STA &0F                            ; &101C
    LDA &02                            ; &101E
    AND #&07                           ; &1020
    TAY                                ; &1022
    LDA &02                            ; &1023
    AND #&F8                           ; &1025
    STA &02                            ; &1027
    LDA &FFFF,X                        ; &1029
    INX                                ; &102C
    EOR (&02),Y                        ; &102D
    STA (&02),Y                        ; &102F
    INY                                ; &1031
    CPY #&08                           ; &1032
    BEQ &1044                          ; &1034
    DEC &0F                            ; &1036
    BEQ &104B                          ; &1038
    DEC &1E                            ; &103A
    BNE &1029                          ; &103C
    PLA                                ; &103E
    PLA                                ; &103F
    PLA                                ; &1040
    STA &1E                            ; &1041
    RTS                                ; &1043
    LDY #&00                           ; &1044
    JSR &1725                          ; &1046
    BNE &1036                          ; &1049
    CLC                                ; &104B
    PLA                                ; &104C
    ADC #&08                           ; &104D
    STA &02                            ; &104F
    PLA                                ; &1051
    ADC #&00                           ; &1052
    BPL &1059                          ; &1054
    SEC                                ; &1056
    SBC #&50                           ; &1057
    STA &03                            ; &1059
    DEC &1E                            ; &105B
    BNE &1014                          ; &105D
    PLA                                ; &105F
    STA &1E                            ; &1060
    RTS                                ; &1062
    LDX #&FF                           ; &1063
    LDY #&00                           ; &1065
    LDA &0C                            ; &1067
    CLC                                ; &1069
    ADC #&78                           ; &106A
    STA &00                            ; &106C
    LDA &0D                            ; &106E
    ADC #&02                           ; &1070
    BPL &1077                          ; &1072
    SEC                                ; &1074
    SBC #&50                           ; &1075
    STA &01                            ; &1077
    LDA &2320,X                        ; &1079
    STA (&00),Y                        ; &107C
    DEX                                ; &107E
    INY                                ; &107F
    CPY #&08                           ; &1080
    BNE &1079                          ; &1082
    LDY #&00                           ; &1084
    LDA &00                            ; &1086
    CLC                                ; &1088
    ADC #&80                           ; &1089
    STA &00                            ; &108B
    LDA &01                            ; &108D
    ADC #&02                           ; &108F
    BPL &1096                          ; &1091
    SEC                                ; &1093
    SBC #&50                           ; &1094
    STA &01                            ; &1096
    CPX #&FF                           ; &1098
    BNE &1079                          ; &109A
    RTS                                ; &109C
    LDA &23                            ; &109D
    CMP &22                            ; &109F
    BCC &10B0                          ; &10A1
    STA &24                            ; &10A3
    LDA #&00                           ; &10A5
    STA &26                            ; &10A7
    LDA &22                            ; &10A9
    STA &25                            ; &10AB
    JMP &10BC                          ; &10AD
    LDA #&FF                           ; &10B0
    STA &26                            ; &10B2
    LDA &22                            ; &10B4
    STA &24                            ; &10B6
    LDA &23                            ; &10B8
    STA &25                            ; &10BA
    LDA &51                            ; &10BC
    CMP &50                            ; &10BE
    BCC &10CF                          ; &10C0
    STA &53                            ; &10C2
    LDA #&FF                           ; &10C4
    STA &4F                            ; &10C6
    LDA &50                            ; &10C8
    STA &52                            ; &10CA
    JMP &10DB                          ; &10CC
    LDA #&00                           ; &10CF
    STA &4F                            ; &10D1
    LDA &50                            ; &10D3
    STA &53                            ; &10D5
    LDA &51                            ; &10D7
    STA &52                            ; &10D9
    LDX #&00                           ; &10DB
    LDA &28                            ; &10DD
    BPL &10E4                          ; &10DF
    JMP &1123                          ; &10E1
    LDA &53                            ; &10E4
    CMP #&E1                           ; &10E6
    BCC &10ED                          ; &10E8
    JMP &1123                          ; &10EA
    LDA #&00                           ; &10ED
    STA &2320,X                        ; &10EF
    CPX #&E0                           ; &10F2
    BEQ &10FA                          ; &10F4
    DEX                                ; &10F6
    JMP &10EF                          ; &10F7
    LDA #&30                           ; &10FA
    STA &2320,X                        ; &10FC
    CPX &53                            ; &10FF
    BEQ &1107                          ; &1101
    DEX                                ; &1103
    JMP &10FC                          ; &1104
    LDA #&0C                           ; &1107
    STA &2320,X                        ; &1109
    DEX                                ; &110C
    LDA &4F                            ; &110D
    BNE &1116                          ; &110F
    LDA #&08                           ; &1111
    JMP &1118                          ; &1113
    LDA #&04                           ; &1116
    STA &2320,X                        ; &1118
    CPX &52                            ; &111B
    BCC &1123                          ; &111D
    DEX                                ; &111F
    JMP &1118                          ; &1120
    LDA #&00                           ; &1123
    STA &2320,X                        ; &1125
    CPX &24                            ; &1128
    BEQ &1130                          ; &112A
    DEX                                ; &112C
    JMP &1125                          ; &112D
    LDA &26                            ; &1130
    BNE &1139                          ; &1132
    LDA #&08                           ; &1134
    JMP &113B                          ; &1136
    LDA #&04                           ; &1139
    STA &2320,X                        ; &113B
    CPX &25                            ; &113E
    BEQ &1146                          ; &1140
    DEX                                ; &1142
    JMP &113B                          ; &1143
    LDA #&0C                           ; &1146
    STA &2320,X                        ; &1148
    DEX                                ; &114B
    LDA #&30                           ; &114C
    STA &2320,X                        ; &114E
    CPX #&00                           ; &1151
    BEQ &1159                          ; &1153
    DEX                                ; &1155
    JMP &114E                          ; &1156
    LDA &22                            ; &1159
    STA &23                            ; &115B
    LDA &50                            ; &115D
    STA &51                            ; &115F
    RTS                                ; &1161

; -----------------------------------------------------------------------------
; NEW GAME / RAID / LIFE INITIALISATION
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
new_game_init:
    LDA #&16                           ; &1162
    JSR &FFEE                          ; &1164
    LDA #&02                           ; &1167
    JSR &FFEE                          ; &1169
    LDA #&20                           ; &116C
    LDX #&0A                           ; &116E
    JSR write_crtc_register            ; &1170
    LDX #&08                           ; &1173
    LDA #&00                           ; &1175
    JSR write_crtc_register            ; &1177
    LDA #&02                           ; &117A
    STA &3D                            ; &117C  lives
    LDA #&00                           ; &117E
    STA &3E                            ; &1180  score_lo
    STA &3F                            ; &1182  score_mid
    STA &40                            ; &1184  score_hi
    STA &76                            ; &1186  stage_bcd
    STA &79                            ; &1188  bonus_life_awarded
    RTS                                ; &118A
new_raid_init:
    LDA #&57                           ; &118B
    LDY #&05                           ; &118D
    STA &002C,Y                        ; &118F
    DEY                                ; &1192
    BPL &118F                          ; &1193
    LDA #&26                           ; &1195
    STA &05                            ; &1197
    LDA #&00                           ; &1199
    STA &04                            ; &119B
    LDA #&28                           ; &119D
    STA &07                            ; &119F
    LDA #&00                           ; &11A1
    STA &06                            ; &11A3
    LDA #&24                           ; &11A5
    STA &09                            ; &11A7
    LDA #&C0                           ; &11A9
    STA &08                            ; &11AB
    LDA #&25                           ; &11AD
    STA &0B                            ; &11AF
    LDA #&60                           ; &11B1
    STA &0A                            ; &11B3
    SED                                ; &11B5
    CLC                                ; &11B6
    LDA &76                            ; &11B7  stage_bcd
    ADC #&01                           ; &11B9
    STA &76                            ; &11BB  stage_bcd
    CLD                                ; &11BD
    LDA #&00                           ; &11BE
    STA &32                            ; &11C0
    STA &4E                            ; &11C2  current_section
    STA &6F                            ; &11C4
    JMP &0E34                          ; &11C6
new_life_init:
    JSR read_system_clock              ; &11C9
    LDA #&02                           ; &11CC
    STA &48                            ; &11CE
    LDA #&40                           ; &11D0
    STA &47                            ; &11D2
    LDA #&03                           ; &11D4
    STA &49                            ; &11D6
    JSR player_screen_setup            ; &11D8
    LDY #&0F                           ; &11DB
    LDA &2BE2,Y                        ; &11DD
    JSR set_palette                    ; &11E0
    DEY                                ; &11E3
    BPL &11DD                          ; &11E4
    LDA #&00                           ; &11E6
    STA &4A                            ; &11E8
    STA &64                            ; &11EA
    STA &65                            ; &11EC
    STA &3A                            ; &11EE
    STA &41                            ; &11F0
    STA &7A                            ; &11F2
    LDY #&13                           ; &11F4
    STA &2B00,Y                        ; &11F6
    STA &2B14,Y                        ; &11F9
    STA &2B28,Y                        ; &11FC
    STA &2B3C,Y                        ; &11FF
    STA &2B8C,Y                        ; &1202  object_y_table
    STA &2B78,Y                        ; &1205  object_x_table
    DEY                                ; &1208
    BPL &11F6                          ; &1209
    STA &3B                            ; &120B
    STA &3C                            ; &120D
    STA &27                            ; &120F
    STA &77                            ; &1211
    STA &78                            ; &1213
    LDA &55                            ; &1215
    STA &04                            ; &1217
    LDA &57                            ; &1219
    STA &06                            ; &121B
    LDA &59                            ; &121D
    STA &08                            ; &121F
    LDA &5B                            ; &1221
    STA &0A                            ; &1223
    LDA &5D                            ; &1225
    STA &32                            ; &1227
    LDA &56                            ; &1229
    STA &05                            ; &122B
    LDA &58                            ; &122D
    STA &07                            ; &122F
    LDA &5A                            ; &1231
    STA &09                            ; &1233
    LDA &5C                            ; &1235
    STA &0B                            ; &1237
    LDY #&09                           ; &1239
    LDA #&80                           ; &123B
    STA &2B64,Y                        ; &123D  object_state_table
    DEY                                ; &1240
    BPL &123D                          ; &1241
    LDA #&14                           ; &1243
    STA &54                            ; &1245
    LDA #&01                           ; &1247
    STA &1D                            ; &1249
    LDY #&05                           ; &124B
    LDA &005E,Y                        ; &124D
    STA &002C,Y                        ; &1250
    DEY                                ; &1253
    BPL &124D                          ; &1254
    LDA #&06                           ; &1256
    STA &2B78                          ; &1258  object_x_table
    LDA #&BB                           ; &125B
    STA &2B8C                          ; &125D  object_y_table
    JSR &109D                          ; &1260
    JMP &0E63                          ; &1263

; -----------------------------------------------------------------------------
; OBJECT ERASE/REDRAW, SLOT PROCESSING AND JOYSTICK CONTROL
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
    LDA &0D                            ; &1266
    CLC                                ; &1268
    ADC #&05                           ; &1269
    STA &01                            ; &126B
    LDA &0C                            ; &126D
    STA &00                            ; &126F
    LDY #&07                           ; &1271
    LDA #&00                           ; &1273
    STA (&00),Y                        ; &1275
    DEY                                ; &1277
    BPL &1275                          ; &1278
    LDY #&00                           ; &127A
    LDA &2B14                          ; &127C
    BEQ &128B                          ; &127F
    STA &03                            ; &1281
    LDA &2B00                          ; &1283
    STA &02                            ; &1286
    JSR erase_object_by_type           ; &1288
    LDA &2B3C                          ; &128B
    BEQ &129A                          ; &128E
    STA &03                            ; &1290
    LDA &2B28                          ; &1292
    STA &02                            ; &1295
    JMP erase_object_by_type           ; &1297
    RTS                                ; &129A
    LDY #&01                           ; &129B
    LDA &2B64,Y                        ; &129D  object_state_table
    ASL A                              ; &12A0
    BMI &12C4                          ; &12A1
    ASL A                              ; &12A3
    BMI &12C4                          ; &12A4
    LDA &2B14,Y                        ; &12A6
    BEQ &12B5                          ; &12A9
    STA &03                            ; &12AB
    LDA &2B00,Y                        ; &12AD
    STA &02                            ; &12B0
    JSR erase_object_by_type           ; &12B2
    LDA &2B3C,Y                        ; &12B5
    BEQ &12C4                          ; &12B8
    STA &03                            ; &12BA
    LDA &2B28,Y                        ; &12BC
    STA &02                            ; &12BF
    JSR erase_object_by_type           ; &12C1
    INY                                ; &12C4
    CPY #&09                           ; &12C5
    BNE &129D                          ; &12C7
    LDA &2B64,Y                        ; &12C9  object_state_table
    BPL &12E0                          ; &12CC
    ASL A                              ; &12CE
    BMI &12E0                          ; &12CF
    LDA &2B3C,Y                        ; &12D1
    BEQ &12E0                          ; &12D4
    STA &03                            ; &12D6
    LDA &2B28,Y                        ; &12D8
    STA &02                            ; &12DB
    JSR erase_object_by_type           ; &12DD
    INY                                ; &12E0
    CPY #&13                           ; &12E1
    BNE &12C9                          ; &12E3
    LDX #&03                           ; &12E5
    LDY #&00                           ; &12E7
    LDA &2B17,X                        ; &12E9
    BEQ &1302                          ; &12EC
    STA &03                            ; &12EE
    LDA &2B03,X                        ; &12F0
    STA &02                            ; &12F3
    LDA #&0F                           ; &12F5
    EOR (&02),Y                        ; &12F7
    STA (&02),Y                        ; &12F9
    INY                                ; &12FB
    LDA #&0F                           ; &12FC
    EOR (&02),Y                        ; &12FE
    STA (&02),Y                        ; &1300
    LDY #&00                           ; &1302
    LDA &2B3F,X                        ; &1304
    BEQ &131D                          ; &1307
    STA &03                            ; &1309
    LDA &2B2B,X                        ; &130B
    STA &02                            ; &130E
    LDA #&0F                           ; &1310
    EOR (&02),Y                        ; &1312
    STA (&02),Y                        ; &1314
    INY                                ; &1316
    LDA #&0F                           ; &1317
    EOR (&02),Y                        ; &1319
    STA (&02),Y                        ; &131B
    DEX                                ; &131D
    BPL &12E7                          ; &131E
    RTS                                ; &1320
    LDA &79                            ; &1321  bonus_life_awarded
    BPL &1330                          ; &1323
    JSR &1D02                          ; &1325
    LDA &73                            ; &1328
    BNE &1330                          ; &132A
    LDA #&7F                           ; &132C
    STA &79                            ; &132E  bonus_life_awarded
    LDY #&09                           ; &1330
    LDA &2B28,Y                        ; &1332
    STA &2B00,Y                        ; &1335
    LDA &2B3C,Y                        ; &1338
    STA &2B14,Y                        ; &133B
    DEY                                ; &133E
    BPL &1332                          ; &133F
    LDY #&13                           ; &1341
    STY &16                            ; &1343
    LDA &2B64,Y                        ; &1345  object_state_table
    BPL &1364                          ; &1348
    ASL A                              ; &134A
    BMI &1364                          ; &134B
    LDA &2B78,Y                        ; &134D  object_x_table
    TAX                                ; &1350
    LDA &2B8C,Y                        ; &1351  object_y_table
    TAY                                ; &1354
    JSR &0FB7                          ; &1355
    LDY &16                            ; &1358
    LDA &02                            ; &135A
    STA &2B28,Y                        ; &135C
    LDA &03                            ; &135F
    STA &2B3C,Y                        ; &1361
    DEY                                ; &1364
    BPL &1343                          ; &1365
    DEC &49                            ; &1367
    BNE &1381                          ; &1369
    LDA #&03                           ; &136B
    STA &49                            ; &136D
    LDA &47                            ; &136F
    BNE &1375                          ; &1371
    DEC &48                            ; &1373
    DEC &47                            ; &1375
    BNE &1381                          ; &1377
    LDA &48                            ; &1379
    BNE &1381                          ; &137B
    LDA #&FF                           ; &137D
    STA &7A                            ; &137F
    JMP spawn_section_hazards          ; &1381
read_joystick_controls:
    LDX #&02                           ; &1384
    JSR adval                          ; &1386
    CPY #&32                           ; &1389
    BCS &1390                          ; &138B
    JSR move_player_down               ; &138D
    CPY #&CE                           ; &1390
    BCC &1397                          ; &1392
    JSR move_player_up                 ; &1394
    LDX #&01                           ; &1397
    JSR adval                          ; &1399
    CPY #&32                           ; &139C
    BCS &13A3                          ; &139E
    JSR move_player_forward            ; &13A0
    CPY #&CE                           ; &13A3
    BCC &13AA                          ; &13A5
    JSR move_player_back               ; &13A7
    LDX #&00                           ; &13AA
    JSR adval                          ; &13AC
    TXA                                ; &13AF
    AND #&01                           ; &13B0
    TAX                                ; &13B2
    PHP                                ; &13B3
    LDA &6F                            ; &13B4
    STX &6F                            ; &13B6
    PLP                                ; &13B8
    BEQ &13C5                          ; &13B9
    EOR &6F                            ; &13BB
    BEQ &13C5                          ; &13BD
    JSR fire_bullet                    ; &13BF
    JSR drop_bomb                      ; &13C2
    LDX #&FF                           ; &13C5
    JMP &1407                          ; &13C7

; -----------------------------------------------------------------------------
; KEYBOARD CONTROL AND PLAYER MOVEMENT
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
read_keyboard_controls:
    LDA &7A                            ; &13CA
    BEQ &13D1                          ; &13CC
    JMP move_player_down               ; &13CE
    LDA &6E                            ; &13D1  joyflag
    BNE read_joystick_controls         ; &13D3
    LDX #&BE                           ; &13D5
    JSR inkey                          ; &13D7
    BEQ &13DF                          ; &13DA
    JSR move_player_up                 ; &13DC
    LDX #&9E                           ; &13DF
    JSR inkey                          ; &13E1
    BEQ &13E9                          ; &13E4
    JSR move_player_down               ; &13E6
    LDX #&FF                           ; &13E9
    JSR inkey                          ; &13EB
    BEQ &13F3                          ; &13EE
    JSR move_player_forward            ; &13F0
    LDX #&9D                           ; &13F3
    JSR inkey                          ; &13F5
    BEQ &13FD                          ; &13F8
    JSR move_player_back               ; &13FA
    LDA &3A                            ; &13FD
    BEQ &1405                          ; &13FF
    DEC &3A                            ; &1401
    BNE &1419                          ; &1403
    LDX #&9F                           ; &1405
    JSR inkey                          ; &1407
    PHP                                ; &140A
    LDA &42                            ; &140B
    STX &42                            ; &140D
    PLP                                ; &140F
    BEQ &1419                          ; &1410
    EOR &42                            ; &1412
    BEQ &1419                          ; &1414
    JSR drop_bomb                      ; &1416
    LDA &41                            ; &1419
    BEQ &1421                          ; &141B
    DEC &41                            ; &141D
    BNE &1435                          ; &141F
    LDX #&B6                           ; &1421
    JSR inkey                          ; &1423
    PHP                                ; &1426
    LDA &43                            ; &1427
    STX &43                            ; &1429
    PLP                                ; &142B
    BEQ &1435                          ; &142C
    EOR &43                            ; &142E
    BEQ &1435                          ; &1430
    JSR fire_bullet                    ; &1432
    RTS                                ; &1435
move_player_up:
    INC &2B8C                          ; &1436  object_y_table
    INC &2B8C                          ; &1439  object_y_table
    LDX #&DD                           ; &143C
    CPX &2B8C                          ; &143E  object_y_table
    BCS &1446                          ; &1441
    STX &2B8C                          ; &1443  object_y_table
    RTS                                ; &1446
move_player_down:
    DEC &2B8C                          ; &1447  object_y_table
    DEC &2B8C                          ; &144A  object_y_table
    LDX #&13                           ; &144D
    CPX &2B8C                          ; &144F  object_y_table
    BCC &1457                          ; &1452
    STX &2B8C                          ; &1454  object_y_table
    RTS                                ; &1457
move_player_back:
    DEC &2B78                          ; &1458  object_x_table
    LDX #&06                           ; &145B
    CPX &2B78                          ; &145D  object_x_table
    BCC &1465                          ; &1460
    STX &2B78                          ; &1462  object_x_table
    RTS                                ; &1465
move_player_forward:
    INC &2B78                          ; &1466  object_x_table
    LDX #&1E                           ; &1469
    CPX &2B78                          ; &146B  object_x_table
    BCS &1473                          ; &146E
    STX &2B78                          ; &1470  object_x_table
    RTS                                ; &1473
    LDX #&A6                           ; &1474
    JSR inkey                          ; &1476
    BEQ &148A                          ; &1479
    LDA #&0F                           ; &147B
    LDX #&01                           ; &147D
    JSR &FFF4                          ; &147F
    LDA #&FF                           ; &1482
    STA &FE4E                          ; &1484
    JSR &FFE0                          ; &1487
    RTS                                ; &148A

; -----------------------------------------------------------------------------
; PLAYER SETUP, COLLISION ENGINE AND OBJECT HIT PROCESSING
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
player_screen_setup:
    JSR &1BB1                          ; &148B
    LDA #&2D                           ; &148E
    STA &0D                            ; &1490
    LDA #&80                           ; &1492
    STA &0C                            ; &1494
    LDA #&28                           ; &1496
    STA &2A                            ; &1498
    STA &22                            ; &149A
    STA &23                            ; &149C
    LDA #&FF                           ; &149E
    STA &28                            ; &14A0
    JSR advance_scroll_position        ; &14A2
    LDA &22                            ; &14A5
    EOR #&01                           ; &14A7
    STA &22                            ; &14A9
    JSR &109D                          ; &14AB
    JSR &1063                          ; &14AE
    JSR &18A7                          ; &14B1
    LDA &0D                            ; &14B4
    CMP #&30                           ; &14B6
    BNE &14A2                          ; &14B8
    LDA &0C                            ; &14BA
    STA &1B                            ; &14BC
    LDA &0D                            ; &14BE
    LSR A                              ; &14C0
    ROR &1B                            ; &14C1
    LSR A                              ; &14C3
    ROR &1B                            ; &14C4
    LSR A                              ; &14C6
    ROR &1B                            ; &14C7
    LDX #&0C                           ; &14C9
    JSR write_crtc_register            ; &14CB
    LDX #&0D                           ; &14CE
    LDA &1B                            ; &14D0
    JSR write_crtc_register            ; &14D2
    JSR &14E1                          ; &14D5
    JSR &1832                          ; &14D8
    JSR update_score_and_bonus_life    ; &14DB
    JMP wait_vsync                     ; &14DE
    LDX #&50                           ; &14E1
    LDA #&00                           ; &14E3
    STA &22D0,X                        ; &14E5
    DEX                                ; &14E8
    BPL &14E5                          ; &14E9
    LDA &3D                            ; &14EB  lives
    BEQ &1528                          ; &14ED
    CMP #&02                           ; &14EF
    BCC &14F5                          ; &14F1
    LDA #&02                           ; &14F3
    STA &1C                            ; &14F5
    BEQ &1528                          ; &14F7
    LDA #&D8                           ; &14F9
    STA &02                            ; &14FB
    LDA #&22                           ; &14FD
    STA &03                            ; &14FF
    LDA &2C60                          ; &1501
    STA &1F                            ; &1504
    LDA &2C53                          ; &1506
    STA &20                            ; &1509
    LDY #&00                           ; &150B
    LDX &2C46                          ; &150D
    LDA (&1F),Y                        ; &1510
    STA (&02),Y                        ; &1512
    INY                                ; &1514
    DEX                                ; &1515
    BNE &1510                          ; &1516
    TYA                                ; &1518
    CLC                                ; &1519
    ADC &02                            ; &151A
    ADC #&08                           ; &151C
    STA &02                            ; &151E
    BCC &1524                          ; &1520
    INC &03                            ; &1522
    DEC &1C                            ; &1524
    BNE &150B                          ; &1526
    RTS                                ; &1528
    LDY &32                            ; &1529
    INC &32                            ; &152B
    LDA &2A00,Y                        ; &152D
    PHA                                ; &1530
    TAY                                ; &1531
    LDX #&4F                           ; &1532
    LDA &2BA1                          ; &1534
    CLC                                ; &1537
    ADC &2C2E,Y                        ; &1538
    TAY                                ; &153B
    DEY                                ; &153C
    STY &72                            ; &153D
    PLA                                ; &153F
    PHA                                ; &1540
    JSR allocate_object_slot           ; &1541
    PLA                                ; &1544
    TAY                                ; &1545
    LDA &2C55,Y                        ; &1546
    STA &1569                          ; &1549
    LDA &2C48,Y                        ; &154C
    STA &156A                          ; &154F
    LDA &2C3B,Y                        ; &1552
    STA &33                            ; &1555
    LDA &2C2E,Y                        ; &1557
    STA &34                            ; &155A
    LDX #&00                           ; &155C
    STX &35                            ; &155E
    LDX &35                            ; &1560
    LDA &34                            ; &1562
    STA &0F                            ; &1564
    LDY &72                            ; &1566
    LDA &FFFF,X                        ; &1568
    INX                                ; &156B
    STA &2320,Y                        ; &156C
    DEY                                ; &156F
    DEC &33                            ; &1570
    DEC &0F                            ; &1572
    BNE &1568                          ; &1574
    STX &35                            ; &1576
    RTS                                ; &1578
    LDA &2B14                          ; &1579
    BNE &157F                          ; &157C
    RTS                                ; &157E
    LDA &2C55                          ; &157F
    STA &14                            ; &1582
    LDA &2C48                          ; &1584
    STA &15                            ; &1587
    LDA &2B28                          ; &1589
    STA &02                            ; &158C
    LDA &2B3C                          ; &158E
    STA &03                            ; &1591
    LDY #&00                           ; &1593
    STY &36                            ; &1595
    JSR &1738                          ; &1597
    LDY &2C2E                          ; &159A
    DEY                                ; &159D
    STY &36                            ; &159E
    LDX &2B78                          ; &15A0  object_x_table
    LDA &2B8C                          ; &15A3  object_y_table
    SEC                                ; &15A6
    SBC &36                            ; &15A7
    TAY                                ; &15A9
    JSR &0FB7                          ; &15AA
    JSR &1738                          ; &15AD
    LDA &2C2E                          ; &15B0
    LSR A                              ; &15B3
    STA &36                            ; &15B4
    LDX &2B78                          ; &15B6  object_x_table
    LDA &2B8C                          ; &15B9  object_y_table
    SEC                                ; &15BC
    SBC &36                            ; &15BD
    TAY                                ; &15BF
    JSR &0FB7                          ; &15C0
    JSR &1738                          ; &15C3
    LDA &2C5F                          ; &15C6
    STA &14                            ; &15C9
    LDA &2C52                          ; &15CB
    STA &15                            ; &15CE
    LDX #&01                           ; &15D0
    STX &4C                            ; &15D2
    LDA &2B3D,X                        ; &15D4
    BEQ &15F0                          ; &15D7
    STA &03                            ; &15D9
    LDA &2B29,X                        ; &15DB
    PHA                                ; &15DE
    AND #&07                           ; &15DF
    STA &37                            ; &15E1
    PLA                                ; &15E3
    AND #&F8                           ; &15E4
    STA &02                            ; &15E6
    LDA &2C38                          ; &15E8
    STA &1B                            ; &15EB
    JSR &1627                          ; &15ED
    DEC &4C                            ; &15F0
    LDX &4C                            ; &15F2
    BPL &15D4                          ; &15F4
    LDA &2C5E                          ; &15F6
    STA &14                            ; &15F9
    LDA &2C51                          ; &15FB
    STA &15                            ; &15FE
    LDX #&03                           ; &1600
    STX &4C                            ; &1602
    LDA &2B3F,X                        ; &1604
    BEQ &1620                          ; &1607
    STA &03                            ; &1609
    LDA &2B2B,X                        ; &160B
    PHA                                ; &160E
    AND #&07                           ; &160F
    STA &37                            ; &1611
    PLA                                ; &1613
    AND #&F8                           ; &1614
    STA &02                            ; &1616
    LDA &2C37                          ; &1618
    STA &1B                            ; &161B
    JSR &1627                          ; &161D
    DEC &4C                            ; &1620
    LDX &4C                            ; &1622
    BPL &1604                          ; &1624
    RTS                                ; &1626
    LDY #&00                           ; &1627
    STY &36                            ; &1629
    LDY &37                            ; &162B
    LDA (&02),Y                        ; &162D
    LDY &36                            ; &162F
    EOR (&14),Y                        ; &1631
    STA &45                            ; &1633
    BNE &1643                          ; &1635
    JSR &1716                          ; &1637
    INC &36                            ; &163A
    LDY &36                            ; &163C
    CPY &1B                            ; &163E
    BNE &162B                          ; &1640
    RTS                                ; &1642
    LDA &1B                            ; &1643
    CMP &2C38                          ; &1645
    BNE &165B                          ; &1648
    LDA &2B8D,X                        ; &164A
    STA &71                            ; &164D
    LDA &2B79,X                        ; &164F
    STA &46                            ; &1652
    LDA #&00                           ; &1654
    STA &2B79,X                        ; &1656
    BEQ &166A                          ; &1659
    LDA &2B8F,X                        ; &165B
    STA &71                            ; &165E
    LDA &2B7B,X                        ; &1660
    STA &46                            ; &1663
    LDA #&00                           ; &1665
    STA &2B7B,X                        ; &1667
    LDA &45                            ; &166A
    AND #&C0                           ; &166C
    BEQ &1693                          ; &166E
    LDX #&13                           ; &1670
    LDA &2B78,X                        ; &1672  object_x_table
    BEQ &168E                          ; &1675
    LDA &46                            ; &1677
    SEC                                ; &1679
    SBC &2B78,X                        ; &167A  object_x_table
    CMP #&10                           ; &167D
    BCS &168E                          ; &167F
    LDA &2B8C,X                        ; &1681  object_y_table
    SEC                                ; &1684
    SBC &71                            ; &1685
    JSR abs_a                          ; &1687
    CMP #&18                           ; &168A
    BCC &1698                          ; &168C
    DEX                                ; &168E
    CPX #&06                           ; &168F
    BNE &1672                          ; &1691
    LDA #&07                           ; &1693
    JMP play_sound_effect              ; &1695
    JSR &1BD4                          ; &1698
    LDA &2B50,X                        ; &169B  object_type_table
    PHA                                ; &169E
    CMP #&02                           ; &169F
    BNE &16E9                          ; &16A1
    LDA &47                            ; &16A3
    AND #&F8                           ; &16A5
    STA &47                            ; &16A7
    LDX #&08                           ; &16A9
    LDA &48                            ; &16AB
    CMP #&02                           ; &16AD
    BNE &16B7                          ; &16AF
    LDA &47                            ; &16B1
    CMP #&40                           ; &16B3
    BEQ &16FE                          ; &16B5
    LDA &47                            ; &16B7
    AND #&F8                           ; &16B9
    CLC                                ; &16BB
    ADC &0C                            ; &16BC
    STA &14                            ; &16BE
    LDA &0D                            ; &16C0
    ADC #&05                           ; &16C2
    ADC &48                            ; &16C4
    BPL &16CB                          ; &16C6
    SEC                                ; &16C8
    SBC #&50                           ; &16C9
    STA &15                            ; &16CB
    LDY #&06                           ; &16CD
    LDA #&2D                           ; &16CF
    STA (&14),Y                        ; &16D1
    DEY                                ; &16D3
    BNE &16D1                          ; &16D4
    CLC                                ; &16D6
    LDA &47                            ; &16D7
    ADC #&08                           ; &16D9
    STA &47                            ; &16DB
    LDA &48                            ; &16DD
    ADC #&00                           ; &16DF
    STA &48                            ; &16E1
    DEX                                ; &16E3
    BNE &16AB                          ; &16E4
    JMP &16FE                          ; &16E6
    CMP #&05                           ; &16E9
    BNE &16FE                          ; &16EB
    PLA                                ; &16ED
    JSR multiply_a_by_y                ; &16EE
    AND #&03                           ; &16F1
    TAY                                ; &16F3
    LDA &2C1C,Y                        ; &16F4
    TAX                                ; &16F7
    LDA &2C18,Y                        ; &16F8
    JMP &170E                          ; &16FB
    CMP #&03                           ; &16FE
    BNE &1705                          ; &1700
    JMP raid_complete                  ; &1702
    PLA                                ; &1705
    TAY                                ; &1706
    LDA &2BFF,Y                        ; &1707
    TAX                                ; &170A
    LDA &2BF2,Y                        ; &170B
    JSR add_score_bcd                  ; &170E
    LDA #&06                           ; &1711
    JMP play_sound_effect              ; &1713
    LDA &37                            ; &1716
    AND #&07                           ; &1718
    CMP #&07                           ; &171A
    BEQ &1721                          ; &171C
    INC &37                            ; &171E
    RTS                                ; &1720
    LDA #&00                           ; &1721
    STA &37                            ; &1723
    LDA &02                            ; &1725
    CLC                                ; &1727
    ADC #&80                           ; &1728
    STA &02                            ; &172A
    LDA &03                            ; &172C
    ADC #&02                           ; &172E
    BPL &1735                          ; &1730
    SEC                                ; &1732
    SBC #&50                           ; &1733
    STA &03                            ; &1735
    RTS                                ; &1737
    LDY &36                            ; &1738
    LDA (&14),Y                        ; &173A
    LDY #&00                           ; &173C
    CMP (&02),Y                        ; &173E
    BNE player_destroyed               ; &1740
    JSR &1797                          ; &1742
    LDY &36                            ; &1745
    CPY &2C3B                          ; &1747
    BCC &1738                          ; &174A
    RTS                                ; &174C

; -----------------------------------------------------------------------------
; PLAYER DEATH, BCD SCORING, EXTRA LIFE AND SCORE DISPLAY
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
player_destroyed:
    LDA &2B28                          ; &174D
    STA &02                            ; &1750
    LDA &2B3C                          ; &1752
    STA &03                            ; &1755
    LDA #&00                           ; &1757
    JSR draw_object_by_type            ; &1759
    LDX &2B78                          ; &175C  object_x_table
    DEX                                ; &175F
    LDY &2B8C                          ; &1760  object_y_table
    INY                                ; &1763
    INY                                ; &1764
    JSR &0FB7                          ; &1765
    LDA #&08                           ; &1768
    JSR draw_object_by_type            ; &176A
    JSR read_system_clock              ; &176D
    LDA #&08                           ; &1770
    JSR play_sound_effect              ; &1772
    LDX #&32                           ; &1775
    SEI                                ; &1777
    JSR wait_vsync                     ; &1778
    CLI                                ; &177B
    LDY #&0F                           ; &177C
    JSR &1C4F                          ; &177E
    AND #&07                           ; &1781
    JSR set_palette                    ; &1783
    DEY                                ; &1786
    BNE &177E                          ; &1787
    DEX                                ; &1789
    BPL &1777                          ; &178A
finish_player_death:
    LDX &0E                            ; &178C  saved_caller_sp
    TXS                                ; &178E
    DEC &3D                            ; &178F  lives
    BMI game_over_return               ; &1791
    JMP &0E09                          ; &1793
game_over_return:
    RTS                                ; &1796
    LDA &36                            ; &1797
    CLC                                ; &1799
    ADC &2C2E                          ; &179A
    STA &36                            ; &179D
    LDA &02                            ; &179F
    CLC                                ; &17A1
    ADC #&08                           ; &17A2
    STA &02                            ; &17A4
    BCC &17B0                          ; &17A6
    INC &03                            ; &17A8
    BPL &17B0                          ; &17AA
    LDA #&30                           ; &17AC
    STA &03                            ; &17AE
    RTS                                ; &17B0
add_score_bcd:
    SED                                ; &17B1
    CLC                                ; &17B2
    ADC &3E                            ; &17B3  score_lo
    STA &3E                            ; &17B5  score_lo
    TXA                                ; &17B7
    ADC &3F                            ; &17B8  score_mid
    STA &3F                            ; &17BA  score_mid
    LDA &40                            ; &17BC  score_hi
    ADC #&00                           ; &17BE
    STA &40                            ; &17C0  score_hi
    CLD                                ; &17C2
update_score_and_bonus_life:
    LDA &79                            ; &17C3  bonus_life_awarded
    BNE &17DF                          ; &17C5
    LDA &40                            ; &17C7  score_hi
    CMP #&01                           ; &17C9
    BCC &17DF                          ; &17CB
    LDA &3F                            ; &17CD  score_mid
    CMP #&50                           ; &17CF
    BCC &17DF                          ; &17D1
    INC &3D                            ; &17D3  lives
    JSR &14E1                          ; &17D5
    LDA #&FF                           ; &17D8
    STA &79                            ; &17DA  bonus_life_awarded
    JSR start_warning_beeper           ; &17DC
    LDA #&50                           ; &17DF
    STA &17                            ; &17E1
    LDA #&22                           ; &17E3
    STA &18                            ; &17E5
    LDA #&FF                           ; &17E7
    STA &44                            ; &17E9
    LDA &40                            ; &17EB  score_hi
    JSR print_bcd_byte                 ; &17ED
    LDA &3F                            ; &17F0  score_mid
    JSR print_bcd_byte                 ; &17F2
    LDA #&00                           ; &17F5
    STA &44                            ; &17F7
    LDA &3E                            ; &17F9  score_lo
print_bcd_byte:
    PHA                                ; &17FB
    AND #&F0                           ; &17FC
    JSR print_score_digit              ; &17FE
    PLA                                ; &1801
    ASL A                              ; &1802
    ASL A                              ; &1803
    ASL A                              ; &1804
    ASL A                              ; &1805
print_score_digit:
    BNE &180C                          ; &1806
    LDA &44                            ; &1808
    BNE &182E                          ; &180A
    LDY #&00                           ; &180C
    STY &44                            ; &180E
    LDY #&00                           ; &1810
    TAX                                ; &1812
    LDA &2C6F,X                        ; &1813
    STA (&17),Y                        ; &1816
    INC &17                            ; &1818
    BNE &1827                          ; &181A
    INC &18                            ; &181C
    BPL &1827                          ; &181E
    LDA &18                            ; &1820
    SEC                                ; &1822
    SBC #&50                           ; &1823
    STA &18                            ; &1825
    INX                                ; &1827
    TXA                                ; &1828
    AND #&0F                           ; &1829
    BNE &1813                          ; &182B
    RTS                                ; &182D
    LDA #&A0                           ; &182E
    BNE &1810                          ; &1830
    LDA #&B0                           ; &1832
    STA &17                            ; &1834
    LDA #&22                           ; &1836
    STA &18                            ; &1838
    LDA #&FF                           ; &183A
    STA &44                            ; &183C
    LDA &76                            ; &183E  stage_bcd
    JMP print_bcd_byte                 ; &1840
    EQUB &A5, &0C, &18, &69, &08, &A8, &A5, &0D, &69, &00, &10, &03, &38    ; &1843-&184F following bytes retained
    EQUB &E9, &50, &8D, &6E, &18, &A2, &80, &4C, &69, &18, &A0, &00, &EE, &6E, &18, &10    ; &1850
    EQUB &11, &A9, &30, &8D, &6E, &18, &4C, &72, &18, &BD, &D0, &21, &99, &00, &FF, &C8    ; &1860
    EQUB &F0, &E8, &E8, &D0, &F4, &A5, &0C, &18, &69, &F8, &A8, &A5, &0D, &69, &01, &10    ; &1870
    EQUB &03, &38, &E9, &50, &8D, &A0, &18, &A2, &B0, &4C, &9B, &18, &A0, &00, &EE, &A0    ; &1880
    EQUB &18, &10, &11, &A9, &30, &8D, &A0, &18, &4C, &A4, &18, &BD, &20, &22, &99, &00    ; &1890
    EQUB &FF, &C8, &F0, &E8, &E8, &D0, &F4, &A5, &48, &30, &1F, &A5, &47, &29, &F8, &18    ; &18A0
    EQUB &65, &0C, &85, &14, &A5, &0D, &69, &05, &65, &48, &10, &03, &38, &E9, &50, &85    ; &18B0
    EQUB &15, &A0, &06, &A9, &2D, &91, &14, &88, &D0, &FB, &A5, &0C, &18, &69, &50, &85    ; &18C0
    EQUB &14, &A5, &0D, &69, &07, &10, &03, &38, &E9, &50, &85, &15, &A0, &07, &A9, &3F    ; &18D0
    EQUB &91, &14, &A9, &15, &88, &D0, &F9, &A9, &3F, &91, &14, &A5, &0C, &18, &69, &48    ; &18E0
    EQUB &85, &14, &A5, &0D, &69, &07, &10, &03, &38, &E9, &50, &85, &15, &A0, &06, &A9    ; &18F0
; -----------------------------------------------------------------------------
; &1907 DROP BOMB / &1938 FIRE BULLET
; Bomb creation uses two slots; bullet creation uses four slots.
; MOD: bomb cooldown at &192E is &06 frames; bullet cooldown at &195B is &01.
; -----------------------------------------------------------------------------
    EQUB &00, &91, &14, &88, &D0, &FB, &60    ; &1900-&1906 preceding bytes retained

; -----------------------------------------------------------------------------
; PROJECTILES, SECTION HAZARDS, ACTIVE OBJECT UPDATE AND RAID COMPLETE CODE
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
drop_bomb:
    LDY #&01                           ; &1907
    LDA &2B79,Y                        ; &1909
    BEQ &1914                          ; &190C
    DEY                                ; &190E
    LDA &2B79,Y                        ; &190F
    BNE &1937                          ; &1912
    LDA &2B78                          ; &1914  object_x_table
    CLC                                ; &1917
    ADC #&03                           ; &1918
    STA &2B79,Y                        ; &191A
    LDA &2B8C                          ; &191D  object_y_table
    SEC                                ; &1920
    SBC &2C2E                          ; &1921
    SBC #&01                           ; &1924
    STA &2B8D,Y                        ; &1926
    LDA #&20                           ; &1929
    STA &0038,Y                        ; &192B
    LDA #&06                           ; &192E
    STA &3A                            ; &1930
    LDA #&02                           ; &1932
    JMP play_sound_effect              ; &1934
    RTS                                ; &1937
fire_bullet:
    LDY #&03                           ; &1938
    LDA &2B7B,Y                        ; &193A
    BEQ &1943                          ; &193D
    DEY                                ; &193F
    BPL &193A                          ; &1940
    RTS                                ; &1942
    LDA &2B78                          ; &1943  object_x_table
    CLC                                ; &1946
    ADC &2C62                          ; &1947
    STA &2B7B,Y                        ; &194A
    LDA &2B8C                          ; &194D  object_y_table
    SEC                                ; &1950
    SBC #&04                           ; &1951
    STA &2B8F,Y                        ; &1953
    LDA #&A0                           ; &1956
    STA &2B67,Y                        ; &1958
    LDA #&01                           ; &195B
    STA &41                            ; &195D
    LDA #&01                           ; &195F
    JMP play_sound_effect              ; &1961
spawn_section_hazards:
    LDY &4E                            ; &1964  current_section
    BEQ &1972                          ; &1966
    DEY                                ; &1968
    BEQ &19B0                          ; &1969
    DEY                                ; &196B
    BEQ &19E4                          ; &196C
    DEY                                ; &196E
    DEY                                ; &196F
    BEQ &1989                          ; &1970
    LDY #&13                           ; &1972
    LDA &2B50,Y                        ; &1974  object_type_table
    CMP #&01                           ; &1977
    BNE &1984                          ; &1979
    LDA &2B78,Y                        ; &197B  object_x_table
    BEQ &1984                          ; &197E
    CMP #&4C                           ; &1980
    BCC &198A                          ; &1982
    DEY                                ; &1984
    CPY #&08                           ; &1985
    BNE &1974                          ; &1987
    RTS                                ; &1989
    JSR multiply_a_by_y                ; &198A
    AND #&07                           ; &198D
    BNE &1984                          ; &198F
    LDA #&C0                           ; &1991
    STA &2B64,Y                        ; &1993  object_state_table
    LDA #&0C                           ; &1996
    STA &2B50,Y                        ; &1998  object_type_table
    TYA                                ; &199B
    LDX &77                            ; &199C
    BNE &19A5                          ; &199E
    STA &77                            ; &19A0
    JMP &19A7                          ; &19A2
    STA &78                            ; &19A5
    TAX                                ; &19A7
    INC &2B78,X                        ; &19A8  object_x_table
    LDA #&03                           ; &19AB
    JMP play_sound_effect              ; &19AD
    DEC &54                            ; &19B0
    BNE &19E3                          ; &19B2
    LDX &2B80                          ; &19B4
    BNE &19C3                          ; &19B7
    LDX &2B7F                          ; &19B9
    BNE &19C3                          ; &19BC
    LDA #&04                           ; &19BE
    JSR play_sound_effect              ; &19C0
    LDY #&08                           ; &19C3
    LDA &2B78,Y                        ; &19C5  object_x_table
    BEQ &19CB                          ; &19C8
    DEY                                ; &19CA
    LDA #&28                           ; &19CB
    STA &54                            ; &19CD
    JSR multiply_a_by_y                ; &19CF
    AND #&1F                           ; &19D2
    ORA #&40                           ; &19D4
    STA &2B64,Y                        ; &19D6  object_state_table
    LDA #&4B                           ; &19D9
    STA &2B78,Y                        ; &19DB  object_x_table
    LDA #&04                           ; &19DE
    STA &2B50,Y                        ; &19E0  object_type_table
    RTS                                ; &19E3
    JSR &1C4F                          ; &19E4
    AND #&07                           ; &19E7
    BNE &1A17                          ; &19E9
    LDY #&08                           ; &19EB
    LDA &2B78,Y                        ; &19ED  object_x_table
    BEQ &19F8                          ; &19F0
    DEY                                ; &19F2
    LDA &2B78,Y                        ; &19F3  object_x_table
    BNE &1A17                          ; &19F6
    JSR &1C4F                          ; &19F8
    AND #&7F                           ; &19FB
    CLC                                ; &19FD
    ADC #&64                           ; &19FE
    STA &2B8C,Y                        ; &1A00  object_y_table
    LDA #&40                           ; &1A03
    STA &2B64,Y                        ; &1A05  object_state_table
    LDA #&4B                           ; &1A08
    STA &2B78,Y                        ; &1A0A  object_x_table
    LDA #&06                           ; &1A0D
    STA &2B50,Y                        ; &1A0F  object_type_table
    LDA #&05                           ; &1A12
    JMP play_sound_effect              ; &1A14
    RTS                                ; &1A17
update_active_objects:
    LDX #&01                           ; &1A18
    LDA &2B79,X                        ; &1A1A
    BEQ &1A4B                          ; &1A1D
    LDA &3B,X                          ; &1A1F
    EOR #&FF                           ; &1A21
    STA &3B,X                          ; &1A23
    BEQ &1A2A                          ; &1A25
    INC &2B79,X                        ; &1A27
    LDA &2B8D,X                        ; &1A2A
    TAY                                ; &1A2D
    LDA &38,X                          ; &1A2E
    LSR A                              ; &1A30
    LSR A                              ; &1A31
    LSR A                              ; &1A32
    LSR A                              ; &1A33
    STA &1B                            ; &1A34
    TYA                                ; &1A36
    SEC                                ; &1A37
    SBC &1B                            ; &1A38
    STA &2B8D,X                        ; &1A3A
    INC &38,X                          ; &1A3D
    LDA &2B8D,X                        ; &1A3F
    CMP #&DD                           ; &1A42
    BCC &1A4B                          ; &1A44
    LDA #&00                           ; &1A46
    STA &2B79,X                        ; &1A48
    DEX                                ; &1A4B
    BPL &1A1A                          ; &1A4C
    LDA &2B79                          ; &1A4E
    BNE &1A5D                          ; &1A51
    LDA &2B7A                          ; &1A53
    BNE &1A5D                          ; &1A56
    LDA #&09                           ; &1A58
    JSR play_sound_effect              ; &1A5A
    LDX #&03                           ; &1A5D
    LDA &2B7B,X                        ; &1A5F
    BEQ &1A73                          ; &1A62
    INC &2B7B,X                        ; &1A64
    INC &2B7B,X                        ; &1A67
    CMP #&46                           ; &1A6A
    BCC &1A73                          ; &1A6C
    LDA #&00                           ; &1A6E
    STA &2B7B,X                        ; &1A70
    DEX                                ; &1A73
    BPL &1A5F                          ; &1A74
    LDY #&01                           ; &1A76
    LDA #&C0                           ; &1A78
    LDX &77,Y                          ; &1A7A
    BEQ &1A81                          ; &1A7C
    STA &2B64,X                        ; &1A7E  object_state_table
    DEY                                ; &1A81
    BPL &1A7A                          ; &1A82
    LDX &78                            ; &1A84
    LDA &4A                            ; &1A86
    EOR #&40                           ; &1A88
    STA &4A                            ; &1A8A
    BEQ &1A90                          ; &1A8C
    LDX &77                            ; &1A8E
    CPX #&00                           ; &1A90
    BEQ &1AA9                          ; &1A92
    LDA #&80                           ; &1A94
    STA &2B64,X                        ; &1A96  object_state_table
    LDA &2B8C,X                        ; &1A99  object_y_table
    CLC                                ; &1A9C
    ADC #&03                           ; &1A9D
    STA &2B8C,X                        ; &1A9F  object_y_table
    CMP #&DD                           ; &1AA2
    BCC &1AA9                          ; &1AA4
    JSR &1BD4                          ; &1AA6
    LDA &2B6C                          ; &1AA9
    ORA #&40                           ; &1AAC
    STA &2B6C                          ; &1AAE
    LDA &2B6B                          ; &1AB1
    ORA #&40                           ; &1AB4
    STA &2B6B                          ; &1AB6
    LDX #&08                           ; &1AB9
    LDA &64                            ; &1ABB
    EOR #&40                           ; &1ABD
    STA &64                            ; &1ABF
    BEQ &1AC4                          ; &1AC1
    DEX                                ; &1AC3
    LDA &2B50,X                        ; &1AC4  object_type_table
    CMP #&04                           ; &1AC7
    BNE &1ADF                          ; &1AC9
    INC &2B64,X                        ; &1ACB  object_state_table
    LDA &2B64,X                        ; &1ACE  object_state_table
    AND #&1F                           ; &1AD1
    TAY                                ; &1AD3
    ORA #&80                           ; &1AD4
    STA &2B64,X                        ; &1AD6  object_state_table
    LDA &24A0,Y                        ; &1AD9
    STA &2B8C,X                        ; &1ADC  object_y_table
    LDX #&08                           ; &1ADF
    LDA &65                            ; &1AE1
    EOR #&40                           ; &1AE3
    STA &65                            ; &1AE5
    BEQ &1AEA                          ; &1AE7
    DEX                                ; &1AE9
    LDA &2B50,X                        ; &1AEA  object_type_table
    CMP #&06                           ; &1AED
    BNE &1B01                          ; &1AEF
    LDA #&80                           ; &1AF1
    STA &2B64,X                        ; &1AF3  object_state_table
    DEC &2B78,X                        ; &1AF6  object_x_table
    DEC &2B78,X                        ; &1AF9  object_x_table
    BPL &1B01                          ; &1AFC
    JSR &1BEE                          ; &1AFE
    LDX #&07                           ; &1B01
    LDA &2B78,X                        ; &1B03  object_x_table
    BEQ &1B10                          ; &1B06
    DEC &2B78,X                        ; &1B08  object_x_table
    BNE &1B10                          ; &1B0B
    JSR &1BEE                          ; &1B0D
    INX                                ; &1B10
    CPX #&13                           ; &1B11
    BNE &1B03                          ; &1B13
    RTS                                ; &1B15
raid_complete:
    JSR read_system_clock              ; &1B16
    LDA #&0C                           ; &1B19
    JSR play_sound_effect              ; &1B1B
    LDX #&64                           ; &1B1E
    JSR delay_ticks                    ; &1B20
    LDY #&0F                           ; &1B23
    LDA #&00                           ; &1B25
    JSR set_palette                    ; &1B27
    DEY                                ; &1B2A
    BPL &1B27                          ; &1B2B
    LDX #&44                           ; &1B2D
    LDY #&1B                           ; &1B2F
    JSR &06B1                          ; &1B31
    LDX #&64                           ; &1B34
    JSR delay_ticks                    ; &1B36
    LDX #&64                           ; &1B39
    JSR delay_ticks                    ; &1B3B
    LDX &0E                            ; &1B3E  saved_caller_sp
    EQUB &9A, &4C, &06, &0E, &0C, &14, &1F, &04, &08, &11, &08, &57, &65, &6C, &6C, &20    ; &1B40
    EQUB &44, &6F, &6E, &65, &20, &21, &21, &1F, &06, &0C, &11, &05, &59, &6F, &75, &20    ; &1B50
    EQUB &48, &61, &76, &65, &1F, &04, &0E, &53, &75, &63, &63, &65, &73, &73, &66, &75    ; &1B60
    EQUB &6C, &6C, &79, &1F, &03, &10, &43, &6F, &6D, &70, &6C, &65, &74, &65, &64, &20    ; &1B70
    EQUB &59, &6F, &75, &72, &1F, &08, &12, &52, &61, &69, &64, &1F, &03, &1A, &11, &01    ; &1B80
    EQUB &4E, &6F, &77, &20, &54, &72, &79, &20, &41, &67, &61, &69, &6E, &0D    ; &1B90-&1B9D preceding bytes retained

; -----------------------------------------------------------------------------
; ESCAPE, SOUND, INPUT, VIDEO AND GENERAL MOS HELPERS
; Converted from raw EQUB bytes to real 6502 mnemonics in Stage 4.
; -----------------------------------------------------------------------------
check_escape_restart:
    LDX #&8F                           ; &1B9E
    JSR inkey                          ; &1BA0
    BEQ &1BB0                          ; &1BA3
    LDA #&00                           ; &1BA5
    STA &40                            ; &1BA7  score_hi
    STA &3F                            ; &1BA9  score_mid
    STA &3E                            ; &1BAB  score_lo
    LDX &0E                            ; &1BAD  saved_caller_sp
    TXS                                ; &1BAF
    RTS                                ; &1BB0
    LDY #&0F                           ; &1BB1
    LDA #&00                           ; &1BB3
    JSR set_palette                    ; &1BB5
    DEY                                ; &1BB8
    BPL &1BB3                          ; &1BB9
    RTS                                ; &1BBB
play_sound_effect:
    LDX &75                            ; &1BBC  soundflag
    BEQ &1BB0                          ; &1BBE
    ASL A                              ; &1BC0
    ASL A                              ; &1BC1
    ASL A                              ; &1BC2
    ADC #&20                           ; &1BC3
    TAX                                ; &1BC5
    LDY #&24                           ; &1BC6
    LDA #&07                           ; &1BC8
    JMP &FFF1                          ; &1BCA
adval:
    LDY #&00                           ; &1BCD
    LDA #&80                           ; &1BCF
    JMP &FFF4                          ; &1BD1
    LDA &2B28,X                        ; &1BD4
    STA &02                            ; &1BD7
    LDA &2B3C,X                        ; &1BD9
    STA &03                            ; &1BDC
    LDA &2B50,X                        ; &1BDE  object_type_table
    CMP #&0C                           ; &1BE1
    BNE &1BE7                          ; &1BE3
    LDA #&01                           ; &1BE5
    STX &1B                            ; &1BE7
    JSR draw_object_by_type            ; &1BE9
    LDX &1B                            ; &1BEC
    LDA &2B80                          ; &1BEE
    BNE &1C01                          ; &1BF1
    LDA &2B7F                          ; &1BF3
    BNE &1C01                          ; &1BF6
    TXA                                ; &1BF8
    PHA                                ; &1BF9
    LDA #&0B                           ; &1BFA
    JSR play_sound_effect              ; &1BFC
    PLA                                ; &1BFF
    TAX                                ; &1C00
    LDA #&00                           ; &1C01
    STA &2B78,X                        ; &1C03  object_x_table
    STA &2B14,X                        ; &1C06
    STA &2B00,X                        ; &1C09
    STA &2B28,X                        ; &1C0C
    STA &2B3C,X                        ; &1C0F
    TAY                                ; &1C12
    CPX &77                            ; &1C13
    BEQ &1C1D                          ; &1C15
    INY                                ; &1C17
    CPX &78                            ; &1C18
    BEQ &1C1D                          ; &1C1A
    RTS                                ; &1C1C
    STA &0077,Y                        ; &1C1D
    RTS                                ; &1C20
inkey:
    PHA                                ; &1C21
    TYA                                ; &1C22
    PHA                                ; &1C23
    LDY #&FF                           ; &1C24
    LDA #&81                           ; &1C26
    JSR &FFF4                          ; &1C28
    PLA                                ; &1C2B
    TAY                                ; &1C2C
    PLA                                ; &1C2D
    CPX #&00                           ; &1C2E
    RTS                                ; &1C30
set_palette:
    STA &1B                            ; &1C31
    TYA                                ; &1C33
    ASL A                              ; &1C34
    ASL A                              ; &1C35
    ASL A                              ; &1C36
    ASL A                              ; &1C37
    ORA &1B                            ; &1C38
    EOR #&07                           ; &1C3A
    STA &FE21                          ; &1C3C
    RTS                                ; &1C3F
write_crtc_register:
    STX &FE00                          ; &1C40
    STA &FE01                          ; &1C43
    RTS                                ; &1C46
wait_vsync:
    LDA #&02                           ; &1C47
    BIT &FE4D                          ; &1C49
    BEQ wait_vsync                     ; &1C4C
    RTS                                ; &1C4E
    LDA &2F                            ; &1C4F
    PHA                                ; &1C51
    AND #&48                           ; &1C52
    ADC #&38                           ; &1C54
    ASL A                              ; &1C56
    ASL A                              ; &1C57
    ROL &31                            ; &1C58
    ROL &30                            ; &1C5A
    ROL &2F                            ; &1C5C
    PLA                                ; &1C5E
    RTS                                ; &1C5F
    LDA &2C                            ; &1C60
    PHA                                ; &1C62
    AND #&48                           ; &1C63
    ADC #&38                           ; &1C65
    ASL A                              ; &1C67
    ASL A                              ; &1C68
    ROL &2E                            ; &1C69
    ROL &2D                            ; &1C6B
    ROL &2C                            ; &1C6D
    PLA                                ; &1C6F
    RTS                                ; &1C70
multiply_a_by_y:
    LDA &2C                            ; &1C71
    RTS                                ; &1C73
    STA &1B                            ; &1C74
    LDA #&00                           ; &1C76
    CPY #&00                           ; &1C78
    BEQ &1C82                          ; &1C7A
    CLC                                ; &1C7C
    ADC &1B                            ; &1C7D
    DEY                                ; &1C7F
    BNE &1C7C                          ; &1C80
    RTS                                ; &1C82
advance_scroll_position:
    LDA &0C                            ; &1C83
    CLC                                ; &1C85
    ADC #&08                           ; &1C86
    STA &0C                            ; &1C88
    LDA &0D                            ; &1C8A
    ADC #&00                           ; &1C8C
    BPL &1C92                          ; &1C8E
    LDA #&30                           ; &1C90
    STA &0D                            ; &1C92
    RTS                                ; &1C94
wrap_delta:
    STY &1B                            ; &1C95
    SEC                                ; &1C97
    SBC &1B                            ; &1C98
    BCS &1C98                          ; &1C9A
    ADC &1B                            ; &1C9C
    RTS                                ; &1C9E
abs_a:
    BPL &1CA6                          ; &1C9F
    EOR #&FF                           ; &1CA1
    CLC                                ; &1CA3
    ADC #&01                           ; &1CA4
    RTS                                ; &1CA6
allocate_object_slot:
    PHA                                ; &1CA7
    TYA                                ; &1CA8
    PHA                                ; &1CA9
    TXA                                ; &1CAA
    PHA                                ; &1CAB
    JSR &0FB7                          ; &1CAC
    LDX #&09                           ; &1CAF
    LDA &2B78,X                        ; &1CB1  object_x_table
    BEQ &1CBB                          ; &1CB4
    INX                                ; &1CB6
    CPX #&13                           ; &1CB7
    BNE &1CB1                          ; &1CB9
    LDA &02                            ; &1CBB
    STA &2B28,X                        ; &1CBD
    LDA &03                            ; &1CC0
    STA &2B3C,X                        ; &1CC2
    PLA                                ; &1CC5
    STA &2B78,X                        ; &1CC6  object_x_table
    PLA                                ; &1CC9
    STA &2B8C,X                        ; &1CCA  object_y_table
    LDA #&00                           ; &1CCD
    STA &2B64,X                        ; &1CCF  object_state_table
    PLA                                ; &1CD2
    STA &2B50,X                        ; &1CD3  object_type_table
    RTS                                ; &1CD6
draw_object_by_type:
    TAY                                ; &1CD7
    LDA &2C55,Y                        ; &1CD8
    STA &1F                            ; &1CDB
    LDA &2C48,Y                        ; &1CDD
    STA &20                            ; &1CE0
    LDA &2C3B,Y                        ; &1CE2
    STA &1E                            ; &1CE5
    LDA &2C2E,Y                        ; &1CE7
    STA &21                            ; &1CEA
    JMP &1000                          ; &1CEC
erase_object_by_type:
    TYA                                ; &1CEF
    PHA                                ; &1CF0
    LDA &2B50,Y                        ; &1CF1  object_type_table
    JSR draw_object_by_type            ; &1CF4
    PLA                                ; &1CF7
    TAY                                ; &1CF8
    RTS                                ; &1CF9
start_warning_beeper:
    LDA #&05                           ; &1CFA
    STA &73                            ; &1CFC
    LDA #&01                           ; &1CFE
    STA &74                            ; &1D00
    LDA &73                            ; &1D02
    BEQ &1D15                          ; &1D04
    DEC &74                            ; &1D06
    BNE &1D15                          ; &1D08
    LDA #&1E                           ; &1D0A
    STA &74                            ; &1D0C
    LDA #&0A                           ; &1D0E
    JSR play_sound_effect              ; &1D10
    DEC &73                            ; &1D13
    RTS                                ; &1D15
read_system_clock:
    LDX #&00                           ; &1D16
    LDA #&0F                           ; &1D18
    JSR &FFF4                          ; &1D1A
    LDA #&0B                           ; &1D1D
    JMP play_sound_effect              ; &1D1F
delay_ticks:
    PHA                                ; &1D22
    TYA                                ; &1D23
    PHA                                ; &1D24
    INX                                ; &1D25
    STX &67                            ; &1D26
    LDX #&68                           ; &1D28
    LDY #&00                           ; &1D2A
    LDA #&01                           ; &1D2C
    JSR &FFF1                          ; &1D2E
    LDA &68                            ; &1D31
    CMP &66                            ; &1D33
    BEQ &1D28                          ; &1D35
    STA &66                            ; &1D37
    DEC &67                            ; &1D39
    BPL &1D28                          ; &1D3B
    PLA                                ; &1D3D
    TAY                                ; &1D3E
    PLA                                ; &1D3F
    RTS                                ; &1D40
    PHA                                ; &1D41
    LSR A                              ; &1D42
    LSR A                              ; &1D43
    LSR A                              ; &1D44
    LSR A                              ; &1D45
    JSR print_bcd_nibble               ; &1D46
    PLA                                ; &1D49
    AND #&0F                           ; &1D4A
print_bcd_nibble:
    BNE &1D51                          ; &1D4C
    TYA                                ; &1D4E
    BNE &1D58                          ; &1D4F
    LDY #&00                           ; &1D51
    ORA #&30                           ; &1D53
    JMP &FFEE                          ; &1D55
    LDA #&2E                           ; &1D58
    JMP &FFEE                          ; &1D5A
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
; That routine calls OSWORD 8 six times, beginning at &21F0 and advancing the
; parameter pointer by 14 bytes each time.  These bytes are present in the
; original payload; no BASIC @basic ENVELOPE metadata is required.
; Blocks start at: &21F0, &21FE, &220C, &221A, &2228 and &2236.
; The first three redefine envelope 4; the remaining blocks define 1, 2 and 3.
; -----------------------------------------------------------------------------
; &21F0 SOUND ENVELOPE TABLE: six records x 14 bytes
; Installed once by the &3400 startup with OSWORD 8.
; -----------------------------------------------------------------------------
    EQUB &04, &01, &00, &00, &00, &00, &00, &00, &0C, &00, &F6, &FF, &78, &3C, &04, &05    ; &21F0
    EQUB &01, &FF, &00, &0C, &0C, &01, &78, &00, &00, &00, &78, &00, &04, &82, &FE, &FE    ; &2200
    EQUB &FE, &14, &14, &28, &79, &FF, &FE, &FE, &78, &78, &01, &01, &FD, &FD, &FD, &14    ; &2210
    EQUB &14, &14, &5A, &FF, &FF, &FD, &7E, &3F, &02, &04, &FF, &FF, &FF, &14, &14, &14    ; &2220
    EQUB &5A, &FF, &FF, &FD, &7E, &3F, &03, &01, &00, &00, &00, &01, &01, &01, &7E, &FC    ; &2230
    EQUB &FF, &FC, &7E, &00, &59, &3A, &53, &54, &41, &6C, &61, &64, &64, &65, &72, &2B    ; &2240
    EQUB &32, &2C, &59, &3A, &4C, &44, &41, &23, &26, &31, &30, &3A, &53, &54, &41, &6C    ; &2250
    EQUB &61, &64, &64, &65, &72, &2B, &31, &2C, &59, &3A, &44, &45, &59, &3A, &44, &45    ; &2260
    EQUB &59, &3A, &44, &45, &59, &3A, &42, &50, &4C, &73, &63, &6F, &72, &65, &69, &6E    ; &2270
    EQUB &69, &74, &0D, &1B, &58, &6A, &4C, &44, &59, &23, &28, &31, &30, &2A, &32, &30    ; &2280
    EQUB &29, &3A, &2E, &6E, &61, &6D, &65, &69, &6E, &69, &74, &20, &4C, &44, &58, &23    ; &2290
    EQUB &39, &3A, &2E, &69, &6E, &6E, &65, &72, &6E, &61, &6D, &65, &20, &4C, &44, &41    ; &22A0
    EQUB &61, &63, &6F, &72, &6E, &73, &6F, &66, &74, &2C, &58, &3A, &53, &54, &41, &6E    ; &22B0
    EQUB &61, &6D, &65, &2D, &31, &2C, &59, &3A, &44, &45, &59, &3A, &44, &45, &58, &3A    ; &22C0
    EQUB &42, &50, &4C, &69, &6E, &6E, &65, &72, &6E, &61, &6D, &65, &3A, &54, &59, &41    ; &22D0
    EQUB &3A, &42, &4E, &45, &6E, &61, &6D, &65, &69, &6E, &69, &74, &0D, &1B, &BC, &71    ; &22E0
    EQUB &4C, &44, &58, &23, &6E, &61, &6D, &65, &20, &80, &26, &46, &46, &3A, &4C, &44    ; &22F0
    EQUB &59, &23, &32, &37, &3A, &2E, &73, &74, &72, &69, &6E, &67, &69, &6E, &69, &74    ; &2300
    EQUB &20, &54, &58, &41, &3A, &53, &54, &41, &73, &74, &72, &69, &6E, &67, &2C, &59    ; &2310
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
; &2420 SOUND EFFECT TABLE: 8-byte OSWORD 7 parameter blocks
; Entry n is addressed as &2420 + n*8 by play_sound.
; -----------------------------------------------------------------------------
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &13, &00, &01, &00, &96, &00, &01, &00    ; &2420
    EQUB &12, &00, &02, &00, &96, &00, &01, &00, &10, &00, &04, &00, &64, &00, &0A, &00    ; &2430
    EQUB &11, &00, &04, &00, &C0, &00, &FF, &FF, &11, &00, &04, &00, &BC, &00, &14, &00    ; &2440
    EQUB &10, &00, &F1, &FF, &05, &00, &05, &00, &10, &00, &F1, &FF, &04, &00, &02, &00    ; &2450
    EQUB &10, &00, &F1, &FF, &06, &00, &32, &00, &12, &00, &00, &00, &00, &00, &00, &00    ; &2460
    EQUB &13, &00, &03, &00, &B4, &00, &01, &00, &11, &00, &00, &00, &00, &00, &00, &00    ; &2470
    EQUB &01, &00, &00, &00, &72, &2B, &31, &3A, &44, &45, &43, &74, &65, &6D, &70, &3A    ; &2480
    EQUB &42, &4E, &45, &65, &6E, &76, &6C, &6F, &6F, &70, &0D, &1D, &4C, &14, &4C, &44    ; &2490
    EQUB &6E, &78, &81, &8A, &91, &98, &9C, &9F, &A0, &9F, &9C, &98, &91, &8A, &81, &78    ; &24A0
    EQUB &6E, &64, &5B, &52, &4B, &44, &40, &3D, &3C, &3D, &40, &44, &4B, &52, &5B, &64    ; &24B0
    EQUB &0A, &0A, &05, &0A, &0F, &14, &0F, &05, &12, &14, &0A, &1E, &05, &0A, &0F, &0D    ; &24C0
    EQUB &19, &1E, &0F, &19, &04, &1E, &14, &07, &0A, &14, &14, &05, &1E, &14, &19, &07    ; &24D0
    EQUB &1E, &1E, &14, &1E, &0A, &0A, &1E, &14, &0A, &0F, &14, &1E, &0A, &14, &1E, &0F    ; &24E0
    EQUB &1E, &0F, &14, &1E, &14, &19, &1E, &15, &01, &1E, &1E, &1E, &1E, &01, &14, &01    ; &24F0
    EQUB &1E, &01, &1E, &1E, &1E, &1E, &1E, &01, &1E, &01, &1E, &01, &1E, &1E, &1E, &14    ; &2500
    EQUB &01, &1E, &01, &14, &01, &1E, &01, &1E, &1E, &14, &01, &1E, &01, &1E, &1E, &1E    ; &2510
    EQUB &14, &01, &05, &01, &1E, &01, &1E, &01, &1E, &1E, &1E, &01, &0A, &01, &1E, &1E    ; &2520
    EQUB &01, &1E, &1E, &1E, &01, &1E, &01, &19, &01, &1E, &1E, &1E, &01, &1E, &01, &0A    ; &2530
    EQUB &01, &1E, &06, &06, &FF, &34, &26, &DD, &F2, &73, &61, &76, &65, &20, &FF, &28    ; &2540
    EQUB &22, &53, &2E, &53, &52, &43, &45, &20, &22, &2B, &C3, &7E, &90, &2B, &22, &20    ; &2550
    EQUB &FE, &FF, &FD, &02, &01, &FF, &01, &FF, &01, &FF, &02, &01, &FF, &01, &01, &FF    ; &2560
    EQUB &01, &01, &FF, &01, &FF, &01, &01, &FE, &01, &01, &01, &FF, &01, &FF, &01, &FE    ; &2570
    EQUB &01, &FF, &01, &01, &FF, &FF, &01, &FF, &01, &02, &FF, &01, &01, &FF, &01, &FF    ; &2580
    EQUB &01, &FF, &01, &01, &FF, &01, &02, &02, &F6, &00, &00, &00, &00, &9C, &00, &E2    ; &2590
    EQUB &00, &5A, &00, &00, &00, &00, &00, &C4, &00, &E2, &00, &5A, &00, &00, &00, &00    ; &25A0
    EQUB &CE, &00, &CE, &00, &32, &00, &3C, &00, &00, &00, &92, &00, &78, &00, &00, &00    ; &25B0
    EQUB &00, &95, &00, &75, &00, &BA, &00, &28, &00, &00, &00, &9C, &00, &32, &00, &00    ; &25C0
    EQUB &32, &00, &00, &00, &9C, &00, &28, &00, &3C, &00, &00, &00, &9C, &00, &64, &00    ; &25D0
    EQUB &3C, &00, &FA, &06, &FF, &20, &0D, &27, &D8, &0E, &2E, &67, &65, &74, &64, &69    ; &25E0
    EQUB &67, &69, &74, &73, &0D, &28, &3C, &2E, &50, &48, &41, &3A, &80, &23, &26, &46    ; &25F0
    EQUB &1E, &0A, &1F, &0A, &1E, &14, &14, &0E, &0E, &1E, &0F, &0F, &0C, &14, &0C, &0D    ; &2600
    EQUB &14, &14, &0F, &04, &08, &04, &0F, &08, &14, &1E, &14, &0A, &0A, &08, &14, &0A    ; &2610
    EQUB &0F, &0A, &14, &0A, &0A, &0A, &0F, &05, &0C, &10, &0A, &0A, &0E, &0C, &0F, &0C    ; &2620
    EQUB &05, &05, &1E, &0F, &0A, &1E, &0A, &05, &0F, &0F, &0A, &0A, &0D, &0C, &0D, &05    ; &2630
    EQUB &0A, &05, &07, &05, &0A, &0F, &0A, &0F, &06, &0A, &0F, &0F, &0A, &14, &1E, &1E    ; &2640
    EQUB &0A, &0A, &14, &0A, &0F, &0A, &0A, &14, &0F, &05, &05, &14, &0A, &1E, &1E, &0A    ; &2650
    EQUB &1E, &1E, &14, &14, &0A, &1E, &14, &1E, &0A, &1E, &0A, &05, &1E, &0A, &14, &0A    ; &2660
    EQUB &1E, &0A, &1E, &05, &1E, &0A, &1E, &14, &1E, &0A, &0F, &1E, &0A, &05, &05, &0E    ; &2670
    EQUB &14, &0A, &0A, &0A, &0A, &13, &09, &14, &1E, &14, &14, &14, &1E, &14, &14, &14    ; &2680
    EQUB &1E, &14, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &14    ; &2690
    EQUB &1E, &14, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &14    ; &26A0
    EQUB &1E, &14, &14, &14, &1E, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &1E, &1E    ; &26B0
    EQUB &0F, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &14, &1E, &14, &14, &18, &01    ; &26C0
    EQUB &4F, &01, &14, &01, &4A, &01, &14, &01, &4F, &01, &4A, &01, &14, &01, &5E, &01    ; &26D0
    EQUB &4F, &01, &14, &01, &59, &01, &14, &01, &4F, &01, &0A, &01, &4A, &01, &4F, &01    ; &26E0
    EQUB &14, &01, &54, &01, &0A, &01, &0A, &01, &5E, &01, &4A, &01, &0A, &01, &05, &01    ; &26F0
    EQUB &54, &01, &05, &01, &4F, &01, &0F, &01, &54, &01, &0A, &01, &0A, &01, &1E, &01    ; &2700
    EQUB &14, &01, &5E, &01, &4A, &01, &54, &01, &0A, &01, &05, &01, &4F, &01, &0A, &01    ; &2710
    EQUB &54, &01, &14, &01, &4A, &01, &0A, &01, &0A, &01, &07, &01, &54, &01, &5E, &05    ; &2720
    EQUB &01, &5E, &1E, &01, &5E, &5E, &5E, &5E, &14, &01, &5E, &54, &01, &5E, &54, &01    ; &2730
    EQUB &5E, &01, &5E, &5E, &14, &01, &5E, &01, &5E, &01, &5E, &5E, &1E, &01, &5E, &01    ; &2740
    EQUB &5E, &01, &5E, &5E, &5E, &4A, &01, &4A, &01, &5E, &5E, &5E, &01, &5E, &14, &01    ; &2750
    EQUB &54, &01, &5E, &5E, &5E, &01, &5E, &5E, &01, &4A, &01, &5E, &5E, &5E, &4A, &01    ; &2760
    EQUB &5E, &01, &5E, &01, &5E, &5E, &1E, &4F, &01, &5E, &01, &5E, &01, &59, &1E, &01    ; &2770
    EQUB &5E, &01, &54, &01, &54, &01, &54, &01, &5E, &01, &4A, &01, &5E, &54, &01, &54    ; &2780
    EQUB &01, &5E, &01, &5E, &01, &5E, &5E, &5E, &01, &5E, &01, &5E, &01, &59, &1E, &01    ; &2790
    EQUB &5E, &01, &54, &01, &54, &01, &54, &01, &5E, &01, &4A, &01, &5E, &54, &01, &54    ; &27A0
    EQUB &01, &5E, &01, &5E, &01, &5E, &5E, &5E, &01, &5E, &01, &5E, &01, &59, &1E, &01    ; &27B0
    EQUB &5E, &01, &54, &01, &54, &01, &54, &01, &5E, &01, &4A, &01, &5E, &54, &01, &54    ; &27C0
    EQUB &01, &5E, &01, &5E, &01, &5E, &5E, &5E, &5E, &5E, &5E, &5E, &5E, &5E, &5E, &5E    ; &27D0
    EQUB &5E, &5E, &5E, &06, &06, &FF, &65, &72, &6F, &66, &6C, &61, &67, &3A, &4C, &44    ; &27E0
    EQUB &41, &63, &79, &63, &6C, &65, &63, &6F, &75, &6E, &74, &3A, &4A, &4D, &50, &67    ; &27F0
    EQUB &04, &FD, &00, &03, &FE, &FE, &00, &02, &FE, &00, &03, &00, &02, &00, &02, &00    ; &2800
    EQUB &03, &03, &FC, &00, &04, &00, &FD, &00, &04, &FC, &00, &02, &04, &00, &FD, &00    ; &2810
    EQUB &01, &03, &FF, &00, &03, &00, &04, &00, &02, &00, &FD, &00, &FF, &00, &01, &00    ; &2820
    EQUB &FE, &00, &02, &00, &02, &00, &FD, &00, &03, &00, &02, &00, &04, &00, &04, &00    ; &2830
    EQUB &FC, &00, &03, &00, &FD, &FE, &00, &FF, &FF, &FF, &02, &FF, &02, &01, &FF, &01    ; &2840
    EQUB &02, &01, &01, &FF, &02, &FF, &01, &01, &FF, &01, &02, &01, &FF, &01, &01, &FF    ; &2850
    EQUB &01, &01, &01, &01, &FF, &01, &FF, &01, &FF, &01, &FF, &02, &01, &FF, &01, &FF    ; &2860
    EQUB &01, &FF, &01, &FF, &01, &FF, &01, &FF, &01, &01, &FF, &01, &FF, &03, &FE, &00    ; &2870
    EQUB &02, &FE, &00, &00, &00, &03, &FF, &01, &01, &FF, &00, &01, &01, &FF, &00, &01    ; &2880
    EQUB &01, &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01    ; &2890
    EQUB &01, &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01    ; &28A0
    EQUB &01, &FF, &00, &01, &01, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01, &01    ; &28B0
    EQUB &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01, &01, &FF, &00, &01, &7F    ; &28C0
    EQUB &00, &EC, &00, &28, &00, &D8, &00, &14, &00, &1E, &00, &DD, &00, &BA, &00, &14    ; &28D0
    EQUB &00, &E2, &00, &F6, &00, &50, &00, &0A, &00, &EC, &00, &19, &00, &F6, &00, &E2    ; &28E0
    EQUB &00, &28, &00, &9C, &00, &1E, &00, &0A, &00, &14, &00, &F1, &00, &19, &00, &E2    ; &28F0
    EQUB &00, &0A, &00, &C4, &00, &14, &00, &1E, &00, &28, &00, &EC, &00, &0F, &00, &D8    ; &2900
    EQUB &00, &EC, &00, &1E, &00, &1E, &00, &1E, &00, &EF, &00, &14, &00, &EC, &00, &11    ; &2910
    EQUB &00, &81, &00, &14, &00, &EC, &00, &1E, &00, &EC, &00, &14, &00, &E2, &00, &00    ; &2920
    EQUB &78, &00, &00, &9C, &00, &00, &00, &00, &00, &64, &00, &00, &CE, &00, &00, &D8    ; &2930
    EQUB &00, &E2, &00, &00, &00, &64, &00, &CE, &00, &CE, &00, &00, &00, &32, &00, &3C    ; &2940
    EQUB &00, &9C, &00, &00, &00, &00, &64, &00, &9C, &00, &00, &00, &46, &00, &00, &28    ; &2950
    EQUB &00, &9C, &00, &00, &00, &32, &00, &00, &32, &00, &9C, &00, &00, &00, &00, &28    ; &2960
    EQUB &00, &3C, &00, &9C, &00, &00, &00, &00, &64, &00, &CE, &00, &C4, &00, &00, &78    ; &2970
    EQUB &00, &3C, &00, &CE, &00, &9C, &00, &EC, &00, &64, &00, &3C, &00, &00, &EC, &00    ; &2980
    EQUB &D8, &00, &CE, &00, &CE, &00, &00, &00, &64, &00, &CE, &00, &C4, &00, &00, &78    ; &2990
    EQUB &00, &3C, &00, &CE, &00, &9C, &00, &EC, &00, &64, &00, &3C, &00, &00, &EC, &00    ; &29A0
    EQUB &D8, &00, &CE, &00, &CE, &00, &00, &00, &64, &00, &CE, &00, &C4, &00, &00, &78    ; &29B0
    EQUB &00, &3C, &00, &CE, &00, &9C, &00, &EC, &00, &64, &00, &3C, &00, &00, &EC, &00    ; &29C0
    EQUB &D8, &00, &CE, &00, &CE, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &29D0
    EQUB &00, &00, &00, &06, &FA, &FF, &6D, &70, &7A, &3A, &4C, &44, &41, &74, &6F, &70    ; &29E0
    EQUB &2B, &31, &3A, &41, &44, &43, &23, &60, &67, &61, &75, &67, &65, &73, &69, &7A    ; &29F0
    EQUB &01, &02, &05, &01, &02, &05, &01, &02, &05, &01, &05, &02, &01, &02, &05, &01    ; &2A00
    EQUB &01, &02, &01, &02, &05, &01, &02, &05, &01, &02, &02, &01, &05, &02, &01, &05    ; &2A10
    EQUB &01, &05, &02, &05, &01, &02, &02, &01, &02, &05, &05, &01, &01, &01, &02, &01    ; &2A20
    EQUB &02, &01, &02, &05, &01, &02, &05, &01, &02, &05, &01, &02, &02, &01, &05, &02    ; &2A30
    EQUB &01, &05, &01, &05, &02, &05, &01, &02, &02, &01, &02, &05, &05, &01, &01, &01    ; &2A40
    EQUB &05, &01, &02, &05, &01, &02, &02, &01, &02, &05, &01, &02, &01, &02, &05, &05    ; &2A50
    EQUB &01, &02, &05, &01, &02, &05, &01, &02, &05, &02, &01, &02, &05, &01, &02, &05    ; &2A60
    EQUB &01, &05, &02, &05, &01, &02, &05, &01, &02, &05, &01, &02, &05, &01, &02, &05    ; &2A70
    EQUB &05, &01, &02, &05, &01, &02, &02, &02, &02, &02, &02, &02, &02, &02, &02, &02    ; &2A80
    EQUB &02, &02, &02, &02, &02, &02, &02, &02, &02, &02, &02, &02, &02, &03, &03, &03    ; &2A90
    EQUB &FF, &24, &41, &25, &2C, &41, &24, &29, &F1, &5A, &25, &3F, &31, &2A, &32, &35    ; &2AA0
    EQUB &36, &2B, &5A, &25, &3F, &32, &3B, &0D, &33, &2C, &1A, &5A, &25, &3D, &5A, &25    ; &2AB0
    EQUB &2B, &5A, &25, &3F, &33, &3A, &FD, &5A, &25, &3F, &31, &3E, &26, &37, &46, &3A    ; &2AC0
    EQUB &E1, &0D, &33, &90, &05, &20, &0D, &33, &F4, &26, &DD, &F2, &73, &61, &76, &65    ; &2AD0
    EQUB &20, &FF, &28, &22, &53, &2E, &53, &52, &43, &42, &20, &22, &2B, &C3, &7E, &90    ; &2AE0
    EQUB &2B, &22, &20, &22, &2B, &C3, &7E, &B8, &50, &29, &3A, &E1, &0D, &FF, &9C, &00    ; &2AF0
; -----------------------------------------------------------------------------
; &2B00-&2BEF RUNTIME OBJECT STATE TABLES
; Parallel arrays store screen pointers, type, animation/state and X/Y positions
; for the player, projectiles and enemies.  They are cleared/rebuilt per life.
; -----------------------------------------------------------------------------
    EQUB &73, &61, &76, &65, &00, &E0, &2A, &91, &99, &AE, &00, &00, &00, &00, &00, &00    ; &2B00
    EQUB &00, &00, &00, &00, &49, &00, &00, &00, &00, &00, &00, &00, &00, &77, &00, &00    ; &2B10
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &F4, &A1, &A1, &A1, &A1, &A1, &A1, &A1    ; &2B20
    EQUB &99, &AE, &06, &1C, &A1, &00, &00, &00, &00, &00, &00, &00, &49, &00, &00, &00    ; &2B30
    EQUB &00, &00, &00, &00, &00, &77, &78, &79, &00, &00, &00, &00, &00, &00, &00, &00    ; &2B40
    EQUB &00, &0A, &0A, &09, &09, &09, &09, &FF, &04, &02, &05, &01, &0C, &01, &02, &32    ; &2B50
    EQUB &20, &22, &2B, &C3, &80, &80, &80, &80, &80, &80, &80, &9D, &DC, &00, &00, &00    ; &2B60
    EQUB &80, &00, &00, &FF, &00, &00, &73, &61, &06, &00, &00, &00, &00, &00, &00, &00    ; &2B70
    EQUB &00, &1C, &27, &4A, &00, &00, &00, &00, &00, &00, &00, &00, &BB, &00, &00, &00    ; &2B80
    EQUB &00, &00, &00, &52, &4B, &29, &29, &2B, &DF, &00, &00, &00, &00, &00, &00, &00    ; &2B90
    EQUB &08, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18    ; &2BA0
    EQUB &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &18, &90    ; &2BB0
    EQUB &0E, &D8, &A6, &A7, &AB, &B0, &B0, &AF, &B2, &B3, &B5, &B7, &BB, &C0, &BE, &BE    ; &2BC0
    EQUB &BD, &C0, &C1, &C3, &C5, &C7, &B0, &B3, &B1, &B0, &B2, &B5, &B3, &B2, &B4, &B5    ; &2BD0
    EQUB &15, &18, &00, &01, &07, &03, &01, &05, &06, &07, &00, &01, &02, &03, &04, &05    ; &2BE0
    EQUB &06, &07, &00, &50, &50, &00, &00, &00, &00, &00, &00, &00, &00, &00, &80, &00    ; &2BF0
; -----------------------------------------------------------------------------
; &2C00-&2Cxx GAMEPLAY DESCRIPTOR TABLES
; Stage parameters, object sprite geometry, collision widths/heights, palette
; values and score awards are indexed from here by the game routines.
; -----------------------------------------------------------------------------
    EQUB &00, &01, &08, &01, &05, &00, &00, &00, &00, &00, &00, &00, &4B, &3C, &48, &60    ; &2C00
    EQUB &48, &80, &FF, &00, &FF, &FF, &00, &FF, &00, &50, &50, &00, &02, &03, &04, &06    ; &2C10
    EQUB &05, &01, &02, &04, &03, &06, &00, &01, &02, &00, &00, &00, &23, &28, &0A, &14    ; &2C20
    EQUB &10, &10, &06, &10, &0A, &06, &0E, &02, &07, &08, &17, &46, &3C, &60, &60, &12    ; &2C30
    EQUB &60, &28, &12, &7E, &02, &0E, &20, &45, &2E, &2E, &2E, &2E, &2F, &2F, &2F, &2F    ; &2C40
    EQUB &2D, &2D, &2D, &2D, &2D, &12, &58, &94, &F4, &B4, &54, &C6, &EE, &64, &E2, &E4    ; &2C50
    EQUB &F2, &1F, &07, &03, &06, &19, &03, &07, &04, &03, &09, &01, &02, &04, &03, &15    ; &2C60
    EQUB &15, &15, &15, &15, &15, &15, &15, &3F, &15, &15, &15, &15, &15, &15, &3F, &00    ; &2C70
    EQUB &15, &00, &00, &00, &00, &00, &15, &2A, &2A, &2A, &2A, &2A, &2A, &2A, &3F, &15    ; &2C80
    EQUB &00, &00, &00, &15, &15, &15, &15, &3F, &15, &15, &15, &3F, &00, &00, &3F, &15    ; &2C90
    EQUB &00, &00, &00, &15, &00, &00, &15, &3F, &15, &15, &15, &3F, &15, &15, &3F, &15    ; &2CA0
    EQUB &15, &15, &15, &15, &00, &00, &00, &00, &00, &15, &15, &3F, &15, &15, &15, &15    ; &2CB0
    EQUB &15, &15, &15, &00, &00, &00, &15, &3F, &00, &00, &3F, &15, &15, &15, &3F, &15    ; &2CC0
    EQUB &15, &15, &15, &15, &15, &15, &15, &00, &00, &00, &3F, &15, &15, &15, &3F, &15    ; &2CD0
    EQUB &00, &00, &00, &00, &00, &00, &00, &3F, &15, &15, &15, &3F, &15, &15, &15, &15    ; &2CE0
    EQUB &15, &15, &15, &15, &15, &15, &15, &3F, &15, &15, &3F, &15, &15, &15, &3F, &15    ; &2CF0
    EQUB &15, &15, &15, &00, &00, &00, &15, &3F, &15, &15, &3F, &15, &15, &15, &3F, &00    ; &2D00
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &2D10
    EQUB &00, &00, &41, &55, &55, &14, &00, &14, &14, &14, &00, &00, &00, &AA, &AA, &EB    ; &2D20
    EQUB &41, &41, &00, &AA, &AA, &AA, &82, &82, &82, &41, &41, &41, &00, &00, &00, &00    ; &2D30
    EQUB &00, &00, &00, &00, &82, &82, &C3, &41, &41, &00, &00, &00, &00, &00, &00, &00    ; &2D40
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &AA, &AA, &AA, &00, &00    ; &2D50
    EQUB &00, &AA, &AA, &AA, &00, &22, &33, &00, &44, &44, &00, &22, &33, &44, &00, &00    ; &2D60
    EQUB &11, &22, &00, &00, &22, &66, &33, &CC, &99, &33, &CC, &CC, &33, &22, &00, &00    ; &2D70
    EQUB &00, &00, &CC, &CC, &33, &CC, &66, &99, &CC, &66, &CC, &44, &11, &11, &22, &33    ; &2D80
    EQUB &99, &33, &99, &CC, &99, &CC, &CC, &99, &33, &22, &00, &00, &00, &00, &CC, &99    ; &2D90
    EQUB &99, &33, &CC, &99, &CC, &CC, &CC, &00, &00, &00, &11, &11, &66, &66, &CC, &CC    ; &2DA0
    EQUB &99, &66, &CC, &CC, &66, &22, &22, &11, &22, &00, &88, &CC, &99, &33, &66, &CC    ; &2DB0
    EQUB &33, &CC, &22, &11, &00, &00, &00, &00, &00, &33, &22, &88, &88, &99, &66, &00    ; &2DC0
    EQUB &00, &33, &11, &00, &00, &00, &22, &00, &00, &00, &11, &33, &00, &00, &00, &00    ; &2DD0
    EQUB &33, &00, &0F, &0F, &15, &15, &15, &3F, &15, &15, &15, &00, &00, &00, &2A, &00    ; &2DE0
    EQUB &00, &00, &33, &2A, &3F, &15, &3F, &2A, &33, &00, &00, &15, &2B, &3F, &2B, &15    ; &2DF0
    EQUB &00, &00, &00, &2A, &2B, &3F, &2B, &2A, &00, &00, &00, &00, &2A, &3F, &2A, &00    ; &2E00
    EQUB &00, &00, &33, &15, &15, &00, &00, &00, &00, &15, &15, &33, &33, &2A, &2A, &3F    ; &2E10
    EQUB &3F, &3F, &3F, &2A, &2A, &33, &22, &00, &15, &2B, &3F, &3F, &2B, &15, &00, &22    ; &2E20
    EQUB &00, &3F, &2B, &2B, &3F, &3F, &2B, &2B, &3F, &00, &00, &2A, &2B, &2B, &3F, &3F    ; &2E30
    EQUB &2B, &2B, &2A, &00, &00, &00, &2A, &2B, &3F, &3F, &2B, &2A, &00, &00, &00, &00    ; &2E40
    EQUB &00, &00, &3F, &3F, &00, &00, &00, &00, &00, &00, &00, &41, &55, &55, &55, &55    ; &2E50
    EQUB &41, &41, &41, &41, &41, &41, &EB, &EB, &AA, &AA, &AA, &AA, &82, &82, &82, &C3    ; &2E60
    EQUB &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &C3, &41, &41, &00, &00, &00, &00    ; &2E70
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &AA, &AA    ; &2E80
    EQUB &AA, &AA, &AA, &AA, &00, &44, &CC, &CC, &CC, &CC, &CC, &44, &00, &00, &00, &00    ; &2E90
    EQUB &00, &51, &51, &51, &CC, &CC, &F3, &E6, &F3, &E6, &E6, &CC, &CC, &51, &51, &F3    ; &2EA0
    EQUB &A2, &F3, &00, &00, &CC, &CC, &C6, &C6, &C6, &C6, &C3, &CC, &CC, &F3, &00, &F3    ; &2EB0
    EQUB &00, &F3, &00, &00, &CC, &CC, &D3, &D3, &D3, &D3, &D3, &CC, &CC, &F3, &00, &F3    ; &2EC0
    EQUB &00, &F3, &00, &00, &CC, &CC, &E3, &C9, &E3, &C9, &E3, &CC, &CC, &A2, &A2, &F3    ; &2ED0
    EQUB &51, &F3, &00, &00, &00, &88, &CC, &CC, &CC, &CC, &C6, &88, &00, &00, &00, &00    ; &2EE0
    EQUB &00, &A2, &A2, &A2, &00, &00, &50, &CC, &CC, &CC, &44, &44, &51, &51, &51, &51    ; &2EF0
    EQUB &F3, &F3, &F3, &51, &44, &C9, &C9, &E4, &D8, &CC, &DC, &DC, &DC, &44, &00, &00    ; &2F00
    EQUB &A2, &A2, &A2, &00, &CC, &C9, &C9, &CC, &F0, &CC, &EC, &EC, &EC, &CC, &CC, &51    ; &2F10
    EQUB &F3, &F3, &F3, &51, &CC, &C9, &C9, &CC, &F0, &CC, &FC, &FC, &FC, &CC, &88, &00    ; &2F20
    EQUB &A2, &A2, &A2, &00, &00, &88, &D8, &E4, &CC, &CC, &CC, &CC, &D9, &51, &51, &51    ; &2F30
    EQUB &F3, &F3, &F3, &51, &00, &00, &00, &88, &88, &88, &00, &00, &00, &00, &00, &00    ; &2F40
    EQUB &A2, &A2, &A2, &00, &00, &00, &00, &41, &C3, &C3, &C3, &C3, &C3, &C3, &41, &51    ; &2F50
    EQUB &41, &C3, &C3, &41, &00, &41, &00, &41, &E3, &E3, &E3, &E3, &E3, &41, &41, &00    ; &2F60
    EQUB &00, &82, &82, &00, &C3, &C3, &E9, &C3, &C7, &CF, &CF, &DA, &DA, &DA, &DA, &C3    ; &2F70
    EQUB &41, &C3, &C3, &41, &82, &C3, &A8, &C3, &E1, &E1, &E1, &E1, &E1, &E1, &C3, &82    ; &2F80
    EQUB &00, &82, &82, &00, &00, &00, &00, &41, &E3, &E3, &E3, &E3, &E3, &41, &41, &51    ; &2F90
    EQUB &41, &C3, &C3, &41, &00, &00, &00, &00, &82, &82, &82, &82, &82, &82, &00, &00    ; &2FA0
    EQUB &00, &82, &82, &00, &44, &CC, &C9, &C9, &CC, &44, &CC, &CC, &CC, &CC, &CC, &CC    ; &2FB0
    EQUB &88, &CC, &C6, &C6, &CC, &88, &00, &00, &00, &01, &01, &07, &03, &17, &01, &00    ; &2FC0
    EQUB &00, &01, &03, &03, &07, &0B, &03, &15, &03, &03, &03, &03, &07, &0B, &03, &01    ; &2FD0
    EQUB &03, &03, &3F, &03, &00, &02, &2B, &0F, &17, &0B, &07, &0B, &02, &00, &00, &01    ; &2FE0
    EQUB &17, &01, &00, &00, &00, &0B, &07, &2B, &05, &00, &03, &3F, &0B, &2F, &02, &00    ; &2FF0
; -----------------------------------------------------------------------------
; &3000-&32FF COPIED UI / HALL-OF-FAME / CONTROLLER BLOCK
; Runtime address = image address - &2C00. Data comes first, followed by the
; high-score code at runtime &0502 and controller at runtime &0664.
; MOD: OSWORD 0 name length is &13 (19 chars) at runtime &0540.
; -----------------------------------------------------------------------------
    EQUB &86, &16, &07, &1F, &07, &03, &86, &9D, &84, &8D, &43, &6F, &6E, &67, &72, &61    ; &3000
    EQUB &74, &75, &6C, &61, &74, &69, &6F, &6E, &73, &21, &21, &20, &20, &20, &9C, &1F    ; &3010
    EQUB &07, &04, &86, &9D, &84, &8D, &43, &6F, &6E, &67, &72, &61, &74, &75, &6C, &61    ; &3020
    EQUB &74, &69, &6F, &6E, &73, &21, &21, &20, &20, &20, &9C, &1F, &03, &07, &82, &59    ; &3030
    EQUB &6F, &75, &72, &20, &73, &63, &6F, &72, &65, &20, &69, &73, &20, &69, &6E, &20    ; &3040
    EQUB &74, &68, &65, &20, &54, &6F, &70, &20, &45, &69, &67, &68, &74, &2E, &1F, &07    ; &3050
    EQUB &0A, &81, &50, &6C, &65, &61, &73, &65, &20, &65, &6E, &74, &65, &72, &20, &79    ; &3060
    EQUB &6F, &75, &72, &20, &6E, &61, &6D, &65, &3A, &1F, &07, &0F, &86, &9D, &84, &1F    ; &3070
    EQUB &1F, &0F, &9C, &1F, &0A, &0F, &16, &07, &1F, &06, &01, &81, &8D, &52, &6F, &63    ; &3080
    EQUB &6B, &65, &74, &20, &52, &61, &69, &64, &20, &48, &61, &6C, &6C, &20, &4F, &66    ; &3090
    EQUB &20, &46, &61, &6D, &65, &1F, &06, &02, &81, &8D, &52, &6F, &63, &6B, &65, &74    ; &30A0
    EQUB &20, &52, &61, &69, &64, &20, &48, &61, &6C, &6C, &20, &4F, &66, &20, &46, &61    ; &30B0
    EQUB &6D, &65, &0A, &0A, &0A, &0D, &1F, &05, &16, &50, &72, &65, &73, &73, &20, &53    ; &30C0
    EQUB &50, &41, &43, &45, &20, &42, &41, &52, &20, &6F, &72, &20, &46, &69, &72, &65    ; &30D0
    EQUB &20, &42, &75, &74, &74, &6F, &6E, &1F, &0A, &17, &4F, &6E, &20, &4A, &6F, &79    ; &30E0
    EQUB &73, &74, &69, &63, &6B, &20, &54, &6F, &20, &53, &74, &61, &72, &74, &0D, &4C    ; &30F0
    EQUB &05, &06, &20, &16, &1D, &A2, &64, &20, &22, &1D, &A9, &FF, &8D, &4E, &FE, &A5    ; &3100
    EQUB &40, &CD, &D5, &06, &90, &E9, &D0, &10, &A5, &3F, &CD, &D4, &06, &90, &E0, &D0    ; &3110
    EQUB &07, &A5, &3E, &CD, &D3, &06, &90, &D7, &A2, &00, &A0, &04, &20, &9B, &06, &A9    ; &3120
    EQUB &7E, &20, &F4, &FF, &A0, &07, &A2, &E0, &A9, &E5, &8D, &E0, &07, &8C, &E1, &07    ; &3130
    EQUB &A9, &13, &8D, &E2, &07, &A9, &20, &8D, &E3, &07, &A9, &7E, &8D, &E4, &07, &A9    ; &3140
    EQUB &00, &20, &F1, &FF, &90, &05, &A9, &0D, &8D, &E5, &07, &AD, &EE, &06, &85, &00    ; &3150
    EQUB &AD, &EF, &06, &85, &01, &A0, &13, &B9, &E5, &07, &91, &00, &88, &10, &F8, &A5    ; &3160
    EQUB &3E, &8D, &D0, &06, &A5, &3F, &8D, &D1, &06, &A5, &40, &8D, &D2, &06, &A2, &03    ; &3170
    EQUB &8A, &A8, &88, &88, &88, &B9, &D2, &06, &DD, &D2, &06, &90, &6E, &D0, &12, &B9    ; &3180
    EQUB &D1, &06, &DD, &D1, &06, &90, &64, &D0, &08, &B9, &D0, &06, &DD, &D0, &06, &90    ; &3190
    EQUB &5A, &BD, &D0, &06, &8D, &D4, &07, &BD, &D1, &06, &8D, &D5, &07, &BD, &D2, &06    ; &31A0
    EQUB &8D, &D6, &07, &B9, &D0, &06, &9D, &D0, &06, &B9, &D1, &06, &9D, &D1, &06, &B9    ; &31B0
    EQUB &D2, &06, &9D, &D2, &06, &AD, &D4, &07, &99, &D0, &06, &AD, &D5, &07, &99, &D1    ; &31C0
    EQUB &06, &AD, &D6, &07, &99, &D2, &06, &BD, &EE, &06, &8D, &D4, &07, &BD, &EF, &06    ; &31D0
    EQUB &8D, &D5, &07, &B9, &EE, &06, &9D, &EE, &06, &B9, &EF, &06, &9D, &EF, &06, &AD    ; &31E0
    EQUB &D4, &07, &99, &EE, &06, &AD, &D5, &07, &99, &EF, &06, &E8, &E8, &E8, &E0, &1B    ; &31F0
    EQUB &F0, &03, &4C, &80, &05, &A2, &86, &A0, &04, &20, &B1, &06, &A2, &0A, &A9, &20    ; &3200
    EQUB &20, &40, &1C, &A2, &18, &A0, &01, &84, &1B, &A9, &20, &20, &C4, &06, &A5, &1B    ; &3210
    EQUB &09, &30, &20, &EE, &FF, &20, &C2, &06, &A0, &FF, &BD, &D2, &06, &20, &41, &1D    ; &3220
    EQUB &BD, &D1, &06, &20, &41, &1D, &BD, &D0, &06, &20, &41, &1D, &20, &C2, &06, &8A    ; &3230
    EQUB &48, &BD, &EF, &06, &A8, &BD, &EE, &06, &AA, &20, &B1, &06, &68, &AA, &A9, &0A    ; &3240
    EQUB &20, &EE, &FF, &20, &EE, &FF, &E6, &1B, &CA, &CA, &CA, &D0, &BC, &A2, &C6, &A0    ; &3250
    ; &3260-&3263 completes a call to the copied Atom-string printer.
    ; &3264 (runtime &0664) is original source label .space: the title/start
    ; controller.  It handles Q/S sound selection, SPACE/joystick selection,
    ; calls game (&0E00), then jumps to checkhi_score (&0502) on return.
    EQUB &04, &20, &B1, &06, &A9, &7E, &20, &F4, &FF, &A2, &EF, &20, &21, &1C, &F0, &03    ; &3260
    EQUB &E8, &86, &75, &A2, &AE, &20, &21, &1C, &F0, &02, &86, &75, &A9, &00, &85, &6E    ; &3270  Q/S -> soundflag; joyflag=0
    EQUB &A2, &9D, &20, &21, &1C, &D0, &0E, &A9, &FF, &85, &6E, &A2, &00, &20, &CD, &1B    ; &3280  SPACE or joystick fire; joyflag=&FF for joystick
    EQUB &8A, &29, &01, &F0, &CF, &20, &00, &0E, &4C, &02, &05, &86, &00, &84, &01, &A0    ; &3290  JSR game; JMP checkhi_score; microsoftstring begins &329B/&069B
    EQUB &00, &B1, &00, &85, &02, &C8, &B1, &00, &20, &EE, &FF, &C8, &C4, &02, &D0, &F6    ; &32A0  microsoftstring: length-prefixed output
    EQUB &60, &86, &00, &84, &01, &A0, &00, &B1, &00, &20, &EE, &FF, &C8, &C9, &0D, &D0    ; &32B0  atomstring begins &32B1/&06B1: CR-terminated output
    EQUB &F6, &60, &A9, &2E, &A0, &04, &20, &EE, &FF, &88, &D0, &FA, &60, &00, &00, &00    ; &32C0  fourdots begins &32C2/&06C2
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &32F0
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

start:      ; REQUIRED entry symbol for generated boot disks (&3400)
game_entry: ; original BASIC RAID2 eventually CALLs &3400

; Original source label recovered as .enter.
; Copy the &3000-&32FF UI/high-score/controller block into its runtime home
; at &0400-&06FF.  The descending-Y loop copies exactly 256 bytes per page.
enter:
    LDY #&00
copy_controller_pages:
    LDA &3000,Y
    STA &0400,Y
    LDA &3100,Y
    STA &0500,Y
    LDA &3200,Y
    STA &0600,Y
    DEY
    BNE copy_controller_pages

    ; Y is zero here.  One more DEY creates &FF, the original default for
    ; soundflag before Q/S are sampled in the controller at runtime &0664.
    DEY
    STY soundflag

    ; Initialise ten 3-byte score entries in the high-score ladder.
    ; Recovered original source name: .scoreinit
    LDY #&1E
scoreinit:
    LDA #&00
    STA ladder,Y
    STA ladder+2,Y
    LDA #&10
    STA ladder+1,Y
    DEY
    DEY
    DEY
    BPL scoreinit

    ; Fill all ten 20-character name slots with "Acornsoft".  The original
    ; source uses name-1,Y so that Y=200 addresses the last byte of the array.
    LDY #&C8                  ; 10 * 20 bytes
nameinit:
    LDX #&09                  ; "Acornsoft" + CR = 10 bytes
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
    LDX #&0C                  ; LO(highscore_names)
    LDY #&1B
stringinit:
    TXA
    STA score_string_table,Y
    CLC
    ADC #20
    TAX
    LDA #&07                  ; HI(highscore_names)
    STA score_string_table+1,Y
    DEY
    DEY
    DEY
    BPL stringinit

    ; Original source name: .cleartimeloop.  A is still &07 here.
    LDX #&04
cleartimeloop:
    STA &68,X
    DEX
    BPL cleartimeloop

    ; *FX 4,1 then CR.  This is original initialisation, not boot-loader code.
    LDA #&04
    LDX #&01
    JSR osbyte
    LDA #13
    JSR oswrch

    ; Install the six 14-byte sound envelopes stored at &21F0-&2243.
    LDA #&06
    STA &1B                    ; original source symbol: temp
    LDA #&F0
    STA &00                    ; original source symbol: stringptr
    LDA #&21
    STA &01
install_envelopes:
    LDX &00
    LDY &01
    LDA #&08                   ; OSWORD 8 = define envelope
    JSR osword
    LDA &00
    CLC
    ADC #14
    STA &00
    BCC envelope_pointer_ok
    INC &01
envelope_pointer_ok:
    DEC &1B
    BNE install_envelopes

    LDA #&01
    STA startup_flag
    JMP &0664                  ; copied controller: wait for SPACE/fire

; Original source label: acornsoft
acornsoft:
    EQUB &41,&63,&6F,&72,&6E,&73,&6F,&66,&74,13    ; "Acornsoft", CR

    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34A0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34B0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34C0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &34F0

; ------------------------------------------------------------
; DFS execution entry. This is NOT part of the relocated runtime payload.
; It copies the payload down by &1000 and returns to BASIC.
; ------------------------------------------------------------
ORG &4500
raidobj_loader:
    LDA #&8C            ; OSBYTE &8C
    LDX #&00
    LDY #&00
    JSR &FFF4           ; OSBYTE

    LDA #&00
    STA &70             ; destination pointer = &0E00
    STA &72             ; source pointer      = &1E00
    LDA #&0E
    STA &71
    LDA #&1E
    STA &73
    LDY #&00

copy_payload_page:
    LDA (&72),Y
    STA (&70),Y
    INY
    BNE copy_payload_page
    INC &71
    INC &73
    LDA &73
    CMP #&45            ; copied source through &44FF
    BNE copy_payload_page

    LDX #&00
copy_low_workspace:
    LDA low_workspace_image,X
    STA &03B0,X
    INX
    CPX #&30
    BNE copy_low_workspace
    RTS

; Original padding &4538-&454F
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00

low_workspace_image: ; original bytes at &4550-&457F copied to &03B0-&03DF
    EQUB &00, &00, &52, &41, &49, &44, &4F, &42, &4A, &00, &00, &00, &00, &00, &00, &0E    ; source &4550
    EQUB &00, &00, &00, &0E, &00, &00, &26, &00, &9D, &00, &80, &00, &00, &00, &00, &89    ; source &4560
    EQUB &7B, &19, &52, &41, &49, &44, &4F, &42, &4A, &00, &00, &00, &00, &00, &00, &80    ; source &4570
