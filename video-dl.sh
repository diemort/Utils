#!/bin/bash

# download with pt-BR subs:
echo "Downloading ${1}"
yt-dlp \
    --restrict-filenames \
    --write-sub \
    --write-auto-sub \
    --sub-lang "pt*" \
    --sub-format ttml \
    --convert-sub vtt \
    ${1}

# extract filename:
filename="$( yt-dlp --restrict-filenames --get-filename --no-download-archive ${1} )"
subtitle="$( ls "$( basename "$filename" .webm )"*.vtt )"
output="$( basename "$filename" .webm )-crf${2}.mp4"

# correct timing in subtitle:
ffmpeg -fix_sub_duration -i "$subtitle" subs.vtt

# convert preserving quality and subs:
if [[ $filename != *.mp4 ]]
then
    echo "Converting video to mp4"
    ffmpeg -i "$filename" \
        -crf ${2} \
        -vf "subtitles=subs.vtt:force_style='PrimaryColour=&H03fcff,Italic=1,Spacing=0.8'" \
        -c:a copy \
        "$output"
    # output
    rm -rf "$filename"
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .webm )"*.vtt
fi
echo "Download of $output completed"

