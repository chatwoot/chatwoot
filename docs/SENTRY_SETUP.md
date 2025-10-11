# Sentry Error & Performance Monitoring Setup

This document describes the complete Sentry integration for error tracking, performance monitoring, and structured logging across our Rails + Vue.js monolithic application.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)
- [Features](#features)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What's Integrated

- ✅ **Backend Error Tracking** (Rails, Sidekiq)
- ✅ **Frontend Error Tracking** (Dashboard Vue.js)
- ✅ **Widget Error Tracking** (Customer-facing Vue.js widget)
- ✅ **Performance Test Logging** (Structured logs to Sentry)
- ✅ **Customer Attribution** (Widget errors linked to customer details)
- ✅ **Lazy-Loaded Widget Sentry** (Minimal bundle impact)

### Technology Stack

- **Backend**: sentry-ruby, sentry-rails, sentry-sidekiq (>= 5.24.0)
- **Frontend**: @sentry/vue (8.31.0)
- **Environments**: devnet, prod-india

---

## Architecture

### Monolithic App = Single Sentry DSN

Since this is a monolithic Rails + Vue app, **one Sentry DSN is used for all components**:

```
SENTRY_DSN → Backend (Rails) errors
          → Dashboard (Vue.js) errors
          → Widget (Vue.js) errors
          → Performance logs
```

### Error Flow

```
┌─────────────────────────────────────────────────────┐
│                   SENTRY PROJECT                     │
│              (One DSN for Everything)                │
└─────────────────────────────────────────────────────┘
                          ↑
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────────┐       ┌──────────┐     ┌──────────┐
   │ Rails  │       │Dashboard │     │  Widget  │
   │Backend │       │ (Vue.js) │     │(Vue.js)  │
   └────────┘       └──────────┘     └──────────┘

   • Errors        • Errors         • Errors
   • Logs          • Performance    • Customer Context
   • Sidekiq       • Crashes        • Lazy-Loaded
```

---

## Setup Instructions

### 1. Get Sentry DSN

#### Option A: Existing Sentry Project
1. Login to https://sentry.io
2. Select your project
3. Go to **Settings → Client Keys (DSN)**
4. Copy the DSN

#### Option B: Create New Project
1. Sign up at https://sentry.io (free tier available)
2. Create project:
   - **Platform**: JavaScript (Vue) or Ruby
   - **Name**: `chatwoot` or `chatwoot-monolith`
3. Copy the DSN from setup page

### 2. Install Dependencies

The required gems are already in the Gemfile:

```ruby
gem 'sentry-rails', '>= 5.24.0', require: false
gem 'sentry-ruby', '>= 5.24.0', require: false
gem 'sentry-sidekiq', '>= 5.24.0', require: false
```

Run bundle install:

```bash
bundle install
```

### 3. Configure Environment Variables

Add to `.env` file:

```bash
# Sentry Configuration (REQUIRED)
SENTRY_DSN=https://your-key@o123456.ingest.sentry.io/789012

# Custom Environment Name (REQUIRED for proper grouping)
APP_ENVIRONMENT=devnet  # or prod-india

# Optional: Enable Performance Monitoring
ENABLE_SENTRY_TRANSACTIONS=true

# Optional: Disable PII Tracking (email, names, etc.)
# DISABLE_SENTRY_PII=true
```

### 4. Restart Application

```bash
# Docker
docker compose restart

# Local
rails server restart
```

---

## Configuration

### Backend Configuration

**File**: `config/initializers/sentry.rb`

```ruby
if ENV['SENTRY_DSN'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.environment = ENV['APP_ENVIRONMENT'] || Rails.env
    config.enabled_environments = %w[devnet prod-india]

    # Performance monitoring (10% sample rate)
    config.traces_sample_rate = 0.1 if ENV['ENABLE_SENTRY_TRANSACTIONS']

    # Exclude noisy exceptions
    config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException']

    # PII tracking (user emails, names)
    config.send_default_pii = true unless ENV['DISABLE_SENTRY_PII']

    # Enable Sentry Logs (requires sentry-ruby >= 5.24.0)
    config.enable_logs = true
  end
end
```

### Frontend Configuration (Dashboard)

**File**: `app/views/layouts/vueapp.html.erb`

```erb
window.errorLoggingConfig = '<%= ENV.fetch('SENTRY_FRONTEND_DSN', '') || ENV.fetch('SENTRY_DSN', '') %>'
window.chatwootEnv = '<%= ENV.fetch('APP_ENVIRONMENT', Rails.env) %>'
```

**File**: `app/javascript/entrypoints/dashboard.js`

```javascript
if (window.errorLoggingConfig) {
  Sentry.init({
    app,
    dsn: window.errorLoggingConfig,
    environment: window.chatwootEnv || 'production',
    integrations: [Sentry.browserTracingIntegration({ router })],
    tracesSampleRate: 0.1,
  });
}
```

### Widget Configuration (Lazy-Loaded)

**File**: `app/views/widgets/show.html.erb`

```erb
window.errorLoggingConfig = '<%= ENV.fetch('SENTRY_FRONTEND_DSN', '') || ENV.fetch('SENTRY_DSN', '') %>'
window.chatwootEnv = '<%= ENV.fetch('APP_ENVIRONMENT', Rails.env) %>'
```

**File**: `app/javascript/entrypoints/widget.js`

Widget Sentry is **lazy-loaded** to minimize bundle size impact:

- **Initial load**: 0 KB (Sentry not loaded)
- **On first error**: Sentry dynamically imported (~40-50 KB)
- **After 2 seconds**: Sentry loaded in background

```javascript
// Lazy-load Sentry on first error or after page load
const Sentry = await import(/* webpackChunkName: "sentry" */ '@sentry/vue');
```

---

## Features

### 1. Backend Error Tracking

All Rails errors are automatically captured and sent to Sentry with:
- Stack traces
- Request context (URL, params, headers)
- User context (if authenticated)
- Environment (devnet/prod-india)

**Example:**
```ruby
begin
  risky_operation
rescue StandardError => e
  # Automatically captured by Sentry
  raise e
end
```

### 2. Structured Logging (Sentry Logs)

Performance test results are logged as **structured, searchable logs** in Sentry.

**File**: `app/controllers/performance_controller.rb`

```ruby
# POST /perf/log
def log_test_results
  Sentry.logger.info(
    'Performance test completed - test_type: %{test_type}, server_latency: %{server_latency}ms',
    test_type: 'all_tests',
    environment: 'devnet',
    server_latency: 45.2,
    db_time: 12.5,
    redis_time: 8.3,
    # ... more metrics
  )
end
```

**View in Sentry:**
- Go to **Logs** tab
- Filter by: `message:"Performance test completed"`
- Query attributes: `server_latency:>100` or `test_type:file_transfer`

### 3. Customer Attribution (Widget)

Widget errors automatically include customer details for better support:

**Captured Data:**
```json
{
  "user": {
    "id": "76640",
    "email": "customer@example.com",
    "username": "John Doe"
  },
  "context": {
    "contact": {
      "identifier": "815719",
      "phone_number": "+1234567890",
      "availability_status": "online",
      "created_at": 1759987468,
      "last_activity_at": 1759990286
    }
  }
}
```

**Security:** Sensitive fields (`auth_token`, `password`, `secret`) are automatically filtered.

### 4. Widget Error Tracking

Widget tracks specific error types:

| Error Type | Component | Description |
|------------|-----------|-------------|
| `attachment_download_failure` | ImageBubble | Image failed to load |
| `attachment_download_failure` | VideoBubble | Video failed to load |
| `file_download_failure` | FileBubble | File download/open failed |
| `file_upload_failure` | ChatAttachment | Direct/indirect upload failed |

**Query Examples:**
```
# All widget errors
error_type:attachment_download_failure

# Errors from specific customer
user.email:"customer@example.com"

# Errors in devnet
environment:devnet
```

### 5. Performance Monitoring

Backend performance is tracked (opt-in via `ENABLE_SENTRY_TRANSACTIONS=true`):

- Database query time
- HTTP request duration
- Background job performance
- External API calls

**Sample Rate**: 10% of requests (configurable)

---

## Usage Examples

### Backend: Capture Custom Error

```ruby
begin
  process_payment(order)
rescue PaymentError => e
  Sentry.capture_exception(e, {
    level: :error,
    tags: { order_type: 'subscription' },
    extra: { order_id: order.id, amount: order.amount }
  })
  raise e
end
```

### Backend: Log Structured Data

```ruby
# Performance metrics
Sentry.logger.info(
  'Database query slow - table: %{table}, duration: %{duration}ms',
  table: 'users',
  duration: 523.4,
  query_type: 'SELECT'
)

# Business events
Sentry.logger.warn(
  'Rate limit reached for endpoint %{endpoint}',
  endpoint: '/api/results/',
  user_id: 123,
  ip_address: request.remote_ip
)
```

### Frontend Dashboard: Capture Error

```javascript
try {
  await fetchData();
} catch (error) {
  Sentry.captureException(error, {
    level: 'error',
    tags: { feature: 'dashboard_analytics' }
  });
}
```

### Frontend Widget: Lazy Error Tracking

Widget components use the helper to ensure lazy loading:

```javascript
import { captureSentryException } from '../helpers/sentry';

captureSentryException(new Error('Widget: Image failed to load'), {
  level: 'warning',
  tags: { component: 'ImageBubble', error_type: 'attachment_download_failure' },
  extra: { imageUrl: this.url }
});
```

---

## Troubleshooting

### No Errors Appearing in Sentry

1. **Check DSN is set:**
   ```bash
   echo $SENTRY_DSN
   # Should output: https://...@sentry.io/...
   ```

2. **Check environment is enabled:**
   ```bash
   echo $APP_ENVIRONMENT
   # Should output: devnet or prod-india
   ```

3. **Verify Sentry is initialized:**
   ```ruby
   # Rails console
   Sentry.configuration.dsn
   # Should output your DSN
   ```

4. **Test manually:**
   ```ruby
   # Rails console
   Sentry.capture_message("Test error from devnet")
   # Check Sentry dashboard
   ```

### Widget Errors Not Showing

1. **Check browser console:**
   - Should see: `window.__CHATWOOT_SENTRY_LOADED__` after ~2 seconds
   - Or after first error

2. **Check Network tab:**
   - Look for Sentry chunk loading: `sentry-*.js`
   - Look for POST requests to `sentry.io`

3. **Verify customer context:**
   ```javascript
   // Browser console in widget
   window.__CHATWOOT_SENTRY_LOADED__  // Should be true after load
   ```

### Logs Not Appearing in Sentry

1. **Check gem version:**
   ```bash
   bundle list | grep sentry
   # Should show: sentry-ruby (5.24.0 or higher)
   ```

2. **Check config:**
   ```ruby
   # Rails console
   Sentry.configuration.enable_logs
   # Should output: true
   ```

3. **Test logs:**
   ```ruby
   # Rails console
   Sentry.logger.info('Test log message', test_key: 'test_value')
   # Check Sentry → Logs tab
   ```

### Too Many Errors

**Ignore specific errors:**

```ruby
# config/initializers/sentry.rb
config.excluded_exceptions += [
  'ActionController::RoutingError',
  'ActiveRecord::RecordNotFound'
]
```

**Reduce sample rate:**

```ruby
# config/initializers/sentry.rb
config.traces_sample_rate = 0.01  # 1% instead of 10%
```

### Widget Bundle Size Impact

Widget Sentry is lazy-loaded:

- **Before first error**: 0 KB impact
- **After first error/2s delay**: ~40-50 KB loaded async
- **No session replay**: Saves ~30-40 KB
- **No performance monitoring**: Saves bandwidth

**Disable widget Sentry** (if needed):
```bash
# Don't set SENTRY_DSN in production
unset SENTRY_DSN
```

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SENTRY_DSN` | ✅ Yes | None | Sentry project DSN (same for backend/frontend) |
| `APP_ENVIRONMENT` | ✅ Yes | `Rails.env` | Environment name (devnet, prod-india) |
| `ENABLE_SENTRY_TRANSACTIONS` | ❌ No | `false` | Enable performance monitoring (10% sample) |
| `DISABLE_SENTRY_PII` | ❌ No | `false` | Disable PII tracking (emails, names) |
| `SENTRY_FRONTEND_DSN` | ❌ No | `SENTRY_DSN` | Separate DSN for frontend (optional, for multi-project setups) |

---

## Testing in Each Environment

### devnet

```bash
# Set environment
export APP_ENVIRONMENT=devnet
export SENTRY_DSN=your-dsn-here

# Test backend
rails console
> Sentry.capture_message("Test from devnet backend")

# Test frontend
# Open /app in browser, check console
> Sentry.captureMessage("Test from devnet dashboard")

# Test widget
# Open widget, trigger error (invalid file upload)
# Check Sentry for customer details
```

### prod-india

```bash
# Set environment
export APP_ENVIRONMENT=prod-india
export SENTRY_DSN=your-dsn-here

# Same tests as devnet
```

---

## Best Practices

### ✅ DO

- Use `Sentry.logger.info/warn/error` for structured logs
- Add meaningful tags: `{ feature: 'payments', user_type: 'premium' }`
- Include context in logs: user_id, order_id, etc.
- Filter sensitive data before logging
- Use appropriate log levels (info, warn, error, fatal)

### ❌ DON'T

- Don't log PII directly (use Sentry's user context instead)
- Don't log at high frequency (causes noise)
- Don't include secrets/tokens in logs
- Don't use for debugging in development (use Rails.logger)

---

## Sentry Dashboard Tips

### Filter Widget Errors

```
# All widget errors
component:ImageBubble OR component:VideoBubble OR component:FileBubble

# Specific customer
user.email:"customer@example.com"

# Specific error type
error_type:attachment_download_failure
```

### Filter Performance Logs

```
# View performance tests
message:"Performance test completed"

# Slow tests
server_latency:>100

# Failed tests
websocket_status:error
```

### Create Alerts

1. Go to **Alerts** → **Create Alert Rule**
2. **Condition**: `error_type:file_upload_failure`
3. **Action**: Email team
4. **Frequency**: At most once per hour

---

## Architecture Decisions

### Why Single DSN?

- **Simpler setup**: One DSN to configure
- **Unified errors**: All errors in one project
- **Cost-effective**: One Sentry project
- **Easy filtering**: Use tags/environment for separation

### Why Lazy-Load Widget Sentry?

- **Performance**: Customer websites load ~100 KB faster
- **On-demand**: Only loads when needed
- **Same tracking**: No loss of error capture
- **Privacy-first**: Minimal data collection

### Why Sentry Logs over capture_message?

- **Structured**: Queryable attributes (server_latency, db_time)
- **Searchable**: Filter by any attribute
- **Analytics**: Create dashboards from logs
- **Standards**: Follows Sentry best practices

---

## Support

For issues or questions:

1. Check this documentation
2. Check Sentry docs: https://docs.sentry.io
3. Check application logs: `docker compose logs -f rails`
4. Open GitHub issue with relevant logs

---

## Changelog

### 2025-10-09
- ✅ Initial Sentry setup for backend, dashboard, widget
- ✅ Implemented lazy-loaded widget Sentry
- ✅ Added customer attribution for widget errors
- ✅ Integrated performance test logging with Sentry Logs
- ✅ Upgraded to sentry-ruby 5.24.0+ for logs feature
- ✅ Created comprehensive documentation

---

**Last Updated**: October 9, 2025
**Maintained By**: Engineering Team
**Sentry Version**: sentry-ruby 5.24.0+, @sentry/vue 8.31.0
