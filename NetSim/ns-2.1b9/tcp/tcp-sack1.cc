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
    "@(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcp/tcp-sack1.cc,v 1.51 2001/11/08 19:06:08 sfloyd Exp $ (PSC)";
#endif

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "ip.h"
#include "tcp.h"
#include "flags.h"
#include "scoreboard.h"
#include "random.h"

#define TRUE    1
#define FALSE   0
#define RECOVER_DUPACK  1
#define RECOVER_TIMEOUT 2
#define RECOVER_QUENCH  3

class Sack1TcpAgent : public TcpAgent {
 public:
	Sack1TcpAgent();
	virtual void recv(Packet *pkt, Handler*);
	void reset();
	virtual void timeout(int tno);
	virtual void dupack_action();
	void plot();
	virtual void send_much(int force, int reason, int maxburst);
 protected:
	u_char timeout_;	/* boolean: sent pkt from timeout? */
	u_char fastrecov_;	/* boolean: doing fast recovery? */
	int pipe_;		/* estimate of pipe size (fast recovery) */ 
	ScoreBoard scb_;
};

static class Sack1TcpClass : public TclClass {
public:
	Sack1TcpClass() : TclClass("Agent/TCP/Sack1") {}
	TclObject* create(int, const char*const*) {
		return (new Sack1TcpAgent());
	}
} class_sack;

Sack1TcpAgent::Sack1TcpAgent() : fastrecov_(FALSE), pipe_(-1)
{
}

void Sack1TcpAgent::reset ()
{
	scb_.ClearScoreBoard();
	TcpAgent::reset ();
}


void Sack1TcpAgent::recv(Packet *pkt, Handler*)
{
	hdr_tcp *tcph = hdr_tcp::access(pkt);

#ifdef notdef
	if (pkt->type_ != PT_ACK) {
		Tcl::instance().evalf("%s error \"received non-ack\"",
				      name());
		Packet::free(pkt);
		return;
	}
#endif
        /* W.N.: check if this is from a previous incarnation */
        if (tcph->ts() < lastreset_) {
                // Remove packet and do nothing
                Packet::free(pkt);
                return;
        }
	++nackpack_;
	int ecnecho = hdr_flags::access(pkt)->ecnecho();
	if (ecnecho && ecn_)
		ecn(tcph->seqno());
	/*
	 * If DSACK is being used, check for DSACK blocks here.
	 * Possibilities:  Check for unnecessary Fast Retransmits.
	 */
	if (!fastrecov_) {
		/* normal... not fast recovery */
		if ((int)tcph->seqno() > last_ack_) {
			/*
			 * regular ACK not in fast recovery... normal
			 */
			recv_newack_helper(pkt);
			timeout_ = FALSE;
			scb_.ClearScoreBoard();
			if (last_ack_ == 0 && delay_growth_) {
				cwnd_ = initial_window();
			}
		} else if ((int)tcph->seqno() < last_ack_) {
			/*NOTHING*/
		} else if (timeout_ == FALSE) {
			if (tcph->seqno() != last_ack_) {
				fprintf(stderr, "pkt seq %d should be %d\n" ,
					tcph->seqno(), last_ack_);
				abort();
			}
			scb_.UpdateScoreBoard (highest_ack_, tcph);
			/*
		 	 * Check for a duplicate ACK.
			 * Check that the SACK block actually
			 *  acknowledges new data.
 			 */
 		        if(scb_.CheckUpdate()) {
 			 	if (++dupacks_ == numdupacks_) {
 					/*
 					 * Assume we dropped just one packet.
 					 * Retransmit last ack + 1
 					 * and try to resume the sequence.
 					 */
 				   	dupack_action();
 				} else if (dupacks_ < numdupacks_ && singledup_ ) {
 				         send_one();
 				}
			}
		}
		if (dupacks_ == 0)
			send_much(FALSE, 0, maxburst_);
	} else {
		/* we are in fast recovery */
		--pipe_;
		if ((int)tcph->seqno() >= recover_) {
			/* ACK indicates fast recovery is over */
			recover_ = 0;
			fastrecov_ = FALSE;
			newack(pkt);
			/* if the connection is done, call finish() */
			if ((highest_ack_ >= curseq_-1) && !closed_) {
				closed_ = 1;
				finish();
			}
			timeout_ = FALSE;
			scb_.ClearScoreBoard();

			/* New window: W/2 - K or W/2? */
		} else if ((int)tcph->seqno() > highest_ack_) {
			/* Not out of fast recovery yet.
			 * Update highest_ack_, but not last_ack_. */
			--pipe_;
			/* If this partial ACK is from a retransmitted pkt, 
			 * then we decrement pipe_ again, so that we never
			 * do worse than slow-start.  If this partial ACK
			 * was instead from the original packet, reordered,
			 * then this might be too aggressive. */
			highest_ack_ = (int)tcph->seqno();
			scb_.UpdateScoreBoard (highest_ack_, tcph);
			t_backoff_ = 1;
			newtimer(pkt);
		} else if (timeout_ == FALSE) {
			/* got another dup ack */
			scb_.UpdateScoreBoard (highest_ack_, tcph);
 		        if(scb_.CheckUpdate()) {
 				if (dupacks_ > 0)
 			        	dupacks_++;
 			}
		}
		send_much(FALSE, 0, maxburst_);
	}

	Packet::free(pkt);
#ifdef notyet
	if (trace_)
		plot();
#endif
}

void
Sack1TcpAgent::dupack_action()
{
	int recovered = (highest_ack_ > recover_);
	if (recovered || (!bug_fix_ && !ecn_)) {
		goto sack_action;
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
		/*
		 * There are three possibilities: 
		 * (1) pipe_ = int(cwnd_) - numdupacks_;
		 * (2) pipe_ = window() - numdupacks_;
		 * (3) pipe_ = maxseq_ - highest_ack_ - numdupacks_;
		 * equation (2) takes into account the receiver's
		 * advertised window, and equation (3) takes into
		 * account a data-limited sender.
		 */
		pipe_ = maxseq_ - highest_ack_ - numdupacks_;
		//pipe_ = int(cwnd_) - numdupacks_;
		fastrecov_ = TRUE;
		scb_.MarkRetran(highest_ack_+1);
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

sack_action:
	// we are now going into fast_recovery and will trace that event
	trace_event("FAST_RECOVERY");

	recover_ = maxseq_;
	last_cwnd_action_ = CWND_ACTION_DUPACK;
	if (oldCode_) {
	 	pipe_ = int(cwnd_) - numdupacks_;
	} else { 
                pipe_ = maxseq_ - highest_ack_ - numdupacks_;
	}
	slowdown(CLOSE_SSTHRESH_HALF|CLOSE_CWND_HALF);
	reset_rtx_timer(1,0);
	fastrecov_ = TRUE;
	scb_.MarkRetran(highest_ack_+1);
	output(last_ack_ + 1, TCP_REASON_DUPACK);	// from top
	/*
	 * If dynamically adjusting numdupacks_, record information
	 *  at this point.
	 */
	return;
}

void Sack1TcpAgent::timeout(int tno)
{
	if (tno == TCP_TIMER_RTX) {
		/*
		 * IF DSACK and dynamic adjustment of numdupacks_,
		 *  check whether a smaller value of numdupacks_
		 *  would have prevented this retransmit timeout.
		 * If DSACK and detection of premature retransmit
		 *  timeouts, then save some info here.
		 */ 
		dupacks_ = 0;
		fastrecov_ = FALSE;
		timeout_ = TRUE;
		if (highest_ack_ > last_ack_)
			last_ack_ = highest_ack_;
#ifdef DEBUGSACK1A
		printf ("timeout. highest_ack: %d seqno: %d\n", 
			highest_ack_, t_seqno_);
#endif
		recover_ = maxseq_;
		scb_.ClearScoreBoard();
	}
	TcpAgent::timeout(tno);
}

void Sack1TcpAgent::send_much(int force, int reason, int maxburst)
{
	register int found, npacket = 0;
	int win = window();
	int xmit_seqno;

	found = 1;
	if (!force && delsnd_timer_.status() == TIMER_PENDING)
		return;
	/*
	 * as long as the pipe is open and there is app data to send...
	 */
	while (((!fastrecov_ && (t_seqno_ <= last_ack_ + win)) ||
			(fastrecov_ && (pipe_ < int(cwnd_)))) 
			&& t_seqno_ < curseq_ && found) {

		if (overhead_ == 0 || force) {
			found = 0;
			xmit_seqno = scb_.GetNextRetran ();

#ifdef DEBUGSACK1A
			printf("highest_ack: %d xmit_seqno: %d\n", 
			highest_ack_, xmit_seqno);
#endif
			if (xmit_seqno == -1) { 
				if ((!fastrecov_ && t_seqno_<=highest_ack_+win)||
					(fastrecov_ && t_seqno_<=highest_ack_+int(wnd_))) {
					found = 1;
					xmit_seqno = t_seqno_++;
#ifdef DEBUGSACK1A
					printf("sending %d fastrecovery: %d win %d\n",
						xmit_seqno, fastrecov_, win);
#endif
				}
			} else if (recover_>0 && xmit_seqno<=highest_ack_+int(wnd_)) {
				found = 1;
				scb_.MarkRetran (xmit_seqno);
				win = window();
			}
			if (found) {
				output(xmit_seqno, reason);
				if (t_seqno_ <= xmit_seqno)
					t_seqno_ = xmit_seqno + 1;
				npacket++;
				pipe_++;
			}
		} else if (!(delsnd_timer_.status() == TIMER_PENDING)) {
			/*
			 * Set a delayed send timeout.
			 * This is only for the simulator,to add some
			 *   randomization if speficied.
			 */
			delsnd_timer_.resched(Random::uniform(overhead_));
			return;
		}
		if (maxburst && npacket == maxburst)
			break;
	} /* while */
}

void Sack1TcpAgent::plot()
{
#ifdef notyet
	double t = Scheduler::instance().clock();
	sprintf(trace_->buffer(), "t %g %d rtt %g\n", 
		t, class_, t_rtt_ * tcp_tick_);
	trace_->dump();
	sprintf(trace_->buffer(), "t %g %d dev %g\n", 
		t, class_, t_rttvar_ * tcp_tick_);
	trace_->dump();
	sprintf(trace_->buffer(), "t %g %d win %f\n", t, class_, cwnd_);
	trace_->dump();
	sprintf(trace_->buffer(), "t %g %d bck %d\n", t, class_, t_backoff_);
	trace_->dump();
#endif
}
