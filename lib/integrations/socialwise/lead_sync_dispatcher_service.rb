# frozen_string_literal: true

class Integrations::Socialwise::LeadSyncDispatcherService
  PAYLOAD_VERSION = '1.0'

  class << self
    def dispatch_contact_event(contact:, event_name:)
      return unless configured?

      payload = build_contact_payload(contact, event_name)
      return if payload.blank?

      Integrations::Socialwise::LeadSyncJob.perform_later(payload)
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-LEAD-SYNC] Failed to enqueue contact sync: #{e.class}: #{e.message}"
    end

    def dispatch_message_event(message:, event_name:)
      return unless configured?
      return unless message.incoming?
      return if message.private?

      attachments = message.attachments.filter_map(&:push_event_data)
      return if attachments.blank?

      payload = build_message_payload(message, event_name, attachments)
      return if payload.blank?

      Integrations::Socialwise::LeadSyncJob.perform_later(payload)
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-LEAD-SYNC] Failed to enqueue message sync: #{e.class}: #{e.message}"
    end

    private

    def configured?
      ENV.fetch('SOCIALWISE_WEBHOOK_URL', nil).present?
    end

    def build_contact_payload(contact, event_name)
      {
        integration: 'socialwise_lead_sync',
        event: event_name,
        account: contact.account.webhook_data,
        contact: contact.push_event_data.except(:type),
        ACCESS_TOKEN: account_access_token(contact.account),
        metadata: base_metadata(dispatch_type: 'contact', source_event: event_name)
      }.compact
    end

    def build_message_payload(message, event_name, attachments)
      contact = message.conversation.contact || message.sender

      {
        integration: 'socialwise_lead_sync',
        event: 'lead_files_sync',
        source_event: event_name,
        message_id: message.id,
        message_type: message.message_type,
        private: message.private?,
        account: message.account.webhook_data,
        inbox: message.inbox.webhook_data.merge(channel_type: message.inbox.channel_type),
        contact: contact&.push_event_data&.except(:type),
        conversation: {
          id: message.conversation.id,
          display_id: message.conversation.display_id
        },
        attachments: attachments,
        ACCESS_TOKEN: account_access_token(message.account),
        metadata: base_metadata(
          dispatch_type: 'attachment',
          source_event: event_name,
          account_id: message.account_id,
          inbox_id: message.inbox_id,
          conversation_id: message.conversation_id,
          message_id: message.id,
          skip_outgoing: true
        )
      }.compact
    end

    def account_access_token(account)
      account.administrators.first&.access_token&.token
    end

    def base_metadata(dispatch_type:, source_event:, **extra)
      {
        purpose: 'lead_sync',
        payload_version: PAYLOAD_VERSION,
        source: 'chatwit',
        dispatch_type: dispatch_type,
        source_event: source_event,
        generated_at: Time.current.iso8601
      }.merge(extra)
    end
  end
end
