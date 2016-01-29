#!/usr/bin/env bash

# do various re-mappings, etc., to try to make tiny Panasonic CF-R5
# usable as a laptop.

# without any parameters, set it up

# with --cleanup, remove temporary directory

# with --force, reset, e.g., xrdb ('-load' rather than '-merge') and
# setxkbmap ('-option ""'), rather than add to options.

# getopt processing.  see
# /usr/share/doc/util-linux/examples/getopt-parse.bash

name=$0

usage() { echo "usage: $name [--cleanup] [--force] [--dir dirname]" >&2; exit 1; }

TEMP=`getopt -n "$name" -o "" --long cleanup,force,dir: -- "$@"`

if [ $? != 0 ] ; then usage; fi # usage() does NOT return

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

cleanup=0
force=0
dir=/var/tmp/${USER}/${name}

while true ; do
    case "$1" in
	--cleanup) cleanup=1; shift ;;
	--force) force=1; shift ;;
	--dir) dir=$2; shift 2 ;;
	--) shift ; break ;;
	*) echo "Internal error!" ; exit 1 ;;
    esac
done
echo cleanup $cleanup, force $force, dir $dir

if [ $# != 0 ]; then echo extraneous arguments on command line >&2; usage; fi


