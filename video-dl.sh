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
}

description () {
    echo "Youtube video downloader"\
        "with automatic conversion to MP4"
    echo "Use option -h for help"
}

syntax () {
    echo "Syntax: bash video-dl.sh -i|--input [youtube-link] -q|--quality [crf quality 0-51]"
    echo
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
    return
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
    return
}

redefine () {
    link=$1
    crf=$2
    # extract filename:
    filename="$( yt-dlp --restrict-filenames --get-filename --no-download-archive $link )"
    subtitle="$( ls "$( basename "$filename" .webm )"*.vtt )"
    output="$( basename "$filename" .webm )-crf${crf}.mp4"
    return
}

fix_subs () {
    subtitle=$1
    # correct timing in subtitle:
    echo "${bold}>>>>> ${underline}Adjusting timing in auto subtitles${normal}"
    ffmpeg -fix_sub_duration -i "$subtitle" subs.vtt
    return
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
    return
}

clean () {
    # output if converted to mp4:
    rm -rf "$filename"
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .webm )"*.vtt
    return
}

# main:
# check arguments:
if [[ $# -eq 0 ]]
then
    echo "Arguments missing"
    syntax
    exit 1
else
    while [[ $# -gt 0 ]]
    do
        case $1 in
            -i|--input)
                link="$2"
                shift # past argument
                shift # past value
                ;;
            -q|--quality)
                crf="$2"
                shift # past argument
                shift # past value
                ;;
            -h|--help)
                help
                exit 0
                ;;
            -*|--*)
                echo "Unknown option $1"
                syntax
                exit 1
                ;;
        esac
    done
fi
# main:
main "$@" $link $crf
# say goodbye:
if [ $? == "0" ]
then
    echo "${bold}>>>>> ${underline}Download of $output completed${normal}"
    exit 0
else
    exit 1
fi

