#!/bin/bash

# Git post-checkout hook script for automatic Liquibase rollback/update on commit switch.

# Получаем аргументы Git-хука:
previous_commit=$1   # Старый коммит (откуда мы переключаемся)
new_commit=$2        # Новый коммит (куда мы переключаемся)
checkout_flag=$3     # 1 - смена ветки/коммита, 0 - checkout отдельных файлов

# Если checkout_flag == 0, значит это не смена ветки/коммита (например, checkout файла). Пропускаем выполнение.
if [ "$checkout_flag" != "1" ]; then
    echo "ℹ️  Checkout отдельного файла — Liquibase не требуется."
    exit 0
fi

# Функция для извлечения последнего тега Liquibase в данном коммите
get_liquibase_tag() {
    local commit_hash="$1"

    # Проверяем, существует ли коммит
    if ! git cat-file -e "$commit_hash" 2>/dev/null; then
        echo ""
        return
    fi

    # Ищем тег в db.changelog-master.yaml в указанном коммите
    git show "$commit_hash:src/main/resources/db.changelog-master.yaml" 2>/dev/null \
        | grep -E 'tag:[[:space:]]*".*"' \
        | sed -E 's/.*tag:[[:space:]]*"([^"]+)".*/\1/' | tail -1
}

# Определяем последний тег Liquibase на предыдущем и новом коммите
last_tag_old=$(get_liquibase_tag "$previous_commit")
last_tag_new=$(get_liquibase_tag "$new_commit")

# Логируем найденные теги
echo "🔍 Liquibase-тег на предыдущем коммите: ${last_tag_old:-<не найден>}"
echo "🔍 Liquibase-тег на новом коммите: ${last_tag_new:-<не найден>}"

# Если тег не изменился (или отсутствует в обоих коммитах), то пропускаем действия
if [ "$last_tag_old" = "$last_tag_new" ]; then
    if [ -z "$last_tag_new" ]; then
        echo "ℹ️  Теги не найдены в обоих коммитах. Операции отката/обновления пропущены."
    else
        echo "ℹ️  Тег не изменился (остался \"$last_tag_new\"). Откат/обновление не требуются."
    fi
    exit 0
fi

# Определяем направление переключения: назад (rollback) или вперёд (update)
if git merge-base --is-ancestor "$new_commit" "$previous_commit"; then
    # Двигаемся назад → Откат базы данных
    if [ -n "$last_tag_new" ]; then
        echo "⏪ Откат базы до тега \"$last_tag_new\"..."
        (cd src/main/resources && liquibase rollback "$last_tag_new" --defaultsFile=liquibase.properties)
    else
        echo "⚠️  Новый коммит не содержит тега. Откат невозможен."
    fi
else
    # Двигаемся вперёд → Обновление базы данных
    echo "⏩ Обновление базы данных..."
    (cd src/main/resources && liquibase update --defaultsFile=liquibase.properties)
fi
