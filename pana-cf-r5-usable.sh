#!/usr/bin/env bash

# do various re-mappings, etc., to try to make tiny Panasonic CF-R5
# usable as a laptop.

# without any parameters, set it up

# with --cleanup, remove temporary directory

# with --force, reset, e.g., xrdb ('-load' rather than '-merge') and
# setxkbmap ('-option ""'), rather than add to options.

# getopt processing.  see
# /usr/share/doc/util-linux/examples/getopt-parse.bash

ensure() { mkdir -p ${dir}; }

cleanup() { echo "XXX implement cleanup!!"; }

execute() {
    # now, generate all the files, execute all the commands

    # Xresources
    cat > ${dir}/Xresources <<EOF
! make M-b, et al., work
XTerm*metaSendsEscape: true
! in xterm (and friends), make C-S-c copy, and C-S-v paste
*VT100*translations:    #override \n\\
    Shift Ctrl <KeyPress> c: copy-selection(PRIMARY, CLIPBOARD) \n\\
    Shift Ctrl <KeyPress> v: insert-selection(PRIMARY, CLIPBOARD)
EOF
    if [ $force == 0 ]; then
	xrdbparm=merge;
    else
	xrdbparm=load
    fi
    ${setup} xrdb -${xrdbparm} ${dir}/Xresources

    # setxkbmap
    mkdir -p ${dir}/xkb
    mkdir -p ${dir}/xkb/rules
    mkdir -p ${dir}/xkb/symbols
    cp -f ${xkb}/rules/evdev ${dir}/xkb/rules/hybrid-evdev
    cp -f ${xkb}/rules/evdev.lst ${dir}/xkb/rules/hybrid-evdev.lst
    cat >> ${dir}/xkb/rules/hybrid-evdev <<EOF

! option			=	symbols
  japan:muhenkan_meta		=	+my-jp(muhenkan_meta)
  japan:henkan_meta		=	+my-jp(henkan_meta)
  japan:hiragana-katakana_alt	=	+my-jp(hiragana-katakana_alt)
EOF
    cat >> ${dir}/xkb/rules/hybrid-evdev.lst <<EOF
! option
japan:muhenkan_meta		Muhenkan as Meta_L
japan:henkan_meta		Henkan as Meta_R
japan:hiragana_katakana_alt	Hiragana-Katakana as Alt_R
EOF
    cat > ${dir}/xkb/symbols/my-jp <<EOF
// Make the Muhenkan key a left Meta.
partial modifier_keys
xkb_symbols "muhenkan_meta" {
    replace key <MUHE>	{ [ Meta_L ] };
};

// Make the Muhenkan key a right Meta.
partial modifier_keys
xkb_symbols "henkan_meta" {
    replace key <HENK>	{ [ Meta_R ] };
};

// Make the Hiragana-Katakana key a right Alt.
partial modifier_keys
xkb_symbols "hiragana-katakana_alt" {
    replace key <HKTG>	{ [ Alt_R ] };
};
EOF
    if [ $force == 0 ]; then
	clear='';
    else
	clear='-option ""';
    fi
    if [ $verbose == 0 ]; then
	warnings="";
    else
	warnings="-w 10"
    fi
    # http://stackoverflow.com/a/12797512 for backtick comment trick
    eval ${setup} setxkbmap -I ${dir}/xkb -rules hybrid-evdev ${clear} \
	-option ctrl:nocaps	`# make capslock an extra control key` \
	`# map Japanese-specific keys to meta, alt` \
    	-option japan:henkan_meta -option japan:muhenkan_meta -option japan:hiragana-katakana_alt \
	-option japan:hztg_escape `# make zenkaku-hankaku an extra escape` \
	-option altwin:alt_win `# make win key an extra alt` \
	-print ${setuppipe} xkbcomp -I${dir}/xkb ${warnings} - $DISPLAY

    # xmodmap
    # make Delete key act like BackSpace.
    ${setup} xmodmap -e "keysym Delete = BackSpace"
    if [ $? != 0 ]; then
	echo "note that \"xmodmap -e ...\" is *not* idempotent, so second+ invocations may result in an error"
	# actually, errors *don't* get generated, probably because
	# above xbcomp resets things nicely
    fi

    # synclient (to get rid of annoying trackpad clicks)
    ${setup} synclient TapButton1=0

    # try to get emacs/readline keybindings for firefox
    # (need to restart firefox *after* this!)
    gtkrc=~/.gtkrc-2.0
    if [ ! -e ~/${gtkrc} ]; then
	touch ${gtkrc}
    fi
    if ! grep -q gtk-key-theme-name ${gtkrc}; then
	cat >> ${gtkrc} <<EOF

gtk-key-theme-name = "Emacs"
EOF
    fi

    # get mac-like vertical scrolling (if requested)
    if [ $notmaclike == 0 ]; then
	macminus="-"		# make vertical scrolling mac-like
    else
	macminus=""		# make vertical scrolling un-mac-like
    fi
    ${setup} synclient VertScrollDelta=${macminus}`synclient | grep VertScrollDelta | sed s/-//g | awk '{print $3}'`
}

name=$0

usage() { echo "usage: $name [--cleanup] [--force] [--notmaclike] [--setup] [--verbose] [--dir dirname] [--xkb dirname]" >&2; exit 1; }

TEMP=`getopt -n "$name" -o "" --long cleanup,force,notmaclike,setup,verbose,dir:,xkb: -- "$@"`

if [ $? != 0 ] ; then usage; fi # usage() does NOT return

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

cleanup=0
dir=/var/tmp/${USER}/${name}
force=0
notmaclike=0
setup=""
setuppipe='|'
verbose=0
xkb=/usr/share/X11/xkb

while true ; do
    case "$1" in
	--cleanup) cleanup=1; shift ;;
	--dir) dir=$2; shift 2 ;;
	--force) force=1; shift ;;
	--notmaclike) notmaclike=1; shift ;;
	--setup) setup=echo; setuppipe='\|'; shift ;; # echo commands rather than executing them
	--verbose) verbose=1; shift ;;
	--xkb) xkb=$2; shift 2 ;;
	--) shift ; break ;;
	*) echo "Internal error!" ; exit 1 ;;
    esac
done

# make sure we have our target directory
ensure $dir

execute

# cleanup if necessary
if [ $cleanup != 0 ]; then cleanup; fi

if [ $# != 0 ]; then echo extraneous arguments on command line >&2; usage; fi
