--liquibase formatted sql

--changeset Artem_Pupyshev:1.1
CREATE TABLE loan_wipe (
                           id SERIAL PRIMARY KEY,
                           Name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO loan_wipe (Name)
VALUES ('Sberpank'),
       ('TZ-bank');

--rollback DROP TABLE loan_wipe;