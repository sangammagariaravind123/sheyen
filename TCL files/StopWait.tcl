# Create a new simulator instance
set ns [new Simulator]
$ns color 1 Blue

# Set NAM output file
set nf [open out.nam w]
$ns namtrace-all $nf

# Destructor
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam out.nam &
    exit 0
}

# Create two new nodes and create labels for them
set n0 [$ns node]
set n1 [$ns node]
$ns at 0.0 "$n0 label \"Sender\""
$ns at 0.0 "$n1 label \"Receiver\""

# Set up a new duplex link
$ns duplex-link $n0 $n1 1Mb 200ms DropTail
$ns duplex-link-op $n0 $n1 orient right

# Create a new TCP agent
set tcp [new Agent/TCP]

# Attach the agent to the first node
$ns attach-agent $n0 $tcp
$tcp set fid_ 1
$tcp set window_ 1
$tcp set maxcwnd_ 1

# Create a TCPSink and attach to the second node
set tcpsink [new Agent/TCPSink]
$ns attach-agent $n1 $tcpsink

# Connect TCP and TCPSink agents
$ns connect $tcp $tcpsink

# Create an FTP application and attach it to the TCP agent
set ftp [new Application/FTP]
$ftp attach-agent $tcp

# Schedule FTP and other events
$ns at 0.5 "$ftp start"
$ns at 3.0 "$ns detach-agent $n0 $tcp ; $ns detach-agent $n1 $tcpsink"
$ns at 1.0 "$ns trace-annotate \"send packet 1\""
$ns at 1.4 "$ns trace-annotate \"receive ack 1\""
$ns at 2.0 "$ns trace-annotate \"send packet 2\""
$ns at 2.5 "$ns trace-annotate \"receive ack 2\""
$ns at 3.2 "$ns trace-annotate \"send packet 3\""
$ns at 3.5 "$ns trace-annotate \"receive ack 3\""
$ns at 3.8 "$ns trace-annotate \"send packet 4\""
$ns at 4.0 "finish"
$ns run
