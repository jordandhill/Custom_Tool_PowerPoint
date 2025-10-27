# Quick Debugging Reference

Fast troubleshooting guide for PowerPoint generation issues.

## 🚨 Getting File Stream Errors?

### Quick Test (2 minutes)

```sql
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;
USE WAREHOUSE REPORTING_WH;
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- Run all 4 diagnostic tests
CALL TEST_STAGE_ACCESS();
CALL TEST_FILE_OPERATIONS();
CALL TEST_POWERPOINT_LIBRARY();
CALL TEST_COMPLETE_WORKFLOW('ACC001');
```

**Look for**: Any "✗ FAILED" messages

### Most Common Issues

#### 1. Stage Permission Missing
```sql
-- Check if you have WRITE permission
SHOW GRANTS ON STAGE PPT_STAGE;

-- If WRITE is missing, grant it:
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE 
    TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

#### 2. Wrong Role
```sql
-- Check your current role
SELECT CURRENT_ROLE();

-- Should be: SNOWFLAKE_INTELLIGENCE_RL
-- If not, switch:
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Or set as default:
ALTER USER <your_username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
```

#### 3. File I/O Issues
```sql
-- Run file operations test
CALL TEST_FILE_OPERATIONS();

-- Look for which step fails:
-- ✗ Create temp file: FAILED
-- ✗ Write to file: FAILED
-- ✗ Upload to stage: FAILED
```

## 🔍 Debug Mode

### Run Debug Version
```sql
-- Use debug version instead of regular procedure
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');

-- Check the logs
SELECT 
    LOG_TIMESTAMP,
    LOG_LEVEL,
    LOG_MESSAGE,
    ERROR_DETAILS
FROM DEBUG_LOGS
WHERE ACCOUNT_ID = 'ACC001'
ORDER BY LOG_TIMESTAMP DESC;
```

### View Recent Logs
```sql
-- Last 20 log entries
SELECT * FROM DEBUG_LOGS 
ORDER BY LOG_TIMESTAMP DESC 
LIMIT 20;

-- Only errors
SELECT * FROM DEBUG_LOGS 
WHERE LOG_LEVEL IN ('ERROR', 'CRITICAL')
ORDER BY LOG_TIMESTAMP DESC;
```

## 🤖 Agent-Specific Issues

### Works directly but fails through Snowflake Intelligence?

**Test 1**: Run debug version directly
```sql
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');
```

**Test 2**: Update agent to use debug procedure
1. Edit agent in Snowsight
2. Change custom tool to `GENERATE_ACCOUNT_POWERPOINT_DEBUG`
3. Ask agent to generate PowerPoint
4. Check DEBUG_LOGS table

**Compare**: Direct vs. Agent execution logs

### Common Agent Issues

1. **User's default role not set**
   ```sql
   ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
   ```

2. **Agent timeout too short**
   - Edit agent → Tools → increase "Query timeout"

3. **Warehouse not specified**
   - Edit agent → Tools → select REPORTING_WH

## 📊 Quick Diagnostics

### One-Command Check
```sql
-- Check everything at once
SELECT 
    'Role' AS check_type, 
    CURRENT_ROLE() AS value
UNION ALL
SELECT 'Warehouse', CURRENT_WAREHOUSE()
UNION ALL
SELECT 'Database', CURRENT_DATABASE()
UNION ALL
SELECT 'Schema', CURRENT_SCHEMA();

-- Check stage
DESC STAGE PPT_STAGE;

-- Check permissions
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

### Test Specific Component

**Stage Only**:
```sql
CALL TEST_STAGE_ACCESS();
```

**Files Only**:
```sql
CALL TEST_FILE_OPERATIONS();
```

**PowerPoint Library Only**:
```sql
CALL TEST_POWERPOINT_LIBRARY();
```

**Full Workflow**:
```sql
CALL TEST_COMPLETE_WORKFLOW('ACC001');
```

## 🧹 Clean Up After Debugging

```sql
-- Remove test files from stage
LIST @PPT_STAGE PATTERN='.*TEST_.*';
REMOVE @PPT_STAGE PATTERN='.*TEST_.*';

-- Clear old debug logs
DELETE FROM DEBUG_LOGS 
WHERE LOG_TIMESTAMP < DATEADD(day, -7, CURRENT_TIMESTAMP());
```

## 📞 Still Stuck?

Collect this information:

```sql
-- 1. Run all diagnostics
CALL TEST_STAGE_ACCESS();
CALL TEST_FILE_OPERATIONS();
CALL TEST_POWERPOINT_LIBRARY();
CALL TEST_COMPLETE_WORKFLOW('ACC001');

-- 2. Run debug version
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');

-- 3. Get debug logs
SELECT * FROM DEBUG_LOGS 
WHERE ACCOUNT_ID = 'ACC001' 
ORDER BY LOG_TIMESTAMP DESC;

-- 4. Get permissions
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
SHOW GRANTS ON STAGE PPT_STAGE;

-- 5. Get context
SELECT 
    CURRENT_ROLE(),
    CURRENT_WAREHOUSE(),
    CURRENT_DATABASE(),
    CURRENT_SCHEMA(),
    CURRENT_USER();
```

Then check **DEBUGGING_GUIDE.md** for detailed solutions.

---

## Quick Commands

| Command | Purpose |
|---------|---------|
| `CALL TEST_STAGE_ACCESS()` | Test stage permissions |
| `CALL TEST_FILE_OPERATIONS()` | Test file I/O |
| `CALL TEST_POWERPOINT_LIBRARY()` | Test python-pptx |
| `CALL TEST_COMPLETE_WORKFLOW('ACC001')` | Test end-to-end |
| `CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001')` | Run with logging |
| `SELECT * FROM DEBUG_LOGS ORDER BY LOG_TIMESTAMP DESC` | View logs |

---

**See**: DEBUGGING_GUIDE.md for comprehensive troubleshooting


