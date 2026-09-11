; Frak! (BBC Micro, Aardvark Software, 1984)
; GitLab runnable reconstruction baseline
;
; PURPOSE
; -------
; This is the first BUILDABLE source baseline for the reverse-engineering project.
; It deliberately prioritises a dependable compile/run cycle over annotation.
;
; The original Frak3 payload is encrypted on disk.  This source contains the
; DECRYPTED Frak3 image at its original load address (&2F00).  The only code
; change is the three-byte JMP at &2F0D: instead of entering Frak2 to decrypt an
; already-decoded payload, it jumps directly to the original decoded startup at
; Bootstrap (&468B).  The original zero-page seed copy still runs first.
;
; Bootstrap is otherwise byte-for-byte original code.  It performs the game's
; original relocations, vector/VIA setup, sprite pointer initialisation and then
; transfers to the relocated game entry at &0380.
;
; RELOCATABLE SOURCE IMAGE
; ------------------------
; @default-origin &2F00
;
; There is deliberately NO ORG directive in this source.  &2F00 is only the
; historical/default load address used by the BBC 6502 Web Assembler UI.
; Change the Origin field to move the packed source image.
;
; Frak is unusual: this packed image is not the final runtime layout.  Bootstrap
; copies eight ranges down into the game's intentional low-memory runtime map.
; All addresses which point back into THIS packed image are labels/expressions,
; so moving the assembly origin moves those pointers coherently.  Numeric low
; addresses which remain are genuine fixed BBC MOS/hardware/zero-page/runtime
; workspace locations used by the original game.
;
; Safe alternate origins must leave the packed image resident while Bootstrap
; performs its copies.  Origins >= &3000 are the simplest choices; keep the end
; of the &2D4B-byte image below the boot loader's high-RAM mover/screen workspace.
;
; BBC 6502 Web Assembler
; ----------------------
; 1. Open this file.
; 2. Assemble.
; 3. Save boot disk.
; 4. Boot entry is selected automatically as: start (the chosen Origin)
; 5. Suggested DFS title/program name: FRAK / FRAK
;
; The assembler's generated boot loader selects MODE 7 and relocates this image
; to the selected Origin before entering start/RunEntry.  At the historical
; &2F00 default it ends at &5C4A, safely below the loader's temporary mover.
;
; Original loader compatibility setting retained:
; @basic *FX200,2
;
; Known runtime symbols (destinations after Bootstrap relocation)
; -----------------------------------------------------------------------------
; These are RUNTIME addresses, not addresses of the packed source image.
; They intentionally remain in Frak's original low-memory map.
OSWRCH                 = &FFEE
OSWORD                 = &FFF1
OSBYTE                  = &FFF4
OSCLI                   = &FFF7
EVENTV                  = &0220
IRQ1V                   = &0204
USERV                   = &0228
CRTC_ADDRESS            = &FE00
CRTC_DATA               = &FE01
SYSTEM_VIA_IER          = &FE4E
USER_VIA_T1CL           = &FE64
USER_VIA_T2CL           = &FE68
USER_VIA_T2CH           = &FE69
USER_VIA_ACR            = &FE6B
USER_VIA_IFR            = &FE6D
USER_VIA_IER            = &FE6E

RuntimeGameEntry        = &0380
TitleInitEightRecords    = &0481
ObjectX                 = &0368
ObjectY                 = &03E3
ObjectSprite            = &045E
ObjectDX                = &04D9
ObjectDY                = &04F0
SoundStream             = &0507
LevelA                  = &05D4
LevelB                  = &0689
LevelC                  = &073C
HighScores              = &0880
Mode1Masks              = &0A00
QueueDescriptors        = &0B00
ObjectMode40            = &0B18
ObjectMode80            = &0B1C
ObjectMode00            = &0B20
ObjectModeC0            = &0B23
DrawSpriteAt            = &0B32
LoadObject              = &0B3C
GameStartTitleLoop      = &0B4C
GameStartCheck          = &0B58
StartScreen             = &0B6A
MainGameFrame           = &0BC7
ResetCountdownDivider   = &0C27
TimerAndKeys            = &0C2C
CheckSoundKey            = &0C89
WaitForTickChange       = &0D01
WaitForObjectRaster     = &0D08
PrintInlineStream       = &0D21
PrintInlineAdvance      = &0D37
TickIRQ                 = &0D44
SoundIRQ                = &0D69
Inkey                   = &0D9C
RandomBelowA            = &0DB6
ClearObjectTables       = &0DDB
UserVHandler            = &0DF4
OSBYTEWrapper           = &0DFB
OSWORDWrapper           = &0E03
TestLadderCollision     = &0E0B
TestFloorCollision      = &0E5F
TroggUpdate             = &0E8F
MoveTest                = &1085
FrameUpdate             = &11AC
KeyCollect              = &1292
GemCollect              = &12A9
BulbCollect             = &12B7
TypeDispatch            = &12D1
ReadHorizontal          = &12F9
ReadVertical            = &131D
ReadYoyo                = &1359
Routine13FF             = &13FF
SetCrtcOrigin           = &1428
RefreshScrollBuffer     = &144B
CollisionScan           = &1472
DisplayInit             = &14CD
Routine1565             = &1565
AddScoreBCD             = &15B8
DrawStatus              = &15DB
Routine163C             = &163C
HighScoreInsert         = &164D
LoadLevelStream         = &17B8
MusicStep               = &186B
SoundOSWORD7            = &18A9
SelectTune              = &18B4
ScreenComplete          = &18CC
TitleStartSequence      = &1977
LevelStreamPtrLoTable   = &196B
LevelStreamPtrHiTable   = &196E
InitialTimeHiTable      = &1971
InitialTuneTable        = &1974
ShowHighScores          = &1A52
Routine1AC7             = &1AC7
Routine1B7E             = &1B7E
SpawnHazard             = &1BA2
BalloonMovement         = &1C68
DaggerMovement          = &1C79
FindFreeSlot            = &1C97
Routine1CCF             = &1CCF
SpriteTraversal         = &1D2E
DirectSpriteRenderer    = &1E36
SpriteRenderSetup       = &1E8C
Mode1Address            = &1FA9
SpriteXOffsets          = &1FFD
SpriteYOffsets          = &2059
SpriteDefLo             = &20B5
SpriteDefHi             = &2111
SpriteWidthFlags        = &216D
SpriteHeightCount       = &21C9

; Frequently used zero-page game state.
CurrentSpriteX          = &11
CurrentSpriteY          = &12
InkeyCode               = &21
Scratch26               = &26
RandomMask              = &27
RandomState             = &28
RelocLengthHi           = &26
InlinePtrLo             = &29
InlinePtrHi             = &2A
GameState2F             = &2F
InputPhase              = &32
SavedObjectIndex        = &33
ScoreLo                 = &38
ScoreMid                = &39
ScoreHi                 = &3A
Lives                   = &3B
BaseScreen              = &3C
TransformCycle          = &3D
RelocSourceLo           = &3F
RelocSourceHi           = &40
RelocDestLo             = &41
RelocDestHi             = &42
TickCounter             = &44
SoundEnabled            = &4B
SavedUserVLo            = &4C
SavedUserVHi            = &4D
SavedIRQ1VLo            = &4E
SavedIRQ1VHi            = &4F
State53                 = &53
State54                 = &54
State55                 = &55
TroggDirection          = &57
SavedSpriteType         = &58
CollisionObject         = &64
LevelStreamLo           = &6D
LevelStreamHi           = &6E
SoundIrqGate            = &70
LastTick                = &71
Orientation             = &74
KeysRemaining           = &7A
PlayerDeathState        = &7B
SpriteTableBaseLo       = &80
SoundStreamCount        = &81
TimeLoBCD               = &82
TimeHiBCD               = &83
CountdownDivider        = &84
CountdownState          = &85
InputMode               = &86
InputState              = &87
HazardCounter           = &88
HazardReload            = &89
MusicCountdown          = &91
PauseGate               = &92
OSCallGate              = &93

TYPE_SCRUBBLY         = &12
TYPE_GEM              = &16
TYPE_KEY              = &17
TYPE_HOOTER           = &1D
TYPE_POGLET           = &1E
TYPE_BULB             = &23
TYPE_DAGGER           = &25
TYPE_DAGGER_FLIP      = &26
TYPE_BALLOON          = &27
TYPE_TROGG_0          = &34


; -----------------------------------------------------------------------------
; Boot/load entry.
;
; IMPORTANT: the web assembler prefers a symbol named "start" for its boot-disk
; entry-point default.  &0380 is only the INTERNAL entry reached after Bootstrap
; has relocated the game; it must not be used as the DFS/BASIC loader entry.
; -----------------------------------------------------------------------------
start:

; -----------------------------------------------------------------------------
; Deprotected entry. These instructions are symbolic already; bytes &2F00-&2F0C
; are the original Frak3 entry. Only the JMP target is intentionally changed.
; -----------------------------------------------------------------------------
RunEntry:
        LDY #&00
CopyZeroPageSeed:
        LDA ZeroPageSeed,Y
        STA &0000,Y
        INY
        CPY #&98
        BNE CopyZeroPageSeed
        JMP Bootstrap

; -----------------------------------------------------------------------------
; &2F10: Original bootstrap state copied to zero page &0000-&0097.
; -----------------------------------------------------------------------------
ZeroPageSeed:
        EQUB &F0,&87,&2C,&6D,&F6,&05,&46,&EB,&BE,&24,&C4,&EC,&79,&A0,&63,&BE    ; &2F10
        EQUB &82,&D2,&72,&94,&E5,&C0,&CF,&90,&E9,&BE,&E0,&30,&12,&C8,&2A,&C8    ; &2F20
        EQUB &D4,&AF,&24,&6D,&D9,&19,&41,&78,&30,&81,&DF,&AB,&FA,&86,&BF,&93    ; &2F30
        EQUB &F4,&02,&0D,&72,&70,&B5,&D3,&96,&7F,&0F,&F7,&D1,&FF,&CB,&06,&74    ; &2F40
        EQUB &9F,&6B,&EF,&48,&66,&61,&EA,&7F,&38,&7A,&65,&B6,&2B,&0A,&74,&C9    ; &2F50
        EQUB &93,&C0,&A2,&30,&40,&ED,&2F,&AC,&0F,&46,&CE,&0E,&A0,&7A,&51,&3D    ; &2F60
        EQUB &89,&8C,&23,&37,&24,&59,&04,&92,&C0,&2A,&8A,&36,&FF,&28,&0F,&03    ; &2F70
        EQUB &78,&8B,&6E,&07,&D9,&87,&34,&DA,&77,&A9,&22,&BB,&B2,&54,&7D,&0D    ; &2F80
        EQUB &84,&CD,&B5,&DF,&B0,&CD,&C0,&04,&B4,&B8,&E5,&B2,&BE,&10,&08,&67    ; &2F90
        EQUB &40,&D9,&3E,&24,&97,&20,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FA0
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FB0
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FC0
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FD0
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FE0
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &2FF0
; -----------------------------------------------------------------------------
; &3000: Relocated by Bootstrap: &3000-&31F2 -> runtime &0B00-&0CF2.
; -----------------------------------------------------------------------------
Runtime_0B00_Source:
; Queue descriptors.  Each queue's final byte is the next queue's first slot,
; giving seven overlapping records: start, collision flags, ASCII tag, next.
        EQUB 0,&00,"T"
        EQUB 3,&09,"D"
        EQUB 13,&09,"B"
        EQUB 23,&50,"K"
        EQUB 38,&C9,"M"
        EQUB 48,&02,"F"
        EQUB 93,&04,"L"
        EQUB 123
        EQUB 0,0                    ; original padding at &0B16-&0B17

; Four compact entries select a sprite/object operation mode in A.  The &00 and
; &C0 entries deliberately overlap: byte &CD is the CMP abs opcode seen only by
; ObjectMode00, while the following A9 C0 bytes are LDA #&C0 when entered at
; ObjectModeC0.  This preserves Orlando's original byte-saving trick.
Core_ObjectMode40:
        LDA #&40
        BPL Core_ApplyObjectMode
Core_ObjectMode80:
        LDA #&80
        BMI Core_ApplyObjectMode
Core_ObjectMode00:
        LDA #&00
        EQUB &CD                    ; CMP abs opcode; operand is following A9 C0
Core_ObjectModeC0:
        LDA #&C0
Core_ApplyObjectMode:
        JSR LoadObject
        BCS Core_ObjectModeDone
        STX SavedObjectIndex
        JSR Routine1CCF
        LDX SavedObjectIndex
Core_ObjectModeDone:
        RTS

Core_DrawSpriteAt:
        STX CurrentSpriteX
        STY CurrentSpriteY
        TAY
        LDA #&00
        JMP Routine1CCF

Core_LoadObject:
        LDY ObjectX,X
        STY CurrentSpriteX
        LDY ObjectY,X
        STY CurrentSpriteY
        LDY ObjectSprite,X
        CPY #&5C
        RTS

; Attract/title loop.  TitleStartSequence returns carry set when a game starts.
Core_GameStartTitleLoop:
        JSR ResetCountdownDivider
        LDA #&FF
        STA GameState2F
        STA InputMode
        JSR TitleStartSequence
        BCC Core_GameStartTitleLoop

Core_NewGame:
        LDA #&03
        STA Lives
        LDA #&00
        STA BaseScreen
        STA TransformCycle
        STA ScoreLo
        STA ScoreMid
        STA ScoreHi

; Initialise one of the three base screens and the current 0..7 transform cycle.
Core_StartScreen:
        LDX BaseScreen
        LDY TransformCycle
        JSR DisplayInit
        SEC
        LDA #&0B
        SBC TransformCycle
        ASL A
        ASL A
        STA HazardReload
        LDA LevelStreamPtrLoTable,X
        STA LevelStreamLo
        LDA LevelStreamPtrHiTable,X
        STA LevelStreamHi
        LDA InitialTimeHiTable,X
        STA TimeHiBCD
        LDA InitialTuneTable,X
        JSR SelectTune
        JSR Routine1565

        LDX #&00
        STX InputPhase
        STX PlayerDeathState
        STX State55
        STX State54
        STX State53
        STX TimeLoBCD
        STX CountdownState
        INX
        STX TroggDirection
        STX HazardCounter
        LDA #&32
        STA CountdownDivider
        JSR ClearObjectTables
        JSR LoadLevelStream
        JSR Routine13FF
        JSR DrawStatus
        DEC SoundIrqGate
        LDA #TYPE_KEY
        LDY #&09
        JSR Routine1B7E
        DEX
        STX KeysRemaining
        LDA TickCounter
        STA LastTick

; Main live frame loop.
Core_MainGameFrame:
        JSR FrameUpdate
        BIT PlayerDeathState
        BMI Core_PlayerDied
        BIT KeysRemaining
        BMI Core_ScreenComplete
        JSR TimerAndKeys
        BNE Core_BackToTitle
        JSR SpawnHazard
        JMP MainGameFrame

Core_PlayerDied:
        JSR ResetCountdownDivider
        LDA #&82
        JSR Routine163C
        DEC Lives
        BNE Core_RestartScreen
        JSR HighScoreInsert
        BCC Core_BackToTitle
        JMP Core_NewGameRuntime
Core_BackToTitle:
        JMP GameStartTitleLoop

Core_ScreenComplete:
        JSR ScreenComplete
        DEC GameState2F
        LDY #&0A
        STY RelocSourceLo           ; reused by game as a temporary counter
Core_TimeBonusOuter:
        LDA TimeLoBCD
        JSR AddScoreBCD
        LDX TimeHiBCD
        BEQ Core_TimeBonusOuterDone
Core_TimeBonusHigh:
        LDA #&60
        JSR AddScoreBCD
        DEX
        BNE Core_TimeBonusHigh
Core_TimeBonusOuterDone:
        DEC RelocSourceLo
        BNE Core_TimeBonusOuter

        INC BaseScreen
        LDA BaseScreen
        CMP #&03
        BCC Core_RestartScreen
        LDA #&00
        STA BaseScreen
        ADC TransformCycle          ; carry is clear here: A=old transform cycle
        AND #&07
        STA TransformCycle
Core_RestartScreen:
        JMP StartScreen

Core_ResetCountdownDivider:
        LDA #&40
        STA CountdownState
        RTS

; Countdown, sound toggle, freeze/unfreeze and escape processing.
Core_TimerAndKeys:
        TXA
        PHA
        TYA
        PHA
        BIT CountdownState
        BPL Core_CheckSoundKey
        INC CountdownState
        SEC
        SED
        LDA TimeLoBCD
        SBC #&01
        BCS Core_StoreTimeLo
        DEC TimeHiBCD
        LDA #&59
Core_StoreTimeLo:
        STA TimeLoBCD
        CLD
        JSR DrawStatus
        DEC SoundIrqGate
        LDA TimeLoBCD
        ORA TimeHiBCD
        BNE Core_CheckSoundKey

        LDA #&40
        STA CountdownState
        SEC
        LDA HazardReload
        SBC #&0A
        STA HazardReload
        LDA TransformCycle
        LSR A
        BNE Core_ExpiryTransformNonZero
        JSR PrintInlineStream
        EQUB &13,0,0,0,0,0,&EA
        JMP CheckSoundKey
Core_ExpiryTransformNonZero:
        LSR A
        BCC Core_CheckSoundKey
        BNE Core_ExpiryThirdPattern
        JSR PrintInlineStream
        EQUB &13,&03,&0F,0,0,0,&EA
        JMP CheckSoundKey
Core_ExpiryThirdPattern:
        JSR PrintInlineStream
        EQUB &13,&03,&08,0,0,0,&EA

Core_CheckSoundKey:
        LDA #&EF
        LDX SoundEnabled
        BPL Core_PollSoundKey
        LDA #&AE
Core_PollSoundKey:
        JSR Inkey
        BEQ Core_CheckFreeze
        TXA
        EOR #&FF
        STA SoundEnabled
        BPL Core_CheckFreeze
        LDA #&15
        LDX #&04
Core_FlushSoundChannels:
        JSR OSBYTEWrapper
        INX
        CPX #&09
        BCC Core_FlushSoundChannels

Core_CheckFreeze:
        LDA #&A6
        JSR Inkey
        BEQ Core_ExitTimerKeys
        LDA #&96
        JSR Inkey
        BNE Core_ExitTimerKeys
        DEC PauseGate
        BIT CountdownState
        BMI Core_ShowFreeze
        BVS Core_WaitForUnfreeze
Core_ShowFreeze:
        JSR PrintInlineStream
        EQUB &1E
        EQUS " *** Freeze *** "
        EQUB &EA
        DEC SoundIrqGate
Core_WaitForUnfreeze:
        LDA #&96
        JSR Inkey
        BEQ Core_WaitForUnfreeze
        BIT CountdownState
        BMI Core_RedrawAfterFreeze
        BVS Core_FinishUnfreeze
Core_RedrawAfterFreeze:
        JSR DrawStatus
        DEC SoundIrqGate
Core_FinishUnfreeze:
        INC PauseGate

Core_ExitTimerKeys:
        PLA
        TAY
        PLA
        TAX
        LDA #&8F
        JMP Inkey

; Runtime aliases for the decompiled packed block above.  These constants are
; deliberately low-memory runtime addresses; the Core_* labels are high packed
; source positions and therefore must not be used as absolute JSR/JMP operands.
Core_NewGameRuntime = &0B5A

Runtime_0B00_SourceEnd:
; -----------------------------------------------------------------------------
; &31F3: Relocated by Bootstrap: &31F3-&46DD -> runtime &0D01-&21EB.
; -----------------------------------------------------------------------------
Runtime_0D01_Source:
; Wait for the 50 Hz/event tick counter to change.
Main_WaitForTickChange:
        LDA TickCounter
Main_WaitTickLoop:
        CMP TickCounter
        BEQ Main_WaitTickLoop
        RTS

; Synchronise drawing to the User VIA timer using the selected object's Y
; coordinate, transformed for the current screen orientation.
Main_WaitForObjectRaster:
        LDA ObjectY,X
        EOR Orientation
        BIT Orientation
        BPL Main_RasterYReady
        SEC
        SBC #&1C
Main_RasterYReady:
        LSR A
        LSR A
        CLC
        ADC #&FF
        AND #&3F
Main_WaitRasterTimer:
        CMP USER_VIA_T2CH
        BCC Main_WaitRasterTimer
        RTS

; Inline VDU/text printer.  JSR PrintInlineStream is followed by bytes and an
; &EA terminator.  The routine consumes its caller's return address, prints the
; stream, then jumps indirectly to the byte after the terminator.
Main_PrintInlineStream:
        PLA
        STA InlinePtrLo
        PLA
        STA InlinePtrHi
        TYA
        PHA
        JMP PrintInlineAdvance
Main_PrintInlineNext:
        LDY #&00
        LDA (InlinePtrLo),Y
        CMP #&EA
        BEQ Main_PrintInlineDone
        JSR OSWRCH
Main_PrintInlineAdvanceSource:
        INC InlinePtrLo
        BNE Main_PrintInlineNext
        INC InlinePtrHi
        BNE Main_PrintInlineNext
Main_PrintInlineDone:
        PLA
        TAY
        JMP (InlinePtrLo)

; EVENTV handler.  Reload User VIA Timer 2, advance the game tick and maintain
; the two-byte countdown state unless pause/freeze gates suppress it.
Main_TickIRQ:
        PHP
        PHA
        LDA #&50
        STA USER_VIA_T2CL
        LDA #&46
        STA USER_VIA_T2CH
        BIT PauseGate
        BMI Main_TickIRQDone
        INC TickCounter
        BIT CountdownState
        BMI Main_TickCountdown
        BVS Main_TickIRQDone
Main_TickCountdown:
        DEC CountdownDivider
        BNE Main_TickIRQDone
        LDA #&32
        STA CountdownDivider
        DEC CountdownState
Main_TickIRQDone:
        PLA
        PLP
        RTS

; IRQ1V handler.  Service User VIA Timer 2/Timer 1 work owned by Frak and then
; chain through the IRQ1V vector which Bootstrap saved in &4E/&4F.
Main_SoundIRQ:
        PHP
        PHA
        LDA #&20
        BIT USER_VIA_IFR
        BEQ Main_CheckTimer1
        BIT USER_VIA_T2CL           ; read clears the Timer 2 interrupt flag
        BIT SoundIrqGate
        BPL Main_CheckTimer1
        TYA
        PHA
        LDA #&00
        STA SoundIrqGate
        JSR RefreshScrollBuffer
        PLA
        TAY
Main_CheckTimer1:
        BIT USER_VIA_IFR
        BVC Main_ChainOldIRQ
        BIT USER_VIA_T1CL           ; read clears the Timer 1 interrupt flag
        LDA GameState2F
        ORA PauseGate
        BMI Main_ChainOldIRQ
        DEC MusicCountdown
        JSR MusicStep
Main_ChainOldIRQ:
        PLA
        PLP
        JMP (SavedIRQ1VLo)

; Negative-INKEY wrapper.  A contains the BBC internal key number; X and Y are
; preserved.  The Z flag returned by OSBYTE &81 is preserved for the caller.
Main_Inkey:
        STA InkeyCode
        TXA
        PHA
        TYA
        PHA
        LDX InkeyCode
        LDY #&FF
        LDA #&81
        JSR OSBYTEWrapper
        PLA
        TAY
        PLA
        CPX #&00
        PHP
        TAX
        LDA InkeyCode
        PLP
        RTS

; Return a pseudo-random value in A in the range 0 <= result < input A.
; The mask is expanded to the next suitable power-of-two range, then candidates
; are rejected until they fall below the requested limit.  The evolving state is
; mixed with User VIA Timer 1 for additional timing entropy.
Main_RandomBelowA:
        STA Scratch26
        LDA #&80
Main_RandomFindMask:
        BIT Scratch26
        BNE Main_RandomMaskFound
        LSR A
        BCC Main_RandomFindMask
        LDA #&01
Main_RandomMaskFound:
        SEC
        SBC #&01
        ROL A
        STA RandomMask
Main_RandomRetry:
        LDA RandomState
        ADC #&63
        STA RandomState
        EOR USER_VIA_T1CL
        AND RandomMask
        CMP Scratch26
        BEQ Main_RandomDone
        BCS Main_RandomRetry
Main_RandomDone:
        RTS

; Reset the 123 object sprite/type slots and the 23 dynamic velocity slots.
Main_ClearObjectTables:
        LDY #&7B
        LDA #&FF
Main_ClearObjectSprites:
        STA ObjectSprite-1,Y
        DEY
        BNE Main_ClearObjectSprites
        LDX #&17
Main_ClearDynamicSlots:
        LDA #&FF
        STA ObjectDY-1,X
        TYA                         ; Y is zero after the object clear loop
        STA ObjectDX-1,X
        DEX
        BNE Main_ClearDynamicSlots
Main_ClearObjectDone:
        RTS

; USERV filter installed by Bootstrap.  Requests not consumed here are chained
; to the previous USERV saved in &4C/&4D.
Main_UserVHandler:
        BVS Main_ClearObjectDone
        BCC Main_ClearObjectDone
        JMP (SavedUserVLo)

; MOS wrappers bracket calls with OSCallGate so interrupt-side code can see that
; a MOS call is in progress.
Main_OSBYTEWrapper:
        DEC OSCallGate
        JSR OSBYTE
        INC OSCallGate
        RTS

Main_OSWORDWrapper:
        DEC OSCallGate
        JSR OSWORD
        INC OSCallGate
        RTS

Runtime_0D01_DecompiledEnd:
; -----------------------------------------------------------------------------
; Reachable game engine, runtime &0E0B-&1FF8.
;
; This is a code/data-aware disassembly generated from the Stage 2 reachability
; map.  Reachable instructions are assembly; bytes which are not proven code
; remain EQUB data.  Absolute operands deliberately name the fixed LOW runtime
; map, while relative branches use the high packed-source labels below.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Runtime &0E0B: ladder/rope collision test.
; -----------------------------------------------------------------------------
Code_TestLadderCollision:
        STA     Scratch26                            ; &0E0B: 85 26
        TXA                                          ; &0E0D: 8A
        PHA                                          ; &0E0E: 48
        TYA                                          ; &0E0F: 98
        PHA                                          ; &0E10: 48
        LDX     Scratch26                            ; &0E11: A6 26
        SEC                                          ; &0E13: 38
        SBC     #&0E                                 ; &0E14: E9 0E
        STA     &48                                  ; &0E16: 85 48
        CLC                                          ; &0E18: 18
        ADC     #&1E                                 ; &0E19: 69 1E
        STA     &47                                  ; &0E1B: 85 47
        LDY     ObjectX,X                            ; &0E1D: BC 68 03
        STY     &45                                  ; &0E20: 84 45
        INY                                          ; &0E22: C8
        STY     &46                                  ; &0E23: 84 46
        LDA     #&04                                 ; &0E25: A9 04
        JSR     CollisionScan                        ; &0E27: 20 72 14
        PLA                                          ; &0E2A: 68
        TAY                                          ; &0E2B: A8
        PLA                                          ; &0E2C: 68
        TAX                                          ; &0E2D: AA
        RTS                                          ; &0E2E: 60
        LDA     #&00                                 ; &0E2F: A9 00
        JSR     TestLadderCollision                  ; &0E31: 20 0B 0E
        BCC     L0E5E                                ; &0E34: 90 28
        BIT     State53                              ; &0E36: 24 53
        BMI     L0E55                                ; &0E38: 30 1B
        CPY     ObjectY                              ; &0E3A: CC E3 03
        PHP                                          ; &0E3D: 08
        STX     Scratch26                            ; &0E3E: 86 26
        LDX     CollisionObject                      ; &0E40: A6 64
        LDA     ObjectY,X                            ; &0E42: BD E3 03
        CMP     ObjectY                              ; &0E45: CD E3 03
        ROR     A                                    ; &0E48: 6A
        LDX     Scratch26                            ; &0E49: A6 26
        STA     Scratch26                            ; &0E4B: 85 26
        PLP                                          ; &0E4D: 28
        ROR     A                                    ; &0E4E: 6A
        CLC                                          ; &0E4F: 18
        EOR     Scratch26                            ; &0E50: 45 26
        BMI     L0E5E                                ; &0E52: 30 0A
        SEC                                          ; &0E54: 38
L0E55:
        DEC     State54                              ; &0E55: C6 54
        LDA     #&00                                 ; &0E57: A9 00
        STA     ObjectDX                             ; &0E59: 8D D9 04
        LDX     #&13                                 ; &0E5C: A2 13
L0E5E:
        RTS                                          ; &0E5E: 60

; -----------------------------------------------------------------------------
; Runtime &0E5F: floor/platform collision test.
; -----------------------------------------------------------------------------
Code_TestFloorCollision:
        STA     &47                                  ; &0E5F: 85 47
        STA     &48                                  ; &0E61: 85 48
        DEC     &48                                  ; &0E63: C6 48
        TXA                                          ; &0E65: 8A
        PHA                                          ; &0E66: 48
        TYA                                          ; &0E67: 98
        PHA                                          ; &0E68: 48
        LDX     #&00                                 ; &0E69: A2 00
        LDA     ObjectX,X                            ; &0E6B: BD 68 03
        STA     &45                                  ; &0E6E: 85 45
        STA     &46                                  ; &0E70: 85 46
        INC     &46                                  ; &0E72: E6 46
        LDA     #&02                                 ; &0E74: A9 02
        JSR     CollisionScan                        ; &0E76: 20 72 14
        PLA                                          ; &0E79: 68
        TAY                                          ; &0E7A: A8
        PLA                                          ; &0E7B: 68
        TAX                                          ; &0E7C: AA
        RTS                                          ; &0E7D: 60
        EQUB &0E,&0D,&0F,&10,&FF,&28,&29,&2A,&2B,&2C,&2D,&2E,&2F,&30,&31,&32    ; runtime &0E7E
        EQUB &33    ; runtime &0E8E

; -----------------------------------------------------------------------------
; Runtime &0E8F: Trogg/player update.
; -----------------------------------------------------------------------------
Code_TroggUpdate:
        STX     SavedSpriteType                      ; &0E8F: 86 58
        DEC     State55                              ; &0E91: C6 55
        LDA     #&00                                 ; &0E93: A9 00
        STA     ObjectDX                             ; &0E95: 8D D9 04
        LDX     #&02                                 ; &0E98: A2 02
        CLC                                          ; &0E9A: 18
        LDA     TroggDirection                       ; &0E9B: A5 57
        STA     ObjectDX,X                           ; &0E9D: 9D D9 04
        ADC     ObjectX                              ; &0EA0: 6D 68 03
        BIT     TroggDirection                       ; &0EA3: 24 57
        BPL     L0EAA                                ; &0EA5: 10 03
        SEC                                          ; &0EA7: 38
        SBC     #&02                                 ; &0EA8: E9 02
L0EAA:
        STA     ObjectX,X                            ; &0EAA: 9D 68 03
        STA     &65                                  ; &0EAD: 85 65
        CLC                                          ; &0EAF: 18
        ADC     #&02                                 ; &0EB0: 69 02
        STA     ObjectX+&1                           ; &0EB2: 8D 69 03
        CLC                                          ; &0EB5: 18
        LDA     ObjectY                              ; &0EB6: AD E3 03
        ADC     #&0B                                 ; &0EB9: 69 0B
        STA     ObjectY+&1                           ; &0EBB: 8D E4 03
        STA     ObjectY+&2                           ; &0EBE: 8D E5 03
        INC     ObjectY+&1                           ; &0EC1: EE E4 03
        LDY     #&01                                 ; &0EC4: A0 01
        STY     &79                                  ; &0EC6: 84 79
        DEY                                          ; &0EC8: 88
        STY     &66                                  ; &0EC9: 84 66
        DEY                                          ; &0ECB: 88
        STY     &67                                  ; &0ECC: 84 67
        STY     &78                                  ; &0ECE: 84 78
        LDX     #&3D                                 ; &0ED0: A2 3D
        LDA     TroggDirection                       ; &0ED2: A5 57
        BMI     L0EDA                                ; &0ED4: 30 04
        LDA     #&00                                 ; &0ED6: A9 00
        LDX     #&3C                                 ; &0ED8: A2 3C
L0EDA:
        STA     ObjectDX+&1                          ; &0EDA: 8D DA 04
        TXA                                          ; &0EDD: 8A
        PHA                                          ; &0EDE: 48
        LDX     #&00                                 ; &0EDF: A2 00
        JSR     WaitForObjectRaster                  ; &0EE1: 20 08 0D
        INC     &67                                  ; &0EE4: E6 67
        BEQ     L0EF7                                ; &0EE6: F0 0F
        INX                                          ; &0EE8: E8
        LDA     ObjectSprite,X                       ; &0EE9: BD 5E 04
        CMP     #&FF                                 ; &0EEC: C9 FF
        BEQ     L0EF3                                ; &0EEE: F0 03
        JSR     ObjectModeC0                         ; &0EF0: 20 23 0B
L0EF3:
        INX                                          ; &0EF3: E8
        JSR     ObjectModeC0                         ; &0EF4: 20 23 0B
L0EF7:
        LDX     #&02                                 ; &0EF7: A2 02
        CLC                                          ; &0EF9: 18
        LDA     &66                                  ; &0EFA: A5 66
        ADC     ObjectDX,X                           ; &0EFC: 7D D9 04
        BMI     L0F09                                ; &0EFF: 30 08
        CMP     #&04                                 ; &0F01: C9 04
        BCC     L0F0B                                ; &0F03: 90 06
        LDA     #&00                                 ; &0F05: A9 00
        BEQ     L0F0B                                ; &0F07: F0 02
L0F09:
        LDA     #&03                                 ; &0F09: A9 03
L0F0B:
        STA     &66                                  ; &0F0B: 85 66
        TAX                                          ; &0F0D: AA
        LDA     &0E7E,X                              ; &0F0E: BD 7E 0E
        LDX     #&02                                 ; &0F11: A2 02
        STA     ObjectSprite,X                       ; &0F13: 9D 5E 04
        LDA     TroggDirection                       ; &0F16: A5 57
        CMP     ObjectDX+&2                          ; &0F18: CD DB 04
        BNE     L0F36                                ; &0F1B: D0 19
        LDA     ObjectX,X                            ; &0F1D: BD 68 03
        CMP     #&C8                                 ; &0F20: C9 C8
        BCS     L0F33                                ; &0F22: B0 0F
        LDA     &67                                  ; &0F24: A5 67
        CMP     #&05                                 ; &0F26: C9 05
        BCC     L0F36                                ; &0F28: 90 0C
        CMP     #&0B                                 ; &0F2A: C9 0B
        BCS     L0F33                                ; &0F2C: B0 05
        JSR     ReadYoyo                             ; &0F2E: 20 59 13
        BNE     L0F36                                ; &0F31: D0 03
L0F33:
        JSR     &1074                                ; &0F33: 20 74 10
L0F36:
        CLC                                          ; &0F36: 18
        LDA     ObjectX,X                            ; &0F37: BD 68 03
        ADC     ObjectDX,X                           ; &0F3A: 7D D9 04
        CLC                                          ; &0F3D: 18
        ADC     ObjectDX,X                           ; &0F3E: 7D D9 04
        STA     ObjectX,X                            ; &0F41: 9D 68 03
        DEX                                          ; &0F44: CA
        BNE     L0F36                                ; &0F45: D0 EF
        CLC                                          ; &0F47: 18
        LDA     &78                                  ; &0F48: A5 78
        ADC     &79                                  ; &0F4A: 65 79
        STA     &78                                  ; &0F4C: 85 78
        TAY                                          ; &0F4E: A8
        LDA     &0E82,Y                              ; &0F4F: B9 82 0E
        STA     ObjectSprite+&1                      ; &0F52: 8D 5F 04
        LDA     ObjectX+&2                           ; &0F55: AD 6A 03
        CMP     &65                                  ; &0F58: C5 65
        BEQ     L0FD0                                ; &0F5A: F0 74
        LDX     #&02                                 ; &0F5C: A2 02
        LDA     #&08                                 ; &0F5E: A9 08
        BIT     CountdownState                       ; &0F60: 24 85
        BMI     L0F68                                ; &0F62: 30 04
        BVC     L0F68                                ; &0F64: 50 02
        LDA     #&80                                 ; &0F66: A9 80
L0F68:
        JSR     &1CBD                                ; &0F68: 20 BD 1C
        BCS     L0F79                                ; &0F6B: B0 0C
L0F6D:
        JSR     ObjectMode00                         ; &0F6D: 20 20 0B
        DEX                                          ; &0F70: CA
        BNE     L0F6D                                ; &0F71: D0 FA
        PLA                                          ; &0F73: 68
        TAX                                          ; &0F74: AA
L0F75:
        LDY     ObjectY                              ; &0F75: AC E3 03
        RTS                                          ; &0F78: 60
L0F79:
        LDX     #&AC                                 ; &0F79: A2 AC
        JSR     SoundOSWORD7                         ; &0F7B: 20 A9 18
        LDA     &94                                  ; &0F7E: A5 94
        CMP     #&0C                                 ; &0F80: C9 0C
        BNE     L0FBA                                ; &0F82: D0 36
        LDX     #&01                                 ; &0F84: A2 01
        JSR     ObjectMode00                         ; &0F86: 20 20 0B
        INX                                          ; &0F89: E8
        JSR     ObjectMode00                         ; &0F8A: 20 20 0B
        LDX     CollisionObject                      ; &0F8D: A6 64
        LDA     #&05                                 ; &0F8F: A9 05
        STA     TYPE_TROGG_0                         ; &0F91: 85 34
L0F93:
        JSR     WaitForTickChange                    ; &0F93: 20 01 0D
        JSR     WaitForObjectRaster                  ; &0F96: 20 08 0D
        JSR     ObjectModeC0                         ; &0F99: 20 23 0B
        LDA     ObjectX,X                            ; &0F9C: BD 68 03
        LDY     #&08                                 ; &0F9F: A0 08
L0FA1:
        CLC                                          ; &0FA1: 18
        ADC     TroggDirection                       ; &0FA2: 65 57
        DEY                                          ; &0FA4: 88
        BNE     L0FA1                                ; &0FA5: D0 FA
        STA     ObjectX,X                            ; &0FA7: 9D 68 03
        JSR     ObjectMode00                         ; &0FAA: 20 20 0B
        DEC     TYPE_TROGG_0                         ; &0FAD: C6 34
        BNE     L0F93                                ; &0FAF: D0 E2
        LDX     #&01                                 ; &0FB1: A2 01
        JSR     ObjectModeC0                         ; &0FB3: 20 23 0B
        INX                                          ; &0FB6: E8
        JSR     ObjectModeC0                         ; &0FB7: 20 23 0B
L0FBA:
        JSR     &1074                                ; &0FBA: 20 74 10
        LDX     CollisionObject                      ; &0FBD: A6 64
        JSR     &12A0                                ; &0FBF: 20 A0 12
        LDA     #&25                                 ; &0FC2: A9 25
        JSR     AddScoreBCD                          ; &0FC4: 20 B8 15
        JSR     DrawStatus                           ; &0FC7: 20 DB 15
        DEC     SoundIrqGate                         ; &0FCA: C6 70
        LDX     #&02                                 ; &0FCC: A2 02
        BNE     L0F6D                                ; &0FCE: D0 9D
L0FD0:
        INC     State55                              ; &0FD0: E6 55
        LDA     #&FF                                 ; &0FD2: A9 FF
        STA     ObjectSprite+&1                      ; &0FD4: 8D 5F 04
        STA     ObjectSprite+&2                      ; &0FD7: 8D 60 04
        PLA                                          ; &0FDA: 68
        LDX     SavedSpriteType                      ; &0FDB: A6 58
        BNE     L0F75                                ; &0FDD: D0 96
L0FDF:
        JMP     TroggUpdate                          ; &0FDF: 4C 8F 0E
L0FE2:
        JMP     &113B                                ; &0FE2: 4C 3B 11
L0FE5:
        JMP     &10DE                                ; &0FE5: 4C DE 10
L0FE8:
        JMP     &0EDD                                ; &0FE8: 4C DD 0E
        LSR     &5D                                  ; &0FEB: 46 5D
        LDX     ObjectSprite                         ; &0FED: AE 5E 04
        LDY     ObjectY                              ; &0FF0: AC E3 03
        BIT     State55                              ; &0FF3: 24 55
        BMI     L0FE8                                ; &0FF5: 30 F1
        BIT     State53                              ; &0FF7: 24 53
        BMI     L0FE5                                ; &0FF9: 30 EA
        BIT     State54                              ; &0FFB: 24 54
        BMI     L0FE2                                ; &0FFD: 30 E3
        LDX     #&00                                 ; &0FFF: A2 00
        JSR     ReadHorizontal                       ; &1001: 20 F9 12
        STX     ObjectDX                             ; &1004: 8E D9 04
        TXA                                          ; &1007: 8A
        BEQ     L100C                                ; &1008: F0 02
        STX     TroggDirection                       ; &100A: 86 57
L100C:
        LDX     ObjectSprite                         ; &100C: AE 5E 04
        STX     SavedSpriteType                      ; &100F: 86 58
        JSR     ReadVertical                         ; &1011: 20 1D 13
        CPY     ObjectY                              ; &1014: CC E3 03
        BEQ     L102F                                ; &1017: F0 16
        JSR     &0E2F                                ; &1019: 20 2F 0E
        BCS     L1069                                ; &101C: B0 4B
        CPY     ObjectY                              ; &101E: CC E3 03
        LDY     ObjectY                              ; &1021: AC E3 03
        BCC     L102F                                ; &1024: 90 09
        BIT     &5D                                  ; &1026: 24 5D
        BVC     L1034                                ; &1028: 50 0A
        BCC     L102F                                ; &102A: 90 03
        JMP     &10CB                                ; &102C: 4C CB 10
L102F:
        ASL     &5D                                  ; &102F: 06 5D
        SEC                                          ; &1031: 38
        ROR     &5D                                  ; &1032: 66 5D
L1034:
        LDA     ObjectDX                             ; &1034: AD D9 04
        BEQ     L1059                                ; &1037: F0 20
        BMI     L104C                                ; &1039: 30 11
        LDX     InputPhase                           ; &103B: A6 32
        INX                                          ; &103D: E8
        CPX     #&04                                 ; &103E: E0 04
        BCC     L1044                                ; &1040: 90 02
        LDX     #&00                                 ; &1042: A2 00
L1044:
        STX     InputPhase                           ; &1044: 86 32
        LDA     &128A,X                              ; &1046: BD 8A 12
        TAX                                          ; &1049: AA
        BNE     L1059                                ; &104A: D0 0D
L104C:
        LDX     InputPhase                           ; &104C: A6 32
        DEX                                          ; &104E: CA
        BPL     L1053                                ; &104F: 10 02
        LDX     #&03                                 ; &1051: A2 03
L1053:
        STX     InputPhase                           ; &1053: 86 32
        LDA     &128E,X                              ; &1055: BD 8E 12
        TAX                                          ; &1058: AA
L1059:
        JSR     ReadYoyo                             ; &1059: 20 59 13
        BNE     L0FDF                                ; &105C: D0 81
        LDA     #&00                                 ; &105E: A9 00
        JSR     MoveTest                             ; &1060: 20 85 10
        BCS     L106A                                ; &1063: B0 05
        LDA     #&FF                                 ; &1065: A9 FF
        STA     State53                              ; &1067: 85 53
L1069:
        RTS                                          ; &1069: 60
L106A:
        LDY     CollisionObject                      ; &106A: A4 64
        STY     &77                                  ; &106C: 84 77
        LDA     ObjectY,Y                            ; &106E: B9 E3 03
        TAY                                          ; &1071: A8
        INY                                          ; &1072: C8
        RTS                                          ; &1073: 60
        LDA     #&FF                                 ; &1074: A9 FF
        STA     &79                                  ; &1076: 85 79
        LDA     TroggDirection                       ; &1078: A5 57
        EOR     #&FE                                 ; &107A: 49 FE
        STA     ObjectDX+&2                          ; &107C: 8D DB 04
        BMI     L1069                                ; &107F: 30 E8
        STA     ObjectDX+&1                          ; &1081: 8D DA 04
        RTS                                          ; &1084: 60

; -----------------------------------------------------------------------------
; Runtime &1085: movement/collision feasibility test.
; -----------------------------------------------------------------------------
Code_MoveTest:
        STA     Scratch26                            ; &1085: 85 26
        TXA                                          ; &1087: 8A
        PHA                                          ; &1088: 48
        TYA                                          ; &1089: 98
        PHA                                          ; &108A: 48
        LDX     Scratch26                            ; &108B: A6 26
        CLC                                          ; &108D: 18
        LDA     ObjectX,X                            ; &108E: BD 68 03
        ADC     ObjectDX,X                           ; &1091: 7D D9 04
        STA     &45                                  ; &1094: 85 45
        STA     &46                                  ; &1096: 85 46
        INC     &46                                  ; &1098: E6 46
        CLC                                          ; &109A: 18
        LDA     ObjectY,X                            ; &109B: BD E3 03
        STA     &47                                  ; &109E: 85 47
        ADC     ObjectDY,X                           ; &10A0: 7D F0 04
        STA     &48                                  ; &10A3: 85 48
        LDA     ObjectDY,X                           ; &10A5: BD F0 04
        BPL     L10C5                                ; &10A8: 10 1B
        LDA     #&02                                 ; &10AA: A9 02
        JSR     CollisionScan                        ; &10AC: 20 72 14
        BCC     L10C6                                ; &10AF: 90 15
        LDX     SavedObjectIndex                     ; &10B1: A6 33
        LDA     #&F6                                 ; &10B3: A9 F6
        CMP     ObjectDY,X                           ; &10B5: DD F0 04
        BCS     L10C6                                ; &10B8: B0 0C
        LDX     CollisionObject                      ; &10BA: A6 64
        SEC                                          ; &10BC: 38
        LDA     ObjectY,X                            ; &10BD: BD E3 03
        SBC     &48                                  ; &10C0: E5 48
        SEC                                          ; &10C2: 38
        SBC     #&05                                 ; &10C3: E9 05
L10C5:
        ASL     A                                    ; &10C5: 0A
L10C6:
        PLA                                          ; &10C6: 68
        TAY                                          ; &10C7: A8
        PLA                                          ; &10C8: 68
        TAX                                          ; &10C9: AA
        RTS                                          ; &10CA: 60
        LDA     #&05                                 ; &10CB: A9 05
        STA     ObjectDY                             ; &10CD: 8D F0 04
        DEC     State53                              ; &10D0: C6 53
        LDA     ObjectDX                             ; &10D2: AD D9 04
        BEQ     L10DE                                ; &10D5: F0 07
        LDX     #&36                                 ; &10D7: A2 36
        ASL     A                                    ; &10D9: 0A
        BCC     L10DE                                ; &10DA: 90 02
        LDX     #&3A                                 ; &10DC: A2 3A
L10DE:
        JSR     ReadVertical                         ; &10DE: 20 1D 13
        CLC                                          ; &10E1: 18
        LDA     ObjectY                              ; &10E2: AD E3 03
        ADC     ObjectDY                             ; &10E5: 6D F0 04
        BIT     ObjectDY                             ; &10E8: 2C F0 04
        BPL     L10F3                                ; &10EB: 10 06
        BCS     L1101                                ; &10ED: B0 12
        LDY     #&00                                 ; &10EF: A0 00
        BEQ     L1126                                ; &10F1: F0 33
L10F3:
        CMP     #&DE                                 ; &10F3: C9 DE
        BCC     L1101                                ; &10F5: 90 0A
        LDA     #&00                                 ; &10F7: A9 00
        SBC     ObjectDY                             ; &10F9: ED F0 04
        STA     ObjectDY                             ; &10FC: 8D F0 04
        LDA     #&DE                                 ; &10FF: A9 DE
L1101:
        DEC     ObjectDY                             ; &1101: CE F0 04
        CPY     ObjectY                              ; &1104: CC E3 03
        PHP                                          ; &1107: 08
        TAY                                          ; &1108: A8
        PLP                                          ; &1109: 28
        BEQ     L1118                                ; &110A: F0 0C
        LDA     ObjectDY                             ; &110C: AD F0 04
        CMP     #&F9                                 ; &110F: C9 F9
        BMI     L1118                                ; &1111: 30 05
        JSR     &0E2F                                ; &1113: 20 2F 0E
        BCS     L1126                                ; &1116: B0 0E
L1118:
        LDA     #&00                                 ; &1118: A9 00
        JSR     MoveTest                             ; &111A: 20 85 10
        BCC     L113A                                ; &111D: 90 1B
        LDY     CollisionObject                      ; &111F: A4 64
        LDA     ObjectY,Y                            ; &1121: B9 E3 03
        TAY                                          ; &1124: A8
        INY                                          ; &1125: C8
L1126:
        INC     State53                              ; &1126: E6 53
        LDA     ObjectDY                             ; &1128: AD F0 04
        CMP     #&F9                                 ; &112B: C9 F9
        BPL     L1135                                ; &112D: 10 06
        CMP     #&F9                                 ; &112F: C9 F9
        BCS     L1135                                ; &1131: B0 02
        DEC     PlayerDeathState                     ; &1133: C6 7B
L1135:
        LDA     #&FF                                 ; &1135: A9 FF
        STA     ObjectDY                             ; &1137: 8D F0 04
L113A:
        RTS                                          ; &113A: 60
        LDA     #&00                                 ; &113B: A9 00
        JSR     TestLadderCollision                  ; &113D: 20 0B 0E
        BCC     L119F                                ; &1140: 90 5D
        JSR     ReadVertical                         ; &1142: 20 1D 13
        LDA     ObjectSprite                         ; &1145: AD 5E 04
        CPY     ObjectY                              ; &1148: CC E3 03
        BEQ     L114F                                ; &114B: F0 02
        EOR     #&07                                 ; &114D: 49 07
L114F:
        PHA                                          ; &114F: 48
        LDX     CollisionObject                      ; &1150: A6 64
        LDA     #&02                                 ; &1152: A9 02
        JSR     RandomBelowA                         ; &1154: 20 B6 0D
        LSR     A                                    ; &1157: 4A
        LDA     #&00                                 ; &1158: A9 00
        BCC     L1166                                ; &115A: 90 0A
        SEC                                          ; &115C: 38
        LDA     ObjectX,X                            ; &115D: BD 68 03
        SBC     ObjectX                              ; &1160: ED 68 03
        JSR     &15AE                                ; &1163: 20 AE 15
L1166:
        STA     ObjectDX                             ; &1166: 8D D9 04
        TYA                                          ; &1169: 98
        CMP     ObjectY,X                            ; &116A: DD E3 03
        BCS     L1187                                ; &116D: B0 18
        CPY     ObjectY                              ; &116F: CC E3 03
        BCS     L119C                                ; &1172: B0 28
        TYA                                          ; &1174: 98
        JSR     TestFloorCollision                   ; &1175: 20 5F 0E
        BCC     L119C                                ; &1178: 90 22
L117A:
        LDX     CollisionObject                      ; &117A: A6 64
        LDA     ObjectY,X                            ; &117C: BD E3 03
        TAY                                          ; &117F: A8
        INY                                          ; &1180: C8
        INC     State54                              ; &1181: E6 54
        LDX     SavedSpriteType                      ; &1183: A6 58
        PLA                                          ; &1185: 68
        RTS                                          ; &1186: 60
L1187:
        CPY     ObjectY                              ; &1187: CC E3 03
        BCC     L119C                                ; &118A: 90 10
        BEQ     L119C                                ; &118C: F0 0E
        LDA     ObjectY                              ; &118E: AD E3 03
        JSR     TestFloorCollision                   ; &1191: 20 5F 0E
        BCC     L119C                                ; &1194: 90 06
        TYA                                          ; &1196: 98
        JSR     TestFloorCollision                   ; &1197: 20 5F 0E
        BCC     L117A                                ; &119A: 90 DE
L119C:
        PLA                                          ; &119C: 68
        TAX                                          ; &119D: AA
        RTS                                          ; &119E: 60
L119F:
        INC     State54                              ; &119F: E6 54
        DEC     State53                              ; &11A1: C6 53
        LDA     #&00                                 ; &11A3: A9 00
        STA     ObjectDX                             ; &11A5: 8D D9 04
        LDX     SavedSpriteType                      ; &11A8: A6 58
        RTS                                          ; &11AA: 60
        EQUB &60    ; runtime &11AB

; -----------------------------------------------------------------------------
; Runtime &11AC: general per-frame object update.
; -----------------------------------------------------------------------------
Code_FrameUpdate:
        LDA     TickCounter                          ; &11AC: A5 44
        SEC                                          ; &11AE: 38
        SBC     LastTick                             ; &11AF: E5 71
        CMP     #&04                                 ; &11B1: C9 04
        BCC     Code_FrameUpdate                     ; &11B3: 90 F7
        LDA     TickCounter                          ; &11B5: A5 44
        STA     LastTick                             ; &11B7: 85 71
        LDA     #&00                                 ; &11B9: A9 00
        STA     &52                                  ; &11BB: 85 52
        LDY     ObjectY                              ; &11BD: AC E3 03
        JSR     &0FEB                                ; &11C0: 20 EB 0F
        CLC                                          ; &11C3: 18
        LDA     ObjectX                              ; &11C4: AD 68 03
        ADC     ObjectDX                             ; &11C7: 6D D9 04
        CMP     #&04                                 ; &11CA: C9 04
        BCC     L11D2                                ; &11CC: 90 04
        CMP     #&C4                                 ; &11CE: C9 C4
        BCC     L11D5                                ; &11D0: 90 03
L11D2:
        LDA     ObjectX                              ; &11D2: AD 68 03
L11D5:
        STA     &69                                  ; &11D5: 85 69
        STX     &68                                  ; &11D7: 86 68
        STY     &6A                                  ; &11D9: 84 6A
        CMP     ObjectX                              ; &11DB: CD 68 03
        BEQ     L1203                                ; &11DE: F0 23
        BCC     L11F4                                ; &11E0: 90 12
        CMP     #&A0                                 ; &11E2: C9 A0
        BCS     L1203                                ; &11E4: B0 1D
        CMP     #&29                                 ; &11E6: C9 29
        BCC     L1203                                ; &11E8: 90 19
        LDA     #&80                                 ; &11EA: A9 80
        STA     &52                                  ; &11EC: 85 52
        JSR     &13E5                                ; &11EE: 20 E5 13
        JMP     &1203                                ; &11F1: 4C 03 12
L11F4:
        CMP     #&28                                 ; &11F4: C9 28
        BCC     L1203                                ; &11F6: 90 0B
        CMP     #&9F                                 ; &11F8: C9 9F
        BCS     L1203                                ; &11FA: B0 07
        LDA     #&40                                 ; &11FC: A9 40
        STA     &52                                  ; &11FE: 85 52
        JSR     &13CB                                ; &1200: 20 CB 13
L1203:
        LDX     #&00                                 ; &1203: A2 00
        JSR     &1C3F                                ; &1205: 20 3F 1C
        BEQ     L1246                                ; &1208: F0 3C
        LDA     &6A                                  ; &120A: A5 6A
        LSR     A                                    ; &120C: 4A
        LSR     A                                    ; &120D: 4A
        STA     &01B8                                ; &120E: 8D B8 01
        LDX     #&B4                                 ; &1211: A2 B4
        JSR     SoundOSWORD7                         ; &1213: 20 A9 18
        LDX     #&00                                 ; &1216: A2 00
        BIT     State55                              ; &1218: 24 55
        BMI     L1222                                ; &121A: 30 06
        JSR     WaitForTickChange                    ; &121C: 20 01 0D
        JSR     WaitForObjectRaster                  ; &121F: 20 08 0D
L1222:
        JSR     SetCrtcOrigin                        ; &1222: 20 28 14
        LDA     &52                                  ; &1225: A5 52
        BEQ     L122B                                ; &1227: F0 02
        DEC     SoundIrqGate                         ; &1229: C6 70
L122B:
        LDX     #&00                                 ; &122B: A2 00
        JSR     ObjectMode80                         ; &122D: 20 1C 0B
        LDA     &68                                  ; &1230: A5 68
        LDX     &69                                  ; &1232: A6 69
        LDY     &6A                                  ; &1234: A4 6A
        JSR     DrawSpriteAt                         ; &1236: 20 32 0B
        LDA     &6A                                  ; &1239: A5 6A
        JSR     &0D0B                                ; &123B: 20 0B 0D
        LDX     #&00                                 ; &123E: A2 00
        JSR     ObjectMode40                         ; &1240: 20 18 0B
        JSR     &1C53                                ; &1243: 20 53 1C
L1246:
        JSR     ObjectMode00                         ; &1246: 20 20 0B
        LDA     #&10                                 ; &1249: A9 10
        JSR     &1CBD                                ; &124B: 20 BD 1C
        BCC     L125C                                ; &124E: 90 0C
        LDX     CollisionObject                      ; &1250: A6 64
        LDA     ObjectSprite,X                       ; &1252: BD 5E 04
        LDY     #&00                                 ; &1255: A0 00
        JSR     TypeDispatch                         ; &1257: 20 D1 12
        LDX     #&00                                 ; &125A: A2 00
L125C:
        LDA     ObjectY,X                            ; &125C: BD E3 03
        BEQ     L1268                                ; &125F: F0 07
        LDA     #&01                                 ; &1261: A9 01
        JSR     &1CBD                                ; &1263: 20 BD 1C
        BCC     L126A                                ; &1266: 90 02
L1268:
        DEC     PlayerDeathState                     ; &1268: C6 7B
L126A:
        BIT     PlayerDeathState                     ; &126A: 24 7B
        BPL     L127E                                ; &126C: 10 10
        LDA     #&8E                                 ; &126E: A9 8E
        JSR     SelectTune                           ; &1270: 20 B4 18
        LDX     ObjectX                              ; &1273: AE 68 03
        LDY     ObjectY                              ; &1276: AC E3 03
        LDA     #&5B                                 ; &1279: A9 5B
        JSR     DrawSpriteAt                         ; &127B: 20 32 0B
L127E:
        BIT     &52                                  ; &127E: 24 52
        BVS     L1287                                ; &1280: 70 05
        BPL     L12A8                                ; &1282: 10 24
        JMP     &13F3                                ; &1284: 4C F3 13
L1287:
        JMP     &13D9                                ; &1287: 4C D9 13
        EQUB &34,&35,&36,&37,&3B,&3A,&39,&38    ; runtime &128A

; -----------------------------------------------------------------------------
; Runtime &1292: key pickup.
; -----------------------------------------------------------------------------
Code_KeyCollect:
        LDA     #&50                                 ; &1292: A9 50
        JSR     AddScoreBCD                          ; &1294: 20 B8 15
        DEC     KeysRemaining                        ; &1297: C6 7A
        LDX     #&BC                                 ; &1299: A2 BC
        JSR     SoundOSWORD7                         ; &129B: 20 A9 18
        LDX     CollisionObject                      ; &129E: A6 64
        JSR     ObjectModeC0                         ; &12A0: 20 23 0B
        LDA     #&FF                                 ; &12A3: A9 FF
        STA     ObjectSprite,X                       ; &12A5: 9D 5E 04
L12A8:
        RTS                                          ; &12A8: 60

; -----------------------------------------------------------------------------
; Runtime &12A9: gem pickup.
; -----------------------------------------------------------------------------
Code_GemCollect:
        LDA     #&15                                 ; &12A9: A9 15
        JSR     AddScoreBCD                          ; &12AB: 20 B8 15
        JSR     &1299                                ; &12AE: 20 99 12
        JSR     DrawStatus                           ; &12B1: 20 DB 15
        DEC     SoundIrqGate                         ; &12B4: C6 70
L12B6:
        RTS                                          ; &12B6: 60

; -----------------------------------------------------------------------------
; Runtime &12B7: light-bulb/time pickup.
; -----------------------------------------------------------------------------
Code_BulbCollect:
        BIT     CountdownState                       ; &12B7: 24 85
        BMI     L12BD                                ; &12B9: 30 02
        BVS     L12B6                                ; &12BB: 70 F9
L12BD:
        CLC                                          ; &12BD: 18
        SED                                          ; &12BE: F8
        LDA     TimeLoBCD                            ; &12BF: A5 82
        ADC     #&10                                 ; &12C1: 69 10
        CMP     #&60                                 ; &12C3: C9 60
        BCC     L12CB                                ; &12C5: 90 04
        SBC     #&60                                 ; &12C7: E9 60
        INC     TimeHiBCD                            ; &12C9: E6 83
L12CB:
        STA     TimeLoBCD                            ; &12CB: 85 82
        CLD                                          ; &12CD: D8
        JMP     &12AE                                ; &12CE: 4C AE 12

; -----------------------------------------------------------------------------
; Runtime &12D1: object type dispatcher.
; -----------------------------------------------------------------------------
Code_TypeDispatch:
        CMP     &12EA,Y                              ; &12D1: D9 EA 12
        BEQ     L12DB                                ; &12D4: F0 05
        INY                                          ; &12D6: C8
        INY                                          ; &12D7: C8
        INY                                          ; &12D8: C8
        BNE     Code_TypeDispatch                    ; &12D9: D0 F6
L12DB:
        PHA                                          ; &12DB: 48
        LDA     &12EB,Y                              ; &12DC: B9 EB 12
        STA     InlinePtrLo                          ; &12DF: 85 29
        LDA     &12EC,Y                              ; &12E1: B9 EC 12
        STA     InlinePtrHi                          ; &12E4: 85 2A
        PLA                                          ; &12E6: 68
        JMP     (InlinePtrLo)                        ; &12E7: 6C 29 00
        EQUB &17,&92,&12,&23,&B7,&12,&16,&A9,&12,&27,&68,&1C,&25,&79,&1C    ; runtime &12EA

; -----------------------------------------------------------------------------
; Runtime &12F9: horizontal control reader.
; -----------------------------------------------------------------------------
Code_ReadHorizontal:
        LDA     InputMode                            ; &12F9: A5 86
        BNE     L130E                                ; &12FB: D0 11
        LDA     #&9E                                 ; &12FD: A9 9E
        JSR     Inkey                                ; &12FF: 20 9C 0D
        BEQ     L1305                                ; &1302: F0 01
        DEX                                          ; &1304: CA
L1305:
        LDA     #&BD                                 ; &1305: A9 BD
        JSR     Inkey                                ; &1307: 20 9C 0D
        BEQ     L130D                                ; &130A: F0 01
L130C:
        INX                                          ; &130C: E8
L130D:
        RTS                                          ; &130D: 60
L130E:
        LDA     #&01                                 ; &130E: A9 01
        JSR     &1376                                ; &1310: 20 76 13
        CMP     #&64                                 ; &1313: C9 64
        BCC     L130C                                ; &1315: 90 F5
        CMP     #&9C                                 ; &1317: C9 9C
        BCC     L130D                                ; &1319: 90 F2
        DEX                                          ; &131B: CA
        RTS                                          ; &131C: 60

; -----------------------------------------------------------------------------
; Runtime &131D: vertical control reader.
; -----------------------------------------------------------------------------
Code_ReadVertical:
        LDA     InputMode                            ; &131D: A5 86
        BNE     L133F                                ; &131F: D0 1E
        LDA     #&B7                                 ; &1321: A9 B7
        JSR     Inkey                                ; &1323: 20 9C 0D
        BEQ     L132B                                ; &1326: F0 03
        JSR     &134C                                ; &1328: 20 4C 13
L132B:
        LDA     #&97                                 ; &132B: A9 97
        JSR     Inkey                                ; &132D: 20 9C 0D
        BEQ     L133E                                ; &1330: F0 0C
L1332:
        DEY                                          ; &1332: 88
        DEY                                          ; &1333: 88
        DEY                                          ; &1334: 88
        BIT     Orientation                          ; &1335: 24 74
        BPL     L133E                                ; &1337: 10 05
        CLC                                          ; &1339: 18
        TYA                                          ; &133A: 98
        ADC     #&06                                 ; &133B: 69 06
        TAY                                          ; &133D: A8
L133E:
        RTS                                          ; &133E: 60
L133F:
        LDA     #&02                                 ; &133F: A9 02
        JSR     &1376                                ; &1341: 20 76 13
        CMP     #&64                                 ; &1344: C9 64
        BCC     L1332                                ; &1346: 90 EA
        CMP     #&9C                                 ; &1348: C9 9C
        BCC     L133E                                ; &134A: 90 F2
        INY                                          ; &134C: C8
        INY                                          ; &134D: C8
        INY                                          ; &134E: C8
        BIT     Orientation                          ; &134F: 24 74
        BPL     L1358                                ; &1351: 10 05
        SEC                                          ; &1353: 38
        TYA                                          ; &1354: 98
        SBC     #&06                                 ; &1355: E9 06
        TAY                                          ; &1357: A8
L1358:
        RTS                                          ; &1358: 60

; -----------------------------------------------------------------------------
; Runtime &1359: yoyo/alternate control reader.
; -----------------------------------------------------------------------------
Code_ReadYoyo:
        LDA     InputMode                            ; &1359: A5 86
        BNE     L1362                                ; &135B: D0 05
        LDA     #&B6                                 ; &135D: A9 B6
        JMP     Inkey                                ; &135F: 4C 9C 0D
L1362:
        TXA                                          ; &1362: 8A
        PHA                                          ; &1363: 48
        TYA                                          ; &1364: 98
        PHA                                          ; &1365: 48
        LDA     #&00                                 ; &1366: A9 00
        JSR     &138A                                ; &1368: 20 8A 13
        STX     Scratch26                            ; &136B: 86 26
        PLA                                          ; &136D: 68
        TAY                                          ; &136E: A8
        PLA                                          ; &136F: 68
        TAX                                          ; &1370: AA
        LDA     Scratch26                            ; &1371: A5 26
        AND     #&01                                 ; &1373: 29 01
        RTS                                          ; &1375: 60
        STA     Scratch26                            ; &1376: 85 26
        TXA                                          ; &1378: 8A
        PHA                                          ; &1379: 48
        TYA                                          ; &137A: 98
        PHA                                          ; &137B: 48
        LDA     Scratch26                            ; &137C: A5 26
        JSR     &138A                                ; &137E: 20 8A 13
        STY     Scratch26                            ; &1381: 84 26
        PLA                                          ; &1383: 68
        TAY                                          ; &1384: A8
        PLA                                          ; &1385: 68
        TAX                                          ; &1386: AA
        LDA     Scratch26                            ; &1387: A5 26
        RTS                                          ; &1389: 60
        TAX                                          ; &138A: AA
        LDA     #&80                                 ; &138B: A9 80
        JMP     OSBYTEWrapper                        ; &138D: 4C FB 0D
        LDX     #&20                                 ; &1390: A2 20
        LDA     Scratch26                            ; &1392: A5 26
        LDA     #&00                                 ; &1394: A9 00
        STA     RelocSourceLo                        ; &1396: 85 3F
        LDY     &0C                                  ; &1398: A4 0C
        LDA     &0D                                  ; &139A: A5 0D
L139C:
        STA     RelocSourceHi                        ; &139C: 85 40
        LDA     #&00                                 ; &139E: A9 00
        STA     (RelocSourceLo),Y                    ; &13A0: 91 3F
        INY                                          ; &13A2: C8
        STA     (RelocSourceLo),Y                    ; &13A3: 91 3F
        INY                                          ; &13A5: C8
        STA     (RelocSourceLo),Y                    ; &13A6: 91 3F
        INY                                          ; &13A8: C8
        STA     (RelocSourceLo),Y                    ; &13A9: 91 3F
        INY                                          ; &13AB: C8
        STA     (RelocSourceLo),Y                    ; &13AC: 91 3F
        INY                                          ; &13AE: C8
        STA     (RelocSourceLo),Y                    ; &13AF: 91 3F
        INY                                          ; &13B1: C8
        STA     (RelocSourceLo),Y                    ; &13B2: 91 3F
        INY                                          ; &13B4: C8
        STA     (RelocSourceLo),Y                    ; &13B5: 91 3F
        DEX                                          ; &13B7: CA
        BEQ     L13CA                                ; &13B8: F0 10
        CLC                                          ; &13BA: 18
        TYA                                          ; &13BB: 98
        ADC     #&79                                 ; &13BC: 69 79
        TAY                                          ; &13BE: A8
        LDA     RelocSourceHi                        ; &13BF: A5 40
        ADC     #&02                                 ; &13C1: 69 02
        BPL     L139C                                ; &13C3: 10 D7
        SEC                                          ; &13C5: 38
        SBC     #&50                                 ; &13C6: E9 50
        BPL     L139C                                ; &13C8: 10 D2
L13CA:
        RTS                                          ; &13CA: 60
        LDY     #&F8                                 ; &13CB: A0 F8
        LDA     #&FF                                 ; &13CD: A9 FF
        JSR     &1411                                ; &13CF: 20 11 14
        JSR     &1390                                ; &13D2: 20 90 13
        DEC     &10                                  ; &13D5: C6 10
        CLC                                          ; &13D7: 18
        RTS                                          ; &13D8: 60
        LDA     #&01                                 ; &13D9: A9 01
        STA     &0F                                  ; &13DB: 85 0F
        JSR     Routine13FF                          ; &13DD: 20 FF 13
        LDA     #&50                                 ; &13E0: A9 50
        STA     &0F                                  ; &13E2: 85 0F
        RTS                                          ; &13E4: 60
        JSR     &1390                                ; &13E5: 20 90 13
        LDY     #&08                                 ; &13E8: A0 08
        LDA     #&00                                 ; &13EA: A9 00
        JSR     &1411                                ; &13EC: 20 11 14
        INC     &10                                  ; &13EF: E6 10
        CLC                                          ; &13F1: 18
        RTS                                          ; &13F2: 60
        LDA     #&4F                                 ; &13F3: A9 4F
        STA     &0E                                  ; &13F5: 85 0E
        JSR     Routine13FF                          ; &13F7: 20 FF 13
        LDA     #&00                                 ; &13FA: A9 00
        STA     &0E                                  ; &13FC: 85 0E
        RTS                                          ; &13FE: 60

; -----------------------------------------------------------------------------
; Runtime &13FF: Routine13FF.
; -----------------------------------------------------------------------------
Code_Routine13FF:
        LDX     #&7A                                 ; &13FF: A2 7A
L1401:
        LDA     ObjectSprite,X                       ; &1401: BD 5E 04
        CMP     #&FF                                 ; &1404: C9 FF
        BEQ     L140B                                ; &1406: F0 03
        JSR     ObjectMode00                         ; &1408: 20 20 0B
L140B:
        DEX                                          ; &140B: CA
        CPX     #&FF                                 ; &140C: E0 FF
        BNE     L1401                                ; &140E: D0 F1
        RTS                                          ; &1410: 60
        PHA                                          ; &1411: 48
        CLC                                          ; &1412: 18
        TYA                                          ; &1413: 98
        ADC     &0C                                  ; &1414: 65 0C
        STA     &0C                                  ; &1416: 85 0C
        PLA                                          ; &1418: 68
        ADC     &0D                                  ; &1419: 65 0D
        BPL     L141F                                ; &141B: 10 02
        SBC     #&4F                                 ; &141D: E9 4F
L141F:
        CMP     #&00                                 ; &141F: C9 00
        BCS     L1425                                ; &1421: B0 02
        ADC     #&50                                 ; &1423: 69 50
L1425:
        STA     &0D                                  ; &1425: 85 0D
        RTS                                          ; &1427: 60

; -----------------------------------------------------------------------------
; Runtime &1428: program CRTC screen origin.
; -----------------------------------------------------------------------------
Code_SetCrtcOrigin:
        LDA     &0C                                  ; &1428: A5 0C
        STA     RelocSourceLo                        ; &142A: 85 3F
        LDA     &0D                                  ; &142C: A5 0D
        LSR     A                                    ; &142E: 4A
        ROR     RelocSourceLo                        ; &142F: 66 3F
        LSR     A                                    ; &1431: 4A
        ROR     RelocSourceLo                        ; &1432: 66 3F
        LSR     A                                    ; &1434: 4A
        ROR     RelocSourceLo                        ; &1435: 66 3F
        LDX     #&0C                                 ; &1437: A2 0C
        SEI                                          ; &1439: 78
        STX     CRTC_ADDRESS                         ; &143A: 8E 00 FE
        STA     CRTC_DATA                            ; &143D: 8D 01 FE
        INX                                          ; &1440: E8
        LDA     RelocSourceLo                        ; &1441: A5 3F
        STX     CRTC_ADDRESS                         ; &1443: 8E 00 FE
        STA     CRTC_DATA                            ; &1446: 8D 01 FE
        CLI                                          ; &1449: 58
        RTS                                          ; &144A: 60
        EQUB &A0,&07,&38,&98,&65,&0C,&85,&24,&A9,&00,&91,&0C,&88,&10,&FB,&65    ; runtime &144B
        EQUB &0D,&85,&25,&C8,&B9,&00,&09,&91,&24,&C8,&D0,&F8,&98,&E6,&25,&A0    ; runtime &145B
        EQUB &07,&91,&24,&88,&10,&FB,&60    ; runtime &146B

; -----------------------------------------------------------------------------
; Runtime &1472: collision scan.
; -----------------------------------------------------------------------------
Code_CollisionScan:
        STA     &5A                                  ; &1472: 85 5A
        STX     SavedObjectIndex                     ; &1474: 86 33
        JSR     &1D19                                ; &1476: 20 19 1D
        JSR     &1D9C                                ; &1479: 20 9C 1D
        TXA                                          ; &147C: 8A
        PHA                                          ; &147D: 48
        TYA                                          ; &147E: 98
        PHA                                          ; &147F: 48
        LDA     CurrentSpriteX                       ; &1480: A5 11
        PHA                                          ; &1482: 48
        LDA     CurrentSpriteY                       ; &1483: A5 12
        PHA                                          ; &1485: 48
        LDY     #&00                                 ; &1486: A0 00
L1488:
        STY     &95                                  ; &1488: 84 95
        LDA     &0B02,Y                              ; &148A: B9 02 0B
        BEQ     L14C1                                ; &148D: F0 32
        LDA     &5A                                  ; &148F: A5 5A
        CMP     #&FF                                 ; &1491: C9 FF
        BEQ     L149A                                ; &1493: F0 05
        AND     &0B01,Y                              ; &1495: 39 01 0B
        BEQ     L14BC                                ; &1498: F0 22
L149A:
        LDX     QueueDescriptors,Y                   ; &149A: BE 00 0B
L149D:
        CPX     SavedObjectIndex                     ; &149D: E4 33
        BEQ     L14B3                                ; &149F: F0 12
        JSR     LoadObject                           ; &14A1: 20 3C 0B
        BCS     L14B3                                ; &14A4: B0 0D
        JSR     &1CB1                                ; &14A6: 20 B1 1C
        BCC     L14B3                                ; &14A9: 90 08
        STX     CollisionObject                      ; &14AB: 86 64
        LDY     &95                                  ; &14AD: A4 95
        STY     &94                                  ; &14AF: 84 94
        BCS     L14C2                                ; &14B1: B0 0F
L14B3:
        INX                                          ; &14B3: E8
        LDY     &95                                  ; &14B4: A4 95
        TXA                                          ; &14B6: 8A
        CMP     &0B03,Y                              ; &14B7: D9 03 0B
        BCC     L149D                                ; &14BA: 90 E1
L14BC:
        INY                                          ; &14BC: C8
        INY                                          ; &14BD: C8
        INY                                          ; &14BE: C8
        BNE     L1488                                ; &14BF: D0 C7
L14C1:
        CLC                                          ; &14C1: 18
L14C2:
        PLA                                          ; &14C2: 68
        STA     CurrentSpriteY                       ; &14C3: 85 12
        PLA                                          ; &14C5: 68
        STA     CurrentSpriteX                       ; &14C6: 85 11
        PLA                                          ; &14C8: 68
        TAY                                          ; &14C9: A8
        PLA                                          ; &14CA: 68
        TAX                                          ; &14CB: AA
        RTS                                          ; &14CC: 60

; -----------------------------------------------------------------------------
; Runtime &14CD: display/orientation initialisation.
; -----------------------------------------------------------------------------
Code_DisplayInit:
        LDA     #&00                                 ; &14CD: A9 00
        STA     &10                                  ; &14CF: 85 10
        LDA     #&00                                 ; &14D1: A9 00
        STA     &0C                                  ; &14D3: 85 0C
        LDA     #&30                                 ; &14D5: A9 30
        STA     &0D                                  ; &14D7: 85 0D
        LDA     #&00                                 ; &14D9: A9 00
        STA     &0E                                  ; &14DB: 85 0E
        LDA     #&50                                 ; &14DD: A9 50
        STA     &0F                                  ; &14DF: 85 0F
        LDA     #&00                                 ; &14E1: A9 00
        STA     Orientation                          ; &14E3: 85 74
        TYA                                          ; &14E5: 98
        LSR     A                                    ; &14E6: 4A
        BCC     L14EB                                ; &14E7: 90 02
        DEC     Orientation                          ; &14E9: C6 74
L14EB:
        JSR     PrintInlineStream                    ; &14EB: 20 21 0D
        EQUB &16,&01,&13,&01,&05,&00,&00,&00,&13,&02,&03,&00,&00,&00,&11,&82    ; runtime &14EE
        EQUB &13,&03,&00,&00,&00,&00,&EA    ; runtime &14FE
        JSR     &1574                                ; &1505: 20 74 15
        TYA                                          ; &1508: 98
        LSR     A                                    ; &1509: 4A
        LSR     A                                    ; &150A: 4A
        BCS     L1529                                ; &150B: B0 1C
        PHP                                          ; &150D: 08
        LDA     &1968,X                              ; &150E: BD 68 19
        PLP                                          ; &1511: 28
        BEQ     L1516                                ; &1512: F0 02
        LDA     #&00                                 ; &1514: A9 00
L1516:
        PHA                                          ; &1516: 48
        JSR     PrintInlineStream                    ; &1517: 20 21 0D
        EQUB &13,&00,&EA    ; runtime &151A
        PLA                                          ; &151D: 68
        JSR     OSWRCH                               ; &151E: 20 EE FF
        JSR     PrintInlineStream                    ; &1521: 20 21 0D
        EQUB &00,&00,&00,&EA    ; runtime &1524
        RTS                                          ; &1528: 60
L1529:
        BNE     L1548                                ; &1529: D0 1D
        JSR     PrintInlineStream                    ; &152B: 20 21 0D
        EQUB &13,&00,&07,&00,&00,&00,&13,&01,&07,&00,&00,&00,&13,&02,&07,&00    ; runtime &152E
        EQUB &00,&00,&13,&03,&00,&00,&00,&00,&EA    ; runtime &153E
        RTS                                          ; &1547: 60
L1548:
        JSR     PrintInlineStream                    ; &1548: 20 21 0D
        EQUB &13,&00,&00,&00,&00,&00,&13,&01,&00,&00,&00,&00,&13,&02,&00,&00    ; runtime &154B
        EQUB &00,&00,&13,&03,&07,&00,&00,&00,&EA    ; runtime &155B
        RTS                                          ; &1564: 60

; -----------------------------------------------------------------------------
; Runtime &1565: Routine1565.
; -----------------------------------------------------------------------------
Code_Routine1565:
        LDY     #&00                                 ; &1565: A0 00
        TYA                                          ; &1567: 98
L1568:
        STA     &0900,Y                              ; &1568: 99 00 09
        DEY                                          ; &156B: 88
        BNE     L1568                                ; &156C: D0 FA
        LDA     #&09                                 ; &156E: A9 09
        STA     &0351                                ; &1570: 8D 51 03
        RTS                                          ; &1573: 60
        JSR     PrintInlineStream                    ; &1574: 20 21 0D
        EQUB &17,&01,&00,&00,&00,&00,&00,&00,&00,&00,&EA    ; runtime &1577
        RTS                                          ; &1582: 60
        JSR     PrintInlineStream                    ; &1583: 20 21 0D
        EQUB &17,&01,&01,&00,&00,&00,&00,&00,&00,&00,&EA    ; runtime &1586
        RTS                                          ; &1591: 60
        CLC                                          ; &1592: 18
        LDA     CurrentSpriteX                       ; &1593: A5 11
        ADC     (&00),Y                              ; &1595: 71 00
        STA     &45                                  ; &1597: 85 45
        LDA     (&08),Y                              ; &1599: B1 08
        ASL     A                                    ; &159B: 0A
        LSR     A                                    ; &159C: 4A
        ADC     &45                                  ; &159D: 65 45
        STA     &46                                  ; &159F: 85 46
        CLC                                          ; &15A1: 18
        LDA     CurrentSpriteY                       ; &15A2: A5 12
        ADC     (&02),Y                              ; &15A4: 71 02
        STA     &48                                  ; &15A6: 85 48
        CLC                                          ; &15A8: 18
        ADC     (&0A),Y                              ; &15A9: 71 0A
        STA     &47                                  ; &15AB: 85 47
        RTS                                          ; &15AD: 60
        BEQ     L15B7                                ; &15AE: F0 07
        BMI     L15B5                                ; &15B0: 30 03
        LDA     #&01                                 ; &15B2: A9 01
        RTS                                          ; &15B4: 60
L15B5:
        LDA     #&FF                                 ; &15B5: A9 FF
L15B7:
        RTS                                          ; &15B7: 60

; -----------------------------------------------------------------------------
; Runtime &15B8: packed-BCD score addition.
; -----------------------------------------------------------------------------
Code_AddScoreBCD:
        LDY     #&00                                 ; &15B8: A0 00
        CLC                                          ; &15BA: 18
        SED                                          ; &15BB: F8
        ADC     ScoreLo                              ; &15BC: 65 38
        STA     ScoreLo                              ; &15BE: 85 38
        LDA     ScoreMid                             ; &15C0: A5 39
        STA     Scratch26                            ; &15C2: 85 26
        TYA                                          ; &15C4: 98
        ADC     ScoreMid                             ; &15C5: 65 39
        STA     ScoreMid                             ; &15C7: 85 39
        EOR     Scratch26                            ; &15C9: 45 26
        AND     #&20                                 ; &15CB: 29 20
        PHA                                          ; &15CD: 48
        LDA     #&00                                 ; &15CE: A9 00
        ADC     ScoreHi                              ; &15D0: 65 3A
        STA     ScoreHi                              ; &15D2: 85 3A
        CLD                                          ; &15D4: D8
        PLA                                          ; &15D5: 68
        BEQ     L15DA                                ; &15D6: F0 02
        INC     Lives                                ; &15D8: E6 3B
L15DA:
        RTS                                          ; &15DA: 60

; -----------------------------------------------------------------------------
; Runtime &15DB: status display.
; -----------------------------------------------------------------------------
Code_DrawStatus:
        JSR     Routine1565                          ; &15DB: 20 65 15
        LDA     #&1E                                 ; &15DE: A9 1E
        JSR     OSWRCH                               ; &15E0: 20 EE FF
        SEC                                          ; &15E3: 38
        LDA     TimeHiBCD                            ; &15E4: A5 83
        JSR     &162F                                ; &15E6: 20 2F 16
        LDA     #&3A                                 ; &15E9: A9 3A
        JSR     OSWRCH                               ; &15EB: 20 EE FF
        SEC                                          ; &15EE: 38
        LDA     TimeLoBCD                            ; &15EF: A5 82
        JSR     &1624                                ; &15F1: 20 24 16
        LDA     #&09                                 ; &15F4: A9 09
        JSR     OSWRCH                               ; &15F6: 20 EE FF
        SEC                                          ; &15F9: 38
        LDA     Lives                                ; &15FA: A5 3B
        SBC     #&01                                 ; &15FC: E9 01
        SEC                                          ; &15FE: 38
        JSR     &162F                                ; &15FF: 20 2F 16
        LDA     #&09                                 ; &1602: A9 09
        JSR     OSWRCH                               ; &1604: 20 EE FF
        CLC                                          ; &1607: 18
        LDA     ScoreHi                              ; &1608: A5 3A
        JSR     &162F                                ; &160A: 20 2F 16
        LDA     ScoreMid                             ; &160D: A5 39
        JSR     &1624                                ; &160F: 20 24 16
        BCC     L161A                                ; &1612: 90 06
        LDA     #&2C                                 ; &1614: A9 2C
        JSR     OSWRCH                               ; &1616: 20 EE FF
        SEC                                          ; &1619: 38
L161A:
        LDA     ScoreLo                              ; &161A: A5 38
        JSR     &1624                                ; &161C: 20 24 16
        LDA     #&30                                 ; &161F: A9 30
        JMP     OSWRCH                               ; &1621: 4C EE FF
        PHA                                          ; &1624: 48
        PHP                                          ; &1625: 08
        LSR     A                                    ; &1626: 4A
        LSR     A                                    ; &1627: 4A
        LSR     A                                    ; &1628: 4A
        LSR     A                                    ; &1629: 4A
        PLP                                          ; &162A: 28
        JSR     &162F                                ; &162B: 20 2F 16
        PLA                                          ; &162E: 68
        AND     #&0F                                 ; &162F: 29 0F
        BNE     L1635                                ; &1631: D0 02
        BCC     L163B                                ; &1633: 90 06
L1635:
        ORA     #&30                                 ; &1635: 09 30
        JSR     OSWRCH                               ; &1637: 20 EE FF
        SEC                                          ; &163A: 38
L163B:
        RTS                                          ; &163B: 60

; -----------------------------------------------------------------------------
; Runtime &163C: Routine163C.
; -----------------------------------------------------------------------------
Code_Routine163C:
        TAY                                          ; &163C: A8
L163D:
        JSR     TimerAndKeys                         ; &163D: 20 2C 0C
        BEQ     L1646                                ; &1640: F0 04
        BIT     InputMode                            ; &1642: 24 86
        BPL     L164C                                ; &1644: 10 06
L1646:
        JSR     WaitForTickChange                    ; &1646: 20 01 0D
        DEY                                          ; &1649: 88
        BNE     L163D                                ; &164A: D0 F1
L164C:
        RTS                                          ; &164C: 60

; -----------------------------------------------------------------------------
; Runtime &164D: high-score insertion.
; -----------------------------------------------------------------------------
Code_HighScoreInsert:
        TSX                                          ; &164D: BA
        STX     &7E                                  ; &164E: 86 7E
        LDA     #&06                                 ; &1650: A9 06
        STA     RelocDestHi                          ; &1652: 85 42
        LDY     #&FF                                 ; &1654: A0 FF
        LDX     #&1E                                 ; &1656: A2 1E
L1658:
        LDA     ScoreLo                              ; &1658: A5 38
        CMP     &0885,X                              ; &165A: DD 85 08
        LDA     ScoreMid                             ; &165D: A5 39
        SBC     &0884,X                              ; &165F: FD 84 08
        LDA     ScoreHi                              ; &1662: A5 3A
        SBC     &0883,X                              ; &1664: FD 83 08
        BCC     L1672                                ; &1667: 90 09
        DEC     RelocDestHi                          ; &1669: C6 42
        TXA                                          ; &166B: 8A
        TAY                                          ; &166C: A8
        SBC     #&06                                 ; &166D: E9 06
        TAX                                          ; &166F: AA
        BPL     L1658                                ; &1670: 10 E6
L1672:
        TYA                                          ; &1672: 98
        BMI     L164C                                ; &1673: 30 D7
        STY     Scratch26                            ; &1675: 84 26
        LDX     #&23                                 ; &1677: A2 23
L1679:
        LDA     &087A,X                              ; &1679: BD 7A 08
        STA     HighScores,X                         ; &167C: 9D 80 08
        DEX                                          ; &167F: CA
        CPX     Scratch26                            ; &1680: E4 26
        BPL     L1679                                ; &1682: 10 F5
        LDA     ScoreLo                              ; &1684: A5 38
        STA     &0885,Y                              ; &1686: 99 85 08
        LDA     ScoreMid                             ; &1689: A5 39
        STA     &0884,Y                              ; &168B: 99 84 08
        LDA     ScoreHi                              ; &168E: A5 3A
        STA     &0883,Y                              ; &1690: 99 83 08
        LDA     #&20                                 ; &1693: A9 20
        STA     HighScores,Y                         ; &1695: 99 80 08
        STA     &0881,Y                              ; &1698: 99 81 08
        STA     &0882,Y                              ; &169B: 99 82 08
        STY     RelocSourceLo                        ; &169E: 84 3F
        LDA     &0C                                  ; &16A0: A5 0C
        STA     &0350                                ; &16A2: 8D 50 03
        LDA     &0D                                  ; &16A5: A5 0D
        STA     &0351                                ; &16A7: 8D 51 03
        JSR     &19DA                                ; &16AA: 20 DA 19
        JSR     PrintInlineStream                    ; &16AD: 20 21 0D
        EQUB &11,&82,&1F,&09,&11,&3C,&2D,&2B,&2D,&3E,&20,&74,&6F,&20,&73,&65    ; runtime &16B0
        EQUB &6C,&65,&63,&74,&20,&6C,&65,&74,&74,&65,&72,&1F,&09,&13,&27,&4A    ; runtime &16C0
        EQUB &75,&6D,&70,&27,&20,&74,&6F,&20,&65,&6E,&74,&65,&72,&20,&6C,&65    ; runtime &16D0
        EQUB &74,&74,&65,&72,&EA    ; runtime &16E0
        JSR     &1583                                ; &16E5: 20 83 15
        LDY     RelocDestHi                          ; &16E8: A4 42
        JSR     &1AB3                                ; &16EA: 20 B3 1A
        LDA     #&03                                 ; &16ED: A9 03
        STA     RelocDestHi                          ; &16EF: 85 42
        LDA     #&41                                 ; &16F1: A9 41
        STA     RelocDestLo                          ; &16F3: 85 41
        LDA     RelocDestLo                          ; &16F5: A5 41
        JSR     OSWRCH                               ; &16F7: 20 EE FF
        LDA     #&08                                 ; &16FA: A9 08
        JSR     OSWRCH                               ; &16FC: 20 EE FF
        JSR     TimerAndKeys                         ; &16FF: 20 2C 0C
        BNE     L175A                                ; &1702: D0 56
        LDA     InputState                           ; &1704: A5 87
        STA     InputMode                            ; &1706: 85 86
        LDX     RelocDestLo                          ; &1708: A6 41
        JSR     ReadHorizontal                       ; &170A: 20 F9 12
        CPX     RelocDestLo                          ; &170D: E4 41
        BEQ     L172A                                ; &170F: F0 19
        CPX     #&7F                                 ; &1711: E0 7F
        BCC     L1719                                ; &1713: 90 04
        LDX     #&20                                 ; &1715: A2 20
        BCS     L171F                                ; &1717: B0 06
L1719:
        CPX     #&20                                 ; &1719: E0 20
        BCS     L171F                                ; &171B: B0 02
        LDX     #&7E                                 ; &171D: A2 7E
L171F:
        TXA                                          ; &171F: 8A
        STA     RelocDestLo                          ; &1720: 85 41
        JSR     OSWRCH                               ; &1722: 20 EE FF
        LDA     #&08                                 ; &1725: A9 08
        JSR     OSWRCH                               ; &1727: 20 EE FF
L172A:
        LDY     #&FF                                 ; &172A: A0 FF
        JSR     ReadVertical                         ; &172C: 20 1D 13
        TYA                                          ; &172F: 98
        BMI     L174A                                ; &1730: 30 18
        LDY     RelocSourceLo                        ; &1732: A4 3F
        LDA     RelocDestLo                          ; &1734: A5 41
        STA     HighScores,Y                         ; &1736: 99 80 08
        JSR     OSWRCH                               ; &1739: 20 EE FF
        INC     RelocSourceLo                        ; &173C: E6 3F
        DEC     RelocDestHi                          ; &173E: C6 42
        BEQ     L1752                                ; &1740: F0 10
        LDA     #&14                                 ; &1742: A9 14
        JSR     &1AC7                                ; &1744: 20 C7 1A
        JMP     &16F5                                ; &1747: 4C F5 16
L174A:
        LDA     #&05                                 ; &174A: A9 05
        JSR     &1AC7                                ; &174C: 20 C7 1A
        JMP     &16FF                                ; &174F: 4C FF 16
L1752:
        JSR     &1574                                ; &1752: 20 74 15
        LDA     #&50                                 ; &1755: A9 50
        JSR     &1AC7                                ; &1757: 20 C7 1A
L175A:
        CLC                                          ; &175A: 18
        RTS                                          ; &175B: 60
        EQUB &00,&34,&FF,&12,&4A,&4B,&4C,&4D,&FF,&0F,&15,&3E,&3F,&40,&41,&42    ; runtime &175C
        EQUB &43,&FF,&0C,&1D,&FF,&09,&17,&23,&16,&FF,&FF,&00,&34,&FF,&0F,&44    ; runtime &176C
        EQUB &45,&46,&47,&48,&49,&FF,&12,&00,&54,&55,&56,&FF,&0C,&00,&1E,&FF    ; runtime &177C
        EQUB &09,&17,&23,&16,&FF,&FF,&00,&34,&FF,&0C,&12,&FF,&09,&17,&23,&16    ; runtime &178C
        EQUB &FF,&12,&24,&57,&58,&59,&5A,&FF,&0F,&11,&4E,&4F,&50,&51,&52,&53    ; runtime &179C
        EQUB &FF,&FF,&47,&5C,&17,&43,&92,&17,&4A,&77,&17,&FF    ; runtime &17AC

; -----------------------------------------------------------------------------
; Runtime &17B8: level stream decoder.
; -----------------------------------------------------------------------------
Code_LoadLevelStream:
        LDX     #&00                                 ; &17B8: A2 00
        LDA     (LevelStreamLo,X)                    ; &17BA: A1 6D
        STA     Scratch26                            ; &17BC: 85 26
L17BE:
        LDA     &17AE,X                              ; &17BE: BD AE 17
        BMI     L17F2                                ; &17C1: 30 2F
        CMP     Scratch26                            ; &17C3: C5 26
        BEQ     L17CC                                ; &17C5: F0 05
        INX                                          ; &17C7: E8
        INX                                          ; &17C8: E8
        INX                                          ; &17C9: E8
        BNE     L17BE                                ; &17CA: D0 F2
L17CC:
        LDA     &17AF,X                              ; &17CC: BD AF 17
        STA     &6B                                  ; &17CF: 85 6B
        LDA     &17B0,X                              ; &17D1: BD B0 17
        STA     &6C                                  ; &17D4: 85 6C
        INC     LevelStreamLo                        ; &17D6: E6 6D
        BNE     L17DC                                ; &17D8: D0 02
        INC     LevelStreamHi                        ; &17DA: E6 6E
L17DC:
        LDX     #&00                                 ; &17DC: A2 00
        LDY     #&00                                 ; &17DE: A0 00
        LDA     (LevelStreamLo,X)                    ; &17E0: A1 6D
        BMI     L17F7                                ; &17E2: 30 13
L17E4:
        LDA     &0B02,Y                              ; &17E4: B9 02 0B
        BEQ     L17F2                                ; &17E7: F0 09
        CMP     (LevelStreamLo,X)                    ; &17E9: C1 6D
        BEQ     L1800                                ; &17EB: F0 13
        INY                                          ; &17ED: C8
        INY                                          ; &17EE: C8
        INY                                          ; &17EF: C8
        BNE     L17E4                                ; &17F0: D0 F2
L17F2:
        LDA     #&07                                 ; &17F2: A9 07
        JSR     OSWRCH                               ; &17F4: 20 EE FF
L17F7:
        RTS                                          ; &17F7: 60
L17F8:
        INC     LevelStreamLo                        ; &17F8: E6 6D
        BNE     L17DC                                ; &17FA: D0 E0
        INC     LevelStreamHi                        ; &17FC: E6 6E
        BNE     L17DC                                ; &17FE: D0 DC
L1800:
        STY     &5C                                  ; &1800: 84 5C
        LDA     &0B03,Y                              ; &1802: B9 03 0B
        STA     RelocSourceHi                        ; &1805: 85 40
        LDX     QueueDescriptors,Y                   ; &1807: BE 00 0B
        LDY     #&00                                 ; &180A: A0 00
        INC     LevelStreamLo                        ; &180C: E6 6D
        BNE     L1812                                ; &180E: D0 02
        INC     LevelStreamHi                        ; &1810: E6 6E
L1812:
        LDA     (&6B),Y                              ; &1812: B1 6B
        BMI     L17F2                                ; &1814: 30 DC
        CMP     &5C                                  ; &1816: C5 5C
        BEQ     L1822                                ; &1818: F0 08
L181A:
        INY                                          ; &181A: C8
        LDA     (&6B),Y                              ; &181B: B1 6B
        BPL     L181A                                ; &181D: 10 FB
        INY                                          ; &181F: C8
        BNE     L1812                                ; &1820: D0 F0
L1822:
        STY     RelocSourceLo                        ; &1822: 84 3F
L1824:
        LDY     #&00                                 ; &1824: A0 00
        SEC                                          ; &1826: 38
        LDA     (LevelStreamLo),Y                    ; &1827: B1 6D
        PHA                                          ; &1829: 48
        AND     #&07                                 ; &182A: 29 07
        ADC     RelocSourceLo                        ; &182C: 65 3F
        TAY                                          ; &182E: A8
        LDA     (&6B),Y                              ; &182F: B1 6B
        STA     &35                                  ; &1831: 85 35
        PLA                                          ; &1833: 68
        LSR     A                                    ; &1834: 4A
        LSR     A                                    ; &1835: 4A
        LSR     A                                    ; &1836: 4A
        BEQ     L17F8                                ; &1837: F0 BF
        STA     Scratch26                            ; &1839: 85 26
        LDY     #&00                                 ; &183B: A0 00
        DEX                                          ; &183D: CA
L183E:
        INX                                          ; &183E: E8
        CPX     RelocSourceHi                        ; &183F: E4 40
        BCS     L17F2                                ; &1841: B0 AF
        LDA     ObjectSprite,X                       ; &1843: BD 5E 04
        CMP     #&FF                                 ; &1846: C9 FF
        BNE     L183E                                ; &1848: D0 F4
        INY                                          ; &184A: C8
        LDA     (LevelStreamLo),Y                    ; &184B: B1 6D
        STA     ObjectX,X                            ; &184D: 9D 68 03
        INY                                          ; &1850: C8
        LDA     (LevelStreamLo),Y                    ; &1851: B1 6D
        STA     ObjectY,X                            ; &1853: 9D E3 03
        LDA     &35                                  ; &1856: A5 35
        STA     ObjectSprite,X                       ; &1858: 9D 5E 04
        DEC     Scratch26                            ; &185B: C6 26
        BNE     L183E                                ; &185D: D0 DF
        SEC                                          ; &185F: 38
        TYA                                          ; &1860: 98
        ADC     LevelStreamLo                        ; &1861: 65 6D
        STA     LevelStreamLo                        ; &1863: 85 6D
        BCC     L1824                                ; &1865: 90 BD
        INC     LevelStreamHi                        ; &1867: E6 6E
        BCS     L1824                                ; &1869: B0 B9

; -----------------------------------------------------------------------------
; Runtime &186B: music/sound stream step.
; -----------------------------------------------------------------------------
Code_MusicStep:
        LDA     GameState2F                          ; &186B: A5 2F
        ORA     OSCallGate                           ; &186D: 05 93
        BMI     L18A8                                ; &186F: 30 37
        BIT     MusicCountdown                       ; &1871: 24 91
        BPL     L18A8                                ; &1873: 10 33
        TXA                                          ; &1875: 8A
        PHA                                          ; &1876: 48
        TYA                                          ; &1877: 98
        PHA                                          ; &1878: 48
        LDY     &90                                  ; &1879: A4 90
        LDX     SoundStream,Y                        ; &187B: BE 07 05
        INY                                          ; &187E: C8
        TXA                                          ; &187F: 8A
        AND     #&7C                                 ; &1880: 29 7C
        STA     &01A8                                ; &1882: 8D A8 01
        TXA                                          ; &1885: 8A
        BPL     L1892                                ; &1886: 10 0A
        LDX     &8A                                  ; &1888: A6 8A
        LDY     &00,X                                ; &188A: B4 00
        CPX     #&8E                                 ; &188C: E0 8E
        BCC     L1892                                ; &188E: 90 02
        DEC     GameState2F                          ; &1890: C6 2F
L1892:
        AND     #&03                                 ; &1892: 29 03
        SEC                                          ; &1894: 38
        ADC     #&00                                 ; &1895: 69 00
        ASL     A                                    ; &1897: 0A
        ASL     A                                    ; &1898: 0A
        ADC     MusicCountdown                       ; &1899: 65 91
        STA     MusicCountdown                       ; &189B: 85 91
        STY     &90                                  ; &189D: 84 90
        LDX     #&A4                                 ; &189F: A2 A4
        JSR     SoundOSWORD7                         ; &18A1: 20 A9 18
        PLA                                          ; &18A4: 68
        TAY                                          ; &18A5: A8
        PLA                                          ; &18A6: 68
        TAX                                          ; &18A7: AA
L18A8:
        RTS                                          ; &18A8: 60

; -----------------------------------------------------------------------------
; Runtime &18A9: SoundOSWORD7.
; -----------------------------------------------------------------------------
Code_SoundOSWORD7:
        LDY     #&01                                 ; &18A9: A0 01
        BIT     SoundEnabled                         ; &18AB: 24 4B
        BMI     L18A8                                ; &18AD: 30 F9
        LDA     #&07                                 ; &18AF: A9 07
        JMP     OSWORDWrapper                        ; &18B1: 4C 03 0E

; -----------------------------------------------------------------------------
; Runtime &18B4: select tune/effect.
; -----------------------------------------------------------------------------
Code_SelectTune:
        TAX                                          ; &18B4: AA
        STX     &8A                                  ; &18B5: 86 8A
        LDA     &00,X                                ; &18B7: B5 00
        STA     &90                                  ; &18B9: 85 90
        LDX     #&A8                                 ; &18BB: A2 A8
        LDY     #&61                                 ; &18BD: A0 61
        STY     &FE65                                ; &18BF: 8C 65 FE
        STX     USER_VIA_T1CL                        ; &18C2: 8E 64 FE
        LDA     #&00                                 ; &18C5: A9 00
        STA     MusicCountdown                       ; &18C7: 85 91
        STA     GameState2F                          ; &18C9: 85 2F
        RTS                                          ; &18CB: 60

; -----------------------------------------------------------------------------
; Runtime &18CC: screen-complete transition.
; -----------------------------------------------------------------------------
Code_ScreenComplete:
        LDA     #&8F                                 ; &18CC: A9 8F
        JSR     SelectTune                           ; &18CE: 20 B4 18
        JSR     ResetCountdownDivider                ; &18D1: 20 27 0C
        STA     SoundIrqGate                         ; &18D4: 85 70
        LDX     BaseScreen                           ; &18D6: A6 3C
        LDY     TransformCycle                       ; &18D8: A4 3D
        JSR     &14D1                                ; &18DA: 20 D1 14
        JSR     &1B1F                                ; &18DD: 20 1F 1B
        LDA     #&FF                                 ; &18E0: A9 FF
        STA     SoundIrqGate                         ; &18E2: 85 70
        LDA     #&01                                 ; &18E4: A9 01
        STA     ObjectDY                             ; &18E6: 8D F0 04
        LDA     #&3C                                 ; &18E9: A9 3C
        STA     TYPE_TROGG_0                         ; &18EB: 85 34
        LDX     #&01                                 ; &18ED: A2 01
        STX     ObjectDX                             ; &18EF: 8E D9 04
        DEX                                          ; &18F2: CA
        JSR     ObjectMode00                         ; &18F3: 20 20 0B
        SEC                                          ; &18F6: 38
        BCS     L1922                                ; &18F7: B0 29
        LDA     #&50                                 ; &18F9: A9 50
        PHA                                          ; &18FB: 48
        LDY     #&FF                                 ; &18FC: A0 FF
        LDA     #&06                                 ; &18FE: A9 06
        LDX     #&01                                 ; &1900: A2 01
        BNE     L190D                                ; &1902: D0 09
        LDA     #&00                                 ; &1904: A9 00
        PHA                                          ; &1906: 48
        LDY     #&01                                 ; &1907: A0 01
        LDA     #&01                                 ; &1909: A9 01
        LDX     #&00                                 ; &190B: A2 00
L190D:
        STA     ObjectDY,X                           ; &190D: 9D F0 04
        TYA                                          ; &1910: 98
        STA     ObjectDX,X                           ; &1911: 9D D9 04
        PLA                                          ; &1914: 68
        STA     ObjectX,X                            ; &1915: 9D 68 03
        LDA     #&1F                                 ; &1918: A9 1F
        STA     TYPE_TROGG_0                         ; &191A: 85 34
        LDA     #&52                                 ; &191C: A9 52
        STA     ObjectY,X                            ; &191E: 9D E3 03
        CLC                                          ; &1921: 18
L1922:
        PHP                                          ; &1922: 08
L1923:
        LDA     #&04                                 ; &1923: A9 04
        JSR     Routine163C                          ; &1925: 20 3C 16
        PLP                                          ; &1928: 28
        PHP                                          ; &1929: 08
        BCS     L192F                                ; &192A: B0 03
        JSR     &1AD7                                ; &192C: 20 D7 1A
L192F:
        JSR     WaitForObjectRaster                  ; &192F: 20 08 0D
        JSR     ObjectMode80                         ; &1932: 20 1C 0B
        CLC                                          ; &1935: 18
        LDA     ObjectX,X                            ; &1936: BD 68 03
        ADC     ObjectDX,X                           ; &1939: 7D D9 04
        STA     ObjectX,X                            ; &193C: 9D 68 03
        LDY     ObjectDY,X                           ; &193F: BC F0 04
L1942:
        INY                                          ; &1942: C8
        LDA     &1960,Y                              ; &1943: B9 60 19
        BPL     L1950                                ; &1946: 10 08
L1948:
        DEY                                          ; &1948: 88
        LDA     &1960,Y                              ; &1949: B9 60 19
        BPL     L1948                                ; &194C: 10 FA
        BMI     L1942                                ; &194E: 30 F2
L1950:
        STA     ObjectSprite,X                       ; &1950: 9D 5E 04
        TYA                                          ; &1953: 98
        STA     ObjectDY,X                           ; &1954: 9D F0 04
        JSR     ObjectMode00                         ; &1957: 20 20 0B
        DEC     TYPE_TROGG_0                         ; &195A: C6 34
        BNE     L1923                                ; &195C: D0 C5
        PLP                                          ; &195E: 28
        RTS                                          ; &195F: 60
        EQUB &FF,&34,&35,&36,&37,&FF,&12,&FF,&06,&02,&01,&D4,&89,&3C,&05,&06    ; runtime &1960
        EQUB &07,&02,&03,&04,&8B,&8C,&8D    ; runtime &1970

; -----------------------------------------------------------------------------
; Runtime &1977: title/start sequence.
; -----------------------------------------------------------------------------
Code_TitleStartSequence:
        TSX                                          ; &1977: BA
        STX     &7E                                  ; &1978: 86 7E
        LDX     #&01                                 ; &197A: A2 01
        LDY     #&00                                 ; &197C: A0 00
        JSR     DisplayInit                          ; &197E: 20 CD 14
        LDA     #&03                                 ; &1981: A9 03
        JSR     RandomBelowA                         ; &1983: 20 B6 0D
        TAY                                          ; &1986: A8
        LDA     &1B1B,Y                              ; &1987: B9 1B 1B
        STA     &7C                                  ; &198A: 85 7C
        LDA     #&7D                                 ; &198C: A9 7D
        STA     &7D                                  ; &198E: 85 7D
L1990:
        LDA     #&50                                 ; &1990: A9 50
        JSR     RandomBelowA                         ; &1992: 20 B6 0D
        TAX                                          ; &1995: AA
        JSR     WaitForTickChange                    ; &1996: 20 01 0D
        LDA     #&FF                                 ; &1999: A9 FF
        JSR     RandomBelowA                         ; &199B: 20 B6 0D
        TAY                                          ; &199E: A8
        LDA     &7C                                  ; &199F: A5 7C
        JSR     DrawSpriteAt                         ; &19A1: 20 32 0B
        JSR     &1AD7                                ; &19A4: 20 D7 1A
        DEC     &7D                                  ; &19A7: C6 7D
        BNE     L1990                                ; &19A9: D0 E5
        JSR     &19DA                                ; &19AB: 20 DA 19
        LDA     #&1A                                 ; &19AE: A9 1A
        JSR     OSWRCH                               ; &19B0: 20 EE FF
        JSR     &1574                                ; &19B3: 20 74 15
        LDA     #&0C                                 ; &19B6: A9 0C
        STA     &0E                                  ; &19B8: 85 0E
        LDA     #&44                                 ; &19BA: A9 44
        STA     &0F                                  ; &19BC: 85 0F
        JSR     &1904                                ; &19BE: 20 04 19
        JSR     &18F9                                ; &19C1: 20 F9 18
        LDA     #&4B                                 ; &19C4: A9 4B
        JSR     Routine163C                          ; &19C6: 20 3C 16
        LDA     #&5B                                 ; &19C9: A9 5B
        LDX     ObjectX                              ; &19CB: AE 68 03
        LDY     #&52                                 ; &19CE: A0 52
        JSR     DrawSpriteAt                         ; &19D0: 20 32 0B
        LDA     #&FA                                 ; &19D3: A9 FA
        JSR     &1AC7                                ; &19D5: 20 C7 1A
        CLC                                          ; &19D8: 18
        RTS                                          ; &19D9: 60
        JSR     PrintInlineStream                    ; &19DA: 20 21 0D
        EQUB &11,&80,&1C,&06,&16,&21,&08,&19,&04,&BF,&00,&1F,&01,&19,&01,&81    ; runtime &19DD
        EQUB &03,&00,&00,&19,&01,&00,&00,&E1,&01,&19,&01,&7F,&FC,&00,&00,&19    ; runtime &19ED
        EQUB &01,&00,&00,&1F,&FE,&0C,&1F,&07,&00,&47,&72,&61,&6E,&64,&6D,&61    ; runtime &19FD
        EQUB &73,&74,&65,&72,&20,&46,&72,&61,&6B,&2E,&2E,&2E,&1F,&02,&02,&2E    ; runtime &1A0D
        EQUB &2E,&2E,&61,&6E,&64,&20,&74,&68,&65,&20,&46,&75,&72,&69,&6F,&75    ; runtime &1A1D
        EQUB &73,&20,&46,&69,&76,&65,&1F,&01,&0E,&28,&43,&29,&20,&41,&61,&72    ; runtime &1A2D
        EQUB &64,&76,&61,&72,&6B,&20,&53,&6F,&66,&74,&77,&61,&72,&65,&20,&31    ; runtime &1A3D
        EQUB &39,&38,&34,&1A,&EA    ; runtime &1A4D

; -----------------------------------------------------------------------------
; Runtime &1A52: high-score display.
; -----------------------------------------------------------------------------
Code_ShowHighScores:
        LDX     #&00                                 ; &1A52: A2 00
        STX     &60                                  ; &1A54: 86 60
L1A56:
        LDY     &60                                  ; &1A56: A4 60
        JSR     &1AB3                                ; &1A58: 20 B3 1A
        LDY     #&03                                 ; &1A5B: A0 03
L1A5D:
        LDA     HighScores,X                         ; &1A5D: BD 80 08
        JSR     OSWRCH                               ; &1A60: 20 EE FF
        INX                                          ; &1A63: E8
        DEY                                          ; &1A64: 88
        BNE     L1A5D                                ; &1A65: D0 F6
        LDA     #&20                                 ; &1A67: A9 20
        JSR     OSWRCH                               ; &1A69: 20 EE FF
        LDY     #&03                                 ; &1A6C: A0 03
        CLC                                          ; &1A6E: 18
L1A6F:
        LDA     HighScores,X                         ; &1A6F: BD 80 08
        STA.ABS &00FF,Y                              ; &1A72: 99 FF 00
        STA     &0102,Y                              ; &1A75: 99 02 01
        JSR     &1624                                ; &1A78: 20 24 16
        INX                                          ; &1A7B: E8
        DEY                                          ; &1A7C: 88
        BNE     L1A6F                                ; &1A7D: D0 F0
        LDA     #&30                                 ; &1A7F: A9 30
        JSR     OSWRCH                               ; &1A81: 20 EE FF
        LDY     &60                                  ; &1A84: A4 60
        JSR     &1AB3                                ; &1A86: 20 B3 1A
        LDA     #&09                                 ; &1A89: A9 09
        LDY     #&0B                                 ; &1A8B: A0 0B
L1A8D:
        JSR     OSWRCH                               ; &1A8D: 20 EE FF
        DEY                                          ; &1A90: 88
        BNE     L1A8D                                ; &1A91: D0 FA
        JSR     PrintInlineStream                    ; &1A93: 20 21 0D
        EQUB &28,&EA    ; runtime &1A96
        LDA     #&63                                 ; &1A98: A9 63
        JSR     &1AF9                                ; &1A9A: 20 F9 1A
        LDA     #&2A                                 ; &1A9D: A9 2A
        JSR     &1AF9                                ; &1A9F: 20 F9 1A
        LDA     #&F7                                 ; &1AA2: A9 F7
        JSR     &1AF9                                ; &1AA4: 20 F9 1A
        JSR     PrintInlineStream                    ; &1AA7: 20 21 0D
        EQUB &29,&EA    ; runtime &1AAA
        INC     &60                                  ; &1AAC: E6 60
        CPX     #&24                                 ; &1AAE: E0 24
        BCC     L1A56                                ; &1AB0: 90 A4
        RTS                                          ; &1AB2: 60
        LDA     &1AC1,Y                              ; &1AB3: B9 C1 1A
        PHA                                          ; &1AB6: 48
        JSR     PrintInlineStream                    ; &1AB7: 20 21 0D
        EQUB &1F,&11,&EA    ; runtime &1ABA
        PLA                                          ; &1ABD: 68
        JMP     OSWRCH                               ; &1ABE: 4C EE FF
        EQUB &09,&0B,&0C,&0D,&0E,&0F    ; runtime &1AC1
        TAY                                          ; &1AC7: A8
L1AC8:
        JSR     TimerAndKeys                         ; &1AC8: 20 2C 0C
        BNE     L1AD6                                ; &1ACB: D0 09
        JSR     WaitForTickChange                    ; &1ACD: 20 01 0D
        JSR     &1AD7                                ; &1AD0: 20 D7 1A
        DEY                                          ; &1AD3: 88
        BNE     L1AC8                                ; &1AD4: D0 F2
L1AD6:
        RTS                                          ; &1AD6: 60
        LDA     InputState                           ; &1AD7: A5 87
        STA     InputMode                            ; &1AD9: 85 86
        LDA     #&9D                                 ; &1ADB: A9 9D
        JSR     Inkey                                ; &1ADD: 20 9C 0D
        BNE     L1AF4                                ; &1AE0: D0 12
        LDA     #&01                                 ; &1AE2: A9 01
        STA     InputMode                            ; &1AE4: 85 86
L1AE6:
        JSR     ReadYoyo                             ; &1AE6: 20 59 13
        BNE     L1AF0                                ; &1AE9: D0 05
        DEC     InputMode                            ; &1AEB: C6 86
        BPL     L1AE6                                ; &1AED: 10 F7
        RTS                                          ; &1AEF: 60
L1AF0:
        LDA     InputMode                            ; &1AF0: A5 86
        STA     InputState                           ; &1AF2: 85 87
L1AF4:
        LDX     &7E                                  ; &1AF4: A6 7E
        TXS                                          ; &1AF6: 9A
        SEC                                          ; &1AF7: 38
        RTS                                          ; &1AF8: 60
        STA     InlinePtrLo                          ; &1AF9: 85 29
        LSR     A                                    ; &1AFB: 4A
        LDA     &0100,Y                              ; &1AFC: B9 00 01
        ADC     &0101,Y                              ; &1AFF: 79 01 01
        SBC     &0102,Y                              ; &1B02: F9 02 01
        EOR     InlinePtrLo                          ; &1B05: 45 29
L1B07:
        CMP     #&24                                 ; &1B07: C9 24
        BCC     L1B0F                                ; &1B09: 90 04
        SBC     #&24                                 ; &1B0B: E9 24
        BCS     L1B07                                ; &1B0D: B0 F8
L1B0F:
        STY     InlinePtrLo                          ; &1B0F: 84 29
        TAY                                          ; &1B11: A8
        LDA     &1B5A,Y                              ; &1B12: B9 5A 1B
        LDY     InlinePtrLo                          ; &1B15: A4 29
        INY                                          ; &1B17: C8
        JMP     OSWRCH                               ; &1B18: 4C EE FF
        EQUB &22,&34,&12,&1D    ; runtime &1B1B
        JSR     PrintInlineStream                    ; &1B1F: 20 21 0D
        EQUB &1C,&0B,&12,&1C,&0E,&19,&04,&5F,&01,&9F,&01,&19,&01,&41,&02,&00    ; runtime &1B22
        EQUB &00,&19,&01,&00,&00,&A1,&00,&19,&01,&BF,&FD,&00,&00,&19,&01,&00    ; runtime &1B32
        EQUB &00,&5F,&FF,&0C,&1F,&02,&02,&57,&65,&27,&76,&65,&20,&64,&6F,&6E    ; runtime &1B42
        EQUB &65,&20,&69,&74,&21,&1A,&EA    ; runtime &1B52
        RTS                                          ; &1B59: 60
        EQUB &38,&34,&42,&51,&52,&4A,&46,&49,&5A,&4D,&41,&58,&47,&43,&53,&32    ; runtime &1B5A
        EQUB &36,&4E,&31,&4C,&45,&4F,&4B,&57,&37,&35,&33,&30,&48,&59,&50,&55    ; runtime &1B6A
        EQUB &54,&39,&56,&44    ; runtime &1B7A

; -----------------------------------------------------------------------------
; Runtime &1B7E: Routine1B7E.
; -----------------------------------------------------------------------------
Code_Routine1B7E:
        STA     Scratch26                            ; &1B7E: 85 26
        LDX     #&00                                 ; &1B80: A2 00
        STX     &60                                  ; &1B82: 86 60
        LDX     QueueDescriptors,Y                   ; &1B84: BE 00 0B
L1B87:
        LDA     ObjectSprite,X                       ; &1B87: BD 5E 04
        CMP     Scratch26                            ; &1B8A: C5 26
        BNE     L1B90                                ; &1B8C: D0 02
        INC     &60                                  ; &1B8E: E6 60
L1B90:
        INX                                          ; &1B90: E8
        TXA                                          ; &1B91: 8A
        CMP     &0B03,Y                              ; &1B92: D9 03 0B
        BCC     L1B87                                ; &1B95: 90 F0
        LDA     Scratch26                            ; &1B97: A5 26
        LDX     &60                                  ; &1B99: A6 60
        RTS                                          ; &1B9B: 60
L1B9C:
        PLA                                          ; &1B9C: 68
        PLA                                          ; &1B9D: 68
        PLA                                          ; &1B9E: 68
        JMP     &1BFA                                ; &1B9F: 4C FA 1B

; -----------------------------------------------------------------------------
; Runtime &1BA2: dagger/balloon hazard spawner.
; -----------------------------------------------------------------------------
Code_SpawnHazard:
        LDY     #&06                                 ; &1BA2: A0 06
        JSR     &1BFB                                ; &1BA4: 20 FB 1B
        LDY     #&03                                 ; &1BA7: A0 03
        JSR     &1BFB                                ; &1BA9: 20 FB 1B
        DEC     HazardCounter                        ; &1BAC: C6 88
        BNE     L1BFA                                ; &1BAE: D0 4A
        LDA     HazardReload                         ; &1BB0: A5 89
        STA     HazardCounter                        ; &1BB2: 85 88
        LDA     #&03                                 ; &1BB4: A9 03
        JSR     RandomBelowA                         ; &1BB6: 20 B6 0D
        TAY                                          ; &1BB9: A8
        BEQ     L1BCE                                ; &1BBA: F0 12
        LDA     #&08                                 ; &1BBC: A9 08
        PHA                                          ; &1BBE: 48
        LDY     #&06                                 ; &1BBF: A0 06
        LDA     #&50                                 ; &1BC1: A9 50
        JSR     RandomBelowA                         ; &1BC3: 20 B6 0D
        CLC                                          ; &1BC6: 18
        ADC     &10                                  ; &1BC7: 65 10
        PHA                                          ; &1BC9: 48
        LDA     #&27                                 ; &1BCA: A9 27
        BNE     L1BE0                                ; &1BCC: D0 12
L1BCE:
        LDA     #&FA                                 ; &1BCE: A9 FA
        PHA                                          ; &1BD0: 48
        LDY     #&03                                 ; &1BD1: A0 03
        LDA     #&28                                 ; &1BD3: A9 28
        JSR     RandomBelowA                         ; &1BD5: 20 B6 0D
        CLC                                          ; &1BD8: 18
        ADC     &10                                  ; &1BD9: 65 10
        ADC     #&32                                 ; &1BDB: 69 32
        PHA                                          ; &1BDD: 48
        LDA     #&25                                 ; &1BDE: A9 25
L1BE0:
        PHA                                          ; &1BE0: 48
        JSR     FindFreeSlot                         ; &1BE1: 20 97 1C
        BCS     L1B9C                                ; &1BE4: B0 B6
        PLA                                          ; &1BE6: 68
        STA     ObjectSprite,X                       ; &1BE7: 9D 5E 04
        PLA                                          ; &1BEA: 68
        STA     ObjectX,X                            ; &1BEB: 9D 68 03
        PLA                                          ; &1BEE: 68
        STA     ObjectY,X                            ; &1BEF: 9D E3 03
        LDA     #&14                                 ; &1BF2: A9 14
        STA     ObjectDX,X                           ; &1BF4: 9D D9 04
        JSR     ObjectMode00                         ; &1BF7: 20 20 0B
L1BFA:
        RTS                                          ; &1BFA: 60
        STY     &5B                                  ; &1BFB: 84 5B
        LDX     QueueDescriptors,Y                   ; &1BFD: BE 00 0B
L1C00:
        JSR     &1C0D                                ; &1C00: 20 0D 1C
        LDY     &5B                                  ; &1C03: A4 5B
        INX                                          ; &1C05: E8
        TXA                                          ; &1C06: 8A
        CMP     &0B03,Y                              ; &1C07: D9 03 0B
        BCC     L1C00                                ; &1C0A: 90 F4
L1C0C:
        RTS                                          ; &1C0C: 60
        JSR     &1C2F                                ; &1C0D: 20 2F 1C
        LDA     &68                                  ; &1C10: A5 68
        CMP     #&FF                                 ; &1C12: C9 FF
        BEQ     L1C0C                                ; &1C14: F0 F6
        LDY     #&09                                 ; &1C16: A0 09
        JSR     TypeDispatch                         ; &1C18: 20 D1 12
        JSR     &1C3F                                ; &1C1B: 20 3F 1C
        BEQ     L1C0C                                ; &1C1E: F0 EC
        JSR     ObjectModeC0                         ; &1C20: 20 23 0B
        JSR     &1C53                                ; &1C23: 20 53 1C
        LDA     &68                                  ; &1C26: A5 68
        CMP     #&FF                                 ; &1C28: C9 FF
        BEQ     L1C0C                                ; &1C2A: F0 E0
        JMP     ObjectMode00                         ; &1C2C: 4C 20 0B
        LDA     ObjectSprite,X                       ; &1C2F: BD 5E 04
        STA     &68                                  ; &1C32: 85 68
        LDA     ObjectX,X                            ; &1C34: BD 68 03
        STA     &69                                  ; &1C37: 85 69
        LDA     ObjectY,X                            ; &1C39: BD E3 03
        STA     &6A                                  ; &1C3C: 85 6A
        RTS                                          ; &1C3E: 60
        LDA     ObjectSprite,X                       ; &1C3F: BD 5E 04
        CMP     &68                                  ; &1C42: C5 68
        BNE     L1C52                                ; &1C44: D0 0C
        LDA     ObjectX,X                            ; &1C46: BD 68 03
        CMP     &69                                  ; &1C49: C5 69
        BNE     L1C52                                ; &1C4B: D0 05
        LDA     ObjectY,X                            ; &1C4D: BD E3 03
        CMP     &6A                                  ; &1C50: C5 6A
L1C52:
        RTS                                          ; &1C52: 60
        LDA     &68                                  ; &1C53: A5 68
        STA     ObjectSprite,X                       ; &1C55: 9D 5E 04
        LDA     &69                                  ; &1C58: A5 69
        STA     ObjectX,X                            ; &1C5A: 9D 68 03
        LDA     &6A                                  ; &1C5D: A5 6A
        STA     ObjectY,X                            ; &1C5F: 9D E3 03
        RTS                                          ; &1C62: 60
L1C63:
        LDA     #&FF                                 ; &1C63: A9 FF
        STA     &68                                  ; &1C65: 85 68
        RTS                                          ; &1C67: 60

; -----------------------------------------------------------------------------
; Runtime &1C68: balloon movement.
; -----------------------------------------------------------------------------
Code_BalloonMovement:
        JSR     &1C8C                                ; &1C68: 20 8C 1C
        BNE     L1C8B                                ; &1C6B: D0 1E
        CLC                                          ; &1C6D: 18
        LDA     &6A                                  ; &1C6E: A5 6A
        ADC     #&06                                 ; &1C70: 69 06
        STA     &6A                                  ; &1C72: 85 6A
        CMP     #&F0                                 ; &1C74: C9 F0
        BCS     L1C63                                ; &1C76: B0 EB
        RTS                                          ; &1C78: 60

; -----------------------------------------------------------------------------
; Runtime &1C79: dagger movement.
; -----------------------------------------------------------------------------
Code_DaggerMovement:
        JSR     &1C8C                                ; &1C79: 20 8C 1C
        BNE     L1C8B                                ; &1C7C: D0 0D
        SEC                                          ; &1C7E: 38
        LDA     &6A                                  ; &1C7F: A5 6A
        SBC     #&02                                 ; &1C81: E9 02
        STA     &6A                                  ; &1C83: 85 6A
        CMP     #&14                                 ; &1C85: C9 14
        BCC     L1C63                                ; &1C87: 90 DA
        DEC     &69                                  ; &1C89: C6 69
L1C8B:
        RTS                                          ; &1C8B: 60
        LDY     ObjectDX,X                           ; &1C8C: BC D9 04
        BEQ     L1C96                                ; &1C8F: F0 05
        DEY                                          ; &1C91: 88
        TYA                                          ; &1C92: 98
        STA     ObjectDX,X                           ; &1C93: 9D D9 04
L1C96:
        RTS                                          ; &1C96: 60

; -----------------------------------------------------------------------------
; Runtime &1C97: find free object slot.
; -----------------------------------------------------------------------------
Code_FindFreeSlot:
        LDX     QueueDescriptors,Y                   ; &1C97: BE 00 0B
L1C9A:
        LDA     ObjectSprite,X                       ; &1C9A: BD 5E 04
        CMP     #&FF                                 ; &1C9D: C9 FF
        BEQ     L1CA9                                ; &1C9F: F0 08
        INX                                          ; &1CA1: E8
        TXA                                          ; &1CA2: 8A
        CMP     &0B03,Y                              ; &1CA3: D9 03 0B
        BCC     L1C9A                                ; &1CA6: 90 F2
        RTS                                          ; &1CA8: 60
L1CA9:
        CLC                                          ; &1CA9: 18
        RTS                                          ; &1CAA: 60
        EQUB &98,&1D,&C9,&1D,&1D,&1E    ; runtime &1CAB
        LDA     &50                                  ; &1CB1: A5 50
        PHA                                          ; &1CB3: 48
        LDA     #&02                                 ; &1CB4: A9 02
        JSR     SpriteTraversal                      ; &1CB6: 20 2E 1D
        PLA                                          ; &1CB9: 68
        STA     &50                                  ; &1CBA: 85 50
        RTS                                          ; &1CBC: 60
        STA     &5A                                  ; &1CBD: 85 5A
        STX     SavedObjectIndex                     ; &1CBF: 86 33
        JSR     LoadObject                           ; &1CC1: 20 3C 0B
        JSR     &1D19                                ; &1CC4: 20 19 1D
        LDA     #&00                                 ; &1CC7: A9 00
        JSR     SpriteTraversal                      ; &1CC9: 20 2E 1D
        JMP     &147C                                ; &1CCC: 4C 7C 14

; -----------------------------------------------------------------------------
; Runtime &1CCF: Routine1CCF.
; -----------------------------------------------------------------------------
Code_Routine1CCF:
        STA     &5E                                  ; &1CCF: 85 5E
        TYA                                          ; &1CD1: 98
        PHA                                          ; &1CD2: 48
        JSR     &1D19                                ; &1CD3: 20 19 1D
        LDA     #&04                                 ; &1CD6: A9 04
        JSR     SpriteTraversal                      ; &1CD8: 20 2E 1D
        PLA                                          ; &1CDB: 68
        TAY                                          ; &1CDC: A8
        BIT     &5E                                  ; &1CDD: 24 5E
        BVC     L1D18                                ; &1CDF: 50 37
        LDA     &6F                                  ; &1CE1: A5 6F
        BEQ     L1D18                                ; &1CE3: F0 33
        LDA     #&FF                                 ; &1CE5: A9 FF
        STA     &5F                                  ; &1CE7: 85 5F
        STA     &5A                                  ; &1CE9: 85 5A
        LDA     &0E                                  ; &1CEB: A5 0E
        PHA                                          ; &1CED: 48
        SEC                                          ; &1CEE: 38
        LDA     &75                                  ; &1CEF: A5 75
        SBC     &10                                  ; &1CF1: E5 10
        CMP     &0E                                  ; &1CF3: C5 0E
        BMI     L1CFD                                ; &1CF5: 30 06
        CMP     &0F                                  ; &1CF7: C5 0F
        BPL     L1CFD                                ; &1CF9: 10 02
        STA     &0E                                  ; &1CFB: 85 0E
L1CFD:
        LDA     &0F                                  ; &1CFD: A5 0F
        PHA                                          ; &1CFF: 48
        SEC                                          ; &1D00: 38
        LDA     &76                                  ; &1D01: A5 76
        SBC     &10                                  ; &1D03: E5 10
        CMP     &0F                                  ; &1D05: C5 0F
        BPL     L1D0F                                ; &1D07: 10 06
        CMP     &0E                                  ; &1D09: C5 0E
        BMI     L1D0F                                ; &1D0B: 30 02
        STA     &0F                                  ; &1D0D: 85 0F
L1D0F:
        JSR     &147C                                ; &1D0F: 20 7C 14
        PLA                                          ; &1D12: 68
        STA     &0F                                  ; &1D13: 85 0F
        PLA                                          ; &1D15: 68
        STA     &0E                                  ; &1D16: 85 0E
L1D18:
        RTS                                          ; &1D18: 60
        CLC                                          ; &1D19: 18
        LDA     &10                                  ; &1D1A: A5 10
        ADC     &0F                                  ; &1D1C: 65 0F
        STA     &75                                  ; &1D1E: 85 75
        CLC                                          ; &1D20: 18
        LDA     &10                                  ; &1D21: A5 10
        ADC     &0E                                  ; &1D23: 65 0E
        STA     &76                                  ; &1D25: 85 76
        LDA     #&00                                 ; &1D27: A9 00
        STA     &6F                                  ; &1D29: 85 6F
        STA     &5F                                  ; &1D2B: 85 5F
        RTS                                          ; &1D2D: 60

; -----------------------------------------------------------------------------
; Runtime &1D2E: recursive sprite traversal.
; -----------------------------------------------------------------------------
Code_SpriteTraversal:
        STA     &50                                  ; &1D2E: 85 50
        LDA     (&08),Y                              ; &1D30: B1 08
        ASL     A                                    ; &1D32: 0A
        BEQ     L1D44                                ; &1D33: F0 0F
        STY     Scratch26                            ; &1D35: 84 26
        LDY     &50                                  ; &1D37: A4 50
        LDA     &1CAC,Y                              ; &1D39: B9 AC 1C
        PHA                                          ; &1D3C: 48
        LDA     &1CAB,Y                              ; &1D3D: B9 AB 1C
        PHA                                          ; &1D40: 48
        LDY     Scratch26                            ; &1D41: A4 26
        RTS                                          ; &1D43: 60
L1D44:
        LDA     TYPE_POGLET                          ; &1D44: A5 1E
        PHA                                          ; &1D46: 48
        LDA     &1F                                  ; &1D47: A5 1F
        PHA                                          ; &1D49: 48
        LDA     &20                                  ; &1D4A: A5 20
        PHA                                          ; &1D4C: 48
        LDA     (&0A),Y                              ; &1D4D: B1 0A
        STA     TYPE_POGLET                          ; &1D4F: 85 1E
        CLC                                          ; &1D51: 18
        LDA     &00                                  ; &1D52: A5 00
        ADC     (&04),Y                              ; &1D54: 71 04
        STA     &1F                                  ; &1D56: 85 1F
        LDA     &01                                  ; &1D58: A5 01
        ADC     (&06),Y                              ; &1D5A: 71 06
        STA     &20                                  ; &1D5C: 85 20
L1D5E:
        LDY     #&02                                 ; &1D5E: A0 02
        LDA     CurrentSpriteY                       ; &1D60: A5 12
        PHA                                          ; &1D62: 48
        CLC                                          ; &1D63: 18
        ADC     (&1F),Y                              ; &1D64: 71 1F
        STA     CurrentSpriteY                       ; &1D66: 85 12
        DEY                                          ; &1D68: 88
        LDA     CurrentSpriteX                       ; &1D69: A5 11
        PHA                                          ; &1D6B: 48
        CLC                                          ; &1D6C: 18
        ADC     (&1F),Y                              ; &1D6D: 71 1F
        STA     CurrentSpriteX                       ; &1D6F: 85 11
        DEY                                          ; &1D71: 88
        LDA     (&1F),Y                              ; &1D72: B1 1F
        TAY                                          ; &1D74: A8
        JSR     &1D30                                ; &1D75: 20 30 1D
        PLA                                          ; &1D78: 68
        STA     CurrentSpriteX                       ; &1D79: 85 11
        PLA                                          ; &1D7B: 68
        STA     CurrentSpriteY                       ; &1D7C: 85 12
        BCS     L1D8F                                ; &1D7E: B0 0F
        LDA     &1F                                  ; &1D80: A5 1F
        ADC     #&03                                 ; &1D82: 69 03
        STA     &1F                                  ; &1D84: 85 1F
        BCC     L1D8A                                ; &1D86: 90 02
        INC     &20                                  ; &1D88: E6 20
L1D8A:
        DEC     TYPE_POGLET                          ; &1D8A: C6 1E
        BNE     L1D5E                                ; &1D8C: D0 D0
        CLC                                          ; &1D8E: 18
L1D8F:
        PLA                                          ; &1D8F: 68
        STA     &20                                  ; &1D90: 85 20
        PLA                                          ; &1D92: 68
        STA     &1F                                  ; &1D93: 85 1F
        PLA                                          ; &1D95: 68
        STA     TYPE_POGLET                          ; &1D96: 85 1E
        RTS                                          ; &1D98: 60
        JSR     &1592                                ; &1D99: 20 92 15
        TYA                                          ; &1D9C: 98
        PHA                                          ; &1D9D: 48
        LDY     &6F                                  ; &1D9E: A4 6F
        LDA     &45                                  ; &1DA0: A5 45
        STA     &0100,Y                              ; &1DA2: 99 00 01
        CMP     &75                                  ; &1DA5: C5 75
        BPL     L1DAB                                ; &1DA7: 10 02
        STA     &75                                  ; &1DA9: 85 75
L1DAB:
        LDA     &46                                  ; &1DAB: A5 46
        STA     &0101,Y                              ; &1DAD: 99 01 01
        CMP     &76                                  ; &1DB0: C5 76
        BMI     L1DB6                                ; &1DB2: 30 02
        STA     &76                                  ; &1DB4: 85 76
L1DB6:
        LDA     &48                                  ; &1DB6: A5 48
        STA     &0102,Y                              ; &1DB8: 99 02 01
        LDA     &47                                  ; &1DBB: A5 47
        STA     &0103,Y                              ; &1DBD: 99 03 01
        CLC                                          ; &1DC0: 18
        TYA                                          ; &1DC1: 98
        ADC     #&04                                 ; &1DC2: 69 04
        STA     &6F                                  ; &1DC4: 85 6F
        PLA                                          ; &1DC6: 68
        TAY                                          ; &1DC7: A8
        CLC                                          ; &1DC8: 18
        RTS                                          ; &1DC9: 60
        TXA                                          ; &1DCA: 8A
        PHA                                          ; &1DCB: 48
        LDX     #&00                                 ; &1DCC: A2 00
        CPX     &6F                                  ; &1DCE: E4 6F
        BCS     L1E0F                                ; &1DD0: B0 3D
        LDA     CurrentSpriteX                       ; &1DD2: A5 11
        ADC     (&00),Y                              ; &1DD4: 71 00
        CMP     &0101,X                              ; &1DD6: DD 01 01
        BPL     L1E17                                ; &1DD9: 10 3C
        STA     Scratch26                            ; &1DDB: 85 26
        LDA     (&08),Y                              ; &1DDD: B1 08
        ASL     A                                    ; &1DDF: 0A
        LSR     A                                    ; &1DE0: 4A
        ADC     Scratch26                            ; &1DE1: 65 26
        CMP     &0100,X                              ; &1DE3: DD 00 01
        BEQ     L1E17                                ; &1DE6: F0 2F
        BMI     L1E17                                ; &1DE8: 30 2D
        CLC                                          ; &1DEA: 18
        LDA     CurrentSpriteY                       ; &1DEB: A5 12
        ADC     (&02),Y                              ; &1DED: 71 02
        CMP     &0103,X                              ; &1DEF: DD 03 01
        BPL     L1E17                                ; &1DF2: 10 23
        CLC                                          ; &1DF4: 18
        ADC     (&0A),Y                              ; &1DF5: 71 0A
        CMP     &0102,X                              ; &1DF7: DD 02 01
        BEQ     L1E17                                ; &1DFA: F0 1B
        BMI     L1E17                                ; &1DFC: 30 19
        BIT     &5F                                  ; &1DFE: 24 5F
        BPL     L1E13                                ; &1E00: 10 11
        LDA     &5E                                  ; &1E02: A5 5E
        PHA                                          ; &1E04: 48
        LDA     #&00                                 ; &1E05: A9 00
        STA     &5E                                  ; &1E07: 85 5E
        JSR     DirectSpriteRenderer                 ; &1E09: 20 36 1E
        PLA                                          ; &1E0C: 68
        STA     &5E                                  ; &1E0D: 85 5E
L1E0F:
        PLA                                          ; &1E0F: 68
        TAX                                          ; &1E10: AA
L1E11:
        CLC                                          ; &1E11: 18
        RTS                                          ; &1E12: 60
L1E13:
        PLA                                          ; &1E13: 68
        TAX                                          ; &1E14: AA
        SEC                                          ; &1E15: 38
        RTS                                          ; &1E16: 60
L1E17:
        INX                                          ; &1E17: E8
        INX                                          ; &1E18: E8
        INX                                          ; &1E19: E8
        INX                                          ; &1E1A: E8
        JMP     &1DCE                                ; &1E1B: 4C CE 1D
        LDA     &5E                                  ; &1E1E: A5 5E
        BEQ     L1E24                                ; &1E20: F0 02
        BPL     L1E31                                ; &1E22: 10 0D
L1E24:
        TYA                                          ; &1E24: 98
        PHA                                          ; &1E25: 48
        JSR     DirectSpriteRenderer                 ; &1E26: 20 36 1E
        PLA                                          ; &1E29: 68
        TAY                                          ; &1E2A: A8
        BCS     L1E11                                ; &1E2B: B0 E4
        BIT     &5E                                  ; &1E2D: 24 5E
        BVC     L1E11                                ; &1E2F: 50 E0
L1E31:
        JMP     &1D99                                ; &1E31: 4C 99 1D
L1E34:
        SEC                                          ; &1E34: 38
        RTS                                          ; &1E35: 60

; -----------------------------------------------------------------------------
; Runtime &1E36: direct sprite renderer.
; -----------------------------------------------------------------------------
Code_DirectSpriteRenderer:
        SEC                                          ; &1E36: 38
        LDA     CurrentSpriteX                       ; &1E37: A5 11
        SBC     &10                                  ; &1E39: E5 10
        CLC                                          ; &1E3B: 18
        ADC     (&00),Y                              ; &1E3C: 71 00
        CMP     &0F                                  ; &1E3E: C5 0F
        BPL     L1E34                                ; &1E40: 10 F2
        STA     InkeyCode                            ; &1E42: 85 21
        LDA     (&08),Y                              ; &1E44: B1 08
        ASL     A                                    ; &1E46: 0A
        LSR     A                                    ; &1E47: 4A
        STA     TYPE_KEY                             ; &1E48: 85 17
        ADC     InkeyCode                            ; &1E4A: 65 21
        CMP     &0E                                  ; &1E4C: C5 0E
        BMI     L1E34                                ; &1E4E: 30 E4
        CLC                                          ; &1E50: 18
        LDA     CurrentSpriteY                       ; &1E51: A5 12
        ADC     (&02),Y                              ; &1E53: 71 02
        STA     &22                                  ; &1E55: 85 22
        LDA     (&0A),Y                              ; &1E57: B1 0A
        STA     &18                                  ; &1E59: 85 18
        BIT     Orientation                          ; &1E5B: 24 74
        BPL     L1E66                                ; &1E5D: 10 07
        CLC                                          ; &1E5F: 18
        ADC     &22                                  ; &1E60: 65 22
        EOR     Orientation                          ; &1E62: 45 74
        STA     &22                                  ; &1E64: 85 22
L1E66:
        CLC                                          ; &1E66: 18
        LDA     (&04),Y                              ; &1E67: B1 04
        ADC     &00                                  ; &1E69: 65 00
        STA     &13                                  ; &1E6B: 85 13
        LDA     (&06),Y                              ; &1E6D: B1 06
        BMI     L1E84                                ; &1E6F: 30 13
        ADC     &01                                  ; &1E71: 65 01
        STA     &14                                  ; &1E73: 85 14
        LDA     Orientation                          ; &1E75: A5 74
        AND     #&02                                 ; &1E77: 29 02
        TAX                                          ; &1E79: AA
        LDA     (&08),Y                              ; &1E7A: B1 08
        BPL     L1E8A                                ; &1E7C: 10 0C
        TXA                                          ; &1E7E: 8A
        EOR     #&02                                 ; &1E7F: 49 02
        TAX                                          ; &1E81: AA
        BPL     L1E8A                                ; &1E82: 10 06
L1E84:
        LDA     (&04),Y                              ; &1E84: B1 04
        STA     &59                                  ; &1E86: 85 59
        LDX     #&04                                 ; &1E88: A2 04
L1E8A:
        STX     &1B                                  ; &1E8A: 86 1B

; -----------------------------------------------------------------------------
; Runtime &1E8C: sprite render setup.
; -----------------------------------------------------------------------------
Code_SpriteRenderSetup:
        JSR     Mode1Address                         ; &1E8C: 20 A9 1F
        LDA     &1B                                  ; &1E8F: A5 1B
        BIT     &5E                                  ; &1E91: 24 5E
        BPL     L1E98                                ; &1E93: 10 03
        CLC                                          ; &1E95: 18
        ADC     #&06                                 ; &1E96: 69 06
L1E98:
        TAX                                          ; &1E98: AA
        LDA     &1F9D,X                              ; &1E99: BD 9D 1F
        STA     &01C5                                ; &1E9C: 8D C5 01
        STA     &01C8                                ; &1E9F: 8D C8 01
        STA     &01CB                                ; &1EA2: 8D CB 01
        STA     &01CE                                ; &1EA5: 8D CE 01
        STA     &01D1                                ; &1EA8: 8D D1 01
        STA     &01D4                                ; &1EAB: 8D D4 01
        STA     &01D7                                ; &1EAE: 8D D7 01
        STA     &01DA                                ; &1EB1: 8D DA 01
        LDA     &1F9E,X                              ; &1EB4: BD 9E 1F
        STA     &01C6                                ; &1EB7: 8D C6 01
        STA     &01C9                                ; &1EBA: 8D C9 01
        STA     &01CC                                ; &1EBD: 8D CC 01
        STA     &01CF                                ; &1EC0: 8D CF 01
        STA     &01D2                                ; &1EC3: 8D D2 01
        STA     &01D5                                ; &1EC6: 8D D5 01
        STA     &01D8                                ; &1EC9: 8D D8 01
        STA     &01DB                                ; &1ECC: 8D DB 01
        LDA     &22                                  ; &1ECF: A5 22
        AND     #&07                                 ; &1ED1: 29 07
        ASL     A                                    ; &1ED3: 0A
        TAX                                          ; &1ED4: AA
        LDA     &1F31,X                              ; &1ED5: BD 31 1F
        STA     &1C                                  ; &1ED8: 85 1C
        LDA     &1F32,X                              ; &1EDA: BD 32 1F
        STA     TYPE_HOOTER                          ; &1EDD: 85 1D
        LDA     &13                                  ; &1EDF: A5 13
        BNE     L1EE5                                ; &1EE1: D0 02
        DEC     &14                                  ; &1EE3: C6 14
L1EE5:
        DEC     &13                                  ; &1EE5: C6 13
        LDX     #&00                                 ; &1EE7: A2 00
L1EE9:
        LDY     &18                                  ; &1EE9: A4 18
        LDA     InkeyCode                            ; &1EEB: A5 21
        CMP     &0E                                  ; &1EED: C5 0E
        BMI     L1EF8                                ; &1EEF: 30 07
        CMP     &0F                                  ; &1EF1: C5 0F
        BPL     L1F2C                                ; &1EF3: 10 37
        JSR     &1F2E                                ; &1EF5: 20 2E 1F
L1EF8:
        DEC     TYPE_KEY                             ; &1EF8: C6 17
        BEQ     L1F2C                                ; &1EFA: F0 30
        INC     InkeyCode                            ; &1EFC: E6 21
        CLC                                          ; &1EFE: 18
        TYA                                          ; &1EFF: 98
        ADC     &13                                  ; &1F00: 65 13
        STA     &13                                  ; &1F02: 85 13
        BCC     L1F08                                ; &1F04: 90 02
        INC     &14                                  ; &1F06: E6 14
L1F08:
        CLC                                          ; &1F08: 18
        LDA     #&08                                 ; &1F09: A9 08
        ADC     &15                                  ; &1F0B: 65 15
        STA     &15                                  ; &1F0D: 85 15
        STA     &19                                  ; &1F0F: 85 19
        TXA                                          ; &1F11: 8A
        ADC     TYPE_GEM                             ; &1F12: 65 16
        STA     TYPE_GEM                             ; &1F14: 85 16
        STA     &1A                                  ; &1F16: 85 1A
        LDA     &18                                  ; &1F18: A5 18
        ADC     &19                                  ; &1F1A: 65 19
        TXA                                          ; &1F1C: 8A
        ADC     &1A                                  ; &1F1D: 65 1A
        BPL     L1EE9                                ; &1F1F: 10 C8
        SEC                                          ; &1F21: 38
        LDA     &1A                                  ; &1F22: A5 1A
        SBC     #&50                                 ; &1F24: E9 50
        STA     &1A                                  ; &1F26: 85 1A
        STA     TYPE_GEM                             ; &1F28: 85 16
        BPL     L1EE9                                ; &1F2A: 10 BD
L1F2C:
        CLC                                          ; &1F2C: 18
        RTS                                          ; &1F2D: 60
        JMP     (&001C)                              ; &1F2E: 6C 1C 00
        EQUB &C4,&01,&C7,&01,&CA,&01,&CD,&01,&D0,&01,&D3,&01,&D6,&01,&D9,&01    ; runtime &1F31
        LDA     (&13),Y                              ; &1F41: B1 13
        STA     SpriteTableBaseLo                    ; &1F43: 85 80
        LDA     (SpriteTableBaseLo,X)                ; &1F45: A1 80
        AND     (&19),Y                              ; &1F47: 31 19
        ORA     SpriteTableBaseLo                    ; &1F49: 05 80
        STA     (&19),Y                              ; &1F4B: 91 19
        DEY                                          ; &1F4D: 88
        BEQ     L1F65                                ; &1F4E: F0 15
        RTS                                          ; &1F50: 60
        INC     &13                                  ; &1F51: E6 13
        BEQ     L1F6A                                ; &1F53: F0 15
L1F55:
        LDA     (&13,X)                              ; &1F55: A1 13
        STA     SpriteTableBaseLo                    ; &1F57: 85 80
        LDA     (SpriteTableBaseLo,X)                ; &1F59: A1 80
        AND     (&19),Y                              ; &1F5B: 31 19
        ORA     SpriteTableBaseLo                    ; &1F5D: 05 80
        STA     (&19),Y                              ; &1F5F: 91 19
        DEY                                          ; &1F61: 88
        BEQ     L1F67                                ; &1F62: F0 03
        RTS                                          ; &1F64: 60
L1F65:
        LDY     &18                                  ; &1F65: A4 18
L1F67:
        PLA                                          ; &1F67: 68
        PLA                                          ; &1F68: 68
        RTS                                          ; &1F69: 60
L1F6A:
        INC     &14                                  ; &1F6A: E6 14
        BNE     L1F55                                ; &1F6C: D0 E7
        LDA     &59                                  ; &1F6E: A5 59
        STA     (&19),Y                              ; &1F70: 91 19
        DEY                                          ; &1F72: 88
        BEQ     L1F67                                ; &1F73: F0 F2
        RTS                                          ; &1F75: 60
        LDA     (&13),Y                              ; &1F76: B1 13
        EOR     #&FF                                 ; &1F78: 49 FF
        AND     (&19),Y                              ; &1F7A: 31 19
        STA     (&19),Y                              ; &1F7C: 91 19
        DEY                                          ; &1F7E: 88
        BEQ     L1F65                                ; &1F7F: F0 E4
        RTS                                          ; &1F81: 60
        INC     &13                                  ; &1F82: E6 13
        BEQ     L1F99                                ; &1F84: F0 13
L1F86:
        LDA     (&13,X)                              ; &1F86: A1 13
        EOR     #&FF                                 ; &1F88: 49 FF
        AND     (&19),Y                              ; &1F8A: 31 19
        STA     (&19),Y                              ; &1F8C: 91 19
        DEY                                          ; &1F8E: 88
        BEQ     L1F67                                ; &1F8F: F0 D6
        RTS                                          ; &1F91: 60
        TXA                                          ; &1F92: 8A
        STA     (&19),Y                              ; &1F93: 91 19
        DEY                                          ; &1F95: 88
        BEQ     L1F67                                ; &1F96: F0 CF
        RTS                                          ; &1F98: 60
L1F99:
        INC     &14                                  ; &1F99: E6 14
        BNE     L1F86                                ; &1F9B: D0 E9
        EOR     (&1F,X)                              ; &1F9D: 41 1F
        EOR     (&1F),Y                              ; &1F9F: 51 1F
        ROR     &761F                                ; &1FA1: 6E 1F 76
        EQUB &1F,&82,&1F,&92,&1F    ; runtime &1FA4

; -----------------------------------------------------------------------------
; Runtime &1FA9: MODE 1 address calculation.
; -----------------------------------------------------------------------------
Code_Mode1Address:
        LDA     #&00                                 ; &1FA9: A9 00
        STA     TYPE_GEM                             ; &1FAB: 85 16
        LDA     &22                                  ; &1FAD: A5 22
        EOR     #&FF                                 ; &1FAF: 49 FF
        TAX                                          ; &1FB1: AA
        AND     #&07                                 ; &1FB2: 29 07
        STA     TYPE_BULB                            ; &1FB4: 85 23
        TXA                                          ; &1FB6: 8A
        LSR     A                                    ; &1FB7: 4A
        LSR     A                                    ; &1FB8: 4A
        ORA     #&01                                 ; &1FB9: 09 01
        TAY                                          ; &1FBB: A8
        LDA     InkeyCode                            ; &1FBC: A5 21
        ASL     A                                    ; &1FBE: 0A
        ROL     TYPE_GEM                             ; &1FBF: 26 16
        ASL     A                                    ; &1FC1: 0A
        ROL     TYPE_GEM                             ; &1FC2: 26 16
        ASL     A                                    ; &1FC4: 0A
        ROL     TYPE_GEM                             ; &1FC5: 26 16
        ORA     TYPE_BULB                            ; &1FC7: 05 23
        ADC     (&E0),Y                              ; &1FC9: 71 E0
        TAX                                          ; &1FCB: AA
        DEY                                          ; &1FCC: 88
        LDA     TYPE_GEM                             ; &1FCD: A5 16
        ADC     (&E0),Y                              ; &1FCF: 71 E0
        TAY                                          ; &1FD1: A8
        TXA                                          ; &1FD2: 8A
        ADC     &0C                                  ; &1FD3: 65 0C
        TAX                                          ; &1FD5: AA
        TYA                                          ; &1FD6: 98
        ADC     &0D                                  ; &1FD7: 65 0D
        BIT     InkeyCode                            ; &1FD9: 24 21
        BPL     L1FDF                                ; &1FDB: 10 02
        SBC     #&07                                 ; &1FDD: E9 07
L1FDF:
        TAY                                          ; &1FDF: A8
        BPL     L1FE8                                ; &1FE0: 10 06
L1FE2:
        SEC                                          ; &1FE2: 38
        SBC     #&50                                 ; &1FE3: E9 50
        BMI     L1FE2                                ; &1FE5: 30 FB
        TAY                                          ; &1FE7: A8
L1FE8:
        SEC                                          ; &1FE8: 38
        TXA                                          ; &1FE9: 8A
        SBC     &18                                  ; &1FEA: E5 18
        TAX                                          ; &1FEC: AA
        BCS     L1FF0                                ; &1FED: B0 01
        DEY                                          ; &1FEF: 88
L1FF0:
        STX     &19                                  ; &1FF0: 86 19
        STY     &1A                                  ; &1FF2: 84 1A
        STX     &15                                  ; &1FF4: 86 15
        STY     TYPE_GEM                             ; &1FF6: 84 16
        RTS                                          ; &1FF8: 60
Runtime_01A4_Source:
        EQUB &13,&00,&01,&00,&00,&00,&FF,&00,&11,&00,&03,&00,&78,&00,&FF,&00    ; &44EB
        EQUB &12,&00,&02,&00,&00,&00,&FF,&00,&11,&00,&04,&00,&5A,&00,&FF,&00    ; &44FB
        EQUB &20,&FF,&FF,&20,&FF,&FF,&20,&FF,&FF,&20,&FF,&FF,&20,&FF,&FF,&20    ; &450B
        EQUB &FF,&FF,&20,&FF,&FF,&20,&FF,&FF,&38,&A5,&19,&E9,&78,&85,&19,&A5    ; &451B
        EQUB &1A,&E9,&02,&85,&1A,&18,&98,&65,&19,&8A,&65,&1A,&C9,&30,&B0,&D0    ; &452B
        EQUB &A5,&1A,&69,&50,&85,&1A,&90,&C8    ; &453B
Runtime_01A4_SourceEnd:
; -----------------------------------------------------------------------------
; &4543: Overlapping title/game entry block copied to runtime &0380-&048F.
; -----------------------------------------------------------------------------
Runtime_0380_Source:
; -----------------------------------------------------------------------------
; Runtime &0380: relocated game/title entry.
; -----------------------------------------------------------------------------
Title_RuntimeEntry:
        LDX #&01
        LDY #&00
        JSR DisplayInit
        CLI
        JSR PrintInlineStream

; Inline VDU stream: "The Cast", then Trogg vs. Scrubbly/Hooter/Poglet.
        EQUB &11,&80,&1F,&10,&03,&54,&68,&65,&20,&43,&61,&73,&74,&1F,&10,&04    ; runtime &038B
        EQUB &2D,&2D,&2D,&2D,&2D,&2D,&2D,&2D,&1F,&1A,&07,&54,&72,&6F,&67,&67    ; runtime &039B
        EQUB &1F,&13,&09,&76,&73,&2E,&1F,&19,&0D,&53,&63,&72,&75,&62,&62,&6C    ; runtime &03AB
        EQUB &79,&1F,&1A,&11,&48,&6F,&6F,&74,&65,&72,&1F,&1A,&15,&50,&6F,&67    ; runtime &03BB
        EQUB &6C,&65,&74,&EA    ; runtime &03CB

; Draw the five cast sprites alongside the text above.
Title_DrawCast:
        LDA #&22
        LDX #&22
        LDY #&EA
        JSR DrawSpriteAt
        LDA #&35
        LDX #&16
        LDY #&B7
        JSR DrawSpriteAt
        LDA #TYPE_SCRUBBLY
        LDX #&15
        LDY #&85
        JSR DrawSpriteAt
        LDA #TYPE_HOOTER
        LDX #&15
        LDY #&6B
        JSR DrawSpriteAt
        LDA #TYPE_POGLET
        LDX #&16
        LDY #&58
        JSR DrawSpriteAt
        JSR PrintInlineStream

; Inline VDU/credits stream: design/programming credits and copyright.
        EQUB &1C,&00,&1F,&27,&19,&11,&82,&0C,&1F,&05,&01,&47,&61,&6D,&65,&20    ; runtime &03FF
        EQUB &63,&6F,&6E,&63,&65,&70,&74,&73,&20,&62,&79,&20,&44,&43,&45,&2C    ; runtime &040F
        EQUB &4F,&4D,&50,&20,&26,&20,&42,&4F,&46,&1F,&01,&03,&50,&72,&6F,&67    ; runtime &041F
        EQUB &72,&61,&6D,&6D,&69,&6E,&67,&20,&62,&65,&79,&6F,&6E,&64,&20,&62    ; runtime &042F
        EQUB &65,&6C,&69,&65,&66,&20,&62,&79,&20,&2A,&4F,&72,&6C,&61,&6E,&64    ; runtime &043F
        EQUB &6F,&2A,&1F,&07,&05,&28,&43,&29,&20,&41,&61,&72,&64,&76,&61,&72    ; runtime &044F
        EQUB &6B,&20,&53,&6F,&66,&74,&77,&61,&72,&65,&20,&31,&39,&38,&34,&19    ; runtime &045F
        EQUB &04,&00,&00,&E0,&00,&19,&01,&00,&05,&00,&00,&EA    ; runtime &046F

Title_EnterAttractLoop:
        JSR TitleInitEightRecords
        JMP GameStartCheck

; Initialise eight records via the helper at runtime &1AC7.  &7E retains the
; caller's hardware stack pointer for the title/start machinery.
Title_InitEightRecordsSource:
        TSX
        STX &7E
        LDX #&07
Title_InitEightLoop:
        LDA #&00
        JSR Routine1AC7
        DEX
        BNE Title_InitEightLoop
        CLC
        RTS
Runtime_0380_SourceEnd:


; Four 14-byte OSWORD parameter/control blocks used by Bootstrap.  They lived
; immediately after the title/cast block in the original packed image.
StartupOSWORD_Block0:
        EQUB &01,&01,&00,&00,&00,&01,&01,&01,&64,&F6,&FE,&FC,&64,&3C    ; original &4653
StartupOSWORD_Block1:
        EQUB &02,&01,&00,&00,&00,&01,&01,&01,&64,&9C,&9C,&9C,&64,&00    ; original &4661
StartupOSWORD_Block2:
        EQUB &03,&82,&00,&02,&FD,&02,&06,&04,&3C,&07,&F2,&F2,&3C,&6E    ; original &466F
StartupOSWORD_Block3:
        EQUB &04,&82,&00,&FC,&02,&03,&03,&28,&28,&FC,&FB,&FB,&78,&74    ; original &467D
; -----------------------------------------------------------------------------
; &468B: Decoded original startup: relocates runtime blocks, installs vectors/state, then JMP &0380.
; -----------------------------------------------------------------------------
Bootstrap:
        SEI
        LDX #&A2
        TXS
        CLD
        LDA #&8C
        LDX #&03
        JSR OSBYTE
        LDA #&40
        STA &0D00                   ; original fixed game workspace
        LDY #&0F
        LDA #&00
Bootstrap_ClearWorkspace:
        STA &02A1,Y
        DEY
        BPL Bootstrap_ClearWorkspace

; Relocation records are inline after each JSR. RelocateBlock consumes the six
; bytes by rewriting the return address on the stack.  Source addresses are now
; LABELS, which is what makes the packed image assembly-origin independent.
Bootstrap_RelocateCore:
        JSR RelocateBlock
        EQUW Runtime_0B00_Source
        EQUW QueueDescriptors
        EQUW Runtime_0B00_SourceEnd-Runtime_0B00_Source

Bootstrap_RelocateMain:
        JSR RelocateBlock
        EQUW Runtime_0D01_Source
        EQUW WaitForTickChange
        EQUW (Bootstrap_RelocateSoundParams+2)-Runtime_0D01_Source

Bootstrap_RelocateSprites:
        JSR RelocateBlock
        EQUW Runtime_1FFD_Source
        EQUW SpriteXOffsets
        EQUW Runtime_1FFD_SourceEnd-Runtime_1FFD_Source

Bootstrap_RelocateSoundLevels:
        JSR RelocateBlock
        EQUW Runtime_0507_Source
        EQUW SoundStream
        EQUW Runtime_0507_SourceEnd-Runtime_0507_Source

Bootstrap_RelocateHighScores:
        JSR RelocateBlock
        EQUW Runtime_0880_Source
        EQUW HighScores
        EQUW Runtime_0880_SourceEnd-Runtime_0880_Source

Bootstrap_RelocateMasks:
        JSR RelocateBlock
        EQUW Runtime_0A00_Source
        EQUW Mode1Masks
        EQUW Runtime_0A00_SourceEnd-Runtime_0A00_Source

Bootstrap_RelocateSoundParams:
        JSR RelocateBlock
        EQUW Runtime_01A4_Source
        EQUW &01A4
        EQUW (Runtime_0380_Source+4)-Runtime_01A4_Source

Bootstrap_RelocateTitle:
        JSR RelocateBlock
        EQUW Runtime_0380_Source
        EQUW RuntimeGameEntry
        EQUW Runtime_0380_SourceEnd-Runtime_0380_Source

; Initialise four OSWORD control blocks retained in the packed source image.
        LDX #<StartupOSWORD_Block0
        LDY #>StartupOSWORD_Block0
        LDA #&08
        JSR OSWORDWrapper
        LDX #<StartupOSWORD_Block1
        LDY #>StartupOSWORD_Block1
        LDA #&08
        JSR OSWORDWrapper
        LDX #<StartupOSWORD_Block2
        LDY #>StartupOSWORD_Block2
        LDA #&08
        JSR OSWORDWrapper
        LDX #<StartupOSWORD_Block3
        LDY #>StartupOSWORD_Block3
        LDA #&08
        JSR OSWORDWrapper

; Install the game EVENTV handler.  Preserve the pre-existing USERV in zero page
; before installing Frak's USERV filter later in startup.
        LDX #<TickIRQ
        LDY #>TickIRQ
        STY EVENTV+1
        STX EVENTV
        LDY USERV+1
        LDX USERV
        STY SavedUserVHi
        STX SavedUserVLo

        LDX #&04
        LDA #&0E
        JSR OSBYTEWrapper

; Install the IRQ1V sound handler, again preserving the old vector.
        LDY IRQ1V+1
        LDX IRQ1V
        STY SavedIRQ1VHi
        STX SavedIRQ1VLo
        LDX #<SoundIRQ
        LDY #>SoundIRQ
        STY IRQ1V+1
        STX IRQ1V

        LDX #&00
        STX SoundEnabled
        STX SoundIrqGate
        STX Orientation
        STX InputState
        STX PauseGate
        STX OSCallGate
        DEX
        STX GameState2F
        STX InputMode
        JSR ResetCountdownDivider

; Build six zero-page pointers to the parallel sprite descriptor arrays.
        LDX #<SpriteXOffsets
        LDY #>SpriteXOffsets
        STY &01
        STX &00
        LDX #<SpriteYOffsets
        LDY #>SpriteYOffsets
        STY &03
        STX &02
        LDX #<SpriteDefLo
        LDY #>SpriteDefLo
        STY &05
        STX &04
        LDX #<SpriteDefHi
        LDY #>SpriteDefHi
        STY &07
        STX &06
        LDX #<SpriteWidthFlags
        LDY #>SpriteWidthFlags
        STY &09
        STX &08
        LDX #<SpriteHeightCount
        LDY #>SpriteHeightCount
        STY &0B
        STX &0A

        LDA #&0A
        STA SoundStreamCount
        LDY #&CF
        LDX #&20
        LDA #&CA
        JSR OSBYTEWrapper
        LDY #&00
        LDX #&08
        LDA #&BE
        JSR OSBYTEWrapper
        LDA #&76
        JSR OSBYTEWrapper
        LDX #&28
        LDA #&09
        JSR OSBYTEWrapper
        LDX #&14
        LDA #&0A
        JSR OSBYTEWrapper

        LDA #&E0
        STA USER_VIA_IER
        LDA #&40
        STA USER_VIA_ACR

; Scan the packed sound stream and cache the five segment offsets in &8B-&8F.
        LDY #&00
        LDX #&8B
Bootstrap_FindSoundStreams:
        STY &00,X
Bootstrap_ScanSoundStream:
        INY
        LDA SoundStream-1,Y
        BPL Bootstrap_ScanSoundStream
        INX
        CPX #&8F
        BCC Bootstrap_FindSoundStreams
        STY &00,X

; Install USERV then enable the required System VIA interrupt source.
        LDX #<UserVHandler
        LDY #>UserVHandler
        STY USERV+1
        STX USERV
        LDA #&01
        STA SYSTEM_VIA_IER
        JMP RuntimeGameEntry

; Original inline-record mover.  The JSR return address points immediately
; before a six-byte record: source word, destination word, byte-count word.
RelocateBlock:
        PLA
        STA InlinePtrLo
        PLA
        STA InlinePtrHi
        LDY #&01
        LDA (InlinePtrLo),Y
        STA RelocSourceLo
        INY
        LDA (InlinePtrLo),Y
        STA RelocSourceHi
        INY
        LDA (InlinePtrLo),Y
        STA RelocDestLo
        INY
        LDA (InlinePtrLo),Y
        STA RelocDestHi
        INY
        LDA (InlinePtrLo),Y
        TAX
        INY
        LDA (InlinePtrLo),Y
        STA RelocLengthHi
        LDY #&00
RelocateBlock_Copy:
        LDA (RelocSourceLo),Y
        STA (RelocDestLo),Y
        TXA
        BNE RelocateBlock_NoBorrow
        DEC RelocLengthHi
RelocateBlock_NoBorrow:
        DEX
        TXA
        ORA RelocLengthHi
        BEQ RelocateBlock_Done
        INY
        BNE RelocateBlock_Copy
        INC RelocSourceHi
        INC RelocDestHi
        JMP RelocateBlock_Copy
RelocateBlock_Done:
        CLC
        LDA InlinePtrLo
        ADC #&06
        TAX
        LDA InlinePtrHi
        ADC #&00
        PHA
        TXA
        PHA
        RTS

; -----------------------------------------------------------------------------
; &482C: Relocated by Bootstrap: &482C-&582E -> runtime &1FFD-&2FFF (sprite system/data).
; -----------------------------------------------------------------------------
Runtime_1FFD_Source:
        EQUB &00,&01,&01,&01,&00,&01,&02,&01,&01,&FF,&00,&FF,&01,&00,&00,&00    ; &482C
        EQUB &00,&00,&FD,&FE,&FE,&00,&FF,&FE,&00,&00,&00,&00,&00,&FF,&FD,&00    ; &483C
        EQUB &00,&00,&00,&00,&FF,&FF,&FF,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &484C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &485C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &486C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &487C
        EQUB &00,&00,&00,&00,&00,&00,&00,&01,&02,&00,&00,&00,&00,&F3,&00,&00    ; &488C
        EQUB &00,&F3,&00,&00,&F5,&F5,&F5,&F2,&F5,&00,&EF,&00,&00,&00,&00,&00    ; &489C
        EQUB &00,&FB,&FB,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &48AC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &48BC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &48CC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&28,&5C,&93,&CA,&FC,&3B,&72,&A3    ; &48DC
        EQUB &E5,&27,&F7,&C7,&84,&25,&31,&25,&31,&3D,&73,&E8,&B1,&7D,&A7,&BF    ; &48EC
        EQUB &FB,&07,&13,&36,&63,&87,&FA,&C6,&D2,&EE,&0A,&00,&2D,&56,&56,&77    ; &48FC
        EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&95,&9B,&A1,&A7    ; &490C
        EQUB &AD,&B3,&B9,&BF,&C5,&CB,&D1,&D7,&DD,&E3,&E9,&EF,&F5,&0A,&25,&40    ; &491C
        EQUB &67,&73,&7C,&85,&91,&A0,&B2,&B8,&BE,&C4,&CA,&D0,&D6,&DC,&E2,&E8    ; &492C
        EQUB &EE,&F4,&FA,&00,&02,&02,&02,&02,&02,&03,&03,&03,&03,&04,&04,&05    ; &493C
        EQUB &06,&07,&07,&07,&07,&07,&07,&08,&09,&0A,&0A,&0A,&0A,&0B,&0B,&0B    ; &494C
        EQUB &0B,&0B,&0B,&0C,&0C,&0C,&0D,&0E,&0E,&0E,&0E,&0E,&FF,&FF,&FF,&FF    ; &495C
        EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E    ; &496C
        EQUB &0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0F,&0F,&0F,&0F,&0F,&0F,&0F    ; &497C
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&10    ; &498C
        EQUB &02,&04,&04,&04,&05,&04,&04,&05,&05,&07,&07,&07,&06,&02,&02,&82    ; &499C
        EQUB &82,&04,&09,&05,&05,&03,&03,&06,&01,&01,&03,&03,&03,&05,&06,&02    ; &49AC
        EQUB &02,&02,&0D,&03,&03,&03,&83,&03,&02,&04,&06,&08,&0A,&0C,&0E,&10    ; &49BC
        EQUB &12,&14,&16,&18,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &49CC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &49DC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&1A,&0B,&0B,&0B    ; &49EC
        EQUB &0B,&0B,&0B,&0B,&0B,&1A,&1A,&18,&17,&06,&06,&06,&06,&0E,&2A,&22    ; &49FC
        EQUB &22,&0E,&09,&0A,&0C,&0C,&0C,&0F,&0C,&17,&22,&06,&0E,&0E,&13,&0F    ; &4A0C
        EQUB &0E,&0B,&0B,&0A,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01,&01    ; &4A1C
        EQUB &02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02    ; &4A2C
        EQUB &07,&09,&09,&0D,&04,&03,&03,&04,&05,&06,&02,&02,&02,&02,&02,&02    ; &4A3C
        EQUB &02,&02,&02,&02,&02,&02,&02,&01,&F9,&F9,&F9,&F9,&F9,&F9,&F8,&74    ; &4A4C
        EQUB &74,&F8,&F9,&F9,&F9,&F9,&F8,&74,&74,&74,&74,&74,&F8,&F9,&F9,&F9    ; &4A5C
        EQUB &F9,&F9,&00,&00,&00,&00,&00,&00,&88,&88,&88,&88,&00,&00,&00,&00    ; &4A6C
        EQUB &88,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&11,&11,&00,&00    ; &4A7C
        EQUB &00,&00,&11,&11,&33,&23,&33,&FF,&8F,&CF,&67,&DF,&8F,&9F,&1F,&3F    ; &4A8C
        EQUB &0F,&FF,&FF,&3F,&1F,&1F,&0F,&8F,&8F,&CF,&CF,&8F,&FF,&00,&00,&00    ; &4A9C
        EQUB &88,&88,&88,&88,&BB,&DF,&1F,&FF,&00,&00,&00,&00,&00,&00,&00,&00    ; &4AAC
        EQUB &00,&00,&00,&11,&00,&00,&11,&33,&67,&47,&47,&67,&33,&00,&FF,&8F    ; &4ABC
        EQUB &8F,&8F,&8F,&4F,&4F,&CF,&4F,&8F,&FF,&FF,&2E,&2E,&2E,&6E,&4C,&CC    ; &4ACC
        EQUB &FF,&DF,&1F,&FF,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4ADC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&00,&00,&11,&33,&77    ; &4AEC
        EQUB &47,&47,&67,&23,&33,&FF,&8F,&8F,&8F,&0F,&1F,&3F,&7F,&7F,&1F,&FF    ; &4AFC
        EQUB &FF,&2E,&2E,&7F,&9F,&1F,&1F,&9F,&8F,&CF,&77,&00,&00,&00,&00,&00    ; &4B0C
        EQUB &00,&EE,&AE,&2E,&EE,&CC,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4B1C
        EQUB &00,&11,&11,&11,&11,&00,&00,&11,&00,&11,&11,&77,&CF,&0F,&1F,&9F    ; &4B2C
        EQUB &8F,&FF,&FF,&8F,&8F,&0F,&1F,&2F,&6F,&EF,&EF,&CF,&FF,&FF,&2E,&6E    ; &4B3C
        EQUB &AE,&2E,&2E,&6E,&7F,&6F,&0F,&FF,&00,&00,&00,&00,&00,&00,&00,&88    ; &4B4C
        EQUB &88,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&11    ; &4B5C
        EQUB &11,&11,&DD,&BF,&8F,&FF,&FF,&CF,&8F,&8F,&0F,&1F,&1F,&3F,&3F,&1F    ; &4B6C
        EQUB &FF,&FF,&1F,&3F,&6E,&BF,&1F,&9F,&8F,&CF,&0F,&FF,&CC,&88,&00,&00    ; &4B7C
        EQUB &00,&00,&88,&88,&CC,&4C,&CC,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4B8C
        EQUB &00,&00,&FF,&47,&47,&47,&67,&23,&33,&FF,&BF,&8F,&FF,&FF,&1F,&1F    ; &4B9C
        EQUB &1F,&1F,&2F,&2F,&3F,&2F,&1F,&FF,&88,&00,&00,&88,&CC,&6E,&2E,&2E    ; &4BAC
        EQUB &6E,&CC,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4BBC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&77,&57,&47,&77,&33,&FF,&47    ; &4BCC
        EQUB &47,&EF,&9F,&8F,&8F,&9F,&1F,&3F,&EE,&FF,&1F,&1F,&1F,&0F,&8F,&CF    ; &4BDC
        EQUB &EF,&EF,&8F,&FF,&88,&00,&00,&88,&CC,&EE,&2E,&2E,&6E,&4C,&CC,&00    ; &4BEC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&33,&23,&67,&47,&CF,&0F    ; &4BFC
        EQUB &3F,&6E,&7F,&3F,&FF,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&11    ; &4C0C
        EQUB &FF,&47,&67,&57,&47,&47,&67,&EF,&6F,&0F,&FF,&FF,&1F,&1F,&0F,&8F    ; &4C1C
        EQUB &4F,&6F,&7F,&7F,&3F,&FF,&88,&00,&88,&88,&EE,&3F,&0F,&8F,&9F,&1F    ; &4C2C
        EQUB &FF,&00,&00,&00,&00,&00,&88,&88,&88,&88,&00,&00,&33,&23,&67,&47    ; &4C3C
        EQUB &CF,&0F,&3F,&6E,&7F,&3F,&FF,&00,&00,&00,&33,&23,&33,&00,&00,&00    ; &4C4C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4C5C
        EQUB &00,&00,&11,&23,&EF,&0F,&FF,&33,&11,&00,&00,&00,&00,&00,&00,&00    ; &4C6C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&FF,&FF,&D3,&E9,&E9    ; &4C7C
        EQUB &0F,&DF,&3F,&FF,&77,&67,&67,&EF,&FB,&FB,&FF,&CF,&CF,&FF,&FC,&76    ; &4C8C
        EQUB &33,&11,&00,&00,&00,&88,&EE,&FF,&FF,&FF,&FF,&BF,&8F,&0F,&2F,&2F    ; &4C9C
        EQUB &3F,&1F,&8F,&FF,&FF,&6F,&0F,&FF,&F0,&F0,&F0,&F8,&00,&00,&00,&00    ; &4CAC
        EQUB &00,&88,&CC,&FF,&FF,&FF,&3F,&1F,&0F,&0F,&0F,&8F,&CF,&FF,&CF,&0F    ; &4CBC
        EQUB &0F,&FF,&F0,&F0,&F0,&F1,&00,&00,&00,&00,&00,&00,&00,&00,&88,&00    ; &4CCC
        EQUB &88,&EE,&FF,&DF,&6F,&6F,&3F,&1F,&1F,&1F,&3F,&FF,&F1,&F3,&F6,&FF    ; &4CDC
        EQUB &77,&77,&33,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&88,&88,&88    ; &4CEC
        EQUB &CC,&4C,&4C,&4C,&6E,&3F,&1F,&DF,&F3,&FD,&FF,&FF,&EE,&11,&33,&67    ; &4CFC
        EQUB &DF,&67,&33,&11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&4C,&F4,&FF    ; &4D0C
        EQUB &85,&20,&A9,&80,&24,&20,&D0,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4D1C
        EQUB &00,&11,&11,&11,&33,&23,&23,&23,&67,&CF,&8F,&BF,&FC,&FB,&FF,&FF    ; &4D2C
        EQUB &77,&00,&00,&00,&00,&00,&11,&00,&11,&77,&CF,&8F,&0F,&1F,&1F,&3F    ; &4D3C
        EQUB &2F,&7F,&7C,&FC,&7C,&FE,&F7,&FF,&EE,&EE,&CC,&00,&00,&11,&33,&FF    ; &4D4C
        EQUB &FF,&FF,&DF,&0F,&0F,&0F,&3F,&EF,&0F,&0F,&1F,&FF,&F0,&F0,&F0,&F0    ; &4D5C
        EQUB &F0,&F8,&00,&00,&00,&11,&77,&FF,&FF,&FF,&FF,&DF,&E7,&FB,&F9,&FD    ; &4D6C
        EQUB &FD,&FC,&FC,&F8,&F8,&F0,&F0,&F0,&F0,&F0,&F0,&F1,&00,&00,&00,&FF    ; &4D7C
        EQUB &FF,&BC,&79,&79,&0F,&BF,&CF,&7F,&2E,&3F,&9F,&9F,&DF,&D7,&F7,&F3    ; &4D8C
        EQUB &F1,&F1,&F1,&F3,&E6,&CC,&00,&00,&00,&00,&88,&4C,&7F,&0F,&FF,&CC    ; &4D9C
        EQUB &88,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4DAC
        EQUB &00,&00,&00,&00,&00,&00,&CC,&4C,&CC,&00,&00,&00,&00,&00,&00,&00    ; &4DBC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&67    ; &4DCC
        EQUB &DF,&67,&33,&11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&4C,&F4,&FF    ; &4DDC
        EQUB &85,&20,&A9,&80,&24,&20,&D0,&00,&00,&00,&77,&47,&77,&00,&00,&00    ; &4DEC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&77,&47,&77,&00,&11    ; &4DFC
        EQUB &33,&56,&DF,&1F,&EF,&77,&23,&11,&00,&11,&11,&11,&11,&11,&11,&33    ; &4E0C
        EQUB &FF,&7F,&9F,&3F,&6E,&CC,&00,&FF,&FF,&B7,&D3,&D3,&1F,&BF,&6F,&CF    ; &4E1C
        EQUB &8F,&8F,&CF,&C7,&C7,&E7,&E3,&F3,&F0,&F0,&F8,&FC,&76,&33,&00,&00    ; &4E2C
        EQUB &CC,&FF,&FF,&FF,&FF,&7F,&0F,&0F,&0F,&0F,&CF,&BF,&1F,&0F,&0F,&FF    ; &4E3C
        EQUB &F0,&F0,&F0,&F0,&F0,&F8,&00,&00,&00,&00,&88,&EE,&FF,&EE,&FF,&7F    ; &4E4C
        EQUB &1F,&0F,&0F,&0F,&CF,&7F,&1F,&FF,&F0,&F0,&F0,&F0,&F0,&F1,&00,&00    ; &4E5C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&88,&EE,&3F,&1F,&1F,&0F,&8F,&8F    ; &4E6C
        EQUB &8F,&CF,&CF,&CF,&8F,&CF,&77,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &4E7C
        EQUB &00,&00,&00,&00,&88,&88,&88,&88,&88,&88,&88,&88,&88,&88,&88,&00    ; &4E8C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&67    ; &4E9C
        EQUB &57,&67,&33,&11,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&77,&DF    ; &4EAC
        EQUB &9F,&BF,&AF,&AF,&BF,&FE,&76,&32,&32,&33,&11,&00,&00,&00,&11,&77    ; &4EBC
        EQUB &FF,&77,&EF,&CF,&8F,&8F,&0F,&0F,&3F,&5F,&0F,&FF,&F0,&F0,&F0,&F0    ; &4ECC
        EQUB &F0,&F8,&00,&33,&FF,&FF,&FF,&FF,&EF,&FB,&7D,&7E,&3F,&1F,&0F,&0F    ; &4EDC
        EQUB &8F,&CF,&EF,&F3,&F1,&F0,&F0,&F0,&F1,&FF,&FF,&DE,&BC,&BC,&8F,&DF    ; &4EEC
        EQUB &6F,&BF,&9F,&9F,&CF,&CF,&6F,&6F,&3F,&1F,&0F,&CF,&F7,&F3,&EE,&88    ; &4EFC
        EQUB &88,&CC,&A6,&BF,&8F,&7F,&EE,&4C,&88,&00,&88,&88,&88,&88,&88,&88    ; &4F0C
        EQUB &CC,&FF,&6F,&1F,&CF,&67,&33,&00,&00,&00,&EE,&2E,&EE,&00,&00,&00    ; &4F1C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&88,&88,&88,&EE,&2E,&EE,&00,&00    ; &4F2C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&22    ; &4F3C
        EQUB &33,&31,&31,&33,&22,&77,&FC,&FF,&FF,&FF,&77,&CC,&E6,&E2,&EA,&EE    ; &4F4C
        EQUB &CC,&77,&FC,&F9,&FB,&FF,&77,&CC,&E6,&EE,&EE,&EE,&CC,&66,&BF,&0F    ; &4F5C
        EQUB &0F,&0F,&FF,&FB,&76,&33,&11,&11,&00,&00,&00,&FF,&8F,&0F,&0F,&FF    ; &4F6C
        EQUB &FB,&F4,&FB,&FA,&F5,&FA,&FD,&F9,&EA,&44,&BF,&0F,&0F,&3F,&FE,&FD    ; &4F7C
        EQUB &F2,&FD,&F2,&FD,&F2,&FD,&F9,&DD,&2F,&0F,&0F,&EF,&FB,&F5,&EA,&C4    ; &4F8C
        EQUB &CC,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11    ; &4F9C
        EQUB &33,&00,&00,&11,&33,&77,&67,&CF,&DF,&BF,&FF,&99,&99,&11,&33,&67    ; &4FAC
        EQUB &67,&CF,&DF,&FF,&DD,&99,&88,&44,&00,&00,&00,&00,&00,&00,&00,&00    ; &4FBC
        EQUB &11,&11,&11,&00,&00,&00,&33,&77,&EF,&FF,&33,&67,&CF,&8F,&8F,&0F    ; &4FCC
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&1F,&1F,&0F,&0F,&0F,&0F,&0F,&0F,&8F,&8F    ; &4FDC
        EQUB &8F,&CF,&77,&33,&32,&33,&11,&00,&77,&CF,&9F,&6E,&88,&00,&33,&EF    ; &4FEC
        EQUB &CF,&0F,&0F,&8F,&0F,&0F,&3F,&7E,&FC,&F8,&F9,&F9,&FD,&7F,&0F,&0F    ; &4FFC
        EQUB &7F,&F8,&F8,&F8,&FD,&7D,&7D,&7F,&2F,&2F,&0F,&0F,&0F,&FF,&F3,&F0    ; &500C
        EQUB &FF,&77,&EF,&3F,&8F,&EF,&67,&EF,&8F,&0F,&0F,&0F,&0F,&0F,&0F,&0F    ; &501C
        EQUB &EF,&F3,&F1,&FD,&FF,&FF,&EF,&CF,&0F,&0F,&5F,&EF,&8F,&8F,&8F,&0F    ; &502C
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&FF,&CC,&88,&DD,&7F,&6F,&0F,&1F    ; &503C
        EQUB &3F,&3F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&3F,&7E,&7C,&7D,&7F,&7F    ; &504C
        EQUB &3F,&1F,&0F,&0F,&5F,&BF,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F    ; &505C
        EQUB &0F,&0F,&FF,&11,&00,&FF,&8F,&2F,&FF,&99,&00,&88,&EE,&3F,&1F,&0F    ; &506C
        EQUB &0F,&0F,&0F,&0F,&EF,&F3,&F1,&F8,&FC,&FC,&FD,&FF,&0F,&0F,&7F,&F8    ; &507C
        EQUB &F8,&F8,&FD,&7D,&7D,&7F,&2F,&2F,&0F,&0F,&0F,&7F,&FE,&F8,&FF,&88    ; &508C
        EQUB &CC,&4C,&4C,&CC,&00,&00,&00,&88,&EE,&7F,&3F,&FF,&6E,&3F,&1F,&0F    ; &509C
        EQUB &8F,&8F,&8F,&8F,&8F,&0F,&0F,&0F,&4F,&CF,&8F,&8F,&8F,&0F,&0F,&0F    ; &50AC
        EQUB &0F,&0F,&0F,&1F,&3F,&EE,&E2,&E6,&CC,&00,&00,&00,&00,&00,&00,&00    ; &50BC
        EQUB &00,&00,&00,&00,&88,&CC,&66,&00,&88,&CC,&EE,&7F,&3F,&1F,&5F,&6F    ; &50CC
        EQUB &7F,&4C,&4C,&4C,&6E,&3F,&3F,&1F,&5F,&7F,&DD,&CC,&88,&99,&00,&00    ; &50DC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &50EC
        EQUB &00,&00,&00,&00,&00,&00,&00,&88,&88,&88,&88,&88,&88,&00,&00,&00    ; &50FC
        EQUB &00,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&33,&67,&CF    ; &510C
        EQUB &BF,&8F,&CF,&67,&33,&11,&11,&11,&11,&11,&11,&11,&11,&11,&00,&00    ; &511C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&33,&77,&77,&FF    ; &512C
        EQUB &FF,&FF,&FF,&7F,&0F,&0F,&0F,&8F,&0F,&0F,&3F,&FE,&F0,&F0,&F0,&F8    ; &513C
        EQUB &FC,&FF,&8F,&8F,&CF,&CF,&47,&47,&47,&67,&47,&77,&FF,&FF,&FF,&FF    ; &514C
        EQUB &FF,&FF,&FF,&FF,&FF,&FF,&1F,&3F,&3E,&7E,&7C,&FC,&F8,&F0,&F0,&F0    ; &515C
        EQUB &F0,&F1,&F3,&FF,&5D,&5D,&CC,&4C,&4C,&5D,&DD,&5D,&4C,&CC,&88,&CC    ; &516C
        EQUB &CC,&FF,&EF,&EF,&FF,&FF,&FD,&F9,&F3,&E3,&E3,&E3,&F3,&F1,&F0,&F0    ; &517C
        EQUB &F0,&F0,&F0,&FF,&0F,&0F,&1F,&BF,&9F,&DF,&BF,&9F,&3F,&EE,&00,&00    ; &518C
        EQUB &00,&00,&00,&88,&CC,&4C,&6E,&EE,&BF,&1F,&3F,&EE,&CC,&4C,&4C,&CC    ; &519C
        EQUB &C4,&C4,&C4,&C4,&CC,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&00    ; &51AC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &51BC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &51CC
        EQUB &00,&00,&00,&00,&11,&33,&23,&67,&77,&CF,&8F,&CF,&77,&33,&33,&23    ; &51DC
        EQUB &33,&32,&32,&32,&32,&33,&11,&11,&11,&11,&00,&00,&00,&00,&00,&00    ; &51EC
        EQUB &00,&00,&00,&11,&33,&33,&FF,&7F,&7F,&FF,&FF,&1F,&0F,&0F,&0F,&0F    ; &51FC
        EQUB &0F,&7F,&FC,&F0,&F0,&F0,&F0,&F0,&FF,&0F,&0F,&8F,&DF,&9F,&BF,&DF    ; &520C
        EQUB &9F,&CF,&77,&00,&00,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&3F    ; &521C
        EQUB &3E,&7E,&FC,&F8,&F0,&F0,&F0,&F0,&F0,&F0,&F8,&FC,&FF,&AB,&AB,&23    ; &522C
        EQUB &33,&23,&AB,&BB,&AB,&23,&33,&88,&CC,&CC,&EE,&EE,&FF,&FF,&FF,&FB    ; &523C
        EQUB &F3,&E3,&E7,&C7,&D7,&C7,&E7,&F3,&F1,&F0,&F0,&F0,&F1,&F3,&FF,&1F    ; &524C
        EQUB &1F,&1F,&3F,&2E,&2E,&2E,&EE,&2E,&EE,&00,&00,&00,&00,&00,&CC,&6E    ; &525C
        EQUB &3F,&DF,&1F,&3F,&6E,&CC,&88,&88,&88,&88,&88,&88,&88,&88,&88,&00    ; &526C
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&01,&77,&00,&00,&00    ; &527C
        EQUB &00,&01,&77,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&67    ; &528C
        EQUB &DF,&67,&33,&11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&FF,&F8,&FB    ; &529C
        EQUB &FD,&76,&33,&11,&11,&33,&76,&FD,&FB,&F8,&FF,&FF,&F0,&FF,&99,&FF    ; &52AC
        EQUB &F6,&F9,&F9,&F6,&FF,&99,&FF,&F0,&FF,&FF,&F1,&FD,&FB,&E6,&CC,&88    ; &52BC
        EQUB &88,&CC,&E6,&FB,&FD,&F1,&FF,&33,&76,&FD,&FC,&76,&33,&11,&00,&00    ; &52CC
        EQUB &FF,&F0,&FF,&F0,&F0,&F1,&FB,&EE,&44,&88,&CC,&E6,&E6,&CC,&88,&00    ; &52DC
        EQUB &00,&00,&FF,&F8,&FF,&74,&74,&75,&66,&00,&00,&00,&FF,&F0,&FF,&E2    ; &52EC
        EQUB &E2,&EA,&66,&00,&00,&00,&FF,&F0,&FF,&00,&00,&00,&00,&00,&11,&33    ; &52FC
        EQUB &FE,&F0,&FE,&33,&11,&00,&00,&FF,&F9,&F0,&F3,&F3,&F3,&F0,&F9,&FF    ; &530C
        EQUB &00,&00,&88,&CC,&C4,&C4,&C4,&CC,&88,&00,&00,&77,&67,&AF,&BF,&AF    ; &531C
        EQUB &BF,&AF,&AF,&BF,&AF,&67,&77,&EE,&2E,&7F,&9F,&3F,&DF,&1F,&1F,&FF    ; &532C
        EQUB &3F,&2E,&EE,&FF,&0F,&3F,&CF,&0F,&FF,&0F,&0F,&FF,&0F,&0F,&FF,&FF    ; &533C
        EQUB &0F,&CF,&3F,&0F,&8F,&7F,&0F,&CF,&3F,&0F,&FF,&FF,&0F,&0F,&FF,&0F    ; &534C
        EQUB &FF,&0F,&0F,&3F,&CF,&0F,&FF,&0F,&0F,&FF,&0F,&9F,&6F,&0F,&FF,&0F    ; &535C
        EQUB &0F,&FF,&11,&00,&00,&FF,&0F,&FF,&0F,&3F,&CF,&0F,&7F,&8F,&3F,&1F    ; &536C
        EQUB &1F,&CF,&77,&11,&FF,&0F,&EF,&1F,&CF,&3F,&0F,&EF,&1F,&CF,&77,&99    ; &537C
        EQUB &CC,&4C,&CC,&FF,&0F,&1F,&EF,&0F,&8F,&6F,&1F,&CF,&3F,&0F,&FF,&FF    ; &538C
        EQUB &0F,&FF,&0F,&FF,&FF,&0F,&FF,&0F,&FF,&0F,&FF,&FF,&0F,&8F,&7F,&0F    ; &539C
        EQUB &3F,&4F,&8F,&3F,&CF,&0F,&FF,&77,&DD,&CC,&00,&11,&11,&33,&67,&47    ; &53AC
        EQUB &CF,&9F,&9F,&9F,&AF,&EF,&23,&23,&33,&11,&00,&33,&CF,&FF,&00,&77    ; &53BC
        EQUB &FC,&FB,&FB,&FC,&7F,&0F,&9F,&9F,&AF,&3F,&2F,&3F,&1F,&0F,&0F,&0F    ; &53CC
        EQUB &8F,&FF,&1F,&8F,&FF,&00,&BB,&FE,&BF,&BF,&FE,&BF,&AF,&1F,&1F,&EF    ; &53DC
        EQUB &1F,&0F,&1F,&FF,&0F,&0F,&0F,&0F,&FF,&11,&AB,&BB,&11,&DD,&E6,&EA    ; &53EC
        EQUB &FB,&F7,&DF,&0F,&2F,&2F,&BF,&9F,&9F,&8F,&0F,&0F,&0F,&1F,&3F,&EE    ; &53FC
        EQUB &1F,&2F,&FF,&CC,&66,&66,&00,&00,&00,&88,&88,&CC,&4C,&6E,&2E,&2E    ; &540C
        EQUB &AE,&EE,&88,&88,&88,&00,&00,&88,&6E,&EE,&00,&00,&00,&00,&00,&00    ; &541C
        EQUB &00,&00,&00,&00,&11,&11,&33,&32,&32,&32,&32,&32,&33,&11,&11,&11    ; &542C
        EQUB &00,&00,&00,&77,&FC,&F9,&F9,&FD,&75,&EF,&8F,&FF,&00,&00,&00,&11    ; &543C
        EQUB &33,&32,&76,&74,&FF,&CF,&CF,&C7,&C7,&E7,&F7,&C4,&C4,&C4,&E6,&E2    ; &544C
        EQUB &F3,&F9,&FF,&23,&EF,&EB,&E3,&FF,&11,&BB,&EF,&CF,&EF,&BB,&00,&33    ; &545C
        EQUB &EF,&CF,&F3,&E6,&CC,&88,&88,&88,&7F,&7C,&7E,&FB,&FB,&F9,&FB,&EB    ; &546C
        EQUB &FB,&74,&23,&EF,&0F,&0F,&0F,&0F,&0F,&0F,&8F,&FF,&6E,&3F,&3E,&FF    ; &547C
        EQUB &00,&FF,&1F,&1F,&FF,&00,&00,&00,&11,&33,&EF,&E3,&E7,&FD,&FD,&F9    ; &548C
        EQUB &FD,&7D,&FD,&E2,&4C,&7F,&0F,&0F,&1F,&1F,&1F,&1F,&1F,&FF,&77,&FC    ; &549C
        EQUB &F1,&FF,&00,&00,&00,&00,&00,&00,&00,&00,&EE,&2E,&2E,&2E,&2E,&6E    ; &54AC
        EQUB &88,&00,&00,&00,&00,&00,&00,&88,&CC,&EA,&EA,&F3,&F2,&F3,&F3,&F3    ; &54BC
        EQUB &F3,&E7,&EF,&33,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &54CC
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&CC,&E6,&E2    ; &54DC
        EQUB &E2,&E6,&C4,&EE,&2E,&EE,&EA,&EA,&FB,&F9,&FC,&77,&75,&75,&FD,&F9    ; &54EC
        EQUB &F3,&EE,&EA,&FB,&EB,&F9,&FC,&FF,&AE,&AE,&FF,&FC,&F9,&EB,&FB,&EA    ; &54FC
        EQUB &75,&FD,&3F,&9F,&D7,&DF,&57,&57,&DF,&D7,&9F,&3F,&FD,&75,&FF,&F8    ; &550C
        EQUB &FC,&77,&23,&23,&33,&DD,&BF,&FC,&F9,&EB,&FB,&EA,&FF,&F1,&F3,&EE    ; &551C
        EQUB &4C,&6E,&3F,&9F,&9F,&9F,&3F,&7D,&FD,&75,&00,&33,&76,&FC,&F8,&F8    ; &552C
        EQUB &F8,&F8,&F8,&F8,&F8,&FC,&76,&33,&00,&00,&00,&00,&33,&FF,&F8,&F0    ; &553C
        EQUB &F3,&F3,&F3,&F3,&F3,&F3,&F3,&F3,&F3,&F0,&F8,&FF,&33,&76,&FC,&FF    ; &554C
        EQUB &FF,&F0,&F0,&FF,&FF,&F0,&F0,&FE,&FE,&F0,&F0,&F0,&F0,&F0,&F0,&F1    ; &555C
        EQUB &F3,&EE,&88,&FF,&F0,&F0,&FB,&FB,&F3,&F3,&F3,&F3,&F3,&F3,&F3,&F0    ; &556C
        EQUB &F0,&FF,&88,&00,&00,&00,&FF,&F0,&F0,&FF,&FF,&F1,&F1,&FF,&FE,&F7    ; &557C
        EQUB &F3,&F1,&F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0,&F0,&F9,&F9,&F9    ; &558C
        EQUB &F1,&F1,&F1,&F9,&F9,&F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0,&FF    ; &559C
        EQUB &FF,&F8,&F8,&FF,&FF,&F8,&F8,&F8,&F0,&F0,&FF,&00,&00,&00,&00,&FF    ; &55AC
        EQUB &F0,&F0,&F8,&FC,&FC,&FC,&FC,&FC,&FC,&FC,&FC,&F0,&F0,&FF,&00,&00    ; &55BC
        EQUB &00,&00,&FF,&F0,&F0,&FC,&FC,&FD,&FF,&FF,&FF,&FD,&FC,&FC,&F0,&F0    ; &55CC
        EQUB &FF,&00,&00,&00,&00,&FF,&F0,&F0,&F6,&FE,&FC,&F8,&F0,&F8,&FC,&FE    ; &55DC
        EQUB &F6,&F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0,&F3,&F3,&F3,&F3,&F3    ; &55EC
        EQUB &F3,&F0,&F3,&F3,&F0,&F0,&FF,&00,&00,&00,&00,&CC,&F7,&F1,&F0,&F0    ; &55FC
        EQUB &F0,&F0,&F0,&F0,&F0,&F0,&F0,&F1,&F7,&CC,&00,&00,&00,&00,&00,&00    ; &560C
        EQUB &88,&CC,&C4,&C4,&C4,&C4,&C4,&C4,&C4,&CC,&88,&00,&00,&00,&00,&00    ; &561C
        EQUB &00,&11,&00,&00,&00,&11,&11,&33,&76,&74,&74,&74,&76,&33,&11,&FF    ; &562C
        EQUB &FF,&FF,&FF,&F9,&F9,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&FF,&00,&88    ; &563C
        EQUB &00,&00,&00,&88,&88,&CC,&E6,&E2,&E2,&E2,&E6,&CC,&88,&00,&00,&FF    ; &564C
        EQUB &F8,&FF,&00,&00,&00,&00,&FF,&F8,&FF,&00,&00,&F9,&F9,&F9,&FF,&F9    ; &565C
        EQUB &F9,&F9,&F9,&F9,&F9,&FF,&F9,&F9,&F9,&00,&00,&FF,&F1,&FF,&00,&00    ; &566C
        EQUB &00,&00,&FF,&F1,&FF,&00,&00,&11,&00,&00,&00,&11,&11,&32,&75,&66    ; &567C
        EQUB &88,&00,&88,&DD,&77,&FB,&F1,&E2,&CC,&00,&00,&00,&88,&CC,&EE,&88    ; &568C
        EQUB &00,&88,&CC,&44,&00,&00,&00,&11,&67,&8F,&8F,&8F,&8F,&8F,&67,&11    ; &569C
        EQUB &00,&FF,&0F,&3C,&1E,&0F,&0F,&0F,&0F,&FF,&66,&88,&6E,&1F,&97,&97    ; &56AC
        EQUB &1F,&1F,&6E,&88,&00,&0A,&FD,&08,&01,&FD,&00,&0A,&FD,&08,&02,&FD    ; &56BC
        EQUB &00,&0A,&FD,&08,&03,&FD,&00,&0A,&FD,&08,&04,&FD,&00,&09,&FD,&08    ; &56CC
        EQUB &05,&FD,&00,&09,&FD,&08,&06,&FD,&00,&09,&FD,&08,&07,&FD,&00,&09    ; &56DC
        EQUB &FD,&08,&08,&FD,&00,&0C,&FD,&09,&04,&FD,&00,&0B,&FD,&09,&08,&FD    ; &56EC
        EQUB &00,&15,&00,&00,&15,&03,&00,&15,&00,&00,&3E,&03,&00,&15,&00,&00    ; &56FC
        EQUB &3F,&03,&00,&15,&00,&00,&40,&03,&00,&15,&00,&00,&41,&03,&00,&15    ; &570C
        EQUB &00,&00,&42,&03,&00,&18,&00,&00,&1A,&01,&00,&1B,&04,&00,&1C,&07    ; &571C
        EQUB &00,&1B,&0A,&00,&1C,&0D,&00,&19,&10,&00,&18,&00,&00,&1A,&01,&00    ; &572C
        EQUB &1A,&04,&00,&1B,&07,&00,&1B,&0A,&00,&1C,&0D,&00,&1B,&10,&00,&1A    ; &573C
        EQUB &13,&00,&19,&16,&00,&18,&00,&00,&1B,&01,&00,&1C,&04,&00,&1C,&07    ; &574C
        EQUB &00,&1A,&0A,&00,&1B,&0D,&00,&1A,&10,&00,&1A,&13,&00,&19,&16,&00    ; &575C
        EQUB &18,&00,&00,&1A,&01,&00,&1A,&04,&00,&1A,&07,&00,&1B,&0A,&00,&1A    ; &576C
        EQUB &0D,&00,&1C,&10,&00,&1A,&13,&00,&1A,&16,&00,&1B,&19,&00,&1A,&1C    ; &577C
        EQUB &00,&1A,&1F,&00,&19,&22,&00,&18,&00,&00,&1C,&01,&00,&1B,&04,&00    ; &578C
        EQUB &19,&07,&00,&18,&00,&00,&1A,&01,&00,&19,&04,&00,&1F,&00,&00,&20    ; &579C
        EQUB &00,&06,&21,&00,&14,&1F,&00,&00,&20,&00,&06,&20,&00,&14,&21,&00    ; &57AC
        EQUB &22,&1F,&00,&00,&20,&00,&06,&20,&00,&14,&20,&00,&22,&21,&00,&30    ; &57BC
        EQUB &1F,&00,&00,&20,&00,&06,&20,&00,&14,&20,&00,&22,&20,&00,&30,&21    ; &57CC
        EQUB &00,&3E,&11,&00,&00,&11,&04,&00,&11,&00,&00,&4E,&04,&00,&11,&00    ; &57DC
        EQUB &00,&4F,&04,&00,&11,&00,&00,&50,&04,&00,&11,&00,&00,&51,&04,&00    ; &57EC
        EQUB &11,&00,&00,&52,&04,&00,&00,&00,&00,&00,&00,&19,&00,&00,&00,&54    ; &57FC
        EQUB &00,&19,&00,&00,&00,&55,&00,&19,&24,&00,&00,&24,&00,&0E,&24,&00    ; &580C
        EQUB &00,&57,&00,&0E,&24,&00,&00,&58,&00,&0E,&24,&00,&00,&59,&00,&0E    ; &581C
        EQUB &22,&03,&1A    ; &582C
Runtime_1FFD_SourceEnd:
; -----------------------------------------------------------------------------
; &582F: Relocated by Bootstrap: &582F-&592E -> runtime &0A00-&0AFF (MODE 1 lookup table).
; -----------------------------------------------------------------------------
Runtime_0A00_Source:
        EQUB &FF,&EE,&DD,&CC,&BB,&AA,&99,&88,&77,&66,&55,&44,&33,&22,&11,&00    ; &582F
        EQUB &EE,&EE,&CC,&CC,&AA,&AA,&88,&88,&66,&66,&44,&44,&22,&22,&00,&00    ; &583F
        EQUB &DD,&CC,&DD,&CC,&99,&88,&99,&88,&55,&44,&55,&44,&11,&00,&11,&00    ; &584F
        EQUB &CC,&CC,&CC,&CC,&88,&88,&88,&88,&44,&44,&44,&44,&00,&00,&00,&00    ; &585F
        EQUB &BB,&AA,&99,&88,&BB,&AA,&99,&88,&33,&22,&11,&00,&33,&22,&11,&00    ; &586F
        EQUB &AA,&AA,&88,&88,&AA,&AA,&88,&88,&22,&22,&00,&00,&22,&22,&00,&00    ; &587F
        EQUB &99,&88,&99,&88,&99,&88,&99,&88,&11,&00,&11,&00,&11,&00,&11,&00    ; &588F
        EQUB &88,&88,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00    ; &589F
        EQUB &77,&66,&55,&44,&33,&22,&11,&00,&77,&66,&55,&44,&33,&22,&11,&00    ; &58AF
        EQUB &66,&66,&44,&44,&22,&22,&00,&00,&66,&66,&44,&44,&22,&22,&00,&00    ; &58BF
        EQUB &55,&44,&55,&44,&11,&00,&11,&00,&55,&44,&55,&44,&11,&00,&11,&00    ; &58CF
        EQUB &44,&44,&44,&44,&00,&00,&00,&00,&44,&44,&44,&44,&00,&00,&00,&00    ; &58DF
        EQUB &33,&22,&11,&00,&33,&22,&11,&00,&33,&22,&11,&00,&33,&22,&11,&00    ; &58EF
        EQUB &22,&22,&00,&00,&22,&22,&00,&00,&22,&22,&00,&00,&22,&22,&00,&00    ; &58FF
        EQUB &11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00    ; &590F
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00    ; &591F
Runtime_0A00_SourceEnd:
; -----------------------------------------------------------------------------
; &592F: Relocated by Bootstrap: &592F-&5C26 -> runtime &0507-&07FE (sound/level data region).
; -----------------------------------------------------------------------------
Runtime_0507_Source:
        EQUB &21,&21,&29,&31,&36,&22,&29,&36,&21,&20,&29,&36,&22,&29,&35,&3D    ; &592F
        EQUB &41,&45,&4A,&36,&3D,&4A,&28,&28,&2C,&30,&34,&4A,&35,&34,&3D,&48    ; &593F
        EQUB &48,&45,&49,&4D,&52,&3D,&3C,&45,&52,&30,&34,&30,&38,&3C,&52,&3D    ; &594F
        EQUB &3C,&45,&50,&54,&58,&41,&34,&3D,&36,&34,&16,&14,&1A,&18,&1E,&1C    ; &595F
        EQUB &20,&1C,&20,&25,&2C,&A5,&0F,&3D,&0D,&1B,&49,&19,&0D,&3D,&0D,&19    ; &596F
        EQUB &49,&19,&3D,&0D,&2B,&51,&29,&09,&59,&09,&0D,&3D,&29,&21,&0D,&19    ; &597F
        EQUB &21,&15,&6D,&0F,&6D,&0D,&1B,&55,&19,&0D,&51,&0D,&19,&51,&19,&49    ; &598F
        EQUB &0D,&2B,&51,&29,&09,&59,&09,&0D,&3D,&29,&23,&1B,&15,&D9,&23,&0D    ; &599F
        EQUB &11,&17,&31,&2D,&29,&11,&0D,&1D,&21,&0D,&15,&1D,&23,&0D,&11,&17    ; &59AF
        EQUB &31,&2D,&29,&21,&1D,&15,&0D,&15,&19,&1D,&23,&0D,&15,&21,&29,&2D    ; &59BF
        EQUB &31,&37,&31,&35,&3B,&35,&39,&23,&1D,&19,&15,&33,&2D,&29,&11,&0D    ; &59CF
        EQUB &1D,&21,&3C,&3D,&44,&BD,&5D,&48,&51,&48,&3D,&AF,&44,&45,&52,&50    ; &59DF
        EQUB &54,&59,&50,&46,&41,&3C,&44,&3C,&51,&40,&45,&37,&E7,&43,&54,&08    ; &59EF
        EQUB &0A,&30,&00,&4D,&38,&33,&BC,&7B,&7E,&4C,&30,&69,&30,&33,&70,&17    ; &59FF
        EQUB &BC,&A7,&BC,&00,&4B,&18,&A8,&2E,&7B,&2F,&5B,&BB,&09,&3D,&BC,&2A    ; &5A0F
        EQUB &2A,&2F,&14,&7D,&A8,&7D,&69,&7D,&4C,&7D,&00,&46,&F8,&08,&2F,&28    ; &5A1F
        EQUB &7C,&28,&2F,&2D,&76,&32,&6F,&37,&66,&3C,&5D,&4B,&7C,&4F,&91,&53    ; &5A2F
        EQUB &A6,&5F,&A6,&63,&91,&7A,&7D,&80,&8A,&86,&98,&8D,&A6,&94,&B3,&80    ; &5A3F
        EQUB &77,&86,&6C,&8D,&60,&94,&53,&94,&2E,&A6,&BB,&A6,&7D,&A6,&2E,&3C    ; &5A4F
        EQUB &7C,&5F,&89,&4F,&74,&53,&89,&63,&74,&67,&7C,&41,&95,&BB,&3B,&2F    ; &5A5F
        EQUB &49,&2F,&57,&BB,&66,&2F,&77,&2F,&77,&BB,&57,&9E,&0C,&09,&7C,&15    ; &5A6F
        EQUB &09,&BB,&28,&BB,&00,&4C,&40,&3E,&42,&51,&76,&55,&8B,&59,&A0,&60    ; &5A7F
        EQUB &8B,&96,&38,&64,&76,&5C,&A0,&29,&A8,&54,&0A,&92,&3E,&92,&29,&92    ; &5A8F
        EQUB &7B,&92,&0A,&A8,&84,&2B,&68,&38,&0A,&37,&29,&37,&4D,&37,&7B,&38    ; &5A9F
        EQUB &00,&FF,&4A,&54,&08,&07,&38,&00,&4D,&41,&6F,&2F,&64,&89,&16,&90    ; &5AAF
        EQUB &7D,&2A,&42,&57,&2F,&28,&48,&E6,&2A,&CD,&00,&4B,&20,&05,&90,&34    ; &5ABF
        EQUB &42,&87,&17,&86,&94,&09,&5F,&D5,&12,&04,&BC,&21,&A2,&00,&46,&30    ; &5ACF
        EQUB &00,&BB,&50,&71,&34,&89,&41,&45,&6E,&60,&7A,&17,&09,&1A,&16,&0A    ; &5ADF
        EQUB &00,&37,&0B,&43,&D4,&5C,&15,&69,&26,&BB,&2F,&58,&47,&1B,&72,&D7    ; &5AEF
        EQUB &79,&AF,&75,&9A,&7A,&79,&03,&90,&2B,&71,&69,&17,&AD,&22,&79,&12    ; &5AFF
        EQUB &90,&27,&92,&19,&BB,&35,&B5,&41,&AE,&4D,&A8,&39,&1B,&59,&1C,&5C    ; &5B0F
        EQUB &28,&5F,&34,&62,&40,&6C,&79,&6C,&A1,&84,&94,&37,&28,&33,&42,&35    ; &5B1F
        EQUB &35,&19,&CB,&16,&D7,&1F,&A1,&00,&4C,&68,&15,&44,&50,&AF,&4A,&20    ; &5B2F
        EQUB &35,&64,&29,&96,&50,&4C,&6E,&3B,&79,&B2,&80,&8A,&6E,&7C,&0E,&96    ; &5B3F
        EQUB &23,&7C,&7D,&3B,&21,&16,&99,&42,&4B,&2F,&1A,&1C,&2B,&0A,&64,&7D    ; &5B4F
        EQUB &0B,&72,&67,&00,&FF,&47,&54,&08,&06,&3A,&00,&4D,&50,&40,&94,&0F    ; &5B5F
        EQUB &B0,&1F,&91,&2E,&4A,&99,&1F,&B0,&90,&21,&4A,&4F,&1F,&85,&1F,&7D    ; &5B6F
        EQUB &C8,&00,&4B,&20,&0D,&90,&57,&6F,&8A,&C2,&B6,&8F,&21,&18,&6D,&13    ; &5B7F
        EQUB &6D,&5A,&D1,&24,&16,&22,&19,&B0,&7C,&8C,&45,&28,&8F,&1F,&00,&46    ; &5B8F
        EQUB &A0,&06,&AF,&0F,&AF,&18,&AF,&1F,&90,&16,&90,&0C,&90,&2E,&49,&3B    ; &5B9F
        EQUB &49,&45,&52,&3B,&5C,&85,&1E,&8E,&1E,&99,&1E,&99,&71,&A2,&71,&98    ; &5BAF
        EQUB &80,&A4,&8F,&97,&8F,&7D,&C7,&A2,&1E,&59,&6E,&5A,&7D,&41,&28,&8D    ; &5BBF
        EQUB &1A,&33,&1C,&3F,&1E,&49,&41,&27,&57,&D0,&6E,&B9,&6E,&C7,&9C,&AF    ; &5BCF
        EQUB &32,&56,&6F,&A2,&62,&72,&1E,&45,&66,&7B,&8B,&B0,&8F,&1B,&4F,&1E    ; &5BDF
        EQUB &22,&DA,&24,&15,&14,&02,&39,&3C,&93,&1E,&4F,&A7,&3C,&DA,&82,&DF    ; &5BEF
        EQUB &00,&4C,&30,&22,&AB,&4F,&AB,&2E,&1A,&72,&2B,&95,&B0,&A9,&33,&19    ; &5BFF
        EQUB &57,&32,&81,&4E,&3C,&9D,&12,&2C,&8F,&82,&94,&2B,&06,&56,&41,&3A    ; &5C0F
        EQUB &6E,&60,&9D,&56,&9F,&56,&00,&FF    ; &5C1F
Runtime_0507_SourceEnd:
; -----------------------------------------------------------------------------
; &5C27: Relocated by Bootstrap: &5C27-&5C4A -> runtime &0880-&08A3 (high-score table).
; -----------------------------------------------------------------------------
Runtime_0880_Source:
        EQUB &76,&26,&6F,&00,&01,&00,&4E,&49,&4B,&00,&01,&00,&42,&4F,&46,&00    ; &5C27
        EQUB &01,&00,&43,&41,&50,&00,&01,&00,&50,&41,&4D,&00,&01,&00,&44,&43    ; &5C37
        EQUB &45,&00,&01,&00    ; &5C47

Runtime_0880_SourceEnd:

EndOfImage:
; Expected exact size: &2D4B bytes (11595). At the default origin &2F00 this
; occupies &2F00-&5C4A inclusive and must match the verified baseline hash.
; VERIFY.txt contains the canonical SHA-256 for the runnable payload.
