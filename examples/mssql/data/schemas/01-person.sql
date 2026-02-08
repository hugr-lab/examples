-- Adventure Works - Person Schema
-- This script creates Person schema tables and loads sample data

-- =============================================================================
-- PERSON SCHEMA TABLES
-- =============================================================================

-- BusinessEntity: Base table for all persons, stores, and vendors
CREATE TABLE Person.BusinessEntity (
    BusinessEntityID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- AddressType: Types of addresses (Home, Office, Billing, Shipping)
CREATE TABLE Person.AddressType (
    AddressTypeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- CountryRegion: Country and region lookup
CREATE TABLE Person.CountryRegion (
    CountryRegionCode NVARCHAR(3) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- StateProvince: State/province lookup
CREATE TABLE Person.StateProvince (
    StateProvinceID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StateProvinceCode NCHAR(3) NOT NULL,
    CountryRegionCode NVARCHAR(3) NOT NULL,
    IsOnlyStateProvinceFlag BIT NOT NULL DEFAULT 1,
    Name NVARCHAR(50) NOT NULL,
    TerritoryID INT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_StateProvince_CountryRegion FOREIGN KEY (CountryRegionCode)
        REFERENCES Person.CountryRegion (CountryRegionCode)
);
GO

-- Address: Street addresses
CREATE TABLE Person.Address (
    AddressID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AddressLine1 NVARCHAR(60) NOT NULL,
    AddressLine2 NVARCHAR(60) NULL,
    City NVARCHAR(30) NOT NULL,
    StateProvinceID INT NOT NULL,
    PostalCode NVARCHAR(15) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Address_StateProvince FOREIGN KEY (StateProvinceID)
        REFERENCES Person.StateProvince (StateProvinceID)
);
GO

-- ContactType: Types of contacts
CREATE TABLE Person.ContactType (
    ContactTypeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- PhoneNumberType: Types of phone numbers
CREATE TABLE Person.PhoneNumberType (
    PhoneNumberTypeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Person: Human beings
CREATE TABLE Person.Person (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    PersonType NCHAR(2) NOT NULL,
    NameStyle BIT NOT NULL DEFAULT 0,
    Title NVARCHAR(8) NULL,
    FirstName NVARCHAR(50) NOT NULL,
    MiddleName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    Suffix NVARCHAR(10) NULL,
    EmailPromotion INT NOT NULL DEFAULT 0,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Person_BusinessEntity FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.BusinessEntity (BusinessEntityID)
);
GO

-- EmailAddress: Email addresses for persons
CREATE TABLE Person.EmailAddress (
    BusinessEntityID INT NOT NULL,
    EmailAddressID INT IDENTITY(1,1) NOT NULL,
    EmailAddress NVARCHAR(50) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, EmailAddressID),
    CONSTRAINT FK_EmailAddress_Person FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.Person (BusinessEntityID)
);
GO

-- PersonPhone: Phone numbers for persons
CREATE TABLE Person.PersonPhone (
    BusinessEntityID INT NOT NULL,
    PhoneNumber NVARCHAR(25) NOT NULL,
    PhoneNumberTypeID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, PhoneNumber, PhoneNumberTypeID),
    CONSTRAINT FK_PersonPhone_Person FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.Person (BusinessEntityID),
    CONSTRAINT FK_PersonPhone_PhoneNumberType FOREIGN KEY (PhoneNumberTypeID)
        REFERENCES Person.PhoneNumberType (PhoneNumberTypeID)
);
GO

-- BusinessEntityAddress: Links business entities to addresses
CREATE TABLE Person.BusinessEntityAddress (
    BusinessEntityID INT NOT NULL,
    AddressID INT NOT NULL,
    AddressTypeID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, AddressID, AddressTypeID),
    CONSTRAINT FK_BusinessEntityAddress_BusinessEntity FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.BusinessEntity (BusinessEntityID),
    CONSTRAINT FK_BusinessEntityAddress_Address FOREIGN KEY (AddressID)
        REFERENCES Person.Address (AddressID),
    CONSTRAINT FK_BusinessEntityAddress_AddressType FOREIGN KEY (AddressTypeID)
        REFERENCES Person.AddressType (AddressTypeID)
);
GO

-- BusinessEntityContact: Contacts for business entities
CREATE TABLE Person.BusinessEntityContact (
    BusinessEntityID INT NOT NULL,
    PersonID INT NOT NULL,
    ContactTypeID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, PersonID, ContactTypeID),
    CONSTRAINT FK_BusinessEntityContact_BusinessEntity FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.BusinessEntity (BusinessEntityID),
    CONSTRAINT FK_BusinessEntityContact_Person FOREIGN KEY (PersonID)
        REFERENCES Person.Person (BusinessEntityID),
    CONSTRAINT FK_BusinessEntityContact_ContactType FOREIGN KEY (ContactTypeID)
        REFERENCES Person.ContactType (ContactTypeID)
);
GO

-- =============================================================================
-- PERSON SCHEMA SAMPLE DATA
-- =============================================================================

-- Address Types
SET IDENTITY_INSERT Person.AddressType ON;
INSERT INTO Person.AddressType (AddressTypeID, Name) VALUES
(1, 'Billing'), (2, 'Home'), (3, 'Main Office'), (4, 'Primary'), (5, 'Shipping'), (6, 'Archive');
SET IDENTITY_INSERT Person.AddressType OFF;
GO

-- Contact Types
SET IDENTITY_INSERT Person.ContactType ON;
INSERT INTO Person.ContactType (ContactTypeID, Name) VALUES
(1, 'Accounting Manager'), (2, 'Assistant Sales Agent'), (3, 'Assistant Sales Representative'),
(4, 'Coordinator Foreign Markets'), (5, 'Export Administrator'), (6, 'International Marketing Manager'),
(7, 'Marketing Assistant'), (8, 'Marketing Manager'), (9, 'Marketing Representative'),
(10, 'Order Administrator'), (11, 'Owner'), (12, 'Owner/Marketing Assistant'),
(13, 'Purchasing Agent'), (14, 'Purchasing Manager'), (15, 'Regional Account Representative'),
(16, 'Sales Agent'), (17, 'Sales Associate'), (18, 'Sales Manager'), (19, 'Sales Representative');
SET IDENTITY_INSERT Person.ContactType OFF;
GO

-- Phone Number Types
SET IDENTITY_INSERT Person.PhoneNumberType ON;
INSERT INTO Person.PhoneNumberType (PhoneNumberTypeID, Name) VALUES
(1, 'Cell'), (2, 'Home'), (3, 'Work');
SET IDENTITY_INSERT Person.PhoneNumberType OFF;
GO

-- Countries
INSERT INTO Person.CountryRegion (CountryRegionCode, Name) VALUES
('US', 'United States'), ('CA', 'Canada'), ('DE', 'Germany'), ('FR', 'France'),
('GB', 'United Kingdom'), ('AU', 'Australia'), ('JP', 'Japan'), ('MX', 'Mexico');
GO

-- Business Entities (for persons, vendors, stores)
SET IDENTITY_INSERT Person.BusinessEntity ON;
INSERT INTO Person.BusinessEntity (BusinessEntityID) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
(100), (101), (102), (103), (104), (105);
SET IDENTITY_INSERT Person.BusinessEntity OFF;
GO

-- Persons
INSERT INTO Person.Person (BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName, Suffix, EmailPromotion) VALUES
(1, 'EM', 'Mr.', 'Ken', 'J', 'Sanchez', NULL, 0),
(2, 'EM', 'Ms.', 'Terri', 'Lee', 'Duffy', NULL, 1),
(3, 'EM', 'Mr.', 'Roberto', NULL, 'Tamburello', NULL, 0),
(4, 'EM', 'Mr.', 'Rob', NULL, 'Walters', NULL, 0),
(5, 'EM', 'Ms.', 'Gail', 'A', 'Erickson', NULL, 0),
(6, 'EM', 'Mr.', 'Jossef', 'H', 'Goldberg', NULL, 0),
(7, 'EM', 'Mr.', 'Dylan', 'A', 'Miller', NULL, 2),
(8, 'EM', 'Ms.', 'Diane', 'L', 'Margheim', NULL, 0),
(9, 'EM', 'Mr.', 'Gigi', 'N', 'Matthew', NULL, 0),
(10, 'EM', 'Mr.', 'Michael', NULL, 'Raheem', NULL, 2),
(11, 'SC', 'Mr.', 'Orlando', 'N.', 'Gee', NULL, 0),
(12, 'SC', 'Mr.', 'Keith', NULL, 'Harris', NULL, 1),
(13, 'SC', 'Ms.', 'Donna', 'F.', 'Carreras', NULL, 0),
(14, 'SC', 'Ms.', 'Janet', 'M.', 'Gates', NULL, 2),
(15, 'SC', 'Mr.', 'Lucy', NULL, 'Harrington', NULL, 2),
(16, 'IN', 'Mr.', 'Rosmarie', 'J.', 'Carroll', NULL, 0),
(17, 'IN', 'Mr.', 'Dominic', 'P.', 'Gash', NULL, 1),
(18, 'IN', 'Ms.', 'Kathleen', 'M.', 'Garza', NULL, 2),
(19, 'IN', 'Mr.', 'Christopher', 'R.', 'Beck', 'Jr.', 0),
(20, 'IN', 'Ms.', 'David', NULL, 'Liu', NULL, 0);
GO

-- Email Addresses
INSERT INTO Person.EmailAddress (BusinessEntityID, EmailAddress) VALUES
(1, 'ken0@adventure-works.com'),
(2, 'terri0@adventure-works.com'),
(3, 'roberto0@adventure-works.com'),
(4, 'rob0@adventure-works.com'),
(5, 'gail0@adventure-works.com'),
(6, 'jossef0@adventure-works.com'),
(7, 'dylan0@adventure-works.com'),
(8, 'diane1@adventure-works.com'),
(9, 'gigi0@adventure-works.com'),
(10, 'michael6@adventure-works.com'),
(11, 'orlando0@adventure-works.com'),
(12, 'keith0@adventure-works.com'),
(13, 'donna0@adventure-works.com'),
(14, 'janet1@adventure-works.com'),
(15, 'lucy0@adventure-works.com');
GO

-- Phone Numbers
INSERT INTO Person.PersonPhone (BusinessEntityID, PhoneNumber, PhoneNumberTypeID) VALUES
(1, '697-555-0142', 1),
(2, '819-555-0175', 1),
(3, '212-555-0187', 3),
(4, '612-555-0100', 3),
(5, '849-555-0139', 3),
(6, '122-555-0189', 3),
(7, '181-555-0156', 3),
(8, '815-555-0138', 3),
(9, '185-555-0186', 3),
(10, '330-555-2568', 3),
(11, '245-555-0173', 1),
(12, '170-555-0127', 1),
(13, '279-555-0130', 1),
(14, '710-555-0173', 1),
(15, '828-555-0186', 1);
GO

PRINT 'Person schema: 12 tables created and loaded';
GO
