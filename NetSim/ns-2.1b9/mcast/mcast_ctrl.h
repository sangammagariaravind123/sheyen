/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
/*
 * mcast_ctrl.h
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
 *
 * @(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/mcast/mcast_ctrl.h,v 1.3 2000/09/01 03:04:06 haoboy Exp $ (LBL)
 */
    

#ifndef ns_mcast_ctrl_h
#define ns_mcast_ctrl_h

struct hdr_mcast_ctrl {
	char           ptype_[15];
	int	       args_;

        /* per-field member functions */
        char*     type()  { return ptype_; }
	int&	  args()  { return args_;  }
	int maxtype()     { return sizeof(ptype_); }

	// Header access methods
	static int offset_; // required by PacketHeaderManager
	inline static int& offset() { return offset_; }
	inline static hdr_mcast_ctrl* access(const Packet* p) {
		return (hdr_mcast_ctrl*) p->access(offset_);
	}
};

#endif



