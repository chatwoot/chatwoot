---
description: Get connection details for your dedicated PostgreSQL instance
---

**Note:** This feature requires adding Postgres endpoints to the MCP server first.

Get direct connection credentials for your dedicated PostgreSQL instance:

**API Endpoint:**
```
GET /api/v1/zerodb/projects/{project_id}/postgres/connection
```

**Query Parameters:**
- `credential_type`: "primary" (full access), "readonly", or "admin"

**Returns:**
- database_url: Full connection string
- host, port, database: Connection parameters
- username, password: Credentials
- connection_string: Formatted connection string

**Use with any PostgreSQL client:**
```bash
psql postgresql://username:password@host:port/database
```

Or use with Python, Node.js, or any ORM that supports PostgreSQL.

To implement this, the Postgres endpoints need to be added to the ZeroDB MCP server first.
