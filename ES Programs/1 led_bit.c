
#include<reg51.h> //include at89c51 microcontoller header file

void delay_ms(unsigned int);

sbit led=P0^0;  //connect p0.0 to led

void main(void)
{
	while(1) //infinite loop
	{
      led=0;            //led off
		delay_ms(1000);   //delay 1000 milli seconds
      led=1;            //led on
		delay_ms(1000);   //delay 1000 milli seconds
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
