// Copyright (c) 2000 by the University of Southern California
// All rights reserved.
//
// Permission to use, copy, modify, and distribute this software and its
// documentation in source and binary forms for non-commercial purposes
// and without fee is hereby granted, provided that the above copyright
// notice appear in all copies and that both the copyright notice and
// this permission notice appear in supporting documentation. and that
// any documentation, advertising materials, and other materials related
// to such distribution and use acknowledge that the software was
// developed by the University of Southern California, Information
// Sciences Institute.  The name of the University may not be used to
// endorse or promote products derived from this software without
// specific prior written permission.
//
// THE UNIVERSITY OF SOUTHERN CALIFORNIA makes no representations about
// the suitability of this software for any purpose.  THIS SOFTWARE IS
// PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Other copyrights might apply to parts of this software and are so
// noted when applicable.
//
// Ported from CMU/Monarch's code, appropriate copyright applies.  

/* -*- c++ -*-
   requesttable.h

   implement a table to keep track of the most current request
   number we've heard from a node in terms of that node's id

   implemented as a circular buffer

*/

#ifndef _requesttable_h
#define _requesttable_h

#include "path.h"

struct Entry;

enum LastType { LIMIT0, UNLIMIT};

class RequestTable {
public:
  RequestTable(int size = 30);
  ~RequestTable();
  void insert(const ID& net_id, int req_num);
  void insert(const ID& net_id, const ID& MAC_id, int req_num);
  int get(const ID& id) const;
  // rtns 0 if id not found
  Entry* getEntry(const ID& id);  
private:
  Entry *table;
  int size;
  int ptr;
  int find(const ID& net_id, const ID& MAC_id ) const;
};

struct Entry {
  ID MAC_id;
  ID net_id;
  int req_num;
  Time last_arp;
  int rt_reqs_outstanding;
  Time last_rt_req;
  LastType last_type;
};

#endif //_requesttable_h
