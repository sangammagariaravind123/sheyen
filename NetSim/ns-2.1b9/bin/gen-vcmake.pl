# 
#  Copyright (c) 1997 by the University of Southern California
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
#  $Header: /nfs/jade/vint/CVSROOT/ns-2/bin/gen-vcmake.pl,v 1.6 1999/08/20 18:14:17 haoboy Exp $
#
# This is not to be used as an executable. Rather, it's intended to be invoked
# from Makfefile to generate a makefile.vc

while (<>) {
    (/^\$\(GEN_DIR\)ns_tcl\.cc/ || /^\$\(GEN_DIR\)version.c/) && do {
	# print current line followed by a '-mkdir gen...'
	print $_;
	print "\t-mkdir \$(GEN_DIR:\\\\=)\n";
	next;
    };

    /^makefile\.vc:/ && do {
	# skip this line and the next two lines;
	<>; <>;
	next;
    };

    # Convert ptypes2tcl, change directory separator from '/' to '\'
    /\.\/ptypes2tcl/ && do { 
	s/\//\\/;
	s/ptypes2tcl/ptypes2tcl\.exe/;
	print $_;
	next;
    };
    # Convert ptypes2tcl to ptypes2tcl.exe
    /ptypes2tcl / && do {
	s/ptypes2tcl/ptypes2tcl\.exe/;
	print $_;
	next;
    };
    /ptypes2tcl:/ && do {
	s/ptypes2tcl/ptypes2tcl\.exe/;
	print $_;
	next;
    };

    # omit ns-autoconf.tcl, because we cannot generate it. :( 
    /ns-autoconf\.tcl/ && do {
	next;
    };

    /^Makefile: Makefile.in/ && do {
	# skip clause
	while (<>) {
	    chomp;
	    last if ($_ eq '');
	};
	next;
    };

    # remove dependence on Makefile from $(NS)
    /^\$\(NS\)/ && do {
	s/ Makefile//;
	print $_;
	next;
    };

    s/^# (\!include)/\!include/o;
    print $_;
}

exit 0;
