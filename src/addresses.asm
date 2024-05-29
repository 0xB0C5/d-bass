.segment "ZEROPAGE"

temp: .res 16

nmi_done: .res 1
nmi_temp: .res 1

joypad_buttons_p1: .res 1
joypad_buttons_p2: .res 1

joypad_presses_p1: .res 1
joypad_presses_p2: .res 1

ppu_pending_control: .res 1

ppu_pending_scroll_x: .res 1
ppu_pending_scroll_y: .res 1

ppu_text_addr: .res 2

frame_counter: .res 1
cpu_counter: .res 2

dmc_counters_lo: .res 2
dmc_counters_hi: .res 2

dmc_periods_lo: .res 2
dmc_periods_hi: .res 2

dmc_volumes: .res 2

dmc_output: .res 1

song_index: .res 1
song_counter: .res 1
song_volume_idx: .res 1
song_width_idx: .res 1
song_pitch_idx: .res 1
song_pitch: .res 1

.segment "OAM"
sprites: .res $100

.segment "BSS"

ppu_pending_text: .res 32
