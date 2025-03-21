#!/bin/sh

previous_commit=$1
new_commit=$2
branch_checkout=$3

# Переходим из .githooks в корень проекта
cd "$(dirname "$0")/.."

# Находим последнюю строку с + tag: "vX.X"
last_liquibase_tag=$(
  git log "$new_commit" -p -- '*.yml' '*.yaml' \
    | grep -E '^[[:space:]]*\+.*tag:[[:space:]]*".*"' \
    | sed -E 's/^[[:space:]]*\+.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | tail -1
)

if [ -n "$last_liquibase_tag" ]; then
    echo "🚩 Последний Liquibase-тег: $last_liquibase_tag"
else
    echo "ℹ️ Нет тегов Liquibase до этого коммита."
    exit 0
fi

# Определяем, откат или вперёд
if git merge-base --is-ancestor "$new_commit" "$previous_commit"; then
    echo "⏪ Откат базы на $last_liquibase_tag..."
    cd src/main/resources
    liquibase rollback "$last_liquibase_tag" --defaultsFile=liquibase.properties
else
    echo "⏩ Обновляем базу..."
    cd src/main/resources
    liquibase update --defaultsFile=liquibase.properties
fi
