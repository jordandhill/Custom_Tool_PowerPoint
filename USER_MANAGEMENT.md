# User Management Guide

This guide explains how to manage user access to the PowerPoint generation system using the `SNOWFLAKE_INTELLIGENCE_RL` role.

## Overview

Access to PowerPoint generation is controlled by the `SNOWFLAKE_INTELLIGENCE_RL` role, which is automatically created during setup. Only users with this role can:
- Use Snowflake Intelligence agents to generate PowerPoints
- Access the Streamlit app for PowerPoint generation
- Directly call the `GENERATE_ACCOUNT_POWERPOINT` stored procedure

## Granting Access to Users

### Individual User Access

To grant access to a specific user:

```sql
-- Grant the role to the user
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER john_doe;

-- Set as their default role (recommended for primary users)
ALTER USER john_doe SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

-- Set default warehouse
ALTER USER john_doe SET DEFAULT_WAREHOUSE = REPORTING_WH;
```

### Multiple Users

Grant access to multiple users:

```sql
-- Grant to multiple users
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER john_doe;
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER jane_smith;
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER bob_johnson;
```

### Role Hierarchy

Grant to another role (all users with that role get access):

```sql
-- Grant to a parent role
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE DATA_ANALYST_ROLE;

-- Now all users with DATA_ANALYST_ROLE can generate PowerPoints
```

## Verifying User Access

### Check If User Has the Role

```sql
-- Check grants for a specific user
SHOW GRANTS TO USER john_doe;

-- Or filter for specific role
SHOW GRANTS TO USER john_doe;
-- Look for SNOWFLAKE_INTELLIGENCE_RL in the results
```

### List All Users with Access

```sql
-- Show all users who have the role
SHOW GRANTS OF ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

### Check Role Permissions

```sql
-- Verify role has all required permissions
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Should show grants on:
-- - POWERPOINT_DB (USAGE)
-- - POWERPOINT_DB.REPORTING (USAGE)
-- - PPT_STAGE (READ, WRITE)
-- - REPORTING_WH (USAGE)
-- - ACCOUNTS table (SELECT)
-- - GENERATE_ACCOUNT_POWERPOINT procedure (USAGE)
```

## Revoking Access

### Remove Access from a User

```sql
-- Revoke the role from a user
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER john_doe;
```

### Remove Access from Multiple Users

```sql
-- Revoke from multiple users
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER john_doe;
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER jane_smith;
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER bob_johnson;
```

### Remove Role from Parent Role

```sql
-- Revoke from parent role (affects all users with that parent role)
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM ROLE DATA_ANALYST_ROLE;
```

## User Self-Service Commands

### User Checks Their Own Access

Users can verify their own access:

```sql
-- Check current role
SELECT CURRENT_ROLE();

-- Check available roles
SHOW ROLES;

-- Switch to the role (if granted)
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Test access
CALL POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT('ACC001');
```

### User Switches Roles

```sql
-- Switch to the PowerPoint generation role
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Switch back to another role
USE ROLE DATA_ANALYST_ROLE;
```

## Common User Management Scenarios

### Scenario 1: Onboarding a New User

```sql
-- 1. Create user (if not exists)
CREATE USER IF NOT EXISTS new_employee
    PASSWORD = 'SecurePassword123!'
    DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL
    DEFAULT_WAREHOUSE = REPORTING_WH
    MUST_CHANGE_PASSWORD = TRUE;

-- 2. Grant the PowerPoint generation role
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER new_employee;

-- 3. Notify user of their credentials and access
```

### Scenario 2: Temporary Access

```sql
-- Grant temporary access (document the expiration date)
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER temp_contractor;

-- Later, revoke when no longer needed
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER temp_contractor;
```

### Scenario 3: Department-Wide Access

```sql
-- Create department role if not exists
CREATE ROLE IF NOT EXISTS MARKETING_DEPT;

-- Grant PowerPoint generation role to department role
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE MARKETING_DEPT;

-- Grant department role to all department users
GRANT ROLE MARKETING_DEPT TO USER marketing_user1;
GRANT ROLE MARKETING_DEPT TO USER marketing_user2;
GRANT ROLE MARKETING_DEPT TO USER marketing_user3;
```

### Scenario 4: Read-Only Access

If you want to give users ability to download existing PowerPoints but not create new ones:

```sql
-- Create a read-only role
CREATE ROLE IF NOT EXISTS POWERPOINT_READONLY;

-- Grant only READ permission on stage
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE POWERPOINT_READONLY;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE POWERPOINT_READONLY;
GRANT READ ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE TO ROLE POWERPOINT_READONLY;

-- Grant to users
GRANT ROLE POWERPOINT_READONLY TO USER viewer_user;
```

## Troubleshooting User Access Issues

### Issue: User Can't Generate PowerPoints

**Check 1**: Verify user has the role
```sql
SHOW GRANTS TO USER <username>;
```

**Solution**: Grant the role
```sql
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;
```

---

**Check 2**: Verify user is using the correct role
```sql
-- As the user, run:
SELECT CURRENT_ROLE();
```

**Solution**: Switch to the role
```sql
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

---

**Check 3**: Verify role has permissions
```sql
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

**Solution**: Re-run setup script if permissions are missing

---

### Issue: Snowflake Intelligence Agent Fails

**Cause**: Agent uses user's default role

**Solution**: Set SNOWFLAKE_INTELLIGENCE_RL as default role
```sql
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
```

---

### Issue: "Stage Does Not Exist" Error

**Cause**: Missing WRITE permission on stage

**Solution**: Verify role permissions
```sql
SHOW GRANTS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
-- Should show: WRITE on PPT_STAGE

-- If missing, grant it:
GRANT READ, WRITE ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE 
    TO ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

## Best Practices

### 1. Use Default Role

Set `SNOWFLAKE_INTELLIGENCE_RL` as the default role for primary PowerPoint users:
```sql
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
```

### 2. Document Access

Maintain a list of users with access:
```sql
-- Create a view for easy tracking
CREATE OR REPLACE VIEW ADMIN.USER_ACCESS_AUDIT AS
SELECT 
    grantee_name AS username,
    role,
    granted_on,
    granted_by,
    created_on
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
WHERE role = 'SNOWFLAKE_INTELLIGENCE_RL'
    AND deleted_on IS NULL;
```

### 3. Regular Access Reviews

Periodically review who has access:
```sql
-- Monthly access review
SHOW GRANTS OF ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

### 4. Use Role Hierarchy

For enterprise deployments, use role hierarchy:
```sql
-- Create department roles
CREATE ROLE SALES_DEPT;
CREATE ROLE MARKETING_DEPT;

-- Grant PowerPoint role to department roles
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE SALES_DEPT;
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE MARKETING_DEPT;

-- Grant department roles to users
GRANT ROLE SALES_DEPT TO USER sales_user1;
GRANT ROLE MARKETING_DEPT TO USER marketing_user1;
```

### 5. Audit Trail

Track PowerPoint generation activity:
```sql
-- Query to see who's generating PowerPoints
SELECT 
    user_name,
    role_name,
    query_text,
    start_time,
    end_time,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%GENERATE_ACCOUNT_POWERPOINT%'
    AND start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;
```

## Security Considerations

### Never Grant to PUBLIC

❌ **NEVER DO THIS:**
```sql
-- This would give ALL users access
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO ROLE PUBLIC;
```

### Principle of Least Privilege

✅ **DO THIS:**
- Only grant access to users who need it
- Use role hierarchy for department-level access
- Regularly review and revoke unnecessary access
- Monitor usage for anomalies

### Password and MFA

Ensure users with PowerPoint generation access have:
- Strong passwords
- Multi-factor authentication (MFA) enabled
- Regular password rotation

```sql
-- Enforce MFA for sensitive roles
ALTER ACCOUNT SET MFA_REQUIRE = TRUE;
```

## Quick Reference

### Common Commands

```sql
-- Grant access
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;

-- Revoke access
REVOKE ROLE SNOWFLAKE_INTELLIGENCE_RL FROM USER <username>;

-- List users with access
SHOW GRANTS OF ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Check user's grants
SHOW GRANTS TO USER <username>;

-- Set default role
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;

-- Check current role
SELECT CURRENT_ROLE();

-- Switch role
USE ROLE SNOWFLAKE_INTELLIGENCE_RL;
```

## Support

For user access issues:
1. Verify user has the role
2. Check user's default role setting
3. Verify role has all permissions
4. Review audit logs for errors
5. Contact Snowflake administrator

---

**Last Updated**: 2024-10-27  
**Version**: 1.0.6

