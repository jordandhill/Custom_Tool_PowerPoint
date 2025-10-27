# Quick Start Guide

Get up and running with PowerPoint generation in Snowflake in 5 minutes.

## Step 1: Run Setup (2 minutes)

Execute in Snowflake:

```sql
-- Copy and paste contents of setup_snowflake_objects.sql
-- This creates database, schema, stage (with SNOWFLAKE_SSE encryption), and sample data
```

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
├── README.md                               # Full documentation
├── QUICK_START.md                          # This file
├── setup_snowflake_objects.sql             # Step 1: Database setup
├── create_powerpoint_procedure.sql         # Step 2: Procedure creation
├── example_usage.sql                       # Step 3: Usage examples
├── snowflake_intelligence_integration.sql  # Snowflake Intelligence agent setup
├── streamlit_integration.py                # Streamlit app for UI
└── PERMISSIONS_GUIDE.md                    # Complete permissions reference
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

## Advanced Integration

### Snowflake Intelligence Agents
Run `snowflake_intelligence_integration.sql` to:
- Set up agent permissions
- Create Snowflake Intelligence database structure
- Get step-by-step instructions for adding as custom tool

### Streamlit App
Deploy `streamlit_integration.py` to Snowflake for:
- User-friendly UI
- Account selection dropdown
- One-click PowerPoint generation
- Automatic download links

## Need Help?

See the full [README.md](README.md) for:
- Detailed architecture
- Snowflake Intelligence integration
- Streamlit deployment
- Customization guide
- Troubleshooting
- Security considerations
- Advanced usage examples

See [PERMISSIONS_GUIDE.md](PERMISSIONS_GUIDE.md) for:
- Complete permissions reference
- Troubleshooting permission issues
- Security best practices
- Verification scripts

