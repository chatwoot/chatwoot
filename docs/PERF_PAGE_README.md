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

### 2. **WebSocket Connection Test** (Comprehensive)
- Tests ActionCable WebSocket connection with multiple scenarios:
  - **Initial Connection**: Establishes WebSocket and measures connection time
  - **Message Round-trip**: Sends test message and measures echo response time
  - **Reconnection**: Tests disconnection and automatic reconnection capability
- Shows WebSocket URL (dynamically constructed from current page)
- Detects connection failures and timeouts
- Works correctly in both HTTP (ws://) and HTTPS (wss://) environments
- Compatible with Docker Compose, localhost, and production deployments

### 3. **Database Connectivity Test** ⭐ NEW
- Tests PostgreSQL/database connection
- Shows query response time
- Displays database adapter type
- Shows connection pool status (active/total)
- Identifies database connectivity issues

### 4. **Redis Connectivity Test**
- Tests Redis connection
- Measures PING response time
- Shows Redis URL (with password masked)
- Verifies cache/session store connectivity

### 5. **File Transfer Performance Test** ⭐ NEW
- Tests storage service (S3/local) upload and download performance
- Upload test:
  - Measures file upload time to storage service
  - Calculates upload throughput (Mbps)
  - Shows file size and server processing time
- Download test:
  - Measures file download time from storage service
  - Calculates download throughput (Mbps)
  - Tests direct S3 signed URLs (multi-pod compatible)
- Sample file download:
  - Provides pre-generated sample files for testing
  - Available sizes: 1MB, 5MB, 10MB
  - Useful for testing without uploading
- Storage service detection:
  - Automatically detects: Amazon S3, S3-compatible, Google Cloud, Azure, or Local
  - Shows storage region/location
- Automatic cleanup of test files after completion
- **Note**: Download test requires proper S3 CORS configuration for localhost testing (see Troubleshooting section)

### 6. **Browser Information**
- User agent details
- Platform/OS information
- Screen resolution
- Online/offline status
- Device memory and CPU cores (if available)

### 7. **Network Quality**
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
Initial Connection Time: X ms
Message Round-trip Time: X ms
Reconnection Time: X ms
URL: wss://...

--- FILE TRANSFER PERFORMANCE ---
Status: success/error
Storage Service: Amazon S3
Region: ap-south-1
Upload Time: X ms
Upload Speed: X Mbps
Download Time: X ms
Download Speed: X Mbps
File Size: X MB

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

### POST /perf/upload
Uploads a test file to storage service and returns performance metrics.

**Request**: `multipart/form-data` with `file` field

**Response**:
```json
{
  "status": "success",
  "blob_id": "abc123",
  "file_size": 1048576,
  "file_size_mb": 1.0,
  "server_upload_time": 450.23,
  "throughput_mbps": 18.52,
  "download_url": "https://bucket.s3.amazonaws.com/key?...",
  "storage_service": "Amazon",
  "region": "ap-south-1"
}
```

### DELETE /perf/cleanup/:blob_id
Deletes a test file from storage.

**Response**:
```json
{
  "status": "success",
  "message": "File deleted"
}
```

### GET /perf/sample?size=:size
Downloads a pre-generated sample file for testing.

**Query Parameters**:
- `size`: File size in MB (1, 5, or 10)

**Response**: Binary file download

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
   - Slow file transfers → Storage service or bandwidth issue
   - Browser issues → Client-side problem

## Technical Details

### Controller
- **Location**: `app/controllers/performance_controller.rb`
- **Base Class**: `PublicController` (no authentication required)

### Routes
- **Location**: `config/routes.rb` (lines 31-39)
- All routes under `/perf` prefix:
  - `GET /perf` - Main page
  - `GET /perf/ping` - Server ping
  - `GET /perf/database` - Database test
  - `GET /perf/redis` - Redis test
  - `POST /perf/upload` - File upload test
  - `DELETE /perf/cleanup/:blob_id` - Cleanup test file
  - `GET /perf/sample` - Download sample file

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
- Read-only operations (except file upload test)
- File upload test automatically cleans up after completion
- S3 URLs are time-limited signed URLs (expire after 1 hour)

⚠ **Note:**
- Database and Redis tests run server-side queries
- File upload test creates temporary ActiveStorage blobs (automatically deleted)
- Minimal performance impact (single SELECT, PING, and optional file transfer)
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

**File Transfer:**
- Good: > 10 Mbps
- Warning: 1-10 Mbps
- Error: < 1 Mbps

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
- Check ActionCable server is running
- Verify WEBSOCKET_URL environment variable (optional, auto-detected if not set)
- Check reverse proxy WebSocket support (nginx/Apache)
- Ensure WebSocket endpoint `/cable` is accessible
- For Docker Compose: WebSocket URL is automatically constructed from page location

### "WebSocket connection to 'wss://localhost/cable' failed"
- **Localhost Testing**: WebSocket URL is now dynamically constructed from current page
- Access via `http://localhost:3000/perf` → uses `ws://localhost:3000/cable`
- Access via `https://domain.com/perf` → uses `wss://domain.com/cable`
- No manual WEBSOCKET_URL configuration needed for standard setups

### "High server latency"
- Network congestion
- Server overload
- Geographic distance
- ISP issues

### "File upload/download CORS error" (S3 Only)
**Problem**: `Access to fetch at 'https://bucket.s3.amazonaws.com/...' has been blocked by CORS policy`

**Solution**: Add CORS configuration to S3 bucket:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "HEAD"],
        "AllowedOrigins": [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "https://your-production-domain.com"
        ],
        "ExposeHeaders": ["ETag", "Content-Length"],
        "MaxAgeSeconds": 3000
    }
]
```

Apply via AWS CLI:
```bash
aws s3api put-bucket-cors \
  --bucket your-bucket-name \
  --cors-configuration file://cors.json \
  --region your-region
```

Or via AWS Console: S3 → Bucket → Permissions → Cross-origin resource sharing (CORS)

### "File upload works but download test fails"
- Check S3 CORS configuration (see above)
- Verify S3 signed URLs are being generated correctly
- Check browser console for specific CORS error
- Ensure `ACTIVE_STORAGE_SERVICE` environment variable is set correctly

### "Slow file transfer speed"
- Network bandwidth limitation
- S3 region far from user location
- Server resource constraints
- Large file size relative to connection speed

## Environment Variables

### Optional Configuration

- **WEBSOCKET_URL**: WebSocket endpoint URL
  - Default: Auto-detected from current page (`ws://` or `wss://` + hostname + `/cable`)
  - Example: `wss://your-domain.com/cable`
  - Only set if using non-standard WebSocket endpoint

- **ACTIVE_STORAGE_SERVICE**: Storage service type
  - Options: `amazon`, `s3_compatible`, `google`, `microsoft`, `local`
  - Default: `local`
  - Affects file transfer test

- **ACTIVE_STORAGE_CACHE_CONTROL**: S3 cache headers
  - Default: `public, max-age=3600`
  - Controls browser caching of S3 files

## Recent Updates

### 2025-10-09
- ✅ Added comprehensive WebSocket testing (connection, message round-trip, reconnection)
- ✅ Added file transfer performance testing with S3 support
- ✅ Fixed WebSocket URL construction for Docker Compose/localhost
- ✅ Added direct S3 signed URL support (multi-pod compatible)
- ✅ Added sample file download feature (1MB, 5MB, 10MB)
- ✅ Added automatic test file cleanup
- ✅ Improved error logging for file uploads

## Future Enhancements

Potential additions:
- [ ] DNS resolution time
- [ ] SSL certificate validation
- [ ] CDN asset loading test
- [ ] Background job queue status
- [ ] Historical data comparison
- [ ] Export to JSON format
- [ ] Automated issue detection with recommendations
- [ ] Multi-region S3 performance comparison
- [ ] Image processing performance test (ActiveStorage variants)
