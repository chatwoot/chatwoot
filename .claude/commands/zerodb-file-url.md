---
description: Generate presigned URL for file access
---

Use the mcp__ainative-zerodb__zerodb_generate_presigned_url tool to create temporary download/upload URLs.

Example usage:
- Share files with temporary links
- Enable direct browser downloads
- Create upload URLs for clients

Key parameters:
- file_id: File ID (required)
- operation: "download" or "upload" (default: "download")
- expiration_seconds: URL expiration time (default: 3600)

Ask the user which file needs a URL, then use the tool to generate it.
