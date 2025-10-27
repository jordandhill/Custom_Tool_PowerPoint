-- ============================================================================
-- PowerPoint Generation Stored Procedure
-- ============================================================================
-- This stored procedure generates a stylized PowerPoint presentation
-- for a given account ID and returns a pre-signed URL
-- ============================================================================

USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;

-- Create the stored procedure
CREATE OR REPLACE PROCEDURE GENERATE_ACCOUNT_POWERPOINT(ACCOUNT_ID_INPUT VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python', 'python-pptx')
HANDLER = 'generate_ppt'
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
from datetime import datetime

def generate_ppt(session: Session, account_id_input: str) -> str:
    """
    Generate a PowerPoint presentation for the given account ID.
    
    Args:
        session: Snowflake session object
        account_id_input: The account ID to generate the presentation for
    
    Returns:
        Pre-signed URL for downloading the PowerPoint file
    """
    
    # Query account data
    query = f"""
        SELECT 
            ACCOUNT_ID,
            ACCOUNT_NAME,
            ACCOUNT_TYPE,
            REVENUE,
            EMPLOYEES,
            INDUSTRY,
            CREATED_DATE
        FROM ACCOUNTS
        WHERE ACCOUNT_ID = '{account_id_input}'
    """
    
    try:
        result = session.sql(query).collect()
        
        if len(result) == 0:
            return f"Error: Account ID '{account_id_input}' not found"
        
        # Extract account data
        account = result[0]
        account_name = account['ACCOUNT_NAME']
        account_type = account['ACCOUNT_TYPE']
        revenue = account['REVENUE']
        employees = account['EMPLOYEES']
        industry = account['INDUSTRY']
        created_date = account['CREATED_DATE']
        
        # Create PowerPoint presentation
        prs = Presentation()
        
        # Set slide dimensions (16:9 aspect ratio)
        prs.slide_width = Inches(10)
        prs.slide_height = Inches(5.625)
        
        # ====================================================================
        # SLIDE 1: Title Slide
        # ====================================================================
        slide1_layout = prs.slide_layouts[6]  # Blank layout
        slide1 = prs.slides.add_slide(slide1_layout)
        
        # Add background color
        background = slide1.background
        fill = background.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(31, 78, 120)  # Professional blue
        
        # Add title
        title_box = slide1.shapes.add_textbox(
            Inches(0.5), Inches(1.5), Inches(9), Inches(1)
        )
        title_frame = title_box.text_frame
        title_frame.text = account_name
        title_para = title_frame.paragraphs[0]
        title_para.font.size = Pt(54)
        title_para.font.bold = True
        title_para.font.color.rgb = RGBColor(255, 255, 255)
        title_para.alignment = PP_ALIGN.CENTER
        
        # Add subtitle
        subtitle_box = slide1.shapes.add_textbox(
            Inches(0.5), Inches(2.8), Inches(9), Inches(0.5)
        )
        subtitle_frame = subtitle_box.text_frame
        subtitle_frame.text = "Account Overview Report"
        subtitle_para = subtitle_frame.paragraphs[0]
        subtitle_para.font.size = Pt(28)
        subtitle_para.font.color.rgb = RGBColor(255, 255, 255)
        subtitle_para.alignment = PP_ALIGN.CENTER
        
        # Add date
        date_box = slide1.shapes.add_textbox(
            Inches(0.5), Inches(4.5), Inches(9), Inches(0.5)
        )
        date_frame = date_box.text_frame
        date_frame.text = f"Generated: {datetime.now().strftime('%B %d, %Y')}"
        date_para = date_frame.paragraphs[0]
        date_para.font.size = Pt(16)
        date_para.font.color.rgb = RGBColor(200, 200, 200)
        date_para.alignment = PP_ALIGN.CENTER
        
        # ====================================================================
        # SLIDE 2: Account Details
        # ====================================================================
        slide2_layout = prs.slide_layouts[6]  # Blank layout
        slide2 = prs.slides.add_slide(slide2_layout)
        
        # Add background color (lighter)
        background2 = slide2.background
        fill2 = background2.fill
        fill2.solid()
        fill2.fore_color.rgb = RGBColor(245, 245, 245)
        
        # Add header
        header_box = slide2.shapes.add_textbox(
            Inches(0.5), Inches(0.4), Inches(9), Inches(0.6)
        )
        header_frame = header_box.text_frame
        header_frame.text = "Account Details"
        header_para = header_frame.paragraphs[0]
        header_para.font.size = Pt(36)
        header_para.font.bold = True
        header_para.font.color.rgb = RGBColor(31, 78, 120)
        
        # Add account details in a styled format
        details_data = [
            ("Account ID:", account_id_input),
            ("Account Name:", account_name),
            ("Account Type:", account_type),
            ("Industry:", industry),
            ("Annual Revenue:", f"${revenue:,.2f}"),
            ("Number of Employees:", str(employees)),
            ("Customer Since:", str(created_date))
        ]
        
        y_position = 1.5
        for label, value in details_data:
            # Label
            label_box = slide2.shapes.add_textbox(
                Inches(1), Inches(y_position), Inches(3), Inches(0.4)
            )
            label_frame = label_box.text_frame
            label_frame.text = label
            label_para = label_frame.paragraphs[0]
            label_para.font.size = Pt(18)
            label_para.font.bold = True
            label_para.font.color.rgb = RGBColor(80, 80, 80)
            
            # Value
            value_box = slide2.shapes.add_textbox(
                Inches(4.5), Inches(y_position), Inches(4.5), Inches(0.4)
            )
            value_frame = value_box.text_frame
            value_frame.text = value
            value_para = value_frame.paragraphs[0]
            value_para.font.size = Pt(18)
            value_para.font.color.rgb = RGBColor(51, 51, 51)
            
            y_position += 0.45
        
        # ====================================================================
        # SLIDE 3: Key Metrics
        # ====================================================================
        slide3_layout = prs.slide_layouts[6]
        slide3 = prs.slides.add_slide(slide3_layout)
        
        # Add background
        background3 = slide3.background
        fill3 = background3.fill
        fill3.solid()
        fill3.fore_color.rgb = RGBColor(245, 245, 245)
        
        # Add header
        header_box3 = slide3.shapes.add_textbox(
            Inches(0.5), Inches(0.4), Inches(9), Inches(0.6)
        )
        header_frame3 = header_box3.text_frame
        header_frame3.text = "Key Performance Metrics"
        header_para3 = header_frame3.paragraphs[0]
        header_para3.font.size = Pt(36)
        header_para3.font.bold = True
        header_para3.font.color.rgb = RGBColor(31, 78, 120)
        
        # Create metric cards
        metrics = [
            ("Total Revenue", f"${revenue:,.0f}", RGBColor(40, 167, 69)),
            ("Employees", str(employees), RGBColor(0, 123, 255)),
            ("Revenue/Employee", f"${revenue/employees:,.0f}", RGBColor(255, 193, 7))
        ]
        
        x_start = 0.8
        card_width = 2.6
        spacing = 0.4
        
        for i, (metric_name, metric_value, color) in enumerate(metrics):
            x_pos = x_start + i * (card_width + spacing)
            
            # Card background
            card_shape = slide3.shapes.add_shape(
                1,  # Rectangle
                Inches(x_pos), Inches(1.8),
                Inches(card_width), Inches(2.2)
            )
            card_fill = card_shape.fill
            card_fill.solid()
            card_fill.fore_color.rgb = RGBColor(255, 255, 255)
            card_shape.line.color.rgb = color
            card_shape.line.width = Pt(3)
            
            # Metric value
            value_box = slide3.shapes.add_textbox(
                Inches(x_pos + 0.2), Inches(2.2),
                Inches(card_width - 0.4), Inches(0.8)
            )
            value_frame = value_box.text_frame
            value_frame.text = metric_value
            value_para = value_frame.paragraphs[0]
            value_para.font.size = Pt(32)
            value_para.font.bold = True
            value_para.font.color.rgb = color
            value_para.alignment = PP_ALIGN.CENTER
            
            # Metric label
            label_box = slide3.shapes.add_textbox(
                Inches(x_pos + 0.2), Inches(3.2),
                Inches(card_width - 0.4), Inches(0.6)
            )
            label_frame = label_box.text_frame
            label_frame.text = metric_name
            label_para = label_frame.paragraphs[0]
            label_para.font.size = Pt(16)
            label_para.font.color.rgb = RGBColor(100, 100, 100)
            label_para.alignment = PP_ALIGN.CENTER
        
        # Save the presentation to a temporary file
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.pptx')
        temp_file_path = temp_file.name
        temp_file.close()
        
        prs.save(temp_file_path)
        
        # Generate file name for stage
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        stage_file_name = f"account_{account_id_input}_{timestamp}.pptx"
        stage_path = f"@PPT_STAGE/{stage_file_name}"
        
        # Upload file to stage
        session.file.put(
            temp_file_path,
            "@PPT_STAGE",
            auto_compress=False,
            overwrite=True
        )
        
        # Clean up temp file
        os.unlink(temp_file_path)
        
        # Generate pre-signed URL (valid for 24 hours = 86400 seconds)
        presigned_url_query = f"""
            SELECT GET_PRESIGNED_URL(@PPT_STAGE, '{os.path.basename(temp_file_path)}', 86400) AS URL
        """
        
        url_result = session.sql(presigned_url_query).collect()
        presigned_url = url_result[0]['URL']
        
        return f"PowerPoint generated successfully! Download URL (valid for 24 hours): {presigned_url}"
        
    except Exception as e:
        return f"Error generating PowerPoint: {str(e)}"
$$;

-- Grant execute permission
GRANT USAGE ON PROCEDURE GENERATE_ACCOUNT_POWERPOINT(VARCHAR) TO ROLE SYSADMIN;

SELECT 'Stored procedure GENERATE_ACCOUNT_POWERPOINT created successfully!' AS STATUS;

