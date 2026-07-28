class Whatsapp::BusinessManagementTokenService
  def initialize(channel)
    @channel = channel
  end

  def update!(business_management_token)
    validate_channel!
    raise ArgumentError, 'Business management token is required' if business_management_token.blank?

    Whatsapp::BusinessManagementTokenValidationService.new(business_management_token).perform

    @channel.business_management_token = business_management_token
    @channel.save!(validate: false)
  end

  def remove!
    validate_channel!

    @channel.business_management_token = nil
    @channel.save!(validate: false)
  end

  private

  def validate_channel!
    raise ArgumentError, 'Business management token is only available on Chatwoot Cloud' unless ChatwootApp.chatwoot_cloud?
    raise ArgumentError, 'Business management token is only supported for WhatsApp Cloud inboxes' unless @channel.provider == 'whatsapp_cloud'
  end
end
