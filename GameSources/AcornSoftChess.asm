ENTRY GameEntry
ORG &0E00
RUNTIME_BASE=*
; =============================================================================
; Acornsoft CHESS V2 (1983) - direct-runtime recovered source
; Authors: Arthur Norman and Nick Pelling (credited by the original CHESS2 program)
; =============================================================================
;
; DEVELOPMENT / RUNNABLE ADDRESS MODEL
; ------------------------------------
; This is the normal source to modify and run with the BBC 6502 Web Assembler.
; The permanent chess engine is assembled directly at its true runtime address &0E00.
; There is no historical high-memory file staging address and no self-relocation copy.
;
; The web assembler's generated BASIC loader already moves the compiled flat image to
; its assembled origin before entering GameEntry.  The loader metadata below selects
; the cassette filing system before that move, because the permanent engine occupies
; RAM that DFS normally uses when PAGE=&1900.
;
; GameEntry is temporary startup code placed directly at MoveArenaBase, immediately
; after the permanent engine.  This makes the assembled program one contiguous segment
; beginning at &0E00, which is exactly what the web assembler's normal boot mover wants.
;
; MoveArenaBase is reclaimable runtime workspace.  The startup module deliberately lives
; there only until it jumps to ChessRuntimeEntry; subsequent move generation or file load
; operations overwrite it.  No startup routine returns to this transient code.
;
; The fixed save/history workspace remains at &5300-&57FF and is not part of the emitted
; program image.
;
; Source metadata for Save boot disk / Feeling Lucky:
; @basic *TAPE
; @basic *FX15,1
;
; CORE CHESS REPRESENTATION
; -------------------------
; * Board: 10x12 mailbox at &0400.
; * 32 piece slots: 0-15 White, 16-31 Black; piece type values are
;   0 king, 2 queen, 4 rook, 6 bishop, 8 knight, 10 pawn.
; * Search uses signed 24-bit negamax alpha-beta with legal-move filtering,
;   move ordering and selective capture/check extensions.
; * Normal move records are 5 bytes; mate-solver records are 4 bytes.
;
; The source retains the semantic labels/comments recovered from the commercial
; program.  Fixed MOS, hardware and deliberately fixed workspace addresses remain
; equates; program-internal code/data references are label based.
; =============================================================================

; MOS entry points / vectors
OSFIND = &FFCE
OSBGET = &FFD7
OSFILE = &FFDD
OSRDCH = &FFE0
OSASCI = &FFE3
OSNEWL = &FFE7
OSWRCH = &FFEE
OSWORD = &FFF1
OSBYTE = &FFF4
OSCLI = &FFF7
BRKV = &0202
IRQ1V = &0204
EVNTV = &0220

; Major RAM structures
MailboxBoard              = &0400
SearchUndoStack           = &0480       ; four bytes per search ply
SaveImageBase             = &5300       ; fixed high-RAM save/workspace base
GameHistoryFrom           = SaveImageBase+&100
GameHistoryTo             = SaveImageBase+&200
GameHistoryAux            = SaveImageBase+&300
GameHistoryFlags          = SaveImageBase+&400
PieceTypeArray            = &49         ; 32 slots
PieceSquareArray          = &69         ; 32 slots

; Zero-page chess/search state
SkillLevel                = &0E
MoveRecordSize            = &0F
SearchPly                 = &10
LastMoveToSquare          = &11
SideToMove                = &15         ; 0=White, &10=Black
MoveFramePtrLo            = &16
MoveFramePtrHi            = &17
MoveListStartLo           = &18
MoveListStartHi           = &19
MoveIteratorLo            = &1A
MoveIteratorHi            = &1B
SearchBetaLo              = &1C
SearchBetaMid             = &1D
SearchBetaHi              = &1E
SearchAlphaLo             = &1F
SearchAlphaMid            = &20
SearchAlphaHi             = &21
BestMovePtrLo             = &22
BestMovePtrHi             = &23
PreferredReplyState       = &24
PreferredReplyFrom        = &25
PreferredReplyTo          = &26
PreferredReplyAux         = &27
ChildScoreLo              = &28
ChildScoreMid             = &29
ChildScoreHi              = &2A
PlyCountLo                = &2C
PlyCountHi                = &2D
PositionScoreLo           = &2E
PositionScoreMid          = &2F
PositionScoreHi           = &30
MoveFromSquare            = &31
MoveToSquare              = &32
MoveAux                   = &33
MoveFlags                 = &34
SearchNodeCountLo         = &35
SearchNodeCountHi         = &36
MoveListEndLo             = &37
MoveListEndHi             = &38
AttackTargetSquare        = &42
EnPassantTargetSquare     = &89
EnPassantPawnSlot         = &8A
CastlingRights            = &8B

; Persistent/UI state
GameSideToMove            = &0637
SearchAbortFlag           = &0639
GameType                  = &063A       ; 0 PvP, 1 player White, 2 player Black, 3 auto
ClockTickPending          = &063B
TickSoundOffFlag          = &063C       ; 0=on, negative=off
EditorCursorSquare        = &065B
HistoryBaseSide           = &0668
MateDepthLimit            = &0669       ; editor values 2..5
EditorSideToMove          = &066A
EditorLegalSideMask       = &066B       ; bit7 White legal-to-move, bit6 Black
BoardConsistencyCheckFlag = &066D       ; normally zero; dormant diagnostic path
ModernMOSEventFlag        = &0676       ; negative => MOS event API available
GamePlyCountLo            = &0672
GamePlyCountHi            = &0673
CursorOffFlag             = &0674       ; 0=on, negative=off
JoysticksOffFlag          = &0675       ; 0=on, negative=off
ResumeGameAvailableFlag   = &0677       ; negative when resumable position exists
EditorPositionInvalidFlag = &0678       ; negative prevents main-menu Restart
SavedCastlingRights       = &067A
EditorCastlingRights      = &067B
MateSearchDepth           = &067E
FiftyMovePlyCounter       = &067F
EditorModeActiveFlag      = &0680
MateSearchPly             = &0681
SavedEnPassantTarget      = &0682
SideEngineStateBase       = &06C0       ; two 16-byte blocks, indexed by side base 0/&10
SideStatePhaseOffset       = &00
SideStateOpeningBookOffset = &0A
SideStatePhasePlyOffset    = &0B
GamePhaseBySide            = SideEngineStateBase+SideStatePhaseOffset
OpeningBookCursorBySide    = SideEngineStateBase+SideStateOpeningBookOffset
PhaseTransitionPlyBySide   = SideEngineStateBase+SideStatePhasePlyOffset
WhiteClockSnapshot        = &06E0
BlackClockSnapshot        = &06F0
HistoryBasePieceSquares   = &073A
HistoryBasePieceTypes     = &075B
ResumePieceSquares        = &07BE
ResumePieceTypes          = &07DF

; -----------------------------------------------------------------------------
; Recovered chess constants
; -----------------------------------------------------------------------------
SIDE_WHITE                 = &00
SIDE_BLACK                 = &10
SIDE_SLOT_MASK             = &10
PIECE_KING                 = &00
PIECE_QUEEN                = &02
PIECE_ROOK                 = &04
PIECE_BISHOP               = &06
PIECE_KNIGHT               = &08
PIECE_PAWN                 = &0A
PIECE_INACTIVE             = &80
MAILBOX_OFFBOARD           = &80
MAILBOX_EMPTY              = &FF
MOVE_CAPTURE_MASK          = &1F
MOVE_PROMOTION_MASK        = &E0
MOVE_ENPASSANT_MASK        = &0F
MOVE_SPECIAL_MASK          = &F0
MOVE_DOUBLE_PAWN_FLAG      = &F0
MOVE_RECORD_BYTES          = &05
MATE_MOVE_RECORD_BYTES     = &04
MOVE_FRAME_HEADER_BYTES    = &10
CASTLE_WHITE_QUEENSIDE     = &10
CASTLE_WHITE_KINGSIDE      = &20
CASTLE_BLACK_QUEENSIDE     = &40
CASTLE_BLACK_KINGSIDE      = &80
CASTLE_WHITE_BOTH          = &30
CASTLE_BLACK_BOTH          = &C0
CASTLE_ALL                 = &F0
SQ_A1                      = &15
SQ_C1                      = &17
SQ_D1                      = &18
SQ_E1                      = &19
SQ_F1                      = &1A
SQ_G1                      = &1B
SQ_H1                      = &1C
SQ_A8                      = &5B
SQ_C8                      = &5D
SQ_D8                      = &5E
SQ_E8                      = &5F
SQ_F8                      = &60
SQ_G8                      = &61
SQ_H8                      = &62
GAME_PVP                   = &00
GAME_HUMAN_WHITE           = &01
GAME_HUMAN_BLACK           = &02
GAME_AUTOPLAY              = &03
PHASE_OPENING              = &00
PHASE_EARLY_MIDDLE         = &01
PHASE_MIDDLE               = &02
PHASE_ENDGAME              = &03
NO_PHASE_TRANSITION         = &FF
PIECE_SLOT_INDEX_MASK       = &0F
EDITOR_BLACK_LEGAL          = &40
EDITOR_WHITE_LEGAL          = &80
EDITOR_BOTH_LEGAL           = &C0
EVENT_INTERVAL_TIMER        = &05
EVENT_ESCAPE                = &06
DECIMAL_TEN                 = &0A
VDU_LF                      = &0A
PIECE_SLOT_COUNT             = &20
PIECE_SLOT_LAST              = PIECE_SLOT_COUNT-1
INFO_TEXT_BYTES              = &3C
SAVE_SIGNATURE_CHECK_BYTES   = &0E       ; loaders compare "(c) Acornsoft " and ignore year
DRAW_SQUARE_INDEX_BIAS       = &0B       ; DrawMailboxSquare subtracts this, lookup adds it back
MAILBOX_PLAYABLE_FILL_BIAS   = &12       ; Y-index bias used while clearing the eight playable files

; Additional state recovered in the final semantic pass.
ActiveClockSideOffset      = &0606       ; 0=White clock block, &10=Black clock block
CurrentTextWindowId        = &066E       ; remembered UI window for RestoreActiveTextWindow
EngineStopFlag             = &2B         ; normally cleared; nonzero causes search/game path to stop
                                             ; producer is not statically identified, so name remains conservative


; -----------------------------------------------------------------------------
; Final recovered workspace / UI aliases
; -----------------------------------------------------------------------------
InlineTextPtrLo             = &12         ; PrintInline return/text pointer
InlineTextPtrHi             = &13
RandomState0                = &8C         ; three-byte PRNG state, also stirred while waiting for input
RandomState1                = &8D
RandomState2                = &8E
SecondProcessorFlag         = &066C       ; negative when OSBYTE &82 reports Tube address 0000
                                           ; used only to alter cursor/flash timing
ClockMinutesBase            = &0600       ; indexed by ActiveClockSideOffset (0 or &10)
ClockSecondsBase            = &0601
ClockHoursBase              = &0602
IntervalTimerPawnWorkspace  = &0617       ; 5-byte OSWORD 3/4 timer block; evaluator reuses
                                           ; bytes +1..+8 as pawn-file counters
DoubledPawnFileCount        = &0636
FlashCycleCount             = &065C
BoardSquareColourXor        = &065E       ; XORs board-square parity while flashing
FlashingSquare              = &065F       ; mailbox square currently being flashed/redrawn
CursorFlashXorMask          = &0660       ; initialised to 1; toggles BoardSquareColourXor
SavedTextCursorY            = &0666
SavedTextCursorX            = &0667
LengthPrefixedStringLength  = &066F
MenuItemIndex               = &0679       ; temporary menu/editor list index
Joystick1MailboxSquare       = &0652       ; ADC channels 1/2 converted to 10x12 mailbox coordinate
Joystick2MailboxSquare       = &0654       ; ADC channels 3/4 converted to 10x12 mailbox coordinate
Joystick1FireState           = &0656       ; bit 7 marks stable/debounced state; clear on new transition
Joystick2FireState           = &0657
BlackClockMinutesBase        = ClockMinutesBase+SIDE_BLACK       ; Black clock block mirrors &0600..&0602
BlackClockSecondsBase        = ClockSecondsBase+SIDE_BLACK
BlackClockHoursBase          = ClockHoursBase+SIDE_BLACK
MOSParameterBlock            = &063D       ; shared 18-byte MOS workspace (OSFILE/OSWORD/sound)
LineInputBufferLo            = &063D       ; OSWORD 0 line-input block overlay
LineInputBufferHi            = &063E
LineInputMaxLength           = &063F
LineInputMinChar             = &0640
LineInputMaxChar             = &0641
MenuItemRightEdgeX           = &0671       ; right-alignment anchor for menu value strings
SnapshotPieceSquares         = &077C       ; temporary live-position snapshot
SnapshotPieceTypes           = &079D
GameInformationText          = &0500       ; 60-byte saved-game description
BoardInformationText         = GameInformationText+&50       ; 60-byte editor-board description
SearchUndoToBase             = SearchUndoStack+1       ; +4 per ply
SearchUndoAuxBase            = SearchUndoStack+2
SearchUndoFlagsBase          = SearchUndoStack+3
PreviousUndoAuxBase          = SearchUndoStack-2       ; previous move aux when indexed by 4*SearchPly
MailboxA1                    = MailboxBoard+SQ_A1
MailboxD1                    = MailboxBoard+SQ_D1
MailboxF1                    = MailboxBoard+SQ_F1
MailboxH1                    = MailboxBoard+SQ_H1
MailboxA8                    = MailboxBoard+SQ_A8
MailboxD8                    = MailboxBoard+SQ_D8
MailboxF8                    = MailboxBoard+SQ_F8
MailboxH8                    = MailboxBoard+SQ_H8
BlackGamePhase               = GamePhaseBySide+SIDE_BLACK
BlackOpeningBookCursor       = OpeningBookCursorBySide+SIDE_BLACK

; MOS/hardware locations used by the old-OS compatibility path.
SYSVIA_IFR                   = &FE4D
USERVIA_T1CL                 = &FE64
USERVIA_T1CH                 = &FE65
USERVIA_ACR                  = &FE6B
USERVIA_IER                  = &FE6E
MOSParameterBlockLoByte      = <MOSParameterBlock
MOSParameterBlockHiByte      = >MOSParameterBlock
MailboxB1                    = MailboxBoard+&16
MailboxC1                    = MailboxBoard+SQ_C1
MailboxG1                    = MailboxBoard+SQ_G1
MailboxB8                    = MailboxBoard+&5C
MailboxC8                    = MailboxBoard+SQ_C8
MailboxG8                    = MailboxBoard+SQ_G8
BlackKingSquare              = PieceSquareArray+SIDE_BLACK         ; PieceSquareArray + SIDE_BLACK

; Contextual scratch aliases used only in the routines named by their prefixes.
MoveSortSpanLo               = &40
MoveSortSpanHi               = &41
MoveSortLeftLo               = &3C
MoveSortLeftHi               = &3D
MoveSortSourceLo             = &3E
MoveSortSourceHi             = &3F
MoveSortGapLo                = &46
MoveSortGapHi                = &47
MoveSortRightLo              = &42
MoveSortRightHi              = &43
CaptureWritePtrLo            = &3B
CaptureWritePtrHi            = &3C
PreferredMovePtrLo           = &07
PreferredMovePtrHi           = &08
ReturnedBestMovePtrLo        = &0A
ReturnedBestMovePtrHi        = &0B
IndirectCallbackPtrLo         = &0A
IndirectCallbackPtrHi         = &0B
InlineOSFileReturnPtrLo       = &07
InlineOSFileReturnPtrHi       = &08
FileHandle                    = &07
ClockWorkspace03              = &0603       ; clock workspace/control byte used by bootstrap and clock code
EventSuppressionFlags         = &0C         ; bit 6 suppresses Escape event, bit 7 clock timer event
CursorBlinkSuppressedFlag     = &067C       ; negative => ReadGameKey does not animate cursor flash
MoveFlashCadence              = &0659       ; normally 6; move display selects five/six flash cycles
JoystickADCWorkspaceBase      = &0651       ; OSBYTE &80 channel samples/quantised coordinates
JoystickSquareSelectBase      = Joystick1MailboxSquare-&04
IntervalTimerSignByte         = IntervalTimerPawnWorkspace+&04
MOSBreakActionFlags           = &0258       ; MOS *FX 200 BREAK action flags
MOSErrorPtrLo                 = &FD         ; MOS BRK error-block pointer (&FD/&FE)
MOSEscapeFlag                 = &FF         ; MOS Escape-condition flag
BlackPieceTypeArray           = PieceTypeArray+SIDE_BLACK
UnusedSearchState14           = &14         ; cleared by move chooser; no proven read in this image
MoveAuxWriteOnlyShadow        = &0670       ; shadow write observed; no static read found
UnusedTurnState0658           = &0658       ; retained conservatively: write-only in recovered code
UnusedState067D               = &067D       ; retained conservatively: write-only in recovered code
UnusedTurnState0683           = &0683       ; retained conservatively: write-only in recovered code
Scratch03                     = &03
Scratch04                     = &04
Scratch06                     = &06
Scratch07                     = &07
Scratch08                     = &08
Scratch09                     = &09
Scratch0A                     = &0A
Scratch0B                     = &0B
Scratch0D                     = &0D
Scratch3B                     = &3B
Scratch43                     = &43
Scratch46                     = &46
Scratch47                     = &47
FilenameBuffer                = IntervalTimerPawnWorkspace
OpeningBookPtrLo              = &08
OpeningBookPtrHi              = &09
HumanMoveScanPtrLo            = &46
HumanMoveScanPtrHi            = &47
TextStringPtrLo               = &0A
TextStringPtrHi               = &0B

; High two bytes of each 32-bit OSFILE address field. InlineOSFILE fills these from OSBYTE &82.
OSFileLoadAddressBank         = MOSParameterBlock+&04
OSFileLoadAddressTop          = MOSParameterBlock+&05
OSFileExecAddressBank         = MOSParameterBlock+&08
OSFileExecAddressTop          = MOSParameterBlock+&09
OSFileStartAddressBank        = MOSParameterBlock+&0C
OSFileStartAddressTop         = MOSParameterBlock+&0D
OSFileEndAddressBank          = MOSParameterBlock+&10
OSFileEndAddressTop           = MOSParameterBlock+&11

; Main-game save image assembled in a fixed high-RAM workspace before OSFILE.
; Only the base is a machine-memory decision; every field/page is derived from it.
SaveImagePieceTypes         = SaveImageBase+&000
SaveImagePieceSquares       = SaveImageBase+&020
SaveImagePlyLo              = SaveImageBase+&040
SaveImagePlyHi              = SaveImageBase+&041
SaveImageCastlingRights     = SaveImageBase+&042
SaveImageEnPassantTarget    = SaveImageBase+&043
SaveImageSideToMove         = SaveImageBase+&044
SaveImageWhiteClock         = SaveImageBase+&045
SaveImageBlackClock         = SaveImageBase+&048
SaveImageHistoryBaseSide    = SaveImageBase+&04B
SaveImageFiftyMoveCounter   = SaveImageBase+&04C
SaveImageSignature          = SaveImageBase+&050
SaveImageHistoryBaseTypes   = SaveImageBase+&064
SaveImageHistoryBaseSquares = SaveImageBase+&084
SaveImageGamePhase          = SaveImageBase+&0A4
SaveImageInformationText    = SaveImageBase+&0C4
SaveImageHistoryFrom        = GameHistoryFrom
SaveImageHistoryTo          = GameHistoryTo
SaveImageHistoryAux         = GameHistoryAux
SaveImageHistoryFlags       = GameHistoryFlags
SaveImageEnd                = SaveImageBase+&500

; Bootstrap code is dead after startup.  The engine deliberately reclaims that same address
; as its move-list arena and as the temporary file-load / editor-board-save image.
 ; MoveArenaBase is a forward label at the first byte after the permanent engine.
; The original program placed its one-shot bootstrap here and reclaimed the bytes
; immediately afterwards.  In this direct-runtime build the address is workspace only.
LoadedImagePieceTypes        = MoveArenaBase+&000
LoadedImagePieceSquares      = MoveArenaBase+&020
LoadedImagePlyLo             = MoveArenaBase+&040
LoadedImagePlyHi             = MoveArenaBase+&041
LoadedImageCastlingRights    = MoveArenaBase+&042
LoadedImageEnPassantTarget   = MoveArenaBase+&043
LoadedImageSideToMove        = MoveArenaBase+&044
LoadedImageWhiteClock        = MoveArenaBase+&045
LoadedImageBlackClock        = MoveArenaBase+&048
LoadedImageHistoryBaseSide   = MoveArenaBase+&04B
LoadedImageFiftyMoveCounter  = MoveArenaBase+&04C
LoadedImageSignature         = MoveArenaBase+&050
LoadedImageHistoryBaseTypes  = MoveArenaBase+&064
LoadedImageHistoryBaseSquares= MoveArenaBase+&084
LoadedImageGamePhase         = MoveArenaBase+&0A4
LoadedImageInformationText   = MoveArenaBase+&0C4
LoadedImageHistoryFrom       = MoveArenaBase+&100
LoadedImageHistoryTo         = MoveArenaBase+&200
LoadedImageHistoryAux        = MoveArenaBase+&300
LoadedImageHistoryFlags      = MoveArenaBase+&400
BoardFileImageEnd            = LoadedImagePieceTypes+&0A0
MoveArenaLimit               = SaveImageBase+&0E0 ; first address not available to generated move frames

; The web assembler deliberately has no relational operators in expressions.
; These assertions therefore test page alignment arithmetically:
;   remainder 0 -> 1/(0+1) = 1 (pass)
;   remainder n -> 1/(n+1) = 0 (fail, integer division)
ASSERT 1 / ((RUNTIME_BASE % &100) + 1)
ORG RUNTIME_BASE


; -----------------------------------------------------------------------------
; Runtime image start: initial tables and opening-book/skill data
; -----------------------------------------------------------------------------

; Convenience entry at the runtime origin.  The generated boot disk should normally
; select GameEntry, but jumping to &0E00 also reaches the same temporary startup path.
RuntimeImageStart:
    JMP GameEntry

CopyrightText:
    EQUB &28,&63,&29,&20,&41,&63,&6F,&72,&6E,&73,&6F,&66,&74,&20,&31,&39 ; (c) Acornsoft 19
    EQUB &38,&33

SavedOldIRQ1V:
    EQUB &00,&00

; 32 initial piece-type bytes: 0 king, 2 queen, 4 rook, 6 bishop, 8 knight, 10 pawn.
; Slots 0-15 are White; 16-31 are Black.
InitialPieceTypes:
    EQUB &00,&02,&04,&04,&06,&06,&08,&08,&0A,&0A,&0A,&0A,&0A,&0A,&0A,&0A
    EQUB &00,&02,&04,&04,&06,&06,&08,&08,&0A,&0A,&0A,&0A,&0A,&0A,&0A,&0A

; 32 mailbox square numbers for the initial position.
; Square encoding is rank*10+file: White back rank 21-28, Black back rank 91-98.
InitialPieceSquares:
    EQUB &19,&18,&15,&1C,&17,&1A,&16,&1B,&1F,&20,&21,&22,&23,&24,&25,&26 ; ......... !"#$%&
    EQUB &5F,&5E,&5B,&62,&5D,&60,&5C,&61,&51,&52,&53,&54,&55,&56,&57,&58 ; _^[b]`\aQRSTUVWX

PieceGlyphPairs:
    EQUB &EC,&ED,&F8,&F9,&E6,&E7,&F2,&F3,&E0,&E1,&FC,&FD,&20,&20,&20,&20 ; ............    
    EQUB &EE,&EF,&FA,&FB,&E8,&E9,&F4,&F5,&E2,&E3,&FE,&FF,&3F,&3F,&20,&20 ; ............??  
    EQUB &F0,&F1,&F0,&F1,&EA,&EB,&F6,&F7,&E4,&E5,&EA,&EB,&20,&20,&20,&20 ; ............    

; Piece notation letters indexed by even piece type (K,Q,R,B,N,P).
PieceLetters:
    EQUB &6B,&00,&71,&00,&72,&00,&62,&00,&6E,&00,&70,&00 ; k.q.r.b.n.p.

; Six little-endian 16-bit evaluation values: king &0200, queen &0120, rook &00A0, bishop/knight &0068, pawn &0020.
PieceValues16:
    EQUB &00,&02,&20,&01,&A0,&00,&68,&00,&68,&00,&20,&00 ; .. ...h.h. .

; Compact material values: king 0, queen 9, rook 5, bishop 3, knight 3, pawn 1.
CompactPieceValues:
    ; Indexed by piece_type/2: K=0, Q=9, R=5, B=3, N=3, P=1.
    EQUB &00,&09,&05,&03,&03,&01

MoveOrderingPieceBonuses:
    ; Low bytes used by the move-orderer (even offsets by piece type):
    ; K=0, Q=&35, R=&75, B=&45, N=&45, P=&15.
    EQUB &00,&00,&35,&00,&75,&00,&45,&00,&45,&00,&15,&00

AdjacentPieceValueTable:
    ; Six 16-bit values adjacent to the ordering table.  No direct static reference has
    ; yet been proven, so retain a conservative name rather than inventing semantics.
    EQUB &05,&00,&50,&00,&28,&00,&18,&00,&18,&00,&05,&00

; Six RTS-dispatch entries stored as target-1, indexed by even piece type.
; The dispatcher pushes one of these values and uses RTS, hence the -1 encoding.
MoveGeneratorDispatch:
    EQUW GenerateKingMoves-1,GenerateQueenMoves-1,GenerateRookMoves-1
    EQUW GenerateBishopMoves-1,GenerateKnightMoves-1,GeneratePawnMoves-1
PostMoveGeneratorData:
    EQUB &00,&00,&01,&F4

MoveOrderingCallbackByPhase:
    ; Four callback addresses, selected as GamePhaseBySide*2.
    EQUW AddBookOrPositionalMoveOrdering,AddNoisyPositionalMoveOrdering
    EQUW AddNoisyPositionalMoveOrdering,AddRandomMoveOrderingNoise

UnreferencedData0ED5:
    ; Adjacent original bytes; not part of the indexed callback table.
    EQUB &00,&00,&20,&53,&42,&43

MoveDeltas:
    ; Orthogonal/diagonal deltas used by king/sliders.
    EQUB &01,&0A,&FF,&F6,&0B,&09,&F5,&F7
KnightDeltas:
    EQUB &0C,&15,&13,&08,&F4,&EB,&ED,&F8

PrimaryDepthLimitBySkill:
    EQUB &02,&02,&02,&03,&03,&04,&04,&05,&07,&09
SelectiveDepthLimitBySkill:
    EQUB &04,&06,&08,&07,&07,&08,&08,&09,&0B,&0D
TopTenMoveLimitFlagBySkill:
    EQUB &01,&00,&00,&01,&00,&01,&00,&01,&00,&00

; Two 8-byte OSWORD 7 SOUND parameter blocks.
SoundParameterBlocks:
    EQUB &10,&00,&01,&00,&04,&00,&02,&00
    EQUB &13,&00,&02,&00,&78,&00,&06,&00

; -----------------------------------------------------------------------------
; Opening book
; -----------------------------------------------------------------------------
; Square bytes below are mailbox squares.  The book is used as a move-ordering bonus,
; not as an unconditional move chooser.  Initial White records are 4 bytes:
;     from, to, weight, continuation-offset
; followed by &FF.  The initial Black selector is also four-byte records.
InitialWhiteOpeningMoves:
    EQUB &23,&37,&0C,WhiteBook_AfterE4-WhiteOpeningContinuations       ; e2-e4
    EQUB &22,&36,&0C,WhiteBook_AfterD4-WhiteOpeningContinuations       ; d2-d4
    EQUB &21,&35,&0A,WhiteBook_FianchettoFamily-WhiteOpeningContinuations ; c2-c4
    EQUB &1B,&2E,&0A,WhiteBook_FianchettoFamily-WhiteOpeningContinuations ; Ng1-f3
    EQUB &25,&2F,&0A,WhiteBook_FianchettoFamily-WhiteOpeningContinuations ; g2-g3
    EQUB &20,&2A,&0A,WhiteBook_AfterB3-WhiteOpeningContinuations       ; b2-b3
    EQUB &FF

InitialBlackContinuationSelector:
    EQUB &23,&37,&00,BlackBook_AfterE4-BlackOpeningContinuations       ; after e2-e4
    EQUB &22,&36,&00,BlackBook_AfterD4-BlackOpeningContinuations       ; after d2-d4
    EQUB &21,&35,&00,BlackBook_AfterC4-BlackOpeningContinuations       ; after c2-c4
    EQUB SQ_A1,SQ_A1,&00,BlackBook_Default-BlackOpeningContinuations   ; fallback selector
    EQUB &FF

; Continuation records are three bytes: from, to, weight; &FF terminates a group.
WhiteOpeningContinuations:
WhiteBook_AfterE4:
    EQUB &1B,&2E,&11           ; Ng1-f3 17
    EQUB &16,&2B,&0A           ; Nb1-c3 10
    EQUB &1A,&23,&06           ; Bf1-e2 6
    EQUB &1A,&35,&0C           ; Bf1-c4 12
    EQUB &1A,&3E,&0C           ; Bf1-b5 12
    EQUB &22,&36,&0C           ; d2-d4 12
    EQUB &19,&1B,&0C           ; O-O 12 (king e1-g1)
    EQUB &22,&2C,&0A           ; d2-d3 10
    EQUB &17,&2D,&08           ; Bc1-e3 8
    EQUB &17,&43,&08           ; Bc1-g5 8
    EQUB &26,&30,&04           ; h2-h3 4
    EQUB &1F,&29,&04           ; a2-a3 4
    EQUB &FF
WhiteBook_AfterD4:
    EQUB &21,&35,&0C           ; c2-c4 12
    EQUB &1B,&2E,&0C           ; Ng1-f3 12
    EQUB &16,&2B,&0A           ; Nb1-c3 10
    EQUB &21,&2B,&06           ; c2-c3 6
    EQUB &23,&2D,&08           ; e2-e3 8
    EQUB &1A,&2C,&0C           ; Bf1-d3 12
    EQUB &17,&38,&06           ; Bc1-f4 6
    EQUB &17,&43,&0A           ; Bc1-g5 10
    EQUB &19,&1B,&0C           ; O-O 12
    EQUB &26,&30,&04           ; h2-h3 4
    EQUB &16,&22,&06           ; Nb1-d2 6
    EQUB &FF
WhiteBook_FianchettoFamily:
    EQUB &25,&2F,&0C           ; g2-g3 12
    EQUB &22,&2C,&0C           ; d2-d3 12
    EQUB &1B,&2E,&0C           ; Ng1-f3 12
    EQUB &1A,&25,&0C           ; Bf1-g2 12
    EQUB &16,&22,&0C           ; Nb1-d2 12
    EQUB &19,&1B,&0C           ; O-O 12
    EQUB &23,&37,&06           ; e2-e4 6
    EQUB &1F,&29,&04           ; a2-a3 4
    EQUB &26,&30,&04           ; h2-h3 4
    EQUB &16,&2B,&0A           ; Nb1-c3 10
    EQUB &20,&34,&06           ; b2-b4 6
    EQUB &15,&16,&06           ; Ra1-b1 6
    EQUB &21,&35,&06           ; c2-c4 6
    EQUB &FF
WhiteBook_AfterB3:
    EQUB &17,&20,&0C           ; Bc1-b2 12
    EQUB &23,&2D,&0C           ; e2-e3 12
    EQUB &1B,&2E,&0C           ; Ng1-f3 12
    EQUB &1A,&23,&0A           ; Bf1-e2 10
    EQUB &1A,&3E,&06           ; Bf1-b5 6
    EQUB &19,&1B,&0C           ; O-O 12
    EQUB &16,&2B,&06           ; Nb1-c3 6
    EQUB &21,&35,&04           ; c2-c4 4
    EQUB &24,&38,&04           ; f2-f4 4
    EQUB &FF

BlackOpeningContinuations:
BlackBook_AfterE4:
    EQUB &55,&41,&11           ; e7-e5 17
    EQUB &5C,&49,&0C           ; Nb8-c6 12
    EQUB &5C,&54,&06           ; Nb8-d7 6
    EQUB &61,&4C,&0A           ; Ng8-f6 10
    EQUB &61,&55,&04           ; Ng8-e7 4
    EQUB &60,&55,&0A           ; Bf8-e7 10
    EQUB &60,&3F,&0A           ; Bf8-c5 10
    EQUB &60,&34,&06           ; Bf8-b4 6
    EQUB &54,&4A,&0A           ; d7-d6 10
    EQUB &54,&40,&04           ; d7-d5 4
    EQUB &58,&4E,&06           ; h7-h6 6
    EQUB &51,&47,&06           ; a7-a6 6
    EQUB &57,&4D,&06           ; g7-g6 6
    EQUB &5F,&61,&0C           ; O-O 12 (king e8-g8)
    EQUB &5D,&39,&0A           ; Bc8-g4 10
    EQUB &5D,&54,&08           ; Bc8-d7 8
    EQUB &5D,&4B,&0A           ; Bc8-e6 10
    EQUB &60,&57,&0C           ; Bf8-g7 12
    EQUB &FF
BlackBook_AfterD4:
    EQUB &61,&4C,&0C           ; Ng8-f6 12
    EQUB &55,&4B,&0C           ; e7-e6 12
    EQUB &52,&48,&0A           ; b7-b6 10
    EQUB &5D,&52,&08           ; Bc8-b7 8
    EQUB &60,&55,&0A           ; Bf8-e7 10
    EQUB &60,&34,&0A           ; Bf8-b4 10
    EQUB &5F,&61,&0C           ; O-O 12
    EQUB &58,&4E,&06           ; h7-h6 6
    EQUB &5C,&49,&06           ; Nb8-c6 6
    EQUB &54,&40,&06           ; d7-d5 6
    EQUB &53,&3F,&06           ; c7-c5 6
    EQUB &5C,&54,&06           ; Nb8-d7 6
    EQUB &FF
BlackBook_AfterC4:
    EQUB &55,&41,&0C           ; e7-e5 12
    EQUB &5C,&49,&0A           ; Nb8-c6 10
    EQUB &5C,&54,&08           ; Nb8-d7 8
    EQUB &53,&49,&08           ; c7-c6 8
    EQUB &54,&4A,&0A           ; d7-d6 10
    EQUB &57,&4D,&0A           ; g7-g6 10
    EQUB &60,&55,&08           ; Bf8-e7 8
    EQUB &60,&57,&0C           ; Bf8-g7 12
    EQUB &5F,&61,&0C           ; O-O 12
    EQUB &61,&4C,&0C           ; Ng8-f6 12
    EQUB &61,&55,&0A           ; Ng8-e7 10
    EQUB &5D,&4B,&00           ; Bc8-e6, weight 0
    EQUB &FF
BlackBook_Default:
    EQUB &54,&40,&0C           ; d7-d5 12
    EQUB &61,&4C,&0C           ; Ng8-f6 12
    EQUB &5C,&49,&08           ; Nb8-c6 8
    EQUB &5C,&54,&08           ; Nb8-d7 8
    EQUB &55,&41,&08           ; e7-e5 8
    EQUB &55,&4B,&08           ; e7-e6 8
    EQUB &53,&49,&06           ; c7-c6 6
    EQUB &5D,&39,&08           ; Bc8-g4 8
    EQUB &5D,&54,&06           ; Bc8-d7 6
    EQUB &5D,&42,&0A           ; Bc8-f5 10
    EQUB &5D,&4B,&06           ; Bc8-e6 6
    EQUB &60,&4A,&0A           ; Bf8-d6 10
    EQUB &60,&3F,&08           ; Bf8-c5 8
    EQUB &5F,&61,&0C           ; O-O 12
    EQUB &FF

; Permanent game entry after one-shot startup has completed.
; From here onward the engine executes entirely from its final runtime addresses.
ChessRuntimeEntry:
    CLD
    LDX #&FF
    TXS
    INX
    STX ClockWorkspace03
    STX ActiveClockSideOffset
    STX SearchAbortFlag
    STX ClockTickPending
    JSR InitialiseDisplayAndState
    LDA #&0F
    LDX #&00
    JSR OSBYTE
    LDA #&04
    LDX #&00
    JSR OSBYTE
    JSR InitialisePosition
    LDA #&FF
    STA EventSuppressionFlags

RedrawMainMenu:
    JSR DrawMainMenu
    JMP MainMenuLoop

MainMenuLoadGame:
    JSR LoadGame
    JMP RedrawMainMenu

MainMenuSaveGame:
    JSR SaveGame
    JMP RedrawMainMenu

ToggleTickSound:
    LDA TickSoundOffFlag
    EOR #&FF
    STA TickSoundOffFlag
    JMP MainMenuLoop

ToggleJoystickControl:
    LDA JoysticksOffFlag
    EOR #&FF
    STA JoysticksOffFlag
    STA CursorOffFlag
    JMP MainMenuLoop

ToggleCursorDisplay:
    BIT JoysticksOffFlag
    BPL MainMenuLoop
    LDA CursorOffFlag
    EOR #&FF
    STA CursorOffFlag
    JMP MainMenuLoop

MainMenuLoop:
    JSR RefreshMainMenuState
    JSR ReadGameKey
    CMP #&4C
    BEQ MainMenuLoadGame
    CMP #&53
    BEQ MainMenuSaveGame
    CMP #&54
    BEQ ToggleTickSound
    CMP #&4A
    BEQ ToggleJoystickControl
    CMP #&50
    BEQ SelectPlayerVsPlayer
    CMP #&57
    BEQ SelectPlayerWhite
    CMP #&42
    BEQ SelectPlayerBlack
    CMP #&41
    BEQ SelectAutoPlay
    CMP #&45
    BEQ EnterEditorFromMenu
    CMP #&4E
    BNE TryMainMenuReturnOrRestart
    JMP RequestNewGame

TryMainMenuReturnOrRestart:
    CMP #&0D
    BEQ ContinueOrStartGame
    CMP #&43
    BEQ ToggleCursorDisplay
    CMP #&52
    BNE TryMainMenuSkillDigit
    JMP StartGameFromEditorPosition

TryMainMenuSkillDigit:
    CMP #&3A
    BCS ReturnToMainMenuLoop
    SBC #&2F
    BCC ReturnToMainMenuLoop
    STA SkillLevel

ReturnToMainMenuLoop:
    JMP MainMenuLoop

EnterEditorFromMenu:
    JSR DisableEscapeEvent
    LDA #&FF
    STA EditorModeActiveFlag
    JSR ReturnToEditorAfterError
    LDA #&00
    STA EditorModeActiveFlag
    JSR EnableEscapeEvent
    JMP RedrawMainMenu

SelectPlayerVsPlayer:
    LDA #&00
    BEQ StoreGameType

SelectPlayerWhite:
    LDA #&01
    BNE StoreGameType

SelectPlayerBlack:
    LDA #&02
    BNE StoreGameType

SelectAutoPlay:
    LDA #&03

StoreGameType:
    STA GameType

ReturnToMainMenu:
    JMP MainMenuLoop

ContinueOrStartGame:
    BIT ResumeGameAvailableFlag
    BMI ResumeCurrentGame
    JMP InitialiseNewGame

ResumeCurrentGame:
    JSR RestoreResumableGamePosition
    JSR RebuildMailboxBoard
    LDA SavedEnPassantTarget
    STA EnPassantTargetSquare
    LDA SavedCastlingRights
    STA CastlingRights
    JSR RestoreChessClocks
    JSR SetGameScreen
    LDA #&04
    LDX #&01
    JSR OSBYTE
    JSR DrawChessBoard
    LDA GameSideToMove
    STA SideToMove
    LDA GamePlyCountLo
    STA PlyCountLo
    LDA GamePlyCountHi
    STA PlyCountHi
    JMP StartGameSession

StartGameFromEditorPosition:
    BIT EditorPositionInvalidFlag
    BMI ReturnToMainMenu
    JSR InitialisePosition
    JSR ClearMailboxBoard
    JSR CopyEditorSnapshotToLive
    JSR RestorePositionSnapshot
    JSR SaveHistoryBasePosition
    JSR RebuildMailboxBoard
    JSR ResetEditorState
    JSR SnapshotChessClocks
    LDA #&02
    STA GamePhaseBySide
    STA BlackGamePhase
    LDA #&00
    STA PlyCountLo
    STA PlyCountHi
    STA EnPassantPawnSlot
    STA EnPassantTargetSquare
    STA EngineStopFlag
    STA FiftyMovePlyCounter
    LDA EditorCastlingRights
    STA CastlingRights
    STA SavedCastlingRights
    LDA EditorSideToMove
    STA HistoryBaseSide
    STA SideToMove
    STA GameSideToMove
    BEQ StoreEditorStartPlyCount
    INC PlyCountLo

StoreEditorStartPlyCount:
    LDA PlyCountLo
    STA GamePlyCountLo
    LDA PlyCountHi
    STA GamePlyCountHi
    JMP ShowInitialGameBoard

RequestNewGame:
    BIT ResumeGameAvailableFlag
    BMI InitialiseNewGame
    JMP MainMenuLoop

InitialiseNewGame:
    JSR InitialisePosition
    JSR SaveHistoryBasePosition
    JSR ResetEditorState
    JSR SnapshotChessClocks
    LDA #&00
    STA ActiveClockSideOffset
    STA SideToMove
    STA HistoryBaseSide
    STA GamePhaseBySide
    STA BlackGamePhase
    STA FiftyMovePlyCounter

ShowInitialGameBoard:
    JSR SetGameScreen
    LDA #&04
    LDX #&01
    JSR OSBYTE
    JSR DrawChessBoard

StartGameSession:
    LDX #&00
    STX EngineStopFlag
    DEX
    STX ResumeGameAvailableFlag
    JSR EnableEscapeEvent
    JSR InstallEventHandler

StartTurn:
    JSR RestoreChessClocks
    LDA #&00
    STA EventSuppressionFlags
    STA SearchPly
    LDA SideToMove
    STA ActiveClockSideOffset
    STA GameSideToMove
    LDA PlyCountLo
    STA GamePlyCountLo
    LDA PlyCountHi
    STA GamePlyCountHi
    LDA CastlingRights
    STA SavedCastlingRights
    LDA EnPassantTargetSquare
    STA SavedEnPassantTarget
    JSR SaveResumePosition
    LDA #&00
    STA SearchNodeCountLo
    STA SearchNodeCountHi
    STA PositionScoreLo
    STA PositionScoreMid
    STA PositionScoreHi
    STA UnusedTurnState0683
    JSR InitialiseMoveListArena
    JSR ValidateBoardConsistency
    JSR BuildLegalMoveList5
    LDA MoveListStartLo
    CMP MoveListEndLo
    BNE ChooseTurnMove
    LDA MoveListStartHi
    CMP MoveListEndHi
    BNE ChooseTurnMove
    JSR SelectStatusTextWindow
    LDA #&0C
    JSR OSWRCH
    JSR IsSideToMoveInCheck
    BNE PrintCheckmatePrefix
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&20,&20,&20,&53,&74,&61,&6C,&65 ;      Stale
    NOP
    JMP PrintMateSuffix

PrintCheckmatePrefix:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&20,&20,&20,&43,&68,&65,&63,&6B ;      Check
    NOP
    JMP PrintMateSuffix

ChooseTurnMove:
    JSR ComputeStaticPositionScore
    LDA GameType
    LDX SideToMove
    BNE TestComputerControlledSide
    LSR A

TestComputerControlledSide:
    AND #&01
    BNE ComputerTurn
    JSR ReadHumanMove
    JMP ApplySelectedTurnMove

ComputerTurn:
    JSR ChooseComputerMove
    LDA SkillLevel
    CMP #&06
    BCC ApplySelectedTurnMove
    LDA #&01
    JSR PlaySoundEffect

ApplySelectedTurnMove:
    LDA MoveFromSquare
    BEQ ShowEndOfGame
    LDX #&06
    LDA MoveFlashCadence
    CMP #&05
    BEQ StoreFlashCadence
    LDX #&05

StoreFlashCadence:
    STX MoveFlashCadence
    LDA CursorOffFlag
    BMI CommitTurnMove
    LDA MoveFromSquare
    JSR FlashSquare

CommitTurnMove:
    JSR MakeMove
    JSR SnapshotChessClocks
    JSR CommitMoveToGameHistory
    LDA EngineStopFlag
    BNE ShowEndOfGame
    JSR DisplayCommittedMove
    JSR CheckAutomaticDraw
    BCS MarkGameFinished
    LDA GamePlyCountLo
    STA PlyCountLo
    LDA GamePlyCountHi
    STA PlyCountHi
    INC PlyCountLo
    BNE StartOpponentsTurn
    INC PlyCountHi

StartOpponentsTurn:
    LDA GameSideToMove
    EOR #&10
    STA SideToMove
    JMP StartTurn

ShowEndOfGame:
    JSR DrawChessBoard
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0D,&0A,&45,&6E,&64,&20,&6F,&66,&20,&67,&61,&6D,&65 ; ..End of game
    NOP
    JMP WaitForReturnToMainMenu

PrintMateSuffix:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &6D,&61,&74,&65 ; mate
    NOP

MarkGameFinished:
    LDA #&00
    STA ResumeGameAvailableFlag

WaitForReturnToMainMenu:
    LDA #&FF
    STA EventSuppressionFlags
    JSR SelectEndGameTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11,&02,&0A,&0D,&50,&72,&65,&73,&73,&20,&66,&69,&72,&65,&20,&62 ; ....Press fire b
    EQUB &75,&74,&74,&6F,&6E,&20,&6F,&72,&20,&52,&45,&54,&55,&52,&4E,&20 ; utton or RETURN 
    EQUB &74,&6F,&20,&67,&65,&74,&20,&62,&61,&63,&6B ; to get back
    NOP
    LDA #&0C
    STA ActiveClockSideOffset
    JSR DisableEscapeEvent

WaitForReturnKeyOrFire:
    JSR ReadGameKey
    BCS ReturnToGameEntry
    CMP #&0D
    BNE WaitForReturnKeyOrFire

ReturnToGameEntry:
    JMP ChessRuntimeEntry

; Initialises the mailbox board and copies InitialPieceTypes/InitialPieceSquares into the live piece arrays.
InitialisePosition:
    LDY #&78
    LDA #MAILBOX_OFFBOARD

FillMailboxWithOffboardSentinel:
    STA MailboxBoard-1,Y
    DEY
    BNE FillMailboxWithOffboardSentinel
    LDY #&50
    LDA #MAILBOX_EMPTY

FillNextPlayableRank:
    LDX #&08

FillPlayableRankSquares:
    STA MailboxBoard+MAILBOX_PLAYABLE_FILL_BIAS,Y
    DEY
    DEX
    BNE FillPlayableRankSquares
    DEY
    DEY
    BNE FillNextPlayableRank
    LDX #PIECE_SLOT_LAST

InstallInitialPieceSlot:
    LDA InitialPieceTypes,X
    STA PieceTypeArray,X
    LDY InitialPieceSquares,X
    STY PieceSquareArray,X
    TXA
    STA MailboxBoard,Y
    DEX
    BPL InstallInitialPieceSlot
    INX
    STX PlyCountLo
    STX PlyCountHi
    STX PositionScoreLo
    STX PositionScoreMid
    STX PositionScoreHi
    STX EngineStopFlag
    STX SideToMove
    STX EnPassantTargetSquare
    STX BoardConsistencyCheckFlag
    LDA #CASTLE_ALL
    STA CastlingRights

; Initialise the move-list stack in reclaimed bootstrap RAM at MoveArenaBase.
; Current frame, list start and list end all begin at the arena base.
InitialiseMoveListArena:
    LDA #<MoveArenaBase
    STA MoveFramePtrLo
    STA MoveListEndLo
    STA MoveListStartLo
    LDA #>MoveArenaBase
    STA MoveFramePtrHi
    STA MoveListEndHi
    STA MoveListStartHi
    RTS

; Installed in BRKV (&0202/&0203); reports MOS error text and returns to the user interface.
BreakHandler:
    JSR CloseAllFiles
    LDA #&FF
    STA EventSuppressionFlags
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&81,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&45,&72,&72 ; ..           Err
    EQUB &6F,&72,&20,&20,&3A,&20,&88 ; or  : .
    NOP
    LDY #&01

PrintNextBreakErrorChar:
    LDA (MOSErrorPtrLo),Y
    BEQ WaitAfterBreakError
    JSR OSWRCH
    INY
    BNE PrintNextBreakErrorChar

WaitAfterBreakError:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&0D,&0A,&0D,&20,&20,&20,&20,&20,&20,&20,&20,&50,&72,&65,&73 ; ....        Pres
    EQUB &73,&20,&61,&6E,&79,&20,&6B,&65,&79,&20,&74,&6F,&20,&63,&6F,&6E ; s any key to con
    EQUB &74,&69,&6E,&75,&65 ; tinue
    NOP
    JSR ReadGameKey

ReturnAfterBreakOrEscape:
    LDX #&FF
    TXS
    LDA EditorModeActiveFlag
    BMI ReturnToEditorAfterBreak
    JMP ChessRuntimeEntry

ReturnToEditorAfterBreak:
    LDA #&11
    PHA
    LDA #&35
    PHA
    JSR ClearMailboxBoard
    JSR RestorePositionSnapshot
    JSR RebuildMailboxBoard
    JSR DisableEscapeEvent
    JMP EditorKeyLoop

IsHistoryAtBeginning:
    CLC
    LDA GamePlyCountLo
    ORA GamePlyCountHi
    BNE TestHistoryAtBeginning
    SEC

TestHistoryAtBeginning:
    RTS

FinishGameHistoryPlayback:
    PLA
    STA CursorOffFlag
    JSR SetSlowKeyboardRepeat
    LDA PlyCountLo
    CMP GamePlyCountLo
    BNE OfferPlayOnFromPlaybackPosition
    LDA PlyCountHi
    CMP GamePlyCountHi
    BNE OfferPlayOnFromPlaybackPosition

ReturnPlaybackToEditor:
    JSR ValidateEditorPosition
    CLC
    PLA
    PLA
    JMP EditorKeyLoop

OfferPlayOnFromPlaybackPosition:
    LDA PlyCountLo
    ORA PlyCountHi
    BEQ ReturnPlaybackToEditor
    JSR SelectMainTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&11,&03,&44,&6F,&20,&79,&6F,&75,&20,&77,&69,&73,&68,&20,&74 ; ...Do you wish t
    EQUB &6F,&20,&70,&6C,&61,&79,&20,&6F,&6E,&20,&66,&72,&6F,&6D,&20,&68 ; o play on from h
    EQUB &65,&72,&65,&0A,&0D,&28,&70,&72,&65,&73,&73,&20,&22,&59,&22,&20 ; ere..(press "Y" 
    EQUB &6F,&72,&20,&22,&4E,&22,&29,&3F ; or "N")?
    NOP
    JSR ReadGameKey
    BCS ReturnPlaybackToEditor
    CMP #&59
    BNE ReturnPlaybackToEditor
    LDA SideToMove
    STA GameSideToMove
    JSR SaveResumePosition
    JSR ValidateEditorPosition
    LDA GameSideToMove
    STA SideToMove
    LDA EditorCastlingRights
    STA SavedCastlingRights
    LDA EnPassantTargetSquare
    STA SavedEnPassantTarget
    LDA PlyCountLo
    STA GamePlyCountLo
    LDA PlyCountHi
    STA GamePlyCountHi
    LDX #&00
    JSR RecomputeGamePhaseForSide
    LDX #&10
    JSR RecomputeGamePhaseForSide
    LDA #&FF
    STA ResumeGameAvailableFlag
    LDA #&00
    STA EditorModeActiveFlag
    PLA
    PLA
    RTS

ExitPlayback:
    JMP FinishGameHistoryPlayback

PlaybackGameHistory:
    JSR SetGameScreen
    JSR InitialisePosition
    JSR ClearMailboxBoard
    JSR RestoreHistoryBasePosition
    JSR RebuildMailboxBoard
    JSR DrawChessBoard
    JSR SelectMainTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11,&01
    NOP
    LDX #&00

PrintPlaybackBannerChar:
    LDA GameInformationText,X
    CMP #&0D
    BEQ BeginPlaybackControls
    JSR OSWRCH
    INX
    CPX #&3B
    BNE PrintPlaybackBannerChar

BeginPlaybackControls:
    JSR SelectMoveTextWindow
    LDA #&04
    LDX #&01
    JSR OSBYTE
    LDA CursorOffFlag
    PHA
    LDX #&FF
    STX CursorOffFlag
    INX
    STX PlyCountHi
    LDA HistoryBaseSide
    BEQ StorePlaybackStartingPly
    INX

StorePlaybackStartingPly:
    STX PlyCountLo
    STA SideToMove

PlaybackKeyLoop:
    JSR ReadGameKey
    BCS ExitPlayback
    CMP #&8C
    BCS PlaybackKeyLoop
    CMP #&88
    BCC PlaybackKeyLoop
    PHA
    JSR SetPlaybackKeyRepeatFromShift
    PLA
    CMP #&88
    BEQ StepHistoryBackward
    CMP #&8A
    BEQ StepHistoryBackward
    LDA PlyCountLo
    CMP GamePlyCountLo
    LDA PlyCountHi
    SBC GamePlyCountHi
    BCS PlaybackKeyLoop
    JSR LoadMoveFromGameHistory
    BCS PlaybackKeyLoop
    LDA #&02
    STA SearchPly
    JSR MakeMove
    JSR RedrawAfterMakeMove

ShowPlaybackPlyNumber:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1A,&1F,&08,&1C,&11,&03
    NOP
    LDY PlyCountLo
    LDX PlyCountHi
    INY
    BNE ConvertPlaybackPlyToMoveNumber
    INX

ConvertPlaybackPlyToMoveNumber:
    TXA
    LSR A
    STA Scratch08
    TYA
    ROR A
    STA Scratch07
    JSR PrintWordDecimal
    JSR SelectMoveTextWindow
    JMP PlaybackKeyLoop

StepHistoryBackward:
    LDA PlyCountLo
    ORA PlyCountHi
    BEQ PlaybackKeyLoop
    LDA PlyCountLo
    BNE DecrementPlaybackPly
    DEC PlyCountHi

DecrementPlaybackPly:
    DEC PlyCountLo
    JSR LoadMoveFromGameHistory
    BCS PlaybackKeyLoop
    LDA #&02
    STA SearchPly
    JSR UnmakeMoveCommon
    JSR RedrawAfterUnmakeMove
    JMP ShowPlaybackPlyNumber

LoadMoveFromGameHistory:
    SEC
    LDA PlyCountHi
    BNE ReturnLoadHistoryMove
    LDY PlyCountLo
    LDA GameHistoryFrom,Y
    STA MoveFromSquare
    LDA GameHistoryTo,Y
    STA MoveToSquare
    LDA GameHistoryAux,Y
    STA MoveAux
    LDA GameHistoryFlags,Y
    STA MoveFlags
    CLC

ReturnLoadHistoryMove:
    RTS

SaveHistoryBasePosition:
    LDX #PIECE_SLOT_LAST

CopyHistoryBaseSlot:
    LDA PieceTypeArray,X
    STA HistoryBasePieceTypes,X
    LDA PieceSquareArray,X
    STA HistoryBasePieceSquares,X
    DEX
    BPL CopyHistoryBaseSlot
    RTS

RestoreHistoryBasePosition:
    LDX #PIECE_SLOT_LAST

RestoreHistoryBaseSlot:
    LDA HistoryBasePieceTypes,X
    STA PieceTypeArray,X
    LDA HistoryBasePieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL RestoreHistoryBaseSlot
    LDA HistoryBaseSide
    STA SideToMove
    RTS

RecomputeGamePhaseForSide:
    LDA PlyCountHi
    BNE ReturnFromPhaseRecompute
    LDY #&FF

ScanPhaseTransitionHistory:
    LDA PhaseTransitionPlyBySide,X
    CMP #NO_PHASE_TRANSITION
    BEQ StoreRecomputedGamePhase
    INY
    CMP PlyCountLo
    BEQ AdvancePhaseTransitionIndex
    BCS StoreRecomputedGamePhase

AdvancePhaseTransitionIndex:
    INX
    TXA
    AND #&03
    BNE ScanPhaseTransitionHistory

StoreRecomputedGamePhase:
    TXA
    AND #&10
    TAX
    TYA
    STA GamePhaseBySide,X

ReturnFromPhaseRecompute:
    RTS

; Detect automatic draw conditions implemented by the game: 100 half-moves (50-move
; rule) and insufficient material K-v-K or K+B/N-v-K.
CheckAutomaticDraw:
    LDA FiftyMovePlyCounter
    CMP #&64
    BCC CheckInsufficientMaterial
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&20,&20,&35,&30,&2D,&6D,&6F,&76,&65,&20,&44,&72,&61,&77 ;     50-move Draw
    NOP
    SEC
    RTS

CheckInsufficientMaterial:
    LDX #PIECE_SLOT_LAST
    LDY #&00

CountNonKingMaterialLoop:
    LDA PieceTypeArray,X
    BEQ NextMaterialSlot
    BMI NextMaterialSlot
    STA Scratch07
    INY

NextMaterialSlot:
    DEX
    BPL CountNonKingMaterialLoop
    CPY #&00
    BEQ ReportInsufficientMaterialDraw
    CPY #&01
    BNE NoAutomaticDraw
    LDA Scratch07
    CMP #&06
    BEQ ReportInsufficientMaterialDraw
    CMP #&08
    BEQ ReportInsufficientMaterialDraw

NoAutomaticDraw:
    CLC
    RTS

ReportInsufficientMaterialDraw:
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&11,&03,&20,&20,&20,&20,&20,&20,&20,&44,&72,&61,&77 ; ...       Draw
    NOP
    SEC
    RTS

ReturnNoDraw:
    CLC
    RTS

AbortSearchToInterface:
    LDA #&00
    STA SearchAbortFlag
    LDA #&7E
    JSR OSBYTE
    LDA #&FF
    STA EventSuppressionFlags
    LDA #&7E
    JSR OSBYTE
    JMP ReturnAfterBreakOrEscape

CountPseudoLegalMoves:
    LDA #<CountGeneratedMove
    STA IndirectCallbackPtrLo
    LDA #>CountGeneratedMove
    STA IndirectCallbackPtrHi
    LDA #&00
    STA Scratch04
    JSR GenerateMovesForSide
    LDA Scratch04
    RTS

; Build a legal move frame using 5-byte search records.
; The common builder allocates a 16-byte frame header and remembers its parent.
BuildLegalMoveList5:
    LDA #MOVE_RECORD_BYTES
    BNE SetMoveRecordSize

; Build a legal move frame using compact 4-byte mate-solver records.
BuildLegalMoveList4:
    LDA #MATE_MOVE_RECORD_BYTES

SetMoveRecordSize:
    STA MoveRecordSize
    BIT SearchAbortFlag
    BPL BuildLegalMoveList
    JMP AbortSearchToInterface

BuildLegalMoveList:
    LDA #<AppendMoveIfLegal
    STA IndirectCallbackPtrLo
    LDA #>AppendMoveIfLegal
    STA IndirectCallbackPtrHi
    JSR ValidateBoardConsistency
    LDY #&00
    LDA MoveFramePtrLo
    STA (MoveListEndLo),Y
    LDA MoveFramePtrHi
    INY
    STA (MoveListEndLo),Y
    CLC
    LDA MoveListEndLo
    STA MoveFramePtrLo
    ADC #MOVE_FRAME_HEADER_BYTES
    STA MoveListEndLo
    STA MoveListStartLo
    LDA MoveListEndHi
    STA MoveFramePtrHi
    ADC #&00
    STA MoveListEndHi
    STA MoveListStartHi

GenerateMovesForSide:
    LDA MoveFromSquare
    PHA
    LDA MoveToSquare
    PHA
    LDA MoveAux
    PHA
    LDA MoveFlags
    PHA
    LDA EnPassantTargetSquare
    BEQ StoreInheritedEnPassantFlags
    LDA EnPassantPawnSlot
    AND #MOVE_ENPASSANT_MASK

StoreInheritedEnPassantFlags:
    STA MoveFlags
    LDA #&10
    STA Scratch47
    LDY SideToMove

GenerateNextPieceMoves:
    STY Scratch46
    LDX PieceTypeArray,Y
    BMI AdvancePieceSlot
    LDA PieceSquareArray,Y
    STA MoveFromSquare
    JSR DispatchPieceMoveGenerator

AdvancePieceSlot:
    LDY Scratch46
    INY
    DEC Scratch47
    BNE GenerateNextPieceMoves
    PLA
    STA MoveFlags
    PLA
    STA MoveAux
    PLA
    STA MoveToSquare
    PLA
    STA MoveFromSquare
    RTS

; Piece move-generator dispatcher. X is an even piece type; table entries are target-address minus one, pushed then entered with RTS.
DispatchPieceMoveGenerator:
    LDA MoveGeneratorDispatch+1,X
    PHA
    LDA MoveGeneratorDispatch,X
    PHA

EnterDispatchedMoveGenerator:
    RTS

GenerateKingMoves:
    LDA MoveFlags
    PHA
    LDA #&00
    STA MoveAux
    LDA #CASTLE_WHITE_BOTH
    LDY SideToMove
    BEQ MergeKingCastlingFlags
    LDA #CASTLE_BLACK_BOTH

MergeKingCastlingFlags:
    AND CastlingRights
    ORA MoveFlags
    STA MoveFlags
    LDA SideToMove
    BNE GenerateBlackCastles
    LDA CastlingRights
    AND #CASTLE_WHITE_BOTH
    BEQ GenerateOrdinaryKingMoves
    LDA #SQ_E1
    CMP PieceSquareArray
    BNE GenerateOrdinaryKingMoves
    JSR IsSquareAttackedByOpponent
    BNE GenerateOrdinaryKingMoves
    LDA CastlingRights
    AND #CASTLE_WHITE_QUEENSIDE
    BEQ TryWhiteKingsideCastle
    LDA #&FF
    CMP MailboxB1
    BNE TryWhiteKingsideCastle
    CMP MailboxC1
    BNE TryWhiteKingsideCastle
    CMP MailboxD1
    BNE TryWhiteKingsideCastle
    LDA #SQ_D1
    JSR IsSquareAttackedByOpponent
    BNE TryWhiteKingsideCastle
    LDX MailboxA1
    BMI TryWhiteKingsideCastle
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE TryWhiteKingsideCastle
    CPX #&10
    BCS TryWhiteKingsideCastle
    LDA #SQ_C1
    STA MoveToSquare
    JSR CallMoveCallback

TryWhiteKingsideCastle:
    LDA CastlingRights
    AND #CASTLE_WHITE_KINGSIDE
    BEQ GenerateOrdinaryKingMoves
    LDA #&FF
    CMP MailboxF1
    BNE GenerateOrdinaryKingMoves
    CMP MailboxG1
    BNE GenerateOrdinaryKingMoves
    LDA #SQ_F1
    JSR IsSquareAttackedByOpponent
    BNE GenerateOrdinaryKingMoves
    LDX MailboxH1
    BMI GenerateOrdinaryKingMoves
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE GenerateOrdinaryKingMoves
    CPX #&10
    BCS GenerateOrdinaryKingMoves
    LDA #SQ_G1
    STA MoveToSquare
    JSR CallMoveCallback

GenerateOrdinaryKingMoves:
    JMP GenerateKingStepMoves

GenerateBlackCastles:
    LDA CastlingRights
    AND #CASTLE_BLACK_BOTH
    BEQ GenerateOrdinaryKingMoves
    LDA #SQ_E8
    CMP BlackKingSquare
    BNE TryBlackKingsideCastle
    JSR IsSquareAttackedByOpponent
    BNE GenerateKingStepMoves
    BIT CastlingRights
    BVC TryBlackKingsideCastle
    LDA #&FF
    CMP MailboxB8
    BNE TryBlackKingsideCastle
    CMP MailboxC8
    BNE TryBlackKingsideCastle
    CMP MailboxD8
    BNE TryBlackKingsideCastle
    LDX MailboxA8
    BMI TryBlackKingsideCastle
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE TryBlackKingsideCastle
    CPX #&10
    BCC TryBlackKingsideCastle
    LDA #SQ_D8
    JSR IsSquareAttackedByOpponent
    BNE TryBlackKingsideCastle
    LDA #SQ_C8
    STA MoveToSquare
    JSR CallMoveCallback

TryBlackKingsideCastle:
    LDA CastlingRights
    BPL GenerateKingStepMoves
    LDA #&FF
    CMP MailboxF8
    BNE GenerateKingStepMoves
    CMP MailboxG8
    BNE GenerateKingStepMoves
    LDA #SQ_F8
    JSR IsSquareAttackedByOpponent
    BNE GenerateKingStepMoves
    LDX MailboxH8
    BMI GenerateKingStepMoves
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE GenerateKingStepMoves
    CPX #&10
    BCC GenerateKingStepMoves
    LDA #SQ_G8
    STA MoveToSquare
    JSR CallMoveCallback

GenerateKingStepMoves:
    LDY #&00
    JSR GenerateLeaperDirections
    PLA
    STA MoveFlags
    RTS

GenerateQueenMoves:
    JSR GenerateBishopMoves
    LDY #&00
    BEQ GenerateSlidingDirections

GenerateRookMoves:
    LDA MoveFlags
    PHA
    LDA #&10
    CPY #&02
    BEQ MergeRookCastlingFlag
    CPY #&03
    BEQ ShiftRookRightMask3
    CPY #&12
    BEQ ShiftRookRightMask2
    CPY #&13
    BEQ ShiftRookRightMask1
    LDA #&00

ShiftRookRightMask1:
    ASL A

ShiftRookRightMask2:
    ASL A

ShiftRookRightMask3:
    ASL A

MergeRookCastlingFlag:
    AND CastlingRights
    ORA MoveFlags
    STA MoveFlags
    LDY #&00
    JSR GenerateSlidingDirections
    PLA
    STA MoveFlags
    RTS

GenerateBishopMoves:
    LDY #&04

GenerateSlidingDirections:
    LDX #&04

NextSlidingDirection:
    LDA MoveDeltas,Y
    JSR GenerateSlidingRay
    INY
    DEX
    BNE NextSlidingDirection
    RTS

GenerateSlidingRay:
    LDA MoveFromSquare
    STA MoveToSquare
    CLC

NextSquareAlongRay:
    LDA MoveToSquare
    ADC MoveDeltas,Y
    STA MoveToSquare
    JSR TryGenerateDestination
    BCC NextSquareAlongRay
    RTS

GenerateKnightMoves:
    LDY #&08

GenerateLeaperDirections:
    LDX #&08

NextLeaperDirection:
    CLC
    LDA MoveFromSquare
    ADC MoveDeltas,Y
    STA MoveToSquare
    JSR TryGenerateDestination
    INY
    DEX
    BNE NextLeaperDirection
    RTS

GeneratePawnMoves:
    LDY #&F6
    LDA SideToMove
    BNE GeneratePawnForwardMove
    LDY #&0A

GeneratePawnForwardMove:
    TYA
    TAX
    CLC
    ADC MoveFromSquare
    STA MoveToSquare
    TAY
    LDA MailboxBoard,Y
    CMP #MAILBOX_EMPTY
    BNE GeneratePawnCaptures
    LDA #&00
    STA MoveAux
    JSR EmitPawnMoveAndPromotions
    LDA SideToMove
    BEQ CheckWhitePawnDoubleMove
    LDA MoveToSquare
    CMP #&47
    BCS TryPawnDoubleMove
    BCC GeneratePawnCaptures

CheckWhitePawnDoubleMove:
    LDA MoveToSquare
    CMP #&31
    BCS GeneratePawnCaptures

TryPawnDoubleMove:
    PHA
    CLC
    TXA
    ADC MoveToSquare
    STA MoveToSquare
    TAY
    LDA MailboxBoard,Y
    CMP #MAILBOX_EMPTY
    BNE RestorePawnSingleStepTarget
    LDA MoveFlags
    PHA
    ORA #MOVE_DOUBLE_PAWN_FLAG
    STA MoveFlags
    JSR CallMoveCallback
    PLA
    STA MoveFlags

RestorePawnSingleStepTarget:
    PLA
    STA MoveToSquare

GeneratePawnCaptures:
    DEC MoveToSquare
    JSR TryPawnCapture
    INC MoveToSquare
    INC MoveToSquare

TryPawnCapture:
    LDY MoveToSquare
    CPY EnPassantTargetSquare
    BEQ GenerateEnPassantCapture
    LDA MailboxBoard,Y
    BMI PawnCaptureRejected
    TAY
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BNE RecordNormalPawnCapture

PawnCaptureRejected:
    RTS

GenerateEnPassantCapture:
    LDA EnPassantPawnSlot
    STA MoveAux
    BNE CallMoveCallback

RecordNormalPawnCapture:
    STY MoveAux

EmitPawnMoveAndPromotions:
    LDA MoveToSquare
    CMP #&5B
    BCS GeneratePromotionChoices
    CMP #&1D
    BCS CallMoveCallback

GeneratePromotionChoices:
    LDX #&04

GenerateNextPromotion:
    CLC
    LDA MoveAux
    ADC #&20
    STA MoveAux
    JSR CallMoveCallback
    DEX
    BNE GenerateNextPromotion
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    STA MoveAux
    RTS

TryGenerateDestination:
    TYA
    PHA
    TXA
    PHA
    LDY MoveToSquare
    LDA MailboxBoard,Y
    CMP #MAILBOX_OFFBOARD
    BEQ DestinationStopsRay
    CMP #MAILBOX_EMPTY
    BEQ GenerateQuietDestination
    TAX
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BEQ DestinationStopsRay
    STX MoveAux
    JSR CallMoveCallback
    JMP DestinationStopsRay

GenerateQuietDestination:
    LDA #&00
    STA MoveAux
    JSR CallMoveCallback
    CLC
    BCC RestoreMoveGeneratorRegisters

DestinationStopsRay:
    SEC

RestoreMoveGeneratorRegisters:
    PLA
    TAX
    PLA
    TAY

ReturnFromDestinationGenerator:
    RTS

CallMoveCallback:
    JMP (IndirectCallbackPtrLo)

CountGeneratedMove:
    INC Scratch04
    RTS

; Candidate-move callback used by BuildLegalMoveList.
; Temporarily applies the candidate to the mailbox, rejects it if our own king would
; be left in check, appends the move record only when legal, then restores the board.
AppendMoveIfLegal:
    LDA MoveListEndLo
    CMP #<MoveArenaLimit
    LDA MoveListEndHi
    SBC #>MoveArenaLimit
    BCS ReturnFromDestinationGenerator
    TXA
    PHA
    LDY #&00
    LDA MoveFromSquare
    STA (MoveListEndLo),Y
    INY
    LDA MoveToSquare
    STA (MoveListEndLo),Y
    INY
    LDA MoveAux
    STA (MoveListEndLo),Y
    AND #MOVE_CAPTURE_MASK
    BEQ StoreMoveFlagsUnchanged
    TAX
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE StoreMoveFlagsUnchanged
    TXA
    AND #SIDE_SLOT_MASK
    BNE CheckCapturedRookHomeSquare
    LDA PieceSquareArray,X
    CMP #&15
    BEQ RevokeWhiteQueensideCastling
    CMP #&1C
    BEQ RevokeWhiteKingsideCastling
    BNE StoreMoveFlagsUnchanged

CheckCapturedRookHomeSquare:
    LDA PieceSquareArray,X
    CMP #&5B
    BEQ RevokeBlackQueensideCastling
    CMP #&62
    BNE StoreMoveFlagsUnchanged
    LDA #&80
    BNE MergeCapturedRookRightsMask

RevokeBlackQueensideCastling:
    LDA #&40
    BNE MergeCapturedRookRightsMask

RevokeWhiteKingsideCastling:
    LDA #&20
    BNE MergeCapturedRookRightsMask

RevokeWhiteQueensideCastling:
    LDA #&10

MergeCapturedRookRightsMask:
    AND CastlingRights
    ORA MoveFlags
    JMP FinishWritingMoveRecord

StoreMoveFlagsUnchanged:
    LDA MoveFlags

FinishWritingMoveRecord:
    INY
    STA (MoveListEndLo),Y
    INY
    LDA #&00
    STA (MoveListEndLo),Y
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ TemporarilyMakeCandidateMove
    TAY
    LDX PieceSquareArray,Y
    LDA #&FF
    STA MailboxBoard,X

TemporarilyMakeCandidateMove:
    LDY MoveFromSquare
    LDX MailboxBoard,Y
    LDA #&FF
    STA MailboxBoard,Y
    LDY MoveToSquare
    STY PieceSquareArray,X
    TXA
    STA MailboxBoard,Y
    JSR IsSideToMoveInCheck
    BNE RestoreCandidatePosition
    CLC
    LDA MoveListEndLo
    ADC MoveRecordSize
    STA MoveListEndLo
    BCC RestoreCandidatePosition
    INC MoveListEndHi

RestoreCandidatePosition:
    LDY MoveToSquare
    LDX MailboxBoard,Y
    LDA #&FF
    STA MailboxBoard,Y
    LDY MoveFromSquare
    TXA
    STA MailboxBoard,Y
    STY PieceSquareArray,X
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ ReturnFromLegalMoveCallback
    TAX
    LDY PieceSquareArray,X
    STA MailboxBoard,Y

ReturnFromLegalMoveCallback:
    PLA
    TAX
    RTS

; Pop the current move-list frame and restore its parent frame/list pointers.
PopMoveListFrame:
    SEC
    LDA MoveFramePtrLo
    STA MoveListEndLo
    LDA MoveFramePtrHi
    STA MoveListEndHi
    LDY #&00
    LDA (MoveListEndLo),Y
    STA MoveFramePtrLo
    CLC
    ADC #&10
    STA MoveListStartLo
    INY
    LDA (MoveListEndLo),Y
    STA MoveFramePtrHi
    ADC #&00
    STA MoveListStartHi
    RTS

PrintMoveNumberAndNotation:
    LDA PlyCountLo
    AND #&01
    BEQ PrintFullMoveNumber
    LDA #&2C
    JMP PrintMoveNumberSeparator

PrintFullMoveNumber:
    LDA PlyCountHi
    LSR A
    TAX
    LDA PlyCountLo
    ROR A
    TAY
    INY
    BNE StoreMoveNumberForDecimalPrint
    INX

StoreMoveNumberForDecimalPrint:
    STX Scratch08
    STY Scratch07
    JSR PrintWordDecimal
    LDA #&2E

PrintMoveNumberSeparator:
    JSR OSWRCH
    LDA SearchUndoStack
    STA MoveFromSquare
    LDA SearchUndoToBase
    STA MoveToSquare
    LDA SearchUndoAuxBase
    STA MoveAux

PrintMoveNotation:
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BNE PrintMoveCoordinates
    LDY MoveToSquare
    LDA MailboxBoard,Y
    TAX
    LDA PieceTypeArray,X
    CMP #PIECE_KING
    BNE PrintMovingPieceLetter
    LDA MoveFromSquare
    SEC
    SBC MoveToSquare
    CMP #&02
    BNE TestKingsideCastleNotation
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &4F,&2D,&4F,&2D,&4F,&20 ; O-O-O 
    NOP
    JMP AppendCheckOrMateMarker

TestKingsideCastleNotation:
    CMP #&FE
    BNE PrintMovingPieceLetter
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&4F,&2D,&4F,&20 ;   O-O 
    NOP
    JMP AppendCheckOrMateMarker

PrintMovingPieceLetter:
    LDA PieceTypeArray,X
    TAX
    LDA PieceLetters,X
    AND #&DF
    CMP #&50
    BNE OutputMovingPieceLetter
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BNE PrintMoveCoordinates
    LDA #&20

OutputMovingPieceLetter:
    JSR OSWRCH

PrintMoveCoordinates:
    LDA MoveFromSquare
    JSR PrintSquareCoordinate
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ PrintMoveSeparator
    LDA #&55

PrintMoveSeparator:
    EOR #&2D
    JSR OSWRCH
    LDA MoveToSquare
    JSR PrintSquareCoordinate
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BEQ AppendCheckOrMateMarker
    LSR A
    LSR A
    LSR A
    LSR A
    TAY
    LDA PieceLetters,Y
    AND #&DF
    JSR OSWRCH

AppendCheckOrMateMarker:
    JSR IsSideToMoveInCheck
    BEQ PrintTrailingMoveSpace
    JSR BuildLegalMoveList5
    LDA MoveListEndLo
    CMP MoveListStartLo
    BNE PrintCheckMarker
    LDA MoveListEndHi
    CMP MoveListStartHi
    BNE PrintCheckMarker
    JSR PopMoveListFrame
    LDA #&23
    JMP OSWRCH

PrintCheckMarker:
    JSR PopMoveListFrame
    LDA #&2B
    JMP OSWRCH

PrintTrailingMoveSpace:
    LDA #&20
    JMP OSWRCH

PrintSquareCoordinate:
    SEC
    SBC #&15
    PHA
    LDA #&30
    STA Scratch3B
    PLA

ConvertMailboxSquareToNotationLoop:
    SEC
    INC Scratch3B
    SBC #&0A
    BPL ConvertMailboxSquareToNotationLoop
    ADC #&6B
    JSR OSWRCH
    LDA Scratch3B
    JMP OSWRCH

PrintWordDecimal:
    LDA #&00
    STA Scratch09
    LDA #&E8
    LDY #&03
    JSR DivideDecimalPlace
    LDA #&64
    LDY #&00
    JSR DivideDecimalPlace
    LDY #&20
    TXA
    BEQ PrintHundredsOrBlank
    DEC Scratch09
    CLC
    ADC #&30
    TAY

PrintHundredsOrBlank:
    TYA
    JSR OSWRCH
    LDA #DECIMAL_TEN
    LDY #&00
    JSR DivideDecimalPlace
    TXA
    BNE PrintTensDigit
    LDA #&20
    BIT Scratch09
    BPL PrintTensPlaceBlankOrZero
    LDA #&30

PrintTensPlaceBlankOrZero:
    JSR OSWRCH
    JMP PrintUnitsDigit

PrintTensDigit:
    CLC
    ADC #&30
    JSR OSWRCH

PrintUnitsDigit:
    LDA Scratch07
    CLC
    ADC #&30
    JMP OSWRCH

DivideDecimalPlace:
    STA Scratch04
    STY Scratch03
    LDX #&FF

DivideDecimalSubtractLoop:
    INX
    SEC
    LDA Scratch07
    SBC Scratch04
    TAY
    LDA Scratch08
    SBC Scratch03
    BCC ReturnFromDecimalDivision
    STA Scratch08
    STY Scratch07
    BCS DivideDecimalSubtractLoop

ReturnFromDecimalDivision:
    RTS

PrintUnsignedNumber:
    LDX #&30

CountUnsignedDecimalTens:
    CMP #DECIMAL_TEN
    BCC EmitUnsignedTensIfNeeded
    SBC #&0A
    INX
    BNE CountUnsignedDecimalTens

EmitUnsignedTensIfNeeded:
    CPX #&30
    BEQ EmitUnsignedUnitsDigit
    PHA
    TXA
    CMP #&3A
    BCC EmitUnsignedTensDigit
    SBC #&0A

EmitUnsignedTensDigit:
    JSR OSWRCH
    PLA

EmitUnsignedUnitsDigit:
    CLC
    ADC #&30
    JMP OSWRCH

; Inline OSFILE wrapper. 19 bytes immediately following each JSR are data: 18-byte parameter block + reason code.
InlineOSFILE:
    PLA
    STA InlineOSFileReturnPtrLo
    PLA
    STA InlineOSFileReturnPtrHi
    LDX #&11
    LDY #&12

CopyInlineOSFILEParameterBlock:
    LDA (InlineOSFileReturnPtrLo),Y
    STA MOSParameterBlock,X
    DEY
    DEX
    BPL CopyInlineOSFILEParameterBlock
    LDA #&82
    JSR OSBYTE
    STX OSFileLoadAddressBank
    STX OSFileExecAddressBank
    STX OSFileStartAddressBank
    STX OSFileEndAddressBank
    STY OSFileLoadAddressTop
    STY OSFileExecAddressTop
    STY OSFileStartAddressTop
    STY OSFileEndAddressTop
    LDY #&13
    LDA (InlineOSFileReturnPtrLo),Y
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    JSR OSFILE
    LDA InlineOSFileReturnPtrLo
    CLC
    ADC #&14
    STA InlineOSFileReturnPtrLo
    LDA InlineOSFileReturnPtrHi
    ADC #&00
    STA InlineOSFileReturnPtrHi
    JMP (InlineOSFileReturnPtrLo)

RandomByte:
    LDA RandomState0
    AND #&48
    ADC #&38
    ASL A
    ASL A
    ROL RandomState2
    ROL RandomState1
    ROL RandomState0
    LDA RandomState0
    RTS

ReadUppercaseChar:
    JSR OSRDCH
    BCS EchoUppercaseChar
    CMP #&60
    BCC EchoUppercaseChar
    SBC #&20

EchoUppercaseChar:
    JMP OSASCI

; Inline VDU/text printer. Bytes immediately following JSR PrintInline are written with OSWRCH until an &EA terminator.
PrintInline:
    PLA
    STA InlineTextPtrLo
    PLA
    STA InlineTextPtrHi
    JMP AdvanceInlineTextPointer

PrintNextInlineByte:
    LDY #&00
    LDA (InlineTextPtrLo),Y
    CMP #&EA
    BEQ ResumeAfterInlineData
    JSR OSWRCH

AdvanceInlineTextPointer:
    INC InlineTextPtrLo
    BNE ContinueInlinePrint
    INC InlineTextPtrHi

ContinueInlinePrint:
    JMP PrintNextInlineByte

ResumeAfterInlineData:
    JMP (InlineTextPtrLo)

ReadAndEchoGameKey:
    JSR ReadGameKey
    PHP
    CMP #&20
    BCC ReturnFromEchoedGameKey
    PHA
    JSR RestoreActiveTextWindow
    PLA
    JSR OSASCI

ReturnFromEchoedGameKey:
    PLP
    RTS

PrintChessClock:
    LDA ClockHoursBase,Y
    JSR PrintUnsignedNumber
    LDA #&3A
    JSR OSWRCH
    LDA ClockMinutesBase,Y
    CMP #DECIMAL_TEN
    BCS PrintClockMinutes
    LDA #&30
    JSR OSWRCH
    LDA ClockMinutesBase,Y

PrintClockMinutes:
    JSR PrintUnsignedNumber
    LDA #&3A
    JSR OSWRCH
    LDA ClockSecondsBase,Y
    CMP #DECIMAL_TEN
    BCS PrintClockSeconds
    LDA #&30
    JSR OSWRCH
    LDA ClockSecondsBase,Y

PrintClockSeconds:
    JMP PrintUnsignedNumber

; Installs EventHandler in EVNTV (&0220/&0221).
InstallEventHandler:
    BIT ModernMOSEventFlag
    BPL ProgramEventTimer
    LDA #<EventHandler
    STA EVNTV
    LDA #>EventHandler
    STA EVNTV+1

ProgramEventTimer:
    LDA #&04
    LDX #<EventTimerBlock
    LDY #>EventTimerBlock
    JMP OSWORD

; OS event handler. Handles events 5 and 6 and maintains chess-clock state.
EventHandler:
    PHP
    STA Scratch06
    TXA
    PHA
    TYA
    PHA
    LDA Scratch06
    CMP #EVENT_INTERVAL_TIMER
    BEQ HandleIntervalTimerEvent
    CMP #EVENT_ESCAPE
    BEQ HandleEscapeEvent

RestoreEventRegistersAndReturn:
    PLA
    TAY
    PLA
    TAX
    LDA Scratch06
    PLP
    RTS

HandleEscapeEvent:
    BIT EventSuppressionFlags
    BVS RestoreEventRegistersAndReturn
    LDA #&FF
    STA SearchAbortFlag
    BMI RestoreEventRegistersAndReturn

HandleIntervalTimerEvent:
    BIT EventSuppressionFlags
    BMI RestoreEventRegistersAndReturn
    LDA #&FF
    STA ClockTickPending
    BMI RestoreEventRegistersAndReturn

UpdateChessClock:
    LDX ActiveClockSideOffset
    CLC
    LDA ClockSecondsBase,X
    ADC #&01
    CMP #&3C
    BCS CarrySecondsIntoMinutes
    STA ClockSecondsBase,X

RescheduleIntervalTimer:
    LDX #<FilenameBuffer
    LDY #>FilenameBuffer
    LDA #&03
    JSR OSWORD
    LDY #&05
    LDX #&00
    LDA #&9C
    CLC

AdjustIntervalTimerByte:
    ADC IntervalTimerPawnWorkspace,X
    STA IntervalTimerPawnWorkspace,X
    LDA #&FF
    INX
    DEY
    BNE AdjustIntervalTimerByte
    LDX #<FilenameBuffer
    LDY #>FilenameBuffer
    LDA #&04
    JMP OSWORD

CarrySecondsIntoMinutes:
    LDA #&00
    STA ClockSecondsBase,X
    LDA ClockMinutesBase,X
    ADC #&00
    CMP #&3C
    BCS CarryMinutesIntoHours
    STA ClockMinutesBase,X
    BNE RescheduleIntervalTimer

CarryMinutesIntoHours:
    LDA #&00
    STA ClockMinutesBase,X
    LDA ClockHoursBase,X
    ADC #&00
    CMP #DECIMAL_TEN
    BCS WrapClockHours
    BNE StoreClockHours

WrapClockHours:
    LDA #&00

StoreClockHours:
    STA ClockHoursBase,X
    JMP RescheduleIntervalTimer

; -----------------------------------------------------------------------------
; Data &1D29-&1D2D: OSWORD interval/event timer parameter block
; -----------------------------------------------------------------------------

EventTimerBlock:
    EQUB &9C,&FF,&FF,&FF,&FF

ServicePendingClockTick:
    LDX #&00
    LDA ClockTickPending
    BEQ ReturnFromClockTickService
    STX ClockTickPending
    JSR UpdateChessClock
    LDA IntervalTimerSignByte
    BMI RedrawClockAfterTick
    DEC ClockTickPending

RedrawClockAfterTick:
    LDA #&86
    JSR OSBYTE
    TYA
    PHA
    TXA
    PHA
    JSR DrawChessClocks
    LDA #&00
    JSR PlayTickSoundIfEnabled
    JSR RestoreActiveTextWindow
    LDA #&1F
    JSR OSWRCH
    PLA
    JSR OSWRCH
    PLA
    JMP OSWRCH

ReturnFromClockTickService:
    RTS

PlayTickSoundIfEnabled:
    BIT TickSoundOffFlag
    BMI ReturnFromClockTickService

PlaySoundEffect:
    ASL A
    ASL A
    ASL A
    ADC #&07
    TAX
    LDY #&07

CopySoundBlockByte:
    LDA SoundParameterBlocks,X
    STA MOSParameterBlock,Y
    DEX
    DEY
    BPL CopySoundBlockByte
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&07
    JMP OSWORD

SetPlaybackKeyRepeatFromShift:
    LDY #&FF
    LDA #&81
    LDX #&FF
    JSR OSBYTE
    TXA
    BMI SetFastKeyboardRepeat

SetSlowKeyboardRepeat:
    LDA #&0C
    LDX #&00
    JSR OSBYTE
    LDA #&0C
    LDX #&3C
    JMP OSBYTE

TailCallKeyboardRepeatOSBYTE:
    JMP OSBYTE

SetFastKeyboardRepeat:
    LDA #&0B
    LDX #&16
    JSR OSBYTE
    LDA #&0C
    LDX #&05
    JMP OSBYTE

ReadGameKey:
    TXA
    PHA
    TYA
    PHA

ReadGameKeyLoop:
    BIT CursorBlinkSuppressedFlag
    BPL BeginCursorBlinkCycle
    LDA EventSuppressionFlags
    BNE StirRandomStateAndServiceInput
    BIT CursorOffFlag
    BMI StirRandomStateAndServiceInput

BeginCursorBlinkCycle:
    LDX #&02

CursorBlinkCycle:
    TXA
    PHA
    LDA BoardSquareColourXor
    EOR CursorFlashXorMask
    STA BoardSquareColourXor
    JSR WaitCursorFlashInterval
    LDA EditorCursorSquare
    JSR DrawMailboxSquare
    PLA
    TAX
    DEX
    BNE CursorBlinkCycle

StirRandomStateAndServiceInput:
    INC RandomState0
    DEC RandomState1
    LDA RandomState2
    EOR RandomState1
    EOR #&83
    STA RandomState2
    BIT EventSuppressionFlags
    BMI PollJoystickOrKeyboard
    JSR ServicePendingClockTick
    LDA EditorModeActiveFlag
    ORA EventSuppressionFlags
    BNE PollJoystickOrKeyboard
    JSR SnapshotChessClocks

PollJoystickOrKeyboard:
    BIT JoysticksOffFlag
    BMI PollKeyboardInput
    JSR PollJoystickAxes
    LDY SideToMove
    BEQ CheckWhiteJoystickFire
    LDA Joystick1FireState
    BPL ReturnJoystickFireAsEnter
    BMI SelectCurrentJoystickSquare

CheckWhiteJoystickFire:
    LDA Joystick2FireState
    BPL ReturnJoystickFireAsEnter

SelectCurrentJoystickSquare:
    LDX #&04
    TYA
    BNE CopyJoystickSquareToCursor
    LDX #&06

CopyJoystickSquareToCursor:
    LDA JoystickSquareSelectBase,X
    STA EditorCursorSquare
    JMP PollKeyboardInput

ReturnJoystickFireAsEnter:
    LDA #&0D
    BNE UppercaseInputCharacter

PollKeyboardInput:
    LDY #&00
    LDX #&00
    LDA #&81
    JSR OSBYTE
    TYA
    BEQ UseKeyboardCharacter
    BIT SearchAbortFlag
    BMI ConvertEscapeOrAbortToEscapeKey
    INY
    BNE ConvertEscapeOrAbortToEscapeKey
    JMP ReadGameKeyLoop

UseKeyboardCharacter:
    TXA

UppercaseInputCharacter:
    CMP #&60
    BCC StoreInputResultClearCarry
    CMP #&7F
    BCS StoreInputResultClearCarry
    SEC
    SBC #&20

StoreInputResultClearCarry:
    STA Scratch04
    CLC

RestoreInputRegistersAndFlags:
    PHP
    PLA
    STA Scratch03
    LDA EventSuppressionFlags
    BNE RestoreInputReturnFlags
    LDA #&00
    STA BoardSquareColourXor
    JSR WaitCursorFlashInterval
    LDA EditorCursorSquare
    JSR DrawMailboxSquare

RestoreInputReturnFlags:
    LDA Scratch03
    PHA
    PLP
    PLA
    TAY
    PLA
    TAX
    LDA Scratch04
    RTS

ConvertEscapeOrAbortToEscapeKey:
    LDA #&7E
    JSR OSBYTE
    LDA #&00
    STA SearchAbortFlag
    LDA #&1B
    STA Scratch04
    SEC
    BCS RestoreInputRegistersAndFlags

RestoreActiveTextWindow:
    LDX CurrentTextWindowId
    BNE TestStatusWindowId
    JMP SelectMoveTextWindow

TestStatusWindowId:
    DEX
    BNE TestFromSquareWindowId
    JMP SelectStatusTextWindow

TestFromSquareWindowId:
    DEX
    BNE TestToSquareWindowId
    JMP SelectFromSquareWindow

TestToSquareWindowId:
    DEX
    BNE TestLeftHistoryWindowId
    JMP SelectToSquareWindow

TestLeftHistoryWindowId:
    DEX
    BNE TestRightHistoryWindowId
    JMP SelectLeftMoveHistoryWindow

TestRightHistoryWindowId:
    DEX
    BNE TestEndGameWindowId
    JMP SelectRightMoveHistoryWindow

TestEndGameWindowId:
    DEX
    BNE RestoreMainTextWindow
    JMP SelectEndGameWindow

RestoreMainTextWindow:
    JMP SelectMainTextWindow

RedrawAfterUnmakeMove:
    LDA MoveToSquare
    JSR DrawMailboxSquare
    LDA MoveFromSquare
    JSR DrawMailboxSquare
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ CheckUnmadeCastlingRook
    TAX
    LDA PieceSquareArray,X
    CMP MoveToSquare
    BEQ CheckUnmadeCastlingRook
    JMP DrawMailboxSquare

CheckUnmadeCastlingRook:
    LDY MoveFromSquare
    LDA MailboxBoard,Y
    BMI ReturnAfterUnmakeRedraw
    AND #PIECE_SLOT_INDEX_MASK
    BNE ReturnAfterUnmakeRedraw
    LDA MoveFromSquare
    SEC
    SBC MoveToSquare
    CMP #&02
    BEQ RedrawUnmadeQueensideCastleRook
    CMP #&FE
    BEQ RedrawUnmadeKingsideCastleRook

ReturnAfterUnmakeRedraw:
    RTS

RedrawUnmadeQueensideCastleRook:
    LDX MoveToSquare
    INX
    TXA
    JSR DrawMailboxSquare
    LDX MoveToSquare
    DEX
    DEX
    TXA
    JSR DrawMailboxSquare
    RTS

RedrawUnmadeKingsideCastleRook:
    LDX MoveToSquare
    DEX
    TXA
    JSR DrawMailboxSquare
    LDX MoveToSquare
    INX
    TXA
    JSR DrawMailboxSquare
    RTS

WaitForVerticalSync:
    PHA
    TXA
    PHA
    TYA
    PHA
    BIT ModernMOSEventFlag
    BMI WaitVerticalSyncViaOSBYTE
    LDA #&02
    SEI

WaitLegacyVerticalSyncBit:
    BIT SYSVIA_IFR
    BEQ WaitLegacyVerticalSyncBit
    CLI

RestoreVerticalSyncRegisters:
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

WaitVerticalSyncViaOSBYTE:
    LDA #&13
    JSR OSBYTE
    JMP RestoreVerticalSyncRegisters

BusyDelayXY:
    DEX
    BNE BusyDelayXY
    DEY
    BNE BusyDelayXY

ReturnFromBusyDelay:
    RTS

WaitCursorFlashInterval:
    LDX #&00
    LDY #&20
    JSR BusyDelayXY
    JSR WaitForVerticalSync
    BIT SecondProcessorFlag
    BMI ReturnFromBusyDelay
    LDY #&16
    JMP BusyDelayXY

FlashSquare:
    BIT CursorOffFlag
    BMI ReturnFromFlashSquare
    STA FlashingSquare

AnimateFlashingSquare:
    LDX #&08
    BIT SecondProcessorFlag
    BPL StoreFlashCycleCount
    LDX #&0E

StoreFlashCycleCount:
    STX FlashCycleCount

FlashSquareCycle:
    LDA BoardSquareColourXor
    EOR #&01
    STA BoardSquareColourXor
    LDA FlashingSquare
    JSR DrawMailboxSquare
    JSR WaitCursorFlashInterval
    DEC FlashCycleCount
    BNE FlashSquareCycle

ReturnFromFlashSquare:
    RTS

RedrawDestinationWithoutFlash:
    LDA MoveToSquare
    STA FlashingSquare
    JSR DrawMailboxSquare
    JMP RedrawCaptureOrCastleAfterMake

DisplayCommittedMove:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11,&01
    NOP
    JSR PrintLastMoveToHistoryWindow

RedrawAfterMakeMove:
    LDA MoveFromSquare
    JSR DrawMailboxSquare
    BIT CursorOffFlag
    BMI RedrawDestinationWithoutFlash
    LDA MoveToSquare
    STA FlashingSquare
    JSR AnimateFlashingSquare

RedrawCaptureOrCastleAfterMake:
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ CheckCastleRookForRedraw
    TAX
    LDA PieceSquareArray,X
    CMP MoveToSquare
    BEQ RestoreMoveDisplayWindowAndReturn
    JSR DrawMailboxSquare

RestoreMoveDisplayWindowAndReturn:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1F,&13,&1E,&11,&01
    NOP
    RTS

CheckCastleRookForRedraw:
    LDX MoveToSquare
    LDA MailboxBoard,X
    BMI RestoreMoveDisplayWindowAndReturn
    AND #PIECE_SLOT_INDEX_MASK
    BNE RestoreMoveDisplayWindowAndReturn
    LDA MoveFromSquare
    SEC
    SBC MoveToSquare
    CMP #&02
    BEQ RedrawQueensideCastleRook
    CMP #&FE
    BEQ RedrawKingsideCastleRook
    BNE RestoreMoveDisplayWindowAndReturn

RedrawQueensideCastleRook:
    LDX MoveToSquare
    DEX
    DEX
    TXA
    JSR DrawMailboxSquare
    JSR FlashSquare
    LDX MoveToSquare
    INX
    TXA
    JSR DrawMailboxSquare
    JSR FlashSquare
    JMP RestoreMoveDisplayWindowAndReturn

RedrawKingsideCastleRook:
    LDX MoveToSquare
    INX
    TXA
    JSR DrawMailboxSquare
    JSR FlashSquare
    LDX MoveToSquare
    DEX
    TXA
    JSR DrawMailboxSquare
    JSR FlashSquare
    JMP RestoreMoveDisplayWindowAndReturn

DrawChessBoard:
    LDX #&03
    JSR BlankLogicalColours1ToX
    JSR DrawChessClocks
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &19,&04,&70,&00,&F8,&03,&0A,&20,&20
    NOP
    LDX #&38

DrawNextBoardRankLabel:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &05,&08,&0A,&0A,&0A
    NOP
    TXA
    JSR OSWRCH
    DEX
    CPX #&30
    BNE DrawNextBoardRankLabel
    JSR DrawBoardFileLabels
    LDY #&50

DrawNextBoardRank:
    LDX #&08

DrawNextBoardFileSquare:
    JSR DrawBoardSquareFromIndex
    INY
    DEX
    BNE DrawNextBoardFileSquare
    TYA
    SEC
    SBC #&12
    TAY
    BNE DrawNextBoardRank
    JSR SelectStatusTextWindow
    LDA #&0C
    JSR OSWRCH
    LDX #&01
    LDY #&06
    JSR SetLogicalColourMapping
    LDX #&02
    LDY #&05
    JSR SetLogicalColourMapping
    LDX #&03
    LDY #&07

SetLogicalColourMapping:
    LDA #&13
    JSR OSWRCH
    TXA
    JSR OSWRCH
    TYA
    JSR OSWRCH
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &00,&00,&00
    NOP
    RTS

BlankLogicalColours1ToX:
    LDA #&13
    JSR OSWRCH
    TXA
    JSR OSWRCH
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &00,&00,&00,&00
    NOP
    DEX
    BNE BlankLogicalColours1ToX
    RTS

DrawBoardFileLabels:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &05,&19,&04,&58,&00,&B0,&00
    NOP
    LDA #&61
    STA Scratch3B
    LDX #&08

DrawNextBoardFileLabel:
    LDA #&20
    JSR OSWRCH
    LDA Scratch3B
    JSR OSWRCH
    INC Scratch3B
    DEX
    BNE DrawNextBoardFileLabel
    LDA #&04
    JMP OSWRCH

DivideMailboxSquareBy10:
    LDX #&FF
    SEC

DivideMailboxSquareBy10Loop:
    INX
    SBC #&0A
    BCS DivideMailboxSquareBy10Loop
    RTS

DrawMailboxSquare:
    SEC
    SBC #DRAW_SQUARE_INDEX_BIAS
    TAY

DrawBoardSquareFromIndex:
    TXA
    PHA
    TYA
    PHA
    JSR DivideMailboxSquareBy10
    TAY
    TXA
    PHA
    TYA
    ADC #&0A
    PHA
    ASL A
    ADC #&02
    PHA
    LDA #&1A
    JSR OSWRCH
    PLA
    TAY
    TXA
    ASL A
    STA Scratch3B
    TXA
    ADC Scratch3B
    TAX
    LDA #&1F
    JSR OSWRCH
    TYA
    JSR OSWRCH
    STX Scratch3B
    LDA #&1A
    SEC
    SBC Scratch3B
    JSR OSWRCH
    PLA
    STA Scratch3B
    PLA
    LDX #&82
    EOR Scratch3B
    EOR BoardSquareColourXor
    AND #&01
    BNE SetBoardSquareBackgroundColour
    LDX #&81

SetBoardSquareBackgroundColour:
    LDA #&11
    JSR OSWRCH
    TXA
    JSR OSWRCH
    LDX #&00
    PLA
    PHA
    TAY
    LDA MailboxBoard+DRAW_SQUARE_INDEX_BIAS,Y
    CMP #MAILBOX_EMPTY
    BNE PrepareOccupiedSquareGlyph
    LDY #&0E
    BNE SelectPieceGlyphRow

PrepareOccupiedSquareGlyph:
    TAY
    AND #&10
    BNE SetPieceTextColour
    LDX #&03

SetPieceTextColour:
    LDA #&11
    JSR OSWRCH
    TXA
    JSR OSWRCH
    LDA PieceTypeArray,Y
    TAY

SelectPieceGlyphRow:
    STY Scratch3B
    LDX #&03

DrawPieceGlyphRow:
    LDA PieceGlyphPairs,Y
    JSR OSWRCH
    LDA PieceGlyphPairs+1,Y
    JSR OSWRCH
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&08,&08
    NOP
    CLC
    LDA Scratch3B
    ADC #&10
    STA Scratch3B
    TAY
    DEX
    BNE DrawPieceGlyphRow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11,&80,&11,&07
    NOP
    PLA
    TAY
    PLA
    TAX
    RTS

ClearRightMoveHistoryWindow:
    LDA #&05
    STA CurrentTextWindowId
    JSR SelectRightMoveHistoryWindow
    LDA #&0C
    JMP OSWRCH

SelectRightMoveHistoryWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&0B,&1F,&13,&1D,&1E
    NOP
    RTS

ClearLeftMoveHistoryWindow:
    LDA #&04
    STA CurrentTextWindowId
    JSR SelectLeftMoveHistoryWindow
    LDA #&0C
    JMP OSWRCH

SelectLeftMoveHistoryWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1F,&13,&1D,&1E
    NOP
    RTS

PrintLastMoveToHistoryWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11,&01
    NOP
    LDA PlyCountLo
    AND #&01
    BNE UseLeftMoveHistoryWindow
    LDA #&05
    STA CurrentTextWindowId
    JSR SelectRightMoveHistoryWindow
    JMP FormatRecentMoveHistory

UseLeftMoveHistoryWindow:
    LDA #&04
    STA CurrentTextWindowId
    JSR SelectLeftMoveHistoryWindow

FormatRecentMoveHistory:
    LDA PlyCountHi
    BNE ScrollOlderMoveHistory
    LDX #VDU_LF
    LDA PlyCountLo
    CMP #&03
    BCC StepBackOnePlyAndPrintMove
    TXA
    JSR OSWRCH
    LDA PlyCountLo
    CMP #&05
    BCC StepBackOnePlyAndPrintMove
    TXA
    JSR OSWRCH
    LDA PlyCountLo
    CMP #&07
    BCC StepBackOnePlyAndPrintMove
    AND #&01
    BEQ StepBackOnePlyAndPrintMove
    TXA
    JSR OSWRCH

StepBackOnePlyAndPrintMove:
    LDA PlyCountLo
    BNE DecrementPlyAndPrintMove
    DEC PlyCountHi

DecrementPlyAndPrintMove:
    DEC PlyCountLo
    JSR PrintMoveNumberAndNotation

SelectStatusWindowAndRemember:
    LDA #&01
    STA CurrentTextWindowId

SelectStatusTextWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1C,&13,&1C,&11,&03
    NOP
    RTS

ScrollOlderMoveHistory:
    LDX #&03
    LDA PlyCountLo
    LSR A
    BCS EmitMoveHistoryLineFeed
    DEX

EmitMoveHistoryLineFeed:
    LDA #VDU_LF
    JSR OSWRCH
    DEX
    BNE EmitMoveHistoryLineFeed
    JMP StepBackOnePlyAndPrintMove

SelectMoveTextWindow:
    LDA #&00
    STA CurrentTextWindowId
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1F,&13,&1E,&11,&01
    NOP
    RTS

SelectMainTextWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1F,&13,&1D
    NOP
    RTS

ValidateBoardConsistency:
    LDX #&15

ScanMailboxConsistency:
    LDA MailboxBoard,X
    CMP #MAILBOX_OFFBOARD
    BEQ AdvanceMailboxConsistencyScan
    CMP #MAILBOX_EMPTY
    BEQ AdvanceMailboxConsistencyScan
    CMP #&20
    BCS InternalErrorBRK
    TAY
    LDA PieceTypeArray,Y
    CMP #&0B
    BCS InternalErrorBRK
    LDA PieceSquareArray,Y
    STA Scratch3B
    CPX Scratch3B
    BNE InternalErrorBRK

AdvanceMailboxConsistencyScan:
    INX
    CPX #&63
    BNE ScanMailboxConsistency
    LDX #PIECE_SLOT_LAST

ScanPieceArrayConsistency:
    LDA PieceTypeArray,X
    BMI AdvancePieceConsistencyScan
    LDA PieceSquareArray,X
    TAY
    LDA MailboxBoard,Y
    STA Scratch3B
    CPX Scratch3B
    BNE InternalErrorBRK

AdvancePieceConsistencyScan:
    DEX
    CPX #&00
    BPL ScanPieceArrayConsistency
    RTS

InternalErrorBRK:
    BRK

; -----------------------------------------------------------------------------
; Data &2247-&2256: MOS BRK error number/text payload: "Internal Error"
; -----------------------------------------------------------------------------
    EQUB &00,&49,&6E,&74,&65,&72,&6E,&61,&6C,&20,&45,&72,&72,&6F,&72,&00 ; .Internal Error.

DrawChessClocks:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1A,&1E,&0A,&20,&20,&11
    NOP
    LDX #&00
    LDA ActiveClockSideOffset
    JSR SetClockTextColour
    LDY #&00
    JSR PrintChessClock
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &11
    NOP
    LDX #&20
    LDA ActiveClockSideOffset
    EOR #&10
    JSR SetClockTextColour
    LDA #&20
    JSR OSWRCH
    LDY #&10
    JSR PrintChessClock
    LDA #&20
    JSR OSWRCH
    LDA #&11
    JSR OSWRCH
    LDA #&03
    JMP OSWRCH

SetClockTextColour:
    BEQ UseInactiveClockColour
    LDA #&02
    BNE EmitClockColourAndOffset

UseInactiveClockColour:
    LDA #&03

EmitClockColourAndOffset:
    JSR OSWRCH
    TXA
    JMP OSWRCH

RestartAfterMoveInput:
    JMP ChessRuntimeEntry

CancelPromotionInput:
    PLA

AbortHumanMoveInput:
    JSR SetSlowKeyboardRepeat
    JSR ReturnToMainMenuFromMoveInput
    BCS RestartAfterMoveInput
    LDA #&0C
    JSR OSWRCH

ReadHumanMove:
    JSR SelectStatusWindowAndRemember
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&20,&20,&20
    NOP
    LDY #&57
    LDA SideToMove
    AND #&10
    BEQ EmitSideToMoveLetter
    LDY #&42

EmitSideToMoveLetter:
    TYA
    JSR OSWRCH
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&4D,&6F,&76,&65,&3A ;  Move:
    NOP

ReadHumanFromSquare:
    JSR SelectFromSquareInputWindow
    JSR ReadBoardSquare
    BCS AbortHumanMoveInput
    BEQ RejectHumanMove
    STA MoveFromSquare
    LDA #&2D
    JSR OSWRCH
    JSR SelectToSquareInputWindow
    JSR ReadBoardSquare
    BCS AbortHumanMoveInput
    BEQ RejectHumanMove
    STA MoveToSquare
    LDA MoveListStartLo
    STA HumanMoveScanPtrLo
    LDA MoveListStartHi
    STA HumanMoveScanPtrHi

ScanLegalMoveForHumanInput:
    LDY #&00
    LDA (HumanMoveScanPtrLo),Y
    CMP MoveFromSquare
    BNE AdvanceLegalMoveCandidate
    INY
    LDA (HumanMoveScanPtrLo),Y
    CMP MoveToSquare
    BNE AdvanceLegalMoveCandidate
    INY
    LDA (HumanMoveScanPtrLo),Y
    STA MoveAux
    AND #MOVE_PROMOTION_MASK
    BEQ LoadSelectedMoveFlags
    TYA
    PHA
    JSR SelectStatusWindowAndRemember
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0D,&50,&72,&6F,&6D,&6F,&74,&65,&20,&69,&6E,&74,&6F,&3F,&20 ; .Promote into? 
    NOP
    JSR SelectToSquareInputWindow
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    STA MoveAux
    JSR ReadAndEchoGameKey
    BCC DecodePromotionChoice
    JMP CancelPromotionInput

DecodePromotionChoice:
    TAY
    LDA #&1F
    CPY #&51
    BEQ MergePromotionChoice
    CPY #&52
    BEQ PromotionChoiceRookOffset
    CPY #&42
    BEQ PromotionChoiceBishopOffset
    CPY #&4E
    BEQ PromotionChoiceKnightOffset
    PLA

RejectHumanMove:
    JMP RetryRejectedHumanMove

PromotionChoiceKnightOffset:
    ADC #&20

PromotionChoiceBishopOffset:
    ADC #&20

PromotionChoiceRookOffset:
    ADC #&20

MergePromotionChoice:
    ADC MoveAux
    STA MoveAux
    PLA
    TAY

LoadSelectedMoveFlags:
    INY
    LDA (HumanMoveScanPtrLo),Y
    STA MoveFlags

FinishHumanMoveInput:
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C
    NOP
    JSR SelectStatusWindowAndRemember
    JSR SetSlowKeyboardRepeat
    JMP PopMoveListFrame

AdvanceLegalMoveCandidate:
    CLC
    LDA Scratch46
    ADC #&05
    STA Scratch46
    LDA Scratch47
    ADC #&00
    STA Scratch47
    CMP MoveListEndHi
    BEQ TestLegalMoveScanEnd

ContinueLegalMoveScan:
    JMP ScanLegalMoveForHumanInput

TestLegalMoveScanEnd:
    LDA Scratch46
    CMP MoveListEndLo
    BNE ContinueLegalMoveScan

RetryRejectedHumanMove:
    LDA EngineStopFlag
    BNE CancelHumanMoveOnEngineStop
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&54,&72,&79,&20,&61,&67,&61,&69,&6E,&3A ; .Try again:
    NOP
    JMP ReadHumanFromSquare

CancelHumanMoveOnEngineStop:
    LDA #&00
    STA MoveFromSquare
    BEQ FinishHumanMoveInput

ReturnToMainMenuFromMoveInput:
    JMP ChessRuntimeEntry

ReadBoardSquare:
    LDA #&FF
    STA MoveToSquare

ReadBoardSquareCommon:
    JSR ReadGameKey
    BCS ReturnAcceptedBoardSquare
    BIT JoystickADCWorkspaceBase
    BMI FinishBoardSquareInput
    CMP #&88
    BCC FinishBoardSquareInput
    CMP #&8C
    BCS FinishBoardSquareInput
    SBC #&89
    BPL MoveCursorUpRank
    ASL A
    ADC #&02
    STA Scratch04
    LDA EditorCursorSquare
    CLC
    ADC Scratch04

AcceptCursorSquareIfPlayable:
    TAX
    LDA MailboxBoard,X
    CMP #MAILBOX_OFFBOARD
    BEQ ReadBoardSquareCommon
    STX EditorCursorSquare
    BNE ReadBoardSquareCommon

MoveCursorUpRank:
    BNE MoveCursorDownRank
    LDA EditorCursorSquare
    SEC
    SBC #&0A
    BNE AcceptCursorSquareIfPlayable

MoveCursorDownRank:
    CLC
    LDA EditorCursorSquare
    ADC #&0A
    BNE AcceptCursorSquareIfPlayable

FinishBoardSquareInput:
    PHA
    JSR RestoreActiveTextWindow
    PLA
    CMP #&0D
    BNE TryFileLetterInput
    BIT CursorOffFlag
    BMI ReadBoardSquareCommon
    LDA EditorCursorSquare
    JSR EchoBoardSquare
    LDA EditorCursorSquare
    CLC

ReturnAcceptedBoardSquare:
    RTS

EchoBoardSquare:
    JSR DivideMailboxSquareBy10
    ADC #&6A
    JSR OSWRCH
    DEX
    TXA
    CLC
    ADC #&30
    JSR OSWRCH
    RTS

ContinueBoardSquareInput:
    JMP ReadBoardSquareCommon

TryFileLetterInput:
    SEC
    PHA
    SBC #&30
    BCC TryNumericRankInput
    BEQ TryNumericRankInput
    CMP #&09
    BCS TryNumericRankInput
    TAX
    PLA
    LDY MoveToSquare
    BMI ContinueBoardSquareInput
    LDA MoveToSquare
    CLC

AddRankToFileSquare:
    ADC #&0A
    DEX
    BPL AddRankToFileSquare
    PHA
    JSR EchoBoardSquare
    PLA
    LDY #&01
    CLC
    RTS

TryNumericRankInput:
    SEC
    SBC #&10
    BCC HandleBoardSquareDeleteOrRetry
    BEQ HandleBoardSquareDeleteOrRetry
    CMP #&09
    BCS HandleBoardSquareDeleteOrRetry
    TAX
    PLA
    PHA
    ORA #&20
    JSR OSWRCH
    PLA
    STX MoveToSquare
    JMP ReadBoardSquareCommon

HandleBoardSquareDeleteOrRetry:
    PLA
    CMP #&7F
    BNE RetryBoardSquareInput
    LDA #&00
    CLC
    RTS

RetryBoardSquareInput:
    JMP ReadBoardSquare

SelectFromSquareInputWindow:
    LDA #&02
    STA CurrentTextWindowId
    JSR SelectFromSquareWindow
    LDA #&0C
    JMP OSWRCH

SelectFromSquareWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&0A,&1C,&13,&1C
    NOP
    RTS

SelectToSquareInputWindow:
    LDA #&03
    STA CurrentTextWindowId
    JSR SelectToSquareWindow
    LDA #&0C
    JMP OSWRCH

SelectToSquareWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&0D,&1C,&13,&1C
    NOP
    RTS

SelectEndGameTextWindow:
    LDA #&06
    STA CurrentTextWindowId
    JSR SelectEndGameWindow
    LDA #&0C
    JMP OSWRCH

SelectEndGameWindow:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&1B,&13,&1A
    NOP
    RTS

; Apply MoveFromSquare/MoveToSquare/MoveAux/MoveFlags to the live position.
; Handles capture, promotion, en-passant state, castling rook movement and rights.
; Pushes a four-byte undo record, increments ply/node counters, toggles SideToMove,
; and negates PositionScore for the new negamax point of view.
MakeMove:
    LDA PlyCountLo
    ORA PlyCountHi
    BNE ApplyMoveToPosition
    TAX
    TAY
    LDA OpeningBookPtrLo
    PHA
    LDA OpeningBookPtrHi
    PHA
    LDA #<InitialBlackContinuationSelector
    STA OpeningBookPtrLo
    LDA #>InitialBlackContinuationSelector
    STA OpeningBookPtrHi
    JSR LookupOpeningMoveRecord
    STX BlackOpeningBookCursor
    TAX
    TAY
    LDA #<InitialWhiteOpeningMoves
    STA OpeningBookPtrLo
    LDA #>InitialWhiteOpeningMoves
    STA OpeningBookPtrHi
    JSR LookupOpeningMoveRecord
    STX OpeningBookCursorBySide
    PLA
    STA OpeningBookPtrHi
    PLA
    STA OpeningBookPtrLo

; Phase 1: update opening-book cursors on the first played move, then clear the old en-passant target.
ApplyMoveToPosition:
    LDA #&00
    STA EnPassantTargetSquare
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ MovePieceToDestination
    TAY
    LDX PieceSquareArray,Y
    LDA #&FF
    STA MailboxBoard,X
    LDA PieceTypeArray,Y
    ORA #PIECE_INACTIVE
    STA PieceTypeArray,Y
    TAY
    CLC
    LDA PositionScoreLo
    ADC PieceValues16-PIECE_INACTIVE,Y
    STA PositionScoreLo
    LDA PositionScoreMid
    ADC PieceValues16+1-PIECE_INACTIVE,Y
    STA PositionScoreMid
    LDA PositionScoreHi
    ADC #&00
    STA PositionScoreHi

; Phase 2: remove any captured slot, move the piece, and apply promotion material/type changes.
MovePieceToDestination:
    LDY MoveFromSquare
    LDX MailboxBoard,Y
    STX EnPassantPawnSlot
    LDA #&FF
    STA MailboxBoard,Y
    LDY MoveToSquare
    STY PieceSquareArray,X
    TXA
    STA MailboxBoard,Y
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BEQ HandleMoveSpecialFlags
    LSR A
    LSR A
    LSR A
    LSR A
    STA PieceTypeArray,X
    TAX
    CLC
    LDA PositionScoreLo
    ADC PieceValues16,X
    STA PositionScoreLo
    LDA PositionScoreMid
    ADC PieceValues16+1,X
    STA PositionScoreMid
    LDA PositionScoreHi
    ADC #&00
    STA PositionScoreHi
    SEC
    LDA PositionScoreLo
    SBC PieceValues16+10
    STA PositionScoreLo
    LDA PositionScoreMid
    SBC PieceValues16+11
    STA PositionScoreMid
    LDA PositionScoreHi
    SBC #&00
    STA PositionScoreHi

; Phase 3: interpret the special high nibble: &F0 is a double-pawn push; other bits revoke castling rights and may move a rook.
HandleMoveSpecialFlags:
    LDA MoveFlags
    AND #MOVE_SPECIAL_MASK
    BEQ AdvanceGamePlyCounter
    CMP #MOVE_DOUBLE_PAWN_FLAG
    BNE ApplyCastlingRightsAndRookMove
    CLC
    LDA MoveFromSquare
    ADC MoveToSquare
    ROR A
    STA EnPassantTargetSquare
    BNE AdvanceGamePlyCounter

ApplyCastlingRightsAndRookMove:
    EOR #&FF
    AND CastlingRights
    STA CastlingRights
    LDA MoveFromSquare
    CMP #SQ_E1
    BNE TryBlackCastlingRookMove
    LDY MoveToSquare
    CPY #SQ_C1
    BNE TryWhiteKingsideRookMove
    LDX MailboxA1
    INY
    BNE MoveCastlingRook

TryWhiteKingsideRookMove:
    CPY #SQ_G1
    BNE AdvanceGamePlyCounter
    LDX MailboxH1
    DEY
    BNE MoveCastlingRook

TryBlackCastlingRookMove:
    CMP #SQ_E8
    BNE AdvanceGamePlyCounter
    LDY MoveToSquare
    CPY #SQ_C8
    BNE TryBlackKingsideRookMove
    LDX MailboxA8
    INY
    BNE MoveCastlingRook

TryBlackKingsideRookMove:
    CPY #SQ_G8
    BNE AdvanceGamePlyCounter
    LDX MailboxH8
    DEY

MoveCastlingRook:
    TXA
    STA MailboxBoard,Y
    LDA PieceSquareArray,X
    STY PieceSquareArray,X
    TAY
    LDA #&FF
    STA MailboxBoard,Y

AdvanceGamePlyCounter:
    INC PlyCountLo
    BNE PushSearchUndoRecord
    INC PlyCountHi

; Phase 4: push the compact 4-byte undo record and account the node.
PushSearchUndoRecord:
    LDA SearchPly
    INC SearchPly
    ASL A
    ASL A
    AND #&7C
    TAY
    LDA MoveFromSquare
    STA SearchUndoStack,Y
    LDA MoveToSquare
    STA SearchUndoToBase,Y
    LDA MoveAux
    STA SearchUndoAuxBase,Y
    LDA MoveFlags
    STA SearchUndoFlagsBase,Y
    INC SearchNodeCountLo
    BNE ServiceClockAfterMove
    INC SearchNodeCountHi

ServiceClockAfterMove:
    JSR ServicePendingClockTick

; Phase 5: toggle side-to-move and negate the 24-bit running material score for negamax.
SwitchNegamaxSide:
    LDA SideToMove
    EOR #SIDE_BLACK
    STA SideToMove
    SEC
    LDA #&00
    SBC PositionScoreLo
    STA PositionScoreLo
    LDA #&00
    SBC PositionScoreMid
    STA PositionScoreMid
    LDA #&00
    SBC PositionScoreHi
    STA PositionScoreHi
    LDA BoardConsistencyCheckFlag
    BNE ValidateBoardAfterMoveIfEnabled
    RTS

ValidateBoardAfterMoveIfEnabled:
    JMP ValidateBoardConsistency

; Pop one four-byte SearchUndoStack record and reverse MakeMove.
UnmakeMove:
    DEC SearchPly
    LDA SearchPly
    ASL A
    ASL A
    TAY
    LDA SearchUndoStack,Y
    STA MoveFromSquare
    LDA SearchUndoToBase,Y
    STA MoveToSquare
    LDA SearchUndoAuxBase,Y
    STA MoveAux
    LDA SearchUndoFlagsBase,Y
    STA MoveFlags
    LDA PlyCountLo
    BNE DecrementGamePlyLow
    DEC PlyCountHi

DecrementGamePlyLow:
    DEC PlyCountLo

; Reverse phase 1: move the active piece back and restore a captured piece/material if present.
UnmakeMoveCommon:
    LDY MoveToSquare
    LDX MailboxBoard,Y
    LDA #&FF
    STA MailboxBoard,Y
    LDY MoveFromSquare
    TXA
    STA MailboxBoard,Y
    STY PieceSquareArray,X
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ UndoPromotionIfPresent
    TAX
    LDY PieceSquareArray,X
    STA MailboxBoard,Y
    LDA PieceTypeArray,X
    AND #(PIECE_INACTIVE-1)
    STA PieceTypeArray,X
    TAY
    CLC
    LDA PositionScoreLo
    ADC PieceValues16,Y
    STA PositionScoreLo
    LDA PositionScoreMid
    ADC PieceValues16+1,Y
    STA PositionScoreMid
    LDA PositionScoreHi
    ADC #&00
    STA PositionScoreHi

; Reverse phase 2: restore a promoted piece to a pawn and undo the promotion material delta.
UndoPromotionIfPresent:
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BEQ RestoreEnPassantAndCastlingState
    LSR A
    LSR A
    LSR A
    LSR A
    TAY
    CLC
    LDA PositionScoreLo
    ADC PieceValues16,Y
    STA PositionScoreLo
    LDA PositionScoreMid
    ADC PieceValues16+1,Y
    STA PositionScoreMid
    LDA PositionScoreHi
    ADC #&00
    STA PositionScoreHi
    SEC
    LDA PositionScoreLo
    SBC PieceValues16+10
    STA PositionScoreLo
    LDA PositionScoreMid
    SBC PieceValues16+11
    STA PositionScoreMid
    LDA PositionScoreHi
    SBC #&00
    STA PositionScoreHi
    LDY MoveFromSquare
    LDX MailboxBoard,Y
    LDA #PIECE_PAWN
    STA PieceTypeArray,X

; Reverse phase 3: reconstruct prior en-passant and castling state from MoveFlags, including rook motion.
RestoreEnPassantAndCastlingState:
    LDA MoveFlags
    BEQ FinishUnmakeBySwitchingSide
    AND #MOVE_ENPASSANT_MASK
    BEQ StoreRestoredEnPassantTarget
    CLC
    ADC SideToMove
    STA EnPassantPawnSlot
    LDA PieceSquareArray,X
    TAX
    ADC #&0A
    CMP #&40
    BCS StoreRestoredEnPassantTarget
    SBC #&13

StoreRestoredEnPassantTarget:
    STA EnPassantTargetSquare
    LDA MoveFlags
    AND #MOVE_SPECIAL_MASK
    BEQ FinishUnmakeBySwitchingSide
    CMP #MOVE_DOUBLE_PAWN_FLAG
    BEQ FinishUnmakeBySwitchingSide
    ORA CastlingRights
    STA CastlingRights
    LDA MoveFromSquare
    CMP #SQ_E1
    BNE UndoBlackCastlingRookMove
    LDY MoveToSquare
    CPY #SQ_G1
    BNE UndoWhiteQueensideRookMove
    LDX MailboxF1
    INY
    BNE RestoreCastlingRook

UndoWhiteQueensideRookMove:
    CPY #SQ_C1
    BNE FinishUnmakeBySwitchingSide
    LDX MailboxD1
    BNE AdjustQueensideRookDestination

FinishUnmakeBySwitchingSide:
    JMP SwitchNegamaxSide

UndoBlackCastlingRookMove:
    CMP #SQ_E8
    BNE FinishUnmakeBySwitchingSide
    LDY MoveToSquare
    CPY #SQ_G8
    BNE UndoBlackQueensideRookMove
    LDX MailboxF8
    INY
    BNE RestoreCastlingRook

UndoBlackQueensideRookMove:
    CPY #SQ_C8
    BNE FinishUnmakeBySwitchingSide
    LDX MailboxD8

AdjustQueensideRookDestination:
    DEY
    DEY

RestoreCastlingRook:
    TXA
    STA MailboxBoard,Y
    LDA PieceSquareArray,X
    STY PieceSquareArray,X
    TAY
    LDA #&FF
    STA MailboxBoard,Y
    BNE FinishUnmakeBySwitchingSide

; A = mailbox square.  Return A = number of opponent attackers (C clear).
; Off-board sentinel squares return zero with C set.
CountOpponentAttacksToSquare:
    TAY
    LDA MailboxBoard,Y
    CMP #MAILBOX_OFFBOARD
    BNE CountAttacksOnValidSquare
    LDA #&00
    SEC
    RTS

CountAttacksOnValidSquare:
    STY AttackTargetSquare
    JSR ToggleSideToMove
    LDA #&00
    STA Scratch04
    JSR ScanAttackers
    JSR ToggleSideToMove
    LDA Scratch04
    CLC
    RTS

; Return nonzero when the current side attacks the opposing king.
DoesSideToMoveGiveCheck:
    LDA SideToMove
    EOR #SIDE_BLACK
    TAX
    LDA PieceSquareArray,X

ScanAttacksOnTargetSquare:
    STA AttackTargetSquare
    LDA #&80
    STA Scratch04

ScanAttackers:
    LDX #&07

ScanKingAndKnightDirection:
    CLC
    LDA AttackTargetSquare
    ADC MoveDeltas,X
    TAY
    LDA MailboxBoard,Y
    BMI ScanKnightAttack
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BNE ScanKnightAttack
    LDA MailboxBoard,Y
    AND #PIECE_SLOT_INDEX_MASK
    BNE ScanKnightAttack
    JSR RecordAttackerOrEarlyExit

ScanKnightAttack:
    CLC
    LDA AttackTargetSquare
    ADC KnightDeltas,X
    TAY
    LDA MailboxBoard,Y
    BMI ScanOrthogonalSlidingAttacks
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BNE ScanOrthogonalSlidingAttacks
    LDA MailboxBoard,Y
    TAY
    LDA PieceTypeArray,Y
    CMP #PIECE_KNIGHT
    BNE ScanOrthogonalSlidingAttacks
    JSR RecordAttackerOrEarlyExit

ScanOrthogonalSlidingAttacks:
    DEX
    BPL ScanKingAndKnightDirection
    LDX #&04
    LDY #&00

ScanNextOrthogonalRay:
    JSR FindFriendlyPieceOnRay
    BEQ AdvanceOrthogonalDirection
    CMP #PIECE_ROOK
    BEQ RecordRookOrQueenAttack
    CMP #PIECE_QUEEN
    BNE AdvanceOrthogonalDirection

RecordRookOrQueenAttack:
    JSR RecordAttackerOrEarlyExit
    JMP ScanNextOrthogonalRay

AdvanceOrthogonalDirection:
    INY
    DEX
    BNE ScanNextOrthogonalRay
    LDX #&04

ScanNextDiagonalRay:
    JSR FindFriendlyPieceOnRay
    BEQ AdvanceDiagonalDirection
    CMP #PIECE_QUEEN
    BEQ RecordBishopOrQueenAttack
    CMP #PIECE_BISHOP
    BNE AdvanceDiagonalDirection

RecordBishopOrQueenAttack:
    JSR RecordAttackerOrEarlyExit
    JMP ScanNextDiagonalRay

AdvanceDiagonalDirection:
    INY
    DEX
    BNE ScanNextDiagonalRay
    LDA #&F5
    LDY SideToMove
    BEQ CheckFirstPawnAttackSquare
    LDA #&09

CheckFirstPawnAttackSquare:
    CLC
    ADC AttackTargetSquare
    TAY
    JSR IsEnemyPawnOnSquare
    BEQ CheckSecondPawnAttackSquare
    JSR RecordAttackerOrEarlyExit

CheckSecondPawnAttackSquare:
    INY
    INY
    JSR IsEnemyPawnOnSquare
    BEQ NormaliseAttackCount
    JSR RecordAttackerOrEarlyExit

NormaliseAttackCount:
    LDA Scratch04
    BPL ReturnAttackCount
    LDA #&00

ReturnAttackCount:
    RTS

IsEnemyPawnOnSquare:
    LDA MailboxBoard,Y
    BMI NoEnemyPawnHere
    TAX
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BNE NoEnemyPawnHere
    LDA PieceTypeArray,X
    CMP #PIECE_PAWN
    BEQ ReturnAttackFound

NoEnemyPawnHere:
    LDA #&00
    RTS

RecordAttackerOrEarlyExit:
    INC Scratch04
    BPL ReturnFromAttackerRecorder
    PLA
    PLA

ReturnAttackFound:
    LDA #&FF

ReturnFromAttackerRecorder:
    RTS

FindFriendlyPieceOnRay:
    STX Scratch43
    LDX AttackTargetSquare

AdvanceAlongAttackRay:
    CLC
    TXA
    ADC MoveDeltas,Y
    TAX
    LDA MailboxBoard,X
    CMP #MAILBOX_EMPTY
    BEQ AdvanceAlongAttackRay
    CMP #MAILBOX_OFFBOARD
    BEQ NoSlidingAttackerOnRay
    TAX
    EOR SideToMove
    AND #SIDE_SLOT_MASK
    BNE NoSlidingAttackerOnRay
    LDA PieceTypeArray,X
    LDX Scratch43
    ORA #&00
    RTS

NoSlidingAttackerOnRay:
    LDX Scratch43
    LDA #&00
    RTS

; A = square.  Temporarily flips SideToMove and tests whether the opponent attacks it.
; Used directly by castling legality checks.
IsSquareAttackedByOpponent:
    JSR ToggleSideToMove
    JSR ScanAttacksOnTargetSquare
    JSR ToggleSideToMove
    RTS

; Return nonzero when the current side's king is attacked by the opponent.
IsSideToMoveInCheck:
    JSR ToggleSideToMove
    JSR DoesSideToMoveGiveCheck
    JSR ToggleSideToMove
    RTS

ToggleSideToMove:
    PHP
    PHA
    LDA SideToMove
    EOR #SIDE_BLACK
    STA SideToMove
    PLA
    PLP
    RTS

ClearDialogArea:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1C,&00,&16,&27,&13,&0C,&82
    NOP
    RTS

SetDialogInputArea:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &1A,&1F,&09,&14,&83,&1F,&09,&15,&83,&1F,&09,&16,&83,&1C,&0A,&16
    EQUB &1D,&14,&0C
    NOP
    RTS

; Main-menu Save game command.
; Main-game save.  Builds a fixed &500-byte image at &5300-&57FF, then OSFILE saves it.
SaveGame:
    JSR DisableEscapeEvent
    JSR ClearDialogArea
    LDA GamePlyCountLo
    ORA GamePlyCountHi
    BNE PromptForSaveInformation
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &81,&53,&6F,&72,&72,&79,&3A,&20,&6E,&6F,&20,&6C,&65,&67,&61,&6C ; .Sorry: no legal
    EQUB &20,&67,&61,&6D,&65,&20,&69,&6E,&20,&6D,&65,&6D,&6F,&72,&79,&20 ;  game in memory 
    EQUB &79,&65,&74,&2E
    NOP
    JSR SetDialogInputArea
    JMP FlushInputAndReturnToMenu

PromptForSaveInformation:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &50,&6C,&65,&61,&73,&65,&20,&74,&79,&70,&65,&20,&61,&6E,&79,&20 ; Please type any 
    EQUB &65,&78,&74,&72,&61,&20,&69,&6E,&66,&6F,&72,&6D,&61,&74,&69,&6F ; extra informatio
    EQUB &6E,&3A
    NOP
    JSR SetDialogInputArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&3B
    STA LineInputMaxLength
    LDA #<GameInformationText
    STA LineInputBufferLo
    LDA #>GameInformationText
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCS AbortSaveGameToMenu
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &57,&68,&61,&74,&20,&64,&6F,&20,&79,&6F,&75,&20,&77,&61,&6E,&74 ; What do you want
    EQUB &20,&74,&6F,&20,&63,&61,&6C,&6C,&20,&74,&68,&65,&20,&66,&69,&6C ;  to call the fil
    EQUB &65,&3F
    NOP
    JSR SetDialogInputArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&14
    STA LineInputMaxLength
    LDA #<FilenameBuffer
    STA LineInputBufferLo
    LDA #>FilenameBuffer
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCC BuildSaveGameImage

AbortSaveGameToMenu:
    JMP FlushInputAndReturnToMenu

BuildSaveGameImage:
    LDX #PIECE_SLOT_LAST

CopySavePositionSlot:
    LDA ResumePieceTypes,X
    STA SaveImagePieceTypes,X
    LDA ResumePieceSquares,X
    STA SaveImagePieceSquares,X
    LDA HistoryBasePieceTypes,X
    STA SaveImageHistoryBaseTypes,X
    LDA HistoryBasePieceSquares,X
    STA SaveImageHistoryBaseSquares,X
    LDA GamePhaseBySide,X
    STA SaveImageGamePhase,X
    DEX
    BPL CopySavePositionSlot
    LDA GamePlyCountLo
    STA SaveImagePlyLo
    LDA GamePlyCountHi
    STA SaveImagePlyHi
    LDA SavedCastlingRights
    STA SaveImageCastlingRights
    LDA SavedEnPassantTarget
    STA SaveImageEnPassantTarget
    LDA GameSideToMove
    STA SaveImageSideToMove
    LDX #&02

CopySaveClockByte:
    LDA WhiteClockSnapshot,X
    STA SaveImageWhiteClock,X
    LDA BlackClockSnapshot,X
    STA SaveImageBlackClock,X
    DEX
    BPL CopySaveClockByte
    LDX #INFO_TEXT_BYTES-1

CopySaveInformationByte:
    LDA GameInformationText,X
    STA SaveImageInformationText,X
    DEX
    BPL CopySaveInformationByte
    LDA HistoryBaseSide
    STA SaveImageHistoryBaseSide
    LDA FiftyMovePlyCounter
    STA SaveImageFiftyMoveCounter
    LDX #SaveFileSignatureEnd-SaveFileSignature-1

CopySaveSignatureByte:
    LDA SaveFileSignature,X
    STA SaveImageSignature,X
    DEX
    BPL CopySaveSignatureByte
    JSR InlineOSFILE

; Inline data consumed by preceding call.
    EQUW FilenameBuffer
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUW SaveImageBase,&0000,SaveImageEnd,&0000
    EQUB &00                         ; OSFILE reason: save

PromptAfterGameFileOperation:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&0D,&82,&50,&72,&65,&73,&73,&20,&53,&50,&41,&43,&45,&20,&42 ; ...Press SPACE B
    EQUB &41,&52
    NOP
    LDA #&0F
    LDX #&01
    JSR OSBYTE
    JSR ReadGameKey

EnableEscapeAndReturnToMenu:
    JSR EnableEscapeEvent
    JMP ChessRuntimeEntry

FlushInputAndReturnToMenu:
    LDA #&7E
    JSR OSBYTE
    JMP EnableEscapeAndReturnToMenu

RaiseFileNotFoundError:
    JMP ErrorFileNotFound

; Main-menu Load game command.
; Main-game load.  Reads into reclaimed bootstrap RAM beginning at LoadedImagePieceTypes, validates
; the Acornsoft signature, then reconstructs snapshots/state/history into live RAM.
LoadGame:
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&57,&68,&69,&63,&68,&20,&66,&69,&6C,&65,&20,&64,&6F,&20 ;   Which file do 
    EQUB &79,&6F,&75,&20,&77,&61,&6E,&74,&20,&74,&6F,&20,&6C,&6F,&61,&64 ; you want to load
    EQUB &3F
    NOP
    JSR SetDialogInputArea
    JSR DisableEscapeEvent
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&14
    STA LineInputMaxLength
    LDA #<FilenameBuffer
    STA LineInputBufferLo
    LDA #>FilenameBuffer
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCS FlushInputAndReturnToMenu
    JSR DisableEscapeEvent
    LDA #&40
    LDX #&17
    LDY #MOSParameterBlockHiByte
    JSR OSFIND
    STA FileHandle
    CMP #&00
    BEQ RaiseFileNotFoundError
    LDA #<LoadedImagePieceTypes
    STA AttackTargetSquare
    LDA #>LoadedImagePieceTypes
    STA Scratch43

ReadSavedGameByte:
    LDY FileHandle
    JSR OSBGET
    BCS ValidateSavedGameEOF
    LDY #&00
    STA (AttackTargetSquare),Y
    INC AttackTargetSquare
    BNE ReadSavedGameByte
    INC Scratch43
    LDA Scratch43
    SEC
    SBC #>LoadedImagePieceTypes
    CMP #((SaveImageEnd-SaveImageBase)/&100)+1
    BCC ReadSavedGameByte

RaiseIncompatibleFileError:
    JMP ErrorIncompatibleFile

ValidateSavedGameEOF:
    CMP #&FE
    BNE RaiseIncompatibleFileError
    JSR CloseAllFiles
    LDX #SAVE_SIGNATURE_CHECK_BYTES-1

CompareSavedGameSignature:
    LDA SaveFileSignature,X
    CMP LoadedImageSignature,X
    BNE RaiseIncompatibleFileError
    DEX
    BPL CompareSavedGameSignature
    LDX #&00

RestoreSavedGameHistoryByte:
    LDA LoadedImageHistoryFrom,X
    STA GameHistoryFrom,X
    LDA LoadedImageHistoryTo,X
    STA GameHistoryTo,X
    LDA LoadedImageHistoryAux,X
    STA GameHistoryAux,X
    LDA LoadedImageHistoryFlags,X
    STA GameHistoryFlags,X
    INX
    BNE RestoreSavedGameHistoryByte
    JSR InitialisePosition
    JSR CopyResumePositionToLive
    JSR ClearMailboxBoard
    LDX #PIECE_SLOT_LAST

RestoreSavedGamePositionSlot:
    LDA LoadedImagePieceTypes,X
    STA ResumePieceTypes,X
    LDA LoadedImagePieceSquares,X
    STA ResumePieceSquares,X
    LDA LoadedImageHistoryBaseTypes,X
    STA HistoryBasePieceTypes,X
    LDA LoadedImageHistoryBaseSquares,X
    STA HistoryBasePieceSquares,X
    LDA LoadedImageGamePhase,X
    STA GamePhaseBySide,X
    DEX
    BPL RestoreSavedGamePositionSlot
    LDA LoadedImagePlyLo
    STA GamePlyCountLo
    LDA LoadedImagePlyHi
    STA GamePlyCountHi
    LDA LoadedImageCastlingRights
    STA SavedCastlingRights
    LDA LoadedImageEnPassantTarget
    STA SavedEnPassantTarget
    LDA LoadedImageSideToMove
    STA GameSideToMove
    LDX #&02

RestoreSavedGameClockByte:
    LDA LoadedImageWhiteClock,X
    STA WhiteClockSnapshot,X
    LDA LoadedImageBlackClock,X
    STA BlackClockSnapshot,X
    DEX
    BPL RestoreSavedGameClockByte
    LDX #INFO_TEXT_BYTES-1

RestoreSavedGameInfoByte:
    LDA LoadedImageInformationText,X
    STA GameInformationText,X
    DEX
    BPL RestoreSavedGameInfoByte
    BPL RestoreSavedGameClockByte
    LDA LoadedImageHistoryBaseSide
    STA HistoryBaseSide
    LDA LoadedImageFiftyMoveCounter
    STA FiftyMovePlyCounter
    LDA #&FF
    STA ResumeGameAvailableFlag
    JMP PromptAfterGameFileOperation

; On MOS versions with event support: OSBYTE 13, event 6 (disable Escape event).
DisableEscapeEvent:
    BIT ModernMOSEventFlag
    BPL ReturnFromDisableEscapeEvent
    LDA #&0D
    LDX #&06
    JSR OSBYTE

ReturnFromDisableEscapeEvent:
    RTS

; On MOS versions with event support: OSBYTE 14, event 6 (enable Escape event).
EnableEscapeEvent:
    BIT ModernMOSEventFlag
    BPL ReturnFromEnableEscapeEvent
    LDA #&0E
    LDX #&06
    JSR OSBYTE

ReturnFromEnableEscapeEvent:
    RTS

; Copy the two three-byte chess clocks into their save/snapshot copies.
SnapshotChessClocks:
    LDX #&02

SnapshotClockByte:
    LDA ClockMinutesBase,X
    STA WhiteClockSnapshot,X
    LDA BlackClockMinutesBase,X
    STA BlackClockSnapshot,X
    DEX
    BPL SnapshotClockByte
    RTS

; Restore both chess clocks from their snapshot copies.
RestoreChessClocks:
    LDX #&02

RestoreClockByte:
    LDA WhiteClockSnapshot,X
    STA ClockMinutesBase,X
    LDA BlackClockSnapshot,X
    STA BlackClockMinutesBase,X
    DEX
    BPL RestoreClockByte
    RTS

CloseAllFiles:
    LDA #&00
    TAY
    TAX
    JMP OSFIND

; Computer move driver.  Starts a full-window 24-bit negamax search and returns the
; selected root move in MoveFromSquare..MoveFlags.  A zero from-square means no move.
ChooseComputerMove:
    LDA #&00
    STA UnusedSearchState14
    STA SearchBetaLo
    STA SearchAlphaLo
    STA SearchBetaMid
    STA SearchAlphaMid
    STA LastMoveToSquare
    LDX #&03

ClearPreferredReplyState:
    STA PreferredReplyState,X
    DEX
    BPL ClearPreferredReplyState
    LDA #&40
    STA SearchBetaHi
    LDA #&C0
    STA SearchAlphaHi
    SEC
    LDA MoveListEndLo
    SBC MoveListStartLo
    STA BestMovePtrLo
    LDA MoveListEndHi
    SBC MoveListStartHi
    BNE SearchRootPosition
    LDA BestMovePtrLo
    CMP #&05
    BNE SearchRootPosition
    LDA MoveListStartLo
    STA BestMovePtrLo
    LDA MoveListStartHi
    STA BestMovePtrHi
    JMP LoadChosenRootMove

SearchRootPosition:
    JSR SearchPosition
    LDA EngineStopFlag
    BNE ReturnNoComputerMove
    LDA BestMovePtrLo
    BNE LoadChosenRootMove
    LDA BestMovePtrHi
    BNE LoadChosenRootMove
    STA MoveFromSquare
    BEQ ReleaseRootMoveFrame

ReturnNoComputerMove:
    LDA #&00
    STA MoveFromSquare
    BEQ ReleaseRootMoveFrame

LoadChosenRootMove:
    LDA BestMovePtrLo
    STA MoveIteratorLo
    LDA BestMovePtrHi
    STA MoveIteratorHi
    JSR LoadMoveFromIterator

ReleaseRootMoveFrame:
    JMP PopMoveListFrame

CallEvaluationCallback:
    JMP (IndirectCallbackPtrLo)

; Assign byte +4 of every 5-byte move record.  Bonuses include captures/promotions,
; recaptures, opening-book weights and phase-dependent positional heuristics.
ScoreMovesForOrdering:
    LDA MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    STA MoveIteratorHi

ScoreMoveOrderingLoop:
    LDA MoveIteratorLo
    CMP MoveListEndLo
    BNE ScoreNextMoveForOrdering
    LDA MoveIteratorHi
    CMP MoveListEndHi
    BNE ScoreNextMoveForOrdering
    RTS

ScoreNextMoveForOrdering:
    JSR ServicePendingClockTick
    JSR LoadMoveFromIterator
    LDA #&30
    STA Scratch07
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ AddRecaptureOrderingBonus
    LDX SearchPly
    BEQ AddRecaptureOrderingBonus
    TAX
    LDY PieceTypeArray,X
    LDA MoveOrderingPieceBonuses,Y
    JSR SaturatingAddOrderingScore

AddRecaptureOrderingBonus:
    LDA MoveToSquare
    CMP LastMoveToSquare
    BNE AddPromotionOrderingBonus
    LDA #&23
    JSR SaturatingAddOrderingScore

AddPromotionOrderingBonus:
    LDA MoveAux
    AND #MOVE_PROMOTION_MASK
    BEQ AddPhaseSpecificOrderingBonus
    LSR A
    LSR A
    LSR A
    LSR A
    TAY
    LDA MoveOrderingPieceBonuses,Y
    JSR SaturatingAddOrderingScore

AddPhaseSpecificOrderingBonus:
    LDX SideToMove
    LDA GamePhaseBySide,X
    ASL A
    TAY
    LDA MoveOrderingCallbackByPhase,Y
    STA Scratch0A
    LDA MoveOrderingCallbackByPhase+1,Y
    STA Scratch0B
    JSR CallEvaluationCallback
    LDY #&04
    LDA Scratch07
    STA (MoveIteratorLo),Y
    CLC
    LDA MoveIteratorLo
    ADC #MOVE_RECORD_BYTES
    STA MoveIteratorLo
    BCC AdvanceMoveOrderingLoop
    INC MoveIteratorHi

AdvanceMoveOrderingLoop:
    JMP ScoreMoveOrderingLoop

LoadMoveFromIterator:
    LDY #&00
    LDA (MoveIteratorLo),Y
    STA MoveFromSquare
    INY
    LDA (MoveIteratorLo),Y
    STA MoveToSquare
    INY
    LDA (MoveIteratorLo),Y
    STA MoveAux
    INY
    LDA (MoveIteratorLo),Y
    STA MoveFlags
    INY
    RTS

SaturatingAddOrderingScore:
    PHA
    CLC
    ADC Scratch07
    BCC StoreSaturatedOrderingAdd
    LDA #&FF

StoreSaturatedOrderingAdd:
    STA Scratch07
    PLA
    RTS

SaturatingSubtractOrderingScore:
    STA Scratch0D
    LDA Scratch07
    SEC
    SBC Scratch0D
    BCS StoreSaturatedOrderingSubtract
    LDA #&00

StoreSaturatedOrderingSubtract:
    STA Scratch07
    LDA Scratch0D
    RTS

; Return a centrality score for a mailbox square.  Each coordinate is folded
; to min(coord,9-coord), giving 1..4 from edge to centre; file+rank therefore
; ranges from 2 at a corner to 8 in the central four squares.
SquareCentralityScore:
    JSR MailboxSquareToFileRank
    TXA
    JSR CoordinateCentrality
    STA Scratch0A
    TYA
    JSR CoordinateCentrality
    CLC
    ADC Scratch0A
    STA Scratch0A
    RTS

CoordinateCentrality:
    CMP #&05
    BCC ReturnCoordinateCentrality
    STA Scratch0D
    LDA #&09
    SEC
    SBC Scratch0D

ReturnCoordinateCentrality:
    RTS

AddRandomMoveOrderingNoise:
    JSR RandomByte
    AND #&07
    JMP SaturatingAddOrderingScore

AddOwnKingCentralisationTerm:
    LDA PositionScoreHi
    LDX SideToMove
    LDA PieceSquareArray,X
    JSR SquareCentralityScore
    ASL A
    ASL A
    JMP AddByteToEvalAccumulator

; Apparently orphaned in this binary: no static caller has been found.  The term
; favours driving the opposing king away from the centre and bringing kings closer.
AddEndgameKingGeometryTerm:
    LDA SideToMove
    EOR #SIDE_BLACK
    TAX
    LDA PieceSquareArray,X
    JSR SquareCentralityScore
    ASL A
    ASL A
    JSR SubtractByteFromEvalAccumulator
    LDX SideToMove
    LDA PieceSquareArray,X
    JSR MailboxSquareToFileRank
    STX Scratch04
    STY Scratch03
    LDA SideToMove
    EOR #SIDE_BLACK
    TAX
    LDA PieceSquareArray,X
    JSR MailboxSquareToFileRank
    LDA Scratch04
    STX Scratch0A
    JSR AbsoluteDifference
    STA Scratch04
    LDA Scratch03
    STY Scratch0A
    JSR AbsoluteDifference
    CLC
    ADC Scratch04
    LSR A
    JMP SubtractByteFromEvalAccumulator

AbsoluteDifference:
    SEC
    SBC Scratch0A
    BCS ReturnAbsoluteDifference
    EOR #&FF
    ADC #&01

ReturnAbsoluteDifference:
    RTS

AddBookOrPositionalMoveOrdering:
    LDA SearchPly
    BNE UsePositionalOrdering
    JSR AddOpeningBookMoveBonus
    TAX
    BNE ReturnBookOrdering

UsePositionalOrdering:
    JMP AddPositionalMoveOrdering

ReturnBookOrdering:
    RTS

AddNoisyPositionalMoveOrdering:
    JSR RandomByte
    AND #&03
    JSR SaturatingAddOrderingScore
    JSR AddPositionalMoveOrdering
    JMP ReturnFromMoveOrdering

AddOpeningBookMoveBonus:
    JSR RandomByte
    AND #&03
    JSR SaturatingAddOrderingScore
    LDA PlyCountLo
    LSR A
    BCS UseBlackOpeningBook
    BEQ UseInitialWhiteBook
    LDA #<WhiteOpeningContinuations
    LDY #>WhiteOpeningContinuations
    BCC LookupBookMoveWeight

UseBlackOpeningBook:
    LDA #<BlackOpeningContinuations
    LDY #>BlackOpeningContinuations

LookupBookMoveWeight:
    STA OpeningBookPtrLo
    STY OpeningBookPtrHi
    LDX SideToMove
    LDY OpeningBookCursorBySide,X
    LDX #&FF

ApplyBookMoveWeight:
    JSR LookupOpeningMoveRecord
    PHA
    JSR SaturatingAddOrderingScore
    PLA
    RTS

UseInitialWhiteBook:
    TAY
    TAX
    LDA #<InitialWhiteOpeningMoves
    STA OpeningBookPtrLo
    LDA #>InitialWhiteOpeningMoves
    STA OpeningBookPtrHi
    BNE ApplyBookMoveWeight

AddPositionalMoveOrdering:
    LDY MoveFromSquare
    LDX MailboxBoard,Y
    LDA PieceTypeArray,X
    BNE OrderNonPawnMove
    JMP OrderKingMove

OrderNonPawnMove:
    CMP #PIECE_PAWN
    BEQ OrderPawnMove
    TYA
    CMP HistoryBasePieceSquares,X
    BNE OrderAlreadyDevelopedPiece
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE OrderQueenOrKnightDevelopment
    LDA MoveToSquare
    JSR MailboxSquareToFileRank
    CPX #&07
    BCS PenaliseEarlyRookMove
    CPX #&03
    BCC PenaliseEarlyRookMove
    LDY #&0A
    LDA SideToMove
    BEQ InspectSupportingPawn
    LDY #&F6

InspectSupportingPawn:
    TYA
    CLC
    ADC MoveToSquare
    TAY
    LDX MailboxBoard,Y
    BMI RewardSupportedRookMove
    LDA PieceTypeArray,X
    CMP #PIECE_PAWN
    BNE RewardSupportedRookMove

PenaliseEarlyRookMove:
    LDA #&0A
    JMP SaturatingSubtractOrderingScore

RewardSupportedRookMove:
    LDA #&06
    JMP SaturatingAddOrderingScore

OrderQueenOrKnightDevelopment:
    CMP #PIECE_QUEEN
    BEQ PenaliseEarlyQueenMove
    CMP #PIECE_KNIGHT
    BNE ReturnFromDevelopmentOrdering
    LDA #&02
    JMP SaturatingAddOrderingScore

ReturnFromDevelopmentOrdering:
    RTS

PenaliseEarlyQueenMove:
    LDA #&03
    JMP SaturatingSubtractOrderingScore

OrderAlreadyDevelopedPiece:
    LDY MoveToSquare
    TYA
    CMP InitialPieceSquares,X
    BNE RewardCentralDevelopment
    LDA #&0A
    JMP SaturatingSubtractOrderingScore

RewardCentralDevelopment:
    JSR MailboxSquareToFileRank
    TXA
    CMP #&05
    BCC ApplyDevelopmentPenalty
    EOR #&FF
    ADC #&09

ApplyDevelopmentPenalty:
    JSR SaturatingAddOrderingScore
    LDA #&0A
    JMP SaturatingSubtractOrderingScore

OrderPawnMove:
    LDA MoveFromSquare
    JSR MailboxSquareToFileRank
    CPX #&04
    BEQ RewardCentralPawnMove
    CPX #&05
    BEQ RewardCentralPawnMove
    LDA #&06
    JMP SaturatingSubtractOrderingScore

RewardCentralPawnMove:
    LDA #&04
    JMP SaturatingAddOrderingScore

OrderKingMove:
    LDA MoveToSquare
    SEC
    SBC MoveFromSquare
    CMP #&02
    BEQ RewardCastlingKingMove
    CMP #&FE
    BEQ RewardCastlingKingMove
    LDA #&0F
    JMP SaturatingSubtractOrderingScore

RewardCastlingKingMove:
    LDA #&1E
    JMP SaturatingAddOrderingScore

ReturnFromMoveOrdering:
    RTS

; Search the compact opening book for MoveFromSquare/MoveToSquare.
; Initial tables use 4-byte records and continuation offsets; continuation tables use
; 3-byte records.  Returns move weight in A, and for initial records branch offset in X.
LookupOpeningMoveRecord:
    LDA (OpeningBookPtrLo),Y

ScanOpeningBookRecord:
    INY
    CMP MoveFromSquare
    BNE AdvanceOpeningBookRecord
    LDA (OpeningBookPtrLo),Y
    CMP MoveToSquare
    BNE AdvanceOpeningBookRecord
    INY
    INY
    LDA (OpeningBookPtrLo),Y
    TAX
    DEY
    LDA (OpeningBookPtrLo),Y
    CLC
    RTS

AdvanceOpeningBookRecord:
    INY
    INY
    TXA
    BNE TestOpeningBookTerminator
    INY

TestOpeningBookTerminator:
    LDA (OpeningBookPtrLo),Y
    BPL ScanOpeningBookRecord
    LDA #&00
    LDX #&81
    SEC
    RTS

; Commit the just-played move to the four 256-byte history pages, maintain the
; fifty-move counter, and advance per-side game phase when its trigger is reached.
; Note: the original contains an unreachable phase-3 branch immediately after CMP #3,
; plus a suspicious phase-2 material sum whose accumulator is not the value compared.
CommitMoveToGameHistory:
    LDA GamePlyCountHi
    BNE UpdateFiftyMoveCounter
    LDY GamePlyCountLo
    LDA MoveFromSquare
    STA GameHistoryFrom,Y
    LDA MoveToSquare
    STA GameHistoryTo,Y
    LDA MoveAux
    STA GameHistoryAux,Y
    LDA MoveFlags
    STA GameHistoryFlags,Y

UpdateFiftyMoveCounter:
    LDA MoveAux
    BNE ResetFiftyMoveCounter
    LDY MoveToSquare
    LDX MailboxBoard,Y
    LDA PieceTypeArray,X
    CMP #PIECE_PAWN
    BNE IncrementFiftyMoveCounter

ResetFiftyMoveCounter:
    LDA #&00
    STA FiftyMovePlyCounter
    BEQ UpdateGamePhaseAfterMove

IncrementFiftyMoveCounter:
    INC FiftyMovePlyCounter

; Update the per-side 16-byte engine-state block.
; Original-code quirk: CMP #3 / BCS below makes the following BEQ for phase 3
; unreachable.  Consequently phases 0 and 1 both use the 40-ply test; the apparent
; 20-ply/development transition block is dead code.  Preserved intentionally.
UpdateGamePhaseAfterMove:
    LDX GameSideToMove
    LDA GamePhaseBySide,X
    CMP #&03
    BCS GamePhaseUnchanged
    BEQ UnreachableOpeningPhaseTransition
    LSR A
    BEQ TestPhase0Or1FortyPlyTransition
    BCC TestMaterialPhaseTransition

GamePhaseUnchanged:
    RTS

; Unreachable in the original control flow (see UpdateGamePhaseAfterMove).
UnreachableOpeningPhaseTransition:
    LDA PlyCountLo
    CMP #&14
    BCS AdvanceGamePhase
    LDX GameSideToMove
    JSR CountChangedNonPawnPieces
    CMP #&05
    BCS AdvanceGamePhase
    RTS

TestPhase0Or1FortyPlyTransition:
    LDA PlyCountLo
    CMP #&28
    BCS AdvanceGamePhase
    RTS

TestMaterialPhaseTransition:
    LDX GameSideToMove
    LDY #&0F
    LDA #&00
    STA Scratch0A
    INX

SumRemainingNonPawnMaterial:
    LDA PieceTypeArray,X
    BMI AdvanceMaterialSlot
    TYA
    PHA
    LDA PieceTypeArray,X
    CMP #PIECE_PAWN
    BEQ RestoreMaterialLoopCounter
    LSR A
    TAY
    LDA CompactPieceValues,Y
    CLC
    ADC Scratch0A
    STA Scratch0A

RestoreMaterialLoopCounter:
    PLA
    TAY

AdvanceMaterialSlot:
    INX
    DEY
    BNE SumRemainingNonPawnMaterial
    ; Original-code anomaly: the loop above computes remaining non-pawn material
    ; in Scratch0A, but the transition test reads Scratch08 instead.  This means the
    ; phase-2 transition depends on stale shared scratch state.  Preserved as shipped.
    LDA Scratch08
    CMP #&0B
    BCC AdvanceGamePhase
    RTS

AdvanceGamePhase:
    LDX GameSideToMove
    TXA
    ORA GamePhaseBySide,X
    TAY
    LDA PlyCountLo
    BIT PlyCountHi
    STA PhaseTransitionPlyBySide,Y
    INC GamePhaseBySide,X
    RTS

; Recursive negamax alpha-beta position search.
; SearchAlpha = signed 24-bit lower/best bound; SearchBeta = signed 24-bit cutoff bound.
; Terminal no-move positions return 0 for stalemate or a large negative, ply-adjusted
; value for checkmate.  Skill tables control depth and selective capture continuation.
SearchPosition:
    LDA EngineStopFlag
    BNE ReturnFromSearchPosition
    STA BestMovePtrLo
    STA BestMovePtrHi
    LDA MoveListEndLo
    CMP MoveListStartLo
    BNE ChooseSearchDepthPolicy
    LDA MoveListEndHi
    CMP MoveListStartHi
    BNE ChooseSearchDepthPolicy
    JSR IsSideToMoveInCheck
    BNE SetCheckmateTerminalScore
    LDA #&00
    BEQ StoreTerminalSearchScore

SetCheckmateTerminalScore:
    LDA #&C1
    CLC
    ADC SearchPly

StoreTerminalSearchScore:
    STA SearchAlphaHi
    LDA #&00
    STA SearchAlphaLo
    STA SearchAlphaMid

ReturnFromSearchPosition:
    RTS

; Past normal depth: continue only after a capture, only to the selective depth, and compact the child list to captures.
ConsiderCaptureOnlyExtension:
    CMP SelectiveDepthLimitBySkill,X
    BCS EvaluateSearchLeaf
    LDA SearchPly
    ASL A
    ASL A
    TAY
    LDA PreviousUndoAuxBase,Y
    AND #MOVE_CAPTURE_MASK
    BEQ EvaluateSearchLeaf
    JSR EvaluatePositionForSearch
    JSR KeepCaptureMovesOnly
    LDA MoveListEndLo
    CMP MoveListStartLo
    BNE SearchCaptureExtension
    LDA MoveListEndHi
    CMP MoveListStartHi
    BEQ EvaluateSearchLeaf

SearchCaptureExtension:
    JMP PrepareSearchMoveIteration

EvaluateSearchLeaf:
    JMP EvaluatePositionAtLeaf

ScoreAndSortMoves:
    JSR ScoreMovesForOrdering
    JSR SortMovesByOrderingScore
    JMP PrepareSearchMoveIteration

; Depth policy: root/early/check nodes are fully ordered; quiet nodes obey primary/selective skill limits.
ChooseSearchDepthPolicy:
    LDA SearchPly
    BEQ ScoreAndSortMoves
    LDX SkillLevel
    BEQ ApplyDepthLimitIfQuiet
    CMP #&02
    BCC ScoreAndSortMoves

ApplyDepthLimitIfQuiet:
    JSR IsSideToMoveInCheck
    BNE ScoreAndSortMoves
    LDX SkillLevel
    LDA SearchPly
    CMP PrimaryDepthLimitBySkill,X
    BCS ConsiderCaptureOnlyExtension
    JSR ScoreMovesForOrdering
    JSR SortMovesByOrderingScore
    LDX SkillLevel
    LDA TopTenMoveLimitFlagBySkill,X
    LSR A
    BCC PrepareSearchMoveIteration
    LDA #&32
    CLC
    ADC MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    ADC #&00
    STA MoveIteratorHi
    LDA MoveIteratorLo
    CMP MoveListEndLo
    LDA MoveIteratorHi
    SBC MoveListEndHi
    BCS PrepareSearchMoveIteration
    LDA MoveIteratorLo
    STA MoveListEndLo
    LDA MoveIteratorHi
    STA MoveListEndHi

; Principal-reply heuristic pass: identify one hinted move for an early probe before scanning the full list.
PrepareSearchMoveIteration:
    LDA MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    STA MoveIteratorHi
    LDA #&00
    STA PreferredMovePtrLo
    STA PreferredMovePtrHi

MarkPreferredReplyLoop:
    LDA MoveIteratorLo
    CMP MoveListEndLo
    LDA MoveIteratorHi
    SBC MoveListEndHi
    BCS ClearReplyHintBeforeSearch
    BIT PreferredReplyState
    BMI ComparePreferredReply

MarkOrdinaryMove:
    LDY #&04
    LDA #&00
    STA (MoveIteratorLo),Y
    BEQ AdvancePreferredReplyScan

ComparePreferredReply:
    LDY #&02
    LDX #&02

ComparePreferredReplyBytes:
    LDA (MoveIteratorLo),Y
    CMP PreferredReplyFrom,X
    BNE MarkOrdinaryMove
    DEX
    DEY
    BPL ComparePreferredReplyBytes
    TYA
    LDY #&04
    STA (MoveIteratorLo),Y
    INX
    STX PreferredReplyState
    LDA MoveIteratorLo
    STA PreferredMovePtrLo
    LDA MoveIteratorHi
    STA PreferredMovePtrHi

AdvancePreferredReplyScan:
    LDA MoveIteratorLo
    CLC
    ADC #MOVE_RECORD_BYTES
    STA MoveIteratorLo
    BCC MarkPreferredReplyLoop
    INC MoveIteratorHi
    BCS MarkPreferredReplyLoop

ClearReplyHintBeforeSearch:
    LDA #&00
    LDX #&03

ClearReplyHintBytes:
    STA PreferredReplyState,X
    DEX
    BPL ClearReplyHintBytes
    LDA PreferredMovePtrLo
    ORA PreferredMovePtrHi
    BEQ StartOrdinarySearchLoop
    LDA PreferredMovePtrLo
    STA MoveIteratorLo
    LDA PreferredMovePtrHi
    STA MoveIteratorHi
    JSR SearchOneMove

; Full alpha-beta move loop; the early-probed move is marked negative in byte +4 and skipped here.
StartOrdinarySearchLoop:
    LDA MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    STA MoveIteratorHi

SearchMoveLoop:
    JSR ServicePendingClockTick
    LDA MoveIteratorLo
    CMP MoveListEndLo
    BNE SearchMoveUnlessAlreadyProbed
    LDA MoveIteratorHi
    CMP MoveListEndHi
    BEQ ReturnAfterSearchingMoves

SearchMoveUnlessAlreadyProbed:
    LDY #&04
    LDA (MoveIteratorLo),Y
    BMI AdvanceSearchMoveIterator
    JSR SearchOneMove

AdvanceSearchMoveIterator:
    CLC
    LDA MoveIteratorLo
    ADC #MOVE_RECORD_BYTES
    STA MoveIteratorLo
    BCC SearchMoveLoop
    INC MoveIteratorHi
    BCS SearchMoveLoop

ReturnAfterSearchingMoves:
    RTS

; Search the move at MoveIterator.  Make it, generate the child list, transform the
; alpha-beta window to (-beta,-alpha), recurse, negate the child score, unmake it,
; update alpha/best move, and perform the beta cutoff when child_score >= beta.
SearchOneMove:
    JSR LoadMoveFromIterator
    LDA MoveToSquare
    STA LastMoveToSquare
    LDA MoveAux
    STA MoveAuxWriteOnlyShadow
    JSR MakeMove
    LDY #&02
    LDX #&00

SaveParentIteratorState:
    LDA MoveIteratorLo,X
    STA (MoveFramePtrLo),Y
    INX
    INY
    CPY #MOVE_FRAME_HEADER_BYTES
    BNE SaveParentIteratorState
    JSR BuildLegalMoveList5
    LDA #&00
    SEC
    SBC SearchBetaLo
    PHA
    LDA #&00
    SBC SearchBetaMid
    PHA
    LDA #&00
    SBC SearchBetaHi
    PHA
    LDA #&00
    SEC
    SBC SearchAlphaLo
    STA SearchBetaLo
    LDA #&00
    SBC SearchAlphaMid
    STA SearchBetaMid
    LDA #&00
    SBC SearchAlphaHi
    STA SearchBetaHi
    PLA
    STA SearchAlphaHi
    PLA
    STA SearchAlphaMid
    PLA
    STA SearchAlphaLo
    JSR SearchPosition
    LDA BestMovePtrLo
    STA ReturnedBestMovePtrLo
    LDA BestMovePtrHi
    STA ReturnedBestMovePtrHi
    LDA #&00
    SEC
    SBC SearchAlphaLo
    STA ChildScoreLo
    LDA #&00
    SBC SearchAlphaMid
    STA ChildScoreMid
    LDA #&00
    SBC SearchAlphaHi
    STA ChildScoreHi
    JSR PopMoveListFrame
    LDY #&02
    LDX #&00

RestoreParentIteratorState:
    LDA (MoveFramePtrLo),Y
    STA MoveIteratorLo,X
    INX
    INY
    CPY #MOVE_FRAME_HEADER_BYTES
    BNE RestoreParentIteratorState
    JSR UnmakeMove
    LDA ChildScoreLo
    CMP SearchBetaLo
    LDA ChildScoreMid
    SBC SearchBetaMid
    LDA ChildScoreHi
    SBC SearchBetaHi
    BMI UpdateAlphaIfImproved
    LDA SearchBetaLo
    STA SearchAlphaLo
    LDA SearchBetaMid
    STA SearchAlphaMid
    LDA SearchBetaHi
    STA SearchAlphaHi
    JSR UpdatePreferredReplyHeuristic
    LDA #&FF
    PLA
    PLA
    RTS

UpdatePreferredReplyHeuristic:
    LDA PreferredReplyState
    BMI ReturnFromReplyHeuristic
    LDY #&02
    LDX #&02

CompareReturnedPrincipalReply:
    LDA (ReturnedBestMovePtrLo),Y
    CMP PreferredReplyFrom,X
    BNE StoreNewPrincipalReply
    DEX
    DEY
    BPL CompareReturnedPrincipalReply
    STY PreferredReplyState

ReturnFromReplyHeuristic:
    RTS

StoreNewPrincipalReply:
    LDY #&02
    LDX #&02

StorePrincipalReplyBytes:
    LDA (ReturnedBestMovePtrLo),Y
    STA PreferredReplyFrom,X
    DEX
    DEY
    BPL StorePrincipalReplyBytes
    RTS

UpdateAlphaIfImproved:
    LDA SearchAlphaLo
    CMP ChildScoreLo
    LDA SearchAlphaMid
    SBC ChildScoreMid
    LDA SearchAlphaHi
    SBC ChildScoreHi
    BPL UpdatePreferredReplyHeuristic
    LDA MoveIteratorLo
    STA BestMovePtrLo
    LDA MoveIteratorHi
    STA BestMovePtrHi
    LDA ChildScoreLo
    STA SearchAlphaLo
    LDA ChildScoreMid
    STA SearchAlphaMid
    LDA ChildScoreHi
    STA SearchAlphaHi
    RTS

; In-place compaction of the current 5-byte move list to captures only.
; Used for selective/quiescence-style continuation beyond the normal depth limit.
KeepCaptureMovesOnly:
    LDA MoveListStartLo
    STA MoveIteratorLo
    STA CaptureWritePtrLo
    LDA MoveListStartHi
    STA MoveIteratorHi
    STA CaptureWritePtrHi

ScanMovesForCaptures:
    JSR LoadMoveFromIterator
    LDA MoveAux
    AND #MOVE_CAPTURE_MASK
    BEQ AdvanceCaptureScan
    LDY #&04

CopyCaptureMoveRecord:
    LDA (MoveIteratorLo),Y
    STA (CaptureWritePtrLo),Y
    DEY
    BPL CopyCaptureMoveRecord
    LDA CaptureWritePtrLo
    CLC
    ADC #MOVE_RECORD_BYTES
    STA CaptureWritePtrLo
    BCC AdvanceCaptureScan
    INC CaptureWritePtrHi

AdvanceCaptureScan:
    LDA MoveIteratorLo
    CLC
    ADC #MOVE_RECORD_BYTES
    STA MoveIteratorLo
    BCC TestCaptureScanComplete
    INC MoveIteratorHi

TestCaptureScanComplete:
    LDA MoveIteratorLo
    CMP MoveListEndLo
    LDA MoveIteratorHi
    SBC MoveListEndHi
    BCC ScanMovesForCaptures
    LDA CaptureWritePtrLo
    STA MoveListEndLo
    LDA CaptureWritePtrHi
    STA MoveListEndHi
    RTS

; Recompute the signed 24-bit static score from the current side's perspective:
; material plus phase-dependent positional terms for both sides.
ComputeStaticPositionScore:
    JSR ClearEvalAccumulator
    LDX SideToMove
    JSR AddSideMaterialValue
    JSR NegateEvalAccumulator
    LDA SideToMove
    EOR #&10
    TAX
    JSR AddSideMaterialValue
    LDA SideToMove
    JSR AddSideEvaluationIfApplicable
    JSR NegateEvalAccumulator
    LDA SideToMove
    EOR #&10
    JSR AddSideEvaluationIfApplicable
    LDX #&02

CopyEvalAccumulatorToPositionScore:
    LDA SearchAlphaLo,X
    STA PositionScoreLo,X
    DEX
    BPL CopyEvalAccumulatorToPositionScore
    RTS

AddSideEvaluationIfApplicable:
    LDX SideToMove
    LDY GamePhaseBySide,X
    CPY #&03
    BCS ReturnFromPositionEvaluation
    JMP EvaluateSideFeatures

ReturnFromPositionEvaluation:
    RTS

EvaluatePositionForSearch:
    JSR ClearEvalAccumulator
    LDA SideToMove
    JSR EvaluateSideFeatures
    JSR NegateEvalAccumulator
    LDA SideToMove
    EOR #&10
    JSR EvaluateSideFeatures

AddMaterialBaselineToSearchScore:
    JSR NegateEvalAccumulator
    CLC
    LDA SearchAlphaLo
    ADC PositionScoreLo
    STA SearchAlphaLo
    LDA SearchAlphaMid
    ADC PositionScoreMid
    STA SearchAlphaMid
    LDA SearchAlphaHi
    ADC PositionScoreHi
    STA SearchAlphaHi
    JMP ServicePendingClockTick

EvaluatePositionAtLeaf:
    JSR ClearEvalAccumulator
    LDA SideToMove
    JSR EvaluateSide
    JSR NegateEvalAccumulator
    LDA SideToMove
    EOR #&10
    JSR EvaluateSide
    JMP AddMaterialBaselineToSearchScore

CountChangedNonPawnPieces:
    LDY #&10
    LDA #&00
    STA Scratch07

ScanChangedPieceSlot:
    LDA HistoryBasePieceTypes,X
    CMP #PIECE_PAWN
    BEQ AdvanceChangedPieceSlot
    LDA PieceTypeArray,X
    BMI CountChangedPiece
    LDA PieceSquareArray,X
    CMP HistoryBasePieceSquares,X
    BEQ AdvanceChangedPieceSlot

CountChangedPiece:
    INC Scratch07

AdvanceChangedPieceSlot:
    INX
    DEY
    BNE ScanChangedPieceSlot
    LDA Scratch07
    RTS

CountDoubledPawnFiles:
; NOTE: this routine deliberately reuses IntervalTimerPawnWorkspace as eight file counters.
; No dedicated clear loop is visible here; the same RAM is also refreshed by OSWORD 3/4 in
; the clock path.  Preserve this aliasing exactly: it is behaviour of the original binary.
    STX Scratch07
    LDA #&10
    STA Scratch08

ScanPawnSlotForFileCount:
    LDX Scratch07
    LDA PieceTypeArray,X
    BMI AdvancePawnFileCountSlot
    CMP #PIECE_PAWN
    BNE AdvancePawnFileCountSlot
    LDA PieceSquareArray,X
    JSR MailboxSquareToFileRank
    INC IntervalTimerPawnWorkspace,X

AdvancePawnFileCountSlot:
    INC Scratch07
    DEC Scratch08
    BNE ScanPawnSlotForFileCount
    LDX #&08
    LDY #&00

CountFilesWithMultiplePawns:
    LDA IntervalTimerPawnWorkspace,X
    CMP #&02
    BCC AdvancePawnFileScan
    INY

AdvancePawnFileScan:
    DEX
    BNE CountFilesWithMultiplePawns
    STY DoubledPawnFileCount
    TYA
    RTS

MailboxSquareToFileRank:
    LDY #&FE
    SEC

SubtractMailboxRankTens:
    SBC #&0A
    INY
    BCS SubtractMailboxRankTens
    ADC #&0A
    TAX
    RTS

AddSideMaterialValue:
    LDA #&0F
    STA Scratch08
    INX

AddNextPieceMaterial:
    LDA PieceTypeArray,X
    BMI AdvanceMaterialPieceSlot
    TAY
    LDA PieceValues16+1,Y
    STA Scratch0A
    LDA PieceValues16,Y
    LDY Scratch0A
    JSR AddWordToEvalAccumulator

AdvanceMaterialPieceSlot:
    INX
    DEC Scratch08
    BNE AddNextPieceMaterial
    RTS

ComputeKingSafetyPressure:
    LDX SideToMove
    LDA #&00
    STA Scratch0A
    LDA GamePhaseBySide,X
    BEQ AddKingFileCastlingPressure
    TXA
    EOR #&10
    TAX
    LDA PieceSquareArray,X
    STA Scratch0B
    LDA #&07
    STA Scratch03

SumKingRingAttackPressure:
    LDX Scratch03
    LDA Scratch0B
    CLC
    ADC MoveDeltas,X
    LDX SideToMove
    JSR CountOpponentAttacksToSquare
    CLC
    ADC Scratch0A
    STA Scratch0A
    DEC Scratch03
    BPL SumKingRingAttackPressure

AddKingFileCastlingPressure:
    LDA SideToMove
    EOR #&10
    TAX
    LDA PieceSquareArray,X
    JSR MailboxSquareToFileRank
    CPX #&07
    BCS ReturnKingSafetyPressure
    CPX #&04
    BCC ReturnKingSafetyPressure
    LDA #&03
    CLC
    ADC Scratch0A
    STA Scratch0A
    LDA #&30
    LDX SideToMove
    BNE TestCastlingRightsForPressure
    LDA #&C0

TestCastlingRightsForPressure:
    AND CastlingRights
    BNE ReturnKingSafetyPressure
    LDA #&02
    CLC
    ADC Scratch0A
    STA Scratch0A

ReturnKingSafetyPressure:
    LDA Scratch0A
    RTS

AddByteToEvalAccumulator:
    LDY #&00

AddWordToEvalAccumulator:
    CLC
    ADC SearchAlphaLo
    STA SearchAlphaLo
    TYA
    ADC SearchAlphaMid
    STA SearchAlphaMid
    LDA #&00
    ADC SearchAlphaHi
    STA SearchAlphaHi
    RTS

SubtractByteFromEvalAccumulator:
    LDY #&00
    SEC
    STA Scratch0D
    LDA SearchAlphaLo
    SBC Scratch0D
    STA SearchAlphaLo
    STY Scratch0D
    LDA SearchAlphaMid
    SBC Scratch0D
    STA SearchAlphaMid
    LDA SearchAlphaHi
    SBC #&00
    STA SearchAlphaHi
    RTS

ClearEvalAccumulator:
    LDA #&00
    STA SearchAlphaLo
    STA SearchAlphaMid
    STA SearchAlphaHi
    RTS

NegateEvalAccumulator:
    SEC
    LDA #&00
    SBC SearchAlphaLo
    STA SearchAlphaLo
    LDA #&00
    SBC SearchAlphaMid
    STA SearchAlphaMid
    LDA #&00
    SBC SearchAlphaHi
    STA SearchAlphaHi
    RTS

EvaluateEndgameKingCentralisation:
    JSR AddOwnKingCentralisationTerm
    JMP RestoreEvaluationSideAndReturn

EvaluateSide:
    JMP EvaluateSideFeatures

; Apparently orphaned wrapper retained from an earlier/intended evaluation path.
; Its skill-table branch is ineffective in this image because the tested values are 0/1
; and BPL is therefore always taken.
EvaluateSideWrapper:
    PHA
    LDX SideToMove
    STA SideToMove
    TXA
    PHA
    LDX SideToMove
    LDA GamePhaseBySide,X
    CMP #&03
    BCS RestoreEvaluationCallerSide
    LDX SkillLevel
    LDA TopTenMoveLimitFlagBySkill,X
    BPL RestoreEvaluationCallerSide

RestoreEvaluationCallerSide:
    PLA
    STA SideToMove
    PLA

; Add phase-dependent features for one side: king safety/pressure, doubled-pawn penalty,
; developed/changed-piece term and mobility.  Phase 3 falls back to king geometry.
EvaluateSideFeatures:
    LDX SideToMove
    STA SideToMove
    TXA
    PHA
    LDX SideToMove
    LDA GamePhaseBySide,X
    CMP #&03
    BCS EvaluateEndgameKingCentralisation
    JSR ComputeKingSafetyPressure
    LDX SideToMove
    LDY GamePhaseBySide,X
    BNE AddKingSafetyTerm
    ASL A

AddKingSafetyTerm:
    ASL A
    JSR AddByteToEvalAccumulator
    LDX SideToMove
    JSR CountDoubledPawnFiles
    LDA DoubledPawnFileCount
    ASL A
    ASL A
    ASL A
    ASL A
    JSR SubtractByteFromEvalAccumulator
    LDX SideToMove
    LDA GamePhaseBySide,X
    BEQ AddMobilityTermIfApplicable
    JSR CountChangedNonPawnPieces
    ASL A
    ASL A
    JSR AddByteToEvalAccumulator

AddMobilityTermIfApplicable:
    LDX SideToMove
    LDA GamePhaseBySide,X
    BEQ RestoreEvaluationSideAndReturn
    JSR CountPseudoLegalMoves
    LDX SideToMove
    LDY GamePhaseBySide,X
    BNE ScaleAndAddMobility
    LSR A

ScaleAndAddMobility:
    LSR A
    JSR AddByteToEvalAccumulator

RestoreEvaluationSideAndReturn:
    PLA
    STA SideToMove
    RTS

; -----------------------------------------------------------------------------
; Data &3356-&35E0: Main-menu VDU/display data and pointer/control tables
; -----------------------------------------------------------------------------

; Packed menu display stream/control data; deliberately kept as bytes, not false-disassembled code.
; -----------------------------------------------------------------------------
; Main-menu VDU/display data.  Every program-visible address is a label; pointer tables
; are EQUW entries so edits to preceding strings automatically retarget them.
; -----------------------------------------------------------------------------
; Packed Acornsoft Chess heading/title block.
MainMenuData:
    EQUB &1C,&81,&9D,&83,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&41,&63
    EQUB &6F,&72,&6E,&73,&6F,&66,&74,&20,&43,&68,&65,&73,&73
MainMenuGameTypeHeading:
    EQUB &13,&1F,&00,&04,&82,&47,&61,&6D,&65,&2D,&74,&79,&70,&65,&20,&20
    EQUB &20,&20,&3A,&0B
GameTypeMenuPointerTable:
    EQUW GameTypeAutoString,GameTypePvPString,GameTypeBlackString,GameTypeWhiteString
GameTypeWhiteString:
    EQUB &17,&81,&57,&20,&2D,&20,&50,&6C,&61,&79,&65,&72,&20,&70,&6C,&61
    EQUB &79,&73,&20,&57,&68,&69,&74,&65
GameTypeBlackString:
    EQUB &17,&81,&42,&20,&2D,&20,&50,&6C,&61,&79,&65,&72,&20,&70,&6C,&61
    EQUB &79,&73,&20,&42,&6C,&61,&63,&6B
GameTypePvPString:
    EQUB &16,&81,&50,&20,&2D,&20,&50,&6C,&61,&79,&65,&72,&20,&76,&73,&2E
    EQUB &20,&50,&6C,&61,&79,&65,&72
GameTypeAutoString:
    EQUB &09,&81,&41,&20,&2D,&20,&41,&75,&74,&6F
; Display letters indexed by GameType.
GameTypeDisplayLetterTable:
    EQUB &50,&57,&42,&41
SkillMenuHeading:
    EQUB &13,&1F,&00,&09,&82,&53,&6B,&69,&6C,&6C,&20,&20,&4C,&65,&76,&65
    EQUB &6C,&20,&3A,&0B
SkillEasiestString:
    EQUB &12,&83,&30,&20,&2D,&20,&45,&61,&73,&69,&65,&73,&74,&20,&6C,&65
    EQUB &76,&65,&6C
SkillSeparatorString:
    EQUB &04,&83,&3A,&20,&2D
SkillHardestString:
    EQUB &13,&83,&39,&20,&2D,&20,&4D,&6F,&73,&74,&20,&64,&69,&66,&66,&69
    EQUB &63,&75,&6C,&74
SkillMenuPointerTable:
    EQUW SkillHardestString,SkillSeparatorString,SkillEasiestString
OptionMenuHeading:
    EQUB &16,&0A,&0A,&0A,&0A,&82,&4B,&65,&79,&20,&20,&4F,&70,&74,&69,&6F
    EQUB &6E,&73,&20,&3A,&0B,&0B,&0B
OptionLoadString:
    EQUB &0E,&85,&4C,&20,&2D,&20,&4C,&6F,&61,&64,&20,&67,&61,&6D,&65
OptionSaveString:
    EQUB &0E,&85,&53,&20,&2D,&20,&53,&61,&76,&65,&20,&67,&61,&6D,&65
OptionEditorString:
    EQUB &0B,&85,&45,&20,&2D,&20,&45,&64,&69,&74,&6F,&72
OptionTickString:
    EQUB &15,&85,&54,&20,&2D,&20,&54,&69,&63,&6B,&20,&20,&20,&20,&20,&20
    EQUB &6F,&6E,&2F,&6F,&66,&66
OptionJoysticksString:
    EQUB &15,&85,&4A,&20,&2D,&20,&4A,&6F,&79,&73,&74,&69,&63,&6B,&73,&20
    EQUB &6F,&6E,&2F,&6F,&66,&66
OptionCursorString:
    EQUB &15,&85,&43,&20,&2D,&20,&43,&75,&72,&73,&6F,&72,&20,&20,&20,&20
    EQUB &6F,&6E,&2F,&6F,&66,&66
OptionMenuPointerTable:
    EQUW OptionEditorString,OptionSaveString,OptionLoadString,OptionTickString,OptionCursorString,OptionJoysticksString
OffWordString:
    EQUB &03,&6E,&6F,&20
OnWordString:
    EQUB &03,&79,&65,&73
MenuJoystickStateLabel:
    EQUB &12,&1F,&00,&18,&86,&9D,&84,&4A,&6F,&79,&73,&74,&69,&63,&6B,&73
    EQUB &20,&3A,&6F
MenuCursorStateLabel:
    EQUB &08,&43,&75,&72,&73,&6F,&72,&3A,&6F
MenuTickStateLabel:
    EQUB &06,&54,&69,&63,&6B,&3A,&6F
MenuGameTypeStateLabel:
    EQUB &16,&1F,&00,&17,&86,&9D,&84,&20,&20,&20,&20,&20,&47,&61,&6D,&65
    EQUB &20,&54,&79,&70,&65,&20,&3A
MenuSkillStateLabel:
    EQUB &0D,&20,&20,&20,&20,&20,&20,&4C,&65,&76,&65,&6C,&20,&3A
MenuResumeStateLabel:
    EQUB &0B,&20,&20,&20,&52,&65,&73,&75,&6D,&65,&20,&3A
MenuEditorAvailableHelp:
    EQUB &40,&1F,&07,&14,&50,&72,&65,&73,&73,&20,&52,&45,&54,&55,&52,&4E
    EQUB &20,&74,&6F,&20,&73,&65,&74,&20,&75,&70,&20,&62,&6F,&61,&72,&64
    EQUB &1F,&06,&15,&6F,&72,&20,&45,&53,&43,&41,&50,&45,&20,&74,&6F,&20
    EQUB &71,&75,&69,&74,&20,&74,&6F,&20,&6D,&61,&69,&6E,&20,&6D,&65,&6E
    EQUB &75
MenuNewGameHelp:
    EQUB &1E,&1F,&07,&13,&50,&72,&65,&73,&73,&20,&52,&45,&54,&55,&52,&4E
    EQUB &20,&66,&6F,&72,&20,&61,&20,&6E,&65,&77,&20,&67,&61,&6D,&65
MenuContinueHelp:
    EQUB &23,&1F,&04,&13,&50,&72,&65,&73,&73,&20,&52,&45,&54,&55,&52,&4E
    EQUB &20,&74,&6F,&20,&63,&6F,&6E,&74,&69,&6E,&75,&65,&20,&70,&6C,&61
    EQUB &79,&69,&6E,&67
MenuNewGameAlternativeHelp:
    EQUB &21,&0A,&0D,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&6F,&72,&20
    EQUB &22,&4E,&22,&20,&66,&6F,&72,&20,&61,&20,&6E,&65,&77,&20,&67,&61
    EQUB &6D,&65
MenuRestartAlternativeHelp:
    EQUB &25,&0A,&0D,&20,&20,&20,&20,&20,&20,&6F,&72,&20,&22,&52,&22,&20
    EQUB &74,&6F,&20,&73,&74,&61,&72,&74,&20,&66,&72,&6F,&6D,&20,&70,&6F
    EQUB &73,&69,&74,&69,&6F,&6E

PrintMenuItemFromTable:
    STX TextStringPtrLo
    STY TextStringPtrHi
    STA Scratch46
    JSR ReadTextCursorPosition
    LDY #&01

FindMenuItemStringOffset:
    LDA (TextStringPtrLo),Y
    CMP Scratch46
    BEQ PositionAndPrintMenuItem
    INY
    BNE FindMenuItemStringOffset

PositionAndPrintMenuItem:
    DEY
    STY Scratch46
    LDA MenuItemRightEdgeX
    SEC
    SBC Scratch46
    TAX
    LDY SavedTextCursorY
    JSR SetTextCursorXY
    JMP PrintLengthPrefixedString

SetTextCursorXY:
    LDA #&1F
    JSR OSWRCH
    TXA
    JSR OSWRCH
    TYA
    JMP OSWRCH

PrintStringAtXY:
    STX TextStringPtrLo
    STY TextStringPtrHi

PrintLengthPrefixedString:
    LDY #&00
    LDA (TextStringPtrLo),Y
    STA LengthPrefixedStringLength

PrintNextLengthPrefixedCharacter:
    INY
    LDA (TextStringPtrLo),Y
    JSR OSWRCH
    CPY LengthPrefixedStringLength
    BNE PrintNextLengthPrefixedCharacter
    RTS

ReadTextCursorPosition:
    LDA #&86
    JSR OSBYTE
    STX SavedTextCursorX
    STY SavedTextCursorY
    RTS

PrintPackedMenuBlock:
    STX TextStringPtrLo
    STY TextStringPtrHi
    JSR ReadTextCursorPosition
    LDX #&02
    STX SearchNodeCountLo

PrintNextPackedMenuLine:
    LDX SavedTextCursorX
    LDY SavedTextCursorY
    JSR SetTextCursorXY
    LDA #&8D
    JSR OSWRCH
    JSR PrintLengthPrefixedString
    LDA #&8C
    JSR OSWRCH
    INC SavedTextCursorY
    DEC SearchNodeCountLo
    BNE PrintNextPackedMenuLine
    RTS

DrawMainMenu:
    LDA #&16
    JSR OSWRCH
    LDA #&07
    JSR OSWRCH
    LDA #&13
    STA MenuItemRightEdgeX
    LDX #<MainMenuData
    LDY #>MainMenuData
    JSR PrintPackedMenuBlock
    LDX #<MainMenuGameTypeHeading
    LDY #>MainMenuGameTypeHeading
    JSR PrintStringAtXY
    LDA #&03
    STA MenuItemIndex

PrintGameTypeMenuItems:
    LDA MenuItemIndex
    ASL A
    TAY
    LDA GameTypeMenuPointerTable,Y
    TAX
    LDA GameTypeMenuPointerTable+1,Y
    TAY
    LDA #&2D
    JSR PrintMenuItemFromTable
    JSR OSNEWL
    DEC MenuItemIndex
    BPL PrintGameTypeMenuItems
    LDX #<SkillMenuHeading
    LDY #>SkillMenuHeading
    JSR PrintStringAtXY
    LDA #&02
    STA MenuItemIndex

PrintSkillMenuItems:
    LDA MenuItemIndex
    ASL A
    TAY
    LDA SkillMenuPointerTable,Y
    TAX
    LDA SkillMenuPointerTable+1,Y
    TAY
    LDA #&2D
    JSR PrintMenuItemFromTable
    JSR OSNEWL
    DEC MenuItemIndex
    BPL PrintSkillMenuItems
    LDX #<OptionMenuHeading
    LDY #>OptionMenuHeading
    JSR PrintStringAtXY
    LDA #&05
    STA MenuItemIndex

PrintOptionMenuItems:
    LDA MenuItemIndex
    ASL A
    TAY
    LDA OptionMenuPointerTable,Y
    TAX
    LDA OptionMenuPointerTable+1,Y
    TAY
    LDA #&2D
    JSR PrintMenuItemFromTable
    JSR OSNEWL
    DEC MenuItemIndex
    BPL PrintOptionMenuItems
    BMI RefreshMainMenuState

PrintMainMenuOptionStates:
    LDX #<MenuJoystickStateLabel
    LDY #>MenuJoystickStateLabel
    JSR PrintStringAtXY
    LDA JoysticksOffFlag
    JSR PrintOnOff
    LDX #<MenuCursorStateLabel
    LDY #>MenuCursorStateLabel
    JSR PrintStringAtXY
    LDA CursorOffFlag
    JSR PrintOnOff
    LDX #<MenuTickStateLabel
    LDY #>MenuTickStateLabel
    JSR PrintStringAtXY
    LDA TickSoundOffFlag
    JSR PrintOnOff
    LDX #<MenuGameTypeStateLabel
    LDY #>MenuGameTypeStateLabel
    JSR PrintStringAtXY
    RTS

RefreshMainMenuState:
    JSR PrintMainMenuOptionStates
    LDY GameType
    LDA GameTypeDisplayLetterTable,Y
    JSR OSWRCH
    LDX #<MenuSkillStateLabel
    LDY #>MenuSkillStateLabel
    JSR PrintStringAtXY
    LDA SkillLevel
    ORA #&30
    JSR OSWRCH
    BIT ResumeGameAvailableFlag
    BPL PrintResumeUnavailableState
    LDX #<MenuContinueHelp
    LDY #>MenuContinueHelp
    JSR PrintStringAtXY
    JMP RefreshEditorAvailabilityState

PrintResumeUnavailableState:
    LDX #<MenuNewGameHelp
    LDY #>MenuNewGameHelp
    JSR PrintStringAtXY

RefreshEditorAvailabilityState:
    LDA EditorPositionInvalidFlag
    BNE RefreshResumeAvailabilityState
    LDX #<MenuRestartAlternativeHelp
    LDY #>MenuRestartAlternativeHelp
    JSR PrintStringAtXY

RefreshResumeAvailabilityState:
    BIT ResumeGameAvailableFlag
    BPL ReturnFromMainMenuRefresh
    LDX #<MenuNewGameAlternativeHelp
    LDY #>MenuNewGameAlternativeHelp
    JSR PrintStringAtXY

ReturnFromMainMenuRefresh:
    RTS

PrintOnOff:
    PHP
    LDA #&6E
    PLP
    BEQ PrintOnState
    LDA #&66
    JSR OSWRCH
    LDA #&66
    BNE PadOnOffState

PrintOnState:
    JSR OSWRCH
    LDA #&20

PadOnOffState:
    JSR OSWRCH
    LDA #&20
    JMP OSWRCH

; Sort complete 5-byte move records by descending ordering byte (+4).
; The original uses a gap-based/Shell-sort style pass and swaps records in place.
SortMovesByOrderingScore:
; In-place Shell-sort-like ordering of 5-byte move records by byte +4 (descending score).
; SortMovesGapPass recursively expands the gap by x3 before insertion passes unwind.
    SEC
    LDA MoveListEndLo
    SBC MoveListStartLo
    STA MoveSortSpanLo
    LDA MoveListEndHi
    SBC MoveListStartHi
    STA MoveSortSpanHi
    ORA MoveSortSpanLo
    BNE InitialiseMoveSortGap
    RTS

InitialiseMoveSortGap:
    LDA #&05
    STA MoveSortGapLo
    LDA #&00
    STA MoveSortGapHi

SortMovesGapPass:
    LDA MoveSortGapLo
    ASL A
    STA MoveSortRightLo
    LDA MoveSortGapHi
    ROL A
    STA MoveSortRightHi
    CLC
    LDA MoveSortGapLo
    ADC MoveSortRightLo
    STA MoveSortRightLo
    LDA MoveSortGapHi
    ADC MoveSortRightHi
    STA MoveSortRightHi
    CMP MoveSortSpanHi
    BNE TestExpandedSortGap
    LDA MoveSortRightLo
    CMP MoveSortSpanLo

TestExpandedSortGap:
    BCS StartGapInsertionPass
    LDA MoveSortGapLo
    PHA
    LDA MoveSortGapHi
    PHA
    LDA MoveSortRightLo
    STA MoveSortGapLo
    LDA MoveSortRightHi
    STA MoveSortGapHi
    JSR SortMovesGapPass
    PLA
    STA MoveSortGapHi
    PLA
    STA MoveSortGapLo

StartGapInsertionPass:
    CLC
    LDA MoveListStartLo
    ADC MoveSortGapLo
    STA MoveSortSourceLo
    LDA MoveListStartHi
    ADC MoveSortGapHi
    STA MoveSortSourceHi

StepInsertionSourceBackOneMove:
    SEC
    LDA MoveSortSourceLo
    SBC #&05
    STA MoveSortSourceLo
    STA MoveSortLeftLo
    LDA MoveSortSourceHi
    SBC #&00
    STA MoveSortSourceHi
    STA MoveSortLeftHi
    LDA MoveSortLeftLo
    CMP MoveListStartLo
    LDA MoveSortLeftHi
    SBC MoveListStartHi
    BCS FormGapComparisonPointer
    RTS

FormGapComparisonPointer:
    CLC
    LDA MoveSortLeftLo
    ADC MoveSortGapLo
    STA MoveSortRightLo
    LDA MoveSortLeftHi
    ADC MoveSortGapHi
    STA MoveSortRightHi

CompareGapSeparatedMoves:
    LDA MoveSortRightLo
    CMP MoveListEndLo
    LDA MoveSortRightHi
    SBC MoveListEndHi
    BCS StepInsertionSourceBackOneMove
    LDY #&04
    LDA (MoveSortLeftLo),Y
    CMP (MoveSortRightLo),Y
    BCS AdvanceGapComparisonPair

SwapMoveRecordsForOrdering:
    LDA (MoveSortLeftLo),Y
    PHA
    LDA (MoveSortRightLo),Y
    STA (MoveSortLeftLo),Y
    PLA
    STA (MoveSortRightLo),Y
    DEY
    BPL SwapMoveRecordsForOrdering
    LDA MoveSortLeftLo
    CMP MoveSortSourceLo
    BNE MoveInsertionPairBackByGap
    LDA MoveSortLeftHi
    CMP MoveSortSourceHi
    BNE MoveInsertionPairBackByGap

AdvanceGapComparisonPair:
    LDA MoveSortRightLo
    STA MoveSortLeftLo
    LDA MoveSortRightHi
    STA MoveSortLeftHi
    JMP FormGapComparisonPointer

MoveInsertionPairBackByGap:
    SEC
    LDA MoveSortLeftLo
    STA MoveSortRightLo
    SBC MoveSortGapLo
    STA MoveSortLeftLo
    LDA MoveSortLeftHi
    STA MoveSortRightHi
    SBC MoveSortGapHi
    STA MoveSortLeftHi
    JMP CompareGapSeparatedMoves

InitialiseDisplayAndState:
    LDA #&16
    JSR OSWRCH
    LDA #&07
    JMP OSWRCH

SetGameScreen:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &16,&05,&13,&01,&06,&00,&00,&00,&13,&02,&05,&00,&00,&00,&17,&00
    EQUB &0A,&20,&00,&00,&00,&00,&00,&00,&03,&0D
    NOP
    RTS

PollJoystickAxes:
; OSBYTE &80 with X=1..4 reads the four ADC channels.  Pairs (1,2) and (3,4)
; are quantised to board file/rank and stored as mailbox squares.  A final X=0 call
; reads the two fire buttons; the code preserves edge/debounce state in the high bit.
    LDA #&04
    TAX

ReadNextJoystickADCChannel:
    PHA
    LDA #&80
    JSR OSBYTE
    PLA
    TAX
    TYA
    AND #&E0
    ASL A
    ROL A
    ROL A
    ROL A
    STA JoystickADCWorkspaceBase,X
    TXA
    PHA
    AND #&01
    BEQ AdvanceJoystickADCChannel
    LDA JoystickADCWorkspaceBase,X
    EOR #&07
    STA JoystickADCWorkspaceBase,X
    CLC
    LDA Joystick1MailboxSquare,X
    TAY
    INY
    LDA #&0B

ConvertJoystickRankToMailbox:
    ADC #&0A
    DEY
    BNE ConvertJoystickRankToMailbox
    ADC JoystickADCWorkspaceBase,X
    STA JoystickADCWorkspaceBase,X

AdvanceJoystickADCChannel:
    PLA
    TAX
    DEX
    TXA
    BNE ReadNextJoystickADCChannel
    LDA #&80
    JSR OSBYTE
    TXA
    LDX #&05
    PHA
    AND #&01

UpdateNextFireButtonState:
    PHA
    LDA JoystickADCWorkspaceBase,X
    AND #&01
    STA JoystickADCWorkspaceBase,X
    PLA
    BEQ MarkFireButtonStateStable
    CMP JoystickADCWorkspaceBase,X
    BNE StoreFireButtonState

MarkFireButtonStateStable:
    ORA #&80

StoreFireButtonState:
    STA JoystickADCWorkspaceBase,X
    INX
    CPX #&07
    BEQ ReturnFromJoystickPoll
    PLA
    AND #&02
    LSR A
    JMP UpdateNextFireButtonState

ReturnFromJoystickPoll:
    RTS

SaveResumePosition:
    LDX #PIECE_SLOT_LAST

SaveResumePieceSlot:
    LDA PieceTypeArray,X
    STA ResumePieceTypes,X
    LDA PieceSquareArray,X
    STA ResumePieceSquares,X
    DEX
    BPL SaveResumePieceSlot
    RTS

RestoreResumePosition:
    LDX #PIECE_SLOT_LAST

RestoreResumePieceSlot:
    LDA ResumePieceTypes,X
    STA PieceTypeArray,X
    LDA ResumePieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL RestoreResumePieceSlot
    RTS

RestoreResumableGamePosition:
    JSR InitialisePosition
    JSR ClearMailboxBoard
    JSR RestoreResumePosition
    LDX #PIECE_SLOT_LAST

RebuildResumableMailboxSlot:
    LDA PieceTypeArray,X
    BMI AdvanceResumableMailboxSlot
    LDY PieceSquareArray,X
    TXA
    STA MailboxBoard,Y

AdvanceResumableMailboxSlot:
    DEX
    BPL RebuildResumableMailboxSlot
    RTS

EditBoardInteractively:
    LDY #&00
    STY CursorBlinkSuppressedFlag
    LDA #&04
    LDX #&01
    JSR OSBYTE
    JSR ResetEditorState
    JSR SetGameScreen
    LDA CursorOffFlag
    PHA
    LDA #&00
    STA CursorOffFlag
    STA ClockTickPending
    LDA #&15
    STA EditorCursorSquare
    LDA #&FF
    STA EventSuppressionFlags
    JSR DrawChessBoard
    JSR PrintEditorInformation
    JSR SelectMoveTextWindow

DrawEditorCursorSquare:
    LDA EditorCursorSquare
    JSR DrawMailboxSquare

ReadEditorCursorKey:
    JSR ReadGameKey

DispatchEditorCursorKey:
    CMP #&88
    BEQ MoveEditorCursorLeft
    CMP #&89
    BEQ MoveEditorCursorRight
    CMP #&8A
    BEQ MoveEditorCursorDownRank
    CMP #&8B
    BEQ MoveEditorCursorUpRank
    CMP #&57
    BEQ SelectWhitePieceToPlace
    CMP #&42
    BEQ SelectBlackPieceToPlace
    CMP #&7F
    BEQ DeletePieceAtCursor
    CMP #&2D
    BEQ DeletePieceAtCursor
    CMP #&1B
    BNE ReadEditorCursorKey
    PLA
    STA CursorOffFlag
    LDA #&FF
    STA EventSuppressionFlags
    STA CursorBlinkSuppressedFlag
    RTS

DeletePieceAtCursor:
    JSR RemovePieceAtEditorCursor
    JMP DrawEditorCursorSquare

MoveEditorCursorUpRank:
    LDA #&0A
    BNE TryMoveEditorCursor

MoveEditorCursorDownRank:
    LDA #&F6
    BNE TryMoveEditorCursor

MoveEditorCursorRight:
    LDA #&01
    BNE TryMoveEditorCursor

MoveEditorCursorLeft:
    LDA #&FF

TryMoveEditorCursor:
    CLC
    ADC EditorCursorSquare
    TAY
    LDA MailboxBoard,Y
    CMP #MAILBOX_OFFBOARD
    BEQ ReadEditorCursorKey
    LDA EditorCursorSquare
    STY EditorCursorSquare
    JSR DrawMailboxSquare
    JMP DrawEditorCursorSquare

SelectWhitePieceToPlace:
    LDX #&00
    BEQ ReadPieceTypeKey

SelectBlackPieceToPlace:
    LDX #&10

ReadPieceTypeKey:
    JSR ReadGameKey
    CMP #&4B
    BEQ PlaceKingIfAvailable
    CMP #&51
    BEQ SelectQueenForPlacement
    CMP #&52
    BEQ SelectRookForPlacement
    CMP #&42
    BEQ SelectBishopForPlacement
    CMP #&4E
    BEQ SelectKnightForPlacement
    CMP #&50
    BEQ SelectPawnForPlacement
    JMP DispatchEditorCursorKey

RejectPieceSelection:
    JMP ReadEditorCursorKey

PlaceKingIfAvailable:
    LDY PieceTypeArray,X
    BPL RejectPieceSelection
    JSR RemovePieceAtEditorCursor
    LDA #&00
    JMP PlacePieceAtEditorCursor

SelectQueenForPlacement:
    LDA #&02
    BNE FindFreePieceSlot

SelectRookForPlacement:
    LDA #&04
    BNE FindFreePieceSlot

SelectBishopForPlacement:
    LDA #&06
    BNE FindFreePieceSlot

SelectKnightForPlacement:
    LDA #&08
    BNE FindFreePieceSlot

SelectPawnForPlacement:
    LDA #PIECE_PAWN
    LDY EditorCursorSquare
    CPY #&5A
    BCS ReturnToEditorInput
    CPY #&1E
    BCC ReturnToEditorInput

FindFreePieceSlot:
    PHA
    JSR RemovePieceAtEditorCursor
    LDY #&0F

ScanForFreePieceSlot:
    INX
    LDA PieceTypeArray,X
    BMI UseFoundFreePieceSlot
    DEY
    BNE ScanForFreePieceSlot
    PLA

ReturnToEditorInput:
    JMP ReadEditorCursorKey

RemovePieceAtEditorCursor:
    PHA
    TXA
    PHA
    TYA
    PHA
    LDY EditorCursorSquare
    LDA MailboxBoard,Y
    BMI ReturnFromRemovePieceAtCursor
    TAX
    LDA #&80
    STA PieceTypeArray,X
    TYA
    STA PieceSquareArray,X
    LDA #&FF
    STA MailboxBoard,Y

ReturnFromRemovePieceAtCursor:
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

UseFoundFreePieceSlot:
    PLA

PlacePieceAtEditorCursor:
    STA PieceTypeArray,X
    LDY EditorCursorSquare
    STY PieceSquareArray,X
    TXA
    STA MailboxBoard,Y
    JMP DrawEditorCursorSquare

StoreEditorLegalityAndReturn:
    STY EditorLegalSideMask
    RTS

; Re-evaluate an editor position.  EditorLegalSideMask bit 7 means White can legally
; be the side to move; bit 6 means Black can.  Also infers castling rights from king/
; rook placement on their original squares.
ValidateEditorPosition:
    JSR InitialiseMoveListArena
    LDA #&04
    STA MoveRecordSize
    LDY #&00
    LDA PieceTypeArray
    BMI StoreEditorLegalityAndReturn
    LDA BlackPieceTypeArray
    BMI StoreEditorLegalityAndReturn
    LDA #&00
    STA EngineStopFlag
    STA BoardConsistencyCheckFlag
    STA EditorCastlingRights
    STA CastlingRights
    STA PositionScoreLo
    STA PositionScoreMid
    STA PositionScoreHi
    STA EditorLegalSideMask
    JSR ValidateSideAsEditorSideToMove
    BCS ValidateBlackAsSideToMove
    LDA #&80
    STA EditorLegalSideMask

ValidateBlackAsSideToMove:
    LDA #&10
    JSR ValidateSideAsEditorSideToMove
    BCS InferWhiteCastlingRights
    LDA #&40
    ORA EditorLegalSideMask
    STA EditorLegalSideMask

InferWhiteCastlingRights:
    LDA PieceTypeArray
    CMP InitialPieceTypes
    BNE InferBlackCastlingRights
    LDX MailboxH1
    BMI InferWhiteQueensideCastling
    CPX #&10
    BCS InferWhiteQueensideCastling
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE InferWhiteQueensideCastling
    LDA EditorCastlingRights
    ORA #&20
    STA EditorCastlingRights

InferWhiteQueensideCastling:
    LDX MailboxA1
    BMI InferBlackCastlingRights
    CPX #&10
    BCS InferBlackCastlingRights
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE InferBlackCastlingRights
    LDA EditorCastlingRights
    ORA #&10
    STA EditorCastlingRights

InferBlackCastlingRights:
    LDA BlackPieceTypeArray
    CMP InitialPieceTypes+16
    BNE ReturnFromEditorValidation
    LDX MailboxH8
    BMI InferBlackQueensideCastling
    CPX #&10
    BCC InferBlackQueensideCastling
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE InferBlackQueensideCastling
    LDA EditorCastlingRights
    ORA #CASTLE_BLACK_KINGSIDE
    STA EditorCastlingRights

InferBlackQueensideCastling:
    LDX MailboxA8
    BMI ReturnFromEditorValidation
    CPX #&10
    BCC ReturnFromEditorValidation
    LDA PieceTypeArray,X
    CMP #PIECE_ROOK
    BNE ReturnFromEditorValidation
    LDA EditorCastlingRights
    ORA #&40
    STA EditorCastlingRights

ReturnFromEditorValidation:
    RTS

ClearMailboxBoard:
    LDX #&78

ClearNextMailboxSquare:
    LDA MailboxBoard,X
    BMI ContinueMailboxClear
    LDA #&FF
    STA MailboxBoard,X

ContinueMailboxClear:
    DEX
    BNE ClearNextMailboxSquare
    RTS

ValidateSideAsEditorSideToMove:
    STA SideToMove
    JSR DoesSideToMoveGiveCheck
    BNE EditorSideIllegal
    LDA #&00
    STA CastlingRights
    STA EnPassantPawnSlot
    STA EnPassantTargetSquare
    JSR InitialiseMoveListArena
    JSR BuildLegalMoveList
    LDA MoveListEndLo
    CMP MoveListStartLo
    BNE EditorSideLegal
    LDA MoveListEndHi
    SBC MoveListStartHi
    BNE EditorSideLegal

EditorSideIllegal:
    SEC
    RTS

EditorSideLegal:
    CLC
    RTS

PrintEditorInformation:
    JSR SelectMainTextWindow
    LDX #&00

PrintNextEditorInformationByte:
    LDA BoardInformationText,X
    CMP #&0D
    BEQ ReturnFromEditorInformation
    JSR OSWRCH
    INX
    CPX #&3B
    BNE PrintNextEditorInformationByte

ReturnFromEditorInformation:
    RTS

ReturnToEditorKeyLoop:
    JMP EditorKeyLoop

; Editor "Find solution" / mate-search path; associated messages include "No mate in", "No solution found" and "Mate in".
; Iterative-deepening forced-mate solver for editor problems (depth 1..MateDepthLimit).
; Uses 4-byte move records and a mutually recursive AND/OR tree.
FindMateSolution:
    LDA EditorLegalSideMask
    AND #&C0
    BEQ ReturnToEditorKeyLoop
    JSR ResetEditorState
    JSR SavePositionSnapshot
    LDA EditorCastlingRights
    STA CastlingRights
    JSR RebuildMailboxBoard
    JSR SetGameScreen
    JSR DrawChessBoard
    JSR PrintEditorInformation
    JSR SelectMainTextWindow
    LDA #&07
    STA CurrentTextWindowId
    JSR SelectStatusTextWindow
    LDA #&00
    STA EngineStopFlag
    STA SearchPly
    LDA #&01
    STA MateSearchDepth
    JSR ResetEditorState
    JSR EnableEscapeEvent
    JSR DrawChessClocks
    LDX EditorSideToMove
    STX ActiveClockSideOffset
    JSR InstallEventHandler
    LDA #&00
    STA EventSuppressionFlags

TryNextMateDepth:
    JSR InitialiseMoveListArena
    LDA EditorSideToMove
    STA SideToMove
    LDA #&01
    STA MateSearchPly
    JSR FindForcedMateAttackerNode
    BCS MateSearchSucceeded
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&11,&02,&20,&20,&4E,&6F,&20,&6D,&61,&74,&65,&20,&69,&6E,&20 ; ...  No mate in 
    NOP
    LDA MateSearchDepth
    ORA #&30
    JSR OSWRCH
    INC MateSearchDepth
    LDA MateSearchDepth
    CMP MateDepthLimit
    BEQ TryNextMateDepth
    BCC TryNextMateDepth
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&11,&02,&20,&20,&4E,&6F,&20,&73,&6F,&6C,&75,&74,&69,&6F,&6E ; ...  No solution
    EQUB &20,&66,&6F,&75,&6E,&64 ;  found
    NOP
    JMP FinishMateSearch

MateSearchSucceeded:
    LDA #&FF
    STA EventSuppressionFlags
    LDA CursorOffFlag
    PHA
    LDA #&00
    STA CursorOffFlag
    JSR SelectStatusTextWindow
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0C,&11,&01,&20,&4D,&61,&74,&65,&20,&69,&6E,&20 ; ... Mate in 
    NOP
    LDA MateSearchDepth
    ORA #&30
    JSR OSWRCH
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &3A,&20,&11,&03
    NOP
    JSR MakeMove
    JSR PrintMoveNotation
    JSR ReadGameKey
    JSR RedrawAfterMakeMove
    JSR UnmakeMove
    JSR ReadGameKey
    PLA
    STA CursorOffFlag

FinishMateSearch:
    JSR DisableEscapeEvent
    LDA #&FF
    STA EventSuppressionFlags
    JSR RestoreChessClocks
    JSR ReadGameKey
    JMP EditorKeyLoop

; Attacker (OR) node: succeed if at least one legal move forces the defender node to
; succeed.  At the root the successful move remains in the current move variables.
FindForcedMateAttackerNode:
    JSR ServicePendingClockTick
    LDA MateSearchPly
    CMP MateSearchDepth
    BEQ BuildAttackerMoveList
    BCC BuildAttackerMoveList
    BCS ReturnMateFailure

AttackerNoMateAtThisNode:
    JSR PopMoveListFrame

ReturnMateFailure:
    CLC
    RTS

BuildAttackerMoveList:
    JSR BuildLegalMoveList4
    LDA MoveListStartLo
    CMP MoveListEndLo
    BNE StartAttackerMoveLoop
    LDA MoveListStartHi
    CMP MoveListEndHi
    BEQ AttackerNoMateAtThisNode

StartAttackerMoveLoop:
    LDA MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    STA MoveIteratorHi

TryAttackerMoveLoop:
    LDA MoveIteratorLo
    CMP MoveListEndLo
    LDA MoveIteratorHi
    SBC MoveListEndHi
    BCS AttackerNoMateAtThisNode
    JSR LoadMoveFromIterator
    JSR MakeMove
    LDA MoveIteratorLo
    PHA
    LDA MoveIteratorHi
    PHA
    JSR FindForcedMateDefenderNode
    PLA
    STA MoveIteratorHi
    PLA
    STA MoveIteratorLo
    PHP
    JSR LoadMoveFromIterator
    JSR UnmakeMove
    PLP
    BCS FinishAttackerMove
    LDA MoveIteratorLo
    ADC MoveRecordSize
    STA MoveIteratorLo
    BCC TryAttackerMoveLoop
    INC MoveIteratorHi
    JMP TryAttackerMoveLoop

FinishAttackerMove:
    LDA MateSearchPly
    CMP #&01
    JSR PopMoveListFrame
    SEC
    RTS

; Defender (AND) node: every legal reply must still allow the forced mate.
; Carry SET means the attacker can still force mate from this node; carry CLEAR means
; the defender has refuted the forced-mate claim.  No legal replies is success only
; when the defender is actually in check (checkmate rather than stalemate).
FindForcedMateDefenderNode:
    JSR ServicePendingClockTick
    JSR BuildLegalMoveList4
    LDA MoveListStartLo
    CMP MoveListEndLo
    BNE ContinueDefenderSearch
    LDA MoveListStartHi
    CMP MoveListEndHi
    BNE ContinueDefenderSearch
    JSR IsSideToMoveInCheck
    BEQ DefenderNodeFailure

; All defender continuations preserve the forced mate (or this is checkmate).
DefenderNodeSuccess:
    JSR PopMoveListFrame
    SEC
    RTS

; At least one defender continuation escapes the forced mate (or this is stalemate).
DefenderNodeFailure:
    JSR PopMoveListFrame
    CLC
    RTS

ContinueDefenderSearch:
    LDA MateSearchPly
    CMP MateSearchDepth
    BEQ DefenderNodeFailure
    LDA MoveListStartLo
    STA MoveIteratorLo
    LDA MoveListStartHi
    STA MoveIteratorHi

TryDefenderMoveLoop:
    LDA MoveIteratorLo
    CMP MoveListEndLo
    LDA MoveIteratorHi
    SBC MoveListEndHi
    BCS DefenderNodeSuccess
    JSR LoadMoveFromIterator
    JSR MakeMove
    INC MateSearchPly
    LDA MoveIteratorLo
    PHA
    LDA MoveIteratorHi
    PHA
    JSR FindForcedMateAttackerNode
    DEC MateSearchPly
    PLA
    STA MoveIteratorHi
    PLA
    STA MoveIteratorLo
    PHP
    JSR LoadMoveFromIterator
    JSR UnmakeMove
    PLP
    BCC DefenderNodeFailure
    LDA MoveIteratorLo
    CLC
    ADC MoveRecordSize
    STA MoveIteratorLo
    BCC TryDefenderMoveLoop
    INC MoveIteratorHi
    JMP TryDefenderMoveLoop

; -----------------------------------------------------------------------------
; Data &3D15-&3D26: Save-file compatibility signature: "(c) Acornsoft 1983"
; -----------------------------------------------------------------------------

; Used to recognise compatible saved positions/files.
SaveFileSignature:
    EQUB &28,&63,&29,&20,&41,&63,&6F,&72,&6E,&73,&6F,&66,&74,&20,&31,&39 ; (c) Acornsoft 19
    EQUB &38,&33
SaveFileSignatureEnd:

; Load a fixed &A0-byte editor-board file and validate its compatibility signature.
LoadBoardFile:
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&57,&68,&69,&63,&68,&20,&62,&6F,&61,&72,&64,&2D,&66,&69 ;   Which board-fi
    EQUB &6C,&65,&20,&64,&6F,&20,&79,&6F,&75,&20,&77,&61,&6E,&74,&3F ; le do you want?
    NOP
    JSR SetDialogInputArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&14
    STA LineInputMaxLength
    LDA #<FilenameBuffer
    STA LineInputBufferLo
    LDA #>FilenameBuffer
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCC OpenBoardFileForInput
    JMP FlushInputAndReturnToEditor

ErrorFileNotFound:
    BRK

; -----------------------------------------------------------------------------
; Data &3D7F-&3D8E: MOS error block/message: File not found
; -----------------------------------------------------------------------------
    EQUB &63,&46,&69,&6C,&65,&20,&6E,&6F,&74,&20,&66,&6F,&75,&6E,&64,&00 ; cFile not found.

ErrorIncompatibleFile:
    BRK

; -----------------------------------------------------------------------------
; Data &3D90-&3DA2: MOS error block/message: Incompatible file
; -----------------------------------------------------------------------------
    EQUB &2A,&49,&6E,&63,&6F,&6D,&70,&61,&74,&69,&62,&6C,&65,&20,&66,&69 ; *Incompatible fi
    EQUB &6C,&65,&00

OpenBoardFileForInput:
    LDA #&40
    LDX #<FilenameBuffer
    LDY #>FilenameBuffer
    JSR OSFIND
    STA Scratch07
    CMP #&00
    BEQ ErrorFileNotFound
    LDA #<LoadedImagePieceTypes
    STA AttackTargetSquare
    LDA #>LoadedImagePieceTypes
    STA Scratch43

ReadBoardFileByte:
    LDY Scratch07
    JSR OSBGET
    BCS ValidateBoardFileSignature
    LDY #&00
    STA (AttackTargetSquare),Y
    INC AttackTargetSquare
    BNE ReadBoardFileByte
    INC Scratch43
    LDA Scratch43
    SEC
    SBC #>LoadedImagePieceTypes
    CMP #((SaveImageEnd-SaveImageBase)/&100)+1
    BCC ReadBoardFileByte
    BCS ErrorIncompatibleFile

ValidateBoardFileSignature:
    JSR CloseAllFiles
    LDX #SAVE_SIGNATURE_CHECK_BYTES-1

CompareBoardFileSignature:
    LDA LoadedImageEnPassantTarget,X
    CMP SaveFileSignature,X
    BNE ErrorIncompatibleFile
    DEX
    BPL CompareBoardFileSignature
    JSR ClearMailboxBoard
    LDX #PIECE_SLOT_LAST

RestoreBoardFilePieceSlot:
    LDA LoadedImagePieceTypes,X
    STA PieceTypeArray,X
    LDA LoadedImagePieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL RestoreBoardFilePieceSlot
    LDA LoadedImagePlyLo
    STA EditorSideToMove
    LDA LoadedImagePlyHi
    STA MateDepthLimit
    LDA LoadedImageCastlingRights
    STA EditorCastlingRights
    LDX #INFO_TEXT_BYTES-1

RestoreBoardFileInfoByte:
    LDA LoadedImageHistoryBaseTypes,X
    STA BoardInformationText,X
    DEX
    BPL RestoreBoardFileInfoByte
    JSR RebuildMailboxBoard
    JSR ValidateEditorPosition

PromptAfterBoardLoad:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&0D,&0A,&0D,&82,&50,&72,&65,&73,&73,&20,&53,&50,&41,&43,&45 ; .....Press SPACE
    EQUB &20,&42,&41,&52 ;  BAR
    NOP
    JSR ReadGameKey

ReturnToEditorAfterBoardFile:
    JMP EditorKeyLoop

FlushInputAndReturnToEditor:
    LDA #&7E
    JSR OSBYTE
    JMP ReturnToEditorAfterBoardFile

; Save a fixed &A0-byte editor-board file: 32 type bytes, 32 square bytes, side/depth/
; castling state, compatibility signature and 60-byte information text.
SaveBoardFile:
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &50,&6C,&65,&61,&73,&65,&20,&74,&79,&70,&65,&20,&69,&6E,&20,&61 ; Please type in a
    EQUB &6E,&79,&20,&65,&78,&74,&72,&61,&20,&69,&6E,&66,&6F,&72,&6D,&61 ; ny extra informa
    EQUB &74,&69,&6F,&6E,&3A ; tion:
    NOP
    JSR SetDialogInputArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&3B
    STA LineInputMaxLength
    LDA #<BoardInformationText
    STA LineInputBufferLo
    LDA #>BoardInformationText
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCS FlushInputAndReturnToEditor
    JSR ClearDialogArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&57,&68,&61,&74,&20,&64,&6F,&20,&79,&6F,&75,&20,&77,&61,&6E ;  What do you wan
    EQUB &74,&20,&74,&6F,&20,&63,&61,&6C,&6C,&20,&74,&68,&65,&20,&66,&69 ; t to call the fi
    EQUB &6C,&65,&3F
    NOP
    JSR SetDialogInputArea
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &5F,&5F,&3E
    NOP
    LDA #&14
    STA LineInputMaxLength
    LDA #<FilenameBuffer
    STA LineInputBufferLo
    LDA #>FilenameBuffer
    STA LineInputBufferHi
    LDA #&20
    STA LineInputMinChar
    LDA #&7F
    STA LineInputMaxChar
    LDX #MOSParameterBlockLoByte
    LDY #MOSParameterBlockHiByte
    LDA #&00
    JSR OSWORD
    BCC BuildBoardSaveImage
    JMP FlushInputAndReturnToEditor

BuildBoardSaveImage:
    JSR SavePositionSnapshot
    LDX #PIECE_SLOT_LAST

CopyBoardSavePieceSlot:
    LDA PieceTypeArray,X
    STA LoadedImagePieceTypes,X
    LDA PieceSquareArray,X
    STA LoadedImagePieceSquares,X
    DEX
    BPL CopyBoardSavePieceSlot
    LDA EditorSideToMove
    STA LoadedImagePlyLo
    LDA MateDepthLimit
    STA LoadedImagePlyHi
    LDA EditorCastlingRights
    STA LoadedImageCastlingRights
    LDX #SaveFileSignatureEnd-SaveFileSignature-1

CopyBoardSaveSignatureByte:
    LDA SaveFileSignature,X
    STA LoadedImageEnPassantTarget,X
    DEX
    BPL CopyBoardSaveSignatureByte
    LDX #INFO_TEXT_BYTES-1

CopyBoardSaveInformationByte:
    LDA BoardInformationText,X
    STA LoadedImageHistoryBaseTypes,X
    DEX
    BPL CopyBoardSaveInformationByte
    JSR InlineOSFILE

; Inline data consumed by preceding call.
    EQUW FilenameBuffer
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUW LoadedImagePieceTypes,&0000,BoardFileImageEnd,&0000
    EQUB &00                         ; OSFILE reason: save
    JMP PromptAfterBoardLoad

ReturnToEditorAfterPrintPrompt:
    JMP EditorKeyLoop

ShowNoGameInMemoryForPrint:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&0D,&81,&20,&20,&4E,&6F,&20,&67,&61,&6D,&65,&20,&63,&75,&72 ; ...  No game cur
    EQUB &72,&65,&6E,&74,&6C,&79,&20,&69,&6E,&20,&6D,&65,&6D,&6F,&72,&79 ; rently in memory
    EQUB &0A,&0D,&0A,&0D,&82,&20,&20,&20,&20,&20,&20,&20,&2A,&2A,&2A,&2A ; .....       ****
    EQUB &20,&50,&72,&65,&73,&73,&20,&53,&50,&41,&43,&45,&20,&42,&41,&52 ;  Press SPACE BAR
    EQUB &20,&2A,&2A,&2A,&2A ;  ****
    NOP

WaitForSpaceAfterNoGameMessage:
    JSR ReadGameKey
    BCS ReturnToEditorAfterNoGameMessage
    CMP #&20
    BNE WaitForSpaceAfterNoGameMessage

ReturnToEditorAfterNoGameMessage:
    JMP EditorKeyLoop

PrintOrPlaybackGameFromEditor:
    JSR SavePositionSnapshot
    JSR ClearDialogArea
    JSR IsHistoryAtBeginning
    BCC AskWhetherToPrintGame
    JMP ShowNoGameInMemoryForPrint

AskWhetherToPrintGame:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &44,&6F,&20,&79,&6F,&75,&20,&77,&61,&6E,&74,&20,&74,&68,&65,&20 ; Do you want the 
    EQUB &67,&61,&6D,&65,&20,&70,&72,&69,&6E,&74,&65,&64,&20,&6F,&75,&74 ; game printed out
    EQUB &20,&28,&59,&2F,&4E,&29,&3F ;  (Y/N)?
    NOP
    LDA #&0F
    LDX #&01
    JSR OSBYTE
    JSR ReadGameKey
    BCC HandlePrintGameAnswer
    JMP ReturnToEditorAfterPrintPrompt

PlayThroughGameInsteadOfPrint:
    JMP PlayThroughGameFromEditor

HandlePrintGameAnswer:
    CMP #&59
    BNE PlayThroughGameInsteadOfPrint
    JSR InitialisePosition
    JSR ClearMailboxBoard
    JSR RestoreHistoryBasePosition
    JSR RebuildMailboxBoard
    LDX #&00
    STX PlyCountLo
    STX PlyCountHi
    LDA SideToMove
    BEQ PrintStoredGameInformation
    INC PlyCountLo

PrintStoredGameInformation:
    DEX
    STX UnusedState067D
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &02
    NOP
    LDX #&00
    LDY #&14

PrintNextStoredGameInfoChar:
    LDA GameInformationText,X
    CMP #&0D
    BEQ BeginPrintedMoveList
    JSR OSWRCH
    DEY
    BNE AdvanceStoredGameInfoChar
    LDY #&14
    LDA #&0D
    JSR OSWRCH

AdvanceStoredGameInfoChar:
    INX
    CPX #&3B
    BNE PrintNextStoredGameInfoChar

BeginPrintedMoveList:
    LDA #&0D
    JSR OSWRCH
    JSR OSWRCH

PrintGameMovesFromHistory:
    LDY PlyCountLo
    CPY GamePlyCountLo
    BEQ LoadNextMoveForPrintedHistory
    LDA PlyCountHi
    SBC GamePlyCountHi
    BCS FinishPrintedHistoryAndReturnEditor

LoadNextMoveForPrintedHistory:
    JSR LoadMoveFromGameHistory
    BCS FinishPrintedHistoryAndReturnEditor
    TYA
    LSR A
    BCS ReplayHistoryMoveForPrinting
    ADC #&01
    STA Scratch07
    LDA #&00
    STA Scratch08
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &0A,&0D
    NOP
    JSR PrintWordDecimal
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &2E,&20
    NOP
    LDA PlyCountLo
    PHA
    LDA #&00
    STA SearchPly
    JSR MakeMove
    JSR PrintMoveNotation
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &2C,&20
    NOP

AdvancePrintedHistoryPly:
    PLA
    TAY
    INY
    STY PlyCountLo
    BNE PrintGameMovesFromHistory

FinishPrintedHistoryAndReturnEditor:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &03
    NOP
    JMP EditorKeyLoop

ContinuePrintingHistory:
    JMP PrintGameMovesFromHistory

ReplayHistoryMoveForPrinting:
    LDA PlyCountLo
    PHA
    JSR MakeMove
    JSR PrintMoveNotation
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &2E
    NOP
    JMP AdvancePrintedHistoryPly

PlayThroughGameFromEditor:
    JSR PlaybackGameHistory
    JMP EditorKeyLoop

ResetEditorState:
    LDA #&00
    STA ClockSecondsBase
    STA ClockMinutesBase
    STA ClockHoursBase
    STA BlackClockSecondsBase
    STA BlackClockMinutesBase
    STA BlackClockHoursBase
    RTS

; -----------------------------------------------------------------------------
; Data &40B5-&428D: Game-editor menu VDU/display data and tables
; -----------------------------------------------------------------------------

; Packed board-editor menu data; deliberately retained as data.
; -----------------------------------------------------------------------------
; Game-editor menu/status data. Pointer tables are label-derived.
; -----------------------------------------------------------------------------
; Packed Game Editor heading.
EditorMenuData:
    EQUB &17,&83,&9D,&84,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20
    EQUB &20,&20,&45,&64,&69,&74,&6F,&72
EditorWhiteFirstString:
    EQUB &16,&83,&57,&20,&2D,&20,&57,&68,&69,&74,&65,&20,&6D,&6F,&76,&65
    EQUB &73,&20,&66,&69,&72,&73,&74
EditorBlackFirstString:
    EQUB &16,&83,&42,&20,&2D,&20,&42,&6C,&61,&63,&6B,&20,&6D,&6F,&76,&65
    EQUB &73,&20,&66,&69,&72,&73,&74
EditorLoadBoardString:
    EQUB &19,&81,&4C,&20,&2D,&20,&4C,&6F,&61,&64,&20,&42,&6F,&61,&72,&64
    EQUB &20,&66,&72,&6F,&6D,&20,&74,&61,&70,&65
EditorSaveBoardString:
    EQUB &19,&81,&53,&20,&2D,&20,&53,&61,&76,&65,&20,&42,&6F,&61,&72,&64
    EQUB &20,&20,&74,&6F,&20,&20,&74,&61,&70,&65
EditorOldPositionString:
    EQUB &17,&85,&4F,&20,&2D,&20,&4F,&6C,&64,&20,&62,&6F,&61,&72,&64,&20
    EQUB &70,&6F,&73,&69,&74,&69,&6F,&6E
EditorReadGameString:
    EQUB &17,&85,&52,&20,&2D,&20,&52,&65,&61,&64,&20,&67,&61,&6D,&65,&20
    EQUB &70,&6F,&73,&69,&74,&69,&6F,&6E
EditorNewPositionString:
    EQUB &17,&85,&4E,&20,&2D,&20,&4E,&65,&77,&20,&62,&6F,&61,&72,&64,&20
    EQUB &70,&6F,&73,&69,&74,&69,&6F,&6E
EditorInitialPositionString:
    EQUB &17,&85,&49,&20,&2D,&20,&49,&6E,&69,&74,&69,&61,&6C,&20,&20,&20
    EQUB &70,&6F,&73,&69,&74,&69,&6F,&6E
EditorPlayThroughString:
    EQUB &16,&82,&50,&20,&2D,&20,&50,&6C,&61,&79,&20,&74,&68,&72,&6F,&75
    EQUB &67,&68,&20,&67,&61,&6D,&65
EditorMateTwoString:
    EQUB &16,&86,&32,&20,&2D,&20,&4D,&61,&74,&65,&20,&69,&6E,&20,&74,&77
    EQUB &6F,&20,&6D,&6F,&76,&65,&73
EditorMateRangeSeparatorString:
    EQUB &04,&86,&3A,&20,&2D
EditorMateFiveString:
    EQUB &17,&86,&35,&20,&2D,&20,&4D,&61,&74,&65,&20,&69,&6E,&20,&66,&69
    EQUB &76,&65,&20,&6D,&6F,&76,&65,&73
EditorFindSolutionString:
    EQUB &12,&82,&46,&20,&2D,&20,&46,&69,&6E,&64,&20,&73,&6F,&6C,&75,&74
    EQUB &69,&6F,&6E
EditorBlankMenuString:
    EQUB &01,&20
EditorStatusCursorPrefix:
    EQUB &03,&1F,&00,&02
EditorStatusHeader:
    EQUB &06,&1F,&00,&17,&86,&9D,&84
EditorStatusToPlayText:
    EQUB &15,&20,&74,&6F,&20,&70,&6C,&61,&79,&20,&61,&6E,&64,&20,&6D,&61
    EQUB &74,&65,&20,&69,&6E,&20
EditorStatusMoveWord:
    EQUB &05,&20,&6D,&6F,&76,&65
EditorIllegalPositionString:
    EQUB &2B,&1F,&00,&17,&81,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&49
    EQUB &6C,&6C,&65,&67,&61,&6C,&20,&70,&6F,&73,&69,&74,&69,&6F,&6E,&20
    EQUB &20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20
EditorWhiteNameString:
    EQUB &05,&57,&68,&69,&74,&65
EditorBlackNameString:
    EQUB &05,&42,&6C,&61,&63,&6B
MateWordOne:
    EQUB &03,&6F,&6E,&65
MateWordTwo:
    EQUB &03,&74,&77,&6F
MateWordThree:
    EQUB &05,&74,&68,&72,&65,&65
MateWordFour:
    EQUB &04,&66,&6F,&75,&72
MateWordFive:
    EQUB &04,&66,&69,&76,&65
MateDepthWordPointerTable:
    EQUW MateWordOne,MateWordTwo,MateWordThree,MateWordFour,MateWordFive
EditorMenuPointerTable:
    EQUW EditorPlayThroughString,EditorFindSolutionString,EditorBlankMenuString
    EQUW EditorNewPositionString,EditorReadGameString,EditorInitialPositionString
    EQUW EditorOldPositionString,EditorLoadBoardString,EditorSaveBoardString
    EQUW EditorBlankMenuString,EditorWhiteFirstString,EditorBlackFirstString
    EQUW EditorMateTwoString,EditorMateRangeSeparatorString,EditorMateFiveString

PrintMateDepthWord:
    ORA #&00
    BNE ClampMateDepthUpperBound
    LDA #&01

ClampMateDepthUpperBound:
    CMP #&06
    BCC LookupMateDepthWord
    LDA #&05

LookupMateDepthWord:
    ASL A
    TAY
    DEY
    DEY
    LDX MateDepthWordPointerTable,Y
    LDA MateDepthWordPointerTable+1,Y
    TAY
    JMP PrintStringAtXY

PrintSideName:
    CMP #&10
    BEQ PrintBlackSideName
    LDX #<EditorWhiteNameString
    LDY #>EditorWhiteNameString
    JSR PrintStringAtXY
    RTS

PrintBlackSideName:
    LDX #<EditorBlackNameString
    LDY #>EditorBlackNameString
    JSR PrintStringAtXY
    RTS

RefreshEditorStatus:
    LDA EditorLegalSideMask
    BNE PrintValidEditorStatus
    LDX #<EditorIllegalPositionString
    LDY #>EditorIllegalPositionString
    JSR PrintStringAtXY
    LDX #<MenuEditorAvailableHelp
    LDY #>MenuEditorAvailableHelp
    JSR PrintStringAtXY
    RTS

PrintValidEditorStatus:
    LDX #<EditorStatusHeader
    LDY #>EditorStatusHeader
    JSR PrintStringAtXY
    LDA EditorSideToMove
    JSR PrintSideName
    LDX #<EditorStatusToPlayText
    LDY #>EditorStatusToPlayText
    JSR PrintStringAtXY
    LDA MateDepthLimit
    JSR PrintMateDepthWord
    LDX #<EditorStatusMoveWord
    LDY #>EditorStatusMoveWord
    JSR PrintStringAtXY
    LDA MateDepthLimit
    CMP #&02
    BCC FinishEditorStatusLine
    LDA #&73
    JSR OSWRCH

FinishEditorStatusLine:
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &20,&20,&20,&20 ;     
    NOP
    LDX #<MenuEditorAvailableHelp
    LDY #>MenuEditorAvailableHelp
    JSR PrintStringAtXY
    RTS

DrawEditorMenu:
    LDA #&0C
    STA MenuItemRightEdgeX
    JSR PrintInline

; Inline data consumed by preceding call.
    EQUB &16,&07
    NOP
    LDX #<EditorMenuData
    LDY #>EditorMenuData
    JSR PrintPackedMenuBlock
    LDX #<EditorStatusCursorPrefix
    LDY #>EditorStatusCursorPrefix
    JSR PrintStringAtXY
    LDA #&0F
    STA MenuItemIndex

PrintNextEditorMenuItem:
    JSR OSNEWL
    LDA #&0F
    SEC
    SBC MenuItemIndex
    ASL A
    TAY
    LDA EditorMenuPointerTable,Y
    TAX
    LDA EditorMenuPointerTable+1,Y
    TAY
    LDA #&2D
    JSR PrintMenuItemFromTable
    DEC MenuItemIndex
    BNE PrintNextEditorMenuItem
    LDX #<MenuEditorAvailableHelp
    LDY #>MenuEditorAvailableHelp
    JSR PrintStringAtXY
    RTS

SelectWhiteEditorSideIfLegal:
    BIT EditorLegalSideMask
    BPL RefreshEditorAfterSideSelection
    LDA #&00
    STA EditorSideToMove

RefreshEditorAfterSideSelection:
    JMP RefreshEditorAndReadCommand

SelectBlackEditorSideIfLegal:
    BIT EditorLegalSideMask
    BVC RefreshEditorAfterSideSelection
    LDA #&10
    STA EditorSideToMove
    JMP RefreshEditorAndReadCommand

EnterInteractiveBoardEdit:
    JSR EditBoardInteractively
    JSR SavePositionSnapshot
    JSR ValidateEditorPosition
    LDA EditorLegalSideMask
    BEQ ReturnToEditorCommandLoop
    CMP #EDITOR_BOTH_LEGAL
    BEQ ReturnToEditorCommandLoop
    LDX #&00
    CMP #EDITOR_WHITE_LEGAL
    BEQ StoreOnlyLegalEditorSide
    LDX #&10

StoreOnlyLegalEditorSide:
    STX EditorSideToMove

ReturnToEditorCommandLoop:
    JMP EditorKeyLoop

NewEmptyEditorPosition:
    JSR ClearMailboxBoard
    JSR CopyResumePositionToLive
    LDA #&00
    STA EditorLegalSideMask
    BEQ RefreshEditorAndReadCommand

ReadCurrentGameIntoEditor:
    JSR ClearMailboxBoard
    JSR CopyGamePositionToLive
    JSR RebuildMailboxBoard
    JSR ValidateEditorPosition
    JMP EnterInteractiveBoardEdit

RestoreOldEditorPosition:
    JSR ClearMailboxBoard
    JSR RestorePositionSnapshot
    JSR RebuildMailboxBoard
    JSR ValidateEditorPosition
    JMP EnterInteractiveBoardEdit

LoadInitialPositionIntoEditor:
    JSR ClearMailboxBoard
    JSR ResetToInitialPieceArrays
    JSR RebuildMailboxBoard
    LDA #&C0
    STA EditorLegalSideMask
    JMP EnterInteractiveBoardEdit

ExitEditor:
    JSR SavePositionSnapshot
    LDX #&00
    LDA EditorLegalSideMask
    BNE StoreEditorInvalidFlag
    DEX

StoreEditorInvalidFlag:
    STX EditorPositionInvalidFlag
    RTS

ReturnToEditorAfterError:
    JSR ClearMailboxBoard
    JSR RestorePositionSnapshot
    JSR RebuildMailboxBoard
    JSR ValidateEditorPosition
    JMP EditorKeyLoop

EditorEntry:
    JMP SavePositionSnapshot

EditorKeyLoop:
    JSR DrawEditorMenu

RefreshEditorAndReadCommand:
    JSR RefreshEditorStatus

ReadEditorCommand:
    JSR ReadGameKey
    BCS ExitEditor
    CMP #&0D
    BNE TryEditorLoadCommand
    JMP EnterInteractiveBoardEdit

TryEditorLoadCommand:
    CMP #&4C
    BNE TryEditorSaveCommand
    JMP LoadBoardFile

TryEditorSaveCommand:
    CMP #&53
    BNE TryEditorInitialPositionCommand
    JMP SaveBoardFile

TryEditorInitialPositionCommand:
    CMP #&49
    BEQ LoadInitialPositionIntoEditor
    CMP #&4E
    BNE TryEditorReadGameCommand
    JMP NewEmptyEditorPosition

TryEditorReadGameCommand:
    CMP #&52
    BEQ ReadCurrentGameIntoEditor
    CMP #&57
    BNE TryEditorBlackSideCommand
    JMP SelectWhiteEditorSideIfLegal

TryEditorBlackSideCommand:
    CMP #&42
    BNE TryEditorPlaybackCommand
    JMP SelectBlackEditorSideIfLegal

TryEditorPlaybackCommand:
    CMP #&50
    BNE TryEditorFindMateCommand
    JMP PrintOrPlaybackGameFromEditor

TryEditorFindMateCommand:
    CMP #&46
    BNE TryEditorRestoreOldCommand
    JMP FindMateSolution

TryEditorRestoreOldCommand:
    CMP #&4F
    BNE TryEditorMateDepthDigit
    JMP RestoreOldEditorPosition

TryEditorMateDepthDigit:
    CMP #&36
    BCS ReadEditorCommand
    CMP #&32
    BCC ReadEditorCommand
    SBC #&30
    STA MateDepthLimit
    JMP RefreshEditorAndReadCommand

CopyResumePositionToLive:
    LDX #PIECE_SLOT_LAST
    LDA #&80

TestResumePositionOccupiedSlots:
    AND PieceTypeArray,X
    DEX
    BPL TestResumePositionOccupiedSlots
    TAX
    BMI ReturnFromCopyEditorSnapshot
    JSR SavePositionSnapshot

CopyEditorSnapshotToLive:
    LDX #PIECE_SLOT_LAST

ClearLivePieceTypesForEditor:
    LDA #&80
    STA PieceTypeArray,X
    DEX
    BPL ClearLivePieceTypesForEditor
    CLC

ReturnFromCopyEditorSnapshot:
    RTS

ResetToInitialPieceArrays:
    JSR SavePositionSnapshot
    LDX #PIECE_SLOT_LAST

CopyInitialPieceSlot:
    LDA InitialPieceTypes,X
    STA PieceTypeArray,X
    LDA InitialPieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL CopyInitialPieceSlot
    RTS

CopyGamePositionToLive:
    JSR SavePositionSnapshot
    LDX #PIECE_SLOT_LAST

CopyGamePieceSlot:
    LDA ResumePieceTypes,X
    STA PieceTypeArray,X
    LDA ResumePieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL CopyGamePieceSlot
    RTS

; Copies live piece arrays to snapshot workspace.
SavePositionSnapshot:
    LDX #PIECE_SLOT_LAST

SaveSnapshotPieceSlot:
    LDA PieceTypeArray,X
    STA SnapshotPieceTypes,X
    LDA PieceSquareArray,X
    STA SnapshotPieceSquares,X
    DEX
    BPL SaveSnapshotPieceSlot
    RTS

; Restores the live piece arrays from snapshot workspace.
RestorePositionSnapshot:
    LDX #PIECE_SLOT_LAST

RestoreSnapshotPieceSlot:
    LDA SnapshotPieceTypes,X
    STA PieceTypeArray,X
    LDA SnapshotPieceSquares,X
    STA PieceSquareArray,X
    DEX
    BPL RestoreSnapshotPieceSlot
    RTS

; Reconstructs the 10x12 mailbox board from the piece-square array.
RebuildMailboxBoard:
    LDY #&1F

RebuildMailboxFromPieceSlot:
    LDA PieceTypeArray,Y
    BMI AdvanceMailboxRebuildSlot
    LDX PieceSquareArray,Y
    TYA
    STA MailboxBoard,X

AdvanceMailboxRebuildSlot:
    DEY
    BPL RebuildMailboxFromPieceSlot
    RTS

; Custom IRQ1V handler. Chains to the saved original vector at (&0E15) when appropriate.
IRQ1Handler:
    PHP
    PHA
    LDA USERVIA_T1CL
    LDA MOSBreakActionFlags
    BPL DispatchIntervalEventFromOldOSIRQ

CheckEscapeFromOldOSIRQ:
    BIT MOSEscapeFlag
    BMI DispatchEscapeEventFromOldOSIRQ

ChainOriginalIRQ1:
    PLA
    PLP
    JMP (SavedOldIRQ1V)

DispatchEventFromOldOSIRQ:
    JMP EventHandler

DispatchIntervalEventFromOldOSIRQ:
    LDA #&05
    JSR DispatchEventFromOldOSIRQ
    JMP CheckEscapeFromOldOSIRQ

DispatchEscapeEventFromOldOSIRQ:
    LDA #&06
    JSR DispatchEventFromOldOSIRQ
    JMP ChainOriginalIRQ1

; -----------------------------------------------------------------------------
; Data &44E0-&44E0: Standalone RTS immediately before bootstrap
; -----------------------------------------------------------------------------

IRQHandlerReturn:
    EQUB &60

; -----------------------------------------------------------------------------
; End of permanent engine / start of reclaimable workspace
; -----------------------------------------------------------------------------
; No bytes are emitted here.  Search move frames and file-load buffers start at this
; exact address and may overwrite everything above it up to MoveArenaLimit.
MoveArenaBase:
PermanentEngineEnd = MoveArenaBase

; -----------------------------------------------------------------------------
; One-shot direct-runtime startup module
; -----------------------------------------------------------------------------
; This begins exactly at MoveArenaBase, immediately after the permanent engine.  It is
; transient by design: once it jumps to ChessRuntimeEntry, the same RAM becomes the
; generated-move / file-load workspace and may overwrite every byte below.
;
; Keeping startup here also means the assembler emits ONE contiguous segment from &0E00,
; so Save boot disk / Feeling Lucky uses the ordinary single-segment mover and does not
; need the multi-ORG scatter staging area.
StartupTransientBase = MoveArenaBase

GameEntry:
    ; The generated BASIC loader has already executed *TAPE before moving the binary.
    ; Repeat OSBYTE &8C here so a manually loaded build also selects CFS immediately.
    ; This must precede other filing-system activity because the engine occupies DFS RAM.
    LDA #&8C
    LDX #&00
    JSR OSBYTE

    ; Define VDU characters &E0-&FF from the recovered 256-byte character table.
    LDX #&00
    LDY #&E0

StartupDefineCharactersLoop:
    TXA
    AND #&07
    BNE StartupEmitCharacterByte
    LDA #&17
    JSR OSWRCH
    TYA
    JSR OSWRCH
    INY

StartupEmitCharacterByte:
    LDA StartupVDUCharacterData,X
    JSR OSWRCH
    INX
    BNE StartupDefineCharactersLoop

    LDA #&FF
    STA EventSuppressionFlags
    STA CursorBlinkSuppressedFlag
    JSR StartupMachineInitialisation
    JSR InstallEventHandler

    ; Default game/editor state recovered from the original bootstrap.
    LDA #&02
    STA SkillLevel
    LDA #&01
    STA GameType
    LDA #&02
    STA MateDepthLimit
    LDA #MOVE_RECORD_BYTES
    STA MoveRecordSize
    LDA #&00
    STA EditorSideToMove
    STA PlyCountLo
    STA PlyCountHi
    STA GamePlyCountLo
    STA GamePlyCountHi
    STA EditorLegalSideMask

    JSR ResetEditorState
    JSR SnapshotChessClocks
    JSR InitialisePosition
    JSR SavePositionSnapshot
    JSR CopyEditorSnapshotToLive
    JSR ClearMailboxBoard

    ; These strings live later in this same transient startup block.  They remain intact
    ; until copied here; after the final jump the move arena may overwrite them.
    LDX #StartupTextData2-EditorBannerData-1
StartupCopyEditorBanner:
    LDA EditorBannerData,X
    STA GameInformationText,X
    DEX
    BPL StartupCopyEditorBanner

    LDX #Envelope1Block-StartupTextData2-1
StartupCopyInformationText:
    LDA StartupTextData2,X
    STA BoardInformationText,X
    DEX
    BPL StartupCopyInformationText

    LDA #&00
    STA EditorLegalSideMask
    LDA #&01
    STA CursorFlashXorMask
    LDA #&00
    STA TickSoundOffFlag
    STA BoardSquareColourXor
    STA ResumeGameAvailableFlag
    STA CursorOffFlag
    STA EditorModeActiveFlag
    LDA #&FF
    STA JoysticksOffFlag
    STA TickSoundOffFlag
    STA EventSuppressionFlags
    STA EditorPositionInvalidFlag
    STA UnusedState067D
    LDA #&01
    STA UnusedTurnState0658

    JSR PollJoystickAxes
    LDA #SQ_A1
    STA EditorCursorSquare

    ; Original MOS setup.
    LDA #&04
    LDX #&01
    JSR OSBYTE
    LDA #&10
    LDX #&04
    JSR OSBYTE
    LDA #&06
    STA MoveFlashCadence
    LDA #&0C
    LDX #&00
    JSR OSBYTE
    LDA #&0C
    LDX #&41
    JSR OSBYTE

    ; Define the two original sound envelopes while this temporary data is intact.
    LDX #<Envelope1Block
    LDY #>Envelope1Block
    LDA #&08
    JSR OSWORD
    LDX #<Envelope2Block
    LDY #>Envelope2Block
    LDA #&08
    JSR OSWORD

    LDA #<BreakHandler
    STA BRKV
    LDA #>BreakHandler
    STA BRKV+1

    ; Startup is complete.  Never return here: move generation / file loading may now
    ; reuse and overwrite this entire transient block.
    JMP ChessRuntimeEntry

; Detect MOS/machine capabilities and configure event handling.
StartupOldOSPathJump:
    JMP StartupInstallIRQ1ForOldOS

StartupMachineInitialisation:
    JSR ProgramEventTimer
    LDA #&00
    STA SecondProcessorFlag
    LDA #&FF
    STA EventSuppressionFlags
    LDA #&0C
    STA ClockWorkspace03
    LDY #&FF
    LDA #&81
    LDX #&00
    JSR OSBYTE
    TXA
    BEQ StartupOldOSPathJump
    CMP #&01
    BNE StartupInitialiseModernMOSServices
    JSR PrintInline

    ; Inline text consumed by PrintInline.
    EQUB &0D,&0A,&20,&20,&20,&20,&53,&6F,&72,&72,&79,&20,&2D,&20,&74,&68
    EQUB &69,&73,&20,&76,&65,&72,&73,&69,&6F,&6E,&20,&6F,&66,&20,&43,&68
    EQUB &65,&73,&73,&20,&69,&73,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20
    EQUB &20,&75,&6E,&73,&75,&69,&74,&61,&62,&6C,&65,&20,&66,&6F,&72,&20
    EQUB &61,&6E,&20,&45,&6C,&65,&63,&74,&72,&6F,&6E
    NOP

StartupElectronUnsupportedHalt:
    JMP StartupElectronUnsupportedHalt

StartupInitialiseModernMOSServices:
    LDA #&FF
    STA ModernMOSEventFlag
    LDA #&0E
    LDX #&05
    JSR OSBYTE
    LDA #&0E
    LDX #&06
    JSR OSBYTE
    LDY #&00
    LDA #&C8
    LDX #&02
    JSR OSBYTE
    LDY #&00
    LDA #&F7
    LDX #&00
    JSR OSBYTE
    LDY #&FF
    LDA #&EA
    LDX #&00
    JSR OSBYTE
    TYA
    BMI StartupDetectTubeSecondProcessor
    RTS

StartupDetectTubeSecondProcessor:
    LDA #&82
    LDX #&00
    JSR OSBYTE
    TYA
    BNE StartupMachineInitReturn
    DEC SecondProcessorFlag
StartupMachineInitReturn:
    RTS

; MOS 0.1 compatibility path: install the recovered IRQ1V handler directly.
StartupInstallIRQ1ForOldOS:
    LDA #&00
    STA ModernMOSEventFlag
    SEI
    LDA IRQ1V
    STA SavedOldIRQ1V
    LDA IRQ1V+1
    STA SavedOldIRQ1V+1
    LDA #<IRQ1Handler
    STA IRQ1V
    LDA #>IRQ1Handler
    STA IRQ1V+1
    LDA #&40
    STA USERVIA_ACR
    LDA #&10
    STA USERVIA_T1CL
    LDA #&10
    STA USERVIA_T1CH
    LDA #&3F
    STA USERVIA_IER
    LDA #&C0
    STA USERVIA_IER
    CLI
    RTS

; -----------------------------------------------------------------------------
; Startup-only text, sound envelopes and custom character bitmaps
; -----------------------------------------------------------------------------
EditorBannerData:
    EQUB &43,&68,&65,&73,&73,&20,&3A,&20,&47,&61,&6D,&65,&20,&45,&64,&69 ; Chess : Game Edi
    EQUB &74,&6F,&72,&2E,&28,&63,&29,&20,&41,&63,&6F,&72,&6E,&73,&6F,&66 ; tor.(c) Acornsof
    EQUB &74,&20,&31,&39,&38,&33,&20,&20,&48,&69,&74,&20,&45,&53,&43,&41 ; t 1983  Hit ESCA
    EQUB &50,&45,&20,&74,&6F,&20,&65,&78,&69,&74,&2E,&0D ; PE to exit..

StartupTextData2:
    EQUB &20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20,&20
    EQUB &20,&20,&20,&20,&50,&72,&65,&73,&73,&20,&45,&53,&43,&41,&50,&45
    EQUB &20,&74,&6F,&20,&65,&78,&69,&74,&0D

; Two 14-byte OSWORD 8 ENVELOPE parameter blocks used during startup.
Envelope1Block:
    EQUB &01,&01,&00,&00,&00,&01,&01,&01,&4B,&B5,&B5,&B5,&4B,&00
Envelope2Block:
    EQUB &02,&02,&01,&FF,&00,&01,&01,&04,&78,&F6,&FF,&FE,&78,&64

StartupVDUCharacterData:
    EQUB &00,&04,&06,&07,&0F,&0F,&1F,&1B,&00,&00,&00,&E0,&F0,&F8,&FC,&FC
    EQUB &1F,&3F,&7E,&7C,&39,&19,&01,&03,&FC,&FC,&FC,&F8,&F8,&F8,&F0,&E0 ; .?~|9...........
    EQUB &07,&0F,&1F,&3F,&3F,&7F,&7F,&00,&E0,&F0,&F8,&FC,&FE,&FE,&FE,&00
    EQUB &00,&19,&19,&1F,&1F,&1F,&0F,&07,&00,&98,&98,&F8,&F8,&F8,&F0,&E0
    EQUB &07,&07,&07,&07,&07,&07,&07,&07,&E0,&E0,&E0,&E0,&E0,&E0,&E0,&E0
    EQUB &07,&0F,&0F,&1F,&1F,&3F,&3F,&00,&E0,&F0,&F0,&F8,&F8,&FC,&FC,&00
    EQUB &00,&01,&03,&01,&3D,&67,&43,&51,&00,&80,&C0,&80,&BC,&E6,&C2,&8A ; ....=gCQ........
    EQUB &59,&49,&4D,&67,&33,&19,&0D,&07,&9A,&92,&B2,&E6,&CC,&98,&B0,&E0 ; YIMg3...........
    EQUB &0E,&3B,&6E,&79,&37,&0F,&00,&00,&70,&DC,&76,&9E,&EC,&F0,&00,&00 ; .:ny7...p.v.....
    EQUB &00,&01,&01,&03,&03,&07,&07,&0E,&00,&80,&80,&C0,&C0,&E0,&E0,&70
    EQUB &0E,&1C,&1C,&1E,&0E,&0E,&0E,&07,&70,&38,&38,&78,&70,&70,&70,&E0 ; ........p88xppp.
    EQUB &07,&07,&03,&03,&1F,&3F,&70,&30,&E0,&EC,&C6,&C6,&FC,&F8,&00,&00
    EQUB &00,&01,&02,&01,&09,&49,&45,&39,&00,&80,&40,&80,&90,&92,&A2,&9C ; .....IE9..@.....
    EQUB &2F,&27,&13,&1B,&0B,&0F,&07,&07,&F4,&E4,&C8,&D8,&D0,&F0,&E0,&E0
    EQUB &00,&00,&01,&01,&01,&03,&03,&01,&00,&00,&80,&80,&80,&C0,&C0,&80
    EQUB &0F,&1F,&19,&01,&01,&03,&03,&07,&F0,&F8,&98,&80,&80,&C0,&C0,&E0

DirectBuildEnd:
ChessImageEnd = DirectBuildEnd
ChessImageSize = DirectBuildEnd-RUNTIME_BASE

; The web boot mover occupies &7AE0-&7BF4 while installing the single contiguous image.
; Ensure the complete emitted image remains below the mover.
WEB_BOOT_MOVER_BASE = &7AE0
ASSERT ((WEB_BOOT_MOVER_BASE - DirectBuildEnd + &10000) >> 16)
