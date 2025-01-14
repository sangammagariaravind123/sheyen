dnl autoconf rules for NS Emulator (NSE)
dnl $Id: configure.in.nse,v 1.5 2001/09/21 02:48:31 alefiyah Exp $

dnl
dnl Look for ethernet.h
dnl

dnl Now look for supporting structures
dnl

AC_MSG_CHECKING([for struct ether_header])
AC_TRY_COMPILE([
#include <stdio.h>
#include <net/ethernet.h>
], [
int main()
{
	struct ether_header etherHdr;

	return 1;
}
], [
AC_DEFINE(HAVE_ETHER_HEADER_STRUCT)
AC_MSG_RESULT(found)
], [
AC_MSG_RESULT(not found)
])
 

dnl 
dnl Look for ether_addr
dnl
AC_MSG_CHECKING([for struct ether_addr])
AC_TRY_COMPILE([
#include <stdio.h>
#include <net/ethernet.h>
], [
int main()
{
	struct ether_addr etherAddr;

	return 0;
}
], [
AC_DEFINE(HAVE_ETHER_ADDRESS_STRUCT)
AC_MSG_RESULT(found)
], [
AC_MSG_RESULT(not found)
])

cross_compiling=no
dnl
dnl Look for addr2ascii function
dnl
AC_CHECK_FUNCS(addr2ascii)

dnl
dnl look for SIOCGIFHWADDR
dnl
AC_TRY_RUN(
#include <stdio.h>
#include <sys/ioctl.h>
int main()
{
	int i = SIOCGIFHWADDR;
	return 0;
}
, AC_DEFINE(HAVE_SIOCGIFHWADDR), , echo 1
)

tcphdr=no
pcap=no

dnl
dnl Checking for Linux tcphdr
dnl
AC_MSG_CHECKING([for Linux compliant tcphdr])
AC_TRY_COMPILE([
#include <stdio.h>
#include <netinet/tcp.h>
], [
int main()
{
	struct tcphdr *tcp;
	tcp->source= 1;

	return 0;
}
], [
V_DEFINE="$V_DEFINE -DLINUX_TCP_HEADER"
AC_MSG_RESULT(found)
tcphdr=yes
], [
AC_MSG_RESULT(not found)
])

dnl
dnl Checking for BSD tcphdr
dnl
AC_MSG_CHECKING([for BSD compliant tcphdr])
AC_TRY_COMPILE([
#include <stdio.h>
#include <netinet/tcp.h>
], [
int main()
{
	struct tcphdr *tcp;
	tcp->th_sport= 1;

	return 0;
}
], [
AC_MSG_RESULT(found)
tcphdr=yes
], [
AC_MSG_RESULT(not found)
])

dnl
dnl  Check for pcap library 
dnl
AC_CHECK_LIB(pcap,main,[V_LIB="$V_LIB -lpcap" pcap=yes])
V_INCLUDES="$V_INCLUDES -I/usr/include/pcap"


dnl
dnl   Testing to make nse
dnl
AC_MSG_CHECKING([to make nse])
if test $tcphdr = yes && test $pcap = yes; then
		build_nse="nse"
		AC_MSG_RESULT(yes)
		AC_SUBST(build_nse)
else
	AC_MSG_RESULT(no)
fi
