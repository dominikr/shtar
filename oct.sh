
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
	'command printf "%d\n" 0$1' \
	'awk "BEGIN{ printf "%d\n" 0$1 }"' \

oct2dec 11

genfunc add '1 1' 2 \
	'echo $(( $1 + $2 ))' \
	'expr $1 + $2' \
	'echo "$1 $2 + p" | dc' \
	'awk "BEGIN{ print $1 + $2 }"'

add 2 3
