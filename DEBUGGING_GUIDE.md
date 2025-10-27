# Debugging Guide for PowerPoint Generation

This guide helps diagnose and fix issues when calling the PowerPoint generation procedure, especially from Snowflake Intelligence agents.

## Common Issue: File Stream Errors

File stream errors typically occur when:
1. The procedure cannot access the temporary directory
2. Stage WRITE permissions are missing or insufficient
3. File I/O operations are blocked in the execution environment
4. The agent's execution context differs from direct procedure calls

## Debugging Tools

We've created several tools to help identify the issue:

### 1. Debug Version of Main Procedure

**File**: `create_powerpoint_procedure_debug.sql`

This creates `GENERATE_ACCOUNT_POWERPOINT_DEBUG` which logs every step to a `DEBUG_LOGS` table.

```sql
-- Run the debug version
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');

-- View the logs
SELECT * FROM DEBUG_LOGS 
WHERE ACCOUNT_ID = 'ACC001' 
ORDER BY LOG_TIMESTAMP DESC;
```

The debug version tests:
- Python environment and version
- Temp directory access and write permissions
- Stage LIST permission
- Account data query
- PowerPoint creation in memory
- File save to temp directory
- Stage upload operation
- File verification in stage
- Temp file cleanup
- Pre-signed URL generation

### 2. Individual Diagnostic Procedures

**File**: `diagnostic_procedures.sql`

Four specialized procedures to test individual components:

#### Test 1: Stage Access
```sql
CALL TEST_STAGE_ACCESS();
```
Tests:
- LIST permission on stage
- DESCRIBE stage
- Current role
- Stage grants

#### Test 2: File Operations
```sql
CALL TEST_FILE_OPERATIONS();
```
Tests:
- Temp directory access
- File creation
- File write/read
- File size check
- Upload to stage
- File verification in stage

#### Test 3: PowerPoint Library
```sql
CALL TEST_POWERPOINT_LIBRARY();
```
Tests:
- python-pptx library import
- Presentation creation
- Slide addition
- File save
- Upload to stage

#### Test 4: Complete Workflow
```sql
CALL TEST_COMPLETE_WORKFLOW('ACC001');
```
Tests the entire workflow end-to-end with detailed step-by-step output.

## Debugging Steps

### Step 1: Run Direct Tests

Test the procedures directly (not through Snowflake Intelligence):

```sql
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;
USE WAREHOUSE REPORTING_WH;
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- Test 1: Stage access
CALL TEST_STAGE_ACCESS();

-- Test 2: File operations
CALL TEST_FILE_OPERATIONS();

-- Test 3: PowerPoint library
CALL TEST_POWERPOINT_LIBRARY();

-- Test 4: Complete workflow
CALL TEST_COMPLETE_WORKFLOW('ACC001');
```

**Expected Result**: All tests should return "✓ SUCCESS" messages.

### Step 2: Run Debug Version Directly

```sql
-- Run debug version
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');

-- Check logs
SELECT 
    LOG_TIMESTAMP,
    LOG_LEVEL,
    LOG_MESSAGE,
    ERROR_DETAILS
FROM DEBUG_LOGS
WHERE ACCOUNT_ID = 'ACC001'
ORDER BY LOG_TIMESTAMP DESC;
```

### Step 3: Test Through Snowflake Intelligence Agent

Configure the agent to use the debug procedure instead:

1. Edit your Snowflake Intelligence agent
2. Change the custom tool to use `GENERATE_ACCOUNT_POWERPOINT_DEBUG` instead
3. Ask the agent to generate a PowerPoint
4. Check the DEBUG_LOGS table to see where it failed

### Step 4: Compare Results

Compare the logs from direct execution vs. agent execution to identify differences.

## Common Issues and Solutions

### Issue 1: "Cannot write to temp directory"

**Symptoms**: File stream errors, temp directory access denied

**Diagnosis**:
```sql
CALL TEST_FILE_OPERATIONS();
-- Look for: "✗ Create temp file: FAILED"
```

**Solutions**:
- Check if the execution environment has restricted file I/O
- Try using a different temporary directory approach
- Verify Python runtime permissions

### Issue 2: "Stage does not exist or not authorized"

**Symptoms**: Cannot upload files to stage

**Diagnosis**:
```sql
CALL TEST_STAGE_ACCESS();
-- Look for: "✗ LIST permission: FAILED"
```

**Solutions**:
```sql
-- Verify role has WRITE permission
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Grant if missing
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE 
    TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

### Issue 3: "File not found after save"

**Symptoms**: File save appears successful but file doesn't exist

**Diagnosis**:
```sql
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');
-- Look for: "File saved: FAILED - File not found after save"
```

**Solutions**:
- Check disk space in execution environment
- Verify Python has write permissions
- Try alternative file save approach

### Issue 4: Agent-Specific Failures

**Symptoms**: Works directly but fails through Snowflake Intelligence

**Diagnosis**: Compare logs from both executions

**Possible Causes**:
1. **Different execution context**: Agents may run in a more restricted environment
2. **Timeout issues**: Agent may have shorter timeout limits
3. **Resource limits**: Agent execution may have stricter memory/CPU limits
4. **Role context**: Agent might not be using the expected role

**Solutions**:
```sql
-- Check agent configuration
-- Ensure it specifies:
-- - Warehouse: REPORTING_WH
-- - Timeout: Sufficient (e.g., 300 seconds)
-- - Role access: SNOWFLAKE_INTELLIGENCE_RL

-- Verify user's default role
SELECT CURRENT_ROLE();

-- Set default role if needed
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
```

## Workaround: Simplified Version

If file stream errors persist, create a simplified version that uses in-memory operations:

```sql
-- This is a placeholder for a potential workaround
-- that avoids temp file operations
-- (Would need custom implementation based on specific error)
```

## Collecting Diagnostic Information

To get comprehensive diagnostic information:

```sql
-- Run all diagnostics
CALL TEST_STAGE_ACCESS();
CALL TEST_FILE_OPERATIONS();
CALL TEST_POWERPOINT_LIBRARY();
CALL TEST_COMPLETE_WORKFLOW('ACC001');

-- Run debug version
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');

-- Collect all results
SELECT * FROM DEBUG_LOGS 
WHERE LOG_TIMESTAMP >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
ORDER BY LOG_TIMESTAMP DESC;

-- Check grants
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
SHOW GRANTS ON STAGE PPT_STAGE;

-- Check current context
SELECT 
    CURRENT_ROLE() AS role,
    CURRENT_WAREHOUSE() AS warehouse,
    CURRENT_DATABASE() AS database,
    CURRENT_SCHEMA() AS schema;
```

## Advanced Debugging

### Enable Python Logging

Add more detailed Python logging:

```python
import sys
import io

# Capture stderr
old_stderr = sys.stderr
sys.stderr = io.StringIO()

try:
    # Your code here
    pass
except Exception as e:
    error_output = sys.stderr.getvalue()
    # Log error_output
finally:
    sys.stderr = old_stderr
```

### Check Environment Variables

```python
import os
env_info = {
    'HOME': os.environ.get('HOME', 'Not set'),
    'TMPDIR': os.environ.get('TMPDIR', 'Not set'),
    'TMP': os.environ.get('TMP', 'Not set'),
    'TEMP': os.environ.get('TEMP', 'Not set')
}
```

## Getting Help

When reporting issues, include:

1. Output from all diagnostic procedures
2. DEBUG_LOGS table contents
3. Role grants (SHOW GRANTS)
4. Whether it works directly but fails through agent
5. Exact error message
6. Snowflake account region and cloud provider

## Clean Up

After debugging:

```sql
-- Clean up test files from stage
LIST @PPT_STAGE PATTERN='.*TEST_.*';
REMOVE @PPT_STAGE PATTERN='.*TEST_.*';

-- Clean up debug logs (optional)
TRUNCATE TABLE DEBUG_LOGS;

-- Or delete old logs
DELETE FROM DEBUG_LOGS 
WHERE LOG_TIMESTAMP < DATEADD(day, -7, CURRENT_TIMESTAMP());
```

## Quick Reference

```sql
-- Debug version
CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');
SELECT * FROM DEBUG_LOGS WHERE ACCOUNT_ID = 'ACC001' ORDER BY LOG_TIMESTAMP DESC;

-- Diagnostic tests
CALL TEST_STAGE_ACCESS();
CALL TEST_FILE_OPERATIONS();
CALL TEST_POWERPOINT_LIBRARY();
CALL TEST_COMPLETE_WORKFLOW('ACC001');

-- Check permissions
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Check context
SELECT CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE();
```

---

**Last Updated**: 2024-10-27  
**Version**: 1.0.6


