# frozen_string_literal: true

# lib/integrations/jusmonitoria/processor_service.rb
# Routes Chatwit events to JusMonitorIA via WebhookForwarderService.
# For message.received events, also processes sync responses from JusMonitorIA.

class Integrations::Jusmonitoria::ProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  LABEL_PREFIX = 'jusmonitoria_'

  EVENT_HANDLERS = {
    'contact.created' => :handle_contact_created,
    'contact.updated' => :handle_contact_updated,
    'message.created' => :handle_message_created,
    'conversation.updated' => :handle_conversation_updated,
    'conversation.resolved' => :handle_conversation_resolved
  }.freeze

  def perform
    log_processing_started
    dispatch_event
    log_processing_completed
  rescue StandardError => e
    capture_processing_error(e)
  end

  private

  def handle_contact_created
    contact = event_data[:contact]
    return if contact.blank?

    Rails.logger.info "[JUSMONITORIA] Forwarding contact.created for contact #{contact.id}"
    Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'contact.created',
      payload: contact.webhook_data,
      account: contact.account
    )
  end

  def handle_contact_updated
    contact = event_data[:contact]
    return if contact.blank?

    Rails.logger.info "[JUSMONITORIA] Forwarding contact.updated for contact #{contact.id}"
    Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'contact.updated',
      payload: contact.webhook_data,
      account: contact.account
    )
  end

  def handle_message_created
    message = event_data[:message]
    return if message.blank?

    conversation = message.conversation
    return unless conversation_has_jusmonitoria_label?(conversation)
    return unless message.incoming?

    Rails.logger.info "[JUSMONITORIA] Forwarding message.received for message #{message.id} in conversation #{conversation.id}"

    payload = {
      message: message.webhook_data,
      contact: conversation.contact&.webhook_data,
      conversation: conversation_payload(conversation),
      inbox: inbox_payload(conversation.inbox)
    }

    response = Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'message.received',
      payload: payload,
      account: conversation.account
    )

    # Process sync response from JusMonitorIA (bidirecional)
    process_sync_response(message, response) if response.present? && response.success?
  end

  def handle_conversation_updated
    conversation = event_data[:conversation]
    label_changes = extract_label_changes(event_data[:changed_attributes])
    return if conversation.blank? || label_changes.blank?

    previous_labels = Array(label_changes[:previous_value] || label_changes[0])
    current_labels = Array(label_changes[:current_value] || label_changes[1])

    forward_label_changes(conversation, current_labels - previous_labels, 'tag.added', 'Tag added')
    forward_label_changes(conversation, previous_labels - current_labels, 'tag.removed', 'Tag removed')
  end

  def extract_label_changes(changed_attributes)
    return if changed_attributes.blank?
    return extract_label_changes_from_array(changed_attributes) if changed_attributes.is_a?(Array)

    extract_label_changes_from_hash(changed_attributes)
  end

  def extract_label_changes_from_array(changed_attributes)
    changed_attributes.find { |attribute| label_changes_attribute?(attribute) }&.values&.first
  end

  def extract_label_changes_from_hash(changed_attributes)
    changed_attributes['label_list'] || changed_attributes[:label_list]
  end

  def label_changes_attribute?(attribute)
    attribute.key?('label_list') || attribute.key?(:label_list)
  end

  def dispatch_event
    handler = EVENT_HANDLERS[event_name]
    handler.present? ? send(handler) : log_unhandled_event
  end

  def log_processing_started
    Rails.logger.info '[JUSMONITORIA] === ProcessorService.perform ==='
    Rails.logger.info "[JUSMONITORIA] Event: #{event_name}, Hook: #{hook.id}"
  end

  def log_processing_completed
    Rails.logger.info '[JUSMONITORIA] === ProcessorService.perform completed ==='
  end

  def capture_processing_error(error)
    Rails.logger.error "[JUSMONITORIA] ProcessorService error: #{error.class}: #{error.message}"
    Rails.logger.error "[JUSMONITORIA] Backtrace: #{error.backtrace.first(5).join("\n")}"
    ChatwootExceptionTracker.new(error, account: hook&.account).capture_exception
  end

  def log_unhandled_event
    Rails.logger.info "[JUSMONITORIA] Unhandled event: #{event_name}"
  end

  def forward_label_changes(conversation, labels, event_type, log_action)
    labels.select { |label| label.to_s.start_with?(LABEL_PREFIX) }.each do |label|
      Rails.logger.info "[JUSMONITORIA] #{log_action}: #{label} on conversation #{conversation.id}"

      Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
        event_type: event_type,
        payload: { tag: label, conversation: conversation_payload(conversation) },
        account: conversation.account
      )
    end
  end

  def handle_conversation_resolved
    conversation = event_data[:conversation]
    return if conversation.blank?
    return unless conversation_has_jusmonitoria_label?(conversation)

    Rails.logger.info "[JUSMONITORIA] Forwarding conversation.resolved for conversation #{conversation.id}"
    Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
      event_type: 'conversation.resolved',
      payload: { conversation: conversation_payload(conversation) },
      account: conversation.account
    )
  end

  # --- Helpers ---

  def conversation_has_jusmonitoria_label?(conversation)
    conversation.cached_label_list_array.any? { |label| label.start_with?(LABEL_PREFIX) }
  end

  def monitoring_label_prefix
    hook.settings&.dig('monitoring_label_prefix').presence || LABEL_PREFIX
  end

  def conversation_payload(conversation)
    data = conversation.webhook_data
    data[:labels] = conversation.cached_label_list_array
    data[:contact] = conversation.contact&.webhook_data
    data[:inbox] = inbox_payload(conversation.inbox)
    data
  end

  def inbox_payload(inbox)
    return {} if inbox.blank?

    payload = { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type }
    payload[:provider] = inbox.channel.provider if inbox.whatsapp? && inbox.channel.respond_to?(:provider)
    payload
  end

  # --- Sync Response Processing (bidirecional) ---

  def process_sync_response(message, http_response)
    body = parse_response_body(http_response)
    return if body.blank?

    # Check for async flag — JusMonitorIA will respond later via Agent Bot API
    return if body['async'] == true

    Rails.logger.info "[JUSMONITORIA] Processing sync response for message #{message.id}"
    Integrations::Jusmonitoria::ResponseProcessor.new(message: message, response: body).perform
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA] Error processing sync response: #{e.class}: #{e.message}"
  end

  def parse_response_body(http_response)
    return nil unless http_response.respond_to?(:parsed_response)

    body = http_response.parsed_response
    body.is_a?(Hash) ? body : JSON.parse(body)
  rescue JSON::ParserError, TypeError
    nil
  end
end
