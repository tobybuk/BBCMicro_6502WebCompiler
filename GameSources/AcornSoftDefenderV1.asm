; =============================================================================
; DEFENDER V1 / early PLANETOID - FINAL annotated reconstruction
; =============================================================================
; Exact source image: user's DFS file $.Defend2
; DFS load address:    &1E00
; DFS execute address: &4100
; File length:         &2380 (9088 bytes)
; Original SHA-256:     9819e1c4d9b4ad3252faac0a12be95d68ec9dc354312f088eaaa94f27b6ba035
;
; BBC BASIC loader setup
; ----------------------
; These @basic statements are consumed only by BBC 6502 Web Assembler's
; boot-disk generator. They emit no machine-code bytes.
;
; IMPORTANT: Defender's runtime engine begins at &0E00. Acorn DFS normally uses
; &0E00-&18FF as filing-system workspace. The original Defend2 relocator therefore
; starts by selecting the cassette filing system (OSBYTE &8C / *TAPE) before it
; copies the engine down to &0E00. The generic boot loader places the engine at
; its runtime address directly, so it must perform the same *TAPE switch first or
; DFS will eventually overwrite live Defender code.
; @basic *TAPE
;
; The four ENVELOPE definitions are the originals from $.Defend1.
; @basic ENVELOPE1,4,-4,-1,-1,20,20,20,1,0,0,0,1,1
; @basic ENVELOPE2,1,2,2,2,20,20,20,1,0,0,0,1,1
; @basic ENVELOPE3,1,3,2,-2,6,6,6,100,0,0,-5,100,0
; @basic ENVELOPE4,1,-15,-15,-15,240,240,240,20,0,0,-20,126,126
;
; Original Defender V1 defines characters &E0-&F6 before entering the game.
; These direct VDU23 statements are equivalent to Defend1's FOR/READ/DATA loop
; and preserve the custom glyphs used by the game-over/title presentation.
; @basic VDU23,224,238,164,164,228,164,164,164,0
; @basic VDU23,225,238,74,74,78,74,74,74,0
; @basic VDU23,226,234,138,138,140,138,138,234,0
; @basic VDU23,227,10,10,10,10,14,14,10,0
; @basic VDU23,228,234,170,170,234,170,164,164,0
; @basic VDU23,229,224,128,128,224,128,128,224,0
; @basic VDU23,230,14,8,8,8,8,8,14,0
; @basic VDU23,231,234,174,174,170,170,170,234,0
; @basic VDU23,232,232,168,168,232,136,136,142,0
; @basic VDU23,233,238,132,132,228,132,132,228,0
; @basic VDU23,234,236,138,138,234,138,138,236,0
; @basic VDU23,235,206,170,170,202,170,170,206,0
; @basic VDU23,236,170,170,234,234,234,170,174,0
; @basic VDU23,237,224,128,128,224,32,32,224,0
; @basic VDU23,238,160,160,160,64,160,160,160,0
; @basic VDU23,239,55,69,69,87,85,85,53,0
; @basic VDU23,240,87,116,116,87,84,84,87,0
; @basic VDU23,241,234,170,170,170,170,164,228,0
; @basic VDU23,242,236,138,138,236,138,138,234,0
; @basic VDU23,243,174,164,164,228,164,164,174,0
; @basic VDU23,244,14,8,8,238,2,2,14,0
; @basic VDU23,245,238,138,138,138,138,138,238,0
; @basic VDU23,246,206,168,168,206,168,168,174,0
;
; This is the original Defend1 display setup immediately following MODE 7.
; 8202 decimal is &200A, so BASIC's semicolon form emits VDU 23,10,32,0,...
; @basic VDU23;8202;0;0;0;
;
; PRNG seed fix from the previously proven working build. BBC BASIC ! indirection
; stores a 32-bit value little-endian, initialising &80..&83 to &CE,&AD,&02,&2D.
; @basic LET !&80=&2D02ADCE
;
; MODIFICATION-FRIENDLY SOURCE
; ----------------------------
; Internal code/data addresses are represented by labels. The original runtime
; addresses remain in comments for forensic reference only. Genuine external
; addresses (MOS/hardware, zero page and fixed BBC workspaces) remain absolute.
; This means normal insertions/deletions in the game image can move subsequent
; routines and tables without leaving stale internal addresses behind.
;
; FINAL STATUS
; ------------
; Every byte of $.Defend2 is represented by this source.  All reachable game
; engine routines have semantic labels and comments.  Data which has no live
; consumer in this V1 build is deliberately retained and explicitly labelled
; as unused rather than guessed at.
;
; This source has been independently assembled and compared with the original
; $.Defend2 payload: 9088 bytes, zero differing bytes, identical SHA-256.
; The forensic address/opcode comments are documentary only and are not used by
; the assembler to generate the output.
;
; Relocation:
;   &4100 Defend2Relocator copies file bytes loaded at &1E00-&40FF down by
;   &1000 to runtime &0E00-&30FF, then returns to BASIC.
;   BASIC later CALLs &0E02; that path enters Startup at &3000.
;   Startup installs IRQ1V, copies the 46-byte live stub from &305A to &0400,
;   then jumps to it.  The stub clears the high score, selects MODE 2 and enters
;   MainWithHighScore.
;
; This is the EARLY "Defender V1" code layout.  A later Acornsoft Planetoid
; release contains strongly related algorithms, but many V1 globals are located
; at &2Fxx rather than zero page and some tables/code differ.  Names imported
; from later-source terminology have therefore only been used where V1 byte
; behaviour independently supports the interpretation.
;
; Unit/sprite type IDs:
SHIP       = 0
LANDER     = 1
MUTANT     = 2
BAITER     = 3
BOMBER     = 4
SWARMER    = 5
HUMAN      = 6
POD        = 7
PROJECTILE = 8
SCORE250   = 9
SCORE500   = 10

UNIT_UPDATE = &80
UNIT_EMPTY  = &FF

; UnitParam state encodings recovered from the Lander/Human state machines.
PARAM_LINK_MASK       = &3F

LANDER_TARGET_FLAG    = &80   ; selected Human slot, approaching target
LANDER_PICKUP_FLAG    = &40   ; combined with TARGET while aligning/picking up
LANDER_PICKUP_STATE   = &C0   ; TARGET|PICKUP; low 6 bits still Human slot

HUMAN_HITCHHIKER     = &80   ; rescued Human currently hanging beneath ship
HUMAN_FALLING        = &FF   ; free-falling Human under gravity

; Unit slot IDs
SHIP_SLOT     = 0
HITCH_SLOT    = 1
FIRST_ENEMY   = 2
LAST_ENEMY    = 31
BULLET1_SLOT  = 32
BULLET2_SLOT  = 33
ALT1_SLOT     = 34
ALT2_SLOT     = 35
ALT3_SLOT     = 36
UNIT_SLOTS    = 37

; BBC negative-INKEY internal key numbers used by V1
KEY_A         = &BE
KEY_Z         = &9E
KEY_SPACE     = &9D
KEY_SHIFT     = &FF
KEY_TAB       = &9F
KEY_RETURN    = &B6

; BBC MOS entry points, vectors and hardware registers used by the engine
OSRDCH              = &FFE0
OSWRCH              = &FFEE
OSWORD              = &FFF1
OSBYTE              = &FFF4
BRKV                 = &0202
IRQ1V                = &0204
SYSTEM_VIA_IFR       = &FE4D
USER_VIA_ORB         = &FE60
USER_VIA_T1CL        = &FE64
USER_VIA_T1CH        = &FE65
USER_VIA_ACR         = &FE6B
CRTC_ADDR            = &FE00
CRTC_DATA            = &FE01
ULA_PALETTE          = &FE21
RELOCATOR_WORKSPACE  = &03B0

; ---------------------------------------------------------------------------
; Unit state - 37-way parallel arrays
; ---------------------------------------------------------------------------
UnitXLo          = &0400
UnitXHi          = &0425
UnitYLo          = &044A
UnitYHi          = &046F
UnitDXLo         = &0494
UnitDXHi         = &04B9
UnitDYLo         = &04DE
UnitDYHi         = &0503
UnitSpritePtrLo  = &0528
UnitSpritePtrHi  = &054D
UnitNextPtrLo    = &0572
UnitNextPtrHi    = &0597
UnitType         = &05BC
UnitParam        = &05E1
UnitRadarPtrLo   = &0606       ; normal unit slots 0..31
UnitRadarPtrHi   = &0626
UnitAnim         = &0646
UnitRadarDot     = &066B

; ---------------------------------------------------------------------------
; Internal game data
; ---------------------------------------------------------------------------
; All data that is part of the assembled Defender image is labelled at its
; point of definition later in this source.  Do not give those objects fixed
; addresses here: their labels must move automatically if code or data is
; inserted earlier in the image.
;
; The only absolute addresses retained in this definitions section are genuine
; BBC Micro / MOS / hardware locations and deliberately fixed external
; workspaces such as the unit arrays at &0400 and zero page.
;
; IMPORTANT: internal addresses assembled as split low/high bytes must also use
; symbolic expressions (#<label / #>label).  The original game occasionally
; constructed sprite/tile pointers this way; leaving the literal bytes in place
; makes apparently harmless code insertions corrupt graphics.

; Zero-page scratch (heavily overlaid by subsystem)
DestPtrLo         = &70
DestPtrHi         = &71
SourcePtrLo       = &72
SourcePtrHi       = &73
BlitRow           = &74
ImageLength       = &75
TempLo            = &76
TempHi            = &77
SurfaceCount      = &78
Random0           = &80
Random1           = &81
Random2           = &82
HeightMask        = &84
SavedX            = &85
SavedY            = &86
LaserStepCount    = &87
LaserEdgeDelta    = &88
CurrentUnit       = &89
PaintMask         = &8A
PlayerCollisionMask = &8B
OldIRQ1VLo        = &8C
OldIRQ1VHi        = &8D

; =============================================================================


RelocatedVideoStub = &0400       ; runtime destination of 46-byte stub copied from &305A

ORG &0E00
Defend2PrefixData:
    EQUB &0D,&FF                  ; &0E00-&0E01 retained prefix bytes
GameEntry:
; Defend1 CALLs &0E02 after the relocation pass.
    JMP Startup                   ; &0E02: 4C 00 30

IRQ1VHandler:
; IRQ1V chain hook.  If System VIA IFR bit 1 is set, increment VSyncCounter,
; then tail-chain to the original IRQ1V vector saved in &8C/&8D.
    LDA #&02                     ; &0E05: A9 02
    BIT SYSTEM_VIA_IFR                    ; &0E07: 2C 4D FE
    BEQ ChainOldIRQ1V                    ; &0E0A: F0 03
    INC VSyncCounter                    ; &0E0C: EE 45 2F

ChainOldIRQ1V:
    JMP (OldIRQ1VLo)                  ; &0E0F: 6C 8C 00

WaitForVSync:
    LDA VSyncCounter                    ; &0E12: AD 45 2F
    CMP LastVSync                    ; &0E15: CD 1B 2F
    BEQ WaitForVSync             ; &0E18: F0 F8
    STA LastVSync                    ; &0E1A: 8D 1B 2F
    RTS                          ; &0E1D: 60

CheckForNewVSync:
    LDA VSyncCounter                    ; &0E1E: AD 45 2F
    CMP LastVSync                    ; &0E21: CD 1B 2F
    RTS                          ; &0E24: 60

WritePaletteColour:
    PHA                          ; &0E25: 48
    EOR #&07                     ; &0E26: 49 07
    STA ULA_PALETTE                    ; &0E28: 8D 21 FE
    PLA                          ; &0E2B: 68
    RTS                          ; &0E2C: 60

WriteCRTCRegister:
    STX CRTC_ADDR                    ; &0E2D: 8E 00 FE
    STA CRTC_DATA                    ; &0E30: 8D 01 FE
    RTS                          ; &0E33: 60

ProgramUserVIATimer:
    LDA #&80                     ; &0E34: A9 80
    STA USER_VIA_ACR                    ; &0E36: 8D 6B FE
    STX USER_VIA_T1CL                    ; &0E39: 8E 64 FE
    STY USER_VIA_T1CH                    ; &0E3C: 8C 65 FE
    RTS                          ; &0E3F: 60

ReadUserVIAStatus:
    BIT USER_VIA_ORB                    ; &0E40: 2C 60 FE
    RTS                          ; &0E43: 60

UpdateUnitAIBatch:
; Update a time-sliced batch of ordinary unit slots.  Ship screen X and
; the visible clipping window are calculated first.  AIBatchSize controls how
; many AI slots are processed before yielding; CurrentUnit rotates through the
; ordinary enemy range while avoiding the hitchhiker slot.
    LDX #&00                     ; &0E44: A2 00
    JSR GetUnitScreenX                    ; &0E46: 20 3B 20
    STA ShipScreenX                    ; &0E49: 8D 2C 2F
    LDA #&00                     ; &0E4C: A9 00
    STA MinScreenX                    ; &0E4E: 8D 28 2F
    LDA #&4D                     ; &0E51: A9 4D
    STA MaxScreenX                    ; &0E53: 8D 29 2F
    LDA ScrollOffsetLo                    ; &0E56: AD 02 2F
    BPL StoreLeftClipBoundary                    ; &0E59: 10 08
    CLC                          ; &0E5B: 18
    ADC #&4D                     ; &0E5C: 69 4D
    STA MaxScreenX                    ; &0E5E: 8D 29 2F
    BNE BeginAIBatch                    ; &0E61: D0 03

StoreLeftClipBoundary:
    STA MinScreenX                    ; &0E63: 8D 28 2F

BeginAIBatch:
    LDA AIBatchSize                    ; &0E66: AD 25 2F
    STA AIBatchCounter                    ; &0E69: 8D 26 2F
    LDX CurrentUnit                      ; &0E6C: A6 89
RunNextAIUnit:
    JSR ProcessUnitAI            ; &0E6E: 20 A1 0E
    LDX CurrentUnit                      ; &0E71: A6 89
AdvanceAIUnitIndex:
    INX                          ; &0E73: E8
    CPX #&01                     ; &0E74: E0 01
    BEQ AdvanceAIUnitIndex                    ; &0E76: F0 FB
    CPX #&20                     ; &0E78: E0 20
    BNE AdvanceAIBatch                    ; &0E7A: D0 09
    LDX #&02                     ; &0E7C: A2 02
    LDA UnitAnim                    ; &0E7E: AD 46 06
    BEQ AdvanceAIBatch                    ; &0E81: F0 02
    LDX #&00                     ; &0E83: A2 00

AdvanceAIBatch:
    STX CurrentUnit                      ; &0E85: 86 89
    JSR CheckForNewVSync         ; &0E87: 20 1E 0E
    DEC AIBatchCounter                    ; &0E8A: CE 26 2F
    BNE RunNextAIUnit                    ; &0E8D: D0 DF
    RTS                          ; &0E8F: 60

UpdateSpecialUnitRoundRobin:
    LDX AlternateUnitIndex                    ; &0E90: AE 22 2F
    JSR ProcessUnitAI            ; &0E93: 20 A1 0E
    INX                          ; &0E96: E8
    CPX #&25                     ; &0E97: E0 25
    BNE StoreAlternateUnitIndex                    ; &0E99: D0 02
    LDX #&22                     ; &0E9B: A2 22

StoreAlternateUnitIndex:
    STX AlternateUnitIndex                    ; &0E9D: 8E 22 2F
    RTS                          ; &0EA0: 60

ProcessUnitAI:
; Dispatch one unit slot.  UnitType bit 7 means an update is pending; bit 6
; distinguishes transition states.  Animated/warping units go through
; UpdateUnitAnimation; otherwise the low 7-bit type indexes AIVectorTable.
    LDA UnitType,X                  ; &0EA1: BD BC 05
    BPL ReturnFromUnitAI                    ; &0EA4: 10 25
    ASL A                        ; &0EA6: 0A
    TAY                          ; &0EA7: A8
    BMI ReturnFromUnitAI                    ; &0EA8: 30 21
    LSR A                        ; &0EAA: 4A
    STA UnitType,X                  ; &0EAB: 9D BC 05
    LDA UnitAnim,X                  ; &0EAE: BD 46 06
    BEQ DispatchUnitAI                    ; &0EB1: F0 0B
    BMI AnimateTransitionUnit                    ; &0EB3: 30 06
    JSR UpdateUnitAnimation      ; &0EB5: 20 AE 26
    JMP UpdateRadarDot           ; &0EB8: 4C 6D 13

AnimateTransitionUnit:
    JMP UpdateUnitAnimation      ; &0EBB: 4C AE 26

DispatchUnitAI:
    LDA AIVectorTable,Y                  ; &0EBE: B9 46 2F
    STA DestPtrLo                      ; &0EC1: 85 70
    LDA AIVectorTable+1,Y                  ; &0EC3: B9 47 2F
    STA DestPtrHi                      ; &0EC6: 85 71
    JMP (DestPtrLo)                  ; &0EC8: 6C 70 00

ReturnFromUnitAI:
    RTS                          ; &0ECB: 60

AI_Ship:
    JMP MoveUnit                    ; &0ECC: 4C C6 1F

AI_TimedObject:
    LDY UnitParam,X                  ; &0ECF: BC E1 05
    INY                          ; &0ED2: C8
    TYA                          ; &0ED3: 98
    STA UnitParam,X                  ; &0ED4: 9D E1 05
    CPY #&A0                     ; &0ED7: C0 A0
    BNE MoveTimedUnit                    ; &0ED9: D0 03
    JMP EraseUnit                ; &0EDB: 4C 64 16

MoveTimedUnit:
    JSR MoveUnit                    ; &0EDE: 20 C6 1F
    LDA UnitNextPtrHi,X                  ; &0EE1: BD 97 05
    BNE ReturnTimedUnit                    ; &0EE4: D0 03
    JMP EraseUnit                ; &0EE6: 4C 64 16

ReturnTimedUnit:
    RTS                          ; &0EE9: 60

AI_Lander:
; LANDER AI.  With no humans left, a Lander converts to a Mutant.  Otherwise it
; can fire, select/link a human target, abduct a linked human upward, or terrain-
; follow while searching.
;
; UnitParam encoding for a Lander:
;   &00                  no target; search / terrain-follow
;   &80 | humanSlot      selected target; approach Human
;   &C0 | humanSlot      horizontally aligned; pickup/vertical alignment phase
;   humanSlot (1..31)    Human is linked and being carried upward
;
; Low six bits identify the Human slot.  Bit 7 marks the target/link path and
; bit 6 distinguishes the pickup-alignment phase before full ascent.
    LDA HumanCount                    ; &0EEA: AD 15 2F
    BNE LanderHasHumans                    ; &0EED: D0 0B
    JSR EraseUnit                ; &0EEF: 20 64 16
    LDA #&02                     ; &0EF2: A9 02
    STA UnitType,X                  ; &0EF4: 9D BC 05
    JMP AI_Mutant                ; &0EF7: 4C 6A 10

LanderHasHumans:
    LDA #&0A                     ; &0EFA: A9 0A
    JSR EnemyShootChance         ; &0EFC: 20 EE 18
    LDA UnitParam,X                  ; &0EFF: BD E1 05
    PHA                          ; &0F02: 48
    AND #PARAM_LINK_MASK                     ; &0F03: 29 3F
    TAY                          ; &0F05: A8
    PLA                          ; &0F06: 68
    BNE HandleLanderTargetState                    ; &0F07: D0 03
    JMP ChooseHumanTarget                    ; &0F09: 4C E3 0F

HandleLanderTargetState:
    BMI HandleLinkedHuman                    ; &0F0C: 30 38
    LDA UnitYHi,X                  ; &0F0E: BD 6F 04
    CMP #&BE                     ; &0F11: C9 BE
    BCC FinishLanderUpdate                    ; &0F13: 90 23
    LDA #&06                     ; &0F15: A9 06
    JSR IsLinked                    ; &0F17: 20 5B 28
    BNE ResetLanderType                    ; &0F1A: D0 1F
    TYA                          ; &0F1C: 98
    TAX                          ; &0F1D: AA
    JSR DestroyUnit              ; &0F1E: 20 23 16
    LDX CurrentUnit                      ; &0F21: A6 89
    JSR EraseUnit                ; &0F23: 20 64 16
    LDA #&02                     ; &0F26: A9 02
    STA UnitType,X                  ; &0F28: 9D BC 05
    JMP AI_Mutant                ; &0F2B: 4C 6A 10

ResetLanderDrift:
    LDY #&01                     ; &0F2E: A0 01
    JSR InitialiseUnitVelocity                    ; &0F30: 20 AC 17

ClearLanderLink:
    LDA #&00                     ; &0F33: A9 00
    STA UnitParam,X                  ; &0F35: 9D E1 05

FinishLanderUpdate:
    JMP AI_Pod                   ; &0F38: 4C 73 12

ResetLanderType:
    JSR EraseUnit                ; &0F3B: 20 64 16
    LDA #&01                     ; &0F3E: A9 01
    STA UnitType,X                  ; &0F40: 9D BC 05
    JMP InitialiseUnit           ; &0F43: 4C 6C 17

HandleLinkedHuman:
    LDA UnitParam,X                  ; &0F46: BD E1 05
    ASL A                        ; &0F49: 0A
    BMI ValidateLinkedHuman                    ; &0F4A: 30 2B
    LDA #&06                     ; &0F4C: A9 06
    JSR IsUnlinked                    ; &0F4E: 20 4F 28
    BNE ClearLanderLink                    ; &0F51: D0 E0
    LDA UnitXHi,X                  ; &0F53: BD 25 04
    CMP UnitXHi,Y                  ; &0F56: D9 25 04
    BEQ BeginHumanAbduction                    ; &0F59: F0 03
    JMP FollowTerrain                    ; &0F5B: 4C 0F 10

BeginHumanAbduction:
    LDA #&FC                     ; &0F5E: A9 FC
    STA UnitDYHi,X                  ; &0F60: 9D 03 05
    LDA UnitDXLo,Y                  ; &0F63: B9 94 04
    STA UnitDXLo,X                  ; &0F66: 9D 94 04
    LDA UnitDXHi,Y                  ; &0F69: B9 B9 04
    STA UnitDXHi,X                  ; &0F6C: 9D B9 04
    LDA UnitParam,X                  ; &0F6F: BD E1 05
    ORA #LANDER_PICKUP_FLAG                     ; &0F72: 09 40
    STA UnitParam,X                  ; &0F74: 9D E1 05

ValidateLinkedHuman:
    LDA UnitType,Y                  ; &0F77: B9 BC 05
    AND #&7F                     ; &0F7A: 29 7F
    CMP #&06                     ; &0F7C: C9 06
    BNE ResetLanderDrift                    ; &0F7E: D0 AE
    LDA UnitParam,Y                  ; &0F80: B9 E1 05
    AND #&C0                     ; &0F83: 29 C0
    BNE ResetLanderDrift                    ; &0F85: D0 A7
    LDA UnitParam,Y                  ; &0F87: B9 E1 05
    BEQ CarryLinkedHuman                    ; &0F8A: F0 0B
    LDA #&00                     ; &0F8C: A9 00
    STA UnitDYLo,X                  ; &0F8E: 9D DE 04
    STA UnitDYHi,X                  ; &0F91: 9D 03 05
    JMP AI_Pod                   ; &0F94: 4C 73 12

CarryLinkedHuman:
    LDA UnitYHi,X                  ; &0F97: BD 6F 04
    SEC                          ; &0F9A: 38
    SBC #&0A                     ; &0F9B: E9 0A
    CMP UnitYHi,Y                  ; &0F9D: D9 6F 04
    BCS FinishLanderViaPodMovement                    ; &0FA0: B0 3E
    STA UnitYHi,Y                  ; &0FA2: 99 6F 04
    LDA DXMinInit+LANDER                    ; &0FA5: AD 87 2F
    LSR A                        ; &0FA8: 4A
    LSR A                        ; &0FA9: 4A
    SEC                          ; &0FAA: 38
    SBC #&01                     ; &0FAB: E9 01
    STA UnitDYHi,X                  ; &0FAD: 9D 03 05
    STA UnitDYHi,Y                  ; &0FB0: 99 03 05
    LDA #&00                     ; &0FB3: A9 00
    STA UnitDYLo,X                  ; &0FB5: 9D DE 04
    STA UnitDYLo,Y                  ; &0FB8: 99 DE 04
    STA UnitDXLo,X                  ; &0FBB: 9D 94 04
    STA UnitDXHi,X                  ; &0FBE: 9D B9 04
    STA UnitDXLo,Y                  ; &0FC1: 99 94 04
    STA UnitDXHi,Y                  ; &0FC4: 99 B9 04
    CLC                          ; &0FC7: 18
    LDA UnitXLo,X                  ; &0FC8: BD 00 04
    ADC #&80                     ; &0FCB: 69 80
    STA UnitXLo,Y                  ; &0FCD: 99 00 04
    LDA UnitXHi,X                  ; &0FD0: BD 25 04
    ADC #&00                     ; &0FD3: 69 00
    STA UnitXHi,Y                  ; &0FD5: 99 25 04
    TYA                          ; &0FD8: 98
    STA UnitParam,X                  ; &0FD9: 9D E1 05
    TXA                          ; &0FDC: 8A
    STA UnitParam,Y                  ; &0FDD: 99 E1 05

FinishLanderViaPodMovement:
    JMP AI_Pod                   ; &0FE0: 4C 73 12

ChooseHumanTarget:
    JSR RandomByte               ; &0FE3: 20 12 22
    AND #&0F                     ; &0FE6: 29 0F
    TAY                          ; &0FE8: A8
    LDA #&06                     ; &0FE9: A9 06
    JSR IsUnlinked                    ; &0FEB: 20 4F 28
    BNE FollowTerrain                    ; &0FEE: D0 1F
    SEC                          ; &0FF0: 38
    LDA UnitXHi,Y                  ; &0FF1: B9 25 04
    SBC UnitXHi,X                  ; &0FF4: FD 25 04
    STA TempLo                      ; &0FF7: 85 76
    LDA UnitDXHi,X                  ; &0FF9: BD B9 04
    ASL A                        ; &0FFC: 0A
    LDA TempLo                      ; &0FFD: A5 76
    BCC LinkNearbyHuman                    ; &0FFF: 90 04
    LDA #&00                     ; &1001: A9 00
    SBC TempLo                      ; &1003: E5 76

LinkNearbyHuman:
    CMP #&32                     ; &1005: C9 32
    BCS FollowTerrain                    ; &1007: B0 06
    TYA                          ; &1009: 98
    ORA #LANDER_TARGET_FLAG                     ; &100A: 09 80
    STA UnitParam,X                  ; &100C: 9D E1 05

FollowTerrain:
    LDA UnitDXLo,X                  ; &100F: BD 94 04
    STA TempLo                      ; &1012: 85 76
    LDA UnitDXHi,X                  ; &1014: BD B9 04
    ASL TempLo                      ; &1017: 06 76
    ROL A                        ; &1019: 2A
    ASL TempLo                      ; &101A: 06 76
    ROL A                        ; &101C: 2A
    ASL TempLo                      ; &101D: 06 76
    ROL A                        ; &101F: 2A
    STA TempHi                      ; &1020: 85 77
    JSR GetSurfaceY                    ; &1022: 20 42 28
    STA TempLo                      ; &1025: 85 76
    SEC                          ; &1027: 38
    LDA UnitYHi,X                  ; &1028: BD 6F 04
    SBC TempLo                      ; &102B: E5 76
    CMP #&14                     ; &102D: C9 14
    BCC SteerAwayFromTerrain                    ; &102F: 90 07
    CMP #&1E                     ; &1031: C9 1E
    BCS SteerTowardTerrain                    ; &1033: B0 09
    JMP AI_Pod                   ; &1035: 4C 73 12

SteerAwayFromTerrain:
    BIT TempHi                      ; &1038: 24 77
    BPL AddVerticalAdjustment                    ; &103A: 10 1A
    BMI SubtractVerticalAdjustment                    ; &103C: 30 04

SteerTowardTerrain:
    BIT TempHi                      ; &103E: 24 77
    BMI AddVerticalAdjustment                    ; &1040: 30 14

SubtractVerticalAdjustment:
    SEC                          ; &1042: 38
    LDA UnitYLo,X                  ; &1043: BD 4A 04
    SBC TempLo                      ; &1046: E5 76
    STA UnitYLo,X                  ; &1048: 9D 4A 04
    LDA UnitYHi,X                  ; &104B: BD 6F 04
    SBC TempHi                      ; &104E: E5 77
    STA UnitYHi,X                  ; &1050: 9D 6F 04
    JMP AI_Pod                   ; &1053: 4C 73 12

AddVerticalAdjustment:
    CLC                          ; &1056: 18
    LDA UnitYLo,X                  ; &1057: BD 4A 04
    ADC TempLo                      ; &105A: 65 76
    STA UnitYLo,X                  ; &105C: 9D 4A 04
    LDA UnitYHi,X                  ; &105F: BD 6F 04
    ADC TempHi                      ; &1062: 65 77
    STA UnitYHi,X                  ; &1064: 9D 6F 04
    JMP AI_Pod                   ; &1067: 4C 73 12

AI_Mutant:
; MUTANT AI: aggressive pursuit.  Horizontal displacement and vertical distance
; from the ship are measured, pursuit velocity is adjusted with randomness, and
; the unit can fire when suitably placed.
    LDA #&19                     ; &106A: A9 19
    JSR EnemyShootChance         ; &106C: 20 EE 18
    LDA UnitSpritePtrHi,X                  ; &106F: BD 4D 05
    BEQ EvaluateMutantPursuit                    ; &1072: F0 0C
    JSR RandomByte               ; &1074: 20 12 22
    CMP #&14                     ; &1077: C9 14
    BCS EvaluateMutantPursuit                    ; &1079: B0 05
    LDA #&10                     ; &107B: A9 10
    JSR PlaySound                ; &107D: 20 7D 12

EvaluateMutantPursuit:
    JSR GetHorizontalDisplacementAhead                    ; &1080: 20 DD 10
    CMP #&0A                     ; &1083: C9 0A
    BPL HandleMutantMidRange                    ; &1085: 10 35
    CMP #&EC                     ; &1087: C9 EC
    BMI RandomiseMutantVerticalDirection                    ; &1089: 30 48
RecalculateMutantVerticalPursuit:
    JSR AbsVerticalDisplacementFromShip                    ; &108B: 20 F3 10
ChooseMutantVerticalVelocity:
    LDY #&06                     ; &108E: A0 06
    LDA #&00                     ; &1090: A9 00
    BCS StoreMutantVerticalVelocity                    ; &1092: B0 04
    LDY #&FA                     ; &1094: A0 FA
    LDA #&00                     ; &1096: A9 00

StoreMutantVerticalVelocity:
    STA UnitDYLo,X                  ; &1098: 9D DE 04
    TYA                          ; &109B: 98
    STA UnitDYHi,X                  ; &109C: 9D 03 05
ChooseMutantHorizontalVelocity:
    SEC                          ; &109F: 38
    LDA UnitXHi                    ; &10A0: AD 25 04
    SBC UnitXHi,X                  ; &10A3: FD 25 04
    PHP                          ; &10A6: 08
    LDY #&03                     ; &10A7: A0 03
    LDA #&50                     ; &10A9: A9 50
    PLP                          ; &10AB: 28
    BPL StoreMutantHorizontalVelocity                    ; &10AC: 10 04
    LDY #&FD                     ; &10AE: A0 FD
    LDA #&B0                     ; &10B0: A9 B0

StoreMutantHorizontalVelocity:
    STA UnitDXLo,X                  ; &10B2: 9D 94 04
    TYA                          ; &10B5: 98
    STA UnitDXHi,X                  ; &10B6: 9D B9 04
    JMP AI_Pod                   ; &10B9: 4C 73 12

HandleMutantMidRange:
    CMP #&32                     ; &10BC: C9 32
    BPL RandomiseMutantVerticalDirection                    ; &10BE: 10 13
    JSR AbsVerticalDisplacementFromShip                    ; &10C0: 20 F3 10
    CMP #&28                     ; &10C3: C9 28
    BCS RecalculateMutantVerticalPursuit                    ; &10C5: B0 C4
    JSR AbsVerticalDisplacementFromShip                    ; &10C7: 20 F3 10
    PHP                          ; &10CA: 08
    PLA                          ; &10CB: 68
    EOR #&01                     ; &10CC: 49 01
    PHA                          ; &10CE: 48
    PLP                          ; &10CF: 28
    JMP ChooseMutantVerticalVelocity                    ; &10D0: 4C 8E 10

RandomiseMutantVerticalDirection:
    JSR RandomByte               ; &10D3: 20 12 22
    AND #&01                     ; &10D6: 29 01
    PHA                          ; &10D8: 48
    PLP                          ; &10D9: 28
    JMP ChooseMutantVerticalVelocity                    ; &10DA: 4C 8E 10

GetHorizontalDisplacementAhead:
    LDY UnitXHi                    ; &10DD: AC 25 04
    LDA ShipAccelerationHi                    ; &10E0: AD 1D 2F
    ASL A                        ; &10E3: 0A
    LDA UnitXHi,X                  ; &10E4: BD 25 04
    BCC ReturnHorizontalDisplacement                    ; &10E7: 90 04
    TYA                          ; &10E9: 98
    LDY UnitXHi,X                  ; &10EA: BC 25 04

ReturnHorizontalDisplacement:
    STY TempLo                      ; &10ED: 84 76
    SEC                          ; &10EF: 38
    SBC TempLo                      ; &10F0: E5 76
    RTS                          ; &10F2: 60

AbsVerticalDisplacementFromShip:
    SEC                          ; &10F3: 38
    LDA UnitYHi,X                  ; &10F4: BD 6F 04
    SBC UnitYHi                    ; &10F7: ED 6F 04
    PHA                          ; &10FA: 48
    ASL A                        ; &10FB: 0A
    PLA                          ; &10FC: 68
    BPL ReturnVerticalDisplacement                    ; &10FD: 10 02
    EOR #&FF                     ; &10FF: 49 FF

ReturnVerticalDisplacement:
    RTS                          ; &1101: 60

AI_Baiter:
; BAITER AI: fast late-pressure pursuer.  It periodically recalculates pursuit
; velocity against the ship and fires more aggressively than normal enemies.
    LDA #&28                     ; &1102: A9 28
    JSR EnemyShootChance         ; &1104: 20 EE 18
    LDA UnitParam,X                  ; &1107: BD E1 05
    BEQ RetargetBaiter                    ; &110A: F0 06
    DEC UnitParam,X                  ; &110C: DE E1 05
    JMP AI_Pod                   ; &110F: 4C 73 12

RetargetBaiter:
    JSR RandomByte               ; &1112: 20 12 22
    AND #&07                     ; &1115: 29 07
    CLC                          ; &1117: 18
    ADC #&0A                     ; &1118: 69 0A
    STA UnitParam,X                  ; &111A: 9D E1 05
    TXA                          ; &111D: 8A
    TAY                          ; &111E: A8
    JSR AimAtShip                ; &111F: 20 1C 19
    ASL UnitDYLo,X                  ; &1122: 1E DE 04
    ROL UnitDYHi,X                  ; &1125: 3E 03 05
    ASL UnitDXLo,X                  ; &1128: 1E 94 04
    ROL UnitDXHi,X                  ; &112B: 3E B9 04
    ASL UnitDXLo,X                  ; &112E: 1E 94 04
    ROL UnitDXHi,X                  ; &1131: 3E B9 04
    JMP AI_Pod                   ; &1134: 4C 73 12

AI_Bomber:
; BOMBER AI.  Movement is mostly ballistic; it periodically attempts to release
; a mine/projectile using BomberMineChance.
    JSR BomberMineChance         ; &1137: 20 A7 19
    JSR ApplyVerticalSineAcceleration                    ; &113A: 20 7A 11
    JMP AI_Pod                   ; &113D: 4C 73 12

AI_Swarmer:
; SWARMER AI: direct pursuit with sine-like vertical acceleration and frequent
; retargeting.  Swarmers are normally generated when a Pod is destroyed.
    JSR ApplyVerticalSineAcceleration                    ; &1140: 20 7A 11
    SEC                          ; &1143: 38
    LDA UnitXHi,X                  ; &1144: BD 25 04
    SBC UnitXHi                    ; &1147: ED 25 04
    STA TempLo                      ; &114A: 85 76
    EOR UnitDXHi,X                  ; &114C: 5D B9 04
    BMI MaybePlaySwarmerTurnSound                    ; &114F: 30 10
    LDA TempLo                      ; &1151: A5 76
    BPL MeasureSwarmerDistance                    ; &1153: 10 02
    EOR #&FF                     ; &1155: 49 FF

MeasureSwarmerDistance:
    CMP #&14                     ; &1157: C9 14
    BCS ReuseMutantHorizontalSteering                    ; &1159: B0 03
    JMP AI_Pod                   ; &115B: 4C 73 12

ReuseMutantHorizontalSteering:
    JMP ChooseMutantHorizontalVelocity                    ; &115E: 4C 9F 10

MaybePlaySwarmerTurnSound:
    LDA UnitSpritePtrHi,X                  ; &1161: BD 4D 05
    BEQ SwarmerShootAndFinish                    ; &1164: F0 0C
    JSR RandomByte               ; &1166: 20 12 22
    CMP #&0F                     ; &1169: C9 0F
    BCS SwarmerShootAndFinish                    ; &116B: B0 05
    LDA #&13                     ; &116D: A9 13
    JSR PlaySound                ; &116F: 20 7D 12

SwarmerShootAndFinish:
    LDA #&1E                     ; &1172: A9 1E
    JSR EnemyShootChance         ; &1174: 20 EE 18
    JMP AI_Pod                   ; &1177: 4C 73 12

ApplyVerticalSineAcceleration:
    LDA #&00                     ; &117A: A9 00
    STA TempLo                      ; &117C: 85 76
    LDA UnitYHi,X                  ; &117E: BD 6F 04
    SEC                          ; &1181: 38
    SBC #&62                     ; &1182: E9 62
    BCS ApplyNegativeSineAcceleration                    ; &1184: B0 1B
    EOR #&FF                     ; &1186: 49 FF
    CLC                          ; &1188: 18
    ADC #&01                     ; &1189: 69 01
    ASL A                        ; &118B: 0A
    ROL TempLo                      ; &118C: 26 76
    ASL A                        ; &118E: 0A
    ROL TempLo                      ; &118F: 26 76
    CLC                          ; &1191: 18
    ADC UnitDYLo,X                  ; &1192: 7D DE 04
    STA UnitDYLo,X                  ; &1195: 9D DE 04
    LDA TempLo                      ; &1198: A5 76
    ADC UnitDYHi,X                  ; &119A: 7D 03 05
    STA UnitDYHi,X                  ; &119D: 9D 03 05
    RTS                          ; &11A0: 60

ApplyNegativeSineAcceleration:
    ASL A                        ; &11A1: 0A
    ROL TempLo                      ; &11A2: 26 76
    ASL A                        ; &11A4: 0A
    ROL TempLo                      ; &11A5: 26 76
    STA TempHi                      ; &11A7: 85 77
    SEC                          ; &11A9: 38
    LDA UnitDYLo,X                  ; &11AA: BD DE 04
    SBC TempHi                      ; &11AD: E5 77
    STA UnitDYLo,X                  ; &11AF: 9D DE 04
    LDA UnitDYHi,X                  ; &11B2: BD 03 05
    SBC TempLo                      ; &11B5: E5 76
    STA UnitDYHi,X                  ; &11B7: 9D 03 05
    RTS                          ; &11BA: 60

AI_Human:
; HUMAN AI.  Handles ground walking, Lander linkage/abduction, falling under
; gravity, safe landing and rescue/hitchhiker state when caught by the ship.
;
; UnitParam encoding for a Human:
;   &00               walking freely on the surface
;   landerSlot 1..31  linked to / being carried by that Lander
;   &80               rescued hitchhiker attached beneath the ship
;   &FF               falling freely under gravity
    LDA UnitParam,X                  ; &11BB: BD E1 05
    BNE HumanIsLinked                    ; &11BE: D0 03
    JMP WalkHumanOnTerrain                    ; &11C0: 4C 49 12

HumanIsLinked:
    BMI HumanFallingOrCarried                    ; &11C3: 30 0B
    TAY                          ; &11C5: A8
    LDA #&01                     ; &11C6: A9 01
    JSR IsLinked                    ; &11C8: 20 5B 28
    BNE StartHumanFalling                    ; &11CB: D0 3A
    JMP AI_Pod                   ; &11CD: 4C 73 12

HumanFallingOrCarried:
    ASL A                        ; &11D0: 0A
    BMI ApplyHumanGravity                    ; &11D1: 30 41
    STX SavedX                      ; &11D3: 86 85
    LDX #&01                     ; &11D5: A2 01
    JSR GetSurfaceY                    ; &11D7: 20 42 28
    LDX SavedX                      ; &11DA: A6 85
    CMP UnitYHi+HITCH_SLOT                    ; &11DC: CD 70 04
    BCS HumanRescuedOrDropped                    ; &11DF: B0 01
    RTS                          ; &11E1: 60

HumanRescuedOrDropped:
    DEC HitchhikerCount                    ; &11E2: CE 2D 2F
    LDA UnitXHi+HITCH_SLOT                    ; &11E5: AD 26 04
    STA UnitXHi,X                  ; &11E8: 9D 25 04
    LDA UnitYHi+HITCH_SLOT                    ; &11EB: AD 70 04
    STA UnitYHi,X                  ; &11EE: 9D 6F 04
    LDA #&00                     ; &11F1: A9 00
    STA UnitDYHi,X                  ; &11F3: 9D 03 05
    STA UnitDYLo,X                  ; &11F6: 9D DE 04
    STA UnitParam,X                  ; &11F9: 9D E1 05
    LDA #&0F                     ; &11FC: A9 0F
    JSR PlaySound                ; &11FE: 20 7D 12
    JSR Spawn500ScorePopup       ; &1201: 20 6B 24
    JMP AI_Pod                   ; &1204: 4C 73 12

StartHumanFalling:
    LDA #HUMAN_FALLING                     ; &1207: A9 FF
    STA UnitParam,X                  ; &1209: 9D E1 05
    LDA #&00                     ; &120C: A9 00
    STA UnitDYLo,X                  ; &120E: 9D DE 04
    STA UnitDYHi,X                  ; &1211: 9D 03 05

ApplyHumanGravity:
    SEC                          ; &1214: 38
    LDA UnitDYLo,X                  ; &1215: BD DE 04
    SBC #&40                     ; &1218: E9 40
    STA UnitDYLo,X                  ; &121A: 9D DE 04
    LDA UnitDYHi,X                  ; &121D: BD 03 05
    SBC #&00                     ; &1220: E9 00
    STA UnitDYHi,X                  ; &1222: 9D 03 05
    JSR GetSurfaceY                    ; &1225: 20 42 28
    CMP UnitYHi,X                  ; &1228: DD 6F 04
    BCC AI_Pod                   ; &122B: 90 46
    LDA UnitDYHi,X                  ; &122D: BD 03 05
    CMP #&FB                     ; &1230: C9 FB
    BCS HumanSafeLanding                    ; &1232: B0 03
    JMP DestroyUnit              ; &1234: 4C 23 16

HumanSafeLanding:
    LDA #&00                     ; &1237: A9 00
    STA UnitParam,X                  ; &1239: 9D E1 05
    LDY #&06                     ; &123C: A0 06
    JSR InitialiseUnitVelocity                    ; &123E: 20 AC 17
    LDA #&0F                     ; &1241: A9 0F
    JSR PlaySound                ; &1243: 20 7D 12
    JMP Spawn250ScorePopup       ; &1246: 4C B1 24

WalkHumanOnTerrain:
    LDA UnitDXLo,X                  ; &1249: BD 94 04
    STA TempLo                      ; &124C: 85 76
    LDA UnitDXHi,X                  ; &124E: BD B9 04
    ASL TempLo                      ; &1251: 06 76
    ROL A                        ; &1253: 2A
    ASL TempLo                      ; &1254: 06 76
    ROL A                        ; &1256: 2A
    ASL TempLo                      ; &1257: 06 76
    ROL A                        ; &1259: 2A
    STA TempHi                      ; &125A: 85 77
    JSR GetSurfaceY                    ; &125C: 20 42 28
    SEC                          ; &125F: 38
    SBC UnitYHi,X                  ; &1260: FD 6F 04
    CMP #&04                     ; &1263: C9 04
    BMI HumanSteerTowardTerrain                    ; &1265: 30 09
    CMP #&08                     ; &1267: C9 08
    BPL HumanSteerAwayFromTerrain                    ; &1269: 10 02
    BMI AI_Pod                   ; &126B: 30 06

HumanSteerAwayFromTerrain:
    JMP SteerAwayFromTerrain                    ; &126D: 4C 38 10

HumanSteerTowardTerrain:
    JMP SteerTowardTerrain                    ; &1270: 4C 3E 10

AI_Pod:
; POD AI is deliberately simple: move using its current velocity and update its
; minimap dot.  DestroyUnit contains the special Pod -> Swarmer-cloud logic.
    LDX CurrentUnit                      ; &1273: A6 89
    JSR MoveUnit                    ; &1275: 20 C6 1F
    LDX CurrentUnit                      ; &1278: A6 89
    JMP UpdateRadarDot           ; &127A: 4C 6D 13

PlaySound:
; Table-driven sound player.  A is a sound ID.  V1 builds an 8-byte OSWORD 7
; sound block at &2A80 from per-sound repeat/channel/parameter tables, then submits
; it one or more times.  X and Y are preserved.
    STA TempLo                      ; &127D: 85 76
    TXA                          ; &127F: 8A
    PHA                          ; &1280: 48
    TYA                          ; &1281: 98
    PHA                          ; &1282: 48
    LDX TempLo                      ; &1283: A6 76
    LDA SoundRepeatTable,X                  ; &1285: BD 88 2A
    STA TempLo                      ; &1288: 85 76
RepeatSoundRequest:
    LDA SoundRepeatTable,X                  ; &128A: BD 88 2A
    STA SoundBlock+1                    ; &128D: 8D 81 2A
    LDA SoundChannelTable,X                  ; &1290: BD 9C 2A
    STA SoundBlock                    ; &1293: 8D 80 2A
    LDY #&02                     ; &1296: A0 02
    LDA SoundParam1Table,X                  ; &1298: BD B0 2A
    JSR StoreSignedSoundWordByte                    ; &129B: 20 C1 12
    LDA SoundParam2Table,X                  ; &129E: BD C4 2A
    JSR StoreSignedSoundWordByte                    ; &12A1: 20 C1 12
    LDA SoundParam3Table,X                  ; &12A4: BD D8 2A
    JSR StoreSignedSoundWordByte                    ; &12A7: 20 C1 12
    TXA                          ; &12AA: 8A
    PHA                          ; &12AB: 48
    LDX #&80                     ; &12AC: A2 80
    LDY #&2A                     ; &12AE: A0 2A
    LDA #&07                     ; &12B0: A9 07
    JSR OSWORD                    ; &12B2: 20 F1 FF
    PLA                          ; &12B5: 68
    TAX                          ; &12B6: AA
    INX                          ; &12B7: E8
    DEC TempLo                      ; &12B8: C6 76
    BPL RepeatSoundRequest                    ; &12BA: 10 CE
    PLA                          ; &12BC: 68
    TAY                          ; &12BD: A8
    PLA                          ; &12BE: 68
    TAX                          ; &12BF: AA
    RTS                          ; &12C0: 60

StoreSignedSoundWordByte:
    STA SoundBlock,Y                  ; &12C1: 99 80 2A
    INY                          ; &12C4: C8
    ASL A                        ; &12C5: 0A
    LDA #&00                     ; &12C6: A9 00
    BCC StoreSoundSignExtension                    ; &12C8: 90 02
    LDA #&FF                     ; &12CA: A9 FF

StoreSoundSignExtension:
    STA SoundBlock,Y                  ; &12CC: 99 80 2A
    INY                          ; &12CF: C8
    RTS                          ; &12D0: 60

RepaintMinimap:
; Erase and redraw every active normal unit's two-byte radar mark while
; compensating its cached radar pointer for horizontal screen scrolling.
    LDA MinScreenX                    ; &12D1: AD 28 2F
    PHA                          ; &12D4: 48
    LDA MaxScreenX                    ; &12D5: AD 29 2F
    PHA                          ; &12D8: 48
    LDA #&00                     ; &12D9: A9 00
    STA MinScreenX                    ; &12DB: 8D 28 2F
    LDA #&50                     ; &12DE: A9 50
    STA MaxScreenX                    ; &12E0: 8D 29 2F
    LDX #&1F                     ; &12E3: A2 1F
RadarUnitScanLoop:
    STX SavedX                      ; &12E5: 86 85
    LDA UnitType,X                  ; &12E7: BD BC 05
    BPL NextMinimapUnit                    ; &12EA: 10 3C
    ASL A                        ; &12EC: 0A
    BMI NextMinimapUnit                    ; &12ED: 30 39
    LDY UnitRadarPtrLo,X                  ; &12EF: BC 06 06
    STY DestPtrLo                      ; &12F2: 84 70
    LDY UnitRadarPtrHi,X                  ; &12F4: BC 26 06
    BEQ NextMinimapUnit                    ; &12F7: F0 2F
    STY DestPtrHi                      ; &12F9: 84 71
    TAX                          ; &12FB: AA
    STX SavedY                      ; &12FC: 86 86
    JSR XorRadarDot                    ; &12FE: 20 36 13
    LDX SavedX                      ; &1301: A6 85
    CLC                          ; &1303: 18
    LDA DestPtrLo                      ; &1304: A5 70
    ADC ScrollOffsetLo                    ; &1306: 6D 02 2F
    STA DestPtrLo                      ; &1309: 85 70
    STA UnitRadarPtrLo,X                  ; &130B: 9D 06 06
    LDA DestPtrHi                      ; &130E: A5 71
    ADC ScrollOffsetHi                    ; &1310: 6D 03 2F
    BPL WrapRadarPointerHigh                    ; &1313: 10 03
    SEC                          ; &1315: 38
    SBC #&50                     ; &1316: E9 50

WrapRadarPointerHigh:
    CMP #&30                     ; &1318: C9 30
    BCS StoreRadarPointerHigh                    ; &131A: B0 02
    ADC #&50                     ; &131C: 69 50

StoreRadarPointerHigh:
    STA DestPtrHi                      ; &131E: 85 71
    STA UnitRadarPtrHi,X                  ; &1320: 9D 26 06
    LDX SavedY                      ; &1323: A6 86
    JSR XorRadarDot                    ; &1325: 20 36 13

NextMinimapUnit:
    LDX SavedX                      ; &1328: A6 85
    DEX                          ; &132A: CA
    BPL RadarUnitScanLoop                    ; &132B: 10 B8
    PLA                          ; &132D: 68
    STA MaxScreenX                    ; &132E: 8D 29 2F
    PLA                          ; &1331: 68
    STA MinScreenX                    ; &1332: 8D 28 2F
    RTS                          ; &1335: 60

XorRadarDot:
    LDA DestPtrHi                      ; &1336: A5 71
    BNE XorRadarDotFirstByte                    ; &1338: D0 01
    RTS                          ; &133A: 60

XorRadarDotFirstByte:
    LDY #&00                     ; &133B: A0 00
    LDA (DestPtrLo),Y                  ; &133D: B1 70
    EOR RadarSpriteData,X                  ; &133F: 5D 21 2B
    STA (DestPtrLo),Y                  ; &1342: 91 70
    LDA DestPtrHi                      ; &1344: A5 71
    STA SourcePtrHi                      ; &1346: 85 73
    LDA DestPtrLo                      ; &1348: A5 70
    STA SourcePtrLo                      ; &134A: 85 72
    AND #&07                     ; &134C: 29 07
    CMP #&07                     ; &134E: C9 07
    BNE XorRadarDotSecondByte                    ; &1350: D0 12
    CLC                          ; &1352: 18
    LDA SourcePtrLo                      ; &1353: A5 72
    ADC #&78                     ; &1355: 69 78
    STA SourcePtrLo                      ; &1357: 85 72
    LDA SourcePtrHi                      ; &1359: A5 73
    ADC #&02                     ; &135B: 69 02
    BPL StoreWrappedRadarSourceHigh                    ; &135D: 10 03
    SEC                          ; &135F: 38
    SBC #&50                     ; &1360: E9 50

StoreWrappedRadarSourceHigh:
    STA SourcePtrHi                      ; &1362: 85 73

XorRadarDotSecondByte:
    INY                          ; &1364: C8
    LDA (SourcePtrLo),Y                  ; &1365: B1 72
    EOR RadarSpriteData+1,X                  ; &1367: 5D 22 2B
    STA (SourcePtrLo),Y                  ; &136A: 91 72
    RTS                          ; &136C: 60

UpdateRadarDot:
; Synchronise to the User VIA timer, erase the old radar mark, convert the
; unit's world coordinates to the scanner/minimap position, cache the new pointer,
; then XOR the new mark.
    JSR ReadUserVIAStatus        ; &136D: 20 40 0E
    BPL UpdateRadarDot           ; &1370: 10 FB
    CPX #&20                     ; &1372: E0 20
    BCC UpdateNormalRadarUnit                    ; &1374: 90 01
    RTS                          ; &1376: 60

UpdateNormalRadarUnit:
    LDA MinScreenX                    ; &1377: AD 28 2F
    PHA                          ; &137A: 48
    LDA MaxScreenX                    ; &137B: AD 29 2F
    PHA                          ; &137E: 48
    TXA                          ; &137F: 8A
    PHA                          ; &1380: 48
    LDA #&00                     ; &1381: A9 00
    STA MinScreenX                    ; &1383: 8D 28 2F
    LDA #&50                     ; &1386: A9 50
    STA MaxScreenX                    ; &1388: 8D 29 2F
    LDA UnitRadarPtrLo,X                  ; &138B: BD 06 06
    STA DestPtrLo                      ; &138E: 85 70
    LDA UnitRadarPtrHi,X                  ; &1390: BD 26 06
    STA DestPtrHi                      ; &1393: 85 71
    LDA UnitType,X                  ; &1395: BD BC 05
    ASL A                        ; &1398: 0A
    TAX                          ; &1399: AA
    JSR XorRadarDot                    ; &139A: 20 36 13
    PLA                          ; &139D: 68
    PHA                          ; &139E: 48
    TAX                          ; &139F: AA
    LDA UnitYHi,X                  ; &13A0: BD 6F 04
    LSR A                        ; &13A3: 4A
    LSR A                        ; &13A4: 4A
    CLC                          ; &13A5: 18
    ADC #&C4                     ; &13A6: 69 C4
    TAY                          ; &13A8: A8
    SEC                          ; &13A9: 38
    LDA UnitXLo,X                  ; &13AA: BD 00 04
    SBC WorldLeftEdgeLo                    ; &13AD: ED 20 2F
    LDA UnitXHi,X                  ; &13B0: BD 25 04
    SBC WorldLeftEdgeHi                    ; &13B3: ED 21 2F
    CLC                          ; &13B6: 18
    ADC #&6C                     ; &13B7: 69 6C
    LSR A                        ; &13B9: 4A
    LSR A                        ; &13BA: 4A
    CLC                          ; &13BB: 18
    ADC #&08                     ; &13BC: 69 08
    TAX                          ; &13BE: AA
    JSR XYToVideoPtr                    ; &13BF: 20 6D 1C
    PLA                          ; &13C2: 68
    TAX                          ; &13C3: AA
    LDA DestPtrLo                      ; &13C4: A5 70
    STA UnitRadarPtrLo,X                  ; &13C6: 9D 06 06
    LDA DestPtrHi                      ; &13C9: A5 71
    STA UnitRadarPtrHi,X                  ; &13CB: 9D 26 06
    LDA UnitType,X                  ; &13CE: BD BC 05
    ASL A                        ; &13D1: 0A
    TAX                          ; &13D2: AA
    JSR XorRadarDot                    ; &13D3: 20 36 13
    PLA                          ; &13D6: 68
    STA MaxScreenX                    ; &13D7: 8D 29 2F
    PLA                          ; &13DA: 68
    STA MinScreenX                    ; &13DB: 8D 28 2F
    RTS                          ; &13DE: 60

HandleFireKey:
; Edge-triggered RETURN fire control.  Allocate one of four beam records,
; calculate the muzzle position/direction from the ship, initialise head/tail
; screen pointers and beam phases, then play the firing sound.
    LDX #KEY_RETURN                     ; &13DF: A2 B6
    JSR ScanInkey                    ; &13E1: 20 5A 1C
    BEQ StoreFireKeyState                    ; &13E4: F0 03
    EOR EnterKeyLatch                    ; &13E6: 4D 2B 2F

StoreFireKeyState:
    STX EnterKeyLatch                    ; &13E9: 8E 2B 2F
    BEQ ReturnFromFireKey                    ; &13EC: F0 0A
    LDX #&03                     ; &13EE: A2 03
FindFreeLaserSlotLoop:
    LDA LaserActive,X                  ; &13F0: BD DC 2E
    BEQ InitialiseNewLaser                    ; &13F3: F0 04
    DEX                          ; &13F5: CA
    BPL FindFreeLaserSlotLoop                    ; &13F6: 10 F8

ReturnFromFireKey:
    RTS                          ; &13F8: 60

InitialiseNewLaser:
    STX SavedX                      ; &13F9: 86 85
    LDA UnitYHi                    ; &13FB: AD 6F 04
    SEC                          ; &13FE: 38
    SBC #&06                     ; &13FF: E9 06
    TAY                          ; &1401: A8
    LDX #&00                     ; &1402: A2 00
    JSR GetUnitScreenX                    ; &1404: 20 3B 20
    TAX                          ; &1407: AA
    DEX                          ; &1408: CA
    LDA #&81                     ; &1409: A9 81
    BIT ShipAccelerationHi                    ; &140B: 2C 1D 2F
    BMI InitialiseLaserVideoPointers                    ; &140E: 30 07
    TXA                          ; &1410: 8A
    CLC                          ; &1411: 18
    ADC #&07                     ; &1412: 69 07
    TAX                          ; &1414: AA
    LDA #&01                     ; &1415: A9 01

InitialiseLaserVideoPointers:
    PHA                          ; &1417: 48
    TXA                          ; &1418: 8A
    PHA                          ; &1419: 48
    TYA                          ; &141A: 98
    PHA                          ; &141B: 48
    JSR XYToVideoPtr                    ; &141C: 20 6D 1C
    LDX SavedX                      ; &141F: A6 85
    LDA DestPtrLo                      ; &1421: A5 70
    STA LaserTailPtrLo,X                  ; &1423: 9D F0 2E
    STA LaserHeadPtrLo,X                  ; &1426: 9D F8 2E
    LDA DestPtrHi                      ; &1429: A5 71
    STA LaserTailPtrHi,X                  ; &142B: 9D F4 2E
    STA LaserHeadPtrHi,X                  ; &142E: 9D FC 2E
    PLA                          ; &1431: 68
    STA LaserY,X                  ; &1432: 9D EC 2E
    PLA                          ; &1435: 68
    STA LaserX,X                  ; &1436: 9D E8 2E
    PLA                          ; &1439: 68
    STA LaserActive,X                  ; &143A: 9D DC 2E
    LDA #&00                     ; &143D: A9 00
    STA LaserTailPhase,X                  ; &143F: 9D E0 2E
    STA LaserHeadPhase,X                  ; &1442: 9D E4 2E
    LDA #&04                     ; &1445: A9 04
    JMP PlaySound                ; &1447: 4C 7D 12

UpdateLasers:
; Advance all four horizontal laser beams.  Beam head and tail are XOR-painted
; through LaserPixelTable while following circular MODE 2 video RAM.  Occupied
; pixels trigger the unit collision scan before the beam continues.
    LDX #&03                     ; &144A: A2 03
UpdateNextLaserSlot:
    LDA #&08                     ; &144C: A9 08
    STA TempLo                      ; &144E: 85 76
    LDA #&00                     ; &1450: A9 00
    STA TempHi                      ; &1452: 85 77
    LDA WorldWindowDelta                    ; &1454: AD 2A 2F
    LDY LaserActive,X                  ; &1457: BC DC 2E
    BPL StoreLaserScrollDelta                    ; &145A: 10 0E
    LDA #&F8                     ; &145C: A9 F8
    STA TempLo                      ; &145E: 85 76
    LDA #&FF                     ; &1460: A9 FF
    STA TempHi                      ; &1462: 85 77
    SEC                          ; &1464: 38
    LDA #&00                     ; &1465: A9 00
    SBC WorldWindowDelta                    ; &1467: ED 2A 2F

StoreLaserScrollDelta:
    STA LaserEdgeDelta                      ; &146A: 85 88
    SEC                          ; &146C: 38
    LDA LaserX,X                  ; &146D: BD E8 2E
    SBC WorldWindowDelta                    ; &1470: ED 2A 2F
    STA LaserX,X                  ; &1473: 9D E8 2E
    LDA LaserActive,X                  ; &1476: BD DC 2E
    BNE UpdateActiveLaser                    ; &1479: D0 03
    JMP NextLaserSlot                    ; &147B: 4C 3D 15

UpdateActiveLaser:
    LDA LaserHeadPtrLo,X                  ; &147E: BD F8 2E
    STA DestPtrLo                      ; &1481: 85 70
    LDA LaserHeadPtrHi,X                  ; &1483: BD FC 2E
    STA DestPtrHi                      ; &1486: 85 71
    CLC                          ; &1488: 18
    LDA #&04                     ; &1489: A9 04
    ADC LaserEdgeDelta                      ; &148B: 65 88
    STA LaserStepCount                      ; &148D: 85 87
ContinueLaserHeadStep:
    LDA LaserX,X                  ; &148F: BD E8 2E
    LDY LaserActive,X                  ; &1492: BC DC 2E
    BMI ExtendLaserLeft                    ; &1495: 30 0A
    CMP MaxScreenX                    ; &1497: CD 29 2F
    BPL EraseCompletedLaser                    ; &149A: 10 37
    INC LaserX,X                  ; &149C: FE E8 2E
    BNE PaintLaserHead                    ; &149F: D0 08

ExtendLaserLeft:
    CMP MinScreenX                    ; &14A1: CD 28 2F
    BMI EraseCompletedLaser                    ; &14A4: 30 2D
    DEC LaserX,X                  ; &14A6: DE E8 2E

PaintLaserHead:
    LDY LaserHeadPhase,X                  ; &14A9: BC E4 2E
    JSR XorLaserPixelAndAdvanceHeadIndex                    ; &14AC: 20 6D 15
    STA LaserHeadPhase,X                  ; &14AF: 9D E4 2E
    JSR AdvanceWrappedVideoPtr                    ; &14B2: 20 81 15
    LDY #&00                     ; &14B5: A0 00
    LDA (DestPtrLo),Y                  ; &14B7: B1 70
    AND #&C0                     ; &14B9: 29 C0
    BEQ ContinueLaserHead                    ; &14BB: F0 06
    JSR CheckLaserCollisionPreservingState                    ; &14BD: 20 44 15
    BCS ContinueLaserHead                    ; &14C0: B0 01
    RTS                          ; &14C2: 60

ContinueLaserHead:
    DEC LaserStepCount                      ; &14C3: C6 87
    BNE ContinueLaserHeadStep                    ; &14C5: D0 C8
    LDA DestPtrLo                      ; &14C7: A5 70
    STA LaserHeadPtrLo,X                  ; &14C9: 9D F8 2E
    LDA DestPtrHi                      ; &14CC: A5 71
    STA LaserHeadPtrHi,X                  ; &14CE: 9D FC 2E
    BNE AdvanceLaserTail                    ; &14D1: D0 3B

EraseCompletedLaser:
    LDA DestPtrLo                      ; &14D3: A5 70
    STA SourcePtrLo                      ; &14D5: 85 72
    LDA DestPtrHi                      ; &14D7: A5 71
    STA SourcePtrHi                      ; &14D9: 85 73
    LDA LaserTailPtrLo,X                  ; &14DB: BD F0 2E
    STA DestPtrLo                      ; &14DE: 85 70
    LDA LaserTailPtrHi,X                  ; &14E0: BD F4 2E
    STA DestPtrHi                      ; &14E3: 85 71
    LDA #&00                     ; &14E5: A9 00
    STA LaserActive,X                  ; &14E7: 9D DC 2E
    LDA LaserTailPhase,X                  ; &14EA: BD E0 2E
    TAX                          ; &14ED: AA
    LDY #&00                     ; &14EE: A0 00
EraseLaserPixelLoop:
    INX                          ; &14F0: E8
    LDA LaserPixelTable,X                  ; &14F1: BD FF 29
    EOR (DestPtrLo),Y                  ; &14F4: 51 70
    STA (DestPtrLo),Y                  ; &14F6: 91 70
    CPX #&50                     ; &14F8: E0 50
    BNE AdvanceLaserErase                    ; &14FA: D0 02
    LDX #&4F                     ; &14FC: A2 4F

AdvanceLaserErase:
    JSR AdvanceWrappedVideoPtr                    ; &14FE: 20 81 15
    LDA DestPtrLo                      ; &1501: A5 70
    CMP SourcePtrLo                      ; &1503: C5 72
    BNE EraseLaserPixelLoop                    ; &1505: D0 E9
    LDA DestPtrHi                      ; &1507: A5 71
    CMP SourcePtrHi                      ; &1509: C5 73
    BNE EraseLaserPixelLoop                    ; &150B: D0 E3
    RTS                          ; &150D: 60

AdvanceLaserTail:
    LDA LaserTailPtrLo,X                  ; &150E: BD F0 2E
    STA DestPtrLo                      ; &1511: 85 70
    LDA LaserTailPtrHi,X                  ; &1513: BD F4 2E
    STA DestPtrHi                      ; &1516: 85 71
    CLC                          ; &1518: 18
    LDA #&01                     ; &1519: A9 01
    ADC LaserEdgeDelta                      ; &151B: 65 88
    STA LaserStepCount                      ; &151D: 85 87
    BEQ NextLaserSlot                    ; &151F: F0 1C
    BMI NextLaserSlot                    ; &1521: 30 1A
AdvanceLaserTailStep:
    LDY LaserTailPhase,X                  ; &1523: BC E0 2E
    JSR XorLaserPixelAndAdvanceHeadIndex                    ; &1526: 20 6D 15
    STA LaserTailPhase,X                  ; &1529: 9D E0 2E
    JSR AdvanceWrappedVideoPtr                    ; &152C: 20 81 15
    DEC LaserStepCount                      ; &152F: C6 87
    BNE AdvanceLaserTailStep                    ; &1531: D0 F0
    LDA DestPtrLo                      ; &1533: A5 70
    STA LaserTailPtrLo,X                  ; &1535: 9D F0 2E
    LDA DestPtrHi                      ; &1538: A5 71
    STA LaserTailPtrHi,X                  ; &153A: 9D F4 2E

NextLaserSlot:
    DEX                          ; &153D: CA
    BMI ReturnLaserUpdate                    ; &153E: 30 03
    JMP UpdateNextLaserSlot                    ; &1540: 4C 4C 14

ReturnLaserUpdate:
    RTS                          ; &1543: 60

CheckLaserCollisionPreservingState:
; Test a laser pixel collision against live units while preserving beam state.
; On a hit the unit is scored/destroyed and the beam is terminated as required.
    LDA DestPtrLo                      ; &1544: A5 70
    PHA                          ; &1546: 48
    LDA DestPtrHi                      ; &1547: A5 71
    PHA                          ; &1549: 48
    LDA TempLo                      ; &154A: A5 76
    PHA                          ; &154C: 48
    LDA TempHi                      ; &154D: A5 77
    PHA                          ; &154F: 48
    LDA LaserX,X                  ; &1550: BD E8 2E
    JSR CheckLaserUnitCollision  ; &1553: 20 99 15
    PLA                          ; &1556: 68
    STA TempHi                      ; &1557: 85 77
    PLA                          ; &1559: 68
    STA TempLo                      ; &155A: 85 76
    PLA                          ; &155C: 68
    STA DestPtrHi                      ; &155D: 85 71
    PLA                          ; &155F: 68
    STA DestPtrLo                      ; &1560: 85 70
    BCS ReturnLaserCollisionCheck                    ; &1562: B0 08
    TXA                          ; &1564: 8A
    PHA                          ; &1565: 48
    JSR EraseCompletedLaser                    ; &1566: 20 D3 14
    PLA                          ; &1569: 68
    TAX                          ; &156A: AA
    CLC                          ; &156B: 18

ReturnLaserCollisionCheck:
    RTS                          ; &156C: 60

XorLaserPixelAndAdvanceHeadIndex:
    INY                          ; &156D: C8
    TYA                          ; &156E: 98
    PHA                          ; &156F: 48
    LDA LaserPixelTable,Y                  ; &1570: B9 FF 29
    LDY #&00                     ; &1573: A0 00
    EOR (DestPtrLo),Y                  ; &1575: 51 70
    STA (DestPtrLo),Y                  ; &1577: 91 70
    PLA                          ; &1579: 68
    CMP #&50                     ; &157A: C9 50
    BNE ReturnLaserPixelAdvance                    ; &157C: D0 02
    LDA #&4F                     ; &157E: A9 4F

ReturnLaserPixelAdvance:
    RTS                          ; &1580: 60

AdvanceWrappedVideoPtr:
    CLC                          ; &1581: 18
    LDA DestPtrLo                      ; &1582: A5 70
    ADC TempLo                      ; &1584: 65 76
    STA DestPtrLo                      ; &1586: 85 70
    LDA DestPtrHi                      ; &1588: A5 71
    ADC TempHi                      ; &158A: 65 77
    BPL WrapAdvancedVideoPointer                    ; &158C: 10 02
    LDA #&30                     ; &158E: A9 30

WrapAdvancedVideoPointer:
    CMP #&30                     ; &1590: C9 30
    BCS StoreAdvancedVideoPointer                    ; &1592: B0 02
    ADC #&50                     ; &1594: 69 50

StoreAdvancedVideoPointer:
    STA DestPtrHi                      ; &1596: 85 71
    RTS                          ; &1598: 60

CheckLaserUnitCollision:
    CMP #&50                     ; &1599: C9 50
    BCC BeginLaserUnitScan                    ; &159B: 90 01
    RTS                          ; &159D: 60

BeginLaserUnitScan:
    STX SavedX                      ; &159E: 86 85
    STA &7A                      ; &15A0: 85 7A
    LDA LaserY,X                  ; &15A2: BD EC 2E
    STA &7C                      ; &15A5: 85 7C
    LDX #&02                     ; &15A7: A2 02
ScanNextLaserCollisionUnit:
    LDA UnitSpritePtrHi,X                  ; &15A9: BD 4D 05
    BEQ AdvanceLaserCollisionUnit                    ; &15AC: F0 6C
    LDA UnitYHi,X                  ; &15AE: BD 6F 04
    SEC                          ; &15B1: 38
    SBC &7C                      ; &15B2: E5 7C
    CMP #&08                     ; &15B4: C9 08
    BCS AdvanceLaserCollisionUnit                    ; &15B6: B0 62
    LDA UnitSpritePtrLo,X                  ; &15B8: BD 28 05
    AND #&F8                     ; &15BB: 29 F8
    STA TempLo                      ; &15BD: 85 76
    SEC                          ; &15BF: 38
    LDA DestPtrLo                      ; &15C0: A5 70
    AND #&F8                     ; &15C2: 29 F8
    SBC TempLo                      ; &15C4: E5 76
    STA TempLo                      ; &15C6: 85 76
    LDA DestPtrHi                      ; &15C8: A5 71
    SBC UnitSpritePtrHi,X                  ; &15CA: FD 4D 05
    BPL ConvertLaserPointerDifferenceToX                    ; &15CD: 10 03
    CLC                          ; &15CF: 18
    ADC #&50                     ; &15D0: 69 50

ConvertLaserPointerDifferenceToX:
    LSR A                        ; &15D2: 4A
    ROR TempLo                      ; &15D3: 66 76
    LSR A                        ; &15D5: 4A
    ROR TempLo                      ; &15D6: 66 76
    LSR A                        ; &15D8: 4A
    ROR TempLo                      ; &15D9: 66 76
    STA TempHi                      ; &15DB: 85 77
    SEC                          ; &15DD: 38
ReduceLaserPointerDifference:
    LDA TempLo                      ; &15DE: A5 76
    SBC #&50                     ; &15E0: E9 50
    STA TempLo                      ; &15E2: 85 76
    LDA TempHi                      ; &15E4: A5 77
    SBC #&00                     ; &15E6: E9 00
    STA TempHi                      ; &15E8: 85 77
    BCS ReduceLaserPointerDifference                    ; &15EA: B0 F2
    LDA TempLo                      ; &15EC: A5 76
    ADC #&50                     ; &15EE: 69 50
    CMP #&04                     ; &15F0: C9 04
    BCS AdvanceLaserCollisionUnit                    ; &15F2: B0 26
    LDA UnitAnim,X                  ; &15F4: BD 46 06
    BNE AdvanceLaserCollisionUnit                    ; &15F7: D0 21
    LDA UnitType,X                  ; &15F9: BD BC 05
    ASL A                        ; &15FC: 0A
    BMI AdvanceLaserCollisionUnit                    ; &15FD: 30 1B
    LSR A                        ; &15FF: 4A
    CMP #&06                     ; &1600: C9 06
    BNE DestroyLaserHitUnit                    ; &1602: D0 07
    LDA UnitParam,X                  ; &1604: BD E1 05
    CMP #&80                     ; &1607: C9 80
    BEQ AdvanceLaserCollisionUnit                    ; &1609: F0 0F

DestroyLaserHitUnit:
    LDA #&03                     ; &160B: A9 03
    JSR PlaySound                ; &160D: 20 7D 12
    JSR ScoreUnit                 ; &1610: 20 4D 24
    JSR DestroyUnit              ; &1613: 20 23 16
    LDX SavedX                      ; &1616: A6 85
    CLC                          ; &1618: 18
    RTS                          ; &1619: 60

AdvanceLaserCollisionUnit:
    INX                          ; &161A: E8
    CPX #&20                     ; &161B: E0 20
    BNE ScanNextLaserCollisionUnit                    ; &161D: D0 8A
    LDX SavedX                      ; &161F: A6 85
    SEC                          ; &1621: 38
    RTS                          ; &1622: 60

DestroyUnit:
; Destroy/erase a unit.  Normal kills award points and start the unit explosion.
; A destroyed Pod is special: its position seeds a random 5..12-Swarmer cloud.
; The unit slot is ultimately cleared when its transition completes.
    LDA UnitType,X                  ; &1623: BD BC 05
    AND #&7F                     ; &1626: 29 7F
    CMP #&08                     ; &1628: C9 08
    BCS EraseUnit                ; &162A: B0 38
    CMP #&03                     ; &162C: C9 03
    BEQ StartUnitExplosion                    ; &162E: F0 1C
    PHA                          ; &1630: 48
    JSR StartUnitExplosion                    ; &1631: 20 4C 16
    PLA                          ; &1634: 68
    BCS ReturnDestroyUnit                    ; &1635: B0 07
    CMP #&06                     ; &1637: C9 06
    BEQ DestroyHuman                    ; &1639: F0 04
    DEC EnemyCount                    ; &163B: CE 13 2F

ReturnDestroyUnit:
    RTS                          ; &163E: 60

DestroyHuman:
    LDA #&0A                     ; &163F: A9 0A
    JSR PlaySound                ; &1641: 20 7D 12
    DEC HumanCount                    ; &1644: CE 15 2F
    BNE ReturnDestroyUnit                    ; &1647: D0 F5
    JMP SetSurfacePaletteGreen                    ; &1649: 4C 7B 1B

StartUnitExplosion:
    LDA UnitType,X                  ; &164C: BD BC 05
    PHA                          ; &164F: 48
    JSR EraseUnit                ; &1650: 20 64 16
    PLA                          ; &1653: 68
    BCS ReturnDestroyUnit                    ; &1654: B0 E8
    STA UnitType,X                  ; &1656: 9D BC 05
    LDA #&FF                     ; &1659: A9 FF
    STA UnitAnim,X                  ; &165B: 9D 46 06
    LDA #&08                     ; &165E: A9 08
    STA UnitParam,X                  ; &1660: 9D E1 05
    RTS                          ; &1663: 60

EraseUnit:
    TXA                          ; &1664: 8A
    PHA                          ; &1665: 48
    LDA UnitType,X                  ; &1666: BD BC 05
    ASL A                        ; &1669: 0A
    BMI ReturnEraseAlreadyUpdating                    ; &166A: 30 6E
    CPX #&20                     ; &166C: E0 20
    BCS EraseUnitSpriteIfVisible                    ; &166E: B0 17
    LDY UnitRadarPtrLo,X                  ; &1670: BC 06 06
    STY DestPtrLo                      ; &1673: 84 70
    LDY UnitRadarPtrHi,X                  ; &1675: BC 26 06
    STY DestPtrHi                      ; &1678: 84 71
    BEQ EraseUnitSpriteIfVisible                    ; &167A: F0 0B
    PHA                          ; &167C: 48
    LDA #&00                     ; &167D: A9 00
    STA UnitRadarPtrHi,X                  ; &167F: 9D 26 06
    PLA                          ; &1682: 68
    TAX                          ; &1683: AA
    JSR XorRadarDot                    ; &1684: 20 36 13

EraseUnitSpriteIfVisible:
    PLA                          ; &1687: 68
    PHA                          ; &1688: 48
    TAX                          ; &1689: AA
    LDA UnitAnim,X                  ; &168A: BD 46 06
    BNE ClearDestroyedUnitState                    ; &168D: D0 13
    LDA UnitSpritePtrLo,X                  ; &168F: BD 28 05
    STA DestPtrLo                      ; &1692: 85 70
    LDA UnitSpritePtrHi,X                  ; &1694: BD 4D 05
    STA DestPtrHi                      ; &1697: 85 71
    LDA UnitType,X                  ; &1699: BD BC 05
    AND #&7F                     ; &169C: 29 7F
    TAX                          ; &169E: AA
    JSR XorBlitSprite                    ; &169F: 20 B4 20

ClearDestroyedUnitState:
    PLA                          ; &16A2: 68
    TAX                          ; &16A3: AA
    JSR ClearUnitData                    ; &16A4: 20 20 24
    LDA UnitType,X                  ; &16A7: BD BC 05
    AND #&7F                     ; &16AA: 29 7F
    CMP #&07                     ; &16AC: C9 07
    BNE FreeDestroyedUnitSlot                    ; &16AE: D0 23
    LDA UnitXHi,X                  ; &16B0: BD 25 04
    STA XMinInit+SWARMER                    ; &16B3: 8D 6B 2F
    LDA UnitYHi,X                  ; &16B6: BD 6F 04
    SEC                          ; &16B9: 38
    SBC #&08                     ; &16BA: E9 08
    STA YMinInit+SWARMER                    ; &16BC: 8D 7B 2F
    JSR RandomByte               ; &16BF: 20 12 22
    AND #&07                     ; &16C2: 29 07
    CLC                          ; &16C4: 18
    ADC #&05                     ; &16C5: 69 05
    STA SpawnCount+SWARMER                    ; &16C7: 8D 63 2F
    TXA                          ; &16CA: 8A
    PHA                          ; &16CB: 48
    LDA #&85                     ; &16CC: A9 85
    JSR SpawnUnit                ; &16CE: 20 DE 16
    PLA                          ; &16D1: 68
    TAX                          ; &16D2: AA

FreeDestroyedUnitSlot:
    LDA #&FF                     ; &16D3: A9 FF
    STA UnitType,X                  ; &16D5: 9D BC 05
    CLC                          ; &16D8: 18
    RTS                          ; &16D9: 60

ReturnEraseAlreadyUpdating:
    PLA                          ; &16DA: 68
    TAX                          ; &16DB: AA
    SEC                          ; &16DC: 38
    RTS                          ; &16DD: 60

SpawnUnit:
; Spawn one or more units of type A using SpawnCount and the per-type X/Y and
; velocity initialisation tables.  The high bit of A controls whether spawning
; advances gameplay frames while searching for free slots.
    STA SpawnSpriteType                    ; &16DE: 8D 27 2F
    AND #&7F                     ; &16E1: 29 7F
    TAY                          ; &16E3: A8
    LDA SpawnCount,Y                  ; &16E4: B9 5E 2F
    BEQ ReturnSpawnUnit                    ; &16E7: F0 48
    STA GeneralCount                    ; &16E9: 8D 12 2F
    CPY #&01                     ; &16EC: C0 01
    BNE SpawnNextRequestedUnit                    ; &16EE: D0 07
    LDA HumanCount                    ; &16F0: AD 15 2F
    BNE SpawnNextRequestedUnit                    ; &16F3: D0 02
    LDY #&02                     ; &16F5: A0 02

SpawnNextRequestedUnit:
    JSR MaybeRunFrameDuringSpawn                    ; &16F7: 20 32 17
    LDX #&02                     ; &16FA: A2 02
ProbeSpawnSlot:
    LDA UnitType,X                  ; &16FC: BD BC 05
    ASL A                        ; &16FF: 0A
    BPL AdvanceSpawnSlotProbe                    ; &1700: 10 19
    TYA                          ; &1702: 98
    ORA #&80                     ; &1703: 09 80
    STA UnitType,X                  ; &1705: 9D BC 05
    JSR InitialiseUnit           ; &1708: 20 6C 17
    CPY #&03                     ; &170B: C0 03
    BEQ CountSpawnedEnemy                    ; &170D: F0 07
    CPY #&06                     ; &170F: C0 06
    BEQ CountSpawnedEnemy                    ; &1711: F0 03
    INC EnemyCount                    ; &1713: EE 13 2F

CountSpawnedEnemy:
    DEC GeneralCount                    ; &1716: CE 12 2F
    BEQ ReturnSpawnUnit                    ; &1719: F0 16

AdvanceSpawnSlotProbe:
    TXA                          ; &171B: 8A
    CLC                          ; &171C: 18
    ADC #&05                     ; &171D: 69 05
    TAX                          ; &171F: AA
    CPX #&20                     ; &1720: E0 20
    BCC ProbeSpawnSlot                    ; &1722: 90 D8
    SEC                          ; &1724: 38
    SBC #&1D                     ; &1725: E9 1D
    TAX                          ; &1727: AA
    CPX #&07                     ; &1728: E0 07
    BNE ProbeSpawnSlot                    ; &172A: D0 D0
    BIT SpawnSpriteType                    ; &172C: 2C 27 2F
    BPL SpawnNextRequestedUnit                    ; &172F: 10 C6

ReturnSpawnUnit:
    RTS                          ; &1731: 60

MaybeRunFrameDuringSpawn:
    LDA SpawnSpriteType                    ; &1732: AD 27 2F
    BMI ReturnSpawnFrameHelper                    ; &1735: 30 14
    PHA                          ; &1737: 48
    LDA GeneralCount                    ; &1738: AD 12 2F
    PHA                          ; &173B: 48
    TYA                          ; &173C: 98
    PHA                          ; &173D: 48
    JSR GameFrameChecked                    ; &173E: 20 21 1A
    PLA                          ; &1741: 68
    TAY                          ; &1742: A8
    PLA                          ; &1743: 68
    STA GeneralCount                    ; &1744: 8D 12 2F
    PLA                          ; &1747: 68
    STA SpawnSpriteType                    ; &1748: 8D 27 2F

ReturnSpawnFrameHelper:
    RTS                          ; &174B: 60

UpdateBaiterTimer:
    DEC BaitDelayLo                    ; &174C: CE 18 2F
    BNE ReturnBaiterTimer                    ; &174F: D0 1A
    DEC BaitDelayHi                    ; &1751: CE 19 2F
    BNE ReturnBaiterTimer                    ; &1754: D0 15
    LDA #&01                     ; &1756: A9 01
    STA SpawnCount+BAITER                    ; &1758: 8D 61 2F
    LDA UnitXHi                    ; &175B: AD 25 04
    STA XMinInit+BAITER                    ; &175E: 8D 69 2F
    LDA #&83                     ; &1761: A9 83
    JSR SpawnUnit                ; &1763: 20 DE 16
    LDA #&02                     ; &1766: A9 02
    STA BaitDelayHi                    ; &1768: 8D 19 2F

ReturnBaiterTimer:
    RTS                          ; &176B: 60

InitialiseUnit:
; Initialise one occupied unit slot: clear transient data, optionally enable
; warp-in animation using DoWarpTable, choose random X/Y from per-type ranges,
; and generate signed fixed-point X/Y velocities.
    LDA UnitType,X                  ; &176C: BD BC 05
    ASL A                        ; &176F: 0A
    PHP                          ; &1770: 08
    LSR A                        ; &1771: 4A
    TAY                          ; &1772: A8
    JSR ClearUnitData                    ; &1773: 20 20 24
    STA UnitRadarPtrHi,X                  ; &1776: 9D 26 06
    PLP                          ; &1779: 28
    BPL InitialiseWarpIfRequired                    ; &177A: 10 01
    RTS                          ; &177C: 60

InitialiseWarpIfRequired:
    LDA DoWarpTable,Y                  ; &177D: B9 58 2B
    BEQ ChooseRandomSpawnPosition                    ; &1780: F0 0A
    LDA #&01                     ; &1782: A9 01
    STA UnitAnim,X                  ; &1784: 9D 46 06
    LDA #&08                     ; &1787: A9 08
    STA UnitParam,X                  ; &1789: 9D E1 05

ChooseRandomSpawnPosition:
    JSR RandomByte               ; &178C: 20 12 22
    AND XRangeInit,Y                  ; &178F: 39 6E 2F
    CLC                          ; &1792: 18
    ADC XMinInit,Y                  ; &1793: 79 66 2F
    STA UnitXHi,X                  ; &1796: 9D 25 04
    JSR RandomByte               ; &1799: 20 12 22
    AND YRangeInit,Y                  ; &179C: 39 7E 2F
    CLC                          ; &179F: 18
    ADC YMinInit,Y                  ; &17A0: 79 76 2F
    CMP #&C0                     ; &17A3: C9 C0
    BCC StoreSpawnY                    ; &17A5: 90 02
    SBC #&C0                     ; &17A7: E9 C0

StoreSpawnY:
    STA UnitYHi,X                  ; &17A9: 9D 6F 04

InitialiseUnitVelocity:
; Choose random X and Y velocity magnitudes from the per-type tables and turn
; them into signed fixed-point values using ScaleSignedDeltaBy8.
    JSR RandomByte               ; &17AC: 20 12 22
    AND DXRangeInit,Y                  ; &17AF: 39 8E 2F
    CLC                          ; &17B2: 18
    ADC DXMinInit,Y                  ; &17B3: 79 86 2F
    JSR StoreSignedInitialVelocity                    ; &17B6: 20 D7 17
    STA UnitDXLo,X                  ; &17B9: 9D 94 04
    LDA TempHi                      ; &17BC: A5 77
    STA UnitDXHi,X                  ; &17BE: 9D B9 04
    JSR RandomByte               ; &17C1: 20 12 22
    AND DYRangeInit,Y                  ; &17C4: 39 9E 2F
    CLC                          ; &17C7: 18
    ADC DYMinInit,Y                  ; &17C8: 79 96 2F
    JSR StoreSignedInitialVelocity                    ; &17CB: 20 D7 17
    STA UnitDYLo,X                  ; &17CE: 9D DE 04
    LDA TempHi                      ; &17D1: A5 77
    STA UnitDYHi,X                  ; &17D3: 9D 03 05
    RTS                          ; &17D6: 60

StoreSignedInitialVelocity:
    STA TempLo                      ; &17D7: 85 76
    LDA #&00                     ; &17D9: A9 00
    STA TempHi                      ; &17DB: 85 77
    JSR RandomByte               ; &17DD: 20 12 22
    BPL StoreInitialYVelocity                    ; &17E0: 10 0B
    SEC                          ; &17E2: 38
    LDA #&00                     ; &17E3: A9 00
    SBC TempLo                      ; &17E5: E5 76
    STA TempLo                      ; &17E7: 85 76
    BCS StoreInitialYVelocity                    ; &17E9: B0 02
    DEC TempHi                      ; &17EB: C6 77

StoreInitialYVelocity:
    LDA TempLo                      ; &17ED: A5 76
    ASL A                        ; &17EF: 0A
    ROL TempHi                      ; &17F0: 26 77
    ASL A                        ; &17F2: 0A
    ROL TempHi                      ; &17F3: 26 77
    ASL A                        ; &17F5: 0A
    ROL TempHi                      ; &17F6: 26 77
    RTS                          ; &17F8: 60

SpawnWaveUnits:
; Spawn the configured counts for the ordinary gameplay types using the current
; SpawnCount table.
    LDX #&01                     ; &17F9: A2 01
SpawnWaveUnitLoop:
    TXA                          ; &17FB: 8A
    PHA                          ; &17FC: 48
    JSR SpawnUnit                ; &17FD: 20 DE 16
    PLA                          ; &1800: 68
    TAX                          ; &1801: AA
    INX                          ; &1802: E8
    CPX #&08                     ; &1803: E0 08
    BNE SpawnWaveUnitLoop                    ; &1805: D0 F4
    RTS                          ; &1807: 60

UseSmartBomb:
; Consume one BCD smart bomb if available, refresh its HUD value, then run two
; detonation passes over enemy slots.  The two passes distinguish visual/update
; handling while killing eligible enemies.
    LDA SmartBombsBCD                    ; &1808: AD 38 2F
    BNE ConsumeSmartBomb                    ; &180B: D0 01
    RTS                          ; &180D: 60

ConsumeSmartBomb:
    SED                          ; &180E: F8
    SEC                          ; &180F: 38
    LDA SmartBombsBCD                    ; &1810: AD 38 2F
    SBC #&01                     ; &1813: E9 01
    STA SmartBombsBCD                    ; &1815: 8D 38 2F
    CLD                          ; &1818: D8
    LDX #&00                     ; &1819: A2 00
    LDY #&00                     ; &181B: A0 00
    JSR AddScoreBCD              ; &181D: 20 CA 24
    LDA #&00                     ; &1820: A9 00
    JSR RunSecondSmartBombPass                    ; &1822: 20 27 18
    LDA #&01                     ; &1825: A9 01

RunSecondSmartBombPass:
    STA SmartBombPass2                    ; &1827: 8D 3B 2F
    LDA #&07                     ; &182A: A9 07
    STA BackgroundPalette                    ; &182C: 8D 0F 2F
    LDX #&02                     ; &182F: A2 02
    JSR DoGameFrames                    ; &1831: 20 6A 26
    JSR SmartBombKillPass        ; &1834: 20 42 18
    LDA #&00                     ; &1837: A9 00
    STA BackgroundPalette                    ; &1839: 8D 0F 2F
    LDX #&02                     ; &183C: A2 02
    JSR DoGameFrames                    ; &183E: 20 6A 26
    RTS                          ; &1841: 60

SmartBombKillPass:
    LDX #&02                     ; &1842: A2 02
ScanNextSmartBombUnit:
    LDA UnitType,X                  ; &1844: BD BC 05
    ASL A                        ; &1847: 0A
    BMI AdvanceSmartBombScan                    ; &1848: 30 34
    LSR A                        ; &184A: 4A
    CMP #&06                     ; &184B: C9 06
    BEQ AdvanceSmartBombScan                    ; &184D: F0 2F
    LDA UnitAnim,X                  ; &184F: BD 46 06
    BNE AdvanceSmartBombScan                    ; &1852: D0 2A
    LDA UnitSpritePtrHi,X                  ; &1854: BD 4D 05
    BNE DetonateSmartBombUnit                    ; &1857: D0 1F
    LDA SmartBombPass2                    ; &1859: AD 3B 2F
    BEQ AdvanceSmartBombScan                    ; &185C: F0 20
    LDA UnitType,X                  ; &185E: BD BC 05
    AND #&7F                     ; &1861: 29 7F
    CMP #&05                     ; &1863: C9 05
    BNE AdvanceSmartBombScan                    ; &1865: D0 17
    JSR GetUnitScreenX                    ; &1867: 20 3B 20
    CMP #&50                     ; &186A: C9 50
    BCS AdvanceSmartBombScan                    ; &186C: B0 10
    LDA UnitXHi,X                  ; &186E: BD 25 04
    EOR #&80                     ; &1871: 49 80
    STA UnitXHi,X                  ; &1873: 9D 25 04
    BNE AdvanceSmartBombScan                    ; &1876: D0 06

DetonateSmartBombUnit:
    JSR ScoreUnit                 ; &1878: 20 4D 24
    JSR DestroyUnit              ; &187B: 20 23 16

AdvanceSmartBombScan:
    INX                          ; &187E: E8
    CPX #&20                     ; &187F: E0 20
    BNE ScanNextSmartBombUnit                    ; &1881: D0 C1
    RTS                          ; &1883: 60

HandleHyperspace:
; Hyperspace control and effect.  The key/probability table at &2A78 is used to
; select the random exit/failure behaviour; the playfield is rebuilt afterward.
    LDX #&06                     ; &1884: A2 06
ScanHyperspaceKeyLoop:
    STX SavedX                      ; &1886: 86 85
    LDA HyperspaceKeys,X                  ; &1888: BD 78 2A
    TAX                          ; &188B: AA
    JSR ScanInkey                    ; &188C: 20 5A 1C
    BNE BeginHyperspace                    ; &188F: D0 06
    LDX SavedX                      ; &1891: A6 85
    DEX                          ; &1893: CA
    BPL ScanHyperspaceKeyLoop                    ; &1894: 10 F0
ReturnFromHyperspaceCheck:
    RTS                          ; &1896: 60

BeginHyperspace:
    BIT UnitAnim                    ; &1897: 2C 46 06
    BVS ReturnFromHyperspaceCheck                    ; &189A: 70 FA
    LDA UnitParam                    ; &189C: AD E1 05
    CMP #&05                     ; &189F: C9 05
    BCS ReturnFromHyperspaceCheck                    ; &18A1: B0 F3
    JSR RandomByte               ; &18A3: 20 12 22
    JSR NewScreen                    ; &18A6: 20 20 23
    JSR RandomByte               ; &18A9: 20 12 22
    LDX #&01                     ; &18AC: A2 01
    CMP #&28                     ; &18AE: C9 28
    BCS FinishHyperspace                    ; &18B0: B0 02
    LDX #&41                     ; &18B2: A2 41

FinishHyperspace:
    STX UnitAnim                    ; &18B4: 8E 46 06
    LDA #&08                     ; &18B7: A9 08
    STA UnitParam                    ; &18B9: 8D E1 05
    RTS                          ; &18BC: 60

FrameNoDeathCheck:
; Execute a frame without immediately branching into player-death handling.
; If the final human has gone while the planet still exists, run the planet-
; destruction palette sequence and convert the remaining Landers to Mutants;
; then fall through to the normal GameFrame workload.
    LDA NoPlanet                    ; &18BD: AD 1A 2F
    ORA HumanCount                    ; &18C0: 0D 15 2F
    BNE ReturnPlanetDestructionCheck                    ; &18C3: D0 26
    LDA #&01                     ; &18C5: A9 01
    STA NoPlanet                    ; &18C7: 8D 1A 2F
ScanPlanetDestructionStateLoop:
    INY                          ; &18CA: C8
    TYA                          ; &18CB: 98
    AND #&07                     ; &18CC: 29 07
    PHA                          ; &18CE: 48
    TAY                          ; &18CF: A8
    LDA FlashPalette,Y                  ; &18D0: B9 70 2A
    AND #&0F                     ; &18D3: 29 0F
    STA BackgroundPalette                    ; &18D5: 8D 0F 2F
    LDX #&03                     ; &18D8: A2 03
    JSR DoGameFrames                    ; &18DA: 20 6A 26
    LDA #&00                     ; &18DD: A9 00
    STA BackgroundPalette                    ; &18DF: 8D 0F 2F
    LDX #&04                     ; &18E2: A2 04
    JSR DoGameFrames                    ; &18E4: 20 6A 26
    PLA                          ; &18E7: 68
    TAY                          ; &18E8: A8
    BNE ScanPlanetDestructionStateLoop                    ; &18E9: D0 DF

ReturnPlanetDestructionCheck:
    JMP GameFrame                ; &18EB: 4C 75 26

EnemyShootChance:
; Random firing gate for an enemy.  If the chance test succeeds, select a free
; projectile slot and aim a fixed-point shot at the ship.
    STA TempLo                      ; &18EE: 85 76
    LDA PlayerDead                    ; &18F0: AD 24 2F
    BEQ EnemyFireGatePassed                    ; &18F3: F0 01
    RTS                          ; &18F5: 60

EnemyFireGatePassed:
    JSR RandomByte               ; &18F6: 20 12 22
    CMP TempLo                      ; &18F9: C5 76
    BCS ReturnEnemyShoot                    ; &18FB: B0 19
    SEC                          ; &18FD: 38
    LDA UnitXHi                    ; &18FE: AD 25 04
    SBC UnitXHi,X                  ; &1901: FD 25 04
    BPL AllocateEnemyProjectile                    ; &1904: 10 07
    STA TempLo                      ; &1906: 85 76
    SEC                          ; &1908: 38
    LDA #&00                     ; &1909: A9 00
    SBC TempLo                      ; &190B: E5 76

AllocateEnemyProjectile:
    CMP #&28                     ; &190D: C9 28
    BCS ReturnEnemyShoot                    ; &190F: B0 05
    JSR FindProjectileSlot                    ; &1911: 20 DA 19
    BCC LaunchEnemyProjectile                    ; &1914: 90 01

ReturnEnemyShoot:
    RTS                          ; &1916: 60

LaunchEnemyProjectile:
    LDA #&08                     ; &1917: A9 08
    JSR PlaySound                ; &1919: 20 7D 12

AimAtShip:
; Construct signed X/Y projectile velocity components aimed from the current
; enemy toward the ship; EnemyShotSpeed scales the result.
    SEC                          ; &191C: 38
    LDA UnitXHi                    ; &191D: AD 25 04
    SBC UnitXHi,X                  ; &1920: FD 25 04
    JSR ScaleSignedDeltaBy8                    ; &1923: 20 C7 19
    STA SourcePtrHi                      ; &1926: 85 73
    CLC                          ; &1928: 18
    LDA TempLo                      ; &1929: A5 76
    STA SourcePtrLo                      ; &192B: 85 72
    ADC UnitDXLo                    ; &192D: 6D 94 04
    STA UnitDXLo,Y                  ; &1930: 99 94 04
    LDA TempHi                      ; &1933: A5 77
    ADC UnitDXHi                    ; &1935: 6D B9 04
    STA UnitDXHi,Y                  ; &1938: 99 B9 04
    SEC                          ; &193B: 38
    LDA UnitYHi                    ; &193C: AD 6F 04
    SBC UnitYHi,X                  ; &193F: FD 6F 04
    JSR ScaleSignedDeltaBy8                    ; &1942: 20 C7 19
    STA DestPtrHi                      ; &1945: 85 71
    STA UnitDYHi,Y                  ; &1947: 99 03 05
    LDA TempLo                      ; &194A: A5 76
    STA DestPtrLo                      ; &194C: 85 70
    STA UnitDYLo,Y                  ; &194E: 99 DE 04
LimitProjectileAimVelocity:
    LDA UnitDYHi,Y                  ; &1951: B9 03 05
    CMP #&03                     ; &1954: C9 03
    BCC ValidateProjectileXVelocity                    ; &1956: 90 04
    CMP #&FE                     ; &1958: C9 FE
    BCC ReturnAimAtShip                    ; &195A: 90 45

ValidateProjectileXVelocity:
    LDA UnitDXHi,Y                  ; &195C: B9 B9 04
    BEQ ApplyProjectileAimCorrection                    ; &195F: F0 0D
    CMP #&FF                     ; &1961: C9 FF
    BNE ReturnAimAtShip                    ; &1963: D0 3C
    SEC                          ; &1965: 38
    LDA #&00                     ; &1966: A9 00
    SBC UnitDXLo,Y                  ; &1968: F9 94 04
    JMP ClampProjectileAimCorrection                    ; &196B: 4C 77 19

ApplyProjectileAimCorrection:
    LDA SourcePtrLo                      ; &196E: A5 72
    ORA SourcePtrHi                      ; &1970: 05 73
    BEQ ReturnAimAtShip                    ; &1972: F0 2D
    LDA UnitDXLo,Y                  ; &1974: B9 94 04

ClampProjectileAimCorrection:
    CMP EnemyShotSpeed                    ; &1977: CD 3A 2F
    BCS ReturnAimAtShip                    ; &197A: B0 25
    CLC                          ; &197C: 18
    LDA UnitDXLo,Y                  ; &197D: B9 94 04
    ADC SourcePtrLo                      ; &1980: 65 72
    STA UnitDXLo,Y                  ; &1982: 99 94 04
    LDA UnitDXHi,Y                  ; &1985: B9 B9 04
    ADC SourcePtrHi                      ; &1988: 65 73
    STA UnitDXHi,Y                  ; &198A: 99 B9 04
    CLC                          ; &198D: 18
    LDA UnitDYLo,Y                  ; &198E: B9 DE 04
    ADC DestPtrLo                      ; &1991: 65 70
    STA UnitDYLo,Y                  ; &1993: 99 DE 04
    LDA UnitDYHi,Y                  ; &1996: B9 03 05
    ADC DestPtrHi                      ; &1999: 65 71
    STA UnitDYHi,Y                  ; &199B: 99 03 05
    JMP LimitProjectileAimVelocity                    ; &199E: 4C 51 19

ReturnAimAtShip:
    RTS                          ; &19A1: 60
    EQUB &A9,&08,&4C,&7D,&12 ; &19A2

BomberMineChance:
; Bomber-specific random mine-release test; on success it allocates and
; initialises a projectile/mine slot from the Bomber's current position.
    LDA UnitNextPtrHi,X                  ; &19A7: BD 97 05
    BEQ ReturnBomberMine                    ; &19AA: F0 1A
    JSR RandomByte               ; &19AC: 20 12 22
    CMP #&3C                     ; &19AF: C9 3C
    BCS ReturnBomberMine                    ; &19B1: B0 13
    JSR FindFreeUnitSlot         ; &19B3: 20 DE 19
    BCS ReturnBomberMine                    ; &19B6: B0 0E
    LDA #&00                     ; &19B8: A9 00
    STA UnitDYLo,Y                  ; &19BA: 99 DE 04
    STA UnitDYHi,Y                  ; &19BD: 99 03 05
    STA UnitDXLo,Y                  ; &19C0: 99 94 04
    STA UnitDXHi,Y                  ; &19C3: 99 B9 04

ReturnBomberMine:
    RTS                          ; &19C6: 60

ScaleSignedDeltaBy8:
    STA TempLo                      ; &19C7: 85 76
    PHP                          ; &19C9: 08
    LDA #&00                     ; &19CA: A9 00
    PLP                          ; &19CC: 28
    BPL ScaleSignedDeltaBody                    ; &19CD: 10 02
    LDA #&FF                     ; &19CF: A9 FF

ScaleSignedDeltaBody:
    ASL TempLo                      ; &19D1: 06 76
    ROL A                        ; &19D3: 2A
    ASL TempLo                      ; &19D4: 06 76
    ROL A                        ; &19D6: 2A
    STA TempHi                      ; &19D7: 85 77
    RTS                          ; &19D9: 60

FindProjectileSlot:
    LDY #&20                     ; &19DA: A0 20
    BNE TryProjectileSlot                    ; &19DC: D0 02

FindFreeUnitSlot:
; Find a free unit slot in the requested allocation range.  Returns carry
; according to allocation success and preserves the current shooter where needed.
    LDY #&22                     ; &19DE: A0 22
TryProjectileSlot:
    JSR SpawnProjectileFromUnit                    ; &19E0: 20 EB 19
    BCC ReturnFindProjectileSlot                    ; &19E3: 90 05
    INY                          ; &19E5: C8
    CPY #&25                     ; &19E6: C0 25
    BNE TryProjectileSlot                    ; &19E8: D0 F6

ReturnFindProjectileSlot:
    RTS                          ; &19EA: 60

SpawnProjectileFromUnit:
    LDA UnitType,Y                  ; &19EB: B9 BC 05
    EOR #&C0                     ; &19EE: 49 C0
    ASL A                        ; &19F0: 0A
    ASL A                        ; &19F1: 0A
    BCS ReturnSpawnProjectile                    ; &19F2: B0 2C
    LDA #&88                     ; &19F4: A9 88
    STA UnitType,Y                  ; &19F6: 99 BC 05
    LDA UnitXLo,X                  ; &19F9: BD 00 04
    STA UnitXLo,Y                  ; &19FC: 99 00 04
    CLC                          ; &19FF: 18
    LDA UnitXHi,X                  ; &1A00: BD 25 04
    ADC #&01                     ; &1A03: 69 01
    STA UnitXHi,Y                  ; &1A05: 99 25 04
    LDA UnitYLo,X                  ; &1A08: BD 4A 04
    STA UnitYLo,Y                  ; &1A0B: 99 4A 04
    SEC                          ; &1A0E: 38
    LDA UnitYHi,X                  ; &1A0F: BD 6F 04
    SBC #&04                     ; &1A12: E9 04
    STA UnitYHi,Y                  ; &1A14: 99 6F 04
    LDA #&00                     ; &1A17: A9 00
    STA UnitParam,Y                  ; &1A19: 99 E1 05
    STA UnitAnim,Y                  ; &1A1C: 99 46 06
    CLC                          ; &1A1F: 18

ReturnSpawnProjectile:
    RTS                          ; &1A20: 60

GameFrameChecked:
; One logical game frame with player-death handling: edge-scan TAB for Smart
; Bomb, process hyperspace, execute FrameNoDeathCheck, then enter the death
; sequence if PlayerDead became nonzero.
    LDX #&9F                     ; &1A21: A2 9F
    JSR ScanInkey                    ; &1A23: 20 5A 1C
    BEQ StoreTabKeyLatch                    ; &1A26: F0 03
    EOR TabKeyLatch                    ; &1A28: 4D 0E 2F

StoreTabKeyLatch:
    STX TabKeyLatch                    ; &1A2B: 8E 0E 2F
    BEQ RunNormalCheckedFrame                    ; &1A2E: F0 03
    JSR UseSmartBomb             ; &1A30: 20 08 18

RunNormalCheckedFrame:
    JSR HandleHyperspace         ; &1A33: 20 84 18
    JSR FrameNoDeathCheck                    ; &1A36: 20 BD 18
    LDA PlayerDead                    ; &1A39: AD 24 2F
    BNE BeginPlayerDeathSequence                    ; &1A3C: D0 01
    RTS                          ; &1A3E: 60

BeginPlayerDeathSequence:
    LDA #&07                     ; &1A3F: A9 07
    STA BackgroundPalette                    ; &1A41: 8D 0F 2F
    JSR GameFrame                ; &1A44: 20 75 26
    LDA #&00                     ; &1A47: A9 00
    STA BackgroundPalette                    ; &1A49: 8D 0F 2F
    LDX #&32                     ; &1A4C: A2 32
    JSR DoGameFrames                    ; &1A4E: 20 6A 26
    LDX #&00                     ; &1A51: A2 00
    STX PlayerDead                    ; &1A53: 8E 24 2F
    JSR EraseUnit                ; &1A56: 20 64 16
    LDA #&0C                     ; &1A59: A9 0C
    JSR PlaySound                ; &1A5B: 20 7D 12
    LDX #&1F                     ; &1A5E: A2 1F
ProcessNextDeathUnit:
    JSR ClearUnitScreenPointers                    ; &1A60: 20 28 24
    LDA UnitType,X                  ; &1A63: BD BC 05
    STA UnitParam,X                  ; &1A66: 9D E1 05
    LDA UnitAnim,X                  ; &1A69: BD 46 06
    STA UnitRadarPtrLo,X                  ; &1A6C: 9D 06 06
    LDA #&80                     ; &1A6F: A9 80
    STA UnitType,X                  ; &1A71: 9D BC 05
    LDA #&00                     ; &1A74: A9 00
    STA UnitAnim,X                  ; &1A76: 9D 46 06
    STA UnitRadarPtrHi,X                  ; &1A79: 9D 26 06
    LDA UnitXHi                    ; &1A7C: AD 25 04
    CLC                          ; &1A7F: 18
    ADC #&02                     ; &1A80: 69 02
    STA UnitXHi,X                  ; &1A82: 9D 25 04
    LDA UnitXLo                    ; &1A85: AD 00 04
    STA UnitXLo,X                  ; &1A88: 9D 00 04
    LDA UnitYHi                    ; &1A8B: AD 6F 04
    STA UnitYHi,X                  ; &1A8E: 9D 6F 04
    LDA UnitYLo                    ; &1A91: AD 4A 04
    STA UnitYLo,X                  ; &1A94: 9D 4A 04
    LDY #&00                     ; &1A97: A0 00
    JSR InitialiseUnitVelocity                    ; &1A99: 20 AC 17
    DEX                          ; &1A9C: CA
    BPL ProcessNextDeathUnit                    ; &1A9D: 10 C1
    ; Original stored the sprite address as literal bytes &2DBA.  Keep it symbolic
    ; so code/data inserted earlier can move the graphics safely.
    LDA #<ShrapnelSprite        ; original &1A9F: A9 BA
    STA SpritePtrLoTable                    ; &1AA1: 8D 0B 2B
    LDA #>ShrapnelSprite        ; original &1AA4: A9 2D
    STA SpritePtrHiTable                    ; &1AA6: 8D 16 2B
    LDA #&04                     ; &1AA9: A9 04
    STA SpriteLengths                    ; &1AAB: 8D 00 2B
    LDA AIBatchSize                    ; &1AAE: AD 25 2F
    PHA                          ; &1AB1: 48
    LDA #&1E                     ; &1AB2: A9 1E
    STA AIBatchSize                    ; &1AB4: 8D 25 2F
    LDX #&3C                     ; &1AB7: A2 3C
DeathExplosionFrameLoop:
    TXA                          ; &1AB9: 8A
    PHA                          ; &1ABA: 48
    JSR UpdateUnitAIBatch        ; &1ABB: 20 44 0E
    JSR NextFrame                    ; &1ABE: 20 37 1D
    JSR RepaintAllUnits                    ; &1AC1: 20 5B 20
    PLA                          ; &1AC4: 68
    TAX                          ; &1AC5: AA
    CPX #&12                     ; &1AC6: E0 12
    BNE ContinueDeathExplosionFrames                    ; &1AC8: D0 05
    LDA #&F1                     ; &1ACA: A9 F1
    JSR WritePaletteColour       ; &1ACC: 20 25 0E

ContinueDeathExplosionFrames:
    DEX                          ; &1ACF: CA
    BNE DeathExplosionFrameLoop                    ; &1AD0: D0 E7
    LDX #&1F                     ; &1AD2: A2 1F
WaitForDeathAnimationLoop:
    LDA UnitParam,X                  ; &1AD4: BD E1 05
    STA UnitType,X                  ; &1AD7: 9D BC 05
    LDA UnitRadarPtrLo,X                  ; &1ADA: BD 06 06
    STA UnitAnim,X                  ; &1ADD: 9D 46 06
    DEX                          ; &1AE0: CA
    BPL WaitForDeathAnimationLoop                    ; &1AE1: 10 F1
    PLA                          ; &1AE3: 68
    STA AIBatchSize                    ; &1AE4: 8D 25 2F
    LDX #&64                     ; &1AE7: A2 64
    JSR DelayVSyncFrames                    ; &1AE9: 20 EF 1B
    SED                          ; &1AEC: F8
    SEC                          ; &1AED: 38
    LDA LivesBCD                    ; &1AEE: AD 37 2F
    SBC #&01                     ; &1AF1: E9 01
    STA LivesBCD                    ; &1AF3: 8D 37 2F
    CLD                          ; &1AF6: D8
    LDA LevelStillSpawning                    ; &1AF7: AD 44 2F
    ORA EnemyCount                    ; &1AFA: 0D 13 2F
    BEQ UnwindCompletedLevel                    ; &1AFD: F0 0A
    LDA LivesBCD                    ; &1AFF: AD 37 2F
    BNE ContinueAfterPlayerDeath                    ; &1B02: D0 0A
    LDX GameOverStackPointer                    ; &1B04: AE 39 2F
    TXS                          ; &1B07: 9A
    RTS                          ; &1B08: 60

UnwindCompletedLevel:
    LDX NextLevelStackPointer                    ; &1B09: AE 43 2F
    TXS                          ; &1B0C: 9A
    RTS                          ; &1B0D: 60

ContinueAfterPlayerDeath:
    JSR ContinueCurrentLevel                    ; &1B0E: 20 EE 22
    LDX #&32                     ; &1B11: A2 32
    JSR DelayVSyncFrames                    ; &1B13: 20 EF 1B
    RTS                          ; &1B16: 60

PlayLevel:
; Play one level.  Save a stack return point used by death/level-completion
; unwinding, seed humans, delay briefly, spawn the configured wave in staged
; squads, then run frames until EnemyCount reaches zero.
    TSX                          ; &1B17: BA
    STX NextLevelStackPointer                    ; &1B18: 8E 43 2F
    LDA #&01                     ; &1B1B: A9 01
    STA LevelStillSpawning                    ; &1B1D: 8D 44 2F
    LDA #&06                     ; &1B20: A9 06
    JSR SpawnUnit                ; &1B22: 20 DE 16
    LDA #&00                     ; &1B25: A9 00
    STA SpawnCount+HUMAN                    ; &1B27: 8D 64 2F
    LDX #&14                     ; &1B2A: A2 14
    JSR DoGameFrames                    ; &1B2C: 20 6A 26
    JSR SpawnWaveUnits           ; &1B2F: 20 F9 17
    JSR SpawnSquadAfterDelay                    ; &1B32: 20 50 1B
    JSR SpawnSquadAfterDelay                    ; &1B35: 20 50 1B
    LDA LevelBCD                    ; &1B38: AD 16 2F
    CMP #&06                     ; &1B3B: C9 06
    BCC RunLevelUntilEnemiesGone                    ; &1B3D: 90 03
    JSR SpawnSquadAfterDelay                    ; &1B3F: 20 50 1B

RunLevelUntilEnemiesGone:
    LDA #&00                     ; &1B42: A9 00
    STA LevelStillSpawning                    ; &1B44: 8D 44 2F
LevelEnemyWaitLoop:
    JSR GameFrameChecked                    ; &1B47: 20 21 1A
    LDA EnemyCount                    ; &1B4A: AD 13 2F
    BNE LevelEnemyWaitLoop                    ; &1B4D: D0 F8
    RTS                          ; &1B4F: 60

SpawnSquadAfterDelay:
; Run frames until either enemies/humans disappear or the squad delay expires,
; then inject another Lander squad.  Called twice on early levels and a third
; time from level 6 onward.
    LDA #&00                     ; &1B50: A9 00
    STA FrameCounterLo                    ; &1B52: 8D 10 2F
    STA FrameCounterHi                    ; &1B55: 8D 11 2F
SquadDelayFrameLoop:
    JSR GameFrameChecked                    ; &1B58: 20 21 1A
    LDA EnemyCount                    ; &1B5B: AD 13 2F
    BEQ SpawnDelayedLander                    ; &1B5E: F0 15
    LDA HumanCount                    ; &1B60: AD 15 2F
    BEQ SpawnDelayedLander                    ; &1B63: F0 10
    INC FrameCounterLo                    ; &1B65: EE 10 2F
    BNE CheckSquadDelay                    ; &1B68: D0 03
    INC FrameCounterHi                    ; &1B6A: EE 11 2F

CheckSquadDelay:
    LDA FrameCounterHi                    ; &1B6D: AD 11 2F
    CMP SquadDelayHigh                    ; &1B70: CD 14 2F
    BNE SquadDelayFrameLoop                    ; &1B73: D0 E3

SpawnDelayedLander:
    LDA #&01                     ; &1B75: A9 01
    JSR SpawnUnit                ; &1B77: 20 DE 16
    RTS                          ; &1B7A: 60

SetSurfacePaletteGreen:
    TXA                          ; &1B7B: 8A
    PHA                          ; &1B7C: 48
    LDA #&60                     ; &1B7D: A9 60
    STA SurfacePalette                    ; &1B7F: 8D 42 2F
    JSR WritePaletteColour       ; &1B82: 20 25 0E
    PLA                          ; &1B85: 68
    TAX                          ; &1B86: AA
    RTS                          ; &1B87: 60

AwardLevelHumanBonus:
; Level-complete screen.  Show level and per-human bonus, then animate each
; surviving human onto the display and add HumanBonusBCD points for each one.
    LDA WorldLeftEdgeHi                    ; &1B88: AD 21 2F
    JSR NewScreen                    ; &1B8B: 20 20 23
    LDA #&01                     ; &1B8E: A9 01
    JSR DrawStringByIndex        ; &1B90: 20 31 24
    LDX #&28                     ; &1B93: A2 28
    LDY #&9F                     ; &1B95: A0 9F
    JSR XYToVideoPtr                    ; &1B97: 20 6D 1C
    LDA #&00                     ; &1B9A: A9 00
    STA LeadingZeroState                    ; &1B9C: 8D 33 2F
    LDA LevelBCD                    ; &1B9F: AD 16 2F
    JSR DrawBCDDigits            ; &1BA2: 20 21 25
    LDX #&2A                     ; &1BA5: A2 2A
    LDY #&87                     ; &1BA7: A0 87
    JSR XYToVideoPtr                    ; &1BA9: 20 6D 1C
    LDA #&00                     ; &1BAC: A9 00
    STA LeadingZeroState                    ; &1BAE: 8D 33 2F
    LDA HumanBonusBCD                    ; &1BB1: AD 17 2F
    JSR DrawBCDDigits            ; &1BB4: 20 21 25
    LDA #&00                     ; &1BB7: A9 00
    JSR DrawBCDDigits            ; &1BB9: 20 21 25
    LDA HumanCount                    ; &1BBC: AD 15 2F
    BEQ HoldBonusScreen                    ; &1BBF: F0 28
    STA GeneralCount                    ; &1BC1: 8D 12 2F
    LDX #&19                     ; &1BC4: A2 19
BonusDisplayDelayLoop:
    LDY #&77                     ; &1BC6: A0 77
    TXA                          ; &1BC8: 8A
    PHA                          ; &1BC9: 48
    JSR XYToVideoPtr                    ; &1BCA: 20 6D 1C
    LDX #&06                     ; &1BCD: A2 06
    JSR XorBlitSprite                    ; &1BCF: 20 B4 20
    LDY HumanBonusBCD                    ; &1BD2: AC 17 2F
    LDX #&00                     ; &1BD5: A2 00
    JSR AddScoreBCD              ; &1BD7: 20 CA 24
    LDX #&04                     ; &1BDA: A2 04
    JSR DelayVSyncFrames                    ; &1BDC: 20 EF 1B
    PLA                          ; &1BDF: 68
    CLC                          ; &1BE0: 18
    ADC #&03                     ; &1BE1: 69 03
    TAX                          ; &1BE3: AA
    DEC GeneralCount                    ; &1BE4: CE 12 2F
    BNE BonusDisplayDelayLoop                    ; &1BE7: D0 DD

HoldBonusScreen:
    LDX #&46                     ; &1BE9: A2 46
    JSR DelayVSyncFrames                    ; &1BEB: 20 EF 1B
    RTS                          ; &1BEE: 60

DelayVSyncFrames:
    TXA                          ; &1BEF: 8A
    PHA                          ; &1BF0: 48
    JSR NextFrame                    ; &1BF1: 20 37 1D
    PLA                          ; &1BF4: 68
    TAX                          ; &1BF5: AA
    DEX                          ; &1BF6: CA
    BNE DelayVSyncFrames                    ; &1BF7: D0 F6
    RTS                          ; &1BF9: 60

MainWithHighScore:
; Outer attract/game loop.  Run a GameSession, display GAME OVER, compare the
; three-byte packed-BCD score with the stored high score, update it if beaten,
; draw the high score and wait for a key before restarting.
    JSR GameSession                    ; &1BFA: 20 3F 1C
    LDA WorldLeftEdgeHi                    ; &1BFD: AD 21 2F
    JSR NewScreen                    ; &1C00: 20 20 23
    LDA #&02                     ; &1C03: A9 02
    JSR DrawStringByIndex        ; &1C05: 20 31 24
    LDX #&02                     ; &1C08: A2 02
CompareScoreByteLoop:
    LDA ScoreBCD,X                  ; &1C0A: BD 30 2F
    CMP HighScoreBCD,X                  ; &1C0D: DD 04 2F
    BCC DrawHighScore                    ; &1C10: 90 10
    BNE StoreNewHighScore                    ; &1C12: D0 03
    DEX                          ; &1C14: CA
    BPL CompareScoreByteLoop                    ; &1C15: 10 F3

StoreNewHighScore:
    LDX #&02                     ; &1C17: A2 02
StoreHighScoreByteLoop:
    LDA ScoreBCD,X                  ; &1C19: BD 30 2F
    STA HighScoreBCD,X                  ; &1C1C: 9D 04 2F
    DEX                          ; &1C1F: CA
    BPL StoreHighScoreByteLoop                    ; &1C20: 10 F7

DrawHighScore:
    LDX #&1A                     ; &1C22: A2 1A
    LDY #&E7                     ; &1C24: A0 E7
    JSR XYToVideoPtr                    ; &1C26: 20 6D 1C
    LDA #&00                     ; &1C29: A9 00
    STA LeadingZeroState                    ; &1C2B: 8D 33 2F
    LDX #&02                     ; &1C2E: A2 02
DrawHighScoreByteLoop:
    LDA HighScoreBCD,X                  ; &1C30: BD 04 2F
    JSR DrawBCDDigits            ; &1C33: 20 21 25
    DEX                          ; &1C36: CA
    BPL DrawHighScoreByteLoop                    ; &1C37: 10 F7
    JSR FlushKeyboardAndReadChar                    ; &1C39: 20 63 1C
    JMP MainWithHighScore                    ; &1C3C: 4C FA 1B

GameSession:
; One complete game session: reset lives/bombs/score, repeatedly start a new
; wave, play it and award surviving-human bonuses until LivesBCD reaches zero.
    TSX                          ; &1C3F: BA
    STX GameOverStackPointer                    ; &1C40: 8E 39 2F
    LDA #&00                     ; &1C43: A9 00
    JSR PlaySound                ; &1C45: 20 7D 12
    JSR ResetGameState           ; &1C48: 20 23 26
GameWaveLoop:
    JSR StartNextWave            ; &1C4B: 20 2C 22
    JSR PlayLevel                    ; &1C4E: 20 17 1B
    JSR AwardLevelHumanBonus                    ; &1C51: 20 88 1B
    LDA LivesBCD                    ; &1C54: AD 37 2F
    BNE GameWaveLoop                    ; &1C57: D0 F2
    RTS                          ; &1C59: 60

ScanInkey:
    LDY #&FF                     ; &1C5A: A0 FF
    LDA #&81                     ; &1C5C: A9 81
    JSR OSBYTE                    ; &1C5E: 20 F4 FF
    TXA                          ; &1C61: 8A
    RTS                          ; &1C62: 60

FlushKeyboardAndReadChar:
    LDA #&0F                     ; &1C63: A9 0F
    LDX #&01                     ; &1C65: A2 01
    JSR OSBYTE                    ; &1C67: 20 F4 FF
    JMP OSRDCH                    ; &1C6A: 4C E0 FF

XYToVideoPtr:
; Convert screen X (X register) and game Y (Y register) into a circular MODE 2
; video-RAM pointer in DestPtrLo/Hi.  MinScreenX/MaxScreenX provide clipping.
    LDA #&00                     ; &1C6D: A9 00
    STA DestPtrHi                      ; &1C6F: 85 71
    CPX MinScreenX                    ; &1C71: EC 28 2F
    BCC ReturnNullVideoPtr                    ; &1C74: 90 47
    CPX MaxScreenX                    ; &1C76: EC 29 2F
    BCS ReturnNullVideoPtr                    ; &1C79: B0 42
    TYA                          ; &1C7B: 98
    EOR #&FF                     ; &1C7C: 49 FF
    PHA                          ; &1C7E: 48
    LSR A                        ; &1C7F: 4A
    LSR A                        ; &1C80: 4A
    LSR A                        ; &1C81: 4A
    TAY                          ; &1C82: A8
    LSR A                        ; &1C83: 4A
    STA TempLo                      ; &1C84: 85 76
    LDA #&00                     ; &1C86: A9 00
    ROR A                        ; &1C88: 6A
    ADC ScreenOriginLo                    ; &1C89: 6D 08 2F
    PHP                          ; &1C8C: 08
    STA DestPtrLo                      ; &1C8D: 85 70
    TYA                          ; &1C8F: 98
    ASL A                        ; &1C90: 0A
    ADC TempLo                      ; &1C91: 65 76
    PLP                          ; &1C93: 28
    ADC ScreenOriginHi                    ; &1C94: 6D 09 2F
    STA DestPtrHi                      ; &1C97: 85 71
    LDA #&00                     ; &1C99: A9 00
    STA TempLo                      ; &1C9B: 85 76
    TXA                          ; &1C9D: 8A
    ASL A                        ; &1C9E: 0A
    ROL TempLo                      ; &1C9F: 26 76
    ASL A                        ; &1CA1: 0A
    ROL TempLo                      ; &1CA2: 26 76
    ASL A                        ; &1CA4: 0A
    ROL TempLo                      ; &1CA5: 26 76
    ADC DestPtrLo                      ; &1CA7: 65 70
    STA DestPtrLo                      ; &1CA9: 85 70
    LDA TempLo                      ; &1CAB: A5 76
    ADC DestPtrHi                      ; &1CAD: 65 71
    BPL StoreVideoPointerHigh                    ; &1CAF: 10 03
    SEC                          ; &1CB1: 38
    SBC #&50                     ; &1CB2: E9 50

StoreVideoPointerHigh:
    STA DestPtrHi                      ; &1CB4: 85 71
    PLA                          ; &1CB6: 68
    AND #&07                     ; &1CB7: 29 07
    ORA DestPtrLo                      ; &1CB9: 05 70
    STA DestPtrLo                      ; &1CBB: 85 70

ReturnNullVideoPtr:
    RTS                          ; &1CBD: 60

RawXorBlit:
; Low-level XOR bitmap blitter.  SourcePtr points to image data, DestPtr to
; circular MODE 2 RAM, ImageLength is byte count and HeightMask controls wrapping.
; PaintMask accumulates overwritten bits for collision detection.
    LDA DestPtrHi                      ; &1CBE: A5 71
    BNE BeginXorBlit                    ; &1CC0: D0 01
    RTS                          ; &1CC2: 60

BeginXorBlit:
    LDA #&00                     ; &1CC3: A9 00
    STA PaintMask                      ; &1CC5: 85 8A
    LDA ImageLength                      ; &1CC7: A5 75
    PHA                          ; &1CC9: 48
    LDY #&00                     ; &1CCA: A0 00
BlitWrappedDestinationPath:
    LDA DestPtrHi                      ; &1CCC: A5 71
    PHA                          ; &1CCE: 48
    LDA DestPtrLo                      ; &1CCF: A5 70
    PHA                          ; &1CD1: 48
    LDA DestPtrLo                      ; &1CD2: A5 70
    AND #&07                     ; &1CD4: 29 07
    STA BlitRow                      ; &1CD6: 85 74
    LDA DestPtrLo                      ; &1CD8: A5 70
    AND #&F8                     ; &1CDA: 29 F8
    STA DestPtrLo                      ; &1CDC: 85 70
BlitRowByteLoop:
    LDA (SourcePtrLo),Y                  ; &1CDE: B1 72
    PHP                          ; &1CE0: 08
    INY                          ; &1CE1: C8
    STY TempLo                      ; &1CE2: 84 76
    LDY BlitRow                      ; &1CE4: A4 74
    EOR (DestPtrLo),Y                  ; &1CE6: 51 70
    STA (DestPtrLo),Y                  ; &1CE8: 91 70
    INY                          ; &1CEA: C8
    PLP                          ; &1CEB: 28
    BEQ HandleBlitRowBoundary                    ; &1CEC: F0 04
    ORA PaintMask                      ; &1CEE: 05 8A
    STA PaintMask                      ; &1CF0: 85 8A

HandleBlitRowBoundary:
    CPY #&08                     ; &1CF2: C0 08
    BEQ AdvanceBlitToNextCharacterRow                    ; &1CF4: F0 13
BlitNextRowLoop:
    STY BlitRow                      ; &1CF6: 84 74
    LDY TempLo                      ; &1CF8: A4 76
    TYA                          ; &1CFA: 98
    AND HeightMask                      ; &1CFB: 25 84
    BEQ AdvanceBlitColumn                    ; &1CFD: F0 20
    DEC ImageLength                      ; &1CFF: C6 75
    BNE BlitRowByteLoop                    ; &1D01: D0 DB
    PLA                          ; &1D03: 68
    PLA                          ; &1D04: 68
    PLA                          ; &1D05: 68
    STA ImageLength                      ; &1D06: 85 75
    RTS                          ; &1D08: 60

AdvanceBlitToNextCharacterRow:
    LDY #&00                     ; &1D09: A0 00
    CLC                          ; &1D0B: 18
    LDA DestPtrLo                      ; &1D0C: A5 70
    ADC #&80                     ; &1D0E: 69 80
    STA DestPtrLo                      ; &1D10: 85 70
    LDA DestPtrHi                      ; &1D12: A5 71
    ADC #&02                     ; &1D14: 69 02
    BPL StoreWrappedBlitHigh                    ; &1D16: 10 03
    SEC                          ; &1D18: 38
    SBC #&50                     ; &1D19: E9 50

StoreWrappedBlitHigh:
    STA DestPtrHi                      ; &1D1B: 85 71
    BNE BlitNextRowLoop                    ; &1D1D: D0 D7

AdvanceBlitColumn:
    CLC                          ; &1D1F: 18
    PLA                          ; &1D20: 68
    ADC #&08                     ; &1D21: 69 08
    STA DestPtrLo                      ; &1D23: 85 70
    PLA                          ; &1D25: 68
    ADC #&00                     ; &1D26: 69 00
    BPL StoreNextBlitColumnHigh                    ; &1D28: 10 03
    SEC                          ; &1D2A: 38
    SBC #&50                     ; &1D2B: E9 50

StoreNextBlitColumnHigh:
    STA DestPtrHi                      ; &1D2D: 85 71
    DEC ImageLength                      ; &1D2F: C6 75
    BNE BlitWrappedDestinationPath                    ; &1D31: D0 99
    PLA                          ; &1D33: 68
    STA ImageLength                      ; &1D34: 85 75
    RTS                          ; &1D36: 60

NextFrame:
; Per-frame video housekeeping: program CRTC start address from ScreenOrigin,
; wait for VSync, start the User VIA timing window, update background/flash
; palette effects and rotate three logical palette colours periodically.
    LDA ScreenOriginLo                    ; &1D37: AD 08 2F
    STA TempLo                      ; &1D3A: 85 76
    LDA ScreenOriginHi                    ; &1D3C: AD 09 2F
    LSR A                        ; &1D3F: 4A
    ROR TempLo                      ; &1D40: 66 76
    LSR A                        ; &1D42: 4A
    ROR TempLo                      ; &1D43: 66 76
    LSR A                        ; &1D45: 4A
    ROR TempLo                      ; &1D46: 66 76
    LDX #&0C                     ; &1D48: A2 0C
    JSR WriteCRTCRegister        ; &1D4A: 20 2D 0E
    LDX #&0D                     ; &1D4D: A2 0D
    LDA TempLo                      ; &1D4F: A5 76
    JSR WriteCRTCRegister        ; &1D51: 20 2D 0E
    JSR WaitForVSync             ; &1D54: 20 12 0E
    LDY #&14                     ; &1D57: A0 14
    LDX #&80                     ; &1D59: A2 80
    JSR ProgramUserVIATimer      ; &1D5B: 20 34 0E
    LDA BackgroundPalette                    ; &1D5E: AD 0F 2F
    JSR WritePaletteColour       ; &1D61: 20 25 0E
    LDA HumanCount                    ; &1D64: AD 15 2F
    BNE UpdateFlashPalette                    ; &1D67: D0 08
    LDA BackgroundPalette                    ; &1D69: AD 0F 2F
    ORA #&60                     ; &1D6C: 09 60
    JSR WritePaletteColour       ; &1D6E: 20 25 0E

UpdateFlashPalette:
    DEC FlashPaletteCountdown                    ; &1D71: CE 35 2F
    BNE UpdateRotatingPalette                    ; &1D74: D0 18
    LDA FlashPalettePeriod                    ; &1D76: AD 36 2F
    STA FlashPaletteCountdown                    ; &1D79: 8D 35 2F
    INC FlashPaletteIndex                    ; &1D7C: EE 34 2F
    LDA FlashPaletteIndex                    ; &1D7F: AD 34 2F
    AND #&07                     ; &1D82: 29 07
    STA FlashPaletteIndex                    ; &1D84: 8D 34 2F
    TAX                          ; &1D87: AA
    LDA FlashPalette,X                  ; &1D88: BD 70 2A
    JSR WritePaletteColour       ; &1D8B: 20 25 0E

UpdateRotatingPalette:
    INC PaletteRotateFrameCount                    ; &1D8E: EE 3D 2F
    LDA PaletteRotateFrameCount                    ; &1D91: AD 3D 2F
    AND #&03                     ; &1D94: 29 03
    BNE ReturnNextFrame                    ; &1D96: D0 22
    LDX PaletteRotateIndex                    ; &1D98: AE 3E 2F
    LDA #&10                     ; &1D9B: A9 10
RotateNextPaletteColour:
    STA TempLo                      ; &1D9D: 85 76
    STX PaletteRotateIndex                    ; &1D9F: 8E 3E 2F
    LDA PaletteRotateColours,X                  ; &1DA2: BD 3F 2F
    ORA TempLo                      ; &1DA5: 05 76
    JSR WritePaletteColour       ; &1DA7: 20 25 0E
    INX                          ; &1DAA: E8
    CPX #&03                     ; &1DAB: E0 03
    BNE AdvancePaletteLogicalSlot                    ; &1DAD: D0 02
    LDX #&00                     ; &1DAF: A2 00

AdvancePaletteLogicalSlot:
    LDA TempLo                      ; &1DB1: A5 76
    CLC                          ; &1DB3: 18
    ADC #&10                     ; &1DB4: 69 10
    CMP #&40                     ; &1DB6: C9 40
    BNE RotateNextPaletteColour                    ; &1DB8: D0 E3

ReturnNextFrame:
    RTS                          ; &1DBA: 60

PaintSurfaceRight:
; Incrementally paint terrain columns moving right, updating one of the two
; SurfaceWindowEdges cursors.
    PHA                          ; &1DBB: 48
    STA SurfaceCount                      ; &1DBC: 85 78
    STY TempHi                      ; &1DBE: 84 77
    LDY SurfaceWindowEdges,X                  ; &1DC0: BC 0C 2F
PaintSurfaceRightLoop:
    JSR XorBlitSurfaceTile                    ; &1DC3: 20 EB 1D
    INC TempHi                      ; &1DC6: E6 77
    INY                          ; &1DC8: C8
    DEC SurfaceCount                      ; &1DC9: C6 78
    BNE PaintSurfaceRightLoop                    ; &1DCB: D0 F6
    TYA                          ; &1DCD: 98
    STA SurfaceWindowEdges,X                  ; &1DCE: 9D 0C 2F
    PLA                          ; &1DD1: 68
    RTS                          ; &1DD2: 60

PaintSurfaceLeft:
; Incrementally paint terrain columns moving left, updating the corresponding
; SurfaceWindowEdges cursor.
    PHA                          ; &1DD3: 48
    STA SurfaceCount                      ; &1DD4: 85 78
    STY TempHi                      ; &1DD6: 84 77
    LDY SurfaceWindowEdges,X                  ; &1DD8: BC 0C 2F
PaintSurfaceLeftLoop:
    DEC TempHi                      ; &1DDB: C6 77
    DEY                          ; &1DDD: 88
    JSR XorBlitSurfaceTile                    ; &1DDE: 20 EB 1D
    INC SurfaceCount                      ; &1DE1: E6 78
    BNE PaintSurfaceLeftLoop                    ; &1DE3: D0 F6
    TYA                          ; &1DE5: 98
    STA SurfaceWindowEdges,X                  ; &1DE6: 9D 0C 2F
    PLA                          ; &1DE9: 68
    RTS                          ; &1DEA: 60

XorBlitSurfaceTile:
; Decode a packed 2-bit terrain quadrant from SurfaceQuadrants, choose one of
; the four surface-tile shapes, convert SurfaceY to a video pointer and XOR the
; tile plus its bright top-edge pixels.
    STX SavedX                      ; &1DEB: 86 85
    STY SavedY                      ; &1DED: 84 86
    TYA                          ; &1DEF: 98
    AND #&03                     ; &1DF0: 29 03
    TAX                          ; &1DF2: AA
    TYA                          ; &1DF3: 98
    LSR A                        ; &1DF4: 4A
    LSR A                        ; &1DF5: 4A
    TAY                          ; &1DF6: A8
    LDA SurfaceQuadrants,Y                  ; &1DF7: B9 C0 28
SurfaceQuadrantShiftLoop:
    DEX                          ; &1DFA: CA
    BMI SelectSurfaceTileQuadrant                    ; &1DFB: 30 04
    LSR A                        ; &1DFD: 4A
    LSR A                        ; &1DFE: 4A
    BNE SurfaceQuadrantShiftLoop                    ; &1DFF: D0 F9

SelectSurfaceTileQuadrant:
    AND #&03                     ; &1E01: 29 03
    ASL A                        ; &1E03: 0A
    ASL A                        ; &1E04: 0A
    ; SurfaceTiles was originally &2D20; derive the base from the label.
    ADC #<SurfaceTiles          ; original &1E05: 69 20
    STA SourcePtrLo                      ; &1E07: 85 72
    LDA #>SurfaceTiles          ; original &1E09: A9 2D
    STA SourcePtrHi                      ; &1E0B: 85 73
    LDX TempHi                      ; &1E0D: A6 77
    LDY SavedY                      ; &1E0F: A4 86
    LDA SurfaceY,Y                  ; &1E11: B9 00 29
    TAY                          ; &1E14: A8
    JSR XYToVideoPtr                    ; &1E15: 20 6D 1C
    LDA #&04                     ; &1E18: A9 04
    STA ImageLength                      ; &1E1A: 85 75
    LDA #&07                     ; &1E1C: A9 07
    STA HeightMask                      ; &1E1E: 85 84
    JSR RawXorBlit                    ; &1E20: 20 BE 1C
    LDX TempHi                      ; &1E23: A6 77
    LDY #&C4                     ; &1E25: A0 C4
    JSR XYToVideoPtr                    ; &1E27: 20 6D 1C
    LDY #&00                     ; &1E2A: A0 00
    LDA #&F0                     ; &1E2C: A9 F0
    EOR (DestPtrLo),Y                  ; &1E2E: 51 70
    STA (DestPtrLo),Y                  ; &1E30: 91 70
    INY                          ; &1E32: C8
    LDA #&F0                     ; &1E33: A9 F0
    EOR (DestPtrLo),Y                  ; &1E35: 51 70
    STA (DestPtrLo),Y                  ; &1E37: 91 70
    LDX SavedX                      ; &1E39: A6 85
    LDY SavedY                      ; &1E3B: A4 86
    RTS                          ; &1E3D: 60

UpdateShipAndControls:
; Complete player navigation.  A/Z move the ship vertically; SPACE reverses
; the ship and acceleration direction; SHIFT applies thrust.  Horizontal velocity
; has drag toward zero.  The world scroll window is adjusted so the ship tends
; toward a direction-dependent screen X, then the ship/minimap are updated.
    LDA UnitAnim                    ; &1E3E: AD 46 06
    BEQ HandleAliveOrDeadShip                    ; &1E41: F0 03
    JMP ScrollScreenOrigin                    ; &1E43: 4C 44 21

HandleAliveOrDeadShip:
    LDA PlayerDead                    ; &1E46: AD 24 2F
    BEQ ReadNavigationKeys                    ; &1E49: F0 1D
    LDA ShipPalette                    ; &1E4B: AD 3C 2F
    EOR #&80                     ; &1E4E: 49 80
    STA ShipPalette                    ; &1E50: 8D 3C 2F
    BMI StopDeadShipHorizontalMotion                    ; &1E53: 30 08
    EOR #&06                     ; &1E55: 49 06
    STA ShipPalette                    ; &1E57: 8D 3C 2F
    JSR WritePaletteColour       ; &1E5A: 20 25 0E

StopDeadShipHorizontalMotion:
    LDA #&00                     ; &1E5D: A9 00
    STA UnitDXLo                    ; &1E5F: 8D 94 04
    STA UnitDXHi                    ; &1E62: 8D B9 04
    JMP CommitShipMovement                    ; &1E65: 4C 87 1F

ReadNavigationKeys:
    JSR HandleFireKey            ; &1E68: 20 DF 13
    LDX #KEY_A                     ; &1E6B: A2 BE
    JSR ScanInkey                    ; &1E6D: 20 5A 1C
    BEQ CheckMoveDownKey                    ; &1E70: F0 0D
    CLC                          ; &1E72: 18
    LDA UnitYHi                    ; &1E73: AD 6F 04
    ADC #&02                     ; &1E76: 69 02
    CMP #&C3                     ; &1E78: C9 C3
    BCS CheckMoveDownKey                    ; &1E7A: B0 03
    STA UnitYHi                    ; &1E7C: 8D 6F 04

CheckMoveDownKey:
    LDX #KEY_Z                     ; &1E7F: A2 9E
    JSR ScanInkey                    ; &1E81: 20 5A 1C
    BEQ CheckReverseKey                    ; &1E84: F0 0D
    SEC                          ; &1E86: 38
    LDA UnitYHi                    ; &1E87: AD 6F 04
    SBC #&02                     ; &1E8A: E9 02
    CMP #&09                     ; &1E8C: C9 09
    BCC CheckReverseKey                    ; &1E8E: 90 03
    STA UnitYHi                    ; &1E90: 8D 6F 04

CheckReverseKey:
    LDX #KEY_SPACE                     ; &1E93: A2 9D
    JSR ScanInkey                    ; &1E95: 20 5A 1C
    BEQ StoreReverseKeyLatch                    ; &1E98: F0 03
    EOR SpaceKeyLatch                    ; &1E9A: 4D 23 2F

StoreReverseKeyLatch:
    STX SpaceKeyLatch                    ; &1E9D: 8E 23 2F
    BEQ CheckThrustKey                    ; &1EA0: F0 2D
    LDA UnitSpritePtrLo                    ; &1EA2: AD 28 05
    STA DestPtrLo                      ; &1EA5: 85 70
    LDA UnitSpritePtrHi                    ; &1EA7: AD 4D 05
    STA DestPtrHi                      ; &1EAA: 85 71
    LDX #&00                     ; &1EAC: A2 00
    JSR XorBlitSprite                    ; &1EAE: 20 B4 20
    LDA SpritePtrLoTable                    ; &1EB1: AD 0B 2B
    EOR #(<ShipRightSprite ^ <ShipLeftSprite) ; original &1EB4: 49 30
    STA SpritePtrLoTable                    ; &1EB6: 8D 0B 2B
    LDA #&00                     ; &1EB9: A9 00
    STA UnitSpritePtrHi                    ; &1EBB: 8D 4D 05
    SEC                          ; &1EBE: 38
    LDA #&00                     ; &1EBF: A9 00
    SBC ShipAccelerationLo                    ; &1EC1: ED 1C 2F
    STA ShipAccelerationLo                    ; &1EC4: 8D 1C 2F
    LDA #&00                     ; &1EC7: A9 00
    SBC ShipAccelerationHi                    ; &1EC9: ED 1D 2F
    STA ShipAccelerationHi                    ; &1ECC: 8D 1D 2F

CheckThrustKey:
    LDX #KEY_SHIFT                     ; &1ECF: A2 FF
    JSR ScanInkey                    ; &1ED1: 20 5A 1C
    BEQ ApplyShipDrag                    ; &1ED4: F0 13
    CLC                          ; &1ED6: 18
    LDA UnitDXLo                    ; &1ED7: AD 94 04
    ADC ShipAccelerationLo                    ; &1EDA: 6D 1C 2F
    STA UnitDXLo                    ; &1EDD: 8D 94 04
    LDA UnitDXHi                    ; &1EE0: AD B9 04
    ADC ShipAccelerationHi                    ; &1EE3: 6D 1D 2F
    STA UnitDXHi                    ; &1EE6: 8D B9 04

ApplyShipDrag:
    LDA UnitDXHi                    ; &1EE9: AD B9 04
    ORA UnitDXLo                    ; &1EEC: 0D 94 04
    BEQ ChooseShipScrollTarget                    ; &1EEF: F0 54
    LDA UnitDXHi                    ; &1EF1: AD B9 04
    BPL ApplyRightwardDrag                    ; &1EF4: 10 26
    CLC                          ; &1EF6: 18
    LDA UnitDXLo                    ; &1EF7: AD 94 04
    ADC #&03                     ; &1EFA: 69 03
    STA UnitDXLo                    ; &1EFC: 8D 94 04
    LDA UnitDXHi                    ; &1EFF: AD B9 04
    ADC #&00                     ; &1F02: 69 00
    STA UnitDXHi                    ; &1F04: 8D B9 04
    BCS StopShipAtDragZero                    ; &1F07: B0 34
    LDA UnitDXHi                    ; &1F09: AD B9 04
    CMP #&FF                     ; &1F0C: C9 FF
    BPL ChooseShipScrollTarget                    ; &1F0E: 10 35
    LDA #&FF                     ; &1F10: A9 FF
    STA UnitDXHi                    ; &1F12: 8D B9 04
    LDA #&00                     ; &1F15: A9 00
    STA UnitDXLo                    ; &1F17: 8D 94 04
    BEQ ChooseShipScrollTarget                    ; &1F1A: F0 29

ApplyRightwardDrag:
    SEC                          ; &1F1C: 38
    LDA UnitDXLo                    ; &1F1D: AD 94 04
    SBC #&03                     ; &1F20: E9 03
    STA UnitDXLo                    ; &1F22: 8D 94 04
    LDA UnitDXHi                    ; &1F25: AD B9 04
    SBC #&00                     ; &1F28: E9 00
    STA UnitDXHi                    ; &1F2A: 8D B9 04
    BCC StopShipAtDragZero                    ; &1F2D: 90 0E
    LDA UnitDXHi                    ; &1F2F: AD B9 04
    CMP #&01                     ; &1F32: C9 01
    BMI ChooseShipScrollTarget                    ; &1F34: 30 0F
    LDA #&00                     ; &1F36: A9 00
    STA UnitDXLo                    ; &1F38: 8D 94 04
    BEQ ChooseShipScrollTarget                    ; &1F3B: F0 08

StopShipAtDragZero:
    LDA #&00                     ; &1F3D: A9 00
    STA UnitDXLo                    ; &1F3F: 8D 94 04
    STA UnitDXHi                    ; &1F42: 8D B9 04

ChooseShipScrollTarget:
    LDX #&00                     ; &1F45: A2 00
    JSR GetUnitScreenX                    ; &1F47: 20 3B 20
    TAX                          ; &1F4A: AA
    LDY #&0F                     ; &1F4B: A0 0F
    LDA ShipAccelerationHi                    ; &1F4D: AD 1D 2F
    BPL ComputeRelativeWorldVelocity                    ; &1F50: 10 02
    LDY #&3B                     ; &1F52: A0 3B

ComputeRelativeWorldVelocity:
    STY TempLo                      ; &1F54: 84 76
    LDA #&00                     ; &1F56: A9 00
    LDY #&00                     ; &1F58: A0 00
    CPX TempLo                      ; &1F5A: E4 76
    BEQ UpdateWorldLeftEdge                    ; &1F5C: F0 08
    LDA #&80                     ; &1F5E: A9 80
    BCS UpdateWorldLeftEdge                    ; &1F60: B0 04
    LDA #&80                     ; &1F62: A9 80
    LDY #&FF                     ; &1F64: A0 FF

UpdateWorldLeftEdge:
    CLC                          ; &1F66: 18
    ADC UnitDXLo                    ; &1F67: 6D 94 04
    STA WorldScrollVelocityLo                    ; &1F6A: 8D 1E 2F
    TYA                          ; &1F6D: 98
    ADC UnitDXHi                    ; &1F6E: 6D B9 04
    STA WorldScrollVelocityHi                    ; &1F71: 8D 1F 2F
    CLC                          ; &1F74: 18
    LDA WorldScrollVelocityLo                    ; &1F75: AD 1E 2F
    ADC WorldLeftEdgeLo                    ; &1F78: 6D 20 2F
    STA WorldLeftEdgeLo                    ; &1F7B: 8D 20 2F
    LDA WorldScrollVelocityHi                    ; &1F7E: AD 1F 2F
    ADC WorldLeftEdgeHi                    ; &1F81: 6D 21 2F
    STA WorldLeftEdgeHi                    ; &1F84: 8D 21 2F

CommitShipMovement:
    JSR ScrollScreenOrigin                    ; &1F87: 20 44 21
    LDX #&00                     ; &1F8A: A2 00
    JSR MoveUnitHorizontal                    ; &1F8C: 20 01 20
    LDX #&00                     ; &1F8F: A2 00
    JSR UpdateRadarDot           ; &1F91: 20 6D 13
    RTS                          ; &1F94: 60

UpdateHitchhiker:
; Draw rescued humans hanging beneath the ship when HitchhikerCount is nonzero;
; otherwise erase the reserved hitchhiker slot.
    LDA HitchhikerCount                    ; &1F95: AD 2D 2F
    BEQ EraseHitchhiker                    ; &1F98: F0 27
    LDA #&06                     ; &1F9A: A9 06
    STA UnitType+HITCH_SLOT                    ; &1F9C: 8D BD 05
    LDA UnitXLo                    ; &1F9F: AD 00 04
    CLC                          ; &1FA2: 18
    ADC #&80                     ; &1FA3: 69 80
    STA UnitXLo+HITCH_SLOT                    ; &1FA5: 8D 01 04
    LDA #&00                     ; &1FA8: A9 00
    ADC UnitXHi                    ; &1FAA: 6D 25 04
    STA UnitXHi+HITCH_SLOT                    ; &1FAD: 8D 26 04
    LDA UnitYHi                    ; &1FB0: AD 6F 04
    SEC                          ; &1FB3: 38
    SBC #&0A                     ; &1FB4: E9 0A
    STA UnitYHi+HITCH_SLOT                    ; &1FB6: 8D 70 04
    LDX #&01                     ; &1FB9: A2 01
    JSR UpdateUnitVideoPointer                    ; &1FBB: 20 14 20
    JMP UpdateRadarDot           ; &1FBE: 4C 6D 13

EraseHitchhiker:
    LDX #&01                     ; &1FC1: A2 01
    JMP EraseUnit                ; &1FC3: 4C 64 16

MoveUnit:
; Apply signed fixed-point dY then dX to one unit, wrapping ordinary actors at
; the vertical playfield limits while allowing projectiles to disappear.  Finish
; by computing/caching the unit's next MODE 2 screen pointer.
    LDA UnitType,X                  ; &1FC6: BD BC 05
    AND #&77                     ; &1FC9: 29 77
    TAY                          ; &1FCB: A8
    CLC                          ; &1FCC: 18
    LDA UnitDYLo,X                  ; &1FCD: BD DE 04
    ADC UnitYLo,X                  ; &1FD0: 7D 4A 04
    STA UnitYLo,X                  ; &1FD3: 9D 4A 04
    LDA UnitDYHi,X                  ; &1FD6: BD 03 05
    ADC UnitYHi,X                  ; &1FD9: 7D 6F 04
    CMP #&C3                     ; &1FDC: C9 C3
    BCC CheckUnitBottomBoundary                    ; &1FDE: 90 06
    CPY #&00                     ; &1FE0: C0 00
    BEQ SetUnitOffscreen                    ; &1FE2: F0 51
    LDA #&09                     ; &1FE4: A9 09

CheckUnitBottomBoundary:
    CMP #&09                     ; &1FE6: C9 09
    BCS StoreMovedUnitY                    ; &1FE8: B0 14
    CPY #&00                     ; &1FEA: C0 00
    BNE WrapOrdinaryUnitY                    ; &1FEC: D0 06
    CMP #&04                     ; &1FEE: C9 04
    BCS StoreMovedUnitY                    ; &1FF0: B0 0C
    BCC SetUnitOffscreen                    ; &1FF2: 90 41

WrapOrdinaryUnitY:
    CPY #&06                     ; &1FF4: C0 06
    PHP                          ; &1FF6: 08
    LDA #&C2                     ; &1FF7: A9 C2
    PLP                          ; &1FF9: 28
    BNE StoreMovedUnitY                    ; &1FFA: D0 02
    LDA #&09                     ; &1FFC: A9 09

StoreMovedUnitY:
    STA UnitYHi,X                  ; &1FFE: 9D 6F 04
MoveUnitHorizontal:
    CLC                          ; &2001: 18
    LDA UnitDXLo,X                  ; &2002: BD 94 04
    ADC UnitXLo,X                  ; &2005: 7D 00 04
    STA UnitXLo,X                  ; &2008: 9D 00 04
    LDA UnitDXHi,X                  ; &200B: BD B9 04
    ADC UnitXHi,X                  ; &200E: 7D 25 04
    STA UnitXHi,X                  ; &2011: 9D 25 04
; Entry used when position is already updated: convert unit world position to next screen pointer.
UpdateUnitVideoPointer:
    LDY UnitYHi,X                  ; &2014: BC 6F 04
    TXA                          ; &2017: 8A
    PHA                          ; &2018: 48
    JSR GetUnitScreenX                    ; &2019: 20 3B 20
    TAX                          ; &201C: AA
    JSR XYToVideoPtr                    ; &201D: 20 6D 1C
    PLA                          ; &2020: 68
    TAX                          ; &2021: AA
StoreUnitNextVideoPointer:
    LDA DestPtrLo                      ; &2022: A5 70
    STA UnitNextPtrLo,X                  ; &2024: 9D 72 05
    LDA DestPtrHi                      ; &2027: A5 71
    STA UnitNextPtrHi,X                  ; &2029: 9D 97 05
    LDA UnitType,X                  ; &202C: BD BC 05
    AND #&7F                     ; &202F: 29 7F
    STA UnitType,X                  ; &2031: 9D BC 05
    RTS                          ; &2034: 60

SetUnitOffscreen:
    LDA #&00                     ; &2035: A9 00
    STA DestPtrHi                      ; &2037: 85 71
    BEQ StoreUnitNextVideoPointer                    ; &2039: F0 E7

GetUnitScreenX:
; Convert unit world X relative to WorldLeftEdge into an 8-bit screen X.
; Returns &80 when the 16-bit sign/range test says the unit is off-screen.
    SEC                          ; &203B: 38
    LDA UnitXLo,X                  ; &203C: BD 00 04
    SBC WorldLeftEdgeLo                    ; &203F: ED 20 2F
    STA TempLo                      ; &2042: 85 76
    LDA UnitXHi,X                  ; &2044: BD 25 04
    SBC WorldLeftEdgeHi                    ; &2047: ED 21 2F
    STA TempHi                      ; &204A: 85 77
    ASL TempLo                      ; &204C: 06 76
    ROL A                        ; &204E: 2A
    STA TempLo                      ; &204F: 85 76
    EOR TempHi                      ; &2051: 45 77
    BMI ReturnOffscreenX                    ; &2053: 30 03
    LDA TempLo                      ; &2055: A5 76
    RTS                          ; &2057: 60

ReturnOffscreenX:
    LDA #&80                     ; &2058: A9 80
    RTS                          ; &205A: 60

RepaintAllUnits:
; XOR erase/redraw pass across all 37 unit slots.  Each unit has current and
; next video pointers; unchanged off-ship sprites can skip the expensive redraw.
; The ship's XOR paint mask is retained for collision testing.
    LDX #&00                     ; &205B: A2 00
RepaintUnitLoop:
    TXA                          ; &205D: 8A
    PHA                          ; &205E: 48
    LDA UnitType,X                  ; &205F: BD BC 05
    BMI AdvanceRepaintUnit                    ; &2062: 30 48
    ORA #&80                     ; &2064: 09 80
    STA UnitType,X                  ; &2066: 9D BC 05
    LDA UnitAnim,X                  ; &2069: BD 46 06
    BNE AdvanceRepaintUnit                    ; &206C: D0 3E
    LDA UnitSpritePtrLo,X                  ; &206E: BD 28 05
    CMP UnitNextPtrLo,X                  ; &2071: DD 72 05
    BNE EraseOldUnitSprite                    ; &2074: D0 0C
    LDA UnitSpritePtrHi,X                  ; &2076: BD 4D 05
    CMP UnitNextPtrHi,X                  ; &2079: DD 97 05
    BNE EraseOldUnitSprite                    ; &207C: D0 04
    CPX #&00                     ; &207E: E0 00
    BNE AdvanceRepaintUnit                    ; &2080: D0 2A

EraseOldUnitSprite:
    LDA UnitSpritePtrLo,X                  ; &2082: BD 28 05
    STA DestPtrLo                      ; &2085: 85 70
    LDA UnitSpritePtrHi,X                  ; &2087: BD 4D 05
    STA DestPtrHi                      ; &208A: 85 71
    LDA UnitType,X                  ; &208C: BD BC 05
    AND #&7F                     ; &208F: 29 7F
    TAX                          ; &2091: AA
    JSR XorBlitSprite                    ; &2092: 20 B4 20
    PLA                          ; &2095: 68
    TAX                          ; &2096: AA
    LDA UnitNextPtrLo,X                  ; &2097: BD 72 05
    STA UnitSpritePtrLo,X                  ; &209A: 9D 28 05
    STA DestPtrLo                      ; &209D: 85 70
    LDA UnitNextPtrHi,X                  ; &209F: BD 97 05
    STA UnitSpritePtrHi,X                  ; &20A2: 9D 4D 05
    STA DestPtrHi                      ; &20A5: 85 71
    TXA                          ; &20A7: 8A
    PHA                          ; &20A8: 48
    JSR RawXorBlit                    ; &20A9: 20 BE 1C

AdvanceRepaintUnit:
    PLA                          ; &20AC: 68
    TAX                          ; &20AD: AA
    INX                          ; &20AE: E8
    CPX #&25                     ; &20AF: E0 25
    BNE RepaintUnitLoop                    ; &20B1: D0 AA
    RTS                          ; &20B3: 60

XorBlitSprite:
; Load sprite length/pointer/vertical mask from the type tables and invoke
; RawXorBlit.  For the ship, save PaintMask into PlayerCollisionMask.
    LDA SpriteMaxYTable,X                  ; &20B4: BD 37 2B
    STA HeightMask                      ; &20B7: 85 84
    LDA SpriteLengths,X                  ; &20B9: BD 00 2B
    STA ImageLength                      ; &20BC: 85 75
    LDA SpritePtrLoTable,X                  ; &20BE: BD 0B 2B
    STA SourcePtrLo                      ; &20C1: 85 72
    LDA SpritePtrHiTable,X                  ; &20C3: BD 16 2B
    STA SourcePtrHi                      ; &20C6: 85 73
    JSR RawXorBlit                    ; &20C8: 20 BE 1C
    CPX #&00                     ; &20CB: E0 00
    BNE ReturnFromSpriteBlit                    ; &20CD: D0 04
    LDA PaintMask                      ; &20CF: A5 8A
    STA PlayerCollisionMask                      ; &20D1: 85 8B

ReturnFromSpriteBlit:
    RTS                          ; &20D3: 60

ScrollSurface:
; Repaint newly exposed planet terrain caused by horizontal world scrolling.
; Temporarily restores the old CRTC origin while painting the entering edge, then
; restores the current origin.
    LDA #&00                     ; &20D4: A9 00
    STA MinScreenX                    ; &20D6: 8D 28 2F
    LDA #&50                     ; &20D9: A9 50
    STA MaxScreenX                    ; &20DB: 8D 29 2F
    LDA ScreenOriginLo                    ; &20DE: AD 08 2F
    PHA                          ; &20E1: 48
    LDA ScreenOriginHi                    ; &20E2: AD 09 2F
    PHA                          ; &20E5: 48
    LDA OldScreenOriginLo                    ; &20E6: AD 00 2F
    STA ScreenOriginLo                    ; &20E9: 8D 08 2F
    LDA OldScreenOriginHi                    ; &20EC: AD 01 2F
    STA ScreenOriginHi                    ; &20EF: 8D 09 2F
    LDA WorldWindowDelta                    ; &20F2: AD 2A 2F
    BEQ RestoreCurrentScreenOrigin                    ; &20F5: F0 44
    BPL PaintNewRightSurfaceEdge                    ; &20F7: 10 21
    LDX #&01                     ; &20F9: A2 01
    LDY #&50                     ; &20FB: A0 50
    JSR PaintSurfaceLeft                    ; &20FD: 20 D3 1D
    STA TempLo                      ; &2100: 85 76
    PLA                          ; &2102: 68
    STA ScreenOriginHi                    ; &2103: 8D 09 2F
    PLA                          ; &2106: 68
    STA ScreenOriginLo                    ; &2107: 8D 08 2F
    SEC                          ; &210A: 38
    LDA #&00                     ; &210B: A9 00
    SBC TempLo                      ; &210D: E5 76
    TAY                          ; &210F: A8
    LDX #&00                     ; &2110: A2 00
    LDA TempLo                      ; &2112: A5 76
    JSR PaintSurfaceLeft                    ; &2114: 20 D3 1D
    JMP ReturnFromSurfaceScroll                    ; &2117: 4C 43 21

PaintNewRightSurfaceEdge:
    LDX #&00                     ; &211A: A2 00
    LDY #&00                     ; &211C: A0 00
    JSR PaintSurfaceRight                    ; &211E: 20 BB 1D
    STA TempLo                      ; &2121: 85 76
    PLA                          ; &2123: 68
    STA ScreenOriginHi                    ; &2124: 8D 09 2F
    PLA                          ; &2127: 68
    STA ScreenOriginLo                    ; &2128: 8D 08 2F
    SEC                          ; &212B: 38
    LDA #&50                     ; &212C: A9 50
    SBC TempLo                      ; &212E: E5 76
    TAY                          ; &2130: A8
    LDX #&01                     ; &2131: A2 01
    LDA TempLo                      ; &2133: A5 76
    JSR PaintSurfaceRight                    ; &2135: 20 BB 1D
    JMP ReturnFromSurfaceScroll                    ; &2138: 4C 43 21

RestoreCurrentScreenOrigin:
    PLA                          ; &213B: 68
    STA ScreenOriginHi                    ; &213C: 8D 09 2F
    PLA                          ; &213F: 68
    STA ScreenOriginLo                    ; &2140: 8D 08 2F

ReturnFromSurfaceScroll:
    RTS                          ; &2143: 60

ScrollScreenOrigin:
; Translate world movement into the circular MODE 2 CRTC origin and the signed
; ScrollOffset used by terrain, minimap and HUD repair.  Screen RAM wraps between
; &3000 and &7FFF.
    LDA ScreenOriginLo                    ; &2144: AD 08 2F
    STA OldScreenOriginLo                    ; &2147: 8D 00 2F
    LDA ScreenOriginHi                    ; &214A: AD 09 2F
    STA OldScreenOriginHi                    ; &214D: 8D 01 2F
    LDA WorldLeftEdgeLo                    ; &2150: AD 20 2F
    ASL A                        ; &2153: 0A
    LDA WorldLeftEdgeHi                    ; &2154: AD 21 2F
    ROL A                        ; &2157: 2A
    PHA                          ; &2158: 48
    SEC                          ; &2159: 38
    SBC WorldWindowX                    ; &215A: ED 0A 2F
    STA WorldWindowDelta                    ; &215D: 8D 2A 2F
    ASL A                        ; &2160: 0A
    ASL A                        ; &2161: 0A
    ASL A                        ; &2162: 0A
    LDY #&00                     ; &2163: A0 00
    BCC ApplyScreenOriginDelta                    ; &2165: 90 02
    LDY #&FF                     ; &2167: A0 FF

ApplyScreenOriginDelta:
    STA ScrollOffsetLo                    ; &2169: 8D 02 2F
    CLC                          ; &216C: 18
    ADC ScreenOriginLo                    ; &216D: 6D 08 2F
    STA ScreenOriginLo                    ; &2170: 8D 08 2F
    TYA                          ; &2173: 98
    STA ScrollOffsetHi                    ; &2174: 8D 03 2F
    ADC ScreenOriginHi                    ; &2177: 6D 09 2F
    BPL WrapScreenOriginLow                    ; &217A: 10 03
    SEC                          ; &217C: 38
    SBC #&50                     ; &217D: E9 50

WrapScreenOriginLow:
    CMP #&30                     ; &217F: C9 30
    BCS StoreScreenOrigin                    ; &2181: B0 02
    ADC #&50                     ; &2183: 69 50

StoreScreenOrigin:
    STA ScreenOriginHi                    ; &2185: 8D 09 2F
    PLA                          ; &2188: 68
    STA WorldWindowX                    ; &2189: 8D 0A 2F
    RTS                          ; &218C: 60

CheckPlayerCollision:
; Use PlayerCollisionMask as broad phase.  If ship pixels overlapped occupied
; screen pixels, scan live unit slots for bounding overlap.  Enemy contact kills
; the ship; a linked/falling Human can instead become a rescued hitchhiker and
; award 500 points.
    LDA PlayerCollisionMask                      ; &218D: A5 8B
    AND #&C0                     ; &218F: 29 C0
    BEQ NoPlayerCollision                    ; &2191: F0 05
    LDA PlayerDead                    ; &2193: AD 24 2F
    BEQ ScanPlayerCollisionUnits                    ; &2196: F0 01

NoPlayerCollision:
    RTS                          ; &2198: 60

ScanPlayerCollisionUnits:
    LDX #&00                     ; &2199: A2 00
    JSR GetUnitScreenX                    ; &219B: 20 3B 20
    STA ShipScreenX                    ; &219E: 8D 2C 2F
    LDX #&24                     ; &21A1: A2 24
CollisionUnitScanLoop:
    LDA UnitType,X                  ; &21A3: BD BC 05
    ASL A                        ; &21A6: 0A
    BMI NextCollisionUnit                    ; &21A7: 30 65
    CMP #&12                     ; &21A9: C9 12
    BCS NextCollisionUnit                    ; &21AB: B0 61
    LDA UnitAnim,X                  ; &21AD: BD 46 06
    BNE NextCollisionUnit                    ; &21B0: D0 5C
    LDA UnitYHi,X                  ; &21B2: BD 6F 04
    SEC                          ; &21B5: 38
    SBC UnitYHi                    ; &21B6: ED 6F 04
    CMP #&08                     ; &21B9: C9 08
    BPL NextCollisionUnit                    ; &21BB: 10 51
    CMP #&F9                     ; &21BD: C9 F9
    BMI NextCollisionUnit                    ; &21BF: 30 4D
    JSR GetUnitScreenX                    ; &21C1: 20 3B 20
    CMP #&50                     ; &21C4: C9 50
    BCS NextCollisionUnit                    ; &21C6: B0 46
    SEC                          ; &21C8: 38
    SBC ShipScreenX                    ; &21C9: ED 2C 2F
    CMP #&06                     ; &21CC: C9 06
    BPL NextCollisionUnit                    ; &21CE: 10 3E
    CMP #&FD                     ; &21D0: C9 FD
    BMI NextCollisionUnit                    ; &21D2: 30 3A
    LDA UnitType,X                  ; &21D4: BD BC 05
    AND #&7F                     ; &21D7: 29 7F
    CMP #&06                     ; &21D9: C9 06
    BEQ TryRescueHuman                    ; &21DB: F0 10
    JSR ScoreUnit                 ; &21DD: 20 4D 24
    JSR DestroyUnit              ; &21E0: 20 23 16
    LDA #&01                     ; &21E3: A9 01
    STA PlayerDead                    ; &21E5: 8D 24 2F
    LDA #&77                     ; &21E8: A9 77
    STA ShipPalette                    ; &21EA: 8D 3C 2F

TryRescueHuman:
    LDA UnitParam,X                  ; &21ED: BD E1 05
    BPL NextCollisionUnit                    ; &21F0: 10 1C
    CMP #HUMAN_HITCHHIKER                     ; &21F2: C9 80
    BEQ NextCollisionUnit                    ; &21F4: F0 18
    JSR EraseUnit                ; &21F6: 20 64 16
    LDA #HUMAN_HITCHHIKER                     ; &21F9: A9 80
    STA UnitParam,X                  ; &21FB: 9D E1 05
    LDA #&86                     ; &21FE: A9 86
    STA UnitType,X                  ; &2200: 9D BC 05
    INC HitchhikerCount                    ; &2203: EE 2D 2F
    LDA #&0E                     ; &2206: A9 0E
    JSR PlaySound                ; &2208: 20 7D 12
    JSR Spawn500ScorePopup       ; &220B: 20 6B 24

NextCollisionUnit:
    DEX                          ; &220E: CA
    BNE CollisionUnitScanLoop                    ; &220F: D0 92
    RTS                          ; &2211: 60

RandomByte:
; 24-bit software PRNG.  Eight feedback shifts use taps from Random0 and rotate
; the three-byte state; returns Random0 while preserving X.
    TXA                          ; &2212: 8A
    PHA                          ; &2213: 48
    LDX #&08                     ; &2214: A2 08
RandomMixLoop:
    LDA Random0                      ; &2216: A5 80
    AND #&48                     ; &2218: 29 48
    ADC #&38                     ; &221A: 69 38
    ASL A                        ; &221C: 0A
    ASL A                        ; &221D: 0A
    ROL Random2                      ; &221E: 26 82
    ROL Random1                      ; &2220: 26 81
    ROL Random0                      ; &2222: 26 80
    DEX                          ; &2224: CA
    BNE RandomMixLoop                    ; &2225: D0 EF
    PLA                          ; &2227: 68
    TAX                          ; &2228: AA
    LDA Random0                      ; &2229: A5 80
    RTS                          ; &222B: 60

StartNextWave:
; Advance packed-BCD LevelBCD and derive difficulty/state for the new level:
; human bonus multiplier, planet renewal every fifth-level cycle, AI batch size,
; enemy-shot speed, Bomber/Pod counts, Lander speed, palettes and timers.  Then
; clear/reinitialise unit slots and rebuild the new screen.
    SED                          ; &222C: F8
    LDA LevelBCD                    ; &222D: AD 16 2F
    CLC                          ; &2230: 18
    ADC #&01                     ; &2231: 69 01
    STA LevelBCD                    ; &2233: 8D 16 2F
    CMP #&05                     ; &2236: C9 05
    BCC StoreHumanBonusMultiplier                    ; &2238: 90 02
    LDA #&05                     ; &223A: A9 05

StoreHumanBonusMultiplier:
    STA HumanBonusBCD                    ; &223C: 8D 17 2F
    LDA LevelBCD                    ; &223F: AD 16 2F
    SEC                          ; &2242: 38
    LDX #&61                     ; &2243: A2 61
ComputePlanetSurfaceIndexLoop:
    SBC #&05                     ; &2245: E9 05
    BCS ComputePlanetSurfaceIndexLoop                    ; &2247: B0 FC
    CMP #&95                     ; &2249: C9 95
    BNE SetSurfaceForPlanetState                    ; &224B: D0 0F
    LDA #&0A                     ; &224D: A9 0A
    STA HumanCount                    ; &224F: 8D 15 2F
    LDA #&00                     ; &2252: A9 00
    STA NoPlanet                    ; &2254: 8D 1A 2F
    LDX #&62                     ; &2257: A2 62
    INC AIBatchSize                    ; &2259: EE 25 2F

SetSurfaceForPlanetState:
    CLD                          ; &225C: D8
    LDA HumanCount                    ; &225D: AD 15 2F
    BNE StoreSurfacePalette                    ; &2260: D0 02
    LDX #&60                     ; &2262: A2 60

StoreSurfacePalette:
    STX SurfacePalette                    ; &2264: 8E 42 2F
    CLC                          ; &2267: 18
    LDA EnemyShotSpeed                    ; &2268: AD 3A 2F
    ADC #&08                     ; &226B: 69 08
    STA EnemyShotSpeed                    ; &226D: 8D 3A 2F
    LDA #&0A                     ; &2270: A9 0A
    STA BaitDelayHi                    ; &2272: 8D 19 2F
    LDA #&00                     ; &2275: A9 00
    STA SpawnCount+BAITER                    ; &2277: 8D 61 2F
    LDA HumanCount                    ; &227A: AD 15 2F
    STA SpawnCount+HUMAN                    ; &227D: 8D 64 2F
    LDX #&1F                     ; &2280: A2 1F
    LDA #&FF                     ; &2282: A9 FF
ClearEnemyUnitSlotsLoop:
    STA UnitType,X                  ; &2284: 9D BC 05
    DEX                          ; &2287: CA
    BPL ClearEnemyUnitSlotsLoop                    ; &2288: 10 FA
    LDA #&00                     ; &228A: A9 00
    STA HitchhikerCount                    ; &228C: 8D 2D 2F
    LDA #&22                     ; &228F: A9 22
    STA AlternateUnitIndex                    ; &2291: 8D 22 2F
    LDA #&00                     ; &2294: A9 00
    STA PaletteRotateIndex                    ; &2296: 8D 3E 2F
    STA FlashPaletteIndex                    ; &2299: 8D 34 2F
    LDA #&06                     ; &229C: A9 06
    STA FlashPalettePeriod                    ; &229E: 8D 36 2F
    STA FlashPaletteCountdown                    ; &22A1: 8D 35 2F
    LDA #&00                     ; &22A4: A9 00
    STA EnemyCount                    ; &22A6: 8D 13 2F
    LDA #&02                     ; &22A9: A9 02
    STA SquadDelayHigh                    ; &22AB: 8D 14 2F
    LDA #&00                     ; &22AE: A9 00
    STA SpawnCount+SWARMER                    ; &22B0: 8D 63 2F
    LDX #&00                     ; &22B3: A2 00
    LDA LevelBCD                    ; &22B5: AD 16 2F
    CMP #&01                     ; &22B8: C9 01
    BEQ StoreBomberCount                    ; &22BA: F0 08
    LDX #&04                     ; &22BC: A2 04
    CMP #&04                     ; &22BE: C9 04
    BCC StoreBomberCount                    ; &22C0: 90 02
    LDX #&07                     ; &22C2: A2 07

StoreBomberCount:
    STX SpawnCount+BOMBER                    ; &22C4: 8E 62 2F
    LDX #&04                     ; &22C7: A2 04
    CMP #&04                     ; &22C9: C9 04
    BCS StorePodCount                    ; &22CB: B0 0C
    DEX                          ; &22CD: CA
    CMP #&03                     ; &22CE: C9 03
    BEQ StorePodCount                    ; &22D0: F0 07
    DEX                          ; &22D2: CA
    DEX                          ; &22D3: CA
    CMP #&02                     ; &22D4: C9 02
    BEQ StorePodCount                    ; &22D6: F0 01
    DEX                          ; &22D8: CA

StorePodCount:
    STX SpawnCount+POD                    ; &22D9: 8E 65 2F
    LDA DXMinInit+LANDER                    ; &22DC: AD 87 2F
    CLC                          ; &22DF: 18
    ADC #&02                     ; &22E0: 69 02
    CMP #&18                     ; &22E2: C9 18
    BCS BeginLevelContinuationSetup                    ; &22E4: B0 03
    STA DXMinInit+LANDER                    ; &22E6: 8D 87 2F

BeginLevelContinuationSetup:
    LDA #&00                     ; &22E9: A9 00
    STA BackgroundPalette                    ; &22EB: 8D 0F 2F
; Life-loss continuation entry: preserve level setup, reset/reinitialise surviving units, then rebuild the screen.
ContinueCurrentLevel:
; Life-loss continuation path entered inside StartNextWave: remove Baiters,
; reset surviving actors/animations and rebuild the current screen without
; incrementing LevelBCD.
    LDA #&80                     ; &22EE: A9 80
    STA XMinInit+SWARMER                    ; &22F0: 8D 6B 2F
    LDX #&1F                     ; &22F3: A2 1F
ScanUnitsForNextLevelReset:
    LDA UnitType,X                  ; &22F5: BD BC 05
    AND #&7F                     ; &22F8: 29 7F
    CMP #&03                     ; &22FA: C9 03
    BNE ResetNextLevelUnit                    ; &22FC: D0 05
    LDA #&FF                     ; &22FE: A9 FF
    STA UnitType,X                  ; &2300: 9D BC 05

ResetNextLevelUnit:
    JSR ResetUnitForNewScreen                    ; &2303: 20 06 24
    JSR InitialiseUnit           ; &2306: 20 6C 17
    DEX                          ; &2309: CA
    BPL ScanUnitsForNextLevelReset                    ; &230A: 10 E9
    LDA #&02                     ; &230C: A9 02
    STA CurrentUnit                      ; &230E: 85 89
    LDA #&00                     ; &2310: A9 00
    STA HitchhikerCount                    ; &2312: 8D 2D 2F
    LDA #&FF                     ; &2315: A9 FF
    STA SpaceKeyLatch                    ; &2317: 8D 23 2F
    STA EnterKeyLatch                    ; &231A: 8D 2B 2F
    STA TabKeyLatch                    ; &231D: 8D 0E 2F

NewScreen:
; Reconstruct the live playfield around a supplied world-X page: initialise
; ship position/acceleration, clear lasers and special slots, reset cached sprite
; pointers, set MODE 2 origin/HUD pointers and palettes, paint the full terrain
; surface and redraw score/lives/bombs.
    STA WorldLeftEdgeHi                    ; &2320: 8D 21 2F
    ASL A                        ; &2323: 0A
    STA WorldWindowX                    ; &2324: 8D 0A 2F
    LDA #&00                     ; &2327: A9 00
    STA WorldLeftEdgeLo                    ; &2329: 8D 20 2F
    LDA #&80                     ; &232C: A9 80
    STA UnitXLo                    ; &232E: 8D 00 04
    CLC                          ; &2331: 18
    LDA WorldLeftEdgeHi                    ; &2332: AD 21 2F
    ADC #&07                     ; &2335: 69 07
    STA UnitXHi                    ; &2337: 8D 25 04
    LDA #&00                     ; &233A: A9 00
    STA UnitYLo                    ; &233C: 8D 4A 04
    LDA #&64                     ; &233F: A9 64
    STA UnitYHi                    ; &2341: 8D 6F 04
    LDA #&07                     ; &2344: A9 07
    STA ShipAccelerationLo                    ; &2346: 8D 1C 2F
    LDA #&00                     ; &2349: A9 00
    STA ShipAccelerationHi                    ; &234B: 8D 1D 2F
    LDA #&00                     ; &234E: A9 00
    LDX #&03                     ; &2350: A2 03
ClearLaserSlotsLoop:
    STA LaserActive,X                  ; &2352: 9D DC 2E
    DEX                          ; &2355: CA
    BPL ClearLaserSlotsLoop                    ; &2356: 10 FA
    LDA #&FF                     ; &2358: A9 FF
    STA UnitType+HITCH_SLOT                    ; &235A: 8D BD 05
    LDX #&24                     ; &235D: A2 24
ClearProjectileSlotsLoop:
    LDA #&FF                     ; &235F: A9 FF
    STA UnitType,X                  ; &2361: 9D BC 05
    JSR ClearUnitData                    ; &2364: 20 20 24
    DEX                          ; &2367: CA
    CPX #&20                     ; &2368: E0 20
    BPL ClearProjectileSlotsLoop                    ; &236A: 10 F3
ResetAllUnitsForNewScreenLoop:
    JSR ResetUnitForNewScreen                    ; &236C: 20 06 24
    DEX                          ; &236F: CA
    BPL ResetAllUnitsForNewScreenLoop                    ; &2370: 10 FA
    LDA #&80                     ; &2372: A9 80
    STA UnitParam+HITCH_SLOT                    ; &2374: 8D E2 05
    LDA #&00                     ; &2377: A9 00
    STA UnitType                    ; &2379: 8D BC 05
    STA UnitDXLo                    ; &237C: 8D 94 04
    STA UnitDXHi                    ; &237F: 8D B9 04
    STA UnitAnim                    ; &2382: 8D 46 06
    STA PlayerDead                    ; &2385: 8D 24 2F
    STA PlayerCollisionMask                      ; &2388: 85 8B
    ; Initial player-sprite pointer was originally hard-coded as &2CC0.
    LDA #<ShipRightSprite       ; original &238A: A9 C0
    STA SpritePtrLoTable                    ; &238C: 8D 0B 2B
    LDA #>ShipRightSprite       ; original &238F: A9 2C
    STA SpritePtrHiTable                    ; &2391: 8D 16 2B
    LDA #&30                     ; &2394: A9 30
    STA SpriteLengths                    ; &2396: 8D 00 2B
    LDA #&00                     ; &2399: A9 00
    STA WorldWindowDelta                    ; &239B: 8D 2A 2F
    STA ScrollOffsetLo                    ; &239E: 8D 02 2F
    STA ScrollOffsetHi                    ; &23A1: 8D 03 2F
    LDA #&00                     ; &23A4: A9 00
    STA ScreenOriginLo                    ; &23A6: 8D 08 2F
    STA OldScreenOriginLo                    ; &23A9: 8D 00 2F
    LDA #&30                     ; &23AC: A9 30
    STA ScreenOriginHi                    ; &23AE: 8D 09 2F
    STA OldScreenOriginHi                    ; &23B1: 8D 01 2F
    STA DigitScreenPtrHi                    ; &23B4: 8D 2F 2F
    LDA #&D0                     ; &23B7: A9 D0
    STA DigitScreenPtrLo                    ; &23B9: 8D 2E 2F
    JSR WaitForVSync             ; &23BC: 20 12 0E
    LDA #&00                     ; &23BF: A9 00
ClearPaletteLoop:
    JSR WritePaletteColour       ; &23C1: 20 25 0E
    CLC                          ; &23C4: 18
    ADC #&10                     ; &23C5: 69 10
    BNE ClearPaletteLoop                    ; &23C7: D0 F8
    LDA #&00                     ; &23C9: A9 00
    JSR DrawStringByIndex        ; &23CB: 20 31 24
    LDA #&80                     ; &23CE: A9 80
RestorePaletteLoop:
    JSR WritePaletteColour       ; &23D0: 20 25 0E
    CLC                          ; &23D3: 18
    ADC #&11                     ; &23D4: 69 11
    BCC RestorePaletteLoop                    ; &23D6: 90 F8
    LDA #&47                     ; &23D8: A9 47
    JSR WritePaletteColour       ; &23DA: 20 25 0E
    LDA SurfacePalette                    ; &23DD: AD 42 2F
    JSR WritePaletteColour       ; &23E0: 20 25 0E
    LDA #&00                     ; &23E3: A9 00
    STA MinScreenX                    ; &23E5: 8D 28 2F
    LDA #&50                     ; &23E8: A9 50
    STA MaxScreenX                    ; &23EA: 8D 29 2F
    LDA WorldWindowX                    ; &23ED: AD 0A 2F
    STA SurfaceWindowEdges                    ; &23F0: 8D 0C 2F
    STA SurfaceWindowEdges+1                    ; &23F3: 8D 0D 2F
    LDX #&01                     ; &23F6: A2 01
    LDA #&50                     ; &23F8: A9 50
    LDY #&00                     ; &23FA: A0 00
    JSR PaintSurfaceRight                    ; &23FC: 20 BB 1D
    LDX #&00                     ; &23FF: A2 00
    LDY #&00                     ; &2401: A0 00
    JMP AddScoreBCD              ; &2403: 4C CA 24

ResetUnitForNewScreen:
; Normalise one unit while rebuilding a screen.  Exploded units are freed;
; warping units are restarted with Param=8; screen/radar pointers are cleared.
    LDA UnitAnim,X                  ; &2406: BD 46 06
    BEQ ClearUnitRadarPointer                    ; &2409: F0 0E
    BPL RestartUnitWarp                    ; &240B: 10 07
    LDA #&FF                     ; &240D: A9 FF
    STA UnitType,X                  ; &240F: 9D BC 05
    BNE ClearUnitRadarPointer                    ; &2412: D0 05

RestartUnitWarp:
    LDA #&08                     ; &2414: A9 08
    STA UnitParam,X                  ; &2416: 9D E1 05

ClearUnitRadarPointer:
    JSR ClearUnitScreenPointers                    ; &2419: 20 28 24
    STA UnitRadarPtrHi,X                  ; &241C: 9D 26 06
    RTS                          ; &241F: 60

ClearUnitData:
; Clear UnitAnim and UnitParam, then clear cached/next screen pointers.
    LDA #&00                     ; &2420: A9 00
    STA UnitAnim,X                  ; &2422: 9D 46 06
    STA UnitParam,X                  ; &2425: 9D E1 05
; Clear cached/next sprite screen pointers for unit X.
ClearUnitScreenPointers:
    LDA #&00                     ; &2428: A9 00
    STA UnitNextPtrHi,X                  ; &242A: 9D 97 05
    STA UnitSpritePtrHi,X                  ; &242D: 9D 4D 05
    RTS                          ; &2430: 60

DrawStringByIndex:
; Print one length-prefixed VDU/control-code string through OSWRCH using the
; pointer table at &2FC8/&2FCC.
    TAX                          ; &2431: AA
    LDA StringPointerLo,X                  ; &2432: BD C8 2F
    STA DestPtrLo                      ; &2435: 85 70
    LDA StringPointerHi,X                  ; &2437: BD CC 2F
    STA DestPtrHi                      ; &243A: 85 71
    LDY #&00                     ; &243C: A0 00
    LDA (DestPtrLo),Y                  ; &243E: B1 70
    STA TempLo                      ; &2440: 85 76
DrawStringCharacterLoop:
    INY                          ; &2442: C8
    LDA (DestPtrLo),Y                  ; &2443: B1 70
    JSR OSWRCH                    ; &2445: 20 EE FF
    CPY TempLo                      ; &2448: C4 76
    BNE DrawStringCharacterLoop                    ; &244A: D0 F6
    RTS                          ; &244C: 60

ScoreUnit:
; Look up the destroyed unit's two-byte BCD point value and pass it to
; AddScoreBCD while preserving X and Y.
    TXA                          ; &244D: 8A
    PHA                          ; &244E: 48
    TYA                          ; &244F: 98
    PHA                          ; &2450: 48
    LDA UnitType,X                  ; &2451: BD BC 05
    CMP #&FF                     ; &2454: C9 FF
    BEQ ReturnFromScoreUnit                    ; &2456: F0 0E
    AND #&7F                     ; &2458: 29 7F
    TAX                          ; &245A: AA
    LDA PointsHiTable,X                  ; &245B: BD 4D 2B
    TAY                          ; &245E: A8
    LDA PointsLoTable,X                  ; &245F: BD 42 2B
    TAX                          ; &2462: AA
    JSR AddScoreBCD              ; &2463: 20 CA 24

ReturnFromScoreUnit:
    PLA                          ; &2466: 68
    TAY                          ; &2467: A8
    PLA                          ; &2468: 68
    TAX                          ; &2469: AA
    RTS                          ; &246A: 60

Spawn500ScorePopup:
    TYA                          ; &246B: 98
    PHA                          ; &246C: 48
    TXA                          ; &246D: 8A
    PHA                          ; &246E: 48
    LDY #&05                     ; &246F: A0 05
    LDX #&00                     ; &2471: A2 00
    JSR AddScoreBCD              ; &2473: 20 CA 24
    PLA                          ; &2476: 68
    TAX                          ; &2477: AA
    JSR FindFreeUnitSlot         ; &2478: 20 DE 19
    BCS ReturnFromScore500Popup                    ; &247B: B0 31
    LDA #&8A                     ; &247D: A9 8A
    STA UnitType,Y                  ; &247F: 99 BC 05
ScorePopupVerticalAdjustLoop:
    CLC                          ; &2482: 18
    LDA UnitYHi,Y                  ; &2483: B9 6F 04
    ADC #&0C                     ; &2486: 69 0C
    STA UnitYHi,Y                  ; &2488: 99 6F 04
    LDA UnitDXHi                    ; &248B: AD B9 04
    ASL A                        ; &248E: 0A
    LDA UnitDXHi                    ; &248F: AD B9 04
    ROR A                        ; &2492: 6A
    STA UnitDXHi,Y                  ; &2493: 99 B9 04
    LDA UnitDXLo                    ; &2496: AD 94 04
    ROR A                        ; &2499: 6A
    STA UnitDXLo,Y                  ; &249A: 99 94 04
    LDA #&00                     ; &249D: A9 00
    STA UnitDYHi,Y                  ; &249F: 99 03 05
    STA UnitDYLo,Y                  ; &24A2: 99 DE 04
    SEC                          ; &24A5: 38
    LDA UnitXHi,Y                  ; &24A6: B9 25 04
    SBC #&01                     ; &24A9: E9 01
    STA UnitXHi,Y                  ; &24AB: 99 25 04

ReturnFromScore500Popup:
    PLA                          ; &24AE: 68
    TAY                          ; &24AF: A8
    RTS                          ; &24B0: 60

Spawn250ScorePopup:
    TYA                          ; &24B1: 98
    PHA                          ; &24B2: 48
    TXA                          ; &24B3: 8A
    PHA                          ; &24B4: 48
    LDY #&02                     ; &24B5: A0 02
    LDX #&50                     ; &24B7: A2 50
    JSR AddScoreBCD              ; &24B9: 20 CA 24
    PLA                          ; &24BC: 68
    TAX                          ; &24BD: AA
    JSR FindFreeUnitSlot         ; &24BE: 20 DE 19
    BCS ReturnFromScore500Popup                    ; &24C1: B0 EB
    LDA #&89                     ; &24C3: A9 89
    STA UnitType,Y                  ; &24C5: 99 BC 05
    BNE ScorePopupVerticalAdjustLoop                    ; &24C8: D0 B8

AddScoreBCD:
; Add a two-byte packed-BCD award (X low byte, Y high byte) into the three-byte
; ScoreBCD, redraw HUD digits and award an extra life + smart bomb on carry out of
; the high score byte threshold used by this version.
    SED                          ; &24CA: F8
    CLC                          ; &24CB: 18
    TXA                          ; &24CC: 8A
    ADC ScoreBCD                    ; &24CD: 6D 30 2F
    STA ScoreBCD                    ; &24D0: 8D 30 2F
    TYA                          ; &24D3: 98
    ADC ScoreBCD+1                    ; &24D4: 6D 31 2F
    STA ScoreBCD+1                    ; &24D7: 8D 31 2F
    PHP                          ; &24DA: 08
    LDA #&00                     ; &24DB: A9 00
    ADC ScoreBCD+2                    ; &24DD: 6D 32 2F
    STA ScoreBCD+2                    ; &24E0: 8D 32 2F
    PLP                          ; &24E3: 28
    CLD                          ; &24E4: D8
    BCC RedrawScoreAndResources                    ; &24E5: 90 03
    JSR AwardExtraLifeAndBomb    ; &24E7: 20 51 26

RedrawScoreAndResources:
    LDA DigitScreenPtrLo                    ; &24EA: AD 2E 2F
    STA DestPtrLo                      ; &24ED: 85 70
    LDA DigitScreenPtrHi                    ; &24EF: AD 2F 2F
    STA DestPtrHi                      ; &24F2: 85 71
    LDA #&00                     ; &24F4: A9 00
    STA LeadingZeroState                    ; &24F6: 8D 33 2F
    LDX #&02                     ; &24F9: A2 02
DrawScoreByteLoop:
    LDA ScoreBCD,X                  ; &24FB: BD 30 2F
    JSR DrawBCDDigits            ; &24FE: 20 21 25
    DEX                          ; &2501: CA
    BPL DrawScoreByteLoop                    ; &2502: 10 F7
    LDA #&00                     ; &2504: A9 00
    STA LeadingZeroState                    ; &2506: 8D 33 2F
    JSR DrawOneBCDNibble                    ; &2509: 20 35 25
    LDX #&00                     ; &250C: A2 00
    LDA LivesBCD                    ; &250E: AD 37 2F
    JSR DrawBCDDigits            ; &2511: 20 21 25
    LDA #&00                     ; &2514: A9 00
    STA LeadingZeroState                    ; &2516: 8D 33 2F
    JSR DrawOneBCDNibble                    ; &2519: 20 35 25
    LDX #&00                     ; &251C: A2 00
    LDA SmartBombsBCD                    ; &251E: AD 38 2F

DrawBCDDigits:
; Render one packed-BCD byte as two digit sprites into the circular MODE 2 HUD
; buffer, suppressing leading zeroes until a non-zero digit is encountered.
    PHA                          ; &2521: 48
    AND #&F0                     ; &2522: 29 F0
    JSR DrawOneBCDNibble                    ; &2524: 20 35 25
    CPX #&00                     ; &2527: E0 00
    BNE DrawLowBCDNibble                    ; &2529: D0 05
    LDA #&01                     ; &252B: A9 01
    STA LeadingZeroState                    ; &252D: 8D 33 2F

DrawLowBCDNibble:
    PLA                          ; &2530: 68
    ASL A                        ; &2531: 0A
    ASL A                        ; &2532: 0A
    ASL A                        ; &2533: 0A
    ASL A                        ; &2534: 0A

DrawOneBCDNibble:
    STX TempLo                      ; &2535: 86 76
    TAX                          ; &2537: AA
    ORA LeadingZeroState                    ; &2538: 0D 33 2F
    STA LeadingZeroState                    ; &253B: 8D 33 2F
    LDY #&00                     ; &253E: A0 00
DrawDigitRowLoop:
    LDA LeadingZeroState                    ; &2540: AD 33 2F
    BEQ AdvanceDigitSpriteByte                    ; &2543: F0 05
    LDA DigitSprites,X                  ; &2545: BD 00 2C
    STA (DestPtrLo),Y                  ; &2548: 91 70

AdvanceDigitSpriteByte:
    INY                          ; &254A: C8
    INX                          ; &254B: E8
    TYA                          ; &254C: 98
    AND #&07                     ; &254D: 29 07
    TAY                          ; &254F: A8
    BNE FinishDigitGlyph                    ; &2550: D0 14
    CLC                          ; &2552: 18
    LDA DestPtrLo                      ; &2553: A5 70
    ADC #&08                     ; &2555: 69 08
    STA DestPtrLo                      ; &2557: 85 70
    BCC FinishDigitGlyph                    ; &2559: 90 0B
    INC DestPtrHi                      ; &255B: E6 71
    BPL FinishDigitGlyph                    ; &255D: 10 07
    LDA DestPtrHi                      ; &255F: A5 71
    SEC                          ; &2561: 38
    SBC #&50                     ; &2562: E9 50
    STA DestPtrHi                      ; &2564: 85 71

FinishDigitGlyph:
    TXA                          ; &2566: 8A
    AND #&0F                     ; &2567: 29 0F
    BNE DrawDigitRowLoop                    ; &2569: D0 D5
    LDX TempLo                      ; &256B: A6 76
    RTS                          ; &256D: 60

RepaintDigits:
; Repair/shift the score/lives/bombs HUD rows after the CRTC origin moves.
; Copies 8-byte vertical strips within circular MODE 2 RAM using ScrollOffset and
; WorldWindowDelta.
    LDY #&00                     ; &256E: A0 00
    LDA ScrollOffsetLo                    ; &2570: AD 02 2F
    BPL InitialiseDigitScrollDirection                    ; &2573: 10 02
    LDY #&FF                     ; &2575: A0 FF

InitialiseDigitScrollDirection:
    STY TempLo                      ; &2577: 84 76
    CLC                          ; &2579: 18
    LDA DigitScreenPtrLo                    ; &257A: AD 2E 2F
    STA SourcePtrLo                      ; &257D: 85 72
    ADC ScrollOffsetLo                    ; &257F: 6D 02 2F
    STA DestPtrLo                      ; &2582: 85 70
    STA DigitScreenPtrLo                    ; &2584: 8D 2E 2F
    LDA DigitScreenPtrHi                    ; &2587: AD 2F 2F
    STA SourcePtrHi                      ; &258A: 85 73
    ADC TempLo                      ; &258C: 65 76
    BPL WrapDigitDestPointerHigh                    ; &258E: 10 03
    SEC                          ; &2590: 38
    SBC #&50                     ; &2591: E9 50

WrapDigitDestPointerHigh:
    CMP #&30                     ; &2593: C9 30
    BCS StoreDigitDestPointer                    ; &2595: B0 02
    ADC #&50                     ; &2597: 69 50

StoreDigitDestPointer:
    STA DestPtrHi                      ; &2599: 85 71
    STA DigitScreenPtrHi                    ; &259B: 8D 2F 2F
    LDA #&FF                     ; &259E: A9 FF
    EOR TempLo                      ; &25A0: 45 76
    STA TempHi                      ; &25A2: 85 77
    LDA #&08                     ; &25A4: A9 08
    STA TempLo                      ; &25A6: 85 76
    SEC                          ; &25A8: 38
    LDA #&18                     ; &25A9: A9 18
    SBC WorldWindowDelta                    ; &25AB: ED 2A 2F
    BIT WorldWindowDelta                    ; &25AE: 2C 2A 2F
    BMI CopyNextDigitColumn                    ; &25B1: 30 32
    CLC                          ; &25B3: 18
    LDA DestPtrLo                      ; &25B4: A5 70
    ADC #&B8                     ; &25B6: 69 B8
    STA DestPtrLo                      ; &25B8: 85 70
    BCC AdvanceDigitSourceStart                    ; &25BA: 90 0B
    INC DestPtrHi                      ; &25BC: E6 71
    BPL AdvanceDigitSourceStart                    ; &25BE: 10 07
    SEC                          ; &25C0: 38
    LDA DestPtrHi                      ; &25C1: A5 71
    SBC #&50                     ; &25C3: E9 50
    STA DestPtrHi                      ; &25C5: 85 71

AdvanceDigitSourceStart:
    CLC                          ; &25C7: 18
    LDA SourcePtrLo                      ; &25C8: A5 72
    ADC #&B8                     ; &25CA: 69 B8
    STA SourcePtrLo                      ; &25CC: 85 72
    BCC PrepareReverseDigitCopy                    ; &25CE: 90 0B
    INC SourcePtrHi                      ; &25D0: E6 73
    BPL PrepareReverseDigitCopy                    ; &25D2: 10 07
    SEC                          ; &25D4: 38
    LDA SourcePtrHi                      ; &25D5: A5 73
    SBC #&50                     ; &25D7: E9 50
    STA SourcePtrHi                      ; &25D9: 85 73

PrepareReverseDigitCopy:
    LDA #&F8                     ; &25DB: A9 F8
    STA TempLo                      ; &25DD: 85 76
    CLC                          ; &25DF: 18
    LDA #&18                     ; &25E0: A9 18
    ADC WorldWindowDelta                    ; &25E2: 6D 2A 2F

CopyNextDigitColumn:
    TAX                          ; &25E5: AA
CopyNextDigitColumnLoop:
    LDY #&07                     ; &25E6: A0 07
CopyDigitColumnByteLoop:
    LDA (SourcePtrLo),Y                  ; &25E8: B1 72
    STA (DestPtrLo),Y                  ; &25EA: 91 70
    DEY                          ; &25EC: 88
    BPL CopyDigitColumnByteLoop                    ; &25ED: 10 F9
    CLC                          ; &25EF: 18
    LDA SourcePtrLo                      ; &25F0: A5 72
    ADC TempLo                      ; &25F2: 65 76
    STA SourcePtrLo                      ; &25F4: 85 72
    LDA TempHi                      ; &25F6: A5 77
    ADC SourcePtrHi                      ; &25F8: 65 73
    BPL WrapDigitSourceHigh                    ; &25FA: 10 03
    SEC                          ; &25FC: 38
    SBC #&50                     ; &25FD: E9 50

WrapDigitSourceHigh:
    CMP #&30                     ; &25FF: C9 30
    BCS StoreDigitSourceHigh                    ; &2601: B0 02
    ADC #&50                     ; &2603: 69 50

StoreDigitSourceHigh:
    STA SourcePtrHi                      ; &2605: 85 73
    CLC                          ; &2607: 18
    LDA DestPtrLo                      ; &2608: A5 70
    ADC TempLo                      ; &260A: 65 76
    STA DestPtrLo                      ; &260C: 85 70
    LDA TempHi                      ; &260E: A5 77
    ADC DestPtrHi                      ; &2610: 65 71
    BPL WrapDigitDestinationHigh                    ; &2612: 10 03
    SEC                          ; &2614: 38
    SBC #&50                     ; &2615: E9 50

WrapDigitDestinationHigh:
    CMP #&30                     ; &2617: C9 30
    BCS StoreDigitDestinationHigh                    ; &2619: B0 02
    ADC #&50                     ; &261B: 69 50

StoreDigitDestinationHigh:
    STA DestPtrHi                      ; &261D: 85 71
    DEX                          ; &261F: CA
    BNE CopyNextDigitColumnLoop                    ; &2620: D0 C4
    RTS                          ; &2622: 60

ResetGameState:
; Initial game state: 10 humans, base Lander speed, zero shot speed, AI batch
; size 5, 3 lives, 3 smart bombs, zero score/level, intact planet.
    LDA #&0A                     ; &2623: A9 0A
    STA HumanCount                    ; &2625: 8D 15 2F
    LDA #&08                     ; &2628: A9 08
    STA DXMinInit+LANDER                    ; &262A: 8D 87 2F
    LDA #&00                     ; &262D: A9 00
    STA EnemyShotSpeed                    ; &262F: 8D 3A 2F
    LDA #&05                     ; &2632: A9 05
    STA AIBatchSize                    ; &2634: 8D 25 2F
    LDA #&03                     ; &2637: A9 03
    STA LivesBCD                    ; &2639: 8D 37 2F
    STA SmartBombsBCD                    ; &263C: 8D 38 2F
    LDA #&00                     ; &263F: A9 00
    STA ScoreBCD                    ; &2641: 8D 30 2F
    STA ScoreBCD+1                    ; &2644: 8D 31 2F
    STA ScoreBCD+2                    ; &2647: 8D 32 2F
    STA LevelBCD                    ; &264A: 8D 16 2F
    STA NoPlanet                    ; &264D: 8D 1A 2F
    RTS                          ; &2650: 60

AwardExtraLifeAndBomb:
; Increment packed-BCD LivesBCD and SmartBombsBCD and play the reward sound.
    SED                          ; &2651: F8
    CLC                          ; &2652: 18
    LDA LivesBCD                    ; &2653: AD 37 2F
    ADC #&01                     ; &2656: 69 01
    STA LivesBCD                    ; &2658: 8D 37 2F
    CLC                          ; &265B: 18
    LDA SmartBombsBCD                    ; &265C: AD 38 2F
    ADC #&01                     ; &265F: 69 01
    STA SmartBombsBCD                    ; &2661: 8D 38 2F
    CLD                          ; &2664: D8
    LDA #&12                     ; &2665: A9 12
    JMP PlaySound                ; &2667: 4C 7D 12

DoGameFrames:
; Run FrameNoDeathCheck X times while preserving the loop count around each
; frame call.
    TXA                          ; &266A: 8A
    PHA                          ; &266B: 48
    JSR FrameNoDeathCheck                    ; &266C: 20 BD 18
    PLA                          ; &266F: 68
    TAX                          ; &2670: AA
    DEX                          ; &2671: CA
    BNE DoGameFrames                    ; &2672: D0 F6
    RTS                          ; &2674: 60

GameFrame:
; Core frame workload: lasers, ship/hitchhikers, HUD repair, minimap, special
; projectile slots, rotating alternate slots, AI batch, VSync/palette work,
; terrain scroll, sprite repaint, ship collision, Baiter timer and ESC acknowledge.
    JSR UpdateLasers             ; &2675: 20 4A 14
    JSR UpdateShipAndControls                    ; &2678: 20 3E 1E
    JSR UpdateHitchhiker                    ; &267B: 20 95 1F
    JSR RepaintDigits          ; &267E: 20 6E 25
    JSR RepaintMinimap                    ; &2681: 20 D1 12
    LDX #&20                     ; &2684: A2 20
    JSR ProcessUnitAI            ; &2686: 20 A1 0E
    LDX #&21                     ; &2689: A2 21
    JSR ProcessUnitAI            ; &268B: 20 A1 0E
    JSR UpdateSpecialUnitRoundRobin ; &268E: 20 90 0E
    JSR UpdateSpecialUnitRoundRobin ; &2691: 20 90 0E
    JSR UpdateSpecialUnitRoundRobin ; &2694: 20 90 0E
    JSR UpdateUnitAIBatch        ; &2697: 20 44 0E
    JSR NextFrame                    ; &269A: 20 37 1D
    JSR ScrollSurface                    ; &269D: 20 D4 20
    JSR RepaintAllUnits                    ; &26A0: 20 5B 20
    JSR CheckPlayerCollision                    ; &26A3: 20 8D 21
    JSR UpdateBaiterTimer        ; &26A6: 20 4C 17
    LDA #&7E                     ; &26A9: A9 7E
    JMP OSBYTE                    ; &26AB: 4C F4 FF

UpdateUnitAnimation:
; Advance warp/explosion animation state for one unit and update its render/
; type state when the transition completes.
    LDA UnitParam,X                  ; &26AE: BD E1 05
    CMP #&08                     ; &26B1: C9 08
    BEQ UpdateWarpAnimation                    ; &26B3: F0 3B
    LDA ScreenOriginLo                    ; &26B5: AD 08 2F
    PHA                          ; &26B8: 48
    LDA ScreenOriginHi                    ; &26B9: AD 09 2F
    PHA                          ; &26BC: 48
    LDA WorldLeftEdgeLo                    ; &26BD: AD 20 2F
    PHA                          ; &26C0: 48
    LDA WorldLeftEdgeHi                    ; &26C1: AD 21 2F
    PHA                          ; &26C4: 48
    LDA UnitNextPtrLo,X                  ; &26C5: BD 72 05
    STA ScreenOriginLo                    ; &26C8: 8D 08 2F
    LDA UnitNextPtrHi,X                  ; &26CB: BD 97 05
    STA ScreenOriginHi                    ; &26CE: 8D 09 2F
    LDA UnitSpritePtrLo,X                  ; &26D1: BD 28 05
    STA WorldLeftEdgeLo                    ; &26D4: 8D 20 2F
    LDA UnitSpritePtrHi,X                  ; &26D7: BD 4D 05
    STA WorldLeftEdgeHi                    ; &26DA: 8D 21 2F
    JSR DrawUnitExplosion        ; &26DD: 20 3A 27
    PLA                          ; &26E0: 68
    STA WorldLeftEdgeHi                    ; &26E1: 8D 21 2F
    PLA                          ; &26E4: 68
    STA WorldLeftEdgeLo                    ; &26E5: 8D 20 2F
    PLA                          ; &26E8: 68
    STA ScreenOriginHi                    ; &26E9: 8D 09 2F
    PLA                          ; &26EC: 68
    STA ScreenOriginLo                    ; &26ED: 8D 08 2F

UpdateWarpAnimation:
    LDY UnitParam,X                  ; &26F0: BC E1 05
    DEY                          ; &26F3: 88
    TYA                          ; &26F4: 98
    STA UnitParam,X                  ; &26F5: 9D E1 05
    BEQ FinishUnitAnimation                    ; &26F8: F0 1B
    LDA ScreenOriginLo                    ; &26FA: AD 08 2F
    STA UnitNextPtrLo,X                  ; &26FD: 9D 72 05
    LDA ScreenOriginHi                    ; &2700: AD 09 2F
    STA UnitNextPtrHi,X                  ; &2703: 9D 97 05
    LDA WorldLeftEdgeLo                    ; &2706: AD 20 2F
    STA UnitSpritePtrLo,X                  ; &2709: 9D 28 05
    LDA WorldLeftEdgeHi                    ; &270C: AD 21 2F
    STA UnitSpritePtrHi,X                  ; &270F: 9D 4D 05
    JMP DrawUnitExplosion        ; &2712: 4C 3A 27

FinishUnitAnimation:
    LDA UnitAnim,X                  ; &2715: BD 46 06
    BMI FreeExplodedUnit                    ; &2718: 30 18
    CPX #&00                     ; &271A: E0 00
    BNE ClearCompletedAnimation                    ; &271C: D0 08
    ASL A                        ; &271E: 0A
    BPL ClearCompletedAnimation                    ; &271F: 10 05
    LDA #&01                     ; &2721: A9 01
    STA PlayerDead                    ; &2723: 8D 24 2F

ClearCompletedAnimation:
    LDA #&00                     ; &2726: A9 00
    STA UnitAnim,X                  ; &2728: 9D 46 06
    STA UnitSpritePtrHi,X                  ; &272B: 9D 4D 05
    STA UnitNextPtrHi,X                  ; &272E: 9D 97 05
    RTS                          ; &2731: 60

FreeExplodedUnit:
    LDA #&FF                     ; &2732: A9 FF
    STA UnitType,X                  ; &2734: 9D BC 05
    JMP InitialiseUnit           ; &2737: 4C 6C 17

DrawUnitExplosion:
; Render the eight-point warp/explosion pattern around a unit.  Two related
; coordinate-scaling helpers generate the expanding/contracting points and the
; unit's radar/sprite mask supplies the XOR pixel.
    LDA MinScreenX                    ; &273A: AD 28 2F
    PHA                          ; &273D: 48
    LDA MaxScreenX                    ; &273E: AD 29 2F
    PHA                          ; &2741: 48
    LDA #&00                     ; &2742: A9 00
    STA MinScreenX                    ; &2744: 8D 28 2F
    LDA #&50                     ; &2747: A9 50
    STA MaxScreenX                    ; &2749: 8D 29 2F
    JSR GetUnitScreenX                    ; &274C: 20 3B 20
    CMP #&64                     ; &274F: C9 64
    BPL RestoreExplosionClipWindow                    ; &2751: 10 51
    CMP #&EC                     ; &2753: C9 EC
    BMI RestoreExplosionClipWindow                    ; &2755: 30 4D
    STA &7A                      ; &2757: 85 7A
    LDA UnitAnim,X                  ; &2759: BD 46 06
    BMI DrawExpandingExplosionPoints                    ; &275C: 30 4F
    LDA UnitParam,X                  ; &275E: BD E1 05
    CMP #&07                     ; &2761: C9 07
    BNE DrawContractingExplosionPoints                    ; &2763: D0 05
    LDA #&06                     ; &2765: A9 06
    JSR PlaySound                ; &2767: 20 7D 12

DrawContractingExplosionPoints:
    LDY #&07                     ; &276A: A0 07
ContractingExplosionPointLoop:
    STY SavedY                      ; &276C: 84 86
    LDX &7A                      ; &276E: A6 7A
    LDA WarpX,Y                  ; &2770: B9 50 2A
    JSR ScaleExplosionVector                    ; &2773: 20 09 28
    PHA                          ; &2776: 48
    LDX CurrentUnit                      ; &2777: A6 89
    LDA UnitYHi,X                  ; &2779: BD 6F 04
    TAX                          ; &277C: AA
    LDA WarpY,Y                  ; &277D: B9 58 2A
    JSR ScaleExplosionVector                    ; &2780: 20 09 28
    TAY                          ; &2783: A8
    PLA                          ; &2784: 68
    TAX                          ; &2785: AA
    JSR XYToVideoPtr                    ; &2786: 20 6D 1C
    LDA DestPtrHi                      ; &2789: A5 71
    BEQ NextExplosionPoint                    ; &278B: F0 10
    LDY #&00                     ; &278D: A0 00
    LDX CurrentUnit                      ; &278F: A6 89
    LDA UnitType,X                  ; &2791: BD BC 05
    ASL A                        ; &2794: 0A
    TAX                          ; &2795: AA
    LDA RadarSpriteData,X                  ; &2796: BD 21 2B
    EOR (DestPtrLo),Y                  ; &2799: 51 70
    STA (DestPtrLo),Y                  ; &279B: 91 70

NextExplosionPoint:
    LDY SavedY                      ; &279D: A4 86
    DEY                          ; &279F: 88
    BPL ContractingExplosionPointLoop                    ; &27A0: 10 CA
    LDX CurrentUnit                      ; &27A2: A6 89

RestoreExplosionClipWindow:
    PLA                          ; &27A4: 68
    STA MaxScreenX                    ; &27A5: 8D 29 2F
    PLA                          ; &27A8: 68
    STA MinScreenX                    ; &27A9: 8D 28 2F
    RTS                          ; &27AC: 60

DrawExpandingExplosionPoints:
    LDY #&07                     ; &27AD: A0 07
ExpandingExplosionPointLoop:
    LDA &7A                      ; &27AF: A5 7A
    LDX BlastX,Y                  ; &27B1: BE 60 2A
    JSR InterpolateExplosionCoordinate                    ; &27B4: 20 ED 27
    PHA                          ; &27B7: 48
    LDA UnitYHi,X                  ; &27B8: BD 6F 04
    LDX BlastY,Y                  ; &27BB: BE 68 2A
    JSR InterpolateExplosionCoordinate                    ; &27BE: 20 ED 27
    TAY                          ; &27C1: A8
    PLA                          ; &27C2: 68
    TAX                          ; &27C3: AA
    CPY #&C0                     ; &27C4: C0 C0
    BCS ContinueExpandingExplosion                    ; &27C6: B0 1B
    JSR XYToVideoPtr                    ; &27C8: 20 6D 1C
    LDA DestPtrHi                      ; &27CB: A5 71
    BEQ ContinueExpandingExplosion                    ; &27CD: F0 14
    LDY #&00                     ; &27CF: A0 00
    LDX CurrentUnit                      ; &27D1: A6 89
    LDA UnitType,X                  ; &27D3: BD BC 05
    ASL A                        ; &27D6: 0A
    TAX                          ; &27D7: AA
    LDA RadarSpriteData,X                  ; &27D8: BD 21 2B
    EOR (DestPtrLo),Y                  ; &27DB: 51 70
    STA (DestPtrLo),Y                  ; &27DD: 91 70
    JMP ContinueExpandingExplosion                    ; &27DF: 4C E3 27
    EQUB &68 ; &27E2

ContinueExpandingExplosion:
    LDX CurrentUnit                      ; &27E3: A6 89
    LDY SavedY                      ; &27E5: A4 86
    DEY                          ; &27E7: 88
    BPL ExpandingExplosionPointLoop                    ; &27E8: 10 C5
    JMP RestoreExplosionClipWindow                    ; &27EA: 4C A4 27

InterpolateExplosionCoordinate:
    STY SavedY                      ; &27ED: 84 86
    STX TempLo                      ; &27EF: 86 76
    LDX CurrentUnit                      ; &27F1: A6 89
    PHA                          ; &27F3: 48
    SEC                          ; &27F4: 38
    LDA #&08                     ; &27F5: A9 08
    SBC UnitParam,X                  ; &27F7: FD E1 05
    TAY                          ; &27FA: A8
    PLA                          ; &27FB: 68
InterpolationAddLoop:
    CLC                          ; &27FC: 18
    ADC TempLo                      ; &27FD: 65 76
    DEY                          ; &27FF: 88
    BNE InterpolationAddLoop                    ; &2800: D0 FA
    PHP                          ; &2802: 08
    LDY SavedY                      ; &2803: A4 86
    LDX CurrentUnit                      ; &2805: A6 89
    PLP                          ; &2807: 28
    RTS                          ; &2808: 60

ScaleExplosionVector:
    STX SavedX                      ; &2809: 86 85
    SEC                          ; &280B: 38
    SBC SavedX                      ; &280C: E5 85
    STA TempLo                      ; &280E: 85 76
    LDA #&00                     ; &2810: A9 00
    SBC #&00                     ; &2812: E9 00
    STA TempHi                      ; &2814: 85 77
    LDA #&00                     ; &2816: A9 00
    STA SourcePtrLo                      ; &2818: 85 72
    STA SourcePtrHi                      ; &281A: 85 73
    LDX CurrentUnit                      ; &281C: A6 89
    LDA UnitParam,X                  ; &281E: BD E1 05
    TAX                          ; &2821: AA
ScaleExplosionAddLoop:
    CLC                          ; &2822: 18
    LDA SourcePtrLo                      ; &2823: A5 72
    ADC TempLo                      ; &2825: 65 76
    STA SourcePtrLo                      ; &2827: 85 72
    LDA SourcePtrHi                      ; &2829: A5 73
    ADC TempHi                      ; &282B: 65 77
    STA SourcePtrHi                      ; &282D: 85 73
    DEX                          ; &282F: CA
    BNE ScaleExplosionAddLoop                    ; &2830: D0 F0
    LDA SourcePtrLo                      ; &2832: A5 72
    LSR SourcePtrHi                      ; &2834: 46 73
    ROR A                        ; &2836: 6A
    LSR SourcePtrHi                      ; &2837: 46 73
    ROR A                        ; &2839: 6A
    LSR SourcePtrHi                      ; &283A: 46 73
    ROR A                        ; &283C: 6A
    CLC                          ; &283D: 18
    ADC SavedX                      ; &283E: 65 85
    RTS                          ; &2840: 60
    EQUB &60 ; &2841

GetSurfaceY:
; Return terrain height SurfaceY[world X page] for unit X.
    LDA UnitXLo,X                  ; &2842: BD 00 04
    ASL A                        ; &2845: 0A
    LDA UnitXHi,X                  ; &2846: BD 25 04
    ROL A                        ; &2849: 2A
    TAY                          ; &284A: A8
    LDA SurfaceY,Y                  ; &284B: B9 00 29
    RTS                          ; &284E: 60

IsUnlinked:
    STX TempHi                      ; &284F: 86 77
    LDX #&00                     ; &2851: A2 00
    JSR IsLinked                    ; &2853: 20 5B 28
    PHP                          ; &2856: 08
    LDX TempHi                      ; &2857: A6 77
    PLP                          ; &2859: 28
    RTS                          ; &285A: 60

IsLinked:
; Compare unit Y's type and Param link field against a requested type/link ID.
; Used heavily by Lander/Human abduction logic.
    EOR UnitType,Y                  ; &285B: 59 BC 05
    AND #&7F                     ; &285E: 29 7F
    BNE ReturnLinkTest                    ; &2860: D0 0C
    STX TempLo                      ; &2862: 86 76
    LDA UnitParam,Y                  ; &2864: B9 E1 05
    CMP TempLo                      ; &2867: C5 76
    BNE ReturnLinkTest                    ; &2869: D0 03
    LDA UnitAnim,Y                  ; &286B: B9 46 06

ReturnLinkTest:
    RTS                          ; &286E: 60

; &286F-&28BF: 81 bytes with no executable references, pointer references or
; indexed-table consumers in Defender V1.  The final 32 bytes (&28A0-&28BF)
; exactly match the later Planetoid pre-SurfaceQuadrants block that its
; independent disassembly explicitly identifies as unused.  The preceding
; 49 bytes are likewise unreachable in this V1 image and appear to be older
; filler/vestigial data rather than a live terrain table.
UnusedPreSurfaceData:
    EQUB &00,&08,&00,&00,&08,&00,&00,&04 ; &286F
    EQUB &04,&00,&00,&04,&00,&04,&00,&04 ; &2877
    EQUB &00,&04,&00,&00,&04,&00,&04,&04 ; &287F
    EQUB &04,&04,&04,&04,&04,&04,&04,&04 ; &2887
    EQUB &04,&04,&04,&04,&04,&04,&04,&04 ; &288F
    EQUB &04,&04,&04,&04,&04,&08,&08,&08 ; &2897
    EQUB &00,&00,&08,&00,&08,&00,&08,&00 ; &289F
    EQUB &00,&00,&00,&04,&04,&04,&08,&08 ; &28A7
    EQUB &04,&04,&04,&04,&04,&04,&04,&04 ; &28AF
    EQUB &04,&04,&04,&04,&04,&04,&04,&04 ; &28B7
    EQUB &04                         ; &28BF
SurfaceQuadrants:
    ; 64 packed bytes, four 2-bit terrain selectors per byte -> 256 world X cells.
    EQUB &2A,&00,&55,&55,&65,&66,&9A ; &28C0
    EQUB &A9,&00,&01,&44,&55,&55,&55,&A5 ; &28C7
    EQUB &2A,&80,&2A,&08,&42,&55,&55,&55 ; &28CF
    EQUB &66,&66,&A6,&A6,&09,&82,&50,&10 ; &28D7
    EQUB &11,&41,&54,&55,&55,&55,&55,&55 ; &28DF
    EQUB &2A,&88,&08,&50,&69,&55,&55,&55 ; &28E7
    EQUB &55,&55,&55,&55,&55,&99,&A9,&99 ; &28EF
    EQUB &99,&19,&50,&40,&14,&54,&55,&55 ; &28F7
    EQUB &95 ; original &28FF
SurfaceY:
    EQUB &22,&26,&2A,&2C,&28,&24,&20 ; original &2900
    EQUB &1C,&19,&19,&19,&19,&19,&19,&19 ; &2907
    EQUB &19,&19,&19,&1A,&1D,&1E,&21,&22 ; &290F
    EQUB &25,&26,&2A,&2D,&2E,&31,&32,&36 ; &2917
    EQUB &3A,&3C,&38,&34,&30,&2D,&2C,&28 ; &291F
    EQUB &24,&20,&1D,&1C,&19,&19,&19,&19 ; &2927
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &292F
    EQUB &19,&19,&19,&1A,&1E,&22,&26,&2A ; &2937
    EQUB &2C,&28,&24,&20,&1E,&22,&26,&2A ; &293F
    EQUB &2C,&28,&26,&28,&24,&22,&24,&20 ; &2947
    EQUB &1D,&1D,&1D,&1D,&1D,&1D,&1D,&1D ; &294F
    EQUB &1D,&1D,&1D,&1D,&1D,&1E,&21,&22 ; &2957
    EQUB &25,&26,&29,&2A,&2D,&2E,&31,&32 ; &295F
    EQUB &36,&3A,&3D,&3E,&42,&45,&46,&48 ; &2967
    EQUB &44,&42,&44,&40,&3E,&40,&3C,&39 ; &296F
    EQUB &39,&38,&34,&31,&30,&2D,&2C,&29 ; &2977
    EQUB &28,&25,&24,&20,&1D,&1C,&19,&19 ; &297F
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &2987
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &298F
    EQUB &19,&19,&19,&19,&19,&1A,&1E,&22 ; &2997
    EQUB &24,&20,&1E,&20,&1E,&20,&1E,&20 ; &299F
    EQUB &1C,&18,&14,&11,&11,&11,&12,&16 ; &29A7
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &29AF
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &29B7
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &29BF
    EQUB &19,&19,&19,&19,&19,&19,&19,&19 ; &29C7
    EQUB &19,&19,&1A,&1D,&1E,&21,&22,&26 ; &29CF
    EQUB &2A,&2D,&2E,&31,&32,&35,&36,&39 ; &29D7
    EQUB &3A,&3D,&3E,&41,&40,&3C,&38,&35 ; &29DF
    EQUB &35,&34,&30,&2C,&29,&28,&25,&25 ; &29E7
    EQUB &24,&20,&1D,&1D,&1D,&1D,&1D,&1D ; &29EF
    EQUB &1D,&1D,&1D,&1D,&1D,&1D,&1D,&1D ; &29F7
LaserPixelTable:
    EQUB &1E,&00,&20,&00,&10,&10,&20,&10 ; original &29FF
    EQUB &10,&30,&30,&30,&10,&20,&30,&30 ; &2A07
    EQUB &30,&10,&30,&10,&30,&30,&30,&30 ; &2A0F
    EQUB &20,&30,&30,&30,&30,&10,&00,&30 ; &2A17
    EQUB &30,&30,&30,&30,&30,&30,&10,&30 ; &2A1F
    EQUB &30,&30,&30,&30,&30,&30,&30,&30 ; &2A27
    EQUB &30,&30,&30,&30,&30,&30,&30,&30 ; &2A2F
    EQUB &30,&30,&30,&30,&30,&30,&30,&30 ; &2A37
    EQUB &30,&30,&30,&30,&30,&30,&30,&30 ; &2A3F
    EQUB &30,&30,&30,&30,&30,&30,&30,&30 ; &2A47
    EQUB &30                         ; &2A4F
WarpX:
    ; Warp transition X offsets: 80,80,40,0,0,0,40,80.
    EQUB &50,&50,&28,&00,&00,&00,&28 ; &2A50
    EQUB &50                         ; &2A57
WarpY:
    ; Warp transition Y offsets: +96,-64,-64,-64,+96,0,0,0.
    EQUB &60,&C0,&C0,&C0,&60,&00,&00 ; &2A58
    EQUB &00                         ; &2A5F
BlastX:
    ; Explosion point X offsets: +2,+4,0,-4,-2,-4,0,+4.
    EQUB &02,&04,&00,&FC,&FE,&FC,&00 ; &2A60
    EQUB &04                         ; &2A67
BlastY:
    ; Explosion point Y offsets: 0,+12,+6,+12,0,-12,-6,-12.
    EQUB &00,&0C,&06,&0C,&00,&F4,&FA ; &2A68
    EQUB &F4                         ; &2A6F
FlashPalette:
    EQUB &45,&42,&46,&43,&47,&43,&46 ; &2A70
    EQUB &42                         ; &2A77
HyperspaceKeys:
    ; Seven BBC negative-INKEY codes; HandleHyperspace treats ANY one as a
    ; hyperspace trigger.  This byte sequence is identical in later Planetoid.
    EQUB &AC,&BB,&CA,&BA,&AA,&9B,&AB ; &2A78
UnusedBeforeSoundBlock:
    EQUB &60                         ; &2A7F ; unreferenced spacer
SoundBlock:
    EQUB &10,&01,&F1,&FF,&07,&00,&28 ; &2A80
    EQUB &00                         ; &2A87
SoundRepeatTable:
    EQUB &02,&02,&02,&00,&01,&01,&01 ; &2A88
    EQUB &01,&01,&01,&01,&01,&01,&01,&00 ; &2A8F
    EQUB &00,&01,&01,&00,&00 ; original &2A97
SoundChannelTable:
    EQUB &11,&12,&13 ; original &2A9C
    EQUB &10,&11,&10,&11,&10,&11,&10,&11 ; &2A9F
    EQUB &10,&11,&10,&12,&12,&11,&10,&13 ; &2AA7
    EQUB &12 ; original &2AAF
SoundParam1Table:
    EQUB &F6,&F6,&F6,&00,&01,&F4,&02 ; original &2AB0
    EQUB &F6,&01,&F6,&01,&F1,&01,&F1,&03 ; &2AB7
    EQUB &03,&01,&F1,&04,&03 ; original &2ABF
SoundParam2Table:
    EQUB &00,&00,&00 ; original &2AC4
    EQUB &00,&E6,&07,&64,&07,&FF,&07,&B4 ; &2AC7
    EQUB &07,&82,&07,&32,&14,&FF,&03,&00 ; &2ACF
    EQUB &AA ; original &2AD7
SoundParam3Table:
    EQUB &32,&32,&32,&00,&FF,&1E,&FF ; original &2AD8
    EQUB &0C,&FF,&02,&FF,&11,&FF,&28,&08 ; &2ADF
    EQUB &08,&FF,&3C,&23,&08,&20,&38,&30 ; &2AE7
    EQUB &30,&30,&0D,&35,&31,&30,&20,&21 ; &2AEF
    EQUB &2C,&4D,&31,&39,&47,&3F,&58,&57 ; &2AF7
    EQUB &80 ; original &2AFF
SpriteLengths:
    EQUB &30,&20,&20,&14,&18,&0C,&08 ; original &2B00
    EQUB &18,&02,&28,&28 ; original &2B07
SpritePtrLoTable:
    ; Sprite addresses for UnitType 0..10.  Keep these symbolic so sprite data
    ; can move when the source is edited.
    EQUB <ShipRightSprite,<LanderSprite,<MutantSprite,<BaiterSprite
    EQUB <BomberSprite,<SwarmerSprite,<HumanSprite,<PodSprite
    EQUB <ProjectileSprite,<Score250Sprite,<Score500Sprite
SpritePtrHiTable:
    EQUB >ShipRightSprite,>LanderSprite,>MutantSprite,>BaiterSprite
    EQUB >BomberSprite,>SwarmerSprite,>HumanSprite,>PodSprite
    EQUB >ProjectileSprite,>Score250Sprite,>Score500Sprite
RadarSpriteData:
    EQUB &FF,&FF,&8A,&88,&A2,LaserEdgeDelta ; original &2B21
    EQUB &88,&88,&A2,&A2,&82,&8A,&A8,&A8 ; &2B27
    EQUB &20,&20,&00,&D8,&00,&00,&00,&FF ; &2B2F
SpriteMaxYTable:
    EQUB &07,&07,&07,&03,&07,&03,&0F,&07 ; original &2B37
    EQUB &03,&07,&07 ; original &2B3F
PointsLoTable:
    EQUB &00,&50,&50,&50,&00 ; original &2B42
    EQUB &50,&00,&00,&25,&00,&00 ; original &2B47
PointsHiTable:
    EQUB &00,&01 ; original &2B4D
    EQUB &01,&01,&02,&02,&00,&10,&00,&00 ; &2B4F
    EQUB &00 ; original &2B57
DoWarpTable:
    EQUB &00,&01,&01,&01,&01,&00,&00 ; original &2B58
    EQUB &01,&00,&00,&00             ; &2B5F ; final four DoWarpTable entries

; &2B63-&2BFF: no code path, absolute/indexed access or table pointer references
; this block.  It begins exactly after the 11-entry DoWarpTable.  Later Planetoid
; independently labels the analogous post-DoWarp area as unused; that version's
; gap is 22 bytes shorter because it contains an additional 22-byte shifted
; minimap-dot table that this V1 layout does not have.
UnusedPostDoWarpData:
    EQUB &00,&00,&00,&00             ; &2B63
    EQUB &00,&00,&E8,&88,&C4,&9C,&C4,&C4 ; &2B67
    EQUB &C8,&3C,&AC,&A4,&8C,&78,&CC,&90 ; &2B6F
    EQUB &8C,&A0,&90,&18,&00,&F8,&00,&00 ; &2B77
    EQUB &00,&00,&00,&03,&00,&00,&00,&00 ; &2B7F
    EQUB &00,&00,&FC,&00,&00,&03,&FC,&FB ; &2B87
    EQUB &FC,&05,&FF,&FF,&FF,&00,&FE,&FE ; &2B8F
    EQUB &FF,&FF,&FE,&FE,&FE,&FF,&FF,&00 ; &2B97
    EQUB &00,&3F,&77,&36,&90,&90,&90,&22 ; &2B9F
    EQUB &90,&90,&90,&46,&90,&52,&BF,&BF ; &2BA7
    EQUB &BF,&98,&52,&52,&42,&42,&3E,&3E ; &2BAF
    EQUB &52,&3E,&58,&58,&58,&58,&58,&58 ; &2BB7
    EQUB &58,&60,&42,&DE,&35,&74,&00,&79 ; &2BBF
    EQUB &00,&00,&00,&70,&00,&00,&00,TempHi ; &2BC7
    EQUB &00,&00,&00,&00,&00,&6D,&00,&00 ; &2BCF
    EQUB &00,&00,&00,&00,&62,&00,&00,&00 ; &2BD7
    EQUB &00,&00,&00,&00,&00,&76,&73,&00 ; &2BDF
    EQUB &64,&3F,&77,&36,&90,&90,&90,&22 ; &2BE7
    EQUB &90,&90,&90,&46,&90,&60,&BF,&BF ; &2BEF
    EQUB &BF,&98,&60,&60,&42,&42,&3E,&3E ; &2BF7
    EQUB &52                         ; &2BFF
DigitSprites:
    ; Ten 16-byte HUD digit images begin here.
    EQUB &30,&20,&20,&20,&20,&20,&30 ; &2C00
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C07
    EQUB &00,&10,&30,&10,&10,&10,&10,&30 ; &2C0F
    EQUB &00,&00,&00,&00,&00,&00,&00,&20 ; &2C17
    EQUB &00,&30,&00,&00,&30,&20,&20,&30 ; &2C1F
    EQUB &00,&20,&20,&20,&20,&00,&00,&20 ; &2C27
    EQUB &00,&30,&00,&00,&30,&00,&00,&30 ; &2C2F
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C37
    EQUB &00,&20,&20,&20,&30,&00,&00,&00 ; &2C3F
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C47
    EQUB &00,&30,&20,&20,&30,&00,&00,&30 ; &2C4F
    EQUB &00,&20,&00,&00,&20,&20,&20,&20 ; &2C57
    EQUB &00,&30,&20,&20,&30,&20,&20,&30 ; &2C5F
    EQUB &00,&20,&00,&00,&20,&20,&20,&20 ; &2C67
    EQUB &00,&30,&00,&00,&00,&00,&00,&00 ; &2C6F
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C77
    EQUB &00,&30,&20,&20,&30,&20,&20,&30 ; &2C7F
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C87
    EQUB &00,&30,&20,&20,&30,&00,&00,&30 ; &2C8F
    EQUB &00,&20,&20,&20,&20,&20,&20,&20 ; &2C97
    EQUB &00 ; original &2C9F
HumanSprite:
    EQUB &CC,&CD,&CD,&CC,&F3,&51,&51 ; original &2CA0
    EQUB &51 ; original &2CA7
PodSprite:
    EQUB &00,&10,&10,&C3,&C3,&10,&10 ; original &2CA8
    EQUB &00,&82,&92,&92,&C3,&C3,&92,&92 ; &2CAF
    EQUB &82,&00,&00,&00,&82,&82,&00,&00 ; &2CB7
    EQUB &00 ; original &2CBF
ShipRightSprite:
    EQUB &15,&3F,&15,&11,&11,&11,&33 ; original &2CC0
    EQUB &11,&00,&2A,&3F,&3F,&37,&33,&33 ; &2CC7
    EQUB &33,&00,&00,&00,&2A,&3F,&3F,&3F ; &2CCF
    EQUB &37,&00,&00,&00,&00,&00,&3F,&3F ; &2CD7
    EQUB &3F,&00,&00,&00,&00,&00,&07,&07 ; &2CDF
    EQUB &3F,&00,&00,&00,&00,&00,&08,&1D ; &2CE7
    EQUB &3F ; original &2CEF
ShipLeftSprite:
    EQUB &00,&00,&00,&00,&00,&04,&2E ; original &2CF0
    EQUB &3F,&00,&00,&00,&00,&00,&0B,&0B ; &2CF7
    EQUB &3F,&00,&00,&00,&00,&00,&3F,&3F ; &2CFF
    EQUB &3F,&00,&00,&00,&15,&3F,&3F,&3F ; &2D07
    EQUB &3B,&00,&15,&3F,&3F,&3B,&33,&33 ; &2D0F
    EQUB &33,&2A,&3F,&2A,&22,&22,&22,&37 ; &2D17
    EQUB &22 ; original &2D1F
SurfaceTiles:
    EQUB &28,&28,&14,&14,&00,&28,&3C ; original &2D20
    EQUB &14,&14,&14,&28,&28 ; original &2D27
LanderSprite:
    EQUB &00,&45,&CC ; original &2D2C
    EQUB &CC,&44,&00,&44,&88,&CF,&CF,&44 ; &2D2F
    EQUB &44,&CC,&CE,&44,&44,&8A,&CF,&44 ; &2D37
    EQUB &44,&CC,&8A,&44,&00,&00,&00,LaserEdgeDelta ; &2D3F
    EQUB &88,&00,&00,&00,&88 ; original &2D47
MutantSprite:
    EQUB &00,&51,&CC ; original &2D4C
    EQUB &CC,&44,&00,&44,&88,&0C,&0C,&51 ; &2D4F
    EQUB &51,&F3,&D9,&51,&51,&88,&F6,&44 ; &2D57
    EQUB &44,&E6,&88,&44,&00,&00,&00,LaserEdgeDelta ; &2D5F
    EQUB &88,&00,&00,&00,&88 ; original &2D67
BaiterSprite:
    EQUB &00,&44,&CD ; original &2D6C
    EQUB &44,&CC,&C0,&CA,&CC,&CC,&C0,&CF ; &2D6F
    EQUB &CC,&CC,&C0,&C5,&CC,&00,&88,&CE ; &2D77
    EQUB &88,&00,&00,&00,&00,&00,&50,&E5 ; &2D7F
    EQUB &76,&A8,&A2,&01,&A5,&76,&20,SourcePtrHi ; &2D87
    EQUB &1D,&4C,&FB,&20,&68 ; original &2D8F
BomberSprite:
    EQUB &51,&03,&06 ; original &2D94
    EQUB &06,&06,&06,&03,&03,&F3,&03,&0C ; &2D97
    EQUB &0E,&0E,&0C,&03,&03,&F3,&53,&53 ; &2D9F
    EQUB &53,&53,&53,&02,&02 ; original &2DA7
SwarmerSprite:
    EQUB &00,&41,&C7 ; original &2DAC
    EQUB &41,&82,&C3,&C7,&C3,&00,&00,Random2 ; &2DAF
    EQUB &00 ; original &2DB7
ProjectileSprite:
    EQUB &AA,&AA ; original &2DB8
ShrapnelSprite:
    EQUB &FF,&FF,&FF,&FF ; original &2DBA
Score250Sprite:
    EQUB &00 ; original &2DBE
    EQUB &00,&05,&00,&05,&05,&05,&00,&00 ; &2DBF
    EQUB &00,&0F,&05,&0F,&00,&0F,&00 ; original &2DC7
Score500Sprite:
    EQUB &00 ; original &2DCE
    EQUB &00,&0C,&08,&0C,&00,&0C,&00,&00 ; &2DCF
    EQUB &00,&09,&01,&09,&09,&09,&00,&00 ; &2DD7
    EQUB &00,&03,&01,&01,&01,&03,&00,&00 ; &2DDF
    EQUB &00,&0F,&0A,&0A,&0A,&0F,&00,&00 ; &2DE7
    EQUB &00,&0A,&0A,&0A,&0A,&0A,&00,&00 ; &2DEF
    EQUB &09,&88,&09,&92,&09,&9C,&09,&A6 ; &2DF7
    EQUB &09,&09,&07,&03,&08,&06,&1E,&0A ; &2DFF
    EQUB &06,&01,&03,&04,&15,&05,&0B,&1B ; &2E07
    EQUB &01,&01,&85,&02,&09,&05,&07,&04 ; &2E0F
    EQUB &02,&03,&88,&08,&86,&02,&01,&02 ; &2E17
    EQUB &04,&03,&07,&05,&02,&04,&02,&19 ; &2E1F
    EQUB &03,&09,&09,&03,&03,&1A,&01,&01 ; &2E27
    EQUB &8D,&04,&04,&04,&04,&84,&07,SavedX ; &2E2F
    EQUB &0B,&10,&02,&03,&09,&43,&2E,&4D ; &2E37
    EQUB &55,&00,&90,&21,&4A,&2E,&44,&55 ; &2E3F
    EQUB &00,&59,&1F,&5C,&2E,&54,&55,&50 ; &2E47
    EQUB &46,&00,&47,&1E,&00,&00,&45,&00 ; &2E4F
    EQUB &83,&40,&00,&00,&00,&62,&2E,&55 ; &2E57
    EQUB &00,&62,&22,&68,&2E,&44,&00,&7B ; &2E5F
    EQUB &22,&6F,&2E,&44,&44,&00,&0A,&20 ; &2E67
    EQUB &83,&2E,&54,&44,&4F,&57,&00,&BF ; &2E6F
    EQUB &1F,&58,&00,&55,&4D,&45,&25,&00 ; &2E77
    EQUB &10,&30,&20,&20,&14,&18,&0C,&08 ; &2E7F
    EQUB &18,&02,&28,&28,&C0,&2C,&4C,&6C ; &2E87
    EQUB &94,&AC,&A0,&A8,&B8,&BA,&CA,&26 ; &2E8F
    EQUB &27,&27,&27,&27,&27,&26,&26,&27 ; &2E97
    EQUB &27,&27,&FF,&FF,&8A,&88,&A2,LaserEdgeDelta ; &2E9F
    EQUB &88,&88,&A2,&A2,&82,&8A,&A8,&A8 ; &2EA7
    EQUB &20,&20,&00,&03,&0F,&07,&03,&00 ; &2EAF
    EQUB &07,&07,&07,&03,&07,&03,&0F,&07 ; &2EB7
    EQUB &03,&07,&07,&00,&50,&50,&50,&00 ; &2EBF
    EQUB &50,&00,&00,&25,&00,&00,&00,&01 ; &2EC7
    EQUB &01,&01,&02,&02,&00,&10,&00,&00 ; &2ECF
    EQUB &00,&00,&01,&01,&01 ; original &2ED7
LaserActive:
    EQUB &00,&00,&00 ; original &2EDC
    EQUB &00 ; original &2EDF
LaserTailPhase:
    EQUB &1C,&0F,&14,&16 ; original &2EE0
LaserHeadPhase:
    EQUB &4A,&3C,&41 ; original &2EE4
    EQUB &43 ; original &2EE7
LaserX:
    EQUB &4C,&FF,&FF,&FF ; original &2EE8
LaserY:
    EQUB &36,&4E,&58 ; original &2EEC
    EQUB &5A ; original &2EEF
LaserTailPtrLo:
    EQUB &79,&E9,&EF,&ED ; original &2EF0
LaserTailPtrHi:
    EQUB &78,&65,&60 ; original &2EF4
    EQUB &60 ; original &2EF7
LaserHeadPtrLo:
    EQUB &C9,&99,&9F,&9D ; original &2EF8
LaserHeadPtrHi:
    EQUB &79,&64,&5F ; original &2EFC
    EQUB &5F ; original &2EFF
OldScreenOriginLo:
    EQUB &88 ; original &2F00
OldScreenOriginHi:
    EQUB &7D ; original &2F01
ScrollOffsetLo:
    EQUB &00 ; original &2F02
ScrollOffsetHi:
    EQUB &00 ; original &2F03
HighScoreBCD:
    EQUB &00,&00,&2F ; original &2F04
    EQUB &4D ; original &2F07
ScreenOriginLo:
    EQUB &88 ; original &2F08
ScreenOriginHi:
    EQUB &7D ; original &2F09
WorldWindowX:
    EQUB &B1,&93 ; original &2F0A
SurfaceWindowEdges:
    EQUB &B1,&01 ; original &2F0C
TabKeyLatch:
    EQUB &00 ; original &2F0E
BackgroundPalette:
    EQUB &00 ; original &2F0F
FrameCounterLo:
    EQUB &00 ; original &2F10
FrameCounterHi:
    EQUB &00 ; original &2F11
GeneralCount:
    EQUB &00 ; original &2F12
EnemyCount:
    EQUB &19 ; original &2F13
SquadDelayHigh:
    EQUB &02 ; original &2F14
HumanCount:
    EQUB &00 ; original &2F15
LevelBCD:
    EQUB &04 ; original &2F16
HumanBonusBCD:
    EQUB &04 ; original &2F17
BaitDelayLo:
    EQUB &D9 ; original &2F18
BaitDelayHi:
    EQUB &08 ; original &2F19
NoPlanet:
    EQUB &01 ; original &2F1A
LastVSync:
    EQUB &76 ; original &2F1B
ShipAccelerationLo:
    EQUB &F9 ; original &2F1C
ShipAccelerationHi:
    EQUB &FF ; original &2F1D
WorldScrollVelocityLo:
    EQUB &93 ; original &2F1E
WorldScrollVelocityHi:
    EQUB &FF ; original &2F1F
WorldLeftEdgeLo:
    EQUB &9E ; original &2F20
WorldLeftEdgeHi:
    EQUB &D8 ; original &2F21
AlternateUnitIndex:
    EQUB &22 ; original &2F22
SpaceKeyLatch:
    EQUB &00 ; original &2F23
PlayerDead:
    EQUB &00 ; original &2F24
AIBatchSize:
    EQUB &1E ; original &2F25
AIBatchCounter:
    EQUB &00 ; original &2F26
SpawnSpriteType:
    EQUB &01 ; original &2F27
MinScreenX:
    EQUB &00 ; original &2F28
MaxScreenX:
    EQUB &4D ; original &2F29
WorldWindowDelta:
    EQUB &00 ; original &2F2A
EnterKeyLatch:
    EQUB &FF ; original &2F2B
ShipScreenX:
    EQUB &3F ; original &2F2C
HitchhikerCount:
    EQUB &00 ; original &2F2D
DigitScreenPtrLo:
    EQUB &58 ; original &2F2E
DigitScreenPtrHi:
    EQUB &7E ; original &2F2F
ScoreBCD:
    EQUB &75,&81,&02 ; original &2F30
LeadingZeroState:
    EQUB &41 ; original &2F33
FlashPaletteIndex:
    EQUB &04 ; original &2F34
FlashPaletteCountdown:
    EQUB &03 ; original &2F35
FlashPalettePeriod:
    EQUB &06 ; original &2F36
LivesBCD:
    EQUB &00 ; original &2F37
SmartBombsBCD:
    EQUB &04 ; original &2F38
GameOverStackPointer:
    EQUB &FB ; original &2F39
EnemyShotSpeed:
    EQUB &40 ; original &2F3A
SmartBombPass2:
    EQUB &01 ; original &2F3B
ShipPalette:
    EQUB &F1 ; original &2F3C
PaletteRotateFrameCount:
    EQUB &2B ; original &2F3D
PaletteRotateIndex:
    EQUB &00 ; original &2F3E
PaletteRotateColours:
    EQUB &01,&03,&04 ; original &2F3F
SurfacePalette:
    EQUB &60 ; original &2F42
NextLevelStackPointer:
    EQUB &F9 ; original &2F43
LevelStillSpawning:
    EQUB &00 ; original &2F44
VSyncCounter:
    EQUB &DE ; original &2F45
AIVectorTable:
    ; One little-endian handler pointer for each UnitType 0..10.
    ; These are expressions, not frozen original addresses, so inserting code
    ; before an AI routine keeps the dispatch table valid.
    EQUW AI_Ship,AI_Lander,AI_Mutant,AI_Baiter,AI_Bomber,AI_Swarmer
    EQUW AI_Human,AI_Pod,AI_TimedObject,AI_TimedObject,AI_TimedObject
    EQUB &00,&00                    ; original unused padding &2F5C-&2F5D
SpawnCount:
    EQUB &00 ; original &2F5E
    EQUB &05,&00,&00,&04,&00,&00,&00 ; original &2F5F
XMinInit:
    EQUB &07 ; original &2F66
    EQUB &00,&40,&00,&40,&00,&00,&00 ; original &2F67
XRangeInit:
    EQUB &00 ; original &2F6E
    EQUB &FF,&7F,&0F,&07,&00,&FF,&3F ; original &2F6F
YMinInit:
    EQUB &64 ; original &2F76
    EQUB &B4,&00,&00,&00,&00,&0A,&00 ; original &2F77
YRangeInit:
    EQUB &00 ; original &2F7E
    EQUB &00,&FF,&FF,&FF,&1F,&00,&FF ; original &2F7F
DXMinInit:
    EQUB &02 ; original &2F86
    EQUB &18,&00,&0A,&18,&32,&04,&08 ; original &2F87
DXRangeInit:
    EQUB &07 ; original &2F8E
    EQUB &0F,&00,&07,&0F,&07,&00,&07 ; original &2F8F
DYMinInit:
    EQUB &0A ; original &2F96
    EQUB &00,&00,&0A,&00,&18,&00,&08 ; original &2F97
DYRangeInit:
    EQUB &3F ; original &2F9E
    EQUB &00,&00,&07,&0F,&07,&00,&07 ; &2F9F ; final seven DYRangeInit entries

; &2FA6-&2FC7 is not referenced by any instruction or pointer in Defender V1.
; The preceding indexed table stops exactly at &2FA5 and the used string-pointer
; table begins at &2FC8.  Later Planetoid places its string pointers immediately
; after the corresponding DYRange table, so this is V1-specific vestigial data.
UnusedPreStringPointerData:
    EQUB &0F                         ; &2FA6
    EQUB &07,&00,&07,&00,&00,&00,&00,&00 ; &2FA7
    EQUB &07,&07,&07,&00,&07,&00,&00,&3F ; &2FAF
    EQUB &00,&15,&3F,&15,&15,&15,&15,&3F ; &2FB7
    EQUB &22,&F0,&3F,&15,&15,&2F,&15,&3F ; &2FBF
    EQUB &00                         ; &2FC7

StringPointerLo:
    ; Only indices 0,1,2 are ever passed to DrawStringByIndex.
    EQUB <String0_ClearTextAndRestorePalette
    EQUB <String1_LevelCompleteTemplate
    EQUB <String2_GameOverTemplate

UnusedStringPointerLowPadding:
    EQUB &17                         ; &2FCB ; never indexed

StringPointerHi:
    EQUB >String0_ClearTextAndRestorePalette
    EQUB >String1_LevelCompleteTemplate
    EQUB >String2_GameOverTemplate
UnusedStringPointerHighPadding:
    EQUB &00                         ; &2FCF ; fourth, unused high-table byte

String0_ClearTextAndRestorePalette:
    EQUB &02,&0C,&14                 ; &2FD0 ; length 2, VDU 12 then VDU 20

UnusedStringSpacer0:
    EQUB &1F                         ; &2FD3

String1_LevelCompleteTemplate:
    EQUB &18,&11,&04                 ; &2FD4 ; length 24 begins here
    EQUB &1F,&04,&0C,&E0,&E1,&E2,&E3,&E4 ; &2FD7
    EQUB &E5,&20,&E6,&E7,&E8,&E9,&EA,&1F ; &2FDF
    EQUB &07,&0F,&EB,&EC,&ED,&EE     ; &2FE7 ; end String1 data
UnusedStringSpacer1:
    EQUB &E7                         ; &2FED

String2_GameOverTemplate:
    EQUB &10                         ; &2FEE ; length 16 begins here
    EQUB &1F,&07,&0F,&EF,&F0,&20,&20,&F1 ; &2FEF
    EQUB &F2,&1F,&0B,&03,&F3,&F4,&F5,&F6 ; &2FF7
UnusedTrailingStringByte:
    EQUB &F2                         ; &2FFF

Startup:
; Runtime startup at &3000.  Saves the stack, performs an OS-version/command-tail
; compatibility check, installs IRQ1V at &0E05, copies a 46-byte live video stub
; from &305A to &0400 and jumps to that stub.
    TSX                          ; &3000: BA
    STX GameOverStackPointer                    ; &3001: 8E 39 2F
    LDA #<StartupBRKRecovery     ; original &3004: A9 13
    STA BRKV                     ; original &3006: 8D 02 02
    LDA #>StartupBRKRecovery     ; original &3009: A9 30
    STA BRKV+1                   ; original &300B: 8D 03 02
    LDA #&00                     ; original &300E: A9 00
    JSR OSBYTE                   ; original &3010: 20 F4 FF
StartupBRKRecovery:
    LDX GameOverStackPointer     ; original &3013: AE 39 2F
    TXS                          ; &3016: 9A
    JSR CheckOSCommandTailCompatibility                    ; &3017: 20 90 30
    BNE InstallIRQAndLaunchStub                    ; &301A: D0 10
    LDA #&24                     ; low byte of MOS command-tail pointer &0224
    STA WaitForVSync+1           ; patch operand low byte, original &0E13
    STA CheckForNewVSync+1       ; patch operand low byte, original &0E1F
    LDA #&02                     ; high byte of MOS command-tail pointer &0224
    STA WaitForVSync+2           ; patch operand high byte, original &0E14
    STA CheckForNewVSync+2       ; patch operand high byte, original &0E20

InstallIRQAndLaunchStub:
    SEI                          ; &302C: 78
    LDA IRQ1V                    ; &302D: AD 04 02
    STA OldIRQ1VLo                      ; &3030: 85 8C
    LDA IRQ1V+1                    ; &3032: AD 05 02
    STA OldIRQ1VHi                      ; &3035: 85 8D
    LDA #<IRQ1VHandler          ; original &3037: A9 05
    STA IRQ1V                   ; original &3039: 8D 04 02
    LDA #>IRQ1VHandler          ; original &303C: A9 0E
    STA IRQ1V+1                 ; original &303E: 8D 05 02
    CLI                          ; &3041: 58
    LDA #<RelocatedVideoStub      ; &3042: A9 00
    STA DestPtrLo                  ; &3044: 85 70
    LDA #>RelocatedVideoStub      ; &3046: A9 04
    STA DestPtrHi                  ; &3048: 85 71
    LDA #<LiveVideoStubImage      ; &304A: A9 5A
    STA SourcePtrLo                ; &304C: 85 72
    LDA #>LiveVideoStubImage      ; &304E: A9 30
    STA SourcePtrHi                ; &3050: 85 73
    LDA #(LiveVideoStubImageEnd-LiveVideoStubImage)
                                  ; original &3052: A9 2D ; original 46-byte copy count
    JSR CopyBlockDown             ; original &3054: 20 87 30
    JMP RelocatedVideoStub         ; &3057: 4C 00 04

LiveVideoStubImage:
; Position-independent startup stub. Startup copies these 46 bytes to &0400
; before MODE 2 claims screen RAM at &3000.  It clears the high score, selects
; MODE 2, configures the display and enters the normal game/title path.
    LDA #&00                       ; &305A: A9 00
    STA HighScoreBCD               ; &305C: 8D 04 2F
    STA HighScoreBCD+1             ; &305F: 8D 05 2F
    STA HighScoreBCD+2             ; &3062: 8D 06 2F
    LDA #&16                       ; &3065: A9 16 ; VDU 22 = MODE
    JSR OSWRCH                     ; &3067: 20 EE FF
    LDA #&02                       ; &306A: A9 02 ; MODE 2
    JSR OSWRCH                     ; &306C: 20 EE FF
    LDA #&04                       ; &306F: A9 04 ; OSBYTE 4
    LDX #&01                       ; &3071: A2 01
    JSR OSBYTE                     ; &3073: 20 F4 FF
    LDX #&08                       ; &3076: A2 08 ; CRTC register 8
    LDA #&00                       ; &3078: A9 00
    JSR WriteCRTCRegister          ; &307A: 20 2D 0E
    LDX #&0A                       ; &307D: A2 0A ; CRTC register 10
    LDA #&20                       ; &307F: A9 20 ; cursor off
    JSR WriteCRTCRegister          ; &3081: 20 2D 0E
    JMP MainWithHighScore          ; &3084: 4C FA 1B
LiveVideoStubImageEnd:

CopyBlockDown:
; Copy A+1 bytes backwards from SourcePtr to DestPtr. The original startup copies
; 46 bytes beginning at LiveVideoStubImage; its final copied byte is the byte at
; LiveVideoStubImageEnd (the first byte of the following routine). Deriving A
; from the labels preserves that original behaviour without freezing &2D.
    TAY                          ; &3087: A8
CopyBlockDownLoop:
    LDA (SourcePtrLo),Y                  ; &3088: B1 72
    STA (DestPtrLo),Y                  ; &308A: 91 70
    DEY                          ; &308C: 88
    BPL CopyBlockDownLoop                    ; &308D: 10 F9
    RTS                          ; &308F: 60

CheckOSCommandTailCompatibility:
    LDY #&00                     ; &3090: A0 00
ScanCommandTailForZero:
    INY                          ; &3092: C8
    LDA (&FD),Y                  ; &3093: B1 FD
    BEQ CompatibilityNotFound                    ; &3095: F0 12
    CMP #&30                     ; &3097: C9 30
    BNE ScanCommandTailForZero                    ; &3099: D0 F7
    LDX #&00                     ; &309B: A2 00
CompareCompatibilityPattern:
    INY                          ; &309D: C8
    LDA CompatibilityVersionPattern,X ; &309E: BD AC 30
    BEQ ReturnCompatibilityResult                    ; &30A1: F0 05
    INX                          ; &30A3: E8
    CMP (&FD),Y                  ; &30A4: D1 FD
    BEQ CompareCompatibilityPattern                    ; &30A6: F0 F5

ReturnCompatibilityResult:
    RTS                          ; &30A8: 60

CompatibilityNotFound:
    LDA #&01                     ; &30A9: A9 01
    RTS                          ; &30AB: 60
CompatibilityVersionPattern:
    EQUS ".10"                   ; &30AC-&30AE
    EQUB &00,&0D,&00,&00,&00     ; &30AF
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30B4
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30BC
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30C4
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30CC
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30D4
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30DC
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30E4
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30EC
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &30F4
    EQUB &00,&00,&00,&00 ; &30FC

ORG &4100

Defend2Relocator:
; DFS execute entry at &4100.  Copies 35 pages (&2300 bytes) from load image
; &1E00-&40FF down to runtime &0E00-&30FF, installs a small block at &03B0,
; then returns to BASIC.
    LDA #&8C                     ; &4100: A9 8C
    LDX #&00                     ; &4102: A2 00
    LDY #&00                     ; &4104: A0 00
    JSR OSBYTE                    ; &4106: 20 F4 FF
    LDA #&00                     ; &4109: A9 00
    STA DestPtrLo                      ; &410B: 85 70
    STA SourcePtrLo                      ; &410D: 85 72
    LDA #&0E                     ; &410F: A9 0E
    STA DestPtrHi                      ; &4111: 85 71
    LDA #&1E                     ; &4113: A9 1E
    STA SourcePtrHi                      ; &4115: 85 73
    LDY #&00                     ; &4117: A0 00
RelocateMainImageLoop:
    LDA (SourcePtrLo),Y                  ; &4119: B1 72
    STA (DestPtrLo),Y                  ; &411B: 91 70
    INY                          ; &411D: C8
    BNE RelocateMainImageLoop                    ; &411E: D0 F9
    INC DestPtrHi                      ; &4120: E6 71
    INC SourcePtrHi                      ; &4122: E6 73
    LDA SourcePtrHi                      ; &4124: A5 73
    CMP #&41                     ; &4126: C9 41
    BNE RelocateMainImageLoop                    ; &4128: D0 EF
    LDX #&00                     ; &412A: A2 00
CopyRelocatorWorkspaceLoop:
    LDA RelocatorWorkspaceImage,X ; &412C: BD 50 41
    STA RELOCATOR_WORKSPACE,X     ; &412F: 9D B0 03
    INX                          ; &4132: E8
    CPX #&30                     ; &4133: E0 30
    BNE CopyRelocatorWorkspaceLoop                    ; &4135: D0 F5
    RTS                          ; &4137: 60
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &4138
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &4140
    EQUB &00,&00,&00,&00,&00,&00,&00,&00 ; &4148
RelocatorWorkspaceImage:
; 48-byte block installed at &03B0 by the DFS execute stub.  It contains two
; copies of the DFS filename "Defend2" plus the original control/workspace data.
; Retained byte-for-byte because these bytes are part of the supplied file image.
    EQUB &00,&00
    EQUS "Defend"
    EQUB &32,&00,&00,&00,&00,&00,&00,&0E ; &4158
    EQUB &00,&00,&00,&0E,&00,&00,&22,&00 ; &4160
    EQUB &00,&01,&80,&00,&00,&00,&00,&0A ; &4168
    EQUB &15,&19
    EQUS "Defend"
    EQUB &32,&00,&00,&00,&00,&00,&00,Random0 ; &4178
