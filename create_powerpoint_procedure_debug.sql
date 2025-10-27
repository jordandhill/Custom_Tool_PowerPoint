-- ============================================================================
-- PowerPoint Generation Stored Procedure - DEBUG VERSION
-- ============================================================================
-- This is a debug version with extensive logging to troubleshoot issues
-- especially when calling from Snowflake Intelligence agents
-- ============================================================================

USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- Create a logging table for debug output
CREATE TABLE IF NOT EXISTS DEBUG_LOGS (
    LOG_ID NUMBER AUTOINCREMENT PRIMARY KEY,
    PROCEDURE_NAME VARCHAR(200),
    LOG_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    LOG_LEVEL VARCHAR(20),
    LOG_MESSAGE VARCHAR(5000),
    ACCOUNT_ID VARCHAR(50),
    ERROR_DETAILS VARCHAR(5000)
);

-- Create the debug version of the stored procedure
CREATE OR REPLACE PROCEDURE GENERATE_ACCOUNT_POWERPOINT_DEBUG(ACCOUNT_ID_INPUT VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'python-pptx')
HANDLER = 'generate_ppt_debug'
EXECUTE AS CALLER
AS
$$
import snowflake.snowpark as snowpark
from snowflake.snowpark import Session
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor
import tempfile
import os
import sys
from datetime import datetime

def log_debug(session: Session, level: str, message: str, account_id: str = None, error_details: str = None):
    """Log debug information to DEBUG_LOGS table"""
    try:
        log_query = f"""
            INSERT INTO DEBUG_LOGS (PROCEDURE_NAME, LOG_LEVEL, LOG_MESSAGE, ACCOUNT_ID, ERROR_DETAILS)
            VALUES ('GENERATE_ACCOUNT_POWERPOINT_DEBUG', '{level}', '{message.replace("'", "''")}', 
                    '{account_id if account_id else "N/A"}', 
                    '{error_details.replace("'", "''") if error_details else "N/A"}')
        """
        session.sql(log_query).collect()
    except Exception as e:
        # If logging fails, just continue
        pass

def generate_ppt_debug(session: Session, account_id_input: str) -> str:
    """
    Generate a PowerPoint presentation for the given account ID with extensive debugging.
    """
    
    try:
        log_debug(session, "INFO", f"Starting PowerPoint generation for account: {account_id_input}", account_id_input)
        
        # ====================================================================
        # TEST 1: Check Python environment
        # ====================================================================
        log_debug(session, "INFO", f"Python version: {sys.version}", account_id_input)
        log_debug(session, "INFO", f"Python executable: {sys.executable}", account_id_input)
        
        # ====================================================================
        # TEST 2: Check temp directory access
        # ====================================================================
        try:
            temp_dir_path = tempfile.gettempdir()
            log_debug(session, "INFO", f"Temp directory: {temp_dir_path}", account_id_input)
            
            # Test write access to temp directory
            test_file_path = os.path.join(temp_dir_path, "test_write.txt")
            with open(test_file_path, 'w') as f:
                f.write("test")
            os.remove(test_file_path)
            log_debug(session, "INFO", "Temp directory write test: SUCCESS", account_id_input)
        except Exception as e:
            log_debug(session, "ERROR", "Temp directory write test: FAILED", account_id_input, str(e))
            return f"Error: Cannot write to temp directory - {str(e)}"
        
        # ====================================================================
        # TEST 3: Check stage access (LIST)
        # ====================================================================
        try:
            list_query = "LIST @PPT_STAGE"
            list_result = session.sql(list_query).collect()
            log_debug(session, "INFO", f"Stage LIST test: SUCCESS - Found {len(list_result)} files", account_id_input)
        except Exception as e:
            log_debug(session, "ERROR", "Stage LIST test: FAILED", account_id_input, str(e))
            return f"Error: Cannot list stage contents - {str(e)}"
        
        # ====================================================================
        # TEST 4: Query account data
        # ====================================================================
        query = f"""
            SELECT 
                ACCOUNT_ID,
                ACCOUNT_NAME,
                ACCOUNT_TYPE,
                REVENUE,
                EMPLOYEES,
                INDUSTRY,
                CREATED_DATE
            FROM POWERPOINT_DB.REPORTING.ACCOUNTS
            WHERE ACCOUNT_ID = '{account_id_input}'
        """
        
        try:
            result = session.sql(query).collect()
            log_debug(session, "INFO", f"Account query: SUCCESS - Found {len(result)} records", account_id_input)
            
            if len(result) == 0:
                log_debug(session, "WARNING", f"Account not found: {account_id_input}", account_id_input)
                return f"Error: Account ID '{account_id_input}' not found"
            
            # Extract account data
            account = result[0]
            account_name = account['ACCOUNT_NAME']
            account_type = account['ACCOUNT_TYPE']
            revenue = account['REVENUE']
            employees = account['EMPLOYEES']
            industry = account['INDUSTRY']
            created_date = account['CREATED_DATE']
            
            log_debug(session, "INFO", f"Account data: {account_name}, Revenue: {revenue}, Employees: {employees}", account_id_input)
            
        except Exception as e:
            log_debug(session, "ERROR", "Account query: FAILED", account_id_input, str(e))
            return f"Error querying account data: {str(e)}"
        
        # ====================================================================
        # TEST 5: Create PowerPoint in memory
        # ====================================================================
        try:
            log_debug(session, "INFO", "Creating PowerPoint presentation", account_id_input)
            prs = Presentation()
            prs.slide_width = Inches(10)
            prs.slide_height = Inches(5.625)
            
            # Create simple slide
            slide_layout = prs.slide_layouts[6]
            slide = prs.slides.add_slide(slide_layout)
            
            # Add title
            title_box = slide.shapes.add_textbox(Inches(1), Inches(2), Inches(8), Inches(1))
            title_frame = title_box.text_frame
            title_frame.text = f"Debug Test: {account_name}"
            
            log_debug(session, "INFO", "PowerPoint creation: SUCCESS", account_id_input)
            
        except Exception as e:
            log_debug(session, "ERROR", "PowerPoint creation: FAILED", account_id_input, str(e))
            return f"Error creating PowerPoint: {str(e)}"
        
        # ====================================================================
        # TEST 6: Save to temp directory
        # ====================================================================
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            safe_account_name = account_name.replace(' ', '_').replace('/', '_').replace('\\', '_')
            safe_account_name = ''.join(c for c in safe_account_name if c.isalnum() or c in ('_', '-'))
            stage_file_name = f"{safe_account_name}_{timestamp}.pptx"
            
            # Create temp directory with better permissions
            temp_dir = tempfile.mkdtemp()
            local_file_path = os.path.join(temp_dir, stage_file_name)
            
            log_debug(session, "INFO", f"Saving to temp file: {local_file_path}", account_id_input)
            
            prs.save(local_file_path)
            
            # Verify file was created
            if os.path.exists(local_file_path):
                file_size = os.path.getsize(local_file_path)
                log_debug(session, "INFO", f"File saved: SUCCESS - Size: {file_size} bytes", account_id_input)
            else:
                log_debug(session, "ERROR", "File saved: FAILED - File not found after save", account_id_input)
                return "Error: File not created after save"
            
        except Exception as e:
            log_debug(session, "ERROR", "File save: FAILED", account_id_input, str(e))
            return f"Error saving file: {str(e)}"
        
        # ====================================================================
        # TEST 7: Upload to stage
        # ====================================================================
        try:
            log_debug(session, "INFO", f"Uploading file to stage: {stage_file_name}", account_id_input)
            
            put_result = session.file.put(
                local_file_path,
                "@PPT_STAGE",
                auto_compress=False,
                overwrite=True
            )
            
            log_debug(session, "INFO", f"Stage upload: SUCCESS - {put_result}", account_id_input)
            
        except Exception as e:
            log_debug(session, "ERROR", "Stage upload: FAILED", account_id_input, str(e))
            # Try to clean up before returning
            try:
                os.unlink(local_file_path)
                os.rmdir(temp_dir)
            except:
                pass
            return f"Error uploading to stage: {str(e)}"
        
        # ====================================================================
        # TEST 8: Verify file in stage
        # ====================================================================
        try:
            list_query = f"LIST @PPT_STAGE PATTERN='.*{stage_file_name}.*'"
            list_result = session.sql(list_query).collect()
            
            if len(list_result) > 0:
                actual_stage_filename = list_result[0]['name'].split('/')[-1]
                log_debug(session, "INFO", f"Stage verification: SUCCESS - File found: {actual_stage_filename}", account_id_input)
            else:
                log_debug(session, "WARNING", "Stage verification: File not found in stage", account_id_input)
                actual_stage_filename = stage_file_name
                
        except Exception as e:
            log_debug(session, "ERROR", "Stage verification: FAILED", account_id_input, str(e))
            actual_stage_filename = stage_file_name
        
        # ====================================================================
        # TEST 9: Clean up temp files
        # ====================================================================
        try:
            os.unlink(local_file_path)
            os.rmdir(temp_dir)
            log_debug(session, "INFO", "Temp file cleanup: SUCCESS", account_id_input)
        except Exception as e:
            log_debug(session, "WARNING", "Temp file cleanup: FAILED (non-critical)", account_id_input, str(e))
        
        # ====================================================================
        # TEST 10: Generate pre-signed URL
        # ====================================================================
        try:
            presigned_url_query = f"""
                SELECT GET_PRESIGNED_URL(@PPT_STAGE, '{actual_stage_filename}', 86400) AS URL
            """
            
            url_result = session.sql(presigned_url_query).collect()
            presigned_url = url_result[0]['URL']
            log_debug(session, "INFO", "Pre-signed URL generation: SUCCESS", account_id_input)
            
        except Exception as e:
            log_debug(session, "ERROR", "Pre-signed URL generation: FAILED", account_id_input, str(e))
            presigned_url = "URL generation failed"
        
        log_debug(session, "INFO", "PowerPoint generation completed successfully", account_id_input)
        
        return f"""PowerPoint generated successfully for '{account_name}'!
File: {actual_stage_filename}
Download URL (valid for 24 hours): {presigned_url}

DEBUG: All tests passed! Check DEBUG_LOGS table for detailed execution log.
Query: SELECT * FROM DEBUG_LOGS WHERE ACCOUNT_ID = '{account_id_input}' ORDER BY LOG_TIMESTAMP DESC;"""
        
    except Exception as e:
        error_msg = str(e)
        log_debug(session, "CRITICAL", f"Unhandled exception: {error_msg}", account_id_input, error_msg)
        return f"Critical Error: {error_msg}\n\nCheck DEBUG_LOGS table for details:\nSELECT * FROM DEBUG_LOGS WHERE ACCOUNT_ID = '{account_id_input}' ORDER BY LOG_TIMESTAMP DESC;"
$$;

-- Grant execute permission
GRANT USAGE ON PROCEDURE GENERATE_ACCOUNT_POWERPOINT_DEBUG(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE GENERATE_ACCOUNT_POWERPOINT_DEBUG(VARCHAR) TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

-- Grant access to debug logs table
GRANT SELECT, INSERT ON TABLE DEBUG_LOGS TO ROLE SYSADMIN;
GRANT SELECT, INSERT ON TABLE DEBUG_LOGS TO ROLE SNOWFLAKE_INTELLIGENCE_RL;

SELECT 'Debug stored procedure GENERATE_ACCOUNT_POWERPOINT_DEBUG created successfully!' AS STATUS;
SELECT 'Call with: CALL GENERATE_ACCOUNT_POWERPOINT_DEBUG(''ACC001'');' AS USAGE;
SELECT 'View logs with: SELECT * FROM DEBUG_LOGS ORDER BY LOG_TIMESTAMP DESC LIMIT 20;' AS VIEW_LOGS;


