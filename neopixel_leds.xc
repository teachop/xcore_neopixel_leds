//---------------------------------------------------------
// Adafruit NeoPixel LED Strip Blinky
// by teachop
//

#include <xs1.h>
#include <timer.h>


// length of the strip
#define LEDS 8


// ---------------------------------------------------------
// neopixel_led_task - output task for single neopixel strip
//
void neopixel_led_task(port neo, chanend comm) {
    const unsigned int delay_third = 42;
    const unsigned int delay_latch = 5000;
    unsigned int delay_count;
    unsigned int bit_count = 0;
    unsigned int led_count = 0;
    unsigned int grb[LEDS];
    unsigned int color_shift;
    unsigned int bit = 0;
    int loop;

    // first pass will output all zeros
    for( loop=0; loop<LEDS; ++loop ) {
        grb[loop] = 0;
    }
    color_shift = 0;

    // read the initial counter
    neo <: 0 @ delay_count;

    while (1) {
        // output low->high transition
        delay_count += delay_third;
        neo @ delay_count <: 1;

        // shift through bits in a grb color
        bit = color_shift & 0x800000;
        color_shift <<=1;
        bit_count++;

        // output high->data transition
        delay_count += delay_third;
        neo @ delay_count <: bit? 1 : 0;

        if ( 24 <= bit_count ) {
            // complete, scan to next led
            bit_count = 0;
            if ( LEDS <= ++led_count ) {
                led_count = 0;
            }
            color_shift = grb[led_count];
        }

        // output data->low transition
        delay_count += delay_third;
        neo @ delay_count <: 0;

        if ( !bit_count && !led_count ) {
            // end of strip, minimum latch delay requred
            delay_count += delay_latch;
            // read from the channel new color data
            for ( loop=0; loop<LEDS; ++loop) {
                comm :> grb[loop];
            }
        }
    }

}


// ------------------------------------------------------------
// grbColor - convert separate R,G,B into a neopixel color word
//
unsigned int grbColor(unsigned char r, unsigned char g, unsigned char b) {
    return ((unsigned int)g << 16) | ((unsigned int)r <<  8) | b;
}


// ---------------------------------------------------------
// wheel - input a value 0 to 255 to get a color value.
//         The colors are a transition r - g - b - back to r
//
unsigned int wheel(unsigned char wheelPos) {
    if ( wheelPos < 85 ) {
        return grbColor(wheelPos * 3, 255 - wheelPos * 3, 0);
    } else if ( wheelPos < 170 ) {
        wheelPos -= 85;
        return grbColor(255 - wheelPos * 3, 0, wheelPos * 3);
    } else {
        wheelPos -= 170;
        return grbColor(0, wheelPos * 3, 255 - wheelPos * 3);
    }
}


// ---------------------------------------------------------------
// blinky_task - rainbow cycle pattern from pjrc and / or adafruit
//
void blinky_task(unsigned int delay, chanend comm) {
    timer tick;
    unsigned int next_pass;
    unsigned int grb[LEDS];
    int loop, outer;

    tick :> next_pass;

    while (1) {
        for ( outer=0; outer<256; ++outer) {
            // cycle of all colors on wheel
            for ( loop=0; loop<LEDS; ++loop) {
                grb[loop] = wheel(( (loop*256/LEDS) + outer) & 255);
            }

            // emit data to the driver
            for( loop=0; loop<LEDS; ++loop ) {
                comm <: grb[loop];
            }

            // wait a bit
            next_pass += delay;
            tick when timerafter(next_pass) :> void;
        }
    }
}


// ---------------------------------------------------------
// main - xCore startKIT NeoPixel blinky test
//
port out_pin = XS1_PORT_1H;
int main() {
    chan comm_chan;

    par {
        neopixel_led_task(out_pin, comm_chan);
        blinky_task(1500*100, comm_chan);
    }

    return 0;
}

