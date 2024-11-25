use strict;

sub Usage {
    print "fixbuild.pl -vs <Visual Studio Path> -ns <NS Path>\n";
    exit;
}

sub GetShortPath {
    my($path) = @_;
    # Currently just ensures that there is no blank in the path!!
    if ($path =~ /\s+/) {
	print "Spaces in $path not supported\n";
	exit;
    }
    
    return $path;
}

sub FixFile {
    my($file, $path, @params) = @_;
    print "FixFile: $file $path @params\n";
    open(FILE, "$file") || die "Cannot open $file: $! \n";
    open(TMPFILE, ">$file.tmp") || die "Cannot open $file.tmp: $! \n";
    while(<FILE>)  {
	my $line = $_;
	for (my($i) = 0; $i < scalar(@params); $i++) {
	    if ($line =~ /$params[$i]\s*=/ && $line !~ /^\s*\#/) {
		print "Found Line $line\n";
		$line =~ s/($params[$i])(\s*)=(\s*).*/$1$2=$3$path/g;
		print "New   Line $line\n";
	    }
	}
	printf(TMPFILE "%s", $line);
    } 
    close(FILE);
    close(TMPFILE);
    system("copy $file ${file}~");
    system("move $file.tmp $file");
}

sub FixPath {
    my($file, $vsPath) = @_;
    open(FILE, "$file") || die "Cannot open $file: $! \n";
    open(TMPFILE, ">$file.tmp") || die "Cannot open $file.tmp: $! \n";
    while(<FILE>)  {
	my $line = $_;
	if (/vcvars32.bat/) {
	    $line = "$vsPath\\bin\\vcvars32.bat";
	}
	printf(TMPFILE "%s", $line);
    }
    close(FILE);
    close(TMPFILE);
    system("move $file ${file}~");
    system("move $file.tmp $file");
}


my($nsPath,$vsPath);
if (scalar(@ARGV) <= 0) {
    Usage();
}

while (@ARGV) {
    if ($ARGV[0] eq "-vs") {
	$vsPath= $ARGV[1];
    } elsif ($ARGV[0] eq "-ns") {
	$nsPath= $ARGV[1];
    } else {
	Usage();
    }
    shift(@ARGV);
    shift(@ARGV);
}

if (!(-e $vsPath) || !(-e $nsPath)) {
    print "$vsPath or $nsPath does not exist\n";
    Usage();
}

$vsPath .= "\\VC7";

$vsPath = GetShortPath($vsPath);
$nsPath = GetShortPath($nsPath);

chdir($nsPath);
FixFile("$nsPath\\SetupNs.Bat", $nsPath, "MyNetSim");
FixPath("$nsPath\\SetupNs.Bat", $vsPath);
FixFile("$nsPath\\tcl8.3.2\\win\\Makefile.vc", $vsPath, "TOOLS32", "TOOLS32_rc");
FixFile("$nsPath\\tk8.3.2\\win\\Makefile.vc", $vsPath, "TOOLS32", "TOOLS32_rc");
FixFile("$nsPath\\otcl-1.0a8\\Makefile.vc", $vsPath, "TOOLS32", "TOOLS32_rc");
FixFile("$nsPath\\tclcl-1.0b12\\conf\\Makefile.win", "$vsPath", "MSVCDIR");
FixFile("$nsPath\\tclcl-1.0b12\\conf\\Makefile.win", $nsPath, "LOCAL_SRC");
FixFile("$nsPath\\ns-2.1b9\\conf\\Makefile.win", "$vsPath", "MSVCDIR");
FixFile("$nsPath\\ns-2.1b9\\conf\\Makefile.win", $nsPath, "LOCAL_SRC");
