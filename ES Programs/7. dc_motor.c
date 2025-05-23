#include<reg51.h>
sbit mtr_1 =P2^0;
sbit mtr_2 =P2^1;
sbit pwm_control =P2^3;
sbit key2_REV 	= P2^4;
sbit key1_FRW	= P2^5;
sbit speed_dec 	= P2^6;
sbit speed_inc 	= P2^7;


void main(void)
{
	unsigned int count,value=500;
	while(1)
	{
		if(key1_FRW == 0)
		{
			mtr_1 =0;
			mtr_2 =1;
		//	pwm_control = 1;
		 }

		 if(key2_REV == 0)
		{
			mtr_1 =1;
			mtr_2 =0;
		//	pwm_control = 1;
		 }

		 if(speed_dec ==0 )
		 {
		 	value -= 1;
			if(value <= 15)
			{
				value = 16;
			}
		 }

		 if(speed_inc ==0 )
		 {
		 	value += 1;
			if(value >= 1000)
			{
				value = 999;
			}
		 }

		 
	 	pwm_control=1;
		for(count=0;count<= value ;count++);
		
	   	pwm_control=0;
		for(count=0;count<= 500;count++);


	}
	while(1);
}
