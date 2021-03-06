//---------------------------------------------------------
// Adafruit NeoPixel LED Strip Blinky
// by teachop
//

#include <xs1.h>
#include <timer.h>


// length of the strip(s)
#define LEDS 60

// SPEED constant must be larger than ((30.25*LEDS) + 50) microseconds
#define SPEED     1900
#define SPEED_INC 1000


// ---------------------------------------------------------
// neopixel_led_task - output task for single neopixel strip
//
void neopixel_led_task(port neo, port tp, streaming chanend comm) {
    const unsigned int delay_third = 42;
    unsigned int delay_count;
    unsigned int color_shift;
    int bit_count = 24;
    unsigned int bit;

    while (1) {
        comm :> color_shift;
        // have new color data
        if ( 0x80000000 & color_shift ) {
            // beginning of strip, resync counter
            neo <: 0 @ delay_count;
            delay_count += delay_third;
        }
        do {
            // output low->high transition
            delay_count += delay_third;
            tp <: 1;
            neo @ delay_count <: 1;

            // output high->data transition
            bit = (color_shift & 0x800000)? 1 : 0;
            color_shift <<=1;
            delay_count += delay_third;
            neo @ delay_count <: bit;
            tp <: 0;

            // output data->low transition
            delay_count += delay_third;
            neo @ delay_count <: 0;
        } while ( --bit_count );
        bit_count = 24;
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
void blinky_task(unsigned int delay, int length, streaming chanend comm) {
    timer tick;
    unsigned int next_pass;
    int loop, outer;

    tick :> next_pass;

    while (1) {
        for ( outer=0; outer<256; ++outer) {
            // cycle of all colors on wheel
            comm <: (wheel(outer) | 0x80000000);
            for ( loop=1; loop<length; ++loop) {
                // emit data to the driver
                comm <: wheel(( (loop*256/length) + outer) & 255);
            }

            // wait a bit, must allow strip to latch at least
            next_pass += delay;
            tick when timerafter(next_pass) :> void;
        }
    }
}


// ---------------------------------------------------------
// main - xCore startKIT NeoPixel blinky test
//
port out_pin[4] = { // j7.1, j7.2, j7.3, j7.4
    XS1_PORT_1F, XS1_PORT_1H, XS1_PORT_1G, XS1_PORT_1E
};
port test_pin[4] = { // j7.23, j7.21, j7.20, j7.19
    XS1_PORT_1P, XS1_PORT_1O, XS1_PORT_1I, XS1_PORT_1L
};
int main() {
    streaming chan comm_chan[4];

    par {
        // 4 led stips - possible to have differing speeds / lengths
        neopixel_led_task(out_pin[0], test_pin[0], comm_chan[0]);
        blinky_task((SPEED+SPEED_INC*0)*100, LEDS, comm_chan[0]);

        neopixel_led_task(out_pin[1], test_pin[1], comm_chan[1]);
        blinky_task((SPEED+SPEED_INC*1)*100, LEDS, comm_chan[1]);

        neopixel_led_task(out_pin[2], test_pin[2], comm_chan[2]);
        blinky_task((SPEED+SPEED_INC*2)*100, LEDS, comm_chan[2]);

        neopixel_led_task(out_pin[3], test_pin[3], comm_chan[3]);
        blinky_task((SPEED+SPEED_INC*3)*100, LEDS, comm_chan[3]);
    }

    return 0;
}

