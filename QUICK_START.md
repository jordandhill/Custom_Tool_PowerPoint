# Quick Start Guide

Get up and running with PowerPoint generation in Snowflake in 5 minutes.

## Step 1: Run Setup (2 minutes)

Execute in Snowflake:

```sql
-- Copy and paste contents of setup_snowflake_objects.sql
-- This creates database, schema, stage (with SNOWFLAKE_SSE encryption), and sample data
```

**Important**: If you previously created the stage without `SNOWFLAKE_SSE` encryption, run `fix_existing_stage.sql` to recreate it properly.

## Step 2: Create Procedure (1 minute)

Execute in Snowflake:

```sql
-- Copy and paste contents of create_powerpoint_procedure.sql
-- This creates the GENERATE_ACCOUNT_POWERPOINT stored procedure
```

## Step 3: Generate Your First PowerPoint (1 minute)

```sql
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;

-- View available accounts
SELECT * FROM ACCOUNTS;

-- Generate PowerPoint for account ACC001
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');
```

## Step 4: Download

Copy the pre-signed URL from the result and paste it in your browser to download the PowerPoint.

## That's it!

You now have a working PowerPoint generation system in Snowflake.

---

## Quick Reference

### Generate PowerPoint
```sql
CALL GENERATE_ACCOUNT_POWERPOINT('YOUR_ACCOUNT_ID');
```

### List Generated Files
```sql
LIST @PPT_STAGE;
```

### Get Pre-signed URL for Existing File
```sql
SELECT GET_PRESIGNED_URL(@PPT_STAGE, 'filename.pptx', 86400);
```

### View All Accounts
```sql
SELECT * FROM ACCOUNTS;
```

---

## Execution Order

1. `setup_snowflake_objects.sql` - Creates all database objects
2. `create_powerpoint_procedure.sql` - Creates the stored procedure
3. `example_usage.sql` - Examples of how to use the procedure

---

## File Structure

```
Custom_Tool_PowerPoint/
├── README.md                          # Full documentation
├── QUICK_START.md                     # This file
├── setup_snowflake_objects.sql        # Step 1: Database setup
├── create_powerpoint_procedure.sql    # Step 2: Procedure creation
├── example_usage.sql                  # Step 3: Usage examples
├── fix_existing_stage.sql             # Fix for existing stages (if needed)
├── IMMEDIATE_FIX.md                   # Troubleshooting guide
├── TROUBLESHOOTING_FILE_CORRUPTION.md # Detailed corruption fixes
└── DEPLOYMENT_CHECKLIST.md            # Production deployment guide
```

---

## Common Commands

### Set Context
```sql
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;
```

### Add New Account
```sql
INSERT INTO ACCOUNTS (ACCOUNT_ID, ACCOUNT_NAME, ACCOUNT_TYPE, REVENUE, EMPLOYEES, INDUSTRY, CREATED_DATE)
VALUES ('ACC005', 'New Company', 'Enterprise', 10000000.00, 1000, 'Technology', CURRENT_DATE());
```

### Clean Up Old Files
```sql
-- List files first
LIST @PPT_STAGE;

-- Remove specific file
REMOVE @PPT_STAGE/account_ACC001_20241027_120000.pptx;
```

---

## Need Help?

See the full [README.md](README.md) for:
- Detailed architecture
- Customization guide
- Troubleshooting
- Security considerations
- Advanced usage examples

