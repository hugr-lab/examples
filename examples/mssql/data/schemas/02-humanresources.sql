-- Adventure Works - Human Resources Schema
-- This script creates HumanResources schema tables and loads sample data

-- =============================================================================
-- HUMAN RESOURCES SCHEMA TABLES
-- =============================================================================

-- Department: Company departments
CREATE TABLE HumanResources.Department (
    DepartmentID SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    GroupName NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Shift: Work shifts
CREATE TABLE HumanResources.Shift (
    ShiftID TINYINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Employee: Employee information
CREATE TABLE HumanResources.Employee (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    NationalIDNumber NVARCHAR(15) NOT NULL,
    LoginID NVARCHAR(256) NOT NULL,
    OrganizationNode HIERARCHYID NULL,
    OrganizationLevel AS OrganizationNode.GetLevel(),
    JobTitle NVARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    MaritalStatus NCHAR(1) NOT NULL,
    Gender NCHAR(1) NOT NULL,
    HireDate DATE NOT NULL,
    SalariedFlag BIT NOT NULL DEFAULT 1,
    VacationHours SMALLINT NOT NULL DEFAULT 0,
    SickLeaveHours SMALLINT NOT NULL DEFAULT 0,
    CurrentFlag BIT NOT NULL DEFAULT 1,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Employee_Person FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.Person (BusinessEntityID)
);
GO

-- EmployeeDepartmentHistory: Employee department assignments over time
CREATE TABLE HumanResources.EmployeeDepartmentHistory (
    BusinessEntityID INT NOT NULL,
    DepartmentID SMALLINT NOT NULL,
    ShiftID TINYINT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, DepartmentID, ShiftID, StartDate),
    CONSTRAINT FK_EmployeeDepartmentHistory_Employee FOREIGN KEY (BusinessEntityID)
        REFERENCES HumanResources.Employee (BusinessEntityID),
    CONSTRAINT FK_EmployeeDepartmentHistory_Department FOREIGN KEY (DepartmentID)
        REFERENCES HumanResources.Department (DepartmentID),
    CONSTRAINT FK_EmployeeDepartmentHistory_Shift FOREIGN KEY (ShiftID)
        REFERENCES HumanResources.Shift (ShiftID)
);
GO

-- EmployeePayHistory: Employee pay rate history
CREATE TABLE HumanResources.EmployeePayHistory (
    BusinessEntityID INT NOT NULL,
    RateChangeDate DATETIME NOT NULL,
    Rate MONEY NOT NULL,
    PayFrequency TINYINT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, RateChangeDate),
    CONSTRAINT FK_EmployeePayHistory_Employee FOREIGN KEY (BusinessEntityID)
        REFERENCES HumanResources.Employee (BusinessEntityID)
);
GO

-- JobCandidate: Job applicants
CREATE TABLE HumanResources.JobCandidate (
    JobCandidateID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BusinessEntityID INT NULL,
    Resume NVARCHAR(MAX) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_JobCandidate_Employee FOREIGN KEY (BusinessEntityID)
        REFERENCES HumanResources.Employee (BusinessEntityID)
);
GO

-- =============================================================================
-- HUMAN RESOURCES SCHEMA SAMPLE DATA
-- =============================================================================

-- Departments
SET IDENTITY_INSERT HumanResources.Department ON;
INSERT INTO HumanResources.Department (DepartmentID, Name, GroupName) VALUES
(1, 'Engineering', 'Research and Development'),
(2, 'Tool Design', 'Research and Development'),
(3, 'Sales', 'Sales and Marketing'),
(4, 'Marketing', 'Sales and Marketing'),
(5, 'Purchasing', 'Inventory Management'),
(6, 'Research and Development', 'Research and Development'),
(7, 'Production', 'Manufacturing'),
(8, 'Production Control', 'Manufacturing'),
(9, 'Human Resources', 'Executive General and Administration'),
(10, 'Finance', 'Executive General and Administration'),
(11, 'Information Services', 'Executive General and Administration'),
(12, 'Document Control', 'Quality Assurance'),
(13, 'Quality Assurance', 'Quality Assurance'),
(14, 'Facilities and Maintenance', 'Executive General and Administration'),
(15, 'Shipping and Receiving', 'Inventory Management'),
(16, 'Executive', 'Executive General and Administration');
SET IDENTITY_INSERT HumanResources.Department OFF;
GO

-- Shifts
SET IDENTITY_INSERT HumanResources.Shift ON;
INSERT INTO HumanResources.Shift (ShiftID, Name, StartTime, EndTime) VALUES
(1, 'Day', '07:00:00', '15:00:00'),
(2, 'Evening', '15:00:00', '23:00:00'),
(3, 'Night', '23:00:00', '07:00:00');
SET IDENTITY_INSERT HumanResources.Shift OFF;
GO

-- Employees
INSERT INTO HumanResources.Employee (BusinessEntityID, NationalIDNumber, LoginID, JobTitle, BirthDate, MaritalStatus, Gender, HireDate, SalariedFlag, VacationHours, SickLeaveHours, CurrentFlag) VALUES
(1, '295847284', 'adventure-works\ken0', 'Chief Executive Officer', '1969-01-29', 'S', 'M', '2009-01-14', 1, 99, 69, 1),
(2, '245797967', 'adventure-works\terri0', 'Vice President of Engineering', '1971-08-01', 'S', 'F', '2008-01-31', 1, 1, 20, 1),
(3, '509647174', 'adventure-works\roberto0', 'Engineering Manager', '1974-11-12', 'M', 'M', '2007-11-11', 1, 2, 21, 1),
(4, '112457891', 'adventure-works\rob0', 'Senior Tool Designer', '1974-12-23', 'S', 'M', '2007-12-05', 0, 16, 28, 1),
(5, '695256908', 'adventure-works\gail0', 'Design Engineer', '1952-09-27', 'M', 'F', '2008-01-06', 1, 5, 22, 1),
(6, '998320692', 'adventure-works\jossef0', 'Design Engineer', '1959-03-11', 'M', 'M', '2008-01-24', 1, 6, 23, 1),
(7, '134969118', 'adventure-works\dylan0', 'Research and Development Manager', '1987-02-24', 'M', 'M', '2009-02-08', 1, 61, 50, 1),
(8, '811994146', 'adventure-works\diane1', 'Research and Development Engineer', '1986-06-05', 'S', 'F', '2008-12-29', 1, 62, 51, 1),
(9, '658797903', 'adventure-works\gigi0', 'Research and Development Engineer', '1979-01-21', 'M', 'F', '2009-01-16', 1, 63, 51, 1),
(10, '879342154', 'adventure-works\michael6', 'Research and Development Manager', '1984-11-30', 'M', 'M', '2009-05-03', 1, 16, 64, 1);
GO

-- Employee Department History
INSERT INTO HumanResources.EmployeeDepartmentHistory (BusinessEntityID, DepartmentID, ShiftID, StartDate) VALUES
(1, 16, 1, '2009-01-14'),
(2, 1, 1, '2008-01-31'),
(3, 1, 1, '2007-11-11'),
(4, 2, 1, '2007-12-05'),
(5, 1, 1, '2008-01-06'),
(6, 1, 1, '2008-01-24'),
(7, 6, 1, '2009-02-08'),
(8, 6, 1, '2008-12-29'),
(9, 6, 1, '2009-01-16'),
(10, 6, 1, '2009-05-03');
GO

-- Employee Pay History
INSERT INTO HumanResources.EmployeePayHistory (BusinessEntityID, RateChangeDate, Rate, PayFrequency) VALUES
(1, '2009-01-14', 125.50, 2),
(2, '2008-01-31', 63.46, 2),
(3, '2007-11-11', 43.27, 2),
(4, '2007-12-05', 29.89, 2),
(5, '2008-01-06', 32.69, 2),
(6, '2008-01-24', 32.69, 2),
(7, '2009-02-08', 50.48, 2),
(8, '2008-12-29', 40.87, 2),
(9, '2009-01-16', 40.87, 2),
(10, '2009-05-03', 42.43, 2);
GO

PRINT 'HumanResources schema: 6 tables created and loaded';
GO
