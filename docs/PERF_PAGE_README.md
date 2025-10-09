# Performance Testing Page - /perf

## Overview

A comprehensive, public (no-login required) performance monitoring page at `/perf` to help debug connectivity and performance issues for agents.

## Access

- **URL**: `https://your-domain.com/perf`
- **Authentication**: None required (public endpoint)

## Features

### 1. **Server Connectivity Test**
- Runs 10 ping tests to measure server latency
- Shows average, min, max latency
- Displays packet loss percentage
- Color-coded results:
  - Green: < 100ms (good)
  - Yellow: 100-300ms (warning)
  - Red: > 300ms (error)

### 2. **WebSocket Connection Test**
- Tests ActionCable WebSocket connection
- Measures connection establishment time
- Shows WebSocket URL
- Detects connection failures and timeouts

### 3. **Database Connectivity Test** ⭐ NEW
- Tests PostgreSQL/database connection
- Shows query response time
- Displays database adapter type
- Shows connection pool status (active/total)
- Identifies database connectivity issues

### 4. **Redis Connectivity Test** ⭐ NEW
- Tests Redis connection
- Measures PING response time
- Shows Redis URL (with password masked)
- Verifies cache/session store connectivity

### 5. **Browser Information**
- User agent details
- Platform/OS information
- Screen resolution
- Online/offline status
- Device memory and CPU cores (if available)

### 6. **Network Quality**
- Connection type (WiFi, 4G, etc.)
- Effective connection type
- Downlink speed
- Round-trip time (RTT)
- Note: Uses Network Information API (may not be supported in all browsers)

## User Actions

### Run All Tests
Click "Run All Tests" button to execute all connectivity tests sequentially.

### Copy to Clipboard
Copies the complete test report to clipboard in text format for easy sharing.

### Download Report
Downloads a `.txt` file with all test results and detailed logs, named `chatwoot-perf-{timestamp}.txt`.

## Report Format

The generated report includes:
```
============================================================
CHATWOOT PERFORMANCE TEST REPORT
============================================================

Test Date: [timestamp]
Test URL: [current URL]

--- BROWSER INFORMATION ---
User Agent: ...
Platform: ...
Screen: ...
Online: Yes/No
Memory: X GB
CPU Cores: X

--- NETWORK INFORMATION ---
Connection Type: ...
Effective Type: ...
Downlink: ... Mbps
RTT: ... ms

--- SERVER CONNECTIVITY ---
Average Latency: X ms
Min Latency: X ms
Max Latency: X ms
Packet Loss: X%
Samples: [list of all ping times]

--- DATABASE CONNECTION ---
Status: connected/error
Response Time: X ms
Adapter: PostgreSQL
Pool Size: X
Active Connections: X

--- REDIS CONNECTION ---
Status: connected/error
Response Time: X ms
Ping Result: PONG
URL: redis://...

--- WEBSOCKET CONNECTION ---
Status: connected/error/timeout
Connection Time: X ms
URL: wss://...

--- DETAILED TEST LOG ---
[timestamp] Log entries...
```

## API Endpoints

### GET /perf
Returns the HTML performance testing page.

### GET /perf/ping
Simple server ping endpoint.
```json
{
  "timestamp": 1234567890,
  "server_time": "2025-10-06T12:00:00Z",
  "status": "ok"
}
```

### GET /perf/database
Tests database connectivity.
```json
{
  "status": "connected",
  "response_time": 5.23,
  "adapter": "PostgreSQL",
  "pool_size": 5,
  "active_connections": 2
}
```

### GET /perf/redis
Tests Redis connectivity.
```json
{
  "status": "connected",
  "response_time": 2.45,
  "ping_result": "PONG",
  "url": "redis://***@localhost:6379"
}
```

## Usage Workflow

When an agent reports connectivity or performance issues:

1. Ask them to visit `/perf` page
2. Click "Run All Tests"
3. Review the results on screen:
   - Red status = problem area
   - Yellow = potential issue
   - Green = working fine
4. Ask them to click "Copy to Clipboard" or "Download Report"
5. Have them send you the report
6. Analyze the results to identify the issue:
   - High latency → Network/server issue
   - Database errors → DB connectivity problem
   - Redis errors → Cache/session issue
   - WebSocket errors → ActionCable problem
   - Browser issues → Client-side problem

## Technical Details

### Controller
- **Location**: `app/controllers/performance_controller.rb`
- **Base Class**: `PublicController` (no authentication required)

### Routes
- **Location**: `config/routes.rb` (lines 31-35)
- All routes under `/perf` prefix

### View
- **Location**: `app/views/performance/index.html.erb`
- Self-contained HTML page with inline CSS and JavaScript
- No external dependencies
- Works without authentication

## Security Considerations

✅ **Safe to expose publicly:**
- No sensitive data exposed
- Redis password is masked in output
- Only tests connectivity, doesn't expose data
- Read-only operations
- No destructive actions

⚠ **Note:**
- Database and Redis tests run server-side queries
- Minimal performance impact (single SELECT and PING)
- Tests are lightweight and safe for production

## Color Coding

### Status Indicators
- 🟢 Green: All good, optimal performance
- 🟡 Yellow: Warning, elevated latency
- 🔴 Red: Error, connection failed or poor performance
- ⚪ Gray: Not tested yet

### Latency Thresholds

**Server Latency:**
- Good: < 100ms
- Warning: 100-300ms
- Error: > 300ms

**Database/Redis:**
- Good: < 50ms
- Warning: 50-200ms
- Error: > 200ms

**WebSocket:**
- Good: < 500ms
- Warning: 500-2000ms
- Error: > 2000ms or failed

## Auto-Run on Load

Browser and Network information are automatically collected when the page loads. Other tests require clicking "Run All Tests".

## Browser Compatibility

- Modern browsers (Chrome, Firefox, Safari, Edge)
- Network Information API may not work in all browsers (degrades gracefully)
- WebSocket support required for WebSocket test
- Clipboard API for copy functionality

## Troubleshooting

### "Database connection failed"
- Check database server status
- Verify connection string
- Check firewall rules

### "Redis connection failed"
- Check Redis server status
- Verify REDIS_URL environment variable
- Check Redis authentication

### "WebSocket timeout"
- Check ActionCable server
- Verify WEBSOCKET_URL configuration
- Check reverse proxy WebSocket support

### "High server latency"
- Network congestion
- Server overload
- Geographic distance
- ISP issues

## Future Enhancements

Potential additions:
- [ ] DNS resolution time
- [ ] SSL certificate validation
- [ ] CDN asset loading test
- [ ] Background job queue status
- [ ] Historical data comparison
- [ ] Export to JSON format
- [ ] Automated issue detection with recommendations
