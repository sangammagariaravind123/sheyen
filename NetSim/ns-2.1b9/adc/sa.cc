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
 *
 * $Header: /nfs/jade/vint/CVSROOT/ns-2/adc/sa.cc,v 1.14 2000/09/01 03:04:06 haoboy Exp $
 */

//packets after it succeeds in a3-way handshake from the receiver
// should be connected with Agent/SignalAck class

#include "udp.h"
#include "sa.h"
#include "ip.h"
#include "random.h"

#define SAMPLERATE 8000

SA_Agent::SA_Agent() : Agent(PT_UDP), trafgen_(0), rtd_(0), callback_(0), 
    sa_timer_(this), nextPkttime_(-1), running_(0), seqno_(-1)
{
	bind_bw("rate_",&rate_);
	bind("bucket_",&bucket_);
	bind("packetSize_", &size_);
}

SA_Agent::~SA_Agent()
{
        if (callback_) 
                delete[] callback_;

}


static class SA_AgentClass : public TclClass {
public:
	SA_AgentClass() : TclClass("Agent/SA") {}
	TclObject* create(int, const char*const*) {
		return (new SA_Agent());
	}
} class_signalsource_agent;

int SA_Agent::command(int argc, const char*const* argv)
{
	Tcl& tcl = Tcl::instance();
	if (argc==3) {
		if (strcmp(argv[1], "target") == 0) {
			target_ = (NsObject*)TclObject::lookup(argv[2]);
			if (target_ == 0) {
				tcl.resultf("no such object %s", argv[2]);
				return (TCL_ERROR);
			}
			ctrl_target_=target_;
			return (TCL_OK);
		} 
		else if (strcmp(argv[1],"ctrl-target")== 0) {
			ctrl_target_=(NsObject*)TclObject::lookup(argv[2]);
			if (ctrl_target_ == 0) {
				tcl.resultf("no such object %s", argv[2]);
				return (TCL_ERROR);
			}
			return (TCL_OK);
		}
	        if (strcmp(argv[1], "stoponidle") == 0) {
		        stoponidle(argv[2]);
			return(TCL_OK);
		}
                if (strcmp(argv[1], "attach-traffic") == 0) {
                        trafgen_ =(TrafficGenerator*)TclObject::lookup(argv[2]);
                        if (trafgen_ == 0) {
                                tcl.resultf("no such node %s", argv[2]);
                                return(TCL_ERROR);
                        }
                        return(TCL_OK);
                }

	}
        if (argc == 2) {
                if (strcmp(argv[1], "start") == 0) {
                        start();
                        return(TCL_OK);
                } else if (strcmp(argv[1], "stop") == 0) {
                        stop();
                        return(TCL_OK);
                }
        }
	return (Agent::command(argc,argv));
}


void SA_Agent::start()
{
	//send the request packet
	if (trafgen_) {
		trafgen_->init();
		//running_=1;
		sendreq();
	}
}

void SA_Agent::stop()
{
	sendteardown();
	if (running_ != 0) {
		sa_timer_.cancel();
		running_ =0;
	}
}


void SA_Agent::sendreq()
{
	Packet *p = allocpkt();
	hdr_cmn* ch= hdr_cmn::access(p);
	ch->ptype()=PT_REQUEST;
	ch->size()=20;
	//also put in the r,b parameters for the flow in the packet
	hdr_resv* rv=hdr_resv::access(p);
	rv->decision() =1;
	rv->rate()=rate_;
	rv->bucket()=bucket_;
	ctrl_target_->recv(p);
}

void SA_Agent::sendteardown()
{
	Packet *p = allocpkt();
	hdr_cmn* ch= hdr_cmn::access(p);
	ch->ptype()=PT_TEARDOWN;
	ch->size()=20;
	//also put in the r,b parameters for the flow in the packet
	hdr_resv* rv=hdr_resv::access(p);
	rv->decision() =1;
	rv->rate()=rate_;
	rv->bucket()=bucket_;
	ctrl_target_->recv(p);
}


void SA_Agent::recv(Packet *p, Handler *) 
{
	hdr_cmn *ch= hdr_cmn::access(p);
	hdr_resv *rv=hdr_resv::access(p);
	hdr_ip * iph = hdr_ip::access(p);
	if ( ch->ptype() == PT_ACCEPT || ch->ptype() == PT_REJECT ) {
		ch->ptype() = PT_CONFIRM;

		// turn the packet around by swapping src and dst
		// (address and port)
		ns_addr_t tmp;
		tmp = iph->src();
		iph->src() = iph->dst();
		iph->dst() = tmp;
		ctrl_target_->recv(p);
	}
	
	// put an additional check here to see if admission was granted
	if (rv->decision()) {
		//printf("Flow %d accepted @ %f\n",iph->flowid(),Scheduler::instance().clock());
		fflush(stdout);
		double t = trafgen_->next_interval(size_);
		running_=1;
		sa_timer_.resched(t);
	}
	else {
		//printf("Flow %d rejected @ %f\n",iph->flowid(),Scheduler::instance().clock());
		fflush(stdout);
		//Currently the flow is stopped if rejected
		running_=0;
	}
	//make an upcall to sched a stoptime for this flow from now
	Tcl::instance().evalf("%s sched-stop %d",name(),rv->decision());
}

void SA_Agent::stoponidle(const char *s)
{
        callback_ = new char[strlen(s)+1];
        strcpy(callback_, s);

        if (trafgen_->on()) {
                // Tcl::instance().evalf("puts \"%s waiting for burst at %f\"", name(), Scheduler::instance().clock());
                rtd_ = 1;
        }
        else {
                stop();
                Tcl::instance().evalf("%s %s", name(), callback_);
        }

}

void SA_Timer::expire(Event* /*e*/) {
        a_->timeout(0);
}

void SA_Agent::timeout(int)
{
        if (running_) {
                /* send a packet */
                sendpkt();
                /* figure out when to send the next one */
                nextPkttime_ = trafgen_->next_interval(size_);
                /* schedule it */
                sa_timer_.resched(nextPkttime_);

                /* hack: if we are waiting for a current burst to end
                 * before stopping . . .
                 */
                if (rtd_) {
                        if (trafgen_->on() == 0) {
                                stop();
                                //Tcl::instance().evalf("puts \"%s burst over at %f\"",
                                // name(), Scheduler::instance().clock());
                                Tcl::instance().evalf("%s sched-stop %d", name(), 0);
                        }
                }
        }
}

void SA_Agent::sendpkt()
{
        Packet* p = allocpkt();
        hdr_rtp* rh = hdr_rtp::access(p);
        rh->seqno() = ++seqno_;
        rh->flags()=0;

        double local_time=Scheduler::instance().clock();
        /*put in "rtp timestamps" and begining of talkspurt labels */
        hdr_cmn* ch = hdr_cmn::access(p);
        ch->timestamp()=(u_int32_t)(SAMPLERATE*local_time);
        ch->size()=size_;
        if ((nextPkttime_ != trafgen_->interval()) || (nextPkttime_ == -1))
                rh->flags() |= RTP_M;

        target_->recv(p);
}

void SA_Agent::sendmsg(int nbytes, const char* /*flags*/)
{
        Packet *p;
        int n;

        if (size_)
                n = nbytes / size_;
        else
                printf("Error: SA_Agent size = 0\n");

        if (nbytes == -1) {
                start();
                return;
        }
        while (n-- > 0) {
       		p = allocpkt();
                hdr_rtp* rh = hdr_rtp::access(p);
                rh->seqno() = seqno_;
                target_->recv(p);
        }
        n = nbytes % size_;
        if (n > 0) {
        	p = allocpkt();
        	hdr_rtp* rh = hdr_rtp::access(p);
        	rh->seqno() = seqno_;
        	target_->recv(p);
        }
        idle();
}
