-- Open Payments Database Schema for DuckDB
-- CMS Open Payments data processing and analysis

-- Enable progress bar for long-running operations
PRAGMA enable_progress_bar;

-- Set memory limit for processing large files
PRAGMA memory_limit='4GB';

-- Create schema for Open Payments data
-- Note: DuckDB uses 'main' schema by default

-- General Payments Table
-- Contains payments made to physicians and teaching hospitals
DROP TABLE IF EXISTS general_payments;
CREATE TABLE general_payments AS 
SELECT * FROM read_csv_auto(
    getenv('OPENPAYMENTS_DATA_DIR') || '/OP_DTL_GNRL_PGYR2023*.csv',
    header=true,
    ignore_errors=true,
    max_line_size=1048576
);

-- Research Payments Table  
-- Contains research payments made to physicians and teaching hospitals
DROP TABLE IF EXISTS research_payments;
CREATE TABLE research_payments AS 
SELECT * FROM read_csv_auto(
    getenv('OPENPAYMENTS_DATA_DIR') || '/OP_DTL_RSRCH_PGYR2023*.csv',
    header=true,
    ignore_errors=true,
    max_line_size=1048576
);

-- Ownership Information Table
-- Contains physician and teaching hospital ownership information
DROP TABLE IF EXISTS ownership_information;
CREATE TABLE ownership_information AS 
SELECT * FROM read_csv_auto(
    getenv('OPENPAYMENTS_DATA_DIR') || '/OP_DTL_OWNRSHP_PGYR2023*.csv',
    header=true,
    ignore_errors=true,
    max_line_size=1048576
);

-- Display summary statistics
SELECT 'Database creation completed successfully!' as status;