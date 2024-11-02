#!/bin/sh

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Lat/lon to Google's plus codes

SYNOPSIS
    `basename $PROGNAME` [options] [lat lon]

DESCRIPTION
    Lat/lon to Google's plus codes.

    You can use command line argument(s) or stdin.

OPTIONS
    -D lvl	Debug level

EXAMPLE
    Convert lat/lon:

	$ ll2pluscodes 45 -93.5
	86Q82G22+22

SEE ALSO
    https://stedolan.github.io/jq/

    https://github.com/google/open-location-code/wiki/Plus-codes-API
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
#unset OPTIND
while getopts "D:h?" opt
do
	case $opt in
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

#
#	Main Program
#
doit (){
    URL="https://plus.codes/api?address=$1,$2"
    global_code=` curl -s "$URL" | jq ".plus_code.global_code" `
    global_code=` echo $global_code | tr -d '"' `
    echo $global_code
}

if ! which jq >/dev/null 2>&1; then
    error "You need to install 'jq' (dnf install jq)"
fi

case $# in
0)
    while read lat lon; do
	LAT=`latlon $lat`
	LON=`latlon $lon`
	doit $LAT $LON
    done
    ;;
2)
    LAT=`latlon $1`
    LON=`latlon $2`
    doit $LAT $LON
    ;;
4)
    LAT=`latlon $1.$2`
    LON=`latlon $3.$4`
    doit $LAT $LON
    ;;
6)
    # Cut and paste from geocaching.com cache page
    # N 44° 58.630 W 093° 09.310
    LAT=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT=`latlon $LAT`
    LON=`echo "$4$5.$6" | tr -d '\260\302' `
    LON=`latlon $LON`
    doit $LAT $LON
    ;;
*)
    usage
    ;;
esac
