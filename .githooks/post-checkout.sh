#!/bin/sh
cd "$(dirname "$0")/.."
FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"
FILE_CONTENT=$(git show "$2:$FILE_PATH")
LAST_LINE=$(echo "$FILE_CONTENT" | grep 'file:' | tail -n 1)
VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')
echo "$VERSION"
exit 0
