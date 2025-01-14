# Copyright (C) 1999 by USC/ISI
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
# Re-tooled version of Polly's web traffic models (tcl/ex/web-traffic.tcl, 
# tcl/ex/large-scale-traffic.tcl) in order to save memory.
#
# The main strategy is to move everything into C++, only leave an OTcl 
# configuration interface. Be very careful as what is configuration and 
# what is functionality.
#
# $Header: /nfs/jade/vint/CVSROOT/ns-2/tcl/webcache/empweb.tcl,v 1.9 2002/02/13 22:58:55 kclan Exp $

PagePool/EmpWebTraf set debug_ false
PagePool/EmpWebTraf set TCPTYPE_ Reno
PagePool/EmpWebTraf set TCPSINKTYPE_ TCPSink   ;#required for SACK1 Sinks.
PagePool/EmpWebTraf set REQ_TRACE_ 0
PagePool/EmpWebTraf set RESP_TRACE_ 0

#0 for default, fid=id
#1 for increasing along with new agent allocation (as in red-pd). 
#   useful when used with flow monitors (as they tend to run out of space in hash tables)
#   (see red-pd scripts for usage of this)
#2 for assigning the same fid to all connections.
#    useful when want to differentiate between various web traffic generators using flow monitors.
#   (see pushback scripts for usage of this).
PagePool/EmpWebTraf set FID_ASSIGNING_MODE_ 0 
PagePool/EmpWebTraf set VERBOSE_ 0
PagePool/EmpWebTraf set maxFid_ 0


PagePool/EmpWebTraf instproc set-fid { id ctcp stcp} {
	$stcp set fid_ $id
	$ctcp set fid_ $id
}

PagePool/EmpWebTraf instproc launch-req { id pid clnt svr ctcp csnk stcp ssnk size reqSize pobj persist} {
	set ns [Simulator instance]

	$ns attach-agent $svr $stcp
	$ns attach-agent $clnt $ssnk
	$ns connect $stcp $ssnk
	
	$ns attach-agent $clnt $ctcp
	$ns attach-agent $svr $csnk
	$ns connect $ctcp $csnk

#	if {[PagePool/EmpWebTraf set FID_ASSIGNING_MODE_] == 0} {
#		$stcp set fid_ $id
#		$ctcp set fid_ $id
#	}

	$ctcp proc done {} "$self done-req $id $pid $clnt $svr $ctcp $csnk $stcp $size $pobj $persist"
	$stcp proc done {} "$self done-resp $id $pid $clnt $svr $stcp $ssnk $size [$ns now] [$stcp set fid_] $pobj $persist"
	
	# modified to trace web traffic flows (send request: client==>server).
        	puts "req + obj:$id clnt:[$clnt id] svr:[$svr id] $size [$ns now]"
	if {[PagePool/EmpWebTraf set REQ_TRACE_]} {
        	puts "req + obj:$id clnt:[$clnt id] svr:[$svr id] $size [$ns now]"
	}

	# Send request packets based on empirical distribution
	$ctcp advanceby $reqSize
}

PagePool/EmpWebTraf instproc done-req { id pid clnt svr ctcp csnk stcp size pobj persist} {
	set ns [Simulator instance]

	# modified to trace web traffic flows (recv request: client==>server).
        	puts "req - obj:$id clnt:[$clnt id] srv:[$svr id] [$ns now]"
	if {[PagePool/EmpWebTraf set REQ_TRACE_]} {
        	puts "req - obj:$id clnt:[$clnt id] srv:[$svr id] [$ns now]"
	}	
	# Recycle client-side TCP agents
	$ns detach-agent $clnt $ctcp
	$ns detach-agent $svr $csnk

	#don't recycle and reset if it's persistent connection
	if {$persist != 1} {
		$ctcp reset
		$csnk reset
		$self recycle $ctcp $csnk
	}

	# modified to trace web traffic flows (send responese: server->client).
		puts "resp + obj:$id srv:[$svr id] clnt:[$clnt id] $size [$ns now]"
	if {[PagePool/EmpWebTraf set RESP_TRACE_]} {
		puts "resp + obj:$id srv:[$svr id] clnt:[$clnt id] $size [$ns now]"
	}

	# Advance $size packets
	$stcp advanceby $size
}

PagePool/EmpWebTraf instproc done-resp { id pid clnt svr stcp ssnk size {startTime 0} {fid 0} pobj persist} {
	set ns [Simulator instance]

	# modified to trace web traffic flows (recv responese: server->client).
	   	puts "resp - $id $pid $size [$svr id] [$clnt id] [$ns now]"
	if {[PagePool/EmpWebTraf set RESP_TRACE_]} {
	   	puts "resp - $id $pid $size [$svr id] [$clnt id] [$ns now]"
       	}

		puts "done-resp - obj:$id srv:[$svr id] clnt:[$clnt id] $size $startTime [$ns now] $fid"
	if {[PagePool/EmpWebTraf set VERBOSE_] == 1} {
		puts "done-resp - obj:$id srv:[$svr id] clnt:[$clnt id] $size $startTime [$ns now] $fid"
	}

	# Recycle server-side TCP agents
	$ns detach-agent $clnt $ssnk
	$ns detach-agent $svr $stcp

	#don't recycle if it's persistent connection
	if {$persist != 1} { 
		$stcp reset
		$ssnk reset
		$self recycle $stcp $ssnk
	}
	$self doneObj $pobj
}



# XXX Should allow customizable TCP types. Can be easily done via a 
# class variable
PagePool/EmpWebTraf instproc alloc-tcp { size } {


	set tcp [new Agent/TCP/[PagePool/EmpWebTraf set TCPTYPE_]]

        $tcp set window_ $size

	set fidMode [PagePool/EmpWebTraf set FID_ASSIGNING_MODE_]
	if {$fidMode == 1} {
		$self instvar maxFid_

		if ![info exists maxFid_] {
			$self set maxFid_ 0
		}

		$tcp set fid_ $maxFid_
		incr maxFid_
	} elseif  {$fidMode == 2} {
		$self instvar sameFid_
		$tcp set fid_ $sameFid_
	}
    
	return $tcp
}

PagePool/EmpWebTraf instproc alloc-tcp-sink {} {
	return [new Agent/[PagePool/EmpWebTraf set TCPSINKTYPE_]]
}

