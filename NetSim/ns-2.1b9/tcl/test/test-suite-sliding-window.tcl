#
Agent/TCP set tcpTick_ 0.1
# The default for tcpTick_ is being changed to reflect a changing reality.
Agent/TCP set rfc2988_ false
# The default for rfc2988_ is being changed to true.
# FOR UPDATING GLOBAL DEFAULTS:
Agent/TCP set useHeaders_ false
# The default is being changed to useHeaders_ true.
Agent/TCP set windowInit_ 1
# The default is being changed to 2.
Agent/TCP set singledup_ 0
# The default is being changed to 1
# Copyright (c) 1998 University of Southern California.
# All rights reserved.                                            
#                                                                
# Redistribution and use in source and binary forms are permitted
# provided that the above copyright notice and this paragraph are
# duplicated in all such forms and that any documentation, advertising
# materials, and other materials related to such distribution and use
# acknowledge that the software was developed by the University of
# Southern California, Information Sciences Institute.  The name of the
# University may not be used to endorse or promote products derived from
# this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
# 


# This test suite is for validating sliding window
# To run all tests: test-all-sliding-window
# to run individual test:
# ns test-suite-sliding-window.tcl sliding-normal
# ns test-suite-sliding-window.tcl sliding-loss
#
# To view a list of available test to run with this script:
# ns test-suite-sliding-window.tcl
#
# Each of the tests uses 6 nodes 
#

Class TestSuite

Class Test/sliding-normal -superclass TestSuite
# Simple sliding window without any packet loss

Class Test/sliding-loss -superclass TestSuite
# Simple sliding window with packet loss

proc usage {} {
	global argv0
	puts stderr "usage: ns $argv0 <tests> "
	puts "Valid <tests> : sliding-normal sliding-loss"
	exit 1
}

TestSuite instproc init {} {

    $self instvar ns_ n_

    set ns_ [new Simulator]
    $ns_ trace-all [open temp.rands w]
    $ns_ namtrace-all [open temp.rands.nam w]

    # setup sliding window topology
       
    foreach i " 0 1 2 3 4 5" {
	set n_($i) [$ns_ node]
    }

    $ns_ duplex-link $n_(0) $n_(2) 1Mb 20ms DropTail
    $ns_ duplex-link $n_(1) $n_(2) 1Mb 20ms DropTail
    $ns_ duplex-link $n_(2) $n_(3) 0.5Mb 20ms DropTail
    $ns_ duplex-link $n_(3) $n_(4) 1Mb 20ms DropTail
    $ns_ duplex-link $n_(3) $n_(5) 1Mb 20ms DropTail

    $ns_ duplex-link-op $n_(0) $n_(2) orient right-down
    $ns_ duplex-link-op $n_(1) $n_(2) orient right-up
    $ns_ duplex-link-op $n_(2) $n_(3) orient right
    $ns_ duplex-link-op $n_(3) $n_(4) orient right-up
    $ns_ duplex-link-op $n_(3) $n_(5) orient right-down

    $ns_ duplex-link-op $n_(2) $n_(3) queuePos 0.5
}

TestSuite instproc finish {} {
	$self instvar ns_
	global quiet

	$ns_ flush-trace
        if { !$quiet } {
                puts "running nam..."
                exec nam temp.rands.nam &
        }
	exit 0
}

Test/sliding-normal instproc init {flag} {
	$self instvar ns_ testName_ flag_
	set testName_ sliding-normal
	set flag_ $flag
	$self next
}

Test/sliding-normal instproc run {} {

	$self instvar ns_ n_ 
        $ns_ queue-limit $n_(2) $n_(3) 50

        ### TCP between n_(0) & n_(4)
        Agent/TCP set maxcwnd_ 8
        set sliding [new Agent/TCP/SlidingWindow]
        $ns_ attach-agent $n_(0) $sliding
        set sink [new Agent/TCPSink/SlidingWindowSink]
        $ns_ attach-agent $n_(4) $sink
        $ns_ connect $sliding $sink
        set ftp [new Application/FTP]
        $ftp attach-agent $sliding

        ### CBR traffic between n_(1) & n_(5)
        set udp0 [new Agent/UDP]
        $ns_ attach-agent $n_(1) $udp0
        set cbr0 [new Application/Traffic/CBR]
        $cbr0 set packetSize_ 500
        $cbr0 set interval_ 0.01
        $cbr0 attach-agent $udp0
        set null0 [new Agent/Null]
        $ns_ attach-agent $n_(5) $null0
        $ns_ connect $udp0 $null0

        ### setup operation
	$ns_ at 0.1 "$cbr0 start"
        $ns_ at 1.1 "$cbr0 stop"
        $ns_ at 0.2 "$ftp start"
        $ns_ at 1.1 "$ftp stop"
	$ns_ at 1.2 "$self finish"
	$ns_ run
}

Test/sliding-loss instproc init {flag} {
	$self instvar ns_ testName_ flag_
	set testName_ sliding-loss
	set flag_ $flag
	$self next 
}

Test/sliding-loss instproc run {} {

	$self instvar ns_ n_
        $ns_ queue-limit $n_(2) $n_(3) 10

        ### TCP between n_(0) & n_(4)
        Agent/TCP set maxcwnd_ 8
        set sliding [new Agent/TCP/SlidingWindow]
        $ns_ attach-agent $n_(0) $sliding
        set sink [new Agent/TCPSink/SlidingWindowSink]
        $ns_ attach-agent $n_(4) $sink
        $ns_ connect $sliding $sink
        set ftp [new Application/FTP]
        $ftp attach-agent $sliding

        ### CBR traffic between n_(1) & n_(5)
        set udp0 [new Agent/UDP]
        $ns_ attach-agent $n_(1) $udp0
        set cbr0 [new Application/Traffic/CBR]
        $cbr0 attach-agent $udp0
        set null0 [new Agent/Null]
        $ns_ attach-agent $n_(5) $null0
        $ns_ connect $udp0 $null0

        ### setup operation
	$ns_ at 0.1 "$cbr0 start"
        $ns_ at 1.1 "$cbr0 stop"
        $ns_ at 0.2 "$ftp start"
        $ns_ at 1.1 "$ftp stop"
	$ns_ at 1.2 "$self finish"
	$ns_ run
}
	
proc runtest {arg} {
	global quiet
	set quiet 0

	set b [llength $arg]
	if {$b == 1} {
		set test $arg
	} elseif {$b == 2} {
		set test [lindex $arg 0]
	    if {[lindex $arg 1] == "QUIET"} {
		set quiet 1
	    }
	} else {
		usage
	}
	switch $test {
                sliding-normal -
                sliding-loss {
			set t [new Test/$test 1]
		}
		default {
			stderr "Unknown test $test"
			exit 1
		}
	}
	$t run
}

global argv arg0
runtest $argv


