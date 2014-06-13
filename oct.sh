
ff(){
	name=$1
	in=$2
	out=$3
	shift; shift; shift

	for i
	do
		a=`set $in; eval $i 2>&-`
		case $a in
			$out)
				echo $i
				eval "$name(){ $i; }"
				break
				;;
		esac
	done
}


ff oct2dec 11 9 \
	'echo $((0$1))' \
	'echo $((8#$1))' \
	'printf "%d\n" 0$1' \
	'echo "8i${1}p" | dc' \
	'command printf "%d\n" 0$1'

oct2dec 12

exit
for i in \
	'echo $((0$1))' \
	'echo $((8#$1))' \
	'printf "%d\n" 0$1' \
	'echo "8i${1}p" | dc' \
	'command printf "%d\n" 0$1'
do
	a=`eval $i 2>&-`
	case $a in
		9)
			echo $i
			eval 'oct2dec(){ '$i'; }'
			break
			;;
	esac
done



