 /*Program to interface Buzzer using byte addressing*/

#include<reg51.h> //include at89c51 microcontoller header file

#define buzzer P0  //connect lower nibble of p0 to leds

void delay_ms(unsigned int);

void main(void)
{
	while(1) //infinite loop
	{
     buzzer=0x2F;       //Buzzer & led are ON
		delay_ms(200); //delay 200 milli seconds
      buzzer=0x00;       //Buzzer OFF 
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


