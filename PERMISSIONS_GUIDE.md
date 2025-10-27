# Permissions Guide for PowerPoint Generator

This guide explains all the permissions required for different users and integrations to use the PowerPoint generation system.

## Overview

The PowerPoint generation system requires specific permissions to:
1. Read account data from the `ACCOUNTS` table
2. Execute the `GENERATE_ACCOUNT_POWERPOINT` stored procedure
3. Write PowerPoint files to the `PPT_STAGE` internal stage
4. Use the `REPORTING_WH` warehouse for computation

## Permission Matrix

| Object | Permission | Required For |
|--------|-----------|--------------|
| `POWERPOINT_DB` database | USAGE | All users, agents, and Streamlit apps |
| `POWERPOINT_DB.REPORTING` schema | USAGE | All users, agents, and Streamlit apps |
| `PPT_STAGE` stage | READ, WRITE | **Critical for file generation** |
| `REPORTING_WH` warehouse | USAGE | Query execution |
| `ACCOUNTS` table | SELECT | Reading account data |
| `GENERATE_ACCOUNT_POWERPOINT` procedure | USAGE | Executing the procedure |

## Snowflake Intelligence Agents

According to the [Snowflake Intelligence documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence):

> **All of the queries from Snowflake Intelligence use the user's credentials. All role-based access control and data-masking policies associated with the user automatically apply to all interactions and conversations with the agent.**

### Key Points for Agents

1. **Agents use the user's default role**
   - Each user must have a default role set
   - The default role must have all required permissions

2. **Agents use the user's default warehouse**
   - Each user must have a default warehouse set
   - Alternatively, specify the warehouse when configuring the custom tool

3. **Stage WRITE permission is critical**
   - Without WRITE permission on the stage, the stored procedure cannot save PowerPoint files
   - This is the most commonly missed permission

### Setting Up Permissions for Agents

The PowerPoint generation system uses a dedicated role: `SNOWFLAKE_INTELLIGENCE_RL`

This role is automatically created by `setup_snowflake_objects.sql` with all necessary permissions:

```sql
-- The role is created with all required permissions
CREATE ROLE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_RL;

-- All permissions are granted to this role
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT SELECT ON TABLE POWERPOINT_DB.REPORTING.ACCOUNTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
GRANT USAGE ON PROCEDURE POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT(VARCHAR) TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

**Important**: Only users granted the `SNOWFLAKE_INTELLIGENCE_RL` role can use the PowerPoint generation feature.

### Granting Access to Users

To grant PowerPoint generation access to specific users:

```sql
-- Grant the role to a user
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER john_doe;

-- Set it as their default role (recommended)
ALTER USER john_doe SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

-- Set default warehouse
ALTER USER john_doe SET DEFAULT_WAREHOUSE = REPORTING_WH;
```

### Verifying User Access

```sql
-- Check if user has the role
SHOW GRANTS TO USER john_doe;

-- Check current user settings
SELECT CURRENT_ROLE() AS default_role;
SELECT CURRENT_WAREHOUSE() AS default_warehouse;

-- Check what users have the role
SHOW GRANTS OF ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

## Streamlit Apps

Streamlit apps in Snowflake use the same permission model as Snowflake Intelligence agents.

### Requirements

1. **Same permissions as agents** (see above)
2. **Warehouse assignment** when deploying the Streamlit app
3. **App owner's role** must have permissions, or use caller's rights

### Deployment Checklist

- [ ] Grant USAGE on database to app users' roles
- [ ] Grant USAGE on schema to app users' roles
- [ ] Grant READ, WRITE on stage to app users' roles (critical!)
- [ ] Grant USAGE on warehouse to app users' roles
- [ ] Grant SELECT on ACCOUNTS table to app users' roles
- [ ] Grant USAGE on procedure to app users' roles
- [ ] Select REPORTING_WH as the app warehouse
- [ ] Test with a user who has the appropriate role

## Stored Procedure Execution Rights

The `GENERATE_ACCOUNT_POWERPOINT` procedure uses **CALLER'S RIGHTS** (default).

### What This Means

```sql
CREATE OR REPLACE PROCEDURE GENERATE_ACCOUNT_POWERPOINT(...)
...
EXECUTE AS CALLER  -- Uses the calling user's permissions
```

**Implications:**
- The procedure runs with the permissions of the user calling it
- Each user must have direct permissions on all objects
- More secure as it respects role-based access control
- Data masking policies apply automatically

### Alternative: Owner's Rights

If you want the procedure to run with the owner's permissions:

```sql
CREATE OR REPLACE PROCEDURE GENERATE_ACCOUNT_POWERPOINT(...)
...
EXECUTE AS OWNER  -- Uses the procedure owner's permissions
```

**Implications:**
- Only the procedure owner needs permissions on objects
- Users only need USAGE permission on the procedure
- Less secure as it bypasses role-based access control
- Useful for centralized access control

## Common Permission Issues

### Issue 1: "Stage does not exist or not authorized"

**Cause:** Missing WRITE permission on stage

**Solution:**
```sql
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE <role>;
```

### Issue 2: "Insufficient privileges to operate on warehouse"

**Cause:** Missing USAGE permission on warehouse

**Solution:**
```sql
GRANT USAGE ON WAREHOUSE REPORTING_WH TO ROLE <role>;
```

### Issue 3: "Object does not exist or not authorized" (procedure)

**Cause:** Missing USAGE permission on procedure

**Solution:**
```sql
GRANT USAGE ON PROCEDURE POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT(VARCHAR) TO ROLE <role>;
```

### Issue 4: "SQL compilation error: Object 'ACCOUNTS' does not exist"

**Cause:** Missing SELECT permission on table or missing USAGE on database/schema

**Solution:**
```sql
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE <role>;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE <role>;
GRANT SELECT ON TABLE POWERPOINT_DB.REPORTING.ACCOUNTS TO ROLE <role>;
```

## Verification Script

Run this script to verify all permissions for a specific role:

```sql
-- Set the role to check
SET role_to_check = 'PUBLIC';

-- Check database permissions
SHOW GRANTS TO ROLE IDENTIFIER($role_to_check);

-- Verify specific objects
SELECT 
    'Database' AS object_type,
    COUNT(*) AS has_permission
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "granted_on" = 'DATABASE' 
  AND "name" = 'POWERPOINT_DB'
  AND "privilege" = 'USAGE';

-- Verify stage permissions (most critical)
SELECT 
    'Stage - WRITE' AS permission_check,
    COUNT(*) AS has_permission
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1)))
WHERE "granted_on" = 'STAGE' 
  AND "name" = 'POWERPOINT_DB.REPORTING.PPT_STAGE'
  AND "privilege" = 'WRITE';

SELECT 
    'Stage - READ' AS permission_check,
    COUNT(*) AS has_permission
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-2)))
WHERE "granted_on" = 'STAGE' 
  AND "name" = 'POWERPOINT_DB.REPORTING.PPT_STAGE'
  AND "privilege" = 'READ';
```

## Security Best Practices

### 1. Use Dedicated Role (Already Implemented)

The system uses `SNOWFLAKE_INTELLIGENCE_RL` role for access control:

```sql
-- The role is automatically created by setup_snowflake_objects.sql
-- Grant it to specific users:
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER john_doe;
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER jane_smith;

-- Or grant to another role (role hierarchy):
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE DATA_ANALYST_ROLE;

-- Never grant to PUBLIC (security risk):
-- ❌ GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE PUBLIC;
```

### 2. Limit Stage Access

```sql
-- Only grant WRITE to roles that need to generate PowerPoints
-- Grant READ for roles that only need to download existing files
GRANT READ ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE READ_ONLY_ROLE;
```

### 3. Use Resource Monitors

```sql
-- Create resource monitor for cost control
CREATE RESOURCE MONITOR powerpoint_generation_monitor
  WITH CREDIT_QUOTA = 100
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND
    ON 110 PERCENT DO SUSPEND_IMMEDIATE;

-- Assign to warehouse
ALTER WAREHOUSE REPORTING_WH SET RESOURCE_MONITOR = powerpoint_generation_monitor;
```

### 4. Audit Usage

```sql
-- Monitor who is generating PowerPoints
SELECT 
    query_text,
    user_name,
    role_name,
    warehouse_name,
    start_time,
    end_time,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%GENERATE_ACCOUNT_POWERPOINT%'
  AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;
```

## Quick Reference

### Grant Access to a User

```sql
-- Grant the SNOWFLAKE_INTELLIGENCE_RL role to a user
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;

-- Set as default role (recommended)
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

-- Set default warehouse
ALTER USER <username> SET DEFAULT_WAREHOUSE = REPORTING_WH;
```

### Check Your Access

```sql
-- Check if you have the role
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Should succeed if you have access
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
SELECT * FROM ACCOUNTS LIMIT 1;
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');
```

### Revoke Access from a User

```sql
-- Revoke the role from a user
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER <username>;
```

## Support

For permission-related issues:

1. Verify role and warehouse settings
2. Run the verification script above
3. Check for common permission issues
4. Review security best practices
5. Contact your Snowflake administrator

---

**References:**
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence)
- [Snowflake Access Control](https://docs.snowflake.com/en/user-guide/security-access-control)
- [Understanding Caller's Rights and Owner's Rights](https://docs.snowflake.com/en/sql-reference/stored-procedures-rights)

