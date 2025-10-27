"""
Streamlit App for PowerPoint Generation
=========================================
This Streamlit app provides a user interface for generating PowerPoint presentations
from Snowflake data using the GENERATE_ACCOUNT_POWERPOINT stored procedure.

Required Permissions:
- USAGE on POWERPOINT_DB database
- USAGE on POWERPOINT_DB.REPORTING schema
- READ, WRITE on POWERPOINT_DB.REPORTING.PPT_STAGE stage
- USAGE on REPORTING_WH warehouse
- SELECT on POWERPOINT_DB.REPORTING.ACCOUNTS table
- USAGE on POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT procedure

Deployment:
1. Upload this file to Snowflake Streamlit
2. Select REPORTING_WH as the warehouse
3. Grant necessary permissions (see snowflake_intelligence_integration.sql)
4. Run the app
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

# Get the current session
session = get_active_session()

# App configuration
st.set_page_config(
    page_title="PowerPoint Generator",
    page_icon="📊",
    layout="wide"
)

# Title and description
st.title("📊 PowerPoint Presentation Generator")
st.markdown("""
Generate professional PowerPoint presentations for your accounts.
Select an account from the dropdown or enter an account ID manually.
""")

# Create two columns for layout
col1, col2 = st.columns([2, 1])

with col1:
    st.subheader("Select Account")
    
    # Load available accounts
    try:
        accounts_df = session.sql("""
            SELECT 
                ACCOUNT_ID,
                ACCOUNT_NAME,
                ACCOUNT_TYPE,
                REVENUE,
                EMPLOYEES,
                INDUSTRY
            FROM POWERPOINT_DB.REPORTING.ACCOUNTS
            ORDER BY ACCOUNT_NAME
        """).to_pandas()
        
        # Display accounts table
        st.dataframe(
            accounts_df,
            use_container_width=True,
            hide_index=True
        )
        
        # Create dropdown for account selection
        account_options = [f"{row['ACCOUNT_ID']} - {row['ACCOUNT_NAME']}" 
                          for _, row in accounts_df.iterrows()]
        selected_account = st.selectbox(
            "Choose an account:",
            options=account_options,
            index=0
        )
        
        # Extract account ID from selection
        account_id = selected_account.split(' - ')[0]
        
    except Exception as e:
        st.error(f"Error loading accounts: {str(e)}")
        st.info("Using manual account ID input instead.")
        account_id = None

with col2:
    st.subheader("Account Details")
    
    if account_id and 'accounts_df' in locals():
        # Display selected account details
        account_details = accounts_df[accounts_df['ACCOUNT_ID'] == account_id].iloc[0]
        
        st.metric("Account Name", account_details['ACCOUNT_NAME'])
        st.metric("Type", account_details['ACCOUNT_TYPE'])
        st.metric("Revenue", f"${account_details['REVENUE']:,.2f}")
        st.metric("Employees", f"{account_details['EMPLOYEES']:,}")
        st.metric("Industry", account_details['INDUSTRY'])

# Manual account ID input (fallback)
st.divider()
manual_account_id = st.text_input(
    "Or enter Account ID manually:",
    value=account_id if account_id else "",
    placeholder="e.g., ACC001"
)

# Use manual input if provided
final_account_id = manual_account_id if manual_account_id else account_id

# Generate button
st.divider()
col_btn1, col_btn2, col_btn3 = st.columns([1, 2, 1])

with col_btn2:
    generate_button = st.button(
        "🎨 Generate PowerPoint",
        type="primary",
        use_container_width=True,
        disabled=not final_account_id
    )

# Generate PowerPoint when button is clicked
if generate_button and final_account_id:
    with st.spinner(f"Generating PowerPoint for account {final_account_id}..."):
        try:
            # Call the stored procedure
            result = session.sql(f"""
                CALL POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT('{final_account_id}')
            """).collect()
            
            # Extract the result message
            result_message = result[0][0]
            
            # Check if generation was successful
            if "successfully" in result_message.lower():
                st.success("✅ PowerPoint generated successfully!")
                
                # Parse the result to extract information
                if "File:" in result_message:
                    file_name = result_message.split("File:")[1].split("|")[0].strip()
                    st.info(f"📄 File Name: `{file_name}`")
                
                if "Download URL" in result_message:
                    # Extract URL
                    url = result_message.split("Download URL (valid for 24 hours):")[1].strip()
                    
                    # Display download section
                    st.markdown("### 📥 Download Options")
                    
                    # Option 1: Direct download link
                    st.markdown(f"""
                    **Option 1: Direct Browser Download**
                    
                    Click the link below to download the PowerPoint file:
                    
                    [🔗 Download PowerPoint]({url})
                    """)
                    
                    # Display the URL in a code block for copying
                    st.code(url, language=None)
                    
                    # Option 2: SnowSQL command
                    st.markdown("**Option 2: Download via SnowSQL**")
                    snowsql_command = f"GET @POWERPOINT_DB.REPORTING.PPT_STAGE/{file_name} file://./;"
                    st.code(snowsql_command, language="sql")
                    
                    st.info("💡 Tip: The download URL is valid for 24 hours.")
                else:
                    # Fallback if URL parsing fails
                    st.text_area("Result:", result_message, height=150)
            else:
                # Display error message
                st.error("❌ Failed to generate PowerPoint")
                st.text_area("Error details:", result_message, height=150)
                
        except Exception as e:
            st.error(f"❌ Error generating PowerPoint: {str(e)}")
            
            # Display troubleshooting information
            with st.expander("🔧 Troubleshooting"):
                st.markdown("""
                **Common Issues:**
                
                1. **Permission Denied**: Ensure your role has the following permissions:
                   - USAGE on POWERPOINT_DB database
                   - USAGE on POWERPOINT_DB.REPORTING schema
                   - READ, WRITE on PPT_STAGE stage
                   - USAGE on REPORTING_WH warehouse
                   - SELECT on ACCOUNTS table
                   - USAGE on GENERATE_ACCOUNT_POWERPOINT procedure
                
                2. **Account Not Found**: Verify the account ID exists in the ACCOUNTS table
                
                3. **Warehouse Not Available**: Ensure REPORTING_WH is running or set to auto-resume
                
                **Check Current Settings:**
                """)
                
                try:
                    current_role = session.sql("SELECT CURRENT_ROLE()").collect()[0][0]
                    current_warehouse = session.sql("SELECT CURRENT_WAREHOUSE()").collect()[0][0]
                    
                    st.code(f"""
Current Role: {current_role}
Current Warehouse: {current_warehouse}
                    """)
                except:
                    st.warning("Could not retrieve current session information")

# Footer
st.divider()
st.markdown("""
---
**About**: This app uses the `GENERATE_ACCOUNT_POWERPOINT` stored procedure to create PowerPoint presentations.
The presentations include account details, key metrics, and professional visualizations.

**Support**: For questions or issues, contact your Snowflake administrator.
""")

# Sidebar with additional information
with st.sidebar:
    st.header("ℹ️ Information")
    
    st.markdown("""
    ### How it works
    
    1. Select an account from the list
    2. Click "Generate PowerPoint"
    3. Download using the provided URL
    
    ### PowerPoint Contents
    
    The generated presentation includes:
    - **Slide 1**: Title slide with account name
    - **Slide 2**: Account details and information
    - **Slide 3**: Key performance metrics
    
    ### File Format
    
    Files are named: `AccountName_YYYYMMDD_HHMMSS.pptx`
    
    Example: `Acme_Corporation_20241027_143022.pptx`
    
    ### Download URL Expiration
    
    Pre-signed URLs expire after **24 hours**. 
    If the link expires, regenerate the presentation.
    """)
    
    # Display current session info
    try:
        st.markdown("### 🔐 Current Session")
        current_role = session.sql("SELECT CURRENT_ROLE()").collect()[0][0]
        current_warehouse = session.sql("SELECT CURRENT_WAREHOUSE()").collect()[0][0]
        current_database = session.sql("SELECT CURRENT_DATABASE()").collect()[0][0]
        
        st.text(f"Role: {current_role}")
        st.text(f"Warehouse: {current_warehouse}")
        st.text(f"Database: {current_database}")
    except:
        pass

