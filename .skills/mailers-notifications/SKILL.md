---
name: mailers-notifications
description: Create and customize email notifications and mailers in Chatwoot. Use this skill when implementing email templates, notification triggers, or customizing email delivery.
metadata:
  author: chatwoot
  version: "1.0"
---

# Mailers & Email Notifications

## Overview

Chatwoot uses Action Mailer for email delivery with support for custom templates, attachments, and tracking.

## Structure

```
app/mailers/
├── application_mailer.rb                    # Base mailer
├── conversation_reply_mailer.rb             # Reply notifications
├── conversation_reply_mailer_helper.rb      # Helper methods
├── administrator_notifications/             # Admin emails
├── agent_notifications/                     # Agent emails
└── team_notifications/                      # Team emails

app/views/
└── mailers/                                 # Email templates
    ├── conversation_reply_mailer/
    └── agent_notifications/
```

## Creating a Mailer

### Basic Mailer

```ruby
# app/mailers/agent_notifications/new_conversation_mailer.rb
class AgentNotifications::NewConversationMailer < ApplicationMailer
  def new_conversation(conversation, agent)
    @conversation = conversation
    @agent = agent
    @account = conversation.account

    subject = I18n.t(
      'mailer.new_conversation.subject',
      inbox: conversation.inbox.name
    )

    mail(
      to: agent.email,
      subject: subject,
      reply_to: reply_email
    )
  end

  private

  def reply_email
    "reply+#{@conversation.uuid}@#{mail_domain}"
  end

  def mail_domain
    ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN', 'chatwoot.com')
  end
end
```

### Conversation Reply Mailer

```ruby
# app/mailers/conversation_reply_mailer.rb
class ConversationReplyMailer < ApplicationMailer
  include ConversationReplyMailerHelper
  include ConversationReplyMailerAttachmentHelper

  default from: -> { default_from_email }

  def reply_with_summary(conversation, last_message_id)
    @conversation = conversation
    @contact = conversation.contact
    @inbox = conversation.inbox
    @account = conversation.account
    @messages = recent_messages(conversation, last_message_id)

    return unless @contact.email.present?

    configure_mail_settings

    mail(
      to: @contact.email,
      subject: email_subject,
      message_id: message_id_header,
      in_reply_to: in_reply_to_header
    ) do |format|
      format.html { render 'reply_with_summary' }
      format.text { render 'reply_with_summary' }
    end
  end

  private

  def configure_mail_settings
    return unless custom_email_domain?

    mail.delivery_method.settings.merge!(
      smtp_settings_for(@inbox)
    )
  end

  def email_subject
    "[##{@conversation.display_id}] #{@conversation.additional_attributes['mail_subject'] || default_subject}"
  end

  def default_subject
    I18n.t('mailer.conversation_reply.subject', account_name: @account.name)
  end

  def recent_messages(conversation, last_id)
    conversation.messages
                .outgoing
                .where('id >= ?', last_id)
                .includes(:attachments)
                .order(created_at: :asc)
  end
end
```

## Email Templates

### HTML Template

```erb
<!-- app/views/mailers/conversation_reply_mailer/reply_with_summary.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .message {
      background: #f5f5f5;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 16px;
    }
    .message-header {
      font-size: 12px;
      color: #666;
      margin-bottom: 8px;
    }
    .attachment {
      display: inline-block;
      background: #e0e0e0;
      padding: 8px 12px;
      border-radius: 4px;
      margin: 4px;
      text-decoration: none;
      color: #333;
    }
    .footer {
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid #eee;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <p><%= t('mailer.conversation_reply.greeting', name: @contact.name) %></p>

  <% @messages.each do |message| %>
    <div class="message">
      <div class="message-header">
        <%= message.sender&.name || @account.name %> •
        <%= l(message.created_at, format: :short) %>
      </div>
      <div class="message-content">
        <%= simple_format(message.content) %>
      </div>
      
      <% if message.attachments.any? %>
        <div class="attachments">
          <% message.attachments.each do |attachment| %>
            <%= link_to attachment.file.filename, 
                        url_for(attachment.file), 
                        class: 'attachment' %>
          <% end %>
        </div>
      <% end %>
    </div>
  <% end %>

  <p><%= t('mailer.conversation_reply.reply_instruction') %></p>

  <div class="footer">
    <p>
      <%= t('mailer.conversation_reply.footer', account_name: @account.name) %>
    </p>
    <p>
      <a href="<%= unsubscribe_url(@contact) %>">
        <%= t('mailer.common.unsubscribe') %>
      </a>
    </p>
  </div>
</body>
</html>
```

### Text Template

```erb
<!-- app/views/mailers/conversation_reply_mailer/reply_with_summary.text.erb -->
<%= t('mailer.conversation_reply.greeting', name: @contact.name) %>

<% @messages.each do |message| %>
---
<%= message.sender&.name || @account.name %> (<%= l(message.created_at, format: :short) %>):

<%= message.content %>

<% if message.attachments.any? %>
Attachments:
<% message.attachments.each do |attachment| %>
- <%= url_for(attachment.file) %>
<% end %>
<% end %>
<% end %>
---

<%= t('mailer.conversation_reply.reply_instruction') %>

--
<%= t('mailer.conversation_reply.footer', account_name: @account.name) %>
<%= t('mailer.common.unsubscribe') %>: <%= unsubscribe_url(@contact) %>
```

## Triggering Emails

### From Service

```ruby
# app/services/notification/email_notification_service.rb
class Notification::EmailNotificationService
  def initialize(conversation:, message:)
    @conversation = conversation
    @message = message
    @account = conversation.account
  end

  def perform
    return unless should_send_email?

    send_agent_notification if notify_agent?
    send_contact_notification if notify_contact?
  end

  private

  def should_send_email?
    @account.email_notifications_enabled? && 
      @conversation.inbox.email_notifications_enabled?
  end

  def notify_agent?
    @message.incoming? && @conversation.assignee.present?
  end

  def notify_contact?
    @message.outgoing? && @conversation.contact.email.present?
  end

  def send_agent_notification
    AgentNotifications::NewMessageMailer
      .new_message(@conversation, @message, @conversation.assignee)
      .deliver_later
  end

  def send_contact_notification
    ConversationReplyMailer
      .reply_with_summary(@conversation, @message.id)
      .deliver_later(wait: 1.minute) # Debounce for quick replies
  end
end
```

### From Job

```ruby
# app/jobs/send_reply_email_job.rb
class SendReplyEmailJob < ApplicationJob
  queue_as :mailers

  def perform(conversation_id, message_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    ConversationReplyMailer
      .reply_with_summary(conversation, message_id)
      .deliver_now
  rescue StandardError => e
    Rails.logger.error("Email delivery failed: #{e.message}")
    raise if should_retry?(e)
  end

  private

  def should_retry?(error)
    error.is_a?(Net::SMTPServerBusy) || 
      error.is_a?(Net::OpenTimeout)
  end
end
```

## Email Configuration

### SMTP Settings

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
  enable_starttls_auto: true
}
```

### Custom Domain per Inbox

```ruby
# app/models/inbox.rb
class Inbox < ApplicationRecord
  def smtp_settings
    return {} unless custom_email_enabled?

    {
      address: email_settings['smtp_address'],
      port: email_settings['smtp_port'],
      user_name: email_settings['smtp_username'],
      password: email_settings['smtp_password'],
      authentication: email_settings['smtp_authentication']
    }
  end
end
```

## Notification Preferences

```ruby
# app/models/notification_setting.rb
class NotificationSetting < ApplicationRecord
  belongs_to :user
  belongs_to :account

  FLAGS = {
    email_conversation_creation: 1,
    email_conversation_assignment: 2,
    email_new_message: 4,
    email_mention: 8
  }.freeze

  def email_enabled?(flag)
    (email_flags & FLAGS[flag]).positive?
  end
end
```

## Testing Mailers

```ruby
# spec/mailers/conversation_reply_mailer_spec.rb
require 'rails_helper'

RSpec.describe ConversationReplyMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, email: 'customer@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

  describe '#reply_with_summary' do
    subject(:mail) { described_class.reply_with_summary(conversation, message.id) }

    it 'sends email to contact' do
      expect(mail.to).to eq(['customer@example.com'])
    end

    it 'includes conversation ID in subject' do
      expect(mail.subject).to include("##{conversation.display_id}")
    end

    it 'renders message content' do
      expect(mail.body.encoded).to include(message.content)
    end

    context 'when contact has no email' do
      let(:contact) { create(:contact, account: account, email: nil) }

      it 'does not send email' do
        expect(mail.message).to be_a(ActionMailer::Base::NullMail)
      end
    end
  end
end
```

## Email Previews

```ruby
# spec/mailers/previews/conversation_reply_mailer_preview.rb
class ConversationReplyMailerPreview < ActionMailer::Preview
  def reply_with_summary
    conversation = Conversation.first
    message = conversation.messages.outgoing.last
    
    ConversationReplyMailer.reply_with_summary(conversation, message.id)
  end
end

# Access at: /rails/mailers/conversation_reply_mailer/reply_with_summary
```

## Best Practices

1. **Always use `deliver_later`** for non-critical emails
2. **Include unsubscribe links** in all marketing/notification emails
3. **Test both HTML and text versions** of emails
4. **Use I18n** for all email content
5. **Handle bounces and complaints** via webhooks
6. **Set proper reply-to headers** for conversation threading
