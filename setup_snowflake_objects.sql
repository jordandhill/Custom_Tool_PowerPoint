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
-- ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') ensures files work correctly with pre-signed URLs
CREATE STAGE IF NOT EXISTS PPT_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
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

-- ============================================================================
-- Create Role for PowerPoint Generation Access
-- ============================================================================

-- Create dedicated role for Snowflake Intelligence agents and authorized users
CREATE ROLE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_RL
    COMMENT = 'Role for users authorized to generate PowerPoint presentations via Snowflake Intelligence';

-- Grant necessary permissions (adjust as needed for your security model)
-- Note: Using a specific role instead of PUBLIC for better security

-- Grant usage on database
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE ACCOUNTADMIN;

-- Grant usage on schema
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE ACCOUNTADMIN;


-- Grant read/write on stage (required for PowerPoint file storage)
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE SYSADMIN;
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE ACCOUNTADMIN;

-- Grant usage on warehouse
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE SNOWFLAKE_INTELLIGENCE_RL;



-- ============================================================================
-- Grant Role to Users
-- ============================================================================

-- Grant the role to specific users who should have access
-- Uncomment and modify the following lines to grant to specific users:
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username1>;
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username2>;

-- Or grant to another role (role hierarchy)
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE <parent_role>;

-- Example: Grant to SYSADMIN for testing
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE SYSADMIN;

-- Display information about the created role
SELECT 'SNOWFLAKE_INTELLIGENCE_RL role created successfully!' AS STATUS;
SELECT 'Grant this role to users who should access PowerPoint generation:' AS INFO;
SELECT '  GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;' AS COMMAND;

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
    ('ACC001', 'Acme Corporation', 'Enterprise', 4000000.00, 500, 'Technology', '2023-01-15'),
    ('ACC002', 'Global Industries Inc', 'Mid-Market', 2500000.00, 250, 'Manufacturing', '2023-03-20'),
    ('ACC003', 'Tech Innovators LLC', 'Enterprise', 7500000.00, 750, 'Technology', '2022-11-10'),
    ('ACC004', 'Retail Solutions Co', 'Small Business', 500000.00, 50, 'Retail', '2024-01-05');


-- Grant select on tables (for agents to read account data)
GRANT SELECT ON TABLE POWERPOINT_DB.REPORTING.ACCOUNTS TO ROLE SYSADMIN;
GRANT SELECT ON TABLE POWERPOINT_DB.REPORTING.ACCOUNTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Grant execute on future procedures
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA POWERPOINT_DB.REPORTING TO ROLE SYSADMIN;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA POWERPOINT_DB.REPORTING TO ROLE SNOWFLAKE_INTELLIGENCE_RL;


-- Display created objects
SHOW DATABASES LIKE 'POWERPOINT_DB';
SHOW SCHEMAS IN DATABASE POWERPOINT_DB;
SHOW STAGES IN SCHEMA POWERPOINT_DB.REPORTING;
SHOW TABLES IN SCHEMA POWERPOINT_DB.REPORTING;

SELECT 'Setup completed successfully!' AS STATUS;



