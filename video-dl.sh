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
DEFAULT_SUBTITLES="no"
DEFAULT_LANGUAGE="en"
DEFAULT_OVERWRITE="yes"
DEFAULT_CRF=23
DEFAULT_VERBOSE=false
DEFAULT_ORIGINAL=false
DEFAULT_NOTCONVERT=false
URL_REGEX="^https://www\.youtube\.com/watch\?v=[a-zA-Z0-9_-]{11}$"

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
    echo "  -i, --input     [youtube-link]       Specify the YouTube video link [mandatory]"
    echo "                  link format: https://www.youtube.com/watch?v=XXXXXXXXXXX"
    echo "  -q, --quality   [crf quality 0-51]   Set the CRF quality (0-51) for video conversion (optional, default: 23)"
    echo "  -l, --language  [2-word language]    Specify the language symbol for subtitles (optional, default en)"
    echo "  -w, --overwrite [yes|no]             Overwrite previous MP4 files from ffmpeg (optional, default: no)"
    echo "  -s, --subtitles [yes|no]             Add subtitles (optional, default: no)"
    echo "  -nc, --notconvert                    Do not convert video to mp4"
    echo "  -k, --keep-original                  Keep original file (webm, mkv) after video conversion" \
                                                    "(optional, default: false)"
    echo "  -v, --verbose                        Output from yt-dlp and ffmpeg (optional, default: suppressed)"
    echo
}

main () {
    link=$1
    crf=$2
    lang=$3
    overwrite=$4
    subtitles=$5
    # full log:
    log "Downloading '$( get_title )'"
    log $(subtitles_status)
    log $(crf_status)
    log $(overwrite_status)
    log $(original_status)
    log $(conversion_status)
    #start:
    download $link $lang $subtitles
    redefine $link $crf
    # check if subtitles needed:
    if [ "$subtitles" == "yes" ]
    then
        fix_subs $subtitle
    fi
    # convert to mp4:
    if [ "$not_convert_vid" == false ];
    then
        if [[ $filename != *.mp4 ]]
        then
            convert $filename $crf "${output}" $overwrite
        fi
    fi
    clean $filename
}

download () {
    # download with subs:
    link=$1
    lang=$2
    subtitles=$3
    # check verbosity:
    verbose_yt=""; if [ "$verbose" == false ]; then verbose_yt="-q"; fi
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]
    then
        yt-dlp \
            ${verbose_yt} \
            --progress \
            --restrict-filenames \
            --write-sub \
            --write-auto-sub \
            --sub-lang ""${lang}"*" \
            --sub-format ttml \
            --convert-sub vtt \
            ${link}
    else
        yt-dlp \
            ${verbose_yt} \
            --progress \
            --restrict-filenames \
            ${link}
    fi
    check_success "Downloaded"
}

# get video title without tags:
get_title () {
    title="$( yt-dlp --get-filename --no-download-archive $link )"
    title=$( basename "$title" .${filename##*.} )
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
        subtitle="$( basename "$filename" .${filename##*.} ).${lang}.vtt"
        output="$( basename "$filename" .${filename##*.} )-crf${crf}-${lang}"
    else
        subtitle=""  # No subtitles, so set subtitle to an empty string
        output="$( basename "$filename" .${filename##*.} )-crf${crf}"
    fi
}

fix_subs () {
    subtitle=$1
    # correct timing in subtitle:
    echo "${bold}>>>>> ${underline}Adjusting timing in auto subtitles${normal}"
    # check verbosity:
    verbose_ffmpeg=""; if [ "$verbose" == false ]; then verbose_ffmpeg="-hide_banner -loglevel error"; fi
    ffmpeg -fix_sub_duration ${verbose_ffmpeg} -i "$subtitle" subs.vtt
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
    log "Converting video to mp4 $(overwrite_status) and $(original_status)"
    # check verbosity:
    verbose_ffmpeg=""; if [ "$verbose" == false ]; then verbose_ffmpeg="-hide_banner -loglevel error"; fi
    # check wether subtitles should be added or not:
    if [ "$subtitles" == "yes" ]
    then
        ffmpeg -i "$filename" \
            -crf $crf \
            -vf "subtitles=subs.vtt:force_style='PrimaryColour=&H03fcff,Italic=1,Spacing=0.8'" \
            -c:a copy \
            $overw \
            $verbose_ffmpeg \
            "${output}.mp4"
    else
        ffmpeg -i "$filename" \
            -crf $crf \
            -c:a copy \
            $overw \
            $verbose_ffmpeg \
            "${output}.mp4"
    fi
    check_success "Video converted"
}

clean () {
    # output if converted to mp4:
    if [ "$keep_original" == false ]
    then
        rm -rf "$filename"
    fi
    rm -rf subs.vtt
    rm -rf "$( basename "$filename" .${filename##*.} )"*.vtt
    check_success "Area cleaned"
}

# subtitles status function:
subtitles_status() {
    if [ "$subtitles" == "yes" ]
    then
        echo "with subtitles in ${lang}"
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

# keep original status:
original_status() {
    if [ "$keep_original" == true ]
    then    
        echo "keeping original video file" 
    else    
        echo "deleting original video file"
    fi
}

# conversion status:
conversion_status() {
    if [ "$not_convert_vid" == false ]
    then
        echo "convert video to mp4" 
    else
        echo "no video conversion"
    fi
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

# defaults:
subtitles="${subtitles:-$DEFAULT_SUBTITLES}"
overwrite="${overwrite:-$DEFAULT_OVERWRITE}"
lang="${lang:-$DEFAULT_LANGUAGE}"
crf="${crf:-$DEFAULT_CRF}"
verbose="${verbose:-$DEFAULT_VERBOSE}"
keep_original="${keep_original:-$DEFAULT_ORIGINAL}"
not_convert_vid="${not_convert_vid:-$DEFAULT_NOTCONVERT}"

# check arguments:
if { [ $# -eq 1 ] && [ "$1" == "-h" ]; } || { [ $# -ge 1 ]; }
then
    # if -h option is present, display help and exit:
    if [ "$1" == "-h" ]
    then
        help
        exit 0
    fi
    # test if -i option given:
    found_i=false
    for arg in "$@"
    do
        if [[ "$arg" == "-i" ]] || [[ "$arg" == "--input" ]]
        then
            found_i=true
            break
        fi
    done
    if ! $found_i
    then
        echo "Missing required option -i: youtube link"
        exit 1
    fi
    # parse command-line options:
    while [[ $# -gt 0 ]]
    do
        case $1 in
            -i|--input)
                if [ -z "$2" ]
                then
                    echo "Missing Youtube link"
                    help
                    exit 1
                elif [[ ! "$2" =~ $URL_REGEX ]]
                then
                    echo "Invalid YouTube URL format"
                    exit 1
                fi
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
            -v|--verbose)
                verbose=true
                shift
                ;;
            -k|--keep-original)
                keep_original=true
                shift
                ;;
            -nc|--not-convert)
                not_convert_vid=true
                keep_original=true
                shift
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
log "Download of $output completed"
exit 0

