# ZeroDB MCP Server Guide

This guide covers how to use the ZeroDB MCP server through custom slash commands in Claude Code.

## What is ZeroDB?

ZeroDB is a comprehensive cloud database platform that provides:
- **Vector Storage**: Store and search high-dimensional embeddings (1536 dimensions)
- **NoSQL Database**: Flexible document storage with MongoDB-style queries
- **Dedicated PostgreSQL**: Fully managed PostgreSQL instances with direct SQL access
- **File Storage**: Cloud file storage with metadata and presigned URLs
- **Agent Memory**: Persistent conversation context and semantic search
- **Event Streaming**: Publish/subscribe event system
- **Quantum Operations**: Quantum-enhanced search and compression
- **RLHF System**: Human feedback collection for agent improvement

## Available Slash Commands

### Vector Operations

**`/zerodb-vector-upsert`** - Store vector embeddings with metadata
- Use for: Semantic search, document indexing, RAG systems
- Requires: 1536-dimension vector array + document text
- Example: Store text chunk embeddings for later retrieval

**`/zerodb-vector-search`** - Search for similar vectors
- Use for: Semantic search, finding related documents
- Requires: Query vector (1536 dimensions)
- Options: Similarity threshold, metadata filters, namespace

**`/zerodb-vector-list`** - Browse stored vectors
- Use for: Viewing all vectors, pagination
- Options: Namespace filter, metadata filter, limit/offset

**`/zerodb-vector-stats`** - Get vector storage statistics
- Use for: Monitoring usage, checking vector counts
- Options: Namespace filter, detailed stats

**`/zerodb-quantum-search`** - Quantum-enhanced vector search
- Use for: Advanced similarity search with quantum boost
- Balances classical and quantum similarity weights

### NoSQL Table Operations

**`/zerodb-table-create`** - Create a new table
- Use for: Setting up data models
- Requires: Table name, schema definition (fields + indexes)

**`/zerodb-table-list`** - List all tables
- Use for: Browsing available tables
- Shows table names and schemas

**`/zerodb-table-query`** - Query table data
- Use for: Retrieving records with filters
- Supports: MongoDB-style filters, sorting, pagination, projection

**`/zerodb-table-insert`** - Insert rows into a table
- Use for: Adding new records
- Supports: Bulk inserts, returning IDs

**`/zerodb-table-update`** - Update existing rows
- Use for: Modifying records
- Supports: MongoDB operators ($set, $inc, etc.), upsert

### File Storage Operations

**`/zerodb-file-upload`** - Upload files to cloud storage
- Use for: Storing documents, images, any file type
- Requires: File name, base64-encoded content
- Options: Folder organization, metadata, content type

**`/zerodb-file-list`** - Browse uploaded files
- Use for: Viewing stored files
- Options: Folder filter, content type filter, pagination

**`/zerodb-file-download`** - Download files
- Use for: Retrieving file content
- Returns: Base64-encoded file data

**`/zerodb-file-url`** - Generate presigned URLs
- Use for: Temporary file sharing, browser downloads
- Options: Expiration time, download/upload operation

### Memory Operations

**`/zerodb-memory-store`** - Store agent conversation memory
- Use for: Building long-term agent memory
- Requires: Content, role (user/assistant/system)
- Auto-generates: Session ID, agent ID

**`/zerodb-memory-search`** - Search past conversations
- Use for: Finding relevant context from history
- Supports: Semantic search, session/agent filtering

**`/zerodb-memory-context`** - Get session context window
- Use for: Loading conversation history
- Options: Token limit control

### Event Stream Operations

**`/zerodb-event-create`** - Publish events
- Use for: Logging, workflow triggers, notifications
- Requires: Event type, event data payload

**`/zerodb-event-list`** - Query events
- Use for: Event history, monitoring
- Supports: Type/source filters, time range queries

### Project Management

**`/zerodb-project-info`** - View current project details
- Use for: Checking configuration, project metadata

**`/zerodb-project-stats`** - Get usage statistics
- Use for: Monitoring storage, API usage, resource consumption
- Shows: Vector counts, table sizes, file storage

### RLHF Operations

**`/zerodb-rlhf-feedback`** - Collect user feedback
- Use for: Agent improvement, training data collection
- Supports: Thumbs up/down, ratings (1-5), comments

### Dedicated PostgreSQL (API Only - MCP Integration Pending)

**Note:** These endpoints are available via REST API but not yet exposed as MCP tools. Use the REST API directly or help implement MCP tools for these operations.

**`/zerodb-postgres-provision`** - Provision dedicated PostgreSQL instance
- Use for: Creating managed Postgres databases
- Sizes: micro-1 ($5/mo) to performance-16 ($100/mo)
- Features: Auto-backup, monitoring, direct SQL access

**`/zerodb-postgres-status`** - Check instance status
- Use for: Monitoring instance health and metrics
- Shows: CPU, memory, storage usage, connection count

**`/zerodb-postgres-connection`** - Get connection details
- Use for: Direct SQL access via psql, ORMs, etc.
- Returns: Connection string, credentials, host/port

**`/zerodb-postgres-usage`** - View usage statistics
- Use for: Monitoring queries, credits, performance
- Shows: Query counts, execution times, billing

**`/zerodb-postgres-logs`** - View SQL query logs
- Use for: Performance optimization, debugging
- Shows: Execution time, complexity, credits per query

## Common Workflows

### 1. Semantic Search with RAG

```
1. /zerodb-vector-upsert - Store document embeddings
2. /zerodb-vector-search - Find relevant chunks
3. Use results to augment LLM prompts
```

### 2. Document Management

```
1. /zerodb-file-upload - Upload documents
2. /zerodb-file-list - Browse uploaded files
3. /zerodb-file-url - Generate shareable links
```

### 3. Data Storage and Query

```
1. /zerodb-table-create - Create schema
2. /zerodb-table-insert - Add records
3. /zerodb-table-query - Retrieve with filters
4. /zerodb-table-update - Modify records
```

### 4. Agent Memory System

```
1. /zerodb-memory-store - Save conversations
2. /zerodb-memory-search - Find relevant context
3. /zerodb-memory-context - Load session history
```

### 5. Event-Driven Architecture

```
1. /zerodb-event-create - Publish events
2. /zerodb-event-list - Monitor event stream
3. Subscribe to events for real-time updates
```

### 6. Dedicated PostgreSQL Instance (API Only)

```
1. /zerodb-postgres-provision - Create Postgres instance
2. /zerodb-postgres-status - Wait for provisioning to complete
3. /zerodb-postgres-connection - Get connection string
4. Connect with psql, pgAdmin, or any PostgreSQL client
5. /zerodb-postgres-logs - Monitor query performance
6. /zerodb-postgres-usage - Track credits and billing
```

## Direct Tool Usage

All slash commands use MCP tools under the hood. You can also ask Claude to use the tools directly:

### Vector Tools
- `mcp__ainative-zerodb__zerodb_upsert_vector`
- `mcp__ainative-zerodb__zerodb_search_vectors`
- `mcp__ainative-zerodb__zerodb_batch_upsert_vectors`
- `mcp__ainative-zerodb__zerodb_list_vectors`
- `mcp__ainative-zerodb__zerodb_vector_stats`
- `mcp__ainative-zerodb__zerodb_delete_vector`
- `mcp__ainative-zerodb__zerodb_get_vector`

### Quantum Tools
- `mcp__ainative-zerodb__zerodb_quantum_compress`
- `mcp__ainative-zerodb__zerodb_quantum_hybrid_search`
- `mcp__ainative-zerodb__zerodb_quantum_kernel`
- `mcp__ainative-zerodb__zerodb_quantum_feature_map`

### NoSQL Table Tools
- `mcp__ainative-zerodb__zerodb_create_table`
- `mcp__ainative-zerodb__zerodb_list_tables`
- `mcp__ainative-zerodb__zerodb_get_table`
- `mcp__ainative-zerodb__zerodb_delete_table`
- `mcp__ainative-zerodb__zerodb_insert_rows`
- `mcp__ainative-zerodb__zerodb_query_rows`
- `mcp__ainative-zerodb__zerodb_update_rows`
- `mcp__ainative-zerodb__zerodb_delete_rows`

### File Storage Tools
- `mcp__ainative-zerodb__zerodb_upload_file`
- `mcp__ainative-zerodb__zerodb_download_file`
- `mcp__ainative-zerodb__zerodb_list_files`
- `mcp__ainative-zerodb__zerodb_delete_file`
- `mcp__ainative-zerodb__zerodb_get_file_metadata`
- `mcp__ainative-zerodb__zerodb_generate_presigned_url`

### Memory Tools
- `mcp__ainative-zerodb__zerodb_store_memory`
- `mcp__ainative-zerodb__zerodb_search_memory`
- `mcp__ainative-zerodb__zerodb_get_context`

### Event Tools
- `mcp__ainative-zerodb__zerodb_create_event`
- `mcp__ainative-zerodb__zerodb_list_events`
- `mcp__ainative-zerodb__zerodb_get_event`
- `mcp__ainative-zerodb__zerodb_subscribe_events`
- `mcp__ainative-zerodb__zerodb_event_stats`

### Project Tools
- `mcp__ainative-zerodb__zerodb_create_project`
- `mcp__ainative-zerodb__zerodb_get_project`
- `mcp__ainative-zerodb__zerodb_list_projects`
- `mcp__ainative-zerodb__zerodb_update_project`
- `mcp__ainative-zerodb__zerodb_delete_project`
- `mcp__ainative-zerodb__zerodb_get_project_stats`
- `mcp__ainative-zerodb__zerodb_enable_database`

### RLHF Tools
- `mcp__ainative-zerodb__zerodb_rlhf_interaction`
- `mcp__ainative-zerodb__zerodb_rlhf_agent_feedback`
- `mcp__ainative-zerodb__zerodb_rlhf_workflow`
- `mcp__ainative-zerodb__zerodb_rlhf_error`
- `mcp__ainative-zerodb__zerodb_rlhf_status`
- `mcp__ainative-zerodb__zerodb_rlhf_summary`

## Authentication

The ZeroDB MCP server uses environment variables for authentication:

```bash
ZERODB_PROJECT_ID=your-project-id
ZERODB_API_KEY=your-api-key
```

Make sure these are configured in your environment or MCP server settings.

## Best Practices

1. **Vector Dimensions**: Always use 1536-dimension vectors (OpenAI ada-002 compatible)

2. **Namespaces**: Organize vectors into namespaces for better management
   - Example: "documents", "code", "chat-history"

3. **Metadata**: Add rich metadata to vectors and files for better filtering
   - Example: `{"source": "doc.pdf", "page": 5, "type": "paragraph"}`

4. **Batch Operations**: Use batch upsert for multiple vectors to reduce API calls

5. **Pagination**: Use limit/offset for large result sets

6. **Error Handling**: Check tool responses for errors and handle gracefully

7. **RLHF**: Collect feedback consistently to improve agent performance

## Tips

- Use `/zerodb-project-stats` regularly to monitor usage
- Leverage quantum search for better semantic matching
- Store agent memories to build long-term context
- Use events for workflow automation
- Organize files in folders for better management
- Add indexes to frequently queried table fields

## Dedicated PostgreSQL - MCP Integration

The dedicated PostgreSQL endpoints are available via REST API at:
```
https://api.ainative.studio/v1/zerodb/projects/{project_id}/postgres
```

**To add MCP support**, the following tools need to be implemented in `zerodb-mcp-server/index.js`:
- `zerodb_provision_postgres` - Provision instance
- `zerodb_get_postgres_status` - Get instance status
- `zerodb_get_postgres_connection` - Get connection details
- `zerodb_restart_postgres` - Restart instance
- `zerodb_delete_postgres` - Delete instance
- `zerodb_get_postgres_usage` - Get usage stats
- `zerodb_get_postgres_logs` - Get query logs

Once these tools are added, the slash commands will work seamlessly through the MCP server.

## Support

For issues or questions about ZeroDB:
- API Docs: https://api.ainative.studio/docs
- GitHub: Check project repository for issues
