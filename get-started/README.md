# Get started

This example will set up a Northwind database on PostgreSQL and create GraphQL SDL schema for it.
Originally, the Northwind database was created by Microsoft and is widely used as a sample database for learning SQL and database management.
The Northwind database contains data about a fictional company that imports and exports specialty foods from around the world. It includes tables for customers, orders, products, suppliers, and more.
The example uses the `hugr` library to generate a GraphQL schema from the Northwind database schema. The generated schema can be used to query and manipulate the data in the Northwind database using GraphQL.

Currently, `hugr` doesn't support MS SQL Server, we will use PostgreSQL as a data source. The Northwind database schema is compatible with PostgreSQL, and we will use it to demonstrate how to set up a GraphQL API using `hugr`.
The database dump was taken from `https://github.com/pthom/northwind_psql`.

To run this example, you need to start entire examples infrastructure (scripts/start.sh). Than you can run the example:

## 1. Up the dump PostgreSQL database with Northwind schema

```bash
cd get-started
sh setup.sh
```

## 2. Set up the hugr data source

The example schema definition is located in `get-started/schema`. You need to set up the data source in `hugr`.

Open browser and go to `http://localhost:18000/admin` (port can be changed through .env). You will see the hugr admin UI (GraphiQL).
Create a new data source with the following mutation:

```graphql
mutation addNorthwindDataSet($data: data_sources_mut_input_data! = {}) {
  core {
    insert_data_sources(data: $data) {
      name
      description
      as_module
      disabled
      path
      prefix
      read_only
      self_defined
      type
      catalogs {
        name
        description
        path
        type
      }
    }
  }
}
```

You can use the following variables:

```json
{
  "data": {
    "name": "northwind",
    "type": "postgres",
    "prefix": "nw",
    "description": "The Northwind database example",
    "read_only": false,
    "as_module": true,
    "path": "postgres://hugr:hugr_password@postgres:5432/northwind",
    "catalogs": [
      {
        "name": "northwind",
        "type": "uri",
        "description": "Northwind database schema",
        "path": "/workspace/get-started/schema"
      }
    ]
  }
}
```

This mutation will create a new data source with the name `northwind` and the path to the Northwind database schema. The `catalogs` field is used to specify the schema definition for the data source.

## 3. Load the data source

After creating the data source, you need to load it manually - it will load automatically on startup. You can do this by running the following mutation:

```graphql
mutation {
  function {
    core {
      load_data_source(name: "northwind") {
        success
        message
      }
    }
  }
}
```

## 4. Finally, you can query the data source

You can use the following queries:

### 4.1. Get the list of customers with their sum of orders from the Northwind database

```graphql
{
  northwind {
    customers {
      id
      company_name
      orders_aggregation{
        details{
          total{
            sum
          }
        }
      }
    }
  }
}
```

### 4.2. Get the total amount and products count by category and shipper

```graphql
{
  northwind {
    order_details_bucket_aggregation(
      order_by:[
        {field: "aggregations.total.sum", direction: DESC}
      ]
    ){
      key{
        product{
          category{
            name
          }
        }
        order{
          shipper{
            company_name
          }
        }
      }
      aggregations{
        total{
          sum
        }
        quantity{
          sum
        }
      }
    } 
  }
}
```

### 4.3. Get the total shipped products (amount) by years and months

```graphql
{
  northwind {
    orders_bucket_aggregation(
      filter: {
        shipped_date: {
          is_null: false
        }
      }
      order_by: [
        {field: "key.year", direction: DESC}
        {field: "key.month", direction: DESC}
      ]
    ){
      key{
        year: _shipped_date_part(extract: year)
        month:_shipped_date_part(extract: month)
      }
      aggregations{
        _rows_count
        details{
          total{
            sum
          }
        }
      }
    }
  }
}
```

### 4.4. Get the total shipped products (amount) by month bucket and in the orders were shipped by suppliers from Finland and France

```graphql
{
  northwind {
    orders_bucket_aggregation(
      filter: {
        shipped_date: {
          is_null: false
        }
        details: {
          any_of: {
            product:{
              supplier:{
                country: {in: ["Finland", "France"]}
              }
            }
          }
        }
      }
      order_by: [
        {field: "key.bucket", direction: DESC}
      ]
    ){
      key{
        bucket: shipped_date(bucket: month)
      }
      aggregations{
        _rows_count
        details{
          total{
            sum
          }
        }
      }
    }
  }
}
```

### 4.5. Get the total shipped products (amount) by month bucket and shipped by suppliers from Finland and France

```graphql
{
  northwind {
    orders_bucket_aggregation(
      filter: {
        shipped_date: {
          is_null: false
        }
      }
      order_by: [
        {field: "key.bucket", direction: DESC}
      ]
    ){
      key{
        bucket: shipped_date(bucket: month)
      }
      aggregations{
        _rows_count
        details(
          filter:{
            product:{
              supplier:{
                country: {in: ["Finland", "France"]}
              }
            }
          }
        ){
          total{
            sum
          }
        }
      }
    }
  }
}
```
