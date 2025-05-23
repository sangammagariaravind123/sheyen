#include<reg51.h>
#define relay P0

void delay_ms(unsigned int);
void main(void)
{
while(1)
{
relay=0x10;
delay_ms(500);
relay=0x02;
delay_ms(500);
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
