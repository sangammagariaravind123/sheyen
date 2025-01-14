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
# @(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/test/test-suite-testReno.tcl,v 1.11 2002/03/08 21:55:44 sfloyd Exp $
#
# To view a list of available tests to run with this script:
# ns test-suite-testReno.tcl
#

source misc_simple.tcl
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

Agent/TCP set minrto_ 0
# The default is being changed to minrto_ 1
Agent/TCP set syn_ false
Agent/TCP set delay_growth_ false
# In preparation for changing the default values for syn_ and delay_growth_.

Trace set show_tcphdr_ 1

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
    exec $PERL ../../bin/set_flow_id -s all.tr | \
	    $PERL ../../bin/getrc -e -s 2 -d 3 | \
	    $PERL ../../bin/raw2xg -v -s 0.01 -m $wrap -t $file > temp.rands

    if {$quiet == "false"} {
	exec xgraph -bb -tk -nl -m -x time -y packets temp.rands &
    }
    ## now use default graphing tool to make a data file
    ## if so desired
    # exec csh gnuplotC.com temp.rands $file
    exit 0
}

TestSuite instproc emod {} {
        $self instvar topo_
        $topo_ instvar lossylink_
        set errmodule [$lossylink_ errormodule]
        return $errmodule
} 

TestSuite instproc drop_pkts pkts {
    $self instvar ns_
    set emod [$self emod]
    set errmodel1 [new ErrorModel/List]
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

TestSuite instproc setup {tcptype window list} {
	global wrap wrap1
        $self instvar ns_ node_ testName_
	$self setTopo

        Agent/TCP set bugFix_ false
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

        #$tcp1 set window_ 5
	$tcp1 set window_ $window
        set ftp1 [$tcp1 attach-app FTP]
        $ns_ at 1.0 "$ftp1 start"

        $self tcpDump $tcp1 4.0
        $self drop_pkts $list

        #$self traceQueues $node_(r1) [$self openTrace 4.01 $testName_]
	$ns_ at 4.01 "$self cleanupAll $testName_"
        $ns_ run
}


# Definition of test-suite tests

###################################################
## Two drops
###################################################

Class Test/Tahoe_TCP -superclass TestSuite
Test/Tahoe_TCP instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Tahoe_TCP
	$self next
}
Test/Tahoe_TCP instproc run {} {
    $self setup Tahoe {5} {15 18}
}

Class Test/Tahoe_TCP_without_Fast_Retransmit -superclass TestSuite
Test/Tahoe_TCP_without_Fast_Retransmit instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Tahoe_TCP_without_Fast_Retransmit
	Agent/TCP set noFastRetrans_ true
	$self next
}
Test/Tahoe_TCP_without_Fast_Retransmit instproc run {} {
    $self setup Tahoe {5} {15 18}
}

Class Test/Reno_TCP -superclass TestSuite
Test/Reno_TCP instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Reno_TCP
	$self next
}
Test/Reno_TCP instproc run {} {
    $self setup Reno {5} {15 18}
}

Class Test/NewReno_TCP -superclass TestSuite
Test/NewReno_TCP instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	NewReno_TCP
	Agent/TCP set noFastRetrans_ false
	$self next
}
Test/NewReno_TCP instproc run {} {
    $self setup Newreno {5} {15 18}
}

Class Test/Sack_TCP -superclass TestSuite
Test/Sack_TCP instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Sack_TCP
	Agent/TCP set noFastRetrans_ false
	$self next
}
Test/Sack_TCP instproc run {} {
    $self setup Sack1 {5} {15 18}
}

###################################################
## One drop
###################################################

Class Test/Tahoe_TCP2 -superclass TestSuite
Test/Tahoe_TCP2 instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Tahoe_TCP2
	$self next
}
Test/Tahoe_TCP2 instproc run {} {
        #$self setup1 Tahoe {17}
	$self setup Tahoe {8} {17}
}

Class Test/Tahoe_TCP2_without_Fast_Retransmit -superclass TestSuite
Test/Tahoe_TCP2_without_Fast_Retransmit instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Tahoe_TCP2_without_Fast_Retransmit
	Agent/TCP set noFastRetrans_ true
	$self next
}
Test/Tahoe_TCP2_without_Fast_Retransmit instproc run {} {
        #$self setup1 Tahoe {17}
	$self setup Tahoe {8} {17}
}

Class Test/Reno_TCP2 -superclass TestSuite
Test/Reno_TCP2 instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Reno_TCP2
	$self next
}
Test/Reno_TCP2 instproc run {} {
    $self setup Reno {8} {17}
}

Class Test/NewReno_TCP2 -superclass TestSuite
Test/NewReno_TCP2 instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	NewReno_TCP2
	Agent/TCP set noFastRetrans_ false
	$self next
}
Test/NewReno_TCP2 instproc run {} {
    $self setup Newreno {8} {17}
}

Class Test/Sack_TCP2 -superclass TestSuite
Test/Sack_TCP2 instproc init {} {
	$self instvar net_ test_
	set net_	net4
	set test_	Sack_TCP2
	Agent/TCP set noFastRetrans_ false
	$self next
}
Test/Sack_TCP2 instproc run {} {
    $self setup Sack1 {8} {17}
}

TestSuite runTest

