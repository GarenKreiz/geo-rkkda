#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Convert lat/lon from one format to another

SYNOPSIS
	`basename $PROGNAME` [options] latitude longitude

	`basename $PROGNAME` [options]

DESCRIPTION
	Convert lat/lon from one format to another.
	Lat/Lon may be in DegDec, MinDec, or DMS formats.

	Acceptable formats for lat/lon are:

	    -93.49130	    DegDec (decimal degrees)
	    W93.49130	    DegDec (decimal degrees)

	    "-93 29.478"    MinDec (decimal minutes)
	    "W93 29.478"    MinDec (decimal minutes)
	    -93.29.478	    MinDec (decimal minutes)
	    W93.29.478	    MinDec (decimal minutes)
	
	    "-93 45 30"	    DMS (degrees, minutes, seconds)

	The second form reads from stdin.

OPTIONS
	-a	Antipod (opposite side)
	-d	Output DegDec only
	-m	Output MinDec only
	-l	Lat only
	-L	Long only
	-M	Also do a geo-map of the coordinates

EXAMPLE
	Convert DegDec:

	    $ geo-coords n45.12345 w93.12345
	      45.12345   -93.12345
	    N45.12345 W93.12345
	    N45 7' 24.420000" W93 7' 24.420000"
	    N45.07.407 W93.07.407

	Convert to antipod:

	    $ geo-coords -a s38.32.329 e58.13.715
	      38.538816   121.771417
	    N38.538816 E121.771417
	    N38 32' 19.737600" E121 46' 17.101200"
	    N38.32.329 E121.46.285

	Convert from stdin:

	    $ echo "n45 w93.5" | geo-coords -a -m
	    S45.00.000 E86.30.000

SEE ALSO
	ll2maidenhead, ll2osg, ll2rd, ll2usng, ll2utm,
	maidenhead2ll, rd2ll, usng2ll, utm2ll

EOF

	exit 1
}

#include "geo-common"

#
#       Set default options, can be overriden on command line or in rc file
#
DEBUG=0
DEGMIN=0
DEGDEC=0
DOLAT=0
DOLON=0
ANTI=0
MAP=0
read_rc_file

#
#       Process the options
#
while getopts "alLdmMDh?-" opt
do
	case $opt in
	a)	ANTI="1";;
	d)	DEGDEC="1";;
	m)	DEGMIN="1";;
	M)	MAP="1";;
	l)	DOLAT="1";;
	L)	DOLON="1";;
	D)	DEBUG="$OPTARG";;
	h|\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
case "$#" in
6)
	# Cut and paste from geocaching.com cache page
	# N 44° 58.630 W 093° 09.310
	LAT=`echo "$1$2.$3" | tr -d '\260\302' `
	LAT=`latlon $LAT`
	LON=`echo "$4$5.$6" | tr -d '\260\302' `
	LON=`latlon $LON`
	;;
4)
	LAT=`latlon $1.$2`
	LON=`latlon $3.$4`
	;;
2)
	LAT=`latlon $1`
	LON=`latlon $2`
	;;
0)
	if [ -t 0 ]; then
	    echo "Type the geo-coords command line(s): "
	fi
	while read a; do
	    opts=
	    if [ $ANTI = 1 ]; then opts="$opts -a"; fi
	    if [ $DEGDEC = 1 ]; then opts="$opts -d"; fi
	    if [ $DEGMIN = 1 ]; then opts="$opts -m"; fi
	    if [ $DOLAT = 1 ]; then opts="$opts -l"; fi
	    if [ $DOLON = 1 ]; then opts="$opts -L"; fi
	    if [ $MAP = 1 ]; then opts="$opts -M"; fi
	    geo-coords $opts $a
	done
	exit
	;;
*)
	usage
	;;
esac

if [ $ANTI = 1 ]; then
    LAT=`echo $LAT | awk '{ printf "%f\n", 0.0 - $1 }' `
    LON=`echo $LON | awk '{ printf "%f\n", $1>=0 ? -(180.0-$1) : 180.0+$1 }' `
fi

if [ $DEGMIN = 0 ]; then
    if [ $DOLAT = 1 -a $DOLON = 1 ]; then
	echo "$LAT $LON"
	exit
    elif [ $DOLAT = 1 ]; then
	echo "$LAT"
	exit
    elif [ $DOLON = 1 ]; then
	echo "$LON"
	exit
    fi
    echo "$LAT $LON"
    if [ $DEGDEC = 1 ]; then
	exit
    fi
fi

#
#       Convert DegDec to DegDec with NS/EW
#
degdec2degdec() {
    if [ "$2" = "" ]; then
	error "No sym given for degdec2degdec"
    fi
    awk -v v=$1 -v sym=$2 \
    '
    function abs(x)     { return (x>=0) ? x : -x }
    BEGIN {
	printf "%s%09.6f\n", \
	    (v >= 0.0) ? substr(sym, 1, 1) : substr(sym, 2, 1), \
	    abs(v)
    }'
}

#
#       Convert DegDec to dms with optional NS/EW
#
degdec2dms() {
    awk -v v=$1 -v sym=$2 \
	'
	function abs(x)     { return (x>=0) ? x : -x }
        BEGIN {
	    d=int(v)
	    f=(v-d)*60
	    if(f<0)f=-f
	    m=int(f)
	    s=(f-m)*60
	    if (sym == "")
		printf "%d %d'\'' %f\"\n", d, m, s
	    else
		printf "%s%02d %d'\'' %f\"\n", \
		    (v >= 0.0) ? substr(sym, 1, 1) : substr(sym, 2, 1), \
		    abs(d), m, s
	}'
}

if [ $DEGMIN = 0 ]; then
    echo "$(degdec2degdec $LAT NS) $(degdec2degdec $LON EW)"
    echo "$(degdec2dms $LAT NS) $(degdec2dms $LON EW)"
else
    if [ $DOLAT = 1 -a $DOLON = 1 ]; then
	echo "$(degdec2mindec $LAT NS)" "$(degdec2mindec $LON EW)"
	exit
    elif [ $DOLAT = 1 ]; then
	echo "$(degdec2mindec $LAT NS)"
	exit
    elif [ $DOLON = 1 ]; then
	echo "$(degdec2mindec $LON EW)"
	exit
    fi
fi
echo "$(degdec2mindec $LAT NS) $(degdec2mindec $LON EW)"

if [ $MAP = 1 ]; then
    geo-map $(degdec2mindec $LAT NS) $(degdec2mindec $LON EW)
fi
