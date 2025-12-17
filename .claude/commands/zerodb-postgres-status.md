---
description: Check the status of your dedicated PostgreSQL instance
---

**Note:** This feature requires adding Postgres endpoints to the MCP server first.

Get detailed status and metrics for your PostgreSQL instance:

**API Endpoint:**
```
GET /api/v1/zerodb/projects/{project_id}/postgres
```

**Returns:**
- Status: provisioning, active, maintenance, error
- Resource usage: CPU, memory, storage
- Connection count and performance metrics
- Billing information
- Health check status

**Instance States:**
- **provisioning**: Instance is being created (typically 2-3 minutes)
- **active**: Instance is running and ready
- **maintenance**: Scheduled maintenance in progress
- **error**: Issue with the instance (check error_message)

To implement this, the Postgres endpoints need to be added to the ZeroDB MCP server first.
