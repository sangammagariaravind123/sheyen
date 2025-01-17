/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * Copyright (c) Xerox Corporation 1997. All rights reserved.
 *
 * License is granted to copy, to use, and to make and to use derivative
 * works for research and evaluation purposes, provided that Xerox is
 * acknowledged in all documentation pertaining to any such copy or
 * derivative work. Xerox grants no other licenses expressed or
 * implied. The Xerox trade name should not be used in any advertising
 * without its written permission. 
 *
 * XEROX CORPORATION MAKES NO REPRESENTATIONS CONCERNING EITHER THE
 * MERCHANTABILITY OF THIS SOFTWARE OR THE SUITABILITY OF THIS SOFTWARE
 * FOR ANY PARTICULAR PURPOSE.  The software is provided "as is" without
 * express or implied warranty of any kind.
 *
 * These notices must be retained in any copies of any part of this
 * software. 
 */
#ifndef lint
static const char rcsid[] =
	"@(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/adc/actp-adc.cc,v 1.5 1999/02/12 22:01:30 breslau Exp $";
#endif


//Acceptance region Tangent at Peak Admission Control

#include "adc.h"
#include <stdlib.h>
#include <math.h>

class ACTP_ADC : public ADC {
public:
	ACTP_ADC();
	void teardown_action(int,double,int);
	void rej_action(int,double,int);
protected:
	int admit_flow(int,double,int);
	int rejected_; 
	double s_;
	double sump_;
};

ACTP_ADC::ACTP_ADC() : rejected_(0), sump_(0)
{
	bind("s_", &s_);
	type_ = new char[5];
	strcpy(type_, "ACTP");
}



int ACTP_ADC::admit_flow(int cl,double r,int b)
{
	//get peak rate this class of flow
	double p=peak_rate(cl,r,b);

	if (backoff_) {
		if (rejected_)
			return 0;
	}
	
	//fprintf (stderr,"%f %f %f\n",sump_*(1-exp(-p*s_)),exp(-p*s_)*est_[cl]->avload(),est_[cl]->avload());
	if (sump_*(1-exp(-p*s_))+exp(-p*s_)*est_[cl]->avload() <= bandwidth_) {
		sump_+= p;
		if (dobump_) {
			est_[cl]->change_avload(p);
		}
		return 1;
	}
	else {
		rejected_=1;
		return 0;
	}
}


void ACTP_ADC::rej_action(int cl,double r,int b)
{
	double p=peak_rate(cl,r,b);
	sump_ -= p;
}


void ACTP_ADC::teardown_action(int cl,double r,int b)
{
	rejected_=0;
	double p=peak_rate(cl,r,b);
	sump_ -= p;
}

static class ACTP_ADCClass : public TclClass {
public:
	ACTP_ADCClass() : TclClass("ADC/ACTP") {}
	TclObject* create(int,const char*const*) {
		return (new ACTP_ADC());
	}
}class_actp_adc;
