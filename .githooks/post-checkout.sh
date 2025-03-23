#!/bin/sh
#Получение коммитов

#$1 — старый HEAD, то есть коммит, на котором вы находились до checkout.
#
#$2 — новый HEAD, коммит, на который переключились.
#
#$3 — флаг типа checkout:
#
#1 если переключение произошло между ветками (branch checkout);
#
#0 если был выполнен checkout отдельных файлов (например, при восстановлении файлов).


#Считать тег ДО

#SELECT tag
#FROM databasechangelog
#WHERE tag IS NOT NULL
#ORDER BY dateexecuted DESC
#LIMIT 1;


# Считываем путь к нужному changelog

#!/bin/sh
# Переходим в корень репозитория (из .git/hooks)
cd "$(dirname "$0")/../.."
FILE_PATH="src/main/resources/db/changelog/db.changelog-master.yaml"
if git merge-base --is-ancestor "$2" "$1"; then
  LAST_LINE=$(grep 'file:' "$FILE_PATH" | tail -n 1)
  VERSION=$(echo "$LAST_LINE" | sed 's/^.*db\.changelog-\(.*\)\.yml/\1/')
  if [ -n "$VERSION" ]; then
    echo "$VERSION"
  else
    echo "Версия не найдена"
  fi
fi
exit 0
