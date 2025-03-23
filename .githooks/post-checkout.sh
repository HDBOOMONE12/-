#!/bin/sh
cd "$(dirname "$0")/.."
FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"

# Отладочный вывод параметров
echo "Post-checkout hook triggered with parameters: $1, $2, $3" >> /tmp/post-checkout.log

if [ "$3" = "1" ]; then
  # Переход между ветками
  CONTENT=$(git show $2:$FILE_PATH 2>/dev/null)
else
  # Проверка файлов или другое
  CONTENT=$(cat $FILE_PATH 2>/dev/null)
fi

LAST_LINE=$(echo "$CONTENT" | grep 'file:' | tail -n 1)
VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')

if [ -n "$VERSION" ]; then
  if [ "$3" = "1" ]; then
    TIMESTAMP_A=$(git show --format=%ct -s $1)
    TIMESTAMP_B=$(git show --format=%ct -s $2)
    if [ "$TIMESTAMP_A" -gt "$TIMESTAMP_B" ]; then
      # Переход на более ранний коммит, выполняем откат
      liquibase --defaultsFile=liquibase.properties rollbackToTag v$VERSION
    else
      # Переход на более поздний коммит, выполняем обновление
      liquibase --defaultsFile=liquibase.properties update
    fi
  fi
  echo "$VERSION"
else
  echo "Версия не найдена"
fi

exit 0