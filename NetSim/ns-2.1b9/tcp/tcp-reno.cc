/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * Copyright (c) 1990, 1997 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Lawrence Berkeley Laboratory,
 * Berkeley, CA.  The name of the University may not be used to
 * endorse or promote products derived from this software without
 * specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef lint
static const char rcsid[] =
    "@(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcp/tcp-reno.cc,v 1.36 2001/11/08 19:06:08 sfloyd Exp $ (LBL)";
#endif

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "ip.h"
#include "tcp.h"
#include "flags.h"


static class RenoTcpClass : public TclClass {
public:
	RenoTcpClass() : TclClass("Agent/TCP/Reno") {}
	TclObject* create(int, const char*const*) {
		return (new RenoTcpAgent());
	}
} class_reno;

int RenoTcpAgent::window()
{
	//
	// reno: inflate the window by dupwnd_
	//	dupwnd_ will be non-zero during fast recovery,
	//	at which time it contains the number of dup acks
	//
	int win = int(cwnd_) + dupwnd_;
	if (win > int(wnd_))
		win = int(wnd_);
	return (win);
}

double RenoTcpAgent::windowd()
{
	//
	// reno: inflate the window by dupwnd_
	//	dupwnd_ will be non-zero during fast recovery,
	//	at which time it contains the number of dup acks
	//
	double win = cwnd_ + dupwnd_;
	if (win > wnd_)
		win = wnd_;
	return (win);
}

RenoTcpAgent::RenoTcpAgent() : TcpAgent(), dupwnd_(0)
{
}

void RenoTcpAgent::recv(Packet *pkt, Handler*)
{
	hdr_tcp *tcph = hdr_tcp::access(pkt);
#ifdef notdef
	if (pkt->type_ != PT_ACK) {
		fprintf(stderr,
			"ns: confiuration error: tcp received non-ack\n");
		exit(1);
	}
#endif
        /* W.N.: check if this is from a previous incarnation */
        if (tcph->ts() < lastreset_) {
                // Remove packet and do nothing
                Packet::free(pkt);
                return;
        }
	++nackpack_;
	ts_peer_ = tcph->ts();

	if (hdr_flags::access(pkt)->ecnecho() && ecn_)
		ecn(tcph->seqno());
	recv_helper(pkt);
	if (tcph->seqno() > last_ack_) {
		dupwnd_ = 0;
		recv_newack_helper(pkt);
		if (last_ack_ == 0 && delay_growth_) {
			cwnd_ = initial_window();
		}
	} else if (tcph->seqno() == last_ack_) {
		if (hdr_flags::access(pkt)->eln_ && eln_) {
			tcp_eln(pkt);
			return;
		}
		if (++dupacks_ == numdupacks_) {
			dupack_action();
			dupwnd_ = numdupacks_;
		} else if (dupacks_ > numdupacks_) {
			++dupwnd_;	// fast recovery
		} else if (dupacks_ < numdupacks_ && singledup_ ) {
			send_one();
		}
	}
	Packet::free(pkt);
#ifdef notyet
	if (trace_)
		plot();
#endif

	/*
	 * Try to send more data
	 */

	if (dupacks_ == 0 || dupacks_ > numdupacks_ - 1)
		send_much(0, 0, maxburst_);
}

int
RenoTcpAgent::allow_fast_retransmit(int last_cwnd_action_)
{
	return (last_cwnd_action_ == CWND_ACTION_DUPACK);
}

/*
 * Dupack-action: what to do on a DUP ACK.  After the initial check
 * of 'recover' below, this function implements the following truth
 * table:
 *  
 *      bugfix  ecn     last-cwnd == ecn        action  
 *  
 *      0       0       0                       reno_action
 *      0       0       1                       reno_action    [impossible]
 *      0       1       0                       reno_action
 *      0       1       1                       retransmit, return  
 *      1       0       0                       nothing 
 *      1       0       1                       nothing        [impossible]
 *      1       1       0                       nothing 
 *      1       1       1                       retransmit, return
 */ 
    
void
RenoTcpAgent::dupack_action()
{
	int recovered = (highest_ack_ > recover_);
	int allowFastRetransmit = allow_fast_retransmit(last_cwnd_action_);
        if (recovered || (!bug_fix_ && !ecn_) || allowFastRetransmit) {
		goto reno_action;
	}

	if (ecn_ && last_cwnd_action_ == CWND_ACTION_ECN) {
		last_cwnd_action_ = CWND_ACTION_DUPACK;
		/* 
		 * What if there is a DUPACK action followed closely by ECN
		 * followed closely by a DUPACK action?
		 * The optimal thing to do would be to remember all
		 * congestion actions from the most recent window
		 * of data.  Otherwise "bugfix" might not prevent
		 * all unnecessary Fast Retransmits.
		 */
		reset_rtx_timer(1,0);
		output(last_ack_ + 1, TCP_REASON_DUPACK);
		return; 
	}

	if (bug_fix_) {
		/*
		 * The line below, for "bug_fix_" true, avoids
		 * problems with multiple fast retransmits in one
		 * window of data.
		 */
		return;
	}

reno_action:
	// we are now going to fast-retransmit and will trace that event
	trace_event("RENO_FAST_RETX");
	recover_ = maxseq_;
	last_cwnd_action_ = CWND_ACTION_DUPACK;
	slowdown(CLOSE_SSTHRESH_HALF|CLOSE_CWND_HALF);
	reset_rtx_timer(1,0);
	output(last_ack_ + 1, TCP_REASON_DUPACK);	// from top
	return;
}

void RenoTcpAgent::timeout(int tno)
{
	if (tno == TCP_TIMER_RTX) {
		dupwnd_ = 0;
		dupacks_ = 0;
		if (bug_fix_) recover_ = maxseq_;
		TcpAgent::timeout(tno);
	} else {
		timeout_nonrtx(tno);
	}
}
