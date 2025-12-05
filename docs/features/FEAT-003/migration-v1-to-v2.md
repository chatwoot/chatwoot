# FEAT-003: Migration Guide - Version 1.0 to 2.0

## Overview

This guide provides instructions for migrating from the initial audio transcription feature (Version 1.0) to the enhanced multi-channel version (Version 2.0).

### What's New in Version 2.0

**Key Enhancements**:
- **Multi-Channel Support**: Transcription now works across all channels (Widget, WhatsApp, Email, etc.), not just API
- **Background Processing**: Non-blocking async transcription with Sidekiq
- **Real-Time Updates**: ActionCable broadcasts for instant UI updates
- **Integration-Based Config**: Per-account API key configuration via UI
- **Language Detection**: Automatic language detection and metadata storage
- **Retry Logic**: Exponential backoff for transient failures (2s, 4s, 8s)
- **Custom Exceptions**: Better error handling and monitoring

### Version Comparison

| Feature | Version 1.0 | Version 2.0 |
|---------|-------------|-------------|
| Channel Support | API only | All channels |
| Processing | Synchronous (blocking) | Asynchronous (background) |
| API Key Config | Environment variable only | Integration + Environment fallback |
| Language Detection | No | Yes (with metadata) |
| Retry Logic | No | Yes (exponential backoff) |
| Real-Time UI | No | Yes (ActionCable) |
| Error Handling | Basic logging | Custom exceptions + retry |

---

## Backward Compatibility

**Good News**: Version 2.0 is fully backward compatible with Version 1.0.

**No Breaking Changes**:
- Existing environment variable configuration continues to work
- API-based transcription still functions
- Message format remains unchanged
- No database migrations required
- Feature can be enabled/disabled via flag

**Migration Strategy**: Zero-downtime upgrade with gradual rollout support.

---

## Migration Steps

### Step 1: Verify Current State

Before upgrading, verify your Version 1.0 configuration:

```bash
# Check if transcription is currently enabled
rails console
> ENV['OPENAI_API_KEY'].present?
# Should return true if configured

# Check recent transcriptions
> Message.where("content LIKE '%Transcription:%'").count
```

**Expected State**:
- `OPENAI_API_KEY` environment variable set
- Audio messages have transcriptions in content field
- Transcriptions processed synchronously

### Step 2: Deploy Version 2.0 Code

Deploy the new version to your environment:

```bash
# Pull latest changes
git checkout feature/audio-transcription
git pull origin feature/audio-transcription

# Install dependencies (if any new gems added)
bundle install

# Restart application
pnpm dev
# or
overmind restart
```

**New Files Deployed**:
- `app/listeners/audio_transcription_listener.rb`
- `app/jobs/transcribe_audio_message_job.rb`
- `app/services/openai/exceptions.rb`
- `config/initializers/listeners.rb`

**Modified Files**:
- `app/services/openai/audio_transcription_service.rb`
- `config/integration/apps.yml`

### Step 3: Configuration Migration (Optional)

You have two options for configuration:

#### Option A: Keep Environment Variable (No Changes Required)

If you prefer to continue using the global environment variable:

```bash
# Your existing .env configuration
OPENAI_API_KEY=sk-proj-abc123...
AUDIO_TRANSCRIPTION_ENABLED=true
```

**Behavior**:
- All accounts share the same API key
- Works immediately after deployment
- No UI configuration needed
- Suitable for single-tenant deployments

#### Option B: Migrate to Integration-Based Config (Recommended)

For per-account API key management:

1. **Navigate to Settings → Integrations**
2. **Select "OpenAI" integration**
3. **Configure per account**:
   ```
   API Key: sk-proj-[your-key]
   ☑ Enable audio transcription
   ☑ Detect and store audio language
   ```
4. **Save configuration**

**Benefits**:
- Per-account usage tracking
- Independent billing per workspace
- No server restart required for changes
- Better multi-tenant support

**Migration Path**:
- Environment variable serves as fallback
- Configure integrations gradually per account
- Remove environment variable when all accounts configured

### Step 4: Verify Background Jobs

Ensure Sidekiq is running and configured:

```bash
# Check Sidekiq is running
ps aux | grep sidekiq

# Or via Procfile.dev
cat Procfile.dev | grep worker
# Should show: worker: bundle exec sidekiq

# Monitor Sidekiq logs
tail -f log/sidekiq.log
```

**Expected Output**:
```
Sidekiq starting
Registered jobs: TranscribeAudioMessageJob
Listening on queues: default
```

**If Sidekiq not running**:
```bash
# Start via overmind
overmind start

# Or manually
bundle exec sidekiq
```

### Step 5: Test Multi-Channel Transcription

Verify transcription works across different channels:

**Test Checklist**:
- [ ] Send audio via API endpoint → Verify async transcription
- [ ] Send audio via Widget → Verify transcription appears
- [ ] Send audio via WhatsApp → Verify transcription works
- [ ] Send audio via Email → Verify transcription processes
- [ ] Check message updates in real-time (no refresh needed)

**Testing Script**:
```bash
# Monitor transcription jobs
rails console
> TranscribeAudioMessageJob.jobs.count
# Should increase when audio messages sent

# Check recent transcriptions
> Message.order(created_at: :desc).limit(10).pluck(:id, :content)
```

### Step 6: Monitor and Validate

Monitor the system for 24-48 hours after deployment:

**Metrics to Track**:
1. **Transcription Success Rate**:
   ```ruby
   # Rails console
   total = TranscribeAudioMessageJob.jobs.count
   failed = Sidekiq::RetrySet.new.select { |job| job.klass == 'TranscribeAudioMessageJob' }.count
   success_rate = ((total - failed).to_f / total * 100).round(2)
   puts "Success rate: #{success_rate}%"
   ```

2. **Average Processing Time**:
   - Check Sidekiq dashboard for job latency
   - Target: <30 seconds for most transcriptions

3. **Error Rates**:
   ```bash
   # Check logs for errors
   grep "Openai::.*Error" log/production.log | wc -l
   ```

4. **ActionCable Updates**:
   - Verify messages update in UI without refresh
   - Check browser console for WebSocket errors

**Expected Metrics**:
- Success rate: >95%
- Average latency: 5-30 seconds
- Error rate: <5%
- Zero WebSocket disconnections

---

## Rollback Procedures

If issues arise, you can rollback to Version 1.0 behavior:

### Quick Rollback (Feature Flag)

Disable async processing without code changes:

```bash
# Add to .env
AUDIO_TRANSCRIPTION_ENABLED=false

# Restart application
pnpm dev
```

**Effect**:
- Transcription disabled entirely
- Messages created normally with audio
- No background jobs enqueued

### Partial Rollback (Listener Only)

Disable listener but keep synchronous processing:

```ruby
# config/initializers/listeners.rb
# Comment out the listener subscription
# Rails.application.config.after_initialize do
#   AudioTranscriptionListener.new.subscribe
# end
```

**Effect**:
- API transcription continues (sync)
- Multi-channel transcription disabled
- Background jobs not created

### Full Rollback (Code Revert)

Revert to Version 1.0 commit:

```bash
# Checkout Version 1.0 commit
git checkout 11d2bc818

# Restart application
pnpm dev
```

**Effect**:
- Complete rollback to Version 1.0
- Synchronous API-only transcription
- No multi-channel support

---

## Troubleshooting

### Issue: Transcriptions Not Appearing

**Symptoms**: Audio messages don't have transcriptions

**Diagnosis**:
```bash
# Check API key configuration
rails console
> ENV['OPENAI_API_KEY'].present?

# Check listener is subscribed
> AudioTranscriptionListener.subscribers.count
# Should be > 0

# Check Sidekiq is running
> Sidekiq.redis { |c| c.info }
```

**Solutions**:
1. Verify API key is configured (ENV or Integration)
2. Ensure Sidekiq is running
3. Check Rails logs for errors
4. Verify feature flag is enabled

### Issue: Slow Transcription

**Symptoms**: Transcriptions take >60 seconds to appear

**Diagnosis**:
```bash
# Check Sidekiq queue depth
redis-cli
> LLEN queue:default

# Check OpenAI API status
curl https://status.openai.com/api/v2/status.json
```

**Solutions**:
1. Scale Sidekiq workers: `SIDEKIQ_CONCURRENCY=10`
2. Check network latency to OpenAI
3. Verify no rate limiting (429 errors)
4. Consider increasing timeout values

### Issue: Integration API Key Not Used

**Symptoms**: Environment variable used instead of integration config

**Diagnosis**:
```ruby
# Rails console
account = Account.find(123)
integration = account.integrations.find_by(name: 'openai')
integration.settings['api_key'].present?
# Should return true if configured
```

**Solutions**:
1. Verify integration saved correctly in UI
2. Check integration settings structure
3. Review service API key resolution logic
4. Ensure no caching issues

### Issue: ActionCable Not Updating UI

**Symptoms**: Transcriptions don't appear without page refresh

**Diagnosis**:
```javascript
// Browser console
window.App.cable.connection.isActive()
// Should return true
```

**Solutions**:
1. Verify ActionCable is enabled
2. Check WebSocket connection in Network tab
3. Review broadcast code in job
4. Ensure correct conversation channel subscribed

---

## Feature Flags

Version 2.0 supports granular feature control:

### Global Feature Flag

```bash
# .env
AUDIO_TRANSCRIPTION_ENABLED=true  # Enable/disable globally
```

### Account-Level Feature Flag

```ruby
# app/models/account.rb
def audio_transcription_enabled?
  # Check account-specific feature flag
  feature_flags['audio_transcription'] != false
end
```

### Gradual Rollout Strategy

**Week 1**: Enable for internal accounts only
```ruby
# config/initializers/feature_flags.rb
AUDIO_TRANSCRIPTION_ACCOUNTS = [1, 2, 3]  # Internal account IDs

# In listener
def should_transcribe?(message)
  AUDIO_TRANSCRIPTION_ACCOUNTS.include?(message.account_id)
end
```

**Week 2**: Enable for beta accounts
```ruby
AUDIO_TRANSCRIPTION_ACCOUNTS = Account.where(beta: true).pluck(:id)
```

**Week 3**: Enable for all accounts
```ruby
# Remove restriction, enable globally
AUDIO_TRANSCRIPTION_ENABLED=true
```

---

## Performance Considerations

### Sidekiq Scaling

For high-volume deployments:

```bash
# Increase Sidekiq concurrency
export SIDEKIQ_CONCURRENCY=25

# Add dedicated transcription queue
# config/sidekiq.yml
:queues:
  - [transcription, 2]  # Higher priority
  - [default, 1]
```

### Rate Limiting

Prevent OpenAI rate limit issues:

```ruby
# app/jobs/transcribe_audio_message_job.rb
queue_as :transcription
rate_limit 60, per: 1.minute  # Max 60 transcriptions/minute
```

### Cost Optimization

Monitor and control costs:

```ruby
# Add cost tracking
class TranscriptionUsage < ApplicationRecord
  belongs_to :account

  def self.monthly_cost(account_id)
    where(account_id: account_id)
      .where('created_at >= ?', 1.month.ago)
      .sum(:cost)
  end
end
```

---

## FAQ

### Q: Do I need to re-transcribe existing audio messages?

**A**: No. Version 2.0 only processes new audio messages. Existing transcriptions remain in message content.

If you want to backfill historical messages:
```bash
# Rake task (create if needed)
rake transcription:backfill[start_date,end_date]
```

### Q: Can I use both environment variable and integration config?

**A**: Yes. The system follows a priority order:
1. Integration API key (per-account)
2. Environment variable `OPENAI_API_KEY` (global fallback)
3. Disabled (if neither available)

### Q: What happens if Sidekiq crashes during transcription?

**A**: Sidekiq's retry mechanism handles this:
- Job is retried automatically (exponential backoff)
- Maximum 3 retry attempts
- After exhaustion, error is logged
- Message remains accessible with audio attachment

### Q: How do I disable transcription for specific accounts?

**A**: Use account-level feature flags:
```ruby
# In Rails console
account = Account.find(123)
account.update(feature_flags: { audio_transcription: false })
```

### Q: Does Version 2.0 support the same audio formats as Version 1.0?

**A**: Yes, identical format support:
- MP3, M4A, WAV, WebM, MPEG, MPGA
- Maximum 25 MB file size
- All formats supported by OpenAI Whisper

### Q: How do I monitor transcription costs per account?

**A**: Use integration-based configuration for automatic tracking, or implement custom analytics:
```ruby
# Example: Track usage in integration logs
Integration::OpenAI.log_usage(
  account: account,
  duration: audio_duration,
  cost: (audio_duration / 60.0) * 0.006
)
```

---

## Support

**Documentation**:
- Main Feature Docs: `docs/features/FEAT-003/README.md`
- Implementation Guide: `docs/features/FEAT-003/enhancement-story.md`

**Internal Support**:
- Engineering: #engineering-support
- Product: #product-questions

**External Resources**:
- OpenAI Whisper Docs: https://platform.openai.com/docs/guides/speech-to-text
- Sidekiq Docs: https://github.com/sidekiq/sidekiq/wiki

---

## Document Metadata

- **Feature**: FEAT-003 Audio Transcription Migration
- **Version**: 1.0 → 2.0
- **Created**: 2025-01-04
- **Author**: Engineering Team
- **Migration Type**: Zero-downtime, backward compatible
