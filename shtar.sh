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
#  - test/[
#  - /dev/null
#  - /tmp
#  - if

genfunc(){
	name=$1
	in=$2
	out=$3
	shift; shift; shift

	for i
	do
		case `set $in; eval $i 2>&-` in
		$out)
			#echo $i
			eval "$name(){ $i; }"
			return
			;;
		esac
	done
	echo "Can not create $name(): no valid function body found"
	exit 1
}

genfunc oct2dec 11 9 \
	'echo $((0$1))' \
	'echo $((8#$1))' \
	'printf "%d\n" 0$1' \
	'echo "8i${1}p" | dc' \
	'echo "ibase=8; $1" | bc' \
	'command printf "%d\n" 0$1' \
	'awk "BEGIN{ print 0$1; exit }"' \
	'gawk "BEGIN{ print 0$1; exit }"' \
	'perl -e "print oct $1"'

genfunc add '1 1' 2 \
	'echo $(( $1 + $2 ))' \
	'expr $1 + $2' \
	'echo "$1 $2 + p" | dc' \
	'echo "$1 + $2" | bc' \
	'awk "BEGIN{ print $1 + $2; exit }"' \
	'perl -e "print $1 + $2"'

inc(){
	add $1 1
}

# Candidates:
# nothing beats dd here
# maybe nawk or perl...
carve(){
	dd if="${FILE}" count=1 skip=$num 2>&- | dd bs=1 skip=$1 count=$2 2>&-
	#dd if="${FILE}" count=1 skip=$num | dd bs=1 skip=$1 count=$2
}


output(){

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
		num=`inc $num`
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

	echo "$num $name $type $mode $fullblock $restblock"

	case $name in
	'')
		echo "EOF"
		exit 0
		;;
	esac

	num=`inc $num`
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
