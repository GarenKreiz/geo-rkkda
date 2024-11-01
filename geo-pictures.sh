#!/bin/bash

#
#       geo-pictures
#
#       add pictures to logs on www.geocaching.com
#
#       syntax:
#               geo-pictures -f <list-of-pictures.txt>

#
#	Requires: curl; bash or ksh;
#
#	Based on geo-found, donated to the public domain by Rick Richardson <rickrich@gmail.com>
#   Modifications and additions : copyright Garenkreiz 2016-2024
# 
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
    `basename $PROGNAME` - Add pictures to geocaching logs

SYNOPSIS
    `basename $PROGNAME` -n <list-of-pictures.txt> 

DESCRIPTION
    Add pictures to geocaching logs, setting the correct date

    Requires:
        A member login at:
	     http://www.geocaching.com

	curl		http://curl.haxx.se/
EOF
    gc_usage
    cat << EOF

EXAMPLES

    The <list-of-pictures.txt> file contains lines of the form 
    
    <YYYY/MM/DD>|<LogID>|<filename-of-image>|<caption>|<description>

    For example
    2016/11/20|GLPT5Y98|GC/2016_1120_121859AA.jpg|Stade en travaux|

    The pictures are associated to logs in the same order as the lines in the file

FILES
    ~/.georc

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
UPDATE_URL=$WEBHOME/geo-pictures
UPDATE_FILE=geo-pictures.new

read_rc_file

#
#       Process the options
#
BYUSER="$USERNAME"

while getopts "f:h?-" opt
do
    case $opt in
	f)      LISTPICTURES="$OPTARG";;
	h|\?|-) usage;;
    esac
done

if [ "$LISTPICTURES" == "" ] ; then
    LOGID="$1"
    FILEPICTURE="$2"
    CAPTIONPICTURE="$3"
    DATEPICTURE="$4"
    DESCRIPTIONPICTURE="$5"    
fi
shift `expr $OPTIND - 1`

DBGCMD_LVL=2
if [ $DEBUG -gt 0 ]; then
    TMP=/tmp/geo
else
    TMP=/tmp/geo$$
fi
if [ $NOCOOKIES = 1 ]; then
    CRUFT="$CRUFT $COOKIE_FILE"
fi

#
#	Main Program
#

LOGUSERNAME="$BYUSER"
byuser=`urlencode "$BYUSER" | tr ' ' '+' `
SEARCH="?ul=$byuser"
if [ "$BYUSER" = "$USERNAME" ]; then
    VARTIME=ifound
fi

#
# upload an image with title and set the date
#
upload_image() {
    FILEPICTURE="$1"
    CAPTIONPICTURE="$2"
    DATEPICTURE="$3"
    DESCRIPTIONPICTURE="$4"    

    echo ==== Uploading image $FILEPICTURE $CAPTIONPICTURE $DATEPICTURE

    ID=$RANDOM
    
	URL="$GEOS/api/live/v1/logs/$LID/images"

    echo ==== Upload $URL in $ID

	curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		 -v --trace trace_upload_image_$ID.txt \
		 -H "Connection: keep-alive" \
		 -H "CSRF-Token: $CSRF_TOKEN" \
		 -H "Authorization: Bearer $ACCESS_TOKEN" \
		 -H "Accept: application/json, text/javascript, */*; q=0.01" \
		 -F "image=@$FILEPICTURE;type=image/jpeg" \
		 "$URL" > $HTMLPAGE

    cp $HTMLPAGE geo_upload_image_$ID.html

    sleep 1

    if ! grep -y -q 'url":' $HTMLPAGE; then
		error "Error after uploading an image"
    fi
	
    PICTURE=`grep url $HTMLPAGE | sed 's/.*geocaching.com\///' | sed 's/.jpg".*//'`
	URL="$GEOS/api/live/v1/images/$LID/$PICTURE/replace"

    echo ==== Modify image description $PICTURE in $LID

    curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		 -X PUT \
		 -v --trace trace_modify_image_$ID.txt \
		 -H "Connection: keep-alive" \
		 -H "CSRF-Token: $CSRF_TOKEN" \
		 -H "Origin: www.geocaching.com" \
		 -H "Referer: https://www.geocaching.com/live/log/$LID" \
		 -H "Accept: application/json" \
		 -H "Content-Type: multipart/form-data" \
		 -F "description=$DESCRIPTIONPICTURE" \
		 -F "name=$CAPTIONPICTURE" \
		 "$URL" > $HTMLPAGE

    cp $HTMLPAGE geo_modify_image_$ID.html

    sleep 1
    
    if ! grep -y -q 'name":' $HTMLPAGE; then
		error "Error modifying image name"
    fi 
    
    return
    echo ==== Modify details $URL in $ID

    curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
	 -v --trace trace_modify_details_$ID.txt \
    	 $viewstate \
	 -d "__VIEWSTATEGENERATOR=$__VIEWSTATEGENERATOR" \
	 -d "__EVENTTARGET=ctl00\$ContentBody\$ImageEditPanel1\$btnEditTxt" \
	 -d "__EVENTARGUMENT=" \
	"$URL" > $HTMLPAGE

    cp $HTMLPAGE geo_modify_details_$ID.html
    gc_getviewstate $HTMLPAGE
    sleep 1
    
    if ! grep -y -q "description:" $HTMLPAGE; then
	error "Error after modifying details"
    fi 

    echo ==== Sending form $URL
  
    echo ==== Date $DATEPICTURE
    setDate=`echo $DATEPICTURE | sed 's,\(....\)/\(..\)/\(..\),Year=\1 ; Month=\2 ; Day=\3,'`
    eval $setDate
    curl $CURL_OPTS -L -s -b $COOKIE_FILE -A "$UA" \
	 -v --trace trace_sending_form_$ID.txt \
	 -d "__EVENTTARGET=" \
	 -d "__EVENTARGUMENT=" \
	 -d "__LASTFOCUS=" \
    	 $viewstate \
	 -d "__VIEWSTATEGENERATOR=$__VIEWSTATEGENERATOR" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbName=$CAPTIONPICTURE" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbDateTimeTaken=September/01/2016" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbDateTimeTaken\$Month=$Month" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbDateTimeTaken\$Day=$Day" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbDateTimeTaken\$Year=$Year" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$tbNote=$DESCRIPTIONPICTURE" \
	 -d "ctl00\$ContentBody\$ImageEditPanel1\$btnEdit=Modifier+les+détails" \
	 -d "__RequestVerificationToken=$__RequestVerificationToken" \
	"$URL" > $HTMLPAGE

    cp $HTMLPAGE geo_sending_form_$ID.html
    sleep 1
    
    if ! grep -y -q "_lbHeading" $HTMLPAGE; then
		return
	error "Error after uploading an image"
    fi 
}

export OLDLOGID=""

#
# load the web page of a geocaching log
#
goto_log() {

    #
    # Fetch the page of a log 
    #

    LOGID="$1"
    
	if [ "$LOGID" = "$OLDLOGID" ];
	then
		return
	fi

    URL="$GEOS/live/log/$LOGID"

    echo ==== Seeking log $1 $URL

    debug 1 "$start: curl $URL "

    ID=$RANDOM
    curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	 -v --trace trace_seeking_log_$ID.txt \
        "$URL" \
        | $sed -e "s/&#39;/'/g" -e "s/\r//" > $HTMLPAGE

    cp $HTMLPAGE geo_seeking_log_$ID.html
    gc_getviewstate $HTMLPAGE
    
    if ! grep -y -q "logText" $HTMLPAGE; then
	error "Log page not found"
    fi 

    LID=`grep "referenceCode" $HTMLPAGE | sed 's,.*referenceCode":",,' | sed 's/".*//'` 
    CSRF_TOKEN=`grep "csrfToken" $HTMLPAGE | sed 's,.*csrfToken":",,' | sed 's/".*//'` 
    
    echo ==== Uploading for log $LID csrf $CSRF
	    
    URL="https://www.geocaching.com/account/oauth/token"

    echo ==== Getting authorization $URL

    debug 1 "$start: curl $URL "

    ID=$RANDOM
	
    curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
	 -v --trace trace_get_auth_$ID.txt \
        "$URL" \
        | $sed -e "s/&#39;/'/g" -e "s/\r//" > $HTMLPAGE

    cp $HTMLPAGE geo_get_auth_$ID.html
    
    if ! grep -y -q "access_token" $HTMLPAGE; then
		error "Authorization failed"
    fi 

    ACCESS_TOKEN=`grep "access_token" $HTMLPAGE | sed 's,.*access_token":",,' | sed 's/".*//'` 
    TOKEN_TYPE=`grep "token_type" $HTMLPAGE | sed 's,.*token_type":",,' | sed 's/".*//'` 

    URL="https://www.geocaching.com/api/auth/csrf"
	
    echo ==== Getting CSRF $URL

    debug 1 "$start: curl $URL "

    ID=$RANDOM
	
    curl $CURL_OPTS -L -s -b $COOKIE_FILE -c $COOKIE_FILE -A "$UA" \
		-v --trace trace_get_csrf_$ID.txt \
		-H "Accept: application/json" \
		-H "Referer: https://www.geocaching.com/live/log/$LID" \
        "$URL" \
        | $sed -e "s/&#39;/'/g" -e "s/\r//" > $HTMLPAGE

    cp $HTMLPAGE geo_get_csrf_$ID.html
    
    if ! grep -y -q "csrfToken" $HTMLPAGE; then
		error "Authorization failed"
    fi 

    CSRF_TOKEN=`grep "csrfToken" $HTMLPAGE | sed 's,.*csrfToken":",,' | sed 's/".*//'`
	OLDLOGID=$LOGID
}

process_file() {

    echo "==== Processing file" $1
    cp $1 listeImages_$RANDOM.txt
    LOGID="__DUMMY__"
    grep "|" $1 | \
	while read i ; do
	    D=""

	    # read Day LogID, Path Caption Text
	    evalString=`echo $i | sed 's/"/\\\\"/g' | sed 's/\(.*\)|\(.*\)|\(.*\)|\(.*\)|\(.*\)/D="\1" ; L="\2" ; P="\3" ; C="\4" ; T="\5" ;/'`
	    eval $evalString
	    if [ "$D" = "" ] ; then
		exit
	    fi

	    goto_log "$L"
	    
	    test -f "$P" && upload_image "$P" "$C" "$D" ""

	done
}

#
#	Upload pictures
#
upload_pictures() {

    echo ==== Uploading pictures $FILEPICTURES $LOGID $FILEPICTURE $CAPTIONPICTURE $DATEPICTURE

    if [ $DEBUG -gt 0 ]; then
	TMP=/tmp/geo
    else
	TMP=/tmp/geo$$
    fi

    HTMLPAGE=$TMP.page
    CIDFILE=$TMP.cids
    LOCFILE=$TMP.loc
    LOCTMPFILE=$TMP.tmp
    XTRAFILE=$TMP.xtra
    CSVFILE=$TMP.csv
    CSVFILE2=$TMP.csv2
    JOINFILE=$TMP.join
    MERGEFILE=$TMP.merge
    ARCHFILE=$TMP.arch
    OUTWAY=$TMP.way
    STYLE=$TMP.newstyle

    CRUFT="$CRUFT $HTMLPAGE"
    CRUFT="$CRUFT $CIDFILE"
    CRUFT="$CRUFT $LOCFILE"
    CRUFT="$CRUFT $LOCTMPFILE"
    CRUFT="$CRUFT $XTRAFILE"
    CRUFT="$CRUFT $CSVFILE"
    CRUFT="$CRUFT $CSVFILE2"
    CRUFT="$CRUFT $JOINFILE"
    CRUFT="$CRUFT $MERGEFILE"
    CRUFT="$CRUFT $ARCHFILE"
    CRUFT="$CRUFT $OUTWAY"
    CRUFT="$CRUFT $STYLE"
    if [ $NOCOOKIES = 1 ]; then
	CRUFT="$CRUFT $COOKIE_FILE"
    fi

    echo ==== Login to gc.com
    gc_login "$USERNAME" "$PASSWORD"

    if [ $DEBUG -gt 0 ]; then
	filter2="tee $TMP.bulk"
    else
	filter2=cat
    fi

    subscriber=1
    > $XTRAFILE
    > $ARCHFILE
    ((start=0))

    if [ "$LISTPICTURES" != "" ] ; then

	echo ==== Processing $LISTPICTURES
	test -f $LISTPICTURES || (echo "No file " $LISTPICTURES ; exit )
 	process_file $LISTPICTURES			       
	exit
    fi		  

    # upload individual image
    echo "Uploading single image " $LOGID "-" $FILEPICTURE "-" "$CAPTIONPICTURE" "-" "$DATEPICTURE" "-" "" 
    goto_log "$LOGID"
    upload_image "$FILEPICTURE" "$CAPTIONPICTURE" "$DATEPICTURE" "" 
}

upload_pictures
