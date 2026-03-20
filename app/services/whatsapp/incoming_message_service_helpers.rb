module Whatsapp::IncomingMessageServiceHelpers
  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    messages_data.first[:type]
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message.dig(:name, :formatted_name)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[reaction ephemeral unsupported request_welcome].include?(message_type)
  end

  def processed_waid(waid)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(waid, :cloud)
  end

  def error_webhook_event?(message)
    message.key?('errors')
  end

  def log_error(message)
    Rails.logger.warn "Whatsapp Error: #{message['errors'][0]['title']} - contact: #{message['from']}"
  end

  def process_in_reply_to(message)
    @in_reply_to_external_id = message['context']&.[]('id')
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = inbox.messages.find_by(source_id: source_id)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    Redis::Alfred.get(key)
  end

  def acquire_message_processing_lock
    return false if @processed_params.try(:[], :messages).blank?

    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    Redis::Alfred.set(key, true, nx: true, ex: 1.day)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    ::Redis::Alfred.delete(key)
  end

  # Lock by contact phone to prevent race conditions when multiple messages
  # from the same contact arrive simultaneously (e.g., WhatsApp albums).
  # Without this, each message could create its own conversation.
  def with_contact_lock(phone, timeout: 5.seconds)
    raise ArgumentError, 'A block is required for with_contact_lock' unless block_given?
    return yield if phone.blank?

    key = "WHATSAPP::CONTACT_LOCK::#{inbox.id}_#{phone}"
    start_time = Time.now.to_i
    lock_acquired = false

    while (Time.now.to_i - start_time) < timeout
      if Redis::Alfred.set(key, 1, nx: true, ex: timeout)
        lock_acquired = true
        break
      end

      sleep(0.1)
    end

    raise Timeout::Error, "Timeout acquiring contact lock for #{phone}" unless lock_acquired

    yield
  ensure
    Redis::Alfred.delete(key) if lock_acquired
  end
end
