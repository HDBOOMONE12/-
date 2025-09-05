# 🧩 InfraMigrate — управление миграциями БД (Liquibase + Testcontainers)

[![Java](https://img.shields.io/badge/Java-17%2B-007396?logo=java)](#-требования)
[![Maven](https://img.shields.io/badge/Maven-Project-CC0000?logo=apachemaven)](#-установка-и-запуск)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?logo=postgresql)](#-локальная-разработка)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](#-локальная-разработка)
[![CI](https://img.shields.io/badge/GitHub_Actions-CI-2088FF?logo=githubactions)](#-ci)

**InfraMigrate** — инструмент для безопасного управления изменениями схемы БД.  
Проект помогает: **вносить миграции предсказуемо**, **проверять их автоматически** на чистой базе через **Testcontainers**, и **мигрировать/откатывать** схему без простоя.

---

## 🧭 Зачем
- Снизить риск «сломать прод» невалидной миграцией.
- Проверять миграции автоматически на чистом PostgreSQL (Testcontainers) до деплоя.
- Иметь единый, воспроизводимый процесс для разработчиков и CI.

---

## ⚙️ Требования
- **Java 17+** (или используйте версию из `pom.xml`).
- **Maven 3.8+**.
- **Docker** и **docker-compose** для локальной базы.

---

## 🚀 Установка и запуск

```bash
git clone https://github.com/HDBOOMONE12/InfraMigrate.git
cd InfraMigrate
mvn -q -DskipTests clean package
```

> Переменные окружения задаются в `.env` (если используется) и/или через Maven-профили.

---

## 🧪 Локальная разработка

Поднимите PostgreSQL локально (пример):
```bash
docker compose up -d
# или: docker-compose up -d
```

Прогон тестов с автоподъёмом временной БД (Testcontainers):
```bash
mvn test
```

Применение миграций (вариант через Maven Liquibase Plugin, если настроен):
```bash
mvn liquibase:update
# откат на шаг
mvn liquibase:rollback -Dliquibase.rollbackCount=1
```

> Если миграции запускаются из кода/тестов, используйте команды тестового профиля. Конкретные goal’ы смотрите в `pom.xml`.

---

## 🔄 Типовой поток работ

1. Создайте новую миграцию в changelog (например, `src/main/resources/db/changelog/`).
2. Запустите `mvn test` — миграции прогонятся на чистой базе (Testcontainers).
3. При необходимости добавьте «rollback» для обратимости.
4. Закоммитьте изменения; в CI всё повторится автоматически.
5. На окружениях — применяйте миграции через Liquibase (CLI/Maven) по тому же changelog’у.

---

## 🗂️ Структура проекта
```text
.
├── .github/workflows/         # CI (GitHub Actions)
├── .mvn/wrapper/              # Maven Wrapper
├── src/                       # код/ресурсы проекта
├── Dockerfile                 # образ сервиса/утилиты
├── docker-compose.yml         # локальный PostgreSQL и окружение
├── pom.xml                    # зависимости/плагины (Liquibase, Testcontainers и пр.)
└── .gitignore
```

---

## 🧰 Технологии
- **Liquibase** — версионирование схемы и откаты.
- **Testcontainers** — автоподнятие чистой PostgreSQL в тестах.
- **Docker/Compose** — локальная инфраструктура.
- **GitHub Actions** — CI: сборка, тесты, проверка миграций.

---

## 🧪 CI
- В репозитории настроены workflow’ы в `.github/workflows/` (сборка/тесты/проверки).  
  При каждом пуше прогоняются тесты и валидация миграций.
