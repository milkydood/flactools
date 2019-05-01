#!/bin/bash

for flacpath in "$@"; do
        while IFS= read -r -d '' file; do
                read -d '' -ra D <<<$(metaflac --list "$file" 2>/dev/null |strings | grep -Po '(width|height)\: \K.*')

                if [ "${D[0]}" == "" -o "${D[1]}" == "" ]; then
                        echo "$file (No picture?)"
                elif [ ${D[0]} -lt 300 -o ${D[1]} -lt 300 ]; then
                        echo "$file (${D[0]}x${D[1]})"
                fi
        done < <(find $flacpath -type f -name '*flac' -print0)
done
