# Meta error 138006 means the contact hasn't opted in to calls yet; send the opt-in template.
class Whatsapp::CallPermissionRequestService
  THROTTLE = 5.minutes
  REQUESTS_KEY = 'call_permission_requests'.freeze
  REQUESTED_AT_KEY = 'call_permission_requested_at'.freeze
  MESSAGE_ID_KEY = 'call_permission_request_message_id'.freeze

  pattr_initialize [:conversation!, :recipient!]

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
    last_requested = permission_request_attrs[REQUESTED_AT_KEY]
    last_requested.present? && Time.zone.parse(last_requested) > THROTTLE.ago
  end

  # Treat transport errors as a falsy return so the caller renders 422 rather than 500.
  def send_request_safely
    provider_service.send_call_permission_request(recipient, *body_args)
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
    requested_at = Time.current.iso8601
    request_attrs = {
      REQUESTED_AT_KEY => requested_at,
      MESSAGE_ID_KEY => sent.dig('messages', 0, 'id')
    }
    attrs = (conversation.additional_attributes || {}).merge(
      REQUESTED_AT_KEY => requested_at,
      MESSAGE_ID_KEY => request_attrs[MESSAGE_ID_KEY],
      REQUESTS_KEY => permission_requests.merge(recipient_key => request_attrs)
    )
    conversation.update!(additional_attributes: attrs)
  end

  def provider_service
    @provider_service ||= conversation.inbox.channel.provider_service
  end

  def permission_request_attrs
    permission_requests[recipient_key] || legacy_permission_request_attrs
  end

  def permission_requests
    (conversation.additional_attributes || {}).fetch(REQUESTS_KEY, {})
  end

  # Older versions stored one pending request directly on the conversation.
  # Preserve that throttle after deploy until the old window naturally expires.
  def legacy_permission_request_attrs
    return {} if permission_requests.present?

    (conversation.additional_attributes || {}).slice(REQUESTED_AT_KEY, MESSAGE_ID_KEY).compact
  end

  def recipient_key
    recipient.to_s
  end
end
