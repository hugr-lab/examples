-- Adventure Works Full Schema and Sample Data for SQL Server 2022
-- This script creates the complete Adventure Works database with all schemas:
-- Person, HumanResources, Production, Purchasing, Sales

-- =============================================================================
-- CREATE SCHEMAS
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Person')
    EXEC('CREATE SCHEMA Person');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'HumanResources')
    EXEC('CREATE SCHEMA HumanResources');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Production')
    EXEC('CREATE SCHEMA Production');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Purchasing')
    EXEC('CREATE SCHEMA Purchasing');
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Sales')
    EXEC('CREATE SCHEMA Sales');
GO

-- =============================================================================
-- PERSON SCHEMA
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
-- HUMAN RESOURCES SCHEMA
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
-- PRODUCTION SCHEMA
-- =============================================================================

-- UnitMeasure: Units of measure
CREATE TABLE Production.UnitMeasure (
    UnitMeasureCode NCHAR(3) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ProductCategory: Top-level product categories
CREATE TABLE Production.ProductCategory (
    ProductCategoryID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ProductSubcategory: Product subcategories
CREATE TABLE Production.ProductSubcategory (
    ProductSubcategoryID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductCategoryID INT NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ProductSubcategory_ProductCategory FOREIGN KEY (ProductCategoryID)
        REFERENCES Production.ProductCategory (ProductCategoryID)
);
GO

-- ProductModel: Product model definitions
CREATE TABLE Production.ProductModel (
    ProductModelID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    CatalogDescription NVARCHAR(MAX) NULL,
    Instructions NVARCHAR(MAX) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Product: Products sold or used in manufacturing
CREATE TABLE Production.Product (
    ProductID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ProductNumber NVARCHAR(25) NOT NULL UNIQUE,
    MakeFlag BIT NOT NULL DEFAULT 1,
    FinishedGoodsFlag BIT NOT NULL DEFAULT 1,
    Color NVARCHAR(15) NULL,
    SafetyStockLevel SMALLINT NOT NULL,
    ReorderPoint SMALLINT NOT NULL,
    StandardCost MONEY NOT NULL,
    ListPrice MONEY NOT NULL,
    Size NVARCHAR(5) NULL,
    SizeUnitMeasureCode NCHAR(3) NULL,
    WeightUnitMeasureCode NCHAR(3) NULL,
    Weight DECIMAL(8,2) NULL,
    DaysToManufacture INT NOT NULL,
    ProductLine NCHAR(2) NULL,
    Class NCHAR(2) NULL,
    Style NCHAR(2) NULL,
    ProductSubcategoryID INT NULL,
    ProductModelID INT NULL,
    SellStartDate DATETIME NOT NULL,
    SellEndDate DATETIME NULL,
    DiscontinuedDate DATETIME NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Product_ProductSubcategory FOREIGN KEY (ProductSubcategoryID)
        REFERENCES Production.ProductSubcategory (ProductSubcategoryID),
    CONSTRAINT FK_Product_ProductModel FOREIGN KEY (ProductModelID)
        REFERENCES Production.ProductModel (ProductModelID),
    CONSTRAINT FK_Product_SizeUnitMeasure FOREIGN KEY (SizeUnitMeasureCode)
        REFERENCES Production.UnitMeasure (UnitMeasureCode),
    CONSTRAINT FK_Product_WeightUnitMeasure FOREIGN KEY (WeightUnitMeasureCode)
        REFERENCES Production.UnitMeasure (UnitMeasureCode)
);
GO

-- ProductDescription: Product descriptions
CREATE TABLE Production.ProductDescription (
    ProductDescriptionID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Description NVARCHAR(400) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Culture: Languages/cultures
CREATE TABLE Production.Culture (
    CultureID NCHAR(6) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ProductModelProductDescriptionCulture: Localized product descriptions
CREATE TABLE Production.ProductModelProductDescriptionCulture (
    ProductModelID INT NOT NULL,
    ProductDescriptionID INT NOT NULL,
    CultureID NCHAR(6) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (ProductModelID, ProductDescriptionID, CultureID),
    CONSTRAINT FK_PMPDC_ProductModel FOREIGN KEY (ProductModelID)
        REFERENCES Production.ProductModel (ProductModelID),
    CONSTRAINT FK_PMPDC_ProductDescription FOREIGN KEY (ProductDescriptionID)
        REFERENCES Production.ProductDescription (ProductDescriptionID),
    CONSTRAINT FK_PMPDC_Culture FOREIGN KEY (CultureID)
        REFERENCES Production.Culture (CultureID)
);
GO

-- Location: Inventory locations
CREATE TABLE Production.Location (
    LocationID SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    CostRate SMALLMONEY NOT NULL DEFAULT 0.00,
    Availability DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ProductInventory: Product inventory at locations
CREATE TABLE Production.ProductInventory (
    ProductID INT NOT NULL,
    LocationID SMALLINT NOT NULL,
    Shelf NVARCHAR(10) NOT NULL,
    Bin TINYINT NOT NULL,
    Quantity SMALLINT NOT NULL DEFAULT 0,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (ProductID, LocationID),
    CONSTRAINT FK_ProductInventory_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID),
    CONSTRAINT FK_ProductInventory_Location FOREIGN KEY (LocationID)
        REFERENCES Production.Location (LocationID)
);
GO

-- ProductCostHistory: Product cost history
CREATE TABLE Production.ProductCostHistory (
    ProductID INT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    StandardCost MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (ProductID, StartDate),
    CONSTRAINT FK_ProductCostHistory_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- ProductListPriceHistory: Product list price history
CREATE TABLE Production.ProductListPriceHistory (
    ProductID INT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    ListPrice MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (ProductID, StartDate),
    CONSTRAINT FK_ProductListPriceHistory_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- ProductReview: Customer product reviews
CREATE TABLE Production.ProductReview (
    ProductReviewID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,
    ReviewerName NVARCHAR(50) NOT NULL,
    ReviewDate DATETIME NOT NULL DEFAULT GETDATE(),
    EmailAddress NVARCHAR(50) NOT NULL,
    Rating INT NOT NULL,
    Comments NVARCHAR(3850) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ProductReview_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- ScrapReason: Manufacturing scrap reasons
CREATE TABLE Production.ScrapReason (
    ScrapReasonID SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- WorkOrder: Manufacturing work orders
CREATE TABLE Production.WorkOrder (
    WorkOrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,
    OrderQty INT NOT NULL,
    StockedQty AS (OrderQty - ScrappedQty),
    ScrappedQty SMALLINT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    DueDate DATETIME NOT NULL,
    ScrapReasonID SMALLINT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_WorkOrder_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID),
    CONSTRAINT FK_WorkOrder_ScrapReason FOREIGN KEY (ScrapReasonID)
        REFERENCES Production.ScrapReason (ScrapReasonID)
);
GO

-- WorkOrderRouting: Work order routing through locations
CREATE TABLE Production.WorkOrderRouting (
    WorkOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    OperationSequence SMALLINT NOT NULL,
    LocationID SMALLINT NOT NULL,
    ScheduledStartDate DATETIME NOT NULL,
    ScheduledEndDate DATETIME NOT NULL,
    ActualStartDate DATETIME NULL,
    ActualEndDate DATETIME NULL,
    ActualResourceHrs DECIMAL(9,4) NULL,
    PlannedCost MONEY NOT NULL,
    ActualCost MONEY NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (WorkOrderID, ProductID, OperationSequence),
    CONSTRAINT FK_WorkOrderRouting_WorkOrder FOREIGN KEY (WorkOrderID)
        REFERENCES Production.WorkOrder (WorkOrderID),
    CONSTRAINT FK_WorkOrderRouting_Location FOREIGN KEY (LocationID)
        REFERENCES Production.Location (LocationID)
);
GO

-- BillOfMaterials: Product components
CREATE TABLE Production.BillOfMaterials (
    BillOfMaterialsID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductAssemblyID INT NULL,
    ComponentID INT NOT NULL,
    StartDate DATETIME NOT NULL DEFAULT GETDATE(),
    EndDate DATETIME NULL,
    UnitMeasureCode NCHAR(3) NOT NULL,
    BOMLevel SMALLINT NOT NULL,
    PerAssemblyQty DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_BillOfMaterials_ProductAssembly FOREIGN KEY (ProductAssemblyID)
        REFERENCES Production.Product (ProductID),
    CONSTRAINT FK_BillOfMaterials_Component FOREIGN KEY (ComponentID)
        REFERENCES Production.Product (ProductID),
    CONSTRAINT FK_BillOfMaterials_UnitMeasure FOREIGN KEY (UnitMeasureCode)
        REFERENCES Production.UnitMeasure (UnitMeasureCode)
);
GO

-- TransactionHistory: Product transaction history
CREATE TABLE Production.TransactionHistory (
    TransactionID INT IDENTITY(100000,1) NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,
    ReferenceOrderID INT NOT NULL,
    ReferenceOrderLineID INT NOT NULL DEFAULT 0,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    TransactionType NCHAR(1) NOT NULL,
    Quantity INT NOT NULL,
    ActualCost MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_TransactionHistory_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- =============================================================================
-- PURCHASING SCHEMA
-- =============================================================================

-- ShipMethod: Shipping methods
CREATE TABLE Purchasing.ShipMethod (
    ShipMethodID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ShipBase MONEY NOT NULL DEFAULT 0.00,
    ShipRate MONEY NOT NULL DEFAULT 0.00,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Vendor: Product vendors
CREATE TABLE Purchasing.Vendor (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    AccountNumber NVARCHAR(15) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    CreditRating TINYINT NOT NULL,
    PreferredVendorStatus BIT NOT NULL DEFAULT 1,
    ActiveFlag BIT NOT NULL DEFAULT 1,
    PurchasingWebServiceURL NVARCHAR(1024) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Vendor_BusinessEntity FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.BusinessEntity (BusinessEntityID)
);
GO

-- ProductVendor: Products supplied by vendors
CREATE TABLE Purchasing.ProductVendor (
    ProductID INT NOT NULL,
    BusinessEntityID INT NOT NULL,
    AverageLeadTime INT NOT NULL,
    StandardPrice MONEY NOT NULL,
    LastReceiptCost MONEY NULL,
    LastReceiptDate DATETIME NULL,
    MinOrderQty INT NOT NULL,
    MaxOrderQty INT NOT NULL,
    OnOrderQty INT NULL,
    UnitMeasureCode NCHAR(3) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (ProductID, BusinessEntityID),
    CONSTRAINT FK_ProductVendor_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID),
    CONSTRAINT FK_ProductVendor_Vendor FOREIGN KEY (BusinessEntityID)
        REFERENCES Purchasing.Vendor (BusinessEntityID),
    CONSTRAINT FK_ProductVendor_UnitMeasure FOREIGN KEY (UnitMeasureCode)
        REFERENCES Production.UnitMeasure (UnitMeasureCode)
);
GO

-- PurchaseOrderHeader: Purchase order headers
CREATE TABLE Purchasing.PurchaseOrderHeader (
    PurchaseOrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RevisionNumber TINYINT NOT NULL DEFAULT 0,
    Status TINYINT NOT NULL DEFAULT 1,
    EmployeeID INT NOT NULL,
    VendorID INT NOT NULL,
    ShipMethodID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    ShipDate DATETIME NULL,
    SubTotal MONEY NOT NULL DEFAULT 0.00,
    TaxAmt MONEY NOT NULL DEFAULT 0.00,
    Freight MONEY NOT NULL DEFAULT 0.00,
    TotalDue AS (SubTotal + TaxAmt + Freight),
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_PurchaseOrderHeader_Employee FOREIGN KEY (EmployeeID)
        REFERENCES HumanResources.Employee (BusinessEntityID),
    CONSTRAINT FK_PurchaseOrderHeader_Vendor FOREIGN KEY (VendorID)
        REFERENCES Purchasing.Vendor (BusinessEntityID),
    CONSTRAINT FK_PurchaseOrderHeader_ShipMethod FOREIGN KEY (ShipMethodID)
        REFERENCES Purchasing.ShipMethod (ShipMethodID)
);
GO

-- PurchaseOrderDetail: Purchase order line items
CREATE TABLE Purchasing.PurchaseOrderDetail (
    PurchaseOrderID INT NOT NULL,
    PurchaseOrderDetailID INT IDENTITY(1,1) NOT NULL,
    DueDate DATETIME NOT NULL,
    OrderQty SMALLINT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice MONEY NOT NULL,
    LineTotal AS (OrderQty * UnitPrice),
    ReceivedQty DECIMAL(8,2) NOT NULL,
    RejectedQty DECIMAL(8,2) NOT NULL,
    StockedQty AS (ReceivedQty - RejectedQty),
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (PurchaseOrderID, PurchaseOrderDetailID),
    CONSTRAINT FK_PurchaseOrderDetail_PurchaseOrderHeader FOREIGN KEY (PurchaseOrderID)
        REFERENCES Purchasing.PurchaseOrderHeader (PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderDetail_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- =============================================================================
-- SALES SCHEMA
-- =============================================================================

-- SalesTerritory: Sales territories
CREATE TABLE Sales.SalesTerritory (
    TerritoryID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    CountryRegionCode NVARCHAR(3) NOT NULL,
    [Group] NVARCHAR(50) NOT NULL,
    SalesYTD MONEY NOT NULL DEFAULT 0.00,
    SalesLastYear MONEY NOT NULL DEFAULT 0.00,
    CostYTD MONEY NOT NULL DEFAULT 0.00,
    CostLastYear MONEY NOT NULL DEFAULT 0.00,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_SalesTerritory_CountryRegion FOREIGN KEY (CountryRegionCode)
        REFERENCES Person.CountryRegion (CountryRegionCode)
);
GO

-- Update StateProvince to reference SalesTerritory
ALTER TABLE Person.StateProvince
ADD CONSTRAINT FK_StateProvince_SalesTerritory FOREIGN KEY (TerritoryID)
    REFERENCES Sales.SalesTerritory (TerritoryID);
GO

-- SalesPerson: Sales representatives
CREATE TABLE Sales.SalesPerson (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    TerritoryID INT NULL,
    SalesQuota MONEY NULL,
    Bonus MONEY NOT NULL DEFAULT 0.00,
    CommissionPct SMALLMONEY NOT NULL DEFAULT 0.00,
    SalesYTD MONEY NOT NULL DEFAULT 0.00,
    SalesLastYear MONEY NOT NULL DEFAULT 0.00,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_SalesPerson_Employee FOREIGN KEY (BusinessEntityID)
        REFERENCES HumanResources.Employee (BusinessEntityID),
    CONSTRAINT FK_SalesPerson_SalesTerritory FOREIGN KEY (TerritoryID)
        REFERENCES Sales.SalesTerritory (TerritoryID)
);
GO

-- SalesPersonQuotaHistory: Sales quota history
CREATE TABLE Sales.SalesPersonQuotaHistory (
    BusinessEntityID INT NOT NULL,
    QuotaDate DATETIME NOT NULL,
    SalesQuota MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, QuotaDate),
    CONSTRAINT FK_SalesPersonQuotaHistory_SalesPerson FOREIGN KEY (BusinessEntityID)
        REFERENCES Sales.SalesPerson (BusinessEntityID)
);
GO

-- SalesTerritoryHistory: Sales person territory assignments
CREATE TABLE Sales.SalesTerritoryHistory (
    BusinessEntityID INT NOT NULL,
    TerritoryID INT NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, TerritoryID, StartDate),
    CONSTRAINT FK_SalesTerritoryHistory_SalesPerson FOREIGN KEY (BusinessEntityID)
        REFERENCES Sales.SalesPerson (BusinessEntityID),
    CONSTRAINT FK_SalesTerritoryHistory_SalesTerritory FOREIGN KEY (TerritoryID)
        REFERENCES Sales.SalesTerritory (TerritoryID)
);
GO

-- Store: Retail stores
CREATE TABLE Sales.Store (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    SalesPersonID INT NULL,
    Demographics NVARCHAR(MAX) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Store_BusinessEntity FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.BusinessEntity (BusinessEntityID),
    CONSTRAINT FK_Store_SalesPerson FOREIGN KEY (SalesPersonID)
        REFERENCES Sales.SalesPerson (BusinessEntityID)
);
GO

-- Customer: Customers (individuals or stores)
CREATE TABLE Sales.Customer (
    CustomerID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PersonID INT NULL,
    StoreID INT NULL,
    TerritoryID INT NULL,
    AccountNumber AS ('AW' + RIGHT('00000000' + CAST(CustomerID AS VARCHAR(10)), 8)),
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Customer_Person FOREIGN KEY (PersonID)
        REFERENCES Person.Person (BusinessEntityID),
    CONSTRAINT FK_Customer_Store FOREIGN KEY (StoreID)
        REFERENCES Sales.Store (BusinessEntityID),
    CONSTRAINT FK_Customer_SalesTerritory FOREIGN KEY (TerritoryID)
        REFERENCES Sales.SalesTerritory (TerritoryID)
);
GO

-- Currency: Currencies
CREATE TABLE Sales.Currency (
    CurrencyCode NCHAR(3) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- CurrencyRate: Currency exchange rates
CREATE TABLE Sales.CurrencyRate (
    CurrencyRateID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CurrencyRateDate DATETIME NOT NULL,
    FromCurrencyCode NCHAR(3) NOT NULL,
    ToCurrencyCode NCHAR(3) NOT NULL,
    AverageRate MONEY NOT NULL,
    EndOfDayRate MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CurrencyRate_FromCurrency FOREIGN KEY (FromCurrencyCode)
        REFERENCES Sales.Currency (CurrencyCode),
    CONSTRAINT FK_CurrencyRate_ToCurrency FOREIGN KEY (ToCurrencyCode)
        REFERENCES Sales.Currency (CurrencyCode)
);
GO

-- CountryRegionCurrency: Country/region currencies
CREATE TABLE Sales.CountryRegionCurrency (
    CountryRegionCode NVARCHAR(3) NOT NULL,
    CurrencyCode NCHAR(3) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (CountryRegionCode, CurrencyCode),
    CONSTRAINT FK_CountryRegionCurrency_CountryRegion FOREIGN KEY (CountryRegionCode)
        REFERENCES Person.CountryRegion (CountryRegionCode),
    CONSTRAINT FK_CountryRegionCurrency_Currency FOREIGN KEY (CurrencyCode)
        REFERENCES Sales.Currency (CurrencyCode)
);
GO

-- CreditCard: Credit cards
CREATE TABLE Sales.CreditCard (
    CreditCardID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CardType NVARCHAR(50) NOT NULL,
    CardNumber NVARCHAR(25) NOT NULL,
    ExpMonth TINYINT NOT NULL,
    ExpYear SMALLINT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- PersonCreditCard: Person credit card associations
CREATE TABLE Sales.PersonCreditCard (
    BusinessEntityID INT NOT NULL,
    CreditCardID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BusinessEntityID, CreditCardID),
    CONSTRAINT FK_PersonCreditCard_Person FOREIGN KEY (BusinessEntityID)
        REFERENCES Person.Person (BusinessEntityID),
    CONSTRAINT FK_PersonCreditCard_CreditCard FOREIGN KEY (CreditCardID)
        REFERENCES Sales.CreditCard (CreditCardID)
);
GO

-- SpecialOffer: Special offers/discounts
CREATE TABLE Sales.SpecialOffer (
    SpecialOfferID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Description NVARCHAR(255) NOT NULL,
    DiscountPct SMALLMONEY NOT NULL DEFAULT 0.00,
    Type NVARCHAR(50) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    MinQty INT NOT NULL DEFAULT 0,
    MaxQty INT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- SpecialOfferProduct: Products included in special offers
CREATE TABLE Sales.SpecialOfferProduct (
    SpecialOfferID INT NOT NULL,
    ProductID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (SpecialOfferID, ProductID),
    CONSTRAINT FK_SpecialOfferProduct_SpecialOffer FOREIGN KEY (SpecialOfferID)
        REFERENCES Sales.SpecialOffer (SpecialOfferID),
    CONSTRAINT FK_SpecialOfferProduct_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- SalesReason: Sales reasons
CREATE TABLE Sales.SalesReason (
    SalesReasonID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(50) NOT NULL,
    ReasonType NVARCHAR(50) NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- SalesOrderHeader: Sales order headers
CREATE TABLE Sales.SalesOrderHeader (
    SalesOrderID INT IDENTITY(43659,1) NOT NULL PRIMARY KEY,
    RevisionNumber TINYINT NOT NULL DEFAULT 0,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NULL,
    Status TINYINT NOT NULL DEFAULT 1,
    OnlineOrderFlag BIT NOT NULL DEFAULT 1,
    SalesOrderNumber AS ('SO' + CONVERT(NVARCHAR(23), SalesOrderID)),
    PurchaseOrderNumber NVARCHAR(25) NULL,
    AccountNumber NVARCHAR(15) NULL,
    CustomerID INT NOT NULL,
    SalesPersonID INT NULL,
    TerritoryID INT NULL,
    BillToAddressID INT NOT NULL,
    ShipToAddressID INT NOT NULL,
    ShipMethodID INT NOT NULL,
    CreditCardID INT NULL,
    CreditCardApprovalCode NVARCHAR(15) NULL,
    CurrencyRateID INT NULL,
    SubTotal MONEY NOT NULL DEFAULT 0.00,
    TaxAmt MONEY NOT NULL DEFAULT 0.00,
    Freight MONEY NOT NULL DEFAULT 0.00,
    TotalDue AS (SubTotal + TaxAmt + Freight),
    Comment NVARCHAR(128) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_SalesOrderHeader_Customer FOREIGN KEY (CustomerID)
        REFERENCES Sales.Customer (CustomerID),
    CONSTRAINT FK_SalesOrderHeader_SalesPerson FOREIGN KEY (SalesPersonID)
        REFERENCES Sales.SalesPerson (BusinessEntityID),
    CONSTRAINT FK_SalesOrderHeader_SalesTerritory FOREIGN KEY (TerritoryID)
        REFERENCES Sales.SalesTerritory (TerritoryID),
    CONSTRAINT FK_SalesOrderHeader_BillToAddress FOREIGN KEY (BillToAddressID)
        REFERENCES Person.Address (AddressID),
    CONSTRAINT FK_SalesOrderHeader_ShipToAddress FOREIGN KEY (ShipToAddressID)
        REFERENCES Person.Address (AddressID),
    CONSTRAINT FK_SalesOrderHeader_ShipMethod FOREIGN KEY (ShipMethodID)
        REFERENCES Purchasing.ShipMethod (ShipMethodID),
    CONSTRAINT FK_SalesOrderHeader_CreditCard FOREIGN KEY (CreditCardID)
        REFERENCES Sales.CreditCard (CreditCardID),
    CONSTRAINT FK_SalesOrderHeader_CurrencyRate FOREIGN KEY (CurrencyRateID)
        REFERENCES Sales.CurrencyRate (CurrencyRateID)
);
GO

-- SalesOrderDetail: Sales order line items
CREATE TABLE Sales.SalesOrderDetail (
    SalesOrderID INT NOT NULL,
    SalesOrderDetailID INT IDENTITY(1,1) NOT NULL,
    CarrierTrackingNumber NVARCHAR(25) NULL,
    OrderQty SMALLINT NOT NULL,
    ProductID INT NOT NULL,
    SpecialOfferID INT NOT NULL,
    UnitPrice MONEY NOT NULL,
    UnitPriceDiscount MONEY NOT NULL DEFAULT 0.00,
    LineTotal AS (UnitPrice * (1.00 - UnitPriceDiscount) * OrderQty),
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (SalesOrderID, SalesOrderDetailID),
    CONSTRAINT FK_SalesOrderDetail_SalesOrderHeader FOREIGN KEY (SalesOrderID)
        REFERENCES Sales.SalesOrderHeader (SalesOrderID) ON DELETE CASCADE,
    CONSTRAINT FK_SalesOrderDetail_SpecialOfferProduct FOREIGN KEY (SpecialOfferID, ProductID)
        REFERENCES Sales.SpecialOfferProduct (SpecialOfferID, ProductID)
);
GO

-- SalesOrderHeaderSalesReason: Sales reasons for orders
CREATE TABLE Sales.SalesOrderHeaderSalesReason (
    SalesOrderID INT NOT NULL,
    SalesReasonID INT NOT NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (SalesOrderID, SalesReasonID),
    CONSTRAINT FK_SalesOrderHeaderSalesReason_SalesOrderHeader FOREIGN KEY (SalesOrderID)
        REFERENCES Sales.SalesOrderHeader (SalesOrderID) ON DELETE CASCADE,
    CONSTRAINT FK_SalesOrderHeaderSalesReason_SalesReason FOREIGN KEY (SalesReasonID)
        REFERENCES Sales.SalesReason (SalesReasonID)
);
GO

-- ShoppingCartItem: Shopping cart items
CREATE TABLE Sales.ShoppingCartItem (
    ShoppingCartItemID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ShoppingCartID NVARCHAR(50) NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    ProductID INT NOT NULL,
    DateCreated DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ShoppingCartItem_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product (ProductID)
);
GO

-- =============================================================================
-- SAMPLE DATA
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

-- Currencies
INSERT INTO Sales.Currency (CurrencyCode, Name) VALUES
('USD', 'US Dollar'), ('CAD', 'Canadian Dollar'), ('EUR', 'Euro'),
('GBP', 'British Pound'), ('AUD', 'Australian Dollar'), ('JPY', 'Japanese Yen'), ('MXN', 'Mexican Peso');
GO

-- Country Region Currencies
INSERT INTO Sales.CountryRegionCurrency (CountryRegionCode, CurrencyCode) VALUES
('US', 'USD'), ('CA', 'CAD'), ('DE', 'EUR'), ('FR', 'EUR'),
('GB', 'GBP'), ('AU', 'AUD'), ('JP', 'JPY'), ('MX', 'MXN');
GO

-- Sales Territories
SET IDENTITY_INSERT Sales.SalesTerritory ON;
INSERT INTO Sales.SalesTerritory (TerritoryID, Name, CountryRegionCode, [Group], SalesYTD, SalesLastYear) VALUES
(1, 'Northwest', 'US', 'North America', 7887186.78, 3298694.49),
(2, 'Northeast', 'US', 'North America', 3607148.94, 3607148.94),
(3, 'Central', 'US', 'North America', 4677218.04, 3205014.08),
(4, 'Southwest', 'US', 'North America', 10510853.87, 5366575.99),
(5, 'Southeast', 'US', 'North America', 2315185.61, 2315185.61),
(6, 'Canada', 'CA', 'North America', 6771829.14, 5765086.72),
(7, 'France', 'FR', 'Europe', 4772398.31, 2396539.76),
(8, 'Germany', 'DE', 'Europe', 3805202.15, 1307949.79),
(9, 'Australia', 'AU', 'Pacific', 5977814.91, 2278548.98),
(10, 'United Kingdom', 'GB', 'Europe', 5012905.37, 1635823.35);
SET IDENTITY_INSERT Sales.SalesTerritory OFF;
GO

-- States/Provinces
SET IDENTITY_INSERT Person.StateProvince ON;
INSERT INTO Person.StateProvince (StateProvinceID, StateProvinceCode, CountryRegionCode, Name, TerritoryID) VALUES
(1, 'WA', 'US', 'Washington', 1), (2, 'OR', 'US', 'Oregon', 1), (3, 'CA', 'US', 'California', 4),
(4, 'TX', 'US', 'Texas', 4), (5, 'NY', 'US', 'New York', 2), (6, 'FL', 'US', 'Florida', 5),
(7, 'IL', 'US', 'Illinois', 3), (8, 'ON', 'CA', 'Ontario', 6), (9, 'BC', 'CA', 'British Columbia', 6),
(10, 'AB', 'CA', 'Alberta', 6);
SET IDENTITY_INSERT Person.StateProvince OFF;
GO

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

-- Unit Measures
INSERT INTO Production.UnitMeasure (UnitMeasureCode, Name) VALUES
('CM', 'Centimeters'), ('DZ', 'Dozen'), ('EA', 'Each'), ('FT', 'Feet'),
('GAL', 'Gallons'), ('G', 'Grams'), ('IN', 'Inches'), ('KG', 'Kilograms'),
('L', 'Liters'), ('LB', 'Pounds'), ('M', 'Meters'), ('ML', 'Milliliters'),
('MM', 'Millimeters'), ('OZ', 'Ounces'), ('PC', 'Piece'), ('PCT', 'Percentage');
GO

-- Product Categories
SET IDENTITY_INSERT Production.ProductCategory ON;
INSERT INTO Production.ProductCategory (ProductCategoryID, Name) VALUES
(1, 'Bikes'), (2, 'Components'), (3, 'Clothing'), (4, 'Accessories');
SET IDENTITY_INSERT Production.ProductCategory OFF;
GO

-- Product Subcategories
SET IDENTITY_INSERT Production.ProductSubcategory ON;
INSERT INTO Production.ProductSubcategory (ProductSubcategoryID, ProductCategoryID, Name) VALUES
(1, 1, 'Mountain Bikes'), (2, 1, 'Road Bikes'), (3, 1, 'Touring Bikes'),
(4, 2, 'Handlebars'), (5, 2, 'Bottom Brackets'), (6, 2, 'Brakes'),
(7, 2, 'Chains'), (8, 2, 'Cranksets'), (9, 2, 'Derailleurs'),
(10, 2, 'Forks'), (11, 2, 'Headsets'), (12, 2, 'Mountain Frames'),
(13, 2, 'Pedals'), (14, 2, 'Road Frames'), (15, 2, 'Saddles'),
(16, 2, 'Touring Frames'), (17, 2, 'Wheels'),
(18, 3, 'Bib-Shorts'), (19, 3, 'Caps'), (20, 3, 'Gloves'),
(21, 3, 'Jerseys'), (22, 3, 'Shorts'), (23, 3, 'Socks'),
(24, 3, 'Tights'), (25, 3, 'Vests'),
(26, 4, 'Bike Racks'), (27, 4, 'Bike Stands'), (28, 4, 'Bottles and Cages'),
(29, 4, 'Cleaners'), (30, 4, 'Fenders'), (31, 4, 'Helmets'),
(32, 4, 'Hydration Packs'), (33, 4, 'Lights'), (34, 4, 'Locks'),
(35, 4, 'Panniers'), (36, 4, 'Pumps'), (37, 4, 'Tires and Tubes');
SET IDENTITY_INSERT Production.ProductSubcategory OFF;
GO

-- Product Models
SET IDENTITY_INSERT Production.ProductModel ON;
INSERT INTO Production.ProductModel (ProductModelID, Name, CatalogDescription) VALUES
(1, 'Classic Vest', 'Classic vest for all weather conditions'),
(2, 'Cycling Cap', 'Lightweight cycling cap'),
(3, 'Full-Finger Gloves', 'Full coverage gloves for cold weather'),
(4, 'Half-Finger Gloves', 'Half finger gloves for warm weather'),
(5, 'HL Road Frame', 'High-end road frame for professional cyclists'),
(6, 'LL Road Frame', 'Entry-level road frame'),
(7, 'ML Road Frame', 'Mid-level road frame'),
(8, 'HL Mountain Frame', 'High-end mountain frame'),
(9, 'LL Mountain Frame', 'Entry-level mountain frame'),
(10, 'ML Mountain Frame', 'Mid-level mountain frame'),
(11, 'Long-Sleeve Logo Jersey', 'Long sleeve jersey with logo'),
(12, 'Short-Sleeve Classic Jersey', 'Classic short sleeve jersey'),
(13, 'Mountain-100', 'Top of the line mountain bike'),
(14, 'Mountain-200', 'Mid-range mountain bike'),
(15, 'Mountain-300', 'Entry level mountain bike'),
(16, 'Road-150', 'Professional road bike'),
(17, 'Road-250', 'Mid-range road bike'),
(18, 'Road-350', 'Entry level road bike'),
(19, 'Road-450', 'Budget road bike'),
(20, 'Road-550', 'Basic road bike'),
(21, 'Touring-1000', 'Premium touring bike'),
(22, 'Touring-2000', 'Mid-range touring bike'),
(23, 'Touring-3000', 'Entry level touring bike'),
(24, 'Sport-100', 'Sport helmet model'),
(25, 'Water Bottle', 'Standard water bottle');
SET IDENTITY_INSERT Production.ProductModel OFF;
GO

-- Cultures
INSERT INTO Production.Culture (CultureID, Name) VALUES
('en', 'English'), ('ar', 'Arabic'), ('fr', 'French'),
('de', 'German'), ('he', 'Hebrew'), ('ja', 'Japanese'),
('es', 'Spanish'), ('zh-cht', 'Traditional Chinese');
GO

-- Locations
SET IDENTITY_INSERT Production.Location ON;
INSERT INTO Production.Location (LocationID, Name, CostRate, Availability) VALUES
(1, 'Tool Crib', 0.00, 0.00),
(10, 'Frame Forming', 22.50, 96.00),
(20, 'Frame Welding', 25.00, 108.00),
(30, 'Debur and Polish', 14.50, 120.00),
(40, 'Paint', 15.75, 120.00),
(45, 'Specialized Paint', 18.00, 80.00),
(50, 'Subassembly', 12.25, 120.00),
(60, 'Final Assembly', 12.25, 120.00);
SET IDENTITY_INSERT Production.Location OFF;
GO

-- Scrap Reasons
SET IDENTITY_INSERT Production.ScrapReason ON;
INSERT INTO Production.ScrapReason (ScrapReasonID, Name) VALUES
(1, 'Brake assembly not as specified'),
(2, 'Color incorrect'),
(3, 'Drill pattern incorrect'),
(4, 'Drill size too large'),
(5, 'Drill size too small'),
(6, 'Gouge in metal'),
(7, 'Handling damage'),
(8, 'Incomplete assembly'),
(9, 'Metal fatigue'),
(10, 'Miscellaneous'),
(11, 'Paint process failed'),
(12, 'Primer process failed'),
(13, 'Thermoform temperature too high'),
(14, 'Thermoform temperature too low'),
(15, 'Trim length too long'),
(16, 'Trim length too short'),
(17, 'Wheel assembly not as specified');
SET IDENTITY_INSERT Production.ScrapReason OFF;
GO

-- Ship Methods
SET IDENTITY_INSERT Purchasing.ShipMethod ON;
INSERT INTO Purchasing.ShipMethod (ShipMethodID, Name, ShipBase, ShipRate) VALUES
(1, 'XRQ - TRUCK GROUND', 3.95, 0.99),
(2, 'ZY - EXPRESS', 9.95, 1.99),
(3, 'OVERSEAS - DELUXE', 29.95, 2.99),
(4, 'OVERNIGHT J-FAST', 21.95, 1.29),
(5, 'CARGO TRANSPORT 5', 8.99, 1.49);
SET IDENTITY_INSERT Purchasing.ShipMethod OFF;
GO

-- Special Offers
SET IDENTITY_INSERT Sales.SpecialOffer ON;
INSERT INTO Sales.SpecialOffer (SpecialOfferID, Description, DiscountPct, Type, Category, StartDate, EndDate, MinQty, MaxQty) VALUES
(1, 'No Discount', 0.00, 'No Discount', 'No Discount', '2024-01-01', '2026-12-31', 0, NULL),
(2, 'Volume Discount 11 to 14', 0.02, 'Volume Discount', 'Reseller', '2024-01-01', '2026-12-31', 11, 14),
(3, 'Volume Discount 15 to 24', 0.05, 'Volume Discount', 'Reseller', '2024-01-01', '2026-12-31', 15, 24),
(4, 'Volume Discount 25 to 40', 0.10, 'Volume Discount', 'Reseller', '2024-01-01', '2026-12-31', 25, 40),
(5, 'Volume Discount 41 to 60', 0.15, 'Volume Discount', 'Reseller', '2024-01-01', '2026-12-31', 41, 60),
(6, 'Volume Discount over 60', 0.20, 'Volume Discount', 'Reseller', '2024-01-01', '2026-12-31', 61, NULL),
(7, 'Mountain-100 Clearance Sale', 0.35, 'Discontinued Product', 'Reseller', '2024-06-01', '2024-06-30', 0, NULL),
(8, 'Sport Helmet Discount-2024', 0.10, 'Seasonal Discount', 'Customer', '2024-03-01', '2024-05-31', 0, NULL);
SET IDENTITY_INSERT Sales.SpecialOffer OFF;
GO

-- Sales Reasons
SET IDENTITY_INSERT Sales.SalesReason ON;
INSERT INTO Sales.SalesReason (SalesReasonID, Name, ReasonType) VALUES
(1, 'Price', 'Other'),
(2, 'On Promotion', 'Promotion'),
(3, 'Magazine Advertisement', 'Marketing'),
(4, 'Television Advertisement', 'Marketing'),
(5, 'Manufacturer', 'Other'),
(6, 'Review', 'Other'),
(7, 'Demo Event', 'Marketing'),
(8, 'Sponsor', 'Marketing'),
(9, 'Quality', 'Other'),
(10, 'Other', 'Other');
SET IDENTITY_INSERT Sales.SalesReason OFF;
GO

-- Products
SET IDENTITY_INSERT Production.Product ON;
INSERT INTO Production.Product (ProductID, Name, ProductNumber, MakeFlag, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, Size, SizeUnitMeasureCode, WeightUnitMeasureCode, Weight, DaysToManufacture, ProductLine, Class, Style, ProductSubcategoryID, ProductModelID, SellStartDate) VALUES
-- Road Frames
(680, 'HL Road Frame - Black, 58', 'FR-R92B-58', 1, 0, 'Black', 500, 375, 1059.31, 1431.50, '58', 'CM', 'LB', 2.24, 1, 'R', 'H', 'U', 14, 5, '2024-01-01'),
(706, 'HL Road Frame - Red, 58', 'FR-R92R-58', 1, 0, 'Red', 500, 375, 1059.31, 1431.50, '58', 'CM', 'LB', 2.24, 1, 'R', 'H', 'U', 14, 5, '2024-01-01'),
(707, 'HL Road Frame - Red, 62', 'FR-R92R-62', 1, 0, 'Red', 500, 375, 1059.31, 1431.50, '62', 'CM', 'LB', 2.30, 1, 'R', 'H', 'U', 14, 5, '2024-01-01'),
(708, 'HL Road Frame - Black, 62', 'FR-R92B-62', 1, 0, 'Black', 500, 375, 1059.31, 1431.50, '62', 'CM', 'LB', 2.30, 1, 'R', 'H', 'U', 14, 5, '2024-01-01'),
(709, 'ML Road Frame - Red, 58', 'FR-R72R-58', 1, 0, 'Red', 500, 375, 352.14, 594.83, '58', 'CM', 'LB', 2.52, 1, 'R', 'M', 'U', 14, 7, '2024-01-01'),
(710, 'ML Road Frame - Red, 60', 'FR-R72R-60', 1, 0, 'Red', 500, 375, 352.14, 594.83, '60', 'CM', 'LB', 2.56, 1, 'R', 'M', 'U', 14, 7, '2024-01-01'),
(711, 'LL Road Frame - Black, 58', 'FR-R38B-58', 1, 0, 'Black', 500, 375, 204.62, 337.22, '58', 'CM', 'LB', 2.46, 1, 'R', 'L', 'U', 14, 6, '2024-01-01'),
(712, 'LL Road Frame - Black, 60', 'FR-R38B-60', 1, 0, 'Black', 500, 375, 204.62, 337.22, '60', 'CM', 'LB', 2.48, 1, 'R', 'L', 'U', 14, 6, '2024-01-01'),
-- Mountain Frames
(713, 'HL Mountain Frame - Black, 42', 'FR-M94B-42', 1, 0, 'Black', 500, 375, 739.04, 1349.60, '42', 'CM', 'LB', 2.52, 1, 'M', 'H', 'U', 12, 8, '2024-01-01'),
(714, 'HL Mountain Frame - Silver, 42', 'FR-M94S-42', 1, 0, 'Silver', 500, 375, 747.20, 1364.50, '42', 'CM', 'LB', 2.72, 1, 'M', 'H', 'U', 12, 8, '2024-01-01'),
(715, 'ML Mountain Frame - Black, 38', 'FR-M63B-38', 1, 0, 'Black', 500, 375, 348.76, 364.09, '38', 'CM', 'LB', 2.65, 1, 'M', 'M', 'U', 12, 10, '2024-01-01'),
(716, 'ML Mountain Frame - Silver, 38', 'FR-M63S-38', 1, 0, 'Silver', 500, 375, 348.76, 364.09, '38', 'CM', 'LB', 2.65, 1, 'M', 'M', 'U', 12, 10, '2024-01-01'),
(717, 'LL Mountain Frame - Black, 40', 'FR-M21B-40', 1, 0, 'Black', 500, 375, 149.87, 249.79, '40', 'CM', 'LB', 2.77, 1, 'M', 'L', 'U', 12, 9, '2024-01-01'),
(718, 'LL Mountain Frame - Silver, 40', 'FR-M21S-40', 1, 0, 'Silver', 500, 375, 149.87, 249.79, '40', 'CM', 'LB', 2.77, 1, 'M', 'L', 'U', 12, 9, '2024-01-01'),
-- Road Bikes
(749, 'Road-150 Red, 62', 'BK-R93R-62', 1, 1, 'Red', 100, 75, 2171.29, 3578.27, '62', 'CM', 'LB', 6.74, 4, 'R', 'H', 'U', 2, 16, '2024-01-01'),
(750, 'Road-150 Red, 44', 'BK-R93R-44', 1, 1, 'Red', 100, 75, 2171.29, 3578.27, '44', 'CM', 'LB', 6.36, 4, 'R', 'H', 'U', 2, 16, '2024-01-01'),
(751, 'Road-150 Red, 48', 'BK-R93R-48', 1, 1, 'Red', 100, 75, 2171.29, 3578.27, '48', 'CM', 'LB', 6.42, 4, 'R', 'H', 'U', 2, 16, '2024-01-01'),
(752, 'Road-150 Red, 52', 'BK-R93R-52', 1, 1, 'Red', 100, 75, 2171.29, 3578.27, '52', 'CM', 'LB', 6.56, 4, 'R', 'H', 'U', 2, 16, '2024-01-01'),
(753, 'Road-150 Red, 56', 'BK-R93R-56', 1, 1, 'Red', 100, 75, 2171.29, 3578.27, '56', 'CM', 'LB', 6.68, 4, 'R', 'H', 'U', 2, 16, '2024-01-01'),
(754, 'Road-250 Black, 44', 'BK-R89B-44', 1, 1, 'Black', 100, 75, 1518.78, 2443.35, '44', 'CM', 'LB', 6.86, 4, 'R', 'M', 'U', 2, 17, '2024-01-01'),
(755, 'Road-250 Black, 48', 'BK-R89B-48', 1, 1, 'Black', 100, 75, 1518.78, 2443.35, '48', 'CM', 'LB', 6.92, 4, 'R', 'M', 'U', 2, 17, '2024-01-01'),
(756, 'Road-250 Red, 44', 'BK-R89R-44', 1, 1, 'Red', 100, 75, 1518.78, 2443.35, '44', 'CM', 'LB', 6.86, 4, 'R', 'M', 'U', 2, 17, '2024-01-01'),
(757, 'Road-250 Red, 48', 'BK-R89R-48', 1, 1, 'Red', 100, 75, 1518.78, 2443.35, '48', 'CM', 'LB', 6.92, 4, 'R', 'M', 'U', 2, 17, '2024-01-01'),
-- Mountain Bikes
(771, 'Mountain-100 Silver, 38', 'BK-M82S-38', 1, 1, 'Silver', 100, 75, 1912.15, 3399.99, '38', 'CM', 'LB', 9.23, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(772, 'Mountain-100 Silver, 42', 'BK-M82S-42', 1, 1, 'Silver', 100, 75, 1912.15, 3399.99, '42', 'CM', 'LB', 9.36, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(773, 'Mountain-100 Silver, 44', 'BK-M82S-44', 1, 1, 'Silver', 100, 75, 1912.15, 3399.99, '44', 'CM', 'LB', 9.42, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(774, 'Mountain-100 Black, 38', 'BK-M82B-38', 1, 1, 'Black', 100, 75, 1898.09, 3374.99, '38', 'CM', 'LB', 9.23, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(775, 'Mountain-100 Black, 42', 'BK-M82B-42', 1, 1, 'Black', 100, 75, 1898.09, 3374.99, '42', 'CM', 'LB', 9.36, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(776, 'Mountain-100 Black, 44', 'BK-M82B-44', 1, 1, 'Black', 100, 75, 1898.09, 3374.99, '44', 'CM', 'LB', 9.42, 4, 'M', 'H', 'U', 1, 13, '2024-01-01'),
(777, 'Mountain-200 Silver, 38', 'BK-M68S-38', 1, 1, 'Silver', 100, 75, 1265.62, 2319.99, '38', 'CM', 'LB', 10.25, 4, 'M', 'M', 'U', 1, 14, '2024-01-01'),
(778, 'Mountain-200 Silver, 42', 'BK-M68S-42', 1, 1, 'Silver', 100, 75, 1265.62, 2319.99, '42', 'CM', 'LB', 10.35, 4, 'M', 'M', 'U', 1, 14, '2024-01-01'),
(779, 'Mountain-200 Black, 38', 'BK-M68B-38', 1, 1, 'Black', 100, 75, 1251.98, 2294.99, '38', 'CM', 'LB', 10.25, 4, 'M', 'M', 'U', 1, 14, '2024-01-01'),
(780, 'Mountain-200 Black, 42', 'BK-M68B-42', 1, 1, 'Black', 100, 75, 1251.98, 2294.99, '42', 'CM', 'LB', 10.35, 4, 'M', 'M', 'U', 1, 14, '2024-01-01'),
-- Touring Bikes
(781, 'Touring-1000 Yellow, 46', 'BK-T79Y-46', 1, 1, 'Yellow', 100, 75, 1481.92, 2384.07, '46', 'CM', 'LB', 11.38, 4, 'T', 'H', 'U', 3, 21, '2024-01-01'),
(782, 'Touring-1000 Yellow, 50', 'BK-T79Y-50', 1, 1, 'Yellow', 100, 75, 1481.92, 2384.07, '50', 'CM', 'LB', 11.52, 4, 'T', 'H', 'U', 3, 21, '2024-01-01'),
(783, 'Touring-1000 Blue, 46', 'BK-T79B-46', 1, 1, 'Blue', 100, 75, 1481.92, 2384.07, '46', 'CM', 'LB', 11.38, 4, 'T', 'H', 'U', 3, 21, '2024-01-01'),
(784, 'Touring-1000 Blue, 50', 'BK-T79B-50', 1, 1, 'Blue', 100, 75, 1481.92, 2384.07, '50', 'CM', 'LB', 11.52, 4, 'T', 'H', 'U', 3, 21, '2024-01-01'),
(785, 'Touring-2000 Blue, 46', 'BK-T44B-46', 1, 1, 'Blue', 100, 75, 755.17, 1214.85, '46', 'CM', 'LB', 12.62, 4, 'T', 'M', 'U', 3, 22, '2024-01-01'),
(786, 'Touring-2000 Blue, 50', 'BK-T44B-50', 1, 1, 'Blue', 100, 75, 755.17, 1214.85, '50', 'CM', 'LB', 12.84, 4, 'T', 'M', 'U', 3, 22, '2024-01-01'),
(787, 'Touring-3000 Yellow, 44', 'BK-T18Y-44', 1, 1, 'Yellow', 100, 75, 461.44, 742.35, '44', 'CM', 'LB', 13.77, 4, 'T', 'L', 'U', 3, 23, '2024-01-01'),
(788, 'Touring-3000 Blue, 44', 'BK-T18B-44', 1, 1, 'Blue', 100, 75, 461.44, 742.35, '44', 'CM', 'LB', 13.77, 4, 'T', 'L', 'U', 3, 23, '2024-01-01'),
-- Clothing
(789, 'Classic Vest, S', 'VE-C304-S', 0, 1, 'Blue', 100, 75, 23.75, 63.50, 'S', NULL, NULL, NULL, 0, 'S', NULL, 'U', 25, 1, '2024-01-01'),
(790, 'Classic Vest, M', 'VE-C304-M', 0, 1, 'Blue', 100, 75, 23.75, 63.50, 'M', NULL, NULL, NULL, 0, 'S', NULL, 'U', 25, 1, '2024-01-01'),
(791, 'Classic Vest, L', 'VE-C304-L', 0, 1, 'Blue', 100, 75, 23.75, 63.50, 'L', NULL, NULL, NULL, 0, 'S', NULL, 'U', 25, 1, '2024-01-01'),
(792, 'AWC Logo Cap', 'CA-1098', 0, 1, 'Multi', 100, 75, 5.77, 8.99, NULL, NULL, NULL, NULL, 0, 'S', NULL, 'U', 19, 2, '2024-01-01'),
(793, 'Full-Finger Gloves, S', 'GL-F110-S', 0, 1, 'Black', 100, 75, 15.67, 37.99, 'S', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 3, '2024-01-01'),
(794, 'Full-Finger Gloves, M', 'GL-F110-M', 0, 1, 'Black', 100, 75, 15.67, 37.99, 'M', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 3, '2024-01-01'),
(795, 'Full-Finger Gloves, L', 'GL-F110-L', 0, 1, 'Black', 100, 75, 15.67, 37.99, 'L', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 3, '2024-01-01'),
(796, 'Half-Finger Gloves, S', 'GL-H102-S', 0, 1, 'Black', 100, 75, 9.16, 24.49, 'S', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 4, '2024-01-01'),
(797, 'Half-Finger Gloves, M', 'GL-H102-M', 0, 1, 'Black', 100, 75, 9.16, 24.49, 'M', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 4, '2024-01-01'),
(798, 'Half-Finger Gloves, L', 'GL-H102-L', 0, 1, 'Black', 100, 75, 9.16, 24.49, 'L', NULL, NULL, NULL, 0, 'S', NULL, 'U', 20, 4, '2024-01-01'),
(799, 'Long-Sleeve Logo Jersey, S', 'LJ-0192-S', 0, 1, 'Multi', 100, 75, 38.49, 49.99, 'S', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 11, '2024-01-01'),
(800, 'Long-Sleeve Logo Jersey, M', 'LJ-0192-M', 0, 1, 'Multi', 100, 75, 38.49, 49.99, 'M', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 11, '2024-01-01'),
(801, 'Long-Sleeve Logo Jersey, L', 'LJ-0192-L', 0, 1, 'Multi', 100, 75, 38.49, 49.99, 'L', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 11, '2024-01-01'),
(802, 'Long-Sleeve Logo Jersey, XL', 'LJ-0192-XL', 0, 1, 'Multi', 100, 75, 38.49, 49.99, 'XL', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 11, '2024-01-01'),
(803, 'Short-Sleeve Classic Jersey, S', 'SJ-0194-S', 0, 1, 'Yellow', 100, 75, 41.57, 53.99, 'S', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 12, '2024-01-01'),
(804, 'Short-Sleeve Classic Jersey, M', 'SJ-0194-M', 0, 1, 'Yellow', 100, 75, 41.57, 53.99, 'M', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 12, '2024-01-01'),
(805, 'Short-Sleeve Classic Jersey, L', 'SJ-0194-L', 0, 1, 'Yellow', 100, 75, 41.57, 53.99, 'L', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 12, '2024-01-01'),
(806, 'Short-Sleeve Classic Jersey, XL', 'SJ-0194-XL', 0, 1, 'Yellow', 100, 75, 41.57, 53.99, 'XL', NULL, NULL, NULL, 0, 'S', NULL, 'U', 21, 12, '2024-01-01'),
-- Accessories
(807, 'Sport-100 Helmet, Red', 'HL-U509-R', 0, 1, 'Red', 100, 75, 13.08, 34.99, NULL, NULL, NULL, NULL, 0, 'S', NULL, 'U', 31, 24, '2024-01-01'),
(808, 'Sport-100 Helmet, Black', 'HL-U509', 0, 1, 'Black', 100, 75, 13.08, 34.99, NULL, NULL, NULL, NULL, 0, 'S', NULL, 'U', 31, 24, '2024-01-01'),
(809, 'Sport-100 Helmet, Blue', 'HL-U509-B', 0, 1, 'Blue', 100, 75, 13.08, 34.99, NULL, NULL, NULL, NULL, 0, 'S', NULL, 'U', 31, 24, '2024-01-01'),
(810, 'Water Bottle - 30 oz.', 'WB-H098', 0, 1, 'Blue', 100, 75, 2.98, 4.99, NULL, NULL, NULL, NULL, 0, 'S', NULL, 'U', 28, 25, '2024-01-01');
SET IDENTITY_INSERT Production.Product OFF;
GO

-- Link special offers to products (required for sales order details)
INSERT INTO Sales.SpecialOfferProduct (SpecialOfferID, ProductID)
SELECT 1, ProductID FROM Production.Product;
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

-- Addresses
SET IDENTITY_INSERT Person.Address ON;
INSERT INTO Person.Address (AddressID, AddressLine1, AddressLine2, City, StateProvinceID, PostalCode) VALUES
(1, '1970 Napa Ct.', NULL, 'Bothell', 1, '98011'),
(2, '9833 Mt. Dias Blv.', NULL, 'Bothell', 1, '98011'),
(3, '7484 Roundtree Drive', NULL, 'Bothell', 1, '98011'),
(4, '9539 Glenside Dr', NULL, 'Bothell', 1, '98011'),
(5, '1226 Shoe St.', NULL, 'Bothell', 1, '98011'),
(6, '1399 Firestone Drive', NULL, 'Bothell', 1, '98011'),
(7, '5672 Hale Dr.', NULL, 'Bothell', 1, '98011'),
(8, '6387 Scenic Avenue', NULL, 'Bothell', 1, '98011'),
(9, '8713 Yosemite Ct.', NULL, 'Bothell', 1, '98011'),
(10, '250 Race Court', NULL, 'Bothell', 1, '98011'),
(11, '1318 Lasalle Street', NULL, 'Bothell', 1, '98011'),
(12, '5415 San Gabriel Dr.', NULL, 'Bothell', 1, '98011'),
(13, '9265 La Paz', NULL, 'Bothell', 1, '98011'),
(14, '8157 W. Book', NULL, 'Bothell', 1, '98011'),
(15, '4912 La Vuelta', NULL, 'Bothell', 1, '98011');
SET IDENTITY_INSERT Person.Address OFF;
GO

-- Business Entity Addresses
INSERT INTO Person.BusinessEntityAddress (BusinessEntityID, AddressID, AddressTypeID) VALUES
(1, 1, 2), (2, 2, 2), (3, 3, 2), (4, 4, 2), (5, 5, 2),
(6, 6, 2), (7, 7, 2), (8, 8, 2), (9, 9, 2), (10, 10, 2),
(11, 11, 3), (12, 12, 3), (13, 13, 3), (14, 14, 3), (15, 15, 3);
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

-- Sales Persons
INSERT INTO Sales.SalesPerson (BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear) VALUES
(1, 1, 250000.00, 5000.00, 0.02, 1421810.92, 1262697.71),
(2, 2, 250000.00, 3500.00, 0.02, 992257.22, 750026.77),
(3, 3, 250000.00, 4500.00, 0.02, 1439156.04, 1453719.47);
GO

-- Vendors
INSERT INTO Purchasing.Vendor (BusinessEntityID, AccountNumber, Name, CreditRating, PreferredVendorStatus, ActiveFlag) VALUES
(100, 'AUSTRALI0001', 'Australia Bike Retailer', 1, 1, 1),
(101, 'ALLENSON0001', 'Allenson Cycles', 2, 1, 1),
(102, 'ADVANCED0001', 'Advanced Bicycles', 1, 1, 1),
(103, 'TRIKES0001', 'Trikes, Inc.', 2, 1, 1),
(104, 'MORGANBK0001', 'Morgan Bike Accessories', 1, 1, 1),
(105, 'CYCLING0001', 'Cycling Master', 3, 0, 1);
GO

-- Stores
INSERT INTO Sales.Store (BusinessEntityID, Name, SalesPersonID) VALUES
(11, 'A Bike Store', 1),
(12, 'Progressive Sports', 2),
(13, 'Advanced Bike Components', 3),
(14, 'Modular Cycle Systems', 1),
(15, 'Metropolitan Sports Supply', 2);
GO

-- Customers
SET IDENTITY_INSERT Sales.Customer ON;
INSERT INTO Sales.Customer (CustomerID, PersonID, StoreID, TerritoryID) VALUES
(1, 16, NULL, 1),
(2, 17, NULL, 2),
(3, 18, NULL, 3),
(4, 19, NULL, 4),
(5, 20, NULL, 5),
(11, NULL, 11, 1),
(12, NULL, 12, 2),
(13, NULL, 13, 3),
(14, NULL, 14, 4),
(15, NULL, 15, 5);
SET IDENTITY_INSERT Sales.Customer OFF;
GO

-- Credit Cards
SET IDENTITY_INSERT Sales.CreditCard ON;
INSERT INTO Sales.CreditCard (CreditCardID, CardType, CardNumber, ExpMonth, ExpYear) VALUES
(1, 'SuperiorCard', '33332664695310', 11, 2028),
(2, 'Distinguish', '55552127249722', 8, 2027),
(3, 'ColonialVoice', '77778344838353', 7, 2026),
(4, 'SuperiorCard', '11114312260625', 4, 2027),
(5, 'Vista', '11117129858595', 12, 2028);
SET IDENTITY_INSERT Sales.CreditCard OFF;
GO

-- Person Credit Cards
INSERT INTO Sales.PersonCreditCard (BusinessEntityID, CreditCardID) VALUES
(16, 1), (17, 2), (18, 3), (19, 4), (20, 5);
GO

-- Product Inventory
INSERT INTO Production.ProductInventory (ProductID, LocationID, Shelf, Bin, Quantity) VALUES
(680, 1, 'A', 1, 50), (706, 1, 'A', 2, 45), (707, 1, 'A', 3, 40),
(749, 60, 'N/A', 0, 25), (750, 60, 'N/A', 0, 20), (751, 60, 'N/A', 0, 22),
(771, 60, 'N/A', 0, 15), (772, 60, 'N/A', 0, 18), (773, 60, 'N/A', 0, 16),
(789, 1, 'B', 1, 100), (790, 1, 'B', 2, 95), (791, 1, 'B', 3, 88),
(807, 1, 'C', 1, 75), (808, 1, 'C', 2, 80), (809, 1, 'C', 3, 70);
GO

-- Sales Order Headers
SET IDENTITY_INSERT Sales.SalesOrderHeader ON;
INSERT INTO Sales.SalesOrderHeader (SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, SubTotal, TaxAmt, Freight, Comment) VALUES
(43659, 8, '2024-01-01', '2024-01-13', '2024-01-08', 5, 0, 'PO522145787', 'AW00000011', 11, 1, 1, 1, 1, 5, NULL, 20565.62, 1971.51, 616.09, NULL),
(43660, 8, '2024-01-01', '2024-01-13', '2024-01-08', 5, 0, 'PO18850127500', 'AW00000012', 12, 2, 2, 2, 2, 5, NULL, 1294.25, 124.24, 38.83, NULL),
(43661, 8, '2024-01-01', '2024-01-13', '2024-01-08', 5, 0, 'PO18473134765', 'AW00000013', 13, 3, 3, 3, 3, 5, NULL, 32726.47, 3153.76, 985.55, NULL),
(43662, 8, '2024-01-02', '2024-01-14', '2024-01-09', 5, 1, NULL, 'AW00000001', 1, NULL, 1, 11, 11, 5, 1, 28832.52, 2766.32, 864.47, NULL),
(43663, 8, '2024-01-02', '2024-01-14', '2024-01-09', 5, 1, NULL, 'AW00000002', 2, NULL, 2, 12, 12, 5, 2, 419.46, 40.27, 12.58, NULL),
(43664, 8, '2024-01-02', '2024-01-14', '2024-01-09', 5, 1, NULL, 'AW00000003', 3, NULL, 3, 13, 13, 5, 3, 24432.60, 2345.53, 732.98, NULL),
(43665, 8, '2024-01-03', '2024-01-15', '2024-01-10', 5, 1, NULL, 'AW00000004', 4, NULL, 4, 14, 14, 5, 4, 14352.72, 1377.86, 430.58, NULL),
(43666, 8, '2024-01-03', '2024-01-15', '2024-01-10', 5, 1, NULL, 'AW00000005', 5, NULL, 5, 15, 15, 5, 5, 5056.47, 485.42, 151.69, 'Expedite delivery'),
(43667, 8, '2024-01-04', '2024-01-16', '2024-01-11', 5, 0, 'PO19952192051', 'AW00000014', 14, 1, 4, 4, 4, 5, NULL, 6107.08, 586.27, 183.21, NULL),
(43668, 8, '2024-01-05', '2024-01-17', '2024-01-12', 5, 0, 'PO19604173239', 'AW00000015', 15, 2, 5, 5, 5, 5, NULL, 3953.99, 379.58, 118.62, NULL);
SET IDENTITY_INSERT Sales.SalesOrderHeader OFF;
GO

-- Sales Order Details
INSERT INTO Sales.SalesOrderDetail (SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount) VALUES
(43659, '4911-403C-98', 1, 776, 1, 3374.99, 0.00),
(43659, '4911-403C-98', 3, 777, 1, 2319.99, 0.00),
(43659, '4911-403C-98', 1, 778, 1, 2319.99, 0.00),
(43659, '4911-403C-98', 1, 771, 1, 3399.99, 0.00),
(43660, '4911-403C-98', 1, 758, 1, 874.79, 0.00),
(43660, '4911-403C-98', 1, 762, 1, 419.46, 0.00),
(43661, '4911-403C-98', 2, 758, 1, 874.79, 0.00),
(43661, '4911-403C-98', 1, 765, 1, 419.46, 0.00),
(43661, '4911-403C-98', 2, 768, 1, 874.79, 0.00),
(43661, '4911-403C-98', 4, 771, 1, 3399.99, 0.00),
(43661, '4911-403C-98', 4, 772, 1, 3399.99, 0.00),
(43662, '6431-4D57-83', 1, 771, 1, 3399.99, 0.00),
(43662, '6431-4D57-83', 2, 772, 1, 3399.99, 0.00),
(43662, '6431-4D57-83', 2, 773, 1, 3399.99, 0.00),
(43662, '6431-4D57-83', 1, 774, 1, 3374.99, 0.00),
(43662, '6431-4D57-83', 2, 714, 1, 1364.50, 0.00),
(43663, 'E572-40F8-EA', 5, 792, 1, 8.99, 0.00),
(43663, 'E572-40F8-EA', 6, 793, 1, 37.99, 0.00),
(43663, 'E572-40F8-EA', 4, 794, 1, 37.99, 0.00),
(43664, '3E57-4F38-35', 2, 749, 1, 3578.27, 0.00),
(43664, '3E57-4F38-35', 2, 750, 1, 3578.27, 0.00),
(43664, '3E57-4F38-35', 2, 751, 1, 3578.27, 0.00),
(43665, 'A254-53A4-B6', 2, 754, 1, 2443.35, 0.00),
(43665, 'A254-53A4-B6', 2, 755, 1, 2443.35, 0.00),
(43665, 'A254-53A4-B6', 1, 756, 1, 2443.35, 0.00),
(43665, 'A254-53A4-B6', 1, 757, 1, 2443.35, 0.00),
(43666, 'BA52-5DB1-DE', 1, 781, 1, 2384.07, 0.00),
(43666, 'BA52-5DB1-DE', 1, 782, 1, 2384.07, 0.00),
(43666, 'BA52-5DB1-DE', 3, 807, 1, 34.99, 0.00),
(43666, 'BA52-5DB1-DE', 2, 808, 1, 34.99, 0.00),
(43667, '46C7-5F9D-11', 1, 710, 1, 594.83, 0.00),
(43667, '46C7-5F9D-11', 2, 709, 1, 594.83, 0.00),
(43667, '46C7-5F9D-11', 3, 711, 1, 337.22, 0.00),
(43667, '46C7-5F9D-11', 4, 712, 1, 337.22, 0.00),
(43668, 'CB21-5DA8-92', 2, 715, 1, 364.09, 0.00),
(43668, 'CB21-5DA8-92', 2, 716, 1, 364.09, 0.00),
(43668, 'CB21-5DA8-92', 3, 717, 1, 249.79, 0.00),
(43668, 'CB21-5DA8-92', 3, 718, 1, 249.79, 0.00),
(43668, 'CB21-5DA8-92', 5, 792, 1, 8.99, 0.00);
GO

-- Sales Order Reasons
INSERT INTO Sales.SalesOrderHeaderSalesReason (SalesOrderID, SalesReasonID) VALUES
(43659, 5), (43660, 5), (43661, 5), (43662, 5), (43663, 1),
(43664, 9), (43665, 9), (43666, 5), (43667, 5), (43668, 5);
GO

-- Work Orders
SET IDENTITY_INSERT Production.WorkOrder ON;
INSERT INTO Production.WorkOrder (WorkOrderID, ProductID, OrderQty, ScrappedQty, StartDate, EndDate, DueDate, ScrapReasonID) VALUES
(1, 771, 4, 0, '2024-01-01', '2024-01-12', '2024-01-12', NULL),
(2, 772, 6, 0, '2024-01-01', '2024-01-12', '2024-01-12', NULL),
(3, 773, 4, 0, '2024-01-02', '2024-01-13', '2024-01-13', NULL),
(4, 749, 8, 1, '2024-01-02', '2024-01-14', '2024-01-14', 7),
(5, 750, 4, 0, '2024-01-03', '2024-01-15', '2024-01-15', NULL);
SET IDENTITY_INSERT Production.WorkOrder OFF;
GO

-- Purchase Order Headers
SET IDENTITY_INSERT Purchasing.PurchaseOrderHeader ON;
INSERT INTO Purchasing.PurchaseOrderHeader (PurchaseOrderID, RevisionNumber, Status, EmployeeID, VendorID, ShipMethodID, OrderDate, ShipDate, SubTotal, TaxAmt, Freight) VALUES
(1, 2, 4, 3, 100, 3, '2024-01-01', '2024-01-15', 17364.99, 1389.20, 434.12),
(2, 2, 4, 4, 101, 3, '2024-01-02', '2024-01-16', 6548.82, 523.91, 163.72),
(3, 2, 4, 3, 102, 3, '2024-01-03', '2024-01-17', 10549.46, 843.96, 263.74),
(4, 2, 4, 5, 103, 3, '2024-01-04', '2024-01-18', 3562.79, 285.02, 89.07),
(5, 2, 4, 4, 104, 3, '2024-01-05', '2024-01-19', 7248.68, 579.89, 181.22);
SET IDENTITY_INSERT Purchasing.PurchaseOrderHeader OFF;
GO

-- Purchase Order Details
INSERT INTO Purchasing.PurchaseOrderDetail (PurchaseOrderID, DueDate, OrderQty, ProductID, UnitPrice, ReceivedQty, RejectedQty) VALUES
(1, '2024-01-15', 4, 771, 1912.15, 4, 0),
(1, '2024-01-15', 4, 772, 1912.15, 4, 0),
(1, '2024-01-15', 2, 773, 1912.15, 2, 0),
(2, '2024-01-16', 4, 749, 1637.21, 4, 0),
(3, '2024-01-17', 6, 750, 1637.21, 6, 0),
(3, '2024-01-17', 2, 792, 5.77, 2, 0),
(4, '2024-01-18', 10, 793, 15.67, 10, 0),
(4, '2024-01-18', 10, 794, 15.67, 10, 0),
(4, '2024-01-18', 10, 795, 15.67, 10, 0),
(5, '2024-01-19', 6, 807, 13.08, 6, 0),
(5, '2024-01-19', 6, 808, 13.08, 6, 0),
(5, '2024-01-19', 6, 809, 13.08, 6, 0),
(5, '2024-01-19', 200, 810, 2.98, 200, 0);
GO

-- Product Reviews
SET IDENTITY_INSERT Production.ProductReview ON;
INSERT INTO Production.ProductReview (ProductReviewID, ProductID, ReviewerName, ReviewDate, EmailAddress, Rating, Comments) VALUES
(1, 771, 'John Smith', '2024-01-15', 'jsmith@example.com', 5, 'Excellent mountain bike! Great performance on rough terrain.'),
(2, 749, 'Jane Doe', '2024-01-16', 'jdoe@example.com', 4, 'Very fast road bike. Comfortable for long rides.'),
(3, 807, 'Mike Johnson', '2024-01-17', 'mjohnson@example.com', 5, 'Best helmet I have owned. Light and protective.'),
(4, 789, 'Sarah Wilson', '2024-01-18', 'swilson@example.com', 4, 'Nice vest, keeps me warm during fall rides.');
SET IDENTITY_INSERT Production.ProductReview OFF;
GO

PRINT 'Adventure Works Full database setup complete!';
PRINT '';
PRINT 'Schemas created: Person, HumanResources, Production, Purchasing, Sales';
PRINT '';
PRINT 'Tables created per schema:';
PRINT '  Person: 12 tables';
PRINT '  HumanResources: 6 tables';
PRINT '  Production: 18 tables';
PRINT '  Purchasing: 5 tables';
PRINT '  Sales: 18 tables';
PRINT '';
PRINT 'Total: 59 tables';
GO
