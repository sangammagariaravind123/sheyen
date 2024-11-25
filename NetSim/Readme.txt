Command for removing files: "rm -f". Make sure that you have "rm.exe"
available on your path (and it takes the -f option for forced remove)


Fixing Build File
=================

Run the file called fixbuild.pl giving it the NS and Visual Studio.Net
paths (This file automates the instructions given below). Note that the paths
specified cannot contain spaces. So you have to give the DOS pathname for
Visual Studio (use dir /x to find that out in Program files)
e.g.,
    fixbuild.pl -vs c:\Progra~1\Micros~1.Net -ns c:\Root\Work\MCoM\NetSim

Compiling NS
============

Change your directory to your NS directory. Run makens.bat.


Validation
==========

PERL: Make sure that this environment variable is set to your perl executable
Awk:  Use the awk from Brian Kernighan's web page:
      http://cm.bell-labs.com/cm/cs/who/bwk/awk95.exe
     

				Manual Instructions
				===================



Note: If you have installed VS.Net in the default place, you will not have to
modify most of the variables such as TOOLS32.

SetupNS.Bat
===========

* Run it before proceeding further. Also run it before running any NS simulation
* Set MyNetSim to be your directory where ns, tclcl,tcl, etc are kept
* Change the path to include: installed Tcl bin dir (Probably
  c:\Progra~1\Tcl\bin), Tcl lib dir, NetSim ns dir, NetSim otcl dir, NetSeim
  tclcl dir, NetSim tkdir (see sample file). 
  NOTE: If you chose the default directory structure for the NS, TCL, TK, etc
  directories, you just have to modify MyNetSim
* Make sure that it runs the correct vcvars32.bat file, i.e., the VS.Net vcvars32.bat


TCL
===

* Edit <TCLDIR>/win/Makefile.vc: 
  - Set TOOLS32, TOOLS32_rc to the VS.Net directory
* Compile: nmake /f makefile.vc in win directory
* Install: nmake /f makefile.vc install
  TCL will be installed in C:\Program Files\Tcl

TK
===
* Edit <TKDIR>/win/Makefile.vc:
  - Set TOOLS32, TOOLS32_rc to the VS.Net directory
* Compile: nmake /f makefile.vc in win directory
* Install: nmake /f makefile.vc install
  TK will be installed in C:\Program Files\Tcl

OTCL
=====
* Edit Makefile.vc:
  - Set TOOLS32, TOOLS32_rc to the VS.Net directory
* Compile: nmake /f makefile.vc

TCLCL
=====
* Edit conf/Makefile.win
  - Set MSVCDIR to the VS.Net directory
  - Set LOCAL_SRC to be your NetSim source dir, e.g., C:\Root\Work\Netsim

* Compile: nmake /f makefile.vc

NS
==

* Edit conf/makefile.win
  - Set MSVCDIR to the VS.Net directory
  - Set LOCAL_SRC to be your NetSim source dir, e.g., C:\Root\Work\Netsim
* Compile
  nmake /f makefile.vc in the main directory


