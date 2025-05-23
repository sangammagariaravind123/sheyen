/* Interfacing Seven Segment Display through 8051 microcontroller */

#include <reg51.h>
#define sevensegment_data P1

// Declare the display selection pins
sbit DISP1_sel = P0^3;
sbit DISP2_sel = P0^2;
sbit DISP3_sel = P0^1;
sbit DISP4_sel = P0^0;

void port_init(void);
void delay_ms(unsigned int);

// BCD codes for 0-9
unsigned char bcd_code[] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

void main(void)
{
    unsigned char count1 = 0, count2 = 0, count3 = 0, count4 = 0;

    port_init();  // Initialize all the ports

    while (1)
    {
        // Display first digit
        DISP1_sel = 0;
        sevensegment_data = bcd_code[count1];
        delay_ms(10);
        DISP1_sel = 1;

        // Display second digit
        DISP2_sel = 0;
        sevensegment_data = bcd_code[count2];
        delay_ms(2);
        DISP2_sel = 1;

        // Display third digit
        DISP3_sel = 0;
        sevensegment_data = bcd_code[count3];
        delay_ms(2);
        DISP3_sel = 1;

        // Display fourth digit
        DISP4_sel = 0;
        sevensegment_data = bcd_code[count4];
        delay_ms(2);
        DISP4_sel = 1;

        // Increment the counts and loop through 0-9
        count1++;
        if (count1 > 9)
        {
            count1 = 0;
            count2++;
            if (count2 > 9)
            {
                count2 = 0;
                count3++;
                if (count3 > 9)
                {
                    count3 = 0;
                    count4++;
                    if (count4 > 9)
                    {
                        count4 = 0;  // Reset all digits to 0 after reaching 9999
                    }
                }
            }
        }
    }
}

void port_init(void)
{
    // Initialize ports here if necessary, e.g., setting up P0, P1, P2, P3 as output ports
    P0 = 0xFF;  // Set all bits of Port 0 as high (output)
    P1 = 0xFF;  // Set all bits of Port 1 as high (output)
    P2 = 0xFF;  // Set all bits of Port 2 as high (output)
    P3 = 0xFF;  // Set all bits of Port 3 as high (output)
}

// Delay function to create a visible update rate for the 7-segment display
void delay_ms(unsigned int i)
{
    unsigned int j;
    while (i-- > 0)
    {
        for (j = 0; j < 500; j++)
        {
            ;  // Empty loop for delay
        }
    }
}
