# Open Payments DuckDB example

This example demonstrates how to set up a data source for Open Payments data using DuckDB in ``hugr``. The Open Payments data is a public dataset that contains information about financial relationships between healthcare providers and pharmaceutical companies. It also demonstrates how working with `hugr` self described data sources and data source as module.

To read more about the Open Payments data, visit the [Open Payments website](https://www.cms.gov/openpayments).

## Prerequisites

To run this example, you need to set up the example environment (see [README](../../README.md)).
Also you need to install [duckdb](https://duckdb.org/docs/installation/) to your local machine.

## Set up the environment

After setting up the environment, you can run the example using the following command:

```bash
cd examples/open-payments
sh setup.sh
```

This command will:

- Download the Open Payments archive data for 2023 year from the [Open Payments website](https://www.cms.gov/openpayments).
- Unpack the archive and load the data into a DuckDB database.

The data files will be stored in the data/open-payments directory, and the DuckDB database will be created in the same directory.

## Set up the hugr self described data source

Let's create a self described data source in `hugr` for the duckdb database through GraphQL API.
Open your browser and go to `http://localhost:18000/admin` (port can be changed through .env).
Create a new data source with the following mutation:

```graphql
mutation addOpenPaymentsDataSet {
  core {
    insert_data_sources(data: {
      name: "op2023",
      description: "Open payments 2023"
      type: "duckdb",
      prefix: "op2023",
      path: "/workspace/examples/open-payments/openpayments.duckdb"
      read_only: true,
      as_module:true,
    }) {
      name
      type
      description
      as_module
      path
      self_defined
      prefix
      read_only
      disabled
    }
  }
}
```

The mutation will create a new data source with the name `op2023`, type `duckdb`, and path to the DuckDB database file. The `as_module` flag is set to `true`, which means that the data source will be treated as a module in `hugr`. We create the data source as readonly, so that it can be used only for querying only.

Let's load the data source into `hugr`. You can do this by running the following mutation:

```graphql
mutation loadOpenPaymentsDataSet {
  function {
    core {
      load_data_sources(name: "op2023") {
        success
        message
      }
    }
  }
}
```

As you can see, we didn't create any catalogs for this data source. To request auto-generated schema, we can use following query:

```graphql
query schema {
  function {
    core {
      describe_data_source_schema(name: "op2023", self: true)
    }
  }
}
```

This query will return the string with the schema of the `op2023` data source, which is automatically generated based on the DuckDB database structure.

We can use auto-generated schema to query the data source or create a custom schema for it.
To use the auto-generated schema, you should set the `self_defined` flag to `true` in the data source.

```graphql
mutation updateOpenPaymentsDataSet {
  core {
    update_data_sources(
      filter: { name: { eq: "op2023" } }
      data: {
        self_defined: true
      }
    ) {
      name
      description
      type
      prefix
      path
      read_only
      as_module
      disabled
    }
  }
}
```

And reload the data source:

```graphql
mutation reloadOpenPaymentsDataSet {
  function {
    core {
      load_data_sources(name: "op2023") {
        success
        message
      }
    }
  }
}
```

Now you can fetch the schema in the AdminUI (GraphiQL) and see that the `op2023` data source placed as a field in the root query type.

The data set contains the following tables:

- `general_payments`: Contains information about general payments made by pharmaceutical companies to healthcare providers.
- `research_payments`: Contains information about research payments made by pharmaceutical companies to healthcare providers.
- `ownership_information`: Contains information about ownership and investment interests held by healthcare providers in pharmaceutical companies.

## Querying the data

Let's make a couple of queries to analyze the `op2023` data source.

### 1. Count of records in each table

```graphql
query countRecords {
  op2023 {
    general: general_payments_aggregation {
      count: _rows_count
      npis: Covered_Recipient_NPI {
        count
      }
      amount: Total_Amount_of_Payment_USDollars {
        sum
        avg
      }
    }
    research: research_payments_aggregation {
      count: _rows_count
      npis: Covered_Recipient_NPI {
        count
      }
      amount: Total_Amount_of_Payment_USDollars {
        sum
        avg
      }
    }
    ownership: ownership_information_aggregation {
      count: _rows_count
      npis: Physician_NPI {
        count
      }
      invested: Total_Amount_Invested_USDollars{
        sum
        avg
      }
    }
  }
}
```

This query will return the count of records in each table, the count of unique NPIs, and the total and average amount of payments or investments.

```json
{
  "data": {
    "op2023": {
      "general": {
        "count": 14607336,
        "npis": {
          "count": 929741
        },
        "amount": {
          "sum": 3277603855.210096,
          "avg": 224.38067113744052
        }
      },
      "ownership": {
        "count": 4013,
        "npis": {
          "count": 3650
        },
        "invested": {
          "sum": 218848111.81000003,
          "avg": 54534.78988537255
        }
      },
      "research": {
        "count": 1027925,
        "npis": {
          "count": 5640
        },
        "amount": {
          "sum": 8071625141.640943,
          "avg": 7852.3483149460735
        }
      }
    }
  }
}
```

### 2. Top 10 healthcare providers by total amount of general payments

```graphql
query topGeneralPayments {
  op2023 {
    general_payments_bucket_aggregation(
      filter: {Covered_Recipient_NPI: {is_null: false}}
      order_by: [{field: "aggregations.amount.sum", direction: DESC}]
      limit: 10
    ) {
      key {
        Covered_Recipient_NPI
        Covered_Recipient_Last_Name
        Covered_Recipient_First_Name
      }
      aggregations {
        amount: Total_Amount_of_Payment_USDollars {
          sum
        }
      }
    }
  }
}
```

### 3. Top 10 healthcare providers by total amount of research payments

```graphql
query topResearchPayments {
  op2023 {
    research_payments_bucket_aggregation(
      filter: {Covered_Recipient_NPI: {is_null: false}}
      order_by: [{field: "aggregations.amount.sum", direction: DESC}]
      limit: 10
    ) {
      key {
        Covered_Recipient_NPI
        Covered_Recipient_Last_Name
        Covered_Recipient_First_Name
      }
      aggregations {
        amount: Total_Amount_of_Payment_USDollars {
          sum
        }
      }
    }
  }
}
```

### 4. Top 10 Payers by total amount with their nature of payment

```graphql
query topPayers {
  op2023 {
    top_companies: general_payments_bucket_aggregation(
      order_by:[ {field: "aggregations.amount.sum", direction: DESC}]
      limit: 5
    ) @stats {
      key{
        name: Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
      }
      aggregations{
        nums: _rows_count
        recipients: Covered_Recipient_NPI{
          count(distinct: true)
        }
        nature: Nature_of_Payment_or_Transfer_of_Value{
          list(distinct:true)
        }
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
  }
}
```

### 5. Aggregated amount by state and quarter

This query aggregates the total amount of payments by state and quarter for both general and research payments.

```graphql
query aggregatedAmountByState {
  op2023 {
    general_payments_bucket_aggregation(
      filter: {
        Covered_Recipient_NPI:{is_null:false}
      }
    ) @stats {
      key{
        Recipient_State
        _Date_of_Payment_part(extract: quarter)
      }
      aggregations{
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
    research_payments_bucket_aggregation (
      filter: {
        Covered_Recipient_NPI:{is_null:false}
      }
    ) @stats {
      key{
        Recipient_State
        _Date_of_Payment_part(extract: quarter)
      }
      aggregations{
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
  }
}
```

## Query benchmarks

You can also query statistics about the data source using the `@stats` directive. This directive will return additional statistics about the query execution, such as the number of rows processed, the time taken to execute the query, and more.

```graphql
{
  op2023 {
    general_payments_bucket_aggregation(
      filter: {
        Covered_Recipient_NPI:{is_null:false}
      }
    ) @stats {
      key{
        Recipient_State
        _Date_of_Payment_part(extract: quarter)
      }
      aggregations{
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
    research_payments_bucket_aggregation (
      filter: {
        Covered_Recipient_NPI:{is_null:false}
      }
    ) @stats {
      key{
        Recipient_State
        _Date_of_Payment_part(extract: quarter)
      }
      aggregations{
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
    total_general_payments: general_payments_aggregation @stats{
      count: _rows_count
    }
    total_research_payments: research_payments_aggregation @stats{
      count: _rows_count
    }
    top_companies: general_payments_bucket_aggregation(
      order_by:[
        {field: "aggregations.amount.sum", direction: DESC}
      ]
      limit: 5
    ) @stats {
      key{
        name: Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
      }
      aggregations{
        nums: _rows_count
        recipients: Covered_Recipient_NPI{
          count
        }
        nature: Nature_of_Payment_or_Transfer_of_Value{
          list(distinct:true)
        }
        amount: Total_Amount_of_Payment_USDollars{
          sum
          avg
        }
      }
    }
  }
}
```

You will get the statistics in the extension field in the response.

```json
{
  "data": {
    "op2023": {
      "general_payments_bucket_aggregation": [ ... ],
      "research_payments_bucket_aggregation": [ ... ],
      "top_companies": [ ... ],
      "total_general_payments": {
        "count": 14607336
      },
      "total_research_payments": {
        "count": 1027925
      }
    }
  },
  "extensions": {
    "op2023": {
      "children": {
        "general_payments_bucket_aggregation": {
          "stats": {
            "compile_time": "293.5µs",
            "exec_time": "270.864833ms",
            "name": "general_payments_bucket_aggregation",
            "node_time": "271.158333ms",
            "planning_time": "148.75µs"
          }
        },
        "research_payments_bucket_aggregation": {
          "stats": {
            "compile_time": "369.375µs",
            "exec_time": "15.520875ms",
            "name": "research_payments_bucket_aggregation",
            "node_time": "15.89025ms",
            "planning_time": "230.375µs"
          }
        },
        "top_companies": {
          "stats": {
            "compile_time": "309.333µs",
            "exec_time": "392.747792ms",
            "name": "top_companies",
            "node_time": "393.057125ms",
            "planning_time": "200.75µs"
          }
        },
        "total_general_payments": {
          "stats": {
            "compile_time": "118.584µs",
            "exec_time": "997.375µs",
            "name": "total_general_payments",
            "node_time": "1.115959ms",
            "planning_time": "85.917µs"
          }
        },
        "total_research_payments": {
          "stats": {
            "compile_time": "103µs",
            "exec_time": "1.639709ms",
            "name": "total_research_payments",
            "node_time": "1.742709ms",
            "planning_time": "73.542µs"
          }
        }
      }
    }
  }
}
```

## Add relationships to the data source schema

You can add the catalog source that will contain your custom views or tables definitions, as well as relationships between them as a normal data source catalog. The tables and views will be added to the schema.

### Create providers table view

```bash
duckdb openpayments.duckdb -c "
CREATE TABLE providers AS
SELECT npi, any_value(last_name) AS last_name, any_value(first_name) AS first_name,
       any_value(total_general_count) AS total_general_count,
       any_value(total_general_amount) AS total_general_amount,
       any_value(avg_general_amount) AS avg_general_amount,
       any_value(total_research_count) AS total_research_count,
       any_value(total_research_amount) AS total_research_amount,
       any_value(avg_research_amount) AS avg_research_amount,
       any_value(total_ownership_count) AS total_ownership_count,
       any_value(total_invested_amount) AS total_invested_amount,
       any_value(avg_invested_amount) AS avg_invested_amount
FROM (
  SELECT DISTINCT
      Covered_Recipient_NPI AS npi,
      Covered_Recipient_Last_Name AS last_name,
      Covered_Recipient_First_Name AS first_name,
      COUNT(*) AS total_general_count,
      SUM(Total_Amount_of_Payment_USDollars) AS total_general_amount,
      AVG(Total_Amount_of_Payment_USDollars) AS avg_general_amount
  FROM general_payments 
  WHERE Covered_Recipient_Type = 'Covered Recipient Physician'
  GROUP BY ALL
  UNION BY NAME
  SELECT DISTINCT
      Covered_Recipient_NPI AS npi,
      Covered_Recipient_Last_Name AS last_name,
      Covered_Recipient_First_Name AS first_name,
      COUNT(*) AS total_research_count,
      SUM(Total_Amount_of_Payment_USDollars) AS total_research_amount,
      AVG(Total_Amount_of_Payment_USDollars) AS avg_research_amount
  FROM research_payments 
  WHERE Covered_Recipient_Type = 'Covered Recipient Physician'
  GROUP BY ALL
  UNION BY NAME
  SELECT DISTINCT
      Physician_NPI AS npi,
      Physician_First_Name AS first_name,
      Physician_Last_Name AS last_name,
      COUNT(*) AS total_ownership_count,
      SUM(Total_Amount_Invested_USDollars) AS total_invested_amount,
      AVG(Total_Amount_Invested_USDollars) AS avg_invested_amount
  FROM ownership_information
  GROUP BY ALL
)
GROUP BY npi;
";
```

### Create a catalog source

Create a new file or use an existing one in the `examples/open-payments/extra.graphql` directory.
In this file, we will define a extension to the generated schema. In this we will extend providers,general_payments, research_payments and ownership_information tables to add one calculated fields and relationships to the providers table.

```graphql
extend type providers {
  total_payments_amount: Float @sql(exp: "COALESCE(total_general_amount,0) + COALESCE(total_research_amount, 0)")
}


extend type general_payments {
  Covered_Recipient_NPI: BigInt @field_references(
    name: "general_payments_providers_npi"
    references_name: "providers"
    field: "npi"
    query: "provider"
    description: "NPI of the covered recipient physician"
    references_query: "general_payments"
    references_description: "General payments made to the covered recipient physician"
  )
}

extend type research_payments {
  Covered_Recipient_NPI: BigInt @field_references(
    name: "research_payments_providers_npi"
    references_name: "providers"
    field: "npi"
    query: "provider"
    description: "NPI of the covered recipient physician"
    references_query: "research_payments"
    references_description: "Research payments made to the covered recipient physician"
  )
}

extend type ownership_information {
  Physician_NPI: BigInt @field_references(
    name: "ownership_information_providers_npi"
    references_name: "providers"
    field: "npi"
    query: "provider"
    description: "NPI of the covered recipient physician"
    references_query: "ownership_information"
    references_description: "Ownership information of the covered recipient physician"
  )
}
```

### Querying across providers

Now we can query the top 10 providers with their top 5 general payments, research payments and ownership information by invested amount

```graphql
query topProviders {
  op2023 {
    info: providers(
      filter: {total_general_count: {is_null: false}, total_research_count: {is_null: false}, total_ownership_count: {is_null: false}}
      limit: 10
      order_by: [{field: "total_payments_amount", direction: DESC}]
    ) {
      npi
      last_name
      first_name
      total_payments_amount
      total_research_count
      total_general_count
      total_ownership_count
      general_payments(
        nested_order_by: [{field: "Total_Amount_of_Payment_USDollars", direction: DESC}]
        nested_limit: 5
      ) {
        Total_Amount_of_Payment_USDollars
        Nature_of_Payment_or_Transfer_of_Value
        Number_of_Payments_Included_in_Total_Amount
        Payment_Publication_Date
        Form_of_Payment_or_Transfer_of_Value
        Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
        Date_of_Payment
      }
      research_payments(
        nested_order_by: [{field: "Total_Amount_of_Payment_USDollars", direction: DESC}]
        nested_limit: 5
      ) {
        Total_Amount_of_Payment_USDollars
        Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
        Context_of_Research
        ClinicalTrials_Gov_Identifier
        Date_of_Payment
        Form_of_Payment_or_Transfer_of_Value
        Name_of_Study
        Payment_Publication_Date
        Research_Information_Link
        Related_Product_Indicator
        Submitting_Applicable_Manufacturer_or_Applicable_GPO_Name
      }
      ownership_information(
        nested_order_by: [
          {field: "Total_Amount_Invested_USDollars", direction: DESC}
        ]
        nested_limit: 5
      ) {
        Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Country
        Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
        Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_State
        Interest_Held_by_Physician_or_an_Immediate_Family_Member
        Value_of_Interest
        Total_Amount_Invested_USDollars
        Terms_of_Interest
      }
    }
  }
}
```

As well now we can get providers with aggregated references tables.

```graphql
query topProvidersWithAggregates {
  op2023 {
    info: providers(
      filter: {total_general_count: {is_null: false}, total_research_count: {is_null: false}, total_ownership_count: {is_null: false}}
      limit: 10
      order_by: [{field: "total_payments_amount", direction: DESC}]
    ) {
      npi
      last_name
      first_name
      total_payments_amount
      total_research_count
      total_general_count
      total_ownership_count
      general_payments_bucket_aggregation {
        key{
          Nature_of_Payment_or_Transfer_of_Value
        }
        aggregations{
          count: _rows_count
          amount: Total_Amount_of_Payment_USDollars{
            sum
          }        
        }
      }
      research_payments_bucket_aggregation {
        key{
          Form_of_Payment_or_Transfer_of_Value
        }
        aggregations{
          count: _rows_count
          amount: Total_Amount_of_Payment_USDollars{
            sum
          }        
        }
      }
      ownership_information_bucket_aggregation {
        key{
          Terms_of_Interest
        }
        aggregations{
          amount: Total_Amount_Invested_USDollars{
            sum
          }
        }
      }
    }
  }
}
```

We can also utilize relationships to filter data. For example, we can get all general payments made to providers with total amount of research payments greater than 1000 USD.

```graphql
query topProvidersWithResearchPayments {
  op2023 {
    general_payments(
      filter:{
        provider:{
          total_research_amount:{ gt: 1000 }
        }
      }
      order_by: [
        {field: "Total_Amount_of_Payment_USDollars", direction: DESC}
      ]
      limit: 10
    ){
      Total_Amount_of_Payment_USDollars
      Nature_of_Payment_or_Transfer_of_Value
      Number_of_Payments_Included_in_Total_Amount
      Payment_Publication_Date
      Form_of_Payment_or_Transfer_of_Value
      Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
      Date_of_Payment
      provider{
        npi
        last_name
        first_name
        total_research_amount
      }
    }
  }
}
```

Or get all general payments of providers who have at least one ownership with invested amount greater than 1000 USD.

```graphql
query topProvidersWithOwnership {
  op2023 {
    general_with_owns: general_payments(
      filter:{
        provider:{
          ownership_information: {
            any_of: {
              Total_Amount_Invested_USDollars: {eq:1000}
            }
          }
        }
      }
      order_by: [
        {field: "Total_Amount_of_Payment_USDollars", direction: DESC}
      ]
      limit: 10
    ){
      Total_Amount_of_Payment_USDollars
      Nature_of_Payment_or_Transfer_of_Value
      Number_of_Payments_Included_in_Total_Amount
      Payment_Publication_Date
      Form_of_Payment_or_Transfer_of_Value
      Applicable_Manufacturer_or_Applicable_GPO_Making_Payment_Name
      Date_of_Payment
      provider{
        npi
        last_name
        first_name
        total_invested_amount
      }
    }
  }
}
```
