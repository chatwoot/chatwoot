class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    channel = find_channel_from_whatsapp_business_payload(params)
    return if channel_is_inactive?(channel)

    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end

    forward_webhook_to_additional_endpoints(params)
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

    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end

  def forward_webhook_to_additional_endpoints(params)
    additional_endpoints = ENV['WHATSAPP_WEBHOOK_URLS']&.split(',')&.map(&:strip)
    return if additional_endpoints.blank?

    additional_endpoints.each do |endpoint|
      begin
        # Validate URL format
        uri = URI.parse(endpoint)
        raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

        # Make the request with timeout and specific error handling
        response = HTTParty.post(
          endpoint,
          body: params.to_json,
          headers: { 
            'Content-Type' => 'application/json',
            'User-Agent' => 'Chatwoot-Webhook-Forwarder'
          },
          timeout: 10,
          verify: true  # Verify SSL certificates
        )

        unless response.success?
          Rails.logger.error "Failed to forward WhatsApp webhook to #{endpoint}. Status: #{response.code}"
        end
      rescue StandardError => e
        Rails.logger.error "Error forwarding WhatsApp webhook to #{endpoint}: #{e.message}"
      end
    end
  end
end
