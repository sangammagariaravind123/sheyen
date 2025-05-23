#include<reg51.h>
#define sevensegment_data P1
sbit DISP1_se1=P0^3;
sbit DISP2_se1=P0^2;
sbit DISP3_se1=P0^1;
sbit DISP4_se1=P0^0;
sbit lcd_back_light=P0^7;

void delay_ms(unsigned int);

void main(void)
{
unsigned char count0=0, count1=0, count2=0, count3=0, count4=0, count5=0, count6=0;
unsigned bcd_code[]={0x3F,0x06,0x05,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f};

do
{
do
{
do
{
do
{
do
{
DISP1_se1=0;
sevensegment_data=bcd_code[count1];
delay_ms(2);
DISP1_se1=1;

DISP2_se1=0;
sevensegment_data=bcd_code[count2];
delay_ms(2);
DISP2_se1=1;

DISP3_se1=0;
sevensegment_data=bcd_code[count3];
delay_ms(2);
DISP3_se1=1;

DISP4_se1=0;
sevensegment_data=bcd_code[count4];
delay_ms(2);
DISP4_se1=1;

count0+=1;
}
while(count0<=25);
count0=0;
count1+=1;
}
while(count1<=9);
count1=0;
count2+=1;
}
while(count2<=9);
count2=0;
count3+=1;
}
while(count3<=9);
count3=0;
count4+=1;
}
while(count4<=9);
count4=0;
while(1);
}
void delay_ms(unsigned int itime)
{
unsigned int i,j;
for(i=0;i<itime;i++)
for(j=0;j<100;j++)
{
;
}
}



