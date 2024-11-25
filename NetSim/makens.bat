call SetupNS.bat
echo off

for %%d in (tcl8.3.2\win tk8.3.2\win otcl-1.0a8 tclcl-1.0b12 ns-2.1b9) do (
    pushd %%d
    nmake /f makefile.vc
    if %%d == tcl8.3.2\win nmake /f makefile.vc install
    if %%d == tk8.3.2\win nmake /f makefile.vc install
    popd
)
