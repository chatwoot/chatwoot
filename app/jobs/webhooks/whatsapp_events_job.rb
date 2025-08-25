class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    correlation_id = params['correlation_id'] || SecureRandom.uuid
    channel = find_channel_from_whatsapp_business_payload(params)

    if channel_is_inactive?(channel)
      Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number || "unknown - #{params[:phone_number]}"}")
      return
    end

    service = Whatsapp::IncomingMessageServiceFactory.create(
      channel: channel,
      params: params,
      correlation_id: correlation_id
    )

    service.perform
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
    # for the case where facebook cloud api support multiple numbers for a single app
    # https://github.com/chatwoot/chatwoot/issues/4712#issuecomment-1173838350
    # we will give priority to the phone_number in the payload
    return get_channel_from_wb_payload(params) if params[:object] == 'whatsapp_business_account'

    # Try to find by phone number first for traditional endpoints
    channel = find_channel_by_url_param(params)
    return channel if channel

    # For Whapi partner posts to /webhooks/whapi, match by channel_id in payload
    whapi_channel_id = params[:channel_id] || params['channel_id'] || (params.is_a?(Hash) ? params.dig('channel', 'id') : nil)
    return find_channel_by_whapi_channel_id(whapi_channel_id) if whapi_channel_id.present?

    # For Whapi partner channels, try to find by whapi_channel_id if no phone_number
    find_channel_by_whapi_id(params)
  end

  def get_channel_from_wb_payload(wb_params)
    entry = wb_params[:entry]&.first
    change = entry[:changes]&.first if entry.is_a?(Hash)
    value = change[:value] if change.is_a?(Hash)
    metadata = value[:metadata] if value.is_a?(Hash)

    return nil unless metadata.is_a?(Hash)

    phone_number = "+#{metadata[:display_phone_number]}"
    phone_number_id = metadata[:phone_number_id]
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end

  def find_channel_by_whapi_id(params)
    whapi_channel_id = params[:channel_id] || params['channel_id']
    return unless whapi_channel_id

    find_channel_by_whapi_channel_id(whapi_channel_id)
  end

  def find_channel_by_whapi_channel_id(whapi_channel_id)
    return unless whapi_channel_id

    # Use config object pattern to find channel by whapi_channel_id
    Channel::Whatsapp.where(provider: 'whapi').find do |channel|
      channel.provider_config_object.whapi_channel_id == whapi_channel_id
    end
  end
end
