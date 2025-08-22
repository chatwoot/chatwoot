# Chatwoot Performance Analysis & Troubleshooting Guide

This guide provides step-by-step instructions for diagnosing performance issues, analyzing logs, and monitoring the health of Chatwoot production infrastructure on AWS.

## Prerequisites

- AWS CLI configured with `chatscomm` profile
- Access to CloudWatch, ECS, and RDS services
- Basic understanding of Chatwoot architecture

## Quick Reference Commands

### Environment Setup
```bash
export AWS_PROFILE=chatscomm
```

### Key Infrastructure Components
- **ECS Cluster**: `chatscomm-ecs-cluster-prod`
- **Web Service**: `chatscomm-chatwoot-prod-web-service`
- **Worker Service**: `chatscomm-chatwoot-prod-worker`
- **Database**: `chatscomm-db-prod`
- **AI Backend**: `chatscomm-ai-backend-prod`

## Performance Analysis Workflow

### 1. Initial Assessment

#### Check ECS Service Health
```bash
# Get service status and recent events
aws ecs describe-services \
  --cluster chatscomm-ecs-cluster-prod \
  --services chatscomm-chatwoot-prod-web-service

# Check task status
aws ecs list-tasks \
  --cluster chatscomm-ecs-cluster-prod \
  --service-name chatscomm-chatwoot-prod-web-service

# Get detailed task information
aws ecs describe-tasks \
  --cluster chatscomm-ecs-cluster-prod \
  --tasks TASK_ARN_HERE
```

#### Check Database Status
```bash
# List RDS instances
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]' \
  --output table
```

### 2. Metrics Analysis

#### ECS Metrics (Replace timestamps with your incident window)
```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=chatscomm-chatwoot-prod-web-service Name=ClusterName,Value=chatscomm-ecs-cluster-prod \
  --start-time 2025-08-21T23:00:00Z \
  --end-time 2025-08-21T23:10:00Z \
  --period 60 \
  --statistics Average,Maximum

# Memory Utilization  
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=chatscomm-chatwoot-prod-web-service Name=ClusterName,Value=chatscomm-ecs-cluster-prod \
  --start-time 2025-08-21T23:00:00Z \
  --end-time 2025-08-21T23:10:00Z \
  --period 60 \
  --statistics Average,Maximum
```

#### RDS Metrics
```bash
# Database CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=chatscomm-db-prod \
  --start-time 2025-08-21T23:00:00Z \
  --end-time 2025-08-21T23:10:00Z \
  --period 60 \
  --statistics Average,Maximum

# Database Connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=chatscomm-db-prod \
  --start-time 2025-08-21T23:00:00Z \
  --end-time 2025-08-21T23:10:00Z \
  --period 60 \
  --statistics Average,Maximum

# Read/Write Latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name ReadLatency \
  --dimensions Name=DBInstanceIdentifier,Value=chatscomm-db-prod \
  --start-time 2025-08-21T23:00:00Z \
  --end-time 2025-08-21T23:10:00Z \
  --period 60 \
  --statistics Average,Maximum
```

### 3. Log Analysis

#### List Available Log Groups
```bash
aws logs describe-log-groups \
  --query 'logGroups[*].logGroupName' \
  --output table
```

#### Application Logs
```bash
# Search for errors in web service
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-web" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ERROR" \
  --max-items 50

# Search for timeouts
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-web" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "timeout" \
  --max-items 50

# Search for ActiveStorage issues
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-web" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ActiveStorage" \
  --max-items 50
```

#### Database Logs
```bash
# PostgreSQL errors
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/chatscomm-db-prod/postgresql" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ERROR" \
  --max-items 50

# Statement timeouts
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/chatscomm-db-prod/postgresql" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "timeout" \
  --max-items 50

# Slow queries
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/chatscomm-db-prod/postgresql" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "duration" \
  --max-items 50
```

#### Worker Process Logs
```bash
# Check Sidekiq worker issues
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-worker" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ERROR" \
  --max-items 50
```

### 4. Time Conversion Helpers

#### Convert Time to Epoch (macOS)
```bash
# Convert CR time to epoch (seconds)
date -j -f "%Y-%m-%d %H:%M:%S" "2025-08-21 17:00:00" +%s

# Convert to milliseconds for CloudWatch
echo "$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-08-21 17:00:00" +%s)000"
```

#### Convert Time to Epoch (Linux)
```bash
# Convert CR time to epoch (seconds)
date -d "2025-08-21 17:00:00" +%s

# Convert to milliseconds for CloudWatch
echo "$(date -d "2025-08-21 17:00:00" +%s)000"
```

## Common Issues & Patterns

### 1. Database Performance Issues

#### Symptoms
- High RDS CPU utilization (>70%)
- Increased read/write latency
- Statement timeout errors in logs
- Application timeouts

#### Investigation Commands
```bash
# Check for long-running queries
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/chatscomm-db-prod/postgresql" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "duration.*ms" \
  --max-items 100

# Look for specific query patterns (like large IN clauses)
aws logs filter-log-events \
  --log-group-name "/aws/rds/instance/chatscomm-db-prod/postgresql" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "IN (" \
  --max-items 50
```

### 2. ActiveStorage Issues

#### Symptoms
- Image processing timeouts
- High memory usage during file operations
- S3 connectivity issues

#### Investigation Commands
```bash
# Look for ActiveStorage errors
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-web" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ActiveStorage" \
  --max-items 50

# Check for image processing timeouts
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-chatwoot-prod-web" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "resize_to_fill" \
  --max-items 50
```

### 3. Memory Issues

#### Symptoms
- High ECS memory utilization
- Application restarts
- Out of memory errors

#### Investigation Commands
```bash
# Check memory metrics over longer period
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=chatscomm-chatwoot-prod-web-service Name=ClusterName,Value=chatscomm-ecs-cluster-prod \
  --start-time 2025-08-21T22:00:00Z \
  --end-time 2025-08-22T00:00:00Z \
  --period 300 \
  --statistics Average,Maximum
```

### 4. AI Backend Issues

#### Symptoms
- Slow response times
- AI feature failures
- Large query parameter lists

#### Investigation Commands
```bash
# Check AI backend logs
aws logs filter-log-events \
  --log-group-name "/aws/ecs/chatscomm-ai-backend-prod" \
  --start-time EPOCH_TIMESTAMP_MS \
  --end-time EPOCH_TIMESTAMP_MS \
  --filter-pattern "ERROR" \
  --max-items 50
```

## Performance Analysis Report Template

### Report Structure
1. **Executive Summary**
   - Incident window
   - Severity assessment
   - Root cause (if identified)

2. **Technical Analysis**
   - ECS metrics and status
   - RDS performance metrics
   - Log analysis findings
   - Error patterns identified

3. **Timeline of Events**
   - Chronological sequence of issues
   - Recovery timeline

4. **Root Cause Analysis**
   - Primary and secondary causes
   - Contributing factors

5. **Recommendations**
   - Immediate actions (24 hours)
   - Medium-term fixes (1 week)
   - Long-term improvements (1 month)

6. **Preventive Measures**
   - Monitoring improvements
   - Code review guidelines
   - Infrastructure changes

### Sample Metrics Table
| Metric | Normal Range | Incident Value | Status |
|--------|--------------|----------------|--------|
| ECS CPU | <20% | 45% | ⚠️ Elevated |
| ECS Memory | <60% | 85% | 🚨 High |
| RDS CPU | <30% | 15% | ✅ Normal |
| DB Connections | <50 | 25 | ✅ Normal |
| Error Rate | <1% | 15% | 🚨 Critical |

## Monitoring & Alerting Setup

### Recommended CloudWatch Alarms
```bash
# High CPU utilization
aws cloudwatch put-metric-alarm \
  --alarm-name "ECS-HighCPU-chatwoot-prod" \
  --alarm-description "ECS CPU utilization > 70%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Database connection count
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-HighConnections-chatwoot-prod" \
  --alarm-description "Database connections > 80" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### Log-based Alerts
- Statement timeout errors > 5 per minute
- Rack timeout errors > 2 per minute
- ActiveStorage processing failures > 10 per hour
- Memory allocation errors

## Best Practices

### During an Incident
1. **Document everything** - timestamps, commands, outputs
2. **Work systematically** - follow this guide step by step
3. **Preserve evidence** - save log excerpts and metric screenshots
4. **Communicate status** - keep stakeholders informed
5. **Don't panic fix** - understand the issue before applying solutions

### Post-Incident
1. **Create detailed report** using the template above
2. **Implement preventive measures** to avoid recurrence
3. **Update monitoring** based on lessons learned
4. **Share findings** with the team
5. **Schedule follow-up reviews**

### Regular Maintenance
1. **Weekly performance reviews** - check trends and patterns
2. **Monthly capacity planning** - assess resource usage growth
3. **Quarterly disaster recovery testing**
4. **Semi-annual architecture reviews**

## Escalation Procedures

### Severity Levels
- **Critical (P0)**: Service down, data loss risk
- **High (P1)**: Major feature broken, performance severely degraded
- **Medium (P2)**: Minor feature issues, moderate performance impact
- **Low (P3)**: Cosmetic issues, minimal impact

### Contact Information
- **DevOps Team**: [Contact details]
- **Database Admin**: [Contact details]
- **Infrastructure Team**: [Contact details]
- **On-call Engineer**: [Contact details]

## Additional Resources

- [AWS ECS Troubleshooting](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html)
- [RDS Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)
- [CloudWatch Logs User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [Chatwoot Architecture Documentation](../architecture/)

---
**Last Updated**: August 21, 2025  
**Version**: 1.0  
**Maintainer**: DevOps Team