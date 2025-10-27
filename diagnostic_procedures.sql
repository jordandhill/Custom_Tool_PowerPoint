-- ============================================================================
-- Diagnostic Procedures for Troubleshooting
-- ============================================================================
-- These procedures test individual components to identify issues
-- ============================================================================

USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- ============================================================================
-- Diagnostic Procedure 1: Test Stage Access
-- ============================================================================

CREATE OR REPLACE PROCEDURE TEST_STAGE_ACCESS()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'test_stage'
EXECUTE AS CALLER
AS
$$
from snowflake.snowpark import Session

def test_stage(session: Session) -> str:
    """Test stage access permissions"""
    
    results = []
    
    # Test 1: LIST stage
    try:
        list_result = session.sql("LIST @PPT_STAGE").collect()
        results.append(f"✓ LIST permission: SUCCESS - Found {len(list_result)} files")
    except Exception as e:
        results.append(f"✗ LIST permission: FAILED - {str(e)}")
    
    # Test 2: Describe stage
    try:
        desc_result = session.sql("DESC STAGE PPT_STAGE").collect()
        results.append(f"✓ DESCRIBE stage: SUCCESS")
        for row in desc_result:
            if 'encryption_type' in str(row).lower():
                results.append(f"  Encryption: {row}")
    except Exception as e:
        results.append(f"✗ DESCRIBE stage: FAILED - {str(e)}")
    
    # Test 3: Check current role
    try:
        role_result = session.sql("SELECT CURRENT_ROLE()").collect()
        results.append(f"✓ Current role: {role_result[0][0]}")
    except Exception as e:
        results.append(f"✗ Get current role: FAILED - {str(e)}")
    
    # Test 4: Check stage grants
    try:
        grants_result = session.sql("SHOW GRANTS ON STAGE PPT_STAGE").collect()
        results.append(f"✓ Stage grants: {len(grants_result)} permissions found")
    except Exception as e:
        results.append(f"✗ Show grants: FAILED - {str(e)}")
    
    return "\n".join(results)
$$;

-- ============================================================================
-- Diagnostic Procedure 2: Test File Operations
-- ============================================================================

CREATE OR REPLACE PROCEDURE TEST_FILE_OPERATIONS()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'test_files'
EXECUTE AS CALLER
AS
$$
from snowflake.snowpark import Session
import tempfile
import os

def test_files(session: Session) -> str:
    """Test file system operations"""
    
    results = []
    
    # Test 1: Get temp directory
    try:
        temp_dir = tempfile.gettempdir()
        results.append(f"✓ Temp directory: {temp_dir}")
    except Exception as e:
        results.append(f"✗ Get temp directory: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 2: Create temp file
    try:
        test_file = tempfile.NamedTemporaryFile(delete=False, suffix='.txt')
        test_file_path = test_file.name
        test_file.close()
        results.append(f"✓ Create temp file: SUCCESS - {test_file_path}")
    except Exception as e:
        results.append(f"✗ Create temp file: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 3: Write to file
    try:
        with open(test_file_path, 'w') as f:
            f.write("Test content for Snowflake Intelligence debugging")
        results.append(f"✓ Write to file: SUCCESS")
    except Exception as e:
        results.append(f"✗ Write to file: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 4: Read from file
    try:
        with open(test_file_path, 'r') as f:
            content = f.read()
        results.append(f"✓ Read from file: SUCCESS - {len(content)} bytes")
    except Exception as e:
        results.append(f"✗ Read from file: FAILED - {str(e)}")
    
    # Test 5: Get file size
    try:
        file_size = os.path.getsize(test_file_path)
        results.append(f"✓ Get file size: SUCCESS - {file_size} bytes")
    except Exception as e:
        results.append(f"✗ Get file size: FAILED - {str(e)}")
    
    # Test 6: Upload to stage
    try:
        put_result = session.file.put(
            test_file_path,
            "@PPT_STAGE",
            auto_compress=False,
            overwrite=True
        )
        results.append(f"✓ Upload to stage: SUCCESS")
        results.append(f"  Result: {put_result}")
    except Exception as e:
        results.append(f"✗ Upload to stage: FAILED - {str(e)}")
    
    # Test 7: Verify file in stage
    try:
        filename = os.path.basename(test_file_path)
        list_result = session.sql(f"LIST @PPT_STAGE PATTERN='.*{filename}.*'").collect()
        if len(list_result) > 0:
            results.append(f"✓ Verify in stage: SUCCESS - File found")
        else:
            results.append(f"✗ Verify in stage: FAILED - File not found")
    except Exception as e:
        results.append(f"✗ Verify in stage: FAILED - {str(e)}")
    
    # Test 8: Clean up
    try:
        os.unlink(test_file_path)
        results.append(f"✓ Delete temp file: SUCCESS")
    except Exception as e:
        results.append(f"✗ Delete temp file: FAILED - {str(e)}")
    
    return "\n".join(results)
$$;

-- ============================================================================
-- Diagnostic Procedure 3: Test PowerPoint Library
-- ============================================================================

CREATE OR REPLACE PROCEDURE TEST_POWERPOINT_LIBRARY()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'python-pptx')
HANDLER = 'test_pptx'
EXECUTE AS CALLER
AS
$$
from snowflake.snowpark import Session
from pptx import Presentation
from pptx.util import Inches, Pt
import tempfile
import os

def test_pptx(session: Session) -> str:
    """Test python-pptx library"""
    
    results = []
    
    # Test 1: Import library
    try:
        from pptx import Presentation
        results.append(f"✓ Import python-pptx: SUCCESS")
    except Exception as e:
        results.append(f"✗ Import python-pptx: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 2: Create presentation
    try:
        prs = Presentation()
        results.append(f"✓ Create presentation: SUCCESS")
    except Exception as e:
        results.append(f"✗ Create presentation: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 3: Add slide
    try:
        slide_layout = prs.slide_layouts[0]
        slide = prs.slides.add_slide(slide_layout)
        results.append(f"✓ Add slide: SUCCESS")
    except Exception as e:
        results.append(f"✗ Add slide: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 4: Save to temp file
    try:
        temp_dir = tempfile.mkdtemp()
        temp_file = os.path.join(temp_dir, "test_presentation.pptx")
        prs.save(temp_file)
        results.append(f"✓ Save presentation: SUCCESS - {temp_file}")
    except Exception as e:
        results.append(f"✗ Save presentation: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Test 5: Verify file exists
    try:
        if os.path.exists(temp_file):
            file_size = os.path.getsize(temp_file)
            results.append(f"✓ Verify file: SUCCESS - {file_size} bytes")
        else:
            results.append(f"✗ Verify file: FAILED - File not found")
    except Exception as e:
        results.append(f"✗ Verify file: FAILED - {str(e)}")
    
    # Test 6: Upload to stage
    try:
        put_result = session.file.put(
            temp_file,
            "@PPT_STAGE",
            auto_compress=False,
            overwrite=True
        )
        results.append(f"✓ Upload PPTX to stage: SUCCESS")
    except Exception as e:
        results.append(f"✗ Upload PPTX to stage: FAILED - {str(e)}")
    
    # Test 7: Clean up
    try:
        os.unlink(temp_file)
        os.rmdir(temp_dir)
        results.append(f"✓ Cleanup: SUCCESS")
    except Exception as e:
        results.append(f"✗ Cleanup: FAILED - {str(e)}")
    
    return "\n".join(results)
$$;

-- ============================================================================
-- Diagnostic Procedure 4: Test Complete Workflow
-- ============================================================================

CREATE OR REPLACE PROCEDURE TEST_COMPLETE_WORKFLOW(ACCOUNT_ID_INPUT VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'python-pptx')
HANDLER = 'test_workflow'
EXECUTE AS CALLER
AS
$$
from snowflake.snowpark import Session
from pptx import Presentation
from pptx.util import Inches
import tempfile
import os
from datetime import datetime

def test_workflow(session: Session, account_id_input: str) -> str:
    """Test the complete workflow step by step"""
    
    results = []
    results.append(f"Testing complete workflow for account: {account_id_input}\n")
    
    # Step 1: Query account
    try:
        query = f"""
            SELECT ACCOUNT_NAME, REVENUE, EMPLOYEES
            FROM POWERPOINT_DB.REPORTING.ACCOUNTS
            WHERE ACCOUNT_ID = '{account_id_input}'
        """
        result = session.sql(query).collect()
        if len(result) == 0:
            return f"✗ Account {account_id_input} not found"
        account_name = result[0]['ACCOUNT_NAME']
        results.append(f"✓ Step 1 - Query account: SUCCESS - {account_name}")
    except Exception as e:
        results.append(f"✗ Step 1 - Query account: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Step 2: Create PowerPoint
    try:
        prs = Presentation()
        prs.slide_width = Inches(10)
        prs.slide_height = Inches(5.625)
        slide = prs.slides.add_slide(prs.slide_layouts[6])
        results.append(f"✓ Step 2 - Create PowerPoint: SUCCESS")
    except Exception as e:
        results.append(f"✗ Step 2 - Create PowerPoint: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Step 3: Generate filename
    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        safe_name = account_name.replace(' ', '_')
        safe_name = ''.join(c for c in safe_name if c.isalnum() or c == '_')
        filename = f"TEST_{safe_name}_{timestamp}.pptx"
        results.append(f"✓ Step 3 - Generate filename: SUCCESS - {filename}")
    except Exception as e:
        results.append(f"✗ Step 3 - Generate filename: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Step 4: Create temp directory
    try:
        temp_dir = tempfile.mkdtemp()
        temp_file = os.path.join(temp_dir, filename)
        results.append(f"✓ Step 4 - Create temp directory: SUCCESS")
        results.append(f"  Path: {temp_file}")
    except Exception as e:
        results.append(f"✗ Step 4 - Create temp directory: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Step 5: Save PowerPoint
    try:
        prs.save(temp_file)
        file_size = os.path.getsize(temp_file)
        results.append(f"✓ Step 5 - Save PowerPoint: SUCCESS - {file_size} bytes")
    except Exception as e:
        results.append(f"✗ Step 5 - Save PowerPoint: FAILED - {str(e)}")
        return "\n".join(results)
    
    # Step 6: Upload to stage
    try:
        put_result = session.file.put(
            temp_file,
            "@PPT_STAGE",
            auto_compress=False,
            overwrite=True
        )
        results.append(f"✓ Step 6 - Upload to stage: SUCCESS")
        results.append(f"  Result: {put_result}")
    except Exception as e:
        results.append(f"✗ Step 6 - Upload to stage: FAILED - {str(e)}")
        # Try to clean up before returning
        try:
            os.unlink(temp_file)
            os.rmdir(temp_dir)
        except:
            pass
        return "\n".join(results)
    
    # Step 7: Verify in stage
    try:
        list_result = session.sql(f"LIST @PPT_STAGE PATTERN='.*{filename}.*'").collect()
        if len(list_result) > 0:
            results.append(f"✓ Step 7 - Verify in stage: SUCCESS")
        else:
            results.append(f"✗ Step 7 - Verify in stage: File not found")
    except Exception as e:
        results.append(f"✗ Step 7 - Verify in stage: FAILED - {str(e)}")
    
    # Step 8: Generate pre-signed URL
    try:
        url_query = f"SELECT GET_PRESIGNED_URL(@PPT_STAGE, '{filename}', 86400) AS URL"
        url_result = session.sql(url_query).collect()
        url = url_result[0]['URL']
        results.append(f"✓ Step 8 - Generate URL: SUCCESS")
        results.append(f"  URL length: {len(url)} characters")
    except Exception as e:
        results.append(f"✗ Step 8 - Generate URL: FAILED - {str(e)}")
    
    # Step 9: Cleanup
    try:
        os.unlink(temp_file)
        os.rmdir(temp_dir)
        results.append(f"✓ Step 9 - Cleanup: SUCCESS")
    except Exception as e:
        results.append(f"✗ Step 9 - Cleanup: FAILED - {str(e)}")
    
    results.append(f"\nAll steps completed!")
    return "\n".join(results)
$$;

-- Grant execute permissions
GRANT USAGE ON PROCEDURE TEST_STAGE_ACCESS() TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE TEST_STAGE_ACCESS() TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

GRANT USAGE ON PROCEDURE TEST_FILE_OPERATIONS() TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE TEST_FILE_OPERATIONS() TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

GRANT USAGE ON PROCEDURE TEST_POWERPOINT_LIBRARY() TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE TEST_POWERPOINT_LIBRARY() TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

GRANT USAGE ON PROCEDURE TEST_COMPLETE_WORKFLOW(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE TEST_COMPLETE_WORKFLOW(VARCHAR) TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Display usage instructions
SELECT 'Diagnostic procedures created successfully!' AS STATUS;
SELECT '' AS BLANK;
SELECT 'Run diagnostics with:' AS INSTRUCTIONS;
SELECT '  CALL TEST_STAGE_ACCESS();' AS TEST_1;
SELECT '  CALL TEST_FILE_OPERATIONS();' AS TEST_2;
SELECT '  CALL TEST_POWERPOINT_LIBRARY();' AS TEST_3;
SELECT '  CALL TEST_COMPLETE_WORKFLOW(''ACC001'');' AS TEST_4;
SELECT '' AS BLANK2;
SELECT 'For debugging the main procedure, use:' AS DEBUG_INFO;
SELECT '  CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG(''ACC001'');' AS DEBUG_CMD;
SELECT '  SELECT * FROM DEBUG_LOGS ORDER BY LOG_TIMESTAMP DESC LIMIT 20;' AS VIEW_LOGS;


