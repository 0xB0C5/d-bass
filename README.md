D-Bass
======
Use the NES's DMC as a wave channel, and use its IRQs for timed code.

https://github.com/user-attachments/assets/411d44db-75e6-40b1-82df-d1e5088c91ba

Setup
-----
Warning: This is a work in progress.
It may have undocumented quirks.
It hasn't been tested on all NES variants.
Changes will not be backwards-compatible.

Use the cc65 toolset.

Place `d-bass.asm` and `d-bass.inc` in your source directory.

Edit `d-bass.inc` to configure its settings.

Include `d-bass.inc` in code files that need to interface with the library.

Modify your build process to build and link D-Bass:
```
ca65 d-bass.asm -o dbass.o --debug-info
[commands to build your code]
ld65 dbass.o [the rest of the command for the linker]
```

Modify your vectors to use d-bass's IRQ and NMI handlers:
```
.segment "VECTORS"
	.word dbass_nmi_handler
	.word [your_reset_vector]
	.word dbass_irq_handler
```

Create and export a custom IRQ handler for your raster effects:
```
.proc user_irq_handler
	[your code here]
	rts
.endproc
.export user_irq_handler
```

Create and export a custom NMI handler (or replace your existing one). Note that you don't need to preserve registers like you would for a raw NMI handler.
```
.proc user_nmi_handler
	lda #$02
	sta $4014
	[more VBlank code]
	rts
.endproc
```

Before you enable NMIs, call `jsr dbass_start` to initialize and start D-Bass.

Before you disable NMIs, call `jsr dbass_disable` to stop D-Bass. Note: this hasn't been tested.

While D-Bass is enabled, you must call `jsr dbass_update` once per frame, as soon as possible after your VBlank code.

Silencing Other Channels
------------------------
D-Bass currently writes `$1f` to `$4015` every DMC IRQ. Silencing channels via `$4015` will not work.

TODO : document how to silence other channels by other means and/or support preserving `$4015`.

Audio
-----
D-Bass produces a waveform that looks like this:
![Waveform](https://github.com/0xB0C5/d-bass/blob/main/docs/wave.png)

`dbass_period` is a 2-byte period for the wave, measured in 256ths of a DMC IRQ at rate `$e`.
To play a note with frequency `f` in Hz, set `dbass_period` to `1060604.8 / f`.

D-Bass audio works best when playing low notes (as a bass).
Low periods/high frequencies use more CPU and are distorted.
Periods below `$1000` are very distorted.
Periods below `$200` will not work.

`dbass_volume` is a 1-byte volume and timbre for the wave. It represents the number of DMC IRQs per period the wave will rise.
If the volume would cause the wave to rise for more than half the period, it instead rises for approximately half the period.

Custom User IRQs
----------------
The setting `DBASS_USER_IRQ_COUNT` determines how many times your custom IRQ handler will be called per frame.

The times at which your IRQ handler will be called are measured in DMC IRQs and "ticks".
One IRQ is 576 CPU cycles. One tick is 8 CPU cycles. There are 72 ticks per IRQ.

Your code should write these values to the tables `dbass_user_times_irqs` and `dbass_user_times_ticks` respectively.
Each table is 1 byte per user IRQ (`DBASS_USER_IRQ_COUNT` bytes).
Changes to these tables will take effect the next time `dbass_update` is called.

The times must be ordered earliest to latest, and each time must be at least 2 DMC IRQs after the previous.

Your IRQ handler will be called with `y` set to the index of the user IRQ (i.e. the first time in a frame it is 0, then 1, etc).

Your IRQ handler does NOT need to preserve any registers.

Your IRQ handler must return within about 500 CPU cycles.

The first time your IRQ handler is called must be after `dbass_update` is called. (This is why you want to call `dbass_update` as soon as possible after VBlank.)

Currently, D-Bass takes some time to measure the synchronization between NMI and IRQ.
This means your custom IRQs will be called at slightly the wrong times for the first up to 36 frames.

Feature Roadmap
===============

- Better way to enable/disable that plays more nicely with enabling/disabling PPU NMIs.
- Add a way to measure sync directly rather than relying entirely on dynamic corrections.
- Faster no-audio mode for projects that only need IRQs.
- Faster no-IRQ mode for projects that only need audio.
- Support dynamic user IRQ count.
- Support faster coarsely-timed user IRQs.
- Call `dbass_update` automatically from IRQs.
- Support IRQ-driven DMA-conflict-free controller reading.
- HQ audio mode for higher pitches at the expense of CPU.
- Support other waveforms: M-shaped waves and/or fixed-pattern waves.
