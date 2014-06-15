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
	shift
	shift
	shift

	for i
	do
		case `set -- $in; eval $i 2>&-` in
		"$out")
			#echo $i
			eval "$name(){ $i; }"
			return
			;;
		esac
	done
	#echo "Can not create $name(): no valid function body found"
	echo "$name failed"
	exit 1
}

genfunc say '-e a\tb' '-e a\tb' \
	'print -r -- "$*"' \
	'echo "$*"' \
	'printf "%s\n" "$*"' \
	'/bin/echo "$*"' \

genfunc oct2dec 11 9 \
	'say $((0$1))' \
	'say $((8#$1))' \
	'printf "%d\n" 0$1' \
	'say "8i${1}p" | dc' \
	'say "ibase=8; $1" | bc' \
	'command printf "%d\n" 0$1' \
	'awk "BEGIN{ print 0$1; exit }"' \
	'gawk "BEGIN{ print 0$1; exit }"' \
	'perl -e "print oct $1"'

genfunc add '1 1' 2 \
	'say $(( $1 + $2 ))' \
	'expr $1 + $2' \
	'say "$1 $2 + p" | dc' \
	'say "$1 + $2" | bc' \
	'awk "BEGIN{ print $1 + $2; exit }"' \
	'perl -e "print $1 + $2"'

# Candidates:
# nothing beats dd here
# maybe nawk or perl...
carve(){
	dd if="${FILE}" count=1 skip=$num 2>&-| dd bs=1 skip=$1 count=$2 2>&-
	#dd if="${FILE}" count=1 skip=$num | dd bs=1 skip=$1 count=$2
}

inc(){
	num=`add $num 1`
}

output(){

	inc
	case $fullblock in
	00000000) 
		:
		;;
	*)
		blocks=`oct2dec $fullblock`
		dd if=${FILE} count=$blocks skip=$num of=$name 2>&-
		num=`add $num $blocks`
		;;
	esac

	case $restblock in
	000)
		:
		;;
	*)
		rest=`oct2dec $restblock`
		carve 0 $rest >> $name
		inc
		;;
	esac

	# zero-length files
	:>>$name

}

#set -e
#. /usr/lib/pab3/errdash.sh || exit 3
FILE=$1
num=0

while :
do
	
	name=`carve 0 99`

	case $name in
	'')
		say EOF
		exit 0
		;;
	esac

	type=`carve 156 1`
	mode=`carve 103 4`
	uid=`carve 265 32`
	gid=`carve 297 32`

	case $type in
		1)
			link=`carve 157 99`
			inc
			ln "$link" "$name"
			;;
		2)
			link=`carve 157 99`
			inc
			ln -s "$link" "$name"
			;;
		3)
			maj=`carve 329 8`
			min=`carve 337 8`
			inc
			mknod "$name" c "$maj" "$min"
			;;
		4)
			maj=`carve 329 8`
			min=`carve 337 8`
			inc
			mknod "$name" b "$maj" "$min"
			;;
		5)
			inc
			mkdir "$name" 2>&-
			;;
		6)
			inc
			mknod "$name" p || mkfifo "$name"
			;;
		*)
			fullblock=`carve 124 8`
			restblock=`carve 132 3`
			output
			;;
	esac

	say $num $name $uid:$gid $type $mode $fullblock $restblock
	chmod $mode $name 2>&-
	chown $uid:$gid $name

done
