-- Adventure Works - Sales Schema
-- This script creates Sales schema tables and loads sample data

-- =============================================================================
-- SALES SCHEMA TABLES
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
-- SALES SCHEMA SAMPLE DATA
-- =============================================================================

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

-- States/Provinces (must come after Sales.SalesTerritory)
SET IDENTITY_INSERT Person.StateProvince ON;
INSERT INTO Person.StateProvince (StateProvinceID, StateProvinceCode, CountryRegionCode, Name, TerritoryID) VALUES
(1, 'WA', 'US', 'Washington', 1), (2, 'OR', 'US', 'Oregon', 1), (3, 'CA', 'US', 'California', 4),
(4, 'TX', 'US', 'Texas', 4), (5, 'NY', 'US', 'New York', 2), (6, 'FL', 'US', 'Florida', 5),
(7, 'IL', 'US', 'Illinois', 3), (8, 'ON', 'CA', 'Ontario', 6), (9, 'BC', 'CA', 'British Columbia', 6),
(10, 'AB', 'CA', 'Alberta', 6);
SET IDENTITY_INSERT Person.StateProvince OFF;
GO

-- Addresses (depends on StateProvince)
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

-- Link special offers to products (required for sales order details)
INSERT INTO Sales.SpecialOfferProduct (SpecialOfferID, ProductID)
SELECT 1, ProductID FROM Production.Product;
GO

-- Sales Persons
INSERT INTO Sales.SalesPerson (BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear) VALUES
(1, 1, 250000.00, 5000.00, 0.02, 1421810.92, 1262697.71),
(2, 2, 250000.00, 3500.00, 0.02, 992257.22, 750026.77),
(3, 3, 250000.00, 4500.00, 0.02, 1439156.04, 1453719.47);
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
(43660, '4911-403C-98', 1, 754, 1, 2443.35, 0.00),
(43660, '4911-403C-98', 1, 755, 1, 2443.35, 0.00),
(43661, '4911-403C-98', 2, 754, 1, 2443.35, 0.00),
(43661, '4911-403C-98', 1, 756, 1, 2443.35, 0.00),
(43661, '4911-403C-98', 2, 757, 1, 2443.35, 0.00),
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

PRINT 'Sales schema: 18 tables created and loaded';
GO
