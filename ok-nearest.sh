#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: ok-nearest.sh,v 1.18 2020/12/30 14:50:24 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Fetch a list of nearest geocaches from opencaching.us

SYNOPSIS
	`basename $PROGNAME` [options]

	`basename $PROGNAME` [options] lat lon

DESCRIPTION
	Fetch a list of nearest geocaches from opencaching.us or another
	opencaching site based on OKBASE setting.

	Requires:
	    curl	http://curl.haxx.se/

EOF
	ok_usage
	cat << EOF

EXAMPLES
	Nearest to n45 w93.5:

	    ok-nearest -c 45 w93.5
	    OU04AA 44.91493 -93.28522 Geocache-unfound-multi
	    OU0976 44.84817 -93.30575 Geocache-unfound-regular
	    OU0B7B 45.00970 -93.19838 Geocache-unfound-regular
	    OU0A2F 44.81170 -93.30227 Geocache-unfound-regular
	    OU09BA 44.99575 -93.09005 Geocache-unfound-regular
	    OU09B1 45.00555 -93.06733 Geocache-unfound-regular
	    OU09AE 45.01950 -93.05673 Geocache-unfound-regular
	    OU09A5 44.99997 -93.05240 Geocache-unfound-regular
	    OU09A8 44.99805 -93.05145 Geocache-unfound-regular
	    OU09B7 45.03328 -93.05215 Geocache-unfound-regular
	    OU0972 44.90817 -93.06050 Geocache-unfound-regular
	    OU09B4 45.00167 -93.04078 Geocache-unfound-regular
	    OU09B5 45.00917 -93.03440 Geocache-unfound-regular
	    OU09B9 44.99583 -93.03332 Geocache-unfound-regular
	    OU09AB 45.02360 -93.03315 Geocache-unfound-regular
	    OU09A6 45.01585 -93.03047 Geocache-unfound-regular
	    OU09A9 44.99585 -93.01712 Geocache-unfound-regular
	    OU09A0 45.03540 -93.00947 Geocache-unfound-regular
	    OU09AC 44.99680 -93.00325 Geocache-unfound-regular
	    OU09B2 45.03113 -93.00007 Geocache-unfound-regular

	Add nearest 50 caches to a GpsDrive SQL database

	    ok-nearest -n50 -f -s -S

	Purge the existing SQL database of all geocaches, and fetch
	200 fresh ones...

	    ok-nearest -S -P -s -n200

	Nearest in Czechia:

	    ok-nearest -E OKBASE=https://www.opencaching.cz n48 e9

	Nearest in Germany:

	    ok-nearest -E OKBASE=https://opencaching.de n50 e7

	Nearest in Italy:

	    ok-nearest -E OKBASE=https://www.opencaching.it n48 e10

	Nearest in The Nederlands:

	    ok-nearest -E OKBASE=https://www.opencaching.nl n51.37.944 e5

	Nearest in Poland:

	    ok-nearest -E OKBASE=https://opencaching.pl n51.37.944 e5

	Nearest in Romania:

	    ok-nearest -E OKBASE=https://www.opencaching.ro n44 e24.40.000

	Nearest in UK:

	    ok-nearest -E OKBASE=https://opencache.uk n53.5 w1.5

SEE ALSO
	geo-newest, geo-nearest, geo-found, geo-placed, geo-code, geo-map,
	geo-waypoint, ok-newest,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-ok"
#include "geo-common-gpsdrive"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$UPDATEHOME/ok-nearest
UPDATE_FILE=ok-nearest.new

read_rc_file

#
#       Process the options
#

ok_getopts "$@"
shift $?

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
2)
        LAT=`latlon $1`
        LON=`latlon $2`
        ;;
0)
        ;;
*)
        usage
        ;;
esac

LAT=`latlon $LAT`
LATNS=`degdec2mindec $LAT NS | cut -c 1 `
LATH=`degdec2mindec $LAT NS | sed -e "s/.//" -e "s/\..*//" `
LATMIN=`degdec2mindec $LAT | sed "s/[^.]*\.//" `
LON=`latlon $LON`
LONEW=`degdec2mindec $LON EW | cut -c 1 `
LONH=`degdec2mindec $LON EW | sed -e "s/.//" -e "s/\..*//" `
LONMIN=`degdec2mindec $LON | sed "s/[^.]*\.//" `
SEARCH="searchto=searchbydistance&sort=bydistance"
SEARCH="$SEARCH&latNS=$LATNS&lat_h=$LATH&lat_min=$LATMIN"
SEARCH="$SEARCH&lonEW=$LONEW&lon_h=$LONH&lon_min=$LONMIN"
#echo "$SEARCH"

ok_query
