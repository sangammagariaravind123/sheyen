
# copyright (c) 1995 The Regents of the University of California.
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
# @(#) $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/test/test-suite-friendly.tcl,v 1.45 2002/03/08 21:55:41 sfloyd Exp $
#

source misc_simple.tcl
Agent/TCP set tcpTick_ 0.1
# The default for tcpTick_ is being changed to reflect a changing reality.
Agent/TCP set rfc2988_ false
# The default for rfc2988_ is being changed to true.
# FOR UPDATING GLOBAL DEFAULTS:
Queue/RED set q_weight_ 0.002
Queue/RED set thresh_ 5 
Queue/RED set maxthresh_ 15
# The RED parameter defaults are being changed for automatic configuration.
Agent/TCP set useHeaders_ false
# The default is being changed to useHeaders_ true.
Agent/TCP set windowInit_ 1
# The default is being changed to 2.
Agent/TCP set singledup_ 0
# The default is being changed to 1
Agent/TFRC set df_ 0.25
# The default for df_ is 0.95
Agent/TFRC set ca_ 0
# The default for ca_ is 1
Agent/TFRCSink set smooth_ 0
# The default for smooth_ is 1
Agent/TFRCSink set discount_ 0
# The default for discount_ is 1
Agent/TCP set oldCode_ true
# The default for oldCode_ is false.
Agent/TCP set minrto_ 0
# The default is being changed to minrto_ 1
Agent/TCP set syn_ false
Agent/TCP set delay_growth_ false
# In preparation for changing the default values for syn_ and delay_growth_.

Agent/TCP set window_ 100
# Uncomment the line below to use a random seed for the
#  random number generator.
# ns-random 0

TestSuite instproc finish file {
        global quiet PERL
        exec $PERL ../../bin/getrc -s 2 -d 3 all.tr | \
          $PERL ../../bin/raw2xg -s 0.01 -m 90 -t $file > temp1.rands
        if {$quiet == "false"} {
                exec xgraph -bb -tk -nl -m -x time -y packets temp1.rands &
        }
        ## now use default graphing tool to make a data file
        ## if so desired
#       exec csh figure2.com $file
#	exec cp temp1.rands temp.$file 
#	exec csh gnuplotA.com temp.$file $file
###        exit 0
}

Class Topology

Topology instproc node? num {
    $self instvar node_
    return $node_($num)
}

Class Topology/net2 -superclass Topology
Topology/net2 instproc init ns {
    $self instvar node_
    set node_(s1) [$ns node]
    set node_(s2) [$ns node]
    set node_(r1) [$ns node]
    set node_(r2) [$ns node]
    set node_(s3) [$ns node]
    set node_(s4) [$ns node]

    $self next
    Queue/RED set gentle_ true
    $ns duplex-link $node_(s1) $node_(r1) 10Mb 2ms DropTail
    $ns duplex-link $node_(s2) $node_(r1) 10Mb 3ms DropTail
    $ns duplex-link $node_(r1) $node_(r2) 1.5Mb 20ms RED
    $ns queue-limit $node_(r1) $node_(r2) 50
    $ns queue-limit $node_(r2) $node_(r1) 50
    $ns duplex-link $node_(s3) $node_(r2) 10Mb 4ms DropTail
    $ns duplex-link $node_(s4) $node_(r2) 10Mb 5ms DropTail
}

Class Topology/net2a -superclass Topology
Topology/net2a instproc init ns {
    $self instvar node_
    set node_(s1) [$ns node]
    set node_(s2) [$ns node]
    set node_(r1) [$ns node]
    set node_(r2) [$ns node]
    set node_(s3) [$ns node]
    set node_(s4) [$ns node]

    $self next
    Queue/RED set gentle_ true
    $ns duplex-link $node_(s1) $node_(r1) 10Mb 2ms DropTail
    $ns duplex-link $node_(s2) $node_(r1) 10Mb 3ms DropTail
    $ns duplex-link $node_(r1) $node_(r2) 0.15Kb 2ms RED
    $ns queue-limit $node_(r1) $node_(r2) 2
    $ns queue-limit $node_(r2) $node_(r1) 50
    $ns duplex-link $node_(s3) $node_(r2) 10Mb 4ms DropTail
    $ns duplex-link $node_(s4) $node_(r2) 10Mb 5ms DropTail
}

TestSuite instproc setTopo {} {
    $self instvar node_ net_ ns_ topo_

    set topo_ [new Topology/$net_ $ns_]
    if {$net_ == "net2" || $net_ == "net2a"} {
        set node_(s1) [$topo_ node? s1]
        set node_(s2) [$topo_ node? s2]
        set node_(s3) [$topo_ node? s3]
        set node_(s4) [$topo_ node? s4]
        set node_(r1) [$topo_ node? r1]
        set node_(r2) [$topo_ node? r2]
        [$ns_ link $node_(r1) $node_(r2)] trace-dynamics $ns_ stdout
    }
}

# 
# Arrange for TFCC stats to be dumped for $src every
# $interval seconds of simulation time
# 
TestSuite instproc tfccDump { label src interval file } {
	set dumpfile temp.s
        $self instvar dump_inst_ ns_ f
        if ![info exists dump_inst_($src)] {
                set dump_inst_($src) 1
                $ns_ at 0.0 "$self tfccDump $label $src $interval $file"
                return
        }
        $ns_ at [expr [$ns_ now] + $interval] "$self tfccDump $label $src $interval $file"
        set report "[$ns_ now] $label [$src set ndatapack_] " 
        puts $file $report
}

#
# Arrange for TCP stats to be dumped for $tcp every
# $interval seconds of simulation time
#
TestSuite instproc pktsDump { label tcp interval file } {
    $self instvar dump_inst_ ns_
    if ![info exists dump_inst_($tcp)] {
        set dump_inst_($tcp) 1
        $ns_ at 0.0 "$self pktsDump $label $tcp $interval $file"
        return
    }
    $ns_ at [expr [$ns_ now] + $interval] "$self pktsDump $label $tcp $interval $file"
    set report "[$ns_ now] $label [$tcp set ack_]"
    puts $file $report
}

# display graph of results
TestSuite instproc finish_1 testname {
        global quiet
        $self instvar topo_

        set graphfile temp.rands

        set awkCode  {\
		{\
                if ($2 == fid) { print $1, $3 - last; last = $3 }\
		}\
        }

        set f [open $graphfile w]
        puts $f "TitleText: $testname"
        puts $f "Device: Postscript"

        exec rm -f temp.p
        exec touch temp.p
        foreach i { 1 2 3 4 5} {
                exec echo "\n\"flow $i" >> temp.p
                exec awk $awkCode fid=$i temp.s > temp.$i
                exec cat temp.$i >> temp.p
                exec echo " " >> temp.p
        }

        exec cat temp.p >@ $f
        close $f
	exec cp -f $graphfile temp2.rands
        if {$quiet == "false"} {
                exec xgraph -bb -tk -x time -y packets temp2.rands &
        }
#	exec csh gnuplotB.com temp2.rands $testname
#       exec csh figure2.com temp.rands $testname

###        exit 0
}

TestSuite instproc runFriendly {} {
    $self instvar ns_ node_ interval_ dumpfile_

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 3]
    set tf2 [$ns_ create-connection TFRC $node_(s2) TFRCSink $node_(s4) 4]
    $ns_ at 0.0 "$tf1 start"
    $ns_ at 4.0 "$tf2 start"
    $ns_ at 30 "$tf1 stop"
    $ns_ at 30 "$tf2 stop"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_
    $self tfccDump 2 $tf2 $interval_ $dumpfile_
}

TestSuite instproc runTcp {} {
    $self instvar ns_ node_ interval_ dumpfile_

    set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) TCPSink/Sack1 $node_(s3) 3]
    set ftp1 [$tcp1 attach-app FTP]
    set tcp2 [$ns_ create-connection TCP/Sack1 $node_(s2) TCPSink/Sack1 $node_(s4) 4]
    set ftp2 [$tcp2 attach-app FTP]

    $ns_ at 0.0 "$ftp1 start"
    $ns_ at 4.0 "$ftp2 start"
    $ns_ at 30 "$ftp1 stop"
    $ns_ at 30 "$ftp2 stop"

    $self pktsDump 1 $tcp1 $interval_ $dumpfile_
    $self pktsDump 2 $tcp2 $interval_ $dumpfile_
}

TestSuite instproc runTcps {} {
    $self instvar ns_ node_ interval_ dumpfile_

    set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s2) TCPSink/Sack1 $node_(s4) 0]
    set ftp1 [$tcp1 attach-app FTP] 
    set tcp2 [$ns_ create-connection TCP/Sack1 $node_(s2) TCPSink/Sack1 $node_(s4) 1]
    set ftp2 [$tcp2 attach-app FTP] 
    set tcp3 [$ns_ create-connection TCP/Sack1 $node_(s2) TCPSink/Sack1 $node_(s4) 2]
    set ftp3 [$tcp3 attach-app FTP] 
    $ns_ at 8.0 "$ftp1 start"
    $ns_ at 12.0 "$ftp2 start"
    $ns_ at 16.0 "$ftp3 start"
    $ns_ at 24 "$ftp2 stop"
    $ns_ at 20 "$ftp3 stop"

    $self pktsDump 3 $tcp1 $interval_ $dumpfile_
    $self pktsDump 4 $tcp2 $interval_ $dumpfile_
    $self pktsDump 5 $tcp3 $interval_ $dumpfile_
}

Class Test/slowStartDiscount -superclass TestSuite
Test/slowStartDiscount instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartDiscount
    Agent/TFRCSink set discount_ 1
    Queue/RED set gentle_ false
    Test/slowStartDiscount instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/slowStartDiscountCA -superclass TestSuite
Test/slowStartDiscountCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartDiscountCA
    Agent/TFRCSink set discount_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Queue/RED set gentle_ false
    Test/slowStartDiscountCA instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/smooth -superclass TestSuite
Test/smooth instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	smooth
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Test/smooth instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/smoothCA -superclass TestSuite
Test/smoothCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	smoothCA
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/smoothCA instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/slowStart -superclass TestSuite
Test/slowStart instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStart
    Agent/TFRCSink set discount_ 0
    Queue/RED set gentle_ false
    $self next
}

Class Test/slowStartCA -superclass TestSuite
Test/slowStartCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartCA
    Agent/TFRCSink set discount_ 0
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/slowStartCA instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Test/slowStart instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 40.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"
    $ns_ at 30 "$tf1 stop"
    set tf2 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 1]
    if {$stopTime > 16} {
        $ns_ at 16 "$tf2 start"
        $ns_ at $stopTime "$tf2 stop"
        $self tfccDump 2 $tf2 $interval_ $dumpfile_
    }

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

# This test uses EWMA for estimating the loss event rate.
Class Test/slowStartEWMA -superclass TestSuite
Test/slowStartEWMA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartEWMA
    Agent/TFRCSink set algo_ 2
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/slowStartEWMA instproc run {} [Test/slowStart info instbody run ]
    $self next
}

# This test uses Fixed Windows for estimating the loss event rate.
Class Test/slowStartFixed -superclass TestSuite
Test/slowStartFixed instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartFixed
    Agent/TFRCSink set algo_ 3
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/slowStartFixed instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/ecn -superclass TestSuite
Test/ecn instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	ecn
    Agent/TFRC set ecn_ 1
    Queue/RED set setbit_ true
    Test/ecn instproc run {} [Test/slowStart info instbody run ]
    $self next
}

Class Test/slowStartTcp -superclass TestSuite
Test/slowStartTcp instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	slowStartTcp
    $self next
}
Test/slowStartTcp instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 40.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) TCPSink/Sack1 $node_(s3) 0]
    set ftp1 [$tcp1 attach-app FTP]
    $ns_ at 0.0 "$ftp1 start"
    $ns_ at 30 "$ftp1 stop"
    set tcp2 [$ns_ create-connection TCP/Sack1 $node_(s1) TCPSink/Sack1 $node_(s3) 1]
    set ftp2 [$tcp2 attach-app FTP]
    $ns_ at 16 "$ftp2 start"
    $ns_ at $stopTime "$ftp2 stop"

    $self tfccDump 1 $tcp1 $interval_ $dumpfile_
    $self tfccDump 2 $tcp2 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

Class Test/impulseDiscount -superclass TestSuite
Test/impulseDiscount instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseDiscount
    Agent/TFRCSink set discount_ 1
    Test/impulseDiscount instproc run {} [Test/impulseCA info instbody run ]
    $self next
}

Class Test/impulseDiscountCA -superclass TestSuite
Test/impulseDiscountCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseDiscountCA
    Agent/TFRCSink set discount_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/impulseDiscountCA instproc run {} [Test/impulseCA info instbody run ]
    $self next
}

Class Test/impulse -superclass TestSuite
Test/impulse instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulse
    Agent/TFRCSink set discount_ 0
    Test/impulse instproc run {} [Test/impulseCA info instbody run ]
    $self next
}

Class Test/impulseCA -superclass TestSuite
Test/impulseCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseCA
    Agent/TFRCSink set discount_ 0
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
#    Test/impulseCA instproc run {} [Test/impulseCA info instbody run ]
    $self next
}

Test/impulseCA instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 40.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"
    $ns_ at $stopTime "$tf1 stop"
    set tf2 [$ns_ create-connection TFRC $node_(s2) TFRCSink $node_(s4) 1]
    $ns_ at 10.0 "$tf2 start"
    $ns_ at 20.0 "$tf2 stop"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_
    $self tfccDump 2 $tf2 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

# Feedback 4 times per roundtrip time.
Class Test/impulseMultReportDiscount -superclass TestSuite
Test/impulseMultReportDiscount instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseMultReportDiscount
    Agent/TFRCSink set NumFeedback_ 4
    Agent/TFRCSink set discount_ 1
    Test/impulseMultReportDiscount instproc run {} [Test/impulseMultReport info instbody run ]
    $self next
}

# Feedback 4 times per roundtrip time.
Class Test/impulseMultReportDiscountCA -superclass TestSuite
Test/impulseMultReportDiscountCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseMultReportDiscountCA
    Agent/TFRCSink set NumFeedback_ 4
    Agent/TFRCSink set discount_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/impulseMultReportDiscountCA instproc run {} [Test/impulseMultReport info instbody run ]
    $self next
}

Class Test/impulseMultReport -superclass TestSuite
Test/impulseMultReport instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseMultReport
    Agent/TFRCSink set NumFeedback_ 4
    Agent/TFRCSink set discount_ 0
    $self next
}

Class Test/impulseMultReportCA -superclass TestSuite
Test/impulseMultReportCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseMultReportCA
    Agent/TFRCSink set NumFeedback_ 4
    Agent/TFRCSink set discount_ 0
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/impulseMultReportCA instproc run {} [Test/impulseMultReport info instbody run ]
    $self next
}

Test/impulseMultReport instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 40.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"
    set tf2 [$ns_ create-connection TFRC $node_(s2) TFRCSink $node_(s4) 1]
    $ns_ at 10.0 "$tf2 start"
    $ns_ at 20.0 "$tf2 stop"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_
    $self tfccDump 2 $tf2 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

Class Test/impulseTcp -superclass TestSuite
Test/impulseTcp instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	impulseTcp
    $self next
}
Test/impulseTcp instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 40.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) TCPSink/Sack1 $node_(s3) 0]
    set ftp1 [$tcp1 attach-app FTP]
    $ns_ at 0.0 "$ftp1 start"
    set tcp2 [$ns_ create-connection TCP/Sack1 $node_(s2) TCPSink/Sack1 $node_(s4) 1]
    set ftp2 [$tcp2 attach-app FTP]
    $ns_ at 10.0 "$ftp2 start"
    $ns_ at 20.0 "$ftp2 stop"

    $self tfccDump 1 $tcp1 $interval_ $dumpfile_
    $self tfccDump 2 $tcp2 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

# Two TFRC connections and three TCP connections.
Class Test/two-friendly -superclass TestSuite
Test/two-friendly instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	two-friendly
    Agent/TFRCSink set discount_ 0
    Agent/TCP set timerfix_ false
    # The default is being changed to true.
    $self next
}

# Two TFRC connections and three TCP connections.
Class Test/two-friendlyCA -superclass TestSuite
Test/two-friendlyCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	two-friendlyCA
    Agent/TFRCSink set discount_ 0
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Agent/TCP set timerfix_ false
    # The default is being changed to true.
    Test/two-friendlyCA instproc run {} [Test/two-friendly info instbody run ]
    $self next
}

Test/two-friendly instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 30.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    $self runFriendly 
    $self runTcps
    
    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

# Only TCP
Class Test/OnlyTcp -superclass TestSuite
Test/OnlyTcp instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	OnlyTcp
    Agent/TCP set timerfix_ false
    # The default is being changed to true.
    $self next
}
Test/OnlyTcp instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 30.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    $self runTcp 
    $self runTcps
    
    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

## Random factor added to sending times
Class Test/randomized -superclass TestSuite
Test/randomized instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	randomized
    Agent/TFRC set overhead_ 0.5
    Test/randomized instproc run {} [Test/slowStart info instbody run]
    $self next
}

## Random factor added to sending times
Class Test/randomizedCA -superclass TestSuite
Test/randomizedCA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	randomizedCA
    Agent/TFRC set overhead_ 0.5
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/randomizedCA instproc run {} [Test/slowStart info instbody run]
    $self next
}

## Smaller random factor added to sending times
Class Test/randomized1 -superclass TestSuite
Test/randomized1 instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	randomized1
    Agent/TFRC set overhead_ 0.1
    Test/randomized1 instproc run {} [Test/slowStart info instbody run]
    $self next
}

## Smaller random factor added to sending times
Class Test/randomized1CA -superclass TestSuite
Test/randomized1CA instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	randomized1CA
    Agent/TFRC set overhead_ 0.1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Test/randomized1CA instproc run {} [Test/slowStart info instbody run]
    $self next
}

Class Test/slow -superclass TestSuite
Test/slow instproc init {} {
    $self instvar net_ test_
    set net_	net2a
    set test_	slow
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    $self next
}

Test/slow instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
#    [$ns_ link $node_(r1) $node_(r2)] set bandwidth 0.001Mb
#    [$ns_ link $node_(r1) $node_(r2)] set queue-limit 5
    set interval_ 100
    set stopTime 4000.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

Class Test/twoDrops -superclass TestSuite
Test/twoDrops instproc init {} {
    $self instvar net_ test_ drops_ stopTime1_
    set net_	net2
    set test_	twoDrops
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    set drops_ " 2 3 "
    set stopTime1_ 5.0
    $self next
}

Class Test/manyDrops -superclass TestSuite 
Test/manyDrops instproc init {} { 
    $self instvar net_ test_ drops_ stopTime1_
    set net_    net2
    set test_   manyDrops 
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
##  set stopTime1_ 100.0
    set stopTime1_ 100.0
#    set drops_ " 0 1 "
    set drops_ " 0 1 2 3 4 5 6 "
    Test/manyDrops instproc run {} [Test/twoDrops info instbody run ]
    $self next
}

Test/twoDrops instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_ drops_ stopTime1_
    $self setTopo
    set interval_ 1
    set stopTime $stopTime1_
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set em [new ErrorModule Fid]
    set lossylink_ [$ns_ link $node_(r1) $node_(r2)]
    $lossylink_ errormodule $em
    $em default pass
    set emod [$lossylink_ errormodule]
    set errmodel [new ErrorModel/List]
    $errmodel unit pkt
    $errmodel droplist $drops_
    $emod insert $errmodel
    $emod bind $errmodel 0

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"


    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

Class Test/HighLoss -superclass TestSuite
Test/HighLoss instproc init {} {
    $self instvar net_ test_ stopTime1_
    set net_	net2
    set test_ HighLoss	
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    set stopTime1_ 60
    $self next
}
Test/HighLoss instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_ stopTime1_
    $self setTopo
    set interval_ 1
    set stopTime $stopTime1_
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"

    set udp1 [$ns_ create-connection UDP $node_(s2) UDP $node_(s4) 1]
		set cbr1 [$udp1 attach-app Traffic/CBR]
		$cbr1 set rate_ 3Mb
		$ns_ at [expr $stopTime1_/3.0] "$cbr1 start"   
		$ns_ at [expr 2.0*$stopTime1_/3.0] "$cbr1 stop"   

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}
  
Class Test/HighLossConservative -superclass TestSuite
Test/HighLossConservative instproc init {} {
    $self instvar net_ test_ stopTime1_
    set net_	net2
    set test_ HighLossConservative	
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Agent/TFRC set conservative_ true
    set stopTime1_ 60
    # Test/HighLossConservative instproc run {} [Test/HighLoss info instbody run ]
    $self next
}
Test/HighLossConservative instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_ stopTime1_
    $self setTopo
    set interval_ 1
    set stopTime $stopTime1_
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"

    set udp1 [$ns_ create-connection UDP $node_(s2) UDP $node_(s4) 1]
		set cbr1 [$udp1 attach-app Traffic/CBR]
		$cbr1 set rate_ 3Mb
		$ns_ at [expr $stopTime1_/3.0] "$cbr1 start"   
		$ns_ at [expr 2.0*$stopTime1_/3.0] "$cbr1 stop"   

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}


Class Test/HighLossTCP -superclass TestSuite
Test/HighLossTCP instproc init {} {
    $self instvar net_ test_ stopTime1_
    set net_	net2
    set test_ HighLossTCP	
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    set stopTime1_ 60
    $self next
}
Test/HighLossTCP instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_ stopTime1_
    $self setTopo
    set interval_ 1
    set stopTime $stopTime1_
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tcp1 [$ns_ create-connection TCP/Sack1 $node_(s1) TCPSink/Sack1 $node_(s3) 0]
    set ftp1 [$tcp1 attach-app FTP]
    $ns_ at 0.0 "$ftp1 start"

    set udp1 [$ns_ create-connection UDP $node_(s2) UDP $node_(s4) 1]
		set cbr1 [$udp1 attach-app Traffic/CBR]
		$cbr1 set rate_ 3Mb
		$ns_ at [expr $stopTime1_/3.0] "$cbr1 start"   
		$ns_ at [expr 2.0*$stopTime1_/3.0] "$cbr1 stop"   

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_"
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}

Class Test/TFRC_FTP -superclass TestSuite
Test/TFRC_FTP instproc init {} {
    $self instvar net_ test_ stopTime1_
    set net_	net2
    set test_ TFRC_FTP	
    Agent/TFRC set SndrType_ 1 
    Agent/TFRCSink set smooth_ 1
    Agent/TFRC set df_ 0.95
    Agent/TFRC set ca_ 1
    Agent/TFRC set discount_ 1
    Agent/TCP set oldCode_ false
    set stopTime1_ 15
    $self next
}
Test/TFRC_FTP instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_ stopTime1_
    $self setTopo
    set interval_ 1
    set stopTime $stopTime1_
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    set ftp [new Application/FTP]
    $ftp attach-agent $tf1
    $ns_ at 0 "$ftp produce 100"
    $ns_ at 5 "$ftp producemore 100"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    $ns_ at $stopTime "$self cleanupAll $testName_" 
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}
  
Class Test/printLosses -superclass TestSuite
Test/printLosses instproc init {} {
    $self instvar net_ test_
    set net_	net2
    set test_	printLosses
    Agent/TFRCSink set discount_ 1
    Agent/TFRCSink set printLosses_ 1
    Agent/TFRCSink set printLoss_ 1
    $self next
}
Test/printLosses instproc run {} {
    global quiet
    $self instvar ns_ node_ testName_ interval_ dumpfile_
    $self setTopo
    set interval_ 0.1
    set stopTime 3.0
    set stopTime0 [expr $stopTime - 0.001]
    set stopTime2 [expr $stopTime + 0.001]

    set dumpfile_ [open temp.s w]
    if {$quiet == "false"} {
        set tracefile [open all.tr w]
        $ns_ trace-all $tracefile
    }

    set tf1 [$ns_ create-connection TFRC $node_(s1) TFRCSink $node_(s3) 0]
    $ns_ at 0.0 "$tf1 start"

    $self tfccDump 1 $tf1 $interval_ $dumpfile_

    $ns_ at $stopTime0 "close $dumpfile_; $self finish_1 $testName_"
    #$self traceQueues $node_(r1) [$self openTrace $stopTime $testName_]
    $ns_ at $stopTime "$self cleanupAll $testName_"
    if {$quiet == "false"} {
	$ns_ at $stopTime2 "close $tracefile"
    }
    $ns_ at $stopTime2 "exec cp temp2.rands temp.rands; exit 0"

    # trace only the bottleneck link
    $ns_ run
}


TestSuite runTest

