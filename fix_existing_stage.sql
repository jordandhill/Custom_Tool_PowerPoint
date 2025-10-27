-- ============================================================================
-- Fix Existing Stage - Add SNOWFLAKE_SSE Encryption
-- ============================================================================
-- If you already created the PPT_STAGE without SNOWFLAKE_SSE encryption,
-- run this script to recreate it with the correct encryption type.
-- This fixes the file corruption issue with pre-signed URLs.
-- ============================================================================

USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- Step 1: Check current stage configuration
DESC STAGE PPT_STAGE;

-- Step 2: Backup any existing files (optional but recommended)
-- List all files currently in the stage
LIST @PPT_STAGE;

-- Step 3: Drop the existing stage
-- WARNING: This will delete all files in the stage
-- If you need to preserve files, download them first using:
-- GET @PPT_STAGE file:///path/to/backup/directory/;

DROP STAGE IF EXISTS PPT_STAGE;

-- Step 4: Recreate the stage with SNOWFLAKE_SSE encryption
CREATE STAGE PPT_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for storing generated PowerPoint presentations';

-- Step 5: Verify the new stage configuration
DESC STAGE PPT_STAGE;

-- Step 6: Check encryption settings
SHOW STAGES LIKE 'PPT_STAGE';

-- Step 7: Test the fix by generating a new PowerPoint
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');

-- The pre-signed URL returned should now work correctly without corruption!

SELECT 'Stage recreation complete! Pre-signed URLs should now work correctly.' AS STATUS;

-- ============================================================================
-- Notes:
-- ============================================================================
-- 
-- SNOWFLAKE_SSE encryption:
-- - Server-side encryption managed by Snowflake
-- - Ensures pre-signed URLs serve files correctly
-- - No performance impact
-- - Compatible with all Snowflake features
--
-- Alternative: If you want to preserve existing files while migrating:
--
-- 1. Download existing files:
--    GET @PPT_STAGE file:///path/to/backup/;
--
-- 2. Recreate stage with encryption (as shown above)
--
-- 3. Re-upload files:
--    PUT file:///path/to/backup/*.pptx @PPT_STAGE AUTO_COMPRESS=FALSE;
--
-- ============================================================================

