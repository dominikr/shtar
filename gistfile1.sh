#!/bin/sh
#
#this version should work with a SVR2 bourne shell or later,
# or any POSIX compliant shell
#
#used tools:
# required: dd, echo, dc
# optional:
#  mkdir: will not be able to extract tar files with directories
#  chmod: file mode will not be set
#
# high level requirements:
# - tool to carve from tar, binary-safe (dd)
# - tool to convert from octal to decimal
# - tool to add numbers
#
# things which are NOT used:
#  * test/[
#  * /dev/null
#  * /tmp
#  * if
#  * 
#todo: 
# -try to use bc if dc doesn't exist
# -try to use printf if dc does not support radix conversion (busybox)
# -use dc.sed? Works!
# -get rid of echo
# -use expr if using printf for oct conversion?
# -use POSIX shell arithmetic/octal conversion?
#

# Candidates:
# posix math
# dc
# bc
# expr
# awk?
# sed?
add(){
	echo "$1 $2 + p" | dc
}

incr(){
	add $1 1
}

# Candidates:
# posix math
# dc
# bc
# printf
# command printf
# awk?
# sed?
oct2dec(){
	echo "8 i ${1} p" | dc
}

# Candidates:
# nothing beats dd here
# maybe nawk or perl...
carve(){
	dd if="${FILE}" count=1 skip=$num 2>&- | dd bs=1 skip=$1 count=$2 2>&-
	#dd if="${FILE}" count=1 skip=$num | dd bs=1 skip=$1 count=$2
}


output() {

	case $fullblock in
	00000000) 
		: 'do nothing'
		;;
	*)
		blocks=`oct2dec $fullblock`
		dd if=${FILE} count=$blocks skip=$num of=$name 2>&-
		num=`add $num $blocks`
		;;
	esac

	case $restblock in
	000)
		: 'do nothing'
		;;
	*)
		rest=`oct2dec $restblock`
		carve 0 $rest >> $name
		num=`incr $num`
		;;
	esac

	# zero-length files
	: >> $name

}

#set -e
#. /usr/lib/pab3/errdash.sh || exit 3
FILE=$1
num=0

while :; do
	
	name=`carve 0 99`
	type=`carve 156 1`
	mode=`carve 103 4`
	fullblock=`carve 124 8`
	restblock=`carve 132 3`

	echo "$num $name $type $mode $g $fullblock $restblock"

	case $name in
	'')
		echo "EOF"
		exit 0
		;;
	esac

	num=`incr $num`
	case $type in
		0|7)
			output;;
		5)
			mkdir $name 2>&- ;;
		*)
			echo "ERROR: unknown type $type, trying to extract anyway"
			output
			;;
	esac

	chmod $mode $name

done
