#!/bin/sh
# Переходим из .githooks в корень репозитория (ОДИН уровень)
cd "$(dirname "$0")/.."

FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"
FILE_CONTENT=$(git show "$2:$FILE_PATH")

LAST_LINE=$(echo "$FILE_CONTENT" | grep 'file:' | tail -n 1)
VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')

# Если новый коммит ($2) является предком старого ($1), значит откат (rollback)
if git merge-base --is-ancestor "$2" "$1"; then
  liquibase --defaultsFile="src/main/resources/liquibase.properties" rollback v$VERSION
else
  liquibase --defaultsFile="src/main/resources/liquibase.properties" update
fi

exit 0
