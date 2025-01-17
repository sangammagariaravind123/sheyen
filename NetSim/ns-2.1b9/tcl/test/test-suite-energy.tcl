# -*-	Mode:tcl; tcl-indent-level:8; tab-width:8; indent-tabs-mode:t -*-
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
# $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/test/test-suite-energy.tcl,v 1.8 2002/03/08 21:55:41 sfloyd Exp $

# To run all tests: test-all-energy
# to run individual test:
# ns test-suite-energy.tcl dsdv
# ns test-suite-energy.tcl dsr
# ns test-suite-energy.tcl aodv
#
# To view a list of available test to run with this script:
# ns test-suite-energy.tcl


# ======================================================================
# Define options
# ======================================================================
global opt
set opt(chan)		Channel/WirelessChannel
set opt(prop)		Propagation/TwoRayGround
set opt(netif)		Phy/WirelessPhy
set opt(mac)		Mac/802_11
set opt(ifq)		Queue/DropTail/PriQueue
set opt(ll)		LL
set opt(ant)            Antenna/OmniAntenna

set opt(x)		670	;# X dimension of the topography
set opt(y)		670		;# Y dimension of the topography
set opt(cp)		"cbr.tcl"
set opt(sc)		"mobility.tcl"

set opt(ifqlen)		50		;# max packet in ifq
set opt(nn)		5		;# number of nodes
set opt(seed)		0.0
set opt(stop)		500.0		;# simulation time
set opt(tr)		estudy.tr	;# trace file
set opt(nam)		temp.rands
set opt(lm)             "off"           ;# log movement
set opt(energymodel)    EnergyModel     ;
set opt(initialenergy)  0.455               ;# Initial energy in Joules

# ======================================================================
# needs to be fixed later
set AgentTrace			ON
set RouterTrace			ON
set MacTrace			OFF

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
Phy/WirelessPhy set Pt_ 0.2818
Phy/WirelessPhy set freq_ 914e+6 
Phy/WirelessPhy set L_ 1.0

# ======================================================================

proc usage {}  {
        global argv0
	puts stderr "usage: ns $argv0 <tests> "
	puts "Valid <tests> : dsdv dsr aodv "
        exit 1
}


proc getopt {argc argv} {
	global opt
	lappend optlist cp nn seed sc stop tr x y

	for {set i 0} {$i < $argc} {incr i} {
		set arg [lindex $argv $i]
		if {[string range $arg 0 0] != "-"} continue

		set name [string range $arg 1 end]
		set opt($name) [lindex $argv [expr $i+1]]
	}
}

Class TestSuite

Class Test/dsdv -superclass TestSuite
Class Test/dsr -superclass TestSuite
Class Test/aodv -superclass TestSuite

TestSuite instproc init {} {
global opt
$self instvar ns_ topo  

set ns_		[new Simulator]
set topo	[new Topography]
set god_         [new God]

set tracefd	[open $opt(tr) w]
set namtrace    [open $opt(nam) w]

$topo load_flatgrid $opt(x) $opt(y)

$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)

create-god $opt(nn)

}

TestSuite instproc finish {} {
        $self instvar ns_
	global quiet
        $ns_ flush-trace
        if { !$quiet } {
            puts "running nam..."
            exec nam temp.rands &
        }
        exit 0
}



Test/dsdv instproc init {} {
   global opt
   $self instvar ns_ topo
   set opt(rp)             DSDV
   $self next
}
Test/dsdv instproc run {} {
   global opt
   $self instvar ns_ topo

        $ns_ node-config -adhocRouting $opt(rp) \
			 -llType $opt(ll) \
			 -macType $opt(mac) \
			 -ifqType $opt(ifq) \
			 -ifqLen $opt(ifqlen) \
			 -antType $opt(ant) \
			 -propType $opt(prop) \
			 -phyType $opt(netif) \
			 -channel [new $opt(chan)] \
			 -topoInstance $topo \
			 -energyModel $opt(energymodel) \
			 -macTrace ON \
			 -rxPower 0.3 \
			 -txPower 0.6 \
			 -initialEnergy $opt(initialenergy)
			 
	for {set i 0} {$i < $opt(nn) } {incr i} {
		set node_($i) [$ns_ node]	
		$node_($i) random-motion 0		;# disable random motion
	}

#
# Source the Connection and Movement scripts
#
if { $opt(cp) == "" } {
	puts "*** NOTE: no connection pattern specified."
        set opt(cp) "none"
} else {
	puts "Loading connection pattern..."
	source $opt(cp)
}


#
# Tell all the nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).000000001 "$node_($i) reset";
}
$ns_ at $opt(stop).00000001 "puts \"NS EXITING...\" ; $ns_ halt"


if { $opt(sc) == "" } {
	puts "*** NOTE: no scenario file specified."
        set opt(sc) "none"
} else {
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."
}

# Define node initial position in nam

for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your scenario
    # The function must be called after mobility model is defined

    $ns_ initial_node_pos $node_($i) 20
}

$ns_ run
}



Test/dsr instproc init {} {
   global opt
   $self instvar ns_ topo
   set opt(rp)             DSR
   $self next
}
Test/dsr instproc run {} {
   global opt
   $self instvar ns_ topo
        $ns_ node-config -adhocRouting $opt(rp) \
			 -llType $opt(ll) \
			 -macType $opt(mac) \
			 -ifqType $opt(ifq) \
			 -ifqLen $opt(ifqlen) \
			 -antType $opt(ant) \
			 -propType $opt(prop) \
			 -phyType $opt(netif) \
			 -channel [new $opt(chan)] \
			 -topoInstance $topo \
			 -energyModel $opt(energymodel) \
			 -macTrace ON \
			 -rxPower 0.3 \
			 -txPower 0.6 \
			 -initialEnergy $opt(initialenergy)
			 
	for {set i 0} {$i < $opt(nn) } {incr i} {
		set node_($i) [$ns_ node]	
		$node_($i) random-motion 0		;# disable random motion
	}

#
# Source the Connection and Movement scripts
#
if { $opt(cp) == "" } {
	puts "*** NOTE: no connection pattern specified."
        set opt(cp) "none"
} else {
	puts "Loading connection pattern..."
	source $opt(cp)
}


#
# Tell all the nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).000000001 "$node_($i) reset";
}
$ns_ at $opt(stop).00000001 "puts \"NS EXITING...\" ; $ns_ halt"


if { $opt(sc) == "" } {
	puts "*** NOTE: no scenario file specified."
        set opt(sc) "none"
} else {
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."
}

# Define node initial position in nam

for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your scenario
    # The function must be called after mobility model is defined

    $ns_ initial_node_pos $node_($i) 20
}

$ns_ run
}



Test/aodv instproc init {} {
   global opt
   $self instvar ns_ topo
   set opt(rp)             AODV
   $self next
}
Test/aodv instproc run {} {
   global opt
   $self instvar ns_ topo
        $ns_ node-config -adhocRouting $opt(rp) \
			 -llType $opt(ll) \
			 -macType $opt(mac) \
			 -ifqType $opt(ifq) \
			 -ifqLen $opt(ifqlen) \
			 -antType $opt(ant) \
			 -propType $opt(prop) \
			 -phyType $opt(netif) \
			 -channel [new $opt(chan)] \
			 -topoInstance $topo \
			 -energyModel $opt(energymodel) \
			 -macTrace ON \
			 -rxPower 0.3 \
			 -txPower 0.6 \
			 -initialEnergy $opt(initialenergy)
			 
	for {set i 0} {$i < $opt(nn) } {incr i} {
		set node_($i) [$ns_ node]	
		$node_($i) random-motion 0		;# disable random motion
	}

#
# Source the Connection and Movement scripts
#
if { $opt(cp) == "" } {
	puts "*** NOTE: no connection pattern specified."
        set opt(cp) "none"
} else {
	puts "Loading connection pattern..."
	source $opt(cp)
}


#
# Tell all the nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
    $ns_ at $opt(stop).000000001 "$node_($i) reset";
}
$ns_ at $opt(stop).00000001 "puts \"NS EXITING...\" ; $ns_ halt"


if { $opt(sc) == "" } {
	puts "*** NOTE: no scenario file specified."
        set opt(sc) "none"
} else {
	puts "Loading scenario file..."
	source $opt(sc)
	puts "Load complete..."
}

# Define node initial position in nam

for {set i 0} {$i < $opt(nn)} {incr i} {

    # 20 defines the node size in nam, must adjust it according to your scenario
    # The function must be called after mobility model is defined

    $ns_ initial_node_pos $node_($i) 20
}

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
	        dsdv -
	        dsr -
		aodv {
                     set t [new Test/$test]
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



