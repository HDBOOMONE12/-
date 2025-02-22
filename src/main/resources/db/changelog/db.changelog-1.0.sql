--changeSet Artem_Pupyshev:1
--liquibase formatted sql
CREATE TABLE Loan_Type(
                          id serial primary key,
                          Name varchar(50) NOT NULL UNIQUE
);

insert into Loan_Type(Name)
values('Sberpank'),
      ('TZ-bank');




CREATE table Students_Loans(
                               id serial PRIMARY KEY,
                               First_Name varchar(50) NOT NULL,
                               Second_Name varchar(50) NOT NULL ,
                               Loan_Type int references Loan_Type(id),
                               Loan_Amount NUMERIC(10,4) NOT NULL
);

insert into Students_Loans(First_Name,Second_Name,Loan_Type,Loan_Amount)
values ('Artem','Kokos',1,500.2),
       ('Bob','Bobov',2,50000.2);

