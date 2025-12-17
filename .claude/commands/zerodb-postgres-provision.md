---
description: Provision a dedicated PostgreSQL instance for your project
---

**Note:** This feature requires adding Postgres endpoints to the MCP server first.

The ZeroDB API provides dedicated PostgreSQL instance provisioning with:

**Available Instance Sizes:**
- **micro-1**: $5/month - 0.25 CPU, 0.25GB RAM, 1GB storage
- **standard-2**: $10/month - 0.5 CPU, 0.5GB RAM, 5GB storage
- **standard-4**: $25/month - 1 CPU, 1GB RAM, 20GB storage
- **performance-8**: $50/month - 2 CPU, 2GB RAM, 50GB storage
- **performance-16**: $100/month - 4 CPU, 4GB RAM, 100GB storage

**API Endpoint:**
```
POST /api/v1/zerodb/projects/{project_id}/postgres
```

**Request Body:**
```json
{
  "instance_size": "standard-2",
  "postgres_version": "15",
  "tags": []
}
```

To use this feature, first check with the user if the Postgres endpoints have been added to the ZeroDB MCP server. If not, suggest using the REST API directly with curl or implementing the MCP tools.
