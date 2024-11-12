#!/bin/bash

#
#	geo-count: Count geocache finds
#
#	Requires: curl; lynx; gawk; bash or ksh;
#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#
#	$Id: geo-count.sh,v 1.36 2015/03/26 22:36:16 rick Exp $
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Count geocache finds or logs

SYNOPSIS
    `basename $PROGNAME` [options] user ...
    `basename $PROGNAME` [options] GCxxxx ...

DESCRIPTION
    `basename $PROGNAME` [options] user ...

	Report and count geocache finds for "user".  "user" can be
	a user name or a user account number.

    `basename $PROGNAME` [options] GCxxxx ...

	Count number of log entries for a cache.

    Requires:
	A free login at http://www.geocaching.com.
	curl		http://curl.haxx.se/

OPTIONS
	-b		Include benchmarks in count
	-c		Remove cookie file when done
	-o		Include counts of items owned
	-s		Only print one output line with totals
	-h		Print header line
	-t		Include counts of travel bugs
	-u username	Username for http://www.geocaching.com
	-p password	Password for http://www.geocaching.com
	-D lvl		Debug level [$DEBUG]
	-U		Retrieve latest version of this script

	Defaults can also be set with variables in file \$HOME/.georc:

	    PASSWORD=password;  USERNAME=username;

EXAMPLES
	Report cache finds by type for user 'Jeremy':

	    geo-count Jeremy

	Report totals (found, placed, bugs, bugged) for user number 3:

	    geo-count -s 3

SEE ALSO
	geo-usernum, geo-found,
	$WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
BENCH=0
SUMONLY=0
DO_OWNED=0
DO_BUGS=0

read_rc_file

#
#       Process the options
#
HDR=0
UPDATE_URL=$UPDATEHOME/geo-count
UPDATE_FILE=geo-count.new
while getopts "bchop:stu:D:Uh?-" opt
do
	case $opt in
	b)	BENCH=1;;
	c)	NOCOOKIES=1;;
	o)	DO_OWNED=1;;
	s)	SUMONLY=1;;
	h)	HDR=1;;
	t)	DO_BUGS=1;;
	u)	USERNAME="$OPTARG";;
	p)	PASSWORD="$OPTARG";;
	D)	DEBUG="$OPTARG";;
	U)	echo "Getting latest version of this script..."
		curl $CURL_OPTS -o$UPDATE_FILE "$UPDATE_URL"
		chmod +x "$UPDATE_FILE"
		echo "Latest version is in $UPDATE_FILE"
		exit
		;;
	h|\?|-)	usage;;
	esac
done
shift `expr $OPTIND - 1`

[ "$USERNAME" != dummy ] || error "You need a www.geocaching.com username"
[ "$PASSWORD" != dummy ] || error "You need a www.geocaching.com password"
[ "$#" != 0 ] || usage

#
#	Count the cache stats for a gc.com cache
#
count_a_gc_cache() {
    curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
	"$GEOS/seek/cache_details.aspx?wp=$1" \
	| tee $HTMLPAGE \
    | awk \
	-v "ID=$1" \
	-v SUMONLY=$SUMONLY \
    '
	BEGIN {
		searchingby = 1
	}
	/CacheName/ {
		match($0, ".>(.*)<.", fld)
		name = fld[1]
	}
	/ContentBody_mcd1/ {
		if (searchingby == 1)
			searchingby = 2
	}
    /guid=.*/ {
		if (searchingby == 2) {
			match($0, ".*guid=[^>]*> *([^<]*)<.*", fld)
			by = fld[1]
			searchingby = 0
		}
    }
	/uxLogbookLink/ {
		match($0, ".*uxLogbookLink[^<]*\\(([0-9][0-9,]*)\\)<.*", fld)
		logs = fld[1]
		sub(",","",logs)
	}
    /lblFindCounts/{
		if ($0 ~ "Found it") {
			match($0, ".*Found it\" */> *([0-9,]*)<.*", fld)
			finds = fld[1]
			sub(",","",finds)
		}
		if ($0 ~ "Write note") {
			match($0, ".*Write note\" */> *([0-9,]*)<.*", fld)
			notes = fld[1]
			sub(",","",notes)
		}
		if ($0 ~ "Owner attention required") {
			match($0, ".*Owner attention required\" */> *([0-9,]*)<.*", fld)
			maints = fld[1]
			sub(",","",maints)
			notes = notes + maints
		}
		if ($0 ~ "t find it") {
			match($0, ".*t find it\" */> *([0-9,]*)<.*", fld)
			dnfs = fld[1]
			sub(",","",dnfs)
		}
    }
    END {
	if (SUMONLY)
	{
	    printf "%s	%6d	%6d	%6d	%6d	%s	%s\n",
		ID, finds, dnfs, notes, logs, name, by
	}
	else
	{
	    printf "Cache:	%s %s %s\n", ID, name, by
	    printf "Finds:	%6d\n", finds
	    printf "DNFs:	%6d\n", dnfs
	    printf "Notes:	%6d\n", notes
	    if (unk)
			printf "Unknown:	%6d\n", unk
	    printf "Total:	%6d\n", logs
	}
    }'
}

#
#	Count the stats for a gc.com user
#
count_a_gc_user() {
    case "$1" in
    [0-9])			USERNUM="$1";;
    [0-9][0-9])			USERNUM="$1";;
    [0-9][0-9][0-9])		USERNUM="$1";;
    [0-9][0-9][0-9][0-9]*)	USERNUM="$1";;
    *)
	    USERNUM=`geo-usernum "$1"`
	    if [ "$USERNUM" = "" ]; then
		if [ $SUMONLY = 1 ]; then
		    printf "?	?	?	?	?	"
		    echo "$1"
		else
		    error "Could not determine the user account number for '$1'"
		fi
		exit 1
	    fi
	    ;;
    esac

	#
	#	Get Profile page first, so we can get a viewstate.
	#
	case "$USERNUM" in
	*-*)	URL="$GEOS/profile/default.aspx?guid=$USERNUM";;
	*)	URL="$GEOS/profile/default.aspx?A=$USERNUM";;
	esac
	case "$USERNUM" in
	*-*)	URL="$GEOS/p/default.aspx?guid=$USERNUM&tab=geocaches#profilepanel";;
	*)	URL="$GEOS/p/default.aspx?A=$USERNUM&tab=geocaches#profilepanel";;
	esac
	debug 1 "$URL"
	curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" "$URL" > $HTMLPAGE

	gc_getviewstate $HTMLPAGE

	#
	#	Now retrieve the page of user stats
	#   Unused as some are now private by user choice
	#
	#HTMLPAGE=${TMP}_stats.html
	#CRUFT="$CRUFT $HTMLPAGE"

	#debug 1 "curl $URL -d __EVENTTARGET=ctl00%24ContentBody%24ProfilePanel1%24lnkStatistics"
	#curl $CURL_OPTS -L -s -b $COOKIE_FILE -A $"UA" \
	#    -d __EVENTTARGET=ctl00%24ContentBody%24ProfilePanel1%24lnkStatistics \
	#    -d __EVENTARGUMENT= \
	#    $viewstate \
	#    "$URL" > $HTMLPAGE
    
    #
    #	Use htmltbl2db to dump the table in an easily parsable format, then
    #	massage the output with sed and awk
    #
    geo-htmltbl2db -F'	' $HTMLPAGE \
    | gawk \
	-F "	" \
	-v SUMONLY=$SUMONLY \
	-v DO_OWNED=$DO_OWNED \
	-v DO_BUGS=$DO_BUGS \
	-v BENCH=$BENCH \
	'
    /Total Found/ { infound=1; next }
    /^$/ { next }
    /______/ { next }
    /Name Count/ { next }
    /NGS Benchmarks/ { if (!BENCH) next }
    /Total Caches Owned/ { 
	    if (infound && !SUMONLY)
		printf "%-47s	%4d\n", "TOTAL FOUND", total_found
	    inowned = 1
	    infound = 0
	    next
    }
    /All Rights Reserved/ {
	    if (infound && !SUMONLY)
		printf "%-47s	%4d\n", "TOTAL FOUND", total_found
	    infound = 0
	    inowned = 0
	    next
    }
    /Total Found/ {
	    if (infound && !SUMONLY)
		printf "%-47s	%4d\n", "TOTAL FOUND", total_found
	    infound = 0
	    inowned = 0
	    next
    }
    /Total Caches Owned/ {
	    if (infound && !SUMONLY)
		printf "%-47s	%4d\n", "TOTAL FOUND", total_found
	    infound = 0
	    inowned = 0
	    next
    }
    /Statistics for User:/ {
	    sub(".*: ", "")
	    name = $0
	    if (!SUMONLY)
		printf "%-39s	%s\n", "USERNAME:", name
	    next
    }
    /Travel Bug/ || /Geocoins/ || / Coins/ {
	if (inowned) 
	{
	    match($0, " ([^*]*) [*] *([^ ]*$)", fld)
	    if (DO_BUGS && !SUMONLY)
		printf "%-39s	%4d\n", fld[1] " owned", fld[2]
	    total_bugged += fld[2]
	}
	if (infound)
	{
	    match($0, " ([^*]*) [*] *([^ ]*$)", fld)
	    if (DO_BUGS && !SUMONLY)
		printf "%-39s	%4d\n", fld[1] " found", fld[2]
	    total_bugs += fld[2]
	}
	next
    }
    $0 ~ "All Event Cache Types" {
	next
    }
    $0 ~ "All Mystery Cache Types" {
	next
    }
    $0 !~ "Name" {
	if (inowned) 
	{
	    match($0, " ([^*]*) [*] *([^ ]*$)", fld)
	    if (DO_OWNED && !SUMONLY)
		printf "%-39s	%4d\n", $1 " owned", $2
	    total_owned += $2
	}
	if (infound)
	{
	    match($0, " ([^*]*) [*] *([^ ]*$)", fld)
	    #printf "%s <%s> <%s>\n", $0, fld[1], fld[2]
	    if (!SUMONLY)
		printf "%-39s	%4d\n", $1 " found", $2
	    total_found += $2
	}
    }
    END {
	    if (SUMONLY)
	    {
		printf "%d	%d	%d	%d	%d	%s\n",
		    total_found, total_owned, total_found+total_owned,
		    total_bugs, total_bugged,
		    name
	    }
	    else
	    {
		if (DO_OWNED)
		{
		    printf "%-47s	%4d\n", "TOTAL OWNED", total_owned
		    printf "%-47s	%4d\n", "GRAND TOTAL",
			total_found + total_owned
		}
	    }
    }
    '
}

#
#	Main Program
#
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geocount
else
    TMP=/tmp/geo$$
fi

HTMLPAGE=$TMP.html
CRUFT="$CRUFT $HTMLPAGE"

if [ "$DEBUG" -lt 2 ]; then
if [ "$__VIEWSTATE" = "" ]; then
	gc_login "$USERNAME" "$PASSWORD"
	sleep $GEOSLEEP
fi
fi

needhdr=1
__VIEWSTATE=
for what in "$@"
do
    case "$what" in
    GC[0-9A-Z][0-9A-Z]*)
	if [ $needhdr = 1 -a $HDR = 1 ]; then
	    echo "#ID	#Found	#DNF	#Notes	#Total	Name	By"
	    needhdr=0
	fi
	count_a_gc_cache "$what"
	;;
    *)
	if [ $needhdr = 1 -a $HDR = 1 ]; then
	    echo "#Found	#Placed	#F+P	#Bugs	#Bugged	Who"
	    needhdr=0
	fi
	count_a_gc_user "$what"
	;;
    esac
    if [ $# -gt 1 ]; then
	sleep $GEOSLEEP
    fi
done
