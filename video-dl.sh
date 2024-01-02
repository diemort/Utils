#!/bin/bash

####################
#
# Youtube video downloader with automatic conversion to MP4
# Uses: yt-dlp and ffmpeg
#
# Author: Gustavo Gil da Silveira (CERN-CMS|UFRGS|UERJ)
#
####################

# constants
DEFAULT_SUBTITLES="yes"
DEFAULT_OVERWRITE="yes"
DEFAULT_CRF=23

# styling:
bold=$( tput bold )
normal=$( tput sgr0 )
underline=$( tput smul )

# logging function:
log() {
    echo "${bold}>>>>> ${underline}$@${normal}"
}

help () {
    # display help:
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
    echo -n "Syntax: bash video-dl.sh "
    echo "-i <youtube-link> -q <crf-quality> -l <language> -w <overwrite-option> -s <subtitles-option>"
    echo
    echo "  -i, --input     [youtube-link]       Specify the YouTube video link"
    echo "  -q, --quality   [crf quality 0-51]   Set the CRF quality (0-51) for video conversion (optional, default: 23)"
    echo "  -l, --language  [2-word language]    Specify the language symbol for subtitles"
    echo "  -w, --overwrite [yes|no]             Overwrite previous MP4 files from ffmpeg (optional, default: no)"
    echo "  -s, --subtitles [yes|no]             Add subtitles (optional, default: yes)"
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
    if [ "$subtitles" == "yes" ]
    then
        fix_subs $subtitle
    fi
    # convert to mp4:
    if [[ $filename != *.mp4 ]]
    then
        convert $filename $crf $output $overwrite
        clean $filename
    fi
}

download () {
    # download with subs:
    link=$1
    lang=$2
    subtitles=$3
    log "Downloading '$( get_title )'"
    log $(subtitles_status)
    log $(crf_status)
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]
    then
        yt-dlp \
            --restrict-filenames \
            --write-sub \
            --write-auto-sub \
            --sub-lang ""${lang}"*" \
            --sub-format ttml \
            --convert-sub vtt \
            ${link}
    else
        yt-dlp \
            --restrict-filenames \
            ${link}
    fi
    check_success "Downloaded"
}

# get video title without tags:
get_title () {
    title="$( yt-dlp --get-filename --no-download-archive $link )"
    title=$( basename $title .webm )
    echo ${title%[*}
}

redefine () {
    link=$1
    crf=$2
    # extract filename:
    filename="$( yt-dlp --restrict-filenames --get-filename --no-download-archive $link )"
    # check if subtitles needed:
    if [ "$subtitles" == "yes" ]
    then
        subtitle="$( basename "$filename" .webm ).${lang}.vtt"
    else
        subtitle=""  # No subtitles, so set subtitle to an empty string
    fi
    output="$( basename "$filename" .webm )-crf${crf}.mp4"
}

fix_subs () {
    subtitle=$1
    # correct timing in subtitle:
    echo "${bold}>>>>> ${underline}Adjusting timing in auto subtitles${normal}"
    ffmpeg -fix_sub_duration -i "$subtitle" subs.vtt
    check_success "Subtitles fixed"
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
    log "Converting video to mp4 $(overwrite_status)"
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]
    then
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
    check_success "Video converted"
}

clean () {
    # output if converted to mp4:
    rm -rf "$filename"
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .webm )"*.vtt
    check_success "Area cleaned"
}

# subtitles status function:
subtitles_status() {
    if [ "$subtitles" == "yes" ]
    then
        echo "with subtitles"
    else
        echo "without subtitles"
    fi
}

# overwrite status function:
overwrite_status() {
    if [ "$overwrite" == "yes" ] || [ "$overwrite" == "" ]
    then
        echo "with overwrite"
    else
        echo "without overwrite"
    fi
}

# crf status function:
crf_status() {
    echo "with default quality crf==$crf"
}

# check command success function:
check_success() {
    if [ $? -ne 0 ]
    then
        log "Error: $1 failed. Exiting."
        exit 1
    else
        echo "${bold}----- $@${normal}" 
    fi
}



# main:
# check arguments:
if { [ $# -eq 1 ] && [ "$1" == "-h" ]; } || { [ $# -ge 1 ]; }
then
    # if -h option is present, display help and exit:
    if [ "$1" == "-h" ]
    then
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

# set default value for subtitles/overwrite if not provided
subtitles="${subtitles:-$DEFAULT_SUBTITLES}"
overwrite="${overwrite:-$DEFAULT_OVERWRITE}"
crf="${crf:-$DEFAULT_CRF}"

# main:
main "$@" $link $crf $lang $overwrite $subtitles

# say goodbye:
log "Download of $output completed"
exit 0

