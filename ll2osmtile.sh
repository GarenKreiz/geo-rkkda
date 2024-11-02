#!/bin/sh

#
#	skel.sh:
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Lat/lon to Open Street Map tiles

SYNOPSIS
    `basename $PROGNAME` [options] lat lon zoom

DESCRIPTION
    Lat/lon to Open Street Map tiles (x, y, z).

OPTIONS
    -D lvl	Debug level

EXAMPLE
    Convert https://coord.info/GC83BCN :

	$ ll2osmtile 42.06866518410682 139.43984985351562 18
	232609 97245 18

	$ ll2osmtile N42.04.120 E139.26.391 18
	232609 97245 18
EOF

	exit 1
}

#include "geo-common"

#
#       Report an error and exit
#
error() {
	echo "`basename $PROGNAME`: $1" >&2
	exit 1
}

debug() {
	if [ $DEBUG -ge $1 ]; then
	    echo "`basename $PROGNAME`: $2" >&2
	fi
}

#
#       Process the options
#
DEBUG=0
while getopts "D:h?" opt
do
	case $opt in
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case "$#" in
0)      usage ;;
esac

#
#	encode lat lon zoom
#
encode() {
    awk -v LAT="$1" -v LON="$2" -v Z="$3" '
    BEGIN {
	PI=3.14159265358979323846
	xtile = (LON + 180.0) / 360 * 2.0^Z
	xtile += xtile < 0 ? -0.5 : 0.5

	tan_x = sin(LAT * PI / 180.0)/cos(LAT * PI / 180.0)
	ytile = (1 - log(tan_x + 1/cos(LAT * PI / 180))/PI)/2 * 2.0^Z
	ytile += ytile < 0 ? -0.5 : 0.5

	printf("%d %d %d\n", xtile, ytile, Z)
    }
    '
}

#
#	Main Program
#
process_latlon encode 1 $@
