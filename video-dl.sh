#!/bin/bash

# Styling:
bold=$( tput bold )
normal=$( tput sgr0 )
underline=$( tput smul )

help () {
    # Display help:
    description
    echo
    syntax
    echo
}

description () {
    echo "Youtube video downloader"\
        " with automatic conversion to MP4"
}

syntax () {
    echo "Syntax: bash video-dl.sh [youtube-link] [crf quality 0-51]"
}

main () {
    link=$1
    crf=$2
    download $link
    redefine $link $crf
    fix_subs $subtitle
    if [[ $filename != *.mp4 ]]
    then
        convert $filename $crf $output
        clean $filename
    fi
}

download () {
    # download with pt-BR subs:
    echo "${bold}>>>>> ${underline}Downloading ${1}${normal}"
    yt-dlp \
        --restrict-filenames \
        --write-sub \
        --write-auto-sub \
        --sub-lang "pt*" \
        --sub-format ttml \
        --convert-sub vtt \
        ${1}
}

redefine () {
    link=$1
    crf=$2
    # extract filename:
    filename="$( yt-dlp --restrict-filenames --get-filename --no-download-archive $link )"
    subtitle="$( ls "$( basename "$filename" .webm )"*.vtt )"
    output="$( basename "$filename" .webm )-crf${crf}.mp4"
}

fix_subs () {
    subtitle=$1
    # correct timing in subtitle:
    echo "${bold}>>>>> ${underline}Adjusting timing in auto subtitles${normal}"
    ffmpeg -fix_sub_duration -i "$subtitle" subs.vtt
}

convert () {
    filename=$1
    crf=$2
    output=$3
    # convert preserving quality and subs:
    echo "${bold}>>>>> ${underline}Converting video to mp4${normal}"
    ffmpeg -i "$filename" \
        -crf $crf \
        -vf "subtitles=subs.vtt:force_style='PrimaryColour=&H03fcff,Italic=1,Spacing=0.8'" \
        -c:a copy \
        "$output"
}

clean () {
    # output if converted to mp4:
    rm -rf "$filename"
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .webm )"*.vtt
}

# main:
link=$1
crf=$2
# check arguments:
if [ -z "$1" ] || [ -z "$2" ]
then
    echo
    echo ">>>>> Arguments missing"
    syntax
    exit 1
fi
# main:
main "$@" $link $crf
# say goodbye:
echo "${bold}>>>>> ${underline}Download of $output completed${normal}"
exit 0

