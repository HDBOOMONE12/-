--liquibase formatted sql

--changeset Artem_Pupyshev:1 runOnChange:false
CREATE TABLE loan_type (
                           id SERIAL PRIMARY KEY,
                           Name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO loan_type (Name)
VALUES ('Sberpank'),
       ('TZ-bank');

CREATE TABLE students_loans (
                                id SERIAL PRIMARY KEY,
                                First_Name VARCHAR(50) NOT NULL,
                                Second_Name VARCHAR(50) NOT NULL,
                                Loan_Type INT REFERENCES loan_type(id),
                                Loan_Amount NUMERIC(10,4) NOT NULL
);

INSERT INTO students_loans (First_Name, Second_Name, Loan_Type, Loan_Amount)
VALUES ('Artem','Kokos',1,500.2),
       ('Bob','Bobov',2,50000.2);

--rollback DROP TABLE students_loans;
--rollback DROP TABLE loan_type;
