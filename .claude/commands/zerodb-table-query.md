---
description: Query rows from a ZeroDB table
---

Use the mcp__ainative-zerodb__zerodb_query_rows tool to query data from a table.

Example usage:
- Retrieve table data with filters
- Sort and paginate results
- Project specific fields

Key parameters:
- table_id: Table name or ID (required)
- filter: MongoDB-style query filter (optional)
- limit: Maximum results (default: 100)
- offset: Pagination offset (default: 0)
- sort: Sort specification (optional)
- projection: Field projection (optional)

Ask the user what they want to query, then use the tool to execute the query.
