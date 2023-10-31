class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload)
    @url = url
    @payload = payload
  end

  def self.execute(url, payload)
    new(url, payload).execute
  end

  def execute
    perform_request
  rescue RestClient::Exceptions::Timeout, RestClient::ExceptionWithResponse => e
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
    return unless should_handle_error?
    return unless conversation && message

    update_message_status(error)
  end

  def should_handle_error?
    SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
  end

  def update_message_status(error)
    message.update!(status: :failed, external_error: error.message)
  end

  def conversation
    return if conversation_id.blank?

    @conversation ||= Conversation.find_by(id: conversation_id)
  end

  def message
    return if message_id.blank?

    @message ||= conversation&.messages&.find_by(id: message_id)
  end

  def conversation_id
    @payload.dig(:conversation, :id)
  end

  def message_id
    @payload[:id]
  end
end
