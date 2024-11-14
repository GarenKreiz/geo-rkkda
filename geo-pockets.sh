#!/bin/bash

#       geo-pockets : activation, desactivation or preview of pocket queries
#
#	Requires: curl; bash or ksh;
#
#	Based on geo-found that was donated to the public domain by Rick Richardson <rickrich@gmail.com>
#   Modifications and additions : Copyright Garenkreiz 2016-2024
# 
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Activate/desactivate or preview pocket queries

SYNOPSIS
    `basename $PROGNAME` [-d] -x <day-of-week> -q <list-of-PQ-names>
    `basename $PROGNAME` -t <substring-of-query-names>

DESCRIPTION
    Activate or desactivate a list of pocket queries for a given day in a week.
        The list is a concatenation of the queries' names separated colons (":")
    Display the top most recent caches for pocket queries matching a pattern


    Requires:
        A premium member login at:
	     http://www.geocaching.com

	curl		http://curl.haxx.se/
	gpsbabel	http://gpsbabel.sourceforge.net/

EOF

    cat << EOF

EXAMPLES
    Activate pocket query PQ001 on Monday

	geo-pockets -n 2 -q PQ001

    Desactivate pocket queries PQ001:PQ002 on Sunday

	geo-pockets -n 1 -d -q PQ001:PQ002

    Generate file with top caches for pockets queries beginning with PQ_

    geo-pockets -t PQ_

FILES
    ~/.georc
    ~/.geo/caches/

SEE ALSO
    $WEBHOME
EOF

	exit 1
}

#include "geo-common"
#include "geo-common-gc"

#
#       Set default options, can be overriden on command line or in rc file
#
UPDATE_URL=$WEBHOME/geo-found
UPDATE_FILE=geo-found.new

read_rc_file

#
#       Process the options
#
BYUSER="$USERNAME"

DELETE=0

while getopts "dq:t:x:u:p:D:h?-" opt
do
    case $opt in
    d)  DELETE=1;;
    q)  POCKETQUERY="$OPTARG";;
    t)  TOP="$OPTARG";;
	x)  NUM="$OPTARG"
        case "$NUM" in
		    [0-9]*)	;;
		    *)	error "Not a number: '$NUM'";;
		esac
		if [ "$NUM" -lt 1 -o "$NUM" -gt 7 ]; then
		    error "NUM $NUM is not between 1 (Sunday) and 7 (Saturday)"
		fi
		;;

    u)	USERNAME="$OPTARG";;
    p)	PASSWORD="$OPTARG";;
    D)	DEBUG="$OPTARG";;
	h|\?|-) usage;;
    *) echo "XXXX";;
    esac
done

LOGUSERNAME="$BYUSER"
byuser=`urlencode "$BYUSER" | tr ' ' '+' `
SEARCH="?ul=$byuser"
if [ "$BYUSER" = "$USERNAME" ]; then
    VARTIME=ifound
fi

#
#	Process pocket queries
#
gc_queriesinit() {

    if [ $DEBUG -gt 0 ]; then
	TMP=/tmp/geo-pockets
    else
	TMP=/tmp/geo$$
    fi

    HTMLPAGE=${TMP}_list.html
    CRUFT="$CRUFT $HTMLPAGE"
    
    if [ $NOCOOKIES = 1 ]; then
	CRUFT="$CRUFT $COOKIE_FILE"
    fi

    
    #	Login to gc.com
    #
    gc_login "$USERNAME" "$PASSWORD"

    # 
    #   Goto to page number
    #

    #
    # Fetch the page of closest caches and scrape the cache ID's
    #
    
    URL="$GEOS/pocket"

    debug 1 "$start: curl $URL "

    curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
        "$URL" \
        | $sed -e "s/&#39;/'/g" -e "s/\r//" > $HTMLPAGE

    if [ "$DEBUG" -ge 1 ]; then
        grep "Total Records:.*Top.*" $HTMLPAGE |
        sed -e "s/<.b>.*//" -e "s/^.*span>//" -e "s/<b>//" 1>&2
    fi
    
    rc=$?; if [ $rc != 0 ]; then
        error "curl: fetch $URL"
    fi
    if grep -s -q "We encountered an error when requesting that page!" \
        $HTMLPAGE; then
        error "searching error (1) on $start"
    fi
    if grep -s -q "has resulted in an error" \
        $HTMLPAGE; then
        error "searching error (2) on $start"
    fi
    if grep -s -q "By State" $HTMLPAGE; then
        error "searching gave up on $start"
    fi
    if grep -s -q ">Advanced Search<" $HTMLPAGE; then
        error "need a country AND a state!"
    fi

    #
    # Grab a few important values from the page
    #
    # 
    # gc_getviewstate $HTMLPAGE
    
    #
    # Grab the CIDs into two categories: found and notfound
    #
    PQFILE=${TMP}_pq.txt
    CRUFT="$CRUFT $HTMLPAGE"

    grep gcquery $HTMLPAGE | sed 's/.*uid=\(.*\)" title="\(.*\)".*/\2|\1/' > $PQFILE
}

gc_pqueries() {

    gc_queriesinit

    if [ $DELETE = 0 ]; then
	PQSET=1
    else
	PQSET=0
    fi

    ((NUM=NUM-1))

    if [ "$POCKETQUERY" != "" ]; then
	echo "$POCKETQUERY" | tr ":" "\n" | while read i
	do 
	    pqid=`grep "$i" $PQFILE | sed 's/.*|//'`
	    echo "Setting $i $pqid day=$NUM => set=$PQSET"
	    URL="$GEO/pocket/default.aspx?pq=$pqid&d=$NUM&opt=$PQSET"

        HTMLPAGE=${TMP}_$RANDOM.html
        CRUFT="$CRUFT $HTMLPAGE"

	    curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
		"$URL" \
		| $sed -e "s/&#39;/'/g" -e "s/\r//" > $HTMLPAGE
	    sleep $GEOSLEEP
	done
    fi

}

gc_tqueries() {

    gc_queriesinit

    grep "$1" $PQFILE | while read i
    do
        pqid=`echo "$i" | sed 's/.*|//'`
        name=`echo "$i" | sed 's/|.*//'`

	    URL="$GEO/seek/nearest.aspx?pq=$pqid&sortdir=desc&sort=placed"
        HTMLPAGE=geo-pockets_top_$name.html

	    curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
            "$URL" > $HTMLPAGE

        gawk < $HTMLPAGE \
        '
        BEGIN {
            print "Code|Date placed|Name|D/T|Size|Type"
        }
        /SearchResultsWptType/ {
            match($0, "alt=\"([^\"]*)\".*/geocache/(GC[0-9A-Z]*)_.*<span>(.*)</span>", fld)
            gctype = fld[1]
            gccode = fld[2]
            gcname = fld[3]
            nbSmall = 0
        }
        /<span class="small">/ {
            if (nbSmall == 1)
            {
                match($0, "\"small\">(.*)</span>", fld)
                gcdt = fld[1]
            }
            if (nbSmall == 2) {
                match($0, "\"small\">([^<]*)</span>", fld)
                gcdate = fld[1]
                printf "%s|%s|%s|%s|%s|%s\n", gccode, gcdate, gcname, gcdt, gcsize, gctype
            }
            nbSmall += 1
        }
        /Size:/ {
            match($0, "Size: ([^\"]*)\"", fld)
            gcsize = fld[1]
        }
        '
	    sleep $GEOSLEEP
   done
}

if [ "$TOP" != "" ]; then
    gc_tqueries "$TOP"
elif [ "$POCKETQUERY" != "" ]; then
    gc_pqueries
fi

