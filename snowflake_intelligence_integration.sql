-- ============================================================================
-- Snowflake Intelligence Agent Integration
-- ============================================================================
-- This script sets up permissions and configuration for integrating the
-- PowerPoint generation stored procedure as a custom tool in Snowflake Intelligence
-- Reference: https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence
-- ============================================================================

USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- ============================================================================
-- Step 1: Verify SNOWFLAKE_INTELLIGENCE_RL Role Exists
-- ============================================================================

-- The SNOWFLAKE_INTELLIGENCE_RL role should have been created by setup_snowflake_objects.sql
-- Verify it exists:
SHOW ROLES LIKE 'SNOWFLAKE_INTELLIGENCE_RL';

-- If the role doesn't exist, create it:
-- CREATE ROLE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_RL;

-- ============================================================================
-- Step 2: Verify Required Permissions for Agents
-- ============================================================================

-- Snowflake Intelligence agents use the user's default role and warehouse
-- All permissions should already be granted to SNOWFLAKE_INTELLIGENCE_RL
-- by the setup_snowflake_objects.sql script

-- Verify permissions are in place (these should already be granted):
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT SELECT ON TABLE POWERPOINT_DB.REPORTING.ACCOUNTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON PROCEDURE POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT(VARCHAR) TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- ============================================================================
-- Step 3: Grant Role to Users
-- ============================================================================

-- Grant SNOWFLAKE_INTELLIGENCE_RL role to specific users who should have access
-- Replace <username> with actual usernames

-- Example for individual users:
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER john_doe;
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER jane_smith;

-- Or grant to another role (role hierarchy):
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE DATA_ANALYST_ROLE;

-- Users must also set this as their default role:
-- ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

SELECT 'Grant SNOWFLAKE_INTELLIGENCE_RL to users with command:' AS INFO;
SELECT '  GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;' AS COMMAND;

-- ============================================================================
-- Step 4: Create Snowflake Intelligence Database and Schema (if not exists)
-- ============================================================================

-- Create the database for Snowflake Intelligence agents
CREATE DATABASE IF NOT EXISTS snowflake_intelligence;

-- Grant usage to SYSADMIN and the intelligence role
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Create schema for agents
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

-- Grant usage on schema
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Grant CREATE AGENT privilege to admin roles
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE SYSADMIN;

-- ============================================================================
-- Step 5: Verify Current Permissions
-- ============================================================================

-- Check database permissions
SHOW GRANTS ON DATABASE POWERPOINT_DB;

-- Check schema permissions
SHOW GRANTS ON SCHEMA POWERPOINT_DB.REPORTING;

-- Check stage permissions
SHOW GRANTS ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE;

-- Check procedure permissions
SHOW GRANTS ON PROCEDURE POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT(VARCHAR);

-- Check warehouse permissions
SHOW GRANTS ON WAREHOUSE REPORTING_WH;

-- Check what users have the SNOWFLAKE_INTELLIGENCE_RL role
SHOW GRANTS OF ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- ============================================================================
-- Step 6: Instructions for Creating the Agent
-- ============================================================================

-- IMPORTANT: Create the agent using a role that has CREATE AGENT privilege
-- (e.g., SYSADMIN)

-- After running this script, create a Snowflake Intelligence agent by:
--
-- 1. Navigate to Snowsight: AI & ML » Agents
-- 2. Select "Create agent"
-- 3. For "Platform integration", select "Create this agent for Snowflake Intelligence"
-- 4. For "Agent object name", enter: POWERPOINT_GENERATOR
-- 5. For "Display name", enter: PowerPoint Generator
-- 6. For "Description", enter:
--    "Generates professional PowerPoint presentations for accounts. 
--     Provide an account ID (e.g., ACC001) to create a presentation."
-- 7. Select "Create agent"
-- 8. After creation, select the agent and click "Edit"
-- 9. Select "Tools" tab
-- 10. Select "Add custom tool"
-- 11. For "Custom tool name", enter: generate_powerpoint
-- 12. For "Custom tool identifier", select: POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT
-- 13. For "Warehouse", select: REPORTING_WH
-- 14. For "Description", enter:
--     "Generates a PowerPoint presentation for the specified account ID.
--      Parameter: ACCOUNT_ID_INPUT (VARCHAR) - The account ID to generate presentation for (e.g., 'ACC001')"
-- 15. Verify parameters are correct:
--     - Name: ACCOUNT_ID_INPUT
--     - Type: VARCHAR
--     - Description: The account ID to generate the PowerPoint for
--     - Required: Yes
-- 16. Select "Add"
-- 17. Select "Orchestration" tab
-- 18. For "Planning instructions", enter:
--     "When users ask to create, generate, or make a PowerPoint presentation,
--      use the generate_powerpoint tool with the provided account ID.
--      Always ask for the account ID if not provided."
-- 19. Select "Access" tab
-- 20. Add SNOWFLAKE_INTELLIGENCE_RL role (and any other authorized roles)
-- 21. Select "Save"

-- NOTE: Only users with SNOWFLAKE_INTELLIGENCE_RL role will be able to use the agent

-- ============================================================================
-- Step 7: Sample Agent Prompts
-- ============================================================================

-- Users with SNOWFLAKE_INTELLIGENCE_RL role can interact with the agent using prompts like:
-- 
-- "Create a PowerPoint for account ACC001"
-- "Generate a presentation for ACC002"
-- "Make me a PowerPoint for Acme Corporation (ACC001)"
-- "Show me account ACC003 as a PowerPoint"
--
-- IMPORTANT: Users must have:
-- 1. SNOWFLAKE_INTELLIGENCE_RL role granted to them
-- 2. SNOWFLAKE_INTELLIGENCE_RL set as their default role (or using it actively)

-- ============================================================================
-- Step 8: Troubleshooting
-- ============================================================================

-- If users get "permission denied" errors, verify:

-- 1. Check user's current role and warehouse
SELECT 
    'User Default Role' AS CHECK_TYPE,
    CURRENT_ROLE() AS CURRENT_VALUE
UNION ALL
SELECT 
    'User Default Warehouse',
    CURRENT_WAREHOUSE();

-- 2. Verify user has SNOWFLAKE_INTELLIGENCE_RL role
SHOW GRANTS TO USER <username>;

-- 3. Check if SNOWFLAKE_INTELLIGENCE_RL role has required permissions
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- 4. If user doesn't have the role, grant it:
-- GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;

-- 5. Set as default role (recommended):
-- ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

-- Check if stage has correct encryption
DESC STAGE POWERPOINT_DB.REPORTING.PPT_STAGE;
-- Should show: encryption_type = SNOWFLAKE_SSE

-- ============================================================================
-- Step 9: Monitor Agent Usage
-- ============================================================================

-- To view agent feedback and usage:
-- 1. Grant the AI_OBSERVABILITY_EVENTS_LOOKUP application role
-- 2. Grant MONITOR privileges on the agent
-- 3. Run the following query:

-- SELECT * 
-- FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_OBSERVABILITY_EVENTS(
--     'snowflake_intelligence', 
--     'agents', 
--     'POWERPOINT_GENERATOR', 
--     'CORTEX AGENT'
-- )) 
-- WHERE RECORD:name='CORTEX_AGENT_FEEDBACK';

SELECT 'Snowflake Intelligence integration setup complete!' AS STATUS;
SELECT 'Next: Create agent in Snowsight (AI & ML » Agents)' AS NEXT_STEP;

