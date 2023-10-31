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
  rescue StandardError => e
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
    handle_error(e)
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
    return unless SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])

    return unless conversation.present? && message.present?

    message.update!(status: :failed, external_error: error.message)
  end

  def conversation
    return if @payload[:conversation].blank? || @payload[:conversation][:id].blank?

    @conversation ||= Conversation.find_by(id: @payload[:conversation][:id])
  end

  def message
    return if @payload[:id].blank?

    @message ||= conversation.messages.find_by(id: @payload[:id])
  end
end
