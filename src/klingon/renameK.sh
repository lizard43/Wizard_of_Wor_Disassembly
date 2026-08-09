#!/bin/bash

# Exit immediately if any command fails
set -e

# Define relative paths based on script location in tools/
ROM_DIR="../../roms"
SRC_ZIP="$ROM_DIR/wowk.zip"
DST_ZIP="$ROM_DIR/wowg.zip"

# Ensure the source file exists before proceeding
if [ ! -f "$SRC_ZIP" ]; then
    echo "Error: $SRC_ZIP not found."
    exit 1
fi

# 1. Create a copy of the original zip file
cp "$SRC_ZIP" "$DST_ZIP"

# 2. Extract the specific file locally
unzip -p "$DST_ZIP" klingon.x11 > german.x11

# 3. Add the renamed file into the new zip archive
zip -g "$DST_ZIP" german.x11

# 4. Delete the original file from the new zip archive
zip -d "$DST_ZIP" klingon.x11

# 5. Clean up the temporary local file
rm german.x11

echo "Success! Created $DST_ZIP with klingon.x11 renamed to german.x11."
