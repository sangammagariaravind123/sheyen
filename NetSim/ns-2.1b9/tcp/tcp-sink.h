/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * Copyright (c) 1991-1997 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the Computer Systems
 *	Engineering Group at Lawrence Berkeley Laboratory.
 * 4. Neither the name of the University nor of the Laboratory may be used
 *    to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * @(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcp/tcp-sink.h,v 1.20 2001/12/30 04:54:39 sfloyd Exp $ (LBL)
 */
 
#ifndef ns_tcpsink_h
#define ns_tcpsink_h

#include <math.h>
#include "agent.h"
#include "tcp.h"

/* max window size */
#define MWS 1024  
#define MWM (MWS-1)
#define HS_MWS 65536
#define HS_MWM (MWS-1)
/* For Tahoe TCP, the "window" parameter, representing the receiver's
 * advertised window, should be less than MWM.  For Reno TCP, the
 * "window" parameter should be less than MWM/2.
 */

class TcpSink;
class Acker {
public:
	Acker();
	virtual ~Acker() { delete[] seen_; }
	void update_ts(int seqno, double ts);
	int update(int seqno, int numBytes);
	void update_ecn_unacked(int value);
	inline int Seqno() const { return (next_ - 1); }
	virtual void append_ack(hdr_cmn*, hdr_tcp*, int oldSeqno) const;
	void reset();
	double ts_to_echo() { return ts_to_echo_;}
	int ecn_unacked() { return ecn_unacked_;}
	inline int Maxseen() const { return (maxseen_); }
	void resize_buffers();  // grow Acker's arrays for large window sizes -- Sylvia

protected:
	int next_;		/* next packet expected */
	int maxseen_;		/* max packet number seen */
	int wndmask_;		/* window mask - either MWM or HS_MWM - Sylvia */ 
	int ecn_unacked_;	/* ECN forwarded to sender, but not yet
				 * acknowledged. */
	int *seen_;		/* array of packets seen */
	double ts_to_echo_;	/* timestamp to echo to peer */
	int is_dup_;		// A duplicate packet.
};

// derive Sacker from TclObject to allow for traced variable
class SackStack;
class Sacker : public Acker, public TclObject {
public: 
	Sacker() : base_nblocks_(-1), sf_(0) { };
	~Sacker();
	void append_ack(hdr_cmn*, hdr_tcp*, int oldSeqno) const;
	void reset();
	void configure(TcpSink*);
protected:
	int base_nblocks_;
	int* dsacks_;		// Generate DSACK blocks.
	SackStack *sf_;
	void trace(TracedVar*);
};

class TcpSink : public Agent {
public:
	TcpSink(Acker*);
	void recv(Packet* pkt, Handler*);
	void reset();
	int command(int argc, const char*const* argv);
	TracedInt& maxsackblocks() { return max_sack_blocks_; }
protected:
	void ack(Packet*);
	void resize_buffers();  // grow Acker's arrays for large window sizes -- Sylvia
	virtual void add_to_ack(Packet* pkt);

        virtual void delay_bind_init_all();
        virtual int delay_bind_dispatch(const char *varName, const char *localName, TclObject *tracer);

	Acker* acker_;
	int ts_echo_bugfix_;

	friend void Sacker::configure(TcpSink*);
	TracedInt max_sack_blocks_;	/* used only by sack sinks */
	Packet* save_;		/* place to stash saved packet while delaying */
				/* used by DelAckSink */
	int generate_dsacks_;	// used only by sack sinks
	int RFC2581_immediate_ack_;	// Used to generate ACKs immediately 
					// for RFC2581-compliant gap-filling.
	double lastreset_; 	/* W.N. used for detecting packets  */
				/* from previous incarnations */
};

class DelAckSink;

class DelayTimer : public TimerHandler {
public:
	DelayTimer(DelAckSink *a) : TimerHandler() { a_ = a; }
protected:
	virtual void expire(Event *e);
	DelAckSink *a_;
};

class DelAckSink : public TcpSink {
public:
	DelAckSink(Acker* acker);
	void recv(Packet* pkt, Handler*);
	virtual void timeout(int tno);
	void reset();
protected:
	double interval_;
	DelayTimer delay_timer_;
};

#endif
