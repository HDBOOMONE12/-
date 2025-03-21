#!/bin/bash
#
# Git post-checkout hook script for automatic Liquibase rollback/update on commit switch.
#
# Требования:
# 1. Определение последнего тега Liquibase для предыдущего и нового коммитов.
# 2. Если тег не изменился, никаких действий не выполняется.
# 3. Если новый коммит является предком предыдущего (движение назад по истории), выполняется `liquibase rollback` до указанного тега.
# 4. Если новый коммит более новый (движение вперёд по истории), выполняется `liquibase update`.
# 5. Используется надёжный способ поиска тега (парсинг changelog-файлов в конкретной версии коммита) во избежание неправильного определения.
# 6. Работа кода подробно описана в комментариях.
#
# Дополнительно:
# - Предполагается, что Liquibase YAML-файлы изменений находятся в каталоге src/main/resources/db.changelog.
# - Master-файл db.changelog-master.yaml включает все версии изменений (через include).
# - Теги прописываются в changelog-файлах с помощью changeSet с <tagDatabase>, формат строки: tag: "vX.X".
# - Используется Liquibase 4.31.1, поэтому команда rollback вызывается **без** флага --tag (формат: `liquibase rollback <tag>`).
#
# Скрипт учитывает особые случаи:
# - Если переключение происходит не между ветками/коммитами (а, например, откат отдельного файла), скрипт не выполняет никаких действий.
# - Если в коммите отсутствуют теги Liquibase, это обрабатывается (скрипт выведет предупреждение и ничего не сделает, чтобы избежать ошибок).
# - Все ключевые шаги логгируются сообщениями, чтобы было понятно, что происходит.
#

# Получаем аргументы hook'а: старый и новый коммиты, и флаг типа checkout (1 - смена ветки/коммита, 0 - обновление отдельных файлов)
oldCommit=$1    # хеш предыдущего HEAD (старый коммит)
newCommit=$2    # хеш нового HEAD (новый коммит)
checkoutFlag=$3 # тип checkout: "1" если смена ветки/коммита, "0" если checkout файла (частичный)

# Если checkoutFlag == 0, значит это не смена коммита/ветки (например, checkout отдельного файла), выходим без действий.
if [ "$checkoutFlag" != "1" ]; then
    echo "post-checkout: обнаружен checkout отдельного файла (не смена коммита). Действия Liquibase не требуются."
    exit 0
fi

# Шаг 1: Определяем последний тег Liquibase на предыдущем коммите (oldCommit) и новом коммите (newCommit).

# Инициализируем переменные для тегов
lastTagOld=""
lastTagNew=""

# Получение последнего тега Liquibase для старого коммита.
# Используем `git show` или `git grep` по файлам changelog в указанном коммите, чтобы найти строки с тегом.
if [ -n "$oldCommit" ] && [ "$oldCommit" != "0000000000000000000000000000000000000000" ]; then
    # Извлекаем содержимое changelog-файлов в старом коммите и находим последнюю строку с тегом (формат tag: "v...").
    lastTagOld=$(git grep -h -o 'tag: *"v[^"]*"' "$oldCommit" -- src/main/resources/db.changelog 2>/dev/null \
                 | sed -E 's/.*tag: *"([^"]*)".*/\1/' \
                 | tail -1)
fi

# Получение последнего тега Liquibase для нового коммита.
# Поскольку рабочая директория уже на новом коммите, можно читать файлы напрямую.
lastTagNew=$(grep -R -h -o 'tag: *"v[^"]*"' src/main/resources/db.changelog 2>/dev/null \
             | sed -E 's/.*tag: *"([^"]*)".*/\1/' \
             | tail -1)

# Логируем найденные теги для отладки.
echo "Liquibase tag на предыдущем коммите: ${lastTagOld:-<не найден>}"
echo "Liquibase tag на новом коммите: ${lastTagNew:-<не найден>}"

# Шаг 2: Если тег не изменился (либо оба пустые, либо одинаковые значения), то никаких действий не выполняем.
if [ "$lastTagOld" = "$lastTagNew" ]; then
    if [ -z "$lastTagNew" ]; then
        echo "Liquibase: Теги отсутствуют на обоих сравниваемых коммитах или не определены. Операции отката/обновления пропущены."
    else
        echo "Liquibase: Тег не изменился (остался \"$lastTagNew\"). Откат/обновление не требуются."
    fi
    exit 0
fi

# Шаг 3: Проверяем, является ли новый коммит предком старого.
# Если да, это означает, что мы переключаемся на более старый коммит (движение назад по истории).
# В этом случае нужно выполнить откат базы данных до последнего тега нового (более старого) коммита.
if git merge-base --is-ancestor "$newCommit" "$oldCommit"; then
    # Новый коммит находится в истории старого (т.е. новый коммит старше старого).
    echo "Обнаружено переключение на предшествующий коммит (откат к более старой версии)."

    if [ -z "$lastTagNew" ]; then
        # Если в новом (старом по версии) коммите тег не найден, мы не знаем до какого тега откатывать.
        # Это может означать, что коммит датируется периодом до появления первого тега.
        echo "Предупреждение: для коммита $newCommit не найден Liquibase-тег. Откат изменений не может быть выполнен автоматически."
        echo "При необходимости, откатите базу данных до исходного состояния вручную (нет тега для rollback)."
    else
        # Выполняем rollback на найденный тег нового коммита.
        echo "Выполняем 'liquibase rollback' до тега \"$lastTagNew\" соответствующего новому коммиту..."
        if ! liquibase rollback "$lastTagNew"; then
            echo "Ошибка: команда 'liquibase rollback $lastTagNew' завершилась неудачно."
            exit 1
        fi
    fi

# Шаг 4: Если новый коммит не является предком старого, то это либо движение вперёд по истории, либо переключение на другую ветку.
# В этих случаях мы предполагаем, что необходимо применить новые изменения (либо дополнительные, либо отличающиеся) — выполняем liquibase update.
elif git merge-base --is-ancestor "$oldCommit" "$newCommit"; then
    # Старый коммит является предком нового (обычный переход вперёд по истории).
    echo "Обнаружено переключение на более новый коммит (вперёд по истории). Выполняем 'liquibase update'..."
    if ! liquibase update; then
        echo "Ошибка: команда 'liquibase update' завершилась неудачно."
        exit 1
    fi
else
    # Ни один коммит не является предком другого (возможно, переключение между разными ветками, расходящимися по истории).
    # Будем консервативно выполнять обновление, полагая, что новый коммит требует своего состояния базы.
    echo "Обнаружено переключение на коммит из другой ветки или независимой истории. Выполняем 'liquibase update' по умолчанию..."
    if ! liquibase update; then
        echo "Ошибка: команда 'liquibase update' завершилась неудачно."
        exit 1
    fi
fi

# Конец скрипта. На этом этапе, в зависимости от ситуации, был выполнен откат базы данных к нужному тегу или применены обновления.
# Если ни одно из условий не сработало (например, теги отсутствовали и ничего не делалось), скрипт просто завершил работу без изменений.
