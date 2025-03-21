#!/bin/sh

previous_commit=$1
new_commit=$2
branch_checkout=$3

# Переходим из .githooks в корень проекта
cd "$(dirname "$0")/.."

# Функция для получения последнего тега из содержимого файлов в каталоге changelogs
get_liquibase_tag() {
  local commit_hash="$1"
  git grep -h 'tag:' "$commit_hash" -- src/main/resources/db.changelog \
    | sed -E 's/.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | tail -1
}

# Получаем «эффективный» тег для предыдущего и нового коммитов
last_liquibase_tag_old=$(get_liquibase_tag "$previous_commit")
last_liquibase_tag_new=$(get_liquibase_tag "$new_commit")

echo "Старый тег: $last_liquibase_tag_old"
echo "Новый тег: $last_liquibase_tag_new"

# Если теги совпадают, пропускаем откат/обновление
if [ -n "$last_liquibase_tag_old" ] && [ "$last_liquibase_tag_old" = "$last_liquibase_tag_new" ]; then
  echo "⚠️ Тег не изменился, действия с базой не выполняем."
  exit 0
fi

# Определяем направление переключения: если new_commit предок previous_commit — откат
if git merge-base --is-ancestor "$new_commit" "$previous_commit"; then
  echo "⏪ Откат базы на тег $last_liquibase_tag_new..."
  cd src/main/resources
  liquibase rollback "$last_liquibase_tag_new" --defaultsFile=liquibase.properties
else
  echo "⏩ Обновляем базу до состояния с тегом $last_liquibase_tag_new..."
  cd src/main/resources
  liquibase update --defaultsFile=liquibase.properties
fi
