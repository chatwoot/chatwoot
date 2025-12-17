---
description: Get usage statistics and billing for your PostgreSQL instance
---

**Note:** This feature requires adding Postgres endpoints to the MCP server first.

View comprehensive usage statistics:

**API Endpoint:**
```
GET /api/v1/zerodb/projects/{project_id}/postgres/usage?hours=24
```

**Returns:**
- Total queries and credit consumption
- Average query execution time
- Top query types and patterns
- Connection utilization
- Storage usage
- Monthly cost breakdown

**Credit Billing:**
Queries are billed based on complexity and execution time. Usage is tracked in real-time and billed monthly.

To implement this, the Postgres endpoints need to be added to the ZeroDB MCP server first.
