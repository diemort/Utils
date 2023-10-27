#!/bin/bash

# download with pt-BR subs:
echo "Downloading ${1}"
yt-dlp --write-sub --write-auto-sub --sub-lang "pt-BR*" ${1}
filename=$( yt-dlp --write-sub --write-auto-sub --sub-lang "pt-BR*" --get-filename --no-download-archive ${1} )
# convert preserving quality and subs:
if [[ $filename != *.mp4 ]]
then
    echo "Converting video to mp4"
    ffmpeg -i "$filename" -crf 17 -c:v libx264 -map 0 -c:a aac -c:s mov_text "$( basename "$filename" .webm )".mp4
    # output
    rm -rf "$filename"
    echo "Download of $( basename "$filename" .webm).mp4 completed"
fi
echo "Download of "$filename" completed"

