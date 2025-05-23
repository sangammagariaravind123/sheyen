/* Interfacing Seven Segment Display through 8051 microcontroller */

#include <reg51.h>
#define sevensegment_data P1
sbit DISP1_se1 = P0 ^ 3;
sbit DISP2_se1 = P0 ^ 2;
sbit DISP3_se1 = P0 ^ 1;
sbit DISP4_se1 = P0 ^ 0;
sbit back_lite = P0 ^ 7;

void delay_ms(unsigned int);

void main(void)
{
    unsigned char bcd_code[] = {0x5b , 0x3f, 0x5b, 0x6d};

    while(1)
    {
        DISP1_se1 = 0;         
        DISP2_se1 = 1;
        DISP3_se1 = 1;
        DISP4_se1 = 1;
        sevensegment_data = bcd_code[3];
        delay_ms(1);
        DISP1_se1 = 1;
        
        DISP2_se1 = 0;
        DISP1_se1 = 1;
        DISP3_se1 = 1;
        DISP4_se1 = 1;
        sevensegment_data = bcd_code[2];
        delay_ms(1);
        DISP2_se1 = 1;
        
        DISP3_se1 = 0;
        DISP1_se1 = 1;
        DISP2_se1 = 1;
        DISP4_se1 = 1;
        sevensegment_data = bcd_code[1];
        delay_ms(1);
        DISP3_se1 = 1;
        
        DISP4_se1 = 0;
        DISP1_se1 = 1;
        DISP2_se1 = 1;
        DISP3_se1 = 1;
        sevensegment_data = bcd_code[0];
        delay_ms(1);
        DISP4_se1 = 1;
    }     
}

void delay_ms(unsigned int i)
{
    unsigned int  j;
    while(i-- > 0)
    {
        for (j = 0; j < 500; j++)
        {
            ;
        }
    }
}