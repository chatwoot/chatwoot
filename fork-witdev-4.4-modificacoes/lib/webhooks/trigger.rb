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
    Rails.logger.info "[WEBHOOK_TRIGGER] Executing webhook to #{@url}"
    Rails.logger.info "[WEBHOOK_TRIGGER] Payload event: #{@payload[:event]}"
    Rails.logger.info "[WEBHOOK_TRIGGER] Payload includes ACCESS_TOKEN: #{@payload.key?(:ACCESS_TOKEN)}"
    
    perform_request
    
    Rails.logger.info "[WEBHOOK_TRIGGER] Webhook executed successfully to #{@url}"
  rescue StandardError => e
    handle_error(e)
    Rails.logger.error "[WEBHOOK_TRIGGER] Exception for webhook URL #{@url}: #{e.message}"
    Rails.logger.error "[WEBHOOK_TRIGGER] Backtrace: #{e.backtrace.first(5).join(', ')}"
  end

  private

  def perform_request
    response = RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: { content_type: :json, accept: :json },
      timeout: 5
    )
    
    Rails.logger.info "[WEBHOOK_TRIGGER] Response status: #{response.code}"
  end

  def handle_error(error)
    return unless should_handle_error?
    return unless message

    update_message_status(error)
  end

  def should_handle_error?
    @webhook_type == :api_inbox_webhook && SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
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
