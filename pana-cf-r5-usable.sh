#!/usr/bin/env bash

# do various re-mappings, etc., to try to make tiny Panasonic CF-R5
# usable as a laptop.

# without any parameters, set it up

# with --cleanup, remove temporary directory

# with --force, reset, e.g., xrdb ('-load' rather than '-merge') and
# setxkbmap ('-option ""'), rather than add to options.

# getopt processing.  see
# /usr/share/doc/util-linux/examples/getopt-parse.bash

TEMP=`getopt -o ab:c:: --long a-long,b-long:,c-long:: \
     -n 'example.bash' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
	case "$1" in
		-a|--a-long) echo "Option a" ; shift ;;
		-b|--b-long) echo "Option b, argument \`$2'" ; shift 2 ;;
		-c|--c-long) 
			# c has an optional argument. As we are in quoted mode,
			# an empty parameter will be generated if its optional
			# argument is not found.
			case "$2" in
				"") echo "Option c, no argument"; shift 2 ;;
				*)  echo "Option c, argument \`$2'" ; shift 2 ;;
			esac ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done
echo "Remaining arguments:"
for arg do echo '--> '"\`$arg'" ; done


