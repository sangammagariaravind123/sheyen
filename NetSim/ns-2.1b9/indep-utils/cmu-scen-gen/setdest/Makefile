# 
#  Copyright (c) 1999 by the University of Southern California
#  All rights reserved.
# 
#  Permission to use, copy, modify, and distribute this software and its
#  documentation in source and binary forms for non-commercial purposes
#  and without fee is hereby granted, provided that the above copyright
#  notice appear in all copies and that both the copyright notice and
#  this permission notice appear in supporting documentation. and that
#  any documentation, advertising materials, and other materials related
#  to such distribution and use acknowledge that the software was
#  developed by the University of Southern California, Information
#  Sciences Institute.  The name of the University may not be used to
#  endorse or promote products derived from this software without
#  specific prior written permission.
# 
#  THE UNIVERSITY OF SOUTHERN CALIFORNIA makes no representations about
#  the suitability of this software for any purpose.  THIS SOFTWARE IS
#  PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
# 
#  Other copyrights might apply to parts of this software and are so
#  noted when applicable.
#
# Makefile for CMU mobile code scenario generation.
#
# $Header: /nfs/jade/vint/CVSROOT/ns-2/indep-utils/cmu-scen-gen/setdest/Makefile.in,v 1.7 2002/01/07 18:43:12 haldar Exp $

# Top level hierarchy
#prefix	= /nfs/ruby/buchheim/nsnam/
# Pathname of directory to install the binary
#BINDEST	= /nfs/ruby/buchheim/nsnam//bin

CCX = g++
CC = gcc
MKDEP	= ../../../conf/mkdep

DEFINE = -Dstand_alone
CFLAGS = -O2 
LDFLAGS = 
LIBS =  -lnsl -lpcap -ldl -lm 
#INSTALL = /nfs/ruby/buchheim/bin/install -c

all: setdest calcdest

install: setdest calcdest
	$(INSTALL) -m 555 -o bin -g bin setdest $(DESTDIR)$(BINDEST)
	$(INSTALL) -m 555 -o bin -g bin calcdest $(DESTDIR)$(BINDEST)

setdest: rng.o setdest.o
	$(CC) -o setdest $@.o rng.o $(DEFINE) $(LDFLAGS) $(CFLAGS) \
	$(LIBS)

calcdest: rng.o calcdest.o
	$(CC) -o calcdest $@.o rng.o $(DEFINE) $(LDFLAGS) $(CFLAGS) \
	$(LIBS)

rng.o:
	del /f $@
	$(CC) -c $(DEFINE) -I../../.. -o $@ ../../../tools/rng.cc

setbox: setbox.o
	$(CC) -o setbox $@.o $(LDFLAGS) $(CFLAGS) $(LIBS)

clean:
	del /f setdest setbox *.o *.core

.SUFFIXES: .cc

.cc.o:
	$(CCX) -c $(DEFINE) $(CFLAGS) -o $@ $*.cc

