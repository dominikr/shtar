#s2p 's/^[ \t]*//; /^#/d; /^$/d; s/[ \t]*$//'
#exit
sed 's/^[ \t]*//;/^#/d;/^$/d;s/[ \t]*$//' $1 | perl minify.pl > o.sh

cat o.sh
echo
bash -n o.sh
echo
ls -l $1 o.sh
