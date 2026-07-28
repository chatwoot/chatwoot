class Whatsapp::BusinessManagementTokenService
  def initialize(channel)
    @channel = channel
  end

  def update!(business_management_token)
    raise ArgumentError, 'Business management token is only available on Chatwoot Cloud' unless ChatwootApp.chatwoot_cloud?
    raise ArgumentError, 'Business management token is required' if business_management_token.blank?
    raise ArgumentError, 'Business management token is only supported for WhatsApp Cloud inboxes' unless @channel.provider == 'whatsapp_cloud'

    Whatsapp::BusinessManagementTokenValidationService.new(business_management_token).perform

    @channel.update!(business_management_token: business_management_token)
  end
end
