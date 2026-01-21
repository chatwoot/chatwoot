---
name: background-jobs
description: Create and manage Sidekiq background jobs in Chatwoot. Use this skill when implementing async processing, scheduled tasks, webhook handlers, or any long-running operations.
metadata:
  author: chatwoot
  version: "1.0"
---

# Background Jobs (Sidekiq)

## Overview

Chatwoot uses Sidekiq for background job processing. Jobs are placed in different queues based on priority.

## Job Structure

```
app/jobs/
├── application_job.rb        # Base class
├── conversations/            # Conversation-related jobs
├── contacts/                 # Contact-related jobs
├── webhooks/                 # Webhook processing
├── reports/                  # Report generation
└── ...
```

## Creating a Job

### Basic Job

```ruby
# app/jobs/conversations/resolve_job.rb
class Conversations::ResolveJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, user_id = nil)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    user = User.find_by(id: user_id)

    Conversations::ResolveService.new(
      conversation: conversation,
      user: user
    ).perform
  end
end
```

### Job with Retries

```ruby
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  
  # Retry configuration
  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(webhook_id, payload)
    webhook = Webhook.find(webhook_id)
    
    response = deliver_webhook(webhook, payload)
    
    unless response.success?
      raise "Webhook delivery failed: #{response.status}"
    end
  end

  private

  def deliver_webhook(webhook, payload)
    HTTParty.post(
      webhook.url,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 10
    )
  end
end
```

### Unique Jobs (prevent duplicates)

```ruby
class ReportGenerationJob < ApplicationJob
  queue_as :low
  
  # Using Sidekiq Enterprise or sidekiq-unique-jobs gem
  sidekiq_options lock: :until_executed,
                  lock_ttl: 1.hour,
                  on_conflict: :reject

  def perform(account_id, report_type, date_range)
    account = Account.find(account_id)
    
    Reports::GeneratorService.new(
      account: account,
      type: report_type,
      date_range: date_range
    ).generate
  end
end
```

## Queue Configuration

```ruby
# config/sidekiq.yml
:queues:
  - [critical, 6]
  - [default, 5]
  - [mailers, 4]
  - [webhooks, 3]
  - [low, 2]
  - [scheduled, 1]

:concurrency: 10
```

### Queue Priority Guide

| Queue | Priority | Use For |
|-------|----------|---------|
| `critical` | Highest | Real-time message delivery |
| `default` | High | Standard operations |
| `mailers` | Medium | Email sending |
| `webhooks` | Medium | External webhook calls |
| `low` | Low | Reports, batch operations |
| `scheduled` | Lowest | Cron-like scheduled tasks |

## Enqueuing Jobs

### Immediate Execution

```ruby
# Enqueue for immediate processing
Conversations::ResolveJob.perform_later(conversation.id, current_user.id)

# With explicit queue
Conversations::ResolveJob.set(queue: :critical).perform_later(conversation.id)
```

### Delayed Execution

```ruby
# Run after 5 minutes
Conversations::ReopenCheckJob.set(wait: 5.minutes).perform_later(conversation.id)

# Run at specific time
ReportGenerationJob.set(wait_until: Date.tomorrow.noon).perform_later(account.id)
```

### Scheduled Jobs (Cron)

```ruby
# config/schedule.yml (using sidekiq-cron or whenever)
cleanup_old_messages:
  cron: "0 2 * * *"  # Daily at 2 AM
  class: "CleanupJob"
  queue: scheduled

daily_reports:
  cron: "0 6 * * *"  # Daily at 6 AM
  class: "DailyReportJob"
  queue: low
```

## Best Practices

### Idempotent Jobs

Design jobs to be safely re-run:

```ruby
class ProcessIncomingMessageJob < ApplicationJob
  def perform(message_params, source_id)
    # Check if already processed
    return if Message.exists?(source_id: source_id)

    Message.create!(
      **message_params,
      source_id: source_id
    )
  end
end
```

### Small Payloads

Pass IDs, not objects:

```ruby
# ✅ Good - pass ID
SendNotificationJob.perform_later(user.id, message.id)

# ❌ Bad - pass object
SendNotificationJob.perform_later(user, message)
```

### Handle Missing Records

```ruby
def perform(conversation_id)
  conversation = Conversation.find_by(id: conversation_id)
  return unless conversation  # Gracefully handle deleted records

  # Process conversation
end
```

### Batch Processing

```ruby
class BulkContactUpdateJob < ApplicationJob
  queue_as :low

  def perform(account_id, contact_ids, attributes)
    Contact.where(id: contact_ids, account_id: account_id)
           .find_each(batch_size: 100) do |contact|
      contact.update(attributes)
    end
  end
end
```

### Error Handling

```ruby
class ExternalApiJob < ApplicationJob
  queue_as :default
  
  # Retry on network errors
  retry_on Net::OpenTimeout, wait: 30.seconds, attempts: 3
  retry_on Faraday::TimeoutError, wait: 1.minute, attempts: 3
  
  # Don't retry on validation errors
  discard_on ActiveRecord::RecordInvalid
  
  # Custom error handling
  rescue_from(CustomException) do |exception|
    Rails.logger.error("Custom error: #{exception.message}")
    # Optionally re-raise to trigger retry
  end

  def perform(params)
    # Job logic
  end
end
```

## Testing Jobs

```ruby
# spec/jobs/conversations/resolve_job_spec.rb
require 'rails_helper'

RSpec.describe Conversations::ResolveJob, type: :job do
  let(:conversation) { create(:conversation, status: :open) }
  let(:user) { create(:user) }

  describe '#perform' do
    it 'resolves the conversation' do
      described_class.perform_now(conversation.id, user.id)
      
      expect(conversation.reload).to be_resolved
    end

    it 'handles missing conversation' do
      expect {
        described_class.perform_now(-1, user.id)
      }.not_to raise_error
    end
  end

  describe 'enqueuing' do
    it 'enqueues the job' do
      expect {
        described_class.perform_later(conversation.id)
      }.to have_enqueued_job(described_class)
        .with(conversation.id)
        .on_queue('default')
    end
  end
end
```

### Testing with Time

```ruby
it 'schedules job for later' do
  freeze_time do
    expect {
      described_class.set(wait: 1.hour).perform_later(id)
    }.to have_enqueued_job
      .at(1.hour.from_now)
  end
end
```

## Monitoring

### Sidekiq Web UI

Access at `/sidekiq` (admin only) to monitor:
- Queue depths
- Failed jobs
- Retry queue
- Scheduled jobs

### Logging

```ruby
class ImportantJob < ApplicationJob
  def perform(id)
    Rails.logger.info("Starting ImportantJob for #{id}")
    
    # Job logic
    
    Rails.logger.info("Completed ImportantJob for #{id}")
  rescue StandardError => e
    Rails.logger.error("ImportantJob failed: #{e.message}")
    raise
  end
end
```

## Common Patterns

### Webhook Processing

```ruby
class Webhooks::ProcessorJob < ApplicationJob
  queue_as :webhooks

  def perform(webhook_type, payload)
    processor = "Webhooks::#{webhook_type.camelize}Processor".constantize
    processor.new(payload).process
  end
end
```

### Email Sending

```ruby
class SendEmailJob < ApplicationJob
  queue_as :mailers

  def perform(mailer_class, method, *args)
    mailer_class.constantize.send(method, *args).deliver_now
  end
end

# Usage
SendEmailJob.perform_later('ConversationMailer', 'new_message', message.id)
```
