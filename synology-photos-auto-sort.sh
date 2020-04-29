#!/bin/bash

### INFO #################################################
# Synology photos auto sort                              #
# By Gulivert                                            #
# https://github.com/Gulivertx/synology-photos-auto-sort #
##########################################################

VERSION="0.3"
PID_FILE="/tmp/synology_photos_auto_sort.pid"
ERROR_DIRECTORY="error"

echo "Synology photos and videos auto sort version $VERSION"
echo "https://github.com/Gulivertx/synology-photos-auto-sort"
echo "______________________________________________________"
echo ""

### Verify if a script already running
if [[ -f ${PID_FILE} ]]; then
    echo "Error: an other process of the script is still running" >&2
    exit 0
fi

### Create a pid file
echo $$ > ${PID_FILE}

### Verify if exiftool installed
if ! [[ -x "$(command -v exiftool)" ]]; then
    echo "Error: exiftool is not installed" >&2
    echo "To install exiftool to your Synology NAS add package sources from http://www.cphub.net"
    rm -f ${PID_FILE}
    exit 1
fi

### Get script arguments source and target folders
SOURCE=$1
TARGET=$2

if [[ -z ${SOURCE} ]] || [[ -z ${TARGET} ]]; then
    echo "Error: source and target folders are not specified as script arguments" >&2
    echo "Ex.: synology-photos-auto-sort.sh /path_to_source /path_to_target"
    rm -f ${PID_FILE}
    exit 1
fi

echo "Source folder : $SOURCE"
echo "Target folder : $TARGET"
echo ""

### Allowed image extensions
IMG_EXT=( "jpg" "JPG" "jpeg" "JPEG" "heic" "HEIC" )

### Allowed video extensions
VIDEO_EXT=( "mov" "MOV" "heiv" "HEIV" "m4v" "M4V")

echo "Allowed image formats: ${IMG_EXT[@]}"
echo "Allowed video formats: ${VIDEO_EXT[@]}"
echo ""

### Move to source folder
cd ${SOURCE}

echo "Start image process"
echo ""

for EXT in "${IMG_EXT[@]}"; do
    FILES_COUNTER=$(ls *.${EXT} 2> /dev/null | wc -l)

    if [[ ${FILES_COUNTER} != 0 ]]; then
        for FILE in *.${EXT}; do
            DATETIME=$(exiftool ${FILE} | grep -i "create date" | head -1 | xargs)

            # Verify if we have exif data available
            if [[ -z ${DATETIME} ]]; then
                continue
            fi

            # Extract date, time year and month and build new filename
            DATE=${DATETIME:14:10}
            TIME=${DATETIME:25:8}
            NEW_NAME=${DATE//:}_${TIME//:}.${EXT,,}

            # Create target folder
            YEAR=${DATE:0:4}
            MONTH=${DATE:5:2}
            mkdir -p ${TARGET}/${YEAR}/${YEAR}.${MONTH}

            # Move the file to target folder
            mv -n ${FILE} ${TARGET}/${YEAR}/${YEAR}.${MONTH}/${NEW_NAME}
        done

        # Wait until the copy process is done
        wait

        echo "All $EXT have been moved"
        echo ""
    fi
done

echo "Start video process"
echo ""

for EXT in "${VIDEO_EXT[@]}"; do
    FILES_COUNTER=$(ls *.${EXT} 2> /dev/null | wc -l)

    if [[ ${FILES_COUNTER} != 0 ]]; then
        for FILE in *.$EXT; do
            DATETIME=$(exiftool ${FILE} | grep -i "create date" | head -1 | xargs)

            # Verify if we have exif data available
            if [[ -z ${DATETIME} ]]; then
                continue
            fi

            # Extract date, time year and month and build new filename
            DATE=${DATETIME:14:10}
            TIME=${DATETIME:25:8}
            NEW_NAME=${DATE//:}_${TIME//:}.${EXT,,}

            # Create target folde
            YEAR=${DATE:0:4}
            MONTH=${DATE:5:2}
            mkdir -p ${TARGET}/${YEAR}/${YEAR}.${MONTH}

            # Move the file to target folder
            mv -n ${FILE} ${TARGET}/${YEAR}/${YEAR}.${MONTH}/${NEW_NAME}
        done

        # Wait until the copy process is done
        wait

        echo "All $EXT have been moved"
        echo ""
    fi
done

### Move all files still not moved by the above rules in an error folder
UNMOVED_FILES_COUNTER=$(ls *.* 2> /dev/null | wc -l | xargs)

if [[ ${UNMOVED_FILES_COUNTER} != 0 ]]; then
    echo "There is $UNMOVED_FILES_COUNTER unmoved files, these files will be moved into error folder"
    echo ""

    mkdir -p ${SOURCE}/${ERROR_DIRECTORY}

    for FILE in *.*; do
        # Get file extension
        EXT="${FILE##*.}"

        DATETIME=$(exiftool ${FILE} | grep -i "create date" | head -1 | xargs)

        # Verify if we have exif data available
        if [[ -z ${DATETIME} ]]; then
            echo "No exif data available for image $FILE"
            echo "Use original filename"
            FILENAME="${FILE%.*}"
            NEW_FILENAME=${FILENAME=//:}_exif_data_missing.${EXT,,}
        else
            DATE=${DATETIME:14:10}
            TIME=${DATETIME:25:8}
            NEW_FILENAME=${DATE//:}_${TIME//:}.${EXT,,}
        fi

        mv ${FILE} ${SOURCE}/${ERROR_DIRECTORY}/${NEW_FILENAME}
    done
fi

rm -f ${PID_FILE}

exit 0
