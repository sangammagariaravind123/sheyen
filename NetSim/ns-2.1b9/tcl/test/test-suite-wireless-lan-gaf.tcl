# -*-	Mode:tcl; tcl-indent-level:8; tab-width:8; indent-tabs-mode:t -*-
Agent/TCP set tcpTick_ 0.1
# The default for tcpTick_ is being changed to reflect a changing reality.
Agent/TCP set rfc2988_ false
# The default for rfc2988_ is being changed to true.
# FOR UPDATING GLOBAL DEFAULTS:
Agent/TCP set windowInit_ 1
# The default is being changed to 2.
Agent/TCP set singledup_ 0
# The default is being changed to 1
#
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
# $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/test/test-suite-wireless-lan-gaf.tcl,v 1.5 2002/03/08 21:55:44 sfloyd Exp $

# This test suite is for validating wireless lans 
# To run all tests: test-all-wireless-lan-tora
# to run individual test:
#
# To view a list of available test to run with this script:
# ns test-suite-wireless-lan.tcl
#

Class TestSuite

Class Test/gaf -superclass TestSuite
#wireless model using AODV

proc usage {} {
	global argv0
	puts stderr "usage: ns $argv0 <tests> "
	puts "Valid Tests: dsdv dsr"
	exit 1
}


proc default_options {} {
    global opt

set opt(chan)           Channel/WirelessChannel
set opt(prop)           Propagation/TwoRayGround
set opt(netif)          Phy/WirelessPhy
set opt(mac)            Mac/802_11
set opt(ifq)            Queue/DropTail/PriQueue
set opt(ll)             LL
set opt(ant)            Antenna/OmniAntenna
 
set opt(x)              1500    ;# X dimension of the topography
set opt(y)              300             ;# Y dimension of the topography
set opt(grid)           100     ;# grid size
set opt(cp)             "../mobility/scene/cbr-10-1-10-20"
set opt(sc)             "../mobility/scene/scen-1500x300-60-0-20-2"
 
set opt(ifqlen)         50              ;# max packet in ifq
set opt(nn)             60              ;# number of nodes
set opt(seed)           0.0
set opt(stop)           800.0           ;# simulation time
set opt(tr)             temp.rands          ;# trace file
set opt(rp)             AODV            ;# routing protocol script
set opt(lm)             "off"           ;# log movement
set opt(energymodel)    EnergyModel     ;
set opt(initialenergy)  500             ;# Initial energy in Joules
set opt(infiniteenergy)  20000           ;# enough to keep sim run to the end
#set opt(logenergy)      "on"           ;# log energy every 150 seconds
set opt(gaf4)           0               ;# = 1 means run gaf        

}


# =====================================================================
# Other default settings

LL set mindelay_		50us
LL set delay_			25us
LL set bandwidth_		0	;# not used

Agent/Null set sport_		0
Agent/Null set dport_		0

Agent/CBR set sport_		0
Agent/CBR set dport_		0

Agent/TCPSink set sport_	0
Agent/TCPSink set dport_	0

Agent/TCP set sport_		0
Agent/TCP set dport_		0
Agent/TCP set packetSize_	1460

Queue/DropTail/PriQueue set Prefer_Routing_Protocols    1

# unity gain, omni-directional antennas
# set up the antennas to be centered in the node and 1.5 meters above it
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0

# Initialize the SharedMedia interface with parameters to make
# it work like the 914MHz Lucent WaveLAN DSSS radio interface
Phy/WirelessPhy set CPThresh_ 10.0
Phy/WirelessPhy set CSThresh_ 1.559e-11
Phy/WirelessPhy set RXThresh_ 3.652e-10
Phy/WirelessPhy set Rb_ 2*1e6
Phy/WirelessPhy set Pt_ 0.28183815
Phy/WirelessPhy set freq_ 914e+6 
Phy/WirelessPhy set L_ 1.0

# =====================================================================

TestSuite instproc init {} {
	global opt tracefd topo chan prop 
	global node_ god_ 
	$self instvar ns_ testName_
	set ns_         [new Simulator]
	if {[string compare $testName_ "gaf"] && \
			[string compare $testName_ "tora"]} {
		$ns_ set-address-format hierarchical
		AddrParams set domain_num_ 3
		lappend cluster_num 2 1 1
		AddrParams set cluster_num_ $cluster_num
		lappend eilastlevel 1 1 4 1
		AddrParams set nodes_num_ $eilastlevel
        } 

	set topo	[new Topography]
	set tracefd	[open $opt(tr) w]
	
	$ns_ trace-all $tracefd

	#set opt(rp) $testName_
	$topo load_flatgrid $opt(x) $opt(y)

	
	puts $tracefd "M 0.0 nn:$opt(nn) x:$opt(x) y:$opt(y) rp:$opt(rp)"
	puts $tracefd "M 0.0 sc:$opt(sc) cp:$opt(cp) seed:$opt(seed)"
	puts $tracefd "M 0.0 prop:$opt(prop) ant:$opt(ant)"
}

Test/gaf instproc init {} {
	global opt node_ god_ chan topo
	$self instvar ns_ testName_
	set testName_       gaf
	set opt(rp)         AODV
	set opt(cp)		"../mobility/scene/cbr-10-1-10-20" 
	set opt(sc)		"../mobility/scene/scen-1500x300-60-0-20-2" 
	set opt(nn)		60      
	set opt(stop)       800.0

	$self next

	#
	# Create God
	#
	set god_ [create-god $opt(nn)]
	$god_ load_grid $opt(x) $opt(y) $opt(grid) 

        $ns_ node-config -adhocRouting $opt(rp) \
                         -llType $opt(ll) \
                         -macType $opt(mac) \
                         -ifqType $opt(ifq) \
                         -ifqLen $opt(ifqlen) \
                         -antType $opt(ant) \
                         -propType $opt(prop) \
                         -phyType $opt(netif) \
                         -channelType $opt(chan) \
                         -topoInstance $topo \
                         -energyModel $opt(energymodel) \
                         -routerTrace OFF \
                         -macTrace OFF \
                         -rxPower 1.2 \
                         -txPower 1.6 \
                         -idlePower 1.15 \
                         -initialEnergy $opt(infiniteenergy) 
    
	for {set i 0} {$i < 10 } {incr i} {
                set node_($i) [$ns_ node]
                $node_($i) random-motion 0              ;# disable random motion
		$node_($i) attach-gafpartner
                $node_($i) unset-gafpartner             ;# 
        }                   

	$ns_ node-config -initialEnergy $opt(initialenergy)
 
                # The rest node is GAF node
                #
                for {set i 10} {$i < $opt(nn) } {incr i} {
 
                    set node_($i) [$ns_ node]
                    $node_($i) random-motion 0
 
                    #attach gaf agent to this node, attach at port 254
                    set gafagent_ [new Agent/GAF [$node_($i) id]]
                    $node_($i) attach $gafagent_ 254
                    $node_($i) attach-gafpartner
                    $gafagent_ adapt-mobility $opt(gaf4)
                    $ns_ at 0.0 "$gafagent_ start-gaf"
                }       


	puts "Loading connection pattern..."
	source $opt(cp)
	
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."

#
# Tell all the nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).000000001 "$node_($i) reset";
#    $ns_ at $opt(stop).000000001 "output_energy $i"
 
}   
        $ns_ at $opt(stop).00000001 "puts \"NS EXITING...\" ; $ns_ halt"
	
#	$ns_ at $opt(stop).00000001 "$self finish-gaf"
}

Test/gaf instproc run {} {
	$self instvar ns_
	puts "Starting Simulation..."
	$ns_ run
}

TestSuite instproc finish-gaf {} {
	$self instvar ns_
	global quiet opt

	$ns_ flush-trace
        
        set tracefd	[open $opt(tr) r]
        set tracefd2    [open $opt(tr).w w]

        while { [eof $tracefd] == 0 } {

	    set line [gets $tracefd]
	    set items [split $line " "]

	    set time [lindex $items 1]
	    
	    set times [split $time "."]
	    set time1 [lindex $times 0]
	    set time2 [lindex $times 1]
	    set newtime2 [string range $time2 0 2]
	    set time $time1.$newtime2
	    
	    set newline [lreplace $line 1 1 $time] 

	    puts $tracefd2 $newline

	}
	
	close $tracefd
	close $tracefd2

	exec mv $opt(tr).w $opt(tr)

	puts "finish.."
	exit 0
	

}


TestSuite instproc finish {} {
	$self instvar ns_
	global quiet

	$ns_ flush-trace
        #if { !$quiet } {
        #        puts "running nam..."
        #        exec nam temp.rands.nam &
        #}
	puts "finishing.."
	exit 0
}


TestSuite instproc log-movement {} {
	global ns
	$self instvar logtimer_ ns_

	set ns $ns_
	source ../mobility/timer.tcl
	Class LogTimer -superclass Timer
	LogTimer instproc timeout {} {
		global opt node_;
		for {set i 0} {$i < $opt(nn)} {incr i} {
			$node_($i) log-movement
		}
		$self sched 0.1
	}

	set logtimer_ [new LogTimer]
	$logtimer_ sched 0.1
}

TestSuite instproc create-tcp-traffic {id src dst start} {
    $self instvar ns_
    set tcp_($id) [new Agent/TCP]
    $tcp_($id) set class_ 2
    set sink_($id) [new Agent/TCPSink]
    $ns_ attach-agent $src $tcp_($id)
    $ns_ attach-agent $dst $sink_($id)
    $ns_ connect $tcp_($id) $sink_($id)
    set ftp_($id) [new Application/FTP]
    $ftp_($id) attach-agent $tcp_($id)
    $ns_ at $start "$ftp_($id) start"
    
}


TestSuite instproc create-udp-traffic {id src dst start} {
    $self instvar ns_
    set udp_($id) [new Agent/UDP]
    $ns_ attach-agent $src $udp_($id)
    set null_($id) [new Agent/Null]
    $ns_ attach-agent $dst $null_($id)
    set cbr_($id) [new Application/Traffic/CBR]
    $cbr_($id) set packetSize_ 512
    $cbr_($id) set interval_ 4.0
    $cbr_($id) set random_ 1
    $cbr_($id) set maxpkts_ 10000
    $cbr_($id) attach-agent $udp_($id)
    $ns_ connect $udp_($id) $null_($id)
    $ns_ at $start "$cbr_($id) start"

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
	set t [new Test/$test]
	
	
	$t run
}

global argv arg0
default_options
runtest $argv









