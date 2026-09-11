; ============================================================================
; ZALAGA - WEB-ASSEMBLER BOOTABLE RECONSTRUCTION V14
; BBC Micro / NMOS 6502
;
; BBC 6502 Web Assembler boot-disk / jsbeeb setup
; -----------------------------------------------
; jsbeeb host keyboard remapping used by the assembler's Run in jsbeeb command.
; These are source metadata comments only and do not alter the assembled binary.
; @jsbeeb-key Z=CAPSLOCK
; @jsbeeb-key X=CTRL
;
; Zalaga occupies RAM used by DFS.  The generated BASIC loader must release DFS
; before its high-memory mover installs the image at &0400.
; @basic *TAPE
;
; The game does not require BASIC ENVELOPE definitions.  Its own startup calls
; setup_sound_envelopes at &1487, which installs the four game envelopes through
; OSWORD 8; the sound sequencer subsequently uses OSWORD 7.  All loader state
; required by the game is established by bootstrap_entry below.
;
; ============================================================================
;
; Self-contained source for BBC 6502 Web Assembler v1.4+.
;
; The permanent game engine/data at &0D01-&2FFF has been independently assembled
; and verified byte-for-byte against the running game.
;
; Original author labels are lost. Descriptive labels/comments are reconstructed.
; Undocumented NMOS 6502 instructions used by the original are retained.
;
; This file contains the required transient low-memory startup/data, the byte-exact
; permanent engine/data at &0D01-&2FFF, and a small bootstrap at &3000.
; The old BASIC briefing/copy-protection loader is not required.
;
; V14 correction: restores the protected loader's two distinct formation-table
; copies: species-by-group -> &0693 and X coordinates -> &069D.  V13 inherited
; an old reconstruction error that copied the species table over &069D and
; therefore destroyed the ten formation X coordinates.
; ============================================================================

; ============================================================================
; SYMBOL DEFINITIONS
; ============================================================================

; ZALAGA reconstructed symbol set - V10
; Descriptive names derived from static analysis + supplied jsbeeb snapshots.
; Original source labels are not known.

; MOS
OSBYTE = &FFF4
OSWORD = &FFF1

; Zero-page / low-memory state
work_x                         = &00
work_y                         = &01
screen_lo                      = &02
screen_hi                      = &03
sprite_src_lo                  = &04
sprite_src_hi                  = &05
sprite_width                   = &06
sprite_height                  = &07
indirect_lo                    = &08
indirect_hi                    = &09
erase_screen_lo                = &0C
erase_screen_hi                = &0D
move_vector_lo                 = &0E
move_vector_hi                 = &0F
fire_vector_lo                 = &10
fire_vector_hi                 = &11
stage_handler_lo               = &12
stage_handler_hi               = &13
input_temp                     = &14
temp15                         = &15
player_x                       = &16
player_screen_lo               = &17
player_screen_hi               = &18
fighter_configuration          = &19
palette_delay                  = &1D
palette_phase                  = &1E
player0_score_lo               = &1F
player1_score_lo               = &20
player0_score_mid              = &21
player1_score_mid              = &22
player0_score_hi               = &23
player1_score_hi               = &24
player0_stage_hi               = &25
player1_stage_hi               = &26
stage_phase_flag               = &30
fire_latch                     = &31
current_player                 = &32
player_dead                    = &33
player0_fighters               = &35
player1_fighters               = &36
player0_stage_lo               = &37
player1_stage_lo               = &38
player0_aliens_left            = &39
player1_aliens_left            = &3A
sound_option                   = &3B
two_player_option              = &3C
bcd_work0                      = &3D
bcd_work1                      = &3E
bcd_work2                      = &3F
music_ctr0                     = &40
music_ctr1                     = &41
music_ctr2                     = &42
music_ctr3                     = &43
xor_mask                       = &44
temp45                         = &45
temp46                         = &46
temp47                         = &47
mask_7_constant                = &49
turn_delay                     = &4D
formation_scan_slot            = &4E
formation_phase_mask           = &4F
formation_direction            = &50
formation_sweep_countdown      = &51
game_tick                      = &52
event_tick                     = &53
active_attacker_count          = &54
moving_object_scan_slot        = &55
moving_object_count            = &58
moving_object_scan_start       = &59
message_ptr_lo                 = &5D
message_ptr_hi                 = &5E
collision_result               = &60
collision_left                 = &61
collision_right                = &62
collision_top                  = &63
collision_bottom               = &64
entry_delay                    = &65
path_ptr_lo                    = &66
path_ptr_hi                    = &67
entry_spacing                  = &68
menu_key_debounce              = &69
music_base_lo                  = &6A
music_base_hi                  = &6B
music_offset_base              = &6C
music_offset0                  = &6D
music_offset1                  = &6E
music_offset2                  = &6F
input_mode                     = &70
lives_display_cache            = &71
collision_special              = &72
path_mirror                    = &73
player0_entry_selector         = &74
player1_entry_selector         = &75
math_temp76                    = &76
challenge_stage                = &77
challenge_alien_type           = &78
sound_gate                     = &79
challenge_hits_bcd             = &7A
collision_scan_end             = &7C
queen_escorts_left             = &7D
queen_table_index              = &7E
queen_candidates_left          = &7F
math_temp80                    = &80
text_screen_lo                 = &81
text_screen_hi                 = &82
text_colour_mask               = &83
font_ptr_lo                    = &84
font_ptr_hi                    = &85
font_bit_mask                  = &86
font_pixel_mask                = &87
font_row_pair                  = &88
font_screen_offset             = &89
enemy_shot_slot_limit          = &8A
cycle_opening_stage            = &8B
mos_tick_source_flag           = &8C
music_duration_shift           = &8D
attack_period                  = &BA
attack_slot_limit              = &BB
beam_phase                     = &BC
beam_curve_step                = &BD
beam_curve_radius              = &BE
beam_curve_accum               = &BF
beam_origin_y                  = &C0
beam_centre_x                  = &C1
beam_curve_limit               = &C2
beam_active                    = &C3
beam_closing                   = &C4
beam_owner_slot                = &C5
beam_capture_left              = &C6
beam_capture_right             = &C7
music_last_tick                = &C8

; Runtime arrays/data
object_x                       = &0400
object_y                       = &0449
object_sprite                  = &0492
object_draw_hi                 = &04DB
object_draw_lo                 = &0524
object_last_tick               = &0545
object_state                   = &0566
object_type_flags              = &05AF
object_aux_lo                  = &05C6
object_aux_hi                  = &05DD
object_repeat                  = &05F4
object_home_slot               = &0601
object_next_tick               = &060E
formation_x_index              = &0643
formation_y_index              = &066B
formation_type_by_group        = &0693
formation_x_positions          = &069D
formation_y_positions          = &06A7
formation_motion_masks         = &06AC
movement_dx                    = &0716
movement_dy                    = &072F
movement_anim                  = &0748
high_score_names               = &0900
high_score_low                 = &09FA
message_queue                  = &0A04
star_address_lo                = &0A0E
star_address_hi                = &0A40
star_xor_colour                = &0A72
high_score_mid                 = &0CEC
high_score_hi                  = &0CF6
blitter_table_lo               = &11B2
blitter_table_hi               = &11C2
effect_sprite_sequence         = &143C
enemy_projectile_xor_data      = &1680
enemy_projectile_xor_data_alt  = &168A
input_vector_table             = &1903
queen_drome_escort_table       = &1ACD
stage_handler_table            = &1ADC
object_state_to_handler_offset = &1DE2
object_handler_pointer_table   = &1E03
message_pointer_table          = &20CE
entry_descriptor_table         = &2125
stage_entry_selector_table     = &2187
alien_sprite_base_table        = &2192
alien_score_metadata           = &2193
music_selector_table           = &24A0
beam_colour_masks              = &2732
logical_sprite_descriptors     = &2752
sprite_metadata                = &277B
msg_ready                      = &2F45

; Routines
coord_to_mode2_address         = &0D01
set_text_position              = &0D62
draw_custom_char               = &0D79
blitter_next_mode2_column      = &0DF1
wait_for_tick                  = &0E09
read_game_tick                 = &0E11
poll_sound_toggle              = &0E1E
osbyte_test_key                = &0E2E
poll_control_toggle            = &0E4B
poll_player_count_toggle       = &0E59
event_tick_handler             = &0E67
animate_palette                = &0E6A
random_timer_byte              = &0E97
draw_sprite_xy                 = &0EAF
setup_and_draw_sprite          = &0EBE
draw_object                    = &0EC9
erase_object                   = &0ECC
dispatch_sprite_blitter        = &0F11
call_sprite_blitter            = &0F91
update_formation_motion        = &11D2
update_one_formation_slot      = &11D5
update_starfield               = &1252
choose_random_star_address     = &12B9
add_score_low_only             = &12DA
add_score_bcd                  = &12DC
xor_player_ship                = &12F5
xor_one_fighter                = &130D
load_player_screen_pointer     = &1321
advance_secondary_fighter_pointer = &132A
advance_primary_screen_pointer = &1335
top_level_loop                 = &1341
game_session                   = &134A
erase_enemy_projectile_slot    = &13F1
clear_playfield_objects        = &1405
update_effect_slots            = &144B
clear_object_draw_state        = &147C
setup_sound_envelopes          = &1487
flush_keyboard_buffer          = &149B
update_player                  = &14A3
explode_player_half            = &155D
test_player_half_collision     = &157D
screen_collision_probe_8bytes  = &159D
screen_collision_probe         = &15A2
update_enemy_projectiles       = &15BF
offset_projectile_draw_address = &162E
xor_enemy_projectile           = &163D
service_player_fire            = &1697
update_player_shots            = &16E1
xor_player_shot                = &1717
test_player_shot_collision     = &1736
queue_player_name_message      = &1773
queue_player_score_label       = &177F
scan_player_collision_objects  = &1785
scan_shot_collision_objects    = &178B
allocate_explosion             = &1898
score_alien_hit                = &18CE
award_extra_fighter_on_score_carry = &18D1
read_horizontal_input          = &18E1
read_fire_input                = &18E4
install_input_vectors          = &18E7
joystick_horizontal_1          = &190F
joystick_horizontal_3          = &1912
joystick_fire_2                = &192D
joystick_fire_1                = &1930
keyboard_horizontal            = &1947
keyboard_fire                  = &1958
try_queen_group_attack         = &195D
try_launch_attack              = &19E3
transfer_formation_to_attack_slot = &1A4E
install_attack_path            = &1A91
find_free_attack_slot          = &1AB9
set_queen_normal_attack_state  = &1AC7
dispatch_stage_state           = &1AD9
stage_intro                    = &1AE7
stage_setup                    = &1B06
formation_init                 = &1B85
set_stage_handler              = &1BC6
active_stage                   = &1BD1
divide_current_stage           = &1C2E
bcd_divide                     = &1C3C
deployment_controller          = &1C70
decode_alien_type              = &1D96
service_moving_objects         = &1DA5
dispatch_object_state          = &1DC7
advance_object_state           = &1E21
wait_object_tick               = &1E2A
follow_trajectory              = &1E39
advance_state_and_redispatch   = &1EAC
prepare_return                 = &1EB2
prepare_short_rejoin           = &1ECA
advance_state_and_draw         = &1EDF
select_path_0165               = &1EE5
select_path_01A2               = &1EEB
select_path_01AA               = &1EEE
select_path_014E               = &1EF1
select_path_0362               = &1EF4
linear_leg_start               = &1EFC
linear_leg_continue            = &1F02
interpolate_home               = &1F30
cleanup_transient_object       = &1FA8
proportional_step              = &1FB5
absolute_for_step              = &1FCF
load_current_path_byte         = &1FDA
service_enemy_fire             = &1FE9
display_pending_messages       = &207B
queue_message                  = &2093
draw_message                   = &20A2
decode_entry_descriptor        = &20FE
set_player_entry_selector      = &211C
attract_title                  = &219C
menu_input                     = &21B2
service_menu_toggles           = &21DF
common_frame_service           = &21EF
gameplay_frame_service         = &2201
draw_all_scores                = &2210
draw_current_player_score      = &221B
draw_one_player_score          = &221D
draw_high_score                = &2246
draw_score_separator           = &225E
draw_attract_screen            = &2272
draw_high_score_table          = &2292
high_score_row_position        = &22F1
print_score                    = &22FE
print_score_alt_nibble_order   = &2302
prepare_challenge_hits_display = &2348
prepare_challenge_bonus_display = &235C
prepare_stage_display          = &2383
patch_bcd_digits_into_message  = &239A
patch_bcd_value_into_glyphs    = &23A2
get_bcd_nibble                 = &23D1
sound_osword7                  = &23E0
envelope_osword8               = &23E9
decode_music_note              = &23FE
start_music                    = &2432
service_music                  = &2461
finish_music_delay             = &2496
stop_music_and_restore_sound   = &249A
refresh_lives_display          = &24A6
xor_lives_icons                = &24B1
insert_high_score              = &24CC
erase_name_character           = &25C9
move_text_cursor_left          = &25D4
high_score_name_entry          = &25EF
xor_name_cursor_block          = &2611
decode_sprite_descriptor       = &2623
draw_beam_layer                = &266B
service_beam_state             = &26C7
step_beam_lifecycle            = &26D3
force_finish_beam              = &26FC
select_special_queen_attack    = &2702
init_tractor_beam              = &270F
plot_beam_pixel                = &2736

; Constants
FIGHTER_SINGLE                 = &00
FIGHTER_DUAL                   = &FF
FORMATION_FIRST                = &00
FORMATION_LAST                 = &27
ATTACK_FIRST                   = &28
ATTACK_LAST                    = &34
ENEMY_SHOT_FIRST               = &35
ENEMY_SHOT_LAST                = &3E
EFFECT_FIRST                   = &3F
EFFECT_LAST                    = &48
ALIEN_GUARD                    = &00
ALIEN_DROME                    = &02
ALIEN_QUEEN                    = &04
ALIEN_QUEEN_DAMAGED            = &06
ALIEN_PROJECTILE               = &08
ALIEN_FLAG_BRIDGE              = &40
ALIEN_FLAG_MIRROR              = &80
STATE_ATTACK_OPENING           = &0C
STATE_ATTACK_STRAIGHT_START    = &0D
STATE_ATTACK_STRAIGHT          = &0E
STATE_ATTACK_SELECT_CURVE2     = &0F
STATE_ATTACK_CURVE2            = &10
STATE_ATTACK_PREP_RETURN       = &11
STATE_ATTACK_REJOIN            = &12
STATE_QUEEN_NORMAL_OPENING     = &13
STATE_QUEEN_SPECIAL_OPENING    = &18
STATE_BEAM_APPROACH_SELECT     = &19
STATE_BEAM_APPROACH            = &1A
STATE_BEAM_INIT                = &1B
STATE_BEAM_ACTIVE              = &1C
STATE_BEAM_DEPART_SELECT       = &1D
STATE_BEAM_DEPART              = &1E
STATE_BEAM_PREP_RETURN         = &1F
STATE_BEAM_REJOIN              = &20

; V10 player-shot records and permanent data-tail labels
player_shot_screen_lo          = &B0
player_shot_screen_hi          = &B2
player_shot_active_config      = &B4
player_shot_x                  = &B6
player_shot_y                  = &B8

logical_sprite_descriptors     = &2752
sprite_metadata_records        = &277B
sprite_bitmap_data             = &27D5
sound_envelope_data            = &2E5E
fixed_sound_data               = &2EB2
message_data_start             = &2EE2

; ============================================================================
; PERMANENT GAME ENGINE AND DATA
; Runtime address range: &0D01-&2FFF
; ============================================================================

; ============================================================================
; TRANSIENT STARTUP / LOW-MEMORY RUNTIME TEMPLATE
; Runtime range &0400-&0D00.  These bytes are from the independently
; reconstructed and snapshot-validated pre-startup image.  &0400 begins
; as startup code and is subsequently reused by the object arrays.
; ============================================================================

ORG &0400
runtime_start:
    EQUB &A9, &16, &20, &EE, &FF, &A9, &02, &20, &EE, &FF, &A9, &0A, &8D, &00, &FE, &A9    ; &0400
    EQUB &20, &8D, &01, &FE, &A2, &00, &20, &97, &0E, &CA, &D0, &FA, &20, &CD, &04, &A9    ; &0410
    EQUB &03, &85, &83, &A2, &00, &A0, &7E, &20, &62, &0D, &A9, &31, &20, &79, &0D, &20    ; &0420
    EQUB &C3, &04, &A2, &1D, &A0, &7E, &20, &62, &0D, &A9, &48, &20, &79, &0D, &A9, &69    ; &0430
    EQUB &20, &79, &0D, &A2, &36, &A0, &7E, &20, &62, &0D, &A9, &32, &20, &79, &0D, &20    ; &0440
    EQUB &C3, &04, &A0, &1C, &20, &A2, &20, &A0, &20, &20, &A2, &20, &A2, &01, &A9, &00    ; &0450
    EQUB &95, &B4, &CA, &10, &F9, &A2, &09, &A9, &FF, &9D, &04, &0A, &CA, &10, &F8, &A2    ; &0460
    EQUB &05, &A9, &00, &95, &1F, &CA, &10, &F9, &20, &10, &22, &A0, &60, &B9, &10, &05    ; &0470
    EQUB &99, &1F, &03, &88, &D0, &F7, &24, &8C, &30, &12, &A0, &20, &B9, &90, &05, &99    ; &0480
    EQUB &7F, &03, &88, &D0, &F7, &A9, &80, &8D, &51, &21, &30, &0B, &A0, &20, &B9, &90    ; &0490
    EQUB &05, &99, &FF, &02, &88, &D0, &F7, &A9, &00, &8D, &01, &01, &8D, &03, &01, &8D    ; &04A0
    EQUB &05, &01, &8D, &07, &01, &A9, &01, &8D, &02, &01, &A9, &14, &8D, &06, &01, &58    ; &04B0
    EQUB &4C, &41, &13, &A9, &55, &20, &79, &0D, &A9, &50, &4C, &79, &0D, &A9, &01, &85    ; &04C0
    EQUB &02, &A9, &30, &85, &03, &A0, &00, &A2, &31, &A5, &02, &9D, &0E, &0A, &29, &2A    ; &04D0
    EQUB &9D, &72, &0A, &51, &02, &91, &02, &A5, &03, &9D, &40, &0A, &18, &A5, &02, &69    ; &04E0
    EQUB &19, &85, &02, &A5, &03, &69, &01, &85, &03, &20, &97, &0E, &18, &65, &02, &85    ; &04F0
    EQUB &02, &90, &0A, &E6, &03, &10, &06, &A5, &03, &E9, &50, &85, &03, &CA, &10, &C9    ; &0500
    EQUB &60, &00, &19, &26, &E5, &24, &02, &20, &36, &33, &12, &10, &0D, &2C, &0B, &09    ; &0510
    EQUB &06, &05, &24, &63, &FF, &00, &19, &26, &E5, &25, &03, &21, &40, &37, &15, &32    ; &0520
    EQUB &10, &2E, &6C, &2B, &08, &06, &45, &23, &FF, &00, &20, &26, &E5, &25, &01, &18    ; &0530
    EQUB &02, &00, &18, &36, &18, &12, &18, &12, &0D, &18, &0C, &0B, &18, &07, &18, &26    ; &0540
    EQUB &24, &FF, &28, &28, &16, &19, &02, &05, &06, &08, &2C, &10, &12, &36, &17, &13    ; &0550
    EQUB &12, &11, &0D, &0C, &2A, &08, &07, &09, &0C, &2E, &EC, &4C, &FF, &23, &7E, &AC    ; &0560
    EQUB &EB, &0B, &EC, &EC, &2C, &2D, &31, &33, &37, &20, &21, &04, &05, &E6, &E6, &86    ; &0570
    EQUB &FF, &00, &46, &E6, &47, &A8, &29, &2B, &CC, &C0, &21, &23, &84, &25, &E6, &FF    ; &0580
    EQUB &00, &00, &14, &E3, &E3, &E3, &EC, &ED, &6D, &38, &E3, &E3, &A3, &FF, &04, &05    ; &0590
    EQUB &04, &05, &04, &05, &04, &05, &03, &06, &03, &06, &04, &05, &03, &06, &02, &01    ; &05A0
    EQUB &02, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &05B0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &05C0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &05D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &05E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &05F0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0600
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0610
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0620
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0630
    EQUB &00, &00, &00, &04, &05, &04, &05, &04, &05, &04, &05, &03, &06, &03, &06, &04    ; &0640
    EQUB &05, &03, &06, &02, &01, &02, &01, &07, &08, &07, &08, &03, &02, &03, &02, &06    ; &0650
    EQUB &07, &06, &07, &01, &00, &01, &00, &08, &09, &08, &09, &01, &01, &00, &00, &03    ; &0660
    EQUB &03, &02, &02, &03, &03, &02, &02, &04, &04, &04, &04, &03, &03, &02, &02, &03    ; &0670
    EQUB &03, &02, &02, &01, &01, &00, &00, &01, &01, &00, &00, &01, &01, &00, &00, &01    ; &0680
    EQUB &01, &00, &00, &00, &02, &02, &04, &02, &02, &00, &00, &00, &00, &06, &0D, &14    ; &0690 ; &0693 species table, &069D X positions begin
    EQUB &1B, &22, &29, &30, &37, &3E, &45, &4A, &53, &5C, &65, &6E, &FF, &77, &55, &22    ; &06A0 ; X positions continue through &06A6, then Y positions
    EQUB &00, &00, &22, &55, &77, &FF, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &06B0
    EQUB &00, &00, &00, &2A, &2A, &0A, &15, &15, &15, &05, &3F, &3F, &3F, &3F, &00, &00    ; &06C0
    EQUB &00, &00, &2A, &2A, &2A, &2A, &00, &00, &00, &00, &00, &2A, &2A, &0A, &00, &00    ; &06D0
    EQUB &00, &00, &00, &00, &00, &00, &2A, &2A, &0A, &17, &35, &3F, &3F, &3A, &17, &35    ; &06E0
    EQUB &3F, &3F, &3B, &3B, &31, &11, &3F, &3B, &27, &27, &0F, &0F, &33, &22, &3F, &3F    ; &06F0
    EQUB &37, &37, &1B, &1B, &33, &33, &02, &20, &2A, &3F, &3F, &3F, &35, &10, &2A, &2A    ; &0700
    EQUB &0A, &02, &20, &2A, &2A, &2A, &00, &01, &01, &02, &02, &02, &02, &02, &02, &02    ; &0710
    EQUB &01, &01, &00, &FF, &FF, &FE, &FE, &FE, &FE, &FE, &FE, &FE, &FF, &FF, &00, &03    ; &0720
    EQUB &03, &02, &03, &02, &01, &00, &FF, &FE, &FD, &FE, &FD, &FD, &FD, &FE, &FD, &FE    ; &0730
    EQUB &FF, &00, &01, &02, &03, &02, &03, &00, &00, &01, &01, &01, &02, &02, &03, &04    ; &0740
    EQUB &05, &05, &05, &05, &06, &07, &07, &07, &08, &08, &09, &0A, &0B, &0B, &0B, &0B    ; &0750
    EQUB &03, &11, &11, &11, &11, &11, &11, &30, &10, &00, &00, &00, &00, &00, &00, &20    ; &0760
    EQUB &00, &23, &7E, &AC, &EB, &0B, &EC, &EC, &2C, &2D, &31, &33, &37, &20, &21, &04    ; &0770
    EQUB &05, &E6, &E6, &86, &FF, &00, &46, &E6, &47, &A8, &29, &2B, &CC, &C0, &21, &23    ; &0780
    EQUB &84, &25, &E6, &FF, &00, &32, &E1, &26, &EB, &EA, &CA, &46, &42, &A0, &56, &52    ; &0790
    EQUB &4E, &AC, &4A, &E6, &E6, &C6, &FF, &1E, &7E, &EC, &EC, &EC, &EC, &0C, &2A, &07    ; &07A0
    EQUB &26, &05, &E3, &E3, &43, &FF, &00, &46, &E6, &E6, &E6, &06, &90, &B1, &47, &49    ; &07B0
    EQUB &EC, &78, &E6, &E6, &66, &FF, &1E, &7E, &4C, &98, &A6, &98, &AC, &98, &A6, &98    ; &07C0
    EQUB &AC, &98, &E6, &98, &EC, &EC, &0C, &98, &66, &FF, &00, &6E, &E6, &E6, &E6, &E6    ; &07D0
    EQUB &46, &EF, &EF, &EF, &CF, &E6, &E6, &E6, &E6, &46, &FF, &1E, &64, &00, &16, &12    ; &07E0
    EQUB &0E, &0D, &0C, &FF, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &07F0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0800
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0810
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0820
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0830
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0840
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0850
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0860
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0870
    EQUB &03, &13, &23, &4E, &42, &46, &3A, &3A, &3E, &42, &3E, &3A, &3A, &3A, &4A, &4D    ; &0880
    EQUB &4B, &4E, &FF, &5E, &52, &56, &4A, &4E, &4E, &4E, &4E, &4E, &5E, &4A, &62, &5D    ; &0890
    EQUB &5B, &5E, &FF, &69, &70, &69, &5C, &61, &68, &61, &54, &5D, &60, &5D, &54, &4E    ; &08A0
    EQUB &56, &5C, &60, &64, &6A, &69, &6C, &71, &78, &7D, &67, &6A, &FF, &00, &00, &00    ; &08B0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &08C0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &08D0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &08E0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &08F0
    EQUB &20, &20, &20, &20, &2A, &2A, &2A, &20, &4F, &72, &6C, &61, &6E, &64, &6F, &20    ; &0900
    EQUB &2A, &2A, &2A, &0D, &2A, &0D, &6D, &6F, &0D, &0D, &44, &52, &0D, &0D, &0D, &0D    ; &0910
    EQUB &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D    ; &0920
    EQUB &0D, &0D, &0D, &65, &61, &6E, &2D, &50, &61, &75, &6C, &0D, &0D, &0D, &0D, &0D    ; &0930
    EQUB &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D, &20, &20, &20, &4D, &61    ; &0940
    EQUB &6E, &79, &20, &74, &68, &61, &6E, &6B, &73, &20, &74, &6F, &20, &2E, &2E, &2E    ; &0950
    EQUB &0D, &2E, &0D, &0D, &0D, &68, &65, &61, &70, &20, &50, &61, &63, &28, &6B, &69    ; &0960
    EQUB &6E, &29, &20, &52, &69, &70, &2D, &6F, &66, &66, &0D, &0D, &0D, &20, &20, &4E    ; &0970
    EQUB &4A, &4D, &50, &2C, &20, &43, &41, &50, &2C, &20, &44, &43, &45, &2C, &20, &4C    ; &0980
    EQUB &50, &4D, &2C, &0D, &2C, &0D, &4A, &44, &2C, &20, &4B, &48, &2C, &20, &50, &43    ; &0990
    EQUB &2C, &20, &53, &4B, &2C, &20, &53, &4A, &2C, &20, &41, &44, &2C, &0D, &0D, &49    ; &09A0
    EQUB &41, &54, &2C, &20, &52, &41, &4C, &2C, &20, &30, &2E, &56, &30, &4C, &4C, &28    ; &09B0
    EQUB &4E, &30, &52, &53, &4B, &45, &29, &0D, &0D, &50, &42, &2C, &20, &50, &48, &2C    ; &09C0
    EQUB &20, &44, &4A, &44, &2C, &20, &52, &4A, &4D, &2C, &20, &52, &41, &46, &2C, &0D    ; &09D0
    EQUB &0D, &2E, &2E, &2E, &2B, &20, &61, &6C, &6C, &20, &61, &74, &20, &41, &63, &72    ; &09E0
    EQUB &6F, &6E, &73, &66, &6F, &74, &0D, &45, &29, &0D, &00, &00, &00, &00, &00, &00    ; &09F0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A00
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A10
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A20
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A30
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A40
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A50
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A60
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A70
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A80
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0A90
    EQUB &00, &00, &00, &00, &03, &1B, &37, &58, &60, &65, &6C, &64, &61, &58, &60, &65    ; &0AA0
    EQUB &6C, &64, &60, &58, &64, &6C, &75, &6C, &64, &6C, &64, &50, &65, &5B, &FF, &34    ; &0AB0
    EQUB &3C, &44, &50, &64, &44, &3C, &50, &64, &3C, &34, &44, &58, &64, &58, &44, &34    ; &0AC0
    EQUB &3C, &44, &50, &64, &44, &3C, &50, &30, &29, &36, &FF, &28, &30, &34, &44, &50    ; &0AD0
    EQUB &34, &30, &44, &50, &34, &28, &34, &44, &58, &44, &34, &28, &30, &34, &44, &50    ; &0AE0
    EQUB &34, &20, &30, &50, &19, &2B, &FF, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0AF0
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0B00
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &FA, &00, &00, &E0, &00, &E0, &00    ; &0B10
    EQUB &28, &FE, &28, &FE, &28, &48, &54, &FE, &54, &24, &46, &26, &10, &C8, &C4, &0A    ; &0B20
    EQUB &64, &9A, &92, &6C, &00, &80, &40, &20, &00, &00, &82, &44, &38, &00, &00, &38    ; &0B30
    EQUB &44, &82, &00, &28, &38, &7C, &38, &28, &10, &10, &7C, &10, &10, &00, &06, &07    ; &0B40
    EQUB &01, &00, &10, &10, &10, &10, &10, &00, &00, &06, &06, &00, &40, &20, &10, &08    ; &0B50
    EQUB &04, &7C, &A2, &92, &8A, &7C, &00, &02, &FE, &42, &00, &42, &A2, &92, &8A, &46    ; &0B60
    EQUB &6C, &92, &92, &82, &44, &10, &FE, &90, &50, &30, &9C, &A2, &A2, &A2, &E4, &4C    ; &0B70
    EQUB &92, &92, &92, &7C, &C0, &A0, &90, &8E, &80, &6C, &92, &92, &92, &6C, &7C, &92    ; &0B80
    EQUB &92, &92, &64, &00, &66, &66, &00, &00, &00, &66, &67, &01, &00, &00, &82, &44    ; &0B90
    EQUB &28, &10, &28, &28, &28, &28, &28, &00, &10, &28, &44, &82, &40, &A0, &9A, &80    ; &0BA0
    EQUB &40, &78, &AA, &BA, &82, &7C, &7E, &90, &90, &90, &7E, &6C, &92, &92, &92, &FE    ; &0BB0
    EQUB &44, &82, &82, &82, &7C, &38, &44, &82, &82, &FE, &82, &92, &92, &92, &FE, &80    ; &0BC0
    EQUB &90, &90, &90, &FE, &5C, &92, &82, &82, &7C, &FE, &10, &10, &10, &FE, &82, &82    ; &0BD0
    EQUB &FE, &82, &82, &80, &FC, &82, &82, &04, &82, &44, &28, &10, &FE, &02, &02, &02    ; &0BE0
    EQUB &02, &FE, &FE, &40, &30, &40, &FE, &FE, &0C, &38, &60, &FE, &7C, &82, &82, &82    ; &0BF0
    EQUB &7C, &60, &90, &90, &90, &FE, &7A, &84, &8A, &82, &7C, &66, &98, &90, &90, &FE    ; &0C00
    EQUB &4C, &92, &92, &92, &64, &80, &80, &FE, &80, &80, &FC, &02, &02, &02, &FC, &F0    ; &0C10
    EQUB &0C, &02, &0C, &F0, &FE, &04, &18, &04, &FE, &C6, &28, &10, &28, &C6, &E0, &10    ; &0C20
    EQUB &0E, &10, &E0, &C2, &A2, &92, &8A, &86, &00, &82, &82, &82, &FE, &04, &08, &10    ; &0C30
    EQUB &20, &40, &FE, &82, &82, &82, &00, &20, &40, &FE, &40, &20, &01, &01, &01, &01    ; &0C40
    EQUB &01, &42, &92, &92, &7E, &12, &1E, &2A, &2A, &2A, &04, &1C, &22, &22, &22, &FE    ; &0C50
    EQUB &14, &22, &22, &22, &1C, &FE, &22, &22, &22, &1C, &18, &2A, &2A, &2A, &1C, &80    ; &0C60
    EQUB &90, &7E, &10, &00, &1E, &25, &25, &25, &19, &1E, &20, &20, &20, &FE, &00, &02    ; &0C70
    EQUB &BE, &22, &00, &00, &00, &BE, &21, &01, &00, &22, &14, &08, &FE, &00, &02, &FE    ; &0C80
    EQUB &82, &00, &1E, &30, &18, &30, &1E, &1E, &20, &20, &10, &3E, &1C, &22, &22, &22    ; &0C90
    EQUB &1C, &18, &24, &24, &24, &3F, &1F, &24, &24, &24, &18, &20, &20, &10, &3E, &20    ; &0CA0
    EQUB &24, &2A, &2A, &2A, &12, &00, &22, &22, &FC, &20, &3E, &02, &02, &02, &3C, &38    ; &0CB0
    EQUB &04, &02, &04, &38, &3C, &06, &0C, &06, &3C, &22, &14, &08, &14, &22, &3E, &05    ; &0CC0
    EQUB &05, &05, &39, &22, &32, &2A, &26, &22, &00, &00, &82, &6C, &10, &00, &00, &EE    ; &0CD0
    EQUB &00, &00, &00, &10, &6C, &82, &00, &40, &20, &40, &80, &40, &01, &01, &01, &01    ; &0CE0
    EQUB &01, &01, &01, &01, &01, &01, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00    ; &0CF0
    EQUB &00    ; &0D00

ORG &0D01

; ----------------------------------------------------------------------------
; FLATTENED MODULE: 01_graphics_timing_starfield.asm
; ----------------------------------------------------------------------------
; ZALAGA V10 - Graphics, timing, sprite blitters, formation wobble, starfield and score arithmetic
; Sequential module included by ../zalaga.asm.

coord_to_mode2_address:
    LDA #&00                               ; @0D01 A9 00
    STA screen_hi                          ; @0D03 85 03
    LDA #&7F                               ; @0D05 A9 7F
    SEC                                    ; @0D07 38
    SBC work_y                             ; @0D08 E5 01
    ASL A                                  ; @0D0A 0A
    ORA #&01                               ; @0D0B 09 01
    TAX                                    ; @0D0D AA
    AND #&07                               ; @0D0E 29 07
    STA temp15                             ; @0D10 85 15
    TXA                                    ; @0D12 8A
    AND #&F8                               ; @0D13 29 F8
    STA screen_lo                          ; @0D15 85 02
    ASL A                                  ; @0D17 0A
    ROL screen_hi                          ; @0D18 26 03
    ASL A                                  ; @0D1A 0A
    ROL screen_hi                          ; @0D1B 26 03
    ADC screen_lo                          ; @0D1D 65 02
    BCC loc_0D23                           ; @0D1F 90 02
    INC screen_hi                          ; @0D21 E6 03

; ---------------------------------------------------------------------------
loc_0D23:
    ASL A                                  ; @0D23 0A
    ROL screen_hi                          ; @0D24 26 03
    ADC work_x                             ; @0D26 65 00
    BCC loc_0D2C                           ; @0D28 90 02
    INC screen_hi                          ; @0D2A E6 03

; ---------------------------------------------------------------------------
loc_0D2C:
    ASL A                                  ; @0D2C 0A
    ROL screen_hi                          ; @0D2D 26 03
    ASL A                                  ; @0D2F 0A
    ROL screen_hi                          ; @0D30 26 03
    ASL A                                  ; @0D32 0A
    ROL screen_hi                          ; @0D33 26 03
    ORA temp15                             ; @0D35 05 15
    ADC #&00                               ; @0D37 69 00
    TAX                                    ; @0D39 AA
    LDA screen_hi                          ; @0D3A A5 03
    ADC #&30                               ; @0D3C 69 30
    TAY                                    ; @0D3E A8
    TXA                                    ; @0D3F 8A
    SEC                                    ; @0D40 38
    SBC sprite_height                      ; @0D41 E5 07
    BCS loc_0D46                           ; @0D43 B0 01
    DEY                                    ; @0D45 88

; ---------------------------------------------------------------------------
loc_0D46:
    TAX                                    ; @0D46 AA
    BIT work_x                             ; @0D47 24 00
    BPL loc_0D50                           ; @0D49 10 05
    TYA                                    ; @0D4B 98
    SEC                                    ; @0D4C 38
    SBC #&08                               ; @0D4D E9 08
    TAY                                    ; @0D4F A8

; ---------------------------------------------------------------------------
loc_0D50:
    BIT work_y                             ; @0D50 24 01
    BPL loc_0D59                           ; @0D52 10 05
    TYA                                    ; @0D54 98
    CLC                                    ; @0D55 18
    ADC #&50                               ; @0D56 69 50
    TAY                                    ; @0D58 A8

; ---------------------------------------------------------------------------
loc_0D59:
    STX erase_screen_lo                    ; @0D59 86 0C
    STY erase_screen_hi                    ; @0D5B 84 0D
    STX screen_lo                          ; @0D5D 86 02
    STY screen_hi                          ; @0D5F 84 03
    RTS                                    ; @0D61 60

; ---------------------------------------------------------------------------
set_text_position:
    STX work_x                             ; @0D62 86 00
    TYA                                    ; @0D64 98
    AND #&FC                               ; @0D65 29 FC
    STA work_y                             ; @0D67 85 01
    LDA #&07                               ; @0D69 A9 07
    STA sprite_height                      ; @0D6B 85 07
    JSR coord_to_mode2_address             ; @0D6D 20 01 0D
    LDA screen_lo                          ; @0D70 A5 02
    STA text_screen_lo                     ; @0D72 85 81
    LDA screen_hi                          ; @0D74 A5 03
    STA text_screen_hi                     ; @0D76 85 82
    RTS                                    ; @0D78 60

; ---------------------------------------------------------------------------
; Render one custom 5-column glyph directly into MODE 2 using XOR colour mask.
draw_custom_char:
    PHA                                    ; @0D79 48
    SEC                                    ; @0D7A 38
    SBC #&20                               ; @0D7B E9 20
    STA font_ptr_lo                        ; @0D7D 85 84
    TXA                                    ; @0D7F 8A
    PHA                                    ; @0D80 48
    TYA                                    ; @0D81 98
    PHA                                    ; @0D82 48
    LDX #&00                               ; @0D83 A2 00
    TXA                                    ; @0D85 8A
    LDY #&05                               ; @0D86 A0 05
    CLC                                    ; @0D88 18
    ADC font_ptr_lo                        ; @0D89 65 84
    BCC loc_0D8E                           ; @0D8B 90 01
    INX                                    ; @0D8D E8

; ---------------------------------------------------------------------------
loc_0D8E:
    DEY                                    ; @0D8E 88
    BNE &0D88                              ; @0D8F D0 F7
    CLC                                    ; @0D91 18
    ADC #&11                               ; @0D92 69 11
    STA font_ptr_lo                        ; @0D94 85 84
    TXA                                    ; @0D96 8A
    ADC #&0B                               ; @0D97 69 0B
    STA font_ptr_hi                        ; @0D99 85 85
    LDA #&04                               ; @0D9B A9 04
    STA font_row_pair                      ; @0D9D 85 88
    LDY #&00                               ; @0D9F A0 00
    STY font_screen_offset                 ; @0DA1 84 89
    LDA &0DE9,Y                            ; @0DA3 B9 E9 0D
    STA font_bit_mask                      ; @0DA6 85 86
    LDX #&00                               ; @0DA8 A2 00
    LDA #&AA                               ; @0DAA A9 AA
    LDY font_row_pair                      ; @0DAC A4 88
    STA font_pixel_mask                    ; @0DAE 85 87
    LDA (font_ptr_lo),Y                    ; @0DB0 B1 84
    AND font_bit_mask                      ; @0DB2 25 86
    BEQ loc_0DBA                           ; @0DB4 F0 04
    TXA                                    ; @0DB6 8A
    ORA font_pixel_mask                    ; @0DB7 05 87
    TAX                                    ; @0DB9 AA

; ---------------------------------------------------------------------------
loc_0DBA:
    DEY                                    ; @0DBA 88
    BMI loc_0DC3                           ; @0DBB 30 06
    TYA                                    ; @0DBD 98
    LSR A                                  ; @0DBE 4A
    LDA #&55                               ; @0DBF A9 55
    BCS &0DAE                              ; @0DC1 B0 EB

; ---------------------------------------------------------------------------
loc_0DC3:
    LDY font_screen_offset                 ; @0DC3 A4 89
    TXA                                    ; @0DC5 8A
    AND text_colour_mask                   ; @0DC6 25 83
    EOR (text_screen_lo),Y                 ; @0DC8 51 81
    STA (text_screen_lo),Y                 ; @0DCA 91 81
    INC font_screen_offset                 ; @0DCC E6 89
    INY                                    ; @0DCE C8
    CPY #&08                               ; @0DCF C0 08
    BCC &0DA1                              ; @0DD1 90 CE
    LDA text_screen_lo                     ; @0DD3 A5 81
    ADC #&07                               ; @0DD5 69 07
    STA text_screen_lo                     ; @0DD7 85 81
    BCC loc_0DDD                           ; @0DD9 90 02
    INC text_screen_hi                     ; @0DDB E6 82

; ---------------------------------------------------------------------------
loc_0DDD:
    DEC font_row_pair                      ; @0DDD C6 88
    DEC font_row_pair                      ; @0DDF C6 88
    BPL &0D9F                              ; @0DE1 10 BC
    PLA                                    ; @0DE3 68
    TAY                                    ; @0DE4 A8
    PLA                                    ; @0DE5 68
    TAX                                    ; @0DE6 AA
    PLA                                    ; @0DE7 68
    RTS                                    ; @0DE8 60
    ; DATA &0DE9-&0DF0
    EQUB &80, &40, &20, &10, &08, &04, &02, &01    ; @0DE9

; ---------------------------------------------------------------------------
blitter_next_mode2_column:
    LDA erase_screen_lo                    ; @0DF1 A5 0C
    SEC                                    ; @0DF3 38
    SBC #&78                               ; @0DF4 E9 78
    STA erase_screen_lo                    ; @0DF6 85 0C
    LDA erase_screen_hi                    ; @0DF8 A5 0D
    SBC #&02                               ; @0DFA E9 02
    STA erase_screen_hi                    ; @0DFC 85 0D
    TYA                                    ; @0DFE 98
    CLC                                    ; @0DFF 18
    ADC erase_screen_lo                    ; @0E00 65 0C
    LDA erase_screen_hi                    ; @0E02 A5 0D
    ADC #&00                               ; @0E04 69 00
    CMP #&30                               ; @0E06 C9 30
    RTS                                    ; @0E08 60

; ---------------------------------------------------------------------------
wait_for_tick:
    JSR read_game_tick                     ; @0E09 20 11 0E
    BEQ wait_for_tick                      ; @0E0C F0 FB
    STA game_tick                          ; @0E0E 85 52
    RTS                                    ; @0E10 60

; ---------------------------------------------------------------------------
read_game_tick:
    LDA event_tick                         ; @0E11 A5 53
    BIT mos_tick_source_flag               ; @0E13 24 8C
    BMI loc_0E1B                           ; @0E15 30 04
    LDA &F9                                ; @0E17 A5 F9
    EOR #&FF                               ; @0E19 49 FF

; ---------------------------------------------------------------------------
loc_0E1B:
    CMP game_tick                          ; @0E1B C5 52
    RTS                                    ; @0E1D 60

; ---------------------------------------------------------------------------
poll_sound_toggle:
    DEC menu_key_debounce                  ; @0E1E C6 69
    BPL loc_0E48                           ; @0E20 10 26
    LDA #&0C                               ; @0E22 A9 0C
    STA menu_key_debounce                  ; @0E24 85 69
    LDA #&EF                               ; @0E26 A9 EF
    BIT sound_option                       ; @0E28 24 3B
    BPL osbyte_test_key                    ; @0E2A 10 02
    LDA #&AE                               ; @0E2C A9 AE

; ---------------------------------------------------------------------------
osbyte_test_key:
    STA input_temp                         ; @0E2E 85 14
    TXA                                    ; @0E30 8A
    PHA                                    ; @0E31 48
    TYA                                    ; @0E32 98
    PHA                                    ; @0E33 48
    LDX input_temp                         ; @0E34 A6 14
    LDY #&FF                               ; @0E36 A0 FF
    LDA #&81                               ; @0E38 A9 81
    JSR &FFF4                              ; @0E3A 20 F4 FF
    PLA                                    ; @0E3D 68
    TAY                                    ; @0E3E A8
    PLA                                    ; @0E3F 68
    CPX #&00                               ; @0E40 E0 00
    PHP                                    ; @0E42 08
    TAX                                    ; @0E43 AA
    LDA input_temp                         ; @0E44 A5 14
    PLP                                    ; @0E46 28
    RTS                                    ; @0E47 60

; ---------------------------------------------------------------------------
loc_0E48:
    LDA #&00                               ; @0E48 A9 00
    RTS                                    ; @0E4A 60

; ---------------------------------------------------------------------------
poll_control_toggle:
    LDA menu_key_debounce                  ; @0E4B A5 69
    BNE loc_0E48                           ; @0E4D D0 F9
    LDA #&B9                               ; @0E4F A9 B9
    BIT input_mode                         ; @0E51 24 70
    BMI osbyte_test_key                    ; @0E53 30 D9
    LDA #&BA                               ; @0E55 A9 BA
    BNE osbyte_test_key                    ; @0E57 D0 D5

; ---------------------------------------------------------------------------
poll_player_count_toggle:
    LDA menu_key_debounce                  ; @0E59 A5 69
    BNE loc_0E48                           ; @0E5B D0 EB
    LDA #&CF                               ; @0E5D A9 CF
    BIT two_player_option                  ; @0E5F 24 3C
    BMI osbyte_test_key                    ; @0E61 30 CB
    LDA #&CE                               ; @0E63 A9 CE
    BNE osbyte_test_key                    ; @0E65 D0 C7

; ---------------------------------------------------------------------------
event_tick_handler:
    INC event_tick                         ; @0E67 E6 53
    RTS                                    ; @0E69 60

; ---------------------------------------------------------------------------
animate_palette:
    DEC palette_delay                      ; @0E6A C6 1D
    BEQ loc_0E6F                           ; @0E6C F0 01
    RTS                                    ; @0E6E 60

; ---------------------------------------------------------------------------
loc_0E6F:
    LDY #&08                               ; @0E6F A0 08
    LDX palette_phase                      ; @0E71 A6 1E
    TXA                                    ; @0E73 8A
    EOR #&08                               ; @0E74 49 08
    STA palette_phase                      ; @0E76 85 1E
    LDA &0E87,X                            ; @0E78 BD 87 0E
    STA &FE21                              ; @0E7B 8D 21 FE
    DEX                                    ; @0E7E CA
    DEY                                    ; @0E7F 88
    BNE &0E78                              ; @0E80 D0 F6
    LDA #&14                               ; @0E82 A9 14
    STA palette_delay                      ; @0E84 85 1D
    RTS                                    ; @0E86 60
    ; DATA &0E87-&0E96
    EQUB &86, &93, &A7, &B4, &C7, &D4, &E1, &F3, &87, &97, &A3, &B7    ; @0E87
    EQUB &C4, &D7, &E3, &F1    ; @0E93

; ---------------------------------------------------------------------------
random_timer_byte:
    LDA &FE44                              ; @0E97 AD 44 FE
    EOR game_tick                          ; @0E9A 45 52
    EOR player_x                           ; @0E9C 45 16
    RTS                                    ; @0E9E 60
    ; DATA &0E9F-&0EAE
    EQUB &0A, &0A, &26, &4C, &26, &4B, &26, &4A, &A5, &4A, &45, &52    ; @0E9F
    EQUB &60, &68, &AA, &60    ; @0EAB

; ---------------------------------------------------------------------------
draw_sprite_xy:
    STY work_y                             ; @0EAF 84 01
    TAY                                    ; @0EB1 A8
    STX work_x                             ; @0EB2 86 00
    TXA                                    ; @0EB4 8A
    PHA                                    ; @0EB5 48
    JSR setup_and_draw_sprite              ; @0EB6 20 BE 0E
    PLA                                    ; @0EB9 68
    TAX                                    ; @0EBA AA
    LDY work_y                             ; @0EBB A4 01
    RTS                                    ; @0EBD 60

; ---------------------------------------------------------------------------
setup_and_draw_sprite:
    TYA                                    ; @0EBE 98
    PHA                                    ; @0EBF 48
    JSR decode_sprite_descriptor           ; @0EC0 20 23 26
    JSR coord_to_mode2_address             ; @0EC3 20 01 0D
    JMP dispatch_sprite_blitter            ; @0EC6 4C 11 0F

; ---------------------------------------------------------------------------
draw_object:
    LDA #&FF                               ; @0EC9 A9 FF
    NOP &00A9,X                            ; @0ECB DC A9 00 ; undocumented NOP; operand bytes are deliberate alternate entry
    STA input_temp                         ; @0ECE 85 14
    TXA                                    ; @0ED0 8A
    PHA                                    ; @0ED1 48
    LDA object_x,X                         ; @0ED2 BD 00 04
    STA work_x                             ; @0ED5 85 00
    LDA object_y,X                         ; @0ED7 BD 49 04
    STA work_y                             ; @0EDA 85 01
    LDY object_sprite,X                    ; @0EDC BC 92 04
    JSR decode_sprite_descriptor           ; @0EDF 20 23 26
    LSR input_temp                         ; @0EE2 46 14
    BCS loc_0F01                           ; @0EE4 B0 1B
    LDA object_draw_hi,X                   ; @0EE6 BD DB 04
    BEQ loc_0F01                           ; @0EE9 F0 16
    CMP #&FF                               ; @0EEB C9 FF
    BEQ loc_0F01                           ; @0EED F0 12
    STA screen_hi                          ; @0EEF 85 03
    STA erase_screen_hi                    ; @0EF1 85 0D
    LDA #&00                               ; @0EF3 A9 00
    STA object_draw_hi,X                   ; @0EF5 9D DB 04
    LDA object_draw_lo,X                   ; @0EF8 BD 24 05
    STA screen_lo                          ; @0EFB 85 02
    STA erase_screen_lo                    ; @0EFD 85 0C
    BCC dispatch_sprite_blitter            ; @0EFF 90 10

; ---------------------------------------------------------------------------
loc_0F01:
    JSR coord_to_mode2_address             ; @0F01 20 01 0D
    PLA                                    ; @0F04 68
    PHA                                    ; @0F05 48
    TAX                                    ; @0F06 AA
    LDA screen_lo                          ; @0F07 A5 02
    STA object_draw_lo,X                   ; @0F09 9D 24 05
    LDA screen_hi                          ; @0F0C A5 03
    STA object_draw_hi,X                   ; @0F0E 9D DB 04

; ---------------------------------------------------------------------------
dispatch_sprite_blitter:
    LDA work_y                             ; @0F11 A5 01
    AND #&03                               ; @0F13 29 03
    ORA &1C                                ; @0F15 05 1C
    AND #&0F                               ; @0F17 29 0F
    TAX                                    ; @0F19 AA
    LDA blitter_table_lo,X                 ; @0F1A BD B2 11
    STA &1A                                ; @0F1D 85 1A
    LDA blitter_table_hi,X                 ; @0F1F BD C2 11
    STA &1B                                ; @0F22 85 1B
    LDA sprite_src_lo                      ; @0F24 A5 04
    BNE loc_0F2A                           ; @0F26 D0 02
    DEC sprite_src_hi                      ; @0F28 C6 05

; ---------------------------------------------------------------------------
loc_0F2A:
    DEC sprite_src_lo                      ; @0F2A C6 04
    LDX #&55                               ; @0F2C A2 55
    LDA &1C                                ; @0F2E A5 1C
    AND #&08                               ; @0F30 29 08
    BNE loc_0F63                           ; @0F32 D0 2F
    LDY sprite_height                      ; @0F34 A4 07
    LDA work_x                             ; @0F36 A5 00
    CMP #&50                               ; @0F38 C9 50
    BCS loc_0F3F                           ; @0F3A B0 03
    JSR call_sprite_blitter                ; @0F3C 20 91 0F

; ---------------------------------------------------------------------------
loc_0F3F:
    CLC                                    ; @0F3F 18
    TYA                                    ; @0F40 98
    ADC sprite_src_lo                      ; @0F41 65 04
    STA sprite_src_lo                      ; @0F43 85 04
    BCC loc_0F49                           ; @0F45 90 02
    INC sprite_src_hi                      ; @0F47 E6 05

; ---------------------------------------------------------------------------
loc_0F49:
    LDA screen_lo                          ; @0F49 A5 02
    CLC                                    ; @0F4B 18
    ADC #&08                               ; @0F4C 69 08
    STA screen_lo                          ; @0F4E 85 02
    STA erase_screen_lo                    ; @0F50 85 0C
    LDA screen_hi                          ; @0F52 A5 03
    ADC #&00                               ; @0F54 69 00
    STA screen_hi                          ; @0F56 85 03
    STA erase_screen_hi                    ; @0F58 85 0D
    INC work_x                             ; @0F5A E6 00
    DEC sprite_width                       ; @0F5C C6 06
    BNE &0F34                              ; @0F5E D0 D4
    PLA                                    ; @0F60 68
    TAX                                    ; @0F61 AA
    RTS                                    ; @0F62 60

; ---------------------------------------------------------------------------
loc_0F63:
    LDY sprite_height                      ; @0F63 A4 07
    LDA work_x                             ; @0F65 A5 00
    CMP #&50                               ; @0F67 C9 50
    BCS loc_0F6E                           ; @0F69 B0 03
    JSR call_sprite_blitter                ; @0F6B 20 91 0F

; ---------------------------------------------------------------------------
loc_0F6E:
    CLC                                    ; @0F6E 18
    TYA                                    ; @0F6F 98
    ADC sprite_src_lo                      ; @0F70 65 04
    STA sprite_src_lo                      ; @0F72 85 04
    BCC loc_0F78                           ; @0F74 90 02
    INC sprite_src_hi                      ; @0F76 E6 05

; ---------------------------------------------------------------------------
loc_0F78:
    LDA screen_lo                          ; @0F78 A5 02
    SEC                                    ; @0F7A 38
    SBC #&08                               ; @0F7B E9 08
    STA screen_lo                          ; @0F7D 85 02
    STA erase_screen_lo                    ; @0F7F 85 0C
    LDA screen_hi                          ; @0F81 A5 03
    SBC #&00                               ; @0F83 E9 00
    STA screen_hi                          ; @0F85 85 03
    STA erase_screen_hi                    ; @0F87 85 0D
    DEC work_x                             ; @0F89 C6 00
    DEC sprite_width                       ; @0F8B C6 06
    BNE loc_0F63                           ; @0F8D D0 D4
    BEQ &0F60                              ; @0F8F F0 CF

; ---------------------------------------------------------------------------
call_sprite_blitter:
    JMP (&001A)                            ; @0F91 6C 1A 00

; ---------------------------------------------------------------------------
loc_0F94:
    LDA (sprite_src_lo),Y                  ; @0F94 B1 04
    EOR (erase_screen_lo),Y                ; @0F96 51 0C
    STA (erase_screen_lo),Y                ; @0F98 91 0C
    DEY                                    ; @0F9A 88
    BEQ loc_0FE1                           ; @0F9B F0 44
    LDA (sprite_src_lo),Y                  ; @0F9D B1 04
    EOR (erase_screen_lo),Y                ; @0F9F 51 0C
    STA (erase_screen_lo),Y                ; @0FA1 91 0C
    DEY                                    ; @0FA3 88
    BEQ loc_0FE1                           ; @0FA4 F0 3B

; ---------------------------------------------------------------------------
loc_0FA6:
    LDA (sprite_src_lo),Y                  ; @0FA6 B1 04
    EOR (erase_screen_lo),Y                ; @0FA8 51 0C
    STA (erase_screen_lo),Y                ; @0FAA 91 0C
    DEY                                    ; @0FAC 88
    BEQ loc_0FE1                           ; @0FAD F0 32
    LDA (sprite_src_lo),Y                  ; @0FAF B1 04
    EOR (erase_screen_lo),Y                ; @0FB1 51 0C
    STA (erase_screen_lo),Y                ; @0FB3 91 0C
    DEY                                    ; @0FB5 88
    BEQ loc_0FE1                           ; @0FB6 F0 29

; ---------------------------------------------------------------------------
loc_0FB8:
    LDA (sprite_src_lo),Y                  ; @0FB8 B1 04
    EOR (erase_screen_lo),Y                ; @0FBA 51 0C
    STA (erase_screen_lo),Y                ; @0FBC 91 0C
    DEY                                    ; @0FBE 88
    BEQ loc_0FE1                           ; @0FBF F0 20
    LDA (sprite_src_lo),Y                  ; @0FC1 B1 04
    EOR (erase_screen_lo),Y                ; @0FC3 51 0C
    STA (erase_screen_lo),Y                ; @0FC5 91 0C
    DEY                                    ; @0FC7 88
    BEQ loc_0FE1                           ; @0FC8 F0 17

; ---------------------------------------------------------------------------
loc_0FCA:
    LDA (sprite_src_lo),Y                  ; @0FCA B1 04
    EOR (erase_screen_lo),Y                ; @0FCC 51 0C
    STA (erase_screen_lo),Y                ; @0FCE 91 0C
    DEY                                    ; @0FD0 88
    BEQ loc_0FE1                           ; @0FD1 F0 0E
    LDA (sprite_src_lo),Y                  ; @0FD3 B1 04
    EOR (erase_screen_lo),Y                ; @0FD5 51 0C
    STA (erase_screen_lo),Y                ; @0FD7 91 0C
    DEY                                    ; @0FD9 88
    BEQ loc_0FE1                           ; @0FDA F0 05
    JSR blitter_next_mode2_column          ; @0FDC 20 F1 0D
    BCS loc_0F94                           ; @0FDF B0 B3

; ---------------------------------------------------------------------------
loc_0FE1:
    LDY sprite_height                      ; @0FE1 A4 07

; ---------------------------------------------------------------------------
loc_0FE3:
    RTS                                    ; @0FE3 60

; ---------------------------------------------------------------------------
loc_0FE4:
    INC sprite_src_lo                      ; @0FE4 E6 04
    BEQ loc_1052                           ; @0FE6 F0 6A
    LDA (&AF,X)                            ; @0FE8 A1 AF
    EOR (erase_screen_lo),Y                ; @0FEA 51 0C
    STA (erase_screen_lo),Y                ; @0FEC 91 0C
    DEY                                    ; @0FEE 88
    BEQ loc_0FE3                           ; @0FEF F0 F2
    INC sprite_src_lo                      ; @0FF1 E6 04
    BEQ loc_1056                           ; @0FF3 F0 61
    LDA (&AF,X)                            ; @0FF5 A1 AF
    EOR (erase_screen_lo),Y                ; @0FF7 51 0C
    STA (erase_screen_lo),Y                ; @0FF9 91 0C
    DEY                                    ; @0FFB 88
    BEQ loc_0FE3                           ; @0FFC F0 E5

; ---------------------------------------------------------------------------
loc_0FFE:
    INC sprite_src_lo                      ; @0FFE E6 04
    BEQ loc_105A                           ; @1000 F0 58
    LDA (&AF,X)                            ; @1002 A1 AF
    EOR (erase_screen_lo),Y                ; @1004 51 0C
    STA (erase_screen_lo),Y                ; @1006 91 0C
    DEY                                    ; @1008 88
    BEQ loc_0FE3                           ; @1009 F0 D8
    INC sprite_src_lo                      ; @100B E6 04
    BEQ loc_105E                           ; @100D F0 4F
    LDA (&AF,X)                            ; @100F A1 AF
    EOR (erase_screen_lo),Y                ; @1011 51 0C
    STA (erase_screen_lo),Y                ; @1013 91 0C
    DEY                                    ; @1015 88
    BEQ loc_0FE3                           ; @1016 F0 CB

; ---------------------------------------------------------------------------
loc_1018:
    INC sprite_src_lo                      ; @1018 E6 04
    BEQ loc_1062                           ; @101A F0 46
    LDA (&AF,X)                            ; @101C A1 AF
    EOR (erase_screen_lo),Y                ; @101E 51 0C
    STA (erase_screen_lo),Y                ; @1020 91 0C
    DEY                                    ; @1022 88
    BEQ loc_0FE3                           ; @1023 F0 BE
    INC sprite_src_lo                      ; @1025 E6 04
    BEQ loc_1066                           ; @1027 F0 3D
    LDA (&AF,X)                            ; @1029 A1 AF
    EOR (erase_screen_lo),Y                ; @102B 51 0C
    STA (erase_screen_lo),Y                ; @102D 91 0C
    DEY                                    ; @102F 88
    BEQ loc_0FE3                           ; @1030 F0 B1

; ---------------------------------------------------------------------------
loc_1032:
    INC sprite_src_lo                      ; @1032 E6 04
    BEQ loc_106A                           ; @1034 F0 34
    LDA (&AF,X)                            ; @1036 A1 AF
    EOR (erase_screen_lo),Y                ; @1038 51 0C
    STA (erase_screen_lo),Y                ; @103A 91 0C
    DEY                                    ; @103C 88
    BEQ loc_0FE3                           ; @103D F0 A4
    INC sprite_src_lo                      ; @103F E6 04
    BEQ loc_106E                           ; @1041 F0 2B
    LDA (&AF,X)                            ; @1043 A1 AF
    EOR (erase_screen_lo),Y                ; @1045 51 0C
    STA (erase_screen_lo),Y                ; @1047 91 0C
    DEY                                    ; @1049 88
    BEQ loc_0FE3                           ; @104A F0 97
    JSR blitter_next_mode2_column          ; @104C 20 F1 0D
    BCS loc_0FE4                           ; @104F B0 93
    RTS                                    ; @1051 60

; ---------------------------------------------------------------------------
loc_1052:
    INC sprite_src_hi                      ; @1052 E6 05
    BNE &0FE8                              ; @1054 D0 92

; ---------------------------------------------------------------------------
loc_1056:
    INC sprite_src_hi                      ; @1056 E6 05
    BNE &0FF5                              ; @1058 D0 9B

; ---------------------------------------------------------------------------
loc_105A:
    INC sprite_src_hi                      ; @105A E6 05
    BNE &1002                              ; @105C D0 A4

; ---------------------------------------------------------------------------
loc_105E:
    INC sprite_src_hi                      ; @105E E6 05
    BNE &100F                              ; @1060 D0 AD

; ---------------------------------------------------------------------------
loc_1062:
    INC sprite_src_hi                      ; @1062 E6 05
    BNE &101C                              ; @1064 D0 B6

; ---------------------------------------------------------------------------
loc_1066:
    INC sprite_src_hi                      ; @1066 E6 05
    BNE &1029                              ; @1068 D0 BF

; ---------------------------------------------------------------------------
loc_106A:
    INC sprite_src_hi                      ; @106A E6 05
    BNE &1036                              ; @106C D0 C8

; ---------------------------------------------------------------------------
loc_106E:
    INC sprite_src_hi                      ; @106E E6 05
    BNE &1043                              ; @1070 D0 D1

; ---------------------------------------------------------------------------
loc_1072:
    LDA (sprite_src_lo),Y                  ; @1072 B1 04
    SAX math_temp80                        ; @1074 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1076 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1078 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @107A 51 0C
    STA (erase_screen_lo),Y                ; @107C 91 0C
    DEY                                    ; @107E 88
    BEQ loc_10EF                           ; @107F F0 6E
    LDA (sprite_src_lo),Y                  ; @1081 B1 04
    SAX math_temp80                        ; @1083 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1085 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1087 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @1089 51 0C
    STA (erase_screen_lo),Y                ; @108B 91 0C
    DEY                                    ; @108D 88
    BEQ loc_10EF                           ; @108E F0 5F

; ---------------------------------------------------------------------------
loc_1090:
    LDA (sprite_src_lo),Y                  ; @1090 B1 04
    SAX math_temp80                        ; @1092 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1094 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1096 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @1098 51 0C
    STA (erase_screen_lo),Y                ; @109A 91 0C
    DEY                                    ; @109C 88
    BEQ loc_10EF                           ; @109D F0 50
    LDA (sprite_src_lo),Y                  ; @109F B1 04
    SAX math_temp80                        ; @10A1 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @10A3 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @10A5 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @10A7 51 0C
    STA (erase_screen_lo),Y                ; @10A9 91 0C
    DEY                                    ; @10AB 88
    BEQ loc_10EF                           ; @10AC F0 41

; ---------------------------------------------------------------------------
loc_10AE:
    LDA (sprite_src_lo),Y                  ; @10AE B1 04
    SAX math_temp80                        ; @10B0 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @10B2 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @10B4 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @10B6 51 0C
    STA (erase_screen_lo),Y                ; @10B8 91 0C
    DEY                                    ; @10BA 88
    BEQ loc_10EF                           ; @10BB F0 32
    LDA (sprite_src_lo),Y                  ; @10BD B1 04
    SAX math_temp80                        ; @10BF 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @10C1 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @10C3 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @10C5 51 0C
    STA (erase_screen_lo),Y                ; @10C7 91 0C
    DEY                                    ; @10C9 88
    BEQ loc_10EF                           ; @10CA F0 23

; ---------------------------------------------------------------------------
loc_10CC:
    LDA (sprite_src_lo),Y                  ; @10CC B1 04
    SAX math_temp80                        ; @10CE 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @10D0 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @10D2 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @10D4 51 0C
    STA (erase_screen_lo),Y                ; @10D6 91 0C
    DEY                                    ; @10D8 88
    BEQ loc_10EF                           ; @10D9 F0 14
    LDA (sprite_src_lo),Y                  ; @10DB B1 04
    SAX math_temp80                        ; @10DD 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @10DF 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @10E1 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @10E3 51 0C
    STA (erase_screen_lo),Y                ; @10E5 91 0C
    DEY                                    ; @10E7 88
    BEQ loc_10EF                           ; @10E8 F0 05
    JSR blitter_next_mode2_column          ; @10EA 20 F1 0D
    BCS loc_1072                           ; @10ED B0 83

; ---------------------------------------------------------------------------
loc_10EF:
    LDY sprite_height                      ; @10EF A4 07
    RTS                                    ; @10F1 60

; ---------------------------------------------------------------------------
loc_10F2:
    INC sprite_src_hi                      ; @10F2 E6 05
    BNE &1112                              ; @10F4 D0 1C

; ---------------------------------------------------------------------------
loc_10F6:
    INC sprite_src_hi                      ; @10F6 E6 05
    BNE &1126                              ; @10F8 D0 2C

; ---------------------------------------------------------------------------
loc_10FA:
    INC sprite_src_hi                      ; @10FA E6 05
    BNE &1139                              ; @10FC D0 3B

; ---------------------------------------------------------------------------
loc_10FE:
    INC sprite_src_hi                      ; @10FE E6 05
    BNE &114C                              ; @1100 D0 4A

; ---------------------------------------------------------------------------
loc_1102:
    INC sprite_src_hi                      ; @1102 E6 05
    BNE &115F                              ; @1104 D0 59

; ---------------------------------------------------------------------------
loc_1106:
    INC sprite_src_hi                      ; @1106 E6 05
    BNE &1172                              ; @1108 D0 68

; ---------------------------------------------------------------------------
loc_110A:
    INC sprite_src_hi                      ; @110A E6 05
    BNE &1185                              ; @110C D0 77

; ---------------------------------------------------------------------------
loc_110E:
    INC sprite_src_lo                      ; @110E E6 04
    BEQ loc_10F2                           ; @1110 F0 E0
    LDA (&AF,X)                            ; @1112 A1 AF
    SAX math_temp80                        ; @1114 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1116 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1118 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @111A 51 0C
    STA (erase_screen_lo),Y                ; @111C 91 0C
    DEY                                    ; @111E 88
    BNE loc_1122                           ; @111F D0 01
    RTS                                    ; @1121 60

; ---------------------------------------------------------------------------
loc_1122:
    INC sprite_src_lo                      ; @1122 E6 04
    BEQ loc_10F6                           ; @1124 F0 D0
    LDA (&AF,X)                            ; @1126 A1 AF
    SAX math_temp80                        ; @1128 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @112A 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @112C 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @112E 51 0C
    STA (erase_screen_lo),Y                ; @1130 91 0C
    DEY                                    ; @1132 88
    BEQ loc_11AE                           ; @1133 F0 79

; ---------------------------------------------------------------------------
loc_1135:
    INC sprite_src_lo                      ; @1135 E6 04
    BEQ loc_10FA                           ; @1137 F0 C1
    LDA (&AF,X)                            ; @1139 A1 AF
    SAX math_temp80                        ; @113B 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @113D 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @113F 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @1141 51 0C
    STA (erase_screen_lo),Y                ; @1143 91 0C
    DEY                                    ; @1145 88
    BEQ loc_11AE                           ; @1146 F0 66
    INC sprite_src_lo                      ; @1148 E6 04
    BEQ loc_10FE                           ; @114A F0 B2
    LDA (&AF,X)                            ; @114C A1 AF
    SAX math_temp80                        ; @114E 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1150 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1152 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @1154 51 0C
    STA (erase_screen_lo),Y                ; @1156 91 0C
    DEY                                    ; @1158 88
    BEQ loc_11AE                           ; @1159 F0 53

; ---------------------------------------------------------------------------
loc_115B:
    INC sprite_src_lo                      ; @115B E6 04
    BEQ loc_1102                           ; @115D F0 A3
    LDA (&AF,X)                            ; @115F A1 AF
    SAX math_temp80                        ; @1161 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1163 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1165 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @1167 51 0C
    STA (erase_screen_lo),Y                ; @1169 91 0C
    DEY                                    ; @116B 88
    BEQ loc_11AE                           ; @116C F0 40
    INC sprite_src_lo                      ; @116E E6 04
    BEQ loc_1106                           ; @1170 F0 94
    LDA (&AF,X)                            ; @1172 A1 AF
    SAX math_temp80                        ; @1174 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1176 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @1178 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @117A 51 0C
    STA (erase_screen_lo),Y                ; @117C 91 0C
    DEY                                    ; @117E 88
    BEQ loc_11AE                           ; @117F F0 2D

; ---------------------------------------------------------------------------
loc_1181:
    INC sprite_src_lo                      ; @1181 E6 04
    BEQ loc_110A                           ; @1183 F0 85
    LDA (&AF,X)                            ; @1185 A1 AF
    SAX math_temp80                        ; @1187 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @1189 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @118B 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @118D 51 0C
    STA (erase_screen_lo),Y                ; @118F 91 0C
    DEY                                    ; @1191 88
    BEQ loc_11AE                           ; @1192 F0 1A
    INC sprite_src_lo                      ; @1194 E6 04
    BNE loc_119A                           ; @1196 D0 02
    INC sprite_src_hi                      ; @1198 E6 05

; ---------------------------------------------------------------------------
loc_119A:
    LDA (&AF,X)                            ; @119A A1 AF
    SAX math_temp80                        ; @119C 87 80 ; undocumented NMOS 6502
    ALR #&AA                               ; @119E 4B AA ; undocumented NMOS 6502
    SLO math_temp80                        ; @11A0 07 80 ; undocumented NMOS 6502
    EOR (erase_screen_lo),Y                ; @11A2 51 0C
    STA (erase_screen_lo),Y                ; @11A4 91 0C
    DEY                                    ; @11A6 88
    BEQ loc_11AE                           ; @11A7 F0 05
    JSR blitter_next_mode2_column          ; @11A9 20 F1 0D
    BCS loc_11AF                           ; @11AC B0 01

; ---------------------------------------------------------------------------
loc_11AE:
    RTS                                    ; @11AE 60

; ---------------------------------------------------------------------------
loc_11AF:
    JMP loc_110E                           ; @11AF 4C 0E 11
    ; DATA &11B2-&11D1
    EQUB &94, &A6, &B8, &CA, &E4, &FE, &18, &32, &72, &90, &AE, &CC    ; @11B2
    EQUB &0E, &35, &5B, &81, &0F, &0F, &0F, &0F, &0F, &0F, &10, &10    ; @11BE
    EQUB &10, &10, &10, &10, &11, &11, &11, &11    ; @11CA

; ---------------------------------------------------------------------------
update_formation_motion:
    JSR update_one_formation_slot          ; @11D2 20 D5 11

; ---------------------------------------------------------------------------
update_one_formation_slot:
    DEC formation_scan_slot                ; @11D5 C6 4E
    BPL loc_11FD                           ; @11D7 10 24
    LDA #&27                               ; @11D9 A9 27
    STA formation_scan_slot                ; @11DB 85 4E
    DEC formation_sweep_countdown          ; @11DD C6 51
    BPL loc_11EB                           ; @11DF 10 0A
    LDA #&07                               ; @11E1 A9 07
    STA formation_sweep_countdown          ; @11E3 85 51
    LDA formation_direction                ; @11E5 A5 50
    EOR #&FF                               ; @11E7 49 FF
    STA formation_direction                ; @11E9 85 50

; ---------------------------------------------------------------------------
loc_11EB:
    LDA formation_phase_mask               ; @11EB A5 4F
    BIT formation_direction                ; @11ED 24 50
    BMI loc_11F7                           ; @11EF 30 06
    CMP #&80                               ; @11F1 C9 80
    ROL A                                  ; @11F3 2A
    JMP loc_11FB                           ; @11F4 4C FB 11

; ---------------------------------------------------------------------------
loc_11F7:
    LSR A                                  ; @11F7 4A
    BCC loc_11FB                           ; @11F8 90 01
    ROR A                                  ; @11FA 6A

; ---------------------------------------------------------------------------
loc_11FB:
    STA formation_phase_mask               ; @11FB 85 4F

; ---------------------------------------------------------------------------
loc_11FD:
    LDX formation_scan_slot                ; @11FD A6 4E
    LDY formation_x_index,X                ; @11FF BC 43 06
    LDA formation_motion_masks,Y           ; @1202 B9 AC 06
    LDY formation_y_index,X                ; @1205 BC 6B 06
    ORA formation_motion_masks,Y           ; @1208 19 AC 06
    BIT formation_phase_mask               ; @120B 24 4F
    BEQ loc_1251                           ; @120D F0 42
    LDA object_draw_hi,X                   ; @120F BD DB 04
    PHP                                    ; @1212 08
    BEQ loc_1218                           ; @1213 F0 03
    JSR erase_object                       ; @1215 20 CC 0E

; ---------------------------------------------------------------------------
loc_1218:
    LDY formation_x_index,X                ; @1218 BC 43 06
    LDA formation_motion_masks,Y           ; @121B B9 AC 06
    BIT formation_phase_mask               ; @121E 24 4F
    BEQ loc_1233                           ; @1220 F0 11
    CPY #&05                               ; @1222 C0 05
    LDY object_x,X                         ; @1224 BC 00 04
    ROR A                                  ; @1227 6A
    EOR formation_direction                ; @1228 45 50
    BMI loc_122E                           ; @122A 30 02
    DEY                                    ; @122C 88
    DEY                                    ; @122D 88

; ---------------------------------------------------------------------------
loc_122E:
    INY                                    ; @122E C8
    TYA                                    ; @122F 98
    STA object_x,X                         ; @1230 9D 00 04

; ---------------------------------------------------------------------------
loc_1233:
    LDY formation_y_index,X                ; @1233 BC 6B 06
    LDA formation_motion_masks,Y           ; @1236 B9 AC 06
    BIT formation_phase_mask               ; @1239 24 4F
    BEQ loc_124B                           ; @123B F0 0E
    LDY object_y,X                         ; @123D BC 49 04
    BIT formation_direction                ; @1240 24 50
    BPL loc_1246                           ; @1242 10 02
    INY                                    ; @1244 C8
    INY                                    ; @1245 C8

; ---------------------------------------------------------------------------
loc_1246:
    DEY                                    ; @1246 88
    TYA                                    ; @1247 98
    STA object_y,X                         ; @1248 9D 49 04

; ---------------------------------------------------------------------------
loc_124B:
    PLP                                    ; @124B 28
    BEQ loc_1251                           ; @124C F0 03
    JMP draw_object                        ; @124E 4C C9 0E

; ---------------------------------------------------------------------------
loc_1251:
    RTS                                    ; @1251 60

; ---------------------------------------------------------------------------
; Erase/move/redraw 50 runtime-generated stars.
update_starfield:
    LDY #&00                               ; @1252 A0 00
    LDX #&31                               ; @1254 A2 31
    LDA star_address_lo,X                  ; @1256 BD 0E 0A
    STA screen_lo                          ; @1259 85 02
    LDA star_address_hi,X                  ; @125B BD 40 0A
    STA screen_hi                          ; @125E 85 03
    LDA star_xor_colour,X                  ; @1260 BD 72 0A
    EOR (screen_lo),Y                      ; @1263 51 02
    STA (screen_lo),Y                      ; @1265 91 02
    INC star_address_lo,X                  ; @1267 FE 0E 0A
    BNE loc_126F                           ; @126A D0 03
    INC star_address_hi,X                  ; @126C FE 40 0A

; ---------------------------------------------------------------------------
loc_126F:
    LDA star_address_lo,X                  ; @126F BD 0E 0A
    BIT mask_7_constant                    ; @1272 24 49
    BEQ loc_1290                           ; @1274 F0 1A
    STA screen_lo                          ; @1276 85 02
    LDA star_address_hi,X                  ; @1278 BD 40 0A
    STA screen_hi                          ; @127B 85 03
    CLC                                    ; @127D 18
    LDA star_xor_colour,X                  ; @127E BD 72 0A
    ADC #&16                               ; @1281 69 16
    AND #&2A                               ; @1283 29 2A
    STA star_xor_colour,X                  ; @1285 9D 72 0A
    EOR (screen_lo),Y                      ; @1288 51 02
    STA (screen_lo),Y                      ; @128A 91 02
    DEX                                    ; @128C CA
    BPL &1256                              ; @128D 10 C7
    RTS                                    ; @128F 60

; ---------------------------------------------------------------------------
loc_1290:
    CLC                                    ; @1290 18
    ADC #&78                               ; @1291 69 78
    PHA                                    ; @1293 48
    STA star_address_lo,X                  ; @1294 9D 0E 0A
    LDA star_address_hi,X                  ; @1297 BD 40 0A
    ADC #&02                               ; @129A 69 02
    STA star_address_hi,X                  ; @129C 9D 40 0A
    BMI loc_12A5                           ; @129F 30 04
    PLA                                    ; @12A1 68
    JMP &1276                              ; @12A2 4C 76 12

; ---------------------------------------------------------------------------
loc_12A5:
    JSR choose_random_star_address         ; @12A5 20 B9 12
    CLC                                    ; @12A8 18
    LDA screen_hi                          ; @12A9 A5 03
    ADC #&30                               ; @12AB 69 30
    STA star_address_hi,X                  ; @12AD 9D 40 0A
    PLA                                    ; @12B0 68
    LDA screen_lo                          ; @12B1 A5 02
    STA star_address_lo,X                  ; @12B3 9D 0E 0A
    JMP &1276                              ; @12B6 4C 76 12

; ---------------------------------------------------------------------------
choose_random_star_address:
    LDA #&00                               ; @12B9 A9 00
    STA screen_hi                          ; @12BB 85 03
    JSR random_timer_byte                  ; @12BD 20 97 0E
    SBC #&4F                               ; @12C0 E9 4F
    BCS &12C0                              ; @12C2 B0 FC
    ADC #&50                               ; @12C4 69 50
    LDY #&03                               ; @12C6 A0 03
    ASL A                                  ; @12C8 0A
    ROL screen_hi                          ; @12C9 26 03
    DEY                                    ; @12CB 88
    BNE &12C8                              ; @12CC D0 FA
    STA screen_lo                          ; @12CE 85 02
    JSR random_timer_byte                  ; @12D0 20 97 0E
    AND #&07                               ; @12D3 29 07
    ORA screen_lo                          ; @12D5 05 02
    STA screen_lo                          ; @12D7 85 02
    RTS                                    ; @12D9 60

; ---------------------------------------------------------------------------
add_score_low_only:
    LDY #&00                               ; @12DA A0 00

; ---------------------------------------------------------------------------
; Add packed-BCD score; carry out of middle byte signals 100,000 displayed points.
add_score_bcd:
    LDX current_player                     ; @12DC A6 32
    PHA                                    ; @12DE 48
    CLC                                    ; @12DF 18
    SED                                    ; @12E0 F8
    ADC player0_score_lo,X                 ; @12E1 75 1F
    STA player0_score_lo,X                 ; @12E3 95 1F
    TYA                                    ; @12E5 98
    ADC player0_score_mid,X                ; @12E6 75 21
    STA player0_score_mid,X                ; @12E8 95 21
    PHP                                    ; @12EA 08
    LDA #&00                               ; @12EB A9 00
    ADC player0_score_hi,X                 ; @12ED 75 23
    STA player0_score_hi,X                 ; @12EF 95 23
    PLP                                    ; @12F1 28
    CLD                                    ; @12F2 D8
    PLA                                    ; @12F3 68
    RTS                                    ; @12F4 60

; ---------------------------------------------------------------------------
; XOR one fighter, or two when fighter_configuration=&FF.
xor_player_ship:
    JSR load_player_screen_pointer         ; @12F5 20 21 13
    CLC                                    ; @12F8 18
    ADC #&80                               ; @12F9 69 80
    STA erase_screen_lo                    ; @12FB 85 0C
    LDA player_screen_hi                   ; @12FD A5 18
    ADC #&02                               ; @12FF 69 02
    STA erase_screen_hi                    ; @1301 85 0D
    JSR xor_one_fighter                    ; @1303 20 0D 13
    BIT fighter_configuration              ; @1306 24 19
    BPL loc_1320                           ; @1308 10 16
    JSR advance_secondary_fighter_pointer  ; @130A 20 2A 13

; ---------------------------------------------------------------------------
xor_one_fighter:
    LDY #&2F                               ; @130D A0 2F
    LDA (screen_lo),Y                      ; @130F B1 02
    EOR &06B6,Y                            ; @1311 59 B6 06
    STA (screen_lo),Y                      ; @1314 91 02
    LDA (erase_screen_lo),Y                ; @1316 B1 0C
    EOR &06E6,Y                            ; @1318 59 E6 06
    STA (erase_screen_lo),Y                ; @131B 91 0C
    DEY                                    ; @131D 88
    BPL &130F                              ; @131E 10 EF

; ---------------------------------------------------------------------------
loc_1320:
    RTS                                    ; @1320 60

; ---------------------------------------------------------------------------
load_player_screen_pointer:
    LDA player_screen_hi                   ; @1321 A5 18
    STA screen_hi                          ; @1323 85 03
    LDA player_screen_lo                   ; @1325 A5 17
    STA screen_lo                          ; @1327 85 02
    RTS                                    ; @1329 60

; ---------------------------------------------------------------------------
advance_secondary_fighter_pointer:
    LDA erase_screen_lo                    ; @132A A5 0C
    CLC                                    ; @132C 18
    ADC #&30                               ; @132D 69 30
    STA erase_screen_lo                    ; @132F 85 0C
    BCC advance_primary_screen_pointer     ; @1331 90 02
    INC erase_screen_hi                    ; @1333 E6 0D

; ---------------------------------------------------------------------------
advance_primary_screen_pointer:
    LDA screen_lo                          ; @1335 A5 02
    CLC                                    ; @1337 18
    ADC #&30                               ; @1338 69 30
    STA screen_lo                          ; @133A 85 02
    BCC loc_1340                           ; @133C 90 02
    INC screen_hi                          ; @133E E6 03

; ---------------------------------------------------------------------------
loc_1340:
    RTS                                    ; @1340 60

; ---------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; FLATTENED MODULE: 02_game_player_collision.asm
; ----------------------------------------------------------------------------
; ZALAGA V10 - Top-level game loop, player/lives/Dual Ship, firing, projectiles, collisions, explosions and input
; Sequential module included by ../zalaga.asm.

top_level_loop:
    JSR attract_title                      ; @1341 20 9C 21
    JSR game_session                       ; @1344 20 4A 13
    JMP top_level_loop                     ; @1347 4C 41 13

; ---------------------------------------------------------------------------
; Initialise player/session state, run stages, deaths, player switching and game over.
game_session:
    JSR draw_all_scores                    ; @134A 20 10 22
    LDA #&00                               ; @134D A9 00
    LDX #&15                               ; @134F A2 15
    STA palette_phase,X                    ; @1351 95 1E
    DEX                                    ; @1353 CA
    BNE &1351                              ; @1354 D0 FB
    INX                                    ; @1356 E8
    LDA #&01                               ; @1357 A9 01
    STA player0_stage_lo,X                 ; @1359 95 37
    LDA #&04                               ; @135B A9 04
    STA player0_fighters,X                 ; @135D 95 35
    DEX                                    ; @135F CA
    BPL &1357                              ; @1360 10 F5
    LDA two_player_option                  ; @1362 A5 3C
    BMI loc_1368                           ; @1364 30 02
    STA player1_fighters                   ; @1366 85 36

; ---------------------------------------------------------------------------
loc_1368:
    JSR draw_all_scores                    ; @1368 20 10 22
    LDA #&7E                               ; @136B A9 7E
    JSR &FFF4                              ; @136D 20 F4 FF
    JSR install_input_vectors              ; @1370 20 E7 18
    JSR clear_object_draw_state            ; @1373 20 7C 14
    LDY #&00                               ; @1376 A0 00
    JSR set_stage_handler                  ; @1378 20 C6 1B
    LDA #&30                               ; @137B A9 30
    STA player_screen_lo                   ; @137D 85 17
    LDA #&77                               ; @137F A9 77
    STA player_screen_hi                   ; @1381 85 18
    LDA #&26                               ; @1383 A9 26
    STA player_x                           ; @1385 85 16
    JSR refresh_lives_display              ; @1387 20 A6 24
    JSR setup_sound_envelopes              ; @138A 20 87 14
    LDA #&00                               ; @138D A9 00
    STA beam_active                        ; @138F 85 C3
    STA player_dead                        ; @1391 85 33
    STA fighter_configuration              ; @1393 85 19
    STA beam_phase                         ; @1395 85 BC
    LDX #&01                               ; @1397 A2 01
    STA &B4,X                              ; @1399 95 B4
    DEX                                    ; @139B CA
    BPL &1399                              ; @139C 10 FB
    STX beam_owner_slot                    ; @139E 86 C5
    JSR xor_player_ship                    ; @13A0 20 F5 12
    LDX current_player                     ; @13A3 A6 32
    DEC player0_fighters,X                 ; @13A5 D6 35
    JSR gameplay_frame_service             ; @13A7 20 01 22
    JSR dispatch_stage_state               ; @13AA 20 D9 1A
    BIT player_dead                        ; @13AD 24 33
    BPL &13A7                              ; @13AF 10 F6
    LDA active_attacker_count              ; @13B1 A5 54
    BNE &13A7                              ; @13B3 D0 F2
    DEC turn_delay                         ; @13B5 C6 4D
    BEQ loc_13D0                           ; @13B7 F0 17
    LDA turn_delay                         ; @13B9 A5 4D
    CMP #&82                               ; @13BB C9 82
    BNE &13A7                              ; @13BD D0 E8
    LDX current_player                     ; @13BF A6 32
    LDA player0_fighters,X                 ; @13C1 B5 35
    BNE &13A7                              ; @13C3 D0 E2
    LDY #&28                               ; @13C5 A0 28
    JSR queue_message                      ; @13C7 20 93 20
    JSR queue_player_name_message          ; @13CA 20 73 17
    JMP &13A7                              ; @13CD 4C A7 13

; ---------------------------------------------------------------------------
loc_13D0:
    LDX current_player                     ; @13D0 A6 32
    LDA player0_fighters,X                 ; @13D2 B5 35
    BNE loc_13D9                           ; @13D4 D0 03
    JSR insert_high_score                  ; @13D6 20 CC 24

; ---------------------------------------------------------------------------
loc_13D9:
    LDA player0_fighters                   ; @13D9 A5 35
    ORA player1_fighters                   ; @13DB 05 36
    BEQ &1402                              ; @13DD F0 23
    LDA current_player                     ; @13DF A5 32
    EOR #&01                               ; @13E1 49 01
    TAX                                    ; @13E3 AA
    LDA player0_fighters,X                 ; @13E4 B5 35
    BEQ &137B                              ; @13E6 F0 93
    STX current_player                     ; @13E8 86 32
    JSR clear_playfield_objects            ; @13EA 20 05 14
    JMP &136B                              ; @13ED 4C 6B 13

; ---------------------------------------------------------------------------
loc_13F0:
    RTS                                    ; @13F0 60

; ---------------------------------------------------------------------------
erase_enemy_projectile_slot:
    JSR xor_enemy_projectile               ; @13F1 20 3D 16
    LDA #&00                               ; @13F4 A9 00
    STA object_draw_hi,X                   ; @13F6 9D DB 04
    BEQ loc_141A                           ; @13F9 F0 1F
    LDA #&8F                               ; @13FB A9 8F
    JSR osbyte_test_key                    ; @13FD 20 2E 0E
    BEQ loc_13F0                           ; @1400 F0 EE
    LDX #&FD                               ; @1402 A2 FD
    TXS                                    ; @1404 9A

; ---------------------------------------------------------------------------
clear_playfield_objects:
    LDX #&48                               ; @1405 A2 48
    LDA object_draw_hi,X                   ; @1407 BD DB 04
    BEQ loc_141A                           ; @140A F0 0E
    CMP #&FF                               ; @140C C9 FF
    BEQ &13F4                              ; @140E F0 E4
    LDA object_type_flags,X                ; @1410 BD AF 05
    CMP #&08                               ; @1413 C9 08
    BEQ erase_enemy_projectile_slot        ; @1415 F0 DA
    JSR erase_object                       ; @1417 20 CC 0E

; ---------------------------------------------------------------------------
loc_141A:
    DEX                                    ; @141A CA
    BPL &1407                              ; @141B 10 EA
    BIT player_dead                        ; @141D 24 33
    BMI loc_1424                           ; @141F 30 03
    JSR xor_player_ship                    ; @1421 20 F5 12

; ---------------------------------------------------------------------------
loc_1424:
    JSR force_finish_beam                  ; @1424 20 FC 26
    LDX #&01                               ; @1427 A2 01
    LDA &B4,X                              ; @1429 B5 B4
    BEQ loc_1434                           ; @142B F0 07
    JSR xor_player_shot                    ; @142D 20 17 17
    LDA #&00                               ; @1430 A9 00
    STA &B4,X                              ; @1432 95 B4

; ---------------------------------------------------------------------------
loc_1434:
    DEX                                    ; @1434 CA
    BPL &1429                              ; @1435 10 F2
    STA sound_gate                         ; @1437 85 79
    JMP display_pending_messages           ; @1439 4C 7B 20
    ; DATA &143C-&144A
    EQUB &28, &27, &26, &27, &28, &27, &26, &27, &26, &27, &28, &26    ; @143C
    EQUB &27, &28, &FF    ; @1448

; ---------------------------------------------------------------------------
update_effect_slots:
    LDX #&3F                               ; @144B A2 3F
    LDA object_draw_hi,X                   ; @144D BD DB 04
    BEQ loc_1476                           ; @1450 F0 24
    LDA game_tick                          ; @1452 A5 52
    CMP object_last_tick,X                 ; @1454 DD 45 05
    BMI loc_1476                           ; @1457 30 1D
    JSR erase_object                       ; @1459 20 CC 0E
    LDA object_last_tick,X                 ; @145C BD 45 05
    CLC                                    ; @145F 18
    ADC #&08                               ; @1460 69 08
    STA object_last_tick,X                 ; @1462 9D 45 05
    INC object_state,X                     ; @1465 FE 66 05
    LDY object_state,X                     ; @1468 BC 66 05
    LDA effect_sprite_sequence,Y           ; @146B B9 3C 14
    BMI loc_1476                           ; @146E 30 06
    STA object_sprite,X                    ; @1470 9D 92 04
    JSR draw_object                        ; @1473 20 C9 0E

; ---------------------------------------------------------------------------
loc_1476:
    INX                                    ; @1476 E8
    CPX #&49                               ; @1477 E0 49
    BCC &144D                              ; @1479 90 D2
    RTS                                    ; @147B 60

; ---------------------------------------------------------------------------
clear_object_draw_state:
    LDX #&48                               ; @147C A2 48
    LDA #&00                               ; @147E A9 00
    STA object_draw_hi,X                   ; @1480 9D DB 04
    DEX                                    ; @1483 CA
    BPL &1480                              ; @1484 10 FA
    RTS                                    ; @1486 60

; ---------------------------------------------------------------------------
setup_sound_envelopes:
    LDY #&00                               ; @1487 A0 00
    JSR envelope_osword8                   ; @1489 20 E9 23
    LDY #&0E                               ; @148C A0 0E
    JSR envelope_osword8                   ; @148E 20 E9 23
    LDY #&46                               ; @1491 A0 46
    JSR envelope_osword8                   ; @1493 20 E9 23
    LDY #&1C                               ; @1496 A0 1C
    JMP envelope_osword8                   ; @1498 4C E9 23

; ---------------------------------------------------------------------------
flush_keyboard_buffer:
    LDA #&0F                               ; @149B A9 0F
    LDX #&00                               ; @149D A2 00
    JMP &FFF4                              ; @149F 4C F4 FF

; ---------------------------------------------------------------------------
loc_14A2:
    RTS                                    ; @14A2 60

; ---------------------------------------------------------------------------
; Movement, tractor capture, collision and Dual Ship half-damage logic.
update_player:
    BIT player_dead                        ; @14A3 24 33
    BMI loc_14A2                           ; @14A5 30 FB
    JSR xor_player_ship                    ; @14A7 20 F5 12
    LDX player_x                           ; @14AA A6 16
    JSR read_horizontal_input              ; @14AC 20 E1 18
    TXA                                    ; @14AF 8A
    BEQ loc_14DE                           ; @14B0 F0 2C
    BIT fighter_configuration              ; @14B2 24 19
    BPL loc_14BE                           ; @14B4 10 08
    CPX player_x                           ; @14B6 E4 16
    BEQ loc_14DE                           ; @14B8 F0 24
    BCC loc_14BE                           ; @14BA 90 02
    ADC #&05                               ; @14BC 69 05

; ---------------------------------------------------------------------------
loc_14BE:
    CMP #&4A                               ; @14BE C9 4A
    BCS loc_14DE                           ; @14C0 B0 1C
    CPX player_x                           ; @14C2 E4 16
    BEQ loc_14DE                           ; @14C4 F0 18
    STX player_x                           ; @14C6 86 16
    LDA player_screen_lo                   ; @14C8 A5 17
    BCS loc_14D6                           ; @14CA B0 0A
    SBC #&07                               ; @14CC E9 07
    STA player_screen_lo                   ; @14CE 85 17
    BCS loc_14DE                           ; @14D0 B0 0C
    DEC player_screen_hi                   ; @14D2 C6 18
    BCC loc_14DE                           ; @14D4 90 08

; ---------------------------------------------------------------------------
loc_14D6:
    ADC #&07                               ; @14D6 69 07
    STA player_screen_lo                   ; @14D8 85 17
    BCC loc_14DE                           ; @14DA 90 02
    INC player_screen_hi                   ; @14DC E6 18

; ---------------------------------------------------------------------------
loc_14DE:
    BIT fighter_configuration              ; @14DE 24 19
    BMI loc_1516                           ; @14E0 30 34
    LDX current_player                     ; @14E2 A6 32
    LDA player0_fighters,X                 ; @14E4 B5 35
    BEQ loc_1516                           ; @14E6 F0 2E
    LDA beam_phase                         ; @14E8 A5 BC
    CMP #&10                               ; @14EA C9 10
    BCC loc_1516                           ; @14EC 90 28
    LDA player_x                           ; @14EE A5 16
    CMP beam_capture_left                  ; @14F0 C5 C6
    BCC loc_1516                           ; @14F2 90 22
    CMP beam_capture_right                 ; @14F4 C5 C7
    BCS loc_1516                           ; @14F6 B0 1E
    DEC fighter_configuration              ; @14F8 C6 19
    JSR refresh_lives_display              ; @14FA 20 A6 24
    LDX current_player                     ; @14FD A6 32
    DEC player0_fighters,X                 ; @14FF D6 35
    DEC active_attacker_count              ; @1501 C6 54
    DEC player0_aliens_left,X              ; @1503 D6 39
    JSR force_finish_beam                  ; @1505 20 FC 26
    LDX beam_owner_slot                    ; @1508 A6 C5
    JSR erase_object                       ; @150A 20 CC 0E
    LDA #&FF                               ; @150D A9 FF
    STA beam_owner_slot                    ; @150F 85 C5
    LDY #&03                               ; @1511 A0 03
    JSR start_music                        ; @1513 20 32 24

; ---------------------------------------------------------------------------
loc_1516:
    JSR load_player_screen_pointer         ; @1516 20 21 13
    LDY #&00                               ; @1519 A0 00
    JSR test_player_half_collision         ; @151B 20 7D 15
    BIT fighter_configuration              ; @151E 24 19
    BCC loc_1548                           ; @1520 90 26
    BMI loc_152E                           ; @1522 30 0A
    DEC player_dead                        ; @1524 C6 33
    LDA #&E1                               ; @1526 A9 E1
    STA turn_delay                         ; @1528 85 4D
    LDA player_x                           ; @152A A5 16
    BPL explode_player_half                ; @152C 10 2F

; ---------------------------------------------------------------------------
loc_152E:
    LDA player_x                           ; @152E A5 16
    JSR explode_player_half                ; @1530 20 5D 15
    LDA player_x                           ; @1533 A5 16
    CLC                                    ; @1535 18
    ADC #&06                               ; @1536 69 06
    STA player_x                           ; @1538 85 16
    LDA player_screen_lo                   ; @153A A5 17
    ADC #&30                               ; @153C 69 30
    STA player_screen_lo                   ; @153E 85 17
    BCC loc_1544                           ; @1540 90 02
    INC player_screen_hi                   ; @1542 E6 18

; ---------------------------------------------------------------------------
loc_1544:
    INC fighter_configuration              ; @1544 E6 19
    BEQ loc_14DE                           ; @1546 F0 96

; ---------------------------------------------------------------------------
loc_1548:
    BPL loc_155A                           ; @1548 10 10
    LDY #&30                               ; @154A A0 30
    JSR test_player_half_collision         ; @154C 20 7D 15
    BCC loc_155A                           ; @154F 90 09
    INC fighter_configuration              ; @1551 E6 19
    LDA player_x                           ; @1553 A5 16
    ADC #&05                               ; @1555 69 05
    JSR explode_player_half                ; @1557 20 5D 15

; ---------------------------------------------------------------------------
loc_155A:
    JMP xor_player_ship                    ; @155A 4C F5 12

; ---------------------------------------------------------------------------
explode_player_half:
    LDY #&08                               ; @155D A0 08
    JSR allocate_explosion                 ; @155F 20 98 18
    LDA #&00                               ; @1562 A9 00
    BCS loc_1569                           ; @1564 B0 03
    STA object_state,Y                     ; @1566 99 66 05

; ---------------------------------------------------------------------------
loc_1569:
    STA sound_gate                         ; @1569 85 79
    JSR flush_keyboard_buffer              ; @156B 20 9B 14
    LDY #&38                               ; @156E A0 38
    JSR envelope_osword8                   ; @1570 20 E9 23
    LDY #&74                               ; @1573 A0 74
    JSR sound_osword7                      ; @1575 20 E0 23
    LDA #&D3                               ; @1578 A9 D3
    STA sound_gate                         ; @157A 85 79

; ---------------------------------------------------------------------------
loc_157C:
    RTS                                    ; @157C 60

; ---------------------------------------------------------------------------
test_player_half_collision:
    TYA                                    ; @157D 98
    PHA                                    ; @157E 48
    JSR screen_collision_probe             ; @157F 20 A2 15
    PLA                                    ; @1582 68
    BCC loc_157C                           ; @1583 90 F7
    LSR A                                  ; @1585 4A
    LSR A                                  ; @1586 4A
    LSR A                                  ; @1587 4A
    ADC player_x                           ; @1588 65 16
    STA collision_left                     ; @158A 85 61
    ADC #&05                               ; @158C 69 05
    STA collision_right                    ; @158E 85 62
    LDA #&08                               ; @1590 A9 08
    STA collision_bottom                   ; @1592 85 64
    LDA #&0E                               ; @1594 A9 0E
    STA collision_top                      ; @1596 85 63
    JSR scan_player_collision_objects      ; @1598 20 85 17
    ASL A                                  ; @159B 0A
    RTS                                    ; @159C 60

; ---------------------------------------------------------------------------
screen_collision_probe_8bytes:
    TXA                                    ; @159D 8A
    LDX #&08                               ; @159E A2 08
    BNE &15A5                              ; @15A0 D0 03

; ---------------------------------------------------------------------------
screen_collision_probe:
    TXA                                    ; @15A2 8A
    LDX #&30                               ; @15A3 A2 30
    SEC                                    ; @15A5 38
    PHA                                    ; @15A6 48
    LDA (screen_lo),Y                      ; @15A7 B1 02
    AND #&55                               ; @15A9 29 55
    BNE loc_15B2                           ; @15AB D0 05
    INY                                    ; @15AD C8
    DEX                                    ; @15AE CA
    BNE &15A7                              ; @15AF D0 F6
    CLC                                    ; @15B1 18

; ---------------------------------------------------------------------------
loc_15B2:
    PLA                                    ; @15B2 68
    TAX                                    ; @15B3 AA
    RTS                                    ; @15B4 60

; ---------------------------------------------------------------------------
loc_15B5:
    JSR read_fire_input                    ; @15B5 20 E4 18
    BNE loc_15BE                           ; @15B8 D0 04
    LDA #&00                               ; @15BA A9 00
    STA fire_latch                         ; @15BC 85 31

; ---------------------------------------------------------------------------
loc_15BE:
    RTS                                    ; @15BE 60

; ---------------------------------------------------------------------------
update_enemy_projectiles:
    LDX #&35                               ; @15BF A2 35
    LDA object_draw_hi,X                   ; @15C1 BD DB 04
    BEQ loc_1628                           ; @15C4 F0 62
    JSR xor_enemy_projectile               ; @15C6 20 3D 16
    LDA object_aux_lo,X                    ; @15C9 BD C6 05
    SEC                                    ; @15CC 38
    SBC object_aux_hi,X                    ; @15CD FD DD 05
    STA object_aux_lo,X                    ; @15D0 9D C6 05
    BCS loc_15F6                           ; @15D3 B0 21
    ADC #&41                               ; @15D5 69 41
    STA object_aux_lo,X                    ; @15D7 9D C6 05
    PHP                                    ; @15DA 08
    LDA object_state,X                     ; @15DB BD 66 05
    BMI loc_15E9                           ; @15DE 30 09
    INC object_x,X                         ; @15E0 FE 00 04
    LDA #&08                               ; @15E3 A9 08
    LDY #&00                               ; @15E5 A0 00
    BEQ loc_15F0                           ; @15E7 F0 07

; ---------------------------------------------------------------------------
loc_15E9:
    DEC object_x,X                         ; @15E9 DE 00 04
    LDA #&F8                               ; @15EC A9 F8
    LDY #&FF                               ; @15EE A0 FF

; ---------------------------------------------------------------------------
loc_15F0:
    JSR offset_projectile_draw_address     ; @15F0 20 2E 16
    PLP                                    ; @15F3 28
    BCC &15C9                              ; @15F4 90 D3

; ---------------------------------------------------------------------------
loc_15F6:
    DEC object_y,X                         ; @15F6 DE 49 04
    DEC object_y,X                         ; @15F9 DE 49 04
    LDA object_draw_lo,X                   ; @15FC BD 24 05
    CLC                                    ; @15FF 18
    ADC #&04                               ; @1600 69 04
    STA object_draw_lo,X                   ; @1602 9D 24 05
    BCC loc_160A                           ; @1605 90 03
    INC object_draw_hi,X                   ; @1607 FE DB 04

; ---------------------------------------------------------------------------
loc_160A:
    AND #&04                               ; @160A 29 04
    BNE loc_1615                           ; @160C D0 07
    LDA #&78                               ; @160E A9 78
    LDY #&02                               ; @1610 A0 02
    JSR offset_projectile_draw_address     ; @1612 20 2E 16

; ---------------------------------------------------------------------------
loc_1615:
    LDA object_y,X                         ; @1615 BD 49 04
    BPL loc_1625                           ; @1618 10 0B
    CMP #&F8                               ; @161A C9 F8
    BCS loc_1625                           ; @161C B0 07
    LDA #&00                               ; @161E A9 00
    STA object_draw_hi,X                   ; @1620 9D DB 04
    BEQ loc_1628                           ; @1623 F0 03

; ---------------------------------------------------------------------------
loc_1625:
    JSR xor_enemy_projectile               ; @1625 20 3D 16

; ---------------------------------------------------------------------------
loc_1628:
    INX                                    ; @1628 E8
    CPX #&3F                               ; @1629 E0 3F
    BCC &15C1                              ; @162B 90 94
    RTS                                    ; @162D 60

; ---------------------------------------------------------------------------
offset_projectile_draw_address:
    CLC                                    ; @162E 18
    ADC object_draw_lo,X                   ; @162F 7D 24 05
    STA object_draw_lo,X                   ; @1632 9D 24 05
    TYA                                    ; @1635 98
    ADC object_draw_hi,X                   ; @1636 7D DB 04
    STA object_draw_hi,X                   ; @1639 9D DB 04
    RTS                                    ; @163C 60

; ---------------------------------------------------------------------------
xor_enemy_projectile:
    LDY #&09                               ; @163D A0 09
    LDA object_draw_hi,X                   ; @163F BD DB 04
    STA screen_hi                          ; @1642 85 03
    CMP #&30                               ; @1644 C9 30
    BCC loc_165B                           ; @1646 90 13
    LDA object_draw_lo,X                   ; @1648 BD 24 05
    STA screen_lo                          ; @164B 85 02
    AND #&04                               ; @164D 29 04
    BNE loc_165C                           ; @164F D0 0B
    LDA (screen_lo),Y                      ; @1651 B1 02
    EOR enemy_projectile_xor_data,Y        ; @1653 59 80 16
    STA (screen_lo),Y                      ; @1656 91 02
    DEY                                    ; @1658 88
    BPL &1651                              ; @1659 10 F6

; ---------------------------------------------------------------------------
loc_165B:
    RTS                                    ; @165B 60

; ---------------------------------------------------------------------------
loc_165C:
    LDA (screen_lo),Y                      ; @165C B1 02
    EOR enemy_projectile_xor_data_alt,Y    ; @165E 59 8A 16
    STA (screen_lo),Y                      ; @1661 91 02
    DEY                                    ; @1663 88
    BPL loc_165C                           ; @1664 10 F6
    LDA screen_lo                          ; @1666 A5 02
    CLC                                    ; @1668 18
    ADC #&7C                               ; @1669 69 7C
    STA screen_lo                          ; @166B 85 02
    LDA screen_hi                          ; @166D A5 03
    ADC #&02                               ; @166F 69 02
    STA screen_hi                          ; @1671 85 03
    LDY #&03                               ; @1673 A0 03
    LDA (screen_lo),Y                      ; @1675 B1 02
    EOR &1684,Y                            ; @1677 59 84 16
    STA (screen_lo),Y                      ; @167A 91 02
    DEY                                    ; @167C 88
    BPL &1675                              ; @167D 10 F6
    RTS                                    ; @167F 60
    ; DATA &1680-&1693
    EQUB &01, &03, &15, &15, &15, &15, &15, &15, &00, &02, &01, &03    ; @1680
    EQUB &15, &15, &00, &00, &00, &00, &00, &02    ; @168C

; ---------------------------------------------------------------------------
loc_1694:
    JMP loc_15B5                           ; @1694 4C B5 15

; ---------------------------------------------------------------------------
; Debounce fire and allocate one of two player-shot records.
service_player_fire:
    JSR update_player_shots                ; @1697 20 E1 16
    LDA player_dead                        ; @169A A5 33
    ORA stage_phase_flag                   ; @169C 05 30
    BMI loc_16B6                           ; @169E 30 16
    LDA fire_latch                         ; @16A0 A5 31
    BMI loc_1694                           ; @16A2 30 F0
    JSR read_fire_input                    ; @16A4 20 E4 18
    BEQ loc_16B6                           ; @16A7 F0 0D
    LDA #&FF                               ; @16A9 A9 FF
    STA fire_latch                         ; @16AB 85 31
    LDX #&01                               ; @16AD A2 01
    LDA &B4,X                              ; @16AF B5 B4
    BEQ loc_16B7                           ; @16B1 F0 04
    DEX                                    ; @16B3 CA
    BPL &16AF                              ; @16B4 10 F9

; ---------------------------------------------------------------------------
loc_16B6:
    RTS                                    ; @16B6 60

; ---------------------------------------------------------------------------
loc_16B7:
    LDA fighter_configuration              ; @16B7 A5 19
    ORA #&7F                               ; @16B9 09 7F
    STA &B4,X                              ; @16BB 95 B4
    LDA player_screen_lo                   ; @16BD A5 17
    SEC                                    ; @16BF 38
    SBC #&70                               ; @16C0 E9 70
    STA &B0,X                              ; @16C2 95 B0
    LDA player_screen_hi                   ; @16C4 A5 18
    SBC #&02                               ; @16C6 E9 02
    STA &B2,X                              ; @16C8 95 B2
    LDA #&0C                               ; @16CA A9 0C
    STA &B8,X                              ; @16CC 95 B8
    LDA player_x                           ; @16CE A5 16
    ADC #&02                               ; @16D0 69 02
    STA &B6,X                              ; @16D2 95 B6
    JSR xor_player_shot                    ; @16D4 20 17 17
    LDY #&64                               ; @16D7 A0 64
    JSR sound_osword7                      ; @16D9 20 E0 23
    LDY #&6C                               ; @16DC A0 6C
    JMP sound_osword7                      ; @16DE 4C E0 23

; ---------------------------------------------------------------------------
update_player_shots:
    LDX #&01                               ; @16E1 A2 01
    LDA &B4,X                              ; @16E3 B5 B4
    BEQ loc_170D                           ; @16E5 F0 26
    JSR xor_player_shot                    ; @16E7 20 17 17
    LDA &B8,X                              ; @16EA B5 B8
    CLC                                    ; @16EC 18
    ADC #&04                               ; @16ED 69 04
    STA &B8,X                              ; @16EF 95 B8
    LDA &B0,X                              ; @16F1 B5 B0
    SBC #&7F                               ; @16F3 E9 7F
    STA &B0,X                              ; @16F5 95 B0
    STA screen_lo                          ; @16F7 85 02
    LDA &B2,X                              ; @16F9 B5 B2
    SBC #&02                               ; @16FB E9 02
    STA &B2,X                              ; @16FD 95 B2
    STA screen_hi                          ; @16FF 85 03
    CMP #&30                               ; @1701 C9 30
    BCC loc_1711                           ; @1703 90 0C
    JSR test_player_shot_collision         ; @1705 20 36 17
    BCS loc_1711                           ; @1708 B0 07
    JSR xor_player_shot                    ; @170A 20 17 17

; ---------------------------------------------------------------------------
loc_170D:
    DEX                                    ; @170D CA
    BPL &16E3                              ; @170E 10 D3
    RTS                                    ; @1710 60

; ---------------------------------------------------------------------------
loc_1711:
    LDA #&00                               ; @1711 A9 00
    STA &B4,X                              ; @1713 95 B4
    BEQ loc_170D                           ; @1715 F0 F6

; ---------------------------------------------------------------------------
xor_player_shot:
    LDA &B0,X                              ; @1717 B5 B0
    STA screen_lo                          ; @1719 85 02
    LDA &B2,X                              ; @171B B5 B2
    STA screen_hi                          ; @171D 85 03
    JSR loc_1729                           ; @171F 20 29 17
    LDA &B4,X                              ; @1722 B5 B4
    BPL loc_1735                           ; @1724 10 0F
    JSR advance_primary_screen_pointer     ; @1726 20 35 13

; ---------------------------------------------------------------------------
loc_1729:
    LDY #&0F                               ; @1729 A0 0F
    LDA (screen_lo),Y                      ; @172B B1 02
    EOR &0761,Y                            ; @172D 59 61 07
    STA (screen_lo),Y                      ; @1730 91 02
    DEY                                    ; @1732 88
    BPL &172B                              ; @1733 10 F6

; ---------------------------------------------------------------------------
loc_1735:
    RTS                                    ; @1735 60

; ---------------------------------------------------------------------------
test_player_shot_collision:
    LDY #&00                               ; @1736 A0 00
    JSR screen_collision_probe_8bytes      ; @1738 20 9D 15
    BCS loc_1748                           ; @173B B0 0B
    BIT fighter_configuration              ; @173D 24 19
    BPL loc_1735                           ; @173F 10 F4
    LDY #&30                               ; @1741 A0 30
    JSR screen_collision_probe_8bytes      ; @1743 20 9D 15
    BCC loc_1735                           ; @1746 90 ED

; ---------------------------------------------------------------------------
loc_1748:
    TXA                                    ; @1748 8A
    PHA                                    ; @1749 48
    LDA &B6,X                              ; @174A B5 B6
    STA collision_left                     ; @174C 85 61
    STA collision_right                    ; @174E 85 62
    LDA &B8,X                              ; @1750 B5 B8
    STA collision_bottom                   ; @1752 85 64
    ADC #&02                               ; @1754 69 02
    STA collision_top                      ; @1756 85 63
    JSR scan_shot_collision_objects        ; @1758 20 8B 17
    BIT fighter_configuration              ; @175B 24 19
    BPL loc_176F                           ; @175D 10 10
    PHA                                    ; @175F 48
    LDA collision_left                     ; @1760 A5 61
    CLC                                    ; @1762 18
    ADC #&06                               ; @1763 69 06
    STA collision_left                     ; @1765 85 61
    STA collision_right                    ; @1767 85 62
    JSR scan_shot_collision_objects        ; @1769 20 8B 17
    PLA                                    ; @176C 68
    ORA collision_result                   ; @176D 05 60

; ---------------------------------------------------------------------------
loc_176F:
    ASL A                                  ; @176F 0A
    PLA                                    ; @1770 68
    TAX                                    ; @1771 AA
    RTS                                    ; @1772 60

; ---------------------------------------------------------------------------
queue_player_name_message:
    LDA #&0E                               ; @1773 A9 0E
    LDY #&10                               ; @1775 A0 10

; ---------------------------------------------------------------------------
loc_1777:
    LDX current_player                     ; @1777 A6 32
    BNE loc_177C                           ; @1779 D0 01
    TAY                                    ; @177B A8

; ---------------------------------------------------------------------------
loc_177C:
    JMP queue_message                      ; @177C 4C 93 20

; ---------------------------------------------------------------------------
queue_player_score_label:
    LDA #&12                               ; @177F A9 12
    LDY #&14                               ; @1781 A0 14
    BNE loc_1777                           ; @1783 D0 F2

; ---------------------------------------------------------------------------
scan_player_collision_objects:
    LDX #&28                               ; @1785 A2 28
    LDY #&3F                               ; @1787 A0 3F
    BNE &178F                              ; @1789 D0 04

; ---------------------------------------------------------------------------
scan_shot_collision_objects:
    LDX #&00                               ; @178B A2 00
    LDY #&35                               ; @178D A0 35
    STY collision_scan_end                 ; @178F 84 7C
    LDA #&00                               ; @1791 A9 00
    STA collision_special                  ; @1793 85 72
    STA collision_result                   ; @1795 85 60
    LDA object_draw_hi,X                   ; @1797 BD DB 04
    BEQ loc_17DB                           ; @179A F0 3F
    CMP #&FF                               ; @179C C9 FF
    BCS loc_17DB                           ; @179E B0 3B
    LDY object_sprite,X                    ; @17A0 BC 92 04
    LDA logical_sprite_descriptors,Y       ; @17A3 B9 52 27
    AND #&FC                               ; @17A6 29 FC
    LSR A                                  ; @17A8 4A
    TAY                                    ; @17A9 A8
    LDA object_y,X                         ; @17AA BD 49 04
    ADC &2780,Y                            ; @17AD 79 80 27
    CMP collision_top                      ; @17B0 C5 63
    BEQ loc_17B6                           ; @17B2 F0 02
    BPL loc_17DB                           ; @17B4 10 25

; ---------------------------------------------------------------------------
loc_17B6:
    STA temp45                             ; @17B6 85 45
    LDA &277F,Y                            ; @17B8 B9 7F 27
    LSR A                                  ; @17BB 4A
    ADC temp45                             ; @17BC 65 45
    CMP collision_bottom                   ; @17BE C5 64
    BEQ loc_17DB                           ; @17C0 F0 19
    BMI loc_17DB                           ; @17C2 30 17
    CLC                                    ; @17C4 18
    LDA object_x,X                         ; @17C5 BD 00 04
    ADC sprite_metadata,Y                  ; @17C8 79 7B 27
    CMP collision_right                    ; @17CB C5 62
    BEQ loc_17D1                           ; @17CD F0 02
    BPL loc_17DB                           ; @17CF 10 0A

; ---------------------------------------------------------------------------
loc_17D1:
    CLC                                    ; @17D1 18
    ADC &277E,Y                            ; @17D2 79 7E 27
    CMP collision_left                     ; @17D5 C5 61
    BEQ loc_17DB                           ; @17D7 F0 02
    BPL loc_1802                           ; @17D9 10 27

; ---------------------------------------------------------------------------
loc_17DB:
    INX                                    ; @17DB E8
    CPX collision_scan_end                 ; @17DC E4 7C
    BCC &1797                              ; @17DE 90 B7
    LDA collision_special                  ; @17E0 A5 72
    BEQ loc_17E7                           ; @17E2 F0 03
    JSR draw_current_player_score          ; @17E4 20 1B 22

; ---------------------------------------------------------------------------
loc_17E7:
    BIT collision_result                   ; @17E7 24 60
    BPL loc_17F5                           ; @17E9 10 0A
    LDY #&54                               ; @17EB A0 54
    JSR sound_osword7                      ; @17ED 20 E0 23
    LDY #&5C                               ; @17F0 A0 5C
    JSR sound_osword7                      ; @17F2 20 E0 23

; ---------------------------------------------------------------------------
loc_17F5:
    LDA collision_result                   ; @17F5 A5 60
    RTS                                    ; @17F7 60

; ---------------------------------------------------------------------------
loc_17F8:
    JSR xor_enemy_projectile               ; @17F8 20 3D 16
    LDA #&00                               ; @17FB A9 00
    STA object_draw_hi,X                   ; @17FD 9D DB 04
    BEQ &1809                              ; @1800 F0 07

; ---------------------------------------------------------------------------
loc_1802:
    CPX #&35                               ; @1802 E0 35
    BCS loc_17F8                           ; @1804 B0 F2
    JSR erase_object                       ; @1806 20 CC 0E
    JSR decode_alien_type                  ; @1809 20 96 1D
    LDA alien_score_metadata,Y             ; @180C B9 93 21
    BPL loc_1839                           ; @180F 10 28
    PHP                                    ; @1811 08
    AND #&7F                               ; @1812 29 7F
    PHA                                    ; @1814 48
    LDA object_sprite,X                    ; @1815 BD 92 04
    SEC                                    ; @1818 38
    SBC alien_sprite_base_table,Y          ; @1819 F9 92 21
    STA indirect_lo                        ; @181C 85 08
    PLA                                    ; @181E 68
    TAY                                    ; @181F A8
    ASL A                                  ; @1820 0A
    PLP                                    ; @1821 28
    ROR A                                  ; @1822 6A
    BVC loc_1827                           ; @1823 50 02
    ORA #&40                               ; @1825 09 40

; ---------------------------------------------------------------------------
loc_1827:
    STA object_type_flags,X                ; @1827 9D AF 05
    LDA alien_sprite_base_table,Y          ; @182A B9 92 21
    ADC indirect_lo                        ; @182D 65 08
    STA object_sprite,X                    ; @182F 9D 92 04
    JSR draw_object                        ; @1832 20 C9 0E
    DEC collision_result                   ; @1835 C6 60
    BMI loc_17DB                           ; @1837 30 A2

; ---------------------------------------------------------------------------
loc_1839:
    TXA                                    ; @1839 8A
    PHA                                    ; @183A 48
    BIT collision_special                  ; @183B 24 72
    BMI loc_1844                           ; @183D 30 05
    JSR draw_current_player_score          ; @183F 20 1B 22
    DEC collision_special                  ; @1842 C6 72

; ---------------------------------------------------------------------------
loc_1844:
    LDA challenge_hits_bcd                 ; @1844 A5 7A
    CLC                                    ; @1846 18
    SED                                    ; @1847 F8
    ADC #&01                               ; @1848 69 01
    STA challenge_hits_bcd                 ; @184A 85 7A
    CLD                                    ; @184C D8
    PLA                                    ; @184D 68
    PHA                                    ; @184E 48
    TAX                                    ; @184F AA
    JSR decode_alien_type                  ; @1850 20 96 1D
    LDA alien_score_metadata,Y             ; @1853 B9 93 21
    BIT challenge_stage                    ; @1856 24 77
    BMI loc_1864                           ; @1858 30 0A
    CPX #&28                               ; @185A E0 28
    BCC loc_1861                           ; @185C 90 03
    JSR score_alien_hit                    ; @185E 20 CE 18

; ---------------------------------------------------------------------------
loc_1861:
    JSR score_alien_hit                    ; @1861 20 CE 18

; ---------------------------------------------------------------------------
loc_1864:
    PLA                                    ; @1864 68
    PHA                                    ; @1865 48
    TAX                                    ; @1866 AA
    LDA object_x,X                         ; @1867 BD 00 04
    LDY object_y,X                         ; @186A BC 49 04
    JSR allocate_explosion                 ; @186D 20 98 18
    LDA object_type_flags,X                ; @1870 BD AF 05
    ASL A                                  ; @1873 0A
    BMI loc_1887                           ; @1874 30 11
    CPX #&35                               ; @1876 E0 35
    BCS loc_1887                           ; @1878 B0 0D
    CPX beam_owner_slot                    ; @187A E4 C5
    BNE loc_1881                           ; @187C D0 03
    JSR force_finish_beam                  ; @187E 20 FC 26

; ---------------------------------------------------------------------------
loc_1881:
    LDX current_player                     ; @1881 A6 32
    DEC player0_aliens_left,X              ; @1883 D6 39
    DEC attack_period                      ; @1885 C6 BA

; ---------------------------------------------------------------------------
loc_1887:
    PLA                                    ; @1887 68
    TAX                                    ; @1888 AA
    DEC collision_result                   ; @1889 C6 60
    CPX #&28                               ; @188B E0 28
    BCC loc_1895                           ; @188D 90 06
    CPX #&35                               ; @188F E0 35
    BCS loc_1895                           ; @1891 B0 02
    DEC active_attacker_count              ; @1893 C6 54

; ---------------------------------------------------------------------------
loc_1895:
    JMP loc_17DB                           ; @1895 4C DB 17

; ---------------------------------------------------------------------------
allocate_explosion:
    STA indirect_lo                        ; @1898 85 08
    TXA                                    ; @189A 8A
    PHA                                    ; @189B 48
    LDX #&3F                               ; @189C A2 3F
    LDA object_draw_hi,X                   ; @189E BD DB 04
    BEQ loc_18AA                           ; @18A1 F0 07
    INX                                    ; @18A3 E8
    CPX #&49                               ; @18A4 E0 49
    BCC &189E                              ; @18A6 90 F6
    BCS loc_18CB                           ; @18A8 B0 21

; ---------------------------------------------------------------------------
loc_18AA:
    LDA indirect_lo                        ; @18AA A5 08
    STA object_x,X                         ; @18AC 9D 00 04
    TYA                                    ; @18AF 98
    STA object_y,X                         ; @18B0 9D 49 04
    LDA #&08                               ; @18B3 A9 08
    STA object_state,X                     ; @18B5 9D 66 05
    LDA #&26                               ; @18B8 A9 26
    STA object_sprite,X                    ; @18BA 9D 92 04
    LDA game_tick                          ; @18BD A5 52
    CLC                                    ; @18BF 18
    ADC #&08                               ; @18C0 69 08
    STA object_last_tick,X                 ; @18C2 9D 45 05
    JSR draw_object                        ; @18C5 20 C9 0E
    TXA                                    ; @18C8 8A
    TAY                                    ; @18C9 A8
    CLC                                    ; @18CA 18

; ---------------------------------------------------------------------------
loc_18CB:
    PLA                                    ; @18CB 68
    TAX                                    ; @18CC AA
    RTS                                    ; @18CD 60

; ---------------------------------------------------------------------------
score_alien_hit:
    JSR add_score_low_only                 ; @18CE 20 DA 12

; ---------------------------------------------------------------------------
award_extra_fighter_on_score_carry:
    BCC loc_18E0                           ; @18D1 90 0D
    PHA                                    ; @18D3 48
    INC player0_fighters,X                 ; @18D4 F6 35
    INC player0_fighters,X                 ; @18D6 F6 35
    JSR refresh_lives_display              ; @18D8 20 A6 24
    LDX current_player                     ; @18DB A6 32
    DEC player0_fighters,X                 ; @18DD D6 35
    PLA                                    ; @18DF 68

; ---------------------------------------------------------------------------
loc_18E0:
    RTS                                    ; @18E0 60

; ---------------------------------------------------------------------------
read_horizontal_input:
    JMP (move_vector_lo)                   ; @18E1 6C 0E 00

; ---------------------------------------------------------------------------
read_fire_input:
    JMP (fire_vector_lo)                   ; @18E4 6C 10 00

; ---------------------------------------------------------------------------
install_input_vectors:
    LDY #&00                               ; @18E7 A0 00
    BIT input_mode                         ; @18E9 24 70
    BPL loc_18F5                           ; @18EB 10 08
    LDY #&04                               ; @18ED A0 04
    LDA current_player                     ; @18EF A5 32
    BEQ loc_18F5                           ; @18F1 F0 02
    LDY #&08                               ; @18F3 A0 08

; ---------------------------------------------------------------------------
loc_18F5:
    LDX #&00                               ; @18F5 A2 00
    LDA input_vector_table,Y               ; @18F7 B9 03 19
    STA move_vector_lo,X                   ; @18FA 95 0E
    INY                                    ; @18FC C8
    INX                                    ; @18FD E8
    CPX #&04                               ; @18FE E0 04
    BNE &18F7                              ; @1900 D0 F5
    RTS                                    ; @1902 60
    ; DATA &1903-&190E
    EQUB &47, &19, &58, &19, &0F, &19, &30, &19, &12, &19, &2D, &19    ; @1903

; ---------------------------------------------------------------------------
joystick_horizontal_1:
    LDA #&01                               ; @190F A9 01
    NOP &03A9,X                            ; @1911 DC A9 03 ; undocumented NOP; operand bytes are deliberate alternate entry
    STX input_temp                         ; @1914 86 14
    TAX                                    ; @1916 AA
    TYA                                    ; @1917 98
    PHA                                    ; @1918 48
    LDA #&80                               ; @1919 A9 80
    JSR &FFF4                              ; @191B 20 F4 FF
    LDX input_temp                         ; @191E A6 14
    CPY #&E0                               ; @1920 C0 E0
    BCC loc_1925                           ; @1922 90 01
    DEX                                    ; @1924 CA

; ---------------------------------------------------------------------------
loc_1925:
    CPY #&20                               ; @1925 C0 20
    BCS loc_192A                           ; @1927 B0 01
    INX                                    ; @1929 E8

; ---------------------------------------------------------------------------
loc_192A:
    PLA                                    ; @192A 68
    TAY                                    ; @192B A8
    RTS                                    ; @192C 60

; ---------------------------------------------------------------------------
joystick_fire_2:
    LDA #&02                               ; @192D A9 02
    NOP &01A9,X                            ; @192F DC A9 01 ; undocumented NOP; operand bytes are deliberate alternate entry
    STA input_temp                         ; @1932 85 14
    STX math_temp80                        ; @1934 86 80
    TYA                                    ; @1936 98
    PHA                                    ; @1937 48
    LDX #&00                               ; @1938 A2 00
    LDA #&80                               ; @193A A9 80
    JSR &FFF4                              ; @193C 20 F4 FF
    PLA                                    ; @193F 68
    TAY                                    ; @1940 A8
    TXA                                    ; @1941 8A
    LDX math_temp80                        ; @1942 A6 80
    AND input_temp                         ; @1944 25 14
    RTS                                    ; @1946 60

; ---------------------------------------------------------------------------
keyboard_horizontal:
    LDA #&BF                               ; @1947 A9 BF
    JSR osbyte_test_key                    ; @1949 20 2E 0E
    BEQ loc_194F                           ; @194C F0 01
    DEX                                    ; @194E CA

; ---------------------------------------------------------------------------
loc_194F:
    LDA #&FE                               ; @194F A9 FE
    JSR osbyte_test_key                    ; @1951 20 2E 0E
    BEQ loc_1957                           ; @1954 F0 01
    INX                                    ; @1956 E8

; ---------------------------------------------------------------------------
loc_1957:
    RTS                                    ; @1957 60

; ---------------------------------------------------------------------------
keyboard_fire:
    LDA #&B6                               ; @1958 A9 B6
    JMP osbyte_test_key                    ; @195A 4C 2E 0E

; ---------------------------------------------------------------------------
; Attempt normal Queen group attack or branch to special tractor-beam Queen.

; ----------------------------------------------------------------------------
; FLATTENED MODULE: 03_attacks_stages_objects.asm
; ----------------------------------------------------------------------------
; ZALAGA V10 - Attack selection, Queen logic, stages, deployment, object state machine and trajectories
; Sequential module included by ../zalaga.asm.

try_queen_group_attack:
    LDX #&03                               ; @195D A2 03
    LDA #&00                               ; @195F A9 00
    ORA &04E7,X                            ; @1961 1D E7 04
    DEX                                    ; @1964 CA
    BPL &1961                              ; @1965 10 FA
    TAX                                    ; @1967 AA
    BNE loc_1970                           ; @1968 D0 06
    JSR random_timer_byte                  ; @196A 20 97 0E
    JMP loc_1A0D                           ; @196D 4C 0D 1A

; ---------------------------------------------------------------------------
loc_1970:
    JSR random_timer_byte                  ; @1970 20 97 0E
    AND #&03                               ; @1973 29 03
    TAY                                    ; @1975 A8
    ORA #&0C                               ; @1976 09 0C
    TAX                                    ; @1978 AA
    LDA object_draw_hi,X                   ; @1979 BD DB 04
    BEQ loc_1970                           ; @197C F0 F2
    TYA                                    ; @197E 98
    PHA                                    ; @197F 48
    JSR find_free_attack_slot              ; @1980 20 B9 1A
    BCC &198E                              ; @1983 90 09
    PLA                                    ; @1985 68
    RTS                                    ; @1986 60

; ---------------------------------------------------------------------------
loc_1987:
    JSR set_queen_normal_attack_state      ; @1987 20 C7 1A
    TXA                                    ; @198A 8A
    AND #&03                               ; @198B 29 03
    PHA                                    ; @198D 48
    LDA object_type_flags,X                ; @198E BD AF 05
    STA object_type_flags,Y                ; @1991 99 AF 05
    JSR transfer_formation_to_attack_slot  ; @1994 20 4E 1A
    PLA                                    ; @1997 68
    STA queen_table_index                  ; @1998 85 7E
    ASL A                                  ; @199A 0A
    ADC queen_table_index                  ; @199B 65 7E
    STA queen_table_index                  ; @199D 85 7E
    LDA beam_owner_slot                    ; @199F A5 C5
    BPL loc_19AF                           ; @19A1 10 0C
    JSR random_timer_byte                  ; @19A3 20 97 0E
    AND #&03                               ; @19A6 29 03
    ORA fighter_configuration              ; @19A8 05 19
    BNE loc_19AF                           ; @19AA D0 03
    JMP select_special_queen_attack        ; @19AC 4C 02 27

; ---------------------------------------------------------------------------
loc_19AF:
    LDA #&02                               ; @19AF A9 02
    STA queen_escorts_left                 ; @19B1 85 7D
    STA queen_candidates_left              ; @19B3 85 7F
    LDA object_type_flags,X                ; @19B5 BD AF 05
    ASL A                                  ; @19B8 0A
    PHP                                    ; @19B9 08
    LDX queen_table_index                  ; @19BA A6 7E
    LDA queen_drome_escort_table,X         ; @19BC BD CD 1A
    TAX                                    ; @19BF AA
    LDA object_draw_hi,X                   ; @19C0 BD DB 04
    BEQ loc_19DB                           ; @19C3 F0 16
    JSR find_free_attack_slot              ; @19C5 20 B9 1A
    BCS loc_19E1                           ; @19C8 B0 17
    JSR transfer_formation_to_attack_slot  ; @19CA 20 4E 1A
    LDA object_type_flags,X                ; @19CD BD AF 05
    ASL A                                  ; @19D0 0A
    PLP                                    ; @19D1 28
    PHP                                    ; @19D2 08
    ROR A                                  ; @19D3 6A
    STA object_type_flags,X                ; @19D4 9D AF 05
    DEC queen_escorts_left                 ; @19D7 C6 7D
    BEQ loc_19E1                           ; @19D9 F0 06

; ---------------------------------------------------------------------------
loc_19DB:
    INC queen_table_index                  ; @19DB E6 7E
    DEC queen_candidates_left              ; @19DD C6 7F
    BPL &19BA                              ; @19DF 10 D9

; ---------------------------------------------------------------------------
loc_19E1:
    PLP                                    ; @19E1 28
    RTS                                    ; @19E2 60

; ---------------------------------------------------------------------------
; Stage-cadenced attack allocator; falls back to ordinary alien selection.
try_launch_attack:
    BIT player_dead                        ; @19E3 24 33
    BMI loc_1A02                           ; @19E5 30 1B
    LDA game_tick                          ; @19E7 A5 52
    SEC                                    ; @19E9 38
    SBC attack_period                      ; @19EA E5 BA
    BCS &19EA                              ; @19EC B0 FC
    ADC attack_period                      ; @19EE 65 BA
    BNE loc_1A02                           ; @19F0 D0 10
    LDY #&28                               ; @19F2 A0 28
    LDA object_draw_hi,Y                   ; @19F4 B9 DB 04
    BEQ loc_1A03                           ; @19F7 F0 0A
    INY                                    ; @19F9 C8
    CPY #&35                               ; @19FA C0 35
    BCS loc_1A02                           ; @19FC B0 04
    CPY attack_slot_limit                  ; @19FE C4 BB
    BCC &19F4                              ; @1A00 90 F2

; ---------------------------------------------------------------------------
loc_1A02:
    RTS                                    ; @1A02 60

; ---------------------------------------------------------------------------
loc_1A03:
    JSR random_timer_byte                  ; @1A03 20 97 0E
    BIT mask_7_constant                    ; @1A06 24 49
    BNE loc_1A0D                           ; @1A08 D0 03
    JMP try_queen_group_attack             ; @1A0A 4C 5D 19

; ---------------------------------------------------------------------------
loc_1A0D:
    STA indirect_lo                        ; @1A0D 85 08
    LDA #&0C                               ; @1A0F A9 0C
    STA object_state,Y                     ; @1A11 99 66 05
    LDX #&FF                               ; @1A14 A2 FF
    STX temp15                             ; @1A16 86 15
    INX                                    ; @1A18 E8
    LDA object_draw_hi,X                   ; @1A19 BD DB 04
    BEQ loc_1A35                           ; @1A1C F0 17
    BIT temp15                             ; @1A1E 24 15
    BMI loc_1A2E                           ; @1A20 30 0C
    LDA object_x,X                         ; @1A22 BD 00 04
    SEC                                    ; @1A25 38
    SBC input_temp                         ; @1A26 E5 14
    BEQ loc_1AA5                           ; @1A28 F0 7B
    EOR indirect_lo                        ; @1A2A 45 08
    BMI loc_1A35                           ; @1A2C 30 07

; ---------------------------------------------------------------------------
loc_1A2E:
    LDA object_x,X                         ; @1A2E BD 00 04
    STA input_temp                         ; @1A31 85 14
    STX temp15                             ; @1A33 86 15

; ---------------------------------------------------------------------------
loc_1A35:
    INX                                    ; @1A35 E8
    CPX #&28                               ; @1A36 E0 28
    BCC &1A19                              ; @1A38 90 DF
    LDX temp15                             ; @1A3A A6 15
    BMI loc_1A02                           ; @1A3C 30 C4
    LDA object_type_flags,X                ; @1A3E BD AF 05
    STA object_type_flags,Y                ; @1A41 99 AF 05
    LDA object_sprite,X                    ; @1A44 BD 92 04
    CMP #&18                               ; @1A47 C9 18
    BCC transfer_formation_to_attack_slot  ; @1A49 90 03
    JMP loc_1987                           ; @1A4B 4C 87 19

; ---------------------------------------------------------------------------
transfer_formation_to_attack_slot:
    TYA                                    ; @1A4E 98
    PHA                                    ; @1A4F 48
    JSR erase_object                       ; @1A50 20 CC 0E
    PLA                                    ; @1A53 68
    TAY                                    ; @1A54 A8
    LDA object_y,X                         ; @1A55 BD 49 04
    STA object_y,Y                         ; @1A58 99 49 04
    LDA object_sprite,X                    ; @1A5B BD 92 04
    STA object_sprite,Y                    ; @1A5E 99 92 04
    LDA game_tick                          ; @1A61 A5 52
    STA object_last_tick,Y                 ; @1A63 99 45 05
    CLC                                    ; @1A66 18
    ADC #&19                               ; @1A67 69 19
    STA object_next_tick,Y                 ; @1A69 99 0E 06
    LDA object_x,X                         ; @1A6C BD 00 04
    STA object_x,Y                         ; @1A6F 99 00 04
    LDA formation_x_index,X                ; @1A72 BD 43 06
    SEC                                    ; @1A75 38
    SBC #&05                               ; @1A76 E9 05
    AND #&80                               ; @1A78 29 80
    EOR #&80                               ; @1A7A 49 80
    ORA object_type_flags,X                ; @1A7C 1D AF 05
    STA object_type_flags,Y                ; @1A7F 99 AF 05
    TXA                                    ; @1A82 8A
    STA object_home_slot,Y                 ; @1A83 99 01 06
    TYA                                    ; @1A86 98
    TAX                                    ; @1A87 AA
    INC active_attacker_count              ; @1A88 E6 54
    LDY #&7C                               ; @1A8A A0 7C
    JSR sound_osword7                      ; @1A8C 20 E0 23
    LDY #&00                               ; @1A8F A0 00

; ---------------------------------------------------------------------------
install_attack_path:
    LDA &1AAD,Y                            ; @1A91 B9 AD 1A
    STA object_aux_lo,X                    ; @1A94 9D C6 05
    LDA &1AAE,Y                            ; @1A97 B9 AE 1A
    STA object_aux_hi,X                    ; @1A9A 9D DD 05
    LDA #&FF                               ; @1A9D A9 FF
    STA object_repeat,X                    ; @1A9F 9D F4 05
    JMP draw_object                        ; @1AA2 4C C9 0E

; ---------------------------------------------------------------------------
loc_1AA5:
    JSR random_timer_byte                  ; @1AA5 20 97 0E
    LSR A                                  ; @1AA8 4A
    BCC loc_1A35                           ; @1AA9 90 8A
    BCS &1A33                              ; @1AAB B0 86
    CPX &6207                              ; @1AAD EC 07 62
    SLO (entry_delay,X)                    ; @1AB0 03 65
    ORA (formation_scan_slot,X)            ; @1AB2 01 4E
    ORA (&A2,X)                            ; @1AB4 01 A2
    ORA (&AA,X)                            ; @1AB6 01 AA
    ORA (player_screen_hi,X)               ; @1AB8 01 18
    LDY #&28                               ; @1ABA A0 28
    LDA object_draw_hi,Y                   ; @1ABC B9 DB 04
    BEQ set_queen_normal_attack_state      ; @1ABF F0 06
    INY                                    ; @1AC1 C8
    CPY #&35                               ; @1AC2 C0 35
    BCC &1ABC                              ; @1AC4 90 F6
    RTS                                    ; @1AC6 60

; ---------------------------------------------------------------------------
set_queen_normal_attack_state:
    LDA #&13                               ; @1AC7 A9 13
    STA object_state,Y                     ; @1AC9 99 66 05
    RTS                                    ; @1ACC 60
    ; DATA &1ACD-&1AD8
    EQUB &08, &04, &05, &09, &05, &04, &10, &08, &04, &14, &09, &05    ; @1ACD

; ---------------------------------------------------------------------------
dispatch_stage_state:
    JMP (stage_handler_lo)                 ; @1AD9 6C 12 00
    ; DATA &1ADC-&1AE5
    EQUB &E7, &1A, &06, &1B, &85, &1B, &70, &1C, &D1, &1B    ; @1ADC

; ---------------------------------------------------------------------------
loc_1AE6:
    RTS                                    ; @1AE6 60

; ---------------------------------------------------------------------------
stage_intro:
    LDX current_player                     ; @1AE7 A6 32
    LDA #&64                               ; @1AE9 A9 64
    STA turn_delay                         ; @1AEB 85 4D
    LDA #&FF                               ; @1AED A9 FF
    STA stage_phase_flag                   ; @1AEF 85 30
    LDY #&02                               ; @1AF1 A0 02
    JSR set_stage_handler                  ; @1AF3 20 C6 1B
    LDY #&00                               ; @1AF6 A0 00
    JSR queue_message                      ; @1AF8 20 93 20
    JSR queue_player_score_label           ; @1AFB 20 7F 17
    JSR queue_player_name_message          ; @1AFE 20 73 17
    LDY #&00                               ; @1B01 A0 00
    JMP start_music                        ; @1B03 4C 32 24

; ---------------------------------------------------------------------------
; Classify challenge/cycle stage and derive simultaneous attacker/shot limits.
stage_setup:
    DEC turn_delay                         ; @1B06 C6 4D
    BNE loc_1AE6                           ; @1B08 D0 DC
    LDX #&00                               ; @1B0A A2 00
    STX stage_phase_flag                   ; @1B0C 86 30
    STX challenge_stage                    ; @1B0E 86 77
    STX cycle_opening_stage                ; @1B10 86 8B
    LDA #&64                               ; @1B12 A9 64
    STA turn_delay                         ; @1B14 85 4D
    JSR display_pending_messages           ; @1B16 20 7B 20
    LDA #&09                               ; @1B19 A9 09
    JSR divide_current_stage               ; @1B1B 20 2E 1C
    CMP #&01                               ; @1B1E C9 01
    BNE loc_1B24                           ; @1B20 D0 02
    DEC cycle_opening_stage                ; @1B22 C6 8B

; ---------------------------------------------------------------------------
loc_1B24:
    LDA #&32                               ; @1B24 A9 32
    STA attack_period                      ; @1B26 85 BA
    LDA #&04                               ; @1B28 A9 04
    JSR divide_current_stage               ; @1B2A 20 2E 1C
    CMP #&03                               ; @1B2D C9 03
    BNE loc_1B59                           ; @1B2F D0 28
    STX bcd_work0                          ; @1B31 86 3D
    STY bcd_work1                          ; @1B33 84 3E
    LDY #&00                               ; @1B35 A0 00
    LDA #&04                               ; @1B37 A9 04
    JSR bcd_divide                         ; @1B39 20 3C 1C
    ASL A                                  ; @1B3C 0A
    ADC #&03                               ; @1B3D 69 03
    JSR set_player_entry_selector          ; @1B3F 20 1C 21
    DEC challenge_stage                    ; @1B42 C6 77
    LDA &2188,Y                            ; @1B44 B9 88 21
    STA challenge_alien_type               ; @1B47 85 78
    LDA #&00                               ; @1B49 A9 00
    STA challenge_hits_bcd                 ; @1B4B 85 7A
    LDA #&08                               ; @1B4D A9 08
    STA moving_object_count                ; @1B4F 85 58
    LDY #&08                               ; @1B51 A0 08
    JSR queue_message                      ; @1B53 20 93 20
    JMP loc_1B7D                           ; @1B56 4C 7D 1B

; ---------------------------------------------------------------------------
loc_1B59:
    PHA                                    ; @1B59 48
    TXA                                    ; @1B5A 8A
    ADC #&39                               ; @1B5B 69 39
    STA enemy_shot_slot_limit              ; @1B5D 85 8A
    TXA                                    ; @1B5F 8A
    ADC #&2A                               ; @1B60 69 2A
    STA attack_slot_limit                  ; @1B62 85 BB
    LDA #&08                               ; @1B64 A9 08
    BIT cycle_opening_stage                ; @1B66 24 8B
    BMI loc_1B74                           ; @1B68 30 0A
    DEX                                    ; @1B6A CA
    BMI loc_1B74                           ; @1B6B 30 07
    LDA #&0A                               ; @1B6D A9 0A
    DEX                                    ; @1B6F CA
    BMI loc_1B74                           ; @1B70 30 02
    LDA #&0C                               ; @1B72 A9 0C

; ---------------------------------------------------------------------------
loc_1B74:
    STA moving_object_count                ; @1B74 85 58
    PLA                                    ; @1B76 68
    JSR set_player_entry_selector          ; @1B77 20 1C 21
    JSR prepare_stage_display              ; @1B7A 20 83 23

; ---------------------------------------------------------------------------
loc_1B7D:
    JSR queue_player_score_label           ; @1B7D 20 7F 17
    LDY #&04                               ; @1B80 A0 04
    JMP set_stage_handler                  ; @1B82 4C C6 1B

; ---------------------------------------------------------------------------
formation_init:
    DEC turn_delay                         ; @1B85 C6 4D
    BNE loc_1BD0                           ; @1B87 D0 47
    JSR display_pending_messages           ; @1B89 20 7B 20
    JSR queue_player_score_label           ; @1B8C 20 7F 17
    LDX #&27                               ; @1B8F A2 27
    LDA #&00                               ; @1B91 A9 00
    STA object_draw_hi,X                   ; @1B93 9D DB 04
    LDY formation_x_index,X                ; @1B96 BC 43 06
    LDA formation_x_positions,Y            ; @1B99 B9 9D 06
    STA object_x,X                         ; @1B9C 9D 00 04
    LDY formation_y_index,X                ; @1B9F BC 6B 06
    LDA formation_y_positions,Y            ; @1BA2 B9 A7 06
    STA object_y,X                         ; @1BA5 9D 49 04
    DEX                                    ; @1BA8 CA
    BPL &1B91                              ; @1BA9 10 E6
    INX                                    ; @1BAB E8
    STX formation_scan_slot                ; @1BAC 86 4E
    STX formation_direction                ; @1BAE 86 50
    STX active_attacker_count              ; @1BB0 86 54
    LDA #&80                               ; @1BB2 A9 80
    STA formation_phase_mask               ; @1BB4 85 4F
    LDA #&07                               ; @1BB6 A9 07
    STA formation_sweep_countdown          ; @1BB8 85 51
    LDX current_player                     ; @1BBA A6 32
    LDA #&F8                               ; @1BBC A9 F8
    STA &56,X                              ; @1BBE 95 56
    LDA #&28                               ; @1BC0 A9 28
    STA player0_aliens_left,X              ; @1BC2 95 39
    LDY #&06                               ; @1BC4 A0 06

; ---------------------------------------------------------------------------
set_stage_handler:
    LDA stage_handler_table,Y              ; @1BC6 B9 DC 1A
    STA stage_handler_lo                   ; @1BC9 85 12
    LDA &1ADD,Y                            ; @1BCB B9 DD 1A
    STA stage_handler_hi                   ; @1BCE 85 13

; ---------------------------------------------------------------------------
loc_1BD0:
    RTS                                    ; @1BD0 60

; ---------------------------------------------------------------------------
; Formation wobble, attack launch, moving-object service and stage completion.
active_stage:
    JSR update_formation_motion            ; @1BD1 20 D2 11
    JSR try_launch_attack                  ; @1BD4 20 E3 19
    JSR service_moving_objects             ; @1BD7 20 A5 1D
    LDX current_player                     ; @1BDA A6 32
    LDA player0_aliens_left,X              ; @1BDC B5 39
    BNE loc_1BD0                           ; @1BDE D0 F0
    BIT challenge_stage                    ; @1BE0 24 77
    BPL loc_1C14                           ; @1BE2 10 30
    JSR prepare_challenge_hits_display     ; @1BE4 20 48 23
    JSR prepare_challenge_bonus_display    ; @1BE7 20 5C 23
    LDA #&00                               ; @1BEA A9 00
    STA math_temp76                        ; @1BEC 85 76
    LDA challenge_hits_bcd                 ; @1BEE A5 7A
    BEQ loc_1C14                           ; @1BF0 F0 22
    JSR draw_current_player_score          ; @1BF2 20 1B 22
    LDA challenge_hits_bcd                 ; @1BF5 A5 7A
    LDX #&03                               ; @1BF7 A2 03
    CMP #&40                               ; @1BF9 C9 40
    BNE loc_1C03                           ; @1BFB D0 06
    LDY #&10                               ; @1BFD A0 10
    LDA #&00                               ; @1BFF A9 00
    BEQ loc_1C0B                           ; @1C01 F0 08

; ---------------------------------------------------------------------------
loc_1C03:
    ASL A                                  ; @1C03 0A
    ROL math_temp76                        ; @1C04 26 76
    DEX                                    ; @1C06 CA
    BPL loc_1C03                           ; @1C07 10 FA
    LDY math_temp76                        ; @1C09 A4 76

; ---------------------------------------------------------------------------
loc_1C0B:
    JSR add_score_bcd                      ; @1C0B 20 DC 12
    JSR award_extra_fighter_on_score_carry ; @1C0E 20 D1 18
    JSR draw_current_player_score          ; @1C11 20 1B 22

; ---------------------------------------------------------------------------
loc_1C14:
    LDX current_player                     ; @1C14 A6 32
    LDA #&01                               ; @1C16 A9 01
    CLC                                    ; @1C18 18
    SED                                    ; @1C19 F8
    ADC player0_stage_lo,X                 ; @1C1A 75 37
    STA player0_stage_lo,X                 ; @1C1C 95 37
    LDA player0_stage_hi,X                 ; @1C1E B5 25
    ADC #&00                               ; @1C20 69 00
    STA player0_stage_hi,X                 ; @1C22 95 25
    CLD                                    ; @1C24 D8
    LDA #&64                               ; @1C25 A9 64
    STA turn_delay                         ; @1C27 85 4D
    LDY #&02                               ; @1C29 A0 02
    JMP set_stage_handler                  ; @1C2B 4C C6 1B

; ---------------------------------------------------------------------------
divide_current_stage:
    LDX current_player                     ; @1C2E A6 32
    LDY player0_stage_lo,X                 ; @1C30 B4 37
    STY bcd_work0                          ; @1C32 84 3D
    LDY player0_stage_hi,X                 ; @1C34 B4 25
    STY bcd_work1                          ; @1C36 84 3E
    LDY #&00                               ; @1C38 A0 00
    STY bcd_work2                          ; @1C3A 84 3F

; ---------------------------------------------------------------------------
; Packed-BCD repeated-subtraction divide used for stage MOD/division tests.
bcd_divide:
    SED                                    ; @1C3C F8
    STA math_temp76                        ; @1C3D 85 76
    STY math_temp80                        ; @1C3F 84 80
    LDY #&00                               ; @1C41 A0 00
    LDX #&00                               ; @1C43 A2 00
    SEC                                    ; @1C45 38
    LDA bcd_work0                          ; @1C46 A5 3D
    SBC math_temp76                        ; @1C48 E5 76
    PHA                                    ; @1C4A 48
    LDA bcd_work1                          ; @1C4B A5 3E
    SBC math_temp80                        ; @1C4D E5 80
    PHA                                    ; @1C4F 48
    LDA bcd_work2                          ; @1C50 A5 3F
    SBC #&00                               ; @1C52 E9 00
    BCC loc_1C69                           ; @1C54 90 13
    STA bcd_work2                          ; @1C56 85 3F
    PLA                                    ; @1C58 68
    STA bcd_work1                          ; @1C59 85 3E
    PLA                                    ; @1C5B 68
    STA bcd_work0                          ; @1C5C 85 3D
    TXA                                    ; @1C5E 8A
    ADC #&00                               ; @1C5F 69 00
    TAX                                    ; @1C61 AA
    TYA                                    ; @1C62 98
    ADC #&00                               ; @1C63 69 00
    TAY                                    ; @1C65 A8
    JMP &1C45                              ; @1C66 4C 45 1C

; ---------------------------------------------------------------------------
loc_1C69:
    PLA                                    ; @1C69 68
    PLA                                    ; @1C6A 68
    LDA bcd_work0                          ; @1C6B A5 3D
    CLD                                    ; @1C6D D8
    RTS                                    ; @1C6E 60

; ---------------------------------------------------------------------------
loc_1C6F:
    RTS                                    ; @1C6F 60

; ---------------------------------------------------------------------------
deployment_controller:
    JSR update_one_formation_slot          ; @1C70 20 D5 11
    LDA active_attacker_count              ; @1C73 A5 54
    BEQ loc_1C7A                           ; @1C75 F0 03
    JMP service_moving_objects             ; @1C77 4C A5 1D

; ---------------------------------------------------------------------------
loc_1C7A:
    BIT player_dead                        ; @1C7A 24 33
    BMI loc_1C6F                           ; @1C7C 30 F1
    LDX current_player                     ; @1C7E A6 32
    LDA &56,X                              ; @1C80 B5 56
    CLC                                    ; @1C82 18
    ADC #&08                               ; @1C83 69 08
    STA &56,X                              ; @1C85 95 56
    CMP #&28                               ; @1C87 C9 28
    BCC loc_1C94                           ; @1C89 90 09
    LDA #&00                               ; @1C8B A9 00
    STA cycle_opening_stage                ; @1C8D 85 8B
    LDY #&08                               ; @1C8F A0 08
    JMP set_stage_handler                  ; @1C91 4C C6 1B

; ---------------------------------------------------------------------------
loc_1C94:
    STA temp45                             ; @1C94 85 45
    STA temp46                             ; @1C96 85 46
    LDA #&28                               ; @1C98 A9 28
    STA temp47                             ; @1C9A 85 47
    STA moving_object_scan_slot            ; @1C9C 85 55
    LDA #&14                               ; @1C9E A9 14
    STA entry_delay                        ; @1CA0 85 65
    LDX current_player                     ; @1CA2 A6 32
    LDY player0_entry_selector,X           ; @1CA4 B4 74
    INC player0_entry_selector,X           ; @1CA6 F6 74
    LDX #&08                               ; @1CA8 A2 08
    LDA &2159,Y                            ; @1CAA B9 59 21
    PHP                                    ; @1CAD 08
    BMI loc_1CB2                           ; @1CAE 30 02
    LDX #&10                               ; @1CB0 A2 10

; ---------------------------------------------------------------------------
loc_1CB2:
    STX entry_spacing                      ; @1CB2 86 68
    AND #&7F                               ; @1CB4 29 7F
    TAY                                    ; @1CB6 A8
    JSR decode_entry_descriptor            ; @1CB7 20 FE 20
    LDY #&00                               ; @1CBA A0 00
    LDA (path_ptr_lo),Y                    ; @1CBC B1 66
    LDX path_mirror                        ; @1CBE A6 73
    BEQ loc_1CC7                           ; @1CC0 F0 05
    LDA #&4C                               ; @1CC2 A9 4C
    SEC                                    ; @1CC4 38
    SBC (path_ptr_lo),Y                    ; @1CC5 F1 66

; ---------------------------------------------------------------------------
loc_1CC7:
    STA collision_left                     ; @1CC7 85 61
    INY                                    ; @1CC9 C8
    LDA (path_ptr_lo),Y                    ; @1CCA B1 66
    STA collision_bottom                   ; @1CCC 85 64
    LDX temp47                             ; @1CCE A6 47
    LDA collision_left                     ; @1CD0 A5 61
    STA object_x,X                         ; @1CD2 9D 00 04
    LDA collision_bottom                   ; @1CD5 A5 64
    STA object_y,X                         ; @1CD7 9D 49 04
    CLC                                    ; @1CDA 18
    LDA game_tick                          ; @1CDB A5 52
    ADC entry_delay                        ; @1CDD 65 65
    STA object_last_tick,X                 ; @1CDF 9D 45 05
    JSR random_timer_byte                  ; @1CE2 20 97 0E
    AND #&03                               ; @1CE5 29 03
    ADC collision_top                      ; @1CE7 65 63
    ADC game_tick                          ; @1CE9 65 52
    ADC entry_delay                        ; @1CEB 65 65
    STA object_next_tick,X                 ; @1CED 9D 0E 06
    LDA #&FF                               ; @1CF0 A9 FF
    STA object_draw_hi,X                   ; @1CF2 9D DB 04
    STA object_repeat,X                    ; @1CF5 9D F4 05
    LDA path_ptr_lo                        ; @1CF8 A5 66
    CLC                                    ; @1CFA 18
    ADC #&01                               ; @1CFB 69 01
    STA object_aux_lo,X                    ; @1CFD 9D C6 05
    LDA #&00                               ; @1D00 A9 00
    ADC path_ptr_hi                        ; @1D02 65 67
    STA object_aux_hi,X                    ; @1D04 9D DD 05
    LDA temp45                             ; @1D07 A5 45
    SEC                                    ; @1D09 38
    SBC temp46                             ; @1D0A E5 46
    CMP #&04                               ; @1D0C C9 04
    PHP                                    ; @1D0E 08
    LDA temp46                             ; @1D0F A5 46
    LSR A                                  ; @1D11 4A
    LSR A                                  ; @1D12 4A
    TAY                                    ; @1D13 A8
    LDA formation_type_by_group,Y          ; @1D14 B9 93 06
    CMP #&04                               ; @1D17 C9 04
    BEQ loc_1D21                           ; @1D19 F0 06
    BIT challenge_stage                    ; @1D1B 24 77
    BPL loc_1D21                           ; @1D1D 10 02
    LDA challenge_alien_type               ; @1D1F A5 78

; ---------------------------------------------------------------------------
loc_1D21:
    ORA path_mirror                        ; @1D21 05 73
    PLP                                    ; @1D23 28
    PHP                                    ; @1D24 08
    BCC loc_1D29                           ; @1D25 90 02
    ORA #&40                               ; @1D27 09 40

; ---------------------------------------------------------------------------
loc_1D29:
    STA object_type_flags,X                ; @1D29 9D AF 05
    LDY #&02                               ; @1D2C A0 02
    LDA (path_ptr_lo),Y                    ; @1D2E B1 66
    AND #&1F                               ; @1D30 29 1F
    TAY                                    ; @1D32 A8
    LDA movement_anim,Y                    ; @1D33 B9 48 07
    JSR decode_alien_type                  ; @1D36 20 96 1D
    CLC                                    ; @1D39 18
    ADC alien_sprite_base_table,Y          ; @1D3A 79 92 21
    STA object_sprite,X                    ; @1D3D 9D 92 04
    LDA #&09                               ; @1D40 A9 09
    PLP                                    ; @1D42 28
    BIT challenge_stage                    ; @1D43 24 77
    BMI loc_1D4D                           ; @1D45 30 06
    LDA #&00                               ; @1D47 A9 00
    BCC loc_1D4D                           ; @1D49 90 02
    LDA #&04                               ; @1D4B A9 04

; ---------------------------------------------------------------------------
loc_1D4D:
    STA object_state,X                     ; @1D4D 9D 66 05
    LDA temp45                             ; @1D50 A5 45
    STA object_home_slot,X                 ; @1D52 9D 01 06
    INC temp45                             ; @1D55 E6 45
    INC temp47                             ; @1D57 E6 47
    LDA entry_delay                        ; @1D59 A5 65
    CLC                                    ; @1D5B 18
    ADC entry_spacing                      ; @1D5C 65 68
    STA entry_delay                        ; @1D5E 85 65
    LDA temp47                             ; @1D60 A5 47
    SEC                                    ; @1D62 38
    SBC #&28                               ; @1D63 E9 28
    CMP moving_object_count                ; @1D65 C5 58
    BCS loc_1D90                           ; @1D67 B0 27
    LDA temp45                             ; @1D69 A5 45
    SEC                                    ; @1D6B 38
    SBC temp46                             ; @1D6C E5 46
    ASL A                                  ; @1D6E 0A
    CMP moving_object_count                ; @1D6F C5 58
    BCC loc_1D8D                           ; @1D71 90 1A
    LDX current_player                     ; @1D73 A6 32
    LDA &56,X                              ; @1D75 B5 56
    ADC #&03                               ; @1D77 69 03
    STA temp45                             ; @1D79 85 45
    STA temp46                             ; @1D7B 85 46
    LDA #&1C                               ; @1D7D A9 1C
    STA entry_delay                        ; @1D7F 85 65
    PLP                                    ; @1D81 28
    PHP                                    ; @1D82 08
    BPL loc_1D8D                           ; @1D83 10 08
    LDA #&14                               ; @1D85 A9 14
    STA entry_delay                        ; @1D87 85 65
    PLP                                    ; @1D89 28
    JMP &1CA2                              ; @1D8A 4C A2 1C

; ---------------------------------------------------------------------------
loc_1D8D:
    JMP &1CCE                              ; @1D8D 4C CE 1C

; ---------------------------------------------------------------------------
loc_1D90:
    LDA moving_object_count                ; @1D90 A5 58
    STA active_attacker_count              ; @1D92 85 54
    PLP                                    ; @1D94 28
    RTS                                    ; @1D95 60

; ---------------------------------------------------------------------------
decode_alien_type:
    PHA                                    ; @1D96 48
    LDA object_type_flags,X                ; @1D97 BD AF 05
    STA math_temp76                        ; @1D9A 85 76
    CMP #&80                               ; @1D9C C9 80
    AND #&1F                               ; @1D9E 29 1F
    TAY                                    ; @1DA0 A8
    BIT math_temp76                        ; @1DA1 24 76
    PLA                                    ; @1DA3 68
    RTS                                    ; @1DA4 60

; ---------------------------------------------------------------------------
service_moving_objects:
    LDY moving_object_scan_slot            ; @1DA5 A4 55
    STY moving_object_scan_start           ; @1DA7 84 59
    JSR dispatch_object_state              ; @1DA9 20 C7 1D
    INC moving_object_scan_slot            ; @1DAC E6 55
    LDA moving_object_count                ; @1DAE A5 58
    CLC                                    ; @1DB0 18
    ADC #&28                               ; @1DB1 69 28
    CMP moving_object_scan_slot            ; @1DB3 C5 55
    BCS loc_1DBB                           ; @1DB5 B0 04
    LDA #&28                               ; @1DB7 A9 28
    STA moving_object_scan_slot            ; @1DB9 85 55

; ---------------------------------------------------------------------------
loc_1DBB:
    LDY moving_object_scan_slot            ; @1DBB A4 55
    CPY moving_object_scan_start           ; @1DBD C4 59
    BEQ loc_1DC6                           ; @1DBF F0 05
    JSR read_game_tick                     ; @1DC1 20 11 0E
    BEQ &1DA9                              ; @1DC4 F0 E3

; ---------------------------------------------------------------------------
loc_1DC6:
    RTS                                    ; @1DC6 60

; ---------------------------------------------------------------------------
; Indirect state-machine dispatch for deployment, attacks and Queen behaviours.
dispatch_object_state:
    LDX moving_object_scan_slot            ; @1DC7 A6 55
    LDA object_draw_hi,X                   ; @1DC9 BD DB 04
    BEQ loc_1DC6                           ; @1DCC F0 F8
    LDY object_state,X                     ; @1DCE BC 66 05
    LDA object_state_to_handler_offset,Y   ; @1DD1 B9 E2 1D
    TAY                                    ; @1DD4 A8
    LDA object_handler_pointer_table,Y     ; @1DD5 B9 03 1E
    STA indirect_lo                        ; @1DD8 85 08
    LDA &1E04,Y                            ; @1DDA B9 04 1E
    STA indirect_hi                        ; @1DDD 85 09
    JMP (indirect_lo)                      ; @1DDF 6C 08 00
    ; DATA &1DE2-&1E20
    EQUB &00, &02, &08, &04, &00, &02, &16, &02, &18, &00, &02, &18    ; @1DE2
    EQUB &02, &1A, &1C, &06, &02, &0A, &04, &02, &0C, &02, &0A, &04    ; @1DEE
    EQUB &02, &0E, &02, &10, &12, &14, &02, &0A, &04, &2A, &1E, &39    ; @1DFA
    EQUB &1E, &30, &1F, &E5, &1E, &CA, &1E, &B2, &1E, &F1, &1E, &EB    ; @1E06
    EQUB &1E, &0F, &27, &C7, &26, &EE, &1E, &F4, &1E, &A8, &1F, &FC    ; @1E12
    EQUB &1E, &02, &1F    ; @1E1E

; ---------------------------------------------------------------------------
advance_object_state:
    INC object_state,X                     ; @1E21 FE 66 05
    LDA game_tick                          ; @1E24 A5 52
    STA object_last_tick,X                 ; @1E26 9D 45 05
    RTS                                    ; @1E29 60

; ---------------------------------------------------------------------------
wait_object_tick:
    LDA game_tick                          ; @1E2A A5 52
    CMP object_last_tick,X                 ; @1E2C DD 45 05
    BMI loc_1DC6                           ; @1E2F 30 95
    BEQ loc_1DC6                           ; @1E31 F0 93
    JSR advance_object_state               ; @1E33 20 21 1E
    JMP &1E3C                              ; @1E36 4C 3C 1E

; ---------------------------------------------------------------------------
; Interpret compact vector/repeat bytecode and redraw the object.
follow_trajectory:
    JSR erase_object                       ; @1E39 20 CC 0E
    LDA game_tick                          ; @1E3C A5 52
    SEC                                    ; @1E3E 38
    SBC object_last_tick,X                 ; @1E3F FD 45 05
    STA math_temp80                        ; @1E42 85 80
    BEQ loc_1EA4                           ; @1E44 F0 5E
    DEC object_repeat,X                    ; @1E46 DE F4 05
    BPL loc_1E5D                           ; @1E49 10 12
    INC object_aux_lo,X                    ; @1E4B FE C6 05
    BNE loc_1E53                           ; @1E4E D0 03
    INC object_aux_hi,X                    ; @1E50 FE DD 05

; ---------------------------------------------------------------------------
loc_1E53:
    JSR load_current_path_byte             ; @1E53 20 DA 1F
    JSR &23D9                              ; @1E56 20 D9 23
    LSR A                                  ; @1E59 4A
    STA object_repeat,X                    ; @1E5A 9D F4 05

; ---------------------------------------------------------------------------
loc_1E5D:
    JSR load_current_path_byte             ; @1E5D 20 DA 1F
    CMP #&FF                               ; @1E60 C9 FF
    BEQ advance_state_and_redispatch       ; @1E62 F0 48
    AND #&1F                               ; @1E64 29 1F
    TAY                                    ; @1E66 A8
    LDA object_type_flags,X                ; @1E67 BD AF 05
    ASL A                                  ; @1E6A 0A
    LDA object_x,X                         ; @1E6B BD 00 04
    BCC loc_1E76                           ; @1E6E 90 06
    SBC movement_dx,Y                      ; @1E70 F9 16 07
    JMP loc_1E79                           ; @1E73 4C 79 1E

; ---------------------------------------------------------------------------
loc_1E76:
    ADC movement_dx,Y                      ; @1E76 79 16 07

; ---------------------------------------------------------------------------
loc_1E79:
    STA object_x,X                         ; @1E79 9D 00 04
    CLC                                    ; @1E7C 18
    LDA object_y,X                         ; @1E7D BD 49 04
    ADC movement_dy,Y                      ; @1E80 79 2F 07
    STA object_y,X                         ; @1E83 9D 49 04
    LDA movement_anim,Y                    ; @1E86 B9 48 07
    BMI loc_1EA0                           ; @1E89 30 15
    JSR decode_alien_type                  ; @1E8B 20 96 1D
    BCC loc_1E9A                           ; @1E8E 90 0A
    EOR #&FF                               ; @1E90 49 FF
    ADC #&0C                               ; @1E92 69 0C
    CMP #&0C                               ; @1E94 C9 0C
    BCC loc_1E9A                           ; @1E96 90 02
    LDA #&FF                               ; @1E98 A9 FF

; ---------------------------------------------------------------------------
loc_1E9A:
    ADC alien_sprite_base_table,Y          ; @1E9A 79 92 21
    STA object_sprite,X                    ; @1E9D 9D 92 04

; ---------------------------------------------------------------------------
loc_1EA0:
    DEC math_temp80                        ; @1EA0 C6 80
    BNE &1E46                              ; @1EA2 D0 A2

; ---------------------------------------------------------------------------
loc_1EA4:
    LDA game_tick                          ; @1EA4 A5 52
    STA object_last_tick,X                 ; @1EA6 9D 45 05
    JMP draw_object                        ; @1EA9 4C C9 0E

; ---------------------------------------------------------------------------
advance_state_and_redispatch:
    JSR advance_object_state               ; @1EAC 20 21 1E
    JMP &1DCE                              ; @1EAF 4C CE 1D

; ---------------------------------------------------------------------------
prepare_return:
    LDY object_home_slot,X                 ; @1EB2 BC 01 06
    LDA object_x,Y                         ; @1EB5 B9 00 04
    STA object_x,X                         ; @1EB8 9D 00 04
    LDA #&7E                               ; @1EBB A9 7E
    STA object_y,X                         ; @1EBD 9D 49 04
    SEC                                    ; @1EC0 38
    SBC object_y,Y                         ; @1EC1 F9 49 04
    LSR A                                  ; @1EC4 4A
    STA object_aux_lo,X                    ; @1EC5 9D C6 05
    BPL &1ECF                              ; @1EC8 10 05

; ---------------------------------------------------------------------------
prepare_short_rejoin:
    LDA #&0C                               ; @1ECA A9 0C
    STA object_aux_lo,X                    ; @1ECC 9D C6 05
    JSR decode_alien_type                  ; @1ECF 20 96 1D
    LDA alien_sprite_base_table,Y          ; @1ED2 B9 92 21
    STA object_sprite,X                    ; @1ED5 9D 92 04
    LDA game_tick                          ; @1ED8 A5 52
    ADC #&7E                               ; @1EDA 69 7E
    STA object_next_tick,X                 ; @1EDC 9D 0E 06

; ---------------------------------------------------------------------------
advance_state_and_draw:
    JSR advance_object_state               ; @1EDF 20 21 1E
    JMP draw_object                        ; @1EE2 4C C9 0E

; ---------------------------------------------------------------------------
select_path_0165:
    JSR erase_object                       ; @1EE5 20 CC 0E
    LDY #&04                               ; @1EE8 A0 04
    NOP &08A0,X                            ; @1EEA DC A0 08 ; undocumented NOP; operand bytes are deliberate alternate entry
    NOP &0AA0,X                            ; @1EED DC A0 0A ; undocumented NOP; operand bytes are deliberate alternate entry
    NOP &06A0,X                            ; @1EF0 DC A0 06 ; undocumented NOP; operand bytes are deliberate alternate entry
    NOP &02A0,X                            ; @1EF3 DC A0 02 ; undocumented NOP; operand bytes are deliberate alternate entry
    JSR install_attack_path                ; @1EF6 20 91 1A
    JMP advance_object_state               ; @1EF9 4C 21 1E

; ---------------------------------------------------------------------------
linear_leg_start:
    JSR advance_object_state               ; @1EFC 20 21 1E
    JMP &1F05                              ; @1EFF 4C 05 1F

; ---------------------------------------------------------------------------
linear_leg_continue:
    JSR erase_object                       ; @1F02 20 CC 0E
    LDA game_tick                          ; @1F05 A5 52
    SEC                                    ; @1F07 38
    SBC object_last_tick,X                 ; @1F08 FD 45 05
    TAY                                    ; @1F0B A8
    DEY                                    ; @1F0C 88
    DEC object_y,X                         ; @1F0D DE 49 04
    LDA object_type_flags,X                ; @1F10 BD AF 05
    BPL &1F1B                              ; @1F13 10 06
    DEC object_x,X                         ; @1F15 DE 00 04
    ; DATA &1F18-&1F2F
    EQUB &4C, &1E, &1F, &FE, &00, &04, &BD, &49, &04, &C9, &2D, &90    ; @1F18
    EQUB &BA, &88, &10, &E5, &A5, &52, &9D, &45, &05, &4C, &C9, &0E    ; @1F24

; ---------------------------------------------------------------------------
; Proportionally move attack object to its live home formation coordinates.
interpolate_home:
    JSR erase_object                       ; @1F30 20 CC 0E
    LDY object_home_slot,X                 ; @1F33 BC 01 06
    LDA game_tick                          ; @1F36 A5 52
    SEC                                    ; @1F38 38
    SBC object_last_tick,X                 ; @1F39 FD 45 05
    STA temp45                             ; @1F3C 85 45
    CMP object_aux_lo,X                    ; @1F3E DD C6 05
    BCS loc_1F7F                           ; @1F41 B0 3C
    LDA game_tick                          ; @1F43 A5 52
    STA object_last_tick,X                 ; @1F45 9D 45 05
    LDA object_aux_lo,X                    ; @1F48 BD C6 05
    STA math_temp80                        ; @1F4B 85 80
    SEC                                    ; @1F4D 38
    SBC temp45                             ; @1F4E E5 45
    STA object_aux_lo,X                    ; @1F50 9D C6 05
    LDA object_x,Y                         ; @1F53 B9 00 04
    SEC                                    ; @1F56 38
    SBC object_x,X                         ; @1F57 FD 00 04
    JSR proportional_step                  ; @1F5A 20 B5 1F
    ADC object_x,X                         ; @1F5D 7D 00 04
    STA object_x,X                         ; @1F60 9D 00 04
    CMP object_x,Y                         ; @1F63 D9 00 04
    PHP                                    ; @1F66 08
    LDA object_y,Y                         ; @1F67 B9 49 04
    SEC                                    ; @1F6A 38
    SBC object_y,X                         ; @1F6B FD 49 04
    JSR proportional_step                  ; @1F6E 20 B5 1F
    ADC object_y,X                         ; @1F71 7D 49 04
    STA object_y,X                         ; @1F74 9D 49 04
    PLP                                    ; @1F77 28
    BNE loc_1FA5                           ; @1F78 D0 2B
    CMP object_y,Y                         ; @1F7A D9 49 04
    BNE loc_1FA5                           ; @1F7D D0 26

; ---------------------------------------------------------------------------
loc_1F7F:
    CPX beam_owner_slot                    ; @1F7F E4 C5
    BNE loc_1F87                           ; @1F81 D0 04
    LDA #&FF                               ; @1F83 A9 FF
    STA beam_owner_slot                    ; @1F85 85 C5

; ---------------------------------------------------------------------------
loc_1F87:
    LDA object_type_flags,X                ; @1F87 BD AF 05
    AND #&3F                               ; @1F8A 29 3F
    STA object_type_flags,Y                ; @1F8C 99 AF 05
    TAY                                    ; @1F8F A8
    LDA alien_sprite_base_table,Y          ; @1F90 B9 92 21
    LDY object_home_slot,X                 ; @1F93 BC 01 06
    STA object_sprite,Y                    ; @1F96 99 92 04
    TXA                                    ; @1F99 8A
    PHA                                    ; @1F9A 48
    TYA                                    ; @1F9B 98
    TAX                                    ; @1F9C AA
    JSR draw_object                        ; @1F9D 20 C9 0E
    PLA                                    ; @1FA0 68
    TAX                                    ; @1FA1 AA
    DEC active_attacker_count              ; @1FA2 C6 54
    RTS                                    ; @1FA4 60

; ---------------------------------------------------------------------------
loc_1FA5:
    JMP draw_object                        ; @1FA5 4C C9 0E

; ---------------------------------------------------------------------------
cleanup_transient_object:
    DEC active_attacker_count              ; @1FA8 C6 54
    LDA object_type_flags,X                ; @1FAA BD AF 05
    ASL A                                  ; @1FAD 0A
    BMI loc_1FB4                           ; @1FAE 30 04
    LDX current_player                     ; @1FB0 A6 32
    DEC player0_aliens_left,X              ; @1FB2 D6 39

; ---------------------------------------------------------------------------
loc_1FB4:
    RTS                                    ; @1FB4 60

; ---------------------------------------------------------------------------
proportional_step:
    PHP                                    ; @1FB5 08
    STY temp46                             ; @1FB6 84 46
    JSR absolute_for_step                  ; @1FB8 20 CF 1F
    LDY temp45                             ; @1FBB A4 45
    STA temp47                             ; @1FBD 85 47
    LDA #&00                               ; @1FBF A9 00
    ADC temp47                             ; @1FC1 65 47
    DEY                                    ; @1FC3 88
    BNE &1FC1                              ; @1FC4 D0 FB
    DEY                                    ; @1FC6 88
    INY                                    ; @1FC7 C8
    SEC                                    ; @1FC8 38
    SBC math_temp80                        ; @1FC9 E5 80
    BCS &1FC7                              ; @1FCB B0 FA
    TYA                                    ; @1FCD 98
    PLP                                    ; @1FCE 28

; ---------------------------------------------------------------------------
absolute_for_step:
    BPL loc_1FD6                           ; @1FCF 10 05
    EOR #&FF                               ; @1FD1 49 FF
    SEC                                    ; @1FD3 38
    ADC #&00                               ; @1FD4 69 00

; ---------------------------------------------------------------------------
loc_1FD6:
    LDY temp46                             ; @1FD6 A4 46
    CLC                                    ; @1FD8 18
    RTS                                    ; @1FD9 60

; ---------------------------------------------------------------------------
load_current_path_byte:
    LDA object_aux_lo,X                    ; @1FDA BD C6 05
    STA indirect_lo                        ; @1FDD 85 08
    LDA object_aux_hi,X                    ; @1FDF BD DD 05
    STA indirect_hi                        ; @1FE2 85 09
    LDY #&00                               ; @1FE4 A0 00
    LDA (indirect_lo),Y                    ; @1FE6 B1 08

; ---------------------------------------------------------------------------
loc_1FE8:
    RTS                                    ; @1FE8 60

; ---------------------------------------------------------------------------
; Let eligible attacking aliens fire aimed projectiles subject to stage limits.
service_enemy_fire:
    LDA challenge_stage                    ; @1FE9 A5 77
    ORA cycle_opening_stage                ; @1FEB 05 8B
    BMI loc_1FE8                           ; @1FED 30 F9
    LDY #&28                               ; @1FEF A0 28
    LDA object_draw_hi,Y                   ; @1FF1 B9 DB 04
    BEQ loc_2072                           ; @1FF4 F0 7C
    CMP #&FF                               ; @1FF6 C9 FF
    BEQ loc_2072                           ; @1FF8 F0 78
    CPY beam_owner_slot                    ; @1FFA C4 C5
    BEQ loc_2072                           ; @1FFC F0 74
    LDA game_tick                          ; @1FFE A5 52
    CMP object_next_tick,Y                 ; @2000 D9 0E 06
    BMI loc_2072                           ; @2003 30 6D
    ADC #&7E                               ; @2005 69 7E
    STA object_next_tick,Y                 ; @2007 99 0E 06
    LDX #&35                               ; @200A A2 35
    LDA object_draw_hi,X                   ; @200C BD DB 04
    BEQ loc_201C                           ; @200F F0 0B
    INX                                    ; @2011 E8
    CPX #&3F                               ; @2012 E0 3F
    BCS loc_1FE8                           ; @2014 B0 D2
    CPX enemy_shot_slot_limit              ; @2016 E4 8A
    BCC &200C                              ; @2018 90 F2
    BCS loc_1FE8                           ; @201A B0 CC

; ---------------------------------------------------------------------------
loc_201C:
    LDA fighter_configuration              ; @201C A5 19
    AND #&03                               ; @201E 29 03
    SEC                                    ; @2020 38
    ADC player_x                           ; @2021 65 16
    SBC object_x,Y                         ; @2023 F9 00 04
    STA object_state,X                     ; @2026 9D 66 05
    BPL loc_2030                           ; @2029 10 05
    EOR #&FF                               ; @202B 49 FF
    SEC                                    ; @202D 38
    ADC #&00                               ; @202E 69 00

; ---------------------------------------------------------------------------
loc_2030:
    STA object_aux_hi,X                    ; @2030 9D DD 05
    LDA #&20                               ; @2033 A9 20
    STA object_aux_lo,X                    ; @2035 9D C6 05
    LDA object_x,Y                         ; @2038 B9 00 04
    CLC                                    ; @203B 18
    ADC #&02                               ; @203C 69 02
    STA object_x,X                         ; @203E 9D 00 04
    STA work_x                             ; @2041 85 00
    LDA object_y,Y                         ; @2043 B9 49 04
    AND #&FC                               ; @2046 29 FC
    STA object_y,X                         ; @2048 9D 49 04
    STA work_y                             ; @204B 85 01
    LDA #&07                               ; @204D A9 07
    STA sprite_height                      ; @204F 85 07
    TYA                                    ; @2051 98
    PHA                                    ; @2052 48
    TXA                                    ; @2053 8A
    PHA                                    ; @2054 48
    JSR coord_to_mode2_address             ; @2055 20 01 0D
    PLA                                    ; @2058 68
    TAX                                    ; @2059 AA
    LDA screen_lo                          ; @205A A5 02
    STA object_draw_lo,X                   ; @205C 9D 24 05
    TYA                                    ; @205F 98
    STA object_draw_hi,X                   ; @2060 9D DB 04
    LDA #&08                               ; @2063 A9 08
    STA object_type_flags,X                ; @2065 9D AF 05
    LDA #&25                               ; @2068 A9 25
    STA object_sprite,X                    ; @206A 9D 92 04
    JSR xor_enemy_projectile               ; @206D 20 3D 16
    PLA                                    ; @2070 68
    TAY                                    ; @2071 A8

; ---------------------------------------------------------------------------
loc_2072:
    INY                                    ; @2072 C8
    CPY #&35                               ; @2073 C0 35
    BCC loc_2078                           ; @2075 90 01
    RTS                                    ; @2077 60

; ---------------------------------------------------------------------------
loc_2078:
    JMP &1FF1                              ; @2078 4C F1 1F

; ---------------------------------------------------------------------------
display_pending_messages:
    LDX #&09                               ; @207B A2 09
    LDA message_queue,X                    ; @207D BD 04 0A
    BMI loc_208F                           ; @2080 30 0D
    TAY                                    ; @2082 A8
    TXA                                    ; @2083 8A
    PHA                                    ; @2084 48
    JSR draw_message                       ; @2085 20 A2 20
    PLA                                    ; @2088 68
    TAX                                    ; @2089 AA
    LDA #&FF                               ; @208A A9 FF
    STA message_queue,X                    ; @208C 9D 04 0A

; ---------------------------------------------------------------------------
loc_208F:
    DEX                                    ; @208F CA
    BPL &207D                              ; @2090 10 EB
    RTS                                    ; @2092 60

; ---------------------------------------------------------------------------
queue_message:
    LDX #&09                               ; @2093 A2 09
    LDA message_queue,X                    ; @2095 BD 04 0A
    BMI loc_209E                           ; @2098 30 04
    DEX                                    ; @209A CA
    BPL &2095                              ; @209B 10 F8
    RTS                                    ; @209D 60

; ---------------------------------------------------------------------------
loc_209E:
    TYA                                    ; @209E 98
    STA message_queue,X                    ; @209F 9D 04 0A

; ---------------------------------------------------------------------------
draw_message:
    LDA message_pointer_table,Y            ; @20A2 B9 CE 20
    STA message_ptr_lo                     ; @20A5 85 5D
    LDA &20CF,Y                            ; @20A7 B9 CF 20
    STA message_ptr_hi                     ; @20AA 85 5E
    LDY #&00                               ; @20AC A0 00
    LDA (message_ptr_lo),Y                 ; @20AE B1 5D
    STA text_colour_mask                   ; @20B0 85 83
    INY                                    ; @20B2 C8
    LDA (message_ptr_lo),Y                 ; @20B3 B1 5D
    TAX                                    ; @20B5 AA
    INY                                    ; @20B6 C8
    LDA (message_ptr_lo),Y                 ; @20B7 B1 5D
    TAY                                    ; @20B9 A8
    JSR set_text_position                  ; @20BA 20 62 0D
    LDY #&03                               ; @20BD A0 03
    LDA (message_ptr_lo),Y                 ; @20BF B1 5D
    PHP                                    ; @20C1 08
    AND #&7F                               ; @20C2 29 7F
    JSR draw_custom_char                   ; @20C4 20 79 0D
    PLP                                    ; @20C7 28
    BMI loc_20CD                           ; @20C8 30 03
    INY                                    ; @20CA C8
    BNE &20BF                              ; @20CB D0 F2

; ---------------------------------------------------------------------------
loc_20CD:
    RTS                                    ; @20CD 60
    ; DATA &20CE-&20FD
    EQUB &45, &2F, &90, &2F, &9C, &2F, &73, &2F, &7E, &2F, &A8, &2F    ; @20CE
    EQUB &C8, &2F, &4D, &2F, &5A, &2F, &67, &2F, &6D, &2F, &08, &2F    ; @20DA
    EQUB &21, &2F, &34, &2F, &CC, &2F, &D0, &2F, &D4, &2F, &D8, &2F    ; @20E6
    EQUB &08, &01, &20, &01, &DC, &2F, &B7, &2F, &E2, &2E, &F0, &2E    ; @20F2

; ---------------------------------------------------------------------------
decode_entry_descriptor:
    LDA #&00                               ; @20FE A9 00
    STA path_mirror                        ; @2100 85 73
    LDA &2126,Y                            ; @2102 B9 26 21
    BNE loc_210F                           ; @2105 D0 08
    LDA entry_descriptor_table,Y           ; @2107 B9 25 21
    TAY                                    ; @210A A8
    LDA #&80                               ; @210B A9 80
    BNE &2100                              ; @210D D0 F1

; ---------------------------------------------------------------------------
loc_210F:
    STA path_ptr_hi                        ; @210F 85 67
    LDA &2127,Y                            ; @2111 B9 27 21
    STA collision_top                      ; @2114 85 63
    LDA entry_descriptor_table,Y           ; @2116 B9 25 21
    STA path_ptr_lo                        ; @2119 85 66
    RTS                                    ; @211B 60

; ---------------------------------------------------------------------------
set_player_entry_selector:
    TAY                                    ; @211C A8
    LDA stage_entry_selector_table,Y       ; @211D B9 87 21
    LDX current_player                     ; @2120 A6 32
    STA player0_entry_selector,X           ; @2122 95 74
    RTS                                    ; @2124 60
    ; DATA &2125-&219B
    EQUB &02, &00, &39, &01, &05, &20, &03, &14, &05, &00, &34, &03    ; @2125
    EQUB &14, &48, &03, &14, &0A, &00, &0D, &00, &71, &07, &14, &00    ; @2131
    EQUB &85, &07, &18, &00, &94, &07, &1C, &00, &A7, &07, &20, &00    ; @213D
    EQUB &B6, &07, &24, &00, &C6, &07, &28, &00, &00, &03, &2C, &00    ; @2149
    EQUB &DA, &07, &30, &00, &80, &82, &90, &8A, &8A, &90, &02, &00    ; @2155
    EQUB &80, &82, &05, &08, &02, &00, &80, &82, &8D, &8A, &92, &90    ; @2161
    EQUB &02, &00, &94, &96, &18, &1A, &14, &16, &9C, &9E, &20, &22    ; @216D
    EQUB &1C, &1E, &A4, &A6, &28, &2A, &24, &26, &AC, &AE, &30, &32    ; @2179
    EQUB &2C, &2E, &00, &08, &0E, &16, &00, &1C, &02, &22, &00, &28    ; @2185
    EQUB &02, &00, &05, &0C, &08, &18, &86, &18, &20, &25, &00    ; @2191

; ---------------------------------------------------------------------------
attract_title:
    JSR clear_object_draw_state            ; @219C 20 7C 14
    STA current_player                     ; @219F 85 32
    JSR install_input_vectors              ; @21A1 20 E7 18
    JSR draw_attract_screen                ; @21A4 20 72 22
    JSR menu_input                         ; @21A7 20 B2 21
    JSR read_fire_input                    ; @21AA 20 E4 18
    BEQ &21A7                              ; @21AD F0 F8
    JMP draw_attract_screen                ; @21AF 4C 72 22

; ---------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; FLATTENED MODULE: 04_ui_score_sound.asm
; ----------------------------------------------------------------------------
; ZALAGA V10 - Menu/UI, messages, score/high-score, music/SOUND, lives display and name entry
; Sequential module included by ../zalaga.asm.

menu_input:
    JSR poll_control_toggle                ; @21B2 20 4B 0E
    BEQ loc_21CA                           ; @21B5 F0 13
    LDY #&20                               ; @21B7 A0 20
    JSR draw_message                       ; @21B9 20 A2 20
    LDY #&22                               ; @21BC A0 22
    JSR draw_message                       ; @21BE 20 A2 20
    LDA input_mode                         ; @21C1 A5 70
    EOR #&FF                               ; @21C3 49 FF
    STA input_mode                         ; @21C5 85 70
    JSR install_input_vectors              ; @21C7 20 E7 18

; ---------------------------------------------------------------------------
loc_21CA:
    JSR poll_player_count_toggle           ; @21CA 20 59 0E
    BEQ service_menu_toggles               ; @21CD F0 10
    LDY #&1C                               ; @21CF A0 1C
    JSR draw_message                       ; @21D1 20 A2 20
    LDY #&1E                               ; @21D4 A0 1E
    JSR draw_message                       ; @21D6 20 A2 20
    LDA two_player_option                  ; @21D9 A5 3C
    EOR #&FF                               ; @21DB 49 FF
    STA two_player_option                  ; @21DD 85 3C

; ---------------------------------------------------------------------------
service_menu_toggles:
    JSR poll_sound_toggle                  ; @21DF 20 1E 0E
    BEQ common_frame_service               ; @21E2 F0 0B
    LDA sound_option                       ; @21E4 A5 3B
    EOR #&FF                               ; @21E6 49 FF
    STA sound_option                       ; @21E8 85 3B
    LDY #&0C                               ; @21EA A0 0C
    JSR draw_message                       ; @21EC 20 A2 20

; ---------------------------------------------------------------------------
common_frame_service:
    JSR wait_for_tick                      ; @21EF 20 09 0E
    JSR animate_palette                    ; @21F2 20 6A 0E
    JSR update_starfield                   ; @21F5 20 52 12
    JSR update_enemy_projectiles           ; @21F8 20 BF 15
    JSR service_music                      ; @21FB 20 61 24
    JMP update_effect_slots                ; @21FE 4C 4B 14

; ---------------------------------------------------------------------------
gameplay_frame_service:
    JSR service_menu_toggles               ; @2201 20 DF 21
    JSR update_player                      ; @2204 20 A3 14
    JSR service_player_fire                ; @2207 20 97 16
    JSR service_enemy_fire                 ; @220A 20 E9 1F
    JMP &13FB                              ; @220D 4C FB 13

; ---------------------------------------------------------------------------
; Draw 1UP, high score and 2UP scores; contains deliberate overlapping opcode trick.
draw_all_scores:
    LDA #&00                               ; @2210 A9 00
    JSR draw_one_player_score              ; @2212 20 1D 22
    JSR draw_high_score                    ; @2215 20 46 22
    LDA #&01                               ; @2218 A9 01
    NOP &32A5,X                            ; @221A DC A5 32 ; undocumented NOP; operand bytes are deliberate alternate entry

; ---------------------------------------------------------------------------
draw_one_player_score:
    LDX #&0B                               ; @221D A2 0B
    PHA                                    ; @221F 48
    TAY                                    ; @2220 A8
    BEQ loc_2225                           ; @2221 F0 02
    LDX #&3E                               ; @2223 A2 3E

; ---------------------------------------------------------------------------
loc_2225:
    LDY #&7E                               ; @2225 A0 7E
    JSR set_text_position                  ; @2227 20 62 0D
    LDA #&0F                               ; @222A A9 0F
    STA text_colour_mask                   ; @222C 85 83
    PLA                                    ; @222E 68
    TAX                                    ; @222F AA
    LDA player0_score_lo,X                 ; @2230 B5 1F
    PHA                                    ; @2232 48
    LDY player0_score_mid,X                ; @2233 B4 21
    LDA player0_score_hi,X                 ; @2235 B5 23
    STY bcd_work1                          ; @2237 84 3E
    STA bcd_work2                          ; @2239 85 3F
    PLA                                    ; @223B 68
    STA bcd_work0                          ; @223C 85 3D
    JSR print_score_alt_nibble_order       ; @223E 20 02 23
    LDA #&30                               ; @2241 A9 30
    JMP draw_custom_char                   ; @2243 4C 79 0D

; ---------------------------------------------------------------------------
draw_high_score:
    LDX #&23                               ; @2246 A2 23
    LDY #&7E                               ; @2248 A0 7E
    JSR set_text_position                  ; @224A 20 62 0D
    LDA #&3C                               ; @224D A9 3C
    STA text_colour_mask                   ; @224F 85 83
    LDA high_score_low                     ; @2251 AD FA 09
    PHA                                    ; @2254 48
    LDY high_score_mid                     ; @2255 AC EC 0C
    LDA high_score_hi                      ; @2258 AD F6 0C
    JMP &2237                              ; @225B 4C 37 22

; ---------------------------------------------------------------------------
draw_score_separator:
    LDX #&14                               ; @225E A2 14
    JSR set_text_position                  ; @2260 20 62 0D
    LDA #&03                               ; @2263 A9 03
    STA text_colour_mask                   ; @2265 85 83
    LDX #&0E                               ; @2267 A2 0E
    LDA #&2D                               ; @2269 A9 2D
    JSR draw_custom_char                   ; @226B 20 79 0D
    DEX                                    ; @226E CA
    BNE &226B                              ; @226F D0 FA
    RTS                                    ; @2271 60

; ---------------------------------------------------------------------------
draw_attract_screen:
    JSR menu_input                         ; @2272 20 B2 21
    LDY #&1A                               ; @2275 A0 1A
    JSR draw_message                       ; @2277 20 A2 20
    LDY #&76                               ; @227A A0 76
    JSR draw_score_separator               ; @227C 20 5E 22
    LDY #&6E                               ; @227F A0 6E
    JSR draw_score_separator               ; @2281 20 5E 22
    JSR draw_high_score_table              ; @2284 20 92 22
    LDY #&16                               ; @2287 A0 16
    JSR draw_message                       ; @2289 20 A2 20
    LDY #&18                               ; @228C A0 18
    JSR draw_message                       ; @228E 20 A2 20
    RTS                                    ; @2291 60

; ---------------------------------------------------------------------------
; Render ten 25-byte name/credit rows with three-byte BCD scores.
draw_high_score_table:
    LDX #&00                               ; @2292 A2 00
    STX queen_table_index                  ; @2294 86 7E
    TXA                                    ; @2296 8A
    JSR high_score_row_position            ; @2297 20 F1 22
    JSR set_text_position                  ; @229A 20 62 0D
    JSR common_frame_service               ; @229D 20 EF 21
    LDA #&03                               ; @22A0 A9 03
    STA text_colour_mask                   ; @22A2 85 83
    LDX queen_table_index                  ; @22A4 A6 7E
    LDA high_score_low,X                   ; @22A6 BD FA 09
    STA bcd_work0                          ; @22A9 85 3D
    LDA high_score_mid,X                   ; @22AB BD EC 0C
    STA bcd_work1                          ; @22AE 85 3E
    LDA high_score_hi,X                    ; @22B0 BD F6 0C
    STA bcd_work2                          ; @22B3 85 3F
    JSR print_score                        ; @22B5 20 FE 22
    LDA #&30                               ; @22B8 A9 30
    JSR draw_custom_char                   ; @22BA 20 79 0D
    LDA #&3C                               ; @22BD A9 3C
    STA text_colour_mask                   ; @22BF 85 83
    LDA temp47                             ; @22C1 A5 47
    SEC                                    ; @22C3 38
    SBC #&04                               ; @22C4 E9 04
    TAY                                    ; @22C6 A8
    LDX #&03                               ; @22C7 A2 03
    JSR set_text_position                  ; @22C9 20 62 0D
    LDX queen_table_index                  ; @22CC A6 7E
    TXA                                    ; @22CE 8A
    ASL A                                  ; @22CF 0A
    ASL A                                  ; @22D0 0A
    ASL A                                  ; @22D1 0A
    TAY                                    ; @22D2 A8
    ADC queen_table_index                  ; @22D3 65 7E
    STA temp45                             ; @22D5 85 45
    TYA                                    ; @22D7 98
    ASL A                                  ; @22D8 0A
    ADC temp45                             ; @22D9 65 45
    TAY                                    ; @22DB A8
    LDA high_score_names,Y                 ; @22DC B9 00 09
    CMP #&0D                               ; @22DF C9 0D
    BEQ loc_22E9                           ; @22E1 F0 06
    JSR draw_custom_char                   ; @22E3 20 79 0D
    INY                                    ; @22E6 C8
    BNE &22DC                              ; @22E7 D0 F3

; ---------------------------------------------------------------------------
loc_22E9:
    INX                                    ; @22E9 E8
    CPX #&0A                               ; @22EA E0 0A
    BNE &2294                              ; @22EC D0 A6
    JMP common_frame_service               ; @22EE 4C EF 21

; ---------------------------------------------------------------------------
high_score_row_position:
    ASL A                                  ; @22F1 0A
    ASL A                                  ; @22F2 0A
    ASL A                                  ; @22F3 0A
    EOR #&FF                               ; @22F4 49 FF
    ADC #&68                               ; @22F6 69 68
    STA temp47                             ; @22F8 85 47
    TAY                                    ; @22FA A8
    LDX #&05                               ; @22FB A2 05
    RTS                                    ; @22FD 60

; ---------------------------------------------------------------------------
print_score:
    LDA #&F0                               ; @22FE A9 F0
    BNE &2304                              ; @2300 D0 02

; ---------------------------------------------------------------------------
print_score_alt_nibble_order:
    LDA #&0F                               ; @2302 A9 0F
    STA xor_mask                           ; @2304 85 44
    LDA bcd_work0                          ; @2306 A5 3D
    ORA bcd_work1                          ; @2308 05 3E
    ORA bcd_work2                          ; @230A 05 3F
    BEQ loc_2334                           ; @230C F0 26
    TXA                                    ; @230E 8A
    PHA                                    ; @230F 48
    LDX #&02                               ; @2310 A2 02
    LDY #&00                               ; @2312 A0 00
    JSR get_bcd_nibble                     ; @2314 20 D1 23
    INY                                    ; @2317 C8
    ORA #&30                               ; @2318 09 30
    CMP #&30                               ; @231A C9 30
    BNE loc_2323                           ; @231C D0 05
    DEY                                    ; @231E 88
    BNE loc_2323                           ; @231F D0 02
    LDA #&20                               ; @2321 A9 20

; ---------------------------------------------------------------------------
loc_2323:
    JSR draw_custom_char                   ; @2323 20 79 0D
    LDA xor_mask                           ; @2326 A5 44
    EOR #&FF                               ; @2328 49 FF
    STA xor_mask                           ; @232A 85 44
    BPL &2314                              ; @232C 10 E6
    DEX                                    ; @232E CA
    BPL &2314                              ; @232F 10 E3
    PLA                                    ; @2331 68
    TAX                                    ; @2332 AA
    RTS                                    ; @2333 60

; ---------------------------------------------------------------------------
loc_2334:
    LDX #&04                               ; @2334 A2 04
    LDA #&20                               ; @2336 A9 20
    BIT xor_mask                           ; @2338 24 44
    BPL loc_233D                           ; @233A 10 01
    INX                                    ; @233C E8

; ---------------------------------------------------------------------------
loc_233D:
    JSR draw_custom_char                   ; @233D 20 79 0D
    DEX                                    ; @2340 CA
    BNE loc_233D                           ; @2341 D0 FA
    LDA #&30                               ; @2343 A9 30
    JMP draw_custom_char                   ; @2345 4C 79 0D

; ---------------------------------------------------------------------------
prepare_challenge_hits_display:
    LDY #&0B                               ; @2348 A0 0B
    LDA &2F9C,Y                            ; @234A B9 9C 2F
    STA &0108,Y                            ; @234D 99 08 01
    DEY                                    ; @2350 88
    BPL &234A                              ; @2351 10 F7
    LDA challenge_hits_bcd                 ; @2353 A5 7A
    LDX #&00                               ; @2355 A2 00
    LDY #&12                               ; @2357 A0 12
    JMP patch_bcd_digits_into_message      ; @2359 4C 9A 23

; ---------------------------------------------------------------------------
prepare_challenge_bonus_display:
    LDY #&0E                               ; @235C A0 0E
    LDA &2FA8,Y                            ; @235E B9 A8 2F
    STA &0120,Y                            ; @2361 99 20 01
    DEY                                    ; @2364 88
    BPL &235E                              ; @2365 10 F7
    LDA challenge_hits_bcd                 ; @2367 A5 7A
    CMP #&40                               ; @2369 C9 40
    BEQ loc_2379                           ; @236B F0 0C
    LDX #&00                               ; @236D A2 00
    LDY #&2B                               ; @236F A0 2B
    JSR patch_bcd_value_into_glyphs        ; @2371 20 A2 23
    LDY #&26                               ; @2374 A0 26
    JMP queue_message                      ; @2376 4C 93 20

; ---------------------------------------------------------------------------
loc_2379:
    LDY #&02                               ; @2379 A0 02
    JSR queue_message                      ; @237B 20 93 20
    LDY #&2A                               ; @237E A0 2A
    JMP queue_message                      ; @2380 4C 93 20

; ---------------------------------------------------------------------------
prepare_stage_display:
    LDY #&0A                               ; @2383 A0 0A
    LDA &2F73,Y                            ; @2385 B9 73 2F
    STA &0108,Y                            ; @2388 99 08 01
    DEY                                    ; @238B 88
    BPL &2385                              ; @238C 10 F7
    LDX current_player                     ; @238E A6 32
    LDA player0_stage_hi,X                 ; @2390 B5 25
    STA bcd_work1                          ; @2392 85 3E
    LDA player0_stage_lo,X                 ; @2394 B5 37
    LDX #&01                               ; @2396 A2 01
    LDY #&0F                               ; @2398 A0 0F

; ---------------------------------------------------------------------------
patch_bcd_digits_into_message:
    JSR patch_bcd_value_into_glyphs        ; @239A 20 A2 23
    LDY #&24                               ; @239D A0 24
    JMP queue_message                      ; @239F 4C 93 20

; ---------------------------------------------------------------------------
patch_bcd_value_into_glyphs:
    STA bcd_work0                          ; @23A2 85 3D
    LDA #&FF                               ; @23A4 A9 FF
    STA collision_result                   ; @23A6 85 60
    LDA #&F0                               ; @23A8 A9 F0
    STA xor_mask                           ; @23AA 85 44
    JSR get_bcd_nibble                     ; @23AC 20 D1 23
    BEQ loc_23B3                           ; @23AF F0 02
    INC collision_result                   ; @23B1 E6 60

; ---------------------------------------------------------------------------
loc_23B3:
    BIT collision_result                   ; @23B3 24 60
    BMI loc_23C4                           ; @23B5 30 0D
    EOR #&30                               ; @23B7 49 30
    ASL A                                  ; @23B9 0A
    PHA                                    ; @23BA 48
    LDA &0100,Y                            ; @23BB B9 00 01
    ASL A                                  ; @23BE 0A
    PLA                                    ; @23BF 68
    ROR A                                  ; @23C0 6A
    STA &0100,Y                            ; @23C1 99 00 01

; ---------------------------------------------------------------------------
loc_23C4:
    INY                                    ; @23C4 C8
    LDA xor_mask                           ; @23C5 A5 44
    EOR #&FF                               ; @23C7 49 FF
    STA xor_mask                           ; @23C9 85 44
    BPL &23AC                              ; @23CB 10 DF
    DEX                                    ; @23CD CA
    BPL &23AC                              ; @23CE 10 DC
    RTS                                    ; @23D0 60

; ---------------------------------------------------------------------------
get_bcd_nibble:
    LDA bcd_work0,X                        ; @23D1 B5 3D
    AND xor_mask                           ; @23D3 25 44
    BIT xor_mask                           ; @23D5 24 44
    BPL loc_23DD                           ; @23D7 10 04
    LSR A                                  ; @23D9 4A
    LSR A                                  ; @23DA 4A
    LSR A                                  ; @23DB 4A
    LSR A                                  ; @23DC 4A

; ---------------------------------------------------------------------------
loc_23DD:
    ORA #&00                               ; @23DD 09 00
    RTS                                    ; @23DF 60

; ---------------------------------------------------------------------------
sound_osword7:
    LDA sound_option                       ; @23E0 A5 3B
    ORA sound_gate                         ; @23E2 05 79
    BMI &2431                              ; @23E4 30 4B
    LDA #&07                               ; @23E6 A9 07
    NOP &08A9,X                            ; @23E8 DC A9 08 ; undocumented NOP; operand bytes are deliberate alternate entry
    STA indirect_lo                        ; @23EB 85 08
    TXA                                    ; @23ED 8A
    PHA                                    ; @23EE 48
    TYA                                    ; @23EF 98
    PHA                                    ; @23F0 48
    CLC                                    ; @23F1 18
    ADC #&5E                               ; @23F2 69 5E
    TAX                                    ; @23F4 AA
    LDA #&00                               ; @23F5 A9 00
    ADC #&2E                               ; @23F7 69 2E
    TAY                                    ; @23F9 A8
    LDA indirect_lo                        ; @23FA A5 08
    BNE &2427                              ; @23FC D0 29

; ---------------------------------------------------------------------------
decode_music_note:
    CMP #&FF                               ; @23FE C9 FF
    BEQ loc_242F                           ; @2400 F0 2D
    PHA                                    ; @2402 48
    AND #&03                               ; @2403 29 03
    ADC #&01                               ; @2405 69 01
    STA music_ctr0,X                       ; @2407 95 40
    PLA                                    ; @2409 68
    AND #&FC                               ; @240A 29 FC
    STA &0104                              ; @240C 8D 04 01
    TXA                                    ; @240F 8A
    PHA                                    ; @2410 48
    ORA #&10                               ; @2411 09 10
    STA &0100                              ; @2413 8D 00 01
    TYA                                    ; @2416 98
    PHA                                    ; @2417 48
    LDY music_duration_shift               ; @2418 A4 8D
    ASL music_ctr0,X                       ; @241A 16 40
    DEY                                    ; @241C 88
    BNE &241A                              ; @241D D0 FB
    LDA #&07                               ; @241F A9 07
    LDX sound_option                       ; @2421 A6 3B
    BNE loc_242A                           ; @2423 D0 05
    LDY #&01                               ; @2425 A0 01
    JSR &FFF1                              ; @2427 20 F1 FF

; ---------------------------------------------------------------------------
loc_242A:
    PLA                                    ; @242A 68
    TAY                                    ; @242B A8
    PLA                                    ; @242C 68
    TAX                                    ; @242D AA
    RTS                                    ; @242E 60

; ---------------------------------------------------------------------------
loc_242F:
    STA music_ctr0,X                       ; @242F 95 40
    RTS                                    ; @2431 60

; ---------------------------------------------------------------------------
; Initialise three-voice compact tune sequencer.
start_music:
    BIT sound_option                       ; @2432 24 3B
    BMI loc_2495                           ; @2434 30 5F
    LDA music_selector_table,Y             ; @2436 B9 A0 24
    STA music_base_lo                      ; @2439 85 6A
    LDA &24A1,Y                            ; @243B B9 A1 24
    STA music_base_hi                      ; @243E 85 6B
    LDA &24A2,Y                            ; @2440 B9 A2 24
    STA music_duration_shift               ; @2443 85 8D
    LDY #&2A                               ; @2445 A0 2A
    JSR envelope_osword8                   ; @2447 20 E9 23
    LDY #&02                               ; @244A A0 02
    LDA (music_base_lo),Y                  ; @244C B1 6A
    STA music_offset0,Y                    ; @244E 99 6D 00
    LDA #&00                               ; @2451 A9 00
    STA music_ctr1,Y                       ; @2453 99 41 00
    DEY                                    ; @2456 88
    BPL &244C                              ; @2457 10 F3
    LDA #&80                               ; @2459 A9 80
    STA sound_gate                         ; @245B 85 79
    LDA game_tick                          ; @245D A5 52
    STA music_last_tick                    ; @245F 85 C8

; ---------------------------------------------------------------------------
service_music:
    LDA sound_gate                         ; @2461 A5 79
    BPL loc_2495                           ; @2463 10 30
    CMP #&80                               ; @2465 C9 80
    BNE finish_music_delay                 ; @2467 D0 2D
    LDX #&03                               ; @2469 A2 03
    LDA music_ctr0,X                       ; @246B B5 40
    BNE loc_2478                           ; @246D D0 09
    LDY music_offset_base,X                ; @246F B4 6C
    LDA (music_base_lo),Y                  ; @2471 B1 6A
    JSR decode_music_note                  ; @2473 20 FE 23
    INC music_offset_base,X                ; @2476 F6 6C

; ---------------------------------------------------------------------------
loc_2478:
    DEC music_ctr0,X                       ; @2478 D6 40
    BPL loc_247E                           ; @247A 10 02
    INC music_ctr0,X                       ; @247C F6 40

; ---------------------------------------------------------------------------
loc_247E:
    DEX                                    ; @247E CA
    BNE &246B                              ; @247F D0 EA
    LDA music_last_tick                    ; @2481 A5 C8
    INC music_last_tick                    ; @2483 E6 C8
    CMP game_tick                          ; @2485 C5 52
    BMI &2469                              ; @2487 30 E0
    LDA music_ctr1                         ; @2489 A5 41
    AND music_ctr2                         ; @248B 25 42
    AND music_ctr3                         ; @248D 25 43
    BPL loc_2495                           ; @248F 10 04
    LDA #&E7                               ; @2491 A9 E7
    STA sound_gate                         ; @2493 85 79

; ---------------------------------------------------------------------------
loc_2495:
    RTS                                    ; @2495 60

; ---------------------------------------------------------------------------
finish_music_delay:
    INC sound_gate                         ; @2496 E6 79
    BNE loc_2495                           ; @2498 D0 FB

; ---------------------------------------------------------------------------
stop_music_and_restore_sound:
    JSR flush_keyboard_buffer              ; @249A 20 9B 14
    JMP setup_sound_envelopes              ; @249D 4C 87 14
    ; DATA &24A0-&24A5
    EQUB &80, &08, &02, &A4, &0A, &03    ; @24A0

; ---------------------------------------------------------------------------
; XOR-erase previous reserve icons then XOR-draw new count.
refresh_lives_display:
    LDA lives_display_cache                ; @24A6 A5 71
    JSR xor_lives_icons                    ; @24A8 20 B1 24
    LDX current_player                     ; @24AB A6 32
    LDA player0_fighters,X                 ; @24AD B5 35
    STA lives_display_cache                ; @24AF 85 71

; ---------------------------------------------------------------------------
xor_lives_icons:
    STA temp45                             ; @24B1 85 45
    CMP #&02                               ; @24B3 C9 02
    BCC loc_24CB                           ; @24B5 90 14
    DEC temp45                             ; @24B7 C6 45
    LDX #&00                               ; @24B9 A2 00
    LDY #&00                               ; @24BB A0 00
    LDA #&24                               ; @24BD A9 24
    JSR draw_sprite_xy                     ; @24BF 20 AF 0E
    TXA                                    ; @24C2 8A
    CLC                                    ; @24C3 18
    ADC #&06                               ; @24C4 69 06
    TAX                                    ; @24C6 AA
    DEC temp45                             ; @24C7 C6 45
    BNE &24BD                              ; @24C9 D0 F2

; ---------------------------------------------------------------------------
loc_24CB:
    RTS                                    ; @24CB 60

; ---------------------------------------------------------------------------
; Compare, shift 10-entry table, insert score and invoke name entry.
insert_high_score:
    JSR clear_playfield_objects            ; @24CC 20 05 14
    JSR display_pending_messages           ; @24CF 20 7B 20
    JSR draw_all_scores                    ; @24D2 20 10 22
    LDY #&09                               ; @24D5 A0 09
    LDX current_player                     ; @24D7 A6 32
    LDA player0_score_lo,X                 ; @24D9 B5 1F
    CMP high_score_low,Y                   ; @24DB D9 FA 09
    LDA player0_score_mid,X                ; @24DE B5 21
    SBC high_score_mid,Y                   ; @24E0 F9 EC 0C
    LDA player0_score_hi,X                 ; @24E3 B5 23
    SBC high_score_hi,Y                    ; @24E5 F9 F6 0C
    BCC loc_2539                           ; @24E8 90 4F
    STY indirect_lo                        ; @24EA 84 08
    TYA                                    ; @24EC 98
    ASL A                                  ; @24ED 0A
    ADC indirect_lo                        ; @24EE 65 08
    ASL A                                  ; @24F0 0A
    ASL A                                  ; @24F1 0A
    ASL A                                  ; @24F2 0A
    ADC indirect_lo                        ; @24F3 65 08
    TAY                                    ; @24F5 A8
    STY queen_escorts_left                 ; @24F6 84 7D
    CPY #&E1                               ; @24F8 C0 E1
    BCS loc_251E                           ; @24FA B0 22
    LDX #&19                               ; @24FC A2 19
    LDA high_score_names,Y                 ; @24FE B9 00 09
    STA &0919,Y                            ; @2501 99 19 09
    INY                                    ; @2504 C8
    DEX                                    ; @2505 CA
    BNE &24FE                              ; @2506 D0 F6
    LDY indirect_lo                        ; @2508 A4 08
    LDX current_player                     ; @250A A6 32
    LDA high_score_low,Y                   ; @250C B9 FA 09
    STA &09FB,Y                            ; @250F 99 FB 09
    LDA high_score_mid,Y                   ; @2512 B9 EC 0C
    STA &0CED,Y                            ; @2515 99 ED 0C
    LDA high_score_hi,Y                    ; @2518 B9 F6 0C
    STA &0CF7,Y                            ; @251B 99 F7 0C

; ---------------------------------------------------------------------------
loc_251E:
    LDA #&0D                               ; @251E A9 0D
    LDY queen_escorts_left                 ; @2520 A4 7D
    STA high_score_names,Y                 ; @2522 99 00 09
    LDY indirect_lo                        ; @2525 A4 08
    LDA player0_score_lo,X                 ; @2527 B5 1F
    STA high_score_low,Y                   ; @2529 99 FA 09
    LDA player0_score_mid,X                ; @252C B5 21
    STA high_score_mid,Y                   ; @252E 99 EC 0C
    LDA player0_score_hi,X                 ; @2531 B5 23
    STA high_score_hi,Y                    ; @2533 99 F6 0C
    DEY                                    ; @2536 88
    BPL &24D7                              ; @2537 10 9E

; ---------------------------------------------------------------------------
loc_2539:
    INY                                    ; @2539 C8
    CPY #&0A                               ; @253A C0 0A
    PHP                                    ; @253C 08
    TYA                                    ; @253D 98
    PHA                                    ; @253E 48
    JSR draw_all_scores                    ; @253F 20 10 22
    PLA                                    ; @2542 68
    PLP                                    ; @2543 28
    BNE loc_2547                           ; @2544 D0 01
    RTS                                    ; @2546 60

; ---------------------------------------------------------------------------
loc_2547:
    PHA                                    ; @2547 48
    JSR draw_high_score_table              ; @2548 20 92 22
    PLA                                    ; @254B 68
    JSR high_score_row_position            ; @254C 20 F1 22
    TYA                                    ; @254F 98
    SEC                                    ; @2550 38
    SBC #&04                               ; @2551 E9 04
    TAY                                    ; @2553 A8
    STY path_ptr_lo                        ; @2554 84 66
    JSR high_score_name_entry              ; @2556 20 EF 25
    LDA #&3C                               ; @2559 A9 3C
    STA text_colour_mask                   ; @255B 85 83
    LDA #&7E                               ; @255D A9 7E
    JSR &FFF4                              ; @255F 20 F4 FF
    LDX #&00                               ; @2562 A2 00
    LDA #&0F                               ; @2564 A9 0F
    JSR &FFF4                              ; @2566 20 F4 FF
    LDY queen_escorts_left                 ; @2569 A4 7D
    LDX #&00                               ; @256B A2 00
    STX queen_table_index                  ; @256D 86 7E
    STY queen_candidates_left              ; @256F 84 7F
    JSR common_frame_service               ; @2571 20 EF 21
    LDY #&00                               ; @2574 A0 00
    LDX #&00                               ; @2576 A2 00
    LDA #&81                               ; @2578 A9 81
    JSR &FFF4                              ; @257A 20 F4 FF
    CPY #&1B                               ; @257D C0 1B
    PHP                                    ; @257F 08
    TXA                                    ; @2580 8A
    LDX queen_table_index                  ; @2581 A6 7E
    LDY queen_candidates_left              ; @2583 A4 7F
    PLP                                    ; @2585 28
    BEQ loc_25AA                           ; @2586 F0 22
    BCS &256D                              ; @2588 B0 E3
    CMP #&7F                               ; @258A C9 7F
    BEQ loc_25C0                           ; @258C F0 32
    BCS &256D                              ; @258E B0 DD
    CMP #&15                               ; @2590 C9 15
    BEQ loc_25B7                           ; @2592 F0 23
    CMP #&0D                               ; @2594 C9 0D
    BEQ loc_25E0                           ; @2596 F0 48
    CMP #&20                               ; @2598 C9 20
    BCC &256D                              ; @259A 90 D1
    CPX #&18                               ; @259C E0 18
    BCS &256D                              ; @259E B0 CD
    STA high_score_names,Y                 ; @25A0 99 00 09
    JSR draw_custom_char                   ; @25A3 20 79 0D
    INY                                    ; @25A6 C8
    INX                                    ; @25A7 E8
    BNE &256D                              ; @25A8 D0 C3

; ---------------------------------------------------------------------------
loc_25AA:
    TXA                                    ; @25AA 8A
    PHA                                    ; @25AB 48
    TYA                                    ; @25AC 98
    PHA                                    ; @25AD 48
    LDA #&7E                               ; @25AE A9 7E
    JSR &FFF4                              ; @25B0 20 F4 FF
    PLA                                    ; @25B3 68
    TAY                                    ; @25B4 A8
    PLA                                    ; @25B5 68
    TAX                                    ; @25B6 AA

; ---------------------------------------------------------------------------
loc_25B7:
    TXA                                    ; @25B7 8A
    BEQ &256D                              ; @25B8 F0 B3
    JSR erase_name_character               ; @25BA 20 C9 25
    JMP loc_25B7                           ; @25BD 4C B7 25

; ---------------------------------------------------------------------------
loc_25C0:
    TXA                                    ; @25C0 8A
    BEQ &256D                              ; @25C1 F0 AA
    JSR erase_name_character               ; @25C3 20 C9 25
    JMP &256D                              ; @25C6 4C 6D 25

; ---------------------------------------------------------------------------
erase_name_character:
    DEX                                    ; @25C9 CA
    DEY                                    ; @25CA 88
    JSR move_text_cursor_left              ; @25CB 20 D4 25
    LDA high_score_names,Y                 ; @25CE B9 00 09
    JSR draw_custom_char                   ; @25D1 20 79 0D

; ---------------------------------------------------------------------------
move_text_cursor_left:
    LDA text_screen_lo                     ; @25D4 A5 81
    SEC                                    ; @25D6 38
    SBC #&18                               ; @25D7 E9 18
    STA text_screen_lo                     ; @25D9 85 81
    BCS loc_25DF                           ; @25DB B0 02
    DEC text_screen_hi                     ; @25DD C6 82

; ---------------------------------------------------------------------------
loc_25DF:
    RTS                                    ; @25DF 60

; ---------------------------------------------------------------------------
loc_25E0:
    LDA #&0D                               ; @25E0 A9 0D
    STA high_score_names,Y                 ; @25E2 99 00 09
    JSR draw_high_score_table              ; @25E5 20 92 22
    LDX #&00                               ; @25E8 A2 00
    LDA #&0B                               ; @25EA A9 0B
    JSR &FFF4                              ; @25EC 20 F4 FF

; ---------------------------------------------------------------------------
high_score_name_entry:
    LDY #&2C                               ; @25EF A0 2C
    JSR draw_message                       ; @25F1 20 A2 20
    JSR menu_input                         ; @25F4 20 B2 21
    LDY #&2E                               ; @25F7 A0 2E
    JSR draw_message                       ; @25F9 20 A2 20
    LDX #&03                               ; @25FC A2 03
    LDY path_ptr_lo                        ; @25FE A4 66
    JSR set_text_position                  ; @2600 20 62 0D
    LDY #&3F                               ; @2603 A0 3F
    LDX text_screen_hi                     ; @2605 A6 82
    INX                                    ; @2607 E8
    INX                                    ; @2608 E8
    JSR xor_name_cursor_block              ; @2609 20 11 26
    DEX                                    ; @260C CA
    JSR xor_name_cursor_block              ; @260D 20 11 26
    DEX                                    ; @2610 CA

; ---------------------------------------------------------------------------
xor_name_cursor_block:
    LDA text_screen_lo                     ; @2611 A5 81
    STA screen_lo                          ; @2613 85 02
    STX screen_hi                          ; @2615 86 03
    LDA (screen_lo),Y                      ; @2617 B1 02
    EOR #&30                               ; @2619 49 30
    STA (screen_lo),Y                      ; @261B 91 02
    DEY                                    ; @261D 88
    CPY #&FF                               ; @261E C0 FF
    BNE &2617                              ; @2620 D0 F5
    RTS                                    ; @2622 60

; ---------------------------------------------------------------------------
; Map logical sprite ID to raw bitmap metadata and alignment-aware blitter state.
decode_sprite_descriptor:
    TYA                                    ; @2623 98
    PHA                                    ; @2624 48
    LDA logical_sprite_descriptors,Y       ; @2625 B9 52 27
    PHA                                    ; @2628 48
    AND #&FC                               ; @2629 29 FC
    LSR A                                  ; @262B 4A
    TAY                                    ; @262C A8
    LDA &277C,Y                            ; @262D B9 7C 27
    ADC #&52                               ; @2630 69 52
    STA sprite_src_lo                      ; @2632 85 04
    LDA &277D,Y                            ; @2634 B9 7D 27
    ADC #&27                               ; @2637 69 27
    STA sprite_src_hi                      ; @2639 85 05
    LDA &277E,Y                            ; @263B B9 7E 27
    STA sprite_width                       ; @263E 85 06
    LDA &277F,Y                            ; @2640 B9 7F 27
    STA sprite_height                      ; @2643 85 07
    LDA sprite_metadata,Y                  ; @2645 B9 7B 27
    ADC work_x                             ; @2648 65 00
    STA work_x                             ; @264A 85 00
    LDA &2780,Y                            ; @264C B9 80 27
    CLC                                    ; @264F 18
    ADC work_y                             ; @2650 65 01
    STA work_y                             ; @2652 85 01
    PLA                                    ; @2654 68
    AND #&03                               ; @2655 29 03
    ASL A                                  ; @2657 0A
    ASL A                                  ; @2658 0A
    STA &1C                                ; @2659 85 1C
    AND #&08                               ; @265B 29 08
    BEQ loc_2668                           ; @265D F0 09
    LDA work_x                             ; @265F A5 00
    ADC sprite_width                       ; @2661 65 06
    SEC                                    ; @2663 38
    SBC #&01                               ; @2664 E9 01
    STA work_x                             ; @2666 85 00

; ---------------------------------------------------------------------------
loc_2668:
    PLA                                    ; @2668 68
    TAY                                    ; @2669 A8
    RTS                                    ; @266A 60

; ---------------------------------------------------------------------------
; Procedurally XOR-render one curved tractor-beam layer.
draw_beam_layer:
    LDX beam_phase                         ; @266B A6 BC
    STX beam_curve_radius                  ; @266D 86 BE
    TXA                                    ; @266F 8A
    AND #&03                               ; @2670 29 03
    TAY                                    ; @2672 A8
    LDA beam_colour_masks,Y                ; @2673 B9 32 27
    STA xor_mask                           ; @2676 85 44
    LDA beam_origin_y                      ; @2678 A5 C0
    LSR A                                  ; @267A 4A
    SEC                                    ; @267B 38
    SBC beam_phase                         ; @267C E5 BC
    ASL A                                  ; @267E 0A
    ASL A                                  ; @267F 0A
    STA collision_top                      ; @2680 85 63
    LDA #&00                               ; @2682 A9 00
    STA beam_curve_step                    ; @2684 85 BD
    ADC beam_phase                         ; @2686 65 BC
    DEX                                    ; @2688 CA
    BNE &2686                              ; @2689 D0 FB
    STA beam_curve_accum                   ; @268B 85 BF
    STA beam_curve_limit                   ; @268D 85 C2
    LDA beam_centre_x                      ; @268F A5 C1
    STA collision_left                     ; @2691 85 61
    STA collision_right                    ; @2693 85 62
    JSR plot_beam_pixel                    ; @2695 20 36 27
    LDA beam_curve_accum                   ; @2698 A5 BF
    SEC                                    ; @269A 38
    ADC beam_curve_step                    ; @269B 65 BD
    ADC beam_curve_step                    ; @269D 65 BD
    INC beam_curve_step                    ; @269F E6 BD
    INC collision_right                    ; @26A1 E6 62
    DEC collision_left                     ; @26A3 C6 61
    BCS loc_26AB                           ; @26A5 B0 04
    CMP beam_curve_limit                   ; @26A7 C5 C2
    BCC loc_26B4                           ; @26A9 90 09

; ---------------------------------------------------------------------------
loc_26AB:
    CLC                                    ; @26AB 18
    SBC beam_curve_radius                  ; @26AC E5 BE
    SBC beam_curve_radius                  ; @26AE E5 BE
    DEC beam_curve_radius                  ; @26B0 C6 BE
    INC collision_top                      ; @26B2 E6 63

; ---------------------------------------------------------------------------
loc_26B4:
    STA beam_curve_accum                   ; @26B4 85 BF
    LDA collision_left                     ; @26B6 A5 61
    JSR plot_beam_pixel                    ; @26B8 20 36 27
    LDA collision_right                    ; @26BB A5 62
    JSR plot_beam_pixel                    ; @26BD 20 36 27
    LDA beam_curve_step                    ; @26C0 A5 BD
    CMP beam_curve_radius                  ; @26C2 C5 BE
    BCC &2698                              ; @26C4 90 D2
    RTS                                    ; @26C6 60

; ---------------------------------------------------------------------------
service_beam_state:
    TXA                                    ; @26C7 8A
    PHA                                    ; @26C8 48
    JSR step_beam_lifecycle                ; @26C9 20 D3 26
    PLA                                    ; @26CC 68
    TAX                                    ; @26CD AA
    BCC &26E9                              ; @26CE 90 19
    JMP advance_state_and_draw             ; @26D0 4C DF 1E

; ---------------------------------------------------------------------------
; Open layers 3..15, hold complete beam, then XOR-remove layers in reverse.
step_beam_lifecycle:
    BIT beam_active                        ; @26D3 24 C3
    BPL loc_26FA                           ; @26D5 10 23
    LDA beam_closing                       ; @26D7 A5 C4
    BNE loc_26F0                           ; @26D9 D0 15
    INC beam_phase                         ; @26DB E6 BC
    BMI loc_26EA                           ; @26DD 30 0B
    LDA beam_phase                         ; @26DF A5 BC
    CMP #&10                               ; @26E1 C9 10
    BCS loc_26E8                           ; @26E3 B0 03
    JSR draw_beam_layer                    ; @26E5 20 6B 26

; ---------------------------------------------------------------------------
loc_26E8:
    CLC                                    ; @26E8 18
    RTS                                    ; @26E9 60

; ---------------------------------------------------------------------------
loc_26EA:
    DEC beam_closing                       ; @26EA C6 C4
    LDA #&10                               ; @26EC A9 10
    STA beam_phase                         ; @26EE 85 BC

; ---------------------------------------------------------------------------
loc_26F0:
    DEC beam_phase                         ; @26F0 C6 BC
    LDA beam_phase                         ; @26F2 A5 BC
    CMP #&03                               ; @26F4 C9 03
    BCS &26E5                              ; @26F6 B0 ED
    INC beam_active                        ; @26F8 E6 C3

; ---------------------------------------------------------------------------
loc_26FA:
    SEC                                    ; @26FA 38
    RTS                                    ; @26FB 60

; ---------------------------------------------------------------------------
force_finish_beam:
    JSR step_beam_lifecycle                ; @26FC 20 D3 26
    BCC force_finish_beam                  ; @26FF 90 FB
    RTS                                    ; @2701 60

; ---------------------------------------------------------------------------
select_special_queen_attack:
    LDA #&18                               ; @2702 A9 18
    STA object_state,X                     ; @2704 9D 66 05
    JSR erase_object                       ; @2707 20 CC 0E
    STX beam_owner_slot                    ; @270A 86 C5
    JMP advance_state_and_redispatch       ; @270C 4C AC 1E

; ---------------------------------------------------------------------------
; Set owner geometry, capture bounds and lifecycle for special Queen attack.
init_tractor_beam:
    LDY #&FF                               ; @270F A0 FF
    STY beam_active                        ; @2711 84 C3
    INY                                    ; @2713 C8
    STY beam_closing                       ; @2714 84 C4
    INY                                    ; @2716 C8
    INY                                    ; @2717 C8
    STY beam_phase                         ; @2718 84 BC
    LDA object_x,X                         ; @271A BD 00 04
    SEC                                    ; @271D 38
    SBC #&06                               ; @271E E9 06
    STA beam_capture_left                  ; @2720 85 C6
    ADC #&07                               ; @2722 69 07
    STA beam_centre_x                      ; @2724 85 C1
    ADC #&04                               ; @2726 69 04
    STA beam_capture_right                 ; @2728 85 C7
    LDY object_y,X                         ; @272A BC 49 04
    STY beam_origin_y                      ; @272D 84 C0
    JMP advance_state_and_draw             ; @272F 4C DF 1E
    ; DATA &2732-&2735
    EQUB &30, &FC, &3C, &FF    ; @2732

; ---------------------------------------------------------------------------
plot_beam_pixel:
    STA work_x                             ; @2736 85 00
    LDA collision_top                      ; @2738 A5 63
    LSR A                                  ; @273A 4A
    PHP                                    ; @273B 08
    STA work_y                             ; @273C 85 01
    LDA #&01                               ; @273E A9 01
    STA sprite_height                      ; @2740 85 07
    JSR coord_to_mode2_address             ; @2742 20 01 0D
    PLP                                    ; @2745 28
    LDY #&00                               ; @2746 A0 00
    BCS loc_274B                           ; @2748 B0 01
    INY                                    ; @274A C8

; ---------------------------------------------------------------------------
loc_274B:
    LDA (screen_lo),Y                      ; @274B B1 02
    EOR xor_mask                           ; @274D 45 44
    STA (screen_lo),Y                      ; @274F 91 02
    RTS                                    ; @2751 60


; ZALAGA V10 - SYMBOLIC PERMANENT DATA TAIL
; &2752-&2FFF
;
; The executable engine ends at &2751. Everything below is live, permanent
; game data: logical sprite descriptors, 15 physical sprite metadata records,
; packed bitmap bytes, six ENVELOPE blocks, six fixed SOUND blocks and messages.
; Overlapping sprite bitmap interpretations are intentional.

; ----------------------------------------------------------------------------
; FLATTENED MODULE: 05_permanent_data.asm
; ----------------------------------------------------------------------------
; ZALAGA V10 - Sprite descriptors/bitmaps, sound definitions and message data
; Sequential module included by ../zalaga.asm.

logical_sprite_descriptors:                         ; &2752
    ; 41 bytes: high 6 bits select raw bitmap group; low 2 bits select alignment.
    EQUB &25, &19, &0D, &00, &0C, &18, &24, &1A, &0E, &02, &0F, &1B, &55, &49, &3D, &30  ; &2752
    EQUB &3C, &48, &54, &4A, &3E, &32, &3F, &4B, &85, &79, &6D, &60, &6C, &78, &84, &7A  ; &2762
    EQUB &6E, &62, &6F, &7B, &90, &9C, &A8, &A9, &AA                                     ; &2772

sprite_metadata_records:                         ; &277B
    ; 15 x 6-byte records: x-offset, bitmap pointer offset, width, height, y-offset.
    EQUB &00, &83, &00, &04, &16, &00, &00, &DA, &00, &07, &11, &00, &00, &4C, &01, &07  ; &277B
    EQUB &13, &00, &00, &D1, &01, &06, &0F, &00, &00, &2B, &02, &06, &10, &00, &00, &8A  ; &278B
    EQUB &02, &07, &13, &00, &00, &0A, &03, &06, &17, &00, &00, &92, &03, &06, &11, &00  ; &279B
    EQUB &FF, &F8, &03, &07, &15, &00, &FF, &85, &04, &08, &15, &00, &FF, &2A, &05, &07  ; &27AB
    EQUB &17, &00, &FF, &CB, &05, &07, &17, &00, &00, &68, &06, &05, &0A, &00, &00, &9A  ; &27BB
    EQUB &06, &02, &08, &00, &00, &9A, &06, &06, &13, &00                                ; &27CB

sprite_bitmap_guard_group0:                         ; &27D5
    EQUB &44, &C3, &C3, &C3, &41, &41, &00, &00, &05, &05, &0F, &0F, &05, &05, &00, &00  ; &27D5
    EQUB &41, &41, &C3, &C3, &C3, &44, &CC, &64, &64, &64, &30, &30, &30, &30, &0B, &0B  ; &27E5
    EQUB &0B, &0B, &0B, &0B, &30, &30, &30, &30, &64, &64, &64, &CC, &00, &88, &88, &C9  ; &27F5
    EQUB &98, &98, &11, &11, &31, &31, &30, &30, &31, &31, &11, &11, &98, &98, &C9, &88  ; &2805
    EQUB &88, &00, &00, &82, &82, &88, &88, &00, &00, &22, &22, &22, &20, &20, &22, &22  ; &2815
    EQUB &22, &00, &00, &88, &88, &82, &82                                               ; &2825

sprite_bitmap_guard_group1:                         ; &282C
    EQUB &00, &00, &00, &00, &00, &05, &05, &05, &00, &00, &00, &00, &C3, &41, &41, &00  ; &282C
    EQUB &00, &41, &C3, &00, &00, &0F, &0F, &0F, &0F, &0F, &01, &00, &10, &10, &92, &30  ; &283C
    EQUB &98, &44, &30, &92, &92, &41, &41, &0B, &03, &07, &07, &07, &0F, &30, &64, &64  ; &284C
    EQUB &64, &CC, &88, &CC, &64, &64, &30, &64, &64, &0B, &0B, &03, &12, &12, &12, &00  ; &285C
    EQUB &00, &00, &00, &00, &00, &88, &88, &88, &88, &00, &11, &31, &31, &30, &33, &33  ; &286C
    EQUB &33, &20, &20, &10, &00, &00, &00, &00, &10, &20, &20, &22, &33, &33, &30, &32  ; &287C
    EQUB &22, &00, &00, &00, &88, &82, &00, &00, &82, &88, &00, &00, &00, &00, &00, &00  ; &288C
    EQUB &00, &00                                                                        ; &289C

sprite_bitmap_guard_group2_overlap:                         ; &289E
    EQUB &00, &00, &00, &00, &00, &88, &88, &CC, &64, &30, &92, &92, &C3, &C3, &41, &00  ; &289E
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &CC, &98, &30, &61, &C3  ; &28AE
    EQUB &C3, &C3, &82, &00, &00, &00, &00, &00, &00, &0F, &0F, &0F, &0B, &03, &07, &0F  ; &28BE
    EQUB &25, &83, &83, &00, &00, &10, &20, &20, &C9, &44, &00, &00, &44, &4E, &1A, &12  ; &28CE
    EQUB &03, &0F, &0F, &0B, &03, &30, &30, &32, &33, &33, &11, &11, &88, &98, &98, &98  ; &28DE
    EQUB &30, &30, &30, &61, &41, &00, &12, &30, &33, &33, &31, &30, &22, &22, &00, &00  ; &28EE
    EQUB &00, &82, &61, &C3, &C3, &C3, &82, &00, &00, &30, &10, &00, &22, &22, &22, &00  ; &28FE
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &88, &82, &00  ; &290E
    EQUB &00, &00, &00, &00, &00                                                         ; &291E

sprite_bitmap_guard_group3:                         ; &2923
    EQUB &41, &41, &C9, &C9, &98, &98, &98, &CC, &CC, &44, &00, &00, &00, &10, &C6, &00  ; &2923
    EQUB &00, &82, &82, &C3, &30, &30, &30, &30, &88, &00, &11, &31, &11, &00, &00, &05  ; &2933
    EQUB &0F, &0F, &03, &0F, &0F, &03, &03, &30, &30, &32, &32, &32, &32, &00, &00, &0A  ; &2943
    EQUB &0A, &43, &1A, &1A, &12, &12, &20, &20, &33, &33, &33, &22, &41, &41, &41, &C3  ; &2953
    EQUB &92, &30, &30, &64, &64, &CC, &00, &00, &20, &10, &44, &00, &00, &88, &88, &88  ; &2963
    EQUB &88, &88, &88, &88, &00, &00, &00, &00, &00, &82                                ; &2973

sprite_bitmap_drome_group4:                         ; &297D
    EQUB &40, &C0, &C0, &03, &03, &00, &05, &0F, &05, &00, &03, &03, &C0, &C0, &40, &00  ; &297D
    EQUB &00, &80, &C0, &03, &03, &1B, &1B, &1B, &1B, &1B, &03, &03, &C0, &80, &00, &00  ; &298D
    EQUB &00, &00, &00, &02, &02, &03, &33, &33, &33, &03, &02, &02, &00, &00, &00, &00  ; &299D
    EQUB &00, &40, &C0, &81, &03, &17, &3F, &3F, &3F, &17, &03, &81, &C0, &40, &00, &00  ; &29AD
    EQUB &C0, &C0, &C0, &03, &2A, &30, &30, &3A, &30, &30, &2A, &03, &C0, &C0, &C0, &00  ; &29BD
    EQUB &C0, &80, &80, &03, &00, &00, &20, &30, &20, &00, &00, &03, &80, &80, &C0       ; &29CD

sprite_bitmap_drome_group5:                         ; &29DC
    EQUB &00, &00, &00, &00, &00, &02, &03, &81, &C0, &C0, &C0, &40, &00, &00, &00, &00  ; &29DC
    EQUB &00, &00, &00, &01, &01, &00, &0F, &0F, &0F, &05, &07, &03, &81, &C0, &80, &00  ; &29EC
    EQUB &00, &00, &00, &00, &00, &00, &C0, &42, &03, &01, &0F, &1B, &1B, &33, &03, &01  ; &29FC
    EQUB &01, &01, &40, &40, &00, &00, &00, &00, &00, &80, &C0, &C0, &42, &02, &02, &03  ; &2A0C
    EQUB &23, &37, &37, &3F, &3F, &17, &81, &C0, &C0, &C0, &40, &40, &00, &00, &00, &00  ; &2A1C
    EQUB &00, &42, &03, &2B, &3F, &3A, &3A, &30, &30, &02, &03, &81, &C0, &80, &80, &00  ; &2A2C
    EQUB &00, &00, &00, &40, &C0, &C0, &42, &03, &01, &20, &20, &30, &30, &00, &02, &02  ; &2A3C
    EQUB &00, &00, &00, &00, &00, &00, &80, &C0, &C0, &80, &80, &02, &02, &00, &00, &00  ; &2A4C

sprite_bitmap_drome_group6:                         ; &2A5C
    EQUB &00, &00, &00, &00, &00, &01, &01, &81, &81, &C0, &C0, &00, &00, &00, &00, &00  ; &2A5C
    EQUB &00, &40, &40, &40, &00, &00, &00, &00, &00, &00, &05, &05, &05, &05, &07, &13  ; &2A6C
    EQUB &13, &03, &03, &03, &01, &01, &81, &81, &C0, &C0, &C0, &C0, &C0, &40, &01, &01  ; &2A7C
    EQUB &01, &0A, &0F, &0F, &1B, &33, &33, &33, &33, &17, &3F, &3F, &3F, &3A, &12, &12  ; &2A8C
    EQUB &02, &03, &81, &01, &00, &C0, &C0, &42, &42, &42, &42, &03, &03, &03, &23, &2B  ; &2A9C
    EQUB &3F, &3F, &3A, &3A, &30, &30, &30, &30, &10, &00, &00, &00, &00, &80, &80, &80  ; &2AAC
    EQUB &00, &00, &00, &00, &C0, &42, &42, &42, &42, &03, &21, &21, &20, &20, &20, &20  ; &2ABC
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &80, &80, &C0, &C0, &C0  ; &2ACC
    EQUB &80, &80, &02, &02, &02, &00, &00, &00                                          ; &2ADC

sprite_bitmap_drome_group7:                         ; &2AE4
    EQUB &00, &00, &40, &C0, &40, &00, &00, &00, &00, &00, &00, &40, &40, &C0, &C0, &C0  ; &2AE4
    EQUB &80, &01, &81, &81, &81, &81, &81, &81, &01, &00, &01, &03, &17, &17, &12, &02  ; &2AF4
    EQUB &02, &02, &00, &05, &0F, &0F, &0F, &33, &33, &13, &17, &3F, &3F, &3F, &35, &30  ; &2B04
    EQUB &30, &30, &10, &01, &01, &0B, &0B, &0B, &23, &23, &03, &02, &2B, &2B, &3F, &35  ; &2B14
    EQUB &30, &20, &20, &00, &00, &80, &C0, &C0, &C0, &80, &80, &00, &00, &00, &02, &42  ; &2B24
    EQUB &42, &42, &42, &42, &02, &00, &00, &00, &80, &00, &00, &00, &00, &00, &00, &00  ; &2B34
    EQUB &00, &80, &80, &80, &80, &80                                                    ; &2B44

sprite_bitmap_queen_group8:                         ; &2B4A
    EQUB &44, &CC, &C9, &64, &C6, &82, &C3, &41, &00, &00, &00, &00, &00, &41, &C3, &82  ; &2B4A
    EQUB &C6, &64, &C9, &CC, &44, &98, &82, &00, &00, &98, &82, &82, &00, &00, &00, &00  ; &2B5A
    EQUB &00, &00, &00, &82, &82, &98, &00, &00, &82, &98, &30, &00, &00, &00, &30, &10  ; &2B6A
    EQUB &10, &30, &1A, &30, &10, &30, &1A, &30, &10, &10, &30, &00, &00, &00, &30, &30  ; &2B7A
    EQUB &10, &10, &00, &20, &20, &10, &10, &10, &10, &10, &10, &10, &10, &10, &20, &20  ; &2B8A
    EQUB &00, &10, &10, &30, &00, &00, &20, &20, &10, &30, &10, &10, &10, &30, &31, &30  ; &2B9A
    EQUB &10, &10, &10, &30, &10, &20, &20, &00, &00, &00, &00, &00, &00, &00, &33, &33  ; &2BAA
    EQUB &26, &26, &26, &33, &26, &26, &26, &33, &33, &00, &00, &00, &00, &00, &00, &00  ; &2BBA
    EQUB &00, &00, &00, &00, &22, &22, &33, &22, &22, &22, &33, &22, &22                 ; &2BCA

sprite_bitmap_queen_group9:                         ; &2BD7
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &41, &C3, &C6, &64  ; &2BD7
    EQUB &C9, &C9, &CC, &44, &00, &44, &98, &64, &C6, &C3, &41, &00, &00, &00, &00, &00  ; &2BE7
    EQUB &00, &00, &82, &82, &C9, &98, &00, &82, &98, &10, &30, &00, &00, &98, &82, &00  ; &2BF7
    EQUB &00, &10, &05, &10, &00, &10, &05, &10, &00, &00, &20, &30, &00, &00, &30, &30  ; &2C07
    EQUB &00, &00, &20, &30, &00, &30, &20, &20, &20, &20, &20, &20, &20, &20, &30, &10  ; &2C17
    EQUB &30, &00, &10, &30, &20, &30, &10, &00, &20, &20, &10, &20, &20, &20, &20, &30  ; &2C27
    EQUB &20, &20, &20, &10, &20, &10, &30, &20, &00, &00, &00, &20, &20, &30, &30, &30  ; &2C37
    EQUB &31, &31, &31, &31, &33, &31, &31, &31, &31, &31, &20, &00, &00, &00, &00, &00  ; &2C47
    EQUB &00, &00, &00, &00, &22, &33, &19, &19, &19, &33, &19, &19, &19, &33, &22, &00  ; &2C57
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &00, &22, &00, &00, &00  ; &2C67
    EQUB &22, &00, &00, &00, &00                                                         ; &2C77

sprite_bitmap_queen_group10:                         ; &2C7C
    EQUB &00, &00, &00, &10, &92, &64, &64, &20, &20, &20, &20, &20, &30, &10, &10, &00  ; &2C7C
    EQUB &00, &00, &00, &00, &00, &00, &00, &00, &41, &C3, &C3, &C9, &61, &20, &20, &30  ; &2C8C
    EQUB &30, &10, &00, &00, &00, &20, &30, &10, &00, &00, &00, &00, &00, &00, &00, &82  ; &2C9C
    EQUB &00, &00, &00, &00, &0A, &0F, &05, &10, &30, &20, &30, &10, &10, &10, &30, &30  ; &2CAC
    EQUB &00, &00, &00, &00, &00, &00, &41, &C3, &41, &00, &0A, &0F, &05, &30, &30, &00  ; &2CBC
    EQUB &10, &30, &10, &30, &31, &33, &26, &26, &33, &11, &00, &00, &CC, &61, &61, &88  ; &2CCC
    EQUB &64, &92, &10, &30, &20, &00, &00, &30, &32, &33, &33, &33, &33, &19, &19, &33  ; &2CDC
    EQUB &33, &22, &22, &88, &CC, &C6, &92, &10, &00, &00, &20, &20, &30, &10, &30, &10  ; &2CEC
    EQUB &30, &33, &33, &0C, &0C, &33, &33, &11, &11, &00, &00, &00, &00, &00, &20, &20  ; &2CFC
    EQUB &30, &10, &10, &10, &10, &10, &30, &30, &20, &22, &22, &22, &22, &00, &00, &00  ; &2D0C
    EQUB &00                                                                             ; &2D1C

sprite_bitmap_queen_group11:                         ; &2D1D
    EQUB &44, &CC, &98, &C9, &61, &20, &20, &20, &20, &20, &20, &20, &20, &30, &10, &00  ; &2D1D
    EQUB &00, &00, &00, &00, &00, &00, &00, &88, &30, &92, &CC, &C9, &C9, &61, &20, &20  ; &2D2D
    EQUB &30, &20, &20, &20, &10, &30, &30, &31, &11, &11, &11, &00, &00, &00, &00, &00  ; &2D3D
    EQUB &82, &C3, &C3, &82, &00, &05, &25, &30, &00, &00, &30, &20, &10, &30, &33, &0C  ; &2D4D
    EQUB &0C, &33, &33, &11, &11, &00, &00, &00, &41, &41, &00, &00, &05, &25, &30, &00  ; &2D5D
    EQUB &00, &30, &20, &32, &32, &33, &26, &26, &33, &33, &11, &11, &00, &10, &92, &C6  ; &2D6D
    EQUB &C3, &C3, &41, &00, &20, &30, &00, &00, &20, &30, &10, &30, &33, &19, &19, &33  ; &2D7D
    EQUB &22, &00, &00, &CC, &64, &92, &C9, &C9, &88, &20, &20, &20, &20, &20, &20, &20  ; &2D8D
    EQUB &10, &30, &20, &20, &00, &00, &00, &00, &00, &00, &00, &88, &88, &88, &20, &20  ; &2D9D
    EQUB &20, &20, &20, &20, &20, &20, &20, &20, &00, &00, &00, &00, &00                 ; &2DAD

sprite_bitmap_fighter:                         ; &2DBA
    EQUB &00, &00, &00, &00, &2A, &02, &35, &3F, &3F, &3A, &00, &00, &2A, &17, &35, &3F  ; &2DBA
    EQUB &3F, &3B, &31, &11, &2A, &2A, &2A, &3F, &3F, &37, &37, &1B, &1B, &33, &00, &00  ; &2DCA
    EQUB &2A, &02, &20, &2A, &3F, &3F, &35, &10, &00, &00, &00, &00, &2A, &02, &20, &2A  ; &2DDA
    EQUB &2A, &2A                                                                        ; &2DEA

sprite_bitmap_projectile_and_explosion_shared:                         ; &2DEC
    EQUB &00, &01, &00, &00, &0A, &00, &01, &00, &02, &00, &05, &00, &0A, &00, &02, &05  ; &2DEC
    EQUB &00, &00, &00, &0A, &00, &00, &02, &14, &00, &00, &0A, &00, &14, &00, &14, &02  ; &2DFC
    EQUB &00, &00, &00, &00, &02, &01, &0A, &00, &02, &00, &14, &00, &00, &22, &20, &11  ; &2E0C
    EQUB &20, &00, &00, &28, &01, &28, &00, &00, &05, &02, &05, &00, &14, &00, &20, &32  ; &2E1C
    EQUB &00, &38, &20, &00, &31, &00, &00, &00, &14, &0A, &00, &02, &02, &00, &00, &05  ; &2E2C
    EQUB &28, &00, &00, &01, &14, &00, &14, &00, &00, &28, &00, &05, &02, &05, &00, &00  ; &2E3C
    EQUB &00, &02, &00, &05, &00, &0A, &00, &00, &01, &00, &00, &05, &02, &00, &00, &02  ; &2E4C
    EQUB &00, &00                                                                        ; &2E5C

sound_envelope_0:                         ; &2E5E
    ; 14-byte BBC ENVELOPE definition.
    EQUB &01, &81, &00, &FF, &02, &0C, &0C, &1E, &00, &00, &00, &9C, &00, &00            ; &2E5E

sound_envelope_1:                         ; &2E6C
    ; 14-byte BBC ENVELOPE definition.
    EQUB &02, &02, &00, &00, &00, &01, &01, &01, &6E, &FD, &FE, &9C, &6E, &5A            ; &2E6C

sound_envelope_2:                         ; &2E7A
    ; 14-byte BBC ENVELOPE definition.
    EQUB &03, &81, &01, &00, &FE, &02, &02, &3C, &00, &00, &00, &00, &00, &00            ; &2E7A

sound_envelope_music:                         ; &2E88
    ; 14-byte BBC ENVELOPE definition.
    EQUB &01, &01, &00, &00, &00, &01, &01, &01, &5A, &FC, &FF, &FF, &5A, &46            ; &2E88

sound_envelope_player_loss:                         ; &2E96
    ; 14-byte BBC ENVELOPE definition.
    EQUB &01, &82, &00, &01, &00, &06, &01, &32, &73, &01, &FE, &88, &73, &7E            ; &2E96

sound_envelope_launch:                         ; &2EA4
    ; 14-byte BBC ENVELOPE definition.
    EQUB &04, &82, &00, &02, &FF, &03, &0A, &46, &06, &FF, &FE, &82, &6E, &78            ; &2EA4

sound_hit_part1:                         ; &2EB2
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &10, &00, &02, &00, &03, &00, &08, &00                                          ; &2EB2

sound_hit_part2:                         ; &2EBA
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &11, &00, &01, &00, &EC, &00, &08, &00                                          ; &2EBA

sound_player_fire_part1:                         ; &2EC2
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &10, &00, &02, &00, &07, &00, &0C, &00                                          ; &2EC2

sound_player_fire_part2:                         ; &2ECA
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &11, &00, &03, &00, &F0, &00, &0C, &00                                          ; &2ECA

sound_player_loss:                         ; &2ED2
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &10, &00, &01, &00, &05, &00, &19, &00                                          ; &2ED2

sound_alien_launch:                         ; &2EDA
    ; 8-byte BBC SOUND/OSWORD 7 parameter block.
    EQUB &13, &00, &04, &00, &78, &00, &3C, &00                                          ; &2EDA

msg_well_done:                         ; &2EE2
    ; colour=&0C, x=22, y=114, text='Well Done!!'
    EQUB &0C, &16, &72, &57, &65, &6C, &6C, &20, &44, &6F, &6E, &65, &21, &A1            ; &2EE2

msg_type_your_name:                         ; &2EF0
    ; colour=&FC, x=8, y=12, text='Please type your name'
    EQUB &FC, &08, &0C, &50, &6C, &65, &61, &73, &65, &20, &74, &79, &70, &65, &20, &79  ; &2EF0
    EQUB &6F, &75, &72, &20, &6E, &61, &6D, &E5                                          ; &2F00

msg_press_return_or_fire:                         ; &2F08
    ; colour=&3F, x=6, y=12, text='Press RETURN or (fire)'
    EQUB &3F, &06, &0C, &50, &72, &65, &73, &73, &20, &52, &45, &54, &55, &52, &4E, &20  ; &2F08
    EQUB &6F, &72, &20, &28, &66, &69, &72, &65, &A9                                     ; &2F18

msg_copyright:                         ; &2F21
    ; colour=&0C, x=12, y=4, text="(C) Aardvark '83"
    EQUB &0C, &0C, &04, &28, &43, &29, &20, &41, &61, &72, &64, &76, &61, &72, &6B, &20  ; &2F21
    EQUB &27, &38, &B3                                                                   ; &2F31

msg_zalagan_heroes:                         ; &2F34
    ; colour=&0C, x=20, y=114, text='Zalagan Heroes'
    EQUB &0C, &14, &72, &5A, &61, &6C, &61, &67, &61, &6E, &20, &48, &65, &72, &6F, &65  ; &2F34
    EQUB &F3                                                                             ; &2F44

msg_ready:                         ; &2F45
    ; colour=&3C, x=32, y=64, text='Ready'
    EQUB &3C, &20, &40, &52, &65, &61, &64, &F9                                          ; &2F45

msg_player_one:                         ; &2F4D
    ; colour=&3C, x=24, y=72, text='Player One'
    EQUB &3C, &18, &48, &50, &6C, &61, &79, &65, &72, &20, &4F, &6E, &E5                 ; &2F4D

msg_player_two:                         ; &2F5A
    ; colour=&3C, x=24, y=72, text='Player Two'
    EQUB &3C, &18, &48, &50, &6C, &61, &79, &65, &72, &20, &54, &77, &EF                 ; &2F5A

msg_1up:                         ; &2F67
    ; colour=&C3, x=0, y=126, text='1UP'
    EQUB &C3, &00, &7E, &31, &55, &D0                                                    ; &2F67

msg_2up:                         ; &2F6D
    ; colour=&C3, x=54, y=126, text='2UP'
    EQUB &C3, &36, &7E, &32, &55, &D0                                                    ; &2F6D

msg_stage:                         ; &2F73
    ; colour=&3C, x=25, y=68, text='STAGE   '
    EQUB &3C, &19, &44, &53, &54, &41, &47, &45, &20, &20, &A0                           ; &2F73

msg_challenge_stage:                         ; &2F7E
    ; colour=&3C, x=20, y=64, text='CHALLENGE STAGE'
    EQUB &3C, &14, &40, &43, &48, &41, &4C, &4C, &45, &4E, &47, &45, &20, &53, &54, &41  ; &2F7E
    EQUB &47, &C5                                                                        ; &2F8E

msg_perfect:                         ; &2F90
    ; colour=&0C, x=23, y=74, text='Perfect !'
    EQUB &0C, &17, &4A, &50, &65, &72, &66, &65, &63, &74, &20, &A1                      ; &2F90

msg_hits:                         ; &2F9C
    ; colour=&33, x=23, y=64, text='Hits =  0'
    EQUB &33, &17, &40, &48, &69, &74, &73, &20, &3D, &20, &20, &B0                      ; &2F9C

msg_bonus:                         ; &2FA8
    ; colour=&0F, x=20, y=56, text='Bonus =   00'
    EQUB &0F, &14, &38, &42, &6F, &6E, &75, &73, &20, &3D, &20, &20, &20, &30, &B0       ; &2FA8

msg_special_bonus:                         ; &2FB7
    ; colour=&0F, x=17, y=56, text='Special Bonus!'
    EQUB &0F, &11, &38, &53, &70, &65, &63, &69, &61, &6C, &20, &42, &6F, &6E, &75, &73  ; &2FB7
    EQUB &A1                                                                             ; &2FC7

msg_sound_marker:                         ; &2FC8
    ; colour=&0C, x=70, y=0, text='Q'
    EQUB &0C, &46, &00, &D1                                                              ; &2FC8

msg_one:                         ; &2FCC
    ; colour=&0F, x=76, y=0, text='1'
    EQUB &0F, &4C, &00, &B1                                                              ; &2FCC

msg_two:                         ; &2FD0
    ; colour=&0F, x=76, y=0, text='2'
    EQUB &0F, &4C, &00, &B2                                                              ; &2FD0

msg_keyboard_marker_k:                         ; &2FD4
    ; colour=&33, x=73, y=0, text='K'
    EQUB &33, &49, &00, &CB                                                              ; &2FD4

msg_joystick_marker_j:                         ; &2FD8
    ; colour=&33, x=73, y=0, text='J'
    EQUB &33, &49, &00, &CA                                                              ; &2FD8

msg_game_over:                         ; &2FDC
    ; colour=&3C, x=26, y=64, text='Game Over'
    EQUB &3C, &1A, &40, &47, &61, &6D, &65, &20, &4F, &76, &65, &F2, &00, &19, &26, &E5  ; &2FDC
    EQUB &24, &02, &20, &36, &33, &12, &10, &0D, &2C, &0B, &09, &06, &05, &24, &63, &FF  ; &2FEC
    EQUB &00, &19, &26, &E5                                                              ; &2FFC

; ============================================================================
; WEB-ASSEMBLER BOOTSTRAP
; The generic boot loader has already copied this complete flat image to
; &0400-&3196.  This routine installs the extra page-1 fragment and the state
; formerly established by the protected loader, then enters the genuine startup.
; ============================================================================

ORG &3000

; `entry` is deliberately provided because the web assembler boot-disk dialog
; recognises it automatically as the default execution symbol.
entry:
bootstrap_entry:
    SEI
    CLD
    LDX #&FF
    TXS

    ; Install the static page-1 movement/trajectory fragment.  The active stack
    ; is kept at the top of page 1 and the destination stops at &01AF.
    LDX #&76
bootstrap_copy_page1:
    LDA page1_payload,X
    STA &0139,X
    DEX
    BPL bootstrap_copy_page1

    ; Initial zero-page/fixed state established by the original protected entry.
    LDA #&07
    STA &1E
    STA &49
    LDA #&01
    STA &1D

    LDA #&00
    STA &3B
    STA &79
    STA &3C
    STA &32
    STA &70
    STA &71

    LDA #&40
    STA &0D00

    LDA #&10
    LDX #&10
bootstrap_init_0b_workspace:
    STA &0B00,X
    DEX
    BPL bootstrap_init_0b_workspace

    ; Restore the MOS default vectors as the original loader did.
    LDA &FFB7
    STA temp45
    LDA &FFB8
    STA temp46

    LDY #&01
    LDA (temp45),Y
    STA mos_tick_source_flag

    ; Target the normal MOS 1.20 path.
    BMI bootstrap_vector_copy
    LDA #&FF
    STA mos_tick_source_flag

bootstrap_vector_copy:
    LDY #&35
bootstrap_copy_default_vectors:
    LDA (temp45),Y
    STA &0200,Y
    DEY
    BPL bootstrap_copy_default_vectors

    ; Install Zalaga's vertical-sync event handler.
    LDA #<event_tick_handler
    STA &0220
    LDA #>event_tick_handler
    STA &0221

    ; Original machine-loader MOS event/keyboard setup.
    LDX #&04
    LDA #&0E
    JSR OSBYTE

    LDX #&00
    LDA #&0D
    JSR OSBYTE
    LDX #&01
    LDA #&0D
    JSR OSBYTE
    LDX #&02
    LDA #&0D
    JSR OSBYTE
    LDX #&03
    LDA #&0D
    JSR OSBYTE
    LDX #&05
    LDA #&0D
    JSR OSBYTE
    LDX #&06
    LDA #&0D
    JSR OSBYTE
    LDX #&07
    LDA #&0D
    JSR OSBYTE
    LDX #&08
    LDA #&0D
    JSR OSBYTE

    LDY #&FF
    LDX #&00
    LDA #&FE
    JSR OSBYTE

    LDY #&00
    LDX #&02
    LDA #&C8
    JSR OSBYTE

    LDY #&00
    LDX #&00
    LDA #&F7
    JSR OSBYTE

    LDX #&00
    LDA #&05
    JSR OSBYTE
    LDX #&01
    LDA #&04
    JSR OSBYTE
    LDX #&00
    LDA #&0C
    JSR OSBYTE

    ; Input vectors are part of the permanent engine.
    JSR install_input_vectors

    CLI
    JMP runtime_start

; Keep the page-1 source fragment outside the bootstrap code.  It is discarded
; naturally when MODE 2 screen memory takes over &3000 upwards.
ORG &3120
page1_payload:
    EQUB &2D, &7E, &4C, &0D, &EE, &EE, &EE, &6E, &2D, &6C, &4B, &0A, &09, &07, &26, &25    ; -> &0139
    EQUB &04, &02, &21, &FF, &23, &64, &4C, &4B, &EA, &8A, &06, &22, &01, &00, &17, &36    ; -> &0149
    EQUB &12, &2E, &0D, &0C, &0B, &EA, &EA, &EA, &EA, &4A, &FF, &2C, &41, &08, &0B, &EC    ; -> &0159
    EQUB &4C, &38, &0D, &38, &0F, &38, &11, &38, &12, &38, &12, &38, &12, &38, &13, &38    ; -> &0169
    EQUB &15, &38, &17, &38, &00, &38, &00, &38, &00, &38, &01, &38, &03, &38, &05, &38    ; -> &0179
    EQUB &06, &38, &06, &38, &06, &38, &06, &38, &07, &38, &0A, &38, &0C, &18, &0C, &18    ; -> &0189
    EQUB &0C, &18, &0C, &18, &0C, &18, &8C, &FF, &23, &6E, &EA, &EA, &6A, &0B, &2C, &FF    ; -> &0199
    EQUB &32, &3C, &EC, &EC, &EC, &0C, &FF    ; -> &01A9

page1_payload_end:
; page1 payload length = &77 bytes

; Expected flat build range: &0400-&3196. Boot-disk entry symbol: bootstrap_entry.
