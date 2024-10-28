#!/bin/bash

#
#	Donated to the public domain by Rick Richardson <rickrich@gmail.com>
#
#	Use at your own risk.  Not suitable for any purpose.  Not legal tender.
#

PROGNAME="$0"

usage() {
	cat <<EOF
NAME
	`basename $PROGNAME` - Project a waypoint

SYNOPSIS
	`basename $PROGNAME` [options] lat1 lon1 distance bearing

	`basename $PROGNAME` -1 [options] lat1 lon1 dist bear [dist bear] ...
	`basename $PROGNAME` -2 [options] lat1 lon1 dist bear [dist bear] ...
	`basename $PROGNAME` -3 [options] lat1 lon1 dist bear [dist bear] ...

DESCRIPTION
	Project a waypoint.

	lat/lon can be specified in DegDec or dotted MinDec format.

	distance is in miles unless suffixed with engchain, chain, fathom,
	au, rod, furlong, hand, link, pace, fizzy, smoot, verst, km, m,
	nmi (nautical mile), mi (mile), yd, ft, in, or mil (thou).

	bearing is in compass degrees unless suffixed with mil, grad, rad, or
	furman or n, nne, ne, ene, e, ese, se, sse, s, ssw, sw, wsw, w, wnw,
	nw, nnw or HH:MM.

	If the bearing is a negative number, then calculate in the reverse
	to:from instead of from:to.

OPTIONS
	-1	For the second invocation, 1 number for lat/lon
		e.g. N42.43.919 or 52.155174
	-2	For the second invocation, 2 numbers for lat/lon
		e.g. N42 43.919
	-3	For the second invocation, 3 numbers for lat/lon
		e.g. N 32 57.218
	-g	Use WGS 1984 ellipsoid calculation method - Gazza
	-m	Use WGS 1984 ellipsoid calculation method - Midpoint [default]
	-u	Use UTM calculation method
	-s rad	Use spherical calculation method with radius = rad in meters
		6378137 meters is the equatorial radius of earth
	-l	Output decimal latitude only (for scripts)
	-L	Output decimal longitude only (for scripts)
	-M	Also do a geo-map of the coordinates
	-D lvl	Debug level

EXAMPLES
	Project a waypoint 13147.2 feet at 38 degrees:

	    $ geo-project 44.47.151 -93.14.094 13147.2ft 38
	    wp = 44.814260 -93.203712       n44.48.856 w93.12.223

	Project a spherical waypoint 402.31 meters at 228.942 degrees:

	    $ geo-project -s 6378000 N42.43.919 W84.28.929 402.31m 228.942
	    wp = 42.729609 -84.485860       n42.43.777 w84.29.152

	Project a waypoint 9018.3017 kilometers at 315.44007 degrees:

	    $ geo-project 52.155174 5.387206 9018.3017km 315.44007
	    wp = 33.783663 -118.068481      n33.47.020 w118.04.109

	Project a waypoint 351.98 smoots at 64583.68 furmans:

	    $ geo-project N32.57.218 W111.52.687 351.98smoot 64583.68furman
	    wp = 32.959012 -111.878700      n32.57.541 w111.52.722

	Project a waypoint 898.2 feet at 01:38 hours and minutes:

	    $ geo-project N40.7340167 W73.9886333 898.2ft 1:38 
	    wp = 40.735634 -73.986187       n40.44.138 w73.59.171

	Project a waypoint a total of three times:

	    $ geo-project -1 n44.47.151 w93.14.094 131ft 38 100m 215 1mi n
	    wp = 44.786133 -93.234589       n44.47.168 w93.14.075
	    wp = 44.785396 -93.235314       n44.47.124 w93.14.119
	    wp = 44.799878 -93.235314       n44.47.993 w93.14.119

SEE ALSO
	https://en.wikipedia.org/wiki/Earth_ellipsoid

	http://mngca.rkkda.com/geodetics.html

	http://www.geomidpoint.com/destination/

EOF

	exit 1
}

#include "geo-common"

#
#       Process the options
#
METHOD=midpoint
RADIUS=6378000
DEBUG=0
DOLAT=0
DOLON=0
MAP=0
NUMCOORD=default
while getopts "123gmulLMs:D:h?" opt
do
	case $opt in
	1)	NUMCOORD=1;;
	2)	NUMCOORD=2;;
	3)	NUMCOORD=3;;
	g)	METHOD=gazza;;
	m)	METHOD=midpoint;;
	u)	METHOD=utm;;
	s)	METHOD=sphere; RADIUS="$OPTARG";;
	l)	DOLAT=1;;
	L)	DOLON=1;;
	M)	MAP=1;;
	D)	DEBUG="$OPTARG";;
	h|\?)	usage;;
	esac
done
shift `expr $OPTIND - 1`

case $NUMCOORD in
1)
    if [ $# -lt 4 ]; then
	error "Number of coordinate is less than 1 (or 2 for lat/lon)"
    fi
    LAT0=`latlon $1`
    LON0=`latlon $2`
    DIST=$3
    BEAR=$4
    shift 4
    ;;
2)
    if [ $# -lt 6 ]; then
	error "Number of coordinate is less than 2 (or 4 for lat/lon)"
    fi
    LAT0=`latlon $1.$2`
    LON0=`latlon $3.$4`
    DIST=$5
    BEAR=$6
    shift 6
    ;;
3)
    if [ $# -lt 8 ]; then
	error "Number of coordinate is less than 3 (or 6 for lat/lon)"
    fi
    LAT0=`echo "$1$2.$3" | tr -d '\260\302' `
    LAT0=`latlon $LAT0`
    LON0=`echo "$4$5.$6" | tr -d '\260\302' `
    LON0=`latlon $LON0`
    DIST=$7
    BEAR=$8
    shift 8
    ;;
default)
    case "$#" in
    8)
	    # Cut and paste from geocaching.com cache page
	    # N 44ฐ 58.630 W 093ฐ 09.310
	    LAT0=`echo "$1$2.$3" | tr -d '\260\302' `
	    LAT0=`latlon $LAT0`
	    LON0=`echo "$4$5.$6" | tr -d '\260\302' `
	    LON0=`latlon $LON0`
	    DIST=$7
	    BEAR=$8
	    shift 8
	    ;;
    6)
	    LAT0=`latlon $1.$2`
	    LON0=`latlon $3.$4`
	    DIST=$5
	    BEAR=$6
	    shift 6
	    ;;
    4)
	    LAT0=`latlon $1`
	    LON0=`latlon $2`
	    DIST=$3
	    BEAR=$4
	    shift 4
	    ;;
    *)
	    usage
	    ;;
    esac
    ;;
esac

#
#	Main Program
#
project_utm() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	-v MAP="$MAP" \
	'
    #include "geo-awk-library"

    function doit(LAT0, LON0, DIST, BEAR)  {
	PI = 3.1415926535

	# Convert DIST to meters
	dist = dist2meters(DIST)

	# Convert BEAR to degrees
	BEAR = bear2degrees(BEAR)
	BEAR = ((360-BEAR) + 90) % 360
	bear = BEAR * (PI/180.0)

	command = sprintf("ll2utm -- %s %s", LAT0, LON0)
	command | getline;
	zone = $1
	nz = $2
	x0 = $3
	y0 = $4

	rise = dist * sin(bear)
	run = dist * cos(bear)
	# print rise, run

	x1 = x0 + run
	y1 = y0 + rise
	command = sprintf("utm2ll -- %s %s %s %s", zone, nx, x1, y1)
	command | getline; lat = $1; lon = $2
	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "    %s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}

	if (MAP)
	{
	    if (Delay) system("sleep 2")
	    system("geo-map " lat " " lon)
	}
    }
    BEGIN {
	doit(LAT0, LON0, DIST, BEAR)
	ARGC--
	if (ARGC % 2 == 1)
	{
	    print "error: odd number of distance and bearing!"
	    exit
	}
	Delay = 1
	for (i = 5; i < ARGC; i += 2)
	{
	    #print ARGV[i], ARGV[i+1]
	    doit(lat, lon, ARGV[i], ARGV[i+1])
	}
    }
    ' $*
}

project_gazza() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	-v MAP="$MAP" \
	'
    #include "geo-awk-library"

    function doit(LAT0, LON0, DIST, BEAR)  {
	M_PI = 3.14159265358979323846
	M_PI_2 = M_PI / 2
	a = 6378388.0			# semi-major axis
	f = 1 / 297.0			# flattening

	# https://en.wikipedia.org/wiki/Earth_ellipsoid
	a = 6378137.0			# semi-major axis, WGS-84
	f = 1 / 298.257223563		# flattening, WGS-84

	b = a * (1 - f)			# semi-minor axis
	e2 = (a * a - b * b)/(a * a)	# eccentricity squared
	e = sqrt(e2)			# eccentricity
	ei2 = (a * a - b * b)/(b * b)	# second eccentricity squared
	ei = sqrt(ei2)			# second eccentricity

	lat0 = LAT0*M_PI/180.0	#radians
	lon0 = LON0*M_PI/180.0	#radians
	# Convert BEAR to degrees
	BEAR = bear2degrees(BEAR)
	x12 = BEAR*M_PI/180.0	#radians

	# Convert DIST to meters
	s = dist2meters(DIST)

	if (abs(s) > 10019148.059)
	{
	    print "Distance too great, use a great circle calculator instead"
	    exit(1)
	}

	tanB1 = tan(lat0) * (1 - f);
	B1 = atan(tanB1);
	cosB0 = cos(B1) * sin(x12);
	B0 = acos(cosB0);
	g = cos(B1) * cos(x12);
	m = (1 + (ei2 / 2) * sin(B1) * sin(B1)) * (1 - cos(B0) * cos(B0));
	phis = s / b;
	a1 = (1 + (ei2 / 2) * sin(B1) * sin(B1)) \
	    * (sin(B1) * sin(B1) * cos(phis) + g * sin(B1) * sin(phis));

	term1 = a1 * (-1 * (ei2 / 2) * sin(phis));
	term2 = m * (-1 * (ei2 / 4) * phis + (ei2 / 4) * sin(phis) * cos(phis));
	term3 = a1 * a1 * ((5 * ei2 * ei2 / 8) * sin(phis) * cos(phis));
	term4 = m * m * ( \
		( 11 * ei2 * ei2 / 64) * phis - (13 * ei2 * ei2 / 64) * sin(phis) \
		* cos(phis) - (ei2 * ei2 / 8) * phis * cos(phis) * cos(phis) \
		+ (5 * ei2 * ei2 / 32) * sin(phis) * pow(cos(phis), 3) \
		);
	term5 = a1 * m * ( \
		(3 * ei2 * ei2 / 8) * sin(phis) + (ei2 * ei2 /4) * phis \
		* cos(phis) - (5 * ei2 * ei2 / 8) * sin(phis) * cos(phis) \
		* cos(phis) \
		);
	phi0 = phis + term1 + term2 + term3 + term4 + term5;

	denom = sin(phi0) * sin(x12)
	if (denom == 0)
	    cotlamda = 9999999999999
	else
	    cotlamda = (cos(B1) * cos(phi0) - sin(B1) * sin(phi0) * cos(x12)) \
		    / denom
	lamda = atan(1 / cotlamda);

	term1 = -1 * f * phis;
	term2 = a1 * ((3 * f * f / 2) * sin(phis));
	term3 = m * ((3 * f * f / 4) * phis \
		    - (3 * f * f / 4) * sin(phis) * cos(phis));
	w = (term1 + term2 + term3) * cos(B0) + lamda;

	lon = lon0 + w
	
	sinB2 = sin(B1) * cos(phi0) + g * sin(phi0);
	cosB2 = sqrt((cos(B0) * cos(B0)) + \
	    pow((g * cos(phi0) - sin(B1) * sin(phi0)), 2));
	tanB2 = sinB2 / cosB2;
	tanlat2 = tanB2 / (1 - f);
	lat = atan(tanlat2);

	lon = lon*180.0 / M_PI
	lat = lat*180.0 / M_PI

	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}

	if (MAP)
	{
	    if (Delay) system("sleep 2")
	    system("geo-map " lat " " lon)
	}
    }
    BEGIN {
	doit(LAT0, LON0, DIST, BEAR)
	ARGC--
	if (ARGC % 2 == 1)
	{
	    print "error: odd number of distance and bearing!"
	    exit
	}
	Delay = 1
	for (i = 5; i < ARGC; i += 2)
	{
	    #print ARGV[i], ARGV[i+1]
	    doit(lat, lon, ARGV[i], ARGV[i+1])
	}
    }
    ' $*
}

project_midpoint() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	-v MAP="$MAP" \
	'
    #include "geo-awk-library"

    function doit(LAT0, LON0, DIST, BEAR)  {
	M_PI = 3.14159265358979323846
	M_PI_2 = M_PI / 2
	# https://en.wikipedia.org/wiki/Earth_ellipsoid
	a = 6378137.0			# semi-major axis, WGS-84
	f = 1 / 298.257223563		# flattening, WGS-84
	b = a - (a / 298.257223563)

	# Convert BEAR to degrees
	BEAR = bear2degrees(BEAR)
	brg = BEAR*M_PI/180.0	#radians

	lat1 = LAT0*M_PI/180.0	#radians
	lon1 = LON0*M_PI/180.0	#radians

	sb = sin(brg);
	cb = cos(brg);
	tu1 = (1 - f) * tan(lat1);
	cu1 = 1 / sqrt(1 + tu1*tu1);
	su1 = tu1 * cu1;
	s2 = atan2(tu1, cb);
	sa = cu1 * sb;
	csa = 1 - sa*sa;
	us = csa * (a*a - b*b) / (b*b);
	A = 1 + us/16384 * (4096 + us *(-768 + us * (320 - 175 * us)));
	B = us/1024 * (256 + us * (-128 + us * (74 - 47 * us)));

	# Convert DIST to meters
	s = dist2meters(DIST)

	if (abs(s) > 10019148.059)
	{
	    print "Distance too great, use a great circle calculator instead"
	    exit(1)
	}

	s1 = s/(b*A);
	s1p = 2*PI;
	# Use Vincenty ...
	while (abs(s1 - s1p) > 1e-12) {
	    cs1m = cos(2 * s2 + s1);
	    ss1 = sin(s1);
	    cs1 = cos(s1);
	    ds1 = B * ss1 * (cs1m + B/4 * (cs1 * (-1 + 2*cs1m*cs1m) \
		    - B/6 * cs1m * (-3 + 4*ss1*ss1) * (-3 + 4*cs1m*cs1m)));
	    s1p = s1;
	    s1 = s / (b*A) + ds1;
	}
	t = su1*ss1 - cu1*cs1*cb;
	lat2 = atan2(su1*cs1+cu1*ss1*cb, (1-f)*sqrt(sa*sa + t*t));
	l2 = atan2(ss1*sb, cu1*cs1-su1*ss1*cb);
	c = f/16 * csa * (4 + f * (4 - 3*csa));
	l = l2 - (1-c) * f * sa \
		* (s1 + c * ss1 * (cs1m + c * cs1 * (-1 + 2*cs1m*cs1m)));
	d = atan2(sa, -t);
	#point.finalBrg=d+2*PI;
	#point.backBrg=d+PI;
	#point.lat = lat2;
	#point.lon = lon1+l;
	lat = lat2
	lon = lon1+l
	lat = lat*180.0 / M_PI
	lon = lon*180.0 / M_PI

	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}

	if (MAP)
	{
	    if (Delay) system("sleep 2")
	    system("geo-map " lat " " lon)
	}
    }
    BEGIN {
	doit(LAT0, LON0, DIST, BEAR)
	ARGC--
	if (ARGC % 2 == 1)
	{
	    print "error: odd number of distance and bearing!"
	    exit
	}
	Delay = 1
	for (i = 5; i < ARGC; i += 2)
	{
	    #print ARGV[i], ARGV[i+1]
	    doit(lat, lon, ARGV[i], ARGV[i+1])
	}
    }
    ' $*
}

project_sphere() {
    $awk \
	-v LAT0="$1" \
	-v LON0="$2" \
	-v DIST="$3" \
	-v BEAR="$4" \
	-v RADIUS="$RADIUS" \
	-v DOLAT="$DOLAT" \
	-v DOLON="$DOLON" \
	-v MAP="$MAP" \
	'
    #include "geo-awk-library"

    function doit(LAT0, LON0, DIST, BEAR)  {
	M_PI = 3.14159265358979323846
	M_PI_2 = M_PI / 2

	lat1 = LAT0*M_PI/180.0	#radians
	lon1 = LON0*M_PI/180.0	#radians
	# Convert BEAR to degrees
	BEAR = bear2degrees(BEAR)
	brng = BEAR*M_PI/180.0	#radians

	# Convert DIST to meters
	s = dist2meters(DIST)

	if (abs(s) > 10019148.059)
	{
	    print "Distance too great, use a great circle calculator instead"
	    exit(1)
	}

	dist = s / RADIUS	# convert dist to angular distance in radians
	lat2 = asin( sin(lat1)*cos(dist) + \
		    cos(lat1)*sin(dist)*cos(brng) )
	lon2 = lon1 + atan2(sin(brng)*sin(dist)*cos(lat1), \
			   cos(dist)-sin(lat1)*sin(lat2))
	lon2 = (lon2+3*M_PI) % (2*M_PI) - M_PI;  # normalise to -180..+180ยบ

	lat = lat2
	lon = lon2
	lon = lon*180.0 / M_PI
	lat = lat*180.0 / M_PI

	if (DOLAT || DOLON)
	{
	    if (DOLAT) printf("%f", lat);
	    if (DOLAT && DOLON) printf("	");
	    if (DOLON) printf("%f", lon);
	    printf("\n");
	}
	else
	{
	    printf "wp = %f %f", lat, lon
	    ilat = int(lat); ilon = int(lon)
	    printf "	%s%02d.%06.3f %s%02d.%06.3f", \
		lat >= 0.0 ? "n" : "s", abs(ilat), abs(lat-ilat) * 60, \
		lon >= 0.0 ? "e" : "w", abs(ilon), abs(lon-ilon) * 60
	    printf "\n"
	}

	if (MAP)
	{
	    if (Delay) system("sleep 2")
	    system("geo-map " lat " " lon)
	}
    }
    BEGIN {
	doit(LAT0, LON0, DIST, BEAR)
	ARGC--
	if (ARGC % 2 == 1)
	{
	    print "error: odd number of distance and bearing!"
	    exit
	}
	Delay = 1
	for (i = 5; i < ARGC; i += 2)
	{
	    #print ARGV[i], ARGV[i+1]
	    doit(lat, lon, ARGV[i], ARGV[i+1])
	}
    }
    ' $*
}

case "$METHOD" in
utm)
    project_utm $LAT0 $LON0 $DIST $BEAR $*
    ;;
sphere)
    project_sphere $LAT0 $LON0 $DIST $BEAR $*
    ;;
midpoint)
    project_midpoint $LAT0 $LON0 $DIST $BEAR $*
    ;;
gazza)
    project_gazza $LAT0 $LON0 $DIST $BEAR $*
    ;;
esac
