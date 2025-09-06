class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload, webhook_type)
    @url = url
    @payload = payload
    @webhook_type = webhook_type
  end

  def self.execute(url, payload, webhook_type)
    new(url, payload, webhook_type).execute
  end

  def execute
    perform_request
  rescue StandardError => e
    handle_error(e)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
  end

  private

  def perform_request
    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: { content_type: :json, accept: :json },
      timeout: 5
    )
  end

  def handle_error(error)
    case @webhook_type
    when :api_inbox_webhook
      return unless should_handle_api_error?
      return unless message

      update_message_status(error)
    when :agent_bot_webhook
      update_message_status(error) if message
      open_conversation_if_pending
    end
  end

  def should_handle_api_error?
    SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
  end

  def open_conversation_if_pending
    return unless conversation&.pending?

    conversation.open!
  end

  def conversation
    return if conversation_id.blank?

    @conversation ||= Conversation.find_by(id: conversation_id)
  end

  def conversation_id
    @payload.dig(:conversation, :id) || @payload[:id]
  end

  def update_message_status(error)
    Messages::StatusUpdateService.new(message, 'failed', error.message).perform
  end

  def message
    return if message_id.blank?

    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
