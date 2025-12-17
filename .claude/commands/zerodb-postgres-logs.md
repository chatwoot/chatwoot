---
description: View SQL query logs and performance data
---

**Note:** This feature requires adding Postgres endpoints to the MCP server first.

Get recent SQL query logs with performance metrics:

**API Endpoint:**
```
GET /api/v1/zerodb/projects/{project_id}/postgres/logs?limit=100
```

**Query Parameters:**
- `limit`: Number of logs to return (default: 100)
- `query_type`: Filter by query type (SELECT, INSERT, UPDATE, DELETE)

**Returns:**
- Query execution time and complexity score
- Credit consumption per query
- Rows affected
- Client IP address
- Timestamp

**Use for:**
- Performance optimization
- Identifying slow queries
- Monitoring query patterns
- Debugging issues

To implement this, the Postgres endpoints need to be added to the ZeroDB MCP server first.
