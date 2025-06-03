
# HR CRM Mutations Examples

This document demonstrates various mutation operations for the HR CRM system, including creating, updating, and deleting records across different entities.

## 1. Creating New Records

### 1.1. Add a New Candidate

```graphql
mutation addCandidate($data: candidates_mut_input_data!) {
  hr_crm {
    insert_candidates(data: $data) {
      id
      first_name
      last_name
      email
      current_position
      years_of_experience
      created_at
    }
  }
}
```

**Variables:**

```json
{
  "data": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1-555-0199",
    "linkedin_url": "https://linkedin.com/in/johndoe",
    "github_url": "https://github.com/johndoe",
    "current_position": "Senior Developer",
    "current_company": "TechStart Inc",
    "current_salary": 95000,
    "expected_salary": 120000,
    "location": "New York, NY",
    "is_open_to_remote": true,
    "years_of_experience": 5,
    "source": "linkedin"
  }
}
```

### 1.2. Create a New Job Position

```graphql
mutation addPosition($data: positions_mut_input_data!) {
  hr_crm {
    insert_positions(data: $data) {
      id
      title
      department {
        name
      }
      salary_min
      salary_max
      status
      created_at
    }
  }
}
```

**Variables:**
```json
{
  "data": {
    "title": "React Frontend Developer",
    "department_id": 1,
    "description": "We are looking for an experienced React developer to join our frontend team.",
    "requirements": "3+ years experience with React, TypeScript, and modern frontend tools.",
    "salary_min": 80000,
    "salary_max": 120000,
    "employment_type": "full_time",
    "location": "San Francisco, CA",
    "is_remote": true,
    "experience_years_min": 3,
    "experience_years_max": 8,
    "status": "published"
  }
}
```

### 1.3. Submit a Job Application

```graphql
mutation submitApplication($data: applications_mut_input_data!) {
  hr_crm {
    insert_applications(data: $data) {
      id
      candidate {
        first_name
        last_name
        email
      }
      position {
        title
        department {
          name
        }
      }
      status
      applied_at
    }
  }
}
```

**Variables:**
```json
{
  "data": {
    "candidate_id": 16,
    "position_id": 1,
    "job_board_id": 1,
    "pipeline_template_id": 1,
    "status": "applied"
  }
}
```

### 1.4. Schedule an Interview

```graphql
mutation scheduleInterview($data: interviews_mut_input_data!) {
  hr_crm {
    insert_interviews(data: $data) {
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
      }
      interviewer_name
      scheduled_at
      status
    }
  }
}
```

**Variables:**
```json
{
  "data": {
    "application_id": 16,
    "stage_id": 2,
    "interview_type_id": 1,
    "interviewer_email": "sarah.tech@company.com",
    "interviewer_name": "Sarah Tech Lead",
    "scheduled_at": "2024-03-15T14:00:00Z",
    "duration_minutes": 60,
    "meeting_url": "https://zoom.us/j/123456789",
    "status": "scheduled"
  }
}
```

### 1.5. Add Skills to a Candidate (Many-to-Many)

```graphql
mutation addCandidateSkills($data: [candidate_skills_mut_input_data!]!) {
  hr_crm {
    insert_candidate_skills(data: $data) {
      candidate {
        first_name
        last_name
      }
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
```

**Variables:**
```json
{
  "data": [
    {
      "candidate_id": 16,
      "skill_id": 1,
      "experience_years": 5,
      "proficiency_level": "expert",
      "verified": true
    },
    {
      "candidate_id": 16,
      "skill_id": 11,
      "experience_years": 4,
      "proficiency_level": "advanced",
      "verified": true
    },
    {
      "candidate_id": 16,
      "skill_id": 2,
      "experience_years": 3,
      "proficiency_level": "intermediate",
      "verified": false
    }
  ]
}
```

## 2. Updating Existing Records

### 2.1. Update Application Status

```graphql
mutation updateApplicationStatus($filter: applications_filter!, $data: applications_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      candidate {
        first_name
        last_name
      }
      position {
        title
      }
      last_activity_at
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 16 }
  },
  "data": {
    "status": "screening",
    "current_stage_id": 2
  }
}
```

### 2.2. Complete Interview with Feedback

```graphql
mutation completeInterview($filter: interviews_filter!, $data: interviews_mut_input_data!) {
  hr_crm {
    update_interviews(filter: $filter, data: $data) {
      id
      status
      rating
      recommendation
      feedback
      completed_at
      application {
        candidate {
          first_name
          last_name
        }
      }
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 13 }
  },
  "data": {
    "status": "completed",
    "rating": 8,
    "recommendation": "hire",
    "feedback": "Strong technical skills and good communication. Candidate showed excellent problem-solving abilities during the coding session.",
    "completed_at": "2024-03-15T15:30:00Z"
  }
}
```

### 2.3. Update Candidate Information

```graphql
mutation updateCandidate($filter: candidates_filter!, $data: candidates_mut_input_data!) {
  hr_crm {
    update_candidates(filter: $filter, data: $data) {
      id
      first_name
      last_name
      current_position
      current_company
      expected_salary
      updated_at
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "email": { "eq": "john.doe@example.com" }
  },
  "data": {
    "current_position": "Lead Frontend Developer",
    "current_company": "TechStart Inc",
    "current_salary": 105000,
    "expected_salary": 130000
  }
}
```

### 2.4. Add Interview Score

```graphql
mutation addInterviewScore($data: application_scores_mut_input_data!) {
  hr_crm {
    insert_application_scores(data: $data) {
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
      score_type
      score
      evaluator_email
      comments
      evaluated_at
    }
  }
}
```

**Variables:**
```json
{
  "data": {
    "application_id": 16,
    "stage_id": 2,
    "score_type": "technical",
    "score": 8.5,
    "max_score": 10.0,
    "evaluator_email": "sarah.tech@company.com",
    "comments": "Excellent coding skills and system design thinking"
  }
}
```

### 2.5. Move Application to Next Stage

```graphql
mutation moveApplicationToNextStage($filter: applications_filter!, $data: applications_mut_input_data!, $historyData: application_stage_history_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      currentStage {
        name
        stage_type
      }
    }
    insert_application_stage_history(data: $historyData) {
      id
      stage {
        name
      }
      status
      entered_at
      notes
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 16 }
  },
  "data": {
    "status": "in_progress",
    "current_stage_id": 3
  },
  "historyData": {
    "application_id": 16,
    "stage_id": 3,
    "status": "entered",
    "notes": "Moved to technical interview stage after successful phone screening",
    "moved_by_email": "recruiter@company.com"
  }
}
```

## 3. Deleting Records

### 3.1. Remove Candidate Skill

```graphql
mutation removeCandidateSkill($filter: candidate_skills_filter!) {
  hr_crm {
    delete_candidate_skills(filter: $filter) {
      candidate {
        first_name
        last_name
      }
      skill {
        name
      }
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "candidate_id": { "eq": 16 },
    "skill_id": { "eq": 2 }
  }
}
```

### 3.2. Cancel Interview

```graphql
mutation cancelInterview($filter: interviews_filter!, $data: interviews_mut_input_data!) {
  hr_crm {
    update_interviews(filter: $filter, data: $data) {
      id
      status
      application {
        candidate {
          first_name
          last_name
        }
      }
      interviewer_name
      scheduled_at
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 13 }
  },
  "data": {
    "status": "cancelled"
  }
}
```

### 3.3. Close Job Position

```graphql
mutation closePosition($filter: positions_filter!, $data: positions_mut_input_data!) {
  hr_crm {
    update_positions(filter: $filter, data: $data) {
      id
      title
      status
      closed_at
      department {
        name
      }
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 11 }
  },
  "data": {
    "status": "closed",
    "closed_at": "2024-03-15T12:00:00Z"
  }
}
```

### 3.4. Withdraw Application

```graphql
mutation withdrawApplication($filter: applications_filter!, $data: applications_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      candidate {
        first_name
        last_name
      }
      position {
        title
      }
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "candidate_id": { "eq": 16 },
    "position_id": { "eq": 1 }
  },
  "data": {
    "status": "withdrawn"
  }
}
```

## 4. Batch Operations

### 4.1. Bulk Update Application Status

```graphql
mutation bulkUpdateApplications($filter: applications_filter!, $data: applications_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      candidate {
        first_name
        last_name
      }
      position {
        title
      }
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "position_id": { "eq": 1 },
    "status": { "eq": "applied" }
  },
  "data": {
    "status": "screening"
  }
}
```

### 4.2. Add Multiple Notes to Application

```graphql
mutation addApplicationNotes($data: [application_notes_mut_input_data!]!) {
  hr_crm {
    insert_application_notes(data: $data) {
      id
      application {
        candidate {
          first_name
          last_name
        }
      }
      author_name
      note
      is_internal
      created_at
    }
  }
}
```

**Variables:**
```json
{
  "data": [
    {
      "application_id": 16,
      "author_email": "recruiter@company.com",
      "author_name": "Anna Recruiter",
      "note": "Candidate has strong React experience and is available for immediate start.",
      "is_internal": true
    },
    {
      "application_id": 16,
      "author_email": "hiring.manager@company.com",
      "author_name": "Tom Manager",
      "note": "Salary expectations are within budget range.",
      "is_internal": true
    }
  ]
}
```

## 5. Complex Workflow Operations

### 5.1. Complete Recruitment Process (Hire Candidate)

```graphql
mutation hireCandidate($filter: applications_filter!, $data: applications_mut_input_data!, $historyData: application_stage_history_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      hired_at
      candidate {
        first_name
        last_name
        email
      }
      position {
        title
        department {
          name
        }
      }
    }
    insert_application_stage_history(data: $historyData) {
      status
      entered_at
      notes
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 16 }
  },
  "data": {
    "status": "hired",
    "hired_at": "2024-03-20T10:00:00Z"
  },
  "historyData": {
    "application_id": 16,
    "stage_id": 7,
    "status": "completed",
    "notes": "Offer accepted. Start date: April 1st, 2024",
    "moved_by_email": "hr@company.com"
  }
}
```

### 5.2. Reject Application with Reason

```graphql
mutation rejectApplication($filter: applications_filter!, $data: applications_mut_input_data!, $noteData: application_notes_mut_input_data!) {
  hr_crm {
    update_applications(filter: $filter, data: $data) {
      id
      status
      rejected_at
      rejection_reason
      candidate {
        first_name
        last_name
      }
    }
    insert_application_notes(data: $noteData) {
      note
      is_internal
      created_at
    }
  }
}
```

**Variables:**
```json
{
  "filter": {
    "id": { "eq": 17 }
  },
  "data": {
    "status": "rejected",
    "rejected_at": "2024-03-18T14:30:00Z",
    "rejection_reason": "Skills not matching requirements"
  },
  "noteData": {
    "application_id": 17,
    "author_email": "tech.lead@company.com",
    "author_name": "Sarah Tech Lead",
    "note": "Candidate lacks experience in required technologies. Consider for junior positions in the future.",
    "is_internal": true
  }
}
```

## Best Practices

1. **Always include relevant fields in response** to verify the mutation was successful
2. **Use filters carefully** to avoid updating/deleting wrong records
3. **Include timestamps** when updating status changes
4. **Add notes/comments** for audit trail purposes
5. **Handle many-to-many relationships** separately when needed
6. **Use batch operations** for efficiency when updating multiple records
7. **Maintain data consistency** by updating related records in the same mutation when possible

## Error Handling

When mutations fail, check for:
- **Foreign key constraints**: Ensure referenced IDs exist
- **Required fields**: All non-nullable fields must be provided
- **Data validation**: Check field formats and constraints
- **Permissions**: Verify user has access to modify the data
- **Unique constraints**: Email addresses, application uniqueness, etc.