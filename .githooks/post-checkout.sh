#!/bin/sh
cd "$(dirname "$0")/.."
FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"

# Отладочный вывод параметров
echo "Post-checkout hook triggered with parameters: $1, $2, $3" >> /tmp/post-checkout.log

# Убираем проверку $3, чтобы выполнялось всегда
LAST_LINE=$(grep 'file:' "$FILE_PATH" | tail -n 1)
VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')
if [ -n "$VERSION" ]; then
  echo "$VERSION"
else
  echo "Версия не найдена"
fi

exit 0