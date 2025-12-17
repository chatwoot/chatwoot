---
description: Search for similar vectors in ZeroDB using semantic similarity
---

Use the mcp__ainative-zerodb__zerodb_search_vectors tool to find vectors similar to a query vector.

Example usage:
- Find similar documents or text chunks
- Semantic search across embedded content
- Filter results by metadata

Key parameters:
- query_vector: Array of 1536 numbers (required)
- limit: Maximum number of results (default: 10)
- threshold: Similarity threshold 0-1 (default: 0.7)
- namespace: Search within specific namespace (optional)
- filter_metadata: Filter by metadata fields (optional)

Ask the user for their search requirements, then use the tool to execute the search.
