#!/bin/sh

previous_commit=$1
new_commit=$2
branch_checkout=$3

# Переходим из .githooks в корень проекта
cd "$(dirname "$0")/.."

# Функция: ищет последнюю строку, где есть 'tag: "..."', и извлекает текст в кавычках
get_liquibase_tag() {
  local commit_hash="$1"
  git grep -h 'tag:' "$commit_hash" -- src/main/resources/db.changelog 2>/dev/null \
    | sed -E 's/.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | tail -1
}

# 1. Получаем «эффективный» тег для предыдущего и нового коммитов
last_liquibase_tag_old=$(get_liquibase_tag "$previous_commit")
last_liquibase_tag_new=$(get_liquibase_tag "$new_commit")

# 2. Если в YAML кто-то случайно прописал '--tag=v1.2', убираем префикс '--tag='
last_liquibase_tag_old=$(echo "$last_liquibase_tag_old" | sed -E 's/^--tag=//')
last_liquibase_tag_new=$(echo "$last_liquibase_tag_new" | sed -E 's/^--tag=//')

echo "Старый тег: $last_liquibase_tag_old"
echo "Новый тег: $last_liquibase_tag_new"

# 3. Если теги совпадают (и не пустые), ничего не делаем
if [ -n "$last_liquibase_tag_old" ] && [ "$last_liquibase_tag_old" = "$last_liquibase_tag_new" ]; then
  echo "⚠️  Тег не изменился, действия с базой не выполняем."
  exit 0
fi

# 4. Проверяем, двигаемся назад (rollback) или вперёд (update)
if git merge-base --is-ancestor "$new_commit" "$previous_commit"; then
  echo "⏪ Откат базы на тег $last_liquibase_tag_new..."
  cd src/main/resources
  # В Liquibase 4.x просто пишем 'rollback <tag>', без --tag=
  liquibase rollback "$last_liquibase_tag_new" --defaultsFile=liquibase.properties
else
  echo "⏩ Обновляем базу до состояния с тегом $last_liquibase_tag_new..."
  cd src/main/resources
  liquibase update --defaultsFile=liquibase.properties
fi
