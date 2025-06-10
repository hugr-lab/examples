# OpenWeatherMap REST API Example

In this example, we will set up a hugr data source that connects to the OpenWeatherMap REST API. This will make accessible weather data in the unified GraphQL API.

## Prerequisites

- You need to have a valid OpenWeatherMap API key. You can sign up for a free account at [OpenWeatherMap](https://openweathermap.org/api).
- Set up the hugr environment as described in the main [README](https://github.com/hugr-lab/examples/blob/main/README.md).

## Getting Started

We will work with following APIs:

- [OpenWeatherMap Current Weather API](https://openweathermap.org/current) to fetch current weather data
- [OpenWeatherMap Forecast API](https://openweathermap.org/forecast) to fetch weather forecasts

The api call will perform http GET request to the following endpoint: `https://api.openweathermap.org/data/2.5/current?lat={lat}&lon={lon}&appid={API_KEY}`

Where `{lat}` and `{lon}` are the latitude and longitude of the location you want to get weather data for, and `{API_KEY}` is your OpenWeatherMap API key.

The API parameters are as follows:

- `lat`: Latitude of the location (required)
- `lon`: Longitude of the location (required)
- `appid`: Your OpenWeatherMap API key (required)
- `units`: Units of measurement (optional, e.g., "metric", "imperial", "standard")
- `lang`: Language of the response (optional, e.g., "en", "fr", "de")

## 1. Set up the hugr data source

Open your browser and go to `http://localhost:18000/admin` (port can be changed through .env). You will see the hugr admin UI (GraphiQL).
Create a new data source with the following mutation:

```graphql
mutation addOpenWeatherMapDataSet($data: data_sources_mut_input_data! = {}) {
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
    }
  }
}
```

You can use the following variables:

```json
{
  "data": {
    "name": "owm",
    "type": "http",
    "prefix": "owm",
    "description": "OpenWeatherMap REST API data source",
    "self_defined": false,
    "disabled": false,
    "read_only": true,
    "as_module": true,
    "path": "https://api.openweathermap.org?x-hugr-security=\"{\"schema_name\":\"owm\",\"type\":\"apiKey\",\"in\":\"query\",\"api_key\":\"YOUR_API_KEY\",\"name\":\"appid\"}\"",
  }
}
```

And load it:

```graphql
{
  function{
    core{
      load_data_source(name: "owm") {
        success
        message
      }
    }
  }
}
```

Replace `YOUR_API_KEY` with your actual OpenWeatherMap API key.
This mutation will create a new data source with the name `owm` and the path to the OpenWeatherMap API. The `prefix` field is used to define the prefix for the GraphQL schema.

## 2. Try to call the API

You can now try to call the APIs using the hugr core function `http_data_source_request_scalar` in the GraphiQL interface. Here are some example queries:

```graphql
query getCurrentWeather($lat: Float!, $lon: Float!) {
  function{
    core{
      http_data_source_request_scalar(
        source: "owm"
        path: "/data/2.5/weather"
        method: "GET"
        headers: {},
        parameters: {
          lat: 35.6895
          lon: 139.6917
        },
        body: {},
        jq: ""
      )
    }
  }
}
```

The response will contain the current weather data for the specified latitude and longitude.

```json
{
  "data": {
    "function": {
      "core": {
        "http_data_source_request_scalar": "{\"base\":\"stations\",\"clouds\":{\"all\":75},\"cod\":200,\"coord\":{\"lat\":35.6895,\"lon\":139.6917},\"dt\":1749483960,\"id\":1850144,\"main\":{\"feels_like\":293.88,\"grnd_level\":1010,\"humidity\":85,\"pressure\":1012,\"sea_level\":1012,\"temp\":293.56,\"temp_max\":294.06,\"temp_min\":292.18},\"name\":\"Tokyo\",\"sys\":{\"country\":\"JP\",\"id\":268395,\"sunrise\":1749497104,\"sunset\":1749549384,\"type\":2},\"timezone\":32400,\"visibility\":10000,\"weather\":[{\"description\":\"broken clouds\",\"icon\":\"04n\",\"id\":803,\"main\":\"Clouds\"}],\"wind\":{\"deg\":0,\"speed\":0.51}}"
      }
    }
  }
}
```

The hugr function `http_data_source_request_scalar` allows you to make HTTP requests to the data source. You can specify the HTTP method, headers, parameters, and body of the request. The `jq` parameter is used to transform the response using [jq](https://stedolan.github.io/jq/). This function you can use in SQL function definition.

## 3. Define Function

To make the API accessible to call through GraphQL API more clear we can add catalog source for the data source.

### Make the schema definition file

Create new one or use exists schema.graphql file with following content:

```graphql
extend type Function {
    "Current weather from OpenWeatherMap in raw format"
    current_weather_raw(
        lat: Float!
        lon: Float!
    ): JSON @function(
        name: "get_current_weather", 
        sql: "http_data_source_request_scalar([$catalog], '/data/2.5/weather', 'GET', '{}'::JSON, {lat: [lat], lon: [lon]}::JSON, '{}'::JSON, '')", json_cast: true)
}
```

### Create the new catalog source and add it to the data source

Run following mutation:

```graphql
mutation addOWMCatalog{
  core{
    insert_catalog_sources(
      data: {
        name: "owm-funcs"
        type: "uriFile"
        description: "OpenWeatherMap function definition"
        path: "/workspace/examples/openweathermap/schema.graphql"
      }
    ){
      name
      type
      path
    }
    insert_catalogs(
      data: {
        data_source_name: "owm"
        catalog_name: "owm-funcs"
      }
    ){
      success
      message
      affected_rows
    }
  }
}
```

And reload it:

```graphql
{
  function{
    core{
      load_data_source(name: "owm") {
        success
        message
      }
    }
  }
}
```

Now, you can find the function in the schema:

```graphql
query schemaCall{
  function{
    owm{
      current_weather_raw(
        lat: 35.6895
        lon: 139.6917
      )
    }
  }
}
```

It returns the response in normal json:

```json
{
  "data": {
    "function": {
      "owm": {
        "current_weather_raw": {
          "base": "stations",
          "clouds": {
            "all": 75
          },
          "cod": 200,
          "coord": {
            "lat": 35.6895,
            "lon": 139.6917
          },
          "dt": 1749496542,
          "id": 1850144,
          "main": {
            "feels_like": 20.35,
            "grnd_level": 1009,
            "humidity": 88,
            "pressure": 1011,
            "sea_level": 1011,
            "temp": 20,
            "temp_max": 20.36,
            "temp_min": 18.77
          },
          "name": "Tokyo",
          "rain": {
            "1h": 4.34
          },
          "sys": {
            "country": "JP",
            "id": 268395,
            "sunrise": 1749497104,
            "sunset": 1749549384,
            "type": 2
          },
          "timezone": 32400,
          "visibility": 8000,
          "weather": [
            {
              "description": "heavy intensity rain",
              "icon": "10n",
              "id": 502,
              "main": "Rain"
            }
          ],
          "wind": {
            "deg": 110,
            "speed": 2.57
          }
        }
      }
    }
  }
}
```

### Define type for response

In common cases the API response better to have in structured format, for it we can define the new function and GraphQL type for response. Modify it by the following content to the schema definition file:

```graphql

extend type Function {
  "Current weather from OpenWeatherMap in raw format"
  current_weather_raw(lat: Float!, lon: Float!): JSON
    @function(
      name: "get_current_weather_raw"
      sql: "http_data_source_request_scalar([$catalog], '/data/2.5/weather', 'GET', '{}'::JSON, {lat: [lat], lon: [lon], units: 'metric'}::JSON, '{}'::JSON, '')"
      json_cast: true
    )

  "Current weather from OpenWeatherMap in raw format"
  current_weather(lat: Float!, lon: Float!): current_weather_response
    @function(
      name: "get_current_weather"
      sql: "http_data_source_request_scalar([$catalog], '/data/2.5/weather', 'GET', '{}'::JSON, {lat: [lat], lon: [lon], units: 'metric'}::JSON, '{}'::JSON, '')"
      json_cast: true
    )
}

type current_weather_response {
  cod: Int
  base: String
  coord: coords
  dt: BigInt
  main: main_weather_info
  weather: [weather_conditions]
  clouds: clouds_info
  rain: perc_info
  snow: perc_info
  visibility: Int
  wind: wind_info
  common: sys_info @field_source(field: "sys")
}

type coords {
  lat: Float
  lon: Float
}

type clouds_info {
  all: Float
}

type perc_info {
  current: Float @field_source(field: "1h")
}

type wind_info {
  speed: Float
  deg: Float
  gust: Float
}

type main_weather_info {
  feels_like: Float
  grnd_level: Float
  humidity: Float
  pressure: Float
  sea_level: Float
  temp: Float
  temp_max: Float
  temp_min: Float
}

type weather_conditions {
  id: Int
  name: String @field_source(field: "main")
  icon: String
  description: String
}

type sys_info {
  sunrise: BigInt
  sunset: BigInt
  country: String
}
```

### Call the new function

```graphql
query call{
  function{
    owm{
      current_weather(
        lat: 35.6895
        lon: 139.6917
      ) {
        visibility
        main{
          temp
          temp_max
          temp_min
        }
        rain{
          current
        }
        common{
          sunset
          sunrise
        }
      }
    }
  }
}
```

Response:

```json
{
  "data": {
    "function": {
      "owm": {
        "current_weather": {
          "visibility": 8000,
          "main": {
            "temp": 20,
            "temp_max": 20.360000610351562,
            "temp_min": 18.770000457763672
          },
          "rain": {
            "current": 4.340000152587891
          },
          "common": {
            "sunset": 1749549384,
            "sunrise": 1749497104
          }
        }
      }
    }
  }
}
```

As you can see we define GraphQL type for the API response and the `hugr` transforms response to the defined type. You can see that we excluded and renamed some response fields.

## 4 Using open api specification

To simplify the process of defining the API and its response, you can use the OpenAPI specification. This allows you to define the API in a structured way, and `hugr` will automatically generate the GraphQL schema types and functions based on this specification.
To use the OpenAPI specification, you need to create a specification file that describes the OpenWeatherMap API and create a data source with parameter that points to the OpenAPI specification file. Follow the steps below to set it up.

### Create the OpenAPI specification file

You can use existing one `spec.yaml` or create new specification file.

```yaml
openapi: 3.1.0
info:
  title: OpenWeatherMap
  version: 0.0.1
servers:
  - url: https://api.openweathermap.org
    description: OpenWeatherMap
components:
  securitySchemes:
    owm:
      type: apiKey
      description: API key authentication
      in: query
      name: appid
  schemas:
    current_weather:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        base:
          type: string
        coord:
          type: object
          properties:
            lat:
              type: number
            lon:
              type: number
        dt:
          type: integer
          x-hugr-type:
            type: Timestamp
            transform: "FromUnixTime"
        weather:
          type: array
          items:
            type: object
            properties:
              id:
                type: integer
              icon:
                type: string
              description:
                type: string
              main:
                type: string
        clouds:
          type: object
          properties:
            all:
              type: integer
        rain:
          $ref: "#/components/schemas/perc_info"
        snow:
          $ref: "#/components/schemas/perc_info"
        visibility:
          type: integer
        wind:
          type: object
          properties:
            speed:
              type: number
            deg:
              type: number
            gust:
              type: number
        main:
          type: object
          properties:
            temp:
              type: number
            feels_like:
              type: number
            temp_min:
              type: number
            temp_max:
              type: number
            humidity:
              type: number
            pressure:
              type: number
            grnd_level:
              type: number
            sea_level:
              type: number
        sys:
          type: object
          x-hugr-name: "common"
          properties:
            country:
              type: string
            sunrise:
              type: integer
              x-hugr-type:
                type: Timestamp
                transform: "FromUnixTime"
            sunset:
              type: integer
              x-hugr-type:
                type: Timestamp
                transform: "FromUnixTime"
    perc_info:
      type: object
      properties:
        1h:
          type: number
          x-hugr-name: current
paths:
  /data/2.5/weather:
    get:
      description: Current weather from OpenWeatherMap
      operationId: current
      parameters:
        - name: lat
          description: Latitude of the location
          in: query
          required: true
          schema:
            type: number
        - name: lon
          description: Longitude of the location
          in: query
          required: true
          schema:
            type: number
      responses:
        200:
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/current_weather"
```

As you can see, the specification file describes the OpenWeatherMap API and defines the `current_weather` schema. The `hugr` will use this file to generate the GraphQL schema and functions. There are a couple of `hugr` specific extensions in the specification file:

- `x-hugr-type`: This is used to define the `hugr` GraphQL scalar types and transformations to them.
- `x-hugr-name`: This allows you to specify a custom name for the field in the GraphQL schema.

### Create the new data source

Run the following mutation to create a new data source with the OpenAPI specification file:

```graphql
mutation addOWMWithSpec {
  core {
    insert_data_sources(
      data: {
        name: "owm_spec"
        type: "http"
        prefix: "owm_spec"
        description: "OpenWeatherMap REST API data source with specification"
        self_defined: true
        disabled: false
        read_only: true
        as_module: true
        path: "https://api.openweathermap.org?x-hugr-spec-path=\"/workspace/examples/openweathermap/spec.yaml\"&x-hugr-security=\"{\"schema_name\":\"owm\",\"api_key\":\"YOUR_API_KEY\"}\""}
    ) {
      name
      path
      type
      prefix
      disabled
      description
      as_module
      read_only
    }
  }
}
```

Replace `YOUR_API_KEY` with your actual OpenWeatherMap API key.
And load the new data source:

```graphql
{
  function {
    core {
      load_data_source(name: "owm_spec") {
        success
        message
      }
    }
  }
}
```

Now, you can find the function in the schema:

```graphql
query schemaCall {
  function {
    owm_spec {
      current_weather(lat: 35.6895, lon: 139.6917) {
        visibility
        main {
          temp
          temp_max
          temp_min
        }
        rain {
          current
        }
        common {
          sunset
          sunrise
        }
      }
    }
  }
}
```

The response will looks like this:

```json
{
  "data": {
    "function": {
      "owm_spec": {
        "current": {
          "main": {
            "temp": 294.07000732421875,
            "humidity": 90
          },
          "rain": {
            "current": 1.2599999904632568
          },
          "weather": [
            {
              "id": 501,
              "icon": "10d",
              "main": "Rain",
              "description": "moderate rain"
            }
          ],
          "common": {
            "sunset": "2025-06-10 09:56:24+00",
            "sunrise": "2025-06-09 19:25:04+00"
          }
        }
      }
    }
  }
}
```

You can see that the `hugr` automatically generated the GraphQL schema and functions based on the OpenAPI specification file. The response is structured according to the defined schema and transformed fields to the `hugr` types (Timestamp).

## Conclusion

In this example, we demonstrated how to integrate the OpenWeatherMap API with the `hugr` platform using an OpenAPI specification file. We created a new data source, loaded it, and queried the current weather data for a specific location. The `hugr` framework automatically generated the necessary GraphQL schema and functions based on the provided OpenAPI specification, allowing for seamless interaction with the API.

This allows you to run API calls through the unified GraphQL API and use to extend exits tables and views function call fields. You can also use the `hugr` to create more complex queries and mutations based on the OpenWeatherMap API data.
