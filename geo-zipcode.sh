#!/bin/bash

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Translate zip code to city and state

SYNOPSIS
    `basename $PROGNAME` [options] zip ...

    `basename $PROGNAME` [options] -c city [city ...] 'st'

DESCRIPTION
    Translate zip code to city and state.

OPTIONS
    -c		Reverse lookup by city
    -D lvl	Debug level

EXAMPLE
    Convert cities:

	$ geo-zipcode 05345 50212 84763 67485 15639
	05345   Newfane, VT Windham 802
	50212   Ogden, IA Boone 515
	84763   Rockville, UT Washington 435
	67485   Tipton, KS Mitchell 785
	15639   Hunker, PA Westmoreland 724

    e.g. first letter is "NORTH".

    Convert the first three letter part:

	$ geo-zipcode 679
	67901   Liberal, KS Seward 620
	67905   Liberal, KS Seward 620
	67950   Elkhart, KS Morton 620
	67951   Hugoton, KS Stevens 620
	67952   Moscow, KS Stevens 620
	67953   Richfield, KS Morton 620
	67954   Rolla, KS Morton 620

    Convert by a city:

	$ geo-zipcode -c 'Fort Bragg' Ruffin 'Prospect Hill' 'Chapel Hill' nc
	28307 Fort Bragg, NC Cumberland 910
	28310 Fort Bragg, NC Cumberland 910
	27326 Ruffin, NC Rockingham 336
	27314 Prospect Hill, NC Caswell 336
	27515 Chapel Hill, NC Orange 919
	27514 Chapel Hill, NC Orange 919
	27599 Chapel Hill, NC Orange 919
	27517 Chapel Hill, NC Orange 919
	27516 Chapel Hill, NC Orange 919

SEE ALSO
    https://www.getzips.com/zip.htm

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
read_rc_file

DEBUG=0 
CITY=0
while getopts "cD:h?" opt
do
	case $opt in
	c)	CITY="1";;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

if [ $# = 0 ];then
    usage
fi

TMP=/tmp/zipcode$$
trap "rm -f $TMP" EXIT

#
#	Main Program
#
#    geo-zipcode uses maps.googleapis.com if GMAP_KEY is set in ~/.georc.
#    Otherwise, it uses www.getzips.com .
unset GMAP_KEY
if [ "$CITY" = 1 ]; then
    case $# in
    0|1)	error "-c requires city and abbreviated state";;
    esac
    i=1
    st="${@: -1}"
    while ((i < $#)); do
	# https://www.getzips.com/cgi-bin/ziplook.exe?What=2&City=Slidell&State=LA&Submit=Look+It+Up
	city=`echo $1 | tr ' ' '+' `
	URL="https://www.getzips.com/cgi-bin/ziplook.exe?What=2"
	URL="$URL&City=$city&State=${st^^}&Submit=Look+It+Up"
	curl -s -q "$URL" |
	    geo-htmltbl2db | grep "^[0-9]" > $TMP
	if [ -s $TMP ]; then
	    cat $TMP
	else
	    echo "$zip   No zipcode!"
	fi
	shift
    done
else
for i in $*; do
    if [ "$GMAP_KEY" = "" ]; then
	# curl 'https://www.getzips.com/cgi-bin/ziplook.exe?What=1&Zip=06820' |
	# geo-htmltbl2db 
	zip=`echo $i | sed 's/-.*//g' `
	URL="https://www.getzips.com/cgi-bin/ziplook.exe?What=1&Zip=$zip"
	#echo $URL
	curl -s -q "$URL" |
	    geo-htmltbl2db | grep "[0-9]" | sed 's/ /	/' > $TMP
	if [ -s $TMP ]; then
	    cat $TMP
	else
	    echo "$zip   No zipcode!"
	fi
    else
	URL="https://maps.googleapis.com/maps/api/geocode/xml"
	URL="$URL?key=$GMAP_KEY&address=$i&sensor=false"
	curl -s -q "$URL" > $TMP
	# cat $TMP
	if grep -q "<error_message>" $TMP; then
	    text=$(grep "<error_message>" $TMP |
		    sed -e 's@</.*@@' -e 's/<error_message>//g' )
	    echo "$i: Error: $text"
	    exit
	fi
	if ! grep -q "<status>OK</status>" $TMP; then
	    echo "$i:	no zip!"
	    continue
	fi
	printf "$i	"
	grep "<formatted_address>" $TMP \
	| sed -e 's/.*<formatted_address>//' -e 's#</.*##'
    fi
    sleep 0.1
done
fi
