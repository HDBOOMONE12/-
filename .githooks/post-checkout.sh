#!/bin/bash
# Скрипт Git post-checkout hook для автоматического применения/отката Liquibase-миграций при переключении коммитов.

old_commit="$1"    # SHA1 старого коммита (HEAD до переключения)
new_commit="$2"    # SHA1 нового коммита (HEAD после переключения)
branch_switch="$3" # Флаг (1 если произошел checkout на другую ветку или коммит, 0 если просто обновление файлов)

# Если checkout не изменил HEAD (например, checkout файлов без смены коммита), то ничего не делаем.
if [ "$branch_switch" -eq 0 ]; then
    echo "No HEAD change (file checkout), skipping Liquibase hook."
    exit 0
fi

# Если старого коммита не было (например, первый checkout после clone, old_commit состоит из нулей),
# то это первоначальная настройка – просто применяем все миграции.
if echo "$old_commit" | grep -qE '^[0]+$'; then
    echo "Initial checkout (no previous commit). Running full Liquibase update."
    liquibase update
    exit 0
fi

# Функция для получения последнего тега Liquibase в указанном коммите.
get_last_tag() {
    local commit="$1"
    # Ищем в файлах db.changelog-*.yml строку с определением тега Liquibase.
    # Используем git grep для просмотра содержимого файлов в данном коммите.
    # Получаем все значения tag (например, "v1.0", "v1.1", ...) и выбираем последний по версии.
    local tags=$(git grep -h -A1 'tagDatabase:' "$commit" -- 'db.changelog-*.yml' \
                 | grep -o 'tag: *"[^"]*"' \
                 | sed -E 's/tag: *"([^"]*)"/\1/')
    if [ -z "$tags" ]; then
        # Если тегов нет, возвращаем пустую строку.
        echo ""
    else
        # Сортируем найденные теги по версии и берем последний (самый свежий).
        # sort -V обеспечивает "естественную" сортировку версий (1.10 > 1.2 и т.д.).
        echo "$tags" | sort -V | tail -1
    fi
}

# Получаем последний тег Liquibase для старого и нового коммитов.
old_tag="$(get_last_tag "$old_commit")"
new_tag="$(get_last_tag "$new_commit")"

# Если тег не изменился (или ни в старом, ни в новом коммите тегов нет), Liquibase выполнять не нужно.
if [ "$old_tag" = "$new_tag" ]; then
    echo "Liquibase tag unchanged (tag = ${new_tag:-none}). No rollback/update needed."
    exit 0
fi

# Определяем направление переключения (вперёд или назад по истории).
direction=""  # переменная для хранения направления ('forward' или 'backward')

# Попытаемся определить направление с помощью ancestry (является ли один коммит предком другого).
if git merge-base --is-ancestor "$new_commit" "$old_commit"; then
    # Новый коммит является предком старого -> мы откатываемся на более старую версию (backward).
    direction="backward"
elif git merge-base --is-ancestor "$old_commit" "$new_commit"; then
    # Старый коммит предок нового -> двигаемся вперед (forward) к более новой версии.
    direction="forward"
else
    # Если коммиты находятся на разных ветках (не предки друг друга),
    # определяем направление сравнением тегов по версии.
    # (Предполагается, что нумерация тегов отражает прогресс версий.)
    if [ -n "$old_tag" ] && [ -n "$new_tag" ]; then
        # Сравниваем версии тегов: какой больше.
        latest_tag=$(printf "%s\n%s\n" "$old_tag" "$new_tag" | sort -V | tail -1)
        if [ "$latest_tag" = "$old_tag" ]; then
            # Старый тег больше (новый коммит отстает) -> откат (backward).
            direction="backward"
        else
            # Новый тег больше -> обновление (forward).
            direction="forward"
        fi
    else
        # Если у одного из коммитов тег отсутствует, считаем его "меньшим" версионно.
        if [ -z "$new_tag" ] && [ -n "$old_tag" ]; then
            # Новый тег отсутствует, а старый есть -> откат.
            direction="backward"
        elif [ -n "$new_tag" ] && [ -z "$old_tag" ]; then
            # У нового коммита есть тег, у старого нет -> движение вперед.
            direction="forward"
        fi
    fi
fi

# Выполняем Liquibase операции на основе определенного направления переключения.
if [ "$direction" = "backward" ]; then
    if [ -z "$new_tag" ]; then
        # Если в новом коммите тег не найден, безопасно выходим, чтобы не выполнять rollback на неопределенный тег.
        echo "Target commit has no Liquibase tag. Skipping rollback."
        exit 0
    fi
    echo "Switch to older commit detected. Rolling back database to tag $new_tag."
    # Выполняем откат базы данных до последнего тега нового (более старого) коммита.
    liquibase rollback "$new_tag"
elif [ "$direction" = "forward" ]; then
    echo "Switch to newer commit detected. Updating database to apply new changes."
    # Применяем новые миграции, отсутствовавшие на предыдущем коммите.
    liquibase update
else
    # Непредвиденный случай (направление не определено) – выводим предупреждение.
    echo "Warning: could not determine direction for Liquibase operations. No action taken."
fi

# Конец скрипта
