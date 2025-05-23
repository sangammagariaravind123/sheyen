 /*Program to interface leds using byte addressing*/

#include<reg51.h> //include at89c51 microcontoller header file

#define led P0  //connect lower nibble of p0 to leds

void delay_ms(unsigned int);

void main(void)
{
	while(1) //infinite loop
	{
      led=0x0c;       //led3 & led4 are on
		delay_ms(400); //delay 400 milli seconds
      led=0x03;       //led1 & led2 are on 
		delay_ms(400); //delay 400 milli seconds
	}
}

//generates delay in milli seconds
void delay_ms(unsigned int i)
{
unsigned int j;
	while(i-->0)
	{
		for(j=0;j<500;j++)
		{
			;
		}
	}
}


