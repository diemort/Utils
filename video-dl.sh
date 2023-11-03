#!/bin/bash

# download with pt-BR subs:
echo "Downloading ${1}"
yt-dlp \
    --write-sub \
    --write-auto-sub \
    --sub-lang "pt*" \
    --sub-format ttml \
    --convert-sub vtt \
    ${1}

# extract filename:
filename="$( yt-dlp --get-filename --no-download-archive ${1} )"
subtitle="$( ls "$( basename "$filename" .webm )"*.vtt )"

# correct timing in subtitle:
ffmpeg -fix_sub_duration -i "$subtitle" subs.vtt

# convert preserving quality and subs:
if [[ $filename != *.mp4 ]]
then
    echo "Converting video to mp4"
    ffmpeg -i "$filename" -crf 17 -vf "subtitles=subs.vtt:force_style='PrimaryColour=&H03fcff,Italic=1,Spacing=0.8'" -c:a copy "$( basename "$filename" .webm ).mp4"
    # output
    rm -rf "$filename"
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .webm )"*.vtt
fi
echo "Download of $( basename "$filename" .webm).mp4 completed"

