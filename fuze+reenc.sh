#!/bin/bash
# andyw 20110625
# automatically convert flac files to lame -v2 mp3s.
# Auto-add tags and embedded album art.

# andyw 201607XX - detect cores, run several parallel instances based on count
# cater for almost all sane filenames - IFS is newline

#Usage is $0 a.flac dir_of_flacs more_flacs /output/directory

TMPDIR=/dev/shm
ERRLOG=$TMPDIR/fuze.err.log

function get_tags() {
	#echo $1
	TMP=`mktemp -p /dev/shm`
	flacinfo "$@" >$TMP
	ARTIST=`grep -i 'TAG| Artist:' $TMP | cut -d' ' -f 3-1000`
	TITLE=`grep -i 'TAG| Title:' $TMP | cut -d' ' -f 3-1000`
	ALBUM=`grep -i 'TAG| Album:' $TMP | cut -d' ' -f 3-1000`
	YEAR=`grep -i 'TAG| Date:' $TMP | cut -d' ' -f 3-1000`
	COMMENT=`grep -i 'TAG| Comment:' $TMP | cut -d' ' -f 3-1000`
	TRACKNUMBER=`grep -i 'TAG| Tracknumber:' $TMP | cut -d' ' -f 3-1000`
	rm $TMP
}

function cores() {
	CORES=$(grep -c processor /proc/cpuinfo)
}

function kidcount() {
	ME=$1
	PROCS=$(pgrep -d, -P $ME )
	PROCC=$(pgrep  -c -P $ME)
}

function sched() {
	local TARGET="$1"
	local file="$2"
	kidcount $$
	echo -n "Parent $$ waiting for a free core ($PROCC/$CORES); jobs $PROCS"
	while test $PROCC -eq $CORES; do
			echo -n '.'
			sleep 0.5
			kidcount $$
	done
	echo ""
	echo "Ready; Calling $0 flactomp3 $TARGET $file"
	$0 flactomp3 "$TARGET" "$file"&
}

function targname() {
		TARGET="$1"
		file="$2"
		mp3=`basename "$file" .flac`.mp3
		outdir=`dirname "$file"`
		outmp3="$TARGET/$outdir/$mp3"
}

function flactomp3() {
		targname "$1" "$2"
		tmpmp3="$TMPDIR/tmp.$$.$mp3"
		tmppic=$TMPDIR/a.$$.jpg
		echo "I am kid $$, encoding $file to temp $tmpmp3 (pic $tmppic) -> $TARGET/$outdir/$mp3"
		if [ ! -e "$TARGET/$outdir/$mp3" ]; then
			if [ ! -d "$TARGET/$outdir" ]; then
				mkdir -p "$TARGET/$outdir"
			fi
			get_tags "$file"
			/usr/bin/flac -dc "$file" 2>>$ERRLOG | /usr/bin/lame -V2 --tt "$TITLE" --ta "$ARTIST" --ty "$YEAR" --tc "$COMMENT" --tl "$ALBUM" --tn "$TRACKNUMBER" - "$tmpmp3" 2>>$ERRLOG
			metaflac --export-picture-to=$tmppic "$file"
			if [ $? -ne 0 ]; then
				echo "I only work with files with pictures now"
				#exit 1
			fi
			if [ -f $tmppic ]; then
				convert $tmppic -interlace none $tmppic.TMP && mv $tmppic.TMP $tmppic
				eyeD3 --add-image=$tmppic:FRONT_COVER:cover "$tmpmp3"
				rm $tmppic
			fi
			mv "$tmpmp3" "$TARGET/$outdir/$mp3"
		fi
		echo "kid $$ produced $TARGET/$outdir/$mp3 - signing off"
}


if [ "x$1" == "xflactomp3" ]; then
	flactomp3 "$2" "$3"
	exit
fi

TARGET="${!#}"
length=$(($#-1))
FILES="${@:1:$length}" 

cores

files=$(find $FILES -type f -name '*.flac')
filec=$(echo "$files" |wc -l)
filet=$filec
if [ "x$files" = "x" ]; then
	echo "$filespec found nothing"
	exit 1
fi
IFS=$'\n'
for file in $files; do 
	kidcount $$
	echo "I am parent $ME; $PROCC workers ($filec/$filet to enqueue)"
	targname "$TARGET" "$file"
	if [ ! -e "$outmp3" ]; then
		sched "$TARGET" "$file"
	else
		FLACT=$(stat -c %Y $file)
		MP3T=$(stat -c %Y $outmp3)
		if [ $FLACT -gt $MP3T ]; then
			echo "$file has been updated; refreshing"
			rm $outmp3
			sched "$TARGET" "$file"
		else
			echo "$outmp3 already exists and is current"
		fi
	fi
	filec=$(( $filec - 1 ))
done
echo "Waiting for all workers to complete."
wait
