#
# Copyright (c) 1995 The Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#	This product includes software developed by the Computer Systems
#	Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# @(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/test/test-suite-LimTransmit.tcl,v 1.6 2002/03/08 21:55:41 sfloyd Exp $
#
# To view a list of available tests to run with this script:
# ns test-suite-tcpVariants.tcl
#

source misc_simple.tcl
Agent/TCP set tcpTick_ 0.1
# The default for tcpTick_ is being changed to reflect a changing reality.
Agent/TCP set rfc2988_ false
# The default for rfc2988_ is being changed to true.

# FOR UPDATING GLOBAL DEFAULTS:
Agent/TCP set singledup_ 0
# The default is being changed to 1
Trace set show_tcphdr_ 1
Agent/TCP set useHeaders_ false
# The default is being changed to useHeaders_ true.
Agent/TCP set tcpTick_ 0.5
## First scenaio: maxpkts 15, droppkt 4.
## For the paper: droppkt 2.


set wrap 90
set wrap1 [expr 90 * 512 + 40]

Class Topology

Topology instproc node? num {
    $self instvar node_
    return $node_($num)
}

#
# Links1 uses 8Mb, 5ms feeders, and a 800Kb 10ms bottleneck.
# Queue-limit on bottleneck is 2 packets.
#
Class Topology/net4 -superclass Topology
Topology/net4 instproc init ns {
    $self instvar node_
    set node_(s1) [$ns node]
    set node_(s2) [$ns node]
    set node_(r1) [$ns node]
    set node_(k1) [$ns node]

    $self next
    $ns duplex-link $node_(s1) $node_(r1) 8Mb 0ms DropTail
    $ns duplex-link $node_(s2) $node_(r1) 8Mb 0ms DropTail
    $ns duplex-link $node_(r1) $node_(k1) 800Kb 100ms DropTail
    # 800Kb/sec = 100 pkts/sec = 20 pkts/200 ms.
    $ns queue-limit $node_(r1) $node_(k1) 8
    $ns queue-limit $node_(k1) $node_(r1) 8

    $self instvar lossylink_
    set lossylink_ [$ns link $node_(r1) $node_(k1)]
    set em [new ErrorModule Fid]
    set errmodel [new ErrorModel/Periodic]
    $errmodel unit pkt
    $lossylink_ errormodule $em
}


TestSuite instproc finish file {
	global quiet wrap PERL
        exec $PERL ../../bin/set_flow_id -m all.tr > t
        exec $PERL ../../bin/getrc -s 0 -d 2 t > t1 
        exec  $PERL ../../bin/raw2xg -c -a -s 0.01 -m $wrap -t $file t1 > temp.rands
	exec $PERL ../../bin/getrc -s 2 -d 0 t > t2
        exec $PERL ../../bin/raw2xg -c -a -s 0.01 -m $wrap -t $file t2 > temp1.rands
        exec $PERL ../../bin/getrc -s 2 -d 3 t | \
          $PERL ../../bin/raw2xg -c -d -s 0.01 -m $wrap -t $file > temp2.rands
        #exec $PERL ../../bin/set_flow_id -s all.tr | \
        #  $PERL ../../bin/getrc -s 2 -d 3 | \
        #  $PERL ../../bin/raw2xg -s 0.01 -m $wrap -t $file > temp.rands
	if {$quiet == "false"} {
		exec xgraph -bb -tk -nl -m -x time -y packets temp.rands \
		temp1.rands temp2.rands &
	}
        ## now use default graphing tool to make a data file
	## if so desired
        # exec csh gnuplotC.com temp.rands temp1.rands temp2.rands $file
        exit 0
}

TestSuite instproc printtimers { tcp time} {
	global quiet
	if {$quiet == "false"} {
        	puts "time: $time sRTT(in ticks): [$tcp set srtt_]/8 RTTvar(in ticks): [$tcp set rttvar_]/4 backoff: [$tcp set backoff_]"
	}
}

TestSuite instproc printtimersAll { tcp time interval } {
        $self instvar dump_inst_ ns_
        if ![info exists dump_inst_($tcp)] {
                set dump_inst_($tcp) 1
                $ns_ at $time "$self printtimersAll $tcp $time $interval"
                return
        }
	set newTime [expr [$ns_ now] + $interval]
	$ns_ at $time "$self printtimers $tcp $time"
        $ns_ at $newTime "$self printtimersAll $tcp $newTime $interval"
}


TestSuite instproc emod {} {
        $self instvar topo_
        $topo_ instvar lossylink_
        set errmodule [$lossylink_ errormodule]
        return $errmodule
} 

TestSuite instproc drop_pkts { pkts {ecn 0}} {
    $self instvar ns_
    set emod [$self emod]
    set errmodel1 [new ErrorModel/List]
    if {$ecn == "ECN"} {
    	$errmodel1 set markecn_ true
    }
    $errmodel1 droplist $pkts
    $emod insert $errmodel1
    $emod bind $errmodel1 1
}

TestSuite instproc setTopo {} {
    $self instvar node_ net_ ns_ topo_

    set topo_ [new Topology/$net_ $ns_]
    set node_(s1) [$topo_ node? s1]
    set node_(s2) [$topo_ node? s2]
    set node_(r1) [$topo_ node? r1]
    set node_(k1) [$topo_ node? k1]
    [$ns_ link $node_(r1) $node_(k1)] trace-dynamics $ns_ stdout
}

TestSuite instproc setup { tcptype list {ecn 0}} {
	global wrap wrap1
        $self instvar ns_ node_ testName_
	$self setTopo

        Agent/TCP set bugFix_ false
	if {$ecn == "ECN"} {
		 Agent/TCP set ecn_ 1
	}
	set fid 1
        # Set up TCP connection
    	if {$tcptype == "Tahoe"} {
      		set tcp1 [$ns_ create-connection TCP $node_(s1) \
          	TCPSink/DelAck $node_(k1) $fid]
    	} elseif {$tcptype == "Sack1"} {
      		set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) \
          	TCPSink/Sack1/DelAck  $node_(k1) $fid]
    	} else {
      		set tcp1 [$ns_ create-connection TCP/$tcptype $node_(s1) \
          	TCPSink/DelAck $node_(k1) $fid]
    	}
        $tcp1 set window_ 28
        set ftp1 [$tcp1 attach-app FTP]
        $ns_ at 0.0 "$ftp1 produce 7"

        $self tcpDump $tcp1 5.0
        $self drop_pkts $list $ecn

        #$self traceQueues $node_(r1) [$self openTrace 6.0 $testName_]
	$ns_ at 6.0 "$self cleanupAll $testName_"
        $ns_ run
}

# Definition of test-suite tests

###################################################
## One drop
###################################################

Class Test/onedrop_sack -superclass TestSuite
Test/onedrop_sack instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	onedrop_sack
	$self next
}
Test/onedrop_sack instproc run {} {
        $self setup Sack1 {1}
}

Class Test/onedrop_SA_sack -superclass TestSuite
Test/onedrop_SA_sack instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	onedrop_SA_sack
	Agent/TCP set singledup_ 1
	Test/onedrop_SA_sack instproc run {} [Test/onedrop_sack info instbody run ]
	$self next
}

Class Test/onedrop_ECN_sack -superclass TestSuite
Test/onedrop_ECN_sack instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	onedrop_ECN_sack
	Agent/TCP set ecn_ 1
	$self next
}
Test/onedrop_ECN_sack instproc run {} {
        $self setup Sack1 {1} ECN
}

Class Test/nodrop_sack -superclass TestSuite
Test/nodrop_sack instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	nodrop_sack
	$self next
}
Test/nodrop_sack instproc run {} {
        $self setup Sack1 {1000} 
}


# Bad Retransmit Timeout.
Class Test/badtimeout -superclass TestSuite
Test/badtimeout instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	badtimeout
	$self next
}
Test/badtimeout instproc run {} {
	global wrap wrap1
        $self instvar ns_ node_ testName_
	$self setTopo

	set ecn 0
        Agent/TCP set bugFix_ false
	set fid 1
        # Set up TCP connection
      	set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) \
        TCPSink/Sack1/DelAck  $node_(k1) $fid]
        $tcp1 set window_ 20
        set ftp1 [$tcp1 attach-app FTP]
        $ns_ at 0.0 "$ftp1 produce 99"
	$self drop_pkts {1000}

        $self tcpDump $tcp1 5.0

        #$self traceQueues $node_(r1) [$self openTrace 6.0 $testName_]
	# 0.5, 0.8, 1450
	$ns_ at 1.4 "$ns_ delay $node_(r1) $node_(k1) 1650ms simplex"
	$ns_ at 1.7  "$ns_ delay $node_(r1) $node_(k1) 100ms simplex"
	$ns_ at 6.0 "$self cleanupAll $testName_"
        $ns_ run
}

Class Test/notimeout -superclass TestSuite
Test/notimeout instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	notimeout
	Agent/TCP set tcpTick_ 1.0
	Test/notimeout instproc run {} [Test/badtimeout info instbody run ]
	$self next
}

# Bad Fast Retransmit.
Class Test/badretransmit -superclass TestSuite
Test/badretransmit instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	badretransmit
	$self next
}
Test/badretransmit instproc run {} {
	global wrap wrap1
        $self instvar ns_ node_ testName_
	$self setTopo
	$ns_ queue-limit $node_(r1) $node_(k1) 100

	set ecn 0
        Agent/TCP set bugFix_ false
	set fid 1
        # Set up TCP connection
      	set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) \
        TCPSink/Sack1/DelAck  $node_(k1) $fid]
        $tcp1 set window_ 25
        set ftp1 [$tcp1 attach-app FTP]
        $ns_ at 0.0 "$ftp1 produce 89"
	$self drop_pkts {1000}

        $self tcpDump $tcp1 5.0

        #$self traceQueues $node_(r1) [$self openTrace 6.0 $testName_]
	$ns_ at 0.753 "$ns_ delay $node_(r1) $node_(k1) 220ms simplex"
	$ns_ at 0.756  "$ns_ delay $node_(r1) $node_(k1) 100ms simplex"
	$ns_ at 6.0 "$self cleanupAll $testName_"
        $ns_ run
}

# Bad Fast Retransmit.
Class Test/nobadretransmit -superclass TestSuite
Test/nobadretransmit instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	nobadretransmit
	$self next
}
Test/nobadretransmit instproc run {} {
	global wrap wrap1
        $self instvar ns_ node_ testName_
	$self setTopo
	$ns_ queue-limit $node_(r1) $node_(k1) 100

	set ecn 0
        Agent/TCP set bugFix_ false
	set fid 1
        # Set up TCP connection
      	set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) \
        TCPSink/Sack1/DelAck  $node_(k1) $fid]
        $tcp1 set window_ 25
        set ftp1 [$tcp1 attach-app FTP]
        $ns_ at 0.0 "$ftp1 produce 89"
	$self drop_pkts {1000}

        $self tcpDump $tcp1 5.0

        #$self traceQueues $node_(r1) [$self openTrace 6.0 $testName_]
	$ns_ at 0.753 "$ns_ delay $node_(r1) $node_(k1) 210ms simplex"
	$ns_ at 0.756  "$ns_ delay $node_(r1) $node_(k1) 100ms simplex"
	$ns_ at 6.0 "$self cleanupAll $testName_"
        $ns_ run
}

TestSuite runTest
