# Fabric Warehouse Example

This example demonstrates how to use hugr with Microsoft Fabric Warehouse as a data source, connecting via the `azure://` URI scheme with Azure AD service principal authentication. It features a NYC taxi star schema with 7 tables — a Trip fact table linked to Date, Medallion, HackneyLicense, Geography, Time, and Weather dimensions — using `@field_source` to simplify column names and `@field_references` for relationship traversal.

## Prerequisites

- **Docker**: Installed and running
- **hugr**: Infrastructure running (`./scripts/start.sh` from repository root)
- **Microsoft Fabric Warehouse**: An active Fabric Warehouse instance with sample data
- **Azure AD Service Principal**: With access to the Fabric Warehouse, providing:
  - Tenant ID
  - Client ID
  - Client Secret

## Quick Start

### 1. Start the Environment

From the repository root, start the hugr infrastructure:

```bash
sh scripts/start.sh
```

### 2. Register Data Source in hugr

Open hugr GraphiQL at http://localhost:18000/admin and execute:

```graphql
mutation addAzure($data: data_sources_mut_input_data!) {
  core {
    insert_data_sources(data: $data) {
      name
    }
  }
}
```

With variables:

```json
{
  "data": {
    "name": "azure_wh",
    "description": "Azure Fabric Warehouse with sample data",
    "type": "mssql",
    "path": "azure://<azure-wh-host>/<azure-wh-name>?tenant_id=\"<tenant_id>\"&client_id=\"<client_id>\"&client_secret=\"<client_secret>\"",
    "prefix": "az",
    "as_module": true,
    "read_only": false,
    "catalogs": [{
      "name": "azure_wh",
      "description": "Fabric Warehouse schema",
      "type": "uri",
      "path": "/workspace/examples/fabric-warehouse/schema/"
    }]
  }
}
```

> **Note**: Replace the placeholder values with your actual Fabric Warehouse host, warehouse name, and Azure AD service principal credentials.

### 3. Load the Data Source

```graphql
mutation {
  core {
    load_data_source(name: "azure_wh")
  }
}
```

### 4. Verify with a Query

```graphql
query {
  azure_wh {
    Trip(limit: 5) {
      passenger_count
      trip_distance_miles
      fare_amount
      total_amount
      medallion {
        code
      }
      date {
        day_name
        month_name
        year
      }
    }
  }
}
```

## Azure Fabric Warehouse Connection URI Format

The Fabric Warehouse data source uses the following URI format:

```
azure://<host>/<warehouse-name>?tenant_id="<tenant_id>"&client_id="<client_id>"&client_secret="<client_secret>"
```

| Component | Description |
|-----------|-------------|
| `azure://` | Protocol scheme for Azure Fabric Warehouse |
| `<host>` | Fabric Warehouse hostname (e.g., `<workspace-id>.datawarehouse.fabric.microsoft.com`) |
| `<warehouse-name>` | Name of the Fabric Warehouse |
| `tenant_id` | Azure AD tenant identifier |
| `client_id` | Azure AD service principal application (client) ID |
| `client_secret` | Azure AD service principal secret |

The data source is registered with type `mssql` because Fabric Warehouse uses the TDS protocol.

## Sample Queries

### 1. Trip with Medallion and Date Relationships

Traverse the star schema from Trip to its dimension tables. Field names are simplified using `@field_source` (e.g., `fare_amount` instead of `FareAmount`, `trip_distance_miles` instead of `TripDistanceMiles`):

```graphql
query {
  azure_wh {
    Trip(
      filter: { fare_amount: { gt: 10.0 } }
      order_by: [{ field: "total_amount", direction: DESC }]
      limit: 10
    ) {
      passenger_count
      trip_distance_miles
      payment_type
      fare_amount
      tip_amount
      total_amount
      medallion {
        code
      }
      hackney_license {
        code
      }
      date {
        day_name
        month_name
        year
      }
    }
  }
}
```

### 2. Trip with Pickup/Dropoff Geography

Navigate from Trip to pickup and dropoff geography dimensions:

```graphql
query {
  azure_wh {
    Trip(limit: 5) {
      trip_distance_miles
      fare_amount
      total_amount
      pickup_geography {
        city
        state
        zip_code
      }
      dropoff_geography {
        city
        state
        zip_code
      }
    }
  }
}
```

### 3. Trip with Pickup/Dropoff Time

Navigate from Trip to pickup and dropoff time dimensions:

```graphql
query {
  azure_wh {
    Trip(limit: 5) {
      fare_amount
      total_amount
      pickup_time {
        hour
        minute
        hourly_bucket
        day_time_bucket
      }
      dropoff_time {
        hour
        minute
        hourly_bucket
      }
    }
  }
}
```

### 4. Medallion with Reverse Trip Navigation

Navigate from Medallion to its related trips using the `trips` reverse navigation field:

```graphql
query {
  azure_wh {
    Medallion(limit: 3) {
      id
      code
      trips(nested_limit: 5) {
        fare_amount
        tip_amount
        total_amount
        trip_distance_miles
        date {
          day_name
        }
      }
    }
  }
}
```

### 5. Date Dimension with Trip Aggregation

Navigate from Date to trip aggregations:

```graphql
query {
  azure_wh {
    Date(
      filter: { day_name: { eq: "Monday" } }
      limit: 3
    ) {
      date
      day_name
      month_name
      year
      is_holiday_usa
      trips_aggregation {
        _rows_count
        fare_amount { sum avg }
        tip_amount { sum avg }
      }
    }
  }
}
```

### 6. Trip Aggregation

Get summary statistics for all trip data:

```graphql
query {
  azure_wh {
    Trip_aggregation {
      _rows_count
      fare_amount { sum avg min max }
      tip_amount { sum avg }
      trip_distance_miles { avg max }
      trip_duration_seconds { avg max }
    }
  }
}
```

### 7. Trip Bucket Aggregation by Medallion

Group trip statistics by medallion with relationship traversal in the bucket key:

```graphql
query {
  azure_wh {
    Trip_bucket_aggregation {
      key {
        medallion {
          business_key
        }
      }
      aggregations {
        _rows_count
        fare_amount { sum avg }
        tip_amount { sum avg }
      }
    }
  }
}
```

### 8. Trip Bucket Aggregation by Payment Type

Group trip statistics by payment type:

```graphql
query {
  azure_wh {
    Trip_bucket_aggregation {
      key {
        payment_type
      }
      aggregations {
        _rows_count
        fare_amount { sum avg }
        tip_amount { sum avg }
        trip_distance_miles { avg }
      }
    }
  }
}
```

### 9. Trips Filtered by Date and Fare

Filter trips by date dimension fields and fare amount:

```graphql
query {
  azure_wh {
    Trip(
      filter: {
        fare_amount: { gt: 20.0 }
        date: { year: { eq: "2024" }, month_name: { eq: "January" } }
      }
      order_by: [{ field: "total_amount", direction: DESC }]
      limit: 10
    ) {
      passenger_count
      trip_distance_miles
      fare_amount
      tip_amount
      total_amount
      payment_type
      date {
        date
        day_name
      }
      medallion {
        code
      }
    }
  }
}
```

### 10. Trips Filtered by Pickup Geography

Find trips picked up in a specific city:

```graphql
query {
  azure_wh {
    Trip(
      filter: {
        pickup_geography: { city: { eq: "New York" } }
        passenger_count: { gt: 2 }
      }
      limit: 10
    ) {
      passenger_count
      trip_distance_miles
      fare_amount
      total_amount
      pickup_geography {
        city
        state
        zip_code
      }
      dropoff_geography {
        city
        state
      }
    }
  }
}
```

### 11. Weather with Date and Geography

Query weather data with its dimension relationships:

```graphql
query {
  azure_wh {
    Weather(
      filter: { avg_temperature_fahrenheit: { gt: 80.0 } }
      limit: 5
    ) {
      precipitation_inches
      avg_temperature_fahrenheit
      date {
        date
        day_name
        month_name
      }
      geography {
        city
        state
      }
    }
  }
}
```

## Key Features

This example showcases the following hugr capabilities:

| Feature | Description |
|---------|-------------|
| Azure Fabric Warehouse connection | Cloud data source via `azure://` URI with Azure AD authentication |
| Catalog-based schema | Schema loaded via `catalogs` with GraphQL SDL files |
| Star schema pattern | Fact table (Trip) with 6 dimension references (Date, Medallion, HackneyLicense, Geography, Time, Weather) |
| `@field_source` directive | Simplifies column names (e.g., `fare_amount` instead of `FareAmount`) |
| `@field_references` directive | Defines relationships — 7 foreign keys on Trip, 2 on Weather |
| `@table` directive | Maps GraphQL types to warehouse tables with schema prefix (`dbo.Date`) |
| `@pk` directive | Marks primary key fields — composite PK on Trip and Weather |
| Multiple references to same type | Trip references Geography twice (pickup/dropoff) and Time twice (pickup/dropoff) |
| Forward navigation | `Trip { medallion { code } }`, `Trip { pickup_geography { city } }` |
| Reverse navigation | `Medallion { trips { ... } }`, `Date { trips { ... } }` |
| Aggregation | `_aggregation` suffix with `sum`, `avg`, `min`, `max`, `_rows_count` |
| Bucket aggregation | `_bucket_aggregation` with relationship traversal in `key` |
| Filter by relationships | Filter trips by dimension fields (e.g., `date: { year: { eq: "2012" } }`) |

## Schema Patterns

### Star Schema Design

This example demonstrates a classic star schema pattern with:

- **Fact tables**: Trip (central), Weather
- **Dimension tables**: Date, Medallion, HackneyLicense, Geography, Time

```
                  ┌────────────┐
                  │    Date    │
                  └─────┬──────┘
                        │
    ┌───────────┐  ┌────┴─────┐  ┌──────────────┐
    │ Medallion ├──┤   Trip   ├──┤HackneyLicense│
    └───────────┘  └┬───┬───┬─┘  └──────────────┘
                    │   │   │
            ┌───────┘   │   └───────┐
            │           │           │
       ┌────┴─────┐ ┌──┴──┐  ┌────┴─────┐
       │Geography │ │Time │  │ Weather  │
       │(pickup/  │ │(pk/ │  └──────────┘
       │ dropoff) │ │ do) │
       └──────────┘ └─────┘
```

### Field Source Mapping

The `@field_source` directive maps simplified GraphQL field names to actual database column names:

```graphql
type Trip @table(name: "dbo.Trip") {
  fare_amount: Float @field_source(field: "FareAmount")
  trip_distance_miles: Float @field_source(field: "TripDistanceMiles")
  pickup_latitude: Float @field_source(field: "PickupLatitude")
}
```

### Multiple References to Same Type

Trip references Geography and Time twice each, with distinct navigation names:

```graphql
type Trip @table(name: "dbo.Trip") {
  pickup_geography_id: Int @field_source(field: "PickupGeographyID")
    @field_references(query: "pickup_geography", references_query: "pickup_trips")
  dropoff_geography_id: Int @field_source(field: "DropoffGeographyID")
    @field_references(query: "dropoff_geography", references_query: "dropoff_trips")
}
```

### Data Type Mapping

| Fabric Warehouse (SQL) Type | GraphQL Type | Notes |
|-----------------------------|--------------|-------|
| `int`, `smallint` | `Int` / `Int!` | Integer values |
| `varchar`, `nvarchar` | `String` / `String!` | Text values |
| `decimal`, `float` | `Float` / `Float!` | Numeric values |
| `datetime2`, `datetimeoffset` | `Timestamp` / `Timestamp!` | Timestamp values |
| `date` | `Date` | Date-only values |
| `bit` | `Boolean` | Boolean values |

### Data Model

**Date** — Date dimension (32 fields) with calendar attributes: day/week/month/quarter/year breakdowns, holiday flags, first/last day boundaries.

**Medallion** — Taxi cab identifier dimension: `id`, `business_key`, `code`.

**HackneyLicense** — Driver license dimension: `id`, `business_key`, `code`.

**Geography** — Location dimension: `id`, `zip_code_bkey`, `county`, `city`, `state`, `country`, `zip_code`.

**Time** — Time-of-day dimension: `id`, `business_key`, `hour`, `minute`, `second`, `hourly_bucket`, `day_time_bucket`.

**Weather** — Weather fact table keyed by `date_id` + `geography_id`: `precipitation_inches`, `avg_temperature_fahrenheit`.

**Trip** — Central fact table with composite PK (`date_id` + `medallion_id` + `hackney_license_id`), 7 dimension references, coordinate data, and financial fields (`fare_amount`, `surcharge_amount`, `tax_amount`, `tip_amount`, `tolls_amount`, `total_amount`).

## Troubleshooting

### Authentication Errors

- Verify your `tenant_id`, `client_id`, and `client_secret` values are correct
- Ensure the service principal has the necessary permissions to access the Fabric Warehouse
- Check that the client secret has not expired — Azure AD secrets have configurable expiration dates
- Confirm the tenant ID matches the Azure AD directory where the service principal is registered

### Connection Timeout

- Verify the Fabric Warehouse hostname is correct and the warehouse is running
- Check that the hugr container can reach the Fabric Warehouse endpoint (firewall rules, network security groups)
- Ensure no VPN or proxy is required to access the Fabric Warehouse from your environment

### Table Not Found

- Verify the table names in `schema/schema.graphql` match the exact names in your Fabric Warehouse (case-sensitive)
- All tables use the `dbo` schema prefix (e.g., `dbo.Trip`, `dbo.Date`)
- If tables are in a different schema, update the `@table(name: "SchemaName.TableName")` directive accordingly

### Empty Results

- Verify the Fabric Warehouse tables contain data
- Check filter conditions — they may be too restrictive
- Try querying without filters first: `azure_wh { Trip(limit: 1) { fare_amount } }`

### General Debugging

- Check hugr server logs for detailed error messages
- Use the hugr admin UI to verify the data source status
- Ensure the `load_data_source` mutation was executed successfully after registration
