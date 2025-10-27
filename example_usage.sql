-- ============================================================================
-- Example Usage of PowerPoint Generation Stored Procedure
-- ============================================================================
-- This script demonstrates how to use the GENERATE_ACCOUNT_POWERPOINT procedure
-- ============================================================================

-- Set context
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;

-- ============================================================================
-- Example 1: Generate PowerPoint for a specific account
-- ============================================================================

-- View available accounts
SELECT * FROM ACCOUNTS;

-- Generate PowerPoint for Account ACC001
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');

-- ============================================================================
-- Example 2: Generate PowerPoints for multiple accounts
-- ============================================================================

-- Generate for all Enterprise accounts
DECLARE
    account_cursor CURSOR FOR SELECT ACCOUNT_ID FROM ACCOUNTS WHERE ACCOUNT_TYPE = 'Enterprise';
    account_id_var VARCHAR;
    result_var VARCHAR;
BEGIN
    OPEN account_cursor;
    FETCH account_cursor INTO account_id_var;
    WHILE (SQLCODE = 0) DO
        CALL GENERATE_ACCOUNT_POWERPOINT(:account_id_var) INTO :result_var;
        INSERT INTO PPT_GENERATION_LOG (ACCOUNT_ID, RESULT, GENERATED_AT)
            VALUES (:account_id_var, :result_var, CURRENT_TIMESTAMP());
        FETCH account_cursor INTO account_id_var;
    END WHILE;
    CLOSE account_cursor;
END;

-- ============================================================================
-- Example 3: List all generated PowerPoint files in the stage
-- ============================================================================

LIST @PPT_STAGE;

-- ============================================================================
-- Example 4: Generate pre-signed URL for an existing file
-- ============================================================================

-- List files and get a specific filename
LIST @PPT_STAGE;

-- Generate pre-signed URL for a specific file (replace with actual filename)
-- SELECT GET_PRESIGNED_URL(@PPT_STAGE, 'account_ACC001_20241027_120000.pptx', 86400) AS DOWNLOAD_URL;

-- ============================================================================
-- Example 5: Clean up old PowerPoint files (optional)
-- ============================================================================

-- Remove files older than 30 days
-- Note: This is a manual cleanup example
-- REMOVE @PPT_STAGE PATTERN='.*\.pptx';

-- ============================================================================
-- Optional: Create a log table to track PowerPoint generation
-- ============================================================================

CREATE TABLE IF NOT EXISTS PPT_GENERATION_LOG (
    LOG_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    ACCOUNT_ID VARCHAR(50),
    RESULT VARCHAR(1000),
    GENERATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Query the log
SELECT * FROM PPT_GENERATION_LOG ORDER BY GENERATED_AT DESC;

-- ============================================================================
-- Example 6: Error handling - Try with non-existent account
-- ============================================================================

CALL GENERATE_ACCOUNT_POWERPOINT('INVALID_ACCOUNT');

-- ============================================================================
-- Example 7: Download file using SnowSQL command line (external)
-- ============================================================================

-- To download a file using SnowSQL command line:
-- GET @PPT_STAGE/account_ACC001_20241027_120000.pptx file:///path/to/local/directory;

-- ============================================================================
-- Example 8: View stage properties and configuration
-- ============================================================================

DESCRIBE STAGE PPT_STAGE;

-- Show stage details
SHOW STAGES LIKE 'PPT_STAGE';

