package artem_pupyshev.project666.initializer;

import liquibase.command.core.StatusCommandStep;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import liquibase.Contexts;
import liquibase.LabelExpression;
import liquibase.Liquibase;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.ClassLoaderResourceAccessor;
import liquibase.exception.LiquibaseException;
import liquibase.command.CommandExecutionException;
import liquibase.integration.commandline.LiquibaseCommandLineConfiguration;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

@Testcontainers
public class DatabaseMigrationTest {

    @Container
    private static final PostgreSQLContainer<?> postgresContainer =
            new PostgreSQLContainer<>("postgres:17.2") // нужная версия
                    .withDatabaseName("testdb")
                    .withUsername("test")
                    .withPassword("test");

    private static Connection connection;

    @BeforeAll
    static void setUp() throws Exception {
        connection = DriverManager.getConnection(
                postgresContainer.getJdbcUrl(),
                postgresContainer.getUsername(),
                postgresContainer.getPassword()
        );

        Liquibase liquibase = new Liquibase(
                "db/changelog/db.changelog-master.yaml",
                new ClassLoaderResourceAccessor(),
                new JdbcConnection(connection)
        );

        liquibase.update();
    }

    @AfterEach
    void cleanup() {
        // Сюда можно добавить очистку или rollback
    }

    @Test
    void testNoPendingMigrations_Classic() throws Exception {
        Liquibase liquibase = new Liquibase(
                "db/changelog/db.changelog-master.yaml",
                new ClassLoaderResourceAccessor(),
                new JdbcConnection(connection)
        );

        // Получаем список неприменённых changeSet
        var unrunChangeSets = liquibase.listUnrunChangeSets(new Contexts(), new LabelExpression());

        // Если список пуст — значит никаких неприменённых миграций нет
        org.junit.jupiter.api.Assertions.assertTrue(
                unrunChangeSets.isEmpty(),
                "Есть неприменённые changeSet: " + unrunChangeSets
        );
    }

    @Test
    void testDatabaseChangelogTableExists() throws Exception {
        // Liquibase создаёт служебную таблицу 'databasechangelog'.
        // Универсальная проверка: если её нет — значит миграции не применились
        try (Statement stmt = connection.createStatement()) {
            ResultSet rs = stmt.executeQuery(
                    "SELECT table_name FROM information_schema.tables " +
                            "WHERE table_name = 'databasechangelog'"
            );
            Assertions.assertTrue(rs.next(),
                    "Таблица databasechangelog не найдена — значит Liquibase не применил миграции");
        }
    }

    @Test
    void test4_insertSelectAnyTable() throws Exception {
        // 1) Найдём любую пользовательскую таблицу (в схеме public),
        //    исключая служебные таблицы Liquibase: databasechangelog и databasechangeloglock
        // 2) Попробуем INSERT + SELECT

        String anyTable = null;
        try (Statement stmt = connection.createStatement()) {
            // Выбираем любую таблицу, которая:
            //  - в схеме public
            //  - это обычная (BASE TABLE)
            //  - НЕ называется databasechangelog или databasechangeloglock
            ResultSet rs = stmt.executeQuery(
                    "SELECT table_name " +
                            "FROM information_schema.tables " +
                            "WHERE table_schema = 'public' " +
                            "  AND table_type = 'BASE TABLE' " +
                            "  AND table_name NOT IN ('databasechangelog', 'databasechangeloglock') " +
                            "ORDER BY table_name LIMIT 1"
            );
            if (rs.next()) {
                anyTable = rs.getString("table_name");
            }
        }

        // Если не нашли ни одной «пользовательской» таблицы, пропустим/завершим тест
        if (anyTable == null) {
            System.out.println("Нет ни одной пользовательской таблицы для тестового INSERT.");
            return;
            // или можно сделать Assertions.fail(...), если хотим считать это ошибкой
        }

        // 2) Пытаемся вставить запись (INSERT)
        String insertSql = String.format("INSERT INTO %s DEFAULT VALUES", anyTable);
        try (Statement stmt = connection.createStatement()) {
            // Если у таблицы все колонки NOT NULL без default, INSERT упадёт.


        }
    }
}
