class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze
  RETRYABLE_AGENT_BOT_STATUSES = [429, 500].freeze
  # Both roles of an inbox's bots retry the same way; only `:agent_bot_webhook` (the responder) is
  # allowed into `handle_error`, because escalating moves the conversation to a human and an observer
  # never owned it (AgentBotObserver).
  AGENT_BOT_WEBHOOK_TYPES = %i[agent_bot_webhook agent_bot_observer_webhook].freeze

  class RetryableError < StandardError
    attr_reader :status

    def initialize(status:, message:)
      @status = status
      super(message)
    end
  end

  def initialize(url, payload, webhook_type, secret: nil, delivery_id: nil)
    @url = url
    @payload = payload
    @webhook_type = webhook_type
    @secret = secret
    @delivery_id = delivery_id
  end

  def self.execute(url, payload, webhook_type, secret: nil, delivery_id: nil)
    new(url, payload, webhook_type, secret: secret, delivery_id: delivery_id).execute
  end

  def execute
    perform_request
  rescue StandardError => e
    raise RetryableError.new(status: http_status(e), message: e.message) if retryable_agent_bot_error?(e)

    # NO ESCALATION HERE. A failed request is not a failed delivery: WebhookJob retries this, and
    # escalating on attempt 1 makes those retries unreachable for an agent bot. The bot only acts on
    # a `pending` conversation, so moving it to `open` here means every redelivery arrives at a
    # conversation the bot will not answer, and the retry lands without changing anything.
    # The same holds for an api_inbox message marked `failed` here: a later attempt can still
    # deliver it, leaving an agent to resend what the customer already received.
    # Escalation belongs to whoever learns the delivery is over, which is the retries-exhausted
    # block in WebhookJob (`Webhooks::ErrorHandler`, whose handoff `update_conversation_status`
    # shares).
    Rails.logger.warn "Exception: webhook request to #{@url} failed : #{e.message}"
    raise CustomExceptions::Webhook::RetriableError, "Webhook request failed: #{e.message}"
  end

  def handle_failure(error)
    handle_error(error)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{error.message}"
  end

  private

  def perform_request
    body = @payload.to_json
    SafeFetch.fetch(
      @url,
      method: :post,
      body: body,
      headers: request_headers(body),
      open_timeout: webhook_timeout,
      read_timeout: webhook_timeout,
      validate_content_type: false
    ) { |_response| nil }
  end

  def request_headers(body)
    headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    headers['X-Chatwoot-Delivery'] = @delivery_id if @delivery_id.present?
    if @secret.present?
      ts = Time.now.to_i.to_s
      headers['X-Chatwoot-Timestamp'] = ts
      headers['X-Chatwoot-Signature'] = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', @secret, "#{ts}.#{body}")}"
    end
    headers
  end

  def handle_error(error)
    return unless SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
    return unless message

    case @webhook_type
    when :agent_bot_webhook
      update_conversation_status(message)
    when :api_inbox_webhook
      update_message_status(error)
    end
  end

  def update_conversation_status(message)
    Webhooks::ErrorHandler.hand_off_after_bot_failure(message.conversation)
  end

  def update_message_status(error)
    Messages::StatusUpdateService.new(message, 'failed', error.message).perform
  end

  def message
    return if message_id.blank?

    if defined?(@message)
      @message
    else
      @message = Message.find_by(id: message_id)
    end
  end

  def message_id
    @payload[:id]
  end

  def webhook_timeout
    raw_timeout = GlobalConfig.get_value('WEBHOOK_TIMEOUT')
    timeout = raw_timeout.presence&.to_i

    timeout&.positive? ? timeout : 5
  end

  def retryable_agent_bot_error?(error)
    AGENT_BOT_WEBHOOK_TYPES.include?(@webhook_type) && RETRYABLE_AGENT_BOT_STATUSES.include?(http_status(error))
  end

  def http_status(error)
    return unless error.is_a?(SafeFetch::HttpError)

    error.message.to_s[/\A(\d{3})\b/, 1]&.to_i
  end
end
