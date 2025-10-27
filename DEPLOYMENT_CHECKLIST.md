# Deployment Checklist

Use this checklist to ensure proper deployment of the PowerPoint generation system.

## Pre-Deployment

- [ ] Snowflake account access verified
- [ ] Appropriate role assigned (SYSADMIN or equivalent)
- [ ] Database creation permissions confirmed
- [ ] Warehouse creation permissions confirmed (or existing warehouse identified)

## Deployment Steps

### 1. Database Setup
- [ ] Execute `setup_snowflake_objects.sql`
- [ ] Verify database `POWERPOINT_DB` created
- [ ] Verify schema `REPORTING` created
- [ ] Verify stage `PPT_STAGE` created
- [ ] Verify warehouse `REPORTING_WH` created (or using existing)
- [ ] Verify table `ACCOUNTS` created with sample data

**Verification Command:**
```sql
SHOW DATABASES LIKE 'POWERPOINT_DB';
SHOW SCHEMAS IN DATABASE POWERPOINT_DB;
SHOW STAGES IN SCHEMA POWERPOINT_DB.REPORTING;
SHOW TABLES IN SCHEMA POWERPOINT_DB.REPORTING;
```

### 2. Stored Procedure Setup
- [ ] Execute `create_powerpoint_procedure.sql`
- [ ] Verify procedure `GENERATE_ACCOUNT_POWERPOINT` created
- [ ] Verify Python packages are available (`python-pptx`)

**Verification Command:**
```sql
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
SHOW PROCEDURES LIKE 'GENERATE_ACCOUNT_POWERPOINT';
```

### 3. Permissions Setup
- [ ] Grant database usage to required roles
- [ ] Grant schema usage to required roles
- [ ] Grant stage read/write to required roles
- [ ] Grant procedure execution to required roles
- [ ] Grant warehouse usage to required roles

**Review Grants:**
```sql
SHOW GRANTS ON DATABASE POWERPOINT_DB;
SHOW GRANTS ON SCHEMA POWERPOINT_DB.REPORTING;
SHOW GRANTS ON STAGE POWERPOINT_DB.REPORTING.PPT_STAGE;
```

### 4. Testing
- [ ] Test with sample account (ACC001)
- [ ] Verify PowerPoint file created in stage
- [ ] Verify pre-signed URL generated
- [ ] Download and open PowerPoint file
- [ ] Verify all slides render correctly
- [ ] Test with non-existent account (error handling)

**Test Commands:**
```sql
USE DATABASE POWERPOINT_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE REPORTING_WH;

-- Should succeed
CALL GENERATE_ACCOUNT_POWERPOINT('ACC001');

-- Should fail gracefully
CALL GENERATE_ACCOUNT_POWERPOINT('INVALID_ID');

-- List generated files
LIST @PPT_STAGE;
```

## Post-Deployment

### Monitoring
- [ ] Set up monitoring for procedure execution
- [ ] Monitor stage storage usage
- [ ] Monitor warehouse credit consumption
- [ ] Set up alerts for failures (if applicable)

### Documentation
- [ ] Share README.md with team
- [ ] Document any customizations made
- [ ] Update security policies if needed
- [ ] Create runbook for operations team

### Optimization
- [ ] Review warehouse size (XSMALL is default)
- [ ] Adjust auto-suspend timeout if needed
- [ ] Set up file cleanup schedule if needed
- [ ] Consider resource monitors for cost control

## Security Checklist

- [ ] Review and adjust role-based access
- [ ] Verify pre-signed URL expiration settings (default: 24 hours)
- [ ] Confirm stored procedure execution context (CALLER vs OWNER)
- [ ] Review data access patterns
- [ ] Document security model

## Rollback Plan

If deployment fails or issues arise:

1. **Remove Stored Procedure:**
```sql
DROP PROCEDURE IF EXISTS POWERPOINT_DB.REPORTING.GENERATE_ACCOUNT_POWERPOINT(VARCHAR);
```

2. **Clean Up Stage Files:**
```sql
REMOVE @POWERPOINT_DB.REPORTING.PPT_STAGE PATTERN='.*';
```

3. **Drop Database (if needed):**
```sql
DROP DATABASE IF EXISTS POWERPOINT_DB;
```

## Production Considerations

### For Production Deployment:

- [ ] Replace sample data with actual account data
- [ ] Implement proper error logging
- [ ] Set up notification system for failures
- [ ] Create backup procedures
- [ ] Document service level agreements
- [ ] Plan for disaster recovery
- [ ] Establish change management process
- [ ] Create monitoring dashboard

### Performance Tuning:

- [ ] Benchmark generation time
- [ ] Test with large datasets
- [ ] Optimize SQL queries if needed
- [ ] Consider caching strategies
- [ ] Plan for scaling

### Maintenance Schedule:

- [ ] Weekly: Review stage storage usage
- [ ] Monthly: Clean up old PowerPoint files
- [ ] Quarterly: Review and optimize performance
- [ ] Annually: Review security and access controls

## Support Contacts

Document key contacts for support:

- **Snowflake Administrator:** _________________
- **Application Owner:** _________________
- **Security Team:** _________________
- **Operations Team:** _________________

## Sign-Off

- [ ] Development Team: _________________ Date: _______
- [ ] Security Review: _________________ Date: _______
- [ ] Operations Team: _________________ Date: _______
- [ ] Business Owner: _________________ Date: _______

---

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Procedure not found | Re-run create_powerpoint_procedure.sql |
| Permission denied | Grant appropriate permissions to role |
| Python package error | Verify PACKAGES clause in procedure |
| Stage not accessible | Check stage permissions and existence |
| URL generation fails | Verify file uploaded to stage |
| Empty PowerPoint | Check account data exists |

---

**Deployment Date:** _________________

**Deployed By:** _________________

**Environment:** _________________

**Notes:** _______________________________________

