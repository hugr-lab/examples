# Quickstart: MSSQL Adventure Works Example

**Time to complete**: ~5 minutes

## Prerequisites

- Docker installed and running
- **amd64 platform** (Intel/AMD processor - MSSQL Server does not support ARM)
- hugr examples repository cloned
- hugr infrastructure running (`./scripts/start.sh`)

## Quick Setup

### 1. Start MSSQL Server (if not already running)

```bash
# Start MSSQL with the mssql profile
docker-compose --profile mssql up -d mssql

# Wait for MSSQL to be ready (check health)
docker-compose ps mssql
```

### 2. Run Setup Script

```bash
cd examples/mssql
./setup.sh
```

The script will:
- Check if you're on amd64 platform
- Start MSSQL container if needed
- Create the AdventureWorksLT database
- Load sample data (~300 records)
- Display setup statistics

### 3. Register Data Source in Hugr

Open hugr GraphiQL at http://localhost:18000/admin and execute:

```graphql
mutation {
  core {
    insert_data_sources(data: {
      name: "adventureworks"
      type: "mssql"
      prefix: "aw"
      description: "Adventure Works LT sample database"
      as_module: true
      read_only: false
      path: "mssql://sa:${MSSQL_SA_PASSWORD}@mssql:1433/AdventureWorksLT"
      catalogs: [{
        name: "adventureworks"
        type: "uri"
        description: "Adventure Works schema"
        path: "/workspace/examples/mssql/schema"
      }]
    }) {
      name
      type
      path
    }
  }
}
```

### 4. Load the Data Source

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

### 5. Verify with a Query

```graphql
query {
  aw {
    Product(limit: 5) {
      ProductID
      Name
      ListPrice
      category {
        Name
      }
    }
  }
}
```

## Expected Output

```json
{
  "data": {
    "aw": {
      "Product": [
        {
          "ProductID": 680,
          "Name": "HL Road Frame - Black, 58",
          "ListPrice": 1431.50,
          "category": {
            "Name": "Road Frames"
          }
        }
      ]
    }
  }
}
```

## Troubleshooting

### "Platform not supported" error
MSSQL Server only runs on amd64 (Intel/AMD). If you're on Apple Silicon (M1/M2/M3), you'll need to use a remote MSSQL server or a cloud instance.

### Connection refused
1. Check if MSSQL container is running: `docker-compose ps mssql`
2. Check MSSQL logs: `docker-compose logs mssql`
3. Verify port 18033 is not in use: `lsof -i :18033`

### Database does not exist
Run the setup script again: `./setup.sh --force`

## Next Steps

- Explore more sample queries in the [README](../../examples/mssql/README.md)
- Try aggregation queries
- Explore relationship traversals
- Compare with PostgreSQL and MySQL examples
