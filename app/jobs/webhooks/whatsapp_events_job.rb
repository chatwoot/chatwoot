class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    Rails.logger.info "[WHATSAPP_DEBUG] 🎯 WhatsAppEventsJob started with params: #{params.inspect}"

    channel = find_channel_from_whatsapp_business_payload(params)

    if channel_is_inactive?(channel)
      Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number || "unknown - #{params[:phone_number]}"}")
      return
    end

    Rails.logger.info "[WHATSAPP_DEBUG] Processing with provider: #{channel.provider}"
    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end

    Rails.logger.info '[WHATSAPP_DEBUG] ✅ WhatsAppEventsJob completed'
  end

  private

  def channel_is_inactive?(channel)
    return true if channel.blank?
    return true if channel.reauthorization_required?
    return true unless channel.account.active?

    false
  end

  def find_channel_by_url_param(params)
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

  def find_channel_from_whatsapp_business_payload(params)
    # Priority order:
    # 1. Use phone_number_id from controller (new Facebook WhatsApp Business API format)
    # 2. Use phone_number from Facebook payload (existing logic)
    # 3. Use phone_number from URL params (backward compatibility)

    # First try phone_number_id from controller enhancement
    if params[:phone_number_id].present?
      channel = find_channel_by_phone_number_id(params[:phone_number_id])
      return channel if channel
    end

    # Fallback to existing Facebook payload logic
    return get_channel_from_wb_payload(params) if params[:object] == 'whatsapp_business_account'

    # Final fallback to URL param
    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)

    # First try to find by phone_number_id (more reliable)
    channel = find_channel_by_phone_number_id(phone_number_id) if phone_number_id.present?
    return channel if channel

    # Fallback to phone_number lookup with validation
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end

  # Find WhatsApp channel by phone_number_id in provider_config
  def find_channel_by_phone_number_id(phone_number_id)
    Channel::Whatsapp.find_by_phone_number_id(phone_number_id)
  end
end
