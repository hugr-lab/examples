# MSSQL Adventure Works Example

This example demonstrates how to use hugr with Microsoft SQL Server as a data source, featuring the full Adventure Works sample database with 59 tables across 5 schemas: Person, HumanResources, Production, Purchasing, and Sales.

## Prerequisites

- **Platform**: amd64 (Intel/AMD processor) - SQL Server does not support ARM/Apple Silicon natively
- **Docker**: Installed and running
- **hugr**: Infrastructure running (`./scripts/start.sh` from repository root)

## Quick Start

### 1. Run Setup Script

```bash
cd examples/mssql
./setup.sh
```

The script will:
- Check platform compatibility (amd64 required)
- Start the MSSQL container with the `mssql` profile
- Create the AdventureWorksLT database
- Load schema and sample data

Use `--force` to recreate an existing database:
```bash
./setup.sh --force
```

### 2. Register Data Source in hugr

Open hugr GraphiQL at http://localhost:18000/admin and execute:

```graphql
mutation {
  core {
    insert_data_sources(data: {
      name: "adventureworks"
      type: "mssql"
      prefix: "aw"
      description: "Adventure Works Full sample database"
      as_module: true
      read_only: false
      path: "mssql://sa:'YourStrong@Passw0rd'@mssql:1433/AdventureWorksLT"
      catalogs: [{
        name: "adventureworks"
        type: "uri"
        description: "Adventure Works schema"
        path: "/workspace/examples/mssql/schema/schemas"
      }]
    }) {
      name
      type
      path
    }
  }
}
```

> **Note**: Replace the password in the connection string if you've set a custom `MSSQL_SA_PASSWORD`.

### 3. Load the Data Source

```graphql
mutation {
  core {
    load_data_sources(name: "adventureworks") {
      success
      message
    }
  }
}
```

### 4. Verify with a Query

```graphql
query {
  adventureworks {
    production {
      Product(limit: 5) {
        ProductID
        Name
        ListPrice
        subcategory {
          Name
          category {
            Name
          }
        }
      }
    }
  }
}
```

## MSSQL Connection URI Format

The MSSQL data source uses the following URI format:

```
mssql://user:'password'@host:port/database
```

| Component | Description | Example |
|-----------|-------------|---------|
| `user` | Database username | `sa` |
| `password` | User password (quote with `'` if contains special chars) | `'YourStrong@Passw0rd'` |
| `host` | Server hostname | `mssql` (container name) |
| `port` | Server port | `1433` (internal container port) |
| `database` | Database name | `AdventureWorksLT` |

> **Note**: If your password contains special characters like `@`, `#`, `!`, or `%`, wrap it in single quotes to avoid parsing issues.

## Sample Queries

### 1. Basic Product Listing with Filtering and Sorting

```graphql
query {
  adventureworks {
    production {
      Product(
        filter: { ListPrice: { gt: 1000 } }
        order_by: [{ field: "ListPrice", direction: DESC }]
        limit: 10
      ) {
        ProductID
        Name
        ProductNumber
        Color
        ListPrice
        StandardCost
      }
    }
  }
}
```

Expected output:

```json
{
  "data": {
    "adventureworks": {
      "production": {
        "Product": [
          {
            "ProductID": 749,
            "Name": "Road-150 Red, 62",
            "ProductNumber": "BK-R93R-62",
            "Color": "Red",
            "ListPrice": 3578.27,
            "StandardCost": 2171.29
          }
        ]
      }
    }
  }
}
```

### 2. Products with Categories (Relationship Traversal)

```graphql
query {
  adventureworks {
    production {
      Product(limit: 5) {
        Name
        ListPrice
        subcategory {
          Name
          category {
            Name
          }
        }
        model {
          Name
        }
      }
    }
  }
}
```

Expected output:

```json
{
  "data": {
    "adventureworks": {
      "production": {
        "Product": [
          {
            "Name": "HL Road Frame - Black, 58",
            "ListPrice": 1431.50,
            "subcategory": {
              "Name": "Road Frames",
              "category": {
                "Name": "Components"
              }
            },
            "model": {
              "Name": "HL Road Frame"
            }
          }
        ]
      }
    }
  }
}
```

### 3. Filter by Referenced Object Value

Query products by their category name:

```graphql
query {
  adventureworks {
    production {
      Product(
        filter: { subcategory: { category: { Name: { eq: "Bikes" } } } }
        limit: 5
      ) {
        Name
        ListPrice
        subcategory {
          Name
          category {
            Name
          }
        }
      }
    }
  }
}
```

### 4. Customer Orders with Details (Nested Relationships)

```graphql
query {
  adventureworks {
    sales {
      SalesOrderHeader(limit: 3) {
        SalesOrderNumber
        OrderDate
        TotalDue
        customer {
          AccountNumber
          person {
            FirstName
            LastName
          }
          store {
            Name
          }
        }
        details {
          OrderQty
          UnitPrice
          LineTotal
          product {
            Name
          }
        }
      }
    }
  }
}
```

Expected output:

```json
{
  "data": {
    "adventureworks": {
      "sales": {
        "SalesOrderHeader": [
          {
            "SalesOrderNumber": "SO43659",
            "OrderDate": "2024-01-01T00:00:00",
            "TotalDue": 23153.22,
            "customer": {
              "AccountNumber": "AW00000011",
              "person": null,
              "store": {
                "Name": "A Bike Store"
              }
            },
            "details": [
              {
                "OrderQty": 1,
                "UnitPrice": 3374.99,
                "LineTotal": 3374.99,
                "product": {
                  "Name": "Mountain-100 Black, 44"
                }
              }
            ]
          }
        ]
      }
    }
  }
}
```

### 5. Sales Aggregation by Customer

Use `_rows_count` for counting and aggregate functions inside field objects:

```graphql
query {
  adventureworks {
    sales {
      Customer(limit: 5) {
        CustomerID
        AccountNumber
        orders_aggregation {
          _rows_count
          TotalDue {
            sum
          }
        }
      }
    }
  }
}
```

Expected output:

```json
{
  "data": {
    "adventureworks": {
      "sales": {
        "Customer": [
          {
            "CustomerID": 1,
            "AccountNumber": "AW00000001",
            "orders_aggregation": {
              "_rows_count": 1,
              "TotalDue": {
                "sum": 32463.31
              }
            }
          }
        ]
      }
    }
  }
}
```

### 6. Category Hierarchy with Product Count

```graphql
query {
  adventureworks {
    production {
      ProductCategory {
        Name
        subcategories {
          Name
          products_aggregation {
            _rows_count
          }
        }
      }
    }
  }
}
```

Expected output:

```json
{
  "data": {
    "adventureworks": {
      "production": {
        "ProductCategory": [
          {
            "Name": "Bikes",
            "subcategories": [
              {
                "Name": "Mountain Bikes",
                "products_aggregation": {
                  "_rows_count": 10
                }
              },
              {
                "Name": "Road Bikes",
                "products_aggregation": {
                  "_rows_count": 9
                }
              }
            ]
          }
        ]
      }
    }
  }
}
```

### 7. Bucket Aggregation - Sales by Territory

Group sales orders by territory with aggregated totals:

```graphql
query {
  adventureworks {
    sales {
      SalesOrderHeader_bucket_aggregation {
        key {
          TerritoryID
        }
        aggregations {
          _rows_count
          TotalDue {
            sum
            avg
          }
        }
      }
    }
  }
}
```

### 8. Bucket Aggregation - Products by Category and Color

Multi-dimensional bucket aggregation with nested key fields:

```graphql
query {
  adventureworks {
    production {
      Product_bucket_aggregation {
        key {
          Color
          subcategory {
            Name
          }
        }
        aggregations {
          _rows_count
          ListPrice {
            min
            max
            avg
          }
        }
      }
    }
  }
}
```

### 9. Bucket Aggregation with Filter and Sorting

Aggregate high-value products sorted by total:

```graphql
query {
  adventureworks {
    production {
      Product_bucket_aggregation(
        filter: { ListPrice: { gt: 1000 } }
        order_by: [{ field: "aggregations.ListPrice.sum", direction: DESC }]
        limit: 10
      ) {
        key {
          Class
        }
        aggregations {
          _rows_count
          ListPrice {
            sum
            avg
          }
          StandardCost {
            sum
          }
        }
      }
    }
  }
}
```

### 10. Bucket Aggregation with Subquery

Get sales totals by territory with detailed territory information:

```graphql
query {
  adventureworks {
    sales {
      SalesOrderHeader_bucket_aggregation(
        order_by: [{ field: "aggregations.TotalDue.sum", direction: DESC }]
      ) {
        key {
          territory {
            Name
            CountryRegionCode
            Group
          }
        }
        aggregations {
          _rows_count
          TotalDue {
            sum
            avg
            min
            max
          }
          Freight {
            sum
          }
        }
      }
    }
  }
}
```

### 11. Nested Query with Limit (Last N Related Records)

Get each customer with their last 5 orders using `nested_order_by` and `nested_limit`:

```graphql
query {
  adventureworks {
    sales {
      Customer(limit: 10) {
        CustomerID
        AccountNumber
        store {
          Name
        }
        orders(
          nested_order_by: [{ field: "OrderDate", direction: DESC }]
          nested_limit: 5
        ) {
          SalesOrderNumber
          OrderDate
          TotalDue
          Status
        }
      }
    }
  }
}
```

### 12. Distinct Query

Get distinct product colors:

```graphql
query {
  adventureworks {
    production {
      Product(distinct_on: ["Color"]) {
        Color
      }
    }
  }
}
```

Get distinct category and subcategory combinations:

```graphql
query {
  adventureworks {
    production {
      Product(
        distinct_on: ["ProductSubcategoryID"]
        order_by: [{ field: "ProductSubcategoryID", direction: ASC }]
      ) {
        ProductSubcategoryID
        subcategory {
          Name
          category {
            Name
          }
        }
      }
    }
  }
}
```

## Key Features Demonstrated

### Schema Patterns

| Pattern | Example | Description |
|---------|---------|-------------|
| `@table` | `@table(name: "Production.Product")` | Maps GraphQL type to MSSQL table with schema prefix |
| `@module` | `@module(name: "production")` | Groups types into logical modules |
| `@pk` | `ProductID: Int! @pk` | Marks primary key column |
| `@field_references` | See Product → ProductSubcategory | Defines foreign key relationships |
| Self-reference | ProductSubcategory hierarchy | Categories with parent/child relationships |
| Many-to-many | BusinessEntityAddress | Junction table pattern |
| Composite PK | SalesOrderDetail | Multiple `@pk` fields |

### The `@table` and `@module` Directives

Maps a GraphQL type to a SQL Server table and groups it into a module:

```graphql
type Product @table(name: "Production.Product") @module(name: "production") {
  ProductID: Int! @pk
  Name: String!
  # ...
}
```

- The `@table` directive's `name` parameter includes the schema prefix (e.g., `Production.`, `Sales.`, `Person.`)
- The `@module` directive groups types into logical query namespaces (e.g., `aw { production { Product } }`)

### The `@field_references` Directive

Defines relationships between entities:

```graphql
ProductSubcategoryID: Int @field_references(
  name: "product_subcat_fk"          # Unique constraint name
  references_name: "ProductSubcategory" # Target type name
  field: "ProductSubcategoryID"      # Target field
  query: "subcategory"               # Field name for forward navigation
  description: "Product subcategory"
  references_query: "products"       # Field name for reverse navigation
  references_description: "Products in this subcategory"
)
```

### Self-Referencing Relationships

ProductSubcategory demonstrates hierarchical data through its reference to ProductCategory:

```graphql
type ProductSubcategory @table(name: "Production.ProductSubcategory") @module(name: "production") {
  ProductSubcategoryID: Int! @pk
  ProductCategoryID: Int! @field_references(
    name: "subcat_cat_fk"
    references_name: "ProductCategory"
    field: "ProductCategoryID"
    query: "category"                  # Navigate to parent
    references_query: "subcategories"  # Navigate to children
  )
  Name: String!
}
```

### Many-to-Many Relationships

BusinessEntityAddress junction table links BusinessEntities and Addresses:

```graphql
type BusinessEntityAddress @table(name: "Person.BusinessEntityAddress") @module(name: "person") {
  BusinessEntityID: Int! @pk @field_references(...)
  AddressID: Int! @pk @field_references(...)
  AddressTypeID: Int! @pk @field_references(...)
}
```

## MSSQL-Specific Considerations

### Platform Requirements

SQL Server only runs on amd64 (Intel/AMD) processors. If you're on Apple Silicon (M1/M2/M3):
- Use Docker Desktop's Rosetta emulation (experimental)
- Connect to a remote SQL Server instance
- Use Azure SQL Database

### Query Pushdown

Hugr's MSSQL support uses DuckDB's MSSQL extension which supports:
- **Projection pushdown**: Only requested columns are fetched
- **Filter pushdown**: WHERE conditions are pushed to SQL Server

This means queries are efficiently executed on the SQL Server side.

### Schema Definition

Unlike self-describing data sources, MSSQL requires explicit schema definition.

**GraphQL Schema Files** (`schema/schemas/`):

- `person.graphql` - Person, Address, BusinessEntity tables
- `humanresources.graphql` - Employee, Department, Shift tables
- `production.graphql` - Product, ProductCategory, Inventory tables
- `purchasing.graphql` - Vendor, PurchaseOrder tables
- `sales.graphql` - Customer, SalesOrder, Currency tables

**SQL Schema Files** (`data/schemas/`):

- `00-init.sql` - Create database schemas
- `01-person.sql` - Person schema tables and data
- `02-humanresources.sql` - HR schema tables and data
- `03-production.sql` - Production schema tables and data
- `04-purchasing.sql` - Purchasing schema tables and data
- `05-sales.sql` - Sales schema tables and data

### Data Types

| SQL Server | GraphQL | Notes |
|------------|---------|-------|
| `int`, `smallint`, `tinyint` | `Int` | All integer types map to Int |
| `nvarchar`, `varchar` | `String` | Text types |
| `money`, `decimal` | `Float` | Numeric types |
| `datetime` | `Timestamp` | Date/time values |
| `bit` | `Boolean` | True/false |

## Troubleshooting

### Platform Not Supported

```
[WARN] Detected architecture: arm64
```

SQL Server requires amd64. On Apple Silicon, try Docker Desktop with Rosetta or use a remote server.

### Connection Refused

```bash
# Check container status
docker-compose ps mssql

# View container logs
docker-compose logs mssql

# Check port availability
lsof -i :18033
```

### Database Does Not Exist

```bash
# Recreate the database
./setup.sh --force
```

### Authentication Failed

Verify the SA password matches between:
- `.env` file (`MSSQL_SA_PASSWORD`)
- Data source registration mutation

## Data Model

The Adventure Works Full database includes 59 tables across 5 schemas:

### Person Schema (12 tables)

| Table | Description |
|-------|-------------|
| BusinessEntity | Base entity for persons, stores, vendors |
| Person | Individual contact information |
| Address | Physical addresses |
| StateProvince | State/province reference data |
| CountryRegion | Country reference data |
| AddressType, ContactType, PhoneNumberType | Lookup tables |

### HumanResources Schema (6 tables)

| Table | Description |
|-------|-------------|
| Employee | Employee records linked to Person |
| Department | Company departments |
| Shift | Work shift definitions |
| EmployeeDepartmentHistory | Department assignments over time |
| EmployeePayHistory | Pay rate history |

### Production Schema (18 tables)

| Table | Description |
|-------|-------------|
| Product | Products sold or manufactured |
| ProductCategory, ProductSubcategory | Product hierarchy |
| ProductModel | Product design templates |
| ProductInventory | Inventory at locations |
| WorkOrder | Manufacturing work orders |
| BillOfMaterials | Product assembly components |

### Purchasing Schema (5 tables)

| Table | Description |
|-------|-------------|
| Vendor | Product suppliers |
| PurchaseOrderHeader/Detail | Purchase orders |
| ShipMethod | Shipping methods |
| ProductVendor | Vendor-product relationships |

### Sales Schema (18 tables)

| Table | Description |
|-------|-------------|
| Customer | Customers (individuals or stores) |
| Store | Retail store information |
| SalesOrderHeader/Detail | Sales orders |
| SalesTerritory | Geographic sales regions |
| SalesPerson | Sales representatives |
| SpecialOffer | Discounts and promotions |

## References

- [Microsoft Adventure Works Documentation](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- [DuckDB MSSQL Extension](https://duckdb.org/docs/extensions/mssql)
- [hugr Data Sources Documentation](https://hugr-lab.github.io/docs/engine-configuration/data-sources/)
