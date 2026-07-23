# Meta error 138006 means the contact hasn't opted in to calls yet; send the opt-in template.
class Whatsapp::CallPermissionRequestService
  THROTTLE = 5.minutes

  pattr_initialize [:conversation!]

  # Locked so two agents calling the same contact can't both send the template.
  def perform
    conversation.with_lock do
      next 'permission_pending' if throttled?

      sent = send_request_safely
      next 'failed' if sent.blank?

      record_wamid(sent)
      emit_activity
      'permission_requested'
    end
  end

  private

  def throttled?
    last_requested = conversation.additional_attributes&.dig('call_permission_requested_at')
    last_requested.present? && Time.zone.parse(last_requested) > THROTTLE.ago
  end

  # Treat transport errors as a falsy return so the caller renders 422 rather than 500.
  def send_request_safely
    provider_service.send_call_permission_request(conversation.contact.phone_number.delete('+'), *body_args)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP CALL] permission_request failed: #{e.class} #{e.message}"
    nil
  end

  # Pass the inbox-level override only when present so the provider falls back
  # to the i18n default for inboxes that haven't customized the prompt.
  def body_args
    custom_body = conversation.inbox.channel.provider_config&.dig('call_permission_request_body').presence
    custom_body ? [custom_body] : []
  end

  def emit_activity
    content = I18n.t('conversations.activity.whatsapp_call.permission_requested', contact_name: conversation.contact.name)
    ::Conversations::ActivityMessageJob.perform_later(
      conversation,
      { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
    )
  end

  # Stash the outbound wamid so the reply webhook can match context.id back here.
  def record_wamid(sent)
    attrs = (conversation.additional_attributes || {}).merge(
      'call_permission_requested_at' => Time.current.iso8601,
      'call_permission_request_message_id' => sent.dig('messages', 0, 'id')
    )
    conversation.update!(additional_attributes: attrs)
  end

  def provider_service
    @provider_service ||= conversation.inbox.channel.provider_service
  end
end
