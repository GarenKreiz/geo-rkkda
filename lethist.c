#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <ctype.h>

/*
 * Global option flags
 */
int	Debug = 0;
int	Hist[256];

void
debug(int level, char *fmt, ...)
{
	va_list ap;

	if (Debug < level)
		return;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
}

int
error(int fatal, char *fmt, ...)
{
	va_list ap;

	fprintf(stderr, fatal ? "Error: " : "Warning: ");
	if (errno)
	    fprintf(stderr, "%s: ", strerror(errno));
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	if (fatal > 0)
	    exit(fatal);
	else
	{
	    errno = 0;
	    return (fatal);
	}
}

void
usage(void)
{
	fprintf(stderr,
"NAME\n"
"	lethist - Letter histogram\n"
"\n"
"SYNOPSIS\n"
"	lethist [options] [words] ...\n"
"\n"
"DESCRIPTION\n"
"	Letter histogram from <stdin> or from 'words'.\n"
"\n"
"EXAMPLE\n"
"	Letter histogram:\n"
"\n"
"	 $ lethist | sort -k2 -n -r\n"
"	 1 5 - 8 ) ) W 5 - ( + ) ) ; 4 8 W 5 ; 8 ( * + ; 8 ; W + 0 5 ( 3 8 9\n"
"	 ? 0 ; 6 ; ( ? * K 8 ! ; ( 8 8 ) W 6 ; 4 5 1 5 0 0 8 * + * 8 6 * 2 8\n"
"	 ; W 8 8 * ; 4 8 ! 8 5 ; 4 ) 4 8 5 ! 6 ) 6 * ; 4 8 9 6 ! ! 0 8 + 1 ;\n"
"	 4 8 ; + . 0 6 9 2 + 1 ; 4 8 1 5 0 0 8 * ; ( 8 8 3 + ; 4 8 ( 8 1 ( +\n"
"	 9 ; 4 8 ! 8 5 ; 4 ) 4 8 5 ! ) 4 + + ; 5 2 8 8 0 6 * 8 ; 4 6 ( ; : 1\n"
"	 8 8 ; + ? ; ; + ; 4 8 ) + ? ; 4.\n"
"\n"
"	 $ lethist \"Cottonwood trees are, perhaps, the best shade trees\"\n"
"	 ,       2\n"
"	 C       1\n"
"	 a       3\n"
"	 b       1\n"
"	 d       2\n"
"	 e       9\n"
"	 h       3\n"
"	 n       1\n"
"	 o       4\n"
"	 p       2\n"
"	 r       4\n"
"	 s       5\n"
"	 t       6\n"
"	 w       1\n"
"\n"
"OPTIONS\n"
"       -t          Print total\n"
"       -D lvl      Set Debug level [%d]\n"
"\n"
"SEE ALSO\n"
"       addletters(1)\n"
	, Debug
	);

	exit(1);
}

int DoTotal = 0;

int
main(int argc, char *argv[])
{
	#ifndef __CYGWIN__
	    extern int	optind;
	    extern char	*optarg;
	#endif
	int		c, i, j, total;
	int		unicode = 0;

	while ( (c = getopt(argc, argv, "tD:?h")) != EOF)
		switch (c)
		{
		case 't':
			DoTotal = 1;
			break;
		case 'D':
			Debug = atoi(optarg);
			break;
		default:
			usage();
			exit(1);
		}

	argc -= optind;
	argv += optind;

	if (argc == 0)
	{
	    // Compute histogram
	    while ((c = getchar()) != EOF)
	    {
		if (unicode == 0 && c == 0xC3)
		{
		    unicode = 1;
		    continue;
		}
		if (unicode == 1)
		{
		    unicode = 0;
		    switch (c)
		    {
		    // lowercase `
		    case 0xA0: case 0xA8: case 0xAC: case 0xB2: case 0xB9:
		    // uppercase `
		    case 0x80: case 0x88: case 0x8C: case 0x92: case 0x99:
		    // lowercase '
		    case 0xA1: case 0xA9: case 0xAD:
		    case 0xB3: case 0xBA: case 0xBD:
		    // uppercase '
		    case 0x81: case 0x89: case 0x8D:
		    case 0x93: case 0x9A: case 0x9D:
		    // lowercase ^
		    case 0xA2: case 0xAA: case 0xAE: case 0xB4: case 0xBB:
		    // uppercase ^
		    case 0x82: case 0x8A: case 0x8E: case 0x94: case 0x9B:
		    // lowercase ~
		    case 0xA3: case 0xB1: case 0xB5:
		    // uppercase ~
		    case 0x83: case 0x91: case 0x95:
		    // lowercase :
		    case 0xA4: case 0xAB: case 0xAF:
		    case 0xB6: case 0xBC: case 0xBF:
		    // uppercase :
		    case 0x84: case 0x8B: case 0x8F:
		    case 0x96: case 0x9C: /* case 0xB8: */
		    // o
		    case 0xA5: case 0x85:
		    // ae AE
		    case 0xA6: case 0x86:
		    // c, C,
		    case 0xA7: case 0x87:
		    // o. D-
		    case 0xB0: case 0x90:
		    // o/ O/
		    case 0xB8: case 0x98:
		    // ss
		    case 0x9F:
			break;
		    default:
			continue;
		    }
		}
		else if (!isprint(c)) continue;
		if (c == ' ') continue;
		++Hist[c];
	    }
	}
	else
	{
	    for (i = 0; i < argc; ++i)
	    {
		for (j = 0; (c = argv[i][j]); ++j)
		{
		    c &= 0xff;
		    if (unicode == 0 && c == 0xC3)
		    {
			unicode = 1;
			continue;
		    }
		    if (unicode == 1)
		    {
			unicode = 0;
			switch (c)
			{
			case 0xA0: case 0xA8: case 0xAC: case 0xB2: case 0xB9:
			case 0x80: case 0x88: case 0x8C: case 0x92: case 0x99:
			case 0xA1: case 0xA9: case 0xAD:
			case 0xB3: case 0xBA: case 0xBD:
			case 0x81: case 0x89: case 0x8D:
			case 0x93: case 0x9A: case 0x9D:
			case 0xA2: case 0xAA: case 0xAE: case 0xB4: case 0xBB:
			case 0x82: case 0x8A: case 0x8E: case 0x94: case 0x9B:
			case 0xA3: case 0xB1: case 0xB5:
			case 0x83: case 0x91: case 0x95:
			case 0xA4: case 0xAB: case 0xAF:
			case 0xB6: case 0xBC: case 0xBF:
			case 0x84: case 0x8B: case 0x8F:
			case 0x96: case 0x9C: /* case 0xB8: */
			case 0xA5: case 0x85:
			case 0xA6: case 0x86:
			case 0xA7: case 0x87:
			case 0xB0: case 0x90:
			case 0xB8: case 0x98:
			case 0x9F:
			    break;
			default:
			    continue;
			}
		    }
		    else if (!isprint(c)) continue;
		    if (c == ' ') continue;
		    ++Hist[c];
		}
	    }
	}

	// Print it out
	total = 0;
	for (i = 0; i < 256; ++i)
	{
	    if (Hist[i] == 0) continue;
	    switch (i)
	    {
		case 0xA0: case 0xA8: case 0xAC: case 0xB2: case 0xB9:
		case 0x80: case 0x88: case 0x8C: case 0x92: case 0x99:
		case 0xA1: case 0xA9: case 0xAD:
		case 0xB3: case 0xBA: case 0xBD:
		case 0x81: case 0x89: case 0x8D:
		case 0x93: case 0x9A: case 0x9D:
		case 0xA2: case 0xAA: case 0xAE: case 0xB4: case 0xBB:
		case 0x82: case 0x8A: case 0x8E: case 0x94: case 0x9B:
		case 0xA3: case 0xB1: case 0xB5:
		case 0x83: case 0x91: case 0x95:
		case 0xA4: case 0xAB: case 0xAF:
		case 0xB6: case 0xBC: case 0xBF:
		case 0x84: case 0x8B: case 0x8F:
		case 0x96: case 0x9C: /* case 0xB8: */
		case 0xA5: case 0x85:
		case 0xA6: case 0x86:
		case 0xA7: case 0x87:
		case 0xB0: case 0x90:
		case 0xB8: case 0x98:
		case 0x9F:
		    printf("%c%c	%d\n", 0xC3, i, Hist[i]);
		    break;
		default:
		    printf("%c	%d\n", i, Hist[i]);
		    break;
	    }
	    total += Hist[i];
	}
	if (DoTotal)
	    printf("TOTAL	%d\n", total);

	exit(0);
}
