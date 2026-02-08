-- Adventure Works - Purchasing Schema
-- This script creates Purchasing schema tables and loads sample data

-- =============================================================================
-- PURCHASING SCHEMA TABLES
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
-- PURCHASING SCHEMA SAMPLE DATA
-- =============================================================================

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

-- Vendors
INSERT INTO Purchasing.Vendor (BusinessEntityID, AccountNumber, Name, CreditRating, PreferredVendorStatus, ActiveFlag) VALUES
(100, 'AUSTRALI0001', 'Australia Bike Retailer', 1, 1, 1),
(101, 'ALLENSON0001', 'Allenson Cycles', 2, 1, 1),
(102, 'ADVANCED0001', 'Advanced Bicycles', 1, 1, 1),
(103, 'TRIKES0001', 'Trikes, Inc.', 2, 1, 1),
(104, 'MORGANBK0001', 'Morgan Bike Accessories', 1, 1, 1),
(105, 'CYCLING0001', 'Cycling Master', 3, 0, 1);
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

PRINT 'Purchasing schema: 5 tables created and loaded';
GO
