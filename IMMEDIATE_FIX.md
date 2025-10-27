# IMMEDIATE FIX for File Corruption

## ⚠️ UPDATE: Root Cause Fixed!

**If you're setting up fresh, the corruption issue is now FIXED!** The stage now uses `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')` which ensures pre-signed URLs work correctly.

**If you already created the stage before this fix:**
Run `fix_existing_stage.sql` to recreate your stage with proper encryption.

---

## The Original Problem
Snowflake's internal stages without proper encryption settings use proprietary compression that makes pre-signed URLs serve files in an incompatible format.

## The Fix (Now Implemented)
Adding `ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')` to the stage creation ensures files are encrypted in a way that's compatible with pre-signed URLs.

## Alternative Solutions (if you can't recreate the stage)

## SOLUTION 1: Use SnowSQL to Download (RECOMMENDED - Works Immediately)

SnowSQL automatically handles Snowflake's internal format:

```bash
# Install SnowSQL if you haven't already
# https://docs.snowflake.com/en/user-guide/snowsql-install-config.html

# Connect to Snowflake
snowsql -a YOUR_ACCOUNT -u YOUR_USER

# In SnowSQL session:
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;

# Download the file (this will work correctly)
GET @PPT_STAGE/Acme_Corporation_20251027_102917.pptx file://./;
```

The file will be downloaded to your current directory and will open correctly in PowerPoint.

## SOLUTION 2: Modify the Stored Procedure to Use SCOPED URLs

Update the stored procedure to return a scoped URL instead:

```sql
-- In the stored procedure, replace the GET_PRESIGNED_URL section with:
presigned_url_query = f"""
    SELECT BUILD_SCOPED_FILE_URL(@PPT_STAGE, '{actual_stage_filename}') AS URL
"""
```

Note: SCOPED URLs require authentication but handle compression automatically.

## SOLUTION 3: Use External Stage (Best for Production)

This is the PERMANENT FIX - modify your setup to use an external stage (S3/Azure/GCS).

### For AWS S3:

1. Create S3 bucket
2. Create storage integration in Snowflake:
```sql
CREATE STORAGE INTEGRATION ppt_s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::your-account:role/your-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://your-bucket/powerpoint/');

CREATE STAGE PPT_STAGE_EXTERNAL
  URL = 's3://your-bucket/powerpoint/'
  STORAGE_INTEGRATION = ppt_s3_integration
  FILE_FORMAT = (TYPE = NONE);
```

3. Update stored procedure to use `@PPT_STAGE_EXTERNAL` instead of `@PPT_STAGE`
4. Files will be directly accessible via S3 URLs without corruption

### For Azure Blob:

```sql
CREATE STORAGE INTEGRATION ppt_azure_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = 'your-tenant-id'
  STORAGE_ALLOWED_LOCATIONS = ('azure://youraccount.blob.core.windows.net/powerpoint/');

CREATE STAGE PPT_STAGE_EXTERNAL
  URL = 'azure://youraccount.blob.core.windows.net/powerpoint/'
  STORAGE_INTEGRATION = ppt_azure_integration
  FILE_FORMAT = (TYPE = NONE);
```

## SOLUTION 4: Return File as Base64 (For Small Files)

Modify the stored procedure to return the file as base64-encoded data:

```python
import base64

# After saving the PowerPoint
with open(local_file_path, 'rb') as f:
    file_data = f.read()
    base64_data = base64.b64encode(file_data).decode('utf-8')

# Upload to stage still for backup
session.file.put(...)

# Return base64 data
return f"PowerPoint Base64: {base64_data}"
```

Then decode on the client side:

```python
import base64

# Extract base64 from result
base64_str = result.split("PowerPoint Base64: ")[1]
file_data = base64.b64decode(base64_str)

with open('output.pptx', 'wb') as f:
    f.write(file_data)
```

## Quick Test with SnowSQL

To verify this is the issue and test the fix:

```bash
# After running the stored procedure to generate the file:
snowsql -a YOUR_ACCOUNT -u YOUR_USER -w REPORTING_WH -d POWERPOINT_DB -s REPORTING \
  -q "GET @PPT_STAGE/Acme_Corporation_20251027_102917.pptx file://./downloads/"
```

The file in `./downloads/` should open correctly in PowerPoint.

## Why This Happens

Snowflake internal stages:
- Compress files for storage efficiency (even with auto_compress=False)
- Encrypt files for security
- Use proprietary format that only Snowflake tools understand
- Pre-signed URLs serve the raw internal format

External stages:
- Store files as-is
- No Snowflake-specific processing
- Direct HTTP/HTTPS access
- Works with standard web browsers

## Recommended Path Forward

1. **Immediate**: Use SnowSQL to download files
2. **Short-term**: Document SnowSQL download process for users
3. **Long-term**: Migrate to external stage (S3/Azure/GCS) for production

