# Captain MCP Servers

## Overview

Captain MCP Servers integrate external [Model Context Protocol](https://modelcontextprotocol.io/) services into Chatwoot's Captain AI assistants. MCP servers expose tools (functions) that the LLM can call during conversations, allowing assistants to search documentation, query APIs, browse the web, and more.

**Feature flag:** `captain_mcp` (requires `captain` to also be enabled)
**Enterprise only:** Requires Enterprise installation or Chatwoot Cloud with the Captain plan.

---

## Architecture

```
User Message
    |
    v
Captain Assistant (LLM)
    |
    v
Tool Selection (RubyLLM)
    |
    +--> SearchDocumentation (built-in)
    +--> MCP Tool 1 (dynamic)
    +--> MCP Tool 2 (dynamic)
         |
         v
    Captain::Mcp::ClientService
         |
         v
    ruby-mcp-client gem (HTTP)
         |
         v
    Remote MCP Server
```

### Key Components

| File | Purpose |
|------|---------|
| `enterprise/app/models/captain/mcp_server.rb` | Model: stores server config, auth, cached tools |
| `enterprise/app/models/concerns/mcp_toolable.rb` | Dynamically builds RubyLLM tool classes from cached MCP tool schemas |
| `enterprise/app/services/captain/mcp/client_service.rb` | Connects to MCP servers, calls tools, handles SSRF protection |
| `enterprise/app/services/captain/mcp/discovery_service.rb` | Connects + discovers available tools from an MCP server |
| `enterprise/lib/captain/tools/mcp_tool.rb` | Base class for dynamically generated MCP tool instances |
| `enterprise/app/models/captain/assistant_mcp_server.rb` | Join model: links assistants to MCP servers with optional tool filters |
| `enterprise/app/services/captain/llm/assistant_chat_service.rb` | Builds the tool list (built-in + MCP) for LLM chat completion |
| `enterprise/app/controllers/api/v1/accounts/captain/mcp_servers_controller.rb` | REST API for CRUD, connect, disconnect, refresh |

---

## Supported MCP Servers

### Transport Protocols

The integration uses the [`ruby-mcp-client`](https://rubygems.org/gems/ruby-mcp-client) gem (v0.9.1). Supported transports:

| Transport | Supported | Notes |
|-----------|-----------|-------|
| **Streamable HTTP** | Yes | Default. Most modern MCP servers use this. The gem auto-detects transport from the URL. |
| **SSE (Server-Sent Events)** | Yes | Legacy transport. Some older MCP servers still use this. |
| **stdio** | No | Requires spawning a local subprocess. Not supported in this integration (server-side only). |

### What Works

- **Public HTTPS MCP servers** with streamable HTTP or SSE transport
- **Authentication:** None, Bearer token, or API key (custom header name supported)
- **Tool discovery:** Automatic on connect, manual refresh available
- **Tool filtering:** Per-assistant include/exclude lists for which tools to expose
- **Tool execution:** LLM calls tools during chat, results returned as text
- **Response types:** Text, image placeholders (`[Image: mime/type]`), resource links
- **Response truncation:** Responses larger than 1MB are safely truncated (UTF-8 aware)
- **Multiple assistants:** Same MCP server can be attached to multiple assistants with different tool filters
- **Credential encryption:** `auth_config` is encrypted at rest when `Chatwoot.encryption_configured?` is true

### What Does Not Work

| Limitation | Reason |
|------------|--------|
| **stdio transport** | The `ruby-mcp-client` gem supports it, but this integration only connects via HTTP. Stdio requires spawning a local process, which isn't suitable for a multi-tenant server. |
| **Private/internal MCP servers** | SSRF protection blocks connections to private IPs (10.x, 172.16.x, 192.168.x, 127.x, link-local, CGN, IPv6 private). |
| **IP address URLs** | URL validation rejects raw IP addresses. Must use hostnames. |
| **localhost / .local domains** | Explicitly blocked for security. |
| **Complex tool parameter types** | RubyLLM's `Parameter` only supports scalar types (`string`, `integer`, `number`, `boolean`). Tool params with `array` or `object` types are **coerced to `string`**. The LLM will typically pass JSON-formatted strings, but MCP servers that strictly validate types may reject them. |
| **Binary/streaming tool responses** | Only text-based responses are supported. Images are represented as placeholders. |
| **OAuth / session-based auth** | Only static Bearer tokens and API keys are supported. No OAuth flow, no session cookies. |
| **Bidirectional communication** | MCP servers can't push notifications back to Chatwoot. Communication is request-response only. |

---

## Tested MCP Servers

| Server | URL | Status | Notes |
|--------|-----|--------|-------|
| Cloudflare Docs | `https://developers.cloudflare.com/mcp` | Works | Streamable HTTP, no auth required |
| OpenAI Docs | `https://developers.openai.com/mcp` | Partial | Connects and discovers tools, but `get_openapi_spec` tool has a `languages` array param without `items` schema. Coerced to string; may not work perfectly. |
| Context7 | `https://mcp.context7.com/mcp` | Works | Documentation search, streamable HTTP |

### How to Test a New MCP Server

1. Go to **Settings > Captain > MCP Servers**
2. Click **Add Server**, provide name and HTTPS URL
3. Click **Connect** - the system will:
   - Resolve the hostname and verify it's not a private IP
   - Connect via the detected transport (streamable HTTP or SSE)
   - Discover all available tools
4. Attach the server to an assistant (Settings > Captain > Assistants > Edit > MCP Servers)
5. Optionally filter which tools the assistant can use
6. Test in the assistant playground

---

## Auth Configuration

The `auth_config` field is a JSON object stored as encrypted text. Structure depends on `auth_type`:

### `none` (default)
```json
{}
```

### `bearer`
```json
{
  "token": "your-bearer-token"
}
```
Sent as: `Authorization: Bearer your-bearer-token`

### `api_key`
```json
{
  "key": "your-api-key",
  "header_name": "X-API-Key"
}
```
`header_name` defaults to `X-API-Key` if not specified.

### Advanced Options

These can be set in `auth_config` for non-standard MCP servers:

```json
{
  "token": "...",
  "transport": "streamable_http",
  "rpc_endpoint": "/custom/rpc"
}
```

| Field | Description |
|-------|-------------|
| `transport` | Force transport type: `streamable_http` or `sse`. Auto-detected if omitted. |
| `rpc_endpoint` | Custom JSON-RPC endpoint path. Only needed if the server uses a non-standard path. |

---

## Security

### SSRF Protection

Before connecting, the system resolves the hostname and checks the IP against a blocklist:

| Range | Description |
|-------|-------------|
| `0.0.0.0/8` | Current network |
| `127.0.0.0/8` | Loopback |
| `10.0.0.0/8` | Private class A |
| `172.16.0.0/12` | Private class B |
| `192.168.0.0/16` | Private class C |
| `169.254.0.0/16` | Link-local (includes AWS/GCP metadata at 169.254.169.254) |
| `100.64.0.0/10` | Carrier-grade NAT (RFC 6598) |
| `::1/128` | IPv6 loopback |
| `fc00::/7` | IPv6 unique local |
| `fe80::/10` | IPv6 link-local |
| `::ffff:0:0/96` | IPv4-mapped IPv6 |

### URL Validation (Model-level)

- Must use `http://` or `https://` scheme
- Must have a hostname (no bare IPs)
- Cannot point to `localhost`, `.local` domains, or the Chatwoot frontend host
- Raw IP addresses (IPv4, IPv6, octal, hex) are rejected

### Credential Security

- `auth_config` is stored as encrypted text (when encryption is configured)
- `auth_config` is excluded from audit logs (`audited except: [:auth_config]`)
- API responses mask credentials (show `has_token: true` instead of actual token)
- Credentials are preserved on update if not explicitly provided

### Response Limits

- Tool responses are truncated to **1MB** using `truncate_bytes` (UTF-8 safe)
- Connection timeout: **30 seconds**

---

## API Endpoints

All endpoints require administrator permissions and the `captain_mcp` feature flag.

```
GET    /api/v1/accounts/:account_id/captain/mcp_servers
POST   /api/v1/accounts/:account_id/captain/mcp_servers
GET    /api/v1/accounts/:account_id/captain/mcp_servers/:id
PATCH  /api/v1/accounts/:account_id/captain/mcp_servers/:id
DELETE /api/v1/accounts/:account_id/captain/mcp_servers/:id
POST   /api/v1/accounts/:account_id/captain/mcp_servers/:id/connect
POST   /api/v1/accounts/:account_id/captain/mcp_servers/:id/disconnect
POST   /api/v1/accounts/:account_id/captain/mcp_servers/:id/refresh
```

---

## Data Model

### captain_mcp_servers

| Column | Type | Description |
|--------|------|-------------|
| `name` | string | Display name |
| `slug` | string | Auto-generated, unique per account. Format: `mcp_{parameterized_name}` |
| `url` | string | MCP server endpoint URL |
| `auth_type` | enum | `none`, `bearer`, `api_key` |
| `auth_config` | text | Encrypted JSON with credentials and advanced options |
| `enabled` | boolean | Whether the server is active |
| `status` | enum | `disconnected`, `connecting`, `connected`, `error` |
| `last_error` | text | Last connection error message |
| `last_connected_at` | datetime | Timestamp of last successful connection |
| `cached_tools` | jsonb | Array of tool definitions discovered from the server |
| `cache_refreshed_at` | datetime | When tools were last refreshed |

### captain_assistant_mcp_servers

| Column | Type | Description |
|--------|------|-------------|
| `captain_assistant_id` | bigint | FK to assistant |
| `captain_mcp_server_id` | bigint | FK to MCP server |
| `enabled` | boolean | Whether this link is active |
| `tool_filters` | jsonb | `{"include": ["tool1"], "exclude": ["tool2"]}` |

---

## Known Limitations and Future Work

1. **Complex parameter types (array/object):** Currently coerced to `string`. A future improvement could generate proper nested JSON Schema by extending the tool registration to pass raw `inputSchema` directly to the LLM provider instead of going through RubyLLM's `param` abstraction.

2. **No retry on transient failures:** Connection retries are set to 0. Tool calls that fail due to transient network issues are not retried.

3. **No webhook/push support:** MCP servers can't notify Chatwoot when tools change. Must manually refresh.

4. **Single DNS resolution:** The SSRF check resolves the hostname once at connect time. A DNS rebinding attack could theoretically change the IP after the check. The `ruby-mcp-client` gem uses Faraday which re-resolves DNS on each request.

5. **No connection pooling:** Each tool call creates a new `ClientService` instance and reconnects. This adds latency but avoids stale connection issues.

6. **Tool name length:** Function names are capped at 64 characters (`mcp_{slug}_{tool_name}`). Very long tool names may be truncated and collide.
