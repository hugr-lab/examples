# HR CRM Example

This example sets up an HR CRM (Human Resources Customer Relationship Management) database on MySQL and creates a GraphQL SDL schema for it.

The HR CRM database contains data about a fictional company's recruitment and hiring process. It includes tables for candidates, job positions, applications, interviews, pipeline stages, skills, and more. This system helps HR teams manage the entire recruitment lifecycle from job posting to hiring decisions.

The example uses the `hugr` library to generate a GraphQL schema from the HR CRM database schema. The generated schema can be used to query and manipulate recruitment data using GraphQL.

## Database Schema Overview

The HR CRM system includes the following main entities:

- **Candidates**: Job applicants with their skills and experience
- **Positions**: Open job positions in different departments
- **Applications**: Candidate applications for specific positions
- **Interviews**: Scheduled interviews with feedback and ratings
- **Pipeline Stages**: Recruitment process stages (screening, interviews, offers, etc.)
- **Skills**: Technical and soft skills with proficiency levels
- **Departments**: Company departments with their managers and budgets

## Getting Started

To run this example, you need to start the entire examples infrastructure. Then you can run the HR CRM example:

## 1. Set up the MySQL database with HR CRM schema

```bash
cd examples/hr-crm
sh setup.sh
```

This will:

- Create the `hr_crm` database
- Set up all tables with proper relationships
- Insert sample data (candidates, positions, applications, interviews, etc.)
- Grant necessary permissions to the `hugr` user

## 2. Set up the hugr data source

The example schema definition is located in `examples/hr-crm/schema`. You need to set up the data source in `hugr`.

Open browser and go to `http://localhost:18000/admin` (port can be changed through .env). You will see the hugr admin UI (GraphiQL).
Create a new data source with the following mutation:

```graphql
mutation addHRCRMDataSet($data: data_sources_mut_input_data! = {}) {
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
    "name": "hr_crm",
    "type": "mysql",
    "prefix": "hr",
    "description": "HR CRM recruitment management system",
    "read_only": false,
    "as_module": true,
    "path": "mysql://hugr:hugr_password@mysql:3306/hr_crm",
    "catalogs": [
      {
        "name": "hr_crm",
        "type": "uri",
        "description": "HR CRM database schema",
        "path": "/workspace/examples/hr-crm/schema"
      }
    ]
  }
}
```

This mutation will create a new data source with the name `hr_crm` and the path to the HR CRM database schema. The `catalogs` field is used to specify the schema definition for the data source.

## 3. Load the data source

After creating the data source, you need to load it manually - it will load automatically on startup. You can do this by running the following mutation:

```graphql
mutation {
  function {
    core {
      load_data_source(name: "hr_crm") {
        success
        message
      }
    }
  }
}
```

## 4. Query the HR CRM data

You can use the following queries to explore the recruitment data:

### 4.1. Get all candidates with their applications and current status

```graphql
{
  hr_crm {
    candidates {
      id
      first_name
      last_name
      email
      current_position
      current_company
      years_of_experience
      applications {
        id
        status
        applied_at
        position {
          title
          department {
            name
          }
        }
        currentStage {
          name
          stage_type
        }
      }
    }
  }
}
```

### 4.2. Get active positions with application statistics

```graphql
{
  hr_crm {
    active_positions_view {
      id
      title
      department_name
      salary_min
      salary_max
      employment_type
      is_remote
      active_applications_count
      department {
        manager_email
        budget
      }
    }
  }
}
```

### 4.3. Get application pipeline with candidate and position details

```graphql
{
  hr_crm {
    application_pipeline_view {
      id
      first_name
      last_name
      candidate_email
      position_title
      department_name
      status
      current_stage_name
      current_stage_type
      pipeline_name
      completed_interviews_count
      applied_at
      last_activity_at
    }
  }
}
```

### 4.4. Get candidates by skills and experience level

```graphql
{
  hr_crm {
    candidates(
      filter: {
        matched_skills: {
          any_of: {
            skill: {name: {in: ["JavaScript", "React", "Node.js"]}}
            proficiency_level: {in: ["advanced", "expert"]}
            experience_years: {gte: 3}
          }
        }
      }
    ) {
      id
      first_name
      last_name
      email
      years_of_experience
      matched_skills {
        skill {
          name
          category
        }
        experience_years
        proficiency_level
        verified
      }
    }
  }
}
```

### 4.5. Get interview statistics by department and stage

```graphql
{
  hr_crm {
    interviews_bucket_aggregation(
      order_by: [
        { field: "aggregations._rows_count", direction: DESC }
      ]
    ) {
      key {
        application {
          position {
            department {
              name
            }
          }
        }
        stage {
          name
          stage_type
        }
        status
      }
      aggregations {
        _rows_count
        rating {
          avg
          min
          max
        }
      }
    }
  }
}
```

### 4.6. Get hiring funnel by position

```graphql
{
  hr_crm {
    applications_bucket_aggregation(
      order_by: [
        { field: "key.position.title", direction: ASC }
        { field: "key.status", direction: ASC }
      ]
    ) {
      key {
        position {
          title
          department {
            name
          }
        }
        status
      }
      aggregations {
        _rows_count
      }
    }
  }
}
```

### 4.7. Get top performing candidates by interview scores

```graphql
{
  hr_crm {
    application_scores(
      filter: {score: {gte: 8}, score_type: {eq: "overall"}}
      order_by: [{field: "score", direction: DESC}]
    ) {
      evaluator_email
      score
      comments
      application {
        position {
          title
        }
        status
        candidate {
          first_name
          last_name
          email
          current_position
        }
      }
    }
  }
}
```

### 4.8. Get recruitment metrics by time period

```graphql
{
  hr_crm {
    applications_bucket_aggregation(
      filter: {
        applied_at: {
          gte: "2024-01-01T00:00:00Z"
          lte: "2024-12-31T00:00:00Z"
        }
      }
      order_by: [{field: "key.month", direction: DESC}]
    ) {
      key {
        month: _applied_at_part(extract: month)
        year: _applied_at_part(extract: year)
      }
      aggregations{
        _rows_count
      }
      applied: aggregations(filter: {status: {eq: "applied"}}) {
        count:_rows_count
      }
      rejected: aggregations(filter: {status: {eq: "rejected"}}){
        count: _rows_count
      }
    }
  }
}
```

### 4.9. Get positions requiring specific skills

```graphql
{
  hr_crm {
    positions(
      filter: {
        requiredSkills: {
          any_of: {
            skill: {
              name: { in: ["Python", "Machine Learning"] }
            }
            importance: { eq: "required" }
          }
        }
        status: { eq: "published" }
      }
    ) {
      id
      title
      department {
        name
      }
      salary_min
      salary_max
      requiredSkills(
        filter: {
          importance: {eq: "required"}
        }
        inner: true
      ) {
        skill {
          name
          category
        }
        importance
        experience_years_min
      }
    }
  }
}
```

### 4.10. Get interview feedback and recommendations

```graphql
{
  hr_crm {
    interviews(
      filter: {
        status: { eq: "completed" }
        rating: { gte: 7 }
      }
      order_by: [
        { field: "rating", direction: DESC }
      ]
    ) {
      id
      application {
        candidate {
          first_name
          last_name
        }
        position {
          title
        }
      }
      interviewType {
        name
        is_technical
      }
      interviewer_name
      rating
      recommendation
      feedback
      completed_at
    }
  }
}
```

## Mutations

Currently, the hugr doesn't support auto_increment fields in MySQL mutations, so you can only use queries to retrieve data. However, you can still perform mutations to update existing records or insert new ones without auto-increment fields.

## Key Features Demonstrated

1. **Complex Relationships**: Many-to-many relationships between positions and skills, candidates and skills
2. **Aggregations**: Statistics on applications, interviews, and hiring metrics
3. **Filtering**: Advanced filtering by skills, experience, dates, and scores
4. **Views**: Pre-built analytical views for common queries
5. **Time-based Analysis**: Recruitment funnel and performance over time
6. **Scoring System**: Interview ratings and feedback tracking
7. **Pipeline Management**: Tracking candidates through recruitment stages

This example showcases how `hugr` can handle complex HR and recruitment workflows with rich querying capabilities.
