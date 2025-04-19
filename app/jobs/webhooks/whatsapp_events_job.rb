class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    params = params.with_indifferent_access
    whapi_params = params[:whapi] || params # Handle potential nesting differences
    channel_id = whapi_params[:channel_id]

    # Log the raw payload for debugging
    Rails.logger.info "WHAPI Raw Payload Received: #{whapi_params.inspect}"

    # First try to find channel from WhatsApp business payload or URL param
    channel = find_channel_from_whatsapp_business_payload(params)
    
    # If not found, and we have a WHAPI payload, try to find by WHAPI channel_id
    if channel.nil? && (params[:channel_id].present? || params.dig(:whapi, :channel_id).present?)
      Rails.logger.info("Attempting to find WhatsApp channel by WHAPI channel_id")
      channel = find_channel_by_whapi_id(params)
    end

    if channel_is_inactive?(channel)
      channel_id = params[:channel_id] || params.dig(:whapi, :channel_id)
      Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number || "unknown - #{params[:phone_number]}"}, WHAPI channel_id: #{channel_id}")
      return
    end

    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    when 'whapi'
      Rails.logger.info("Processing WHAPI webhook for channel: #{channel.id}, inbox: #{channel.inbox.id}")
      Whatsapp::IncomingMessageWhapiService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
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
  
  def find_channel_by_whapi_id(params)
    # Extract channel_id from params
    channel_id = params[:channel_id] || params.dig(:whapi, :channel_id)
    return nil if channel_id.blank?
    
    # Find WhatsApp channel with matching channel_id in provider_config
    Channel::Whatsapp.where(provider: 'whapi').each do |channel|
      if channel.provider_config['channel_id'] == channel_id
        Rails.logger.info("Found WHAPI channel #{channel.id} with channel_id: #{channel_id}")
        return channel
      end
    end
    
    Rails.logger.error("No WHAPI channel found with channel_id: #{channel_id}")
    nil
  end

  def find_channel_from_whatsapp_business_payload(params)
    # for the case where facebook cloud api support multiple numbers for a single app
    # https://github.com/chatwoot/chatwoot/issues/4712#issuecomment-1173838350
    # we will give priority to the phone_number in the payload
    return get_channel_from_wb_payload(params) if params[:object] == 'whatsapp_business_account'

    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end
end
