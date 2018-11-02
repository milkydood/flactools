#!/bin/bash
TMP=$(mktemp)

# Just a small script to extract images from flac files, and list any
# flacs that don't at least have an image of 300x300
# - probably doesn't work too great with multiple images.

function tidy() {
	rm -rf $TMP
}

trap tidy QUIT INT EXIT

for flacpath in "$@"; do
	for file in $(find $flacpath -type f -name '*flac'); do
		cp /dev/null $TMP
		metaflac --export-picture-to=$TMP $file
	# this sort of works in bash 4.4+
	#	mapfile -d ';' -t D <<<$(identify -format "%w;%h" $TMP)
	# this works, but below read is more bullet proof
	#IFS="x" read W H  <<<$(identify -format "%wx%h" $TMP)
	# this works, but just IFS is simpler
		read -d '' -ra D <<<$(identify -format "%w\n%h" $TMP)
		if [ ${D[0]} -lt 300 -o ${D[1]} -lt 300 ]; then
			echo "$file (${D[0]}x${D[1]})"
	#	if [ ! $W -ge 300 -a $H -ge 300 ]; then
	#		echo "$file (${W}x$H)"
		fi
	done
done
