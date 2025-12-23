module Whatsapp::IncomingMessageServiceHelpers
  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def conversation_params
    params = {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
    
    ad_source_metadata = extract_ad_source_metadata
    params[:additional_attributes] = ad_source_metadata if ad_source_metadata.present?
    
    params
  end

  def extract_ad_source_metadata
    message = @processed_params[:messages]&.first
    return {} if message.blank?

    metadata = {}

    # Extract referral data from WhatsApp ads
    # https://developers.facebook.com/docs/whatsapp/business-management-api/guides/set-up-ads
    if message[:referral].present?
      referral = message[:referral]
      metadata[:ad_source] = 'whatsapp_ad'
      metadata[:ad_source_id] = referral[:source_id] if referral[:source_id].present?
      metadata[:ad_source_type] = referral[:source_type] if referral[:source_type].present?
      metadata[:ad_source_url] = referral[:source_url] if referral[:source_url].present?
      metadata[:ad_headline] = referral[:headline] if referral[:headline].present?
      metadata[:ad_body] = referral[:body] if referral[:body].present?
      metadata[:ad_media_type] = referral[:media_type] if referral[:media_type].present?
      metadata[:ad_media_url] = referral[:media_url] if referral[:media_url].present?
      metadata[:ad_ctwa_clid] = referral[:ctwa_clid] if referral[:ctwa_clid].present?
    end

    # Extract context data which may include ad-related information
    if message[:context].present?
      context = message[:context]
      metadata[:referral_from] = context[:from] if context[:from].present?
      metadata[:referred_product_id] = context[:referred_product]&.[](:product_retailer_id) if context[:referred_product].present?
    end

    metadata.compact
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    @processed_params[:messages].first[:type]
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

    @message = Message.find_by(source_id: source_id)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    Redis::Alfred.get(key)
  end

  def cache_message_source_id_in_redis
    return if @processed_params.try(:[], :messages).blank?

    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    ::Redis::Alfred.setex(key, true)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: @processed_params[:messages].first[:id])
    ::Redis::Alfred.delete(key)
  end
end
