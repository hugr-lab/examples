# OpenStreetMap DuckDB dataset

In this example, we will use the OpenStreetMap dataset to demonstrate how to work with geospatial data in DuckDB.
We will set up a DuckDB database with OpenStreetMap data and create a GraphQL schema to query this data. Than we will put the DuckDB database file into an object storage bucket and configure the `hugr` server to use it as a data source.

To prepare the OpenStreetMap data, we will use the [osm_dbt](https://github.com/hugr-lab/osm_dbt) project, which is a dbt project that prepares OpenStreetMap data in the DuckDB database file.

We will use the Baden-Württemberg (Germany) and Bayern regions as an example, but you can adapt the setup to any other region just run the `setup.sh --region <region_name>`. Be careful that the region you choose can consume a lot of disk space and requires a lot of RAM to process. The example will create a DuckDB database file with OpenStreetMap data of around 5 GB for the Baden-Württemberg region and requires 16 GB of RAM. Requirements to other regions:

- **bw** - around 100 GB of disk space and at least 16 GB of RAM (the final database file size around 5 GB).
- **germany** - around 150 GB of disk space and at least 96 GB of RAM (the final database file size around 50 GB).
- **europe** - around 250 GB of disk space and at least 128 GB of RAM (the final database file size around 150 GB).
- **world** - around 500 GB of disk space and at least 256 GB of RAM (it was not tested).

## Prerequisites

- Docker and Docker Compose installed
- Basic knowledge of GraphQL and DuckDB
- Familiarity with geospatial data concepts
- `hugr` server running (see [setup instructions](https://hugr-lab.github.io/docs/installation/))
- Access to the `hugr` admin UI (usually at `http://localhost:18000/admin`)
- Python 3.7+ installed (for running dbt project)
- `duckdb` installed (for running DuckDB queries)

## Hardware requirements

- At least 6 CPU cores available for running the dbt project and the `hugr` instance.
- At least 16 GB of RAM available to run dbt project
- At least 100 GB of disk space available for the DuckDB database file and data preparation process (example will create a DuckDB database file with OpenStreetMap data of around 5 GB)

To run this example, you need to start the entire examples infrastructure (scripts/start.sh). Then you can run the example:

```bash
# Start the examples infrastructure
scripts/start.sh
```

This will start the `hugr` server, the DuckDB database, and the necessary services to run the example.

After it is running, we need to prepare the OpenStreetMap data in the DuckDB database.

## Quick Setup

### One-line Setup (Recommended)

```bash
# Default Baden-Württemberg region
cd examples/osm && bash setup.sh

# Custom region
cd examples/osm && bash setup.sh --region berlin

# Force fresh setup
cd examples/osm && bash setup.sh --force-clone
```

### Manual Setup

```bash
# 1. Navigate to data directory
mkdir -p ../../data && cd ../../data

# 2. Clone osm_dbt project
git clone https://github.com/hugr-lab/osm_dbt.git osm
cd osm

# 3. Install dependencies
pip install -r requirements.txt
make install

# 4. Process data (10-30 minutes)
make quick-region REGION=bw TARGET=dev

# 5. Verify database
make stats REGION=bw TARGET=dev
```

### Expected Output

```md
Database: ./data/processed/bw.duckdb
Size: ~5GB
Processing time: 10-20 minutes
RAM usage: ~16GB peak
```

### hugr Integration

```graphql
# Add data source
mutation addOSMDataSource {
  core {
    insert_data_sources(data: {
      name: "osm.bw"
      description: "OpenStreetMap data bw"
      type: "duckdb"
      prefix: "osm_bw"
      path: "/workspace/data/osm/data/processed/bw.duckdb"
      read_only: true
      as_module: true
      self_defined: true
    }) {
      name type path
    }
  }
}

# Load data source
mutation loadOSMDataSource {
  function {
    core {
      load_data_source(name: "osm.bw") {
        success message
      }
    }
  }
}
```

## Querying Data

You can now query the OpenStreetMap data using GraphQL. Here are some example queries:

```graphql
# Get all districts in Baden-Württemberg with their centroids and road lengths by class
query getDistricts {
  osm {
    bw {
      osm_administrative_boundaries(filter: {admin_level: {eq: 6}}) {
        osm_id
        name
        name_de
        region_code
        area_sqm
        centroid: geom(transforms: Centroid)
        _spatial(field: "geom", type: INTERSECTS){
          osm_bw_osm_roads_bucket_aggregation(field: "geom"){
            key{
              road_class
            }
            aggregations{
              len: _geom_measurement(type: LengthSpheroid){
                sum
              } 
            }
          }
        }
      }
    }
  }
}
```

```graphql
# Count of all points of interest (POIs) in Baden-Württemberg
query countPOIs {
  osm {
    bw {
      osm_amenities_aggregation @stats {
        _rows_count
      }
    }
  }
}
```

```graphql
# Get all points of interest (POIs) in Baden-Württemberg by type and category in each district (another aggregation method)
query getPOIsByDistrict {
  osm {
    bw {
      osm_amenities_bucket_aggregation @stats {
        key {
          _spatial(field: "geom", type: INTERSECTS) {
            landkreis: osm_bw_osm_administrative_boundaries(
              field: "geom"
              filter: {admin_level: {eq: 6}}
            ) @unnest {
              name
            }
          }
          category
          amenity_type
        }
        aggregations {
          _rows_count
        }
      }
    }
  }
}
```

With filters

```graphql
query osm($geom: Geometry){
  osm{
    bw{
      osm_amenities_bucket_aggregation(filter:{geom:{intersects: $geom}}) @stats {
        key {
          _spatial(field: "geom", type: INTERSECTS) {
            landkreis: osm_bw_osm_administrative_boundaries(
              field: "geom"
              filter: {admin_level: {eq: 6}, geom: {intersects: $geom}}
              inner: true
            ) {
              name
            }
          }
          category
          amenity_type
        }
        aggregations {
          _rows_count
        }
      }
    }
  }
}
```

and variables

```json
{
  "geom": {
    "type": "Polygon",
    "coordinates": [
      [
        [
          9.0848689,
          48.512357200000004
        ],
        [
          9.596362000000001,
          48.512357200000004
        ],
        [
          9.596362000000001,
          48.788253100000006
        ],
        [
          9.0848689,
          48.788253100000006
        ],
        [
          9.0848689,
          48.512357200000004
        ]
      ]
    ]
  }
}
```

The input geometry can be any valid GeoJSON geometry as object or as string.

## Object Storage

You can also use object storage to store the OpenStreetMap data. Put the DuckDB database file into an object storage bucket and configure the `hugr` server to use it as a data source.

### Prepare DuckDB OSM

Set up the new DuckDB database with OpenStreetMap data by running the `setup.sh` script, we will use the Bayern region as an example:

```bash
cd examples/osm && bash setup.sh --region bayern
```

### Copy DuckDB file to object storage

Open the MinIO admin UI (usually at `http://localhost:9000`) and create a bucket named `osm-bw`. Then copy the DuckDB database file to the bucket:

Create a bucket named `osm` and copy the DuckDB database file to the bucket:

1. Open the MinIO admin UI (default: at `http://localhost:18081` user: `minio_admin` password: `minio_password123`) and create a bucket named `data` (Administrator -> Buckets -> Create Bucket).
2. Load the DuckDB database file into the bucket (Object Browser -> select bucket `data`  -> Create new path -> type `osm` -> Create -> Upload file -> select the DuckDB file `bayern.duckdb`).

### Configure `hugr` to use object storage

To configure the `hugr` server to use the object storage bucket, you need to register the bucket in the `hugr` admin UI:

```graphql
mutation addDataBucket {
  function {
    core {
      storage {
        register_s3(
          endpoint: "minio:9000"
          key: "minio_admin" # replace with your MinIO access key
          name: "examples"
          region: ""
          scope: "s3://data"
          secret: "minio_password123" # replace with your MinIO secret
          url_style: "path"
          use_ssl: false
        ){
          success
          message
        }
      }
    }
  }
}
```

### Add New DuckDB Data Source

```graphql
mutation addDuckDBDataSource {
  core {
    insert_data_sources(data: {
      name: "osm.bayern"
      description: "OpenStreetMap data Bayern"
      type: "duckdb"
      prefix: "osm_bayern"
      path: "s3://data/osm/bayern.duckdb"
      read_only: true
      as_module: true
      self_defined: true
    }) {
      name type path
    }
  }
}
```

### Load Data Source

```graphql
mutation loadOSMDataSource {
  function {
    core {
      load_data_source(name: "osm.bayern") {
        success message
      }
    }
  }
}
```

### Querying Data from Object Storage

You can now query the OpenStreetMap data stored in the object storage using the same GraphQL queries as before. The only difference is that the data source name will be `osm.bayern` instead of `osm.bw`.

```graphql
query getDistrictsBayern {
  osm {
    bayern{
      osm_administrative_boundaries(filter: {admin_level: {eq: 6}}) {
        osm_id
        name
        name_de
        region_code
        area_sqm
        centroid: geom(transforms: Centroid)
        _spatial(field: "geom", type: INTERSECTS){
          osm_bayern_osm_roads_bucket_aggregation(field: "geom"){
            key{
              road_class
            }
            aggregations{
              len: _geom_measurement(type: LengthSpheroid){
                sum
              }
            }
          }
        }
      }
    }
  }
}
```

```graphql
query getPOIsByDistrictBayern {
  osm {
    bayern{
      osm_amenities_bucket_aggregation @stats {
        key {
          _spatial(field: "geom", type: INTERSECTS) {
            landkreis: osm_bw_osm_administrative_boundaries(
              field: "geom"
              filter: {admin_level: {eq: 6}}
            ) @unnest {
              name
            }
          }
          category
          amenity_type
        }
        aggregations {
          _rows_count
        }
      }
    }
  }
}
```

## Conclusion

This example demonstrated how to set up a DuckDB database with OpenStreetMap data, create a GraphQL schema to query this data, and use object storage for storing the DuckDB database file. You can adapt the setup to any other region by changing the `--region` parameter in the `setup.sh` script.

You can also extend the GraphQL schema to include more data sources or additional queries as needed. The `hugr` server provides a powerful way to work with geospatial data and integrate it into your applications.

## Additional Resources

- [OpenStreetMap](https://www.openstreetmap.org/)
- [DuckDB](https://duckdb.org/)
- [GraphQL](https://graphql.org/)
- [osm_dbt](https://github.com/yourusername/osm_dbt)
- [Hugr Documentation](https://hugr-lab.github.io/docs/)
