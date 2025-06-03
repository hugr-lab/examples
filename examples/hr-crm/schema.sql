-- HR CRM Database Schema for MySQL
-- Recruitment and candidate management system

-- Use UTF8MB4 for full Unicode support
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS hr_crm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hr_crm;

-- Job boards and platforms where vacancies are posted
CREATE TABLE job_boards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    website_url VARCHAR(255),
    api_endpoint VARCHAR(255),
    cost_per_posting DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_job_boards_active (is_active),
    INDEX idx_job_boards_name (name)
);

-- Departments in the company
CREATE TABLE departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    manager_email VARCHAR(255),
    budget DECIMAL(12,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_departments_name (name),
    INDEX idx_departments_active (is_active)
);

-- Job positions/vacancies
CREATE TABLE positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    department_id INT NOT NULL,
    description TEXT,
    requirements TEXT,
    salary_min DECIMAL(10,2),
    salary_max DECIMAL(10,2),
    employment_type VARCHAR(20) DEFAULT 'full_time',
    location VARCHAR(100),
    is_remote BOOLEAN DEFAULT FALSE,
    experience_years_min INT DEFAULT 0,
    experience_years_max INT,
    status VARCHAR(20) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    
    FOREIGN KEY (department_id) REFERENCES departments(id),
    INDEX idx_positions_status (status),
    INDEX idx_positions_department (department_id),
    INDEX idx_positions_employment_type (employment_type),
    INDEX idx_positions_remote (is_remote)
);

-- Recruitment pipeline templates
CREATE TABLE pipeline_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_pipeline_templates_name (name),
    INDEX idx_pipeline_templates_default (is_default),
    INDEX idx_pipeline_templates_active (is_active)
);

-- Stages in recruitment pipeline
CREATE TABLE pipeline_stages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    stage_order INT NOT NULL,
    stage_type VARCHAR(20) DEFAULT 'interview',
    is_required BOOLEAN DEFAULT TRUE,
    auto_advance BOOLEAN DEFAULT FALSE,
    duration_days INT DEFAULT 7,
    
    FOREIGN KEY (template_id) REFERENCES pipeline_templates(id) ON DELETE CASCADE,
    UNIQUE KEY uk_pipeline_stages_template_order (template_id, stage_order),
    INDEX idx_pipeline_stages_type (stage_type),
    INDEX idx_pipeline_stages_order (template_id, stage_order)
);

-- Candidates/job applicants
CREATE TABLE candidates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    linkedin_url VARCHAR(255),
    github_url VARCHAR(255),
    portfolio_url VARCHAR(255),
    current_position VARCHAR(200),
    current_company VARCHAR(200),
    current_salary DECIMAL(10,2),
    expected_salary DECIMAL(10,2),
    location VARCHAR(100),
    is_open_to_remote BOOLEAN DEFAULT FALSE,
    years_of_experience INT DEFAULT 0,
    resume_file_path VARCHAR(500),
    cover_letter TEXT,
    skills JSON,
    source VARCHAR(20) DEFAULT 'job_board',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_candidates_email (email),
    INDEX idx_candidates_name (first_name, last_name),
    INDEX idx_candidates_location (location),
    INDEX idx_candidates_experience (years_of_experience),
    INDEX idx_candidates_source (source),
    INDEX idx_candidates_remote (is_open_to_remote)
);

-- Job applications
CREATE TABLE applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    candidate_id INT NOT NULL,
    position_id INT NOT NULL,
    job_board_id INT,
    pipeline_template_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'applied',
    current_stage_id INT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    hired_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    rejection_reason TEXT,
    notes TEXT,
    
    FOREIGN KEY (candidate_id) REFERENCES candidates(id),
    FOREIGN KEY (position_id) REFERENCES positions(id),
    FOREIGN KEY (job_board_id) REFERENCES job_boards(id),
    FOREIGN KEY (pipeline_template_id) REFERENCES pipeline_templates(id),
    FOREIGN KEY (current_stage_id) REFERENCES pipeline_stages(id),
    
    UNIQUE KEY uk_applications_candidate_position (candidate_id, position_id),
    INDEX idx_applications_status (status),
    INDEX idx_applications_position (position_id),
    INDEX idx_applications_applied_at (applied_at),
    INDEX idx_applications_stage (current_stage_id)
);

-- Interview types
CREATE TABLE interview_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    duration_minutes INT DEFAULT 60,
    is_technical BOOLEAN DEFAULT FALSE,
    is_remote_possible BOOLEAN DEFAULT TRUE,
    
    UNIQUE KEY uk_interview_types_name (name)
);

-- Interviews scheduled for applications
CREATE TABLE interviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    stage_id INT NOT NULL,
    interview_type_id INT NOT NULL,
    interviewer_email VARCHAR(255) NOT NULL,
    interviewer_name VARCHAR(200),
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INT DEFAULT 60,
    location VARCHAR(200),
    meeting_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'scheduled',
    feedback TEXT,
    rating TINYINT CHECK (rating >= 1 AND rating <= 10),
    recommendation VARCHAR(20),
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (stage_id) REFERENCES pipeline_stages(id),
    FOREIGN KEY (interview_type_id) REFERENCES interview_types(id),
    
    INDEX idx_interviews_application (application_id),
    INDEX idx_interviews_scheduled_at (scheduled_at),
    INDEX idx_interviews_interviewer (interviewer_email),
    INDEX idx_interviews_status (status),
    INDEX idx_interviews_rating (rating)
);

-- Application stage history
CREATE TABLE application_stage_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    stage_id INT,
    status VARCHAR(20) DEFAULT 'entered',
    entered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    notes TEXT,
    moved_by_email VARCHAR(255),
    
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (stage_id) REFERENCES pipeline_stages(id),
    
    INDEX idx_stage_history_application (application_id),
    INDEX idx_stage_history_entered_at (entered_at),
    INDEX idx_stage_history_status (status)
);

-- Skills and competencies
CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    
    UNIQUE KEY uk_skills_name (name),
    INDEX idx_skills_category (category)
);

-- Position required skills
CREATE TABLE position_skills (
    position_id INT NOT NULL,
    skill_id INT NOT NULL,
    importance VARCHAR(20) DEFAULT 'required',
    experience_years_min INT DEFAULT 0,
    
    PRIMARY KEY (position_id, skill_id),
    FOREIGN KEY (position_id) REFERENCES positions(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    
    INDEX idx_position_skills_importance (importance)
);

-- Candidate skills
CREATE TABLE candidate_skills (
    candidate_id INT NOT NULL,
    skill_id INT NOT NULL,
    experience_years INT DEFAULT 0,
    proficiency_level VARCHAR(20) DEFAULT 'intermediate',
    verified BOOLEAN DEFAULT FALSE,
    
    PRIMARY KEY (candidate_id, skill_id),
    FOREIGN KEY (candidate_id) REFERENCES candidates(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    
    INDEX idx_candidate_skills_proficiency (proficiency_level),
    INDEX idx_candidate_skills_verified (verified)
);

-- Application ratings and scores
CREATE TABLE application_scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    stage_id INT,
    score_type VARCHAR(20) DEFAULT 'overall',
    score DECIMAL(3,2) CHECK (score >= 0 AND score <= 9.99),
    max_score DECIMAL(3,2) DEFAULT 9.99,
    evaluator_email VARCHAR(255) NOT NULL,
    comments TEXT,
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (stage_id) REFERENCES pipeline_stages(id),
    
    INDEX idx_application_scores_application (application_id),
    INDEX idx_application_scores_type (score_type),
    INDEX idx_application_scores_score (score),
    INDEX idx_application_scores_evaluator (evaluator_email)
);

-- Notes and comments on applications
CREATE TABLE application_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_id INT NOT NULL,
    author_email VARCHAR(255) NOT NULL,
    author_name VARCHAR(200),
    note TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    
    INDEX idx_application_notes_application (application_id),
    INDEX idx_application_notes_author (author_email),
    INDEX idx_application_notes_created_at (created_at)
);

-- Create views for common queries

-- Active positions with department info
CREATE VIEW active_positions_view AS
SELECT 
    p.*,
    d.name as department_name,
    d.manager_email as department_manager,
    (SELECT COUNT(*) FROM applications a WHERE a.position_id = p.id AND a.status IN ('applied', 'screening', 'in_progress')) as active_applications_count
FROM positions p
JOIN departments d ON p.department_id = d.id
WHERE p.status = 'published';

-- Application pipeline view with current stage info
CREATE VIEW application_pipeline_view AS
SELECT 
    a.*,
    c.first_name,
    c.last_name,
    c.email as candidate_email,
    c.phone as candidate_phone,
    p.title as position_title,
    p.department_id,
    d.name as department_name,
    ps.name as current_stage_name,
    ps.stage_type as current_stage_type,
    pt.name as pipeline_name,
    (SELECT COUNT(*) FROM interviews i WHERE i.application_id = a.id AND i.status = 'completed') as completed_interviews_count
FROM applications a
JOIN candidates c ON a.candidate_id = c.id
JOIN positions p ON a.position_id = p.id
JOIN departments d ON p.department_id = d.id
LEFT JOIN pipeline_stages ps ON a.current_stage_id = ps.id
JOIN pipeline_templates pt ON a.pipeline_template_id = pt.id;

-- Sample data

-- Insert job boards
INSERT INTO job_boards (name, website_url, cost_per_posting) VALUES
('LinkedIn', 'https://linkedin.com', 299.00),
('Indeed', 'https://indeed.com', 150.00),
('Glassdoor', 'https://glassdoor.com', 200.00),
('Stack Overflow Jobs', 'https://stackoverflow.com/jobs', 399.00),
('AngelList', 'https://angel.co', 250.00),
('Company Website', NULL, 0.00),
('Hacker News', 'https://news.ycombinator.com/jobs', 0.00),
('GitHub Jobs', 'https://jobs.github.com', 450.00);

-- Insert departments
INSERT INTO departments (name, description, manager_email, budget) VALUES
('Engineering', 'Software development and technical teams', 'john.smith@company.com', 2000000.00),
('Product', 'Product management and design', 'sarah.johnson@company.com', 800000.00),
('Marketing', 'Marketing and growth teams', 'mike.wilson@company.com', 600000.00),
('Sales', 'Sales and business development', 'lisa.davis@company.com', 1200000.00),
('HR', 'Human resources and recruiting', 'anna.brown@company.com', 400000.00),
('Finance', 'Finance and accounting', 'david.miller@company.com', 300000.00),
('Operations', 'Operations and support teams', 'carol.garcia@company.com', 500000.00),
('Legal', 'Legal and compliance', 'robert.jones@company.com', 250000.00);

-- Insert pipeline templates
INSERT INTO pipeline_templates (name, description, is_default) VALUES
('Standard Engineering', 'Standard pipeline for engineering positions', TRUE),
('Senior Engineering', 'Pipeline for senior engineering roles with additional technical rounds', FALSE),
('Product Management', 'Pipeline for product management positions', FALSE),
('Sales Pipeline', 'Pipeline for sales positions', FALSE),
('Executive Search', 'Pipeline for C-level and director positions', FALSE),
('Intern Pipeline', 'Simplified pipeline for internship positions', FALSE);

-- Insert pipeline stages
INSERT INTO pipeline_stages (template_id, name, description, stage_order, stage_type, duration_days) VALUES
-- Standard Engineering pipeline (template_id = 1)
(1, 'Application Review', 'Initial review of application and resume', 1, 'screening', 2),
(1, 'Phone Screening', 'Initial phone conversation with recruiter', 2, 'interview', 3),
(1, 'Technical Interview', 'Technical coding interview', 3, 'interview', 5),
(1, 'Team Interview', 'Interview with potential team members', 4, 'interview', 5),
(1, 'Final Interview', 'Interview with hiring manager', 5, 'interview', 3),
(1, 'Reference Check', 'Check references from previous employers', 6, 'reference_check', 3),
(1, 'Offer', 'Make job offer to candidate', 7, 'offer', 5),

-- Senior Engineering pipeline (template_id = 2)
(2, 'Application Review', 'Initial review of application and resume', 1, 'screening', 2),
(2, 'Recruiter Call', 'Initial conversation with senior recruiter', 2, 'interview', 3),
(2, 'System Design Interview', 'System design and architecture interview', 3, 'interview', 7),
(2, 'Technical Deep Dive', 'Advanced technical interview', 4, 'interview', 7),
(2, 'Leadership Interview', 'Interview focusing on leadership skills', 5, 'interview', 5),
(2, 'Team & Culture Fit', 'Interview with team and culture assessment', 6, 'interview', 5),
(2, 'Reference Check', 'Comprehensive reference check', 7, 'reference_check', 5),
(2, 'Offer Negotiation', 'Offer discussion and negotiation', 8, 'offer', 7),

-- Product Management pipeline (template_id = 3)
(3, 'Application Review', 'Review application and portfolio', 1, 'screening', 2),
(3, 'Recruiter Screening', 'Initial screening call', 2, 'interview', 3),
(3, 'Product Case Study', 'Product management case study', 3, 'test', 7),
(3, 'Product Interview', 'Interview with product team', 4, 'interview', 5),
(3, 'Executive Interview', 'Interview with product leadership', 5, 'interview', 5),
(3, 'Reference Check', 'Reference verification', 6, 'reference_check', 3),
(3, 'Offer', 'Job offer', 7, 'offer', 5),

-- Sales Pipeline (template_id = 4)
(4, 'Application Review', 'Review sales application', 1, 'screening', 1),
(4, 'Phone Screening', 'Sales screening call', 2, 'interview', 2),
(4, 'Sales Presentation', 'Candidate presents mock sales pitch', 3, 'test', 5),
(4, 'Manager Interview', 'Interview with sales manager', 4, 'interview', 3),
(4, 'Reference Check', 'Sales reference verification', 5, 'reference_check', 2),
(4, 'Offer', 'Sales offer', 6, 'offer', 3),

-- Executive Search (template_id = 5)
(5, 'Executive Screening', 'Executive recruiter screening', 1, 'screening', 5),
(5, 'Panel Interview', 'Interview with leadership team', 2, 'interview', 7),
(5, 'Board Interview', 'Interview with board members', 3, 'interview', 10),
(5, 'Assessment Center', 'Executive assessment and evaluation', 4, 'test', 10),
(5, 'Reference Check', 'Executive reference verification', 5, 'reference_check', 7),
(5, 'Offer Negotiation', 'Executive offer negotiation', 6, 'offer', 14),

-- Intern Pipeline (template_id = 6)
(6, 'Application Review', 'Review intern application', 1, 'screening', 1),
(6, 'Phone Interview', 'Basic phone interview', 2, 'interview', 3),
(6, 'Technical Assessment', 'Simple technical test', 3, 'test', 5),
(6, 'Team Interview', 'Meet the team', 4, 'interview', 3),
(6, 'Offer', 'Intern offer', 5, 'offer', 3);

-- Insert interview types
INSERT INTO interview_types (name, description, duration_minutes, is_technical, is_remote_possible) VALUES
('Phone Screening', 'Initial phone conversation with recruiter', 30, FALSE, TRUE),
('Video Call', 'General video interview', 60, FALSE, TRUE),
('Technical Interview', 'Live coding or technical discussion', 90, TRUE, TRUE),
('System Design', 'System architecture and design interview', 90, TRUE, TRUE),
('Behavioral Interview', 'Behavioral and culture fit interview', 60, FALSE, TRUE),
('On-site Interview', 'In-person interview at office', 60, FALSE, FALSE),
('Panel Interview', 'Interview with multiple team members', 90, FALSE, TRUE),
('Case Study Presentation', 'Candidate presents case study solution', 45, FALSE, TRUE),
('Technical Assessment', 'Take-home or live coding test', 120, TRUE, TRUE),
('Cultural Fit Interview', 'Assessment of cultural alignment', 45, FALSE, TRUE);

-- Insert skills
INSERT INTO skills (name, category) VALUES
('JavaScript', 'Programming'),
('TypeScript', 'Programming'),
('Python', 'Programming'),
('Java', 'Programming'),
('Go', 'Programming'),
('Rust', 'Programming'),
('C++', 'Programming'),
('C#', 'Programming'),
('Ruby', 'Programming'),
('PHP', 'Programming'),
('React', 'Frontend'),
('Vue.js', 'Frontend'),
('Angular', 'Frontend'),
('Svelte', 'Frontend'),
('HTML/CSS', 'Frontend'),
('Node.js', 'Backend'),
('Express.js', 'Backend'),
('Django', 'Backend'),
('FastAPI', 'Backend'),
('Ruby on Rails', 'Backend'),
('Spring Boot', 'Backend'),
('PostgreSQL', 'Database'),
('MySQL', 'Database'),
('MongoDB', 'Database'),
('Redis', 'Database'),
('Elasticsearch', 'Database'),
('Docker', 'DevOps'),
('Kubernetes', 'DevOps'),
('Jenkins', 'DevOps'),
('GitLab CI', 'DevOps'),
('AWS', 'Cloud'),
('Azure', 'Cloud'),
('GCP', 'Cloud'),
('Terraform', 'Infrastructure'),
('Git', 'Tools'),
('GraphQL', 'API'),
('REST API', 'API'),
('Microservices', 'Architecture'),
('System Design', 'Architecture'),
('Product Management', 'Business'),
('Agile/Scrum', 'Methodology'),
('Leadership', 'Soft Skills'),
('Communication', 'Soft Skills'),
('Problem Solving', 'Soft Skills'),
('Team Management', 'Soft Skills'),
('Data Analysis', 'Analytics'),
('Machine Learning', 'Data Science'),
('Sales', 'Business'),
('Marketing', 'Business'),
('Customer Support', 'Business');

-- Insert positions
INSERT INTO positions (title, department_id, description, requirements, salary_min, salary_max, employment_type, location, is_remote, experience_years_min, experience_years_max, status) VALUES
('Senior Full Stack Engineer', 1, 'We are looking for a senior full stack engineer to join our platform team. You will be responsible for building scalable web applications and APIs.', 'Strong experience with React, Node.js, and PostgreSQL. 5+ years of experience required.', 120000, 160000, 'full_time', 'San Francisco, CA', TRUE, 5, 10, 'published'),
('Product Manager', 2, 'Lead product strategy and roadmap for our core platform. Work closely with engineering and design teams.', 'Experience in B2B SaaS product management. Strong analytical and communication skills.', 130000, 180000, 'full_time', 'San Francisco, CA', TRUE, 3, 8, 'published'),
('Frontend Engineer', 1, 'Build beautiful and responsive user interfaces using modern web technologies.', 'Expert in React, TypeScript, and modern CSS. Experience with design systems preferred.', 90000, 130000, 'full_time', 'Remote', TRUE, 2, 6, 'published'),
('DevOps Engineer', 1, 'Manage our cloud infrastructure and deployment pipelines. Ensure system reliability and security.', 'Experience with AWS, Kubernetes, and CI/CD pipelines. Infrastructure as Code experience required.', 110000, 150000, 'full_time', 'San Francisco, CA', FALSE, 4, 8, 'published'),
('Data Engineer', 1, 'Build and maintain our data infrastructure. Design data pipelines and analytics systems.', 'Strong Python skills and experience with data pipelines. Knowledge of Spark and Airflow preferred.', 105000, 140000, 'full_time', 'Remote', TRUE, 3, 7, 'published'),
('Sales Development Representative', 4, 'Generate and qualify leads for our sales team. First point of contact for potential customers.', 'Experience in B2B sales and excellent communication skills. CRM experience preferred.', 60000, 80000, 'full_time', 'San Francisco, CA', FALSE, 1, 3, 'published'),
('UX Designer', 2, 'Design user experiences for our web and mobile applications. Conduct user research and usability testing.', 'Portfolio showing UX design work. Experience with Figma and user research methodologies.', 85000, 120000, 'full_time', 'San Francisco, CA', TRUE, 2, 6, 'published'),
('Backend Engineer', 1, 'Build robust and scalable backend services and APIs. Focus on performance and reliability.', 'Strong experience with Python/Django or Node.js. Database design and optimization skills.', 95000, 135000, 'full_time', 'Remote', TRUE, 3, 7, 'published'),
('Marketing Manager', 3, 'Develop and execute marketing strategies. Manage digital marketing campaigns and content.', 'Experience in digital marketing and content creation. Analytics and growth marketing skills.', 80000, 110000, 'full_time', 'San Francisco, CA', TRUE, 3, 6, 'published'),
('Software Engineer Intern', 1, 'Summer internship program for software engineering students. Work on real projects with mentorship.', 'Computer Science student with programming experience. Knowledge of web technologies preferred.', 5000, 7000, 'internship', 'San Francisco, CA', TRUE, 0, 1, 'published');

-- Insert candidates
INSERT INTO candidates (first_name, last_name, email, phone, linkedin_url, github_url, current_position, current_company, current_salary, expected_salary, location, is_open_to_remote, years_of_experience, source, skills) VALUES
('Alice', 'Johnson', 'alice.johnson@email.com', '+1-555-0101', 'https://linkedin.com/in/alicejohnson', 'https://github.com/alicejohnson', 'Senior Software Engineer', 'TechCorp', 115000, 140000, 'San Francisco, CA', TRUE, 6, 'linkedin', '["JavaScript", "React", "Node.js", "PostgreSQL"]'),
('Bob', 'Smith', 'bob.smith@email.com', '+1-555-0102', 'https://linkedin.com/in/bobsmith', 'https://github.com/bobsmith', 'Full Stack Developer', 'StartupXYZ', 95000, 120000, 'Austin, TX', TRUE, 4, 'job_board', '["Python", "Django", "React", "AWS"]'),
('Carol', 'Davis', 'carol.davis@email.com', '+1-555-0103', 'https://linkedin.com/in/caroldavis', NULL, 'Product Manager', 'BigCorp', 125000, 160000, 'New York, NY', FALSE, 5, 'referral', '["Product Management", "Agile/Scrum", "Data Analysis"]'),
('David', 'Wilson', 'david.wilson@email.com', '+1-555-0104', 'https://linkedin.com/in/davidwilson', 'https://github.com/davidwilson', 'Frontend Developer', 'WebAgency', 80000, 110000, 'Remote', TRUE, 3, 'job_board', '["React", "TypeScript", "HTML/CSS", "Vue.js"]'),
('Emma', 'Brown', 'emma.brown@email.com', '+1-555-0105', 'https://linkedin.com/in/emmabrown', NULL, 'DevOps Engineer', 'CloudCompany', 120000, 145000, 'Seattle, WA', TRUE, 5, 'linkedin', '["AWS", "Kubernetes", "Docker", "Terraform"]'),
('Frank', 'Miller', 'frank.miller@email.com', '+1-555-0106', 'https://linkedin.com/in/frankmiller', 'https://github.com/frankmiller', 'Data Scientist', 'DataCorp', 100000, 130000, 'Boston, MA', TRUE, 4, 'direct', '["Python", "Machine Learning", "Data Analysis"]'),
('Grace', 'Lee', 'grace.lee@email.com', '+1-555-0107', 'https://linkedin.com/in/gracelee', NULL, 'Sales Representative', 'SalesCorp', 70000, 90000, 'Chicago, IL', FALSE, 2, 'job_board', '["Sales", "Communication", "Customer Support"]'),
('Henry', 'Taylor', 'henry.taylor@email.com', '+1-555-0108', 'https://linkedin.com/in/henrytaylor', 'https://github.com/henrytaylor', 'Software Engineer', 'TechStartup', 85000, 115000, 'San Francisco, CA', TRUE, 3, 'career_fair', '["Java", "Spring Boot", "MySQL", "REST API"]'),
('Ivy', 'Anderson', 'ivy.anderson@email.com', '+1-555-0109', 'https://linkedin.com/in/ivyanderson', 'https://behance.net/ivyanderson', 'Product Designer', 'DesignStudio', 90000, 120000, 'Los Angeles, CA', TRUE, 4, 'linkedin', '["UX Design", "Figma", "User Research"]'),
('Jack', 'Thomas', 'jack.thomas@email.com', '+1-555-0110', 'https://linkedin.com/in/jackthomas', NULL, 'Sales Manager', 'Enterprise Corp', 95000, 120000, 'Dallas, TX', FALSE, 6, 'referral', '["Sales", "Team Management", "Leadership"]'),
('Kate', 'Wilson', 'kate.wilson@email.com', '+1-555-0111', 'https://linkedin.com/in/katewilson', 'https://github.com/katewilson', 'Backend Engineer', 'MicroServices Inc', 92000, 125000, 'Austin, TX', TRUE, 4, 'job_board', '["Python", "FastAPI", "PostgreSQL", "Redis"]'),
('Luke', 'Garcia', 'luke.garcia@email.com', '+1-555-0112', 'https://linkedin.com/in/lukegarcia', NULL, 'Marketing Specialist', 'GrowthCorp', 65000, 85000, 'Miami, FL', TRUE, 3, 'linkedin', '["Marketing", "Content Creation", "Analytics"]'),
('Mia', 'Rodriguez', 'mia.rodriguez@email.com', '+1-555-0113', 'https://linkedin.com/in/miarodriguez', 'https://github.com/miarodriguez', 'CS Student', 'University', 0, 6000, 'Berkeley, CA', TRUE, 0, 'career_fair', '["JavaScript", "Python", "React"]'),
('Noah', 'Martinez', 'noah.martinez@email.com', '+1-555-0114', 'https://linkedin.com/in/noahmartinez', 'https://github.com/noahmartinez', 'DevOps Intern', 'CloudTech', 55000, 75000, 'Portland, OR', TRUE, 1, 'job_board', '["Docker", "AWS", "Git"]'),
('Olivia', 'Clark', 'olivia.clark@email.com', '+1-555-0115', 'https://linkedin.com/in/oliviaclark', NULL, 'UX Researcher', 'DesignFirm', 88000, 115000, 'San Francisco, CA', TRUE, 3, 'referral', '["User Research", "Data Analysis", "Communication"]');

-- Insert applications
INSERT INTO applications (candidate_id, position_id, job_board_id, pipeline_template_id, status, current_stage_id, applied_at) VALUES
(1, 1, 1, 2, 'in_progress', 11, '2024-01-15 10:30:00'),
(2, 1, 2, 1, 'in_progress', 3, '2024-01-18 14:20:00'),
(3, 2, 1, 3, 'in_progress', 17, '2024-01-20 09:15:00'),
(4, 3, 3, 1, 'screening', 2, '2024-01-22 16:45:00'),
(5, 4, 1, 1, 'offer_made', 7, '2024-01-10 11:30:00'),
(6, 5, 4, 1, 'in_progress', 4, '2024-01-25 13:20:00'),
(7, 6, 2, 4, 'applied', 22, '2024-01-28 10:00:00'),
(8, 8, 6, 1, 'rejected', NULL, '2024-01-12 15:30:00'),
(9, 7, 1, 1, 'screening', 2, '2024-01-26 12:10:00'),
(10, 6, 3, 4, 'in_progress', 23, '2024-01-29 09:45:00'),
(11, 8, 2, 1, 'in_progress', 4, '2024-01-30 11:20:00'),
(12, 9, 1, 1, 'applied', 1, '2024-02-01 14:30:00'),
(13, 10, 6, 6, 'in_progress', 29, '2024-02-02 16:15:00'),
(14, 4, 4, 1, 'screening', 2, '2024-02-03 10:45:00'),
(15, 7, 1, 1, 'in_progress', 3, '2024-02-04 13:20:00');

-- Insert interviews
INSERT INTO interviews (application_id, stage_id, interview_type_id, interviewer_email, interviewer_name, scheduled_at, status, rating, recommendation, feedback, completed_at) VALUES
(1, 10, 4, 'tech.lead@company.com', 'John Tech Lead', '2024-01-25 14:00:00', 'completed', 8, 'hire', 'Strong system design skills, good communication. Demonstrated excellent problem-solving abilities.', '2024-01-25 15:30:00'),
(2, 3, 3, 'senior.dev@company.com', 'Sarah Senior Dev', '2024-01-24 10:00:00', 'completed', 7, 'hire', 'Good coding skills, needs improvement in algorithms but shows strong potential.', '2024-01-24 11:30:00'),
(3, 17, 2, 'product.manager@company.com', 'Mike Product Manager', '2024-01-30 15:00:00', 'scheduled', NULL, NULL, NULL, NULL),
(4, 2, 1, 'recruiter@company.com', 'Anna Recruiter', '2024-01-29 11:00:00', 'completed', 6, 'maybe', 'Good enthusiasm but limited experience. Could be good for junior role.', '2024-01-29 11:30:00'),
(5, 5, 5, 'hiring.manager@company.com', 'Lisa Hiring Manager', '2024-01-20 16:00:00', 'completed', 9, 'strong_hire', 'Excellent cultural fit and technical skills. Strong leadership potential.', '2024-01-20 17:00:00'),
(6, 4, 7, 'team@company.com', 'Engineering Team', '2024-02-01 13:00:00', 'scheduled', NULL, NULL, NULL, NULL),
(7, 23, 1, 'sales.manager@company.com', 'Tom Sales Manager', '2024-02-05 10:00:00', 'scheduled', NULL, NULL, NULL, NULL),
(8, 3, 3, 'engineer@company.com', 'Bob Engineer', '2024-01-18 14:00:00', 'completed', 4, 'no_hire', 'Technical skills below requirements. Lacks experience in key technologies.', '2024-01-18 15:30:00'),
(9, 2, 1, 'design.lead@company.com', 'Emma Design Lead', '2024-02-01 11:00:00', 'completed', 8, 'hire', 'Great portfolio and design thinking. Good cultural fit.', '2024-02-01 12:00:00'),
(11, 4, 7, 'backend.team@company.com', 'Backend Team', '2024-02-06 14:00:00', 'scheduled', NULL, NULL, NULL, NULL),
(13, 29, 9, 'intern.mentor@company.com', 'Alex Mentor', '2024-02-08 10:00:00', 'scheduled', NULL, NULL, NULL, NULL),
(15, 3, 3, 'ux.lead@company.com', 'Sophie UX Lead', '2024-02-10 15:00:00', 'scheduled', NULL, NULL, NULL, NULL);

-- Insert application stage history
INSERT INTO application_stage_history (application_id, stage_id, status, entered_at, completed_at, moved_by_email, notes) VALUES
-- Application 1 history (Alice Johnson - Senior Full Stack Engineer)
(1, 8, 'completed', '2024-01-15 10:30:00', '2024-01-16 09:00:00', 'recruiter@company.com', 'Strong resume, good experience match'),
(1, 9, 'completed', '2024-01-16 09:00:00', '2024-01-18 10:30:00', 'recruiter@company.com', 'Passed phone screening with flying colors'),
(1, 10, 'completed', '2024-01-18 10:30:00', '2024-01-25 15:30:00', 'tech.lead@company.com', 'Excellent system design interview'),
(1, 11, 'entered', '2024-01-25 15:30:00', NULL, 'tech.lead@company.com', 'Moving to technical deep dive'),

-- Application 2 history (Bob Smith - Senior Full Stack Engineer)
(2, 1, 'completed', '2024-01-18 14:20:00', '2024-01-19 10:00:00', 'recruiter@company.com', 'Resume looks good'),
(2, 2, 'completed', '2024-01-19 10:00:00', '2024-01-22 14:00:00', 'recruiter@company.com', 'Good phone screening'),
(2, 3, 'entered', '2024-01-22 14:00:00', NULL, 'recruiter@company.com', 'Scheduled for technical interview'),

-- Application 3 history (Carol Davis - Product Manager)
(3, 15, 'completed', '2024-01-20 09:15:00', '2024-01-21 11:00:00', 'recruiter@company.com', 'Strong product background'),
(3, 16, 'completed', '2024-01-21 11:00:00', '2024-01-25 16:00:00', 'recruiter@company.com', 'Good screening call'),
(3, 17, 'entered', '2024-01-25 16:00:00', NULL, 'product.manager@company.com', 'Preparing case study'),

-- Application 5 history (Emma Brown - DevOps Engineer)
(5, 1, 'completed', '2024-01-10 11:30:00', '2024-01-11 09:00:00', 'recruiter@company.com', 'Excellent DevOps background'),
(5, 2, 'completed', '2024-01-11 09:00:00', '2024-01-13 14:00:00', 'recruiter@company.com', 'Strong phone screening'),
(5, 3, 'completed', '2024-01-13 14:00:00', '2024-01-16 15:00:00', 'devops.lead@company.com', 'Great technical knowledge'),
(5, 4, 'completed', '2024-01-16 15:00:00', '2024-01-18 16:00:00', 'devops.team@company.com', 'Team loved her'),
(5, 5, 'completed', '2024-01-18 16:00:00', '2024-01-20 17:00:00', 'hiring.manager@company.com', 'Final interview went very well'),
(5, 6, 'completed', '2024-01-20 17:00:00', '2024-01-23 10:00:00', 'hr@company.com', 'References checked out'),
(5, 7, 'entered', '2024-01-23 10:00:00', NULL, 'hr@company.com', 'Preparing offer package');

-- Insert position skills
INSERT INTO position_skills (position_id, skill_id, importance, experience_years_min) VALUES
-- Senior Full Stack Engineer skills
(1, 1, 'required', 3), -- JavaScript
(1, 16, 'required', 3), -- Node.js
(1, 11, 'required', 2), -- React
(1, 22, 'required', 2), -- PostgreSQL
(1, 2, 'preferred', 1), -- TypeScript
(1, 36, 'preferred', 1), -- GraphQL

-- Product Manager skills
(2, 40, 'required', 2), -- Product Management
(2, 41, 'required', 1), -- Agile/Scrum
(2, 46, 'required', 1), -- Data Analysis
(2, 43, 'preferred', 0), -- Communication
(2, 42, 'preferred', 1), -- Leadership

-- Frontend Engineer skills
(3, 11, 'required', 2), -- React
(3, 2, 'required', 1), -- TypeScript
(3, 15, 'required', 2), -- HTML/CSS
(3, 12, 'preferred', 1), -- Vue.js
(3, 14, 'nice_to_have', 0), -- Svelte

-- DevOps Engineer skills
(4, 31, 'required', 2), -- AWS
(4, 28, 'required', 2), -- Kubernetes
(4, 27, 'required', 2), -- Docker
(4, 34, 'preferred', 1), -- Terraform
(4, 29, 'preferred', 1), -- Jenkins

-- Data Engineer skills
(5, 3, 'required', 3), -- Python
(5, 46, 'required', 2), -- Data Analysis
(5, 22, 'preferred', 1), -- PostgreSQL
(5, 24, 'preferred', 1), -- MongoDB
(5, 47, 'nice_to_have', 0); -- Machine Learning

-- Insert candidate skills
INSERT INTO candidate_skills (candidate_id, skill_id, experience_years, proficiency_level, verified) VALUES
-- Alice Johnson skills
(1, 1, 6, 'expert', TRUE), -- JavaScript
(1, 11, 5, 'advanced', TRUE), -- React
(1, 16, 4, 'advanced', TRUE), -- Node.js
(1, 22, 3, 'intermediate', FALSE), -- PostgreSQL

-- Bob Smith skills
(2, 3, 4, 'advanced', TRUE), -- Python
(2, 18, 3, 'advanced', TRUE), -- Django
(2, 11, 2, 'intermediate', TRUE), -- React
(2, 31, 2, 'intermediate', FALSE), -- AWS

-- Carol Davis skills
(3, 40, 5, 'expert', TRUE), -- Product Management
(3, 41, 4, 'advanced', TRUE), -- Agile/Scrum
(3, 46, 3, 'intermediate', TRUE), -- Data Analysis

-- David Wilson skills
(4, 11, 3, 'advanced', TRUE), -- React
(4, 2, 2, 'intermediate', TRUE), -- TypeScript
(4, 15, 4, 'expert', TRUE), -- HTML/CSS
(4, 12, 2, 'intermediate', FALSE), -- Vue.js

-- Emma Brown skills
(5, 31, 5, 'expert', TRUE), -- AWS
(5, 28, 4, 'advanced', TRUE), -- Kubernetes
(5, 27, 5, 'expert', TRUE), -- Docker
(5, 34, 3, 'intermediate', TRUE); -- Terraform

-- Insert application scores
INSERT INTO application_scores (application_id, stage_id, score_type, score, evaluator_email, comments, evaluated_at) VALUES
(1, 10, 'technical', 8.5, 'tech.lead@company.com', 'Strong system design and coding skills', '2024-01-25 15:30:00'),
(1, 10, 'communication', 8.0, 'tech.lead@company.com', 'Clear communicator, good at explaining complex concepts', '2024-01-25 15:30:00'),
(2, 3, 'technical', 7.0, 'senior.dev@company.com', 'Good fundamentals, some gaps in advanced topics', '2024-01-24 11:30:00'),
(2, 3, 'problem_solving', 7.5, 'senior.dev@company.com', 'Good problem-solving approach', '2024-01-24 11:30:00'),
(4, 2, 'communication', 6.0, 'recruiter@company.com', 'Enthusiastic but needs more confidence', '2024-01-29 11:30:00'),
(5, 5, 'overall', 9.0, 'hiring.manager@company.com', 'Exceptional candidate, strong hire', '2024-01-20 17:00:00'),
(5, 5, 'cultural_fit', 9.5, 'hiring.manager@company.com', 'Perfect culture fit, aligns with company values', '2024-01-20 17:00:00'),
(8, 3, 'technical', 4.0, 'engineer@company.com', 'Below technical requirements', '2024-01-18 15:30:00'),
(9, 2, 'overall', 8.0, 'design.lead@company.com', 'Strong design skills and good portfolio', '2024-02-01 12:00:00'),
(9, 2, 'cultural_fit', 8.5, 'design.lead@company.com', 'Good team fit and collaboration skills', '2024-02-01 12:00:00');

-- Insert application notes
INSERT INTO application_notes (application_id, author_email, author_name, note, is_internal, created_at) VALUES
(1, 'recruiter@company.com', 'Anna Recruiter', 'Candidate has strong background in fintech, which aligns well with our domain.', TRUE, '2024-01-15 11:00:00'),
(1, 'tech.lead@company.com', 'John Tech Lead', 'Very impressed with system design approach. Candidate thought through scalability concerns.', TRUE, '2024-01-25 15:45:00'),
(2, 'recruiter@company.com', 'Anna Recruiter', 'Located in Austin but open to relocation. Salary expectations within range.', TRUE, '2024-01-19 10:30:00'),
(3, 'product.manager@company.com', 'Mike Product Manager', 'Strong product sense. Case study response shows good strategic thinking.', TRUE, '2024-01-30 16:00:00'),
(4, 'recruiter@company.com', 'Anna Recruiter', 'Junior level candidate but shows great potential. Could be good fit for frontend role.', TRUE, '2024-01-29 12:00:00'),
(5, 'hr@company.com', 'Anna HR', 'All references very positive. Previous manager highly recommends.', TRUE, '2024-01-23 11:00:00'),
(5, 'hiring.manager@company.com', 'Lisa Hiring Manager', 'One of the strongest DevOps candidates we\'ve seen. Ready to extend offer.', TRUE, '2024-01-20 17:30:00'),
(7, 'sales.manager@company.com', 'Tom Sales Manager', 'Good sales experience but limited B2B background. Need to assess in interview.', TRUE, '2024-01-28 14:00:00'),
(8, 'engineer@company.com', 'Bob Engineer', 'Unfortunately technical skills not at required level for this position.', TRUE, '2024-01-18 16:00:00'),
(9, 'design.lead@company.com', 'Emma Design Lead', 'Portfolio shows excellent UX thinking. Strong candidate for our design team.', TRUE, '2024-02-01 12:30:00'),
(11, 'recruiter@company.com', 'Anna Recruiter', 'Backend engineer with good Python experience. Scheduling team interview.', TRUE, '2024-01-30 14:00:00'),
(13, 'intern.mentor@company.com', 'Alex Mentor', 'CS student with good fundamentals. Shows promise for internship program.', TRUE, '2024-02-02 17:00:00');