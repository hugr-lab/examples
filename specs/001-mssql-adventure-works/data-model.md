# Data Model: MSSQL Adventure Works Example

**Branch**: `001-mssql-adventure-works` | **Date**: 2026-02-02

## Entity Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ ProductCategory │◄────│     Product      │────►│  ProductModel   │
│  (hierarchy)    │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               │ (via SalesOrderDetail)
                               ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│    Customer     │◄────│ SalesOrderHeader │────►│     Address     │
│                 │     │                  │     │   (Ship/Bill)   │
└────────┬────────┘     └──────────────────┘     └────────┬────────┘
         │                      │                         │
         │                      ▼                         │
         │              ┌──────────────────┐              │
         └──────────────│ CustomerAddress  │──────────────┘
           (M2M)        │   (junction)     │    (M2M)
                        └──────────────────┘
```

## Entities

### ProductCategory

Hierarchical classification of products (self-referencing for parent/child).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| ProductCategoryID | Int! | PK | Unique identifier |
| ParentProductCategoryID | Int | FK → ProductCategory | Parent category (null for root) |
| Name | String! | NOT NULL | Category name |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- Self-referencing: parent_category (many-to-one), subcategories (one-to-many)
- products: One-to-many with Product

### ProductModel

Product design templates that group product variants.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| ProductModelID | Int! | PK | Unique identifier |
| Name | String! | NOT NULL | Model name |
| CatalogDescription | String | NULL | XML catalog description (as string) |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- products: One-to-many with Product

### Product

Merchandise available for sale.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| ProductID | Int! | PK | Unique identifier |
| Name | String! | NOT NULL | Product name |
| ProductNumber | String! | NOT NULL, UNIQUE | Product SKU |
| Color | String | NULL | Product color |
| StandardCost | Float! | NOT NULL | Manufacturing cost |
| ListPrice | Float! | NOT NULL | Retail price |
| Size | String | NULL | Product size |
| Weight | Float | NULL | Product weight (decimal) |
| ProductCategoryID | Int | FK → ProductCategory | Category reference |
| ProductModelID | Int | FK → ProductModel | Model reference |
| SellStartDate | Timestamp! | NOT NULL | Start selling date |
| SellEndDate | Timestamp | NULL | End selling date |
| DiscontinuedDate | Timestamp | NULL | Discontinuation date |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- category: Many-to-one with ProductCategory
- model: Many-to-one with ProductModel
- order_details: One-to-many with SalesOrderDetail

### Customer

Person or business who purchases products.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| CustomerID | Int! | PK | Unique identifier |
| Title | String | NULL | Name prefix (Mr., Ms., etc.) |
| FirstName | String! | NOT NULL | First name |
| MiddleName | String | NULL | Middle name |
| LastName | String! | NOT NULL | Last name |
| Suffix | String | NULL | Name suffix (Jr., Sr., etc.) |
| CompanyName | String | NULL | Company name (B2B customers) |
| SalesPerson | String | NULL | Assigned sales representative |
| EmailAddress | String | NULL | Email contact |
| Phone | String | NULL | Phone contact |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- addresses: Many-to-many with Address (via CustomerAddress)
- orders: One-to-many with SalesOrderHeader

### Address

Customer shipping and billing locations.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| AddressID | Int! | PK | Unique identifier |
| AddressLine1 | String! | NOT NULL | Street address line 1 |
| AddressLine2 | String | NULL | Street address line 2 |
| City | String! | NOT NULL | City name |
| StateProvince | String! | NOT NULL | State or province |
| CountryRegion | String! | NOT NULL | Country or region |
| PostalCode | String! | NOT NULL | Postal/ZIP code |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- customers: Many-to-many with Customer (via CustomerAddress)
- ship_to_orders: One-to-many with SalesOrderHeader (as shipping address)
- bill_to_orders: One-to-many with SalesOrderHeader (as billing address)

### CustomerAddress (Junction Table)

Association between customers and their addresses.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| CustomerID | Int! | PK, FK → Customer | Customer reference |
| AddressID | Int! | PK, FK → Address | Address reference |
| AddressType | String! | NOT NULL | Type: "Main Office", "Shipping", etc. |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- customer: Many-to-one with Customer
- address: Many-to-one with Address

### SalesOrderHeader

Sales transaction metadata.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| SalesOrderID | Int! | PK | Unique identifier |
| RevisionNumber | Int! | NOT NULL | Order revision number |
| OrderDate | Timestamp! | NOT NULL | Order placement date |
| DueDate | Timestamp! | NOT NULL | Expected delivery date |
| ShipDate | Timestamp | NULL | Actual ship date |
| Status | Int! | NOT NULL | Order status code |
| OnlineOrderFlag | Boolean! | NOT NULL | True if ordered online |
| SalesOrderNumber | String! | COMPUTED | Format: 'SO' + SalesOrderID |
| PurchaseOrderNumber | String | NULL | Customer PO reference |
| AccountNumber | String | NULL | Customer account number |
| CustomerID | Int! | FK → Customer | Customer reference |
| ShipToAddressID | Int | FK → Address | Shipping address |
| BillToAddressID | Int | FK → Address | Billing address |
| ShipMethod | String! | NOT NULL | Shipping method name |
| SubTotal | Float! | NOT NULL | Order subtotal |
| TaxAmt | Float! | NOT NULL | Tax amount |
| Freight | Float! | NOT NULL | Shipping cost |
| TotalDue | Float! | COMPUTED | SubTotal + TaxAmt + Freight |
| Comment | String | NULL | Order comments |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- customer: Many-to-one with Customer
- ship_to_address: Many-to-one with Address
- bill_to_address: Many-to-one with Address
- details: One-to-many with SalesOrderDetail

### SalesOrderDetail

Individual line items in a sales order.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| SalesOrderID | Int! | PK, FK → SalesOrderHeader | Order reference |
| SalesOrderDetailID | Int! | PK | Line item identifier |
| OrderQty | Int! | NOT NULL | Quantity ordered |
| ProductID | Int! | FK → Product | Product reference |
| UnitPrice | Float! | NOT NULL | Price per unit |
| UnitPriceDiscount | Float! | NOT NULL | Discount percentage |
| LineTotal | Float! | COMPUTED | Calculated line total |
| ModifiedDate | Timestamp! | NOT NULL | Last modification timestamp |

**Relationships**:
- order: Many-to-one with SalesOrderHeader
- product: Many-to-one with Product

## Validation Rules

### Business Rules
1. Product.ListPrice >= Product.StandardCost (margin requirement)
2. Product.SellStartDate <= Product.SellEndDate when both present
3. SalesOrderDetail.OrderQty > 0
4. SalesOrderDetail.UnitPriceDiscount between 0 and 1

### Referential Integrity
1. Product.ProductCategoryID must reference existing ProductCategory
2. Product.ProductModelID must reference existing ProductModel
3. CustomerAddress requires valid Customer and Address
4. SalesOrderHeader requires valid Customer
5. SalesOrderDetail requires valid SalesOrderHeader and Product

## State Transitions

### Product Lifecycle
```
Active (SellStartDate set, no SellEndDate)
  ↓
Discontinued (DiscontinuedDate set)
  ↓
End of Sale (SellEndDate set)
```

### Order Status
```
1 = In Process
2 = Approved
3 = Backordered
4 = Rejected
5 = Shipped
6 = Cancelled
```

## Data Volume (Adventure Works LT)

| Entity | Approximate Records |
|--------|---------------------|
| ProductCategory | 41 |
| ProductModel | 128 |
| Product | 295 |
| Customer | 847 |
| Address | 450 |
| CustomerAddress | 417 |
| SalesOrderHeader | 32 |
| SalesOrderDetail | 542 |
