#!/bin/bash

# $FORGE_SITE_PATH
RELEASES_DIR="$1/releases"
# Number of releases to keep (excluding the current release)
KEEP=$2 || 3

# Current release folder name
CURRENT_PATH=$(readlink $1/current)
CURRENT_RELEASE=$(basename $CURRENT_PATH)

# Change to the releases directory
cd "$RELEASES_DIR" || exit

# List all directories sorted by modification time, excluding the current release folder
RELEASES=$(ls -dt */ | grep -v "^${CURRENT_RELEASE}/$")

# Count the number of releases
RELEASE_COUNT=$(echo "$RELEASES" | wc -l)

# Calculate the number of releases to delete
DELETE_COUNT=$((RELEASE_COUNT - KEEP))

if [ "$DELETE_COUNT" -gt 0 ]; then
    # List directories to be deleted
    DELETE_DIRS=$(echo "$RELEASES" | tail -n "$DELETE_COUNT")
    echo "Deleting the following directories:"
    echo "$DELETE_DIRS"

    # Delete the directories
    echo "$DELETE_DIRS" | xargs rm -rf
else
    echo "Nothing to delete. Less than $KEEP releases present."
fi
