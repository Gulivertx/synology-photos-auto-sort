#!/bin/bash

### INFO #################################################
# Synology photos and videos auto sort                              #
# By Gulivert                                            #
# https://github.com/Gulivertx/synology-photos-auto-sort #
##########################################################

VERSION="1.0"
PID_FILE="/tmp/synology_photos_auto_sort.pid"
LOG_DIRECTORY="logs"

# Define a folder where the images will be moved for duplicate images and during a process error
ERROR_DIRECTORY="error"

### Allowed image and videos extensions
ALLOWED_EXT="jpg JPG jpeg JPEG heic HEIC mov MOV heiv HEIV m4v M4V"

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

echo "Allowed formats: ${ALLOWED_EXT}"
echo ""

### Move to source folder
cd ${SOURCE}

echo "Start process"

# Count files
FILES_COUNTER=$(ls *.* 2> /dev/null | wc -l | xargs)

echo "$FILES_COUNTER files to process"
echo ""

if [[ ${FILES_COUNTER} != 0 ]]; then
    for FILE in *.*; do
        FILENAME="${FILE%.*}" # Get filename
        EXT="${FILE##*.}" # Get file extension

        # Verify if the extension is allowed
        if [[ ${ALLOWED_EXT} == *"$EXT"* ]]; then
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
        fi
    done

    # Wait until the process is done
    wait

    echo "All have been moved"
    echo ""
fi

### Move all files still not moved by the above rule in an error folder
UNMOVED_FILES_COUNTER=$(ls *.* 2> /dev/null | wc -l | xargs)

if [[ ${UNMOVED_FILES_COUNTER} != 0 ]]; then
    echo "$UNMOVED_FILES_COUNTER unmoved files, these files will be moved into error folder"
    echo ""

    mkdir -p ${SOURCE}/${ERROR_DIRECTORY}

    # Create a new log file
    CURRENT_DATE=`date +"%Y-%m-%d_%H-%M"`
    LOG_FILE="${LOG_DIRECTORY}/${CURRENT_DATE}.log"
    touch ${LOG_FILE}

    for FILE in *.*; do
        FILENAME="${FILE%.*}" # Get filename
        EXT="${FILE##*.}" # Get file extension

        # Verify if the extension is allowed
        if [[ ${ALLOWED_EXT} == *"$EXT"* ]]; then
            DATETIME=$(exiftool ${FILE} | grep -i "create date" | head -1 | xargs)

            # Verify if we have exif data available
            if [[ -z ${DATETIME} ]]; then
                NEW_FILENAME=${FILENAME=//:}_exif_data_missing.${EXT,,}
                echo "No exif data available for image ${FILE}, moved into ${ERROR_DIRECTORY} and renamed as ${NEW_FILENAME}" >> ${LOG_FILE}
            else
                DATE=${DATETIME:14:10}
                TIME=${DATETIME:25:8}
                NEW_FILENAME=${DATE//:}_${TIME//:}.${EXT,,}
                echo "An image with name ${NEW_FILENAME} already exist! File ${FILE} moved into ${ERROR_DIRECTORY} and renamed as ${NEW_FILENAME}" >> ${LOG_FILE}
            fi

            mv ${FILE} ${SOURCE}/${ERROR_DIRECTORY}/${NEW_FILENAME}
        fi
    done
fi

rm -f ${PID_FILE}

exit 0
