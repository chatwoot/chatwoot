# SLA, Departments & Queues Configuration Guide

## Overview

This guide explains how to configure and manage SLA (Service Level Agreement) policies with Departments and Queues in Chatwoot. The system provides automated routing, escalation, and compliance monitoring.

## Architecture

```
Account
├── Departments (Support, Sales, Billing, Technical)
│   ├── Queues (Priority-based routing)
│   │   ├── SLA Policy (Response time thresholds)
│   │   ├── Agents (Queue members)
│   │   └── Conversations (Auto-assigned)
│   └── Compliance Reports
└── Alerts & Notifications
```

## Models Overview

### Department
- **Purpose**: Organize agents and queues by functional area
- **Types**: `support`, `sales`, `billing`, `technical`, `custom`
- **Features**: SLA compliance tracking, performance metrics

### Queue  
- **Purpose**: Route conversations based on priority and agent availability
- **Features**: Capacity management, working hours, routing rules
- **Assignment**: Auto-assigns to least loaded available agent

### SLA Policy
- **Thresholds**: First response, next response, resolution times
- **Scope**: Can be assigned to departments, queues, or conversations
- **Business Hours**: Optional restriction to business hours only

## Configuration Steps

### 1. Create Departments

```ruby
# Via Rails Console
department = Account.first.departments.create!(
  name: 'support',
  description: 'Customer support team',
  department_type: :support,
  active: true
)
```

```bash
# Via API
POST /api/v1/accounts/{account_id}/departments
{
  "department": {
    "name": "support",
    "description": "Customer support team", 
    "department_type": "support",
    "active": true
  }
}
```

### 2. Create SLA Policies

```ruby
# Via Rails Console
sla_policy = Account.first.sla_policies.create!(
  name: 'Support Standard SLA',
  description: 'Standard response times for support',
  first_response_time_threshold: 3600, # 1 hour
  next_response_time_threshold: 1800,  # 30 minutes  
  resolution_time_threshold: 86400,    # 24 hours
  only_during_business_hours: false,
  department: department
)
```

### 3. Create Queues

```ruby
# Via Rails Console
queue = Account.first.queues.create!(
  name: 'priority-support',
  description: 'High priority support tickets',
  department: department,
  sla_policy: sla_policy,
  priority: 1,
  max_capacity: 50,
  active: true,
  working_hours: {
    'monday' => { 'start' => 9, 'end' => 17 },
    'tuesday' => { 'start' => 9, 'end' => 17 },
    # ... etc
  },
  routing_rules: {
    'auto_assign' => true,
    'assignment_method' => 'round_robin',
    'slack_channel' => '#support-alerts',
    'webhooks' => ['https://example.com/sla-webhook']
  }
)
```

### 4. Assign Agents to Queues

```ruby
# Add agents to queue
agents = Account.first.users.where(role: :agent).limit(5)
queue.agents = agents
```

```bash
# Via API
POST /api/v1/accounts/{account_id}/queues/{queue_id}/assign_agents
{
  "agent_ids": [1, 2, 3, 4, 5]
}
```

## SLA Configuration Options

### Threshold Types

1. **First Response Time**: Time from conversation creation to first agent reply
2. **Next Response Time**: Time from customer reply to next agent reply  
3. **Resolution Time**: Total time from creation to conversation resolution

### Business Hours Mode

When `only_during_business_hours` is enabled:
- SLA timers pause outside business hours
- Calculations exclude weekends/holidays
- Configure via account business hours settings

### Example SLA Configurations

```ruby
# Urgent Support Queue - Aggressive SLA
urgent_sla = SlaPolicy.create!(
  name: 'Urgent Support',
  first_response_time_threshold: 900,   # 15 minutes
  next_response_time_threshold: 600,    # 10 minutes
  resolution_time_threshold: 7200,      # 2 hours
  only_during_business_hours: false
)

# Sales Queue - Business Hours Only
sales_sla = SlaPolicy.create!(
  name: 'Sales Inquiries',
  first_response_time_threshold: 7200,  # 2 hours
  next_response_time_threshold: 3600,   # 1 hour
  resolution_time_threshold: 172800,    # 48 hours
  only_during_business_hours: true
)
```

## Automatic Features

### 1. Conversation Routing

```ruby
# Conversations automatically assigned to appropriate queue
conversation.assign_to_queue(queue_id)

# Queue selects best available agent
queue.assign_conversation(conversation)
```

### 2. SLA Breach Alerts

When SLA thresholds are exceeded, the system automatically:

- **Email Notifications**: Sent to assigned agent, queue members, supervisors
- **Slack Alerts**: Posted to configured channels with conversation details
- **Webhook Triggers**: External system notifications with full context
- **Internal Notifications**: Dashboard alerts for immediate attention
- **Escalation**: Auto-escalates to supervisors for critical breaches

### 3. Escalation Rules

```ruby
# Automatic escalation triggers:
# - First response breaches: Always escalated
# - Multiple next response breaches: After 2 occurrences  
# - Resolution breaches: If conversation > 24h old

escalation = {
  'first_response_time' => 'always',
  'next_response_time' => 'after_2_breaches',
  'resolution_time' => 'if_older_than_24h'
}
```

## Reporting & Analytics

### 1. SLA Compliance Reports

Access comprehensive reports via:
- **Dashboard**: `/app/accounts/{id}/settings/reports/sla`
- **API**: `/api/v1/accounts/{id}/applied_slas/metrics`

### 2. Available Metrics

- **Compliance Rate**: Percentage of SLA-compliant conversations
- **Breach Breakdown**: Counts by breach type (FRT, NRT, RT)
- **Average Response Times**: Department/queue performance
- **Trend Analysis**: Month-over-month comparisons
- **Agent Performance**: Individual SLA compliance

### 3. Filtering Options

Reports can be filtered by:
- Date range
- Department
- Queue  
- SLA Policy
- Agent
- Inbox
- Team
- Labels

### 4. Export Options

```bash
# Download CSV reports
GET /api/v1/accounts/{account_id}/applied_slas/download
?department_id=1&queue_id=2&from=1234567890&to=1234567890
```

## Webhook Integration

### 1. SLA Breach Webhooks

```json
{
  "event": "sla_breach",
  "data": {
    "conversation_id": 123,
    "display_id": "#456", 
    "breach_type": "first_response_time",
    "sla_policy": {
      "id": 1,
      "name": "Support Standard SLA",
      "threshold": 3600
    },
    "department": {
      "id": 1,
      "name": "support"
    },
    "queue": {
      "id": 1, 
      "name": "priority-support"
    },
    "actual_time": 4200,
    "is_breach": true,
    "timestamp": "2024-01-01T10:00:00Z"
  }
}
```

### 2. Compliance Report Webhooks

```json
{
  "event": "sla.compliance_report",
  "data": {
    "account_id": 1,
    "department_id": 1,
    "queue_id": 2,
    "period": {
      "start_date": "2024-01-01T00:00:00Z",
      "end_date": "2024-01-31T23:59:59Z"
    },
    "metrics": {
      "compliance_rate": 85.5,
      "total_conversations": 1000,
      "sla_breached": 145,
      "breach_breakdown": {
        "first_response_breaches": 45,
        "next_response_breaches": 60,
        "resolution_breaches": 40
      }
    }
  }
}
```

## Configuration Examples

### High-Volume Support Setup

```ruby
# Department: Customer Support
support_dept = Department.create!(
  name: 'customer-support',
  department_type: :support
)

# Tier 1 Queue - General inquiries
tier1_queue = Queue.create!(
  name: 'tier1-support',
  department: support_dept,
  priority: 3,
  max_capacity: 100,
  sla_policy: standard_sla
)

# Tier 2 Queue - Technical issues  
tier2_queue = Queue.create!(
  name: 'tier2-technical', 
  department: support_dept,
  priority: 2,
  max_capacity: 30,
  sla_policy: technical_sla
)

# VIP Queue - Premium customers
vip_queue = Queue.create!(
  name: 'vip-support',
  department: support_dept, 
  priority: 1,
  max_capacity: 10,
  sla_policy: vip_sla
)
```

### Sales Team Setup

```ruby
# Department: Sales
sales_dept = Department.create!(
  name: 'sales',
  department_type: :sales
)

# Lead qualification queue
leads_queue = Queue.create!(
  name: 'lead-qualification',
  department: sales_dept,
  working_hours: business_hours_config,
  routing_rules: {
    'auto_assign' => true,
    'assignment_method' => 'least_loaded'
  }
)

# Enterprise sales queue
enterprise_queue = Queue.create!(
  name: 'enterprise-sales',
  department: sales_dept,
  priority: 1,
  max_capacity: 5
)
```

## Performance Tuning

### 1. Queue Capacity Planning

```ruby
# Monitor queue load
queue.capacity_percentage
queue.average_wait_time
queue.current_load

# Adjust capacity based on metrics
queue.update!(max_capacity: new_capacity)
```

### 2. SLA Threshold Optimization

```ruby
# Analyze current performance
department.sla_breach_rate
queue.sla_compliance_rate

# Adjust thresholds based on data
sla_policy.update!(
  first_response_time_threshold: optimized_threshold
)
```

### 3. Agent Distribution

```ruby
# Balance agent workload across queues
queue1.agents.count
queue2.agents.count

# Reassign agents as needed
agent.queues = [queue1, queue2]
```

## Troubleshooting

### Common Issues

1. **SLA Not Triggering**
   - Verify SLA policy is assigned to conversation
   - Check if business hours configuration is correct
   - Ensure SLA job scheduler is running

2. **Incorrect Queue Assignment**
   - Verify queue is active and has capacity
   - Check agent availability in queue
   - Review routing rules configuration

3. **Missing Alerts**
   - Verify webhook URLs are accessible
   - Check Slack integration configuration
   - Review notification preferences

### Debugging Commands

```ruby
# Check SLA status
applied_sla = Conversation.first.applied_sla
applied_sla.sla_status
applied_sla.sla_events

# Queue diagnostics  
queue.is_available?
queue.within_working_hours?
queue.next_available_agent

# Department metrics
department.sla_breach_rate
department.active_conversations_count
```

## Migration Notes

When upgrading to include departments and queues:

1. **Data Migration**: Existing conversations remain unaffected
2. **Team Migration**: Teams can be converted to departments if needed
3. **SLA Migration**: Existing SLA policies continue to work
4. **Gradual Rollout**: New features can be enabled per account

## API Reference

### Departments API
- `GET /api/v1/accounts/{id}/departments` - List departments
- `POST /api/v1/accounts/{id}/departments` - Create department
- `PUT /api/v1/accounts/{id}/departments/{id}` - Update department
- `DELETE /api/v1/accounts/{id}/departments/{id}` - Delete department

### Queues API  
- `GET /api/v1/accounts/{id}/queues` - List queues
- `POST /api/v1/accounts/{id}/queues` - Create queue
- `PUT /api/v1/accounts/{id}/queues/{id}` - Update queue
- `POST /api/v1/accounts/{id}/queues/{id}/assign_agents` - Assign agents

### SLA Reports API
- `GET /api/v1/accounts/{id}/applied_slas` - SLA reports with department/queue filters
- `GET /api/v1/accounts/{id}/applied_slas/metrics` - SLA metrics
- `GET /api/v1/accounts/{id}/applied_slas/download` - Export CSV

## Best Practices

1. **Department Structure**: Align with your organizational structure
2. **Queue Priorities**: Use 1-10 scale (1 = highest priority)
3. **SLA Thresholds**: Start conservative and optimize based on data
4. **Agent Training**: Ensure agents understand queue assignments
5. **Regular Review**: Monitor compliance reports monthly
6. **Escalation Paths**: Define clear escalation procedures
7. **Webhook Security**: Always validate webhook signatures
8. **Capacity Planning**: Monitor queue loads and adjust accordingly

---

For additional support or questions, please refer to the Chatwoot documentation or contact your system administrator.