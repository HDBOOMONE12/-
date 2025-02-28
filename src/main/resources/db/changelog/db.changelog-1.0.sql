--changeSet Artem_Pupyshev:1
--liquibase formatted sql
CREATE TABLE loan_type(
                          id serial primary key,
                          Name varchar(50) NOT NULL UNIQUE
);

insert into loan_type(Name)
values('Sberpank'),
      ('TZ-bank');




CREATE table students_loans(
                               id serial PRIMARY KEY,
                               First_Name varchar(50) NOT NULL,
                               Second_Name varchar(50) NOT NULL ,
                               Loan_Type int references Loan_Type(id),
                               Loan_Amount NUMERIC(10,4) NOT NULL
);

insert into students_loans(First_Name,Second_Name,Loan_Type,Loan_Amount)
values ('Artem','Kokos',1,500.2),
       ('Bob','Bobov',2,50000.2);

--rollback DROP TABLE students_loans;
--rollback DROP TABLE loan_type;

--tag v1.0

