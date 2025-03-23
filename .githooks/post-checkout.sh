#!/bin/sh
cd "$(dirname "$0")/.."
FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"

# Отладочный вывод параметров
echo "Post-checkout hook triggered with parameters: $1, $2, $3" >> /tmp/post-checkout.log

if [ "$3" = "1" ]; then
  # Переход между ветками, читаем из коммита
  COMMIT=$2
  CONTENT=$(git show $COMMIT:$FILE_PATH 2>/dev/null)
else
  # Проверка файлов или другое, читаем из рабочей директории
  CONTENT=$(cat $FILE_PATH 2>/dev/null)
fi

LAST_LINE=$(echo "$CONTENT" | grep 'file:' | tail -n 1)
VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')

if [ -n "$VERSION" ]; then
  echo "$VERSION"
else
  echo "Версия не найдена"
fi

exit 0