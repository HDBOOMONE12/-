#!/bin/sh

previous_commit=$1
new_commit=$2
branch_checkout=$3

# Переходим из .githooks в корень проекта
cd "$(dirname "$0")/.."

# Находим последний Liquibase-тег для previous_commit
prev_last_liquibase_tag=$(
  git log "$previous_commit" -p -- '*.yml' '*.yaml' \
    | grep -E '^[[:space:]]*\+.*tag:[[:space:]]*".*"' \
    | sed -E 's/^[[:space:]]*\+.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | head -1
)

# Находим последний Liquibase-тег для new_commit
new_last_liquibase_tag=$(
  git log "$new_commit" -p -- '*.yml' '*.yaml' \
    | grep -E '^[[:space:]]*\+.*tag:[[:space:]]*".*"' \
    | sed -E 's/^[[:space:]]*\+.*tag:[[:space:]]*"([^"]+)".*/\1/' \
    | head -1
)

echo "Предыдущий тег: $prev_last_liquibase_tag"
echo "Новый тег: $new_last_liquibase_tag"

if [ -z "$new_last_liquibase_tag" ]; then
    echo "ℹ️ Нет тегов Liquibase для нового коммита."
    exit 0
fi

if [ -z "$prev_last_liquibase_tag" ]; then
    echo "ℹ️ Нет тегов Liquibase для предыдущего коммита, обновляем базу"
    cd src/main/resources
    liquibase update --defaultsFile=liquibase.properties
    exit 0
fi

if [ "$prev_last_liquibase_tag" = "$new_last_liquibase_tag" ]; then
    echo "ℹ️ Теги Liquibase одинаковы, действие не требуется."
    exit 0
fi

# Сравниваем теги с помощью sort -V
if [ "$(echo -e "$new_last_liquibase_tag\n$prev_last_liquibase_tag" | sort -V | head -1)" = "$new_last_liquibase_tag" ]; then
    echo "⏪ Откат базы на $new_last_liquibase_tag (поскольку $new_last_liquibase_tag < $prev_last_liquibase_tag)"
    cd src/main/resources
    liquibase rollback "$new_last_liquibase_tag" --defaultsFile=liquibase.properties
else
    echo "⏩ Обновляем базу до $new_last_liquibase_tag (поскольку $new_last_liquibase_tag > $prev_last_liquibase_tag)"
    cd src/main/resources
    liquibase update --defaultsFile=liquibase.properties
fi