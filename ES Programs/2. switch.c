  /*Program to interface led & Switch using bit addressing*/

#include<reg51.h> //include at89c51 microcontoller header file

sbit led=P0^0;  //connect P0.0 to led
sbit sw=P2^0;  //connect P2.0 to switch

void delay_ms(unsigned int);

void main(void)
{
	while(1) //infinite loop
	{
      if(sw==0)  //check if switch is pressed
		{
			led= ~led;    // toggle led 
			delay_ms(200);   //delay 200 milli seconds
      	}
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
