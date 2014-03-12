#Driving NeoPixel LEDs from XMOS

This repo is a simple multi-core xCore test of a two-task approach to driving an Adafruit NeoPixel LED Strip.  The source is in XC, an extension of C with concurrency and support for high speed timing synchronized I/O capability at the language level.

For a view of how XCore I/O works compare the driver code in neopixel_led_task() to some other NeoPixel waveform generator code.  An example would be the [Adafruit_NeoPixel::show() routine](https://github.com/adafruit/Adafruit_NeoPixel/blob/master/Adafruit_NeoPixel.cpp#L60-793).

This particular code is able to do precise timing on AVR CPUs by employing cycle-counted assembly language that requires full attention of the CPU.  In the XCore case outputs are handled by ports that precisely synchronize the outputs themselves.

This application is designed for and tested on the XMOS startKIT, but it should be possible to change the XMOS target in the makefile (alter "TARGET = STARTKIT").

This project demonstrates that the xCore is capable of generating color data on the fly without any buffering due to the concurrency and speed features of the xCore.  Most actual applications, however, will want to generate color data into a compete frame/strip buffer ahead of the actual hardware output [like this program](https://github.com/teachop/xcore_neopixel_buffered) does.

###xcore_neopixel_leds
Two tasks make up the application, a pattern generator task and a driver task.  These are exchanging data through a channel, which is a language and hardware communication feature.  These two tasks are started in main using par.  Main connects them together with a channel passed to the tasks.

The task communication uses "streaming channels" - their high performance is important in this application (see the wiki).

In the example, 4 sets of paired tasks execute in parallel, each pair driving its own NeoPixel strip pattern.  While this is likely not the best approach (4 bit wide port?) it is easy and tests multi-tasking on the XCore chip.

Note that the driver tasks use extra test output pins for timing measurements.  These were used to evaluate channels vs. streaming channels vs. interfaces for performance.  The test outputs can be eliminated if desired.

####blinky_task

The pattern generator task presents a "wheel" rolling multi-color pattern on the RGB LEDs.  This pattern code came from an Adafruit or PJRC source but I lost track which - both have some nice code for driving NeoPixels!

####neopixel_led_task

The driver task uses the timed port output feature of the xCore processors.  This generates the serialized data pattern with the precise timing needed for the serial NeoPixel strip.
