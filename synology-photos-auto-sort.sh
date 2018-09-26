#!/bin/bash

### SCRIPT INFO ###
# Synology photos auto sort
# By Gulivert
# https://github.com/Gulivertx/synology-photos-auto-sort
###################

VERSION="0.0.1"

echo "Synology photos auto sort version $VERSION"
echo ""

if ! [ -x "$(command -v exiftool)" ]; then
  echo "Error: exiftool is not installed." >&2
  exit 1
fi

### Get script arguments source and target folders
SOURCE=$1
TARGET=$2

if [ -z "$SOURCE" ] || [ -z "$TARGET" ]; then
  echo "Error: source and target folders are not specified as script arguments" >&2
  echo "Ex.: synology-photos-auto-sort.sh /path_to_source /path_to_target"
  exit 1
fi

echo "Source folder : $SOURCE"
echo "Target folder : $TARGET"
echo ""

### Allowed image extensions
IMG_EXT=( "jpg" "jpeg" "heic" )

### Allowed video extensions
VIDEO_EXT=( "mov" "heiv" "m4v")

echo "Allowed image formats: ${IMG_EXT[@]}"
echo "Allowed video formats: ${VIDEO_EXT[@]}"
echo ""

### Move to source folder
cd $SOURCE

echo "Start image process"
echo ""

for EXT in "${IMG_EXT[@]}"; do
  FILES_COUNTER=$(ls *.$EXT 2> /dev/null | wc -l)

  if [ $FILES_COUNTER != 0 ]; then
    for FILE in *.$EXT; do
      DATETIME=$(exiftool "$FILE" | grep -i "create date" | head -1 | xargs)
      DATE=${DATETIME:14:10}
      TIME=${DATETIME:25:8}
      NEW_NAME=${DATE//:}_${TIME//:}.$EXT

      YEAR=${DATE:0:4}
      MONTH=${DATE:5:2}

      # Create target folder
      mkdir -p $TARGET/$YEAR/$YEAR.$MONTH
      cp "$FILE" $TARGET/$YEAR/$YEAR.$MONTH/$NEW_NAME
    done
    wait
    echo "All $EXT have been moved"
    echo ""
  fi
done

echo "Start video process"
echo ""

for EXT in "${VIDEO_EXT[@]}"; do
  FILES_COUNTER=$(ls *.$EXT 2> /dev/null | wc -l)

  if [ $FILES_COUNTER != 0 ]; then
    for FILE in *.$EXT; do
      DATETIME=$(exiftool "$FILE" | grep -i "create date" | head -1 | xargs)
      DATE=${DATETIME:14:10}
      TIME=${DATETIME:25:8}
      NEW_NAME=${DATE//:}_${TIME//:}.$EXT

      YEAR=${DATE:0:4}
      MONTH=${DATE:5:2}

      # Create target folder
      mkdir -p $TARGET/$YEAR/$YEAR.$MONTH
      cp "$FILE" $TARGET/$YEAR/$YEAR.$MONTH/$NEW_NAME
    done
    wait
    echo "All $EXT have been moved"
    echo ""
  fi
done
