#Driving NeoPixel LEDs from XMOS

This repo is a simple multi-core xCore test of a two-task approach to driving an Adafruit NeoPixel LED Strip.  The source is in xc, an extension of c with concurrency and support for high speed timing synchronized I/O capability at the language level.  Check out the XMOS and Adafruit hardware I used here:
- http://www.xmos.com/en/startkit
- http://www.adafruit.com/products/1426

The application is designed for and tested on the XMOS startKIT, but it should be possible to change the target in the makefile.

###xcore_neopixel_leds
Two tasks make up the application, a pattern generator task and a driver task.  These are connected with a channel, which is a language and hardware communication feature.  These two tasks are started in main using par.  Main connects them together with a chan passed to the tasks.

####blinky_task

The pattern generator task presents a "wheel" rolling multi-color pattern on the RGB LEDs.  This pattern code came from an Adafruit or PJRC source but I lost track which - both have some nice code for driving NeoPixels!

####neopixel_led_task

The driver task uses the timed port output feature of the xCore processors.  This generates the serialized data pattern with the precise timing needed for the serial NeoPixel strip.

######The NeoPixels are here:
http://learn.adafruit.com/adafruit-neopixel-uberguide/overview

######A really nice project on ARM for NeoPixel is here:
https://www.pjrc.com/teensy/td_libs_OctoWS2811.html

...This is my first XC and xCore project so any feedback is welcome!
