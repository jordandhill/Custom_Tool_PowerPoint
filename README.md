# Snowflake PowerPoint Generation Service

A comprehensive solution for generating stylized PowerPoint presentations from Snowflake data using stored procedures. This project enables automated creation of professional account overview presentations with pre-signed URLs for secure downloads.

## Features

- **Automated PowerPoint Generation**: Create professional, multi-slide presentations directly from Snowflake
- **Pre-signed URLs**: Secure, time-limited download links (24-hour validity)
- **Stylized Design**: Professional layouts with custom colors, fonts, and formatting
- **Account Data Integration**: Dynamically populate slides with account information from database
- **Internal Stage Storage**: Secure file storage within Snowflake infrastructure
- **Error Handling**: Robust error handling for missing accounts and processing failures

## Architecture

### Components

1. **Database Objects**
   - Database: `POWERPOINT_DB`
   - Schema: `REPORTING`
   - Internal Stage: `PPT_STAGE`
   - Warehouse: `REPORTING_WH`
   - Sample Table: `ACCOUNTS`

2. **Stored Procedure**
   - Name: `GENERATE_ACCOUNT_POWERPOINT`
   - Language: Python 3.10
   - Dependencies: `snowflake-snowpark-python`, `python-pptx`

3. **Generated PowerPoint Structure**
   - Slide 1: Title slide with account name
   - Slide 2: Detailed account information
   - Slide 3: Key performance metrics with visual cards

## Installation & Setup

### Prerequisites

- Snowflake account with appropriate permissions
- Role with CREATE DATABASE, CREATE SCHEMA, CREATE STAGE privileges
- Warehouse for executing stored procedures

### Step 1: Create Snowflake Objects

Run the setup script to create all necessary objects:

```sql
-- Execute the setup script
-- File: setup_snowflake_objects.sql
```

This creates:
- Database and schema
- Internal stage for file storage (with SNOWFLAKE_SSE encryption)
- Sample accounts table with test data
- Warehouse for processing
- Necessary permissions for users, agents, and Streamlit apps

### Step 2: Create the Stored Procedure

Run the procedure creation script:

```sql
-- Execute the procedure creation script
-- File: create_powerpoint_procedure.sql
```

This creates the `GENERATE_ACCOUNT_POWERPOINT` stored procedure with Python runtime.

### Step 3: Verify Installation

```sql
-- Check that objects were created
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

SHOW PROCEDURES LIKE 'GENERATE_ACCOUNT_POWERPOINT';
SHOW STAGES LIKE 'PPT_STAGE';
SHOW TABLES LIKE 'ACCOUNTS';
```

## Usage

### Basic Usage

Generate a PowerPoint for a specific account:

```sql
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;

-- Generate PowerPoint for account ACC001
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');
```

**Output**: Returns a pre-signed URL (valid for 24 hours) that you can paste directly into your browser to download the PowerPoint file.

**Note**: The stage uses `SNOWFLAKE_SSE` encryption, which ensures pre-signed URLs work correctly with binary files like PowerPoint presentations.

### View Available Accounts

```sql
SELECT * FROM ACCOUNTS;
```

### List Generated Files

```sql
LIST @PPT_STAGE;
```

### Manual Pre-signed URL Generation

For existing files in the stage:

```sql
-- Note: Filenames use account name + datetime (e.g., Acme_Corporation_20241027_120000.pptx)
SELECT GET_PRESIGNED_URL(
    @PPT_STAGE, 
    'Acme_Corporation_20241027_120000.pptx', 
    86400  -- 24 hours in seconds
) AS DOWNLOAD_URL;
```

## PowerPoint Design Details

### Slide 1: Title Slide
- Professional blue background (RGB: 31, 78, 120)
- Large, bold account name (54pt)
- Subtitle: "Account Overview Report"
- Generation timestamp

### Slide 2: Account Details
- Light gray background (RGB: 245, 245, 245)
- Labeled fields with values:
  - Account ID
  - Account Name
  - Account Type
  - Industry
  - Annual Revenue (formatted currency)
  - Number of Employees
  - Customer Since date

### Slide 3: Key Performance Metrics
- Three metric cards with color-coded borders:
  - Total Revenue (Green: RGB 40, 167, 69)
  - Employees (Blue: RGB 0, 123, 255)
  - Revenue per Employee (Yellow: RGB 255, 193, 7)
- Large, bold metric values
- Clear labeling

## Advanced Usage

### Batch Generation

Generate PowerPoints for multiple accounts:

```sql
-- For all Enterprise accounts
SELECT ACCOUNT_ID FROM ACCOUNTS WHERE ACCOUNT_TYPE = 'Enterprise';

-- Call procedure for each account (manual or using scripting)
```

### Integration with Applications

Use the stored procedure in your applications:

```python
# Python example using Snowflake Connector
import snowflake.connector

conn = snowflake.connector.connect(
    user='YOUR_USER',
    password='YOUR_PASSWORD',
    account='YOUR_ACCOUNT',
    warehouse='REPORTING_WH',
    database='POWERPOINT_DB',
    schema='REPORTING'
)

cursor = conn.cursor()
cursor.execute("CALL GENERATE_ACCOUNT_POWERPOINT('ACC001')")
result = cursor.fetchone()
download_url = result[0]
print(f"Download URL: {download_url}")
```

### File Management

Clean up old files:

```sql
-- Remove specific file (use actual account name in filename)
REMOVE @PPT_STAGE/Acme_Corporation_20241027_120000.pptx;

-- Remove all PowerPoint files (use with caution)
REMOVE @PPT_STAGE PATTERN='.*\.pptx';
```

## Customization

### Modifying the PowerPoint Design

Edit the stored procedure to customize:
- Colors: Change `RGBColor()` values
- Fonts: Modify `font.size` and `font.bold` properties
- Layout: Adjust `Inches()` positioning
- Content: Add/remove slides or text boxes
- Metrics: Modify calculations or add new data points

### Adding Additional Data

To include more account information:

1. Update the SQL query in the stored procedure
2. Add new text boxes to slides
3. Format and position new elements

### Extending to Other Entities

Create similar procedures for other entities:
- Customers
- Products
- Projects
- Sales Reports

## Security Considerations

### Permissions

The setup script grants permissions to `SYSADMIN` role. Adjust based on your security model:

```sql
-- Grant to specific role
GRANT USAGE ON DATABASE POWERPOINT_DB TO ROLE YOUR_ROLE;
GRANT USAGE ON SCHEMA POWERPOINT_DB.REPORTING TO ROLE YOUR_ROLE;
GRANT READ, WRITE ON STAGE PPT_STAGE TO ROLE YOUR_ROLE;
```

### Pre-signed URL Expiration

Default: 24 hours (86400 seconds). Adjust as needed:

```sql
-- 1 hour expiration
SELECT GET_PRESIGNED_URL(@PPT_STAGE, 'file.pptx', 3600);

-- 7 days expiration
SELECT GET_PRESIGNED_URL(@PPT_STAGE, 'file.pptx', 604800);
```

### Data Access

The stored procedure uses `EXECUTE AS CALLER`, meaning it runs with the permissions of the calling user. Consider using `EXECUTE AS OWNER` for more controlled access.

## Troubleshooting

### Common Issues

**Issue**: "Account ID not found"
- **Solution**: Verify the account exists in the ACCOUNTS table

**Issue**: "Permission denied on stage"
- **Solution**: Grant READ/WRITE permissions on the stage to your role

**Issue**: "Python package not found"
- **Solution**: Ensure `python-pptx` is included in the PACKAGES clause

**Issue**: "Pre-signed URL generation fails"
- **Solution**: Check that the file was uploaded successfully using `LIST @PPT_STAGE`

### Debug Mode

Add logging to the stored procedure:

```python
# Add at various points in the code
session.sql(f"SELECT SYSTEM$LOG('DEBUG', 'Processing account: {account_id_input}')").collect()
```

## Performance Considerations

- **Warehouse Size**: XSMALL is sufficient for most use cases
- **Auto-suspend**: Set to 300 seconds to balance cost and performance
- **Concurrent Execution**: Multiple procedures can run simultaneously
- **File Size**: PowerPoint files are typically 50-100 KB

## Cost Optimization

1. **Auto-suspend Warehouse**: Enabled with 5-minute timeout
2. **Minimal Compute**: PowerPoint generation is lightweight
3. **Stage Storage**: Internal stages included in storage costs
4. **Pre-signed URLs**: No additional cost for URL generation

## Snowflake Intelligence Integration

You can integrate this PowerPoint generator as a custom tool in Snowflake Intelligence agents. See the [Snowflake Intelligence documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence) for details.

### Required Permissions for Agents

According to [Snowflake's documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-intelligence), agents use the user's default role and warehouse. 

**The system uses a dedicated role:** `SNOWFLAKE_INTELLIGENCE_RL`

This role is automatically created by the setup script with all required permissions:
- **USAGE** on `POWERPOINT_DB` database
- **USAGE** on `POWERPOINT_DB.REPORTING` schema  
- **READ, WRITE** on `PPT_STAGE` stage (required for file generation)
- **USAGE** on `REPORTING_WH` warehouse
- **SELECT** on `ACCOUNTS` table
- **USAGE** on `GENERATE_ACCOUNT_POWERPOINT` procedure

**To grant access to a user:**
```sql
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;
ALTER USER <username> SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_RL;
```

### Setup Instructions

Run the integration script:
```sql
-- Execute: snowflake_intelligence_integration.sql
```

This script:
- Grants necessary permissions
- Creates Snowflake Intelligence database structure
- Provides step-by-step instructions for creating the agent
- Includes troubleshooting queries

### Creating the Agent

1. Navigate to **Snowsight** → **AI & ML** → **Agents**
2. Select **Create agent**
3. Choose **Snowflake Intelligence** platform
4. Add the stored procedure as a **custom tool**
5. Configure warehouse: `REPORTING_WH`
6. Set planning instructions for when to use the tool
7. **Grant access to `SNOWFLAKE_INTELLIGENCE_RL` role** (critical for security)

**Important**: Only users with the `SNOWFLAKE_INTELLIGENCE_RL` role can use the agent.

Users with the role can then ask:
- "Create a PowerPoint for account ACC001"
- "Generate a presentation for Acme Corporation"

## Streamlit Integration

A complete Streamlit app is provided for user-friendly PowerPoint generation.

### Features
- Account selection dropdown
- Account details display
- One-click PowerPoint generation
- Pre-signed URL for direct download
- SnowSQL command fallback
- Error handling and troubleshooting

### Deployment

1. Upload `streamlit_integration.py` to Snowflake Streamlit
2. Select `REPORTING_WH` as the warehouse
3. Grant required permissions (automatically set by setup script)
4. Run the app

### Required Permissions (Same as Agents)

The Streamlit app requires users to have the `SNOWFLAKE_INTELLIGENCE_RL` role, which provides all necessary permissions to write to the stage and execute the stored procedure.

Users must have the role granted:
```sql
GRANT ROLE SNOWFLAKE_INTELLIGENCE_RL TO USER <username>;
```

## Future Enhancements

Potential improvements:
- Add charts and graphs using data visualization
- Support for multiple slides per account
- Template-based generation for different report types
- Email delivery of generated PowerPoints
- Scheduled batch generation with Snowflake Tasks
- Custom branding and logos
- Export to other formats (PDF, Google Slides)
- Integration with Snowflake Marketplace

## Debugging and Troubleshooting

If you encounter issues (especially file stream errors when using Snowflake Intelligence agents), use the comprehensive debugging tools provided.

### Debug Tools

1. **Debug Version of Procedure** (`create_powerpoint_procedure_debug.sql`)
   ```sql
   CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG('ACC001');
   SELECT * FROM DEBUG_LOGS ORDER BY LOG_TIMESTAMP DESC LIMIT 20;
   ```

2. **Diagnostic Procedures** (`diagnostic_procedures.sql`)
   ```sql
   CALL TEST_STAGE_ACCESS();           -- Test stage permissions
   CALL TEST_FILE_OPERATIONS();        -- Test file I/O
   CALL TEST_POWERPOINT_LIBRARY();     -- Test python-pptx
   CALL TEST_COMPLETE_WORKFLOW('ACC001'); -- Test end-to-end
   ```

3. **Debugging Guide** (`DEBUGGING_GUIDE.md`)
   - Comprehensive troubleshooting steps
   - Common issues and solutions
   - Agent-specific debugging
   - Diagnostic information collection

### Common Issues

**File Stream Errors**: Usually caused by temp directory access or stage permissions
- Run `CALL TEST_FILE_OPERATIONS();` to diagnose
- Check stage permissions: `SHOW GRANTS ON STAGE PPT_STAGE;`
- See DEBUGGING_GUIDE.md for detailed solutions

**Agent Failures**: Works directly but fails through Snowflake Intelligence
- Run debug version and compare logs
- Verify user's default role is set correctly
- Check agent configuration (warehouse, timeout, role access)

## Support

For issues or questions:
1. Run diagnostic procedures to identify the issue
2. Check DEBUG_LOGS table for detailed execution information
3. Review DEBUGGING_GUIDE.md for common issues
4. Check the troubleshooting section
5. Review Snowflake documentation on Python stored procedures
6. Consult python-pptx documentation for layout customization

## License

This project is provided as-is for use within your Snowflake environment.

## Version History

- **v1.0.7** (2024-10-27): **Debugging and Diagnostic Tools**
  - Added debug version of procedure with comprehensive logging (`GENERATE_ACCOUNT_POWERPOINT_DEBUG`)
  - Created DEBUG_LOGS table for execution tracking
  - Added 4 diagnostic procedures to test individual components
  - Created comprehensive DEBUGGING_GUIDE.md
  - Addresses file stream errors in Snowflake Intelligence agents
  - Step-by-step troubleshooting for agent-specific issues
- **v1.0.6** (2024-10-27): **Role-Based Security Enhancement**
  - Changed from PUBLIC role to dedicated `SNOWFLAKE_INTELLIGENCE_RL` role
  - Enhanced security by limiting access to authorized users only
  - Added user management commands and examples
  - Updated all documentation to reflect role-based access control
- **v1.0.5** (2024-10-27): **Snowflake Intelligence & Streamlit Integration**
  - Added comprehensive Snowflake Intelligence agent integration guide
  - Created `snowflake_intelligence_integration.sql` with permissions and setup
  - Added complete Streamlit app (`streamlit_integration.py`) for UI-based generation
  - Documented required permissions for agents and Streamlit to write to stage
  - Added permission verification queries and troubleshooting steps
- **v1.0.4** (2024-10-27): **CRITICAL FIX - Stage encryption**
  - **Added `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')` to stage creation** - This fixes the file corruption issue!
  - SNOWFLAKE_SSE encryption ensures pre-signed URLs serve files correctly
  - Simplified stored procedure output (pre-signed URLs now work properly)
  - If you already created the stage, you must recreate it with the encryption parameter
- **v1.0.3** (2024-10-27): Download method improvements
  - Documented internal stage compression limitations
  - Added SnowSQL download instructions as primary method
  - Included troubleshooting guides (IMMEDIATE_FIX.md, TROUBLESHOOTING_FILE_CORRUPTION.md)
  - Updated procedure to return SnowSQL command for easy downloads
  - Added external stage migration guide for production use
- **v1.0.2** (2024-10-27): Filename and corruption fixes
  - Fixed file corruption issue caused by incorrect filename reference
  - Updated filename format to use account name + datetime (e.g., Acme_Corporation_20241027_120000.pptx)
  - Improved file handling and cleanup
- **v1.0.1** (2024-10-27): Python runtime update
  - Updated to Python 3.10 runtime (3.8 is decommissioned)
- **v1.0.0** (2024-10-27): Initial release
  - Basic PowerPoint generation
  - Three-slide template
  - Pre-signed URL support
  - Sample account data

---

**Note**: This solution uses Snowflake's Python runtime environment. Ensure your Snowflake edition supports Python stored procedures (Standard Edition or higher).

