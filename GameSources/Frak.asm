; =============================================================================
; Frak! (BBC Micro, Aardvark Software, 1984)
; Stage 10 documented semantic reconstruction - exact multi-ORG baseline
; =============================================================================
;
; SOURCE LAYOUT
; -------------
; This file now describes Frak's actual sparse runtime memory map directly.
; There is no copy-protection decryptor, Frak-specific relocation routine,
; packed-image relocation table, relocation metadata, or in-game code mover.
;
; Each genuine runtime range is assembled through a named REGION_* origin.
; At the historical settings these are the original BBC Micro addresses.  Code
; and data references inside Frak use labels rather than numeric historical
; addresses, so regions can be moved for relocation analysis without leaving
; stale calls/pointers behind.  The holes between ranges are intentional and
; are NOT emitted as zero-filled data. BBC 6502 Web Assembler v1.9+ packs the
; emitted segments for loading, stages them safely, then installs each segment
; at its ORG address before entering start.
;
; The final one-shot initialisation routine is placed at &3000, immediately above
; the original &1FFD-&2FFF sprite/data area.  &3000 is screen RAM once Frak has
; entered its display code, so this transient startup code may be overwritten
; after it jumps to the genuine game entry at &0380.
;
; BBC BASIC loader setup (metadata only; emits no 6502 bytes):
; @basic *FX200,2
; @basic *TAPE
;
; Boot/run entry point: start
;
; IMPORTANT
; ---------
; "Save binary" still represents the whole sparse address span as a conventional
; flat file and therefore fills holes.  "Save boot disk" / "Run in jsbeeb" do
; not: the loader uses the assembler's emitted segment list and copies only the
; actual Frak bytes to their ORG addresses.
;
; PROGRAM FLOW
; ------------
;   boot loader installs the sparse ORG segments
;       -> start / GameInitialise (&3000, one-shot and disposable)
;       -> RuntimeGameEntry (&0380, cast/credits screen)
;       -> GameStartTitleLoop / TitleStartSequence (attract/high-score sequence)
;       -> NewGame -> StartScreen
;       -> MainGameFrame: player -> death/completion -> keys/timer -> hazards
;       -> ScreenComplete advances BaseScreen A/B/C; every wrap advances the
;          0..7 TransformCycle, giving 24 screen/transform combinations.
;
; CODE-READING CONVENTIONS
; ------------------------
; SharedScratch/SharedWork/SharedIndirect names are not unresolved variables:
; they are bytes deliberately reused by unrelated routines at different times.
; Context-specific aliases immediately below show the proven meaning at each use.
; Numeric addresses that remain are BBC MOS, hardware or intentional runtime
; workspace contracts rather than unidentified references back into the game.
;
; MODIFICATION NOTES
; ------------------
; Search this file for the exact prefix "; MOD:".  Those comments mark values
; whose gameplay effect has been traced well enough to be useful modification
; points.  They are comments only and do not change the original bytes.
; Values without a MOD note may be tightly coupled to screen geometry, record
; formats, workspace layout or self-modifying code and should not be treated as
; simple tuning parameters merely because they are constants.
;
; Fixed BBC MOS/hardware/runtime symbols
; --------------------------------------
; Runtime region origins.  These are kept as named constants rather than being
; embedded in code operands.  They describe the historical Frak memory map and
; make synthetic relocation testing straightforward.
REGION_RENDERER_STUB     = &01A4
REGION_TITLE             = &0380
REGION_SOUND_LEVELS      = &0507
REGION_HIGH_SCORES       = &0880
REGION_MODE1_MASKS       = &0A00
REGION_CORE              = &0B00
REGION_ENGINE            = &0D01
REGION_SPRITES           = &1FFD
REGION_STARTUP           = &3000

OSWRCH                 = &FFEE
OSWORD                 = &FFF1
OSBYTE                  = &FFF4
OSCLI                   = &FFF7
EVENTV                  = &0220
IRQ1V                   = &0204
KEYV                    = &0228
CRTC_ADDRESS            = &FE00
CRTC_DATA               = &FE01
SYSTEM_VIA_IER          = &FE4E
USER_VIA_T1CL           = &FE64
USER_VIA_T1CH           = &FE65
USER_VIA_T2CL           = &FE68
USER_VIA_T2CH           = &FE69
USER_VIA_ACR            = &FE6B
USER_VIA_IFR            = &FE6D
USER_VIA_IER            = &FE6E

; Parallel object workspace.  The original game deliberately places this at
; &0368 so the arrays eventually overwrite disposable title/cast code.  All
; engine references are symbolic, so the workspace can be moved as a unit for
; analysis provided another suitable RAM area exists.
OBJECT_WORKSPACE_BASE   = &0368
OBJECT_SLOT_COUNT       = 123
DYNAMIC_MOTION_SLOTS    = 23
ObjectX                 = OBJECT_WORKSPACE_BASE
ObjectY                 = ObjectX+OBJECT_SLOT_COUNT
ObjectSprite            = ObjectY+OBJECT_SLOT_COUNT
ObjectDX                = ObjectSprite+OBJECT_SLOT_COUNT
ObjectDY                = ObjectDX+DYNAMIC_MOTION_SLOTS

; Deliberately fixed BBC/Frak workspace outside emitted source segments.
ScrollBackingBuffer     = &0900
VDUScreenBaseLo         = &0350
VDUScreenBaseHi         = &0351
HardwareStackPage       = &0100
MOSWorkspaceClearBase   = &02A1
EnginePrefixState       = REGION_ENGINE-1

; Frequently used zero-page game state.
; &1E-&20 are saved/restored by the recursive composite-sprite walker.
; They are scratch state, not object type constants, despite &1E also being the
; numeric Poglet sprite/type ID elsewhere in the game.
ZeroPageBase           = &00
SpriteTraversalCount   = &1E
SpriteTraversalPtrLo   = &1F
SpriteTraversalPtrHi   = &20
CurrentSpriteX          = &11
CurrentSpriteY          = &12
InkeyCode               = &21
ScrollCopyPtrLo         = &24
ScrollCopyPtrHi         = &25
SharedScratch26         = &26
RandomMask              = &27
RandomState             = &28
SharedIndirectLo        = &29
SharedIndirectHi        = &2A
MusicInhibitFlag             = &2F
WalkAnimationPhase              = &32
SharedAnimationCounter = &34
SavedObjectIndex        = &33
ScoreLo                 = &38
ScoreMid                = &39
ScoreHi                 = &3A
Lives                   = &3B
BaseScreen              = &3C
TransformCycle          = &3D
SharedWorkLo            = &3F
SharedWorkHi            = &40
HighScoreEntryChar                  = &41
HighScoreWorkCounter    = &42
TickCounter             = &44
SoundMutedFlag            = &4B
SavedKeyVLo            = &4C
SavedKeyVHi            = &4D
SavedIRQ1VLo            = &4E
SavedIRQ1VHi            = &4F
PlayerAirborneFlag                 = &53
PlayerClimbingFlag                 = &54
YoyoActiveFlag                 = &55
PlayerHorizontalStep          = &57
PlayerFrameSprite         = &58
CollidedObjectSlot         = &64
LevelStreamLo           = &6D
LevelStreamHi           = &6E
ScrollRefreshRequestFlag            = &70
LastTick                = &71
VerticalFlipFlag             = &74
KeysRemainingMinusOne   = &7A
PlayerDeadFlag        = &7B
TitleRandomSprite       = &7C
TitleRandomDrawCount    = &7D
SavedAbortStackPtr      = &7E
MaskLookupPtrLo         = &80
MaskLookupPtrHi         = &81
TimeLoBCD               = &82
TimeHiBCD               = &83
CountdownDivider        = &84
CountdownFlags          = &85
ControlScheme               = &86
SelectedControlScheme              = &87
HazardCounter           = &88
HazardReload            = &89
MusicDurationCounter   = &91
PauseFlag               = &92
MosCallInProgressFlag              = &93

; Collision/object/render workspace.  These locations are deliberately reused
; by several subsystems; names below describe their dominant live meaning.
CollisionLeft           = &45
CollisionRight          = &46
CollisionTop            = &47
CollisionBottom         = &48
ScrollDirectionFlags           = &52
CollisionMask           = &5A
ActiveQueueDescriptor   = &5B
LevelQueueDescriptor    = &5C
JumpInputHistory        = &5D
SpriteOperationMode     = &5E
SpriteCollisionDrawFlag = &5F
SharedObjectCount       = &60
YoyoBaseX               = &65
YoyoSegmentPhase        = &66
YoyoExtensionCount      = &67
PendingObjectSprite     = &68
PendingObjectX          = &69
PendingObjectY          = &6A
LevelThemeMapLo         = &6B
LevelThemeMapHi         = &6C
PrimitiveBoundsByteCount    = &6F
SpriteBoundsMinX        = &75
SpriteBoundsMaxX        = &76
SupportObjectSlot       = &77
YoyoAnimationIndex      = &78
YoyoExtensionDirection  = &79
CurrentTuneOffsetSlot  = &8A
TuneOffsetScreenA       = &8B
TuneOffsetScreenB       = &8C
TuneOffsetScreenC       = &8D
TuneOffsetDeath         = &8E
TuneOffsetComplete      = &8F
TuneStreamPosition      = &90
CollidedQueueDescriptor = &94
ScanQueueDescriptor     = &95

; Context-specific aliases for deliberately shared zero-page scratch bytes.
RandomLimit              = SharedScratch26
JoystickScratch          = SharedScratch26
LevelThemeCode           = SharedScratch26
LevelObjectRemaining     = SharedScratch26
RequestedObjectType      = SharedScratch26
HighScoreInsertOffset    = SharedScratch26
TimeBonusRepeatCounter   = SharedWorkLo
ScreenClearPtrLo         = SharedWorkLo
ScreenClearPtrHi         = SharedWorkHi
LevelVariantBase         = SharedWorkLo
LevelQueueEndSlot        = SharedWorkHi
HighScoreNameOffset      = SharedWorkLo
MovementObjectSlot       = SharedScratch26
PreviousScoreMid         = SharedScratch26
SavedSpriteIndex         = SharedScratch26
PrimitiveLeftScratch     = SharedScratch26
LadderProbeObjectSlot     = SharedScratch26
LadderSavedX              = SharedScratch26
LadderSideRelationBits    = SharedScratch26

; &29/&2A are a deliberately shared indirect-pointer pair.
InlineStreamPtrLo         = SharedIndirectLo
InlineStreamPtrHi         = SharedIndirectHi
TypeDispatchPtrLo         = SharedIndirectLo
TypeDispatchPtrHi         = SharedIndirectHi
TitleRandomScratch        = SharedIndirectLo

; &3F/&40 are general two-byte workspace with non-overlapping lifetimes.
CrtcStartAddressLo        = SharedWorkLo

; Other shared single-byte work areas with context-specific meanings.
HighScoreRankNumber       = HighScoreWorkCounter
HighScoreInitialsRemaining = HighScoreWorkCounter
YoyoKnockbackFramesRemaining = SharedAnimationCounter
TransitionFramesRemaining = SharedAnimationCounter
HighScoreRowIndex         = SharedObjectCount
MatchedObjectCount        = SharedObjectCount
RenderCallerObjectSlot   = SavedObjectIndex
CollisionSourceObjectSlot = SavedObjectIndex


; Queue descriptor offsets (&0B00 + offset) and collision-mask meanings.
QUEUE_TROGG             = &00
QUEUE_DAGGERS           = &03
QUEUE_BALLOONS          = &06
QUEUE_COLLECTIBLES      = &09
QUEUE_MONSTERS          = &0C
QUEUE_FLOORS            = &0F
QUEUE_LADDERS           = &12
QUEUE_DESCRIPTOR_STRIDE  = 3
QUEUE_DESC_FIRST_SLOT    = 0
QUEUE_DESC_COLLISION     = 1
QUEUE_DESC_TAG           = 2
QUEUE_DESC_END_SLOT      = 3
COLLIDE_NONE            = &00
COLLIDE_PLAYER_HAZARD   = &01
COLLIDE_FLOOR           = &02
COLLIDE_LADDER          = &04
COLLIDE_YOYO            = &08
COLLIDE_COLLECTIBLE     = &10
COLLIDE_YOYO_DARK       = &80
COLLIDE_RESERVED_40       = &40  ; present on collectible/monster descriptors; no live caller selects bit 6 alone

TROGG_FIRST_SLOT        = 0
DAGGER_FIRST_SLOT       = 3
BALLOON_FIRST_SLOT      = 13
COLLECTIBLE_FIRST_SLOT  = 23
MONSTER_FIRST_SLOT      = 38
FLOOR_FIRST_SLOT        = 48
LADDER_FIRST_SLOT       = 93
OBJECT_SLOT_END         = OBJECT_SLOT_COUNT
LevelObjectSprite       = &35

; BBC negative-INKEY internal key numbers used by Frak's documented controls.
; MOD: Change the KEY_* negative-INKEY values below to remap Frak controls.
KEY_ESCAPE              = &8F
KEY_UNFREEZE_COPY       = &96
KEY_DOWN_QUESTION       = &97     ; / key position; ? when shifted
KEY_LEFT_Z              = &9E
KEY_FREEZE_DELETE       = &A6
KEY_SOUND_ON_S          = &AE
KEY_YOYO_RETURN         = &B6
KEY_UP_STAR             = &B7     ; :/* key position
KEY_RIGHT_X             = &BD
KEY_QUIET_Q             = &EF

KEY_START_SPACE          = &9D

; Game-state values and timing constants.
CONTROL_KEYBOARD         = 0
CONTROL_JOYSTICK         = 1
COUNTDOWN_RUNNING        = &00
COUNTDOWN_SECOND_PENDING = &FF
COUNTDOWN_STOPPED        = &40
PAUSE_RUNNING            = &00
PAUSE_ACTIVE             = &FF
SCROLL_NONE              = &00
SCROLL_LEFT              = &40
SCROLL_RIGHT             = &80
PLAYER_STEP_RIGHT        = &01
PLAYER_STEP_LEFT         = &FF
; MOD: Player update cadence. Lower = Trogg movement/physics updates more often; higher = slower.
PLAYER_UPDATE_DIVISOR    = 4
; MOD: In-game clock divisor. &32=50 VSync ticks = one real second on a 50 Hz BBC; lower runs the clock faster.
COUNTDOWN_TICKS_PER_SEC  = &32             ; 50 Hz event ticks
; MOD: Starting lives. Increase this number to start a new game with more lives.
INITIAL_LIVES            = 3
BASE_SCREEN_COUNT        = 3
TRANSFORM_MASK           = &07
; MOD: Hazard interval base. Spawn reload is (this - TransformCycle)*4; larger = fewer balloons/daggers. Keep above max cycle 7.
HAZARD_BASE_RELOAD       = &0B
; MOD: Extra hazard aggression after the timer reaches 0. Larger reduction = shorter post-timeout spawn interval; avoid underflow.
HAZARD_EXPIRED_REDUCTION = &0A
; MOD: Initial delay on a newly spawned balloon/dagger. Lower = it starts moving sooner.
DYNAMIC_SPAWN_DELAY      = &14

; Joystick/ADC conventions used by the control readers.
JOYSTICK_FIRE_SELECTOR   = 0
JOYSTICK_X_CHANNEL       = 1
JOYSTICK_Y_CHANNEL       = 2
; MOD: Joystick dead-zone thresholds. Move LOW/HIGH toward the centre for more sensitive analogue control.
JOYSTICK_LOW_THRESHOLD   = &64
JOYSTICK_HIGH_THRESHOLD  = &9C
JOYSTICK_FIRE_MASK       = &01

; BBC MOS reason codes used by Frak.
OSBYTE_SET_FLASH_MARK    = &09
OSBYTE_SET_FLASH_SPACE   = &0A
OSBYTE_ENABLE_EVENT      = &0E
OSBYTE_FLUSH_BUFFER      = &15
OSBYTE_REFLECT_LEDS      = &76
OSBYTE_READ_ADC          = &80
OSBYTE_INKEY             = &81
OSBYTE_ADC_8BIT_MODE     = &BE
OSBYTE_KEYBOARD_STATUS   = &CA
OSWORD_SOUND             = &07
OSWORD_ENVELOPE          = &08
EVENT_VERTICAL_SYNC      = 4
SOUND_CHANNEL_YOYO       = &0011
SOUND_CHANNEL_MOVE       = &0012
SOUND_CHANNEL_MUSIC      = &0013
SOUND_ENVELOPE_MUSIC     = 1
SOUND_ENVELOPE_MOVE      = 2
SOUND_ENVELOPE_YOYO_HIT  = 3
SOUND_ENVELOPE_COLLECT   = 4
SOUND_DURATION_DEFAULT   = &00FF

; CRTC registers used when moving the hardware display origin.
CRTC_SCREEN_START_HI     = &0C
CRTC_SCREEN_START_LO     = &0D
BBC_COLOUR_BLACK          = 0
BBC_COLOUR_RED            = 1
BBC_COLOUR_GREEN          = 2
BBC_COLOUR_YELLOW         = 3
BBC_COLOUR_BLUE           = 4
BBC_COLOUR_MAGENTA        = 5
BBC_COLOUR_CYAN           = 6
BBC_COLOUR_WHITE          = 7

; Music-byte format.  Bits 2-6 are pitch, bits 0-1 are the duration code and
; bit 7 is the end/loop marker consumed by MusicStep.
MUSIC_DURATION_MASK      = &03
MUSIC_PITCH_MASK         = &7C
MUSIC_END_FLAG           = &80

; Packed-BCD scoring/time values.  DrawStatus appends a trailing zero to the
; three BCD score bytes, therefore one score unit here represents ten points.
; MOD: Key score in packed BCD units of 10 displayed points. &50 = 500 points.
SCORE_KEY_BCD            = &50             ; 500 points
; MOD: Gem score in packed BCD units of 10 displayed points. &15 = 150 points.
SCORE_GEM_BCD            = &15             ; 150 points
; MOD: Yo-yo monster-hit score. &25 = 250 points.
SCORE_MONSTER_BCD        = &25             ; 250 points
; MOD: Light-bulb time bonus in packed BCD seconds. &10 adds 10 seconds.
BULB_TIME_BONUS_BCD      = &10             ; ten seconds
BCD_SECONDS_PER_MINUTE   = &60
BCD_LAST_SECOND          = &59
; MOD: Screen-complete time-to-score multiplier. Lower reduces the remaining-time bonus; &0A repeats the conversion ten times.
TIME_BONUS_REPEAT_COUNT  = &0A

; Object/sprite sentinels and compact data-format constants.
OBJECT_EMPTY             = &FF
SPRITE_HIDDEN            = &FF
LEVEL_VARIANT_MASK       = &07
LEVEL_QUEUE_END          = &00
LEVEL_END                = &FF
THEME_LOOKUP_RECORD_SIZE = 3
THEME_LOOKUP_PTR_LO      = 1
THEME_LOOKUP_PTR_HI      = 2
TYPE_DISPATCH_RECORD_SIZE = 3
TYPE_DISPATCH_HANDLER_LO = 1
TYPE_DISPATCH_HANDLER_HI = 2
SPRITE_MIRROR_FLAG       = &80
SPRITE_WIDTH_MASK        = &7F
SPRITE_DESCRIPTOR_COUNT  = &5C             ; 92 descriptor entries

; Object rendering modes passed to ProcessSprite.  Bit 7 selects erase pixel
; operators; bit 6 requests a collision scan after the render traversal.
OBJECT_RENDER_DRAW              = &00
OBJECT_RENDER_DRAW_AND_COLLIDE  = &40
OBJECT_RENDER_ERASE             = &80
OBJECT_RENDER_ERASE_AND_COLLIDE = &C0
OBJECT_RENDER_COLLISION_BIT     = &40
OBJECT_RENDER_ERASE_BIT         = &80

; Recursive sprite traversal modes are word offsets into
; SpriteTraversalReturnTable.  Primitive pixel operators are likewise word
; offsets into PixelOperationTable.
SPRITE_TRAVERSE_BOUNDS          = 0
SPRITE_TRAVERSE_COLLISION       = 2
SPRITE_TRAVERSE_RENDER          = 4
COMPOSITE_CHILD_RECORD_SIZE     = 3
COMPOSITE_CHILD_SPRITE_OFFSET   = 0
COMPOSITE_CHILD_X_OFFSET        = 1
COMPOSITE_CHILD_Y_OFFSET        = 2
PRIMITIVE_BOUNDS_RECORD_SIZE    = 4
PIXEL_OP_MASKED_FORWARD         = 0
PIXEL_OP_MASKED_REVERSE         = 2
PIXEL_OP_SOLID                  = 4
PIXEL_OP_ERASE_TABLE_OFFSET     = 6

; Dynamic hazard geometry/speeds.
; MOD: Balloon vertical movement step. Larger = balloons rise faster each movement update.
BALLOON_Y_STEP           = &06
BALLOON_DESPAWN_Y        = &F0
; MOD: Dagger vertical movement step. Larger = daggers descend faster each movement update.
DAGGER_Y_STEP            = &02
DAGGER_MIN_Y             = &14
BALLOON_SPAWN_Y          = &08
DAGGER_SPAWN_Y           = &FA
DAGGER_SPAWN_X_SPAN      = &28
DAGGER_SPAWN_X_OFFSET    = &32
BALLOON_SPAWN_X_SPAN     = &50

; Yo-yo/player slots and limits.
TROGG_SLOT               = 0
YOYO_STRING_SLOT         = 1
YOYO_HEAD_SLOT           = 2
YOYO_MIN_EXTENSION       = &05
; MOD: Maximum yo-yo string extension. Increase for greater reach; keep descriptor/string-frame limits in mind.
YOYO_MAX_EXTENSION       = &0B
YOYO_RIGHT_LIMIT         = &C8
; MOD: Number of knockback animation frames after the yo-yo hits a monster.
YOYO_KNOCKBACK_FRAMES    = 5
; MOD: Horizontal knockback distance per knockback frame; larger throws a hit monster farther.
YOYO_KNOCKBACK_STEPS     = 8
YOYO_VERTICAL_OFFSET     = &0B
YOYO_HEAD_X_OFFSET       = 2
CLIMB_CORRECTION_RANDOM_MAX = 2

; Trogg-specific animation/physics constants recovered from the movement state
; machines.  ObjectDY is signed: the initial positive jump impulse is reduced
; once per update until it becomes negative (falling).
SPRITE_TROGG_CLIMB_A       = &13
SPRITE_TROGG_CLIMB_B       = &14
SPRITE_TROGG_YOYO_RIGHT    = &3C
SPRITE_TROGG_YOYO_LEFT     = &3D
CLIMB_SPRITE_TOGGLE_MASK   = &07
; MOD: Initial upward jump velocity. Larger positive values produce a higher/longer jump.
PLAYER_INITIAL_JUMP_DY     = &05
PLAYER_Y_CEILING           = &DE
; MOD: Fatal-fall threshold, signed &F9=-7. Lower/more-negative threshold permits faster falls before death.
PLAYER_MAX_SAFE_FALL_DY    = &F9             ; signed -7; faster landings kill
PLAYER_LANDING_Y_ADJUST    = &05
PLAYER_X_MIN               = &04
PLAYER_X_MAX_EXCLUSIVE     = &C4
SCROLL_LEFT_TRIGGER_MIN    = &28
SCROLL_LEFT_TRIGGER_MAX    = &9F             ; exclusive
SCROLL_RIGHT_TRIGGER_MIN   = &29
SCROLL_RIGHT_TRIGGER_MAX   = &A0             ; exclusive

; Text/high-score format.
HIGH_SCORE_COUNT         = 6
HIGH_SCORE_RECORD_SIZE   = 6
HIGH_SCORE_INITIALS      = 3
HIGH_SCORE_SCORE_HI       = 3
HIGH_SCORE_SCORE_MID      = 4
HIGH_SCORE_SCORE_LO       = 5
HIGH_SCORE_TABLE_BYTES    = HIGH_SCORE_COUNT*HIGH_SCORE_RECORD_SIZE
HIGH_SCORE_LAST_RECORD    = (HIGH_SCORE_COUNT-1)*HIGH_SCORE_RECORD_SIZE
HIGH_SCORE_LAST_BYTE      = HIGH_SCORE_TABLE_BYTES-1
HIGH_SCORE_ACCEPT_DELAY   = &14
HIGH_SCORE_RETRY_DELAY    = &05
HIGH_SCORE_FINISH_DELAY   = &50
ASCII_BACKSPACE          = &08
ASCII_SPACE              = &20
ASCII_ZERO               = &30
ASCII_A                  = &41
ASCII_TILDE              = &7E
ASCII_COLON               = &3A
ASCII_COMMA               = &2C
INLINE_STREAM_END        = &EA

SOUND_BUFFER_FIRST       = 4
SOUND_BUFFER_END         = 9              ; exclusive
PRNG_INCREMENT           = &63
PRNG_TOP_BIT             = &80
; MOD: Hazard mix uses RandomUpToA(N): result 0=dagger, non-zero=balloon. N=3 gives 25% daggers / 75% balloons.
HAZARD_RANDOM_MAX        = 3
PLAYER_WALK_FRAME_COUNT  = 4
PLAYER_WALK_FRAME_LAST   = PLAYER_WALK_FRAME_COUNT-1
YOYO_HEAD_FRAME_COUNT    = 4
VERTICAL_INPUT_STEP      = 3
STARTUP_SAFE_STACK_TOP   = &A2
GAME_ZERO_PAGE_LAST      = &97
TITLE_RANDOM_SPRITE_MAX  = 3               ; RandomUpToA => four table entries
; MOD: Number of random title-screen sprite placements before the transition sequence.
TITLE_RANDOM_DRAW_COUNT  = &7D
TITLE_CLIP_LEFT          = &0C
TITLE_CLIP_RIGHT         = &44
TITLE_TRANSITION_DELAY   = &4B
TITLE_FINAL_Y            = &52
TITLE_FINAL_WAIT         = &FA
; MOD: Cast/credits timeout. Each chunk is 256 VSync ticks (~5.12 s), so 7 is ~35.8 s.
TITLE_TIMEOUT_CHUNKS     = 7               ; seven * 256 tick waits
WAIT_256_TICKS           = &00             ; WaitFramesOrInput treats zero as 256 via Y wrap
TRANSITION_FRAME_DELAY   = &04
TRANSITION_TROGG_SLOT     = 0
TRANSITION_SCRUBBLY_SLOT  = 1
TRANSITION_TROGG_SEQUENCE_INDEX    = 1
TRANSITION_SCRUBBLY_SEQUENCE_INDEX = 6
TRANSITION_Y             = &52
TRANSITION_TITLE_FRAMES  = &1F
SCREEN_COMPLETE_FRAMES   = &3C
; MOD: Delay after player death before lives/restart handling, in 50 Hz game ticks.
PLAYER_DEATH_DELAY_TICKS = &82
CONTROL_UNSELECTED       = &FF
LADDER_PROBE_BOTTOM_OFFSET = &0E
LADDER_PROBE_HEIGHT        = &1E
SIGNED_UNIT_FLIP_MASK      = &FE
PLAYER_FLOOR_PROBE_DY_LIMIT = &F6           ; signed -10; collision probe threshold
HIGH_SCORE_SPACING_TABS    = &0B
TITLE_RANDOM_CHAR_SEED_1   = &63
TITLE_RANDOM_CHAR_SEED_2   = &2A
TITLE_RANDOM_CHAR_SEED_3   = &F7
MODE1_PREVIOUS_ROW_LOW_DELTA  = &78
MODE1_PREVIOUS_ROW_HIGH_DELTA = &02
MODE1_NEGATIVE_X_HI_ADJUST     = &07
STARTUP_TRAVERSAL_COUNT_SEED = &2A
STARTUP_TRAVERSAL_PTR_LO_SEED = &C8
STARTUP_TRAVERSAL_PTR_HI_SEED = &D4
; MOD: Initial PRNG seed. Changing it alters the repeatable starting random sequence/timing-dependent hazard/title choices.
STARTUP_RANDOM_SEED           = &30
ENGINE_PREFIX_INITIAL_STATE   = &40
MOS_WORKSPACE_CLEAR_LAST      = &0F
OSBYTE_KEYBOARD_STATUS_X      = &20
OSBYTE_KEYBOARD_STATUS_Y      = &CF
OSBYTE_ADC_8BIT_X             = &08
OSBYTE_FLASH_MARK_X           = &28
OSBYTE_FLASH_SPACE_X          = &14
USER_VIA_IER_INITIAL          = &E0
USER_VIA_ACR_INITIAL          = &40
SYSTEM_VIA_IER_INITIAL        = &01
VDU_BELL                 = &07
VDU_BACKSPACE            = &08
VDU_CLEAR_TEXT           = &0C
VDU_COLOUR               = &11
VDU_PALETTE              = &13
VDU_MODE                 = &16
VDU_DEFAULT_WINDOWS      = &1A
VDU_TEXT_WINDOW          = &1C
VDU_HOME                 = &1E
VDU_TAB                  = &1F
VDU_CURSOR_RIGHT         = &09

; MODE 1 geometry and CRTC/display-ring constants.  One horizontal byte-column
; consists of eight interleaved scanline bytes; the 20 KB screen ring runs from
; &3000 to &7FFF and therefore wraps by &5000 bytes.
MODE1_SCREEN_BASE_HI          = &30
MODE1_SCREEN_RING_SIZE_HI     = &50
MODE1_VIEWPORT_COLUMNS        = &50             ; 80 byte-columns = 320 pixels
MODE1_RIGHTMOST_COLUMN        = MODE1_VIEWPORT_COLUMNS-1
MODE1_TEXT_ROWS               = &20             ; 32 character rows
MODE1_SCANLINES_PER_CHAR      = &08
MODE1_SCROLL_RIGHT_DELTA_LO   = &08
MODE1_SCROLL_LEFT_DELTA_LO    = &F8             ; -8
MODE1_SCROLL_LEFT_DELTA_HI    = &FF
MODE1_SCROLL_RIGHT_DELTA_HI   = &00
MODE1_TEXT_ROW_LOW_ADJUST     = &79             ; +8 already occurred: net +&80
MODE1_TEXT_ROW_HIGH_ADJUST    = &02             ; together gives +&280 bytes
VDU_ROW_ADDRESS_TABLE_PTR     = &E0             ; MOS VDU workspace pointer used here

; Raster/interrupt timing constants.
VIA_IFR_TIMER2                = &20
RASTER_TIMER_RELOAD_LO        = &50
RASTER_TIMER_RELOAD_HI        = &46
RASTER_Y_FLIP_OFFSET          = &1C
RASTER_TIMER_COMPARE_MASK     = &3F
MUSIC_TIMER_RELOAD_LO         = &A8
MUSIC_TIMER_RELOAD_HI         = &61

; Score formatting/life-award bit.  Toggling bit 5 of ScoreMid occurs at each
; 20,000-point boundary in the displayed six-digit score.
; MOD: Extra-life cadence is detected by bit &20 toggling in packed-BCD ScoreMid (the original 20,000-point boundary). Use only a meaningful BCD bit if experimenting.
EXTRA_LIFE_SCORE_BIT          = &20
BCD_NIBBLE_MASK               = &0F

SPRITE_SCRUBBLY        = &12
SPRITE_GEM             = &16
SPRITE_KEY             = &17
SPRITE_HOOTER          = &1D
SPRITE_POGLET          = &1E
SPRITE_FRAK_LOGO       = &22
SPRITE_BULB            = &23
SPRITE_DAGGER          = &25
SPRITE_DAGGER_FLIPPED  = &26
SPRITE_BALLOON         = &27
SPRITE_TROGG_FRAME0    = &34
SPRITE_TROGG_FRAME1    = &35
SPRITE_TROGG_FRAME2    = &36
SPRITE_TROGG_FRAME3    = &37
SPRITE_TROGG_FRAME4    = &38
SPRITE_TROGG_FRAME5    = &39
SPRITE_TROGG_FRAME6    = &3A
SPRITE_TROGG_FRAME7    = &3B
SPRITE_TROGG_DEATH     = &5B
SPRITE_YOYO_HEAD_PHASE0 = &0E
SPRITE_YOYO_HEAD_PHASE1 = &0D
SPRITE_YOYO_HEAD_PHASE2 = &0F
SPRITE_YOYO_HEAD_PHASE3 = &10
SPRITE_YOYO_STRING0     = &28
SPRITE_YOYO_STRING1     = &29
SPRITE_YOYO_STRING2     = &2A
SPRITE_YOYO_STRING3     = &2B
SPRITE_YOYO_STRING4     = &2C
SPRITE_YOYO_STRING5     = &2D
SPRITE_YOYO_STRING6     = &2E
SPRITE_YOYO_STRING7     = &2F
SPRITE_YOYO_STRING8     = &30
SPRITE_YOYO_STRING9     = &31
SPRITE_YOYO_STRING10    = &32
SPRITE_YOYO_STRING11    = &33

; Title/cast sprite placement in Frak logical sprite coordinates.
TITLE_LOGO_X             = &22
TITLE_LOGO_Y             = &EA
TITLE_TROGG_X            = &16
TITLE_TROGG_Y            = &B7
TITLE_SCRUBBLY_X         = &15
TITLE_SCRUBBLY_Y         = &85
TITLE_HOOTER_X           = &15
TITLE_HOOTER_Y           = &6B
TITLE_POGLET_X           = &16
TITLE_POGLET_Y           = &58

; Theme-specific structural sprites.  Names describe their role in the level
; mapper rather than asserting a more specific visual identity than the code proves.
SPRITE_THEME_G_FLOOR0   = &15
SPRITE_THEME_G_FLOOR1   = &3E
SPRITE_THEME_G_FLOOR2   = &3F
SPRITE_THEME_G_FLOOR3   = &40
SPRITE_THEME_G_FLOOR4   = &41
SPRITE_THEME_G_FLOOR5   = &42
SPRITE_THEME_G_FLOOR6   = &43
SPRITE_THEME_G_LADDER0  = &4A
SPRITE_THEME_G_LADDER1  = &4B
SPRITE_THEME_G_LADDER2  = &4C
SPRITE_THEME_G_LADDER3  = &4D
SPRITE_THEME_J_FLOOR0   = &44
SPRITE_THEME_J_FLOOR1   = &45
SPRITE_THEME_J_FLOOR2   = &46
SPRITE_THEME_J_FLOOR3   = &47
SPRITE_THEME_J_FLOOR4   = &48
SPRITE_THEME_J_FLOOR5   = &49
SPRITE_THEME_J_LADDER0  = &00
SPRITE_THEME_J_LADDER1  = &54
SPRITE_THEME_J_LADDER2  = &55
SPRITE_THEME_J_LADDER3  = &56
SPRITE_THEME_C_FLOOR0   = &11
SPRITE_THEME_C_FLOOR1   = &4E
SPRITE_THEME_C_FLOOR2   = &4F
SPRITE_THEME_C_FLOOR3   = &50
SPRITE_THEME_C_FLOOR4   = &51
SPRITE_THEME_C_FLOOR5   = &52
SPRITE_THEME_C_FLOOR6   = &53
SPRITE_THEME_C_LADDER0  = &24
SPRITE_THEME_C_LADDER1  = &57
SPRITE_THEME_C_LADDER2  = &58
SPRITE_THEME_C_LADDER3  = &59
SPRITE_THEME_C_LADDER4  = &5A

; Packed-level variant meanings where the queue defines a semantic object type.
MONSTER_VARIANT_LEVEL_A_SCRUBBLY = 0
MONSTER_VARIANT_LEVEL_B_POGLET   = 1
MONSTER_VARIANT_LEVEL_C_HOOTER   = 0
COLLECTIBLE_VARIANT_KEY  = 0
COLLECTIBLE_VARIANT_BULB = 1
COLLECTIBLE_VARIANT_GEM  = 2


; Renderer aliases for zero-page locations which numerically overlap some of
; the sprite IDs above.  Keeping separate names prevents an immediate sprite
; constant such as #SPRITE_KEY being confused with renderer workspace at &17.
RendererDataPtrLo      = &13
RendererDataPtrHi      = &14
RendererScreenBaseLo   = &15
Mode1XHigh             = &16
RendererWidth          = &17
RendererHeight         = &18
ScreenPtrLo            = &19
ScreenPtrHi            = &1A
PixelOpIndex           = &1B
RendererSolidByte      = &59
SpriteTraversalMode    = &50
RowRoutineLo           = &1C
RowRoutineHi           = &1D
RendererX              = &21
RendererY              = &22
Mode1RowOffset         = &23

; Pointers to the six 92-entry sprite descriptor arrays. Startup loads these
; with the addresses of the actual labels in the &1FFD section below.
SpriteXOffsetPtrLo      = &00
SpriteXOffsetPtrHi      = &01
SpriteYOffsetPtrLo      = &02
SpriteYOffsetPtrHi      = &03
SpriteDefLoPtrLo        = &04
SpriteDefLoPtrHi        = &05
SpriteDefHiPtrLo        = &06
SpriteDefHiPtrHi        = &07
SpriteWidthPtrLo        = &08
SpriteWidthPtrHi        = &09
SpriteHeightPtrLo       = &0A
SpriteHeightPtrHi       = &0B
ScreenOriginLo          = &0C
ScreenOriginHi          = &0D
ClipLeft                = &0E
ClipRight               = &0F
ViewportXOffset         = &10



; =============================================================================
; &01A4-&01FF - OSWORD 7 sound blocks and live self-modifying renderer stub
; =============================================================================
ORG REGION_RENDERER_STUB
; SECTION: SOUND PARAMETER BLOCKS + LIVE RENDERER STUB
; This lives in the upper part of the hardware stack page. Startup deliberately
; sets SP=&A2 so &01A4-&01FF can be used safely. The first 32 bytes are OSWORD 7
; sound parameter blocks; the following eight JSRs are patched at runtime to the
; selected MODE 1 pixel operator. This region must remain writable.
; BBC OSWORD 7 uses four 16-bit fields: channel, amplitude/envelope, pitch,
; duration.  Frak keeps four parameter blocks here and changes pitch in two of
; them at runtime.
; MOD: The four OSWORD 7 blocks below control the basic timbre/pitch/duration of music, yo-yo hit, movement and collect sounds.
MusicSoundBlock:
        EQUW SOUND_CHANNEL_MUSIC    ; channel
        EQUW SOUND_ENVELOPE_MUSIC   ; amplitude / envelope selector
MusicPitch:
        EQUW &0000                  ; low byte replaced by MusicStep
        EQUW SOUND_DURATION_DEFAULT ; duration

YoyoHitSoundBlock:
        EQUW SOUND_CHANNEL_YOYO
        EQUW SOUND_ENVELOPE_YOYO_HIT
        EQUW &0078
        EQUW SOUND_DURATION_DEFAULT

PlayerMoveSoundBlock:
        EQUW SOUND_CHANNEL_MOVE
        EQUW SOUND_ENVELOPE_MOVE
PlayerMovePitch:
        EQUW &0000                  ; set from the player's vertical position
        EQUW SOUND_DURATION_DEFAULT

CollectSoundBlock:
        EQUW SOUND_CHANNEL_YOYO
        EQUW SOUND_ENVELOPE_COLLECT
        EQUW &005A
        EQUW SOUND_DURATION_DEFAULT

; Eight unrolled calls draw one MODE 1 byte-column.  SpriteRenderSetup patches
; every JSR operand to one of the six pixel operators at &1F41-&1F98, then
; jumps into this chain at the call corresponding to RendererY AND 7.
RendererRowCall0:
        JSR &FFFF
RendererRowCall1:
        JSR &FFFF
RendererRowCall2:
        JSR &FFFF
RendererRowCall3:
        JSR &FFFF
RendererRowCall4:
        JSR &FFFF
RendererRowCall5:
        JSR &FFFF
RendererRowCall6:
        JSR &FFFF
RendererRowCall7:
        JSR &FFFF

; Step one character row upward in MODE 1.  If the subtraction crosses the
; circular &3000/&7FFF screen boundary, compensate by &5000 before restarting
; the eight-call chain.
RendererPreviousCharacterRow:
        SEC
        LDA ScreenPtrLo
        SBC #MODE1_PREVIOUS_ROW_LOW_DELTA
        STA ScreenPtrLo
        LDA ScreenPtrHi
        SBC #MODE1_PREVIOUS_ROW_HIGH_DELTA
        STA ScreenPtrHi
        CLC
        TYA
        ADC ScreenPtrLo
        TXA
        ADC ScreenPtrHi
        CMP #MODE1_SCREEN_BASE_HI
        BCS RendererRowCall0
        LDA ScreenPtrHi
        ADC #MODE1_SCREEN_RING_SIZE_HI
        STA ScreenPtrHi
        BCC RendererRowCall0

; The original packed image reused these four bytes as the first four bytes of
; the title entry.  In the sparse runtime map both copies genuinely exist.
RendererStubTail:
        LDX #&01
        LDY #&00



; =============================================================================
; &0380-&048F - title/game entry
; =============================================================================
ORG REGION_TITLE
; SECTION: CAST/CREDITS ENTRY AND TEMPORARY TITLE CODE
; This is the first runtime entry after startup. It displays the cast/credits
; screen and waits for start input. During NewGame the object arrays beginning
; at &0368 deliberately overwrite most/all of this disposable title region.
; -----------------------------------------------------------------------------
; Runtime &0380: installed game/title entry.
; -----------------------------------------------------------------------------
Title_RuntimeEntry:
; CONTRACT: title/attract runtime entry.
; Entry: startup has installed vectors, sprite-table pointers and MOS state.
; Exit: falls into title/attract flow; interrupts are enabled here.
RuntimeGameEntry:
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
        LDA #SPRITE_FRAK_LOGO
        LDX #TITLE_LOGO_X
        LDY #TITLE_LOGO_Y
        JSR DrawSpriteAt
        LDA #SPRITE_TROGG_FRAME1
        LDX #TITLE_TROGG_X
        LDY #TITLE_TROGG_Y
        JSR DrawSpriteAt
        LDA #SPRITE_SCRUBBLY
        LDX #TITLE_SCRUBBLY_X
        LDY #TITLE_SCRUBBLY_Y
        JSR DrawSpriteAt
        LDA #SPRITE_HOOTER
        LDX #TITLE_HOOTER_X
        LDY #TITLE_HOOTER_Y
        JSR DrawSpriteAt
        LDA #SPRITE_POGLET
        LDX #TITLE_POGLET_X
        LDY #TITLE_POGLET_Y
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
        JSR WaitForTitleTimeoutOrStart
        JMP GameStartCheck

; Hold the cast/credits screen for seven full 256-tick chunks unless the player
; starts first.  PollAttractInput uses SavedAbortStackPtr to discard the nested
; WaitFramesOrInput return frames and return directly here with carry set.
WaitForTitleTimeoutOrStart:
        TSX
        STX SavedAbortStackPtr
        LDX #TITLE_TIMEOUT_CHUNKS
TitleTimeout_ChunkLoop:
        LDA #WAIT_256_TICKS
        JSR WaitFramesOrInput
        DEX
        BNE TitleTimeout_ChunkLoop
        CLC
        RTS


; =============================================================================
; &0507-&07FE - music/effect streams followed by three compact level streams
; =============================================================================
ORG REGION_SOUND_LEVELS
; SECTION: MUSIC STREAMS + THREE BASE LEVEL DEFINITIONS
; The first part is read-only encoded music/effect data. The rest is the tagged
; A/B/C level data consumed by LoadLevelStream. Gameplay never executes bytes
; from this region.
SoundStream:
;
; MusicStep uses offsets stored at &8B-&8F.  Each stream ends with a byte whose
; top bit is set; the low bits still carry the final note/control information.
; Encoding recovered from MusicStep:
;   bits 2..6 = pitch written to MusicSoundBlock
;   bits 0..1 = duration code, producing 4,8,12 or 16 countdown units
;   bit 7     = end-of-stream; playback loops to the stream start.  Death and
;               screen-complete streams additionally release MusicInhibitFlag.

; MOD: Music streams can be edited in place without changing the engine.  Preserve the bit-7 terminator convention; see docs/MUSIC_DECODE.md.
TuneScreenA:                         ; base screen A music
        EQUB &21,&21,&29,&31,&36,&22,&29,&36,&21,&20,&29,&36,&22,&29,&35,&3D
        EQUB &41,&45,&4A,&36,&3D,&4A,&28,&28,&2C,&30,&34,&4A,&35,&34,&3D,&48
        EQUB &48,&45,&49,&4D,&52,&3D,&3C,&45,&52,&30,&34,&30,&38,&3C,&52,&3D
        EQUB &3C,&45,&50,&54,&58,&41,&34,&3D,&36,&34,&16,&14,&1A,&18,&1E,&1C
        EQUB &20,&1C,&20,&25,&2C,&A5

TuneScreenB:                         ; base screen B music
        EQUB &0F,&3D,&0D,&1B,&49,&19,&0D,&3D,&0D,&19,&49,&19,&3D,&0D,&2B,&51
        EQUB &29,&09,&59,&09,&0D,&3D,&29,&21,&0D,&19,&21,&15,&6D,&0F,&6D,&0D
        EQUB &1B,&55,&19,&0D,&51,&0D,&19,&51,&19,&49,&0D,&2B,&51,&29,&09,&59
        EQUB &09,&0D,&3D,&29,&23,&1B,&15,&D9

TuneScreenC:                         ; base screen C music
        EQUB &23,&0D,&11,&17,&31,&2D,&29,&11,&0D,&1D,&21,&0D,&15,&1D,&23,&0D
        EQUB &11,&17,&31,&2D,&29,&21,&1D,&15,&0D,&15,&19,&1D,&23,&0D,&15,&21
        EQUB &29,&2D,&31,&37,&31,&35,&3B,&35,&39,&23,&1D,&19,&15,&33,&2D,&29
        EQUB &11,&0D,&1D,&21,&3C,&3D,&44,&BD

TuneDeath:                         ; player death cue
        EQUB &5D,&48,&51,&48,&3D,&AF

TuneScreenComplete:                         ; screen-complete cue
        EQUB &44,&45,&52,&50,&54,&59,&50,&46,&41,&3C,&44,&3C,&51,&40,&45,&37
        EQUB &E7

; -----------------------------------------------------------------------------
; Level A: compact tagged object stream.
; Record byte = (count << 3) | variant, followed by count X/Y pairs.
; A zero record ends the current queue; &FF ends the level.
; -----------------------------------------------------------------------------
; MOD: Level layouts are directly editable here: update a record count when adding/removing X/Y coordinate pairs. Keep each queue's zero terminator and the final LEVEL_END.
LevelA:
        EQUB "C"                  ; original screen/theme selector

        EQUB "T"                  ; Trogg/player queue
        EQUB (1<<3)|0              ; count=1, variant=0: Trogg start position
        EQUB &0A,&30
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "M"                  ; monster queue
        EQUB (7<<3)|MONSTER_VARIANT_LEVEL_A_SCRUBBLY  ; count=7: Scrubbly objects
        EQUB &33,&BC,&7B,&7E,&4C,&30,&69,&30
        EQUB &33,&70,&17,&BC,&A7,&BC
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "K"                  ; collectible queue
        EQUB (3<<3)|COLLECTIBLE_VARIANT_KEY  ; count=3: keys
        EQUB &A8,&2E,&7B,&2F,&5B,&BB
        EQUB (1<<3)|COLLECTIBLE_VARIANT_BULB ; count=1: light bulbs (+time)
        EQUB &3D,&BC
        EQUB (5<<3)|COLLECTIBLE_VARIANT_GEM  ; count=5: gems (+score)
        EQUB &2A,&2F,&14,&7D,&A8,&7D,&69,&7D
        EQUB &4C,&7D
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "F"                  ; floor/platform queue
        EQUB (31<<3)|0              ; count=31, variant=0: floor/platform variant 0
        EQUB &08,&2F,&28,&7C,&28,&2F,&2D,&76
        EQUB &32,&6F,&37,&66,&3C,&5D,&4B,&7C
        EQUB &4F,&91,&53,&A6,&5F,&A6,&63,&91
        EQUB &7A,&7D,&80,&8A,&86,&98,&8D,&A6
        EQUB &94,&B3,&80,&77,&86,&6C,&8D,&60
        EQUB &94,&53,&94,&2E,&A6,&BB,&A6,&7D
        EQUB &A6,&2E,&3C,&7C,&5F,&89,&4F,&74
        EQUB &53,&89,&63,&74,&67,&7C
        EQUB (8<<3)|1              ; count=8, variant=1: floor/platform variant 1
        EQUB &95,&BB,&3B,&2F,&49,&2F,&57,&BB
        EQUB &66,&2F,&77,&2F,&77,&BB,&57,&9E
        EQUB (1<<3)|4              ; count=1, variant=4: floor/platform variant 4
        EQUB &09,&7C
        EQUB (2<<3)|5              ; count=2, variant=5: floor/platform variant 5
        EQUB &09,&BB,&28,&BB
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "L"                  ; ladder/rope queue
        EQUB (8<<3)|0              ; count=8, variant=0: ladder/rope variant 0
        EQUB &3E,&42,&51,&76,&55,&8B,&59,&A0
        EQUB &60,&8B,&96,&38,&64,&76,&5C,&A0
        EQUB (5<<3)|1              ; count=5, variant=1: ladder/rope variant 1
        EQUB &A8,&54,&0A,&92,&3E,&92,&29,&92
        EQUB &7B,&92
        EQUB (1<<3)|2              ; count=1, variant=2: ladder/rope variant 2
        EQUB &A8,&84
        EQUB (5<<3)|3              ; count=5, variant=3: ladder/rope variant 3
        EQUB &68,&38,&0A,&37,&29,&37,&4D,&37
        EQUB &7B,&38
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB LEVEL_END            ; end of level stream

; -----------------------------------------------------------------------------
; Level B: compact tagged object stream.
; Record byte = (count << 3) | variant, followed by count X/Y pairs.
; A zero record ends the current queue; &FF ends the level.
; -----------------------------------------------------------------------------
; MOD: Level B uses the same tagged format as Level A; coordinates are logical Frak X/Y units, not raw MODE 1 addresses.
LevelB:
        EQUB "J"                  ; original screen/theme selector

        EQUB "T"                  ; Trogg/player queue
        EQUB (1<<3)|0              ; count=1, variant=0: Trogg start position
        EQUB &07,&38
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "M"                  ; monster queue
        EQUB (8<<3)|MONSTER_VARIANT_LEVEL_B_POGLET    ; count=8: Poglet objects
        EQUB &6F,&2F,&64,&89,&16,&90,&7D,&2A
        EQUB &42,&57,&2F,&28,&48,&E6,&2A,&CD
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "K"                  ; collectible queue
        EQUB (4<<3)|COLLECTIBLE_VARIANT_KEY  ; count=4: keys
        EQUB &05,&90,&34,&42,&87,&17,&86,&94
        EQUB (1<<3)|COLLECTIBLE_VARIANT_BULB ; count=1: light bulbs (+time)
        EQUB &5F,&D5
        EQUB (2<<3)|COLLECTIBLE_VARIANT_GEM  ; count=2: gems (+score)
        EQUB &04,&BC,&21,&A2
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "F"                  ; floor/platform queue
        EQUB (6<<3)|0              ; count=6, variant=0: floor/platform variant 0
        EQUB &00,&BB,&50,&71,&34,&89,&41,&45
        EQUB &6E,&60,&7A,&17
        EQUB (1<<3)|1              ; count=1, variant=1: floor/platform variant 1
        EQUB &1A,&16
        EQUB (1<<3)|2              ; count=1, variant=2: floor/platform variant 2
        EQUB &00,&37
        EQUB (1<<3)|3              ; count=1, variant=3: floor/platform variant 3
        EQUB &43,&D4
        EQUB (11<<3)|4              ; count=11, variant=4: floor/platform variant 4
        EQUB &15,&69,&26,&BB,&2F,&58,&47,&1B
        EQUB &72,&D7,&79,&AF,&75,&9A,&7A,&79
        EQUB &03,&90,&2B,&71,&69,&17
        EQUB (21<<3)|5              ; count=21, variant=5: floor/platform variant 5
        EQUB &22,&79,&12,&90,&27,&92,&19,&BB
        EQUB &35,&B5,&41,&AE,&4D,&A8,&39,&1B
        EQUB &59,&1C,&5C,&28,&5F,&34,&62,&40
        EQUB &6C,&79,&6C,&A1,&84,&94,&37,&28
        EQUB &33,&42,&35,&35,&19,&CB,&16,&D7
        EQUB &1F,&A1
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "L"                  ; ladder/rope queue
        EQUB (13<<3)|0              ; count=13, variant=0: ladder/rope variant 0
        EQUB &15,&44,&50,&AF,&4A,&20,&35,&64
        EQUB &29,&96,&50,&4C,&6E,&3B,&79,&B2
        EQUB &80,&8A,&6E,&7C,&0E,&96,&23,&7C
        EQUB &7D,&3B
        EQUB (4<<3)|1              ; count=4, variant=1: ladder/rope variant 1
        EQUB &16,&99,&42,&4B,&2F,&1A,&1C,&2B
        EQUB (1<<3)|2              ; count=1, variant=2: ladder/rope variant 2
        EQUB &64,&7D
        EQUB (1<<3)|3              ; count=1, variant=3: ladder/rope variant 3
        EQUB &72,&67
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB LEVEL_END            ; end of level stream

; -----------------------------------------------------------------------------
; Level C: compact tagged object stream.
; Record byte = (count << 3) | variant, followed by count X/Y pairs.
; A zero record ends the current queue; &FF ends the level.
; -----------------------------------------------------------------------------
; MOD: Level C uses theme G. Monster variant 0 maps to Hooter here; variant numbers are theme-local, not global sprite IDs.
LevelC:
        EQUB "G"                  ; original screen/theme selector

        EQUB "T"                  ; Trogg/player queue
        EQUB (1<<3)|0              ; count=1, variant=0: Trogg start position
        EQUB &06,&3A
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "M"                  ; monster queue
        EQUB (10<<3)|MONSTER_VARIANT_LEVEL_C_HOOTER ; count=10: Hooter objects
        EQUB &40,&94,&0F,&B0,&1F,&91,&2E,&4A
        EQUB &99,&1F,&B0,&90,&21,&4A,&4F,&1F
        EQUB &85,&1F,&7D,&C8
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "K"                  ; collectible queue
        EQUB (4<<3)|COLLECTIBLE_VARIANT_KEY  ; count=4: keys
        EQUB &0D,&90,&57,&6F,&8A,&C2,&B6,&8F
        EQUB (4<<3)|COLLECTIBLE_VARIANT_BULB ; count=4: light bulbs (+time)
        EQUB &18,&6D,&13,&6D,&5A,&D1,&24,&16
        EQUB (4<<3)|COLLECTIBLE_VARIANT_GEM  ; count=4: gems (+score)
        EQUB &19,&B0,&7C,&8C,&45,&28,&8F,&1F
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "F"                  ; floor/platform queue
        EQUB (20<<3)|0              ; count=20, variant=0: floor/platform variant 0
        EQUB &06,&AF,&0F,&AF,&18,&AF,&1F,&90
        EQUB &16,&90,&0C,&90,&2E,&49,&3B,&49
        EQUB &45,&52,&3B,&5C,&85,&1E,&8E,&1E
        EQUB &99,&1E,&99,&71,&A2,&71,&98,&80
        EQUB &A4,&8F,&97,&8F,&7D,&C7,&A2,&1E
        EQUB (11<<3)|1              ; count=11, variant=1: floor/platform variant 1
        EQUB &6E,&5A,&7D,&41,&28,&8D,&1A,&33
        EQUB &1C,&3F,&1E,&49,&41,&27,&57,&D0
        EQUB &6E,&B9,&6E,&C7,&9C,&AF
        EQUB (6<<3)|2              ; count=6, variant=2: floor/platform variant 2
        EQUB &56,&6F,&A2,&62,&72,&1E,&45,&66
        EQUB &7B,&8B,&B0,&8F
        EQUB (3<<3)|3              ; count=3, variant=3: floor/platform variant 3
        EQUB &4F,&1E,&22,&DA,&24,&15
        EQUB (2<<3)|4              ; count=2, variant=4: floor/platform variant 4
        EQUB &02,&39,&3C,&93
        EQUB (3<<3)|6              ; count=3, variant=6: floor/platform variant 6
        EQUB &4F,&A7,&3C,&DA,&82,&DF
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB "L"                  ; ladder/rope queue
        EQUB (6<<3)|0              ; count=6, variant=0: ladder/rope variant 0
        EQUB &22,&AB,&4F,&AB,&2E,&1A,&72,&2B
        EQUB &95,&B0,&A9,&33
        EQUB (3<<3)|1              ; count=3, variant=1: ladder/rope variant 1
        EQUB &57,&32,&81,&4E,&3C,&9D
        EQUB (2<<3)|2              ; count=2, variant=2: ladder/rope variant 2
        EQUB &2C,&8F,&82,&94
        EQUB (5<<3)|3              ; count=5, variant=3: ladder/rope variant 3
        EQUB &06,&56,&41,&3A,&6E,&60,&9D,&56
        EQUB &9F,&56
        EQUB LEVEL_QUEUE_END      ; end this queue block

        EQUB LEVEL_END            ; end of level stream
; =============================================================================
; &0880-&08A3 - high-score table
; =============================================================================
ORG REGION_HIGH_SCORES
; SECTION: WRITABLE HIGH-SCORE TABLE
; Six 6-byte records live here for the whole game: 3 initials + 3 packed-BCD
; score bytes. HighScoreInsert edits this table in place.
; Six high-score records: three displayed initials followed by a three-byte
; packed-BCD score.  The first initials are preserved exactly as released.
; MOD: The six initial high-score records may be changed directly: 3 ASCII initials followed by 3 packed-BCD score bytes.
HighScores:
        EQUB &76,&26,&6F, &00,&01,&00
        EQUB "NIK",       &00,&01,&00
        EQUB "BOF",       &00,&01,&00
        EQUB "CAP",       &00,&01,&00
        EQUB "PAM",       &00,&01,&00
        EQUB "DCE",       &00,&01,&00
; =============================================================================
; &0A00-&0AFF - MODE 1 lookup masks
; =============================================================================
ORG REGION_MODE1_MASKS
; SECTION: MODE 1 PIXEL-MASK LOOKUP PAGE
; Exactly 256 bytes used by the sprite renderer for fast masking. The low byte
; of a pixel value indexes this table directly, so the region must remain page
; aligned even though the source is otherwise relocatable.
Mode1Masks:
        ; Pixel bytes are used directly as the low byte of an indirect lookup
        ; pointer, so this 256-byte table must begin on a page boundary.
        ASSERT ((Mode1Masks % 256)-1)>>8
EQUB &FF,&EE,&DD,&CC,&BB,&AA,&99,&88,&77,&66,&55,&44,&33,&22,&11,&00
        EQUB &EE,&EE,&CC,&CC,&AA,&AA,&88,&88,&66,&66,&44,&44,&22,&22,&00,&00
        EQUB &DD,&CC,&DD,&CC,&99,&88,&99,&88,&55,&44,&55,&44,&11,&00,&11,&00
        EQUB &CC,&CC,&CC,&CC,&88,&88,&88,&88,&44,&44,&44,&44,&00,&00,&00,&00
        EQUB &BB,&AA,&99,&88,&BB,&AA,&99,&88,&33,&22,&11,&00,&33,&22,&11,&00
        EQUB &AA,&AA,&88,&88,&AA,&AA,&88,&88,&22,&22,&00,&00,&22,&22,&00,&00
        EQUB &99,&88,&99,&88,&99,&88,&99,&88,&11,&00,&11,&00,&11,&00,&11,&00
        EQUB &88,&88,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &77,&66,&55,&44,&33,&22,&11,&00,&77,&66,&55,&44,&33,&22,&11,&00
        EQUB &66,&66,&44,&44,&22,&22,&00,&00,&66,&66,&44,&44,&22,&22,&00,&00
        EQUB &55,&44,&55,&44,&11,&00,&11,&00,&55,&44,&55,&44,&11,&00,&11,&00
        EQUB &44,&44,&44,&44,&00,&00,&00,&00,&44,&44,&44,&44,&00,&00,&00,&00
        EQUB &33,&22,&11,&00,&33,&22,&11,&00,&33,&22,&11,&00,&33,&22,&11,&00
        EQUB &22,&22,&00,&00,&22,&22,&00,&00,&22,&22,&00,&00,&22,&22,&00,&00
        EQUB &11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00,&11,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
; =============================================================================
; &0B00-&0CF2 - queue descriptors and core game routines
; =============================================================================
ORG REGION_CORE
; SECTION: OBJECT QUEUES + TOP-LEVEL GAME LIFECYCLE
; Defines the seven object pools and compact draw/erase entry points, then owns
; attract -> new game -> screen init -> MainGameFrame -> death/screen-complete
; progression. TimerAndKeys also lives here because it is called every frame.
QueueDescriptors:
; Queue descriptors.  The first byte of each record is also the previous
; record's exclusive end slot, so the seven four-byte records overlap by one
; byte.  Flags are consumed by CollisionScan with the masks named above.
QueueTroggDescriptor:
        EQUB TROGG_FIRST_SLOT,COLLIDE_NONE,"T"
QueueDaggerDescriptor:
        EQUB DAGGER_FIRST_SLOT,COLLIDE_PLAYER_HAZARD|COLLIDE_YOYO,"D"
QueueBalloonDescriptor:
        EQUB BALLOON_FIRST_SLOT,COLLIDE_PLAYER_HAZARD|COLLIDE_YOYO,"B"
QueueCollectibleDescriptor:
        EQUB COLLECTIBLE_FIRST_SLOT,COLLIDE_COLLECTIBLE|COLLIDE_RESERVED_40,"K"
QueueMonsterDescriptor:
        EQUB MONSTER_FIRST_SLOT,COLLIDE_PLAYER_HAZARD|COLLIDE_YOYO|COLLIDE_YOYO_DARK|COLLIDE_RESERVED_40,"M"
QueueFloorDescriptor:
        EQUB FLOOR_FIRST_SLOT,COLLIDE_FLOOR,"F"
QueueLadderDescriptor:
        EQUB LADDER_FIRST_SLOT,COLLIDE_LADDER,"L"
        EQUB OBJECT_SLOT_END
        EQUB 0,0                    ; original padding at &0B16-&0B17

; Four compact entries select a sprite/object operation mode in A.  DRAW and
; ERASE_AND_COLLIDE deliberately overlap: byte &CD is a CMP-abs opcode seen only
; by DrawObject, while the following A9 C0 bytes form LDA #OBJECT_RENDER_ERASE_AND_COLLIDE
; at the overlapping entry.  This preserves Orlando's original byte-saving trick.
DrawObjectAndScanCollisions:
        LDA #OBJECT_RENDER_DRAW_AND_COLLIDE
        BPL ApplyObjectOperation
EraseObject:
        LDA #OBJECT_RENDER_ERASE
        BMI ApplyObjectOperation
DrawObject:
        LDA #OBJECT_RENDER_DRAW
        EQUB &CD                    ; CMP abs opcode; operand is following A9 C0
EraseObjectAndScanCollisions:
        LDA #OBJECT_RENDER_ERASE_AND_COLLIDE
ApplyObjectOperation:
        JSR LoadObject
        BCS ApplyObjectOperation_Return
        STX RenderCallerObjectSlot
        JSR ProcessSprite
        LDX RenderCallerObjectSlot
ApplyObjectOperation_Return:
        RTS

; CONTRACT: draw one sprite at logical coordinates.
; Entry: A=sprite descriptor index, X=logical X, Y=logical Y.
; Effect: updates CurrentSpriteX/Y and dispatches ProcessSprite in draw mode.
DrawSpriteAt:
        STX CurrentSpriteX
        STY CurrentSpriteY
        TAY
        LDA #OBJECT_RENDER_DRAW
        JMP ProcessSprite

LoadObject:
        LDY ObjectX,X
        STY CurrentSpriteX
        LDY ObjectY,X
        STY CurrentSpriteY
        LDY ObjectSprite,X
        CPY #SPRITE_DESCRIPTOR_COUNT
        RTS

; Attract/title loop.  TitleStartSequence returns carry set when a game starts.
GameStartTitleLoop:
        JSR ResetCountdownDivider
        LDA #CONTROL_UNSELECTED
        STA MusicInhibitFlag
        STA ControlScheme
        JSR TitleStartSequence
GameStartCheck:
        BCC GameStartTitleLoop

NewGame:
        LDA #INITIAL_LIVES
        STA Lives
        LDA #&00
        STA BaseScreen
        STA TransformCycle
        STA ScoreLo
        STA ScoreMid
        STA ScoreHi

; Initialise one of the three base screens and the current 0..7 transform cycle.
; CONTRACT: initialise the current base screen/transform combination.
; Uses: BaseScreen (0..2), TransformCycle (0..7).
; Effect: selects level/tune/timer, clears object state, decodes/draws level, resets hazards.
StartScreen:
        LDX BaseScreen
        LDY TransformCycle
        JSR DisplayInit
        SEC
        LDA #HAZARD_BASE_RELOAD
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
        JSR ClearScrollBackingBuffer

        LDX #&00
        STX WalkAnimationPhase
        STX PlayerDeadFlag
        STX YoyoActiveFlag
        STX PlayerClimbingFlag
        STX PlayerAirborneFlag
        STX TimeLoBCD
        STX CountdownFlags
        INX
        STX PlayerHorizontalStep
        STX HazardCounter
        LDA #COUNTDOWN_TICKS_PER_SEC
        STA CountdownDivider
        JSR ClearObjectTables
        JSR LoadLevelStream
        JSR DrawAllObjects
        JSR DrawStatus
        DEC ScrollRefreshRequestFlag
        LDA #SPRITE_KEY
        LDY #QUEUE_COLLECTIBLES
        JSR CountObjectsOfType
        DEX
        STX KeysRemainingMinusOne
        LDA TickCounter
        STA LastTick

; Main live frame loop.
; CONTRACT: one iteration of the live gameplay loop.
; Effect: update player, test death/completion, service timer/keys and dynamic hazards.
; Does not return during normal play; loops through MainGameFrame.
MainGameFrame:
        JSR UpdatePlayerFrame
        BIT PlayerDeadFlag
        BMI PlayerDied
        BIT KeysRemainingMinusOne
        BMI HandleScreenComplete
        JSR TimerAndKeys
        BNE BackToTitle
        JSR SpawnHazard
        JMP MainGameFrame

PlayerDied:
        JSR ResetCountdownDivider
        LDA #PLAYER_DEATH_DELAY_TICKS
        JSR DelayWithInput
        DEC Lives
        BNE RestartScreen
        JSR HighScoreInsert
        BCC BackToTitle
        JMP NewGame
BackToTitle:
        JMP GameStartTitleLoop

HandleScreenComplete:
        JSR ScreenComplete
        DEC MusicInhibitFlag
        LDY #TIME_BONUS_REPEAT_COUNT
        STY TimeBonusRepeatCounter
TimeBonus_Repeat:
        LDA TimeLoBCD
        JSR AddScoreBCD
        LDX TimeHiBCD
        BEQ TimeBonus_RepeatDone
TimeBonus_AddMinutes:
        LDA #BCD_SECONDS_PER_MINUTE
        JSR AddScoreBCD
        DEX
        BNE TimeBonus_AddMinutes
TimeBonus_RepeatDone:
        DEC TimeBonusRepeatCounter
        BNE TimeBonus_Repeat

        INC BaseScreen
        LDA BaseScreen
        CMP #BASE_SCREEN_COUNT
        BCC RestartScreen
        LDA #&00
        STA BaseScreen
        ADC TransformCycle          ; carry is clear here: A=old transform cycle
        AND #TRANSFORM_MASK
        STA TransformCycle
RestartScreen:
        JMP StartScreen

ResetCountdownDivider:
        LDA #COUNTDOWN_STOPPED
        STA CountdownFlags
        RTS

; Countdown, sound toggle, freeze/unfreeze and escape processing.
; CONTRACT: service countdown plus sound/freeze/escape controls.
; Return: Z clear when ESC is pressed; Z set when play should continue.
; Preserves caller X/Y via stack.
TimerAndKeys:
        TXA
        PHA
        TYA
        PHA
        BIT CountdownFlags
        BPL CheckSoundKey
        INC CountdownFlags
        SEC
        SED
        LDA TimeLoBCD
        SBC #&01
        BCS Countdown_StoreTimeLo
        DEC TimeHiBCD
        LDA #BCD_LAST_SECOND
Countdown_StoreTimeLo:
        STA TimeLoBCD
        CLD
        JSR DrawStatus
        DEC ScrollRefreshRequestFlag
        LDA TimeLoBCD
        ORA TimeHiBCD
        BNE CheckSoundKey

        LDA #COUNTDOWN_STOPPED
        STA CountdownFlags
        SEC
        LDA HazardReload
        SBC #HAZARD_EXPIRED_REDUCTION
        STA HazardReload
        LDA TransformCycle
        LSR A
        BNE CountdownExpired_TransformNonZero
        JSR PrintInlineStream
        EQUB &13,0,0,0,0,0,&EA
        JMP CheckSoundKey
CountdownExpired_TransformNonZero:
        LSR A
        BCC CheckSoundKey
        BNE CountdownExpired_ThirdPattern
        JSR PrintInlineStream
        EQUB &13,&03,&0F,0,0,0,&EA
        JMP CheckSoundKey
CountdownExpired_ThirdPattern:
        JSR PrintInlineStream
        EQUB &13,&03,&08,0,0,0,&EA

CheckSoundKey:
        LDA #KEY_QUIET_Q
        LDX SoundMutedFlag
        BPL SoundToggle_PollKey
        LDA #KEY_SOUND_ON_S
SoundToggle_PollKey:
        JSR Inkey
        BEQ CheckFreezeKey
        TXA
        EOR #&FF
        STA SoundMutedFlag
        BPL CheckFreezeKey
        LDA #OSBYTE_FLUSH_BUFFER
        LDX #SOUND_BUFFER_FIRST
SoundToggle_FlushChannels:
        JSR OSBYTEWrapper
        INX
        CPX #SOUND_BUFFER_END
        BCC SoundToggle_FlushChannels

CheckFreezeKey:
        LDA #KEY_FREEZE_DELETE
        JSR Inkey
        BEQ TimerAndKeys_CheckEscape
        LDA #KEY_UNFREEZE_COPY
        JSR Inkey
        BNE TimerAndKeys_CheckEscape
        DEC PauseFlag
        BIT CountdownFlags
        BMI Freeze_ShowMessage
        BVS Freeze_WaitForCopy
Freeze_ShowMessage:
        JSR PrintInlineStream
        EQUB &1E
        EQUS " *** Freeze *** "
        EQUB &EA
        DEC ScrollRefreshRequestFlag
Freeze_WaitForCopy:
        LDA #KEY_UNFREEZE_COPY
        JSR Inkey
        BEQ Freeze_WaitForCopy
        BIT CountdownFlags
        BMI Freeze_RedrawStatus
        BVS Freeze_Resume
Freeze_RedrawStatus:
        JSR DrawStatus
        DEC ScrollRefreshRequestFlag
Freeze_Resume:
        INC PauseFlag

TimerAndKeys_CheckEscape:
        PLA
        TAY
        PLA
        TAX
        LDA #KEY_ESCAPE
        JMP Inkey

; Runtime alias retained for the overlapping compact entry sequence.


; =============================================================================
; &0D01-&1FFC - main engine
; =============================================================================
ORG REGION_ENGINE
; SECTION: MAIN ENGINE
; Broad order through this region:
;   &0Dxx timing/interrupt/MOS helpers
;   &0Exx-&11xx Trogg physics, ladders, jumping and yo-yo
;   &11xx-&13xx frame commit, pickups and keyboard/joystick input
;   &13xx-&15xx scrolling, collision and display transforms
;   &15xx-&17xx score/status/high-score handling
;   &17xx level decode, &18xx music/transitions, &19xx attract/title
;   &1Bxx hazards, &1Cxx-&1Fxx sprite collision/traversal/rendering
; Wait for the 50 Hz/event tick counter to change.
WaitForTickChange:
        LDA TickCounter
WaitForTickChange_Loop:
        CMP TickCounter
        BEQ WaitForTickChange_Loop
        RTS

; Synchronise drawing to the User VIA timer using the selected object's Y
; coordinate, transformed for the current screen orientation.
WaitForObjectRaster:
        LDA ObjectY,X
WaitForRasterAtY:
        EOR VerticalFlipFlag
        BIT VerticalFlipFlag
        BPL WaitForRasterAtY_TransformDone
        SEC
        SBC #RASTER_Y_FLIP_OFFSET
WaitForRasterAtY_TransformDone:
        LSR A
        LSR A
        CLC
        ADC #&FF
        AND #RASTER_TIMER_COMPARE_MASK
WaitForRasterAtY_TimerLoop:
        CMP USER_VIA_T2CH
        BCC WaitForRasterAtY_TimerLoop
        RTS

; Inline VDU/text printer.  JSR PrintInlineStream is followed by bytes and an
; &EA terminator.  The routine consumes its caller's return address, prints the
; stream, then jumps indirectly to the byte after the terminator.
PrintInlineStream:
        PLA
        STA InlineStreamPtrLo
        PLA
        STA InlineStreamPtrHi
        TYA
        PHA
        JMP PrintInlineAdvance
PrintInlineStream_NextByte:
        LDY #&00
        LDA (InlineStreamPtrLo),Y
        CMP #INLINE_STREAM_END
        BEQ PrintInlineStream_Done
        JSR OSWRCH
PrintInlineAdvance:
        INC InlineStreamPtrLo
        BNE PrintInlineStream_NextByte
        INC InlineStreamPtrHi
        BNE PrintInlineStream_NextByte
PrintInlineStream_Done:
        PLA
        TAY
        JMP (InlineStreamPtrLo)

; EVENTV handler.  Reload User VIA Timer 2, advance the game tick and maintain
; the two-byte countdown state unless pause/freeze gates suppress it.
TickIRQ:
        PHP
        PHA
        LDA #RASTER_TIMER_RELOAD_LO
        STA USER_VIA_T2CL
        LDA #RASTER_TIMER_RELOAD_HI
        STA USER_VIA_T2CH
        BIT PauseFlag
        BMI TickIRQ_Return
        INC TickCounter
        BIT CountdownFlags
        BMI TickIRQ_Countdown
        BVS TickIRQ_Return
TickIRQ_Countdown:
        DEC CountdownDivider
        BNE TickIRQ_Return
        LDA #COUNTDOWN_TICKS_PER_SEC
        STA CountdownDivider
        DEC CountdownFlags
TickIRQ_Return:
        PLA
        PLP
        RTS

; IRQ1V handler.  Service User VIA Timer 2/Timer 1 work owned by Frak and then
; chain through the IRQ1V vector which startup saved in &4E/&4F.
SoundIRQ:
        PHP
        PHA
        LDA #VIA_IFR_TIMER2
        BIT USER_VIA_IFR
        BEQ SoundIRQ_CheckTimer1
        BIT USER_VIA_T2CL           ; read clears the Timer 2 interrupt flag
        BIT ScrollRefreshRequestFlag
        BPL SoundIRQ_CheckTimer1
        TYA
        PHA
        LDA #&00
        STA ScrollRefreshRequestFlag
        JSR RefreshScrollBuffer
        PLA
        TAY
SoundIRQ_CheckTimer1:
        BIT USER_VIA_IFR
        BVC SoundIRQ_ChainOldIRQ
        BIT USER_VIA_T1CL           ; read clears the Timer 1 interrupt flag
        LDA MusicInhibitFlag
        ORA PauseFlag
        BMI SoundIRQ_ChainOldIRQ
        DEC MusicDurationCounter
        JSR MusicStep
SoundIRQ_ChainOldIRQ:
        PLA
        PLP
        JMP (SavedIRQ1VLo)

; Negative-INKEY wrapper.  A contains the BBC internal key number; X and Y are
; preserved.  The Z flag returned by OSBYTE &81 is preserved for the caller.
; CONTRACT: BBC negative-INKEY wrapper.
; Entry: A=BBC internal key code. X/Y preserved.
; Return: Z reflects key state as returned by OSBYTE &81; A is restored to key code.
Inkey:
        STA InkeyCode
        TXA
        PHA
        TYA
        PHA
        LDX InkeyCode
        LDY #&FF
        LDA #OSBYTE_INKEY
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

; Return a pseudo-random value in A in the inclusive range 0 <= result <= input A.
; The mask is expanded to the next suitable power-of-two range, then candidates
; are rejected until they are less than or equal to the requested maximum.  The evolving state is
; mixed with User VIA Timer 1 for additional timing entropy.
; CONTRACT: bounded pseudo-random generator.
; Entry: A=inclusive maximum.
; Return: A in 0..input inclusive. Uses RandomState mixed with User VIA T1.
RandomUpToA:
        STA RandomLimit
        LDA #PRNG_TOP_BIT
RandomUpToA_FindMask:
        BIT RandomLimit
        BNE RandomUpToA_MaskReady
        LSR A
        BCC RandomUpToA_FindMask
        LDA #&01
RandomUpToA_MaskReady:
        SEC
        SBC #&01
        ROL A
        STA RandomMask
RandomUpToA_Retry:
        LDA RandomState
        ADC #PRNG_INCREMENT
        STA RandomState
        EOR USER_VIA_T1CL
        AND RandomMask
        CMP RandomLimit
        BEQ RandomUpToA_Return
        BCS RandomUpToA_Retry
RandomUpToA_Return:
        RTS

; Reset the 123 object sprite/type slots and the 23 dynamic velocity slots.
ClearObjectTables:
        LDY #OBJECT_SLOT_COUNT
        LDA #OBJECT_EMPTY
ClearObjectTables_SpritesLoop:
        STA ObjectSprite-1,Y
        DEY
        BNE ClearObjectTables_SpritesLoop
        LDX #DYNAMIC_MOTION_SLOTS
ClearObjectTables_DynamicLoop:
        LDA #OBJECT_EMPTY
        STA ObjectDY-1,X
        TYA                         ; Y is zero after the object clear loop
        STA ObjectDX-1,X
        DEX
        BNE ClearObjectTables_DynamicLoop
ClearObjectTables_Return:
        RTS

; KEYV filter installed by startup. Requests not consumed here are chained
; to the previous KEYV saved in &4C/&4D.
KeyVHandler:
        BVS ClearObjectTables_Return
        BCC ClearObjectTables_Return
        JMP (SavedKeyVLo)

; MOS wrappers bracket calls with MosCallInProgressFlag so interrupt-side code can see that
; a MOS call is in progress.
OSBYTEWrapper:
        DEC MosCallInProgressFlag
        JSR OSBYTE
        INC MosCallInProgressFlag
        RTS

OSWORDWrapper:
        DEC MosCallInProgressFlag
        JSR OSWORD
        INC MosCallInProgressFlag
        RTS

Runtime_0D01_DecompiledEnd:
; -----------------------------------------------------------------------------
; Reachable game engine, runtime &0E0B-&1FF8.
;
; This is a code/data-aware disassembly generated from the Stage 2 reachability
; map.  Reachable instructions are assembly; bytes which are not proven code
; remain EQUB data.  Absolute operands deliberately name the fixed LOW runtime
; map, while relative branches use local source labels below.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; SUBSYSTEM: TROGG MOVEMENT / PHYSICS / YO-YO
; From here through the climbing/airborne routines, code computes Trogg input,
; jump/fall velocity, platform support, ladder attachment and yo-yo state.
;
; Runtime &0E0B: ladder/rope collision test.
; -----------------------------------------------------------------------------
; CONTRACT: construct Trogg's narrow ladder probe and scan ladder queue.
; Entry: A/Y/X participate in current player geometry; preserves caller X/Y on stack.
; Return: carry from collision scan indicates ladder/rope overlap.
TestLadderCollision:
        STA     LadderProbeObjectSlot                    ; &0E0B: 85 26
        TXA                                          ; &0E0D: 8A
        PHA                                          ; &0E0E: 48
        TYA                                          ; &0E0F: 98
        PHA                                          ; &0E10: 48
        LDX     LadderProbeObjectSlot                    ; &0E11: A6 26
        SEC                                          ; &0E13: 38
        SBC     #LADDER_PROBE_BOTTOM_OFFSET                                 ; &0E14: E9 0E
        STA     CollisionBottom                                  ; &0E16: 85 48
        CLC                                          ; &0E18: 18
        ADC     #LADDER_PROBE_HEIGHT                                 ; &0E19: 69 1E
        STA     CollisionTop                                  ; &0E1B: 85 47
        LDY     ObjectX,X                            ; &0E1D: BC 68 03
        STY     CollisionLeft                                  ; &0E20: 84 45
        INY                                          ; &0E22: C8
        STY     CollisionRight                                  ; &0E23: 84 46
        LDA     #COLLIDE_LADDER                                 ; &0E25: A9 04
        JSR     CollisionScan                        ; &0E27: 20 72 14
        PLA                                          ; &0E2A: 68
        TAY                                          ; &0E2B: A8
        PLA                                          ; &0E2C: 68
        TAX                                          ; &0E2D: AA
        RTS                                          ; &0E2E: 60
TryAttachLadder:
        LDA     #&00                                 ; &0E2F: A9 00
        JSR     TestLadderCollision                  ; &0E31: 20 0B 0E
        BCC     TryAttachLadder_Return                                ; &0E34: 90 28
        BIT     PlayerAirborneFlag                              ; &0E36: 24 53
        BMI     TryAttachLadder_Attach                                ; &0E38: 30 1B
        CPY     ObjectY                              ; &0E3A: CC E3 03
        PHP                                          ; &0E3D: 08
        STX     LadderSavedX                             ; &0E3E: 86 26
        LDX     CollidedObjectSlot                      ; &0E40: A6 64
        LDA     ObjectY,X                            ; &0E42: BD E3 03
        CMP     ObjectY                              ; &0E45: CD E3 03
        ROR     A                                    ; &0E48: 6A
        LDX     LadderSavedX                             ; &0E49: A6 26
        STA     LadderSideRelationBits                   ; &0E4B: 85 26
        PLP                                          ; &0E4D: 28
        ROR     A                                    ; &0E4E: 6A
        CLC                                          ; &0E4F: 18
        EOR     LadderSideRelationBits                   ; &0E50: 45 26
        BMI     TryAttachLadder_Return                                ; &0E52: 30 0A
        SEC                                          ; &0E54: 38
TryAttachLadder_Attach:
        DEC     PlayerClimbingFlag                              ; &0E55: C6 54
        LDA     #&00                                 ; &0E57: A9 00
        STA     ObjectDX                             ; &0E59: 8D D9 04
        LDX     #SPRITE_TROGG_CLIMB_A               ; &0E5C: A2 13
TryAttachLadder_Return:
        RTS                                          ; &0E5E: 60

; -----------------------------------------------------------------------------
; Runtime &0E5F: floor/platform collision test.
; -----------------------------------------------------------------------------
TestFloorCollision:
        STA     CollisionTop                                  ; &0E5F: 85 47
        STA     CollisionBottom                                  ; &0E61: 85 48
        DEC     CollisionBottom                                  ; &0E63: C6 48
        TXA                                          ; &0E65: 8A
        PHA                                          ; &0E66: 48
        TYA                                          ; &0E67: 98
        PHA                                          ; &0E68: 48
        LDX     #&00                                 ; &0E69: A2 00
        LDA     ObjectX,X                            ; &0E6B: BD 68 03
        STA     CollisionLeft                                  ; &0E6E: 85 45
        STA     CollisionRight                                  ; &0E70: 85 46
        INC     CollisionRight                                  ; &0E72: E6 46
        LDA     #COLLIDE_FLOOR                                 ; &0E74: A9 02
        JSR     CollisionScan                        ; &0E76: 20 72 14
        PLA                                          ; &0E79: 68
        TAY                                          ; &0E7A: A8
        PLA                                          ; &0E7B: 68
        TAX                                          ; &0E7C: AA
        RTS                                          ; &0E7D: 60
; Yo-yo component animation.  The head cycles through four rotational frames;
; the string/line component walks through the extension frames while the yo-yo
; travels away from and back toward Trogg.
YoyoHeadSpriteTable:
        EQUB SPRITE_YOYO_HEAD_PHASE0,SPRITE_YOYO_HEAD_PHASE1,SPRITE_YOYO_HEAD_PHASE2,SPRITE_YOYO_HEAD_PHASE3
YoyoStringSpriteTable:
        EQUB SPRITE_HIDDEN,SPRITE_YOYO_STRING0,SPRITE_YOYO_STRING1,SPRITE_YOYO_STRING2
        EQUB SPRITE_YOYO_STRING3,SPRITE_YOYO_STRING4,SPRITE_YOYO_STRING5,SPRITE_YOYO_STRING6
        EQUB SPRITE_YOYO_STRING7,SPRITE_YOYO_STRING8,SPRITE_YOYO_STRING9,SPRITE_YOYO_STRING10,SPRITE_YOYO_STRING11

; -----------------------------------------------------------------------------
; Runtime &0E8F: yo-yo attack state machine.
; -----------------------------------------------------------------------------
; CONTRACT: advance the complete yo-yo state machine for one player update.
; Effect: deploy/animate/retract yo-yo, scan hits, award monster score and apply knockback.
; Uses slots 1 (string) and 2 (head); YoyoActiveFlag is the top-level state gate.
UpdateYoyoAttack:
        STX     PlayerFrameSprite                      ; &0E8F: 86 58
        DEC     YoyoActiveFlag                              ; &0E91: C6 55
        LDA     #&00                                 ; &0E93: A9 00
        STA     ObjectDX                             ; &0E95: 8D D9 04
        LDX     #YOYO_HEAD_SLOT                     ; &0E98: A2 02
        CLC                                          ; &0E9A: 18
        LDA     PlayerHorizontalStep                       ; &0E9B: A5 57
        STA     ObjectDX,X                           ; &0E9D: 9D D9 04
        ADC     ObjectX                              ; &0EA0: 6D 68 03
        BIT     PlayerHorizontalStep                       ; &0EA3: 24 57
        BPL     Yoyo_StoreHeadX                                ; &0EA5: 10 03
        SEC                                          ; &0EA7: 38
        SBC     #YOYO_HEAD_X_OFFSET                 ; &0EA8: E9 02
Yoyo_StoreHeadX:
        STA     ObjectX,X                            ; &0EAA: 9D 68 03
        STA     YoyoBaseX                                  ; &0EAD: 85 65
        CLC                                          ; &0EAF: 18
        ADC     #YOYO_HEAD_X_OFFSET                 ; &0EB0: 69 02
        STA     ObjectX+YOYO_STRING_SLOT                           ; &0EB2: 8D 69 03
        CLC                                          ; &0EB5: 18
        LDA     ObjectY                              ; &0EB6: AD E3 03
        ADC     #YOYO_VERTICAL_OFFSET                ; &0EB9: 69 0B
        STA     ObjectY+YOYO_STRING_SLOT                           ; &0EBB: 8D E4 03
        STA     ObjectY+YOYO_HEAD_SLOT                           ; &0EBE: 8D E5 03
        INC     ObjectY+YOYO_STRING_SLOT                           ; &0EC1: EE E4 03
        LDY     #&01                                 ; &0EC4: A0 01
        STY     YoyoExtensionDirection                                  ; &0EC6: 84 79
        DEY                                          ; &0EC8: 88
        STY     YoyoSegmentPhase                                  ; &0EC9: 84 66
        DEY                                          ; &0ECB: 88
        STY     YoyoExtensionCount                                  ; &0ECC: 84 67
        STY     YoyoAnimationIndex                                  ; &0ECE: 84 78
        LDX     #SPRITE_TROGG_YOYO_LEFT              ; &0ED0: A2 3D
        LDA     PlayerHorizontalStep                       ; &0ED2: A5 57
        BMI     Yoyo_InitialiseMotion                                ; &0ED4: 30 04
        LDA     #&00                                 ; &0ED6: A9 00
        LDX     #SPRITE_TROGG_YOYO_RIGHT             ; &0ED8: A2 3C
Yoyo_InitialiseMotion:
        STA     ObjectDX+YOYO_STRING_SLOT                          ; &0EDA: 8D DA 04
ContinueYoyoAttack:
        TXA                                          ; &0EDD: 8A
        PHA                                          ; &0EDE: 48
        LDX     #TROGG_SLOT                                 ; &0EDF: A2 00
        JSR     WaitForObjectRaster                  ; &0EE1: 20 08 0D
        INC     YoyoExtensionCount                                  ; &0EE4: E6 67
        BEQ     Yoyo_AdvanceHeadPhase                                ; &0EE6: F0 0F
        INX                                          ; &0EE8: E8
        LDA     ObjectSprite,X                       ; &0EE9: BD 5E 04
        CMP     #SPRITE_HIDDEN                                 ; &0EEC: C9 FF
        BEQ     Yoyo_EraseHead                                ; &0EEE: F0 03
        JSR     EraseObjectAndScanCollisions                         ; &0EF0: 20 23 0B
Yoyo_EraseHead:
        INX                                          ; &0EF3: E8
        JSR     EraseObjectAndScanCollisions                         ; &0EF4: 20 23 0B
Yoyo_AdvanceHeadPhase:
        LDX     #YOYO_HEAD_SLOT                                 ; &0EF7: A2 02
        CLC                                          ; &0EF9: 18
        LDA     YoyoSegmentPhase                                  ; &0EFA: A5 66
        ADC     ObjectDX,X                           ; &0EFC: 7D D9 04
        BMI     Yoyo_UseLastHeadPhase                                ; &0EFF: 30 08
        CMP     #YOYO_HEAD_FRAME_COUNT                                 ; &0F01: C9 04
        BCC     Yoyo_StoreHeadPhase                                ; &0F03: 90 06
        LDA     #&00                                 ; &0F05: A9 00
        BEQ     Yoyo_StoreHeadPhase                                ; &0F07: F0 02
Yoyo_UseLastHeadPhase:
        LDA     #YOYO_HEAD_FRAME_COUNT-1                                 ; &0F09: A9 03
Yoyo_StoreHeadPhase:
        STA     YoyoSegmentPhase                                  ; &0F0B: 85 66
        TAX                                          ; &0F0D: AA
        LDA     YoyoHeadSpriteTable,X                 ; &0F0E: BD 7E 0E
        LDX     #YOYO_HEAD_SLOT                                 ; &0F11: A2 02
        STA     ObjectSprite,X                       ; &0F13: 9D 5E 04
        LDA     PlayerHorizontalStep                       ; &0F16: A5 57
        CMP     ObjectDX+YOYO_HEAD_SLOT                          ; &0F18: CD DB 04
        BNE     Yoyo_MoveComponents                                ; &0F1B: D0 19
        LDA     ObjectX,X                            ; &0F1D: BD 68 03
        CMP     #YOYO_RIGHT_LIMIT                                 ; &0F20: C9 C8
        BCS     Yoyo_BeginRetraction                                ; &0F22: B0 0F
        LDA     YoyoExtensionCount                                  ; &0F24: A5 67
        CMP     #YOYO_MIN_EXTENSION                                 ; &0F26: C9 05
        BCC     Yoyo_MoveComponents                                ; &0F28: 90 0C
        CMP     #YOYO_MAX_EXTENSION                                 ; &0F2A: C9 0B
        BCS     Yoyo_BeginRetraction                                ; &0F2C: B0 05
        JSR     ReadYoyoControl                             ; &0F2E: 20 59 13
        BNE     Yoyo_MoveComponents                                ; &0F31: D0 03
Yoyo_BeginRetraction:
        JSR     RetractYoyo                                ; &0F33: 20 74 10
Yoyo_MoveComponents:
        CLC                                          ; &0F36: 18
        LDA     ObjectX,X                            ; &0F37: BD 68 03
        ADC     ObjectDX,X                           ; &0F3A: 7D D9 04
        CLC                                          ; &0F3D: 18
        ADC     ObjectDX,X                           ; &0F3E: 7D D9 04
        STA     ObjectX,X                            ; &0F41: 9D 68 03
        DEX                                          ; &0F44: CA
        BNE     Yoyo_MoveComponents                                ; &0F45: D0 EF
        CLC                                          ; &0F47: 18
        LDA     YoyoAnimationIndex                                  ; &0F48: A5 78
        ADC     YoyoExtensionDirection                                  ; &0F4A: 65 79
        STA     YoyoAnimationIndex                                  ; &0F4C: 85 78
        TAY                                          ; &0F4E: A8
        LDA     YoyoStringSpriteTable,Y               ; &0F4F: B9 82 0E
        STA     ObjectSprite+YOYO_STRING_SLOT                      ; &0F52: 8D 5F 04
        LDA     ObjectX+YOYO_HEAD_SLOT                           ; &0F55: AD 6A 03
        CMP     YoyoBaseX                                  ; &0F58: C5 65
        BEQ     Yoyo_Finished                                ; &0F5A: F0 74
        LDX     #YOYO_HEAD_SLOT                                 ; &0F5C: A2 02
        LDA     #COLLIDE_YOYO                                 ; &0F5E: A9 08
        BIT     CountdownFlags                       ; &0F60: 24 85
        BMI     Yoyo_CheckCollision                                ; &0F62: 30 04
        BVC     Yoyo_CheckCollision                                ; &0F64: 50 02
        LDA     #COLLIDE_YOYO_DARK                                 ; &0F66: A9 80
Yoyo_CheckCollision:
        JSR     ScanObjectCollisions                                ; &0F68: 20 BD 1C
        BCS     Yoyo_CollisionHit                                ; &0F6B: B0 0C
Yoyo_RedrawComponentsLoop:
        JSR     DrawObject                         ; &0F6D: 20 20 0B
        DEX                                          ; &0F70: CA
        BNE     Yoyo_RedrawComponentsLoop                                ; &0F71: D0 FA
        PLA                                          ; &0F73: 68
        TAX                                          ; &0F74: AA
Yoyo_ReturnPlayerY:
        LDY     ObjectY                              ; &0F75: AC E3 03
        RTS                                          ; &0F78: 60
Yoyo_CollisionHit:
        LDX     #<YoyoHitSoundBlock                  ; &0F79: A2 AC
        JSR     SoundOSWORD7                         ; &0F7B: 20 A9 18
        LDA     CollidedQueueDescriptor                                  ; &0F7E: A5 94
        CMP     #QUEUE_MONSTERS                                 ; &0F80: C9 0C
        BNE     Yoyo_RemoveHitObject                                ; &0F82: D0 36
        LDX     #YOYO_STRING_SLOT                                 ; &0F84: A2 01
        JSR     DrawObject                         ; &0F86: 20 20 0B
        INX                                          ; &0F89: E8
        JSR     DrawObject                         ; &0F8A: 20 20 0B
        LDX     CollidedObjectSlot                      ; &0F8D: A6 64
        LDA     #YOYO_KNOCKBACK_FRAMES               ; &0F8F: A9 05
        STA     YoyoKnockbackFramesRemaining                         ; &0F91: 85 34
Yoyo_KnockbackLoop:
        JSR     WaitForTickChange                    ; &0F93: 20 01 0D
        JSR     WaitForObjectRaster                  ; &0F96: 20 08 0D
        JSR     EraseObjectAndScanCollisions                         ; &0F99: 20 23 0B
        LDA     ObjectX,X                            ; &0F9C: BD 68 03
        LDY     #YOYO_KNOCKBACK_STEPS                ; &0F9F: A0 08
Yoyo_KnockbackXLoop:
        CLC                                          ; &0FA1: 18
        ADC     PlayerHorizontalStep                       ; &0FA2: 65 57
        DEY                                          ; &0FA4: 88
        BNE     Yoyo_KnockbackXLoop                                ; &0FA5: D0 FA
        STA     ObjectX,X                            ; &0FA7: 9D 68 03
        JSR     DrawObject                         ; &0FAA: 20 20 0B
        DEC     YoyoKnockbackFramesRemaining                         ; &0FAD: C6 34
        BNE     Yoyo_KnockbackLoop                                ; &0FAF: D0 E2
        LDX     #&01                                 ; &0FB1: A2 01
        JSR     EraseObjectAndScanCollisions                         ; &0FB3: 20 23 0B
        INX                                          ; &0FB6: E8
        JSR     EraseObjectAndScanCollisions                         ; &0FB7: 20 23 0B
Yoyo_RemoveHitObject:
        JSR     RetractYoyo                                ; &0FBA: 20 74 10
        LDX     CollidedObjectSlot                      ; &0FBD: A6 64
        JSR     EraseCollidedObject                  ; &0FBF: 20 A0 12
        LDA     #SCORE_MONSTER_BCD                                 ; &0FC2: A9 25
        JSR     AddScoreBCD                          ; &0FC4: 20 B8 15
        JSR     DrawStatus                           ; &0FC7: 20 DB 15
        DEC     ScrollRefreshRequestFlag                         ; &0FCA: C6 70
        LDX     #YOYO_HEAD_SLOT                                 ; &0FCC: A2 02
        BNE     Yoyo_RedrawComponentsLoop                                ; &0FCE: D0 9D
Yoyo_Finished:
        INC     YoyoActiveFlag                              ; &0FD0: E6 55
        LDA     #SPRITE_HIDDEN                                 ; &0FD2: A9 FF
        STA     ObjectSprite+YOYO_STRING_SLOT                      ; &0FD4: 8D 5F 04
        STA     ObjectSprite+YOYO_HEAD_SLOT                      ; &0FD7: 8D 60 04
        PLA                                          ; &0FDA: 68
        LDX     PlayerFrameSprite                      ; &0FDB: A6 58
        BNE     Yoyo_ReturnPlayerY                                ; &0FDD: D0 96
PlayerDispatch_StartYoyo:
        JMP     UpdateYoyoAttack                          ; &0FDF: 4C 8F 0E
PlayerDispatch_Climbing:
        JMP     UpdateClimbingPlayer                                ; &0FE2: 4C 3B 11
PlayerDispatch_Airborne:
        JMP     UpdateAirbornePlayer                                ; &0FE5: 4C DE 10
PlayerDispatch_ContinueYoyo:
        JMP     ContinueYoyoAttack                   ; &0FE8: 4C DD 0E
; CONTRACT: calculate Trogg movement/animation for one player update.
; Entry: Y=current player Y.
; Effect: reads controls, updates proposed X/Y/sprite and dispatches climb/airborne/yo-yo paths.
UpdatePlayerMotion:
        LSR     JumpInputHistory                                  ; &0FEB: 46 5D
        LDX     ObjectSprite                         ; &0FED: AE 5E 04
        LDY     ObjectY                              ; &0FF0: AC E3 03
        BIT     YoyoActiveFlag                              ; &0FF3: 24 55
        BMI     PlayerDispatch_ContinueYoyo                                ; &0FF5: 30 F1
        BIT     PlayerAirborneFlag                              ; &0FF7: 24 53
        BMI     PlayerDispatch_Airborne                                ; &0FF9: 30 EA
        BIT     PlayerClimbingFlag                              ; &0FFB: 24 54
        BMI     PlayerDispatch_Climbing                                ; &0FFD: 30 E3
        LDX     #&00                                 ; &0FFF: A2 00
        JSR     ReadHorizontal                       ; &1001: 20 F9 12
        STX     ObjectDX                             ; &1004: 8E D9 04
        TXA                                          ; &1007: 8A
        BEQ     PlayerMotion_SelectCurrentFrame                                ; &1008: F0 02
        STX     PlayerHorizontalStep                       ; &100A: 86 57
PlayerMotion_SelectCurrentFrame:
        LDX     ObjectSprite                         ; &100C: AE 5E 04
        STX     PlayerFrameSprite                      ; &100F: 86 58
        JSR     ReadVertical                         ; &1011: 20 1D 13
        CPY     ObjectY                              ; &1014: CC E3 03
        BEQ     PlayerMotion_LatchJumpInput                                ; &1017: F0 16
        JSR     TryAttachLadder                                ; &1019: 20 2F 0E
        BCS     PlayerMotion_Return                                ; &101C: B0 4B
        CPY     ObjectY                              ; &101E: CC E3 03
        LDY     ObjectY                              ; &1021: AC E3 03
        BCC     PlayerMotion_LatchJumpInput                                ; &1024: 90 09
        BIT     JumpInputHistory                                  ; &1026: 24 5D
        BVC     PlayerMotion_UpdateWalkAnimation                                ; &1028: 50 0A
        BCC     PlayerMotion_LatchJumpInput                                ; &102A: 90 03
        JMP     StartPlayerJump                                ; &102C: 4C CB 10
PlayerMotion_LatchJumpInput:
        ASL     JumpInputHistory                                  ; &102F: 06 5D
        SEC                                          ; &1031: 38
        ROR     JumpInputHistory                                  ; &1032: 66 5D
PlayerMotion_UpdateWalkAnimation:
        LDA     ObjectDX                             ; &1034: AD D9 04
        BEQ     PlayerMotion_CheckYoyo                                ; &1037: F0 20
        BMI     PlayerMotion_WalkLeft                                ; &1039: 30 11
        LDX     WalkAnimationPhase                           ; &103B: A6 32
        INX                                          ; &103D: E8
        CPX     #PLAYER_WALK_FRAME_COUNT                                 ; &103E: E0 04
        BCC     PlayerMotion_StoreRightWalkPhase                                ; &1040: 90 02
        LDX     #&00                                 ; &1042: A2 00
PlayerMotion_StoreRightWalkPhase:
        STX     WalkAnimationPhase                           ; &1044: 86 32
        LDA     PlayerWalkFramesRight,X              ; &1046: BD 8A 12
        TAX                                          ; &1049: AA
        BNE     PlayerMotion_CheckYoyo                                ; &104A: D0 0D
PlayerMotion_WalkLeft:
        LDX     WalkAnimationPhase                           ; &104C: A6 32
        DEX                                          ; &104E: CA
        BPL     PlayerMotion_StoreLeftWalkPhase                                ; &104F: 10 02
        LDX     #PLAYER_WALK_FRAME_LAST             ; &1051: A2 03
PlayerMotion_StoreLeftWalkPhase:
        STX     WalkAnimationPhase                           ; &1053: 86 32
        LDA     PlayerWalkFramesLeft,X               ; &1055: BD 8E 12
        TAX                                          ; &1058: AA
PlayerMotion_CheckYoyo:
        JSR     ReadYoyoControl                             ; &1059: 20 59 13
        BNE     PlayerDispatch_StartYoyo                                ; &105C: D0 81
        LDA     #&00                                 ; &105E: A9 00
        JSR     TestPlayerMove                             ; &1060: 20 85 10
        BCS     PlayerMotion_SetSupportY                                ; &1063: B0 05
        LDA     #&FF                                 ; &1065: A9 FF
        STA     PlayerAirborneFlag                              ; &1067: 85 53
PlayerMotion_Return:
        RTS                                          ; &1069: 60
PlayerMotion_SetSupportY:
        LDY     CollidedObjectSlot                      ; &106A: A4 64
        STY     SupportObjectSlot                    ; &106C: 84 77
        LDA     ObjectY,Y                            ; &106E: B9 E3 03
        TAY                                          ; &1071: A8
        INY                                          ; &1072: C8
        RTS                                          ; &1073: 60
RetractYoyo:
        LDA     #&FF                                 ; &1074: A9 FF
        STA     YoyoExtensionDirection                                  ; &1076: 85 79
        LDA     PlayerHorizontalStep                       ; &1078: A5 57
        EOR     #SIGNED_UNIT_FLIP_MASK                                 ; &107A: 49 FE
        STA     ObjectDX+YOYO_HEAD_SLOT                          ; &107C: 8D DB 04
        BMI     PlayerMotion_Return                                ; &107F: 30 E8
        STA     ObjectDX+YOYO_STRING_SLOT                          ; &1081: 8D DA 04
        RTS                                          ; &1084: 60

; -----------------------------------------------------------------------------
; Runtime &1085: movement/collision feasibility test.
; -----------------------------------------------------------------------------
; CONTRACT: test proposed Trogg motion against floors and landing rules.
; Entry: player slot/state in object arrays; proposed motion in ObjectDX/ObjectDY.
; Return: collision/landing condition through flags; restores saved registers before return.
TestPlayerMove:
        STA     MovementObjectSlot                            ; &1085: 85 26
        TXA                                          ; &1087: 8A
        PHA                                          ; &1088: 48
        TYA                                          ; &1089: 98
        PHA                                          ; &108A: 48
        LDX     MovementObjectSlot                            ; &108B: A6 26
        CLC                                          ; &108D: 18
        LDA     ObjectX,X                            ; &108E: BD 68 03
        ADC     ObjectDX,X                           ; &1091: 7D D9 04
        STA     CollisionLeft                                  ; &1094: 85 45
        STA     CollisionRight                                  ; &1096: 85 46
        INC     CollisionRight                                  ; &1098: E6 46
        CLC                                          ; &109A: 18
        LDA     ObjectY,X                            ; &109B: BD E3 03
        STA     CollisionTop                                  ; &109E: 85 47
        ADC     ObjectDY,X                           ; &10A0: 7D F0 04
        STA     CollisionBottom                                  ; &10A3: 85 48
        LDA     ObjectDY,X                           ; &10A5: BD F0 04
        BPL     TestPlayerMove_ReturnCollisionValue                                ; &10A8: 10 1B
        LDA     #COLLIDE_FLOOR                       ; &10AA: A9 02
        JSR     CollisionScan                        ; &10AC: 20 72 14
        BCC     TestPlayerMove_RestoreRegisters                                ; &10AF: 90 15
        LDX     CollisionSourceObjectSlot                     ; &10B1: A6 33
        LDA     #PLAYER_FLOOR_PROBE_DY_LIMIT                                 ; &10B3: A9 F6
        CMP     ObjectDY,X                           ; &10B5: DD F0 04
        BCS     TestPlayerMove_RestoreRegisters                                ; &10B8: B0 0C
        LDX     CollidedObjectSlot                      ; &10BA: A6 64
        SEC                                          ; &10BC: 38
        LDA     ObjectY,X                            ; &10BD: BD E3 03
        SBC     CollisionBottom                                  ; &10C0: E5 48
        SEC                                          ; &10C2: 38
        SBC     #PLAYER_LANDING_Y_ADJUST              ; &10C3: E9 05
TestPlayerMove_ReturnCollisionValue:
        ASL     A                                    ; &10C5: 0A
TestPlayerMove_RestoreRegisters:
        PLA                                          ; &10C6: 68
        TAY                                          ; &10C7: A8
        PLA                                          ; &10C8: 68
        TAX                                          ; &10C9: AA
        RTS                                          ; &10CA: 60
StartPlayerJump:
        LDA     #PLAYER_INITIAL_JUMP_DY               ; &10CB: A9 05
        STA     ObjectDY                             ; &10CD: 8D F0 04
        DEC     PlayerAirborneFlag                              ; &10D0: C6 53
        LDA     ObjectDX                             ; &10D2: AD D9 04
        BEQ     Airborne_Enter                                ; &10D5: F0 07
        LDX     #SPRITE_TROGG_FRAME2                 ; &10D7: A2 36
        ASL     A                                    ; &10D9: 0A
        BCC     Airborne_Enter                                ; &10DA: 90 02
        LDX     #SPRITE_TROGG_FRAME6                 ; &10DC: A2 3A
Airborne_Enter:
; CONTRACT: update jumping/falling Trogg state.
; Effect: applies vertical velocity/gravity, ceiling/floor tests and fatal-landing threshold.
UpdateAirbornePlayer:
        JSR     ReadVertical                         ; &10DE: 20 1D 13
        CLC                                          ; &10E1: 18
        LDA     ObjectY                              ; &10E2: AD E3 03
        ADC     ObjectDY                             ; &10E5: 6D F0 04
        BIT     ObjectDY                             ; &10E8: 2C F0 04
        BPL     Airborne_CheckTopBoundary                                ; &10EB: 10 06
        BCS     Airborne_ApplyGravity                                ; &10ED: B0 12
        LDY     #&00                                 ; &10EF: A0 00
        BEQ     Airborne_LandOrDie                                ; &10F1: F0 33
Airborne_CheckTopBoundary:
        CMP     #PLAYER_Y_CEILING                    ; &10F3: C9 DE
        BCC     Airborne_ApplyGravity                                ; &10F5: 90 0A
        LDA     #&00                                 ; &10F7: A9 00
        SBC     ObjectDY                             ; &10F9: ED F0 04
        STA     ObjectDY                             ; &10FC: 8D F0 04
        LDA     #PLAYER_Y_CEILING                    ; &10FF: A9 DE
Airborne_ApplyGravity:
        DEC     ObjectDY                             ; &1101: CE F0 04
        CPY     ObjectY                              ; &1104: CC E3 03
        PHP                                          ; &1107: 08
        TAY                                          ; &1108: A8
        PLP                                          ; &1109: 28
        BEQ     Airborne_TestMovement                                ; &110A: F0 0C
        LDA     ObjectDY                             ; &110C: AD F0 04
        CMP     #PLAYER_MAX_SAFE_FALL_DY             ; &110F: C9 F9
        BMI     Airborne_TestMovement                                ; &1111: 30 05
        JSR     TryAttachLadder                                ; &1113: 20 2F 0E
        BCS     Airborne_LandOrDie                                ; &1116: B0 0E
Airborne_TestMovement:
        LDA     #&00                                 ; &1118: A9 00
        JSR     TestPlayerMove                             ; &111A: 20 85 10
        BCC     Airborne_Return                                ; &111D: 90 1B
        LDY     CollidedObjectSlot                      ; &111F: A4 64
        LDA     ObjectY,Y                            ; &1121: B9 E3 03
        TAY                                          ; &1124: A8
        INY                                          ; &1125: C8
Airborne_LandOrDie:
        INC     PlayerAirborneFlag                              ; &1126: E6 53
        LDA     ObjectDY                             ; &1128: AD F0 04
        CMP     #PLAYER_MAX_SAFE_FALL_DY             ; &112B: C9 F9
        BPL     Airborne_SetDownwardVelocity                                ; &112D: 10 06
        CMP     #PLAYER_MAX_SAFE_FALL_DY             ; &112F: C9 F9
        BCS     Airborne_SetDownwardVelocity                                ; &1131: B0 02
        DEC     PlayerDeadFlag                     ; &1133: C6 7B
Airborne_SetDownwardVelocity:
        LDA     #&FF                                 ; &1135: A9 FF
        STA     ObjectDY                             ; &1137: 8D F0 04
Airborne_Return:
        RTS                                          ; &113A: 60
; CONTRACT: update ladder/rope climbing.
; Effect: reads vertical control, toggles climbing sprite, maintains ladder attachment or falls.
UpdateClimbingPlayer:
        LDA     #&00                                 ; &113B: A9 00
        JSR     TestLadderCollision                  ; &113D: 20 0B 0E
        BCC     Climb_LadderLostStartFalling                                ; &1140: 90 5D
        JSR     ReadVertical                         ; &1142: 20 1D 13
        LDA     ObjectSprite                         ; &1145: AD 5E 04
        CPY     ObjectY                              ; &1148: CC E3 03
        BEQ     Climb_SaveSprite                                ; &114B: F0 02
        EOR     #CLIMB_SPRITE_TOGGLE_MASK            ; &114D: 49 07
Climb_SaveSprite:
        PHA                                          ; &114F: 48
        LDX     CollidedObjectSlot                      ; &1150: A6 64
        LDA     #CLIMB_CORRECTION_RANDOM_MAX        ; &1152: A9 02
        JSR     RandomUpToA                         ; &1154: 20 B6 0D
        LSR     A                                    ; &1157: 4A
        LDA     #&00                                 ; &1158: A9 00
        BCC     Climb_StoreHorizontalCorrection                                ; &115A: 90 0A
        SEC                                          ; &115C: 38
        LDA     ObjectX,X                            ; &115D: BD 68 03
        SBC     ObjectX                              ; &1160: ED 68 03
        JSR     SignA                                ; &1163: 20 AE 15
Climb_StoreHorizontalCorrection:
        STA     ObjectDX                             ; &1166: 8D D9 04
        TYA                                          ; &1169: 98
        CMP     ObjectY,X                            ; &116A: DD E3 03
        BCS     Climb_CheckLowerFloor                                ; &116D: B0 18
        CPY     ObjectY                              ; &116F: CC E3 03
        BCS     Climb_ReturnCurrentSprite                                ; &1172: B0 28
        TYA                                          ; &1174: 98
        JSR     TestFloorCollision                   ; &1175: 20 5F 0E
        BCC     Climb_ReturnCurrentSprite                                ; &1178: 90 22
Climb_DetachAtFloor:
        LDX     CollidedObjectSlot                      ; &117A: A6 64
        LDA     ObjectY,X                            ; &117C: BD E3 03
        TAY                                          ; &117F: A8
        INY                                          ; &1180: C8
        INC     PlayerClimbingFlag                              ; &1181: E6 54
        LDX     PlayerFrameSprite                      ; &1183: A6 58
        PLA                                          ; &1185: 68
        RTS                                          ; &1186: 60
Climb_CheckLowerFloor:
        CPY     ObjectY                              ; &1187: CC E3 03
        BCC     Climb_ReturnCurrentSprite                                ; &118A: 90 10
        BEQ     Climb_ReturnCurrentSprite                                ; &118C: F0 0E
        LDA     ObjectY                              ; &118E: AD E3 03
        JSR     TestFloorCollision                   ; &1191: 20 5F 0E
        BCC     Climb_ReturnCurrentSprite                                ; &1194: 90 06
        TYA                                          ; &1196: 98
        JSR     TestFloorCollision                   ; &1197: 20 5F 0E
        BCC     Climb_DetachAtFloor                                ; &119A: 90 DE
Climb_ReturnCurrentSprite:
        PLA                                          ; &119C: 68
        TAX                                          ; &119D: AA
        RTS                                          ; &119E: 60
Climb_LadderLostStartFalling:
        INC     PlayerClimbingFlag                              ; &119F: E6 54
        DEC     PlayerAirborneFlag                              ; &11A1: C6 53
        LDA     #&00                                 ; &11A3: A9 00
        STA     ObjectDX                             ; &11A5: 8D D9 04
        LDX     PlayerFrameSprite                      ; &11A8: A6 58
        RTS                                          ; &11AA: 60
UnusedRtsPadding_11AB:
        EQUB &60    ; runtime &11AB - unreferenced RTS byte/padding retained exactly from original

; -----------------------------------------------------------------------------
; SUBSYSTEM: PLAYER FRAME COMMIT + PICKUPS / HAZARDS
; Movement routines propose the next player state, this block applies scrolling,
; redraws Trogg, then checks collectible and hazard collisions.
;
; Runtime &11AC: main Trogg/player frame update.
; -----------------------------------------------------------------------------
; CONTRACT: commit one visible player frame.
; Effect: waits for next tick, computes movement, performs scroll, redraws Trogg, then scans
; collectibles and hazards. Sets PlayerDeadFlag/KeysRemainingMinusOne as appropriate.
UpdatePlayerFrame:
        LDA     TickCounter                          ; &11AC: A5 44
        SEC                                          ; &11AE: 38
        SBC     LastTick                             ; &11AF: E5 71
        CMP     #PLAYER_UPDATE_DIVISOR              ; &11B1: C9 04
        BCC     UpdatePlayerFrame                     ; &11B3: 90 F7
        LDA     TickCounter                          ; &11B5: A5 44
        STA     LastTick                             ; &11B7: 85 71
        LDA     #&00                                 ; &11B9: A9 00
        STA     ScrollDirectionFlags                        ; &11BB: 85 52
        LDY     ObjectY                              ; &11BD: AC E3 03
        JSR     UpdatePlayerMotion                   ; &11C0: 20 EB 0F
        CLC                                          ; &11C3: 18
        LDA     ObjectX                              ; &11C4: AD 68 03
        ADC     ObjectDX                             ; &11C7: 6D D9 04
        CMP     #PLAYER_X_MIN                        ; &11CA: C9 04
        BCC     PlayerFrame_ClampXToCurrent                                ; &11CC: 90 04
        CMP     #PLAYER_X_MAX_EXCLUSIVE              ; &11CE: C9 C4
        BCC     PlayerFrame_StoreProposedState                                ; &11D0: 90 03
PlayerFrame_ClampXToCurrent:
        LDA     ObjectX                              ; &11D2: AD 68 03
PlayerFrame_StoreProposedState:
        STA     PendingObjectX                                  ; &11D5: 85 69
        STX     PendingObjectSprite                                  ; &11D7: 86 68
        STY     PendingObjectY                                  ; &11D9: 84 6A
        CMP     ObjectX                              ; &11DB: CD 68 03
        BEQ     CommitPlayerState                                ; &11DE: F0 23
        BCC     PlayerFrame_ScrollLeftCandidate                                ; &11E0: 90 12
        CMP     #SCROLL_RIGHT_TRIGGER_MAX            ; &11E2: C9 A0
        BCS     CommitPlayerState                                ; &11E4: B0 1D
        CMP     #SCROLL_RIGHT_TRIGGER_MIN            ; &11E6: C9 29
        BCC     CommitPlayerState                                ; &11E8: 90 19
        LDA     #SCROLL_RIGHT                        ; &11EA: A9 80
        STA     ScrollDirectionFlags                        ; &11EC: 85 52
        JSR     ScrollViewportRight                                ; &11EE: 20 E5 13
        JMP     CommitPlayerState                    ; &11F1: 4C 03 12
PlayerFrame_ScrollLeftCandidate:
        CMP     #SCROLL_LEFT_TRIGGER_MIN             ; &11F4: C9 28
        BCC     CommitPlayerState                                ; &11F6: 90 0B
        CMP     #SCROLL_LEFT_TRIGGER_MAX             ; &11F8: C9 9F
        BCS     CommitPlayerState                                ; &11FA: B0 07
        LDA     #SCROLL_LEFT                         ; &11FC: A9 40
        STA     ScrollDirectionFlags                        ; &11FE: 85 52
        JSR     ScrollViewportLeft                                ; &1200: 20 CB 13
CommitPlayerState:
        LDX     #&00                                 ; &1203: A2 00
        JSR     ObjectStateChanged                                ; &1205: 20 3F 1C
        BEQ     CommitPlayer_CheckCollectibles                                ; &1208: F0 3C
        LDA     PendingObjectY                                  ; &120A: A5 6A
        LSR     A                                    ; &120C: 4A
        LSR     A                                    ; &120D: 4A
        STA     PlayerMovePitch                      ; &120E: 8D B8 01
        LDX     #<PlayerMoveSoundBlock               ; &1211: A2 B4
        JSR     SoundOSWORD7                         ; &1213: 20 A9 18
        LDX     #&00                                 ; &1216: A2 00
        BIT     YoyoActiveFlag                              ; &1218: 24 55
        BMI     CommitPlayer_SetCrtcOrigin                                ; &121A: 30 06
        JSR     WaitForTickChange                    ; &121C: 20 01 0D
        JSR     WaitForObjectRaster                  ; &121F: 20 08 0D
CommitPlayer_SetCrtcOrigin:
        JSR     SetCrtcOrigin                        ; &1222: 20 28 14
        LDA     ScrollDirectionFlags                        ; &1225: A5 52
        BEQ     CommitPlayer_Redraw                                ; &1227: F0 02
        DEC     ScrollRefreshRequestFlag                         ; &1229: C6 70
CommitPlayer_Redraw:
        LDX     #&00                                 ; &122B: A2 00
        JSR     EraseObject                         ; &122D: 20 1C 0B
        LDA     PendingObjectSprite                                  ; &1230: A5 68
        LDX     PendingObjectX                                  ; &1232: A6 69
        LDY     PendingObjectY                                  ; &1234: A4 6A
        JSR     DrawSpriteAt                         ; &1236: 20 32 0B
        LDA     PendingObjectY                                  ; &1239: A5 6A
        JSR     WaitForRasterAtY                     ; &123B: 20 0B 0D
        LDX     #&00                                 ; &123E: A2 00
        JSR     DrawObjectAndScanCollisions                         ; &1240: 20 18 0B
        JSR     RestoreObjectSnapshot                                ; &1243: 20 53 1C
CommitPlayer_CheckCollectibles:
        JSR     DrawObject                         ; &1246: 20 20 0B
        LDA     #COLLIDE_COLLECTIBLE                                 ; &1249: A9 10
        JSR     ScanObjectCollisions                                ; &124B: 20 BD 1C
        BCC     CommitPlayer_CheckHazards                                ; &124E: 90 0C
        LDX     CollidedObjectSlot                      ; &1250: A6 64
        LDA     ObjectSprite,X                       ; &1252: BD 5E 04
        LDY     #&00                                 ; &1255: A0 00
        JSR     TypeDispatch                         ; &1257: 20 D1 12
        LDX     #&00                                 ; &125A: A2 00
CommitPlayer_CheckHazards:
        LDA     ObjectY,X                            ; &125C: BD E3 03
        BEQ     CommitPlayer_MarkDead                                ; &125F: F0 07
        LDA     #COLLIDE_PLAYER_HAZARD                                 ; &1261: A9 01
        JSR     ScanObjectCollisions                                ; &1263: 20 BD 1C
        BCC     CommitPlayer_DeathEffects                                ; &1266: 90 02
CommitPlayer_MarkDead:
        DEC     PlayerDeadFlag                     ; &1268: C6 7B
CommitPlayer_DeathEffects:
        BIT     PlayerDeadFlag                     ; &126A: 24 7B
        BPL     CommitPlayer_HandleScrollRedraw                                ; &126C: 10 10
        LDA     #TuneOffsetDeath                                 ; &126E: A9 8E
        JSR     SelectTune                           ; &1270: 20 B4 18
        LDX     ObjectX                              ; &1273: AE 68 03
        LDY     ObjectY                              ; &1276: AC E3 03
        LDA     #SPRITE_TROGG_DEATH                                 ; &1279: A9 5B
        JSR     DrawSpriteAt                         ; &127B: 20 32 0B
CommitPlayer_HandleScrollRedraw:
        BIT     ScrollDirectionFlags                        ; &127E: 24 52
        BVS     CommitPlayer_RedrawLeftEdge                                ; &1280: 70 05
        BPL     Collect_Return                                ; &1282: 10 24
        JMP     RedrawRightEdge                                ; &1284: 4C F3 13
CommitPlayer_RedrawLeftEdge:
        JMP     RedrawLeftEdge                                ; &1287: 4C D9 13
; Four-frame walking cycles.  The left-facing sequence is stored in reverse
; frame order so the same 0..3 phase counter can be stepped in the opposite
; direction without changing the composite Trogg sprite definitions.
PlayerWalkFramesRight:
        EQUB SPRITE_TROGG_FRAME0,SPRITE_TROGG_FRAME1,SPRITE_TROGG_FRAME2,SPRITE_TROGG_FRAME3
PlayerWalkFramesLeft:
        EQUB SPRITE_TROGG_FRAME7,SPRITE_TROGG_FRAME6,SPRITE_TROGG_FRAME5,SPRITE_TROGG_FRAME4

; -----------------------------------------------------------------------------
; Runtime &1292: key pickup.
; -----------------------------------------------------------------------------
KeyCollect:
        LDA     #SCORE_KEY_BCD                                 ; &1292: A9 50
        JSR     AddScoreBCD                          ; &1294: 20 B8 15
        DEC     KeysRemainingMinusOne                        ; &1297: C6 7A
CollectObjectAndSound:
        LDX     #<CollectSoundBlock                  ; &1299: A2 BC
        JSR     SoundOSWORD7                         ; &129B: 20 A9 18
        LDX     CollidedObjectSlot                      ; &129E: A6 64
EraseCollidedObject:
        JSR     EraseObjectAndScanCollisions                         ; &12A0: 20 23 0B
        LDA     #OBJECT_EMPTY                                 ; &12A3: A9 FF
        STA     ObjectSprite,X                       ; &12A5: 9D 5E 04
Collect_Return:
        RTS                                          ; &12A8: 60

; -----------------------------------------------------------------------------
; Runtime &12A9: gem pickup.
; -----------------------------------------------------------------------------
GemCollect:
        LDA     #SCORE_GEM_BCD                                 ; &12A9: A9 15
        JSR     AddScoreBCD                          ; &12AB: 20 B8 15
CollectObjectRefreshStatus:
        JSR     CollectObjectAndSound                ; &12AE: 20 99 12
        JSR     DrawStatus                           ; &12B1: 20 DB 15
        DEC     ScrollRefreshRequestFlag                         ; &12B4: C6 70
Collect_ReturnNoChange:
        RTS                                          ; &12B6: 60

; -----------------------------------------------------------------------------
; Runtime &12B7: light-bulb/time pickup.
; -----------------------------------------------------------------------------
BulbCollect:
        BIT     CountdownFlags                       ; &12B7: 24 85
        BMI     Bulb_AddTime                                ; &12B9: 30 02
        BVS     Collect_ReturnNoChange                                ; &12BB: 70 F9
Bulb_AddTime:
        CLC                                          ; &12BD: 18
        SED                                          ; &12BE: F8
        LDA     TimeLoBCD                            ; &12BF: A5 82
        ADC     #BULB_TIME_BONUS_BCD                                 ; &12C1: 69 10
        CMP     #BCD_SECONDS_PER_MINUTE                                 ; &12C3: C9 60
        BCC     Bulb_StoreTime                                ; &12C5: 90 04
        SBC     #BCD_SECONDS_PER_MINUTE                                 ; &12C7: E9 60
        INC     TimeHiBCD                            ; &12C9: E6 83
Bulb_StoreTime:
        STA     TimeLoBCD                            ; &12CB: 85 82
        CLD                                          ; &12CD: D8
        JMP     CollectObjectRefreshStatus           ; &12CE: 4C AE 12

; -----------------------------------------------------------------------------
; SUBSYSTEM: OBJECT-TYPE DISPATCH + CONTROL INPUT
; Collectible handlers and dynamic hazard handlers share a compact type->routine
; table; keyboard/joystick readers follow immediately afterwards.
;
; Runtime &12D1: object type dispatcher.
; -----------------------------------------------------------------------------
; CONTRACT: dispatch an object sprite/type through ObjectTypeDispatchTable.
; Entry: A=sprite/type; Y=queue descriptor offset used as dispatch-table start context.
; Effect: invokes collection or dynamic-movement handler when a matching record exists.
TypeDispatch:
        CMP     ObjectTypeDispatchTable,Y             ; &12D1: D9 EA 12
        BEQ     TypeDispatch_Found                                ; &12D4: F0 05
        INY                                          ; &12D6: C8
        INY                                          ; &12D7: C8
        INY                                          ; &12D8: C8
        BNE     TypeDispatch                    ; &12D9: D0 F6
TypeDispatch_Found:
        PHA                                          ; &12DB: 48
        LDA     ObjectTypeDispatchTable+TYPE_DISPATCH_HANDLER_LO,Y           ; &12DC: B9 EB 12
        STA     TypeDispatchPtrLo                       ; &12DF: 85 29
        LDA     ObjectTypeDispatchTable+TYPE_DISPATCH_HANDLER_HI,Y           ; &12E1: B9 EC 12
        STA     TypeDispatchPtrHi                       ; &12E4: 85 2A
        PLA                                          ; &12E6: 68
        JMP     (TypeDispatchPtrLo)                    ; &12E7: 6C 29 00

; Type-specific actions used both by collectible collision handling and by the
; two dynamic hazard queues.  Each record is sprite/type byte + handler word.
ObjectTypeDispatchTable:
        EQUB SPRITE_KEY
        EQUW KeyCollect
        EQUB SPRITE_BULB
        EQUW BulbCollect
        EQUB SPRITE_GEM
        EQUW GemCollect
        EQUB SPRITE_BALLOON
        EQUW BalloonMovement
        EQUB SPRITE_DAGGER
        EQUW DaggerMovement

; -----------------------------------------------------------------------------
; Runtime &12F9: horizontal control reader.
; -----------------------------------------------------------------------------
; CONTRACT: read horizontal control under current ControlScheme.
; Return: X/current movement value encodes left, neutral or right according to caller convention.
ReadHorizontal:
        LDA     ControlScheme                            ; &12F9: A5 86
        BNE     ReadHorizontal_Joystick                                ; &12FB: D0 11
        LDA     #KEY_LEFT_Z                                 ; &12FD: A9 9E
        JSR     Inkey                                ; &12FF: 20 9C 0D
        BEQ     ReadHorizontal_CheckRight                                ; &1302: F0 01
        DEX                                          ; &1304: CA
ReadHorizontal_CheckRight:
        LDA     #KEY_RIGHT_X                                 ; &1305: A9 BD
        JSR     Inkey                                ; &1307: 20 9C 0D
        BEQ     ReadHorizontal_Return                                ; &130A: F0 01
ReadHorizontal_Positive:
        INX                                          ; &130C: E8
ReadHorizontal_Return:
        RTS                                          ; &130D: 60
ReadHorizontal_Joystick:
        LDA     #JOYSTICK_X_CHANNEL                                 ; &130E: A9 01
        JSR     ReadJoystickAxis                    ; &1310: 20 76 13
        CMP     #JOYSTICK_LOW_THRESHOLD                                 ; &1313: C9 64
        BCC     ReadHorizontal_Positive                                ; &1315: 90 F5
        CMP     #JOYSTICK_HIGH_THRESHOLD                                 ; &1317: C9 9C
        BCC     ReadHorizontal_Return                                ; &1319: 90 F2
        DEX                                          ; &131B: CA
        RTS                                          ; &131C: 60

; -----------------------------------------------------------------------------
; Runtime &131D: vertical control reader.
; -----------------------------------------------------------------------------
; CONTRACT: read vertical control under current ControlScheme.
; Return: signed vertical input used by climbing/jump logic.
ReadVertical:
        LDA     ControlScheme                            ; &131D: A5 86
        BNE     ReadVertical_Joystick                                ; &131F: D0 1E
        LDA     #KEY_UP_STAR                                 ; &1321: A9 B7
        JSR     Inkey                                ; &1323: 20 9C 0D
        BEQ     ReadVertical_CheckDown                                ; &1326: F0 03
        JSR     ApplyVerticalPositiveInput                                ; &1328: 20 4C 13
ReadVertical_CheckDown:
        LDA     #KEY_DOWN_QUESTION                                 ; &132B: A9 97
        JSR     Inkey                                ; &132D: 20 9C 0D
        BEQ     ReadVertical_Return                                ; &1330: F0 0C
ReadVertical_NegativeInput:
        DEY                                          ; &1332: 88
        DEY                                          ; &1333: 88
        DEY                                          ; &1334: 88
        BIT     VerticalFlipFlag                          ; &1335: 24 74
        BPL     ReadVertical_Return                                ; &1337: 10 05
        CLC                                          ; &1339: 18
        TYA                                          ; &133A: 98
        ADC     #2*VERTICAL_INPUT_STEP               ; &133B: 69 06
        TAY                                          ; &133D: A8
ReadVertical_Return:
        RTS                                          ; &133E: 60
ReadVertical_Joystick:
        LDA     #JOYSTICK_Y_CHANNEL                                 ; &133F: A9 02
        JSR     ReadJoystickAxis                    ; &1341: 20 76 13
        CMP     #JOYSTICK_LOW_THRESHOLD                                 ; &1344: C9 64
        BCC     ReadVertical_NegativeInput                                ; &1346: 90 EA
        CMP     #JOYSTICK_HIGH_THRESHOLD                                 ; &1348: C9 9C
        BCC     ReadVertical_Return                                ; &134A: 90 F2
ApplyVerticalPositiveInput:
        INY                                          ; &134C: C8
        INY                                          ; &134D: C8
        INY                                          ; &134E: C8
        BIT     VerticalFlipFlag                          ; &134F: 24 74
        BPL     ReadVertical_PositiveReturn                                ; &1351: 10 05
        SEC                                          ; &1353: 38
        TYA                                          ; &1354: 98
        SBC     #2*VERTICAL_INPUT_STEP               ; &1355: E9 06
        TAY                                          ; &1357: A8
ReadVertical_PositiveReturn:
        RTS                                          ; &1358: 60

; -----------------------------------------------------------------------------
; Runtime &1359: yoyo/alternate control reader.
; -----------------------------------------------------------------------------
ReadYoyoControl:
        LDA     ControlScheme                            ; &1359: A5 86
        BNE     ReadYoyoControl_Joystick                                ; &135B: D0 05
        LDA     #KEY_YOYO_RETURN                                 ; &135D: A9 B6
        JMP     Inkey                                ; &135F: 4C 9C 0D
ReadYoyoControl_Joystick:
        TXA                                          ; &1362: 8A
        PHA                                          ; &1363: 48
        TYA                                          ; &1364: 98
        PHA                                          ; &1365: 48
        LDA     #JOYSTICK_FIRE_SELECTOR                                 ; &1366: A9 00
        JSR     OSBYTEJoystickRead                  ; &1368: 20 8A 13
        STX     JoystickScratch                            ; &136B: 86 26
        PLA                                          ; &136D: 68
        TAY                                          ; &136E: A8
        PLA                                          ; &136F: 68
        TAX                                          ; &1370: AA
        LDA     JoystickScratch                            ; &1371: A5 26
        AND     #JOYSTICK_FIRE_MASK                                 ; &1373: 29 01
        RTS                                          ; &1375: 60
ReadJoystickAxis:
        STA     JoystickScratch                            ; &1376: 85 26
        TXA                                          ; &1378: 8A
        PHA                                          ; &1379: 48
        TYA                                          ; &137A: 98
        PHA                                          ; &137B: 48
        LDA     JoystickScratch                            ; &137C: A5 26
        JSR     OSBYTEJoystickRead                  ; &137E: 20 8A 13
        STY     JoystickScratch                            ; &1381: 84 26
        PLA                                          ; &1383: 68
        TAY                                          ; &1384: A8
        PLA                                          ; &1385: 68
        TAX                                          ; &1386: AA
        LDA     JoystickScratch                            ; &1387: A5 26
        RTS                                          ; &1389: 60
OSBYTEJoystickRead:
        TAX                                          ; &138A: AA
        LDA     #OSBYTE_READ_ADC                                 ; &138B: A9 80
        JMP     OSBYTEWrapper                        ; &138D: 4C FB 0D
ClearExposedScreenStrip:
        LDX     #MODE1_TEXT_ROWS                     ; &1390: A2 20
        LDA     SharedScratch26                            ; &1392: A5 26  ; original dead instruction: value is discarded by the next LDA
        LDA     #&00                                 ; &1394: A9 00
        STA     ScreenClearPtrLo                        ; &1396: 85 3F
        LDY     ScreenOriginLo                                  ; &1398: A4 0C
        LDA     ScreenOriginHi                                  ; &139A: A5 0D
ClearExposedScreenStrip_RowLoop:
        STA     ScreenClearPtrHi                        ; &139C: 85 40
        LDA     #&00                                 ; &139E: A9 00
        STA     (ScreenClearPtrLo),Y                    ; &13A0: 91 3F
        INY                                          ; &13A2: C8
        STA     (ScreenClearPtrLo),Y                    ; &13A3: 91 3F
        INY                                          ; &13A5: C8
        STA     (ScreenClearPtrLo),Y                    ; &13A6: 91 3F
        INY                                          ; &13A8: C8
        STA     (ScreenClearPtrLo),Y                    ; &13A9: 91 3F
        INY                                          ; &13AB: C8
        STA     (ScreenClearPtrLo),Y                    ; &13AC: 91 3F
        INY                                          ; &13AE: C8
        STA     (ScreenClearPtrLo),Y                    ; &13AF: 91 3F
        INY                                          ; &13B1: C8
        STA     (ScreenClearPtrLo),Y                    ; &13B2: 91 3F
        INY                                          ; &13B4: C8
        STA     (ScreenClearPtrLo),Y                    ; &13B5: 91 3F
        DEX                                          ; &13B7: CA
        BEQ     ClearExposedScreenStrip_Return                                ; &13B8: F0 10
        CLC                                          ; &13BA: 18
        TYA                                          ; &13BB: 98
        ADC     #MODE1_TEXT_ROW_LOW_ADJUST           ; &13BC: 69 79
        TAY                                          ; &13BE: A8
        LDA     ScreenClearPtrHi                        ; &13BF: A5 40
        ADC     #MODE1_TEXT_ROW_HIGH_ADJUST          ; &13C1: 69 02
        BPL     ClearExposedScreenStrip_RowLoop                                ; &13C3: 10 D7
        SEC                                          ; &13C5: 38
        SBC     #MODE1_SCREEN_RING_SIZE_HI           ; &13C6: E9 50
        BPL     ClearExposedScreenStrip_RowLoop                                ; &13C8: 10 D2
ClearExposedScreenStrip_Return:
        RTS                                          ; &13CA: 60
ScrollViewportLeft:
        LDY     #MODE1_SCROLL_LEFT_DELTA_LO          ; &13CB: A0 F8
        LDA     #MODE1_SCROLL_LEFT_DELTA_HI          ; &13CD: A9 FF
        JSR     AdjustScreenOrigin                  ; &13CF: 20 11 14
        JSR     ClearExposedScreenStrip                                ; &13D2: 20 90 13
        DEC     ViewportXOffset                                  ; &13D5: C6 10
        CLC                                          ; &13D7: 18
        RTS                                          ; &13D8: 60
RedrawLeftEdge:
        LDA     #&01                                 ; &13D9: A9 01
        STA     ClipRight                                  ; &13DB: 85 0F
        JSR     DrawAllObjects                          ; &13DD: 20 FF 13
        LDA     #MODE1_VIEWPORT_COLUMNS              ; &13E0: A9 50
        STA     ClipRight                                  ; &13E2: 85 0F
        RTS                                          ; &13E4: 60
ScrollViewportRight:
        JSR     ClearExposedScreenStrip                                ; &13E5: 20 90 13
        LDY     #MODE1_SCROLL_RIGHT_DELTA_LO         ; &13E8: A0 08
        LDA     #MODE1_SCROLL_RIGHT_DELTA_HI         ; &13EA: A9 00
        JSR     AdjustScreenOrigin                  ; &13EC: 20 11 14
        INC     ViewportXOffset                                  ; &13EF: E6 10
        CLC                                          ; &13F1: 18
        RTS                                          ; &13F2: 60
RedrawRightEdge:
        LDA     #MODE1_RIGHTMOST_COLUMN              ; &13F3: A9 4F
        STA     ClipLeft                                  ; &13F5: 85 0E
        JSR     DrawAllObjects                          ; &13F7: 20 FF 13
        LDA     #&00                                 ; &13FA: A9 00
        STA     ClipLeft                                  ; &13FC: 85 0E
        RTS                                          ; &13FE: 60

; -----------------------------------------------------------------------------
; Runtime &13FF: Routine13FF.
; -----------------------------------------------------------------------------
DrawAllObjects:
        LDX     #OBJECT_SLOT_COUNT-1                 ; &13FF: A2 7A
DrawAllObjects_Loop:
        LDA     ObjectSprite,X                       ; &1401: BD 5E 04
        CMP     #&FF                                 ; &1404: C9 FF
        BEQ     DrawAllObjects_Next                                ; &1406: F0 03
        JSR     DrawObject                         ; &1408: 20 20 0B
DrawAllObjects_Next:
        DEX                                          ; &140B: CA
        CPX     #&FF                                 ; &140C: E0 FF
        BNE     DrawAllObjects_Loop                                ; &140E: D0 F1
        RTS                                          ; &1410: 60
AdjustScreenOrigin:
        PHA                                          ; &1411: 48
        CLC                                          ; &1412: 18
        TYA                                          ; &1413: 98
        ADC     ScreenOriginLo                                  ; &1414: 65 0C
        STA     ScreenOriginLo                                  ; &1416: 85 0C
        PLA                                          ; &1418: 68
        ADC     ScreenOriginHi                                  ; &1419: 65 0D
        BPL     AdjustScreenOrigin_CheckUnderflow                                ; &141B: 10 02
        SBC     #MODE1_RIGHTMOST_COLUMN              ; &141D: E9 4F
AdjustScreenOrigin_CheckUnderflow:
        CMP     #&00                                 ; &141F: C9 00
        BCS     AdjustScreenOrigin_Store                                ; &1421: B0 02
        ADC     #MODE1_SCREEN_RING_SIZE_HI           ; &1423: 69 50
AdjustScreenOrigin_Store:
        STA     ScreenOriginHi                                  ; &1425: 85 0D
        RTS                                          ; &1427: 60

; -----------------------------------------------------------------------------
; SUBSYSTEM: HARDWARE SCROLL + COLLISION / DISPLAY GEOMETRY
; CRTC start-address changes provide horizontal scrolling. The backing page at
; &0900 rebuilds newly exposed strips; collision uses recursive sprite bounds.
;
; Runtime &1428: program CRTC screen origin.
; -----------------------------------------------------------------------------
SetCrtcOrigin:
        LDA     ScreenOriginLo                                  ; &1428: A5 0C
        STA     CrtcStartAddressLo                     ; &142A: 85 3F
        LDA     ScreenOriginHi                                  ; &142C: A5 0D
        LSR     A                                    ; &142E: 4A
        ROR     CrtcStartAddressLo                     ; &142F: 66 3F
        LSR     A                                    ; &1431: 4A
        ROR     CrtcStartAddressLo                     ; &1432: 66 3F
        LSR     A                                    ; &1434: 4A
        ROR     CrtcStartAddressLo                     ; &1435: 66 3F
        LDX     #CRTC_SCREEN_START_HI                ; &1437: A2 0C
        SEI                                          ; &1439: 78
        STX     CRTC_ADDRESS                         ; &143A: 8E 00 FE
        STA     CRTC_DATA                            ; &143D: 8D 01 FE
        INX                                          ; &1440: E8
        LDA     CrtcStartAddressLo                     ; &1441: A5 3F
        STX     CRTC_ADDRESS                         ; &1443: 8E 00 FE
        STA     CRTC_DATA                            ; &1446: 8D 01 FE
        CLI                                          ; &1449: 58
        RTS                                          ; &144A: 60
; Rebuild the newly exposed MODE 1 strip from the 256-byte backing page at
; &0900.  This routine is called after the CRTC origin moves by one column.
RefreshScrollBuffer:
        LDY #MODE1_SCANLINES_PER_CHAR-1
        SEC
        TYA
        ADC ScreenOriginLo
        STA ScrollCopyPtrLo
        LDA #&00
RefreshScroll_ClearOldEdge:
        STA (ScreenOriginLo),Y
        DEY
        BPL RefreshScroll_ClearOldEdge
        ADC ScreenOriginHi
        STA ScrollCopyPtrHi
        INY                         ; Y wraps from &FF to 0
RefreshScroll_CopyBackingPage:
        LDA ScrollBackingBuffer,Y
        STA (ScrollCopyPtrLo),Y
        INY
        BNE RefreshScroll_CopyBackingPage
        TYA                         ; A=0
        INC ScrollCopyPtrHi
        LDY #MODE1_SCANLINES_PER_CHAR-1
RefreshScroll_ClearNewEdge:
        STA (ScrollCopyPtrLo),Y
        DEY
        BPL RefreshScroll_ClearNewEdge
        RTS

; -----------------------------------------------------------------------------
; Runtime &1472: collision scan.
; -----------------------------------------------------------------------------
; CONTRACT: scan queues selected by CollisionMask for object overlap.
; Entry: X=current object slot; CollisionMask selects eligible queue descriptors.
; Return: carry set on collision, with CollidedObjectSlot/CollidedQueueDescriptor populated.
CollisionScan:
        STA     CollisionMask                                  ; &1472: 85 5A
        STX     CollisionSourceObjectSlot                     ; &1474: 86 33
        JSR     ResetSpriteBounds                                ; &1476: 20 19 1D
        JSR     AccumulateSpriteBounds+3                                ; &1479: 20 9C 1D
CollisionScanPrepared:
        TXA                                          ; &147C: 8A
        PHA                                          ; &147D: 48
        TYA                                          ; &147E: 98
        PHA                                          ; &147F: 48
        LDA     CurrentSpriteX                       ; &1480: A5 11
        PHA                                          ; &1482: 48
        LDA     CurrentSpriteY                       ; &1483: A5 12
        PHA                                          ; &1485: 48
        LDY     #&00                                 ; &1486: A0 00
CollisionScan_NextQueue:
        STY     ScanQueueDescriptor                                  ; &1488: 84 95
        LDA     QueueDescriptors+QUEUE_DESC_TAG,Y                              ; &148A: B9 02 0B
        BEQ     CollisionScan_NoHit                                ; &148D: F0 32
        LDA     CollisionMask                                  ; &148F: A5 5A
        CMP     #&FF                                 ; &1491: C9 FF
        BEQ     CollisionScan_StartQueue                                ; &1493: F0 05
        AND     QueueDescriptors+QUEUE_DESC_COLLISION,Y                              ; &1495: 39 01 0B
        BEQ     CollisionScan_AdvanceQueue                                ; &1498: F0 22
CollisionScan_StartQueue:
        LDX     QueueDescriptors,Y                   ; &149A: BE 00 0B
CollisionScan_NextObject:
        CPX     CollisionSourceObjectSlot                     ; &149D: E4 33
        BEQ     CollisionScan_AdvanceObject                                ; &149F: F0 12
        JSR     LoadObject                           ; &14A1: 20 3C 0B
        BCS     CollisionScan_AdvanceObject                                ; &14A4: B0 0D
        JSR     TestSpriteCollision                                ; &14A6: 20 B1 1C
        BCC     CollisionScan_AdvanceObject                                ; &14A9: 90 08
        STX     CollidedObjectSlot                      ; &14AB: 86 64
        LDY     ScanQueueDescriptor                                  ; &14AD: A4 95
        STY     CollidedQueueDescriptor                                  ; &14AF: 84 94
        BCS     CollisionScan_RestoreAndReturn                                ; &14B1: B0 0F
CollisionScan_AdvanceObject:
        INX                                          ; &14B3: E8
        LDY     ScanQueueDescriptor                                  ; &14B4: A4 95
        TXA                                          ; &14B6: 8A
        CMP     QueueDescriptors+QUEUE_DESC_END_SLOT,Y                              ; &14B7: D9 03 0B
        BCC     CollisionScan_NextObject                                ; &14BA: 90 E1
CollisionScan_AdvanceQueue:
        INY                                          ; &14BC: C8
        INY                                          ; &14BD: C8
        INY                                          ; &14BE: C8
        BNE     CollisionScan_NextQueue                                ; &14BF: D0 C7
CollisionScan_NoHit:
        CLC                                          ; &14C1: 18
CollisionScan_RestoreAndReturn:
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
DisplayInit:
        LDA     #&00                                 ; &14CD: A9 00
        STA     ViewportXOffset                                  ; &14CF: 85 10
ApplyDisplayTransform:
        LDA     #&00                                 ; &14D1: A9 00
        STA     ScreenOriginLo                                  ; &14D3: 85 0C
        LDA     #MODE1_SCREEN_BASE_HI               ; &14D5: A9 30
        STA     ScreenOriginHi                                  ; &14D7: 85 0D
        LDA     #&00                                 ; &14D9: A9 00
        STA     ClipLeft                                  ; &14DB: 85 0E
        LDA     #MODE1_VIEWPORT_COLUMNS             ; &14DD: A9 50
        STA     ClipRight                                  ; &14DF: 85 0F
        LDA     #&00                                 ; &14E1: A9 00
        STA     VerticalFlipFlag                          ; &14E3: 85 74
        TYA                                          ; &14E5: 98
        LSR     A                                    ; &14E6: 4A
        BCC     ApplyDisplayTransform_SetPalette                                ; &14E7: 90 02
        DEC     VerticalFlipFlag                          ; &14E9: C6 74
ApplyDisplayTransform_SetPalette:
        JSR     PrintInlineStream                    ; &14EB: 20 21 0D
        EQUB &16,&01,&13,&01,&05,&00,&00,&00,&13,&02,&03,&00,&00,&00,&11,&82    ; runtime &14EE
        EQUB &13,&03,&00,&00,&00,&00,&EA    ; runtime &14FE
        JSR     HideTextCursor                      ; &1505: 20 74 15
        TYA                                          ; &1508: 98
        LSR     A                                    ; &1509: 4A
        LSR     A                                    ; &150A: 4A
        BCS     ApplyDisplayTransform_AlternatePalette                                ; &150B: B0 1C
        PHP                                          ; &150D: 08
        LDA     ScreenColourTable,X                  ; &150E: BD 68 19
        PLP                                          ; &1511: 28
        BEQ     ApplyDisplayTransform_WriteColour                                ; &1512: F0 02
        LDA     #&00                                 ; &1514: A9 00
ApplyDisplayTransform_WriteColour:
        PHA                                          ; &1516: 48
        JSR     PrintInlineStream                    ; &1517: 20 21 0D
        EQUB &13,&00,&EA    ; runtime &151A
        PLA                                          ; &151D: 68
        JSR     OSWRCH                               ; &151E: 20 EE FF
        JSR     PrintInlineStream                    ; &1521: 20 21 0D
        EQUB &00,&00,&00,&EA    ; runtime &1524
        RTS                                          ; &1528: 60
ApplyDisplayTransform_AlternatePalette:
        BNE     ApplyDisplayTransform_ThirdPalette                                ; &1529: D0 1D
        JSR     PrintInlineStream                    ; &152B: 20 21 0D
        EQUB &13,&00,&07,&00,&00,&00,&13,&01,&07,&00,&00,&00,&13,&02,&07,&00    ; runtime &152E
        EQUB &00,&00,&13,&03,&00,&00,&00,&00,&EA    ; runtime &153E
        RTS                                          ; &1547: 60
ApplyDisplayTransform_ThirdPalette:
        JSR     PrintInlineStream                    ; &1548: 20 21 0D
        EQUB &13,&00,&00,&00,&00,&00,&13,&01,&00,&00,&00,&00,&13,&02,&00,&00    ; runtime &154B
        EQUB &00,&00,&13,&03,&07,&00,&00,&00,&EA    ; runtime &155B
        RTS                                          ; &1564: 60

; -----------------------------------------------------------------------------
; Runtime &1565: clear the 256-byte scroll backing page at &0900.
; -----------------------------------------------------------------------------
ClearScrollBackingBuffer:
        LDY     #&00                                 ; &1565: A0 00
        TYA                                          ; &1567: 98
ClearScrollBackingBuffer_Loop:
        STA     ScrollBackingBuffer,Y                              ; &1568: 99 00 09
        DEY                                          ; &156B: 88
        BNE     ClearScrollBackingBuffer_Loop                                ; &156C: D0 FA
        LDA     #>ScrollBackingBuffer               ; &156E: A9 09
        STA     VDUScreenBaseHi                                ; &1570: 8D 51 03
        RTS                                          ; &1573: 60
HideTextCursor:
        JSR     PrintInlineStream                    ; &1574: 20 21 0D
        EQUB &17,&01,&00,&00,&00,&00,&00,&00,&00,&00,&EA    ; runtime &1577
        RTS                                          ; &1582: 60
ShowTextCursor:
        JSR     PrintInlineStream                    ; &1583: 20 21 0D
        EQUB &17,&01,&01,&00,&00,&00,&00,&00,&00,&00,&EA    ; runtime &1586
        RTS                                          ; &1591: 60
ComputePrimitiveBounds:
        CLC                                          ; &1592: 18
        LDA     CurrentSpriteX                       ; &1593: A5 11
        ADC     (SpriteXOffsetPtrLo),Y                              ; &1595: 71 00
        STA     CollisionLeft                                  ; &1597: 85 45
        LDA     (SpriteWidthPtrLo),Y                              ; &1599: B1 08
        ASL     A                                    ; &159B: 0A
        LSR     A                                    ; &159C: 4A
        ADC     CollisionLeft                                  ; &159D: 65 45
        STA     CollisionRight                                  ; &159F: 85 46
        CLC                                          ; &15A1: 18
        LDA     CurrentSpriteY                       ; &15A2: A5 12
        ADC     (SpriteYOffsetPtrLo),Y                              ; &15A4: 71 02
        STA     CollisionBottom                                  ; &15A6: 85 48
        CLC                                          ; &15A8: 18
        ADC     (SpriteHeightPtrLo),Y                              ; &15A9: 71 0A
        STA     CollisionTop                                  ; &15AB: 85 47
        RTS                                          ; &15AD: 60
; Convert A to -1, 0 or +1 while preserving zero as zero.
SignA:
        BEQ     SignA_Return                                ; &15AE: F0 07
        BMI     SignA_Negative                                ; &15B0: 30 03
        LDA     #PLAYER_STEP_RIGHT                                 ; &15B2: A9 01
        RTS                                          ; &15B4: 60
SignA_Negative:
        LDA     #PLAYER_STEP_LEFT                                 ; &15B5: A9 FF
SignA_Return:
        RTS                                          ; &15B7: 60

; -----------------------------------------------------------------------------
; SUBSYSTEM: SCORE, STATUS AND HIGH-SCORE ENTRY
; Scores are packed BCD; DrawStatus renders time/lives/score and HighScoreInsert
; maintains the six-entry table plus interactive initials selection.
;
; Runtime &15B8: packed-BCD score addition.
; -----------------------------------------------------------------------------
; CONTRACT: add packed-BCD amount in A to the displayed score.
; Entry: A=packed BCD increment in units of 10 displayed points.
; Effect: propagates carry through three score bytes and awards a life on the 20,000 boundary bit.
AddScoreBCD:
        LDY     #&00                                 ; &15B8: A0 00
        CLC                                          ; &15BA: 18
        SED                                          ; &15BB: F8
        ADC     ScoreLo                              ; &15BC: 65 38
        STA     ScoreLo                              ; &15BE: 85 38
        LDA     ScoreMid                             ; &15C0: A5 39
        STA     PreviousScoreMid                            ; &15C2: 85 26
        TYA                                          ; &15C4: 98
        ADC     ScoreMid                             ; &15C5: 65 39
        STA     ScoreMid                             ; &15C7: 85 39
        EOR     PreviousScoreMid                            ; &15C9: 45 26
        AND     #EXTRA_LIFE_SCORE_BIT                                 ; &15CB: 29 20
        PHA                                          ; &15CD: 48
        LDA     #&00                                 ; &15CE: A9 00
        ADC     ScoreHi                              ; &15D0: 65 3A
        STA     ScoreHi                              ; &15D2: 85 3A
        CLD                                          ; &15D4: D8
        PLA                                          ; &15D5: 68
        BEQ     AddScoreBCD_Return                                ; &15D6: F0 02
        INC     Lives                                ; &15D8: E6 3B
AddScoreBCD_Return:
        RTS                                          ; &15DA: 60

; -----------------------------------------------------------------------------
; Runtime &15DB: status display.
; -----------------------------------------------------------------------------
DrawStatus:
        JSR     ClearScrollBackingBuffer                          ; &15DB: 20 65 15
        LDA     #VDU_HOME                            ; &15DE: A9 1E
        JSR     OSWRCH                               ; &15E0: 20 EE FF
        SEC                                          ; &15E3: 38
        LDA     TimeHiBCD                            ; &15E4: A5 83
        JSR     PrintBCDNibble                      ; &15E6: 20 2F 16
        LDA     #ASCII_COLON                         ; &15E9: A9 3A
        JSR     OSWRCH                               ; &15EB: 20 EE FF
        SEC                                          ; &15EE: 38
        LDA     TimeLoBCD                            ; &15EF: A5 82
        JSR     PrintPackedBCD                      ; &15F1: 20 24 16
        LDA     #VDU_CURSOR_RIGHT                    ; &15F4: A9 09
        JSR     OSWRCH                               ; &15F6: 20 EE FF
        SEC                                          ; &15F9: 38
        LDA     Lives                                ; &15FA: A5 3B
        SBC     #&01                                 ; &15FC: E9 01
        SEC                                          ; &15FE: 38
        JSR     PrintBCDNibble                      ; &15FF: 20 2F 16
        LDA     #VDU_CURSOR_RIGHT                    ; &1602: A9 09
        JSR     OSWRCH                               ; &1604: 20 EE FF
        CLC                                          ; &1607: 18
        LDA     ScoreHi                              ; &1608: A5 3A
        JSR     PrintBCDNibble                      ; &160A: 20 2F 16
        LDA     ScoreMid                             ; &160D: A5 39
        JSR     PrintPackedBCD                      ; &160F: 20 24 16
        BCC     DrawStatus_PrintScoreLo                                ; &1612: 90 06
        LDA     #ASCII_COMMA                         ; &1614: A9 2C
        JSR     OSWRCH                               ; &1616: 20 EE FF
        SEC                                          ; &1619: 38
DrawStatus_PrintScoreLo:
        LDA     ScoreLo                              ; &161A: A5 38
        JSR     PrintPackedBCD                      ; &161C: 20 24 16
        LDA     #ASCII_ZERO                          ; &161F: A9 30
        JMP     OSWRCH                               ; &1621: 4C EE FF
PrintPackedBCD:
        PHA                                          ; &1624: 48
        PHP                                          ; &1625: 08
        LSR     A                                    ; &1626: 4A
        LSR     A                                    ; &1627: 4A
        LSR     A                                    ; &1628: 4A
        LSR     A                                    ; &1629: 4A
        PLP                                          ; &162A: 28
        JSR     PrintBCDNibble                      ; &162B: 20 2F 16
        PLA                                          ; &162E: 68
PrintBCDNibble:
        AND     #BCD_NIBBLE_MASK                     ; &162F: 29 0F
        BNE     PrintBCDNibble_Emit                                ; &1631: D0 02
        BCC     PrintBCDNibble_Return                                ; &1633: 90 06
PrintBCDNibble_Emit:
        ORA     #ASCII_ZERO                          ; &1635: 09 30
        JSR     OSWRCH                               ; &1637: 20 EE FF
        SEC                                          ; &163A: 38
PrintBCDNibble_Return:
        RTS                                          ; &163B: 60

; -----------------------------------------------------------------------------
; Runtime &163C: wait A ticks while still polling pause/start controls.
; -----------------------------------------------------------------------------
DelayWithInput:
        TAY                                          ; &163C: A8
DelayWithInput_PollLoop:
        JSR     TimerAndKeys                         ; &163D: 20 2C 0C
        BEQ     DelayWithInput_WaitTick                                ; &1640: F0 04
        BIT     ControlScheme                            ; &1642: 24 86
        BPL     DelayWithInput_Return                                ; &1644: 10 06
DelayWithInput_WaitTick:
        JSR     WaitForTickChange                    ; &1646: 20 01 0D
        DEY                                          ; &1649: 88
        BNE     DelayWithInput_PollLoop                                ; &164A: D0 F1
DelayWithInput_Return:
        RTS                                          ; &164C: 60

; -----------------------------------------------------------------------------
; Runtime &164D: high-score insertion.
; -----------------------------------------------------------------------------
; CONTRACT: compare current score with six-entry table and collect initials if qualified.
; Return: carry/flow distinguishes title return versus immediate new-game restart paths.
HighScoreInsert:
        TSX                                          ; &164D: BA
        STX     SavedAbortStackPtr                                  ; &164E: 86 7E
        LDA     #HIGH_SCORE_COUNT                    ; &1650: A9 06
        STA     HighScoreRankNumber                          ; &1652: 85 42
        LDY     #&FF                                 ; &1654: A0 FF
        LDX     #HIGH_SCORE_LAST_RECORD              ; &1656: A2 1E
HighScoreInsert_CompareLoop:
        LDA     ScoreLo                              ; &1658: A5 38
        CMP     HighScores+HIGH_SCORE_SCORE_LO,X                              ; &165A: DD 85 08
        LDA     ScoreMid                             ; &165D: A5 39
        SBC     HighScores+HIGH_SCORE_SCORE_MID,X                              ; &165F: FD 84 08
        LDA     ScoreHi                              ; &1662: A5 3A
        SBC     HighScores+HIGH_SCORE_SCORE_HI,X                              ; &1664: FD 83 08
        BCC     HighScoreInsert_FoundPosition                                ; &1667: 90 09
        DEC     HighScoreRankNumber                          ; &1669: C6 42
        TXA                                          ; &166B: 8A
        TAY                                          ; &166C: A8
        SBC     #HIGH_SCORE_RECORD_SIZE              ; &166D: E9 06
        TAX                                          ; &166F: AA
        BPL     HighScoreInsert_CompareLoop                                ; &1670: 10 E6
HighScoreInsert_FoundPosition:
        TYA                                          ; &1672: 98
        BMI     DelayWithInput_Return                                ; &1673: 30 D7
        STY     HighScoreInsertOffset                            ; &1675: 84 26
        LDX     #HIGH_SCORE_LAST_BYTE                ; &1677: A2 23
HighScoreInsert_ShiftLoop:
        LDA     HighScores-HIGH_SCORE_RECORD_SIZE,X                              ; &1679: BD 7A 08
        STA     HighScores,X                         ; &167C: 9D 80 08
        DEX                                          ; &167F: CA
        CPX     HighScoreInsertOffset                            ; &1680: E4 26
        BPL     HighScoreInsert_ShiftLoop                                ; &1682: 10 F5
        LDA     ScoreLo                              ; &1684: A5 38
        STA     HighScores+HIGH_SCORE_SCORE_LO,Y                              ; &1686: 99 85 08
        LDA     ScoreMid                             ; &1689: A5 39
        STA     HighScores+HIGH_SCORE_SCORE_MID,Y                              ; &168B: 99 84 08
        LDA     ScoreHi                              ; &168E: A5 3A
        STA     HighScores+HIGH_SCORE_SCORE_HI,Y                              ; &1690: 99 83 08
        LDA     #ASCII_SPACE                                 ; &1693: A9 20
        STA     HighScores,Y                         ; &1695: 99 80 08
        STA     HighScores+1,Y                              ; &1698: 99 81 08
        STA     HighScores+2,Y                              ; &169B: 99 82 08
        STY     HighScoreNameOffset                        ; &169E: 84 3F
        LDA     ScreenOriginLo                                  ; &16A0: A5 0C
        STA     VDUScreenBaseLo                                ; &16A2: 8D 50 03
        LDA     ScreenOriginHi                                  ; &16A5: A5 0D
        STA     VDUScreenBaseHi                                ; &16A7: 8D 51 03
        JSR     PrintTitleBanner                                ; &16AA: 20 DA 19
        JSR     PrintInlineStream                    ; &16AD: 20 21 0D
        EQUB &11,&82,&1F,&09,&11,&3C,&2D,&2B,&2D,&3E,&20,&74,&6F,&20,&73,&65    ; runtime &16B0
        EQUB &6C,&65,&63,&74,&20,&6C,&65,&74,&74,&65,&72,&1F,&09,&13,&27,&4A    ; runtime &16C0
        EQUB &75,&6D,&70,&27,&20,&74,&6F,&20,&65,&6E,&74,&65,&72,&20,&6C,&65    ; runtime &16D0
        EQUB &74,&74,&65,&72,&EA    ; runtime &16E0
        JSR     ShowTextCursor                                ; &16E5: 20 83 15
        LDY     HighScoreRankNumber                          ; &16E8: A4 42
        JSR     PrintHighScorePosition                                ; &16EA: 20 B3 1A
        LDA     #HIGH_SCORE_INITIALS                                 ; &16ED: A9 03
        STA     HighScoreInitialsRemaining                          ; &16EF: 85 42
        LDA     #ASCII_A                                 ; &16F1: A9 41
        STA     HighScoreEntryChar                          ; &16F3: 85 41
HighScoreLetterSelectLoop:
        LDA     HighScoreEntryChar                          ; &16F5: A5 41
        JSR     OSWRCH                               ; &16F7: 20 EE FF
        LDA     #ASCII_BACKSPACE                                 ; &16FA: A9 08
        JSR     OSWRCH                               ; &16FC: 20 EE FF
HighScorePollInput:
        JSR     TimerAndKeys                         ; &16FF: 20 2C 0C
        BNE     HighScoreInsert_Return                                ; &1702: D0 56
        LDA     SelectedControlScheme                           ; &1704: A5 87
        STA     ControlScheme                            ; &1706: 85 86
        LDX     HighScoreEntryChar                          ; &1708: A6 41
        JSR     ReadHorizontal                       ; &170A: 20 F9 12
        CPX     HighScoreEntryChar                          ; &170D: E4 41
        BEQ     HighScoreInput_CheckCommit                                ; &170F: F0 19
        CPX     #ASCII_TILDE+1                                 ; &1711: E0 7F
        BCC     HighScoreInput_CheckLowerBound                                ; &1713: 90 04
        LDX     #ASCII_SPACE                                 ; &1715: A2 20
        BCS     HighScoreInput_StoreCharacter                                ; &1717: B0 06
HighScoreInput_CheckLowerBound:
        CPX     #ASCII_SPACE                                 ; &1719: E0 20
        BCS     HighScoreInput_StoreCharacter                                ; &171B: B0 02
        LDX     #ASCII_TILDE                                 ; &171D: A2 7E
HighScoreInput_StoreCharacter:
        TXA                                          ; &171F: 8A
        STA     HighScoreEntryChar                          ; &1720: 85 41
        JSR     OSWRCH                               ; &1722: 20 EE FF
        LDA     #ASCII_BACKSPACE                                 ; &1725: A9 08
        JSR     OSWRCH                               ; &1727: 20 EE FF
HighScoreInput_CheckCommit:
        LDY     #&FF                                 ; &172A: A0 FF
        JSR     ReadVertical                         ; &172C: 20 1D 13
        TYA                                          ; &172F: 98
        BMI     HighScoreInput_WaitAndRetry                                ; &1730: 30 18
        LDY     HighScoreNameOffset                        ; &1732: A4 3F
        LDA     HighScoreEntryChar                          ; &1734: A5 41
        STA     HighScores,Y                         ; &1736: 99 80 08
        JSR     OSWRCH                               ; &1739: 20 EE FF
        INC     HighScoreNameOffset                        ; &173C: E6 3F
        DEC     HighScoreInitialsRemaining                          ; &173E: C6 42
        BEQ     HighScoreInput_Complete                                ; &1740: F0 10
        LDA     #HIGH_SCORE_ACCEPT_DELAY             ; &1742: A9 14
        JSR     WaitFramesOrInput                                ; &1744: 20 C7 1A
        JMP     HighScoreLetterSelectLoop                                ; &1747: 4C F5 16
HighScoreInput_WaitAndRetry:
        LDA     #HIGH_SCORE_RETRY_DELAY              ; &174A: A9 05
        JSR     WaitFramesOrInput                                ; &174C: 20 C7 1A
        JMP     HighScorePollInput                                ; &174F: 4C FF 16
HighScoreInput_Complete:
        JSR     HideTextCursor                                ; &1752: 20 74 15
        LDA     #HIGH_SCORE_FINISH_DELAY             ; &1755: A9 50
        JSR     WaitFramesOrInput                                ; &1757: 20 C7 1A
HighScoreInsert_Return:
        CLC                                          ; &175A: 18
        RTS                                          ; &175B: 60
; -----------------------------------------------------------------------------
; Per-theme mapping from level-stream queue/variant numbers to sprite IDs.
; Each sub-list begins with a queue-descriptor offset, contains one sprite ID
; per variant, and ends in &FF.  A second &FF terminates the complete theme map.
; The three stream theme bytes are "C", "J" and "G"; these select the different
; platform/ladder artwork and the Scrubbly/Poglet/Hooter monster set.
; -----------------------------------------------------------------------------
ThemeGMap:                              ; Level C: Hooters
        EQUB QUEUE_TROGG,SPRITE_TROGG_FRAME0,&FF
        EQUB QUEUE_LADDERS,SPRITE_THEME_G_LADDER0,SPRITE_THEME_G_LADDER1,SPRITE_THEME_G_LADDER2,SPRITE_THEME_G_LADDER3,&FF
        EQUB QUEUE_FLOORS,SPRITE_THEME_G_FLOOR0,SPRITE_THEME_G_FLOOR1,SPRITE_THEME_G_FLOOR2,SPRITE_THEME_G_FLOOR3,SPRITE_THEME_G_FLOOR4,SPRITE_THEME_G_FLOOR5,SPRITE_THEME_G_FLOOR6,&FF
        EQUB QUEUE_MONSTERS,SPRITE_HOOTER,&FF
        EQUB QUEUE_COLLECTIBLES,SPRITE_KEY,SPRITE_BULB,SPRITE_GEM,&FF
        EQUB &FF

ThemeJMap:                              ; Level B: Poglets
        EQUB QUEUE_TROGG,SPRITE_TROGG_FRAME0,&FF
        EQUB QUEUE_FLOORS,SPRITE_THEME_J_FLOOR0,SPRITE_THEME_J_FLOOR1,SPRITE_THEME_J_FLOOR2,SPRITE_THEME_J_FLOOR3,SPRITE_THEME_J_FLOOR4,SPRITE_THEME_J_FLOOR5,&FF
        EQUB QUEUE_LADDERS,SPRITE_THEME_J_LADDER0,SPRITE_THEME_J_LADDER1,SPRITE_THEME_J_LADDER2,SPRITE_THEME_J_LADDER3,&FF
        EQUB QUEUE_MONSTERS,&00,SPRITE_POGLET,&FF
        EQUB QUEUE_COLLECTIBLES,SPRITE_KEY,SPRITE_BULB,SPRITE_GEM,&FF
        EQUB &FF

ThemeCMap:                              ; Level A: Scrubblies
        EQUB QUEUE_TROGG,SPRITE_TROGG_FRAME0,&FF
        EQUB QUEUE_MONSTERS,SPRITE_SCRUBBLY,&FF
        EQUB QUEUE_COLLECTIBLES,SPRITE_KEY,SPRITE_BULB,SPRITE_GEM,&FF
        EQUB QUEUE_LADDERS,SPRITE_THEME_C_LADDER0,SPRITE_THEME_C_LADDER1,SPRITE_THEME_C_LADDER2,SPRITE_THEME_C_LADDER3,SPRITE_THEME_C_LADDER4,&FF
        EQUB QUEUE_FLOORS,SPRITE_THEME_C_FLOOR0,SPRITE_THEME_C_FLOOR1,SPRITE_THEME_C_FLOOR2,SPRITE_THEME_C_FLOOR3,SPRITE_THEME_C_FLOOR4,SPRITE_THEME_C_FLOOR5,SPRITE_THEME_C_FLOOR6,&FF
        EQUB &FF

ThemeMapLookup:
        EQUB "G"
        EQUW ThemeGMap
        EQUB "C"
        EQUW ThemeCMap
        EQUB "J"
        EQUW ThemeJMap
        EQUB &FF

; -----------------------------------------------------------------------------
; SUBSYSTEM: LEVEL DECODER
; Reads theme + queue tags, maps theme-local variants to sprite IDs and fills the
; fixed object arrays with each record's X/Y coordinate pairs.
;
; Runtime &17B8: level stream decoder.
; -----------------------------------------------------------------------------
; CONTRACT: decode one tagged level stream into object arrays.
; Entry: LevelStreamLo/Hi points at theme byte followed by queue blocks.
; Effect: maps theme-specific variants to sprite IDs and allocates coordinates into queue slots.
LoadLevelStream:
        LDX     #&00                                 ; &17B8: A2 00
        LDA     (LevelStreamLo,X)                    ; &17BA: A1 6D
        STA     LevelThemeCode                            ; &17BC: 85 26
Level_FindThemeLoop:
        LDA     ThemeMapLookup,X                              ; &17BE: BD AE 17
        BMI     Level_ErrorBell                                ; &17C1: 30 2F
        CMP     LevelThemeCode                            ; &17C3: C5 26
        BEQ     Level_ThemeFound                                ; &17C5: F0 05
        INX                                          ; &17C7: E8
        INX                                          ; &17C8: E8
        INX                                          ; &17C9: E8
        BNE     Level_FindThemeLoop                                ; &17CA: D0 F2
Level_ThemeFound:
        LDA     ThemeMapLookup+THEME_LOOKUP_PTR_LO,X                              ; &17CC: BD AF 17
        STA     LevelThemeMapLo                                  ; &17CF: 85 6B
        LDA     ThemeMapLookup+THEME_LOOKUP_PTR_HI,X                              ; &17D1: BD B0 17
        STA     LevelThemeMapHi                                  ; &17D4: 85 6C
        INC     LevelStreamLo                        ; &17D6: E6 6D
        BNE     Level_ReadQueueTag                                ; &17D8: D0 02
        INC     LevelStreamHi                        ; &17DA: E6 6E
Level_ReadQueueTag:
        LDX     #&00                                 ; &17DC: A2 00
        LDY     #&00                                 ; &17DE: A0 00
        LDA     (LevelStreamLo,X)                    ; &17E0: A1 6D
        BMI     Level_Return                                ; &17E2: 30 13
Level_FindQueueDescriptor:
        LDA     QueueDescriptors+QUEUE_DESC_TAG,Y                              ; &17E4: B9 02 0B
        BEQ     Level_ErrorBell                                ; &17E7: F0 09
        CMP     (LevelStreamLo,X)                    ; &17E9: C1 6D
        BEQ     Level_QueueFound                                ; &17EB: F0 13
        INY                                          ; &17ED: C8
        INY                                          ; &17EE: C8
        INY                                          ; &17EF: C8
        BNE     Level_FindQueueDescriptor                                ; &17F0: D0 F2
Level_ErrorBell:
        LDA     #VDU_BELL                                 ; &17F2: A9 07
        JSR     OSWRCH                               ; &17F4: 20 EE FF
Level_Return:
        RTS                                          ; &17F7: 60
Level_AdvancePastQueueEnd:
        INC     LevelStreamLo                        ; &17F8: E6 6D
        BNE     Level_ReadQueueTag                                ; &17FA: D0 E0
        INC     LevelStreamHi                        ; &17FC: E6 6E
        BNE     Level_ReadQueueTag                                ; &17FE: D0 DC
Level_QueueFound:
        STY     LevelQueueDescriptor                                  ; &1800: 84 5C
        LDA     QueueDescriptors+QUEUE_DESC_END_SLOT,Y                              ; &1802: B9 03 0B
        STA     LevelQueueEndSlot                        ; &1805: 85 40
        LDX     QueueDescriptors,Y                   ; &1807: BE 00 0B
        LDY     #&00                                 ; &180A: A0 00
        INC     LevelStreamLo                        ; &180C: E6 6D
        BNE     Level_FindVariantGroup                                ; &180E: D0 02
        INC     LevelStreamHi                        ; &1810: E6 6E
Level_FindVariantGroup:
        LDA     (LevelThemeMapLo),Y                              ; &1812: B1 6B
        BMI     Level_ErrorBell                                ; &1814: 30 DC
        CMP     LevelQueueDescriptor                                  ; &1816: C5 5C
        BEQ     Level_VariantGroupFound                                ; &1818: F0 08
Level_SkipVariantList:
        INY                                          ; &181A: C8
        LDA     (LevelThemeMapLo),Y                              ; &181B: B1 6B
        BPL     Level_SkipVariantList                                ; &181D: 10 FB
        INY                                          ; &181F: C8
        BNE     Level_FindVariantGroup                                ; &1820: D0 F0
Level_VariantGroupFound:
        STY     LevelVariantBase                        ; &1822: 84 3F
Level_ReadObjectRecord:
        LDY     #&00                                 ; &1824: A0 00
        SEC                                          ; &1826: 38
        LDA     (LevelStreamLo),Y                    ; &1827: B1 6D
        PHA                                          ; &1829: 48
        AND     #LEVEL_VARIANT_MASK                                 ; &182A: 29 07
        ADC     LevelVariantBase                        ; &182C: 65 3F
        TAY                                          ; &182E: A8
        LDA     (LevelThemeMapLo),Y                              ; &182F: B1 6B
        STA     LevelObjectSprite                   ; &1831: 85 35
        PLA                                          ; &1833: 68
        LSR     A                                    ; &1834: 4A
        LSR     A                                    ; &1835: 4A
        LSR     A                                    ; &1836: 4A
        BEQ     Level_AdvancePastQueueEnd                                ; &1837: F0 BF
        STA     LevelObjectRemaining                            ; &1839: 85 26
        LDY     #&00                                 ; &183B: A0 00
        DEX                                          ; &183D: CA
Level_FindFreeSlotLoop:
        INX                                          ; &183E: E8
        CPX     LevelQueueEndSlot                        ; &183F: E4 40
        BCS     Level_ErrorBell                                ; &1841: B0 AF
        LDA     ObjectSprite,X                       ; &1843: BD 5E 04
        CMP     #OBJECT_EMPTY                                 ; &1846: C9 FF
        BNE     Level_FindFreeSlotLoop                                ; &1848: D0 F4
        INY                                          ; &184A: C8
        LDA     (LevelStreamLo),Y                    ; &184B: B1 6D
        STA     ObjectX,X                            ; &184D: 9D 68 03
        INY                                          ; &1850: C8
        LDA     (LevelStreamLo),Y                    ; &1851: B1 6D
        STA     ObjectY,X                            ; &1853: 9D E3 03
        LDA     LevelObjectSprite                   ; &1856: A5 35
        STA     ObjectSprite,X                       ; &1858: 9D 5E 04
        DEC     LevelObjectRemaining                            ; &185B: C6 26
        BNE     Level_FindFreeSlotLoop                                ; &185D: D0 DF
        SEC                                          ; &185F: 38
        TYA                                          ; &1860: 98
        ADC     LevelStreamLo                        ; &1861: 65 6D
        STA     LevelStreamLo                        ; &1863: 85 6D
        BCC     Level_ReadObjectRecord                                ; &1865: 90 BD
        INC     LevelStreamHi                        ; &1867: E6 6E
        BCS     Level_ReadObjectRecord                                ; &1869: B0 B9

; -----------------------------------------------------------------------------
; SUBSYSTEM: MUSIC / TRANSITIONS
; User VIA Timer 1 clocks this compact stream player. The same area also contains
; screen-complete/title transition animation and the A/B/C metadata tables.
;
; Runtime &186B: music/sound stream step.
; -----------------------------------------------------------------------------
; CONTRACT: advance one encoded music-stream item when the IRQ delay expires.
; Encoding: bits 2..6 pitch, bits 0..1 duration, bit 7 stream terminator.
; Effect: patches MusicPitch and submits MusicSoundBlock through OSWORD 7.
MusicStep:
        LDA     MusicInhibitFlag                          ; &186B: A5 2F
        ORA     MosCallInProgressFlag                           ; &186D: 05 93
        BMI     MusicStep_Return                                ; &186F: 30 37
        BIT     MusicDurationCounter                       ; &1871: 24 91
        BPL     MusicStep_Return                                ; &1873: 10 33
        TXA                                          ; &1875: 8A
        PHA                                          ; &1876: 48
        TYA                                          ; &1877: 98
        PHA                                          ; &1878: 48
        LDY     TuneStreamPosition                                  ; &1879: A4 90
        LDX     SoundStream,Y                        ; &187B: BE 07 05
        INY                                          ; &187E: C8
        TXA                                          ; &187F: 8A
        AND     #MUSIC_PITCH_MASK                                 ; &1880: 29 7C
        STA     MusicPitch                           ; &1882: 8D A8 01
        TXA                                          ; &1885: 8A
        BPL     MusicStep_DecodeDuration                                ; &1886: 10 0A
        LDX     CurrentTuneOffsetSlot                                  ; &1888: A6 8A
        LDY     ZeroPageBase,X                        ; &188A: B4 00  ; X selects TuneOffsetScreenA..TuneOffsetComplete
        CPX     #TuneOffsetDeath                                 ; &188C: E0 8E
        BCC     MusicStep_DecodeDuration                                ; &188E: 90 02
        DEC     MusicInhibitFlag                          ; &1890: C6 2F
MusicStep_DecodeDuration:
        AND     #MUSIC_DURATION_MASK                                 ; &1892: 29 03
        SEC                                          ; &1894: 38
        ADC     #&00                                 ; &1895: 69 00
        ASL     A                                    ; &1897: 0A
        ASL     A                                    ; &1898: 0A
        ADC     MusicDurationCounter                       ; &1899: 65 91
        STA     MusicDurationCounter                       ; &189B: 85 91
        STY     TuneStreamPosition                                  ; &189D: 84 90
        LDX     #<MusicSoundBlock                    ; &189F: A2 A4
        JSR     SoundOSWORD7                         ; &18A1: 20 A9 18
        PLA                                          ; &18A4: 68
        TAY                                          ; &18A5: A8
        PLA                                          ; &18A6: 68
        TAX                                          ; &18A7: AA
MusicStep_Return:
        RTS                                          ; &18A8: 60

; -----------------------------------------------------------------------------
; Runtime &18A9: SoundOSWORD7.
; -----------------------------------------------------------------------------
SoundOSWORD7:
        LDY     #&01                                 ; &18A9: A0 01
        BIT     SoundMutedFlag                         ; &18AB: 24 4B
        BMI     MusicStep_Return                                ; &18AD: 30 F9
        LDA     #OSWORD_SOUND                                 ; &18AF: A9 07
        JMP     OSWORDWrapper                        ; &18B1: 4C 03 0E

; -----------------------------------------------------------------------------
; Runtime &18B4: select tune/effect.
; -----------------------------------------------------------------------------
SelectTune:
        TAX                                          ; &18B4: AA
        STX     CurrentTuneOffsetSlot                                  ; &18B5: 86 8A
        LDA     ZeroPageBase,X                        ; &18B7: B5 00  ; X selects TuneOffsetScreenA..TuneOffsetComplete
        STA     TuneStreamPosition                                  ; &18B9: 85 90
        LDX     #MUSIC_TIMER_RELOAD_LO               ; &18BB: A2 A8
        LDY     #MUSIC_TIMER_RELOAD_HI               ; &18BD: A0 61
        STY     USER_VIA_T1CH                                ; &18BF: 8C 65 FE
        STX     USER_VIA_T1CL                        ; &18C2: 8E 64 FE
        LDA     #&00                                 ; &18C5: A9 00
        STA     MusicDurationCounter                       ; &18C7: 85 91
        STA     MusicInhibitFlag                          ; &18C9: 85 2F
        RTS                                          ; &18CB: 60

; -----------------------------------------------------------------------------
; Runtime &18CC: screen-complete transition.
; -----------------------------------------------------------------------------
ScreenComplete:
        LDA     #TuneOffsetComplete                                 ; &18CC: A9 8F
        JSR     SelectTune                           ; &18CE: 20 B4 18
        JSR     ResetCountdownDivider                ; &18D1: 20 27 0C
        STA     ScrollRefreshRequestFlag                         ; &18D4: 85 70
        LDX     BaseScreen                           ; &18D6: A6 3C
        LDY     TransformCycle                       ; &18D8: A4 3D
        JSR     ApplyDisplayTransform               ; &18DA: 20 D1 14
        JSR     ShowScreenCompleteText              ; &18DD: 20 1F 1B
        LDA     #&FF                                 ; &18E0: A9 FF
        STA     ScrollRefreshRequestFlag                         ; &18E2: 85 70
        LDA     #&01                                 ; &18E4: A9 01
        STA     ObjectDY                             ; &18E6: 8D F0 04
        LDA     #SCREEN_COMPLETE_FRAMES              ; &18E9: A9 3C
        STA     TransitionFramesRemaining                         ; &18EB: 85 34
        LDX     #&01                                 ; &18ED: A2 01
        STX     ObjectDX                             ; &18EF: 8E D9 04
        DEX                                          ; &18F2: CA
        JSR     DrawObject                         ; &18F3: 20 20 0B
        SEC                                          ; &18F6: 38
        BCS     RunTransitionAnimation                                ; &18F7: B0 29
TransitionFromRight:
        LDA     #MODE1_VIEWPORT_COLUMNS             ; &18F9: A9 50
        PHA                                          ; &18FB: 48
        LDY     #&FF                                 ; &18FC: A0 FF
        LDA     #TRANSITION_SCRUBBLY_SEQUENCE_INDEX                                 ; &18FE: A9 06
        LDX     #TRANSITION_SCRUBBLY_SLOT                                 ; &1900: A2 01
        BNE     Transition_StoreVelocity                                ; &1902: D0 09
TransitionFromLeft:
        LDA     #&00                                 ; &1904: A9 00
        PHA                                          ; &1906: 48
        LDY     #&01                                 ; &1907: A0 01
        LDA     #TRANSITION_TROGG_SEQUENCE_INDEX                                 ; &1909: A9 01
        LDX     #TRANSITION_TROGG_SLOT                                 ; &190B: A2 00
Transition_StoreVelocity:
        STA     ObjectDY,X                           ; &190D: 9D F0 04
        TYA                                          ; &1910: 98
        STA     ObjectDX,X                           ; &1911: 9D D9 04
        PLA                                          ; &1914: 68
        STA     ObjectX,X                            ; &1915: 9D 68 03
        LDA     #TRANSITION_TITLE_FRAMES             ; &1918: A9 1F
        STA     TransitionFramesRemaining                         ; &191A: 85 34
        LDA     #TRANSITION_Y                        ; &191C: A9 52
        STA     ObjectY,X                            ; &191E: 9D E3 03
        CLC                                          ; &1921: 18
RunTransitionAnimation:
        PHP                                          ; &1922: 08
Transition_FrameLoop:
        LDA     #TRANSITION_FRAME_DELAY              ; &1923: A9 04
        JSR     DelayWithInput                          ; &1925: 20 3C 16
        PLP                                          ; &1928: 28
        PHP                                          ; &1929: 08
        BCS     Transition_DrawFrame                                ; &192A: B0 03
        JSR     PollAttractInput                    ; &192C: 20 D7 1A
Transition_DrawFrame:
        JSR     WaitForObjectRaster                  ; &192F: 20 08 0D
        JSR     EraseObject                         ; &1932: 20 1C 0B
        CLC                                          ; &1935: 18
        LDA     ObjectX,X                            ; &1936: BD 68 03
        ADC     ObjectDX,X                           ; &1939: 7D D9 04
        STA     ObjectX,X                            ; &193C: 9D 68 03
        LDY     ObjectDY,X                           ; &193F: BC F0 04
Transition_NextSequenceByte:
        INY                                          ; &1942: C8
        LDA     TransitionSpriteSequence,Y           ; &1943: B9 60 19
        BPL     Transition_StoreSprite                                ; &1946: 10 08
Transition_FindDelimiter:
        DEY                                          ; &1948: 88
        LDA     TransitionSpriteSequence,Y           ; &1949: B9 60 19
        BPL     Transition_FindDelimiter                                ; &194C: 10 FA
        BMI     Transition_NextSequenceByte                                ; &194E: 30 F2
Transition_StoreSprite:
        STA     ObjectSprite,X                       ; &1950: 9D 5E 04
        TYA                                          ; &1953: 98
        STA     ObjectDY,X                           ; &1954: 9D F0 04
        JSR     DrawObject                         ; &1957: 20 20 0B
        DEC     TransitionFramesRemaining                         ; &195A: C6 34
        BNE     Transition_FrameLoop                                ; &195C: D0 C5
        PLP                                          ; &195E: 28
        RTS                                          ; &195F: 60
; Sprite sequence used by the shared title/screen-complete animation code.
; Negative bytes are sequence delimiters; positive bytes are sprite IDs.
TransitionSpriteSequence:
        EQUB &FF,&34,&35,&36,&37,&FF,&12,&FF

; Base-screen foreground/palette selector consumed by ApplyDisplayTransform.
; MOD: Base-screen colour selectors. Editing these changes the normal palette choice for screens A/B/C; TransformCycle still applies alternate palettes.
ScreenColourTable:
        EQUB BBC_COLOUR_CYAN,BBC_COLOUR_GREEN,BBC_COLOUR_RED

; Three base screens.  After screen C, BaseScreen wraps and TransformCycle
; advances, giving 3 layouts x 8 transformations = 24 gameplay states.
LevelStreamPtrLoTable:
        EQUB <LevelA,<LevelB,<LevelC
LevelStreamPtrHiTable:
        EQUB >LevelA,>LevelB,>LevelC
; MOD: Starting times for screens A/B/C are BCD minutes with TimeLoBCD initially 00. Current values are 2:00, 3:00 and 4:00.
InitialTimeHiTable:
        EQUB &02,&03,&04             ; 2:00, 3:00, 4:00 (TimeLoBCD starts at 00)
; MOD: Change these three tune-offset selectors to swap which existing tune plays on base screens A/B/C.
InitialTuneTable:
        EQUB TuneOffsetScreenA,TuneOffsetScreenB,TuneOffsetScreenC

; -----------------------------------------------------------------------------
; SUBSYSTEM: ATTRACT / TITLE / HIGH-SCORE PRESENTATION
; Generates the animated title sequence, random decorative sprites/characters,
; high-score display and stack-unwind start-input handling.
;
; Runtime &1977: title/start sequence.
; -----------------------------------------------------------------------------
TitleStartSequence:
        TSX                                          ; &1977: BA
        STX     SavedAbortStackPtr                                  ; &1978: 86 7E
        LDX     #&01                                 ; &197A: A2 01
        LDY     #&00                                 ; &197C: A0 00
        JSR     DisplayInit                          ; &197E: 20 CD 14
        LDA     #TITLE_RANDOM_SPRITE_MAX             ; &1981: A9 03
        JSR     RandomUpToA                         ; &1983: 20 B6 0D
        TAY                                          ; &1986: A8
        LDA     TitleRandomSpriteTable,Y             ; &1987: B9 1B 1B
        STA     TitleRandomSprite                                  ; &198A: 85 7C
        LDA     #TITLE_RANDOM_DRAW_COUNT             ; &198C: A9 7D
        STA     TitleRandomDrawCount                                  ; &198E: 85 7D
Title_RandomDrawLoop:
        LDA     #MODE1_VIEWPORT_COLUMNS             ; &1990: A9 50
        JSR     RandomUpToA                         ; &1992: 20 B6 0D
        TAX                                          ; &1995: AA
        JSR     WaitForTickChange                    ; &1996: 20 01 0D
        LDA     #&FF                                 ; &1999: A9 FF
        JSR     RandomUpToA                         ; &199B: 20 B6 0D
        TAY                                          ; &199E: A8
        LDA     TitleRandomSprite                                  ; &199F: A5 7C
        JSR     DrawSpriteAt                         ; &19A1: 20 32 0B
        JSR     PollAttractInput                    ; &19A4: 20 D7 1A
        DEC     TitleRandomDrawCount                                  ; &19A7: C6 7D
        BNE     Title_RandomDrawLoop                                ; &19A9: D0 E5
        JSR     PrintTitleBanner                    ; &19AB: 20 DA 19
        LDA     #VDU_DEFAULT_WINDOWS                ; &19AE: A9 1A
        JSR     OSWRCH                               ; &19B0: 20 EE FF
        JSR     HideTextCursor                      ; &19B3: 20 74 15
        LDA     #TITLE_CLIP_LEFT                     ; &19B6: A9 0C
        STA     ClipLeft                                  ; &19B8: 85 0E
        LDA     #TITLE_CLIP_RIGHT                    ; &19BA: A9 44
        STA     ClipRight                                  ; &19BC: 85 0F
        JSR     TransitionFromLeft                  ; &19BE: 20 04 19
        JSR     TransitionFromRight                 ; &19C1: 20 F9 18
        LDA     #TITLE_TRANSITION_DELAY              ; &19C4: A9 4B
        JSR     DelayWithInput                          ; &19C6: 20 3C 16
        LDA     #SPRITE_TROGG_DEATH                                 ; &19C9: A9 5B
        LDX     ObjectX                              ; &19CB: AE 68 03
        LDY     #TITLE_FINAL_Y                       ; &19CE: A0 52
        JSR     DrawSpriteAt                         ; &19D0: 20 32 0B
        LDA     #TITLE_FINAL_WAIT                    ; &19D3: A9 FA
        JSR     WaitFramesOrInput                                ; &19D5: 20 C7 1A
        CLC                                          ; &19D8: 18
        RTS                                          ; &19D9: 60
PrintTitleBanner:
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
ShowHighScores:
        LDX     #&00                                 ; &1A52: A2 00
        STX     HighScoreRowIndex                                  ; &1A54: 86 60
ShowHighScores_NextRecord:
        LDY     HighScoreRowIndex                                  ; &1A56: A4 60
        JSR     PrintHighScorePosition              ; &1A58: 20 B3 1A
        LDY     #HIGH_SCORE_INITIALS                                 ; &1A5B: A0 03
ShowHighScores_PrintInitials:
        LDA     HighScores,X                         ; &1A5D: BD 80 08
        JSR     OSWRCH                               ; &1A60: 20 EE FF
        INX                                          ; &1A63: E8
        DEY                                          ; &1A64: 88
        BNE     ShowHighScores_PrintInitials                                ; &1A65: D0 F6
        LDA     #ASCII_SPACE                                 ; &1A67: A9 20
        JSR     OSWRCH                               ; &1A69: 20 EE FF
        LDY     #HIGH_SCORE_INITIALS                                 ; &1A6C: A0 03
        CLC                                          ; &1A6E: 18
ShowHighScores_PrintScoreBytes:
        LDA     HighScores,X                         ; &1A6F: BD 80 08
        STA.ABS HardwareStackPage-1,Y                              ; &1A72: 99 FF 00
        STA     HardwareStackPage+2,Y                              ; &1A75: 99 02 01
        JSR     PrintPackedBCD                      ; &1A78: 20 24 16
        INX                                          ; &1A7B: E8
        DEY                                          ; &1A7C: 88
        BNE     ShowHighScores_PrintScoreBytes                                ; &1A7D: D0 F0
        LDA     #ASCII_ZERO                                 ; &1A7F: A9 30
        JSR     OSWRCH                               ; &1A81: 20 EE FF
        LDY     HighScoreRowIndex                                  ; &1A84: A4 60
        JSR     PrintHighScorePosition              ; &1A86: 20 B3 1A
        LDA     #VDU_CURSOR_RIGHT                                 ; &1A89: A9 09
        LDY     #HIGH_SCORE_SPACING_TABS                                 ; &1A8B: A0 0B
ShowHighScores_SpacingLoop:
        JSR     OSWRCH                               ; &1A8D: 20 EE FF
        DEY                                          ; &1A90: 88
        BNE     ShowHighScores_SpacingLoop                                ; &1A91: D0 FA
        JSR     PrintInlineStream                    ; &1A93: 20 21 0D
        EQUB &28,&EA    ; runtime &1A96
        LDA     #TITLE_RANDOM_CHAR_SEED_1                                 ; &1A98: A9 63
        JSR     PrintPseudoRandomTitleChar                                ; &1A9A: 20 F9 1A
        LDA     #TITLE_RANDOM_CHAR_SEED_2                                 ; &1A9D: A9 2A
        JSR     PrintPseudoRandomTitleChar                                ; &1A9F: 20 F9 1A
        LDA     #TITLE_RANDOM_CHAR_SEED_3                                 ; &1AA2: A9 F7
        JSR     PrintPseudoRandomTitleChar                                ; &1AA4: 20 F9 1A
        JSR     PrintInlineStream                    ; &1AA7: 20 21 0D
        EQUB &29,&EA    ; runtime &1AAA
        INC     HighScoreRowIndex                                  ; &1AAC: E6 60
        CPX     #HIGH_SCORE_TABLE_BYTES                                 ; &1AAE: E0 24
        BCC     ShowHighScores_NextRecord                                ; &1AB0: 90 A4
        RTS                                          ; &1AB2: 60
PrintHighScorePosition:
        LDA     HighScorePositionRowTable,Y                              ; &1AB3: B9 C1 1A
        PHA                                          ; &1AB6: 48
        JSR     PrintInlineStream                    ; &1AB7: 20 21 0D
        EQUB &1F,&11,&EA    ; runtime &1ABA
        PLA                                          ; &1ABD: 68
        JMP     OSWRCH                               ; &1ABE: 4C EE FF
HighScorePositionRowTable:
        EQUB &09,&0B,&0C,&0D,&0E,&0F    ; runtime &1AC1
; CONTRACT: wait for A game ticks while servicing timer/controls.
; Entry: A=count; A=0 intentionally wraps Y and means 256 ticks.
; Exit: normal expiry returns normally; start input may unwind to SavedAbortStackPtr.
WaitFramesOrInput:
        TAY                                          ; &1AC7: A8
WaitFramesOrInput_Loop:
        JSR     TimerAndKeys                         ; &1AC8: 20 2C 0C
        BNE     WaitFramesOrInput_Return                                ; &1ACB: D0 09
        JSR     WaitForTickChange                    ; &1ACD: 20 01 0D
        JSR     PollAttractInput                    ; &1AD0: 20 D7 1A
        DEY                                          ; &1AD3: 88
        BNE     WaitFramesOrInput_Loop                                ; &1AD4: D0 F2
WaitFramesOrInput_Return:
        RTS                                          ; &1AD6: 60
PollAttractInput:
        LDA     SelectedControlScheme                           ; &1AD7: A5 87
        STA     ControlScheme                            ; &1AD9: 85 86
        LDA     #KEY_START_SPACE                     ; &1ADB: A9 9D
        JSR     Inkey                                ; &1ADD: 20 9C 0D
        BNE     PollAttractInput_StartGame                                ; &1AE0: D0 12
        LDA     #CONTROL_JOYSTICK                                 ; &1AE2: A9 01
        STA     ControlScheme                            ; &1AE4: 85 86
PollAttractInput_TestScheme:
        JSR     ReadYoyoControl                             ; &1AE6: 20 59 13
        BNE     PollAttractInput_SaveScheme                                ; &1AE9: D0 05
        DEC     ControlScheme                            ; &1AEB: C6 86
        BPL     PollAttractInput_TestScheme                                ; &1AED: 10 F7
        RTS                                          ; &1AEF: 60
PollAttractInput_SaveScheme:
        LDA     ControlScheme                            ; &1AF0: A5 86
        STA     SelectedControlScheme                           ; &1AF2: 85 87
PollAttractInput_StartGame:
        LDX     SavedAbortStackPtr                                  ; &1AF4: A6 7E
        TXS                                          ; &1AF6: 9A
        SEC                                          ; &1AF7: 38
        RTS                                          ; &1AF8: 60
PrintPseudoRandomTitleChar:
        STA     TitleRandomScratch                     ; &1AF9: 85 29
        LSR     A                                    ; &1AFB: 4A
        LDA     HardwareStackPage,Y                              ; &1AFC: B9 00 01
        ADC     HardwareStackPage+1,Y                              ; &1AFF: 79 01 01
        SBC     HardwareStackPage+2,Y                              ; &1B02: F9 02 01
        EOR     TitleRandomScratch                     ; &1B05: 45 29
PrintPseudoRandomTitleChar_ReduceIndex:
        CMP     #TitleCharacterMapEnd-TitleCharacterMap                                 ; &1B07: C9 24
        BCC     PrintPseudoRandomTitleChar_Emit                                ; &1B09: 90 04
        SBC     #TitleCharacterMapEnd-TitleCharacterMap                                 ; &1B0B: E9 24
        BCS     PrintPseudoRandomTitleChar_ReduceIndex                                ; &1B0D: B0 F8
PrintPseudoRandomTitleChar_Emit:
        STY     TitleRandomScratch                     ; &1B0F: 84 29
        TAY                                          ; &1B11: A8
        LDA     TitleCharacterMap,Y                              ; &1B12: B9 5A 1B
        LDY     TitleRandomScratch                     ; &1B15: A4 29
        INY                                          ; &1B17: C8
        JMP     OSWRCH                               ; &1B18: 4C EE FF
TitleRandomSpriteTable:
        EQUB SPRITE_FRAK_LOGO,SPRITE_TROGG_FRAME0,SPRITE_SCRUBBLY,SPRITE_HOOTER
ShowScreenCompleteText:
        JSR     PrintInlineStream                    ; &1B1F: 20 21 0D
        EQUB &1C,&0B,&12,&1C,&0E,&19,&04,&5F,&01,&9F,&01,&19,&01,&41,&02,&00    ; runtime &1B22
        EQUB &00,&19,&01,&00,&00,&A1,&00,&19,&01,&BF,&FD,&00,&00,&19,&01,&00    ; runtime &1B32
        EQUB &00,&5F,&FF,&0C,&1F,&02,&02,&57,&65,&27,&76,&65,&20,&64,&6F,&6E    ; runtime &1B42
        EQUB &65,&20,&69,&74,&21,&1A,&EA    ; runtime &1B52
        RTS                                          ; &1B59: 60
TitleCharacterMap:
        EQUB &38,&34,&42,&51,&52,&4A,&46,&49,&5A,&4D,&41,&58,&47,&43,&53,&32    ; runtime &1B5A
        EQUB &36,&4E,&31,&4C,&45,&4F,&4B,&57,&37,&35,&33,&30,&48,&59,&50,&55    ; runtime &1B6A
        EQUB &54,&39,&56,&44    ; runtime &1B7A
TitleCharacterMapEnd:

; -----------------------------------------------------------------------------
; Runtime &1B7E: count objects of a requested sprite/type within one queue.
; -----------------------------------------------------------------------------
CountObjectsOfType:
        STA     RequestedObjectType                            ; &1B7E: 85 26
        LDX     #&00                                 ; &1B80: A2 00
        STX     MatchedObjectCount                                  ; &1B82: 86 60
        LDX     QueueDescriptors,Y                   ; &1B84: BE 00 0B
CountObjectsOfType_Loop:
        LDA     ObjectSprite,X                       ; &1B87: BD 5E 04
        CMP     RequestedObjectType                            ; &1B8A: C5 26
        BNE     CountObjectsOfType_Next                                ; &1B8C: D0 02
        INC     MatchedObjectCount                                  ; &1B8E: E6 60
CountObjectsOfType_Next:
        INX                                          ; &1B90: E8
        TXA                                          ; &1B91: 8A
        CMP     QueueDescriptors+QUEUE_DESC_END_SLOT,Y                              ; &1B92: D9 03 0B
        BCC     CountObjectsOfType_Loop                                ; &1B95: 90 F0
        LDA     RequestedObjectType                            ; &1B97: A5 26
        LDX     MatchedObjectCount                                  ; &1B99: A6 60
        RTS                                          ; &1B9B: 60
SpawnHazard_DiscardStackAndReturn:
        PLA                                          ; &1B9C: 68
        PLA                                          ; &1B9D: 68
        PLA                                          ; &1B9E: 68
        JMP     DynamicUpdateReturn                                ; &1B9F: 4C FA 1B

; -----------------------------------------------------------------------------
; SUBSYSTEM: DYNAMIC HAZARDS
; Updates existing balloons/daggers and creates a new one whenever HazardCounter
; reaches zero. ObjectDX doubles as each new hazard's initial movement delay.
;
; Runtime &1BA2: dagger/balloon hazard spawner.
; Existing balloon and dagger slots are updated every call.  When HazardCounter
; expires, RandomUpToA(3) returns 0..3 inclusive. Result 0 selects a
; dagger; results 1, 2 or 3 select a balloon: 25% daggers / 75% balloons.  Newly spawned objects use
; ObjectDX as an initial 20-tick delay before their first movement step.
; -----------------------------------------------------------------------------
; CONTRACT: update live balloons/daggers and periodically spawn one new hazard.
; Spawn mix: RandomUpToA(3) => value 0 dagger, 1..3 balloon (25% / 75%).
; New hazards receive DYNAMIC_SPAWN_DELAY before movement starts.
SpawnHazard:
        LDY     #QUEUE_BALLOONS                                 ; &1BA2: A0 06
        JSR     UpdateDynamicQueue                                ; &1BA4: 20 FB 1B
        LDY     #QUEUE_DAGGERS                                 ; &1BA7: A0 03
        JSR     UpdateDynamicQueue                                ; &1BA9: 20 FB 1B
        DEC     HazardCounter                        ; &1BAC: C6 88
        BNE     UpdateDynamicQueue_Return                                ; &1BAE: D0 4A
        LDA     HazardReload                         ; &1BB0: A5 89
        STA     HazardCounter                        ; &1BB2: 85 88
        LDA     #HAZARD_RANDOM_MAX                                 ; &1BB4: A9 03
        JSR     RandomUpToA                         ; &1BB6: 20 B6 0D
        TAY                                          ; &1BB9: A8
        BEQ     SpawnHazard_CreateDagger                                ; &1BBA: F0 12
        LDA     #BALLOON_SPAWN_Y                                 ; &1BBC: A9 08
        PHA                                          ; &1BBE: 48
        LDY     #QUEUE_BALLOONS                                 ; &1BBF: A0 06
        LDA     #BALLOON_SPAWN_X_SPAN                                 ; &1BC1: A9 50
        JSR     RandomUpToA                         ; &1BC3: 20 B6 0D
        CLC                                          ; &1BC6: 18
        ADC     ViewportXOffset                                  ; &1BC7: 65 10
        PHA                                          ; &1BC9: 48
        LDA     #SPRITE_BALLOON                      ; &1BCA: A9 27
        BNE     SpawnHazard_AllocateSlot                                ; &1BCC: D0 12
SpawnHazard_CreateDagger:
        LDA     #DAGGER_SPAWN_Y                                 ; &1BCE: A9 FA
        PHA                                          ; &1BD0: 48
        LDY     #QUEUE_DAGGERS                                 ; &1BD1: A0 03
        LDA     #DAGGER_SPAWN_X_SPAN                                 ; &1BD3: A9 28
        JSR     RandomUpToA                         ; &1BD5: 20 B6 0D
        CLC                                          ; &1BD8: 18
        ADC     ViewportXOffset                                  ; &1BD9: 65 10
        ADC     #DAGGER_SPAWN_X_OFFSET                                 ; &1BDB: 69 32
        PHA                                          ; &1BDD: 48
        LDA     #SPRITE_DAGGER                       ; &1BDE: A9 25
SpawnHazard_AllocateSlot:
        PHA                                          ; &1BE0: 48
        JSR     FindFreeSlot                         ; &1BE1: 20 97 1C
        BCS     SpawnHazard_DiscardStackAndReturn                                ; &1BE4: B0 B6
        PLA                                          ; &1BE6: 68
        STA     ObjectSprite,X                       ; &1BE7: 9D 5E 04
        PLA                                          ; &1BEA: 68
        STA     ObjectX,X                            ; &1BEB: 9D 68 03
        PLA                                          ; &1BEE: 68
        STA     ObjectY,X                            ; &1BEF: 9D E3 03
        LDA     #DYNAMIC_SPAWN_DELAY                                 ; &1BF2: A9 14
        STA     ObjectDX,X                           ; &1BF4: 9D D9 04
        JSR     DrawObject                         ; &1BF7: 20 20 0B
DynamicUpdateReturn:
UpdateDynamicQueue_Return:
        RTS                                          ; &1BFA: 60
; CONTRACT: update every object slot belonging to one dynamic queue.
; Entry: Y=queue descriptor offset.
; Effect: snapshot -> type dispatch -> erase/collision -> restore -> redraw when state changed.
UpdateDynamicQueue:
        STY     ActiveQueueDescriptor                                  ; &1BFB: 84 5B
        LDX     QueueDescriptors,Y                   ; &1BFD: BE 00 0B
UpdateDynamicQueue_Loop:
        JSR     UpdateDynamicObject                                ; &1C00: 20 0D 1C
        LDY     ActiveQueueDescriptor                                  ; &1C03: A4 5B
        INX                                          ; &1C05: E8
        TXA                                          ; &1C06: 8A
        CMP     QueueDescriptors+QUEUE_DESC_END_SLOT,Y                              ; &1C07: D9 03 0B
        BCC     UpdateDynamicQueue_Loop                                ; &1C0A: 90 F4
UpdateDynamicQueue_QueueDone:
        RTS                                          ; &1C0C: 60
UpdateDynamicObject:
        JSR     SnapshotObject                                ; &1C0D: 20 2F 1C
        LDA     PendingObjectSprite                                  ; &1C10: A5 68
        CMP     #OBJECT_EMPTY                                 ; &1C12: C9 FF
        BEQ     UpdateDynamicQueue_QueueDone                                ; &1C14: F0 F6
        LDY     #QUEUE_COLLECTIBLES                                 ; &1C16: A0 09
        JSR     TypeDispatch                         ; &1C18: 20 D1 12
        JSR     ObjectStateChanged                                ; &1C1B: 20 3F 1C
        BEQ     UpdateDynamicQueue_QueueDone                                ; &1C1E: F0 EC
        JSR     EraseObjectAndScanCollisions                         ; &1C20: 20 23 0B
        JSR     RestoreObjectSnapshot                                ; &1C23: 20 53 1C
        LDA     PendingObjectSprite                                  ; &1C26: A5 68
        CMP     #OBJECT_EMPTY                                 ; &1C28: C9 FF
        BEQ     UpdateDynamicQueue_QueueDone                                ; &1C2A: F0 E0
        JMP     DrawObject                         ; &1C2C: 4C 20 0B
SnapshotObject:
        LDA     ObjectSprite,X                       ; &1C2F: BD 5E 04
        STA     PendingObjectSprite                                  ; &1C32: 85 68
        LDA     ObjectX,X                            ; &1C34: BD 68 03
        STA     PendingObjectX                                  ; &1C37: 85 69
        LDA     ObjectY,X                            ; &1C39: BD E3 03
        STA     PendingObjectY                                  ; &1C3C: 85 6A
        RTS                                          ; &1C3E: 60
ObjectStateChanged:
        LDA     ObjectSprite,X                       ; &1C3F: BD 5E 04
        CMP     PendingObjectSprite                                  ; &1C42: C5 68
        BNE     ObjectStateChanged_Return                                ; &1C44: D0 0C
        LDA     ObjectX,X                            ; &1C46: BD 68 03
        CMP     PendingObjectX                                  ; &1C49: C5 69
        BNE     ObjectStateChanged_Return                                ; &1C4B: D0 05
        LDA     ObjectY,X                            ; &1C4D: BD E3 03
        CMP     PendingObjectY                                  ; &1C50: C5 6A
ObjectStateChanged_Return:
        RTS                                          ; &1C52: 60
RestoreObjectSnapshot:
        LDA     PendingObjectSprite                                  ; &1C53: A5 68
        STA     ObjectSprite,X                       ; &1C55: 9D 5E 04
        LDA     PendingObjectX                                  ; &1C58: A5 69
        STA     ObjectX,X                            ; &1C5A: 9D 68 03
        LDA     PendingObjectY                                  ; &1C5D: A5 6A
        STA     ObjectY,X                            ; &1C5F: 9D E3 03
        RTS                                          ; &1C62: 60
DynamicObject_Remove:
        LDA     #OBJECT_EMPTY                        ; &1C63: A9 FF
        STA     PendingObjectSprite                                  ; &1C65: 85 68
        RTS                                          ; &1C67: 60

; -----------------------------------------------------------------------------
; Runtime &1C68: balloon movement.
; -----------------------------------------------------------------------------
BalloonMovement:
        JSR     TickObjectDelay                                ; &1C68: 20 8C 1C
        BNE     DynamicMovement_Return                                ; &1C6B: D0 1E
        CLC                                          ; &1C6D: 18
        LDA     PendingObjectY                                  ; &1C6E: A5 6A
        ADC     #BALLOON_Y_STEP                                 ; &1C70: 69 06
        STA     PendingObjectY                                  ; &1C72: 85 6A
        CMP     #BALLOON_DESPAWN_Y                   ; &1C74: C9 F0
        BCS     DynamicObject_Remove                                ; &1C76: B0 EB
        RTS                                          ; &1C78: 60

; -----------------------------------------------------------------------------
; Runtime &1C79: dagger movement.
; -----------------------------------------------------------------------------
DaggerMovement:
        JSR     TickObjectDelay                                ; &1C79: 20 8C 1C
        BNE     DynamicMovement_Return                                ; &1C7C: D0 0D
        SEC                                          ; &1C7E: 38
        LDA     PendingObjectY                                  ; &1C7F: A5 6A
        SBC     #DAGGER_Y_STEP                       ; &1C81: E9 02
        STA     PendingObjectY                                  ; &1C83: 85 6A
        CMP     #DAGGER_MIN_Y                                 ; &1C85: C9 14
        BCC     DynamicObject_Remove                                ; &1C87: 90 DA
        DEC     PendingObjectX                                  ; &1C89: C6 69
DynamicMovement_Return:
        RTS                                          ; &1C8B: 60
TickObjectDelay:
        LDY     ObjectDX,X                           ; &1C8C: BC D9 04
        BEQ     TickObjectDelay_Return                                ; &1C8F: F0 05
        DEY                                          ; &1C91: 88
        TYA                                          ; &1C92: 98
        STA     ObjectDX,X                           ; &1C93: 9D D9 04
TickObjectDelay_Return:
        RTS                                          ; &1C96: 60

; -----------------------------------------------------------------------------
; Runtime &1C97: find free object slot.
; -----------------------------------------------------------------------------
FindFreeSlot:
        LDX     QueueDescriptors,Y                   ; &1C97: BE 00 0B
FindFreeSlot_Loop:
        LDA     ObjectSprite,X                       ; &1C9A: BD 5E 04
        CMP     #OBJECT_EMPTY                        ; &1C9D: C9 FF
        BEQ     FindFreeSlot_Found                                ; &1C9F: F0 08
        INX                                          ; &1CA1: E8
        TXA                                          ; &1CA2: 8A
        CMP     QueueDescriptors+QUEUE_DESC_END_SLOT,Y                              ; &1CA3: D9 03 0B
        BCC     FindFreeSlot_Loop                                ; &1CA6: 90 F2
        RTS                                          ; &1CA8: 60
FindFreeSlot_Found:
        CLC                                          ; &1CA9: 18
        RTS                                          ; &1CAA: 60
; SpriteTraversal selects one of three primitive handlers by pushing a synthetic
; return address and executing RTS.  RTS adds one, so the stored words are
; handler-1.  Modes are 0=bounds, 2=collision, 4=render/conditional-bounds.
SpriteTraversalReturnTable:
        EQUW AccumulateSpriteBounds-1
        EQUW TestPrimitiveBounds-1
        EQUW RenderSpritePrimitive-1
TestSpriteCollision:
        LDA     SpriteTraversalMode                                  ; &1CB1: A5 50
        PHA                                          ; &1CB3: 48
        LDA     #SPRITE_TRAVERSE_COLLISION           ; &1CB4: A9 02
        JSR     SpriteTraversal                      ; &1CB6: 20 2E 1D
        PLA                                          ; &1CB9: 68
        STA     SpriteTraversalMode                                  ; &1CBA: 85 50
        RTS                                          ; &1CBC: 60
ScanObjectCollisions:
        STA     CollisionMask                                  ; &1CBD: 85 5A
        STX     CollisionSourceObjectSlot                     ; &1CBF: 86 33
        JSR     LoadObject                           ; &1CC1: 20 3C 0B
        JSR     ResetSpriteBounds                                ; &1CC4: 20 19 1D
        LDA     #SPRITE_TRAVERSE_BOUNDS              ; &1CC7: A9 00
        JSR     SpriteTraversal                      ; &1CC9: 20 2E 1D
        JMP     CollisionScanPrepared                 ; &1CCC: 4C 7C 14

; -----------------------------------------------------------------------------
; SUBSYSTEM: SPRITE / COLLISION RENDERER
; ProcessSprite and SpriteTraversal share one recursive descriptor walker for
; bounds, collision and rendering. Rendering patches the eight calls in &01C4.
;
; Runtime &1CCF: traverse/render/collide one sprite according to the mode in A.
; -----------------------------------------------------------------------------
ProcessSprite:
        STA     SpriteOperationMode                                  ; &1CCF: 85 5E
        TYA                                          ; &1CD1: 98
        PHA                                          ; &1CD2: 48
        JSR     ResetSpriteBounds                                ; &1CD3: 20 19 1D
        LDA     #SPRITE_TRAVERSE_RENDER              ; &1CD6: A9 04
        JSR     SpriteTraversal                      ; &1CD8: 20 2E 1D
        PLA                                          ; &1CDB: 68
        TAY                                          ; &1CDC: A8
        BIT     SpriteOperationMode                                  ; &1CDD: 24 5E
        BVC     ProcessSprite_Return                                ; &1CDF: 50 37
        LDA     PrimitiveBoundsByteCount                                  ; &1CE1: A5 6F
        BEQ     ProcessSprite_Return                                ; &1CE3: F0 33
        LDA     #&FF                                 ; &1CE5: A9 FF
        STA     SpriteCollisionDrawFlag                                  ; &1CE7: 85 5F
        STA     CollisionMask                                  ; &1CE9: 85 5A
        LDA     ClipLeft                                  ; &1CEB: A5 0E
        PHA                                          ; &1CED: 48
        SEC                                          ; &1CEE: 38
        LDA     SpriteBoundsMinX                                  ; &1CEF: A5 75
        SBC     ViewportXOffset                                  ; &1CF1: E5 10
        CMP     ClipLeft                                  ; &1CF3: C5 0E
        BMI     ProcessSprite_ClipLeftReady                                ; &1CF5: 30 06
        CMP     ClipRight                                  ; &1CF7: C5 0F
        BPL     ProcessSprite_ClipLeftReady                                ; &1CF9: 10 02
        STA     ClipLeft                                  ; &1CFB: 85 0E
ProcessSprite_ClipLeftReady:
        LDA     ClipRight                                  ; &1CFD: A5 0F
        PHA                                          ; &1CFF: 48
        SEC                                          ; &1D00: 38
        LDA     SpriteBoundsMaxX                                  ; &1D01: A5 76
        SBC     ViewportXOffset                                  ; &1D03: E5 10
        CMP     ClipRight                                  ; &1D05: C5 0F
        BPL     ProcessSprite_TestCollision                                ; &1D07: 10 06
        CMP     ClipLeft                                  ; &1D09: C5 0E
        BMI     ProcessSprite_TestCollision                                ; &1D0B: 30 02
        STA     ClipRight                                  ; &1D0D: 85 0F
ProcessSprite_TestCollision:
        JSR     CollisionScanPrepared                 ; &1D0F: 20 7C 14
        PLA                                          ; &1D12: 68
        STA     ClipRight                                  ; &1D13: 85 0F
        PLA                                          ; &1D15: 68
        STA     ClipLeft                                  ; &1D16: 85 0E
ProcessSprite_Return:
        RTS                                          ; &1D18: 60
ResetSpriteBounds:
        CLC                                          ; &1D19: 18
        LDA     ViewportXOffset                                  ; &1D1A: A5 10
        ADC     ClipRight                                  ; &1D1C: 65 0F
        STA     SpriteBoundsMinX                                  ; &1D1E: 85 75
        CLC                                          ; &1D20: 18
        LDA     ViewportXOffset                                  ; &1D21: A5 10
        ADC     ClipLeft                                  ; &1D23: 65 0E
        STA     SpriteBoundsMaxX                                  ; &1D25: 85 76
        LDA     #&00                                 ; &1D27: A9 00
        STA     PrimitiveBoundsByteCount                                  ; &1D29: 85 6F
        STA     SpriteCollisionDrawFlag                                  ; &1D2B: 85 5F
        RTS                                          ; &1D2D: 60

; -----------------------------------------------------------------------------
; Runtime &1D2E: recursive sprite traversal.
; -----------------------------------------------------------------------------
; CONTRACT: recursive primitive/composite sprite walker.
; Entry: A=SPRITE_TRAVERSE_* mode, Y=sprite index, CurrentSpriteX/Y origin.
; Effect: recursively visits composite children or RTS-dispatches primitive handler.
; Carry is propagated to permit collision traversal to abort early.
SpriteTraversal:
        STA     SpriteTraversalMode                  ; &1D2E: 85 50
SpriteTraversalNode:
        LDA     (SpriteWidthPtrLo),Y                              ; &1D30: B1 08
        ASL     A                                    ; &1D32: 0A
        BEQ     SpriteTraversal_Composite                                ; &1D33: F0 0F
        STY     SavedSpriteIndex                            ; &1D35: 84 26
        LDY     SpriteTraversalMode                  ; &1D37: A4 50
        LDA     SpriteTraversalReturnTable+1,Y       ; &1D39: B9 AC 1C
        PHA                                          ; &1D3C: 48
        LDA     SpriteTraversalReturnTable,Y         ; &1D3D: B9 AB 1C
        PHA                                          ; &1D40: 48
        LDY     SavedSpriteIndex                            ; &1D41: A4 26
        RTS                                          ; &1D43: 60
SpriteTraversal_Composite:
        LDA     SpriteTraversalCount                 ; &1D44: A5 1E
        PHA                                          ; &1D46: 48
        LDA     SpriteTraversalPtrLo                 ; &1D47: A5 1F
        PHA                                          ; &1D49: 48
        LDA     SpriteTraversalPtrHi                 ; &1D4A: A5 20
        PHA                                          ; &1D4C: 48
        LDA     (SpriteHeightPtrLo),Y                              ; &1D4D: B1 0A
        STA     SpriteTraversalCount                 ; &1D4F: 85 1E
        CLC                                          ; &1D51: 18
        LDA     SpriteXOffsetPtrLo                                  ; &1D52: A5 00
        ADC     (SpriteDefLoPtrLo),Y                              ; &1D54: 71 04
        STA     SpriteTraversalPtrLo                 ; &1D56: 85 1F
        LDA     SpriteXOffsetPtrHi                                  ; &1D58: A5 01
        ADC     (SpriteDefHiPtrLo),Y                              ; &1D5A: 71 06
        STA     SpriteTraversalPtrHi                 ; &1D5C: 85 20
SpriteTraversal_NextChild:
        LDY     #COMPOSITE_CHILD_Y_OFFSET            ; &1D5E: A0 02
        LDA     CurrentSpriteY                       ; &1D60: A5 12
        PHA                                          ; &1D62: 48
        CLC                                          ; &1D63: 18
        ADC     (SpriteTraversalPtrLo),Y             ; &1D64: 71 1F
        STA     CurrentSpriteY                       ; &1D66: 85 12
        DEY                                          ; &1D68: 88
        LDA     CurrentSpriteX                       ; &1D69: A5 11
        PHA                                          ; &1D6B: 48
        CLC                                          ; &1D6C: 18
        ADC     (SpriteTraversalPtrLo),Y             ; &1D6D: 71 1F
        STA     CurrentSpriteX                       ; &1D6F: 85 11
        DEY                                          ; &1D71: 88
        LDA     (SpriteTraversalPtrLo),Y             ; &1D72: B1 1F
        TAY                                          ; &1D74: A8
        JSR     SpriteTraversalNode                   ; &1D75: 20 30 1D
        PLA                                          ; &1D78: 68
        STA     CurrentSpriteX                       ; &1D79: 85 11
        PLA                                          ; &1D7B: 68
        STA     CurrentSpriteY                       ; &1D7C: 85 12
        BCS     SpriteTraversal_RestoreParent                                ; &1D7E: B0 0F
        LDA     SpriteTraversalPtrLo                 ; &1D80: A5 1F
        ADC     #COMPOSITE_CHILD_RECORD_SIZE         ; &1D82: 69 03
        STA     SpriteTraversalPtrLo                 ; &1D84: 85 1F
        BCC     SpriteTraversal_DecrementChild                                ; &1D86: 90 02
        INC     SpriteTraversalPtrHi                 ; &1D88: E6 20
SpriteTraversal_DecrementChild:
        DEC     SpriteTraversalCount                 ; &1D8A: C6 1E
        BNE     SpriteTraversal_NextChild                                ; &1D8C: D0 D0
        CLC                                          ; &1D8E: 18
SpriteTraversal_RestoreParent:
        PLA                                          ; &1D8F: 68
        STA     SpriteTraversalPtrHi                 ; &1D90: 85 20
        PLA                                          ; &1D92: 68
        STA     SpriteTraversalPtrLo                 ; &1D93: 85 1F
        PLA                                          ; &1D95: 68
        STA     SpriteTraversalCount                 ; &1D96: 85 1E
        RTS                                          ; &1D98: 60
AccumulateSpriteBounds:
        JSR     ComputePrimitiveBounds                                ; &1D99: 20 92 15
        TYA                                          ; &1D9C: 98
        PHA                                          ; &1D9D: 48
        LDY     PrimitiveBoundsByteCount                                  ; &1D9E: A4 6F
        LDA     CollisionLeft                                  ; &1DA0: A5 45
        STA     HardwareStackPage,Y                              ; &1DA2: 99 00 01
        CMP     SpriteBoundsMinX                                  ; &1DA5: C5 75
        BPL     AccumulateBounds_UpdateRight                                ; &1DA7: 10 02
        STA     SpriteBoundsMinX                                  ; &1DA9: 85 75
AccumulateBounds_UpdateRight:
        LDA     CollisionRight                                  ; &1DAB: A5 46
        STA     HardwareStackPage+1,Y                              ; &1DAD: 99 01 01
        CMP     SpriteBoundsMaxX                                  ; &1DB0: C5 76
        BMI     AccumulateBounds_StoreVertical                                ; &1DB2: 30 02
        STA     SpriteBoundsMaxX                                  ; &1DB4: 85 76
AccumulateBounds_StoreVertical:
        LDA     CollisionBottom                                  ; &1DB6: A5 48
        STA     HardwareStackPage+2,Y                              ; &1DB8: 99 02 01
        LDA     CollisionTop                                  ; &1DBB: A5 47
        STA     HardwareStackPage+3,Y                              ; &1DBD: 99 03 01
        CLC                                          ; &1DC0: 18
        TYA                                          ; &1DC1: 98
        ADC     #PRIMITIVE_BOUNDS_RECORD_SIZE       ; &1DC2: 69 04
        STA     PrimitiveBoundsByteCount                                  ; &1DC4: 85 6F
        PLA                                          ; &1DC6: 68
        TAY                                          ; &1DC7: A8
        CLC                                          ; &1DC8: 18
        RTS                                          ; &1DC9: 60
TestPrimitiveBounds:
        TXA                                          ; &1DCA: 8A
        PHA                                          ; &1DCB: 48
        LDX     #&00                                 ; &1DCC: A2 00
TestPrimitiveBounds_NextRecord:
        CPX     PrimitiveBoundsByteCount                                  ; &1DCE: E4 6F
        BCS     TestBounds_NoCollisionRestore                                ; &1DD0: B0 3D
        LDA     CurrentSpriteX                       ; &1DD2: A5 11
        ADC     (SpriteXOffsetPtrLo),Y                              ; &1DD4: 71 00
        CMP     HardwareStackPage+1,X                              ; &1DD6: DD 01 01
        BPL     TestBounds_NextRecord                                ; &1DD9: 10 3C
        STA     PrimitiveLeftScratch                            ; &1DDB: 85 26
        LDA     (SpriteWidthPtrLo),Y                              ; &1DDD: B1 08
        ASL     A                                    ; &1DDF: 0A
        LSR     A                                    ; &1DE0: 4A
        ADC     PrimitiveLeftScratch                            ; &1DE1: 65 26
        CMP     HardwareStackPage,X                              ; &1DE3: DD 00 01
        BEQ     TestBounds_NextRecord                                ; &1DE6: F0 2F
        BMI     TestBounds_NextRecord                                ; &1DE8: 30 2D
        CLC                                          ; &1DEA: 18
        LDA     CurrentSpriteY                       ; &1DEB: A5 12
        ADC     (SpriteYOffsetPtrLo),Y                              ; &1DED: 71 02
        CMP     HardwareStackPage+3,X                              ; &1DEF: DD 03 01
        BPL     TestBounds_NextRecord                                ; &1DF2: 10 23
        CLC                                          ; &1DF4: 18
        ADC     (SpriteHeightPtrLo),Y                              ; &1DF5: 71 0A
        CMP     HardwareStackPage+2,X                              ; &1DF7: DD 02 01
        BEQ     TestBounds_NextRecord                                ; &1DFA: F0 1B
        BMI     TestBounds_NextRecord                                ; &1DFC: 30 19
        BIT     SpriteCollisionDrawFlag                                  ; &1DFE: 24 5F
        BPL     TestBounds_CollisionReturn                                ; &1E00: 10 11
        LDA     SpriteOperationMode                                  ; &1E02: A5 5E
        PHA                                          ; &1E04: 48
        LDA     #OBJECT_RENDER_DRAW                  ; &1E05: A9 00
        STA     SpriteOperationMode                                  ; &1E07: 85 5E
        JSR     DirectSpriteRenderer                 ; &1E09: 20 36 1E
        PLA                                          ; &1E0C: 68
        STA     SpriteOperationMode                                  ; &1E0D: 85 5E
TestBounds_NoCollisionRestore:
        PLA                                          ; &1E0F: 68
        TAX                                          ; &1E10: AA
TestBounds_NoCollisionReturn:
        CLC                                          ; &1E11: 18
        RTS                                          ; &1E12: 60
TestBounds_CollisionReturn:
        PLA                                          ; &1E13: 68
        TAX                                          ; &1E14: AA
        SEC                                          ; &1E15: 38
        RTS                                          ; &1E16: 60
TestBounds_NextRecord:
        INX                                          ; &1E17: E8
        INX                                          ; &1E18: E8
        INX                                          ; &1E19: E8
        INX                                          ; &1E1A: E8
        JMP     TestPrimitiveBounds_NextRecord        ; &1E1B: 4C CE 1D
RenderSpritePrimitive:
        LDA     SpriteOperationMode                                  ; &1E1E: A5 5E
        BEQ     RenderPrimitive_Draw                                ; &1E20: F0 02
        BPL     RenderPrimitive_AccumulateBounds                                ; &1E22: 10 0D
RenderPrimitive_Draw:
        TYA                                          ; &1E24: 98
        PHA                                          ; &1E25: 48
        JSR     DirectSpriteRenderer                 ; &1E26: 20 36 1E
        PLA                                          ; &1E29: 68
        TAY                                          ; &1E2A: A8
        BCS     TestBounds_NoCollisionReturn                                ; &1E2B: B0 E4
        BIT     SpriteOperationMode                                  ; &1E2D: 24 5E
        BVC     TestBounds_NoCollisionReturn                                ; &1E2F: 50 E0
RenderPrimitive_AccumulateBounds:
        JMP     AccumulateSpriteBounds           ; &1E31: 4C 99 1D
DirectRenderer_ClippedReturn:
        SEC                                          ; &1E34: 38
        RTS                                          ; &1E35: 60

; -----------------------------------------------------------------------------
; Runtime &1E36: direct sprite renderer.
; -----------------------------------------------------------------------------
; CONTRACT: render one primitive sprite descriptor.
; Entry: Y=sprite index; CurrentSpriteX/Y and clipping state valid.
; Effect: derives bitmap/solid primitive parameters then calls SpriteRenderSetup.
; Return: carry set when primitive is entirely clipped.
DirectSpriteRenderer:
        SEC                                          ; &1E36: 38
        LDA     CurrentSpriteX                       ; &1E37: A5 11
        SBC     ViewportXOffset                                  ; &1E39: E5 10
        CLC                                          ; &1E3B: 18
        ADC     (SpriteXOffsetPtrLo),Y                              ; &1E3C: 71 00
        CMP     ClipRight                                  ; &1E3E: C5 0F
        BPL     DirectRenderer_ClippedReturn                                ; &1E40: 10 F2
        STA     RendererX                            ; &1E42: 85 21
        LDA     (SpriteWidthPtrLo),Y                              ; &1E44: B1 08
        ASL     A                                    ; &1E46: 0A
        LSR     A                                    ; &1E47: 4A
        STA     RendererWidth                             ; &1E48: 85 17
        ADC     RendererX                            ; &1E4A: 65 21
        CMP     ClipLeft                                  ; &1E4C: C5 0E
        BMI     DirectRenderer_ClippedReturn                                ; &1E4E: 30 E4
        CLC                                          ; &1E50: 18
        LDA     CurrentSpriteY                       ; &1E51: A5 12
        ADC     (SpriteYOffsetPtrLo),Y                              ; &1E53: 71 02
        STA     RendererY                                  ; &1E55: 85 22
        LDA     (SpriteHeightPtrLo),Y                              ; &1E57: B1 0A
        STA     RendererHeight                                  ; &1E59: 85 18
        BIT     VerticalFlipFlag                          ; &1E5B: 24 74
        BPL     DirectRenderer_SetDataPointer                                ; &1E5D: 10 07
        CLC                                          ; &1E5F: 18
        ADC     RendererY                                  ; &1E60: 65 22
        EOR     VerticalFlipFlag                          ; &1E62: 45 74
        STA     RendererY                                  ; &1E64: 85 22
DirectRenderer_SetDataPointer:
        CLC                                          ; &1E66: 18
        LDA     (SpriteDefLoPtrLo),Y                              ; &1E67: B1 04
        ADC     SpriteXOffsetPtrLo                                  ; &1E69: 65 00
        STA     RendererDataPtrLo                                  ; &1E6B: 85 13
        LDA     (SpriteDefHiPtrLo),Y                              ; &1E6D: B1 06
        BMI     DirectRenderer_SolidPrimitive                                ; &1E6F: 30 13
        ADC     SpriteXOffsetPtrHi                                  ; &1E71: 65 01
        STA     RendererDataPtrHi                                  ; &1E73: 85 14
        LDA     VerticalFlipFlag                          ; &1E75: A5 74
        AND     #PIXEL_OP_MASKED_REVERSE             ; &1E77: 29 02
        TAX                                          ; &1E79: AA
        LDA     (SpriteWidthPtrLo),Y                              ; &1E7A: B1 08
        BPL     DirectRenderer_SetPixelOp                                ; &1E7C: 10 0C
        TXA                                          ; &1E7E: 8A
        EOR     #PIXEL_OP_MASKED_REVERSE             ; &1E7F: 49 02
        TAX                                          ; &1E81: AA
        BPL     DirectRenderer_SetPixelOp                                ; &1E82: 10 06
DirectRenderer_SolidPrimitive:
        LDA     (SpriteDefLoPtrLo),Y                              ; &1E84: B1 04
        STA     RendererSolidByte                                  ; &1E86: 85 59
        LDX     #PIXEL_OP_SOLID                      ; &1E88: A2 04
DirectRenderer_SetPixelOp:
        STX     PixelOpIndex                                  ; &1E8A: 86 1B

; -----------------------------------------------------------------------------
; Runtime &1E8C: sprite render setup.
; -----------------------------------------------------------------------------
; CONTRACT: configure and run the eight-call self-modifying MODE 1 row renderer.
; Effect: selects draw/erase pixel operator, patches RendererRowCall0..7, then renders columns.
SpriteRenderSetup:
        JSR     Mode1Address                         ; &1E8C: 20 A9 1F
        LDA     PixelOpIndex                                  ; &1E8F: A5 1B
        BIT     SpriteOperationMode                                  ; &1E91: 24 5E
        BPL     SpriteRenderSetup_SelectOperator                                ; &1E93: 10 03
        CLC                                          ; &1E95: 18
        ADC     #PIXEL_OP_ERASE_TABLE_OFFSET         ; &1E96: 69 06
SpriteRenderSetup_SelectOperator:
        TAX                                          ; &1E98: AA
        LDA     PixelOperationTable,X                 ; &1E99: BD 9D 1F
        STA     RendererRowCall0+1                                ; &1E9C: 8D C5 01
        STA     RendererRowCall1+1                                ; &1E9F: 8D C8 01
        STA     RendererRowCall2+1                                ; &1EA2: 8D CB 01
        STA     RendererRowCall3+1                                ; &1EA5: 8D CE 01
        STA     RendererRowCall4+1                                ; &1EA8: 8D D1 01
        STA     RendererRowCall5+1                                ; &1EAB: 8D D4 01
        STA     RendererRowCall6+1                                ; &1EAE: 8D D7 01
        STA     RendererRowCall7+1                                ; &1EB1: 8D DA 01
        LDA     PixelOperationTable+1,X               ; &1EB4: BD 9E 1F
        STA     RendererRowCall0+2                                ; &1EB7: 8D C6 01
        STA     RendererRowCall1+2                                ; &1EBA: 8D C9 01
        STA     RendererRowCall2+2                                ; &1EBD: 8D CC 01
        STA     RendererRowCall3+2                                ; &1EC0: 8D CF 01
        STA     RendererRowCall4+2                                ; &1EC3: 8D D2 01
        STA     RendererRowCall5+2                                ; &1EC6: 8D D5 01
        STA     RendererRowCall6+2                                ; &1EC9: 8D D8 01
        STA     RendererRowCall7+2                                ; &1ECC: 8D DB 01
        LDA     RendererY                                  ; &1ECF: A5 22
        AND     #MODE1_SCANLINES_PER_CHAR-1          ; &1ED1: 29 07
        ASL     A                                    ; &1ED3: 0A
        TAX                                          ; &1ED4: AA
        LDA     RendererRowEntryTable,X               ; &1ED5: BD 31 1F
        STA     RowRoutineLo                                  ; &1ED8: 85 1C
        LDA     RendererRowEntryTable+1,X             ; &1EDA: BD 32 1F
        STA     RowRoutineHi                          ; &1EDD: 85 1D
        LDA     RendererDataPtrLo                                  ; &1EDF: A5 13
        BNE     SpriteRenderSetup_DataPtrReady                                ; &1EE1: D0 02
        DEC     RendererDataPtrHi                                  ; &1EE3: C6 14
SpriteRenderSetup_DataPtrReady:
        DEC     RendererDataPtrLo                                  ; &1EE5: C6 13
        LDX     #&00                                 ; &1EE7: A2 00
SpriteRenderSetup_ColumnLoop:
        LDY     RendererHeight                                  ; &1EE9: A4 18
        LDA     RendererX                            ; &1EEB: A5 21
        CMP     ClipLeft                                  ; &1EED: C5 0E
        BMI     SpriteRenderSetup_NextColumn                                ; &1EEF: 30 07
        CMP     ClipRight                                  ; &1EF1: C5 0F
        BPL     SpriteRenderSetup_Return                                ; &1EF3: 10 37
        JSR     RendererRowDispatch                 ; &1EF5: 20 2E 1F
SpriteRenderSetup_NextColumn:
        DEC     RendererWidth                             ; &1EF8: C6 17
        BEQ     SpriteRenderSetup_Return                                ; &1EFA: F0 30
        INC     RendererX                            ; &1EFC: E6 21
        CLC                                          ; &1EFE: 18
        TYA                                          ; &1EFF: 98
        ADC     RendererDataPtrLo                                  ; &1F00: 65 13
        STA     RendererDataPtrLo                                  ; &1F02: 85 13
        BCC     SpriteRenderSetup_AdvanceScreenColumn                                ; &1F04: 90 02
        INC     RendererDataPtrHi                                  ; &1F06: E6 14
SpriteRenderSetup_AdvanceScreenColumn:
        CLC                                          ; &1F08: 18
        LDA     #MODE1_SCANLINES_PER_CHAR            ; &1F09: A9 08
        ADC     RendererScreenBaseLo                                  ; &1F0B: 65 15
        STA     RendererScreenBaseLo                                  ; &1F0D: 85 15
        STA     ScreenPtrLo                                  ; &1F0F: 85 19
        TXA                                          ; &1F11: 8A
        ADC     Mode1XHigh                             ; &1F12: 65 16
        STA     Mode1XHigh                             ; &1F14: 85 16
        STA     ScreenPtrHi                                  ; &1F16: 85 1A
        LDA     RendererHeight                                  ; &1F18: A5 18
        ADC     ScreenPtrLo                                  ; &1F1A: 65 19
        TXA                                          ; &1F1C: 8A
        ADC     ScreenPtrHi                                  ; &1F1D: 65 1A
        BPL     SpriteRenderSetup_ColumnLoop                                ; &1F1F: 10 C8
        SEC                                          ; &1F21: 38
        LDA     ScreenPtrHi                                  ; &1F22: A5 1A
        SBC     #MODE1_SCREEN_RING_SIZE_HI           ; &1F24: E9 50
        STA     ScreenPtrHi                                  ; &1F26: 85 1A
        STA     Mode1XHigh                             ; &1F28: 85 16
        BPL     SpriteRenderSetup_ColumnLoop                                ; &1F2A: 10 BD
SpriteRenderSetup_Return:
        CLC                                          ; &1F2C: 18
        RTS                                          ; &1F2D: 60
RendererRowDispatch:
        JMP     (RowRoutineLo)                      ; &1F2E: 6C 1C 00

; Entry points into the eight-call stub.  Selecting a later call handles the
; initial partial character row implied by RendererY AND 7.
RendererRowEntryTable:
        EQUW RendererRowCall0
        EQUW RendererRowCall1
        EQUW RendererRowCall2
        EQUW RendererRowCall3
        EQUW RendererRowCall4
        EQUW RendererRowCall5
        EQUW RendererRowCall6
        EQUW RendererRowCall7

PixelOpMaskedForward:
        LDA     (RendererDataPtrLo),Y                              ; &1F41: B1 13
        STA     MaskLookupPtrLo                    ; &1F43: 85 80
        LDA     (MaskLookupPtrLo,X)                ; &1F45: A1 80
        AND     (ScreenPtrLo),Y                              ; &1F47: 31 19
        ORA     MaskLookupPtrLo                    ; &1F49: 05 80
        STA     (ScreenPtrLo),Y                              ; &1F4B: 91 19
        DEY                                          ; &1F4D: 88
        BEQ     PixelOp_EndRowReloadHeight                                ; &1F4E: F0 15
        RTS                                          ; &1F50: 60
PixelOpMaskedReverse:
        INC     RendererDataPtrLo                                  ; &1F51: E6 13
        BEQ     PixelMaskedReverse_CarryPage                                ; &1F53: F0 15
PixelMaskedReverse_Loop:
        LDA     (RendererDataPtrLo,X)                              ; &1F55: A1 13
        STA     MaskLookupPtrLo                    ; &1F57: 85 80
        LDA     (MaskLookupPtrLo,X)                ; &1F59: A1 80
        AND     (ScreenPtrLo),Y                              ; &1F5B: 31 19
        ORA     MaskLookupPtrLo                    ; &1F5D: 05 80
        STA     (ScreenPtrLo),Y                              ; &1F5F: 91 19
        DEY                                          ; &1F61: 88
        BEQ     PixelOp_EndColumnUnwind                                ; &1F62: F0 03
        RTS                                          ; &1F64: 60
PixelOp_EndRowReloadHeight:
        LDY     RendererHeight                                  ; &1F65: A4 18
PixelOp_EndColumnUnwind:
        PLA                                          ; &1F67: 68
        PLA                                          ; &1F68: 68
        RTS                                          ; &1F69: 60
PixelMaskedReverse_CarryPage:
        INC     RendererDataPtrHi                                  ; &1F6A: E6 14
        BNE     PixelMaskedReverse_Loop                                ; &1F6C: D0 E7
PixelOpSolid:
        LDA     RendererSolidByte                                  ; &1F6E: A5 59
        STA     (ScreenPtrLo),Y                              ; &1F70: 91 19
        DEY                                          ; &1F72: 88
        BEQ     PixelOp_EndColumnUnwind                                ; &1F73: F0 F2
        RTS                                          ; &1F75: 60
PixelOpEraseForward:
        LDA     (RendererDataPtrLo),Y                              ; &1F76: B1 13
        EOR     #&FF                                 ; &1F78: 49 FF
        AND     (ScreenPtrLo),Y                              ; &1F7A: 31 19
        STA     (ScreenPtrLo),Y                              ; &1F7C: 91 19
        DEY                                          ; &1F7E: 88
        BEQ     PixelOp_EndRowReloadHeight                                ; &1F7F: F0 E4
        RTS                                          ; &1F81: 60
PixelOpEraseReverse:
        INC     RendererDataPtrLo                                  ; &1F82: E6 13
        BEQ     PixelEraseReverse_CarryPage                                ; &1F84: F0 13
PixelEraseReverse_Loop:
        LDA     (RendererDataPtrLo,X)                              ; &1F86: A1 13
        EOR     #&FF                                 ; &1F88: 49 FF
        AND     (ScreenPtrLo),Y                              ; &1F8A: 31 19
        STA     (ScreenPtrLo),Y                              ; &1F8C: 91 19
        DEY                                          ; &1F8E: 88
        BEQ     PixelOp_EndColumnUnwind                                ; &1F8F: F0 D6
        RTS                                          ; &1F91: 60
PixelOpClear:
        TXA                                          ; &1F92: 8A
        STA     (ScreenPtrLo),Y                              ; &1F93: 91 19
        DEY                                          ; &1F95: 88
        BEQ     PixelOp_EndColumnUnwind                                ; &1F96: F0 CF
        RTS                                          ; &1F98: 60
PixelEraseReverse_CarryPage:
        INC     RendererDataPtrHi                                  ; &1F99: E6 14
        BNE     PixelEraseReverse_Loop                                ; &1F9B: D0 E9

; Six operator addresses indexed by PixelOpIndex (0,2,4) plus 6 for erase mode.
; These bytes were previously false-disassembled as instructions.
PixelOperationTable:
        EQUW PixelOpMaskedForward
        EQUW PixelOpMaskedReverse
        EQUW PixelOpSolid
        EQUW PixelOpEraseForward
        EQUW PixelOpEraseReverse
        EQUW PixelOpClear

; -----------------------------------------------------------------------------
; Runtime &1FA9: MODE 1 address calculation.
; -----------------------------------------------------------------------------
; CONTRACT: convert logical RendererX/RendererY into the circular MODE 1 screen ring.
; Effect: returns base pointer state in renderer zero page, including CRTC ScreenOrigin offset.
Mode1Address:
        LDA     #&00                                 ; &1FA9: A9 00
        STA     Mode1XHigh                             ; &1FAB: 85 16
        LDA     RendererY                                  ; &1FAD: A5 22
        EOR     #&FF                                 ; &1FAF: 49 FF
        TAX                                          ; &1FB1: AA
        AND     #MODE1_SCANLINES_PER_CHAR-1          ; &1FB2: 29 07
        STA     Mode1RowOffset                            ; &1FB4: 85 23
        TXA                                          ; &1FB6: 8A
        LSR     A                                    ; &1FB7: 4A
        LSR     A                                    ; &1FB8: 4A
        ORA     #&01                                 ; &1FB9: 09 01
        TAY                                          ; &1FBB: A8
        LDA     RendererX                            ; &1FBC: A5 21
        ASL     A                                    ; &1FBE: 0A
        ROL     Mode1XHigh                             ; &1FBF: 26 16
        ASL     A                                    ; &1FC1: 0A
        ROL     Mode1XHigh                             ; &1FC2: 26 16
        ASL     A                                    ; &1FC4: 0A
        ROL     Mode1XHigh                             ; &1FC5: 26 16
        ORA     Mode1RowOffset                            ; &1FC7: 05 23
        ADC     (VDU_ROW_ADDRESS_TABLE_PTR),Y                              ; &1FC9: 71 E0
        TAX                                          ; &1FCB: AA
        DEY                                          ; &1FCC: 88
        LDA     Mode1XHigh                             ; &1FCD: A5 16
        ADC     (VDU_ROW_ADDRESS_TABLE_PTR),Y                              ; &1FCF: 71 E0
        TAY                                          ; &1FD1: A8
        TXA                                          ; &1FD2: 8A
        ADC     ScreenOriginLo                                  ; &1FD3: 65 0C
        TAX                                          ; &1FD5: AA
        TYA                                          ; &1FD6: 98
        ADC     ScreenOriginHi                                  ; &1FD7: 65 0D
        BIT     RendererX                            ; &1FD9: 24 21
        BPL     Mode1Address_AdjustHigh                                ; &1FDB: 10 02
        SBC     #MODE1_NEGATIVE_X_HI_ADJUST         ; &1FDD: E9 07
Mode1Address_AdjustHigh:
        TAY                                          ; &1FDF: A8
        BPL     Mode1Address_SubtractHeight                                ; &1FE0: 10 06
Mode1Address_WrapHigh:
        SEC                                          ; &1FE2: 38
        SBC     #MODE1_SCREEN_RING_SIZE_HI           ; &1FE3: E9 50
        BMI     Mode1Address_WrapHigh                                ; &1FE5: 30 FB
        TAY                                          ; &1FE7: A8
Mode1Address_SubtractHeight:
        SEC                                          ; &1FE8: 38
        TXA                                          ; &1FE9: 8A
        SBC     RendererHeight                                  ; &1FEA: E5 18
        TAX                                          ; &1FEC: AA
        BCS     Mode1Address_StorePointers                                ; &1FED: B0 01
        DEY                                          ; &1FEF: 88
Mode1Address_StorePointers:
        STX     ScreenPtrLo                                  ; &1FF0: 86 19
        STY     ScreenPtrHi                                  ; &1FF2: 84 1A
        STX     RendererScreenBaseLo                                  ; &1FF4: 86 15
        STY     Mode1XHigh                             ; &1FF6: 84 16
        RTS                                          ; &1FF8: 60

; Four original bytes at &1FF9-&1FFC.  The protected packed representation shared
; them with the beginning of the &01A4 block; a true multi-ORG source emits the
; bytes independently at both runtime addresses.
        EQUB &13,&00,&01,&00



; =============================================================================
; &1FFD-&2FFF - sprite descriptors, composite definitions and bitmap data
; =============================================================================
ORG REGION_SPRITES
; SECTION: SPRITE DESCRIPTORS, COMPOSITES AND BITMAP PAYLOAD
; Six parallel descriptor arrays define 92 sprite IDs. Entries point either to
; primitive MODE 1 bitmap data or recursive three-byte composite-child records.
; Trogg, platforms and ladders are composites assembled by SpriteTraversal.
;
; Six parallel 92-entry descriptor arrays indexed by sprite ID.  WidthFlags
; values of &00/&80 denote composite definitions; ordinary bitmap entries carry
; width plus the horizontal-flip flag.  DefLo/DefHi point either to bitmap bytes
; or to a sequence of three-byte composite children: child ID, signed dX, dY.
;
; Important IDs recovered from gameplay and the descriptor data:
;   &12 Scrubbly      &16 gem       &17 key        &1D Hooter
;   &1E Poglet        &23 bulb      &25 dagger     &26 flipped dagger
;   &27 balloon       &34-&3B Trogg animation frames
;   &3E-&53 platform composites     &4A-&4D rope composites
;   &54-&56 vertical structures     &57-&5A ladder composites
;   &5B death/explosion composite
;
; MOD: Sprite descriptors/bitmap data below are editable, but keep the six descriptor arrays at 92 entries and preserve composite child records. See docs/SPRITE_CATALOG.md.
SpriteXOffsets:
        EQUB &00,&01,&01,&01,&00,&01,&02,&01,&01,&FF,&00,&FF,&01,&00,&00,&00
        EQUB &00,&00,&FD,&FE,&FE,&00,&FF,&FE,&00,&00,&00,&00,&00,&FF,&FD,&00
        EQUB &00,&00,&00,&00,&FF,&FF,&FF,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

SpriteYOffsets:
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&01,&02,&00,&00,&00
        EQUB &00,&F3,&00,&00,&00,&F3,&00,&00,&F5,&F5,&F5,&F2,&F5,&00,&EF,&00
        EQUB &00,&00,&00,&00,&00,&FB,&FB,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

SpriteDefLo:
        EQUB &28,&5C,&93,&CA,&FC,&3B,&72,&A3,&E5,&27,&F7,&C7,&84,&25,&31,&25
        EQUB &31,&3D,&73,&E8,&B1,&7D,&A7,&BF,&FB,&07,&13,&36,&63,&87,&FA,&C6
        EQUB &D2,&EE,&0A,&00,&2D,&56,&56,&77,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
        EQUB &FF,&FF,&FF,&FF,&95,&9B,&A1,&A7,&AD,&B3,&B9,&BF,&C5,&CB,&D1,&D7
        EQUB &DD,&E3,&E9,&EF,&F5,&0A,&25,&40,&67,&73,&7C,&85,&91,&A0,&B2,&B8
        EQUB &BE,&C4,&CA,&D0,&D6,&DC,&E2,&E8,&EE,&F4,&FA,&00

SpriteDefHi:
        EQUB &02,&02,&02,&02,&02,&03,&03,&03,&03,&04,&04,&05,&06,&07,&07,&07
        EQUB &07,&07,&07,&08,&09,&0A,&0A,&0A,&0A,&0B,&0B,&0B,&0B,&0B,&0B,&0C
        EQUB &0C,&0C,&0D,&0E,&0E,&0E,&0E,&0E,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
        EQUB &FF,&FF,&FF,&FF,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E,&0E
        EQUB &0E,&0E,&0E,&0E,&0E,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&10

SpriteWidthFlags:
        EQUB &02,&04,&04,&04,&05,&04,&04,&05,&05,&07,&07,&07,&06,&02,&02,&82
        EQUB &82,&04,&09,&05,&05,&03,&03,&06,&01,&01,&03,&03,&03,&05,&06,&02
        EQUB &02,&02,&0D,&03,&03,&03,&83,&03,&02,&04,&06,&08,&0A,&0C,&0E,&10
        EQUB &12,&14,&16,&18,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00

SpriteHeightCount:
        EQUB &1A,&0B,&0B,&0B,&0B,&0B,&0B,&0B,&0B,&1A,&1A,&18,&17,&06,&06,&06
        EQUB &06,&0E,&2A,&22,&22,&0E,&09,&0A,&0C,&0C,&0C,&0F,&0C,&17,&22,&06
        EQUB &0E,&0E,&13,&0F,&0E,&0B,&0B,&0A,&01,&01,&01,&01,&01,&01,&01,&01
        EQUB &01,&01,&01,&01,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02
        EQUB &02,&02,&02,&02,&07,&09,&09,&0D,&04,&03,&03,&04,&05,&06,&02,&02
        EQUB &02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&02,&01

SpriteDefinitionData:
; Bitmap and composite payloads referenced by SpriteDefLo/SpriteDefHi.
; Trogg is built recursively from head/body primitives; the platform and ladder
; families similarly compose short primitives into longer level pieces.

        EQUB &F9,&F9,&F9,&F9,&F9,&F9,&F8,&74,&74,&F8,&F9,&F9,&F9,&F9,&F8,&74
        EQUB &74,&74,&74,&74,&F8,&F9,&F9,&F9,&F9,&F9,&00,&00,&00,&00,&00,&00
        EQUB &88,&88,&88,&88,&00,&00,&00,&00,&88,&88,&88,&88,&88,&88,&88,&00
        EQUB &00,&00,&00,&00,&11,&11,&00,&00,&00,&00,&11,&11,&33,&23,&33,&FF
        EQUB &8F,&CF,&67,&DF,&8F,&9F,&1F,&3F,&0F,&FF,&FF,&3F,&1F,&1F,&0F,&8F
        EQUB &8F,&CF,&CF,&8F,&FF,&00,&00,&00,&88,&88,&88,&88,&BB,&DF,&1F,&FF
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&00,&00,&11,&33
        EQUB &67,&47,&47,&67,&33,&00,&FF,&8F,&8F,&8F,&8F,&4F,&4F,&CF,&4F,&8F
        EQUB &FF,&FF,&2E,&2E,&2E,&6E,&4C,&CC,&FF,&DF,&1F,&FF,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&11,&00,&00,&11,&33,&77,&47,&47,&67,&23,&33,&FF,&8F,&8F
        EQUB &8F,&0F,&1F,&3F,&7F,&7F,&1F,&FF,&FF,&2E,&2E,&7F,&9F,&1F,&1F,&9F
        EQUB &8F,&CF,&77,&00,&00,&00,&00,&00,&00,&EE,&AE,&2E,&EE,&CC,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&11,&00,&00,&11
        EQUB &00,&11,&11,&77,&CF,&0F,&1F,&9F,&8F,&FF,&FF,&8F,&8F,&0F,&1F,&2F
        EQUB &6F,&EF,&EF,&CF,&FF,&FF,&2E,&6E,&AE,&2E,&2E,&6E,&7F,&6F,&0F,&FF
        EQUB &00,&00,&00,&00,&00,&00,&00,&88,&88,&88,&88,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&11,&11,&11,&11,&DD,&BF,&8F,&FF,&FF,&CF
        EQUB &8F,&8F,&0F,&1F,&1F,&3F,&3F,&1F,&FF,&FF,&1F,&3F,&6E,&BF,&1F,&9F
        EQUB &8F,&CF,&0F,&FF,&CC,&88,&00,&00,&00,&00,&88,&88,&CC,&4C,&CC,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&FF,&47,&47,&47,&67,&23
        EQUB &33,&FF,&BF,&8F,&FF,&FF,&1F,&1F,&1F,&1F,&2F,&2F,&3F,&2F,&1F,&FF
        EQUB &88,&00,&00,&88,&CC,&6E,&2E,&2E,&6E,&CC,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&77,&57,&47,&77,&33,&FF,&47,&47,&EF,&9F,&8F,&8F,&9F,&1F,&3F
        EQUB &EE,&FF,&1F,&1F,&1F,&0F,&8F,&CF,&EF,&EF,&8F,&FF,&88,&00,&00,&88
        EQUB &CC,&EE,&2E,&2E,&6E,&4C,&CC,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&33,&23,&67,&47,&CF,&0F,&3F,&6E,&7F,&3F,&FF,&00,&00,&00
        EQUB &00,&00,&00,&00,&11,&11,&11,&11,&FF,&47,&67,&57,&47,&47,&67,&EF
        EQUB &6F,&0F,&FF,&FF,&1F,&1F,&0F,&8F,&4F,&6F,&7F,&7F,&3F,&FF,&88,&00
        EQUB &88,&88,&EE,&3F,&0F,&8F,&9F,&1F,&FF,&00,&00,&00,&00,&00,&88,&88
        EQUB &88,&88,&00,&00,&33,&23,&67,&47,&CF,&0F,&3F,&6E,&7F,&3F,&FF,&00
        EQUB &00,&00,&33,&23,&33,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&23,&EF,&0F,&FF,&33
        EQUB &11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&FF,&FF,&D3,&E9,&E9,&0F,&DF,&3F,&FF,&77,&67,&67,&EF
        EQUB &FB,&FB,&FF,&CF,&CF,&FF,&FC,&76,&33,&11,&00,&00,&00,&88,&EE,&FF
        EQUB &FF,&FF,&FF,&BF,&8F,&0F,&2F,&2F,&3F,&1F,&8F,&FF,&FF,&6F,&0F,&FF
        EQUB &F0,&F0,&F0,&F8,&00,&00,&00,&00,&00,&88,&CC,&FF,&FF,&FF,&3F,&1F
        EQUB &0F,&0F,&0F,&8F,&CF,&FF,&CF,&0F,&0F,&FF,&F0,&F0,&F0,&F1,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&88,&00,&88,&EE,&FF,&DF,&6F,&6F,&3F,&1F
        EQUB &1F,&1F,&3F,&FF,&F1,&F3,&F6,&FF,&77,&77,&33,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&88,&88,&88,&CC,&4C,&4C,&4C,&6E,&3F,&1F,&DF
        EQUB &F3,&FD,&FF,&FF,&EE,&11,&33,&67,&DF,&67,&33,&11,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&4C,&F4,&FF,&85,&20,&A9,&80,&24,&20,&D0,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&33,&23,&23,&23
        EQUB &67,&CF,&8F,&BF,&FC,&FB,&FF,&FF,&77,&00,&00,&00,&00,&00,&11,&00
        EQUB &11,&77,&CF,&8F,&0F,&1F,&1F,&3F,&2F,&7F,&7C,&FC,&7C,&FE,&F7,&FF
        EQUB &EE,&EE,&CC,&00,&00,&11,&33,&FF,&FF,&FF,&DF,&0F,&0F,&0F,&3F,&EF
        EQUB &0F,&0F,&1F,&FF,&F0,&F0,&F0,&F0,&F0,&F8,&00,&00,&00,&11,&77,&FF
        EQUB &FF,&FF,&FF,&DF,&E7,&FB,&F9,&FD,&FD,&FC,&FC,&F8,&F8,&F0,&F0,&F0
        EQUB &F0,&F0,&F0,&F1,&00,&00,&00,&FF,&FF,&BC,&79,&79,&0F,&BF,&CF,&7F
        EQUB &2E,&3F,&9F,&9F,&DF,&D7,&F7,&F3,&F1,&F1,&F1,&F3,&E6,&CC,&00,&00
        EQUB &00,&00,&88,&4C,&7F,&0F,&FF,&CC,&88,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&CC,&4C
        EQUB &CC,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&11,&33,&67,&DF,&67,&33,&11,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&4C,&F4,&FF,&85,&20,&A9,&80,&24,&20,&D0,&00
        EQUB &00,&00,&77,&47,&77,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &11,&11,&11,&77,&47,&77,&00,&11,&33,&56,&DF,&1F,&EF,&77,&23,&11
        EQUB &00,&11,&11,&11,&11,&11,&11,&33,&FF,&7F,&9F,&3F,&6E,&CC,&00,&FF
        EQUB &FF,&B7,&D3,&D3,&1F,&BF,&6F,&CF,&8F,&8F,&CF,&C7,&C7,&E7,&E3,&F3
        EQUB &F0,&F0,&F8,&FC,&76,&33,&00,&00,&CC,&FF,&FF,&FF,&FF,&7F,&0F,&0F
        EQUB &0F,&0F,&CF,&BF,&1F,&0F,&0F,&FF,&F0,&F0,&F0,&F0,&F0,&F8,&00,&00
        EQUB &00,&00,&88,&EE,&FF,&EE,&FF,&7F,&1F,&0F,&0F,&0F,&CF,&7F,&1F,&FF
        EQUB &F0,&F0,&F0,&F0,&F0,&F1,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &88,&EE,&3F,&1F,&1F,&0F,&8F,&8F,&8F,&CF,&CF,&CF,&8F,&CF,&77,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&88,&88,&88,&88
        EQUB &88,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&11,&33,&67,&57,&67,&33,&11,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&11,&33,&77,&DF,&9F,&BF,&AF,&AF,&BF,&FE,&76,&32
        EQUB &32,&33,&11,&00,&00,&00,&11,&77,&FF,&77,&EF,&CF,&8F,&8F,&0F,&0F
        EQUB &3F,&5F,&0F,&FF,&F0,&F0,&F0,&F0,&F0,&F8,&00,&33,&FF,&FF,&FF,&FF
        EQUB &EF,&FB,&7D,&7E,&3F,&1F,&0F,&0F,&8F,&CF,&EF,&F3,&F1,&F0,&F0,&F0
        EQUB &F1,&FF,&FF,&DE,&BC,&BC,&8F,&DF,&6F,&BF,&9F,&9F,&CF,&CF,&6F,&6F
        EQUB &3F,&1F,&0F,&CF,&F7,&F3,&EE,&88,&88,&CC,&A6,&BF,&8F,&7F,&EE,&4C
        EQUB &88,&00,&88,&88,&88,&88,&88,&88,&CC,&FF,&6F,&1F,&CF,&67,&33,&00
        EQUB &00,&00,&EE,&2E,&EE,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &88,&88,&88,&EE,&2E,&EE,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&22,&33,&31,&31,&33,&22,&77,&FC,&FF
        EQUB &FF,&FF,&77,&CC,&E6,&E2,&EA,&EE,&CC,&77,&FC,&F9,&FB,&FF,&77,&CC
        EQUB &E6,&EE,&EE,&EE,&CC,&66,&BF,&0F,&0F,&0F,&FF,&FB,&76,&33,&11,&11
        EQUB &00,&00,&00,&FF,&8F,&0F,&0F,&FF,&FB,&F4,&FB,&FA,&F5,&FA,&FD,&F9
        EQUB &EA,&44,&BF,&0F,&0F,&3F,&FE,&FD,&F2,&FD,&F2,&FD,&F2,&FD,&F9,&DD
        EQUB &2F,&0F,&0F,&EF,&FB,&F5,&EA,&C4,&CC,&88,&88,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&11,&33,&00,&00,&11,&33,&77,&67,&CF
        EQUB &DF,&BF,&FF,&99,&99,&11,&33,&67,&67,&CF,&DF,&FF,&DD,&99,&88,&44
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&11,&00,&00,&00,&33,&77
        EQUB &EF,&FF,&33,&67,&CF,&8F,&8F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&1F,&1F
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&8F,&8F,&8F,&CF,&77,&33,&32,&33,&11,&00
        EQUB &77,&CF,&9F,&6E,&88,&00,&33,&EF,&CF,&0F,&0F,&8F,&0F,&0F,&3F,&7E
        EQUB &FC,&F8,&F9,&F9,&FD,&7F,&0F,&0F,&7F,&F8,&F8,&F8,&FD,&7D,&7D,&7F
        EQUB &2F,&2F,&0F,&0F,&0F,&FF,&F3,&F0,&FF,&77,&EF,&3F,&8F,&EF,&67,&EF
        EQUB &8F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&EF,&F3,&F1,&FD,&FF,&FF,&EF,&CF
        EQUB &0F,&0F,&5F,&EF,&8F,&8F,&8F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F
        EQUB &FF,&CC,&88,&DD,&7F,&6F,&0F,&1F,&3F,&3F,&0F,&0F,&0F,&0F,&0F,&0F
        EQUB &0F,&0F,&3F,&7E,&7C,&7D,&7F,&7F,&3F,&1F,&0F,&0F,&5F,&BF,&0F,&0F
        EQUB &0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&0F,&FF,&11,&00,&FF,&8F,&2F
        EQUB &FF,&99,&00,&88,&EE,&3F,&1F,&0F,&0F,&0F,&0F,&0F,&EF,&F3,&F1,&F8
        EQUB &FC,&FC,&FD,&FF,&0F,&0F,&7F,&F8,&F8,&F8,&FD,&7D,&7D,&7F,&2F,&2F
        EQUB &0F,&0F,&0F,&7F,&FE,&F8,&FF,&88,&CC,&4C,&4C,&CC,&00,&00,&00,&88
        EQUB &EE,&7F,&3F,&FF,&6E,&3F,&1F,&0F,&8F,&8F,&8F,&8F,&8F,&0F,&0F,&0F
        EQUB &4F,&CF,&8F,&8F,&8F,&0F,&0F,&0F,&0F,&0F,&0F,&1F,&3F,&EE,&E2,&E6
        EQUB &CC,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&88,&CC,&66,&00
        EQUB &88,&CC,&EE,&7F,&3F,&1F,&5F,&6F,&7F,&4C,&4C,&4C,&6E,&3F,&3F,&1F
        EQUB &5F,&7F,&DD,&CC,&88,&99,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&88
        EQUB &88,&88,&88,&88,&88,&00,&00,&00,&00,&88,&88,&88,&88,&88,&88,&00
        EQUB &00,&00,&00,&00,&00,&33,&67,&CF,&BF,&8F,&CF,&67,&33,&11,&11,&11
        EQUB &11,&11,&11,&11,&11,&11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&11,&33,&33,&77,&77,&FF,&FF,&FF,&FF,&7F,&0F,&0F,&0F,&8F
        EQUB &0F,&0F,&3F,&FE,&F0,&F0,&F0,&F8,&FC,&FF,&8F,&8F,&CF,&CF,&47,&47
        EQUB &47,&67,&47,&77,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&1F,&3F
        EQUB &3E,&7E,&7C,&FC,&F8,&F0,&F0,&F0,&F0,&F1,&F3,&FF,&5D,&5D,&CC,&4C
        EQUB &4C,&5D,&DD,&5D,&4C,&CC,&88,&CC,&CC,&FF,&EF,&EF,&FF,&FF,&FD,&F9
        EQUB &F3,&E3,&E3,&E3,&F3,&F1,&F0,&F0,&F0,&F0,&F0,&FF,&0F,&0F,&1F,&BF
        EQUB &9F,&DF,&BF,&9F,&3F,&EE,&00,&00,&00,&00,&00,&88,&CC,&4C,&6E,&EE
        EQUB &BF,&1F,&3F,&EE,&CC,&4C,&4C,&CC,&C4,&C4,&C4,&C4,&CC,&88,&88,&88
        EQUB &88,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&23,&67
        EQUB &77,&CF,&8F,&CF,&77,&33,&33,&23,&33,&32,&32,&32,&32,&33,&11,&11
        EQUB &11,&11,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&33,&33,&FF,&7F
        EQUB &7F,&FF,&FF,&1F,&0F,&0F,&0F,&0F,&0F,&7F,&FC,&F0,&F0,&F0,&F0,&F0
        EQUB &FF,&0F,&0F,&8F,&DF,&9F,&BF,&DF,&9F,&CF,&77,&00,&00,&FF,&FF,&FF
        EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&3F,&3E,&7E,&FC,&F8,&F0,&F0,&F0,&F0
        EQUB &F0,&F0,&F8,&FC,&FF,&AB,&AB,&23,&33,&23,&AB,&BB,&AB,&23,&33,&88
        EQUB &CC,&CC,&EE,&EE,&FF,&FF,&FF,&FB,&F3,&E3,&E7,&C7,&D7,&C7,&E7,&F3
        EQUB &F1,&F0,&F0,&F0,&F1,&F3,&FF,&1F,&1F,&1F,&3F,&2E,&2E,&2E,&EE,&2E
        EQUB &EE,&00,&00,&00,&00,&00,&CC,&6E,&3F,&DF,&1F,&3F,&6E,&CC,&88,&88
        EQUB &88,&88,&88,&88,&88,&88,&88,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&01,&77,&00,&00,&00,&00,&01,&77,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&11,&33,&67,&DF,&67,&33,&11,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&FF,&F8,&FB,&FD,&76,&33,&11,&11,&33,&76,&FD
        EQUB &FB,&F8,&FF,&FF,&F0,&FF,&99,&FF,&F6,&F9,&F9,&F6,&FF,&99,&FF,&F0
        EQUB &FF,&FF,&F1,&FD,&FB,&E6,&CC,&88,&88,&CC,&E6,&FB,&FD,&F1,&FF,&33
        EQUB &76,&FD,&FC,&76,&33,&11,&00,&00,&FF,&F0,&FF,&F0,&F0,&F1,&FB,&EE
        EQUB &44,&88,&CC,&E6,&E6,&CC,&88,&00,&00,&00,&FF,&F8,&FF,&74,&74,&75
        EQUB &66,&00,&00,&00,&FF,&F0,&FF,&E2,&E2,&EA,&66,&00,&00,&00,&FF,&F0
        EQUB &FF,&00,&00,&00,&00,&00,&11,&33,&FE,&F0,&FE,&33,&11,&00,&00,&FF
        EQUB &F9,&F0,&F3,&F3,&F3,&F0,&F9,&FF,&00,&00,&88,&CC,&C4,&C4,&C4,&CC
        EQUB &88,&00,&00,&77,&67,&AF,&BF,&AF,&BF,&AF,&AF,&BF,&AF,&67,&77,&EE
        EQUB &2E,&7F,&9F,&3F,&DF,&1F,&1F,&FF,&3F,&2E,&EE,&FF,&0F,&3F,&CF,&0F
        EQUB &FF,&0F,&0F,&FF,&0F,&0F,&FF,&FF,&0F,&CF,&3F,&0F,&8F,&7F,&0F,&CF
        EQUB &3F,&0F,&FF,&FF,&0F,&0F,&FF,&0F,&FF,&0F,&0F,&3F,&CF,&0F,&FF,&0F
        EQUB &0F,&FF,&0F,&9F,&6F,&0F,&FF,&0F,&0F,&FF,&11,&00,&00,&FF,&0F,&FF
        EQUB &0F,&3F,&CF,&0F,&7F,&8F,&3F,&1F,&1F,&CF,&77,&11,&FF,&0F,&EF,&1F
        EQUB &CF,&3F,&0F,&EF,&1F,&CF,&77,&99,&CC,&4C,&CC,&FF,&0F,&1F,&EF,&0F
        EQUB &8F,&6F,&1F,&CF,&3F,&0F,&FF,&FF,&0F,&FF,&0F,&FF,&FF,&0F,&FF,&0F
        EQUB &FF,&0F,&FF,&FF,&0F,&8F,&7F,&0F,&3F,&4F,&8F,&3F,&CF,&0F,&FF,&77
        EQUB &DD,&CC,&00,&11,&11,&33,&67,&47,&CF,&9F,&9F,&9F,&AF,&EF,&23,&23
        EQUB &33,&11,&00,&33,&CF,&FF,&00,&77,&FC,&FB,&FB,&FC,&7F,&0F,&9F,&9F
        EQUB &AF,&3F,&2F,&3F,&1F,&0F,&0F,&0F,&8F,&FF,&1F,&8F,&FF,&00,&BB,&FE
        EQUB &BF,&BF,&FE,&BF,&AF,&1F,&1F,&EF,&1F,&0F,&1F,&FF,&0F,&0F,&0F,&0F
        EQUB &FF,&11,&AB,&BB,&11,&DD,&E6,&EA,&FB,&F7,&DF,&0F,&2F,&2F,&BF,&9F
        EQUB &9F,&8F,&0F,&0F,&0F,&1F,&3F,&EE,&1F,&2F,&FF,&CC,&66,&66,&00,&00
        EQUB &00,&88,&88,&CC,&4C,&6E,&2E,&2E,&AE,&EE,&88,&88,&88,&00,&00,&88
        EQUB &6E,&EE,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&11,&11,&33,&32
        EQUB &32,&32,&32,&32,&33,&11,&11,&11,&00,&00,&00,&77,&FC,&F9,&F9,&FD
        EQUB &75,&EF,&8F,&FF,&00,&00,&00,&11,&33,&32,&76,&74,&FF,&CF,&CF,&C7
        EQUB &C7,&E7,&F7,&C4,&C4,&C4,&E6,&E2,&F3,&F9,&FF,&23,&EF,&EB,&E3,&FF
        EQUB &11,&BB,&EF,&CF,&EF,&BB,&00,&33,&EF,&CF,&F3,&E6,&CC,&88,&88,&88
        EQUB &7F,&7C,&7E,&FB,&FB,&F9,&FB,&EB,&FB,&74,&23,&EF,&0F,&0F,&0F,&0F
        EQUB &0F,&0F,&8F,&FF,&6E,&3F,&3E,&FF,&00,&FF,&1F,&1F,&FF,&00,&00,&00
        EQUB &11,&33,&EF,&E3,&E7,&FD,&FD,&F9,&FD,&7D,&FD,&E2,&4C,&7F,&0F,&0F
        EQUB &1F,&1F,&1F,&1F,&1F,&FF,&77,&FC,&F1,&FF,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&EE,&2E,&2E,&2E,&2E,&6E,&88,&00,&00,&00,&00,&00,&00,&88
        EQUB &CC,&EA,&EA,&F3,&F2,&F3,&F3,&F3,&F3,&E7,&EF,&33,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
        EQUB &00,&00,&00,&00,&00,&CC,&E6,&E2,&E2,&E6,&C4,&EE,&2E,&EE,&EA,&EA
        EQUB &FB,&F9,&FC,&77,&75,&75,&FD,&F9,&F3,&EE,&EA,&FB,&EB,&F9,&FC,&FF
        EQUB &AE,&AE,&FF,&FC,&F9,&EB,&FB,&EA,&75,&FD,&3F,&9F,&D7,&DF,&57,&57
        EQUB &DF,&D7,&9F,&3F,&FD,&75,&FF,&F8,&FC,&77,&23,&23,&33,&DD,&BF,&FC
        EQUB &F9,&EB,&FB,&EA,&FF,&F1,&F3,&EE,&4C,&6E,&3F,&9F,&9F,&9F,&3F,&7D
        EQUB &FD,&75,&00,&33,&76,&FC,&F8,&F8,&F8,&F8,&F8,&F8,&F8,&FC,&76,&33
        EQUB &00,&00,&00,&00,&33,&FF,&F8,&F0,&F3,&F3,&F3,&F3,&F3,&F3,&F3,&F3
        EQUB &F3,&F0,&F8,&FF,&33,&76,&FC,&FF,&FF,&F0,&F0,&FF,&FF,&F0,&F0,&FE
        EQUB &FE,&F0,&F0,&F0,&F0,&F0,&F0,&F1,&F3,&EE,&88,&FF,&F0,&F0,&FB,&FB
        EQUB &F3,&F3,&F3,&F3,&F3,&F3,&F3,&F0,&F0,&FF,&88,&00,&00,&00,&FF,&F0
        EQUB &F0,&FF,&FF,&F1,&F1,&FF,&FE,&F7,&F3,&F1,&F0,&F0,&FF,&00,&00,&00
        EQUB &00,&FF,&F0,&F0,&F0,&F9,&F9,&F9,&F1,&F1,&F1,&F9,&F9,&F0,&F0,&FF
        EQUB &00,&00,&00,&00,&FF,&F0,&F0,&FF,&FF,&F8,&F8,&FF,&FF,&F8,&F8,&F8
        EQUB &F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0,&F8,&FC,&FC,&FC,&FC,&FC
        EQUB &FC,&FC,&FC,&F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0,&FC,&FC,&FD
        EQUB &FF,&FF,&FF,&FD,&FC,&FC,&F0,&F0,&FF,&00,&00,&00,&00,&FF,&F0,&F0
        EQUB &F6,&FE,&FC,&F8,&F0,&F8,&FC,&FE,&F6,&F0,&F0,&FF,&00,&00,&00,&00
        EQUB &FF,&F0,&F0,&F3,&F3,&F3,&F3,&F3,&F3,&F0,&F3,&F3,&F0,&F0,&FF,&00
        EQUB &00,&00,&00,&CC,&F7,&F1,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&F1
        EQUB &F7,&CC,&00,&00,&00,&00,&00,&00,&88,&CC,&C4,&C4,&C4,&C4,&C4,&C4
        EQUB &C4,&CC,&88,&00,&00,&00,&00,&00,&00,&11,&00,&00,&00,&11,&11,&33
        EQUB &76,&74,&74,&74,&76,&33,&11,&FF,&FF,&FF,&FF,&F9,&F9,&F0,&F0,&F0
        EQUB &F0,&F0,&F0,&F0,&F0,&FF,&00,&88,&00,&00,&00,&88,&88,&CC,&E6,&E2
        EQUB &E2,&E2,&E6,&CC,&88,&00,&00,&FF,&F8,&FF,&00,&00,&00,&00,&FF,&F8
        EQUB &FF,&00,&00,&F9,&F9,&F9,&FF,&F9,&F9,&F9,&F9,&F9,&F9,&FF,&F9,&F9
        EQUB &F9,&00,&00,&FF,&F1,&FF,&00,&00,&00,&00,&FF,&F1,&FF,&00,&00,&11
        EQUB &00,&00,&00,&11,&11,&32,&75,&66,&88,&00,&88,&DD,&77,&FB,&F1,&E2
        EQUB &CC,&00,&00,&00,&88,&CC,&EE,&88,&00,&88,&CC,&44,&00,&00,&00,&11
        EQUB &67,&8F,&8F,&8F,&8F,&8F,&67,&11,&00,&FF,&0F,&3C,&1E,&0F,&0F,&0F
        EQUB &0F,&FF,&66,&88,&6E,&1F,&97,&97,&1F,&1F,&6E,&88,&00,&0A,&FD,&08
        EQUB &01,&FD,&00,&0A,&FD,&08,&02,&FD,&00,&0A,&FD,&08,&03,&FD,&00,&0A
        EQUB &FD,&08,&04,&FD,&00,&09,&FD,&08,&05,&FD,&00,&09,&FD,&08,&06,&FD
        EQUB &00,&09,&FD,&08,&07,&FD,&00,&09,&FD,&08,&08,&FD,&00,&0C,&FD,&09
        EQUB &04,&FD,&00,&0B,&FD,&09,&08,&FD,&00,&15,&00,&00,&15,&03,&00,&15
        EQUB &00,&00,&3E,&03,&00,&15,&00,&00,&3F,&03,&00,&15,&00,&00,&40,&03
        EQUB &00,&15,&00,&00,&41,&03,&00,&15,&00,&00,&42,&03,&00,&18,&00,&00
        EQUB &1A,&01,&00,&1B,&04,&00,&1C,&07,&00,&1B,&0A,&00,&1C,&0D,&00,&19
        EQUB &10,&00,&18,&00,&00,&1A,&01,&00,&1A,&04,&00,&1B,&07,&00,&1B,&0A
        EQUB &00,&1C,&0D,&00,&1B,&10,&00,&1A,&13,&00,&19,&16,&00,&18,&00,&00
        EQUB &1B,&01,&00,&1C,&04,&00,&1C,&07,&00,&1A,&0A,&00,&1B,&0D,&00,&1A
        EQUB &10,&00,&1A,&13,&00,&19,&16,&00,&18,&00,&00,&1A,&01,&00,&1A,&04
        EQUB &00,&1A,&07,&00,&1B,&0A,&00,&1A,&0D,&00,&1C,&10,&00,&1A,&13,&00
        EQUB &1A,&16,&00,&1B,&19,&00,&1A,&1C,&00,&1A,&1F,&00,&19,&22,&00,&18
        EQUB &00,&00,&1C,&01,&00,&1B,&04,&00,&19,&07,&00,&18,&00,&00,&1A,&01
        EQUB &00,&19,&04,&00,&1F,&00,&00,&20,&00,&06,&21,&00,&14,&1F,&00,&00
        EQUB &20,&00,&06,&20,&00,&14,&21,&00,&22,&1F,&00,&00,&20,&00,&06,&20
        EQUB &00,&14,&20,&00,&22,&21,&00,&30,&1F,&00,&00,&20,&00,&06,&20,&00
        EQUB &14,&20,&00,&22,&20,&00,&30,&21,&00,&3E,&11,&00,&00,&11,&04,&00
        EQUB &11,&00,&00,&4E,&04,&00,&11,&00,&00,&4F,&04,&00,&11,&00,&00,&50
        EQUB &04,&00,&11,&00,&00,&51,&04,&00,&11,&00,&00,&52,&04,&00,&00,&00
        EQUB &00,&00,&00,&19,&00,&00,&00,&54,&00,&19,&00,&00,&00,&55,&00,&19
        EQUB &24,&00,&00,&24,&00,&0E,&24,&00,&00,&57,&00,&0E,&24,&00,&00,&58
        EQUB &00,&0E,&24,&00,&00,&59,&00,&0E,&22,&03,&1A

; =============================================================================
; &3000+ - transient startup only
; =============================================================================
; This routine is needed only until it jumps to &0380.  Frak subsequently uses
; &3000 upward as display memory, so the startup segment is intentionally disposable.
ORG REGION_STARTUP
; SECTION: ONE-SHOT MACHINE INITIALISATION
; The boot loader has already installed every sparse segment. This code clears
; game state, installs vectors/timers, sets up sprite descriptor pointers and
; sound/tune offsets, then jumps to &0380. It is thereafter disposable screen RAM.
start:

; CONTRACT: one-shot sparse-image startup; disposable after entry to the game.
; Effect: establishes stack/ZP state, envelopes, vectors, sprite pointers, MOS/VIA setup and
; sound-stream offsets, then jumps to RuntimeGameEntry.
GameInitialise:
        SEI
        LDX #STARTUP_SAFE_STACK_TOP
        TXS
        CLD

; The protected release copied a 152-byte opaque blob over &00-&97.  Direct
; read-before-write tracing shows that the game itself needs only a small,
; meaningful subset of that initial state before normal runtime initialisation:
; the recursive composite-sprite walker scratch at &1E-&20 and the PRNG state
; at &28.  Initialise those values explicitly and clear the rest.
        LDA #&00
        LDX #GAME_ZERO_PAGE_LAST
Startup_ClearZeroPage:
        STA &00,X
        DEX
        BPL Startup_ClearZeroPage

        LDA #STARTUP_TRAVERSAL_COUNT_SEED
        STA SpriteTraversalCount
        LDA #STARTUP_TRAVERSAL_PTR_LO_SEED
        STA SpriteTraversalPtrLo
        LDA #STARTUP_TRAVERSAL_PTR_HI_SEED
        STA SpriteTraversalPtrHi
        LDA #STARTUP_RANDOM_SEED
        STA RandomState

; *TAPE is selected by boot-loader @basic metadata before segment installation.

        LDA #ENGINE_PREFIX_INITIAL_STATE
        STA EnginePrefixState
        LDY #MOS_WORKSPACE_CLEAR_LAST
        LDA #&00
Startup_ClearMosWorkspace:
        STA MOSWorkspaceClearBase,Y
        DEY
        BPL Startup_ClearMosWorkspace

; Initialise the four original sound/envelope OSWORD blocks.
        LDX #<EnvelopeMusicDefinition
        LDY #>EnvelopeMusicDefinition
        LDA #OSWORD_ENVELOPE
        JSR OSWORDWrapper
        LDX #<EnvelopeMoveDefinition
        LDY #>EnvelopeMoveDefinition
        LDA #OSWORD_ENVELOPE
        JSR OSWORDWrapper
        LDX #<EnvelopeYoyoHitDefinition
        LDY #>EnvelopeYoyoHitDefinition
        LDA #OSWORD_ENVELOPE
        JSR OSWORDWrapper
        LDX #<EnvelopeCollectDefinition
        LDY #>EnvelopeCollectDefinition
        LDA #OSWORD_ENVELOPE
        JSR OSWORDWrapper

; Install the event handler, preserving the original KEYV before replacing it.
        LDX #<TickIRQ
        LDY #>TickIRQ
        STY EVENTV+1
        STX EVENTV
        LDY KEYV+1
        LDX KEYV
        STY SavedKeyVHi
        STX SavedKeyVLo

        LDX #EVENT_VERTICAL_SYNC
        LDA #OSBYTE_ENABLE_EVENT
        JSR OSBYTEWrapper

; Install the sound IRQ handler, preserving the previous IRQ1V.
        LDY IRQ1V+1
        LDX IRQ1V
        STY SavedIRQ1VHi
        STX SavedIRQ1VLo
        LDX #<SoundIRQ
        LDY #>SoundIRQ
        STY IRQ1V+1
        STX IRQ1V

        LDX #&00
        STX SoundMutedFlag
        STX ScrollRefreshRequestFlag
        STX VerticalFlipFlag
        STX SelectedControlScheme
        STX PauseFlag
        STX MosCallInProgressFlag
        DEX
        STX MusicInhibitFlag
        STX ControlScheme
        JSR ResetCountdownDivider

; Build six zero-page pointers to the parallel sprite descriptor arrays.
        LDX #<SpriteXOffsets
        LDY #>SpriteXOffsets
        STY SpriteXOffsetPtrHi
        STX SpriteXOffsetPtrLo
        LDX #<SpriteYOffsets
        LDY #>SpriteYOffsets
        STY SpriteYOffsetPtrHi
        STX SpriteYOffsetPtrLo
        LDX #<SpriteDefLo
        LDY #>SpriteDefLo
        STY SpriteDefLoPtrHi
        STX SpriteDefLoPtrLo
        LDX #<SpriteDefHi
        LDY #>SpriteDefHi
        STY SpriteDefHiPtrHi
        STX SpriteDefHiPtrLo
        LDX #<SpriteWidthFlags
        LDY #>SpriteWidthFlags
        STY SpriteWidthPtrHi
        STX SpriteWidthPtrLo
        LDX #<SpriteHeightCount
        LDY #>SpriteHeightCount
        STY SpriteHeightPtrHi
        STX SpriteHeightPtrLo

        LDA #>Mode1Masks
        STA MaskLookupPtrHi
        LDY #OSBYTE_KEYBOARD_STATUS_Y
        LDX #OSBYTE_KEYBOARD_STATUS_X
        LDA #OSBYTE_KEYBOARD_STATUS
        JSR OSBYTEWrapper
        LDY #&00
        LDX #OSBYTE_ADC_8BIT_X
        LDA #OSBYTE_ADC_8BIT_MODE
        JSR OSBYTEWrapper
        LDA #OSBYTE_REFLECT_LEDS
        JSR OSBYTEWrapper
        LDX #OSBYTE_FLASH_MARK_X
        LDA #OSBYTE_SET_FLASH_MARK
        JSR OSBYTEWrapper
        LDX #OSBYTE_FLASH_SPACE_X
        LDA #OSBYTE_SET_FLASH_SPACE
        JSR OSBYTEWrapper

        LDA #USER_VIA_IER_INITIAL
        STA USER_VIA_IER
        LDA #USER_VIA_ACR_INITIAL
        STA USER_VIA_ACR

; Cache the five sound-stream segment offsets in &8B-&8F.
        LDY #&00
        LDX #TuneOffsetScreenA
Startup_FindSoundStreams:
        STY &00,X
Startup_ScanSoundStream:
        INY
        LDA SoundStream-1,Y
        BPL Startup_ScanSoundStream
        INX
        CPX #TuneOffsetComplete
        BCC Startup_FindSoundStreams
        STY &00,X

; Install KEYV and enable the required System VIA interrupt source.
        LDX #<KeyVHandler
        LDY #>KeyVHandler
        STY KEYV+1
        STX KEYV
        LDA #SYSTEM_VIA_IER_INITIAL
        STA SYSTEM_VIA_IER
        JMP RuntimeGameEntry

; OSWORD 8 envelope records below are the four envelopes selected by the sound
; blocks at &01A4. Byte order is the BBC ENVELOPE parameter order:
; number,T,PI1,PI2,PI3,PN1,PN2,PN3,AA,AD,AS,AR,ALA,ALD.
; MOD: These 14-byte records control the four envelope shapes. The first byte
; must continue to match SOUND_ENVELOPE_MUSIC/MOVE/YOYO_HIT/COLLECT above.
EnvelopeMusicDefinition:
        EQUB &01,&01,&00,&00,&00,&01,&01,&01,&64,&F6,&FE,&FC,&64,&3C    ; original &4653
        ; ENVELOPE 1,1,0,0,0,1,1,1,100,-10,-2,-4,100,60
EnvelopeMoveDefinition:
        EQUB &02,&01,&00,&00,&00,&01,&01,&01,&64,&9C,&9C,&9C,&64,&00    ; original &4661
        ; ENVELOPE 2,1,0,0,0,1,1,1,100,-100,-100,-100,100,0
EnvelopeYoyoHitDefinition:
        EQUB &03,&82,&00,&02,&FD,&02,&06,&04,&3C,&07,&F2,&F2,&3C,&6E    ; original &466F
        ; ENVELOPE 3,&82,0,2,-3,2,6,4,60,7,-14,-14,60,110
EnvelopeCollectDefinition:
        EQUB &04,&82,&00,&FC,&02,&03,&03,&28,&28,&FC,&FB,&FB,&78,&74    ; original &467D
        ; ENVELOPE 4,&82,0,-4,2,3,3,40,40,-4,-5,-5,120,116

EndOfImage:
; End of emitted startup segment.
