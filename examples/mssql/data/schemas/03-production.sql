-- Adventure Works - Production Schema
-- This script creates Production schema tables and loads sample data

-- =============================================================================
-- PRODUCTION SCHEMA TABLES
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
-- PRODUCTION SCHEMA SAMPLE DATA
-- =============================================================================

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

-- Product Inventory
INSERT INTO Production.ProductInventory (ProductID, LocationID, Shelf, Bin, Quantity) VALUES
(680, 1, 'A', 1, 50), (706, 1, 'A', 2, 45), (707, 1, 'A', 3, 40),
(749, 60, 'N/A', 0, 25), (750, 60, 'N/A', 0, 20), (751, 60, 'N/A', 0, 22),
(771, 60, 'N/A', 0, 15), (772, 60, 'N/A', 0, 18), (773, 60, 'N/A', 0, 16),
(789, 1, 'B', 1, 100), (790, 1, 'B', 2, 95), (791, 1, 'B', 3, 88),
(807, 1, 'C', 1, 75), (808, 1, 'C', 2, 80), (809, 1, 'C', 3, 70);
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

-- Product Reviews
SET IDENTITY_INSERT Production.ProductReview ON;
INSERT INTO Production.ProductReview (ProductReviewID, ProductID, ReviewerName, ReviewDate, EmailAddress, Rating, Comments) VALUES
(1, 771, 'John Smith', '2024-01-15', 'jsmith@example.com', 5, 'Excellent mountain bike! Great performance on rough terrain.'),
(2, 749, 'Jane Doe', '2024-01-16', 'jdoe@example.com', 4, 'Very fast road bike. Comfortable for long rides.'),
(3, 807, 'Mike Johnson', '2024-01-17', 'mjohnson@example.com', 5, 'Best helmet I have owned. Light and protective.'),
(4, 789, 'Sarah Wilson', '2024-01-18', 'swilson@example.com', 4, 'Nice vest, keeps me warm during fall rides.');
SET IDENTITY_INSERT Production.ProductReview OFF;
GO

PRINT 'Production schema: 18 tables created and loaded';
GO
