# Troubleshooting File Corruption Issues

If you're experiencing corrupted PowerPoint files when downloading via pre-signed URLs, this guide will help you resolve the issue.

## Problem: Downloaded File is Corrupted

### Cause
Snowflake's internal stages may compress or encrypt files for storage, even when `auto_compress=False` is specified. When downloading via pre-signed URLs, the file may be served in its raw internal format rather than being automatically decompressed.

### Solution Options

## Option 1: Download Using SnowSQL (Recommended)

SnowSQL automatically handles decompression and decryption when downloading from stages:

```bash
# Using SnowSQL command line
snowsql -a YOUR_ACCOUNT -u YOUR_USER -w REPORTING_WH -d POWERPOINT_DB -s REPORTING

# Download the file (SnowSQL handles decompression automatically)
GET @PPT_STAGE/Acme_Corporation_20241027_120000.pptx file:///path/to/local/directory/;
```

This is the most reliable method as SnowSQL handles all Snowflake's internal file processing.

## Option 2: Manual Decompression

If the file has a `.gz` extension or appears compressed:

### On macOS/Linux:
```bash
# If file ends with .gz
gunzip Acme_Corporation_20241027_120000.pptx.gz

# Or if already named .pptx but is compressed
mv Acme_Corporation_20241027_120000.pptx Acme_Corporation_20241027_120000.pptx.gz
gunzip Acme_Corporation_20241027_120000.pptx.gz
```

### On Windows:
```powershell
# Use 7-Zip or WinRAR to extract the .gz file
# Or use PowerShell:
[System.IO.Compression.GzipStream]::new([System.IO.File]::OpenRead("file.pptx.gz"), [System.IO.Compression.CompressionMode]::Decompress)
```

## Option 3: Use External Stage (Recommended for Production)

For production deployments, consider using an external stage (AWS S3, Azure Blob, or GCS) which provides direct, uncompressed access:

### Create External Stage on AWS S3:
```sql
CREATE STAGE PPT_STAGE_EXTERNAL
  URL = 's3://your-bucket/powerpoint-files/'
  STORAGE_INTEGRATION = your_integration
  DIRECTORY = (ENABLE = TRUE)
  FILE_FORMAT = (TYPE = NONE);
```

### Create External Stage on Azure:
```sql
CREATE STAGE PPT_STAGE_EXTERNAL
  URL = 'azure://youraccount.blob.core.windows.net/powerpoint-files/'
  STORAGE_INTEGRATION = your_integration
  DIRECTORY = (ENABLE = TRUE)
  FILE_FORMAT = (TYPE = NONE);
```

External stages provide direct HTTP/HTTPS URLs that don't require Snowflake's internal processing.

## Option 4: Python/JavaScript Download Helper

Create a simple script to download and handle decompression automatically:

### Python Script:
```python
import requests
import gzip
import shutil

def download_and_decompress(presigned_url, output_path):
    """Download from Snowflake pre-signed URL and decompress if needed"""
    response = requests.get(presigned_url, stream=True)
    response.raise_for_status()
    
    temp_file = output_path + '.tmp'
    
    # Download file
    with open(temp_file, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    
    # Check if file is gzipped
    try:
        with gzip.open(temp_file, 'rb') as f_in:
            with open(output_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        print(f"File decompressed and saved to: {output_path}")
    except gzip.BadGzipFile:
        # Not gzipped, just rename
        shutil.move(temp_file, output_path)
        print(f"File saved to: {output_path}")
    finally:
        if os.path.exists(temp_file):
            os.unlink(temp_file)

# Usage
url = "YOUR_PRESIGNED_URL"
download_and_decompress(url, "Acme_Corporation.pptx")
```

### Node.js Script:
```javascript
const fs = require('fs');
const https = require('https');
const zlib = require('zlib');

function downloadAndDecompress(presignedUrl, outputPath) {
    https.get(presignedUrl, (response) => {
        const tempFile = `${outputPath}.tmp`;
        const fileStream = fs.createWriteStream(tempFile);
        
        response.pipe(fileStream);
        
        fileStream.on('finish', () => {
            fileStream.close();
            
            // Try to decompress
            const readStream = fs.createReadStream(tempFile);
            const writeStream = fs.createWriteStream(outputPath);
            const gunzip = zlib.createGunzip();
            
            readStream.pipe(gunzip).on('error', () => {
                // Not gzipped, just copy
                fs.copyFileSync(tempFile, outputPath);
                fs.unlinkSync(tempFile);
                console.log(`File saved to: ${outputPath}`);
            }).pipe(writeStream).on('finish', () => {
                fs.unlinkSync(tempFile);
                console.log(`File decompressed and saved to: ${outputPath}`);
            });
        });
    });
}

// Usage
const url = "YOUR_PRESIGNED_URL";
downloadAndDecompress(url, "Acme_Corporation.pptx");
```

## Verification

After downloading, verify the PowerPoint file:

### Check if file is valid ZIP (PowerPoint files are ZIP archives):
```bash
# Should show "Zip archive data" or similar
file Acme_Corporation_20241027_120000.pptx

# Test ZIP integrity
unzip -t Acme_Corporation_20241027_120000.pptx
```

### Check file signature:
```bash
# Should start with "PK" (hex: 50 4B)
xxd -l 4 Acme_Corporation_20241027_120000.pptx
```

Expected output:
```
00000000: 504b 0304                                PK..
```

## Prevention

To prevent this issue in future:

1. **Use SnowSQL for downloads** - Always recommend users download via SnowSQL
2. **Migrate to External Stage** - For production, use external cloud storage
3. **Add download instructions** - Provide clear documentation to users
4. **Create download scripts** - Provide Python/JS scripts that handle decompression

## Testing Current File

To test your downloaded file:

```bash
# Navigate to directory
cd /Users/jhill/VSCodeProjects/Custom_Tool_PowerPoint/

# Check file type
file Acme_Corporation_20251027_102917.pptx

# If it's not a valid ZIP, try decompressing
cp Acme_Corporation_20251027_102917.pptx test.gz
gunzip test.gz
mv test Acme_Corporation_20251027_102917_fixed.pptx

# Open the fixed file
open Acme_Corporation_20251027_102917_fixed.pptx
```

## Additional Resources

- [Snowflake Stage Compression Documentation](https://docs.snowflake.com/en/sql-reference/sql/put.html)
- [Snowflake GET_PRESIGNED_URL Documentation](https://docs.snowflake.com/en/sql-reference/functions/get_presigned_url.html)
- [SnowSQL Installation Guide](https://docs.snowflake.com/en/user-guide/snowsql-install-config.html)

## Contact

If issues persist after trying these solutions, check:
1. Snowflake stage configuration
2. File permissions
3. Network/proxy settings that might modify downloaded files

