/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * mcast_ctrl.cc
 * Copyright (C) 1997 by USC/ISI
 * All rights reserved.                                            
 *                                                                
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation, advertising
 * materials, and other materials related to such distribution and use
 * acknowledge that the software was developed by the University of
 * Southern California, Information Sciences Institute.  The name of the
 * University may not be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Contributed by Polly Huang (USC/ISI), http://www-scf.usc.edu/~bhuang
 */

#ifndef lint
static const char rcsid[] =
    "@(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/mcast/mcast_ctrl.cc,v 1.6 2000/09/01 03:04:06 haoboy Exp $ (LBL)";
#endif

#include "agent.h"
#include "packet.h"
#include "mcast_ctrl.h"

class mcastControlAgent : public Agent {
public:
	mcastControlAgent() : Agent(PT_NTYPE) {
		bind("packetSize_", &size_);
	}

	void recv(Packet* pkt, Handler*) {
		hdr_mcast_ctrl* ph = hdr_mcast_ctrl::access(pkt);
		hdr_cmn* ch = hdr_cmn::access(pkt);
		// Agent/Mcast/Control instproc recv type from src group iface
		Tcl::instance().evalf("%s recv %s %d %d", name(),
				      ph->type(), ch->iface(), ph->args());
		Packet::free(pkt);
	}

	/*
 	 * $proc send $type $src $group
 	 */

#define	CASE(c,str,type)						\
		case (c):	if (strcmp(argv[2], (str)) == 0) {	\
			type_ = (type);					\
			break;						\
		} else {						\
			/*FALLTHROUGH*/					\
		}

	int command(int argc, const char*const* argv) {
		if (argc == 4) {
			if (strcmp(argv[1], "send") == 0) {
				switch (*argv[2]) {
					CASE('p', "prune", PT_PRUNE);
					CASE('g', "graft", PT_GRAFT);
					CASE('X', "graftAck", PT_GRAFTACK);
					CASE('j', "join",  PT_JOIN);
					CASE('a', "assert", PT_ASSERT);
				default:
					Tcl& tcl = Tcl::instance();
					tcl.result("invalid control message");
					return (TCL_ERROR);
				}
				Packet* pkt = allocpkt();
				hdr_mcast_ctrl* ph=hdr_mcast_ctrl::access(pkt);
				strcpy(ph->type(), argv[2]);
				ph->args()  = atoi(argv[3]);
				send(pkt, 0);
				return (TCL_OK);
			}
		}
		return (Agent::command(argc, argv));
	}
};

//
// Now put the standard OTcl linkage templates here
//
int hdr_mcast_ctrl::offset_;
static class mcastControlHeaderClass : public PacketHeaderClass {
public:
        mcastControlHeaderClass() : PacketHeaderClass("PacketHeader/mcastCtrl",
					     sizeof(hdr_mcast_ctrl)) {
		bind_offset(&hdr_mcast_ctrl::offset_);
	}
} class_mcast_ctrl_hdr;

static class mcastControlClass : public TclClass {
public:
	mcastControlClass() : TclClass("Agent/Mcast/Control") {}
	TclObject* create(int, const char*const*) {
		return (new mcastControlAgent());
	}
} class_mcast_ctrl;
