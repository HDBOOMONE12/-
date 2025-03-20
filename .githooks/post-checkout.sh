#!/bin/sh

previous_commit=$1
new_commit=$2
branch_checkout=$3

# 1. Переходим из .githooks в корень проекта
cd "$(dirname "$0")/.."

# 2. Функция для извлечения последнего Liquibase-тега из конкретного коммита
get_liquibase_tag() {
  local commit_hash="$1"
  git log "$commit_hash" -p -- '*.yml' '*.yaml' \
    | grep -E '^[[:space:]]*\+.*tag:[[:space:]]*".*"' \
    | sed -E 's/^[[:space:]]*\+.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | tail -1
}

# 3. Ищем теги для старого и нового коммитов
last_liquibase_tag_old=$(get_liquibase_tag "$previous_commit")
last_liquibase_tag_new=$(get_liquibase_tag "$new_commit")

echo "Старый тег: $last_liquibase_tag_old"
echo "Новый тег: $last_liquibase_tag_new"

# 4. Если теги совпадают — пропускаем любые действия с базой
if [ -n "$last_liquibase_tag_old" ] && [ "$last_liquibase_tag_old" = "$last_liquibase_tag_new" ]; then
  echo "⚠️ Тег не изменился. Пропускаем rollback/update."
  exit 0
fi

# 5. Если тега нет в новом коммите, тоже можно пропустить или вывести предупреждение
if [ -z "$last_liquibase_tag_new" ]; then
  echo "ℹ️ В новом коммите нет тега Liquibase. Пропускаем."
  exit 0
fi

# 6. Определяем направление: если new_commit — предок previous_commit, значит откат
if git merge-base --is-ancestor "$new_commit" "$previous_commit"; then
  echo "⏪ Откат базы на $last_liquibase_tag_new..."
  cd src/main/resources
  liquibase rollback "$last_liquibase_tag_new" --defaultsFile=liquibase.properties
else
  echo "⏩ Обновляем базу до $last_liquibase_tag_new..."
  cd src/main/resources
  liquibase update --defaultsFile=liquibase.properties
fi
