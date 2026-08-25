class Whatsapp::BusinessManagementTokenService
  def initialize(channel)
    @channel = channel
  end

  def update!(business_management_token)
    validate_channel!
    raise ArgumentError, 'Business management token is required' if business_management_token.blank?

    Whatsapp::BusinessManagementTokenValidationService.new(
      business_management_token,
      @channel.provider_config['business_account_id']
    ).perform

    @channel.business_management_token = business_management_token
    @channel.save!(validate: false)
  end

  private

  def validate_channel!
    raise ArgumentError, 'Business management token is only available on Chatwoot Cloud' unless ChatwootApp.chatwoot_cloud?
    return if @channel.provider == 'whatsapp_cloud' && @channel.provider_config['source'] == 'embedded_signup'

    raise ArgumentError, 'Business management token is only supported for WhatsApp Embedded Signup inboxes'
  end
end
