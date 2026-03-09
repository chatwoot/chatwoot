# frozen_string_literal: true

# lib/integrations/jusmonitoria/processor_service.rb
# Routes Chatwit events to JusMonitorIA via WebhookForwarderService.
# For message.received events, also processes sync responses from JusMonitorIA.

class Integrations::Jusmonitoria::ProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  LABEL_PREFIX = 'jusmonitoria_'

  def perform
    Rails.logger.info "[JUSMONITORIA] === ProcessorService.perform ==="
    Rails.logger.info "[JUSMONITORIA] Event: #{event_name}, Hook: #{hook.id}"

    case event_name
    when 'contact.created'
      handle_contact_created
    when 'contact.updated'
      handle_contact_updated
    when 'message.created'
      handle_message_created
    when 'conversation.updated'
      handle_conversation_updated
    when 'conversation.resolved'
      handle_conversation_resolved
    else
      Rails.logger.info "[JUSMONITORIA] Unhandled event: #{event_name}"
    end

    Rails.logger.info "[JUSMONITORIA] === ProcessorService.perform completed ==="
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA] ProcessorService error: #{e.class}: #{e.message}"
    Rails.logger.error "[JUSMONITORIA] Backtrace: #{e.backtrace.first(5).join("\n")}"
    ChatwootExceptionTracker.new(e, account: hook&.account).capture_exception
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
    changed_attributes = event_data[:changed_attributes]
    return if conversation.blank? || changed_attributes.blank?

    # Check if label_list changed
    label_changes = changed_attributes['label_list'] || changed_attributes[:label_list]
    return if label_changes.blank?

    previous_labels = Array(label_changes[0])
    current_labels = Array(label_changes[1])

    added_labels = current_labels - previous_labels
    removed_labels = previous_labels - current_labels

    # Forward tag.added for JusMonitorIA labels
    added_labels.each do |label|
      next unless label.to_s.start_with?(LABEL_PREFIX)

      Rails.logger.info "[JUSMONITORIA] Tag added: #{label} on conversation #{conversation.id}"
      Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
        event_type: 'tag.added',
        payload: { tag: label, conversation: conversation_payload(conversation) },
        account: conversation.account
      )
    end

    # Forward tag.removed for JusMonitorIA labels
    removed_labels.each do |label|
      next unless label.to_s.start_with?(LABEL_PREFIX)

      Rails.logger.info "[JUSMONITORIA] Tag removed: #{label} on conversation #{conversation.id}"
      Integrations::Jusmonitoria::WebhookForwarderService.forward_event(
        event_type: 'tag.removed',
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

    { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type }
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
