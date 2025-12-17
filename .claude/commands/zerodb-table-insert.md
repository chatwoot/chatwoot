---
description: Insert rows into a ZeroDB table
---

Use the mcp__ainative-zerodb__zerodb_insert_rows tool to insert data into a table.

Example usage:
- Add new records to a table
- Bulk insert multiple rows
- Get inserted row IDs

Key parameters:
- table_id: Table name or ID (required)
- rows: Array of row objects to insert (required)
- return_ids: Return inserted row IDs (default: true)

Ask the user what data to insert, then use the tool to add the rows.
