class Whatsapp::ManualWebhookStatusService
  def initialize(channel)
    @channel = channel
    @api_client = Whatsapp::FacebookApiClient.new(channel.provider_config['api_key'])
  end

  def perform
    callback_configured = callback_configured?

    {
      callback_verified: callback_configured,
      callback_configured: callback_configured,
      callback_url: callback_url,
      subscription_verified: subscription_verified?
    }
  end

  private

  def callback_configured?
    phone_number = @api_client.fetch_phone_number(
      @channel.provider_config['phone_number_id'],
      fields: 'webhook_configuration'
    )
    webhook_configuration = phone_number.fetch('webhook_configuration', {})

    %w[override_callback_uri phone_number whatsapp_business_account application].any? do |key|
      webhook_configuration[key] == callback_url
    end
  end

  def subscription_verified?
    @api_client.fetch_subscribed_apps(@channel.provider_config['business_account_id']).fetch('data', []).present?
  end

  def callback_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{@channel.phone_number}"
  end
end
