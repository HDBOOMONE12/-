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
LAST_FILE_LINE=$(grep 'file:' db.changelog-master.yaml | tail -n 1 | sed 's/.*file:\s*//')
if [ -n "$LAST_FILE_LINE" ]; then
  echo "Последний путь к файлу: $LAST_FILE_LINE"
else
  echo "В файле db.changelog-master.yaml не нашлось ни одной строки с 'file:'."
fi
exit 0