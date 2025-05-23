#include<reg51.h>
sbit sw=P0^0;
#define motor P2

void delay_ms(unsigned int);
bit dir=0;
void main(void)
{
while(1)
{
do
{
if(dir==0)
{
motor=0x06;
delay_ms(1);
motor=0x0a;
delay_ms(1);
motor=0x09;
delay_ms(1);
motor=0x05;
delay_ms(1);
}
else if(dir==1)
{
motor=0x05;
delay_ms(1);
motor=0x09;
delay_ms(1);
motor=0x0a;
delay_ms(1);
motor=0x06;
delay_ms(1);
}
}
while(sw==1);
delay_ms(200);
dir=~dir;
}
}
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
