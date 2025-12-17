---
description: Upsert a vector embedding with metadata to ZeroDB
---

Use the mcp__ainative-zerodb__zerodb_upsert_vector tool to store a vector embedding (1536 dimensions) with associated document and metadata.

Example usage:
- Store embeddings from text chunks for semantic search
- Index document vectors with metadata for filtering
- Update existing vectors by providing vector_id

Key parameters:
- vector_embedding: Array of 1536 numbers (required)
- document: Source text or document (required)
- metadata: JSON object with additional info (optional)
- namespace: Organize vectors into namespaces (default: "default")
- vector_id: For updating existing vectors (optional)

Ask the user what they want to upsert, then use the tool to execute the operation.
