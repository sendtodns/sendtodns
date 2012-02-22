#!/bin/bash
#
# Usage: getfile.sh filecode
# 
# This example downloads the Elephants Dream video
# 
# Example: getfile e8fkiy
# 

function nameserver {
	echo $NSLIST | cut -d\, -f `expr \( $RANDOM % 1 \) + 1`
}

function prereq {
	EXISTS=`which $1; echo $?`
	if [ "$EXISTS" == "1" ]; then
		echo "Please install $1"
		exit 1
	fi
}

function getfile {
	for (( i=0;i<$ENDPART + 1;i++)); do
		dig @$(nameserver) TXT +short +vc $i.$1.$PART.sendtodns.org >> $1.unparsed.$PART
	done	
}

function parsefile {
	cat $1.unparsed.$PART | cut -d\" -f 2- | sed -e 's/" "/\'$'\n/g' | sed -E 's/^[0-9]+ //g' | sed 's/\"$//g' > $1.get.$PART
}

function die {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument (the file key) is required, $# provided"

NSLIST="ns1.sendtodns.org"
FILENAME=`dig @$(nameserver) TXT +short +vc fileid.$1.sendtodns.org | cut -d\, -f 1 | sed 's/^"//'`
MD5=`dig @$(nameserver) TXT +short +vc fileid.$1.sendtodns.org | cut -d\, -f 4 | sed 's/"$//'`
END=`dig @$(nameserver) TXT +short +vc fileid.$1.sendtodns.org | cut -d\, -f3 | cut -d\. -f2 | sed s/^0//`
BATCHSIZE="15.0" # Must be a float in a string
prereq lxsplit
prereq uudecode
prereq dig
prereq cut
prereq sed
prereq bc
prereq md5sum


echo "Getting $FILENAME with $END parts."

for (( x=1;x<$END + 1;x++)); do
	WAIT="`echo "scale=2; $x / $BATCHSIZE" | bc`"
	WAITMOD="`echo "scale=0; $WAIT % 1" | bc`"	
	PART=`printf %03d $x`
	ENDPART=`dig @$(nameserver) TXT +short +vc fileid.$1.$PART.sendtodns.org | cut -d\, -f2`
	
	echo "Getting $1.$PART"
	getfile $1 &
	
	if [ "$WAITMOD" == "0" ]; then
		echo "Settling processes."
		wait
	fi
	

done

wait

for (( x=1;x<$END + 1;x++)); do
	PART=`printf %03d $x`
	parsefile $1 $PART
done

echo "Decoding files."
uudecode *get*
echo "Joining files."
lxsplit -j $1.001 > /dev/null
mv $1 $FILENAME

DOWNLOADMD5=`md5sum $FILENAME | awk '{print $1}'`

if [ "$DOWNLOADMD5" == "$MD5" ]; then
	echo "MD5 sum of downloaded file is correct."
	rm $1.*	
else
	echo "MD5 sum of downloaded file did not match.  Leaving downloaded parts."
fi


