---
description: Create a new NoSQL table in ZeroDB
---

Use the mcp__ainative-zerodb__zerodb_create_table tool to create a new table with a schema.

Example usage:
- Create tables for storing structured data
- Define field types and indexes
- Set up data models

Key parameters:
- table_name: Unique table name (required)
- schema: Schema definition with fields and indexes (required)
  - fields: Object defining field names and types
  - indexes: Array of index definitions
- description: Table description (optional)

Ask the user for table requirements, then use the tool to create the table.
