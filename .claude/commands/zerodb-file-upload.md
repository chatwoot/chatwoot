---
description: Upload a file to ZeroDB storage
---

Use the mcp__ainative-zerodb__zerodb_upload_file tool to upload files to cloud storage.

Example usage:
- Store documents, images, or any file type
- Organize files in virtual folders
- Attach metadata to files

Key parameters:
- file_name: Name of the file (required)
- file_content: Base64-encoded file content (required)
- content_type: MIME type (default: "application/octet-stream")
- folder: Virtual folder path (optional)
- metadata: Additional file metadata (optional)

Ask the user which file to upload, then use the tool to store it.
