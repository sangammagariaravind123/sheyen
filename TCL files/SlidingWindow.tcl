set ns [new Simulator]

# Open files for NAM and trace output
set namf [open slidingwindow.nam w]
$ns namtrace-all $namf

set trf [open slidingwindow.tr w]
$ns trace-all $trf

# Define a finish procedure
proc finish {} {    
    global ns namf trf
    $ns flush-trace
    close $namf
    close $trf
    exec nam slidingwindow.nam &
    exit 0
}

# Create nodes
set n0 [$ns node]
set n1 [$ns node]

# Create duplex link between the nodes
$ns duplex-link $n0 $n1 0.2Mb 200ms DropTail
$ns duplex-link-op $n0 $n1 orient right
$ns queue-limit $n0 $n1 10

# Create and configure TCP agent
set tcp [new Agent/TCP]
set sink [new Agent/TCPSink]
$ns attach-agent $n0 $tcp
$ns attach-agent $n1 $sink
$ns connect $tcp $sink

# Attach FTP application to the TCP agent
set ftp [new Application/FTP]
$ftp attach-agent $tcp

# Set TCP parameters
$tcp set window_ 1
$tcp set maxcwnd_ 1

# Enable NAM trace for the TCP agent
$tcp set nam_tracevar_ true


# Schedule events
$ns at 0.1 "$ftp start"
$ns at 3.0 "$ns detach-agent $n0 $tcp"
$ns at 3.0 "$ns detach-agent $n1 $sink"
$ns at 3.5 "$ftp stop"
$ns at 5.0 "finish"

# Run the simulation
$ns run
