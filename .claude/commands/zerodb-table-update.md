---
description: Update rows in a ZeroDB table
---

Use the mcp__ainative-zerodb__zerodb_update_rows tool to update existing table data.

Example usage:
- Update records matching a filter
- Use MongoDB-style update operators ($set, $inc, etc.)
- Upsert if records don't exist

Key parameters:
- table_id: Table name or ID (required)
- filter: MongoDB-style query filter (required)
- update: Update operations object (required)
- upsert: Insert if not found (default: false)

Ask the user what to update, then use the tool to modify the rows.
