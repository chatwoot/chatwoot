require 'openssl'
require 'securerandom'
require 'uri'

class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze
  DEFAULT_TIMEOUT = 5
  WHATSAPP_WEB_SIGNATURE_ALGORITHM = 'HMAC-SHA256'.freeze
  WHATSAPP_WEB_ALLOWED_PATH_FRAGMENT = '/chatwoot/webhook/'.freeze

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
    payload_json = @payload.to_json
    validate_destination!

    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: payload_json,
      headers: request_headers(payload_json),
      timeout: request_timeout
    )
  end

  def handle_error(error)
    return unless SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
    return unless message

    case @webhook_type
    when :agent_bot_webhook
      update_conversation_status(message)
    when :api_inbox_webhook, :whatsapp_web_inbox_webhook
      update_message_status(error)
    end
  end

  def request_headers(payload_json)
    headers = { content_type: :json, accept: :json }
    return headers unless whatsapp_web_webhook?

    headers.merge(whatsapp_web_headers(payload_json))
  end

  def request_timeout
    return webhook_timeout unless whatsapp_web_webhook?

    raw_timeout = ENV.fetch('WHATSAPP_WEB_WEBHOOK_TIMEOUT', '').to_s
    timeout = raw_timeout.presence&.to_i
    timeout&.positive? ? timeout : webhook_timeout
  end

  def validate_destination!
    return unless whatsapp_web_webhook?

    uri = URI.parse(@url)
    raise ArgumentError, 'WhatsApp Web webhook URL must be http/https' unless uri.is_a?(URI::HTTP) && uri.host.present?
    raise ArgumentError, 'WhatsApp Web webhook URL must target the Evolution Chatwoot webhook path' unless uri.path.include?(WHATSAPP_WEB_ALLOWED_PATH_FRAGMENT)

    return if allowed_whatsapp_web_hosts.blank?
    return if allowed_whatsapp_web_hosts.include?(uri.host.downcase)

    raise ArgumentError, "WhatsApp Web webhook host #{uri.host} is not in the allowlist"
  rescue URI::InvalidURIError
    raise ArgumentError, 'WhatsApp Web webhook URL must be a valid URL'
  end

  def allowed_whatsapp_web_hosts
    @allowed_whatsapp_web_hosts ||= ENV.fetch('WHATSAPP_WEB_WEBHOOK_ALLOWED_HOSTS', '').to_s.split(',')
                                      .map { |host| host.strip.downcase }
                                      .reject(&:blank?)
  end

  def whatsapp_web_headers(payload_json)
    timestamp = Time.current.to_i.to_s
    nonce = SecureRandom.hex(16)
    headers = {
      'X-Chatwoot-Webhook-Type' => 'whatsapp_web',
      'X-Chatwoot-Signature-Timestamp' => timestamp,
      'X-Chatwoot-Signature-Nonce' => nonce
    }
    secret = ENV.fetch('WHATSAPP_WEB_WEBHOOK_SECRET', '').to_s
    return headers if secret.blank?

    headers.merge(
      'X-Chatwoot-Signature-Algorithm' => WHATSAPP_WEB_SIGNATURE_ALGORITHM,
      'X-Chatwoot-Signature' => OpenSSL::HMAC.hexdigest('sha256', secret, "#{timestamp}.#{nonce}.#{payload_json}")
    )
  end

  def whatsapp_web_webhook?
    @webhook_type == :whatsapp_web_inbox_webhook
  end

  def update_conversation_status(message)
    conversation = message.conversation
    return unless conversation&.pending?
    return if conversation&.account&.keep_pending_on_bot_failure

    conversation.open!
    create_agent_bot_error_activity(conversation)
  end

  def create_agent_bot_error_activity(conversation)
    content = I18n.t('conversations.activity.agent_bot.error_moved_to_open')
    Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(conversation, content))
  end

  def activity_message_params(conversation, content)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
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

  def webhook_timeout
    raw_timeout = GlobalConfig.get_value('WEBHOOK_TIMEOUT')
    timeout = raw_timeout.presence&.to_i

    timeout&.positive? ? timeout : DEFAULT_TIMEOUT
  end
end
