-- ============================================================================
-- Snowflake Setup Script for PowerPoint Generation
-- ============================================================================
-- This script creates all necessary Snowflake objects for the PowerPoint
-- generation stored procedure
-- ============================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS POWERPOINT_DB
    COMMENT = 'Database for PowerPoint generation service';

-- Use the database
USE DATABASE POWERPOINT_DB;

-- Create schema
CREATE SCHEMA IF NOT EXISTS REPORTING
    COMMENT = 'Schema for reporting and presentation generation';

USE SCHEMA REPORTING;

-- Create internal stage for storing generated PowerPoint files
CREATE STAGE IF NOT EXISTS PPT_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for storing generated PowerPoint presentations';

-- Create a warehouse for executing the stored procedure (if needed)
CREATE WAREHOUSE IF NOT EXISTS REPORTING_WH
    WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for reporting and PowerPoint generation';

-- Grant necessary permissions (adjust as needed for your security model)
-- Note: These are example grants - adjust according to your security requirements

-- Grant usage on database
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE SYSADMIN;

-- Grant usage on schema
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE SYSADMIN;

-- Grant read/write on stage
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE SYSADMIN;

-- Grant usage on warehouse
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE SYSADMIN;

-- Grant execute on future procedures
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA POWERPOINT_DB.REPORTING TO ROLE SYSADMIN;

-- Create a sample accounts table (for demonstration purposes)
CREATE TABLE IF NOT EXISTS ACCOUNTS (
    ACCOUNT_ID VARCHAR(50) PRIMARY KEY,
    ACCOUNT_NAME VARCHAR(200),
    ACCOUNT_TYPE VARCHAR(50),
    REVENUE DECIMAL(18,2),
    EMPLOYEES INTEGER,
    INDUSTRY VARCHAR(100),
    CREATED_DATE DATE,
    LAST_MODIFIED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert sample data
INSERT INTO ACCOUNTS (ACCOUNT_ID, ACCOUNT_NAME, ACCOUNT_TYPE, REVENUE, EMPLOYEES, INDUSTRY, CREATED_DATE)
VALUES
    ('ACC001', 'Acme Corporation', 'Enterprise', 5000000.00, 500, 'Technology', '2023-01-15'),
    ('ACC002', 'Global Industries Inc', 'Mid-Market', 2500000.00, 250, 'Manufacturing', '2023-03-20'),
    ('ACC003', 'Tech Innovators LLC', 'Enterprise', 7500000.00, 750, 'Technology', '2022-11-10'),
    ('ACC004', 'Retail Solutions Co', 'Small Business', 500000.00, 50, 'Retail', '2024-01-05');

-- Display created objects
SHOW DATABASES LIKE 'POWERPOINT_DB';
SHOW SCHEMAS IN DATABASE POWERPOINT_DB;
SHOW STAGES IN SCHEMA POWERPOINT_DB.REPORTING;
SHOW TABLES IN SCHEMA POWERPOINT_DB.REPORTING;

SELECT 'Setup completed successfully!' AS STATUS;

