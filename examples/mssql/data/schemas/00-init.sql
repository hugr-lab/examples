-- Adventure Works Full Schema - Initialization
-- This script creates all database schemas

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

PRINT 'Schemas created: Person, HumanResources, Production, Purchasing, Sales';
GO
