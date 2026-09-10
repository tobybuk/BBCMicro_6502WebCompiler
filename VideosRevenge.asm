; Video's Revenge (BBC Micro, 1985) - reconstructed source
;
; RELOCATABLE SOURCE
; ------------------
; @default-origin &09C0
;
; The @default-origin line is source metadata for the BBC 6502 Web Assembler.
; It pre-populates the Origin field when this file is opened, but it is not an
; ORG directive and does not constrain relocation. Change the Origin field to
; assemble the complete program at another suitable address.
;
; This source deliberately contains no assembly origin. Select the run/assembly
; origin in the assembler. All addresses which refer to code or data in this
; source are labels, so moving the origin moves the complete image coherently.
;
; Addresses which remain numeric are intentional fixed BBC Micro hardware, MOS,
; zero-page, workspace, object-pool or screen-memory addresses.
;
; This is an annotated reverse-engineering pass. The eight generic object behaviours have
; been traced semantically and use the original object names supplied by the author.
; Every byte in the reconstructed game image is represented either as an instruction or an EQUB/EQUS/EQUW data directive.

OSWRCH      = &FFEE
OSWORD      = &FFF1
OSBYTE      = &FFF4
OSCLI       = &FFF7
CRTC_ADDR   = &FE00
CRTC_DATA   = &FE01
ULA_PALETTE = &FE21
EVENTV      = &0220

; BBC internal key codes passed to OSBYTE &81 / KeyPressed.
; Names come from the control list stored on this disk.
KEY_ESCAPE        = &8F
KEY_MOVE_DOWN     = &97     ; /
KEY_UNFREEZE      = &96     ; COPY
KEY_SMART_BOMB    = &9D     ; SPACE (also starts a game from attract mode)
KEY_FREEZE        = &A6     ; DELETE
KEY_SOUND_TOGGLE  = &AE     ; S
KEY_FIRE          = &B6     ; RETURN
KEY_MOVE_UP       = &B7     ; *
KEY_MOVE_LEFT     = &BF     ; CAPS LOCK
KEY_MOVE_RIGHT    = &FE     ; CTRL
KEY_INVISO        = &FF     ; SHIFT

; Frequently used zero-page / state fields established from usage:
ScoreLo      = &2C          ; packed BCD score digits 5-6
ScoreMid     = &2D          ; packed BCD score digits 3-4
ScoreHi      = &2E          ; packed BCD score digits 1-2
WaveBCD      = &2F
WorldScrollDeltaLo = &30     ; signed vertical world shift: usually &04, &FC or 0
WorldScrollDeltaHi = &31     ; sign extension: &00 or &FF
TimeSubtick  = &37
TimeBCD      = &38
LivesBCD     = &3D
PlayerDeathTimer = &3E
GameInactive = &3F          ; non-zero while title/attract state is active
EnergyUnitsBCD = &45
PlayerVisibilityMask = &55  ; &FF normally; Inviso-flight sets 0, then re-materialises through 1..&FF
PaletteFlashColour = &56 ; one-frame ULA palette pulse; VSync consumes low 3 bits then restores 7
ScannerGlitchPhase = &57 ; &FF=idle; 0..&FE advances one late-wave scanner interference cycle

SoundFlags   = &58          ; bit 7 = sound enabled; bit 0 = S-key latch

; Frame-driven music/jingle sequencer:
SoundSequencePtrLo       = &40
SoundSequencePtrHi       = &41
SoundSequenceCounter     = &42   ; data steps + 2; zero means no active sequence
SoundSequenceDelay       = &43   ; frames until next 4-byte sequence step

; High-score display/name-entry workspace:
HighScoreRow             = &54   ; displayed rank row 0..7
NameEntryLength          = &54   ; same byte reused by the 16-character name editor
HighScoreScratch         = &65   ; high-score record-index / multiply scratch; overlaps blitter/dispatch scratch
UnusedHighScoreScratch   = &4B   ; written &FF, never read anywhere in the game
ScreenYLo    = &60
ScreenYHi    = &61
ScreenXByte  = &62
ScreenPtrLo  = &63
ScreenPtrHi  = &64

; Context aliases for the generic object behaviour workspace.
; These deliberately overlap: &00/&01/&02/&05 are loaded from ObjectParam0..3
; before a behaviour call, and each object type gives those bytes its own meaning.
ObjectWorkParam0 = &00
ObjectWorkParam1 = &01
ObjectWorkParam2 = &02
ObjectWorkParam3 = &05
ObjectWorkState  = &06     ; cached ObjectState while one generic object is being processed

; Zero-page values which are global rather than generic-object parameters:
EnemyFireChanceThreshold = &03 ; CreateEnemyShot fires only if RandomByte < this; never written by the game
InitialisedUnusedZP07     = &07 ; set to &FF during init, never subsequently read/written by the game
RandomState               = &08 ; one-byte feedback state mixed with both VIA timers by RandomByte
InitialisedUnusedZP09     = &09 ; set to &FF during init, never subsequently read/written by the game

; Type-specific aliases for the remaining behaviour helpers:
SwarmerHorizontalPhase    = &00
SwarmerPositiveXBias      = &01
SwarmerNegativeXBias      = &02
SwarmerYDirection         = &05

BaiterYDirection          = &00 ; 0=add Y, non-zero=subtract Y
BaiterXDirection          = &01 ; 0=add X, non-zero=subtract X
BaiterYRetargetCountdown  = &02
BaiterXRetargetCountdown  = &05

LanderVerticalPhase       = &00 ; +&0C/update; signed triangular-wave vertical speed
LanderHorizontalPhase     = &01 ; bit 7 selects horizontal direction; phase increments randomly
LanderVerticalStep        = &0110 ; one-byte temporary used for upward Y displacement

ObjectYDirectionToPlayer = &0E ; 1 => subtract Y, 0 => add Y
ObjectRightOfPlayer      = &0F ; 1 when object X is to the right of player X+2
PlayerXByte              = &8C

; Player/projectile/collision state:
FireKeyLatch             = &0C
CollisionResultMask      = &0D
BonusLifeMessageTimer    = &32

; Vertical movement model. The player graphic stays at a fixed screen Y; these
; values provide acceleration/inertia and eventually scroll the world by +/-4.
PlayerUpThrust            = &33
PlayerDownThrust          = &34
PlayerVerticalAccumulator = &35
StageCompleteTimer       = &36
StageStartTimer          = &39
ObjectUpdateQuotaMinus1  = &3A
BaiterSpawnDelay         = &3B
PowerBlasterEnabled      = &44
EnergyPackPickupState    = &46
SmartBombPulseCounter    = &47
ExplosionScanIndex       = &4D
EnergyPackYLo            = &50
EnergyPackYHi            = &51
EnergyPackX              = &52
EnergyPackState          = &53
PendingSwarmerCount      = &1E
DestroyedPodYLo           = &1F
DestroyedPodYHi           = &20
DestroyedPodX             = &21
SmartBombKeyLatch        = &25
FrozenRenderStartIndex    = &19 ; snapshot of ObjectRenderScanIndex used by the frozen-display loop
InlineSoundPtrLo          = &27 ; pointer to 8-byte SOUND block embedded after JSR PlayInlineSound
InlineSoundPtrHi          = &28
ActiveObjectCount        = &69
ObjectRenderScanIndex    = &6A
ObjectUpdateIndex        = &8B

; Materialisation/explosion pattern workspace:
TransitionCentreYLo      = &12
TransitionCentreYHi      = &13
TransitionCentreX        = &14
TransitionRadiusX        = &15
TransitionRadiusY        = &16
TransitionPixelMask      = &0D

; &0D is a deliberately shared single-byte scratch location:
ScoreBoundaryScratch     = &0D ; old/new 2000-point boundary bits in AddScoreBCD
BCDColourMask            = &0D ; colour mask consumed by DrawBCDValue
CountdownStep            = &0D ; 3/4 sub-tick decrement selected by wave
PlayerShotCollisionMask  = &0D ; negative when XOR projectile hit occupied pixels
DeathParticlePlotMask    = &0D ; temporary mask for four-point death particle

SharedScratch65          = &65
ObjectBehaviourPtrLo     = &65
ObjectBehaviourPtrHi     = &66

; &10/&11 are reused as several short-lived 16-bit vectors:
CRTCStartAddressLo       = &10
CRTCStartAddressHi       = &11
StageSpawnPtrLo          = &10
StageSpawnPtrHi          = &11

; &65/&66 are also reused as temporary 16-bit arithmetic/pointers:
CRTCDisplayedRows        = &65
ScreenAddressHighWork    = &65
RadarPixelLaneMask       = &65
PlayerCollisionAccumulator = &65
VerticalMotionWorkLo     = &65
VerticalMotionWorkHi     = &66
StageSchedulePtrLo       = &65
StageSchedulePtrHi       = &66
DeathParticleWorkLo      = &65
DeathParticleWorkHi      = &66

; Player projectile pool (9 slots):
PlayerShotActive         = &06AC
PlayerShotX              = &06B5
PlayerShotY              = &06BE

; 32-particle player-death explosion.
; Y is stored inverted: DrawPlayerExplosionParticle uses EOR #&FF before plotting,
; so initial &4B becomes screen Y &B4 (the player's vertical reference position).
DeathParticleXFrac       = &0580
DeathParticleX           = &05A0
DeathParticleXVelocity   = &05C0
DeathParticleYFrac       = &05E0
DeathParticleYInverted   = &0600
DeathParticleYVelocity   = &0620

; Generic XOR bitmap blitter workspace:
BitmapSourceLo            = &17
BitmapSourceHi            = &18
BitmapCurrentX            = &1B
BitmapWidthBytes          = &67
BitmapHeightScanlines     = &68
BitmapRowOffset           = &65
BlitEntryVectorLo         = &10
BlitEntryVectorHi         = &11

; Inline SOUND helper workspace:
; InlineSoundPtrLo/Hi (&27/&28) is reconstructed from the return address so the
; eight bytes following JSR PlayInlineSound can be copied before execution resumes.

; Inline 4x8 font renderer workspace (overlaps generic scratch):
InlineTextPtrLo           = &29
InlineTextPtrHi           = &2A
InlineTextColourMask      = &2B
FontGlyphPtrLo            = &17
FontGlyphPtrHi            = &18

; MODE 2 layout used by the game:
PlayfieldRadarBoundaryX   = &47   ; byte-column 71: scanner begins here
Mode2Columns              = &50   ; 80 byte-columns across the MODE 2 screen

; Starfield: 24 stars arranged as three groups/layers of eight.
StarX                     = &0640
StarY                     = &0658
StarLoopIndex             = &0D

; Enemy projectile pool: six fixed-point ballistic shots.
; Position/velocity are 8.8-style signed fixed-point pairs: fraction then integer.
EnemyShotState            = &0670 ; &FF=free, 0=active
EnemyShotXFrac            = &0676
EnemyShotX                = &067C
EnemyShotYFrac            = &0682
EnemyShotY                = &0688
EnemyShotXVelocityFrac    = &068E
EnemyShotXVelocity        = &0694 ; signed integer byte
EnemyShotYVelocityFrac    = &069A
EnemyShotYVelocity        = &06A0 ; signed integer byte
EnemyShotLifetime         = &06A6

; Donald (type 4) parameter meanings:
DonaldXDirection = &00         ; 0 => +X, 1 => -X
DonaldYDirection = &01         ; 0 => -Y, 1 => +Y

; Banger (type 5) parameter meanings:
BangerXVector = &00            ; bit 7 selects X direction
BangerYVector = &01            ; bit 7 selects Y direction
BangerXPhase  = &02            ; auxiliary X trajectory/error state
BangerYPhase  = &05            ; auxiliary Y trajectory/error state

; Spinner (type 6) parameter meaning:
SpinnerPauseCounter = &00

; Pod (type 3) fixed-point drift. Bit 7 of each vector selects direction; the
; corresponding phase/error byte supplies the fractional carry/borrow.
PodXVector = &00
PodYVector = &01
PodXPhase  = &02
PodYPhase  = &05

; Energy Balloon (type 7) 8.8-ish upward escape rate and hit state.
EnergyBalloonVelocityFrac = &00
EnergyBalloonVelocityInt  = &01
EnergyBalloonHitCount     = &02
EnergyBalloonPhase        = &05

; Donald -> Banger deferred-spawn state:
PendingBangerCount = &22
PendingBangerX     = &23
PendingBangerY     = &24

; General object pool (32 slots; parallel arrays in low RAM):
;
; ObjectWorld* is the authoritative position updated by the behaviour engine.
; ObjectDraw* caches the last position used by the renderer. The render pass
; XOR-erases at ObjectDraw*, copies ObjectWorld* into ObjectDraw*, then XOR-draws
; at the new position. ObjectDrawYHi=&FF means "nothing currently drawn".
ObjectWorldX   = &0400
ObjectWorldYLo = &0420
ObjectWorldYHi = &0440
ObjectDrawYLo  = &0460
ObjectDrawYHi  = &0480
ObjectDrawX    = &04A0
ObjectState    = &04C0       ; &FF=free; >=0 transition/active state
ObjectType     = &04E0       ; 0..7 active; &80..&87 materialising/exploding
ObjectParam0   = &0500
ObjectParam1   = &0520
ObjectParam2   = &0540
ObjectParam3   = &0560


; =============================================================================
; COMPLETE ZERO-PAGE MAP
; =============================================================================
; Only locations actually used as memory by the game are listed. Gaps are unused by
; the game itself. Several bytes deliberately have multiple aliases because the game
; overlays short-lived workspaces rather than reserving separate RAM for each task.
;
; &00 ObjectWorkParam0
;     SwarmerHorizontalPhase / BaiterYDirection / LanderVerticalPhase /
;     DonaldXDirection / BangerXVector / SpinnerPauseCounter / PodXVector /
;     EnergyBalloonVelocityFrac
;
; &01 ObjectWorkParam1
;     SwarmerPositiveXBias / BaiterXDirection / LanderHorizontalPhase /
;     DonaldYDirection / BangerYVector / PodYVector / EnergyBalloonVelocityInt
;
; &02 ObjectWorkParam2
;     SwarmerNegativeXBias / BaiterYRetargetCountdown / BangerXPhase /
;     PodXPhase / EnergyBalloonHitCount
;
; &03 EnemyFireChanceThreshold
;     Read by CreateEnemyShot; never written anywhere in the game.
;
; &05 ObjectWorkParam3
;     SwarmerYDirection / BaiterXRetargetCountdown / BangerYPhase /
;     PodYPhase / EnergyBalloonPhase
;
; &06 ObjectWorkState
;     Cached ObjectState used by behaviour and materialisation/explosion code.
;
; &07 InitialisedUnusedZP07
;     Set to &FF during InitialiseGameHardwareAndState; never read again by the game.
;
; &08 RandomState
;     Feedback byte for RandomByte; initialised &FF and updated on each PRNG call.
;
; &09 InitialisedUnusedZP09
;     Set to &FF during InitialiseGameHardwareAndState; never read again by the game.
;
; &0C FireKeyLatch
;
; &0D SHARED SCRATCH:
;     CollisionResultMask    player/player-shot XOR broad-phase collision result
;     TransitionPixelMask    object materialisation/explosion plot mask
;     StarLoopIndex          24-star update loop index
;
; &0E ObjectYDirectionToPlayer
; &0F ObjectRightOfPlayer
;
; &10/&11 SHARED 16-BIT VECTOR:
;     BlitEntryVectorLo/Hi   computed entry into the unrolled XOR blitter
;     CRTCStartAddressLo/Hi  animated CRTC screen-start address
;     StageSpawnPtrLo/Hi     indirect stage-spawn routine pointer.
;
; &12 TransitionCentreYLo
; &13 TransitionCentreYHi
; &14 TransitionCentreX
; &15 TransitionRadiusX
; &16 TransitionRadiusY
;
; &17/&18 SHARED POINTER:
;     BitmapSourceLo/Hi      generic XOR bitmap source
;     FontGlyphPtrLo/Hi      current 4x8 font glyph source
;
; &19 FrozenRenderStartIndex
;     Snapshot of ObjectRenderScanIndex used to detect a full frozen-display pass.
;
; &1B BitmapCurrentX
;
; &1E PendingSwarmerCount
; &1F DestroyedPodYLo
; &20 DestroyedPodYHi
; &21 DestroyedPodX
;
; &22 PendingBangerCount
; &23 PendingBangerX
; &24 PendingBangerY
; &25 SmartBombKeyLatch
;
; &27 InlineSoundPtrLo
; &28 InlineSoundPtrHi
;     Pointer reconstructed from the caller return address by PlayInlineSound.
;
; &29 InlineTextPtrLo
; &2A InlineTextPtrHi
; &2B InlineTextColourMask
;
; &2C ScoreLo      packed BCD least-significant two score digits
; &2D ScoreMid     packed BCD middle two score digits
; &2E ScoreHi      packed BCD most-significant two score digits
; &2F WaveBCD
;
; &30 WorldScrollDeltaLo
; &31 WorldScrollDeltaHi
; &32 BonusLifeMessageTimer
; &33 PlayerUpThrust
; &34 PlayerDownThrust
; &35 PlayerVerticalAccumulator
; &36 StageCompleteTimer
; &37 TimeSubtick
; &38 TimeBCD
; &39 StageStartTimer
; &3A ObjectUpdateQuotaMinus1
; &3B BaiterSpawnDelay
;
; &3D LivesBCD
; &3E PlayerDeathTimer
; &3F GameInactive
;
; &40 SoundSequencePtrLo
; &41 SoundSequencePtrHi
; &42 SoundSequenceCounter
; &43 SoundSequenceDelay
; &44 PowerBlasterEnabled
; &45 EnergyUnitsBCD
; &46 EnergyPackPickupState
; &47 SmartBombPulseCounter
;
; &4B UnusedHighScoreScratch
;     Written &FF once; never read anywhere in the game.
;
; &4D ExplosionScanIndex
;
; &50 EnergyPackYLo
; &51 EnergyPackYHi
; &52 EnergyPackX
; &53 EnergyPackState
;
; &54 SHARED STATE:
;     HighScoreRow          displayed high-score rank while rendering the table
;     NameEntryLength       number of characters currently entered
;
; &55 PlayerVisibilityMask
; &56 PaletteFlashColour
; &57 ScannerGlitchPhase
; &58 SoundFlags
;
; &60 ScreenYLo
; &61 ScreenYHi
; &62 ScreenXByte
;     Shared world/screen coordinate workspace used by drawing, spawning and
;     object behaviour routines.
;
; &63 ScreenPtrLo
; &64 ScreenPtrHi
;
; &65/&66 HEAVILY SHARED SCRATCH:
;     ObjectBehaviourPtrLo/Hi       indirect behaviour jump vector
;     BitmapRowOffset (&65)         MODE 2 blitter row/scanline offset
;     CRTCDisplayedRows (&65)       reveal/restore vertical-row counter
;     ScreenAddressHighWork (&65)   MODE 2 address calculation intermediate
;     RadarPixelLaneMask (&65)      left/right logical radar pixel mask
;     PlayerCollisionAccumulator (&65) broad XOR collision result
;     VerticalMotionWorkLo/Hi       signed vertical accumulator/scroll temporary
;     StageSchedulePtrLo/Hi         selected 16-byte schedule source pointer
;     DeathParticleWorkLo/Hi        particle fixed-point arithmetic temporary
;     HighScoreScratch (&65)        physical-record / x3 multiply scratch
; &67 BitmapWidthBytes
; &68 BitmapHeightScanlines
; &69 ActiveObjectCount
; &6A ObjectRenderScanIndex
;
; &8B ObjectUpdateIndex
; &8C PlayerXByte
;
; Unused gaps inside the owned range include:
; &04, &0A-&0B, &1A, &1C-&1D, &26, &3C, &48-&4A, &4C, &4E-&4F,
; &59-&5F and &6B-&8A.
; =============================================================================


; =============================================================================
; ARCHITECTURE OVERVIEW
; =============================================================================
; Video's Revenge main game engine. Its assembly origin is supplied by the assembler.
;
; Major subsystems:
;   Game/control     GameEntry, MainLoop, title/start/freeze/escape handling
;   Objects          32-slot world/draw-cache engine-&057F
;   Player           fixed-screen-Y ship, horizontal X, inertial world scrolling
;   Weapons          9 player-shot slots, Smart Bomb, Power Blaster
;   Enemies          Swarmer, Lander, Baiter, Pod, Donald, Banger, Spinner,
;                    Energy Balloon
;   Effects          32-particle player death, materialisation/explosion patterns,
;                    scanner glitch, palette animation, Inviso reappearance
;   Background       24-star / 3-layer parallax starfield
;   Enemy fire       6 ballistic fixed-point projectile slots
;   Display          MODE 2 XOR sprite blitter, right-side radar/scanner
;   UI               packed-BCD score/lives/time/wave/energy
;   Audio            inline OSWORD 7 effects + frame-driven tune sequencer
;   Text             inline 4x8 MODE 2 font renderer
;   High scores      eight fixed physical records + rank-order indirection
;
; Memory summary:
;   &0400-&057F  generic object pool
;   &0580-&063F  player-death particles
;   &0640-&066F  starfield
;   &0670-&06AB  enemy shots
;   &06AC-&06C6  player shots
;   selected origin onward  assembled game code/data
;   &3000-&7FFF  MODE 2 screen
;
; =============================================================================

; -----------------------------------------------------------------------------
; Recovered original object terminology
; -----------------------------------------------------------------------------
; Type 0  Swarmer
; Type 1  Lander
; Type 2  Baiter
; Type 3  Pod
; Type 4  Donald
; Type 5  Banger
; Type 6  Spinner
; Type 7  Energy Balloon
; -----------------------------------------------------------------------------


GameEntry:
    ; Select MODE 2 and initialise the game engine.
    LDA #&16; VDU 22 follows: select graphics mode
    JSR OSWRCH; MOS character/VDU output
    LDA #&02; MODE 2
    JSR OSWRCH; MOS character/VDU output
    LDA #&04
    LDX #&02
    LDY #&00
    JSR OSBYTE; MOS OSBYTE

StartGameSession:
    LDX #&FF
    TXS
    JSR InitialiseGameHardwareAndState
    JSR ResetSingleMovingObject
    JSR InitialiseCRTCDisplay
    JSR ResetGameCounters
    JSR ResetSoundSequencer
    JSR ClearPlayerDeathTimer

MainLoop:
    ; One pass of the main game loop; returns here continuously via JMP MainLoop.
    JSR UpdatePlayerDeath
    JSR UpdateObjectBatch
    JSR UpdateBonusAndStageMessages
    JSR UpdateObjectExplosions
    JSR FrozenGameWaitLoop
    JSR UpdatePlayer
    JSR UpdateSingleMovingObject
    JSR UpdateEnemyShots
    JSR SpawnQueuedBanger
    JSR CreateEnemyShot
    JSR GrantCollectedEnergyPack
    JSR HandleSmartBomb
    JSR BeginStageCompletion
    JSR UpdateCountdownTimer
    JSR HandleStartGameKey
    JSR HandleEscapeQuit
    JSR UpdateSoundSequencer
    JSR UpdateSoundSequencer
    JSR HandleInvisoFlight
    JSR UpdateScannerGlitchEffect
    JSR HandleSoundToggle
    JSR HandleFreezeKeys
    JMP MainLoop

InstallVSyncEventHandler:
    ; EVENTV callback.
    ;
    ; Every VSync:
    ;   * apply PaletteFlashColour to logical colour 0, then restore the pending
    ;     value to 7 for the next frame;
    ;   * increment FrameSyncPending, used as a simple frame semaphore by the
    ;     freeze/title/display-transition code;
    ;   * increment VSyncQuarterDivider.
    ;
    ; Every fourth VSync, animate three ULA palette slots through independent
    ; three-phase cycles and advance a separate 13-step colour cycle. This is
    ; the source of the continuously moving colour effects seen in the game.
    SEI
    LDA #<VSyncEventHandler
    STA EVENTV
    LDA #>VSyncEventHandler
    STA EVENTV+1
    CLI
    LDA #&0E
    LDX #&04
    LDY #&00
    JMP OSBYTE; MOS OSBYTE

VSyncEventHandler:
    ; EVENTV callback. Updates ULA palette (&FE21) and frame counters; must be short and re-entrant.
    LDA PaletteFlashColour
    AND #&07
    STA ULA_PALETTE; write ULA logical->physical colour mapping
    LDA #&07
    STA PaletteFlashColour
    INC FrameSyncPending
    INC VSyncQuarterDivider
    LDA VSyncQuarterDivider
    AND #&03
    BEQ AdvanceAnimatedPalette
    RTS

AdvanceAnimatedPalette:
    LDX #&02

AdvanceNextPaletteSlot:
    INC PaletteSlotPhases,X
    LDA PaletteSlotPhases,X
    CMP #&03
    BNE StorePaletteSlotPhase
    LDA #&00

StorePaletteSlotPhase:
    STA PaletteSlotPhases,X
    TAY
    LDA PaletteThreePhaseColours,Y
    EOR #&07
    AND #&07
    ORA PaletteRegisterTable,X
    STA ULA_PALETTE; write ULA logical->physical colour mapping
    DEX
    BPL AdvanceNextPaletteSlot
    INC PaletteCycleIndex
    LDA PaletteCycleIndex
    CMP #&0D
    BNE StoreMainPaletteCycleIndex
    LDA #&00

StoreMainPaletteCycleIndex:
    STA PaletteCycleIndex
    TAX
    LDA PaletteMainCycleColours,X
    EOR #&07
    ORA #&E0
    STA ULA_PALETTE; write ULA logical->physical colour mapping
    RTS

; --- DATA: palette lookup/counters ---
PaletteRegisterTable:
    ; ULA palette register selectors used by the VSync handler.
    EQUB &10,&20,&30,&60
FrameSyncPending:
    EQUB &00
VSyncQuarterDivider:
    EQUB &00
PaletteCycleIndex:
    EQUB &00
PaletteSlotPhases:
    EQUB &00,&01,&02
PaletteThreePhaseColours:
    EQUB &01,&04,&03
PaletteMainCycleColours:
    EQUB &07,&07,&03,&06,&02,&05,&01,&04,&01,&05,&02,&06,&03
LogicalPaletteTable:
    EQUB &00,&0F,&0F,&0F,&01,&02,&04,&07
    EQUB &01,&03,&02,&05,&06,&07,&0F,&00

AddScoreBCD:
    ; Add packed-BCD A to the six-digit score and redraw it.
    ;
    ; The compact extra-life test compares the top three bits of ScoreMid before
    ; and after the addition. ScoreMid contains the hundreds/thousands BCD pair;
    ; those top three bits change whenever the thousands digit crosses an even
    ; boundary (0->2, 2->4, 4->6, 6->8, 8->0 with carry).
    ;
    ; Result: an extra ship AND one Energy Unit are awarded every 2,000 points.
    ; BonusLifeMessageTimer is set to &FF and the extra-life jingle is started.
    TAY
    LDA ScoreMid
    PHA
    TYA
    PHA
    JSR DrawScore
    SED
    PLA
    CLC
    ADC ScoreLo
    STA ScoreLo
    LDA ScoreMid
    ADC #&00
    STA ScoreMid
    PHA
    LDA ScoreHi
    ADC #&00
    STA ScoreHi
    CLD
    JSR DrawScore
    PLA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA ScoreBoundaryScratch
    PLA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    EOR ScoreBoundaryScratch
    BNE GrantTwoThousandPointBonus
    RTS

GrantTwoThousandPointBonus:
    LDA #&FF
    STA BonusLifeMessageTimer
    JSR DrawLives
    CLC
    SED
    LDA LivesBCD
    ADC #&01
    STA LivesBCD
    CLD
    JSR DrawLives
    JSR DrawEnergyUnits
    INC EnergyUnitsBCD
    JSR DrawEnergyUnits
    JMP StartExtraLifeJingle

DrawScore:
    ; Expand ScoreHi:ScoreMid:ScoreLo from three packed-BCD bytes into six ASCII
    ; digits, highest byte first, and XOR-redraw the six-character HUD field.
    LDX #&00
    LDY #&02

ConvertNextScoreBCDByte:
    LDA ScoreLo,Y
    LSR A
    LSR A
    LSR A
    LSR A
    CLC
    ADC #&30
    STA ScoreDigitsBuffer,X
    INX
    LDA ScoreLo,Y
    AND #&0F
    CLC
    ADC #&30
    STA ScoreDigitsBuffer,X
    DEY
    INX
    CPX #&06
    BNE ConvertNextScoreBCDByte
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &09,&01,&C3
ScoreDigitsBuffer:
    EQUS "123456"
    EQUB &00
    RTS

IncrementWaveBCD:
    JSR DrawWave
    SED
    LDA WaveBCD
    CLC
    ADC #&01
    STA WaveBCD
    CLD
    JMP DrawWave
    RTS

DrawWave:
    LDA #&C3
    STA BCDColourMask
    LDA WaveBCD
    LDX #&16
    LDY #&01
    JMP DrawBCDValue

DrawTime:
    LDA #&CF
    STA BCDColourMask
    LDA TimeBCD
    LDX #&20
    LDY #&1E
    JMP DrawBCDValue

DrawEnergyUnits:
    LDA #&CF
    STA BCDColourMask
    LDA EnergyUnitsBCD
    LDX #&18
    LDY #&1E
    JMP DrawBCDValue

UpdateCountdownTimer:
    ; Run the BCD TIME clock while at least one generic object remains.
    ;
    ; TimeSubtick is a finer-grained BCD accumulator. It is reduced by 4 on
    ; waves <15 and by 3 from wave 15 onward; when it borrows, TimeBCD decreases
    ; by one and the HUD is XOR-erased/redrawn.
    ;
    ; Two special cases hang off the displayed TIME:
    ;   TIME = 80: if the player has neither Power Blaster nor an active death
    ;              state, spawn the Energy Balloon at a random position.
    ;   TIME = 00: TimeSubtick becomes a free-running binary-ish delay; each
    ;              underflow counts down BaiterSpawnDelay until another Baiter
    ;              is introduced.
    LDA ActiveObjectCount
    BNE CountdownWhileObjectsRemain
    RTS

CountdownWhileObjectsRemain:
    LDX #&04
    LDA WaveBCD
    CMP #&15
    BCC SubtractCountdownSubtick
    LDX #&03

SubtractCountdownSubtick:
    STX CountdownStep
    LDA TimeBCD
    BEQ HandleTimeAtZero
    SED
    SEC
    LDA TimeSubtick
    SBC CountdownStep
    STA TimeSubtick
    LDA TimeBCD
    PHA
    SBC #&00
    STA TimeBCD
    PLA
    CLD
    CMP TimeBCD
    BNE RedrawChangedTime
    RTS

RedrawChangedTime:
    TAX
    LDA TimeBCD
    PHA
    TXA
    STA TimeBCD
    JSR DrawTime
    PLA
    CMP #&99
    BNE DrawNewTimeValue
    LDA #&00

DrawNewTimeValue:
    STA TimeBCD
    JSR DrawTime
    LDA PowerBlasterEnabled
    ORA PlayerDeathTimer
    BEQ CheckEnergyBalloonTriggerTime
    RTS

CheckEnergyBalloonTriggerTime:
    LDA TimeBCD
    CMP #&80; Energy Balloon appears when displayed TIME reaches 80
    BEQ SpawnEnergyBalloonAtRandomPosition
    RTS

SpawnEnergyBalloonAtRandomPosition:
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    STA ScreenYLo
    LDA #&00
    STA ScreenYHi
    LDA #&00
    STA ObjectWorkParam0
    STA ObjectWorkParam1
    STA ObjectWorkParam2
    STA ObjectWorkParam3
    LDA #&87
    JMP SpawnObject

HandleTimeAtZero:
    SEC
    LDA TimeSubtick
    SBC #&BE
    STA TimeSubtick
    BCC TickBaiterSpawnDelay
    RTS

TickBaiterSpawnDelay:
    DEC BaiterSpawnDelay
    BEQ SpawnTimeoutBaiter
    RTS

SpawnTimeoutBaiter:
    JMP SpawnBaiter

BeginStageCompletion:
    ; A stage is complete only when there are no active objects, no pending
    ; Bangers/Swarmers, no other stage activity, and the player is alive.
    ; StageCompleteTimer=&FF starts the completion/bonus presentation.
    LDA ActiveObjectCount
    ORA StageCompleteTimer
    ORA StageStartTimer
    ORA PendingBangerCount
    ORA PendingSwarmerCount
    ORA PlayerDeathTimer
    ORA GameInactive
    BEQ StartStageCompletion
    RTS

StartStageCompletion:
    LDA #&FF
    STA StageCompleteTimer
    LDX #&05
    LDA #&01

ClampEnemyShotLifetimeForStageEnd:
    LDY EnemyShotLifetime,X
    BEQ NextEnemyShotAtStageEnd
    STA EnemyShotLifetime,X

NextEnemyShotAtStageEnd:
    DEX
    BPL ClampEnemyShotLifetimeForStageEnd
    RTS

InitialiseGameHardwareAndState:
    ; Establish the game's MOS, CRTC, ULA, screen and gameplay state.
    ;
    ; The routine flushes MOS buffers, disables page-mode scrolling, clears the
    ; screen, installs the VSync event handler, programs all 16 logical palette
    ; mappings, installs the VDU-defined colours, clears object/projectile pools,
    ; creates the starfield and draws the static HUD/title text.
    ;
    ; Gameplay counters are initially zeroed here; ResetGameCounters later turns
    ; these into the starting 3 lives / 3 Energy Units when a game begins.
    LDA #&00
    STA FrameSyncPending
    LDA #&0F
    LDX #&00
    LDY #&00
    JSR OSBYTE; MOS OSBYTE
    LDA #&0B
    LDX #&00
    LDY #&00
    JSR OSBYTE; MOS OSBYTE
    LDA #&FF
    STA GameInactive
    STA PlayerVisibilityMask
    STA SoundFlags
    STA ScannerGlitchPhase
    LDA #&00
    STA SmartBombPulseCounter
    LDA #&0C
    JSR OSWRCH; MOS character/VDU output
    JSR ResetPlayer
    JSR ResetPlayer
    LDA #&01
    STA CRTC_ADDR
    LDA #&00
    STA CRTC_DATA
    LDA #&0B
    STA CRTC_ADDR
    LDA #&00
    STA CRTC_DATA
    LDA #&08
    STA CRTC_ADDR
    LDA #&00
    STA CRTC_DATA
    JSR InstallVSyncEventHandler
    LDX #&0F

InitialiseNextLogicalPaletteEntry:
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    ORA LogicalPaletteTable,X
    EOR #&07
    STA ULA_PALETTE; write ULA logical->physical colour mapping
    DEX
    BPL InitialiseNextLogicalPaletteEntry
    JSR SendDisplaySetupVDU
    JSR ResetObjectPool
    LDA #&00
    STA ActiveObjectCount
    JSR InitialiseStarfield
    LDA #&FF
    STA InitialisedUnusedZP07
    STA RandomState
    STA InitialisedUnusedZP09
    STA GameInactive
    JSR ResetEnemyShotPool
    JSR DrawInlineText

; --- DATA: HUD inline text ---
    EQUB &03,&01,&C3
    EQUS "SCORE       0 WAVE 0  LIVES"
    EQUB &00
    LDA #&00
    STA WorldScrollDeltaLo
    STA WorldScrollDeltaHi
    STA BonusLifeMessageTimer
    STA WaveBCD
    STA SmartBombKeyLatch
    JSR DrawInlineText

; --- DATA: HUD inline text ---
    EQUB &01,&1E,&CF
    EQUS "SOUND ON  ENERGY UNITS 0  TIME 99"
    EQUB &00
    LDA #&00
    STA TimeSubtick
    LDA #&99
    STA TimeBCD
    STA StageCompleteTimer
    LDA #&03
    STA ObjectUpdateQuotaMinus1
    LDA #&00
    STA LivesBCD
    STA ScoreLo
    STA ScoreMid
    STA ScoreHi
    JSR DrawLives
    LDA #&00
    STA EnergyUnitsBCD
    JSR DrawScore
    JSR DrawTitleScreenText
    RTS

DrawLives:
    LDA #&C3
    STA BCDColourMask
    LDA LivesBCD
    LDY #&01
    LDX #&1F
    JMP DrawBCDValue

ClearPlayerDeathTimer:
    LDA #&00
    STA PlayerDeathTimer
    RTS

ResetGameCounters:
    JSR DrawLives
    LDA #&03
    STA LivesBCD
    JSR DrawLives
    JSR DrawEnergyUnits
    LDA #&03
    STA EnergyUnitsBCD
    JSR DrawEnergyUnits
    LDA #&03
    STA ObjectUpdateQuotaMinus1
    JSR DrawScore
    LDA #&00
    STA ScoreLo
    STA ScoreMid
    STA ScoreHi
    JSR DrawScore
    LDA #&00
    STA StageCompleteTimer
    STA StageStartTimer
    STA ActiveObjectCount
    JSR DrawWave
    LDA #&00
    STA WaveBCD
    JSR DrawWave
    RTS

UpdateObjectBatch:
    ; Run ObjectUpdateQuotaMinus1+1 behaviour updates per main-loop pass.
    ; The quota begins at four objects/frame and rises on later odd-numbered
    ; waves, capped by the stage-start code. Object rendering is a separate
    ; rotating pass, so behaviour workload and screen-update workload need not
    ; advance in lockstep.
    LDA StageCompleteTimer
    BEQ RunObjectUpdateQuota
    RTS

RunObjectUpdateQuota:
    LDX ObjectUpdateQuotaMinus1

UpdateNextObjectInQuota:
    TXA
    PHA
    JSR UpdateOneObject
    PLA
    TAX
    DEX
    BPL UpdateNextObjectInQuota
    LDX ObjectRenderScanIndex
    STX FrozenRenderStartIndex
    RTS

HandleFreezeKeys:
    ; Implements the DELETE/COPY freeze-unfreeze control described by the game instructions.
    LDA #KEY_FREEZE
    JSR KeyPressed
    BCS PollUnfreezeKey
    RTS

PollUnfreezeKey:
    LDA #KEY_UNFREEZE
    JSR KeyPressed
    BCC ServiceFrozenFrame
    RTS

ServiceFrozenFrame:
    JSR FrozenGameWaitLoop
    JMP PollUnfreezeKey

FrozenGameWaitLoop:
    ; Keep the display alive while gameplay is frozen.
    ;
    ; Object behaviour, shots and timers stop, but the routine continues XOR
    ; rendering objects and the starfield. FrameSyncPending, incremented by the
    ; VSync event handler, acts as a one-byte frame semaphore so the frozen
    ; display still advances at video-frame cadence.
    LDA ObjectRenderScanIndex
    STA FrozenRenderStartIndex
    JSR UpdateNextObject
    JSR UpdateNextObject
    LDA FrameSyncPending
    BEQ UpdateFrozenStarfield
    LDA #&00
    STA FrameSyncPending
    RTS

UpdateFrozenStarfield:
    JSR UpdateStarfield

UpdateFrozenObjectUntilFrameBoundary:
    JSR UpdateNextObject
    LDA FrozenRenderStartIndex
    CMP ObjectRenderScanIndex
    BEQ WaitForFrozenVSync
    LDA FrameSyncPending
    BEQ UpdateFrozenObjectUntilFrameBoundary

WaitForFrozenVSync:
    LDA FrameSyncPending
    BEQ WaitForFrozenVSync
    LDA #&00
    STA FrameSyncPending
    RTS

HandleStartGameKey:
    ; Attract mode.
    ;
    ; While GameInactive is non-zero, force one starfield step per call and use
    ; SPACE as the start key. Starting a game resets counters, removes the title
    ; text, starts the opening music, latches SPACE so it cannot immediately act
    ; as a Smart Bomb, and resets the player.
    LDA GameInactive
    BNE AnimateAttractModeAndCheckStart
    RTS

AnimateAttractModeAndCheckStart:
    JSR ScrollStarfieldOneStep
    LDA #KEY_SMART_BOMB
    JSR KeyPressed
    BCS BeginNewGameFromTitle
    RTS

BeginNewGameFromTitle:
    JSR ResetGameCounters
    LDA #&00
    STA GameInactive
    LDA #&00
    STA StageCompleteTimer
    LDA #&65
    STA StageStartTimer
    JSR DrawTitleScreenText
    JSR StartGameMusic
    LDA #&FF
    STA SmartBombKeyLatch
    JSR ResetPlayer
    RTS

HandleEscapeQuit:
    ; Escape handling; restores display state and restarts at the session initialisation path.
    LDA GameInactive
    BEQ CheckEscapeKey
    RTS

CheckEscapeKey:
    LDA #KEY_ESCAPE
    JSR KeyPressed
    BCS RestartSessionAfterEscape
    RTS

RestartSessionAfterEscape:
    JSR RestoreCRTCDisplay
    JMP StartGameSession

InitialiseCRTCDisplay:
    ; Animated display reveal used when entering the playfield.
    ;
    ; CRTC start-address registers 12/13 are stepped backwards by &50 bytes per
    ; frame while register 6 (vertical displayed rows) increases from 0 to &20.
    ; ScrollStarfieldOneStep is called between frames so the reveal is animated
    ; rather than a static CRTC switch.
    LDA #&00
    STA CRTCDisplayedRows
    LDA #&50
    STA CRTCStartAddressLo
    LDA #&10
    STA CRTCStartAddressHi

AdvanceCRTCRevealAddress:
    SEC
    LDA CRTCStartAddressLo
    SBC #&50
    STA CRTCStartAddressLo
    BCS ProgramNextCRTCRevealFrame
    DEC CRTCStartAddressHi

ProgramNextCRTCRevealFrame:
    JSR ProgramCRTCForFrame
    LDA CRTCDisplayedRows
    PHA
    JSR ScrollStarfieldOneStep
    PLA
    CLC
    ADC #&01
    STA CRTCDisplayedRows
    CMP #&21
    BNE AdvanceCRTCRevealAddress
    RTS

ProgramCRTCForFrame:
    LDA #&13
    JSR OSBYTE; MOS OSBYTE
    LDA #&06
    STA CRTC_ADDR
    LDA CRTCDisplayedRows
    STA CRTC_DATA
    LDY #&0C
    LDX #&0D
    LDA CRTCStartAddressLo
    STX CRTC_ADDR
    STA CRTC_DATA
    LDA CRTCStartAddressHi
    STY CRTC_ADDR
    STA CRTC_DATA
    LDA CRTCDisplayedRows
    BNE EnableFullCRTCDisplayWidth
    RTS

EnableFullCRTCDisplayWidth:
    LDA #&01
    STA CRTC_ADDR
    LDA #&50
    STA CRTC_DATA
    RTS

HandleInvisoFlight:
    ; SHIFT activates Inviso-flight only while alive/in-game, with at least one
    ; Energy Unit, and only when the previous Inviso cycle has fully rematerialised
    ; (PlayerVisibilityMask=&FF).
    ;
    ; The player is XOR-erased, visibility is set to zero, the now-masked player
    ; is redrawn, and one Energy Unit is consumed. UpdateInvisoRematerialisation
    ; then grows the mask back to &FF over subsequent frames.
    LDA PlayerDeathTimer
    ORA GameInactive
    BEQ RequireEnergyForInviso
    RTS

RequireEnergyForInviso:
    LDA EnergyUnitsBCD
    BNE CheckInvisoKey
    RTS

CheckInvisoKey:
    LDA #KEY_INVISO
    JSR KeyPressed
    BCS RequireFullyVisiblePlayer
    RTS

RequireFullyVisiblePlayer:
    LDA PlayerVisibilityMask
    CMP #&FF
    BEQ ActivateInvisoFlight
    RTS

ActivateInvisoFlight:
    JSR DrawPlayer
    LDA #&00
    STA PlayerVisibilityMask
    JSR DrawPlayer
    JSR DrawEnergyUnits
    DEC EnergyUnitsBCD
    JSR DrawEnergyUnits
    RTS

RestoreCRTCDisplay:
    ; Reverse the CRTC reveal when leaving the playfield.
    ;
    ; Register 6 counts down from &20 while the screen start address advances by
    ; &50 bytes per frame. The starfield continues to move during the transition.
    ; Register 1 is finally set to zero, hiding the playfield display.
    LDA #&20
    STA SharedScratch65
    LDA #&00
    STA CRTCStartAddressLo
    LDA #&06
    STA CRTCStartAddressHi

ProgramNextCRTCRestoreFrame:
    JSR ProgramCRTCForFrame
    LDA SharedScratch65
    PHA
    JSR ScrollStarfieldOneStep
    PLA
    SEC
    SBC #&01
    STA SharedScratch65
    PHA
    CLC
    LDA CRTCStartAddressLo
    ADC #&50
    STA CRTCStartAddressLo
    BCC ContinueCRTCRestoreAddress
    INC CRTCStartAddressHi

ContinueCRTCRestoreAddress:
    PLA
    BPL ProgramNextCRTCRestoreFrame
    LDA #&01
    STA CRTC_ADDR
    LDA #&00
    STA CRTC_DATA
    RTS

UpdateScannerGlitchEffect:
    ; Late-wave scanner interference effect.
    ;
    ; ScannerGlitchPhase=&FF means idle. A triggered cycle runs 0..&FE. Only
    ; phases 0..31 and &DF..&FE actually alter screen RAM; the long middle
    ; section simply advances the phase, creating an opening/closing burst.
    ;
    ; The affected block starts at MODE 2 byte-column &48, inside the scanner
    ; area. Sixty-four bytes are XORed with low-nibble noise partly derived from
    ; bytes in sideways-ROM address space &C000+X.
    ;
    ; A new burst is considered only while playing, with live objects, from
    ; wave 9 onward. Three random gates make it deliberately rare, and the
    ; ObjectUpdateQuotaMinus1 gate makes it somewhat more likely as difficulty
    ; increases.
    LDA ScannerGlitchPhase
    CMP #&FF
    BEQ MaybeStartScannerGlitch
    LDA ScannerGlitchPhase
    CMP #&20
    BCC RenderScannerGlitchBand
    CMP #&DF
    BCS RenderScannerGlitchBand
    INC ScannerGlitchPhase
    RTS

RenderScannerGlitchBand:
    LDA ScannerGlitchPhase
    BPL ConvertGlitchPhaseToScreenY
    CLC
    ADC #&01

ConvertGlitchPhaseToScreenY:
    AND #&1F
    ASL A
    ASL A
    ASL A
    STA ScreenYLo
    LDA #&48
    STA ScreenXByte
    JSR Mode2ScreenAddressFromXY
    LDY #&3F

XorNextScannerGlitchByte:
    TYA
    CLC
    ADC ScreenPtrLo
    ADC ScreenPtrHi
    TAX
    SBC &C000,X
    AND #&0F
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    DEY
    BPL XorNextScannerGlitchByte
    INC ScannerGlitchPhase
    RTS

MaybeStartScannerGlitch:
    LDA GameInactive
    ORA PlayerDeathTimer
    BEQ RequireObjectsForScannerGlitch
    RTS

RequireObjectsForScannerGlitch:
    LDA ActiveObjectCount
    BNE RequireLateWaveForScannerGlitch
    RTS

RequireLateWaveForScannerGlitch:
    LDA WaveBCD
    CMP #&09; scanner interference only from wave 9
    BCS PassScannerGlitchCoinFlip
    RTS

PassScannerGlitchCoinFlip:
    JSR RandomByte
    AND #&01
    BEQ PassScannerGlitchDifficultyGate
    RTS

PassScannerGlitchDifficultyGate:
    JSR RandomByte
    AND #&0F
    CMP ObjectUpdateQuotaMinus1
    BCC RollFinalScannerGlitchTrigger
    RTS

RollFinalScannerGlitchTrigger:
    JSR RandomByte
    CMP #&FF; final 1/256 trigger gate
    BEQ StartScannerGlitch
    RTS

StartScannerGlitch:
    LDA #&00
    STA ScannerGlitchPhase
    RTS
    RTS

ResetObjectPool:
    ; Mark all 32 generic object slots free. ObjectDrawYHi=&FF is also used as
    ; the renderer's "no old sprite currently on screen" sentinel.
    LDA #&00
    STA PendingSwarmerCount
    STA PendingBangerCount
    LDX #&1F

ClearNextObjectSlot:
    LDA #&FF
    STA ObjectState,X
    STA ObjectType,X
    STA ObjectDrawYHi,X
    DEX
    BPL ClearNextObjectSlot
    LDA #&00
    STA ActiveObjectCount
    STA ObjectRenderScanIndex
    STA ObjectUpdateIndex
    RTS
    LDA ObjectWorkState
    AND #&3F
    LSR A
    STA TransitionRadiusY
    LSR A
    STA TransitionRadiusX

SpawnObject:
    ; Allocate one of 32 parallel-array object records.
    ;
    ; Entry:
    ;   A = type. 0..7 creates an immediately active object; &80..&87 creates
    ;       the same type in materialisation state.
    ;   ScreenXByte/ScreenYLo/ScreenYHi = initial world position
    ;   ObjectWorkParam0..3 = type-specific initial parameters
    ;
    ; State &3F is the initial contracting materialisation radius. Both the
    ; authoritative ObjectWorld* and cached ObjectDraw* positions start equal.
    ;
    ; Immediately-active visible objects are drawn and installed on radar.
    ; Materialising visible objects instead draw the transition pattern and play
    ; the two spawn sounds; their real sprite/radar blip appears only when the
    ; transition contracts to zero.
    PHA
    LDX #&1F

FindFreeObjectSlot:
    LDA ObjectState,X
    BMI InitialiseAllocatedObjectSlot
    DEX
    BPL FindFreeObjectSlot
    PLA
    RTS

InitialiseAllocatedObjectSlot:
    LDA ScreenXByte
    STA ObjectWorldX,X
    STA ObjectDrawX,X
    LDA ScreenYLo
    STA ObjectWorldYLo,X
    STA ObjectDrawYLo,X
    LDA ScreenYHi
    STA ObjectWorldYHi,X
    STA ObjectDrawYHi,X
    LDA #&3F
    STA ObjectState,X
    STA ObjectWorkState
    LDA ObjectWorkParam0
    STA ObjectParam0,X
    LDA ObjectWorkParam1
    STA ObjectParam1,X
    LDA ObjectWorkParam2
    STA ObjectParam2,X
    LDA ObjectWorkParam3
    STA ObjectParam3,X
    INC ActiveObjectCount
    PLA
    STA ObjectType,X
    PHA
    LDA ScreenYHi
    BNE FinishSpawnVisibilityHandling
    LDA ObjectType,X
    BMI BeginSpawnMaterialisation
    JSR DrawXorSprite

FinishSpawnVisibilityHandling:
    PLA
    BPL DrawSpawnedObjectRadarBlip
    RTS

DrawSpawnedObjectRadarBlip:
    JMP DrawRadarBlip

BeginSpawnMaterialisation:
    LDA ObjectType,X
    JSR DrawObjectCollisionPattern
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F1,&FF,&07,&00,&12,&00
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &11,&00,&04,&00,&64,&00,&12,&00
    PLA
    RTS
    RTS

UpdateNextObject:
    ; Rendering pass for one rotating object slot.
    ;
    ; Erase the object's radar blip at ObjectDraw*. If a sprite was drawn on the
    ; visible page, XOR-erase it there too. Then copy ObjectWorld* to ObjectDraw*
    ; and redraw the sprite if the new position is on visible Y page zero.
    ; Finally redraw its radar blip at the cached new position.
    ;
    ; This is why the object pool carries two complete coordinate sets.
    INC ObjectRenderScanIndex
    LDX ObjectRenderScanIndex
    CPX #&20
    BCC StoreWrappedRenderScanIndex
    LDX #&00

StoreWrappedRenderScanIndex:
    STX ObjectRenderScanIndex
    PHA
    LDA ObjectType,X
    BPL RenderCurrentObjectSlot
    PLA
    RTS

RenderCurrentObjectSlot:
    PLA
    JSR DrawObjectRadarBlip
    JSR PrepareObjectForUpdate
    JMP DrawObjectRadarBlip

PrepareObjectForUpdate:
    ; Update the render-position cache for ObjectRenderScanIndex.
    ;
    ; ObjectDrawYHi==0 means an old sprite is currently visible and must first be
    ; erased. ObjectDrawYHi=&FF means there was no visible old sprite. After the
    ; erase step, copy authoritative ObjectWorld* into ObjectDraw* and draw the
    ; new sprite only when ObjectWorldYHi==0.
    LDX ObjectRenderScanIndex
    LDA ObjectState,X
    BPL EraseOldObjectSpriteIfVisible
    RTS

EraseOldObjectSpriteIfVisible:
    LDA ObjectDrawYHi,X
    BNE CacheCurrentObjectWorldPosition
    STA ScreenYHi
    LDA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectDrawX,X
    STA ScreenXByte
    LDA ObjectType,X
    JSR DrawXorSprite
    LDX ObjectRenderScanIndex

CacheCurrentObjectWorldPosition:
    LDA #&FF
    STA ObjectDrawYHi,X
    LDA ObjectWorldYHi,X
    AND #&07
    STA ObjectWorldYHi,X
    PHA
    LDA ObjectWorldX,X
    STA ObjectDrawX,X
    STA ScreenXByte
    LDA ObjectWorldYLo,X
    STA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectWorldYHi,X
    STA ObjectDrawYHi,X
    STA ScreenYHi
    PLA
    CMP #&00
    BEQ DrawObjectAtNewVisiblePosition
    RTS

DrawObjectAtNewVisiblePosition:
    TXA
    PHA
    LDA ObjectType,X
    JSR DrawXorSprite
    PLA
    TAX
    RTS

DrawObjectRadarBlip:
    LDX ObjectRenderScanIndex
    LDA ObjectDrawX,X
    STA ScreenXByte
    LDA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectDrawYHi,X
    STA ScreenYHi
    LDA ObjectType,X
    JMP DrawRadarBlip

UpdateOneObject:
    ; Behaviour pass for one rotating object slot.
    ;
    ; Load authoritative ObjectWorld* plus ObjectParam0..3 into the shared
    ; zero-page workspace, dispatch types 0..7, then write the modified values
    ; back. Rendering is deliberately separate: UpdateNextObject later erases
    ; the cached old position and draws this new world position.
    LDX ObjectUpdateIndex
    LDA ObjectState,X
    BPL LoadObjectBehaviourWorkspace
    JMP AdvanceObjectUpdateIndex

LoadObjectBehaviourWorkspace:
    LDA ObjectWorldX,X
    STA ScreenXByte
    LDA ObjectWorldYLo,X
    STA ScreenYLo
    LDA ObjectWorldYHi,X
    STA ScreenYHi
    LDA ObjectParam0,X
    STA ObjectWorkParam0
    LDA ObjectParam1,X
    STA ObjectWorkParam1
    LDA ObjectParam2,X
    STA ObjectWorkParam2
    LDA ObjectParam3,X
    STA ObjectWorkParam3
    LDA ObjectState,X
    STA ObjectWorkState
    JSR DispatchObjectBehaviour
    JMP StoreUpdatedObjectState

DispatchObjectBehaviour:
    ; Types 0..7 dispatch through ObjectBehaviourTable. Negative type values denote special/transitional states.
    LDA ObjectType,X
    BPL ValidateObjectTypeForDispatch
    RTS

ValidateObjectTypeForDispatch:
    CMP #&08
    BCC DispatchKnownObjectType
    RTS

DispatchKnownObjectType:
    ASL A
    TAY
    LDA ObjectBehaviourTable,Y
    STA ObjectBehaviourPtrLo
    INY
    LDA ObjectBehaviourTable,Y
    STA ObjectBehaviourPtrHi
    JMP (ObjectBehaviourPtrLo)

; --- DATA: object behaviour jump table ---
ObjectBehaviourTable:
    ; Eight little-endian behaviour routine addresses, one per generic object type.
    ; Original object names recovered from the author:
    ;   0=Swarmer, 1=Lander, 2=Baiter, 3=Pod,
    ;   4=Donald, 5=Banger, 6=Spinner, 7=Energy Balloon.
    EQUW UpdateSwarmer
    EQUW UpdateLander
    EQUW UpdateBaiter
    EQUW UpdatePod
    EQUW UpdateDonald
    EQUW UpdateBanger
    EQUW UpdateSpinner
    EQUW UpdateEnergyBalloon
    RTS

StoreUpdatedObjectState:
    ; Commit the zero-page behaviour workspace back to the authoritative object
    ; record. X coordinates >=&47 are wrapped to zero so ordinary objects remain
    ; left of the scanner; Y page is wrapped modulo 8.
    LDX ObjectUpdateIndex
    LDA ScreenXByte
    CMP #&47
    BCC StoreWrappedObjectWorldX
    LDA #&00

StoreWrappedObjectWorldX:
    STA ObjectWorldX,X
    LDA ScreenYLo
    STA ObjectWorldYLo,X
    LDA ScreenYHi
    AND #&07
    STA ObjectWorldYHi,X
    LDA ObjectWorkParam0
    STA ObjectParam0,X
    LDA ObjectWorkParam1
    STA ObjectParam1,X
    LDA ObjectWorkParam2
    STA ObjectParam2,X
    LDA ObjectWorkParam3
    STA ObjectParam3,X
    LDA ObjectWorkState
    STA ObjectState,X

AdvanceObjectUpdateIndex:
    LDX ObjectUpdateIndex
    INX
    CPX #&20
    BNE StoreWrappedObjectUpdateIndex
    LDX #&00

StoreWrappedObjectUpdateIndex:
    STX ObjectUpdateIndex
    RTS

RandomByte:
    ; Pseudo-random byte made by mixing System VIA and User VIA timer counters
    ; with RandomState. RandomState is the only persistent PRNG feedback byte
    ; used by the game; the neighbouring &07/&09 bytes are merely initialised &FF.
    EOR &FE44
    SBC &FE64
    PHA
    SBC RandomState
    PLA
    STA RandomState
    SBC &FE65
    ADC &FE45
    PHA
    ORA #&80
    STA &FE64
    EOR #&FF
    STA &FE65
    PLA
    RTS
    RTS

DrawObjectCollisionPattern:
    ; XOR the eight-point materialisation/explosion pattern around ScreenX/Y.
    ;
    ; ObjectState low six bits provide TransitionRadiusX; TransitionRadiusY is
    ; twice that value. Four axial points and four diagonal points are plotted.
    ; Before wave 20 the object's radar mask is thinned with &55; from wave 20
    ; onward the fuller logical-colour pattern is used.
    ;
    ; From wave 8 onward XorCollisionPoint duplicates each point one scanline
    ; lower, making the transition effect vertically thicker.
    LDY ScreenYHi
    BEQ RequireActiveTransitionPattern
    RTS

RequireActiveTransitionPattern:
    BIT ObjectWorkState
    BPL ChooseTransitionPixelMask
    RTS

ChooseTransitionPixelMask:
    AND #&7F
    TAX
    LDA RadarBlipMasks,X
    AND #&7F
    TAX
    LDA WaveBCD
    CMP #&14; wave 20+: use fuller transition pixel mask
    BCS StoreTransitionPixelMask
    TXA
    AND #&55
    TAX

StoreTransitionPixelMask:
    STX TransitionPixelMask
    LDA ScreenXByte
    PHA
    STA TransitionCentreX
    LDA ScreenYLo
    PHA
    STA TransitionCentreYLo
    LDA ScreenYHi
    PHA
    STA TransitionCentreYHi
    LDA ObjectWorkState
    AND #&3F
    STA TransitionRadiusX
    ASL A
    STA TransitionRadiusY
    CLC
    LDA TransitionCentreX
    ADC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    STA ScreenYLo
    LDA TransitionCentreYHi
    STA ScreenYHi
    JSR XorCollisionPoint
    SEC
    LDA TransitionCentreX
    SBC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    STA ScreenYLo
    LDA TransitionCentreYHi
    STA ScreenYHi
    JSR XorCollisionPoint
    LDA TransitionCentreX
    STA ScreenXByte
    CLC
    LDA TransitionCentreYLo
    ADC TransitionRadiusY
    STA ScreenYLo
    LDA ScreenYHi
    ADC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    LDA TransitionCentreX
    STA ScreenXByte
    SEC
    LDA TransitionCentreYLo
    SBC TransitionRadiusY
    STA ScreenYLo
    LDA ScreenYHi
    SBC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    CLC
    LDA TransitionCentreX
    ADC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    CLC
    ADC TransitionRadiusY
    STA ScreenYLo
    LDA TransitionCentreYHi
    ADC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    CLC
    LDA TransitionCentreX
    ADC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    SEC
    SBC TransitionRadiusY
    STA ScreenYLo
    LDA TransitionCentreYHi
    SBC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    SEC
    LDA TransitionCentreX
    SBC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    CLC
    ADC TransitionRadiusY
    STA ScreenYLo
    LDA TransitionCentreYHi
    ADC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    SEC
    LDA TransitionCentreX
    SBC TransitionRadiusX
    STA ScreenXByte
    LDA TransitionCentreYLo
    SEC
    SBC TransitionRadiusY
    STA ScreenYLo
    LDA TransitionCentreYHi
    SBC #&00
    STA ScreenYHi
    JSR XorCollisionPoint
    PLA
    STA ScreenYHi
    PLA
    STA ScreenYLo
    PLA
    STA ScreenXByte
    RTS

XorCollisionPoint:
    LDA ScreenYHi
    BEQ CheckTransitionPointXBounds
    RTS

CheckTransitionPointXBounds:
    LDA ScreenXByte
    CMP #&46
    BCC XorTransitionPointOnScreen
    RTS

XorTransitionPointOnScreen:
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA TransitionPixelMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    LDA WaveBCD
    CMP #&08; wave 8+: make each transition point two scanlines high
    BCS XorSecondTransitionPointScanline
    RTS

XorSecondTransitionPointScanline:
    INC ScreenYLo
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA TransitionPixelMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    RTS

UpdateObjectExplosionState:
    ; Animate one materialising or exploding object.
    ;
    ; First XOR-erase the previous transition pattern at ObjectDraw*. Copy the
    ; current ObjectWorld* position into ObjectDraw*, then modify the radius:
    ;
    ;   ObjectState bit 6 clear  -> materialising: radius -= 4
    ;   ObjectState bit 6 set    -> exploding:     radius += 4
    ;
    ; Explosion reaching radius &40 becomes &FF (slot free). Materialisation
    ; crossing below zero becomes active state 0: clear ObjectType bit 7, draw
    ; the real sprite if visible, and install the radar blip.
    TXA
    PHA
    LDA ObjectState,X
    STA ObjectWorkState
    LDA ObjectDrawX,X
    STA ScreenXByte
    LDA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectDrawYHi,X
    STA ScreenYHi
    LDA ObjectType,X
    JSR DrawObjectCollisionPattern
    PLA
    PHA
    TAX
    LDA ObjectWorldX,X
    STA ScreenXByte
    STA ObjectDrawX,X
    LDA ObjectWorldYLo,X
    STA ScreenYLo
    STA ObjectDrawYLo,X
    LDA ObjectWorldYHi,X
    STA ScreenYHi
    STA ObjectDrawYHi,X
    LDA ObjectWorkState
    AND #&40
    PHP
    LDA ObjectWorkState
    PLP
    BEQ ContractMaterialisationRadius
    AND #&3F
    CLC
    ADC #&04
    CMP #&40
    BCC StoreExpandingExplosionRadius
    LDA #&FF

StoreExpandingExplosionRadius:
    ORA #&40
    JMP StoreObjectTransitionState

ContractMaterialisationRadius:
    SEC
    SBC #&04
    BMI FinishObjectMaterialisation

StoreObjectTransitionState:
    STA ObjectWorkState
    LDA ObjectType,X
    JSR DrawObjectCollisionPattern
    PLA
    TAX
    LDA ObjectWorkState
    STA ObjectState,X
    RTS

FinishObjectMaterialisation:
    PLA
    TAX
    LDA #&00
    STA ObjectState,X
    LDA ObjectType,X
    AND #&7F
    PHA
    STA ObjectType,X
    LDY ScreenYHi
    BNE InstallMaterialisedRadarBlip
    JSR DrawXorSprite

InstallMaterialisedRadarBlip:
    PLA
    TAY
    LDA ScreenXByte
    PHA
    LDA ScreenYLo
    PHA
    LDA ScreenYHi
    PHA
    TYA
    JSR DrawRadarBlip
    PLA
    STA ScreenYHi
    PLA
    STA ScreenYLo
    PLA
    STA ScreenXByte
    RTS

GrantCollectedEnergyPack:
    ; Convert a pending Energy Pack pickup into the permanent Power Blaster.
    ;
    ; Pickup state 1 is consumed only when alive/in-game and not already powered.
    ; The player is erased, X is clamped to 5..&3D so the wider side-gun graphics
    ; fit on-screen, PowerBlasterEnabled is set, then the player is redrawn.
    LDA PlayerDeathTimer
    ORA GameInactive
    ORA PowerBlasterEnabled
    BEQ CheckPendingEnergyPackPickup
    RTS

CheckPendingEnergyPackPickup:
    LDA EnergyPackPickupState
    CMP #&01
    BEQ EnablePowerBlasterFromEnergyPack
    RTS

EnablePowerBlasterFromEnergyPack:
    INC EnergyPackPickupState
    JSR DrawPlayer
    LDA PlayerXByte
    CMP #&05
    BCS ClampPowerBlasterPlayerXRight
    LDA #&05

ClampPowerBlasterPlayerXRight:
    CMP #&3E
    BCC StorePowerBlasterPlayerX
    LDA #&3D

StorePowerBlasterPlayerX:
    STA PlayerXByte
    LDA #&FF
    STA PowerBlasterEnabled
    JSR DrawPlayer
    RTS

HandleSmartBomb:
    ; SPACE activates one Smart Bomb if:
    ;   * no Smart Bomb pulse is already running,
    ;   * the key was released since the previous activation,
    ;   * the player is alive/in-game,
    ;   * at least one Energy Unit remains.
    ;
    ; The bomb lasts seven pulse counts. Each frame randomises the ULA palette
    ; flash and destroys every active object currently on the visible Y page.
    ; One Energy Unit is consumed only on the first pulse (counter becomes 6).
    ; SmartBombKeyLatch prevents holding SPACE from immediately firing another.
    LDA SmartBombPulseCounter
    BNE UpdateSmartBombPulse
    LDA #KEY_SMART_BOMB
    JSR KeyPressed
    BCS SmartBombKeyIsDown
    LDA #&00
    STA SmartBombKeyLatch
    RTS

SmartBombKeyIsDown:
    LDA SmartBombKeyLatch
    ORA PlayerDeathTimer
    ORA GameInactive
    BEQ RequireSmartBombEnergy
    RTS

RequireSmartBombEnergy:
    LDA EnergyUnitsBCD
    BNE BeginSmartBombPulse
    RTS

BeginSmartBombPulse:
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F1,&FF,&06,&00,&02,&00

UpdateSmartBombPulse:
    JSR RandomByte
    AND #&07
    STA PaletteFlashColour
    LDA SmartBombPulseCounter
    BNE StoreSmartBombPulseCounter
    LDA #&07

StoreSmartBombPulseCounter:
    STA SmartBombPulseCounter
    DEC SmartBombPulseCounter
    LDX #&1F

ScanNextSmartBombObject:
    LDA ObjectDrawYHi,X
    BNE AdvanceSmartBombObjectScan
    LDA ObjectState,X
    ORA ObjectType,X
    BMI AdvanceSmartBombObjectScan
    TXA
    PHA
    LDA #&00
    JSR DestroyObjectAndAwardScore
    PLA
    TAX

AdvanceSmartBombObjectScan:
    DEX
    BPL ScanNextSmartBombObject
    LDA #&FF
    STA SmartBombKeyLatch
    LDA SmartBombPulseCounter
    CMP #&06
    BEQ ConsumeSmartBombEnergy
    RTS

ConsumeSmartBombEnergy:
    JSR DrawEnergyUnits
    DEC EnergyUnitsBCD
    JSR DrawEnergyUnits
    RTS

UpdateObjectExplosions:
    ; Service SEVEN transition slots per main-loop pass, using a rotating scan
    ; across all 32 object records. (The loop starts X=7 and stops when DEX
    ; reaches zero, so there are seven calls, not eight.)
    ;
    ; Only records with ObjectState>=0 and ObjectType bit 7 set enter the
    ; materialisation/explosion state machine.
    LDX #&07

ServiceAnotherTransitionSlot:
    TXA
    PHA
    JSR UpdateNextObjectExplosion
    PLA
    TAX
    DEX
    BNE ServiceAnotherTransitionSlot
    RTS

UpdateNextObjectExplosion:
    ; Advance the rotating explosion/materialisation scan by one object slot.
    LDX ExplosionScanIndex
    INX
    CPX #&20
    BCC StoreWrappedTransitionScanIndex
    LDX #&00

StoreWrappedTransitionScanIndex:
    STX ExplosionScanIndex
    LDA ObjectState,X
    BPL RequireTransitionalObjectType
    RTS

RequireTransitionalObjectType:
    LDA ObjectType,X
    BMI AnimateCurrentObjectTransition
    RTS

AnimateCurrentObjectTransition:
    JMP UpdateObjectExplosionState

ResetSingleMovingObject:
    LDA #&FF
    STA EnergyPackState
    RTS

DrawSingleMovingObject:
    ; Draw/erase the collectible Energy Pack using the generic raw XOR blitter.
    ; The Pack is a 3-byte-column x 6-scanline bitmap at SingleMovingObjectSprite
    ; and is only rendered while EnergyPackYHi==0.
    LDA #&03
    STA BitmapWidthBytes
    LDA #&06
    STA BitmapHeightScanlines
    LDA #&20
    STA BitmapSourceLo
    LDA #&14
    STA BitmapSourceHi
    LDA EnergyPackX
    STA ScreenXByte
    LDA EnergyPackYLo
    STA ScreenYLo
    LDA EnergyPackYHi
    STA ScreenYHi
    BEQ XorVisibleEnergyPack
    RTS

XorVisibleEnergyPack:
    JMP DrawRawXorBitmap
    RTS

UpdateSingleMovingObject:
    ; Update the collectible Energy Pack.
    ;
    ; EnergyPackState=&FF means absent. Otherwise erase its previous bitmap,
    ; apply this frame's world-scroll delta, then move it upward by three Y units.
    ; If it leaves visible Y page zero, state is forced to &FE; incrementing state
    ; then turns it into &FF (absent) at the end of that update.
    ;
    ; While Y is &AC..&BF, test horizontal overlap against the player. A live
    ; player overlap increments EnergyPackPickupState and similarly retires the
    ; Pack. GrantCollectedEnergyPack consumes that pending pickup later in the
    ; main loop.
    LDA EnergyPackState
    CMP #&FF
    BNE EraseOldEnergyPackIfDrawn
    RTS

EraseOldEnergyPackIfDrawn:
    CMP #&00
    BEQ ApplyScrollToEnergyPack
    JSR DrawSingleMovingObject

ApplyScrollToEnergyPack:
    LDA EnergyPackYLo
    CLC
    ADC WorldScrollDeltaLo
    STA EnergyPackYLo
    LDA EnergyPackYHi
    ADC WorldScrollDeltaHi
    STA EnergyPackYHi
    CMP #&00
    BEQ MoveEnergyPackUpThree
    LDA #&FE
    STA EnergyPackState

MoveEnergyPackUpThree:
    SEC
    LDA EnergyPackYLo
    SBC #&03
    STA EnergyPackYLo
    BCS MarkEnergyPackIfOffVisiblePage
    DEC EnergyPackYHi

MarkEnergyPackIfOffVisiblePage:
    LDA EnergyPackYHi
    BEQ TestEnergyPackPlayerOverlap
    LDA #&FE
    STA EnergyPackState

TestEnergyPackPlayerOverlap:
    LDA EnergyPackYLo
    CMP #&AC
    BCC AdvanceEnergyPackState
    CMP #&C0
    BCS AdvanceEnergyPackState
    LDA EnergyPackX
    CLC
    ADC #&03
    CMP PlayerXByte
    BCC AdvanceEnergyPackState
    LDA PlayerXByte
    CLC
    ADC #&05
    CMP EnergyPackX
    BCC AdvanceEnergyPackState
    LDA PlayerDeathTimer
    BNE AdvanceEnergyPackState
    LDA #&FE
    STA EnergyPackState
    INC EnergyPackPickupState

AdvanceEnergyPackState:
    INC EnergyPackState
    LDA EnergyPackState
    CMP #&FF
    BNE DrawUpdatedEnergyPack
    RTS

DrawUpdatedEnergyPack:
    JMP DrawSingleMovingObject
    RTS

; --- DATA: sprite + MODE 2 screen address lookup tables ---
SingleMovingObjectSprite:
    ; 18-byte (3 x 6) bitmap drawn by DrawSingleMovingObject.
    EQUB &00
    EQUS "2002"
    EQUB &00,&20,&30,&12,&12,&30,&20,&00
    EQUS "\"  \""
    EQUB &00,&60
Mode2RowHighTable:
    ; High-byte lookup used by Mode2ScreenAddressFromXY; 32 rows.
    EQUB &00,&02,&05,&07,&0A,&0C,&0F,&11
    EQUB &14,&16,&19,&1B,&1E
    EQUS " #%(*-/2479<>ACFHKM"
Mode2RowLowTable:
    ; Low-byte lookup (00/80 alternation) for 640-byte MODE 2 character rows.
    EQUB &00,&80

Mode2ScreenAddressFromXY:
    ; Convert game coordinates ScreenYLo/ScreenXByte into the BBC MODE 2
    ; framebuffer address in ScreenPtrLo/Hi.
    ;
    ; MODE 2 stores eight vertical scanlines consecutively for each byte-column,
    ; and each 8-scanline character row occupies &280 (640) bytes. The two tiny
    ; lookup tables avoid a general multiply by 640.
    LDA ScreenYLo
    LSR A
    LSR A
    LSR A
    TAX
    LDA Mode2RowHighTable,X
    STA ScreenPtrHi
    CLC
    TXA
    AND #&01
    TAX
    LDA ScreenYLo
    AND #&07
    ADC Mode2RowLowTable,X
    STA ScreenPtrLo
    LDA #&0C
    STA ScreenAddressHighWork
    LDA ScreenXByte
    ASL A
    ASL A
    ROL ScreenAddressHighWork
    ASL A
    ROL ScreenAddressHighWork
    ADC ScreenPtrLo
    STA ScreenPtrLo
    LDA ScreenAddressHighWork
    ADC ScreenPtrHi
    STA ScreenPtrHi
    RTS

DrawXorSprite:
    ; Table-driven entry to the generic XOR bitmap blitter.
    ; A = object type 0..7. Resolve width, height and bitmap address, then fall
    ; through to DrawRawXorBitmap. Sprite data is stored column-major.
    AND #&FF
    BPL LoadSpriteDescriptor
    RTS

LoadSpriteDescriptor:
    TAX
    LDA SpriteHeights,X
    STA BitmapHeightScanlines
    LDA SpriteWidths,X
    STA BitmapWidthBytes
    TXA
    ASL A
    TAX
    LDA SpritePointers,X
    STA BitmapSourceLo
    LDA SpritePointers+1,X
    STA BitmapSourceHi

DrawRawXorBitmap:
    ; Lower-level blitter used both by DrawXorSprite and by the Energy Pack.
    ; Entry workspace:
    ;   BitmapSourceLo/Hi        -> column-major bitmap
    ;   BitmapWidthBytes         = horizontal byte-columns
    ;   BitmapHeightScanlines    = vertical pixel rows
    ;   ScreenXByte/ScreenYLo    = destination
    ;
    ; MODE 2's awkward memory layout is handled without per-pixel address
    ; calculation. The Y mod 8 value is converted into an address *inside* the
    ; unrolled eight-scanline XOR sequence..[relocatable]. This jumps directly
    ; to the correct first scanline, then advances the screen by &280 whenever
    ; an 8-line character-cell boundary is crossed.
    JSR Mode2ScreenAddressFromXY
    LDA ScreenXByte
    STA BitmapCurrentX
    LDA ScreenPtrLo
    PHA
    AND #&F8
    STA ScreenPtrLo
    PLA
    AND #&07
    STA BitmapRowOffset
    ASL A
    ASL A
    ASL A
    CLC
    ADC BitmapRowOffset
    ADC BitmapRowOffset
    CLC
    ADC #<BlitScanline0
    STA BlitEntryVectorLo
    LDA #>BlitScanline0
    ADC #&00
    STA BlitEntryVectorHi

DrawRawXorBitmapColumn:
    ; Draw one bitmap byte-column. BitmapHeightScanlines counts source bytes.
    ; When the column is complete, advance screen address by 8 bytes to the next
    ; MODE 2 byte-column and advance the source by one complete column.
    LDX BitmapHeightScanlines
    LDY BitmapRowOffset
    SEC
    LDA BitmapSourceLo
    SBC BitmapRowOffset
    STA BitmapSourceLo
    LDA BitmapSourceHi
    SBC #&00
    STA BitmapSourceHi
    LDA ScreenPtrHi
    PHA
    LDA ScreenPtrLo
    PHA
    JMP (BlitEntryVectorLo)

BlitScanline0:
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    LDA (BitmapSourceLo),Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INY
    DEX
    BEQ FinishBitmapColumn
    CLC
    TYA
    ADC BitmapSourceLo
    STA BitmapSourceLo
    LDA BitmapSourceHi
    ADC #&00
    STA BitmapSourceHi
    LDY #&00
    CLC
    LDA ScreenPtrLo
    ADC #&80
    STA ScreenPtrLo
    LDA ScreenPtrHi
    ADC #&02
    STA ScreenPtrHi
    BNE BlitScanline0

FinishBitmapColumn:
    INC BitmapCurrentX
    LDA BitmapCurrentX
    CMP #&47; clip before radar/scanner byte-columns
    BNE AdvanceToNextBitmapColumn
    PLA
    PLA
    RTS

AdvanceToNextBitmapColumn:
    CLC
    TYA
    ADC BitmapSourceLo
    STA BitmapSourceLo
    LDA BitmapSourceHi
    ADC #&00
    STA BitmapSourceHi
    PLA
    CLC
    ADC #&08
    STA ScreenPtrLo
    PLA
    ADC #&00
    STA ScreenPtrHi
    DEC BitmapWidthBytes
    BEQ FinishRawBitmap
    JMP DrawRawXorBitmapColumn

FinishRawBitmap:
    RTS

SendDisplaySetupVDU:
    ; Writes the 102-byte VDU control stream at DisplaySetupVDU to OSWRCH.
    LDY #&00

SendNextDisplaySetupByte:
    LDA DisplaySetupVDU,Y
    JSR OSWRCH; MOS character/VDU output
    INY
    CPY #&66
    BNE SendNextDisplaySetupByte
    RTS

; --- DATA: VDU setup command stream ---
DisplaySetupVDU:
    ; 102 bytes sent verbatim through OSWRCH during display setup.
    EQUB &12,&00,&05,&19,&04,&7F,&04,&00
    EQUB &00,&19,&05,&7F,&04,&FF,&03,&19
    EQUB &05,&FF,&04,&FF,&03,&19,&05,&FF
    EQUB &04,&00,&00,&19,&05,&7F,&04,&00
    EQUB &00,&19,&05,&00,&00,&00,&00,&19
    EQUB &05,&00,&00,&FF,&03,&19,&05,&00
    EQUB &05,&FF,&03,&12,&00,&07,&19,&04
    EQUB &FF,&04,&80,&01,&19,&05,&FF,&04
    EQUB &00,&02,&19,&04,&7F,&04,&80,&01
    EQUB &19,&05,&7F,&04,&00,&02,&19,&45
    EQUB &87,&04,&80,&01,&19,&45,&F7,&04
    EQUB &80,&01,&19,&45,&87,&04,&00,&02
    EQUB &19,&45,&F7,&04,&00,&02

DrawRadarBlip:
    ; Draw/erase one object on the right-hand scanner.
    ; A=&FF selects the player marker; otherwise A is object type 0..7 and
    ; RadarBlipMasks supplies its logical-colour mask. XOR means the same call
    ; both draws and erases a blip.
    CMP #&FF
    BNE LoadObjectRadarMask
    LDA #&FC
    JMP PlotScaledRadarMask

LoadObjectRadarMask:
    AND #&7F
    TAY
    LDA RadarBlipMasks,Y

PlotScaledRadarMask:
    ; Scale world coordinates into the scanner:
    ;   world Y (16-bit ScreenYHi:ScreenYLo) / 8
    ;   world X approximately rounded / 8
    ;
    ; Radar X is offset by &47, so object X 0..70 maps into byte-columns
    ; &47..&4F: exactly the rightmost nine byte-columns of an 80-column MODE 2
    ; bitmap. The carry retained during X scaling selects the left/right MODE 2
    ; logical pixel lane (&55 versus &AA).
    ;
    ; Two vertically adjacent XOR pixels are plotted, producing a taller and
    ; more visible scanner mark. Y is biased by &80 and clamped away from the
    ; extreme top/bottom addresses.
    PHA
    LSR ScreenYHi
    ROR ScreenYLo
    LSR ScreenYHi
    ROR ScreenYLo
    LSR ScreenYHi
    ROR ScreenYLo
    LDA ScreenXByte
    LSR A
    LSR A
    LSR A
    PHP
    BPL StoreScaledRadarX
    LDA #&00

StoreScaledRadarX:
    STA ScreenXByte
    LDA ScreenXByte
    ASL A
    PLP
    ADC #&01
    LSR A
    PHP
    STA ScreenXByte
    CLC
    LDA ScreenXByte
    ADC #&47
    CMP #&50
    BCC StoreClampedRadarX
    LDA #&4F
    PLP
    SEC
    PHP

StoreClampedRadarX:
    STA ScreenXByte
    LDA ScreenYLo
    CLC
    ADC #&80
    STA ScreenYLo
    LDA ScreenYLo
    CMP #&02
    BCS ClampRadarYHighEnd
    LDA #&02

ClampRadarYHighEnd:
    CMP #&FF
    BNE StoreClampedRadarY
    LDA #&FE

StoreClampedRadarY:
    STA ScreenYLo
    JSR Mode2ScreenAddressFromXY
    PLP
    LDA #&55
    BCS SelectRadarPixelLane
    LDA #&AA

SelectRadarPixelLane:
    STA RadarPixelLaneMask
    PLA
    AND RadarPixelLaneMask
    PHA
    LDY #&00
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    DEC ScreenYLo
    JSR Mode2ScreenAddressFromXY
    PLA
    LDY #&00
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    RTS

ResetPlayer:
    LDA #&21
    STA PlayerXByte
    LDA #&00
    STA PowerBlasterEnabled
    STA SmartBombPulseCounter
    JSR DrawPlayer
    LDA #&00
    LDX #&08

ClearNextPlayerShotSlot:
    STA PlayerShotActive,X
    DEX
    BPL ClearNextPlayerShotSlot
    STA PlayerUpThrust
    STA PlayerDownThrust
    STA EnergyPackPickupState
    RTS

DrawPlayer:
    ; XOR the player craft at its fixed vertical screen position.
    ;
    ; PlayerXByte controls horizontal byte-column position. The two 48-byte
    ; halves are drawn separately because the player spans two MODE 2 character
    ; rows. Any resulting byte with bit 7 set is remembered as a broad collision
    ; indication for CheckPlayerCollisionFromXor.
    ;
    ; With PowerBlasterEnabled, PlayerEffectGraphic is XORed on both sides of
    ; the ship. PlayerVisibilityMask is ANDed into every bitmap byte, giving
    ; Inviso-flight/re-materialisation its disappearing stipple effect.
    LDA GameInactive
    BEQ DrawActivePlayer
    RTS

DrawActivePlayer:
    JSR DrawPlayerRadarBlip
    LDA #&00
    STA ScreenPtrHi
    LDA PlayerXByte
    ASL A
    ASL A
    ROL ScreenPtrHi
    ASL A
    ROL ScreenPtrHi
    CLC
    ADC #&00
    STA ScreenPtrLo
    LDA ScreenPtrHi
    ADC #&67
    STA ScreenPtrHi
    LDY #&2F
    LDX #&00

XorPlayerTopByte:
    LDA PlayerSpriteTop,Y
    AND PlayerVisibilityMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    BPL NextPlayerTopByte
    TAX

NextPlayerTopByte:
    DEY
    BPL XorPlayerTopByte
    TXA
    STA PlayerCollisionAccumulator
    CLC
    LDA ScreenPtrLo
    ADC #&80
    STA ScreenPtrLo
    PHA
    LDA ScreenPtrHi
    ADC #&02
    STA ScreenPtrHi
    PHA
    LDY #&2F
    LDX #&00

XorPlayerBottomByte:
    LDA PlayerSpriteBottom,Y
    AND PlayerVisibilityMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    BPL NextPlayerBottomByte
    TAX

NextPlayerBottomByte:
    DEY
    BPL XorPlayerBottomByte
    TXA
    BPL CheckPowerBlasterGraphics
    STA PlayerCollisionAccumulator

CheckPowerBlasterGraphics:
    LDA PowerBlasterEnabled
    BNE DrawPowerBlasterGraphics
    PLA
    PLA
    JMP CheckPlayerCollisionFromXor

DrawPowerBlasterGraphics:
    LDY #&4F
    LDX #&1F

XorRightPowerBlasterGraphic:
    LDA PlayerEffectGraphic,X
    AND PlayerVisibilityMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    DEY
    DEX
    BPL XorRightPowerBlasterGraphic
    PLA
    TAX
    PLA
    SEC
    SBC #&20
    STA ScreenPtrLo
    TXA
    SBC #&00
    STA ScreenPtrHi
    LDY #&1F

XorLeftPowerBlasterGraphic:
    LDA PlayerEffectGraphic,Y
    AND PlayerVisibilityMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    DEY
    BPL XorLeftPowerBlasterGraphic

CheckPlayerCollisionFromXor:
    ; The player renderer uses XOR drawing as a broad collision detector.
    ; If either half leaves a result byte with bit 7 set, &65 is negative.
    ; A collision only kills the player while fully visible (not Inviso-flight)
    ; and when a death sequence is not already running.
    LDA PlayerCollisionAccumulator
    BMI RequirePlayerFullyVisibleForCollision
    RTS

RequirePlayerFullyVisibleForCollision:
    LDA PlayerVisibilityMask
    CMP #&FF
    BEQ RequireNoExistingPlayerDeath
    RTS

RequireNoExistingPlayerDeath:
    LDA PlayerDeathTimer
    BEQ StartPlayerDeathSequence
    RTS

StartPlayerDeathSequence:
    LDA #&FF
    STA PlayerDeathTimer
    RTS

; --- DATA: player bitmap data ---
PlayerSpriteTop:
    ; First 48-byte half of the player craft.
    EQUB &00,&00,&00,&00,&15,&15,&15,&00
    EQUB &00,&00,&00,&00,&00,&15,&15,&3B
    EQUB &15,&15,&15,&0F,&2F,&2F,&27,&00
    EQUB &00,&00,&00,&0A,&2A,&3F,&37,&11
    EQUB &00,&00,&00,&00,&15,&15,&15,&2A
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
PlayerSpriteBottom:
    ; Second 48-byte half of the player craft.
    EQUB &3F,&3B,&3B,&15,&11
    EQUS ";;**7;'"
    EQUB &0B,&0B,&05,&2A,&05,&2F,&05,&0F
    EQUB &1B,&0A,&00,&33,&00,&3F,&11,&0F
    EQUB &0B,&0B,&05
    EQUS "\"?3;7"
    EQUB &1B,&1B,&11
    EQUS "****"
    EQUB &00,&00,&2A,&2A,&2A
PlayerEffectGraphic:
    ; 32-byte player-related effect drawn twice around the craft when &44 is active.
    EQUB &00,&00,&15,&00,&15,&3F,&7E,&7E
    EQUB &15,&15,&15,&3F,&7E,&A8,&41,&C3
    EQUB &00,&00,&15,&2A,&3F,&BD,&54,&D6
    EQUB &00,&00,&00,&00,&00,&2A,&2A,&2A

UpdatePlayer:
    JSR UpdatePlayerControlsAndWeapons
    JMP UpdatePlayerShots

UpdatePlayerControlsAndWeapons:
    LDA #&00
    STA WorldScrollDeltaLo
    STA WorldScrollDeltaHi
    LDA PlayerDeathTimer
    BEQ UpdateLivePlayer
    RTS

UpdateLivePlayer:
    JSR DrawPlayer
    JSR UpdateInvisoRematerialisation
    JSR UpdatePlayerHorizontalControl
    JSR DrawPlayer
    JSR UpdatePlayerVerticalMotion
    JSR HandleFireButton
    LDA PendingSwarmerCount
    BNE SpawnPendingSwarmerForPlayerLoop
    RTS

SpawnPendingSwarmerForPlayerLoop:
    JSR SpawnQueuedSwarmer
    RTS

UpdatePlayerHorizontalControl:
    ; Handle CAPS LOCK / CTRL movement of the player's on-screen X position.
    ; The basic allowed range is 1..&42 byte-columns. With Power Blaster active,
    ; clamp it further to 5..&3D so the two side graphics/guns remain on-screen.
    LDA PlayerDeathTimer
    ORA GameInactive
    BEQ ReadHorizontalMovementKeys
    RTS

ReadHorizontalMovementKeys:
    JSR ReadLeftRightKeys
    LDA PowerBlasterEnabled
    BNE ClampPoweredPlayerLeftEdge
    RTS

ClampPoweredPlayerLeftEdge:
    LDA PlayerXByte
    CMP #&05
    BCS ClampPoweredPlayerRightEdge
    LDA #&05

ClampPoweredPlayerRightEdge:
    CMP #&3E
    BCC StoreClampedPlayerX
    LDA #&3D

StoreClampedPlayerX:
    STA PlayerXByte
    RTS

ReadLeftRightKeys:
    ; CAPS LOCK moves PlayerXByte one byte-column left; CTRL moves it one
    ; byte-column right. The two tests are independent, so if both are pressed
    ; they cancel except at a boundary.
    LDA #KEY_MOVE_LEFT
    JSR KeyPressed
    BCC CheckMoveRightKey
    LDA PlayerXByte
    CMP #&01
    BNE MovePlayerLeftOneColumn
    RTS

MovePlayerLeftOneColumn:
    DEC PlayerXByte

CheckMoveRightKey:
    LDA #KEY_MOVE_RIGHT
    JSR KeyPressed
    BCS MovePlayerRightOneColumn
    RTS

MovePlayerRightOneColumn:
    LDA PlayerXByte
    CMP #&42
    BEQ FinishHorizontalMovementInput
    INC PlayerXByte

FinishHorizontalMovementInput:
    RTS

KeyPressed:
    ; Wrapper around OSBYTE &81 (INKEY-style direct key test). Entry A is the BBC internal key code.
    TAX
    LDA #&81
    LDY #&FF
    JMP OSBYTE; MOS OSBYTE

DrawPlayerRadarBlip:
    LDA PlayerXByte
    STA ScreenXByte
    LDA #&D8
    STA ScreenYLo
    LDA #&00
    STA ScreenYHi
    LDA #&FF
    JMP DrawRadarBlip

HandleFireButton:
    ; RETURN fires only on the transition from released -> pressed and is
    ; ignored during the stage-complete presentation.
    ;
    ; Normal fire attempts one central projectile. Power Blaster then moves the
    ; temporary PlayerXByte five columns left/right and attempts two additional
    ; projectiles, restoring PlayerXByte afterwards. This reuses CreatePlayerShot
    ; without a separate side-shot placement routine.
    LDA PlayerDeathTimer
    ORA GameInactive
    BEQ CheckFireKey
    RTS

CheckFireKey:
    LDA #KEY_FIRE
    JSR KeyPressed
    BCS FireKeyIsDown
    LDA #&00
    STA FireKeyLatch
    RTS

FireKeyIsDown:
    LDA FireKeyLatch
    ORA StageCompleteTimer
    BEQ FireNewVolley
    RTS

FireNewVolley:
    LDA #&FF
    STA FireKeyLatch
    JSR CreatePlayerShot
    BCC CheckForPowerBlasterSideShots
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &11,&00,&03,&00,&C8,&00,&26,&00
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F1,&FF,&07,&00,&26,&00

CheckForPowerBlasterSideShots:
    LDA PowerBlasterEnabled
    BNE FirePowerBlasterSideShots
    RTS

FirePowerBlasterSideShots:
    LDA PlayerXByte
    PHA
    SEC
    SBC #&05
    STA PlayerXByte
    JSR CreatePlayerShot
    PLA
    PHA
    CLC
    ADC #&05
    STA PlayerXByte
    JSR CreatePlayerShot
    PLA
    STA PlayerXByte
    RTS

CreatePlayerShot:
    ; Allocate a projectile slot.
    ;
    ; Normal weapon: search 4 slots (3..0).
    ; Power Blaster: search all 9 slots (8..0).
    ;
    ; New shots start two byte-columns to the right of PlayerXByte at fixed
    ; screen Y=&B0. C is returned set on success, clear if the pool is full.
    LDX #&03
    LDA PowerBlasterEnabled
    BEQ FindFreePlayerShotSlot
    LDX #&08

FindFreePlayerShotSlot:
    LDA PlayerShotActive,X
    BPL InitialisePlayerShot
    DEX
    BPL FindFreePlayerShotSlot
    CLC
    RTS

InitialisePlayerShot:
    LDA #&FF
    STA PlayerShotActive,X
    CLC
    LDA PlayerXByte
    ADC #&02
    STA PlayerShotX,X
    LDA #&B0
    STA PlayerShotY,X
    JSR XorPlayerShot
    SEC
    RTS

UpdatePlayerShots:
    ; Erase/move/redraw the active player projectile pool.
    ; XorPlayerShot leaves CollisionResultMask negative when the newly drawn
    ; projectile overlaps occupied screen pixels; only then do we scan the
    ; 32-object pool for a precise sprite-width/height hit.
    ; Erase/move/redraw the active player projectile pool and check impacts.
    LDX #&08

UpdateNextPlayerShot:
    LDA PlayerShotActive,X
    BPL AdvancePlayerShotUpdate
    JSR XorPlayerShot
    SEC
    LDA PlayerShotY,X
    SBC #&08
    STA PlayerShotY,X
    BCS RedrawMovedPlayerShot
    LDA #&00
    STA PlayerShotActive,X
    JMP AdvancePlayerShotUpdate

RedrawMovedPlayerShot:
    JSR XorPlayerShot
    LDA PlayerShotCollisionMask
    BPL AdvancePlayerShotUpdate
    TXA
    PHA
    JSR CheckPlayerShotObjectCollision
    PLA
    TAX

AdvancePlayerShotUpdate:
    DEX
    BPL UpdateNextPlayerShot
    RTS

XorPlayerShot:
    TXA
    PHA
    LDA PlayerShotX,X
    STA ScreenXByte
    LDA PlayerShotY,X
    STA ScreenYLo
    JSR Mode2ScreenAddressFromXY
    LDX #&00
    LDY #&0F

XorNextPlayerShotByte:
    LDA PlayerShotGraphic,Y
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    BPL AdvancePlayerShotBitmapByte
    TAX

AdvancePlayerShotBitmapByte:
    DEY
    BPL XorNextPlayerShotByte
    STX PlayerShotCollisionMask
    PLA
    TAX
    RTS

; --- DATA: player shot bitmap ---
PlayerShotGraphic:
    ; 16-byte projectile bitmap for player shots.
    EQUS "EEEEEE<"
    EQUB &14,&00,&00,&00,&00,&00,&00,&28
    EQUB &00

UpdatePlayerVerticalMotion:
    ; Inertial up/down movement while the player graphic remains at fixed Y.
    ;
    ; PlayerUpThrust and PlayerDownThrust decay by 4 every frame. Holding '*'
    ; boosts UpThrust by 8 while simultaneously reducing DownThrust by another
    ; 4; holding '/' does the converse. Both values saturate at 0..255.
    ;
    ; PlayerVerticalAccumulator += UpThrust - DownThrust. As long as this fits
    ; in one byte, no world movement occurs. A positive or negative 16-bit
    ; overflow is converted to a fixed +4 or -4 world-scroll step and handed to
    ; ApplyPlayerVerticalScrollToObjects.
    ;
    ; This is a compact acceleration/inertia model: thrust affects how often
    ; the 8-bit accumulator crosses a boundary, and each crossing scrolls the
    ; world by exactly four units.
    LDA PlayerDeathTimer
    ORA GameInactive
    BEQ DecayUpThrust
    RTS

DecayUpThrust:
    SEC
    LDA PlayerUpThrust
    SBC #&04
    BCS StoreDecayedUpThrust
    LDA #&00

StoreDecayedUpThrust:
    STA PlayerUpThrust
    SEC
    LDA PlayerDownThrust
    SBC #&04
    BCS CheckMoveUpKey
    LDA #&00

CheckMoveUpKey:
    STA PlayerDownThrust
    LDA #KEY_MOVE_UP
    JSR KeyPressed
    BCC CheckMoveDownKey
    CLC
    LDA PlayerUpThrust
    ADC #&08
    BCC StoreBoostedUpThrust
    LDA #&FF

StoreBoostedUpThrust:
    STA PlayerUpThrust
    SEC
    LDA PlayerDownThrust
    SBC #&04
    BCS StoreReducedDownThrust
    LDA #&00

StoreReducedDownThrust:
    STA PlayerDownThrust

CheckMoveDownKey:
    LDA #KEY_MOVE_DOWN
    JSR KeyPressed
    BCC IntegrateVerticalThrust
    CLC
    LDA PlayerDownThrust
    ADC #&08
    BCC StoreBoostedDownThrust
    LDA #&FF

StoreBoostedDownThrust:
    STA PlayerDownThrust
    SEC
    LDA PlayerUpThrust
    SBC #&04
    BCS StoreReducedUpThrust
    LDA #&00

StoreReducedUpThrust:
    STA PlayerUpThrust

IntegrateVerticalThrust:
    LDA #&00
    STA VerticalMotionWorkHi
    LDA PlayerVerticalAccumulator
    STA VerticalMotionWorkLo
    CLC
    LDA VerticalMotionWorkLo
    ADC PlayerUpThrust
    STA VerticalMotionWorkLo
    LDA VerticalMotionWorkHi
    ADC #&00
    STA VerticalMotionWorkHi
    SEC
    LDA VerticalMotionWorkLo
    SBC PlayerDownThrust
    STA VerticalMotionWorkLo
    LDA VerticalMotionWorkHi
    SBC #&00
    STA VerticalMotionWorkHi
    LDA VerticalMotionWorkLo
    STA PlayerVerticalAccumulator
    LDA VerticalMotionWorkHi
    BNE ApplyVerticalScrollOverflow
    RTS

ApplyVerticalScrollOverflow:
    BMI ApplyNegativeVerticalScroll
    LDA #&04
    STA VerticalMotionWorkLo
    LDA #&00
    STA VerticalMotionWorkHi
    JMP ApplyPlayerVerticalScrollToObjects

ApplyNegativeVerticalScroll:
    LDA #&FC
    STA VerticalMotionWorkLo
    LDA #&FF
    STA VerticalMotionWorkHi
    JMP ApplyPlayerVerticalScrollToObjects

ApplyPlayerVerticalScrollToObjects:
    ; When the player's fixed-point vertical motion crosses a coarse boundary,
    ; shift every object's stored world Y by the same signed 16-bit amount.
    ; WorldScrollDeltaLo/Hi are also updated so stars, the Energy Pack and
    ; enemy shots remain in the same scrolling world.
    LDX #&1F

ScrollNextObjectWorldY:
    CLC
    LDA ObjectWorldYLo,X
    ADC VerticalMotionWorkLo
    STA ObjectWorldYLo,X
    LDA ObjectWorldYHi,X
    ADC VerticalMotionWorkHi
    STA ObjectWorldYHi,X
    DEX
    BPL ScrollNextObjectWorldY
    LDA VerticalMotionWorkLo
    STA WorldScrollDeltaLo
    LDA VerticalMotionWorkHi
    STA WorldScrollDeltaHi
    RTS

CheckPlayerShotObjectCollision:
    ; Broad-phase screen overlap has already been detected by XorPlayerShot.
    ; Save the projectile slot in X, then test all 32 active visible objects.
    TXA
    PHA
    LDX #&1F

CheckPlayerShotAgainstObjectSlot:
    ; Precise player-shot/object hit test.
    ; Reject inactive, off-page or transitional objects, then compare absolute
    ; Y/X distance against the per-type SpriteHeights/SpriteWidths tables.
    ;
    ; Energy Balloon (type 7) is special: each hit adds &0180 to its escape
    ; velocity and increments its hit counter. Hit 10 creates the Energy Pack.
    LDA ObjectState,X
    BPL RequireObjectOnVisiblePageForShot
    JMP ContinuePlayerShotCollisionScan

RequireObjectOnVisiblePageForShot:
    LDA ObjectDrawYHi,X
    BEQ RequireActiveObjectForShot
    JMP ContinuePlayerShotCollisionScan

RequireActiveObjectForShot:
    LDA ObjectType,X
    BMI ContinuePlayerShotCollisionScan
    TAY
    LDA ScreenYLo
    SEC
    SBC ObjectDrawYLo,X
    BPL CompareShotVerticalExtent
    EOR #&FF

CompareShotVerticalExtent:
    CMP SpriteHeights,Y
    BCS ContinuePlayerShotCollisionScan
    LDA ScreenXByte
    SEC
    SBC ObjectDrawX,X
    BPL CompareShotHorizontalExtent
    EOR #&FF

CompareShotHorizontalExtent:
    CMP SpriteWidths,Y
    BCS ContinuePlayerShotCollisionScan
    LDA ObjectType,X
    CMP #&07
    BNE DestroyObjectHitByPlayerShot
    CLC
    LDA ObjectParam0,X
    ADC #&80
    STA ObjectParam0,X
    LDA ObjectParam1,X
    ADC #&01
    STA ObjectParam1,X
    INC ObjectParam2,X
    LDA ObjectParam2,X
    CMP #&0A
    BNE PlayPlayerShotImpactSound
    LDA ObjectDrawX,X
    CLC
    ADC #&01
    STA EnergyPackX
    LDA ObjectDrawYLo,X
    CLC
    ADC #&08
    STA EnergyPackYLo
    LDA #&00
    STA EnergyPackYHi
    STA EnergyPackState

DestroyObjectHitByPlayerShot:
    LDA #&00
    JSR DestroyObjectAndAwardScore

PlayPlayerShotImpactSound:
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F1,&FF,&03,&00,&0A,&00
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &11,&00,&08,&00,&FA,&00,&0A,&00
    PLA
    TAX
    LDA #&00
    STA PlayerShotActive,X
    JMP XorPlayerShot

ContinuePlayerShotCollisionScan:
    DEX
    BMI FinishPlayerShotCollisionScan
    JMP CheckPlayerShotAgainstObjectSlot

FinishPlayerShotCollisionScan:
    PLA
    TAX
    RTS
    RTS

DestroyObjectAndAwardScore:
    ; Destroy or silently delete one active object.
    ;
    ; A=0: normal kill. Decrement ActiveObjectCount, set type bit 7 and state
    ;      &41 (explosion bit + radius 1), XOR the first transition pattern,
    ;      remove sprite/radar blip and award the type's BCD score.
    ; A<>0: immediate deletion. Remove sprite/radar, mark ObjectState=&FF and
    ;       award no score / no expanding transition.
    ;
    ; A destroyed Pod is special: before its record changes further, save its
    ; position and queue a random number of Swarmers.
    STA DestroyObjectMode
    CPX #&20
    BCC ValidateObjectForDestruction
    RTS

ValidateObjectForDestruction:
    LDA ObjectState,X
    ORA ObjectType,X
    BPL BeginObjectDestruction
    RTS

BeginObjectDestruction:
    DEC ActiveObjectCount
    LDA ObjectDrawX,X
    STA ScreenXByte
    LDA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectDrawYHi,X
    STA ScreenYHi
    LDA ObjectType,X
    ORA #&80
    STA ObjectType,X
    LDA #&41
    STA ObjectState,X
    STA ObjectWorkState
    TXA
    PHA
    LDA ObjectType,X
    CMP #&83
    BNE HandleDestructionVisualMode
    JSR QueueSwarmersFromDestroyedPod

HandleDestructionVisualMode:
    PLA
    PHA
    TAX
    LDA DestroyObjectMode
    BNE EraseDestroyedObjectSpriteIfVisible
    LDA ObjectType,X
    JSR DrawObjectCollisionPattern

EraseDestroyedObjectSpriteIfVisible:
    PLA
    PHA
    TAX
    LDA ScreenYHi
    BNE ApplyImmediateObjectDeletion
    LDA ObjectType,X
    AND #&7F
    JSR DrawXorSprite

ApplyImmediateObjectDeletion:
    PLA
    TAX
    LDA DestroyObjectMode
    BEQ EraseDestroyedObjectRadarBlip
    LDA #&FF
    STA ObjectState,X

EraseDestroyedObjectRadarBlip:
    LDA ObjectType,X
    AND #&7F
    PHA
    JSR DrawRadarBlip
    PLA
    TAX
    LDA PlayerDeathTimer
    ORA DestroyObjectMode
    BEQ AwardDestroyedObjectScore
    RTS

AwardDestroyedObjectScore:
    LDA ObjectScoreBCD,X
    JSR AddScoreBCD
    RTS

DestroyObjectMode:
    BRK

UpdateInvisoRematerialisation:
    ; Advance the player's reappearance after Inviso-flight.
    ;
    ; Inviso-flight sets PlayerVisibilityMask to 0. DrawPlayer ANDs every player
    ; bitmap byte with this value, so successive values 1..&FE create a changing
    ; stippled/materialising craft rather than an all-or-nothing visibility flag.
    ;
    ; Each player frame:
    ;   * &FF means fully materialised: do nothing;
    ;   * otherwise increment the visibility mask;
    ;   * feed max(mask,20) into the pitch field of an inline SOUND block,
    ;     producing a rising re-materialisation sound;
    ;   * issue a second sound command;
    ;   * once mask >= &C8, generate a random one-frame palette pulse.
    ;
    ; VSyncEventHandler consumes PaletteFlashColour's low three bits and then
    ; immediately restores it to 7, so the colour disturbance lasts one event.
    LDA PlayerVisibilityMask
    CMP #&FF
    BNE AdvanceInvisoVisibilityPhase
    RTS

AdvanceInvisoVisibilityPhase:
    INC PlayerVisibilityMask
    LDA PlayerVisibilityMask
    CMP #&14
    BCS SetInvisoSoundPitch
    LDA #&14

SetInvisoSoundPitch:
    STA InvisoSoundPitch
    JSR PlayInlineSound

; Inline OSWORD 7 SOUND parameter block.
InvisoSoundBlock:
    EQUB &11,&00,&09,&00
InvisoSoundPitch:
    EQUB &00
    EQUB &00,&FF,&FF
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&00,&00,&00,&00,&00,&00
    LDA PlayerVisibilityMask
    CMP #&C8
    BCS PulseInvisoPalette
    RTS

PulseInvisoPalette:
    JSR RandomByte
    AND #&07
    STA PaletteFlashColour
    RTS

ComputeObjectDirectionToPlayer:
    ; Determine the shortest wrapped-Y direction and the horizontal direction
    ; from this object toward the player's position.
    ;
    ; The world Y coordinate wraps modulo 8 pages. The player reference point
    ; used by this routine is Y=&00B4 and X=PlayerXByte+2.
    ;
    ; Outputs:
    ;   ObjectYDirectionToPlayer = 1 => subtract Y, 0 => add Y
    ;   ObjectRightOfPlayer      = 1 => object lies right of PlayerXByte+2
    CLC
    LDA ScreenYHi
    ADC #&04
    AND #&07
    CMP #&04
    BNE StoreObjectDirectionFlags
    LDA ScreenYLo
    CMP #&B4

StoreObjectDirectionFlags:
    LDA #&00
    ADC #&00
    STA ObjectYDirectionToPlayer
    LDX PlayerXByte
    INX
    INX
    CPX ScreenXByte
    LDA #&00
    ADC #&00
    EOR #&01
    STA ObjectRightOfPlayer
    RTS
    RTS

AddObjectXClamped:
    ; A = positive X displacement. Add to object X and clamp at &48.
    CLC
    ADC ScreenXByte
    CMP #&48
    BCC StoreAddedObjectX
    LDA #&48

StoreAddedObjectX:
    STA ScreenXByte
    RTS

SubtractObjectXClamped:
    ; A = positive X displacement. Subtract from object X and clamp at zero.
    ; &0100 is used as a one-byte temporary.
    STA &0100
    SEC
    LDA ScreenXByte
    SBC &0100
    BPL StoreSubtractedObjectX
    LDA #&00

StoreSubtractedObjectX:
    STA ScreenXByte
    RTS

AddObjectY:
    ; A = positive displacement. Add to the 16-bit object Y coordinate.
    CLC
    ADC ScreenYLo
    STA ScreenYLo
    LDA ScreenYHi
    ADC #&00
    STA ScreenYHi
    RTS

SubtractObjectY:
    ; A = positive displacement. Subtract from the 16-bit object Y coordinate.
    ; &0100 is used as a one-byte temporary.
    STA &0100
    SEC
    LDA ScreenYLo
    SBC &0100
    STA ScreenYLo
    LDA ScreenYHi
    SBC #&00
    STA ScreenYHi
    RTS

UpdateSwarmer:
    ; Type 0 - SWARMER.
    ;
    ; Horizontal motion uses a tiny fractional/integrator scheme. Three passes
    ; per behaviour update add SwarmerPositiveXBias into the phase/X position,
    ; then subtract SwarmerNegativeXBias. Boundary crossings swap phase/bias
    ; values rather than simply reflecting a velocity.
    ;
    ; After ComputeObjectDirectionToPlayer, the two biases are slowly pushed
    ; apart by &10 toward the player's horizontal side, saturating at &F0/0.
    ; Vertical pursuit is handled separately by UpdateSwarmerVerticalPursuit.
    ;
    ; A visible Swarmer also has a 24/256 chance per update of emitting its
    ; characteristic sound.
    LDA ScreenYHi
    BNE AimSwarmerAtPlayer
    JSR RandomByte
    CMP #&18
    BCS AimSwarmerAtPlayer
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &12,&00,&01,&00,&BE,&00,&08,&00

AimSwarmerAtPlayer:
    JSR ComputeObjectDirectionToPlayer
    LDX #&02
    CLC
    PHP

ApplySwarmerHorizontalIntegratorPass:
    LDA SwarmerPositiveXBias
    CLC
    ADC SwarmerHorizontalPhase
    STA SwarmerHorizontalPhase
    LDA ScreenXByte
    ADC #&00
    CMP #&46
    BCC StoreSwarmerXAfterPositiveBias
    LDA SwarmerHorizontalPhase
    PHA
    LDA SwarmerPositiveXBias
    STA SwarmerHorizontalPhase
    PLA
    STA SwarmerPositiveXBias
    LDA #&44

StoreSwarmerXAfterPositiveBias:
    STA ScreenXByte
    LDA SwarmerHorizontalPhase
    SEC
    SBC SwarmerNegativeXBias
    STA SwarmerHorizontalPhase
    LDA ScreenXByte
    SBC #&00
    BCS StoreSwarmerXAfterNegativeBias
    LDA SwarmerPositiveXBias
    PHA
    LDA SwarmerHorizontalPhase
    STA SwarmerPositiveXBias
    PLA
    STA SwarmerHorizontalPhase
    LDA #&02

StoreSwarmerXAfterNegativeBias:
    STA ScreenXByte
    DEX
    BPL ApplySwarmerHorizontalIntegratorPass
    PLP
    BCC SteerSwarmerRight
    RTS

SteerSwarmerRight:
    LDA ObjectRightOfPlayer
    BNE SteerSwarmerLeft
    CLC
    LDA SwarmerPositiveXBias
    ADC #&10
    BCC ClampSwarmerPositiveBias
    LDA #&F0

ClampSwarmerPositiveBias:
    STA SwarmerPositiveXBias
    LDA SwarmerNegativeXBias
    SEC
    SBC #&10
    BCS StoreSwarmerNegativeBias
    LDA #&00

StoreSwarmerNegativeBias:
    STA SwarmerNegativeXBias
    JMP UpdateSwarmerVerticalPursuit; finish with +/-5 Y pursuit/overshoot

SteerSwarmerLeft:
    CLC
    LDA SwarmerNegativeXBias
    ADC #&10
    BCC ClampSwarmerNegativeBias
    LDA #&F0

ClampSwarmerNegativeBias:
    STA SwarmerNegativeXBias
    LDA SwarmerPositiveXBias
    SEC
    SBC #&10
    BCS StoreSwarmerPositiveBias
    LDA #&00

StoreSwarmerPositiveBias:
    STA SwarmerPositiveXBias

UpdateSwarmerVerticalPursuit:
    ; Final Y-motion stage of the Swarmer behaviour.
    ;
    ; If the Swarmer is at least about &2A Y-units from the player's fixed
    ; vertical reference (&B4), refresh SwarmerYDirection from the previously
    ; calculated shortest wrapped-Y direction. Once it gets close, retain its
    ; existing direction instead of immediately turning around.
    ;
    ; The result is deliberate overshoot: move +/-5 through the player's Y,
    ; continue past it while inside the near band, then turn back only after
    ; moving far enough away. This is what gives the Swarmer its weaving attack.
    LDA ScreenYLo
    SEC
    SBC #&B4
    BPL SwarmerCheckVerticalDistance
    EOR #&FF

SwarmerCheckVerticalDistance:
    CMP #&2A
    BCC MoveSwarmerVertically
    LDA ObjectYDirectionToPlayer
    STA SwarmerYDirection

MoveSwarmerVertically:
    LDA SwarmerYDirection
    BNE MoveSwarmerUp
    CLC
    LDA ScreenYLo
    ADC #&05
    STA ScreenYLo
    BCC FinishSwarmerDownwardMove
    INC ScreenYHi

FinishSwarmerDownwardMove:
    RTS

MoveSwarmerUp:
    SEC
    LDA ScreenYLo
    SBC #&05
    STA ScreenYLo
    BCS FinishSwarmerUpwardMove
    DEC ScreenYHi

FinishSwarmerUpwardMove:
    RTS
    RTS

UpdateLander:
    ; Type 1 - LANDER.
    ;
    ; Horizontal motion is controlled by LanderHorizontalPhase. Its sign bit
    ; selects +/-1 X; the phase is randomly incremented, so direction changes
    ; only when it crosses &7F/&80 or &FF/&00. A sign transition while the
    ; Lander is on the visible Y page triggers its characteristic sound.
    ;
    ; Vertically, LanderVerticalPhase increases by &0C every update. Interpreting
    ; the signed phase as a triangular speed curve produces a smooth oscillation:
    ; positive half-cycle moves downward by phase/8; negative half-cycle mirrors
    ; the magnitude and moves upward. Horizontal position wraps between roughly
    ; byte-columns 1 and &44.
    LDA #&01
    BIT LanderHorizontalPhase
    BPL ApplyLanderHorizontalStep
    LDA #&FF

ApplyLanderHorizontalStep:
    CLC
    ADC ScreenXByte
    BPL ClampLanderRightEdge
    LDA #&44

ClampLanderRightEdge:
    CMP #&46
    BCC StoreLanderHorizontalPosition
    LDA #&01

StoreLanderHorizontalPosition:
    STA ScreenXByte
    JSR RandomByte
    CMP #&BE; random gate for advancing horizontal phase
    BCS AdvanceLanderVerticalPhase
    INC LanderHorizontalPhase
    LDA ScreenYHi
    BNE AdvanceLanderVerticalPhase
    DEC LanderHorizontalPhase
    LDA LanderHorizontalPhase
    INC LanderHorizontalPhase
    EOR LanderHorizontalPhase
    BPL AdvanceLanderVerticalPhase
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &02,&00,&02,&00,&64,&00,&02,&00

AdvanceLanderVerticalPhase:
    CLC
    LDA LanderVerticalPhase
    ADC #&0C
    STA LanderVerticalPhase
    BMI MoveLanderUpward
    LSR A
    LSR A
    LSR A
    CLC
    ADC ScreenYLo
    STA ScreenYLo
    BCC FinishLanderDownwardMove
    INC ScreenYHi

FinishLanderDownwardMove:
    RTS

MoveLanderUpward:
    AND #&7F
    EOR #&7F
    LSR A
    LSR A
    LSR A
    STA LanderVerticalStep
    SEC
    LDA ScreenYLo
    SBC LanderVerticalStep
    STA ScreenYLo
    LDA ScreenYHi
    SBC #&00
    STA ScreenYHi
    RTS
    RTS

UpdateBaiter:
    ; Type 2 - BAITER. Time-out attacker; fast horizontal/vertical homing on the player.
    LDA BaiterYDirection
    BEQ MoveBaiterDown
    LDA #&14
    JSR SubtractObjectY
    JMP UpdateBaiterVerticalRetarget; retarget Y periodically, then move X

MoveBaiterDown:
    LDA #&14
    JSR AddObjectY

UpdateBaiterVerticalRetarget:
    ; Baiter vertical steering timer.
    ;
    ; The Baiter has already moved +/-20 in Y before entering here. Every
    ; 1..15 updates, recompute the shortest Y direction toward the player and
    ; reload BaiterYRetargetCountdown. Between retargets, keep the old heading.
    ;
    ; After the Y decision, move one X byte-column using BaiterXDirection.
    DEC BaiterYRetargetCountdown
    BNE MoveBaiterHorizontally
    JSR RandomByte
    AND #&0F
    ORA #&01
    STA BaiterYRetargetCountdown
    JSR ComputeObjectDirectionToPlayer
    LDA ObjectYDirectionToPlayer
    STA BaiterYDirection

MoveBaiterHorizontally:
    LDA BaiterXDirection
    BEQ MoveBaiterRight
    LDA #&01
    JSR SubtractObjectXClamped
    JMP UpdateBaiterHorizontalRetarget

MoveBaiterRight:
    LDA #&01
    JSR AddObjectXClamped

UpdateBaiterHorizontalRetarget:
    ; Baiter horizontal steering timer.
    ;
    ; Every 1..7 updates, copy ObjectRightOfPlayer into BaiterXDirection and
    ; reload the countdown. Because ComputeObjectDirectionToPlayer was called
    ; by the vertical retarget path, both steering axes share that latest target
    ; snapshot rather than performing two direction calculations every frame.
    DEC BaiterXRetargetCountdown
    BEQ RetargetBaiterHorizontally
    RTS

RetargetBaiterHorizontally:
    JSR RandomByte
    AND #&07
    ORA #&01
    STA BaiterXRetargetCountdown
    LDA ObjectRightOfPlayer
    STA BaiterXDirection
    RTS

UpdatePod:
    ; Type 3 - POD.
    ;
    ; Two compact fixed-point drift pairs are used:
    ;   PodXVector / PodXPhase
    ;   PodYVector / PodYPhase
    ;
    ; Vector bit 7 selects negative direction. The lower magnitude is folded
    ; into the phase accumulator; carry/borrow makes the integer coordinate move
    ; occasionally, yielding slow sub-unit drift without 16-bit arithmetic.
    ;
    ; SpawnPod explicitly initialises only the two vector bytes. PodXPhase and
    ; PodYPhase inherit the current shared zero-page workspace. This is an exact
    ; property of the binary, as with the partially initialised Banger state.
    LDX #&00
    LDA PodXVector
    BPL AdvancePodXFixedPoint
    LDX #&FF
    EOR #&80

AdvancePodXFixedPoint:
    CLC
    ADC PodXPhase
    STA PodXPhase
    TXA
    ADC ScreenXByte
    STA ScreenXByte
    LDX #&00
    LDA PodYVector
    BPL AdvancePodYFixedPoint
    LDX #&FF
    EOR #&80

AdvancePodYFixedPoint:
    CLC
    ADC PodYPhase
    STA PodYPhase
    TXA
    ADC ScreenYLo
    STA ScreenYLo
    TXA
    ADC ScreenYHi
    STA ScreenYHi
    BIT ScreenXByte
    BMI WrapPodFromLeftEdge
    RTS

WrapPodFromLeftEdge:
    LDA #&46
    STA ScreenXByte
    RTS
    RTS

UpdateDonald:
    ; -------------------------------------------------------------------------
    ; TYPE 4 - DONALD
    ;
    ; DonaldXDirection: 0 moves +2 in X, 1 moves -2.
    ; DonaldYDirection: 0 moves -4 in Y, 1 moves +4.
    ;
    ; Per update:
    ;   * random >= &F0 (~6.25%) toggles vertical direction;
    ;   * a second random >= &E0 (~12.5%) toggles horizontal direction;
    ;   * horizontal edge checks provoke a reversal;
    ;   * while on visible Y page 0, first random < &0F (~5.86%) queues a Banger.
    ;
    ; The first random byte is held on the stack and reused for the Banger test,
    ; so an update that reverses Y (>=&F0) cannot also emit a Banger (<&0F).
    ; -------------------------------------------------------------------------
    JSR RandomByte
    PHA; retain first random byte for Banger-emission test
    CMP #&F0; >=&F0: reverse vertical direction
    BCC DonaldMaybeFlipXDirection
    LDA DonaldYDirection
    EOR #&01; toggle DonaldYDirection
    STA DonaldYDirection

DonaldMaybeFlipXDirection:
    JSR RandomByte
    CMP #&E0; >=&E0: reverse horizontal direction
    BCC DonaldCheckHorizontalEdges
    LDA DonaldXDirection
    EOR #&01; toggle DonaldXDirection
    STA DonaldXDirection

DonaldCheckHorizontalEdges:
    LDA DonaldXDirection
    LDX ScreenXByte
    BNE DonaldCheckRightEdge
    EOR #&01

DonaldCheckRightEdge:
    CPX #&45
    BCC DonaldMaybeQueueBanger
    EOR #&01

DonaldMaybeQueueBanger:
    STA DonaldXDirection
    PLA; recover first random byte
    CMP #&0F; <&0F: queue Banger if visible
    BCS DonaldMoveHorizontally
    LDA ScreenYHi
    BNE DonaldMoveHorizontally
    LDA ScreenXByte
    STA PendingBangerX
    LDA ScreenYLo
    STA PendingBangerY
    INC PendingBangerCount

DonaldMoveHorizontally:
    LDA DonaldXDirection
    BEQ DonaldMoveRight
    LDA #&02
    JSR SubtractObjectXClamped
    JMP MoveDonaldVertically

DonaldMoveRight:
    LDA #&02
    JSR AddObjectXClamped

MoveDonaldVertically:
    ; DonaldYDirection 1 => +4; 0 => -4.
    LDA DonaldYDirection
    BEQ DonaldMoveYNegative
    LDA #&04
    JMP AddObjectY

DonaldMoveYNegative:
    LDA #&04
    JMP SubtractObjectY
    RTS

UpdateBanger:
    ; -------------------------------------------------------------------------
    ; TYPE 5 - BANGER
    ;
    ; Four generic parameter bytes form two trajectory pairs:
    ;   BangerXVector / BangerXPhase
    ;   BangerYVector / BangerYPhase
    ;
    ; Vector bit 7 selects direction. Updating the associated phase/error byte
    ; supplies the carry/borrow used by the coordinate update:
    ;   X changes by 3 or 4 byte-columns per update.
    ;   Y changes by 5 or 6 scanlines per update.
    ;
    ; This is a compact integer trajectory generator: no multiply/divide and no
    ; per-object 16-bit velocity is required.
    ;
    ; If X wraps or reaches &45+, the Banger is silently removed. Passing A=1
    ; to DestroyObjectAndAwardScore suppresses both score and explosion state.
    ; -------------------------------------------------------------------------
    TXA
    PHA
    JSR AdvanceBangerTrajectory
    LDA ScreenXByte
    CMP #&45
    BCS BangerRemoveAtHorizontalBoundary
    PLA
    RTS

BangerRemoveAtHorizontalBoundary:
    PLA
    TAX
    LDA #&01; silent immediate deletion, no score
    JSR DestroyObjectAndAwardScore
    LDA #&FF
    STA ObjectWorkState
    RTS

AdvanceBangerTrajectory:
    ; Update X first, then Y. Sign bit of each vector selects direction;
    ; carry/borrow from the phase update selects the 3/4 or 5/6 step.
    CLC
    LDA BangerXVector
    BPL BangerMoveXNegative
    ORA #&80
    ADC BangerXPhase
    STA BangerXPhase
    LDA ScreenXByte
    ADC #&03; coordinate advances by 3 or 4
    STA ScreenXByte
    JMP BangerUpdateVerticalTrajectory

BangerMoveXNegative:
    ORA #&80
    SEC
    SBC BangerXPhase
    STA BangerXPhase
    LDA ScreenXByte
    SBC #&03; coordinate retreats by 3 or 4
    STA ScreenXByte

BangerUpdateVerticalTrajectory:
    CLC
    LDA BangerYVector
    BPL BangerMoveYNegative
    ORA #&80
    ADC BangerYPhase
    STA BangerYPhase
    LDA ScreenYLo
    ADC #&05; coordinate advances by 5 or 6
    STA ScreenYLo
    LDA ScreenYHi
    ADC #&00
    STA ScreenYHi
    RTS

BangerMoveYNegative:
    ORA #&80
    SEC
    SBC BangerYPhase
    STA BangerYPhase
    LDA ScreenYLo
    SBC #&05; coordinate retreats by 5 or 6
    STA ScreenYLo
    LDA ScreenYHi
    SBC #&00
    STA ScreenYHi
    RTS
    RTS

UpdateSpinner:
    ; -------------------------------------------------------------------------
    ; TYPE 6 - SPINNER
    ;
    ; SpinnerPauseCounter is the only behaviour parameter used.
    ;
    ; * world Y advances by one every update;
    ; * pursuit logic runs only when ScreenYHi == 0;
    ; * a non-zero pause counter simply counts down;
    ; * when moving, random &F0..&FF (16/256) schedules a pause of 16..31;
    ; * horizontal pursuit is +/-2 byte-columns toward PlayerXByte+2;
    ; * wrapped-Y pursuit is +/-7 toward the player reference Y=&00B4.
    ;
    ; There is no frame-indexed sprite animation in this behaviour routine.
    ; The burst/pause homing is the Spinner's movement behaviour.
    ; -------------------------------------------------------------------------
    INC ScreenYLo
    BNE SpinnerRequireVisibleYPage
    INC ScreenYHi

SpinnerRequireVisibleYPage:
    LDA ScreenYHi
    BEQ SpinnerUpdatePause
    RTS

SpinnerUpdatePause:
    LDA SpinnerPauseCounter
    BEQ SpinnerPauseExpired
    DEC SpinnerPauseCounter

SpinnerPauseExpired:
    BEQ SpinnerMaybeStartPause
    RTS

SpinnerMaybeStartPause:
    JSR RandomByte
    CMP #&F0; &F0..&FF => start a pause
    BCC SpinnerHomeOnPlayer
    AND #&1F; because A>=&F0, result is 16..31
    STA SpinnerPauseCounter

SpinnerHomeOnPlayer:
    JSR ComputeObjectDirectionToPlayer
    DEC ScreenXByte
    DEC ScreenXByte
    LDA ObjectRightOfPlayer
    BNE SpinnerMoveTowardPlayerY
    INC ScreenXByte
    INC ScreenXByte
    INC ScreenXByte
    INC ScreenXByte

SpinnerMoveTowardPlayerY:
    SEC
    LDA ScreenYLo
    SBC #&07; provisional -7 wrapped-Y step
    STA ScreenYLo
    LDA ScreenYHi
    SBC #&00
    STA ScreenYHi
    LDA ObjectYDirectionToPlayer
    BEQ SpinnerMoveYPositive
    RTS

SpinnerMoveYPositive:
    CLC
    LDA ScreenYLo
    ADC #&0E; +14 compensation => net +7
    STA ScreenYLo
    LDA ScreenYHi
    ADC #&00
    STA ScreenYHi
    RTS
    RTS

UpdateEnergyBalloon:
    ; Type 7 - ENERGY BALLOON.
    ;
    ; Player-shot hits increase EnergyBalloonVelocity by &0180 and increment
    ; EnergyBalloonHitCount. This routine subtracts that fixed-point velocity
    ; from the Balloon's Y coordinate, making it escape upward faster after
    ; every hit.
    ;
    ; Once it has crossed out of visible Y page zero, the fractional phase is
    ; allowed to settle; when EnergyBalloonPhase >=5 the object is silently
    ; deleted without score/explosion. A successful tenth hit destroys it via
    ; the collision path instead and creates the collectible Energy Pack.
    SEC
    LDA EnergyBalloonPhase
    SBC EnergyBalloonVelocityFrac
    STA EnergyBalloonPhase
    LDA ScreenYLo
    SBC EnergyBalloonVelocityInt
    STA ScreenYLo
    BCS CheckEnergyBalloonEscape
    DEC ScreenYHi

CheckEnergyBalloonEscape:
    LDA ScreenYHi
    BNE CheckEnergyBalloonEscapePhase
    RTS

CheckEnergyBalloonEscapePhase:
    LDA EnergyBalloonPhase
    CMP #&05
    BCS RemoveEscapedEnergyBalloon
    RTS

RemoveEscapedEnergyBalloon:
    LDA #&01
    JSR DestroyObjectAndAwardScore
    LDA #&FF
    STA ObjectWorkState
    RTS
    RTS

StartNextStage:
    ; Increment the BCD wave number, gradually increase the object-update quota
    ; (on odd-numbered waves, capped at &10), reset TIME to 99, load the
    ; appropriate wave schedule and instantiate its objects.
    JSR IncrementWaveBCD
    LDA WaveBCD
    AND #&01
    CLC
    ADC ObjectUpdateQuotaMinus1
    STA ObjectUpdateQuotaMinus1
    CMP #&10
    BCC StoreClampedObjectUpdateQuota
    LDA #&10

StoreClampedObjectUpdateQuota:
    STA ObjectUpdateQuotaMinus1
    JSR DrawTime
    LDA #&00
    STA TimeSubtick
    LDA #&99
    STA TimeBCD
    JSR DrawTime
    JSR LoadStageSchedule

InitialiseStageObjects:
    ; Instantiate the 16-byte StageScheduleScratch count table.
    ;
    ; The loop scans schedule indices 15 down to 0. Entries 8..15 are always
    ; zero in the supplied schedules, so only indices 0..7 can dispatch through
    ; StageSpawnRoutineTable. A non-zero count causes one spawn; the count is
    ; decremented and the same index is revisited until exhausted.
    LDA #&00
    STA PendingSwarmerCount
    STA PendingBangerCount
    STA SmartBombKeyLatch
    STA ActiveObjectCount
    LDA #&00
    STA StageScheduleScratch+2
    STA StageScheduleScratch+5
    LDX #&0F

ScanStageScheduleSlot:
    LDA StageScheduleScratch,X
    BEQ ConsumeStageScheduleCount
    TXA
    PHA
    ASL A
    TAY
    LDA StageSpawnRoutineTable,Y
    STA StageSpawnPtrLo
    LDA StageSpawnRoutineTable+1,Y
    STA StageSpawnPtrHi
    JSR CallStageSpawnRoutine
    PLA
    TAX
    JMP ConsumeStageScheduleCount

CallStageSpawnRoutine:
    JMP (StageSpawnPtrLo)

; --- DATA: stage spawn jump table ---
StageSpawnRoutineTable:
    ; Spawn function for generic type 0..7. Normal wave schedules directly use
    ; Landers, Pods, Donalds and (schedule 3+) Spinners; other types enter through
    ; Pod destruction, Donald emission, timeout, or the Energy Balloon trigger.
    EQUW SpawnSwarmer
    EQUW SpawnLander
    EQUW SpawnBaiter
    EQUW SpawnPod
    EQUW SpawnDonald
    EQUW SpawnBangerAtCurrentPosition
    EQUW SpawnSpinner
    EQUW SpawnEnergyBalloon

ConsumeStageScheduleCount:
    DEC StageScheduleScratch,X
    BPL ScanStageScheduleSlot
    INC StageScheduleScratch,X
    DEX
    BPL ScanStageScheduleSlot
    RTS
SpawnSwarmer:
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    AND #&0F
    CLC
    ADC #&0A
    STA ScreenYLo
    LDA #&02
    STA ScreenYHi
    LDA #&00
    STA ObjectWorkParam1
    STA ObjectWorkParam2
    LDA #&80
    JMP SpawnObject
SpawnLander:
    ; Create materialising Lander type &81.
    ; LanderVerticalPhase is explicitly zeroed. LanderHorizontalPhase is not
    ; initialised here, so its starting horizontal phase/direction inherits the
    ; shared zero-page workspace.
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    AND #&3F
    STA ScreenYLo
    AND #&07
    STA ScreenYHi
    LDA #&00
    STA ObjectWorkParam0
    LDA #&81
    JMP SpawnObject

SpawnBaiter:
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    STA ScreenYLo
    LDA #&00
    STA ScreenYHi
    LDA #&00
    STA ObjectWorkParam0
    STA ObjectWorkParam1
    JSR RandomByte
    ORA #&01
    AND #&07
    STA ObjectWorkParam2
    STA ObjectWorkParam3
    LDA #&82
    JMP SpawnObject
SpawnPod:
    ; Create materialising Pod type &83 at a random world position.
    ; PodXVector and PodYVector are randomised with bit 6 cleared, constraining
    ; the fractional drift magnitude. PodXPhase/PodYPhase are not initialised
    ; here and therefore inherit the shared zero-page workspace.
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    AND #&3F
    STA ScreenYLo
    AND #&07
    STA ScreenYHi
    JSR RandomByte
    AND #&BF
    STA PodXVector
    JSR RandomByte
    AND #&BF
    STA PodYVector
    LDA #&83
    JMP SpawnObject

QueueSwarmersFromDestroyedPod:
    ; Save the destroyed Pod's world position as the centre for deferred Swarmer
    ; spawning. Queue 0..7 additional Swarmers normally; from wave 15 onward add
    ; another 10, giving 10..17.
    LDY ScreenXByte
    STY DestroyedPodX
    LDY ScreenYLo
    STY DestroyedPodYLo
    LDY ScreenYHi
    STY DestroyedPodYHi
    PHA
    JSR RandomByte
    AND #&07
    TAX
    LDA WaveBCD
    CMP #&15
    BCC AddQueuedSwarmerCount
    TXA
    CLC
    ADC #&0A
    TAX

AddQueuedSwarmerCount:
    TXA
    CLC
    ADC PendingSwarmerCount
    STA PendingSwarmerCount
    PLA
    RTS

SpawnQueuedSwarmer:
    ; Spawn one immediately-active Swarmer close to the last destroyed Pod.
    ; Random signed offsets are applied around DestroyedPodX/Y, then the pending
    ; count is decremented.
    ;
    ; No Swarmer behaviour parameters are explicitly initialised here before
    ; SpawnObject; they inherit the current shared zero-page workspace. The
    ; subsequent steering logic rapidly reshapes those inherited values.
    JSR RandomByte
    AND #&07
    PHA
    JSR RandomByte
    BPL ApplyQueuedSwarmerXOffset
    PLA
    EOR #&FF
    PHA

ApplyQueuedSwarmerXOffset:
    PLA
    CLC
    ADC DestroyedPodX
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    AND #&0F
    PHA
    JSR RandomByte
    PHP
    LDY #&00
    PLP
    BPL ApplyQueuedSwarmerYOffset
    PLA
    EOR #&FF
    LDY #&FF
    PHA

ApplyQueuedSwarmerYOffset:
    PLA
    CLC
    ADC DestroyedPodYLo
    STA ScreenYLo
    TYA
    ADC #&00
    STA ScreenYHi
    LDA #&00
    JSR SpawnObject
    DEC PendingSwarmerCount
    RTS
SpawnDonald:
    ; Create a materialising Donald (type &84). Initial X and Y directions are
    ; randomised independently to 0/1; ObjectParam2/3 are unused by Donald.
    JSR RandomByte
    AND #&3E
    STA ScreenXByte
    JSR RandomByte
    AND #&3F
    STA ScreenYLo

ChooseNonZeroDonaldYPage:
    JSR RandomByte
    AND #&07
    BEQ ChooseNonZeroDonaldYPage
    STA ScreenYHi
    JSR RandomByte
    AND #&01
    STA DonaldXDirection
    JSR RandomByte
    AND #&01
    STA DonaldYDirection
    LDA #&84
    JMP SpawnObject

SpawnBangerAtCurrentPosition:
    ; Create an active Banger (type 5) at the current ScreenX/Y position.
    ; Only BangerXVector is explicitly written here. BangerYVector and the two
    ; phase bytes are NOT initialised by this routine; they inherit whatever is
    ; currently in the shared object-work zero-page bytes at the time of spawn.
    ; That is an exact property of the binary, not an inferred source-level rule.
    JSR RandomByte
    STA BangerXVector
    LDA #&05
    JMP SpawnObject
SpawnSpinner:
    ; Create a materialising Spinner (type &86). Initial pause is 0 or 16
    ; because RandomByte is masked with #&10.
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    JSR RandomByte
    STA ScreenYLo
    AND #&07
    STA ScreenYHi
    JSR RandomByte
    AND #&10
    STA SpinnerPauseCounter
    LDA #&86
    JMP SpawnObject
SpawnEnergyBalloon:
    ; Create materialising Energy Balloon type &87 at random X/Y on visible page.
    ; Velocity fraction/int and hit count start at zero. EnergyBalloonPhase is
    ; not explicitly initialised and inherits the shared zero-page workspace;
    ; it is irrelevant while velocity remains zero.
    LDA #&00
    STA EnergyBalloonVelocityFrac
    STA EnergyBalloonVelocityInt
    STA EnergyBalloonHitCount
    LDA #&00
    STA ScreenYHi
    JSR RandomByte
    STA ScreenYLo
    JSR RandomByte
    AND #&3F
    STA ScreenXByte
    LDA #&87
    JMP SpawnObject

LoadStageSchedule:
    ; Select one of the three 16-byte wave-count tables and copy it into the
    ; writable StageScheduleScratch buffer.
    ;
    ; Waves 1 and 2 use schedules 1 and 2. Wave 3 and every later wave select
    ; schedule 3. The slightly unusual BCD/bit arithmetic arrives at that clamp
    ; without a general conversion routine.
    LDX #&0F
    LDA #&00

ClearStageScheduleScratch:
    STA StageScheduleScratch,X
    DEX
    BPL ClearStageScheduleScratch
    LDA WaveBCD
    AND #&07
    CMP WaveBCD
    BEQ ConvertWaveToScheduleIndex
    LDA #&07

ConvertWaveToScheduleIndex:
    SEC
    SBC #&01
    CMP #&02
    BCC SelectStageSchedule
    LDA #&02

SelectStageSchedule:
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #<StageSchedule1
    STA StageSchedulePtrLo
    LDA #&00
    ADC #>StageSchedule1
    STA StageSchedulePtrHi
    LDY #&0F

CopySelectedStageSchedule:
    LDA (StageSchedulePtrLo),Y
    STA StageScheduleScratch,Y
    DEY
    BPL CopySelectedStageSchedule
    RTS

; --- DATA: stage schedule tables/scratch ---
StageSchedule1:
    EQUB &00,&08,&00,&02,&01,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
StageSchedule2:
    EQUB &00,&08,&00,&02,&03,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
StageSchedule3:
    EQUB &00,&0C,&00,&05,&05,&00,&07,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00
StageScheduleScratch:
    ; Writable 17-byte work area in the loaded image. The first 16 bytes are
    ; overwritten from a selected schedule before normal use; original bytes
    ; happen to contain the ASCII test pattern below.
    EQUS "0123456789ABCDEFH"

SpawnQueuedBanger:
    ; Consume at most one deferred Donald->Banger request per main-loop pass.
    ; Donald stores only the most recent visible-page position, so if several
    ; requests accumulate they all emerge from that saved X/Y point.
    LDA PendingBangerCount
    BNE SpawnNextQueuedBanger
    RTS

SpawnNextQueuedBanger:
    DEC PendingBangerCount
    LDA PendingBangerX
    STA ScreenXByte
    LDA PendingBangerY
    STA ScreenYLo
    LDA #&00
    STA ScreenYHi
    JMP SpawnBangerAtCurrentPosition

; --- DATA: sprite metadata and sprite bitmaps ---
SpriteWidths:
    ; Eight sprite widths in bytes; one byte encodes two MODE 2 logical pixels.
    EQUB &03,&04,&06,&03,&04,&02,&04,&04
SpriteHeights:
    ; Eight sprite heights in scanlines.
    EQUB &04,&10,&04,&06,&0C,&0C,&0D,&10
RadarBlipMasks:
    ; Eight radar/scanner XOR masks associated with object types.
    EQUB &30,&33,&3F,&03,&C3,&F0,&F0,&03
SpritePointers:
    ; Bitmap pointer for object types 0..7, in the same order as ObjectBehaviourTable.
    EQUW SwarmerSprite
    EQUW LanderSprite
    EQUW BaiterSprite
    EQUW PodSprite
    EQUW DonaldSprite
    EQUW BangerSprite
    EQUW SpinnerSprite
    EQUW EnergyBalloonSprite
ObjectScoreBCD:
    ; Packed-BCD score by type:
    ; Swarmer=20, Lander=5, Baiter=15, Pod=2,
    ; Donald=50, Banger=15, Spinner=20, Energy Balloon=80.
    EQUB &20,&05,&15,&02,&50,&15,&20,&80
SwarmerSprite:
    EQUB &00,&40,&D4,&40,&80,&C0,&D4,&C0
    EQUB &00,&00,&80,&00
LanderSprite:
    EQUB &AA,&44,&CC,&CC,&DC,&DC,&CC
    EQUS "DDDD@@DD"
    EQUB &00,&CC,&CC,&CC,&CC,&EC,&EC,&EC
    EQUB &CC,&CC,&CC,&CC,&C8,&C0,&C4,&CC
    EQUB &CC,&CC,&CC,&CC,&CC,&DC,&DC,&DC
    EQUB &CC,&CC,&CC,&CC,&C8,&C0,&C4,&CC
    EQUB &CC,&00,&88,&CC,&CC,&EC,&EC,&CC
    EQUB &88,&88,&88,&88,&88,&80,&80,&88
    EQUB &00
BaiterSprite:
    EQUB &00,&04,&04,&00,&09,&07,&07,&09
    EQUB &0E,&09,&09,&0E,&06,&A9,&A9,&06
    EQUB &0B,&0D,&0D,&0B,&08,&06,&06,&08
PodSprite:
    EQUB &54,&54,&C0,&C0,&54,&54,&D4,&D4
    EQUB &C0,&C0,&D4,&D4,&00,&00,&80,&80
    EQUB &00,&00
DonaldSprite:
    EQUB &01,&4A,&84,&C0,&80,&54,&80,&C0
    EQUB &C0,&40,&40,&00,&0D,&C0,&C0,&02
    EQUB &10,&10,&C0,&C0
    EQUS " @@`"
    EQUB &06,&C0,&C0,&05,&20,&20,&C0,&C0
    EQUB &10,&80,&80,&90,&0A,&81,&48,&C0
    EQUB &40,&A8,&40,&C0,&C0,&80,&80,&00
UnknownGraphicData_21A2:
    EQUS "0000000000000000"
BangerSprite:
    EQUB &02,&08,&05,&40,&40,&C0,&C0,&C0
    EQUB &C0,&90,&60,&90,&08,&02,&00,&00
    EQUB &00,&80,&80,&80,&80,&80,&20,&80
SpinnerSprite:
    EQUB &00,&55,&AE,&AF,&07,&07,&03,&0C
    EQUB &0C,&AF,&AF,&55,&00,&AB,&09,&09
    EQUB &09,&0B,&0B,&03,&0B,&0B,&0B,&03
    EQUB &03,&AB,&AA,&57,&07,&0F,&0E,&0E
    EQUB &03,&0F,&0D,&0C,&0C,&5D,&AA,&00
    EQUB &00,&AA,&AA
    EQUS "]]WWW"
    EQUB &AA,&AA,&00,&00
EnergyBalloonSprite:
    EQUB &00,&00,&54,&54,&FC,&ED,&FC,&FC
    EQUB &54,&54,&00,&11,&10,&10,&11,&00
    EQUB &00,&B8,&30,&B8,&DE,&CF,&DE,&B9
    EQUB &33,&B9,&B8
    EQUS "0!!0"
    EQUB &10,&00,&A8,&74,&F8,&F0,&F8,&FC
    EQUB &FC,&76,&FC,&A8
    EQUS "1001"
    EQUB &00,&00,&00,&00,&00,&A0,&A8,&A8
    EQUB &A8,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&60

InitialiseStarfield:
    ; Create 24 stars. Slots 0..7, 8..15 and 16..23 form three parallax layers.
    ; Each layer has its own pixel mask and vertical speed (2, 3 or 4 units).
    ; Initial X is 0..69 and Y is a full random byte.
    LDX #&17
    STX StarLoopIndex

InitialiseNextStar:
    LDX StarLoopIndex
    JSR RandomByte
    STA ScreenYLo
    PHA
    JSR RandomStarX
    LDX StarLoopIndex
    STA StarX,X
    PLA
    STA StarY,X
    JSR XorStar
    DEC StarLoopIndex
    BPL InitialiseNextStar
    RTS

XorStar:
    ; XOR one star at ScreenXByte/ScreenYLo. Star slot / 8 selects one of the
    ; three layer masks in StarPixelMasks, so the layers can also differ visually.
    TXA
    PHA
    JSR Mode2ScreenAddressFromXY
    PLA
    LSR A
    LSR A
    LSR A
    TAX
    LDY #&00
    LDA StarPixelMasks,X
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    RTS

; --- DATA: star masks ---
StarPixelMasks:
    ; One MODE 2 XOR mask per eight-star depth band; fourth entry is unused by
    ; the 24-star pool but makes the table naturally four bytes long.
    EQUB &14,&11,&41,&00

UpdateStarfield:
    ; Main-loop wrapper. The starfield only scrolls when the world moved
    ; vertically on this frame. Direct callers use ScrollStarfieldOneStep for
    ; title/display transitions where a forced starfield step is wanted.
    LDA WorldScrollDeltaLo
    BNE ScrollStarfieldOneStep
    RTS

ScrollStarfieldOneStep:
    ; Erase, move and redraw all 24 stars.
    ; WorldScrollDeltaHi supplies the scroll direction; the *magnitude* of the
    ; player's +/-4 world shift is deliberately ignored. Layer speed instead
    ; comes from StarSpeedTable: 2, 3, 4 for the three groups of eight.
    ;
    ; If a star wraps vertically, only its X coordinate is randomised. This is
    ; a compact three-depth parallax starfield with just 48 bytes of position
    ; state.
    LDX #&17
    STX StarLoopIndex

UpdateNextStar:
    LDX StarLoopIndex
    LDA StarX,X
    STA ScreenXByte
    LDA StarY,X
    STA ScreenYLo
    LDX StarLoopIndex
    JSR XorStar
    LDA StarLoopIndex
    LSR A
    LSR A
    LSR A
    TAX
    BIT WorldScrollDeltaHi
    BMI ScrollStarUp
    LDA StarSpeedTable,X
    CLC
    ADC ScreenYLo
    STA ScreenYLo
    BCC FinishStarMovement
    JSR RandomStarX

FinishStarMovement:
    JMP StoreAndRedrawStar

ScrollStarUp:
    LDA ScreenYLo
    SEC
    SBC StarSpeedTable,X
    STA ScreenYLo
    BCS StoreAndRedrawStar
    JSR RandomStarX

StoreAndRedrawStar:
    ; Common tail after moving one star: XOR it at the new location, store
    ; updated X/Y back into the parallel arrays, then continue the 24-star scan.
    LDX StarLoopIndex
    JSR XorStar
    LDX StarLoopIndex
    LDA ScreenYLo
    STA StarY,X
    LDA ScreenXByte
    STA StarX,X
    DEC StarLoopIndex
    BPL UpdateNextStar
    RTS

; --- DATA: star speed table ---
StarSpeedTable:
    ; Vertical parallax speed for star slot/8: near/far ordering is visual,
    ; but the three actual magnitudes are 2, 3 and 4 pixels/units per step.
    EQUB &02,&03,&04,&00

RandomStarX:
    JSR RandomByte
    CMP #&46
    BCS RandomStarX
    STA ScreenXByte
    RTS
    RTS

ResetEnemyShotPool:
    ; Six projectile slots. EnemyShotState=&FF marks a free slot.
    LDA #&FF
    LDX #&05

ClearNextEnemyShotSlot:
    STA EnemyShotState,X
    DEX
    BPL ClearNextEnemyShotSlot
    RTS

CreateEnemyShot:
    ; Probabilistically choose a live, visible object as a shooter, find one of
    ; six free projectile slots, and construct a ballistic vector aimed at the
    ; player's CURRENT position.
    ;
    ; The first random byte must be < EnemyFireChanceThreshold. The game never
    ; writes that zero-page threshold, so its runtime value must already exist
    ; when the game starts (or be inherited from earlier loader/program state).
    ;
    ; The shot does not home after launch. X/Y target deltas are converted to
    ; signed fixed-point velocities by ScaleEnemyShotVectorAndLaunch.
    JSR RandomByte
    CMP EnemyFireChanceThreshold
    BCC TrySelectEnemyShooter
    RTS

TrySelectEnemyShooter:
    JSR RandomByte
    AND #&3F
    TAX
    LDA PlayerDeathTimer
    BEQ ValidateEnemyShooter
    RTS

ValidateEnemyShooter:
    LDA ObjectState,X
    ORA ObjectType,X
    BPL RequireGenericObjectSlot
    RTS

RequireGenericObjectSlot:
    CPX #&20
    BCC RequireShooterOnVisiblePage
    RTS

RequireShooterOnVisiblePage:
    LDA ObjectDrawYHi,X
    BEQ FindFreeEnemyShotSlot
    RTS

FindFreeEnemyShotSlot:
    LDA ObjectDrawYLo,X
    STA ScreenYLo
    LDA ObjectDrawX,X
    STA ScreenXByte
    LDX #&05

ScanEnemyShotSlots:
    LDA EnemyShotState,X
    BMI InitialiseEnemyShotPosition
    DEX
    BPL ScanEnemyShotSlots
    RTS

InitialiseEnemyShotPosition:
    LDA #&00
    STA EnemyShotState,X
    LDA #&00
    STA EnemyShotXFrac,X
    STA EnemyShotYFrac,X
    LDA ScreenXByte
    STA EnemyShotX,X
    LDA ScreenYLo
    STA EnemyShotY,X
    LDA PlayerXByte
    CLC
    ADC #&03
    SEC
    SBC ScreenXByte
    BCC EnemyShotTargetIsLeft
    STA EnemyShotXVelocityFrac,X
    LDA #&00
    STA EnemyShotXVelocity,X
    JMP SetEnemyShotVerticalAimDelta

EnemyShotTargetIsLeft:
    STA EnemyShotXVelocityFrac,X
    LDA #&FF
    STA EnemyShotXVelocity,X

SetEnemyShotVerticalAimDelta:
    ; Build signed 16-bit vertical target delta:
    ;       player reference Y (&B0) - shooter's Y
    ; into EnemyShotYVelocity:EnemyShotYVelocityFrac.
    LDA #&B0
    SEC
    SBC ScreenYLo
    BCC EnemyShotTargetIsAbove
    STA EnemyShotYVelocityFrac,X
    LDA #&00
    STA EnemyShotYVelocity,X
    JMP ScaleEnemyShotVectorAndLaunch

EnemyShotTargetIsAbove:
    STA EnemyShotYVelocityFrac,X
    LDA #&FF
    STA EnemyShotYVelocity,X

ScaleEnemyShotVectorAndLaunch:
    ; Convert both signed target deltas into fixed-point velocities.
    ; Three 16-bit left shifts multiply each delta by 8; because the result is
    ; subsequently accumulated as integer:fraction, this is equivalent to
    ; travelling approximately target_delta / 32 per update.
    ;
    ; Subtract the current signed world-scroll amount from the Y integer
    ; velocity so a newly fired shot remains aimed correctly in screen space
    ; while the world is scrolling. Lifetime starts at 255 frames.
    LDA #&FF
    STA EnemyShotLifetime,X
    LDY #&02

DoubleEnemyShotAimVector:
    CLC
    LDA EnemyShotXVelocityFrac,X
    ADC EnemyShotXVelocityFrac,X
    STA EnemyShotXVelocityFrac,X
    LDA EnemyShotXVelocity,X
    ADC EnemyShotXVelocity,X
    STA EnemyShotXVelocity,X
    CLC
    LDA EnemyShotYVelocityFrac,X
    ADC EnemyShotYVelocityFrac,X
    STA EnemyShotYVelocityFrac,X
    LDA EnemyShotYVelocity,X
    ADC EnemyShotYVelocity,X
    STA EnemyShotYVelocity,X
    DEY
    BPL DoubleEnemyShotAimVector
    SEC
    LDA EnemyShotYVelocity,X
    SBC WorldScrollDeltaLo
    STA EnemyShotYVelocity,X
    JSR XorEnemyShot
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F4,&FF,&04,&00,&01,&00
    RTS

UpdateEnemyShots:
    ; Update all six ballistic enemy shots:
    ;   erase -> add 8.8 fixed-point X/Y velocity -> compensate for this frame's
    ;   world scroll -> bounds/lifetime tests -> redraw.
    ;
    ; There is no separate enemy-shot/player hit-test here. Because shots are
    ; already XORed into screen RAM, the player's own XOR renderer notices the
    ; occupied pixels and its broad-phase collision path kills the player.
    LDX #&05

UpdateNextEnemyShot:
    TXA
    PHA
    LDA EnemyShotState,X
    BMI AdvanceEnemyShotSlot
    JSR XorEnemyShot
    CLC
    LDA EnemyShotXFrac,X
    ADC EnemyShotXVelocityFrac,X
    STA EnemyShotXFrac,X
    LDA EnemyShotX,X
    ADC EnemyShotXVelocity,X
    STA EnemyShotX,X
    CMP #&48
    BCS ExpireEnemyShot
    CLC
    LDA EnemyShotYFrac,X
    ADC EnemyShotYVelocityFrac,X
    STA EnemyShotYFrac,X
    LDA EnemyShotY,X
    ADC EnemyShotYVelocity,X
    STA EnemyShotY,X
    PHP
    PLA
    ROR A
    ROR A
    EOR EnemyShotYVelocity,X
    BMI ExpireEnemyShot
    CLC
    LDA EnemyShotY,X
    ADC WorldScrollDeltaLo
    STA EnemyShotY,X
    PHP
    PLA
    ROR A
    ROR A
    EOR WorldScrollDeltaHi
    BMI ExpireEnemyShot
    DEC EnemyShotLifetime,X
    BEQ ExpireEnemyShot
    JSR XorEnemyShot

AdvanceEnemyShotSlot:
    PLA
    TAX
    DEX
    BPL UpdateNextEnemyShot
    RTS

ExpireEnemyShot:
    LDA #&FF
    STA EnemyShotState,X
    BMI AdvanceEnemyShotSlot

XorEnemyShot:
    ; Draw/erase one enemy shot as a two-scanline XOR mark (&FC on each line).
    ; X is the projectile slot.
    TXA
    PHA
    LDA EnemyShotX,X
    STA ScreenXByte
    LDA EnemyShotY,X
    STA ScreenYLo
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA (ScreenPtrLo),Y
    EOR #&FC
    STA (ScreenPtrLo),Y
    INC ScreenYLo
    JSR Mode2ScreenAddressFromXY
    DEC ScreenYLo
    LDY #&00
    LDA (ScreenPtrLo),Y
    EOR #&FC
    STA (ScreenPtrLo),Y
    PLA
    TAX
    RTS
    RTS

PlayInlineSound:
    ; Inline OSWORD 7 SOUND helper.
    ;
    ; The eight bytes immediately following the JSR are copied into a common
    ; SoundParameterBuffer. The return address is rewritten so execution resumes
    ; after those eight bytes.
    ;
    ; If the inline channel byte has bit 7 set, the sound is allowed even while
    ; a tune/jingle is active. Otherwise an active SoundSequenceCounter suppresses
    ; the effect to avoid trampling sequenced music. Bit 7 is stripped before
    ; submitting OSWORD 7. SoundFlags bit 7 globally enables/disables output.
    CLC
    PLA
    ADC #&01
    STA InlineSoundPtrLo
    PLA
    ADC #&00
    STA InlineSoundPtrHi
    LDY #&07

CopyNextInlineSoundByte:
    LDA (InlineSoundPtrLo),Y
    STA SoundParameterBuffer,Y
    DEY
    BPL CopyNextInlineSoundByte
    CLC
    LDA InlineSoundPtrLo
    ADC #&07
    TAX
    LDA InlineSoundPtrHi
    ADC #&00
    PHA
    TXA
    PHA
    LDA SoundParameterBuffer
    BMI SubmitInlineSound
    LDA SoundSequenceCounter
    BEQ SubmitInlineSound
    RTS

SubmitInlineSound:
    LDA SoundParameterBuffer
    AND #&7F
    STA SoundParameterBuffer
    LDA #&07
    LDX #<SoundParameterBuffer
    LDY #>SoundParameterBuffer
    BIT SoundFlags
    BPL FinishInlineSound
    JMP OSWORD; MOS OSWORD

FinishInlineSound:
    RTS

; --- DATA: OSWORD 7 sound buffer ---
SoundParameterBuffer:
    EQUS "RESERVED"

HandleSoundToggle:
    ; Edge-triggered S-key sound toggle.
    ;
    ; SoundFlags bit 7 is sound enable; bit 0 is the key-release latch. Releasing
    ; S sets the latch. Pressing it with the latch set XOR-erases the current
    ; ON/OFF HUD text, toggles both bits with EOR #&81, then draws the new status.
    LDA #KEY_SOUND_TOGGLE
    JSR KeyPressed
    BCS HandleHeldSoundToggleKey
    LDA SoundFlags
    ORA #&01
    STA SoundFlags
    RTS

HandleHeldSoundToggleKey:
    LDA SoundFlags
    AND #&01
    BNE ToggleSoundAndRedrawStatus
    RTS

ToggleSoundAndRedrawStatus:
    JSR DrawSoundStatus
    LDA SoundFlags
    EOR #&81
    STA SoundFlags
    JMP DrawSoundStatus

DrawSoundStatus:
    LDA SoundFlags
    BPL DrawSoundOffStatus
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&1E,&CF,&4F,&4E,&00
    RTS

DrawSoundOffStatus:
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&1E,&CF,&4F,&46,&46,&00
    RTS
    RTS

DrawInlineText:
    ; Inline fixed-width 4x8 MODE 2 text renderer.
    ;
    ; Calling convention is deliberately encoded after the JSR:
    ;       JSR DrawInlineText
    ;       EQUB x, y, colourMask
    ;       EQUS "TEXT"
    ;       EQUB 0
    ;       ; execution resumes here
    ;
    ; x is doubled into a MODE 2 byte-column; y is multiplied by 8. Each glyph
    ; is 16 bytes = two MODE 2 byte-columns x eight scanlines = four logical
    ; pixels wide by eight high. Glyph bytes are ANDed with colourMask and XORed
    ; into the screen, so the same call can draw and erase text.
    CLC
    PLA
    ADC #&01
    STA InlineTextPtrLo
    PLA
    ADC #&00
    STA InlineTextPtrHi
    LDY #&00
    LDA (InlineTextPtrLo),Y
    ASL A
    STA ScreenXByte
    INY
    LDA (InlineTextPtrLo),Y
    ASL A
    ASL A
    ASL A
    STA ScreenYLo
    LDA #&00
    STA ScreenYHi
    JSR Mode2ScreenAddressFromXY
    LDY #&02
    LDA (InlineTextPtrLo),Y
    STA InlineTextColourMask

RenderNextInlineTextCharacter:
    ; Interpret the next byte of the inline string.
    ;
    ; 0 terminates the string: manufacture the continuation address (the byte
    ; after the terminator) and JMP indirect to it, effectively replacing RTS.
    ; Space advances one fixed character cell without drawing.
    ; Other supported characters are 0-9 and A-Z.
    INY
    LDA (InlineTextPtrLo),Y
    CMP #&00
    BNE RenderInlineTextCharacter
    SEC
    TYA
    ADC InlineTextPtrLo
    STA InlineTextPtrLo
    LDA InlineTextPtrHi
    ADC #&00
    STA InlineTextPtrHi
    JMP (InlineTextPtrLo)

RenderInlineTextCharacter:
    TYA
    PHA
    LDA (InlineTextPtrLo),Y
    CMP #&20
    BNE MapAsciiToGlyphIndex
    JMP AdvanceInlineTextCursor

MapAsciiToGlyphIndex:
    CMP #&3A
    BCS BuildFontGlyphAddress
    ADC #&07; digits: '0'..'9' -> values aligned with letters

BuildFontGlyphAddress:
    SEC
    SBC #&37; glyph index: 0..9 then A=10..Z=35
    STA FontGlyphPtrLo
    LDA #&00
    ASL FontGlyphPtrLo
    ROL A
    ASL FontGlyphPtrLo
    ROL A
    ASL FontGlyphPtrLo
    ROL A
    ASL FontGlyphPtrLo
    ROL A
    PHA
    LDA FontGlyphPtrLo
    CLC
    ADC #<FontGlyphs_0_9_A_Z
    STA FontGlyphPtrLo
    PLA
    ADC #>FontGlyphs_0_9_A_Z
    STA FontGlyphPtrHi
    LDY #&0F

XorFontGlyphBytes:
    LDA (FontGlyphPtrLo),Y
    AND InlineTextColourMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    DEY
    BPL XorFontGlyphBytes

AdvanceInlineTextCursor:
    ; Move right by one 4-pixel glyph cell. In MODE 2 that is two byte-columns,
    ; hence +16 bytes in screen memory (8 bytes per byte-column), then restore
    ; the inline-string index from the stack and process the next character.
    CLC
    LDA ScreenPtrLo
    ADC #&10
    STA ScreenPtrLo
    LDA ScreenPtrHi
    ADC #&00
    STA ScreenPtrHi
    PLA
    TAY
    JMP RenderNextInlineTextCharacter

; --- DATA: 36 glyph font: 0-9 and A-Z, 16 bytes each ---
FontGlyphs_0_9_A_Z:
    ; Fixed-width 4x8 MODE 2 font.
    ; 36 glyphs x 16 bytes: two byte-columns x eight scanlines per character.
    ; ASCII 0-9 maps to glyph 0..9; A-Z maps to glyph 10..35.
    EQUB &FF,&AA,&AA,&AA,&AA,&AA,&FF,&00
    EQUB &AA,&AA,&AA,&AA,&AA,&AA,&AA,&00
    EQUB &55,&FF
    EQUS "UUUU"
    EQUB &FF,&00,&00,&00,&00,&00,&00,&00
    EQUB &AA,&00,&FF,&00,&00,&FF,&AA,&AA
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&00,&00
    EQUB &AA,&00,&FF,&00,&00,&FF,&00,&00
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&FF,&00,&00
    EQUB &00,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&00,&00
    EQUB &FF,&00,&AA,&00,&00,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &FF,&00,&AA,&00,&00,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&00,&00,&00
    EQUB &00,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&00,&00
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &FF,&00,&00,&AA,&AA,&00,&AA,&AA
    EQUB &00,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&AA,&AA,&00,&00,&00,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&00,&AA,&AA,&AA,&AA,&AA
    EQUB &00,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &FF,&00,&AA,&00,&00,&AA,&00,&00
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&00,&00,&AA,&00,&00
    EQUB &00,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&AA,&00,&00,&00,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF
    EQUS "UUUUU"
    EQUB &FF,&00,&AA,&00,&00,&00,&00,&00
    EQUB &AA,&00,&FF
    EQUS "UUUUU"
    EQUB &FF,&00,&AA,&00,&00,&00,&00,&00
    EQUB &00,&00,&AA,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&00,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&00,&00,&00,&00,&00,&00
    EQUB &AA,&00,&AA,&FF,&FF,&AA,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&AA,&00,&00
    EQUB &00,&00,&FF,&AA,&AA,&AA,&AA,&AA
    EQUB &FF,&00,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &AA,&55,&FF,&AA,&AA,&FF,&AA,&AA
    EQUB &AA,&00,&AA,&AA,&AA,&00,&AA,&AA
    EQUB &AA,&00,&FF,&AA,&AA,&FF,&00,&00
    EQUB &FF,&00,&AA,&00,&00,&AA,&AA,&AA
    EQUB &AA,&00,&FF
    EQUS "UUUUUU"
    EQUB &00,&AA,&00,&00,&00,&00,&00,&00
    EQUB &00,&AA,&AA,&AA,&AA,&AA,&AA,&FF
    EQUB &00,&AA,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &00,&AA,&AA,&AA,&AA,&AA,&AA,&55
    EQUB &00,&AA,&AA,&AA,&AA,&AA,&AA,&00
    EQUB &00,&AA,&AA,&AA,&AA,&FF,&FF,&AA
    EQUB &00,&AA,&AA,&AA,&AA,&AA,&AA,&AA
    EQUB &00,&AA,&AA,&AA,&55,&AA,&AA,&AA
    EQUB &00,&AA,&AA,&AA,&00,&AA,&AA,&AA
    EQUB &00,&AA,&AA,&AA
    EQUS "UUUU"
    EQUB &00,&AA,&AA,&AA,&00,&00,&00,&00
    EQUB &00,&FF,&00,&00,&55,&55,&AA,&FF
    EQUB &00,&AA,&AA,&AA,&00,&00,&00,&AA
    EQUB &00

UpdateBonusAndStageMessages:
    JSR UpdateBonusLifeMessage
    JSR UpdateStageCompleteMessage
    JSR UpdateStageCompleteTimer
    RTS

UpdateBonusLifeMessage:
    ; BonusLifeMessageTimer=&FF displays the bonus message immediately. The timer
    ; then counts down once per call; when the previous value reaches 1 the same
    ; XOR text call removes the message.
    LDA BonusLifeMessageTimer
    CMP #&FF
    BNE ServiceBonusLifeMessage
    JSR DrawBonusLifeMessage

ServiceBonusLifeMessage:
    LDA BonusLifeMessageTimer
    BNE TickBonusLifeMessage
    RTS

TickBonusLifeMessage:
    DEC BonusLifeMessageTimer
    CMP #&01
    BEQ EraseBonusLifeMessage
    RTS

EraseBonusLifeMessage:
    JMP DrawBonusLifeMessage

DrawBonusLifeMessage:
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &02,&03
    EQUS "<BONUS SHIP AND ENERGY UNIT GIVEN"
    EQUB &00
    RTS

UpdateStageCompleteMessage:
    ; StageCompleteTimer drives the stage-complete panel and time-bonus phase.
    ; At start (&FF) the panel is drawn. While the timer runs down below &C8,
    ; remaining BCD time is converted into score. Once time reaches zero, a
    ; final 60-frame hold is installed before the panel is removed.
    LDA StageCompleteTimer
    BNE TickStageCompleteDisplay
    RTS

TickStageCompleteDisplay:
    DEC StageCompleteTimer
    CMP #&FF
    BNE ConvertStageTimeOrFinish
    JSR DrawRemainingTimeBonus
    JSR DrawStageBonusMultiplier
    JMP DrawStageCompleteSummary

ConvertStageTimeOrFinish:
    LDA StageCompleteTimer
    BEQ FinishStageCompleteDisplay
    JMP ConvertRemainingTimeToScore

FinishStageCompleteDisplay:
    JSR DrawStageCompleteSummary
    JSR DrawRemainingTimeBonus
    JSR DrawStageBonusMultiplier
    LDA #&64
    STA StageStartTimer
    RTS

DrawStageCompleteSummary:
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &08,&09,&F0
    EQUS "STAGE    COMPLETED"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&0B
    EQUS "3ALL ALIENS DESTROYED"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&0D,&FC
    EQUS "BONUS POINTS   0 X"
    EQUB &00
    RTS

DrawRemainingTimeBonus:
    LDX #&1A
    LDA #&FC
    STA BCDColourMask
    LDA TimeBCD
    LDY #&0D
    JMP DrawBCDValue

ConvertRemainingTimeToScore:
    ; Once StageCompleteTimer has dropped below &C8, convert one remaining BCD
    ; TIME unit per call into score. The award per converted unit is min(Wave,5).
    ;
    ; When TIME reaches zero, StageCompleteTimer is set to &3C, creating a final
    ; 60-call hold before the stage-complete panel is removed.
    LDA TimeBCD
    BNE WaitBeforeConvertingTimeBonus
    RTS

WaitBeforeConvertingTimeBonus:
    LDA StageCompleteTimer
    CMP #&C8
    BCC ConvertOneRemainingTimeUnit
    RTS

ConvertOneRemainingTimeUnit:
    JSR DrawRemainingTimeBonus
    JSR DrawTime
    SEC
    LDA TimeBCD
    SED
    SBC #&01
    BCS StoreDecrementedBonusTime
    LDA #&00

StoreDecrementedBonusTime:
    STA TimeBCD
    CLD
    JSR DrawRemainingTimeBonus
    JSR DrawTime
    LDA TimeBCD
    BEQ BeginStageCompleteHold
    LDA WaveBCD
    CMP #&05
    BCC AddStageTimeBonusScore
    LDA #&05

AddStageTimeBonusScore:
    JSR AddScoreBCD
    RTS

BeginStageCompleteHold:
    LDA #&3C
    STA StageCompleteTimer
    RTS

DrawStageBonusMultiplier:
    LDA WaveBCD
    CMP #&05
    BCC DrawClampedStageMultiplier
    LDA #&05

DrawClampedStageMultiplier:
    PHA
    LDA #&FC
    STA BCDColourMask
    PLA
    LDY #&0D
    LDX #&15
    JSR DrawBCDValue
    LDA #&F0
    STA BCDColourMask
    LDA WaveBCD
    LDY #&09
    LDX #&0E
    JSR DrawBCDValue
    RTS

DrawBCDValue:
    ; Render one packed-BCD byte as one or two decimal characters using DrawInlineText.
    STX BCDInlineTextParameters
    STY BCDInlineTextParameters+1
    LDY BCDColourMask
    STY BCDInlineTextParameters+2
    PHA
    LDA #&20
    STA BCDTextDigits+1
    LDX #&00
    PLA
    PHA
    AND #&F0
    LSR A
    LSR A
    LSR A
    LSR A
    CLC
    ADC #&30
    STA BCDTextDigits,X
    CMP #&30
    BEQ SkipLeadingZeroAndDrawOnes
    INX

SkipLeadingZeroAndDrawOnes:
    PLA
    AND #&0F
    CLC
    ADC #&30
    STA BCDTextDigits,X
    JSR DrawInlineText

; Inline DrawInlineText parameters/string.
BCDInlineTextParameters:
    EQUB &00,&00,&00
BCDTextDigits:
    EQUB &53,&53,&00
    RTS

UpdateStageCompleteTimer:
    ; StageStartTimer controls the pause between the completed-stage display
    ; and the next wave. When it expires, erase the stage number and call
    ; StartNextStage.
    LDA SoundSequenceCounter
    CMP #&07
    BCC CheckStageStartDelay
    RTS

CheckStageStartDelay:
    LDA StageStartTimer
    BNE TickStageStartDelay
    RTS

TickStageStartDelay:
    DEC StageStartTimer
    CMP #&64
    BNE WaitForStageStartDelay
    JSR DrawStageNumber

WaitForStageStartDelay:
    LDA StageStartTimer
    BEQ EraseStageNumberAndStartWave
    RTS

EraseStageNumberAndStartWave:
    JSR DrawStageNumber
    JMP StartNextStage

DrawStageNumber:
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &0E,&0B
    EQUS "0STAGE"
    EQUB &00
    LDX #&14
    LDA #&30
    STA BCDColourMask
    LDA WaveBCD
    CLC
    SED
    ADC #&01
    CLD
    LDY #&0B
    JMP DrawBCDValue
    RTS

DrawTitleScreenText:
    ; Draw title/attract strings and two copies of sprite 7.
    JSR DrawHighScoreTable
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &0B,&05,&FC
    EQUS "VIDEOS REVENGE"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &09,&08
    EQUS "<RIPPING  REVENGERS"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &05,&1C,&F0
    EQUS "SPACE TO ENTER COMBAT ZONE"
    EQUB &00
    LDA #&0D
    STA ScreenXByte
    LDA #&20
    STA ScreenYLo
    LDA #&07
    JSR DrawXorSprite
    LDA #&37
    STA ScreenXByte
    LDA #&20
    STA ScreenYLo
    LDA #&07
    JSR DrawXorSprite
    RTS
    RTS

UpdatePlayerDeath:
    ; Multi-phase player-death controller.
    ;
    ; &FF: take a snapshot of surviving object types and force palette flash 0.
    ; &FE..&F1: brief lead-in where the player sprite blinks.
    ; &F0: initialise and draw the 32-particle explosion.
    ; &EF..&01: move explosion particles and silently delete one object selected
    ;           by the timer's low six bits each call.
    ; &00: erase remaining particles, decrement lives and either respawn the
    ;      surviving object mix or enter game-over/high-score handling.
    LDA PlayerDeathTimer
    BNE TickPlayerDeathTimer
    RTS

TickPlayerDeathTimer:
    DEC PlayerDeathTimer
    CMP #&FF
    BNE DispatchPlayerDeathPhase
    CMP #&FF
    BNE DispatchPlayerDeathPhase
    LDA #&00
    STA PaletteFlashColour
    JSR SnapshotRemainingObjectCounts

DispatchPlayerDeathPhase:
    LDA PlayerDeathTimer
    CMP #&F0
    BEQ InitialisePlayerExplosion
    BCS BlinkPlayerDuringDeathLeadIn
    JSR UpdatePlayerExplosionParticles
    JMP AdvancePlayerDeathCleanup

BlinkPlayerDuringDeathLeadIn:
    LDA PlayerDeathTimer
    AND #&02
    BEQ AdvancePlayerDeathCleanup
    JSR DrawPlayer

AdvancePlayerDeathCleanup:
    LDA PlayerDeathTimer
    AND #&3F
    TAX
    LDA #&01
    JSR DestroyObjectAndAwardScore
    LDA PlayerDeathTimer
    BEQ FinishPlayerDeath
    RTS

FinishPlayerDeath:
    JSR DrawLives
    SEC
    LDA LivesBCD
    SED
    SBC #&01
    CLD
    STA LivesBCD
    JSR DrawLives
    JSR ResetPlayer
    JSR ClearPlayerDeathTimer
    JSR XorAllPlayerExplosionParticles
    LDA LivesBCD
    BEQ PlayerGameOver
    JMP InitialiseStageObjects

PlayerGameOver:
    LDA #&00
    STA PendingSwarmerCount
    STA PendingBangerCount
    STA SmartBombKeyLatch
    STA ActiveObjectCount
    JSR HandleGameOverAndHighScores
    JSR ResetPlayer
    LDA #&FF
    STA GameInactive
    JSR DrawTitleScreenText
    RTS
    RTS

InitialisePlayerExplosion:
    ; PlayerDeathTimer has just reached &F0. Stop any active sequence, play the
    ; death sounds and initialise 32 fixed-point particles at the player.
    LDA #&00
    STA SoundSequenceCounter
    LDA #&0F
    LDX #&00
    LDY #&00
    JSR OSBYTE; MOS OSBYTE
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &10,&00,&F1,&FF,&07,&00,&25,&00
    JSR PlayInlineSound

; --- DATA: inline OSWORD 7 SOUND parameter block ---
    EQUB &11,&00,&05,&00,&FF,&00,&25,&00
    LDX #&1F

InitialiseNextDeathParticle:
    LDA #&4B
    STA DeathParticleYInverted,X
    LDA PlayerXByte
    STA DeathParticleX,X
    TXA
    PHA
    JSR RandomByte
    TAY
    PLA
    TAX
    TYA
    AND #&7F
    STA DeathParticleYVelocity,X
    TXA
    PHA
    JSR RandomByte
    TAY
    PLA
    TAX
    TYA
    AND #&3F
    PHA
    TXA
    AND #&01
    BEQ StoreDeathParticleXVelocity
    PLA
    EOR #&FF
    PHA

StoreDeathParticleXVelocity:
    PLA
    STA DeathParticleXVelocity,X
    DEX
    BPL InitialiseNextDeathParticle
    JSR XorAllPlayerExplosionParticles
    RTS

UpdatePlayerExplosionParticles:
    ; Erase, advance and redraw all 32 death particles.
    ; Each particle is fixed-point in both axes:
    ;   X = DeathParticleX : DeathParticleXFrac, signed X velocity
    ;   Y = DeathParticleYInverted : DeathParticleYFrac, positive Y velocity
    ; The inverted Y representation makes the initial &4B map to screen Y &B4.
    LDX #&1F

UpdateNextDeathParticle:
    JSR XorPlayerExplosionParticle
    LDA DeathParticleX,X
    CMP #&47
    BCS RedrawNextDeathParticle
    LDA DeathParticleYVelocity,X
    ASL A
    ASL A
    ASL A
    STA DeathParticleWorkLo
    LDA DeathParticleYVelocity,X
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA DeathParticleWorkHi
    CLC
    LDA DeathParticleYFrac,X
    ADC DeathParticleWorkLo
    STA DeathParticleYFrac,X
    LDA DeathParticleWorkHi
    ADC DeathParticleYInverted,X
    STA DeathParticleYInverted,X
    BCC ChooseDeathParticleXSignExtension
    LDA #&FF
    STA DeathParticleX,X
    JMP RedrawNextDeathParticle

ChooseDeathParticleXSignExtension:
    LDY #&00
    TXA
    AND #&01
    BEQ ApplyDeathParticleXVelocity
    LDY #&FF

ApplyDeathParticleXVelocity:
    LDA DeathParticleXVelocity,X
    STA DeathParticleWorkLo
    STY DeathParticleWorkHi
    ASL DeathParticleWorkLo
    ROL DeathParticleWorkHi
    LDA DeathParticleWorkLo
    CLC
    ADC DeathParticleXFrac,X
    STA DeathParticleXFrac,X
    LDA DeathParticleWorkHi
    ADC DeathParticleX,X
    STA DeathParticleX,X
    CMP #&47
    BCC RedrawNextDeathParticle
    LDA #&FF
    STA DeathParticleX,X

RedrawNextDeathParticle:
    JSR XorPlayerExplosionParticle
    DEX
    BPL UpdateNextDeathParticle
    RTS

XorAllPlayerExplosionParticles:
    ; XOR all 32 death particles. Used once after initialisation and once at
    ; the end of the death sequence to remove the remaining particles.
    LDX #&1F

XorNextDeathParticle:
    JSR XorPlayerExplosionParticle
    DEX
    BPL XorNextDeathParticle
    RTS

XorPlayerExplosionParticle:
    ; Draw/erase one four-point death particle by XOR.
    TXA
    PHA
    LDA #&FC
    STA DeathParticlePlotMask
    LDA DeathParticleX,X
    STA ScreenXByte
    LDA DeathParticleYInverted,X
    EOR #&FF
    STA ScreenYLo
    LDA ScreenXByte
    BMI FinishDeathParticleDraw
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA #&55
    AND DeathParticlePlotMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INC ScreenYLo
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA #&FF
    AND DeathParticlePlotMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    LDY #&08
    LDA #&AA
    AND DeathParticlePlotMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y
    INC ScreenYLo
    JSR Mode2ScreenAddressFromXY
    LDY #&00
    LDA #&55
    AND DeathParticlePlotMask
    EOR (ScreenPtrLo),Y
    STA (ScreenPtrLo),Y

FinishDeathParticleDraw:
    PLA
    TAX
    RTS

SnapshotRemainingObjectCounts:
    ; Count surviving active object types into StageScheduleScratch before a
    ; player death.
    ;
    ; The routine explicitly clears only counters 0..5, then scans all active
    ; objects and increments the counter indexed by each object's type. That means
    ; slots 6/7 are NOT reset first: if Spinner/Energy-Balloon counts are already
    ; present in StageScheduleScratch, active type-6/7 objects increment those
    ; existing values rather than replacing them. This is an exact quirk of the
    ; binary and may be deliberate or incidental.
    ;
    ; The resulting scratch table is later consumed by InitialiseStageObjects.
    LDX #&05
    LDA #&00

ClearNextRespawnCount:
    STA StageScheduleScratch,X
    DEX
    BPL ClearNextRespawnCount
    LDY #&1F

CountNextSurvivingObject:
    LDA ObjectType,Y
    ORA ObjectState,Y
    BMI AdvanceSurvivingObjectScan
    LDA ObjectType,Y
    TAX
    INC StageScheduleScratch,X

AdvanceSurvivingObjectScan:
    DEY
    BPL CountNextSurvivingObject
    RTS
    RTS

ResetSoundSequencer:
    ; Stop any active multi-step tune/jingle.
    LDA #&00
    STA SoundSequenceCounter
    RTS

StartSoundSequence:
    ; Start a table-driven three-channel sound sequence, but only when sound is on.
    ;
    ; Entry:
    ;   A = number of 4-byte data steps + 2
    ;   X/Y = low/high address of the first sequence step
    ;
    ; Each step is:
    ;   byte 0 = frame delay
    ;   byte 1 = channel-1 pitch, or &FF for silence
    ;   byte 2 = channel-2 pitch, or &FF
    ;   byte 3 = channel-3 pitch, or &FF
    ;
    ; The +2 counter convention leaves a final 80-frame hold after the last
    ; actual data step. Starting a sequence also flushes all MOS buffers.
    BIT SoundFlags
    BMI InitialiseSoundSequence
    RTS

InitialiseSoundSequence:
    STA SoundSequenceCounter
    STX SoundSequencePtrLo
    STY SoundSequencePtrHi
    LDA #&01
    STA SoundSequenceDelay
    LDA #&0F
    LDX #&00
    LDY #&00
    JMP OSBYTE; OSBYTE &0F,X=0: flush all MOS buffers

StartGameMusic:
    ; 33-step game-start tune. Counter=&23 = 33 data steps + 2.
    LDA #&23
    LDX #<GameStartMusicData
    LDY #>GameStartMusicData
    JMP StartSoundSequence

StartExtraLifeJingle:
    ; 12-step jingle played when an extra life/energy award is granted.
    ; Counter=&0E = 12 data steps + 2; sequence starts.
    LDA #&0E
    LDX #<ExtraLifeJingleData
    LDY #>ExtraLifeJingleData
    JMP StartSoundSequence

; --- DATA: game-start sound sequence ---
GameStartMusicData:
    ; 33 x four-byte steps: delay, pitch ch1, pitch ch2, pitch ch3.
    EQUS "$vVF"
    EQUB &0C
    EQUS "bVF$bVF"
    EQUB &0C,&62,&56,&46,&0C,&6A,&5A,&FF
    EQUB &0C,&72,&5A,&FF,&0C,&76,&5A,&FF
    EQUB &0C,&7E,&5A,&FF,&24,&86,&62,&46
    EQUB &0C,&76,&56,&46,&18,&76,&56,&46
    EQUB &08,&72,&FF,&FF,&08,&76,&FF,&FF
    EQUB &08,&7E,&FF,&FF,&18,&76,&FF,&FF
    EQUB &18,&62,&FF,&FF,&24,&86,&62,&46
    EQUB &0C
    EQUS "vVF$vVF"
    EQUB &0C,&72,&56,&46,&0C,&76,&56,&46
    EQUB &0C,&7E,&76,&56,&0C,&86,&76,&56
    EQUB &0C,&8A,&76,&5A,&24,&9A,&76,&5E
    EQUB &0C,&92,&76,&62,&18,&92,&86,&76
    EQUB &08,&72,&FF,&FF,&08,&76,&FF,&FF
    EQUB &08,&7E,&FF,&FF,&18,&76,&FF,&FF
    EQUB &18,&62,&FF,&FF,&30,&76,&56,&FF

UpdateSoundSequencer:
    ; Frame-driven interpreter for the 4-byte music/jingle steps described above.
    ;
    ; Each main-loop call decrements SoundSequenceDelay. When it expires, the
    ; sequence counter advances. Actual data steps patch the pitch byte of a
    ; common OSWORD 7 SOUND block and play channels 1, 2 and 3 independently.
    ; Pitch &FF suppresses that channel for the step.
    LDA SoundSequenceCounter
    BNE TickSoundSequenceDelay
    RTS

TickSoundSequenceDelay:
    DEC SoundSequenceDelay
    BEQ AdvanceSoundSequenceStep
    RTS

AdvanceSoundSequenceStep:
    DEC SoundSequenceCounter
    BNE CheckSoundSequenceFinalHold
    RTS

CheckSoundSequenceFinalHold:
    LDA SoundSequenceCounter
    CMP #&01
    BNE ReadSoundSequenceStep
    LDA #&50
    STA SoundSequenceDelay
    RTS

ReadSoundSequenceStep:
    LDY #&00
    LDA (SoundSequencePtrLo),Y
    STA SoundSequenceDelay
    INY

PlaySoundSequenceChannel:
    TYA
    PHA
    ORA #&90
    STA SequencedSoundBlock
    LDA (SoundSequencePtrLo),Y
    STA SequencedSoundPitch
    CMP #&FF
    BEQ AdvanceSoundSequenceChannel
    JSR PlaySequencedSound

AdvanceSoundSequenceChannel:
    PLA
    TAY
    INY
    CPY #&04
    BNE PlaySoundSequenceChannel
    CLC
    LDA SoundSequencePtrLo
    ADC #&04
    STA SoundSequencePtrLo
    BCS AdvanceSoundSequencePage
    RTS

AdvanceSoundSequencePage:
    INC SoundSequencePtrHi
    RTS

PlaySequencedSound:
    ; Channel byte and pitch byte are self-modified by the
    ; sequencer before this common OSWORD 7 block is submitted.
    JSR PlayInlineSound

; Inline OSWORD 7 SOUND parameter block.
SequencedSoundBlock:
    EQUB &01,&00,&06,&00
SequencedSoundPitch:
    EQUB &01
    EQUB &00,&FF,&FF
    RTS

; --- DATA: extra-life sound sequence ---
ExtraLifeJingleData:
    ; 12 x four-byte steps: delay, pitch ch1, pitch ch2, pitch ch3.
    EQUB &0A,&30,&FF,&FF,&0A,&38,&FF,&FF
    EQUB &0A,&40,&FF,&FF,&14,&4C,&FF,&FF
    EQUB &0A,&40,&FF,&FF,&14,&4C,&FF,&FF
    EQUB &0A,&60,&FF,&FF,&0A,&68,&FF,&FF
    EQUB &0A,&70,&FF,&FF,&14,&7C,&FF,&FF
    EQUB &0A,&70,&FF,&FF,&3C,&7C,&FF,&FF

    EQUB &60

HighScoreNames:
    ; Eight physical 16-character name records. The initial table doubles as
    ; the game's credits/thank-you list. HighScoreRankOrder determines which
    ; record appears at each displayed rank; the strings themselves are not
    ; shuffled when the ranking changes.
    EQUS "  TOBY BUTLER    TO MY ACE TEAM   TIM  SORRELL    VINCE DARLEY       MIDGE       LAST NOT LEAST JAN PETE DAN JIMVAM MJP SJD MIKE"
HighScoreRankOrder:
    ; One byte per PHYSICAL score/name record: value = current displayed rank.
    ; This indirection lets insertion reorder the table without moving any
    ; 16-byte name strings or 3-byte score records.
    EQUB &00,&01,&02,&03,&04,&05,&06,&07

HighScoreScoresBCD:
    ; Eight physical scores, three packed-BCD bytes each, low/mid/high.
    ; Initial value for every entry is 000100.
    EQUB &00,&01,&00,&00,&01,&00,&00,&01
    EQUB &00,&00,&01,&00,&00,&01,&00,&00
    EQUB &01,&00,&00,&01,&00,&00,&01,&00

DrawHighScoreTable:
    ; Render ranks 1..8. The loop variable is displayed rank 0..7; each row
    ; resolves that rank through HighScoreRankOrder to find its physical score
    ; and name record.
    LDX #&07

DrawNextHighScoreRow:
    TXA
    PHA
    JSR DrawHighScoreRow
    PLA
    TAX
    DEX
    BPL DrawNextHighScoreRow
    RTS

DrawHighScoreRow:
    ; A = displayed rank 0..7. Render its rank number, six-digit score and
    ; sixteen-character name. HighScoreRow is shared by the three helpers.
    STA HighScoreRow
    JSR DrawHighScoreRankNumber
    JSR DrawHighScoreScore
    JSR DrawHighScoreName
    RTS

DrawHighScoreRankNumber:
    ; Draw displayed rank number 1..8 at X=5.
    ; Y = &0B + rank*2, leaving a blank character row between entries.
    ;
    ; The two stores of &F0 into &0D are redundant as machine code but set the
    ; colour mask consumed by DrawBCDValue.
    LDA #&F0
    STA BCDColourMask
    LDA #&F0
    STA BCDColourMask
    LDA HighScoreRow
    PHA
    ASL A
    CLC
    ADC #&0B
    TAY
    PLA
    CLC
    ADC #&01
    LDX #&05
    JMP DrawBCDValue

DrawHighScoreScore:
    ; Resolve displayed rank -> physical score record, unpack its three BCD
    ; bytes into six ASCII digits, then XOR-draw them at X=7.
    ;
    ; The physical record is selected by searching HighScoreRankOrder for the
    ; entry whose value equals HighScoreRow.
    LDA HighScoreRow
    ASL A
    CLC
    ADC #&0B
    STA HighScoreDigitsY
    LDA #&07
    STA HighScoreDigitsX
    LDA #&F0
    STA HighScoreDigitsColour
    LDA HighScoreRow
    LDX #&08

FindScoreRecordForRank:
    DEX
    CMP HighScoreRankOrder,X
    BNE FindScoreRecordForRank
    TXA
    STA HighScoreScratch
    ASL A
    CLC
    ADC HighScoreScratch
    TAX
    INX
    INX
    LDY #&00

ConvertHighScoreBCDByte:
    LDA HighScoreScoresBCD,X
    AND #&F0
    LSR A
    LSR A
    LSR A
    LSR A
    CLC
    ADC #&30
    STA HighScoreDigitsBuffer,Y
    INY
    LDA HighScoreScoresBCD,X
    AND #&0F
    CLC
    ADC #&30
    STA HighScoreDigitsBuffer,Y
    INY
    DEX
    CPY #&06
    BNE ConvertHighScoreBCDByte
    JSR DrawInlineText

; --- DATA: mutable six-digit score DrawInlineText field ---
HighScoreDigitsX:
    EQUB &00
HighScoreDigitsY:
    EQUB &00
HighScoreDigitsColour:
    EQUB &00
HighScoreDigitsBuffer:
    ; Six bytes are overwritten with score digits before drawing. The original
    ; seventh byte is ASCII '0', followed by the zero terminator.
    ; Keeping that otherwise redundant '0' is required for byte-exact rebuild.
    EQUS "AAAAAA0"
    EQUB &00
    RTS

DrawHighScoreName:
    ; Resolve displayed rank -> physical 16-byte name record, copy that name
    ; into the shared mutable text buffer, and fall through to draw it at X=16.
    LDA HighScoreRow
    LDX #&08

FindNameRecordForRank:
    DEX
    CMP HighScoreRankOrder,X
    BNE FindNameRecordForRank
    LDA HighScoreRow
    ASL A
    CLC
    ADC #&0B
    STA MutableNameFieldY
    LDA #&10
    STA MutableNameFieldX
    LDA #&33
    STA MutableNameFieldColour
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #&0F
    TAX
    LDY #&0F

CopyHighScoreNameCharacter:
    LDA HighScoreNames,X
    STA MutableNameBuffer,Y
    DEX
    DEY
    BPL CopyHighScoreNameCharacter

DrawMutableNameField:
    ; XOR-draw the shared 16-character mutable buffer using the x/y/colour
    ; bytes immediately preceding it. It is used both for high-score table
    ; names and for the interactive name-entry field.
    JSR DrawInlineText

; --- DATA: mutable 16-character DrawInlineText field ---
MutableNameFieldX:
    EQUB &00
MutableNameFieldY:
    EQUB &00
MutableNameFieldColour:
    EQUB &00
MutableNameBuffer:
    EQUS "1212121212121212"
    EQUB &00
    RTS

HandleGameOverAndHighScores:
    ; Determine whether the player's six-digit BCD score belongs in the top 8.
    ; The initial STA UnusedHighScoreScratch is a dead store in the game:
    ; the byte is never read later. It is retained exactly as found in the binary.
    ; Compare against displayed ranks from best to worst. If no entry is beaten,
    ; return immediately.
    ;
    ; On qualification, ranks are changed only in HighScoreRankOrder. The
    ; physical record that is pushed to rank 8 becomes the storage slot for the
    ; new score and name, avoiding any bulk movement of 16-byte strings.
    LDA #&FF
    STA UnusedHighScoreScratch
    LDX #&07
    LDX #&FF

FindQualifyingHighScoreRank:
    INX
    JSR CompareScoreAgainstHighScoreRank
    BCC FindQualifyingHighScoreRank
    CPX #&08
    BNE InsertNewHighScore
    RTS

InsertNewHighScore:
    TXA
    PHA
    JSR ToggleHighScoreEntryPrompt
    PLA
    PHA
    STA HighScoreScratch
    LDX #&07

PushLowerRanksDown:
    CMP HighScoreRankOrder,X
    BCS ContinueRankShiftPass1
    INC HighScoreRankOrder,X

ContinueRankShiftPass1:
    DEX
    BPL PushLowerRanksDown
    LDX #&07

MoveExistingEntryAtInsertRank:
    CMP HighScoreRankOrder,X
    BNE ContinueRankShiftPass2
    INC HighScoreRankOrder,X

ContinueRankShiftPass2:
    DEX
    BPL MoveExistingEntryAtInsertRank
    LDY #&08

FindRecordDroppedFromTopEight:
    DEY
    LDA HighScoreRankOrder,Y
    CMP #&08
    BNE FindRecordDroppedFromTopEight
    PLA
    STA HighScoreRankOrder,Y
    TYA
    STA HighScoreScratch
    STA HighScoreRow
    ASL A
    CLC
    ADC HighScoreScratch
    TAX
    LDA ScoreLo
    STA HighScoreScoresBCD,X
    LDA ScoreMid
    STA HighScoreScoresBCD+1,X
    LDA ScoreHi
    STA HighScoreScoresBCD+2,X
    LDA HighScoreRow
    PHA
    JSR EnterHighScoreName
    PLA
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #&0F
    TAX
    LDY #&0F

StoreEnteredNameInHighScoreRecord:
    LDA MutableNameBuffer,Y
    STA HighScoreNames,X
    DEX
    DEY
    BPL StoreEnteredNameInHighScoreRecord
    JSR ToggleHighScoreEntryPrompt
    RTS

CompareScoreAgainstHighScoreRank:
    ; X = displayed rank to compare (0=best .. 7=lowest, 8=end sentinel).
    ;
    ; Locate the physical record for that rank via HighScoreRankOrder and compare
    ; ScoreHi, ScoreMid, ScoreLo in descending significance.
    ;
    ; Returns C set when player score >= that table score. X=8 always returns
    ; C set so the caller's search terminates cleanly.
    CPX #&08
    BNE LocateRecordForComparedRank
    SEC
    RTS

LocateRecordForComparedRank:
    TXA
    LDY #&FF

SearchComparedRankRecord:
    INY
    CMP HighScoreRankOrder,Y
    BNE SearchComparedRankRecord
    STY HighScoreScratch
    TYA
    ASL A
    CLC
    ADC HighScoreScratch
    TAY
    LDA ScoreHi
    CMP HighScoreScoresBCD+2,Y
    BCS CompareHighScoreMiddleByte
    RTS

CompareHighScoreMiddleByte:
    BEQ DoCompareHighScoreMiddleByte
    RTS

DoCompareHighScoreMiddleByte:
    LDA ScoreMid
    CMP HighScoreScoresBCD+1,Y
    BCS CompareHighScoreLowByte
    RTS

CompareHighScoreLowByte:
    BEQ DoCompareHighScoreLowByte
    RTS

DoCompareHighScoreLowByte:
    LDA ScoreLo
    CMP HighScoreScoresBCD,Y
    RTS

EnterHighScoreName:
    ; Interactive 16-character high-score name editor.
    ;
    ; Game play normally polls individual keys directly, so keyboard interrupts
    ; can be disabled. Name entry needs the MOS keyboard input buffer: OSBYTE
    ; &B2 is therefore used to enable keyboard interrupts for the editor and
    ; disable them again afterwards.
    ;
    ; A blank 16-character field is XOR-drawn at text position (10,12). The
    ; surrounding 64x8 logical-pixel rectangle is highlighted by XORing screen
    ; bytes &4EA0..&4F9F with &3C. While waiting for RETURN, the starfield keeps
    ; moving and the editor is serviced once per vertical sync.
    LDA #&B2
    LDX #&FF
    LDY #&00
    JSR OSBYTE; OSBYTE &B2: enable keyboard interrupts
    JSR ToggleNameEntryHighlight
    LDY #&0F
    LDA #&20

ClearNameEntryBuffer:
    STA MutableNameBuffer,Y
    DEY
    BPL ClearNameEntryBuffer
    LDA #&00
    STA NameEntryLength
    LDA #&0C
    STA MutableNameFieldY
    LDA #&0A
    STA MutableNameFieldX
    LDA #&CC
    STA MutableNameFieldColour
    JSR DrawMutableNameField

HighScoreNameEntryLoop:
    JSR ScrollStarfieldOneStep
    JSR PollHighScoreNameKey
    PHA
    LDA #&13
    JSR OSBYTE; OSBYTE &13: wait for vertical sync
    PLA
    CMP #&0D
    BNE HighScoreNameEntryLoop
    JSR DrawMutableNameField
    LDA #&B2
    LDX #&00
    LDY #&00
    JSR OSBYTE; OSBYTE &B2: disable keyboard interrupts
    JMP ToggleNameEntryHighlight

PollHighScoreNameKey:
    ; Non-blocking keyboard-buffer poll for the high-score editor.
    ;
    ; OSBYTE &CA writes keyboard-status byte &EF, effectively forcing the
    ; CAPS-LOCK/SHIFT state used here for uppercase input. OSBYTE &81 with a
    ; zero timeout then reads one buffered key if available.
    ;
    ; Accepted input:
    ;   RETURN (&0D)  finish
    ;   DELETE (&7F)  erase previous character
    ;   SPACE         append space
    ;   A..Z          append uppercase letter
    ;
    ; Maximum length is 16. Before and after a modification the field is
    ; XOR-drawn, so the same routine erases the old string and draws the new one.
    ; Returns the key code in A so EnterHighScoreName can recognise RETURN.
    LDA #&CA
    LDX #&EF
    LDY #&00
    JSR OSBYTE; OSBYTE &CA: force keyboard status to &EF
    LDA #&81
    LDX #&00
    LDY #&00
    JSR OSBYTE; OSBYTE &81: read key with zero timeout
    BCC ValidateNameEntryKey
    RTS

ValidateNameEntryKey:
    TXA
    CMP #&00
    BNE CheckNameEntryReturn
    RTS

CheckNameEntryReturn:
    CMP #&0D
    BNE CheckNameEntryDelete
    RTS

CheckNameEntryDelete:
    CMP #&7F
    BEQ DeleteNameEntryCharacter
    CMP #&20
    BEQ AppendNameEntryCharacter
    CMP #&41
    BCS CheckNameEntryUpperBound
    RTS

CheckNameEntryUpperBound:
    CMP #&5B
    BCC AppendNameEntryCharacter
    RTS

AppendNameEntryCharacter:
    LDX NameEntryLength
    CPX #&10
    BNE RedrawNameBeforeAppend
    RTS

RedrawNameBeforeAppend:
    PHA
    JSR DrawMutableNameField
    LDX NameEntryLength
    PLA
    STA MutableNameBuffer,X
    JSR DrawMutableNameField
    INC NameEntryLength
    RTS

DeleteNameEntryCharacter:
    LDX NameEntryLength
    BNE EraseLastNameEntryCharacter
    RTS

EraseLastNameEntryCharacter:
    DEC NameEntryLength
    JSR DrawMutableNameField
    LDX NameEntryLength
    LDA #&20
    STA MutableNameBuffer,X
    JMP DrawMutableNameField

ToggleHighScoreEntryPrompt:
    ; XOR-toggle the congratulatory/name-entry instructions:
    ;   WELL DONE ALIEN SMASHER
    ;   YOU SCORED IN THE TOP EIGHT
    ;   PLEASE TYPE IN YOUR NAME
    ;
    ; If ScoreHi is non-zero (score >= 10000), also toggle:
    ;   GREAT SCORE KEEP AT IT
    ;
    ; HandleGameOverAndHighScores calls this once before insertion/name entry and
    ; again afterwards, so the same text routine both displays and removes it.
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&05,&FC
    EQUS "WELL DONE ALIEN SMASHER"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &05,&07,&F0
    EQUS "YOU SCORED IN THE TOP EIGHT"
    EQUB &00
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &07,&09,&CF
    EQUS "PLEASE TYPE IN YOUR NAME"
    EQUB &00
    LDA ScoreHi
    BEQ FinishHighScoreEntryPrompt
    JSR DrawInlineText

; --- DATA: inline DrawInlineText parameters/string ---
    EQUB &08,&0E,&FC
    EQUS "GREAT SCORE KEEP AT IT"
    EQUB &00

FinishHighScoreEntryPrompt:
    RTS

ToggleNameEntryHighlight:
    ; XOR a 256-byte MODE 2 rectangle at &4EA0..&4F9F with &3C.
    ;
    ; &4EA0 is character row 12, byte-column 20: exactly the screen position of
    ; the 16-character name field at text coordinates (10,12). 256 contiguous
    ; bytes represent 32 MODE 2 byte-columns x 8 scanlines = 64 logical pixels
    ; x 8 pixels. Calling this twice restores the original screen.
    LDY #&00

InvertNameEntryHighlightByte:
    LDA &4EA0,Y
    EOR #&3C
    STA &4EA0,Y
    DEY
    BNE InvertNameEntryHighlightByte
    RTS

; --- DATA: trailing data/padding ---
    EQUB &01,&00,&FC,&00,&00,&00,&00,&00
    EQUB &00,&02
