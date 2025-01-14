/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * Copyright (c) 1997 Regents of the University of California.
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
 *      This product includes software developed by the MASH Research
 *      Group at the University of California Berkeley.
 * 4. Neither the name of the University nor of the Research Group may be
 *    used to endorse or promote products derived from this software without
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
 */

#ifndef lint
static const char rcsid[] =
    "@(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tools/queue-monitor.cc,v 1.24 2002/03/10 04:43:31 sfloyd Exp $";
#endif

#include "queue-monitor.h"
#include "trace.h"
#include <math.h>

int QueueMonitor::command(int argc, const char*const* argv)
{
	Tcl& tcl = Tcl::instance();

	if (argc == 2) {
		if (strcmp(argv[1], "get-bytes-integrator") == 0) {
			if (bytesInt_)
				tcl.resultf("%s", bytesInt_->name());
			else
				tcl.resultf("");
			return (TCL_OK);
		}
		if (strcmp(argv[1], "get-pkts-integrator") == 0) {
			if (pktsInt_)
				tcl.resultf("%s", pktsInt_->name());
			else
				tcl.resultf("");
			return (TCL_OK);
		}
		if (strcmp(argv[1], "get-delay-samples") == 0) {
			if (delaySamp_)
				tcl.resultf("%s", delaySamp_->name());
			else
				tcl.resultf("");
			return (TCL_OK);
		}
	}

	if (argc == 3) {
		if (strcmp(argv[1], "set-bytes-integrator") == 0) {
			bytesInt_ = (Integrator *)
				TclObject::lookup(argv[2]);
			if (bytesInt_ == NULL)
				return (TCL_ERROR);
			return (TCL_OK);
		}
		if (strcmp(argv[1], "set-pkts-integrator") == 0) {
			pktsInt_ = (Integrator *)
				TclObject::lookup(argv[2]);
			if (pktsInt_ == NULL)
				return (TCL_ERROR);
			return (TCL_OK);
		}
		if (strcmp(argv[1], "set-delay-samples") == 0) {
			delaySamp_ = (Samples*)
				TclObject::lookup(argv[2]);
			if (delaySamp_ == NULL)
				return (TCL_ERROR);
			return (TCL_OK);
		}
		if (strcmp(argv[1], "trace") == 0) {
			int mode;
			const char* id = argv[2];
			channel_ = Tcl_GetChannel(tcl.interp(), (char*)id, &mode);
						if (channel_ == 0) {
				tcl.resultf("trace: can't attach %s for writing", id);
				return (TCL_ERROR);
			}
			return (TCL_OK);
		}
	}
	if (argc == 4) {
		if (strcmp(argv[1], "set-src-dst") == 0) {
			srcId_ = atoi(argv[2]);
			dstId_ = atoi(argv[3]);
			return (TCL_OK);
		}
	}
	return TclObject::command(argc, argv);	// else control reaches end of
						// non-void function, see? :-)
}

static class QueueMonitorClass : public TclClass {
 public:
	QueueMonitorClass() : TclClass("QueueMonitor") {}
	TclObject* create(int, const char*const*) {
		return (new QueueMonitor());
	}
} queue_monitor_class;

void
QueueMonitor::printStats() {
	char wrk[500];
	int n;
	double now = Scheduler::instance().clock();
	sprintf(wrk, "q -t "TIME_FORMAT" -s %d -d %d -l %d -p %d", now, srcId_, dstId_, size_, pkts_);
	n = strlen(wrk);
	wrk[n] = '\n';
	wrk[n+1] = 0;
	(void)Tcl_Write(channel_, wrk, n+1);
	wrk[n] = 0;
}	

// packet arrival to a queue
void QueueMonitor::in(Packet* p)
{
	hdr_cmn* hdr = hdr_cmn::access(p);
	double now = Scheduler::instance().clock();
	int pktsz = hdr->size();

       	//if enabled estimate rate now
	if (estimate_rate_) {
		estimateRate(p);
	}
	else {
		prevTime_ = now;
	}

	barrivals_ += pktsz;
	parrivals_++;
	size_ += pktsz;
	pkts_++;
	if (bytesInt_)
		bytesInt_->newPoint(now, double(size_));
	if (pktsInt_)
		pktsInt_->newPoint(now, double(pkts_));
	if (delaySamp_)
		hdr->timestamp() = now;
	if (channel_)
		printStats();

}

void QueueMonitor::out(Packet* p)
{
	hdr_cmn* hdr = hdr_cmn::access(p);
	hdr_flags* pf = hdr_flags::access(p);
	double now = Scheduler::instance().clock();
	int pktsz = hdr->size();

	if (pf->ce() && pf->ect()) 
		pmarks_++;
	size_ -= pktsz;
	pkts_--;
	bdepartures_ += pktsz;
	pdepartures_++;
	if (bytesInt_)
		bytesInt_->newPoint(now, double(size_));
	if (pktsInt_)
		pktsInt_->newPoint(now, double(pkts_));
	if (delaySamp_)
		delaySamp_->newPoint(now - hdr->timestamp());
	if (channel_)
		printStats();
}

void QueueMonitor::drop(Packet* p)
{
	hdr_cmn* hdr = hdr_cmn::access(p);
	double now = Scheduler::instance().clock();
	int pktsz = hdr->size();

	size_ -= pktsz;
	pkts_--;
	bdrops_ += pktsz;
	pdrops_++;
	if (bytesInt_)
		bytesInt_->newPoint(now, double(size_));
	if (pktsInt_)
		pktsInt_->newPoint(now, double(pkts_));
	if (channel_)
		printStats();
}

// The procedure to estimate the rate of the incoming traffic
void QueueMonitor::estimateRate(Packet *pkt) {
	
	hdr_cmn* hdr  = hdr_cmn::access(pkt);
	int pktSize   = hdr->size() << 3; /* length of the packet in bits */

	double now = Scheduler::instance().clock();
	double timeGap = ( now - prevTime_);

	if (timeGap == 0) {
		temp_size_ += pktSize;
		return;
	}
	else {
		pktSize+= temp_size_;
		temp_size_ = 0;
	}
	
	prevTime_ = now;
	
	estRate_ = (1 - exp(-timeGap/k_))*((double)pktSize)/timeGap + exp(-timeGap/k_)*estRate_;
}

/* ##############
 * Tcl Stuff
 * ##############
 */

static class SnoopQueueInClass : public TclClass {
public:
	SnoopQueueInClass() : TclClass("SnoopQueue/In") {}
	TclObject* create(int, const char*const*) {
		return (new SnoopQueueIn());
	}
} snoopq_in_class;

static class SnoopQueueOutClass : public TclClass {
public:
	SnoopQueueOutClass() : TclClass("SnoopQueue/Out") {}
	TclObject* create(int, const char*const*) {
		return (new SnoopQueueOut());
	}
} snoopq_out_class;

static class SnoopQueueDropClass : public TclClass {
public:
	SnoopQueueDropClass() : TclClass("SnoopQueue/Drop") {}
	TclObject* create(int, const char*const*) {
		return (new SnoopQueueDrop());
	}
} snoopq_drop_class;

static class SnoopQueueEDropClass : public TclClass {
public:
	SnoopQueueEDropClass() : TclClass("SnoopQueue/EDrop") {}
	TclObject* create(int, const char*const*) {
		return (new SnoopQueueEDrop);
	}
} snoopq_edrop_class;

/* Added by Yun Wang, for use of In/Out tagger */
static class SnoopQueueTaggerClass : public TclClass {
public:
        SnoopQueueTaggerClass() : TclClass("SnoopQueue/Tagger") {}
        TclObject* create(int, const char*const*) {
                return (new SnoopQueueTagger);
        }
} snoopq_tagger_class;

static class QueueMonitorEDClass : public TclClass {
public: 
	QueueMonitorEDClass() : TclClass("QueueMonitor/ED") {}
	TclObject* create(int, const char*const*) { 
		return (new EDQueueMonitor);
	}
} queue_monitor_ed_class;


/* ############################################################
 * a 'QueueMonitorCompat', which is used by the compat
 * code to produce the link statistics used available in ns-1
 *
 * in ns-1, the counters are the number of departures
 * ############################################################
 */

#include "ip.h"
QueueMonitorCompat::QueueMonitorCompat()
{
	memset(pkts_, 0, sizeof(pkts_));
	memset(bytes_, 0, sizeof(bytes_));
	memset(drops_, 0, sizeof(drops_));
	memset(flowstats_, 0, sizeof(flowstats_));
}


/*
 * create an entry in the flowstats_ array.
 */

void
QueueMonitorCompat::flowstats(int flowid)
{
	Tcl& tcl = Tcl::instance();

	/*
	 * here is the deal.  we are in C code.  we'd like to do
	 *     flowstats_[flowid] = new Samples;
	 * but, we want to create an object that can be
	 * referenced via tcl.  (in particular, we want ->name_
	 * to be valid.)
	 *
	 * so, how do we do this?
	 *
	 * well, the answer is, call tcl to create it.  then,
	 * do a lookup on the result from tcl!
	 */

	tcl.evalf("new Samples");
	flowstats_[flowid] = (Samples*)TclObject::lookup(tcl.result());
	if (flowstats_[flowid] == 0) {
		abort();
		/*NOTREACHED*/
	}
}


void QueueMonitorCompat::out(Packet* pkt)
{
	hdr_cmn* hdr = hdr_cmn::access(pkt);
	hdr_ip* iph = hdr_ip::access(pkt);
	double now = Scheduler::instance().clock();
	int fid = iph->flowid();

	if (fid >= MAXFLOW) {
		abort();
		/*NOTREACHED*/
	}
	// printf("QueueMonitorCompat::out(), fid=%d\n", fid);
	bytes_[fid] += hdr_cmn::access(pkt)->size();
	pkts_[fid]++;
	if (flowstats_[fid] == 0) {
		flowstats(fid);
	}
	flowstats_[fid]->newPoint(now - hdr->timestamp());
	QueueMonitor::out(pkt);
}

void QueueMonitorCompat::in(Packet* pkt)
{
	hdr_cmn* hdr = hdr_cmn::access(pkt);
	double now = Scheduler::instance().clock();
	// QueueMonitor::in() *may* do this, but we always need it...
	hdr->timestamp() = now;
	QueueMonitor::in(pkt);
}

void QueueMonitorCompat::drop(Packet* pkt)
{

	hdr_ip* iph = hdr_ip::access(pkt);
	int fid = iph->flowid();
	if (fid >= MAXFLOW) {
		abort();
		/*NOTREACHED*/
	}
	++drops_[fid];
	QueueMonitor::drop(pkt);
}

int QueueMonitorCompat::command(int argc, const char*const* argv)
{
	Tcl& tcl = Tcl::instance();
	int fid;
	if (argc == 3) {
		fid = atoi(argv[2]);
		if (strcmp(argv[1], "bytes") == 0) {
			if (fid >= MAXFLOW) {
				abort();
				/*NOTREACHED*/
			}
			tcl.resultf("%d", bytes_[fid]);
			return TCL_OK;
		} else if (strcmp(argv[1], "pkts") == 0) {
			if (fid >= MAXFLOW) {
				abort();
				/*NOTREACHED*/
			}
			tcl.resultf("%d", pkts_[fid]);
			return TCL_OK;
		} else if (strcmp(argv[1], "drops") == 0) {
			if (fid >= MAXFLOW) {
				abort();
				/*NOTREACHED*/
			}
			tcl.resultf("%d", drops_[fid]);
			return TCL_OK;
		} else if (strcmp(argv[1], "get-class-delay-samples") == 0) {
			if (fid >= MAXFLOW) {
				abort();
				/*NOTREACHED*/
			}
			if (flowstats_[fid] == 0) {
				/*
				 * instantiate one if user actually
				 * cares enough to ask for it!
				 *
				 * (otherwise, need to return "",
				 * and then special-case caller to
				 * handle this null return.)
				 */
				flowstats(fid);
			}
			tcl.resultf("%s", flowstats_[fid]->name());
			return TCL_OK;
		}
	}
	return (QueueMonitor::command(argc, argv));
}

static class QueueMonitorCompatClass : public TclClass {
 public: 
	QueueMonitorCompatClass() : TclClass("QueueMonitor/Compat") {}
	TclObject* create(int, const char*const*) { 
		return (new QueueMonitorCompat);
	}
} queue_monitor_compat_class;
