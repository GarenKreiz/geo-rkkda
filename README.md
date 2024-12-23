# geo-*		Rick Richardson's Linux tools for geocaching

Here are various tools for geocaching.  Some are designed to turn the
clickly‐clicky‐scroll‐clicky‐clicky messes that are geocaching.com,
opencaching.com, www.opencaching.us and navicache.com into a set of tools
which you can use in a batch or cron mode to establish your normal caching
routine, backup your caches and cache logs, etc.  Others are used to enter
new waypoints, free geocoder, create custom maps of waypoints, etc.

These tools work on Linux and CygWin or MSYS on MS Windows and might also work on
Mac OS X.

All of the tools that were written by Rick Richardson were released into the public
domain, with no copyright or license restrictions.  Other
tools, like gpx2html and geodetics.html, are copyright by their
original author and may have license restrictions as indicated in the
source code.

Rick Richardson passed away but his great legacy remains!

Warning: some tools make use of the rkkda.com site but it closed early 2021.

## Documentation

Any of the tools will print a usage summary with "-?", e.g.
```bash
geo-gid -?
```

### Tools for accessing gc.com...

	geo-found	List caches found (by you or someone else)
	geo-nearest	List the nearest caches to a location
	geo-newest	List the newest caches in a state
	geo-placed	List caches placed (by you or someone else)
	geo-keyword	List caches by keywords.
			All of the above can enter the waypoints into the
			GpsDrive MySQL database.
	geo-html2gpx	Convert a gc.com printable web page (such as the
			above commands can produce with the -H option) to
			a GPX file.

	geo-count	Count caches found
	geo-usernum	Determine gc.com user number (used by geo-count)
	geo-pictures	Add pictures to logs
	geo-density	Compute cache density of an area

	gpx2html	Lightly hacked converter from GPX to HTML
			Originally by fizzymagic (v1.90).  My version
			fixes issues with HTML in the cache descriptions, adds
			sort by latest log date for easy perusing of recent
		        cache activity, and fixes bug in GC[1-9]xxxx.
	gpx-loghistory	Print all logs in reverse cron order.
	geo-pqs		Figure out what PQs to run to get an entire state.
	geo-state	Convenience script;  geo-state -? gives usage.
	geo-sdt         Replace Size, Difficulty, Terrain from a PQ file
	geo-suffix	Replace name with name/TypeSizeDiffTerr/gcid/LatLon
	geo-uniq	Unique the tabsep database

### Tools for accessing gc.com requiring a Premium membership...

	geo-gid		Retrieve cache info by GCxxxx waypoint name
	geo-gpx		Retrieve GPX file by GCxxxx waypoint name
	geo-demand	Request an immediate pocket query email
	geo-gpxmail	Process PQ email using gpx2html
	geo-gpxprocess	Process PQ download(s) using geo-pqdownload and gpx2html
	geo-pqdownload	Perform a Pocket Query download(s)
	geo-myfinds	Schedule a Pocket Query containing your finds
	geo-pockets	Activate/desactivate/preview pocket queries
	geo-rehides	From your found.gpx file, produce a GPX file of rehides
	geo-correct-coords Correct the coords of cache(s)

### Tools for accessing opencaching.com...

	oc-nearest	List the nearest caches to a location
	oc-newest	List the newest caches in a state
			EXPERIMENTAL, subject to drastic changes

### Tools for accessing opencaching.us (and .nl, .de,...) ...

	ok-nearest	List the nearest caches to a location
	ok-newest	List the newest caches in a state
			EXPERIMENTAL, subject to drastic changes

### Tools for accessing navicache.com...

	nc-nearest	List the nearest caches to a location
	nc-newest	List the newest caches in a state
			EXPERIMENTAL, subject to drastic changes

### Tools for general use

	geo-2gpsdrive	Enter a waypoint file into the GpsDrive MySQL database
	geo-2tangogps	Enter a waypoint file into the tangoGPS or FoxtrotGPS
			sqlite database
	geo-circles	Compute the intersection of two circles on the earth
	geo-trilateration Compute the intersection of three circles on the earth
	geo-triangulation Compute the point by two or three bearings
	geo-intersect	Compute the intersection of two line segments
	geo-polygon	Compute the centroid of a polygon
	geo-gccode2id   Convert GC codes to the decimal equivalent
	geo-id2gccode	Convert decimal IDs to GC codes
	geo-loran-c     Brute force solve of Loran-C problems
	geo-project	Project a waypoint
	geo-code	Geocode an address
	geo-dist	Compute distance along a list of waypoints.
	geo-waypoint	Enter a waypoint into the GpsDrive MySQL database
	geo-map		Create a map with waypoints plotted on it
			These CANNOT be used for publication unless the
			selected map source is the tiger, topographic, or
			aerial map server!
	geo-firefox     Display a map of a point using MapQuest aerial photos
	gpx-finders	Output the finders from a GPX file.
	gpx-merge       GPX file merge.
	gpx-photos	Fetch hi-res aerial photos of all caches in a GPX file
	gpx-stats	Compute stats from a GPX file.
	gpx-unfound     Filter a GPX file removing found caches.
	geodetics.html	A modified version of Gary Nicholson's javascript
			Geodetics Calculator.

### Tools for coordinate conversions

	geo-addsub	Add or subtract a value from the coordinates
	geo-coords	Convert lat/lon from one format to another
	geo-incomplete-coords	Print out incomplete coordinates
	ll2maidenhead	Lat/long to Maidenhead (Grid Squares)
	maidenhead2ll	Maidenhead (Grid Squares) to Lat/long
	ll2ggl/ggl2ll	To/From lat/lon to Google Maps QRST string
	ll2osg/osg2ll	To/From lat/lon to British National Grid
	ll2rd/rd2ll	To/From lat/lon to RD (Dutch)
	ll2usng/usng2ll	To/From lat/lon to US National Grid
	ll2utm/utm2ll	To/From lat/lon to UTM
	bing2ll		Bing maps quadkey string to lat/lon
	ll2geohash/geohash2ll	To/From lat/lon to geohash

### Tools for manipulating Mapopolis place guide data

	geo-poi		Search place guide (*.pdb or *.csv) for places
	pgpdb2txt	Convert a place guide to plain text

### Tools for use by the MN Geocaching Association

	mngca		Count caches found/placed by MnGCA members
	mngca-logs	Create web pages of recent area logs from GPX files
	mngca-newmap	Create newest cache maps for Minnesota

### Miscellaneous

	add-pyramids	Add the Pyramids
	adddigits	Add individual digits in a number
	addletters	Add all letters: a=1, b=2, c=3, ... z=26
	anybase2anybase	Base to base conversion to/from base 2 thru 62
	atomic-symbol-to-atomic-number Atomic Symbol to Atomic Number
	atomic-symbol-to-period-or-group Atomic Symbol to Period or Group
	atomic-number-to-text Atomic Number to text
	baconian2text	Convert baconian to text
	geo-bacon	Baconian decoder from HTML font's or b's
	balanced-ternary Convert balanced-ternary to/from decimal
	decimal2cryptogram Anthing to cryptogram
	smilies2cryptogram Geocaching 'smilies' to cryptogram
	lethist		Compute letter histogram.
	braille2text	Braille to text translator
	fibonacci-coding Convert a binary coding to a number
	geo-algebraic-expressions Solve a system of algebraic expressions
	geo-alphametic	Solve a math puzzle in which letters stand for digits
	geo-battleship	Map the geocheck.org battleship locations
	geo-clock-angle	Compute the clock angle or the time
	geo-compare-images Compare two images
	geo-char-at	Pick the char at position "n"
	geo-fax		Decode a FAX using 0s and 1s
	geo-jigsaw-puzzle Solve flash-gear.com Jigsaw Puzzles
	geo-lewis-and-clark Encode/decode Lewis and Clark cipher
	geo-math-functions Do various math functions
	geo-morse	Morse decoder
	geo-phone2word	Convert numerical "phone" to a word(s)
	geo-rotate-text	Rotate text CW, CCW, or flip
	geo-slash-backslash Decrypt slashes and backslashes a.k.a Tomtom code
	geo-slash-pipe	Decrypt slash and pipe code
	geo-sub		Do a substitution (caesar) cipher for all shifts
	geo-excel2qrcode Excel to binary or QR barcode converter
	geo-text2qrcode	ASCII text to QR barcode converter
	geo-text2numbers grep for numbers in text
	geo-thumbnails	Recursively extract image thumbnails
	geo-timed-cache Timed cache password fetcher
	geo-wordsearch  Perform a Word Search
	geo-zipcode	Translate zip code to city and state
        mayan-long-count Mayan long count
        navaho-code-talkers Translate Navaho into English
	negadecimal	Convert to/from negabinary, negadecimal
	radio-orphan-annie Radio Orphan Annie’s Decoder Ring
	reverse-montage	reverse (split up) montage image
	segment2text	N-Segment Display to text
	spiritdvd2text	Spirit DVD Code to/from text
	stickman2text	Stickman to text
	tap-code	Tap Code or Polybius Square decoder

### Wherigo

	reverse-wherigo Reverse Wherigo decoder
	urwigo-decode	urwigo and earwigo decoder
	wherigo2jpg	Pull jpg images out of a wherigo file
	wherigo2lua	De-compile wherigo
	zonepoint2map	Convert Wherigo ZonePoint's to geo-map coords

### Nonograms

Need to get nonogram solvers from an offsite place!
	geo-nonogram	Nonogram solver
	nono2teal	Convert .nono to teal format
	nono2cross+a	Convert .nono to monochrome cross+a format
	nono2jsolver	Convert .nono to jsolver format
	pbnsolve-wrapper Wrapper for .non format nonograms

## Installation/Removal

### Install

Download and extract the archive https://github.com/GarenKreiz/geo-rkkda/archive/refs/heads/main.zip

In the newly created directory

#### Compile

```bash
make
```
#### Install

```bash
make install			# to install in $HOME/bin
```
or
```bash
su OR sudo sh
PREFIX=/usr make install	# to install in /usr/bin
make install-man
```

#### Configure

Create a $HOME/.georc file with at least these lines in it:

```
PASSWORD="your-gc.com-password"
USERNAME="your-gc.com-username"
LAT=44.497250	# Your home latitude in decimal degrees
LON=-93.941033	# Your home longitude in decimal degrees
```

### Uninstall

If you don't like or don't use geo-*

```bash
make uninstall			# to uninstall in $HOME/bin
```
or
```bash
su OR sudo sh
PREFIX=/usr make uninstall	# to uninstall in /usr/bin...
make uninstall-man
```

### GPSBABEL

Use the latest gpsbabel (1.5.4+):

    git clone https://github.com/gpsbabel/gpsbabel.git
    cd gpsbabel
    ./configure --prefix=/usr
    make
    make install

### MAC OSX SUPPORT

First, download and install MacPorts from http://www.macports.org/

    PATH=$PATH:/opt/local/bin
    sudo port selfupdate
    sudo port install gsed
    sudo port install coreutils
    sudo port install lynx
    sudo port install ImageMagick
    sudo port install gawk
    sudo port install ghostscript
    sudo port install dos2unix
    sudo port install p5-xml-twig
    sudo port install p5-datetime
    sudo port install p5-html-parser

Download and install gpsbabel from http://www.gpsbabel.org/

    wget http://www.linklevel.net/distfiles/gpsbabel-1.5.4.tar.gz
    tar zxf gpsbabel-1.5.4.tar.gz
    cd gpsbabel-1.5.4
    ./configure
    make
    sudo make install

If you get "configure: error: *** A compiler with support for C++11
language features is required.", then drop back and use:

    wget http://www.linklevel.net/distfiles/gpsbabel-1.4.4.tar.gz

### CYGWIN SUPPORT

Install CygWin as per: http://www.cygwin.com.  For the easiest (but
longer) install experience, just install everything.  If you choose
to install a subset, you will need to install the base package plus
these other packages (this list might be incomplete):

    ImageMagick     bash                bc              binutils
    cpio            curl                curl-devel      dos2unix
    gawk            gcc                 ghostscript     grep
    libQt5Core      libQt5Core-devel    lynx            make
    sh-utils        sharutils           wget            expat
    units

Download and install gpsbabel:

    wget http://www.linklevel.net/distfiles/gpsbabel-1.5.4.tar.gz
    tar zxf gpsbabel-*.tar.gz
    cd gpsbabel-1.5.4
    ./configure --without-libusb
    make
    make install

### FREEBSD SUPPORT

Install with "pkg install":

    coreutils (gives gtouch and gdate, and more)
    gawk
    gmake
    gpsbabel
    gsed
    unix2dos

and:

    su
    ln -s /usr/local/bin/bash /bin/bash

Then follow the Linux instructions but use "gmake" instead of "make".

## Questions and support

You can report bug or ask for support by creating issues on Github https://github.com/GarenKreiz/geo-rkkda/issues

## Source code

The Github repository https://github.com/GarenKreiz/geo-rkkda was initialised with the lastest release by Rick Richardson. I, Garenkreiz, only tested and used a minimal subsets of the tools for www.geocaching.com and can't maintain the tools I don't use. Any help is thus welcome, feel free to propose patches or pull requests.

