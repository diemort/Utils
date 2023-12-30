#!/bin/bash

####################
#
# Youtube video downloader with automatic conversion to MP4
# Uses: yt-dlp and ffmpeg
#
# Author: Gustavo Gil da Silveira (CERN-CMS|UFRGS|UERJ)
#
####################

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
    echo "Syntax: bash video-dl.sh"
    echo "  -i, --input     [youtube-link]       Specify the YouTube video link"
    echo "  -q, --quality   [crf quality 0-51]   Set the CRF quality (0-51) for video conversion"
    echo "  -l, --language  [2-word language]    Specify the language symbol for subtitles"
    echo "  -w, --overwrite [yes|no]             Overwrite previous MP4 files from ffmpeg (default: no)"
    echo "  -s, --subtitles [yes|no]             Add subtitles (default: yes)"
    echo
}

main () {
    link=$1
    crf=$2
    lang=$3
    overwrite=$4
    subtitles=$5
    download $link $lang $subtitles
    redefine $link $crf
    # check if subtitles needed:
    if [ "$subtitles" == "yes" ]; then
        fix_subs $subtitle
    fi
    # convert to mp4:
    if [[ $filename != *.mp4 ]]
    then
        convert $filename $crf $output $overwrite
        clean $filename
    fi
    return
}

download () {
    # download with subs:
    link=$1
    lang=$2
    subtitles=$3
    echo -n "${bold}>>>>> ${underline}Downloading ${link} "
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]; then
        echo "with subtitles in ${lang}${normal}"
        yt-dlp \
            --restrict-filenames \
            --write-sub \
            --write-auto-sub \
            --sub-lang ""${lang}"*" \
            --sub-format ttml \
            --convert-sub vtt \
            ${link}
    else
        echo "without subtitles${normal}"
        yt-dlp \
            --restrict-filenames \
            ${link}
    fi
    return
}

redefine () {
    link=$1
    crf=$2
    # extract filename:
    filename="$( yt-dlp --restrict-filenames --get-filename --no-download-archive $link )"
    # check if subtitles needed:
    if [ "$subtitles" == "yes" ]; then
        subtitle="$( basename "$filename" .webm ).${lang}.vtt"
    else
        subtitle=""  # No subtitles, so set subtitle to an empty string
    fi
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
    overwrite=$4
    # check if overwrite
    overw="-n"
    if [ "$overwrite" == "yes" ] || [ "$overwrite" == "" ]
    then
        overw="-y"
    fi
    # convert preserving quality and subs:
    echo "${bold}>>>>> ${underline}Converting video to mp4${normal}"
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]; then
        ffmpeg -i "$filename" \
            -crf $crf \
            -vf "subtitles=subs.vtt:force_style='PrimaryColour=&H03fcff,Italic=1,Spacing=0.8'" \
            -c:a copy \
            $overw \
            "$output"
    else
        ffmpeg -i "$filename" \
            -crf $crf \
            -c:a copy \
            $overw \
            "$output"
    fi
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
subtitles="yes"

# check arguments:
if { [ $# -eq 1 ] && [ "$1" == "-h" ]; } || { [ $# -ge 5 ]; }; then
    # if -h option is present, display help and exit:
    if [ "$1" == "-h" ]; then
        help
        exit 0
    fi
    # parse command-line options:
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--input)
                link="$2"
                shift 2
                ;;
            -q|--quality)
                crf="$2"
                shift 2
                ;;
            -l|--language)
                lang="$2"
                shift 2
                ;;
            -w|--overwrite)
                overwrite="$2"
                shift 2
                ;;
            -s|--subtitles)
                subtitles="$2"
                shift 2
                ;;
            -*|--*)
                echo "Unknown option $1"
                syntax
                exit 1
                ;;
        esac
    done
else
    # if conditions are not met, display an error message and exit:
    echo "Error: Missing one or more required options."
    syntax
    exit 1
fi

# main:
main "$@" $link $crf $lang $overwrite $subtitles
# say goodbye:
if [ $? == "0" ]
then
    echo "${bold}>>>>> ${underline}Download of $output completed${normal}"
    exit 0
else
    exit 1
fi

