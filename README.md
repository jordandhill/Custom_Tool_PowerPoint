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
- Internal stage for file storage
- Sample accounts table with test data
- Warehouse for processing
- Necessary permissions

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

## Future Enhancements

Potential improvements:
- Add charts and graphs using data visualization
- Support for multiple slides per account
- Template-based generation for different report types
- Email delivery of generated PowerPoints
- Scheduled batch generation
- Custom branding and logos
- Export to other formats (PDF, Google Slides)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Snowflake documentation on Python stored procedures
3. Consult python-pptx documentation for layout customization

## License

This project is provided as-is for use within your Snowflake environment.

## Version History

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

