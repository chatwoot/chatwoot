class Whatsapp::DisplayNameService
  def initialize(channel)
    @channel = channel
    @api = Whatsapp::FacebookApiClient.new(channel.provider_config['api_key'])
  end

  def perform(display_name:)
    validate_channel!
    raise ArgumentError, I18n.t('whatsapp.display_name.approval_changed') unless display_name.is_a?(String) && display_name.present?

    validate_approval!(display_name)
    pin = registration_pin
    result = @api.register_phone_number(@channel.provider_config.fetch('phone_number_id'), pin)
    raise ArgumentError, I18n.t('whatsapp.display_name.registration_failed') unless result['success'] == true

    store_pin(pin) if @channel.provider_config['verification_pin'].blank?
  end

  private

  def validate_channel!
    return if @channel.provider == 'whatsapp_cloud'

    raise ArgumentError, I18n.t('whatsapp.display_name.unsupported_channel')
  end

  def validate_approval!(display_name)
    health = Whatsapp::HealthService.new(@channel).fetch_health_status
    raise ArgumentError, I18n.t('whatsapp.display_name.unsupported_number') unless health[:is_on_biz_app] == false && health[:status] == 'CONNECTED'

    return if health[:new_name_status] == 'APPROVED' && health[:new_display_name] == display_name

    raise ArgumentError, I18n.t('whatsapp.display_name.approval_changed')
  end

  def registration_pin
    stored_pin = @channel.provider_config['verification_pin']
    return stored_pin.to_s if stored_pin.present?

    phone = @api.fetch_phone_number(@channel.provider_config.fetch('phone_number_id'), fields: 'is_pin_enabled')
    raise ArgumentError, I18n.t('whatsapp.display_name.pin_unavailable') unless phone['is_pin_enabled'] == false

    (SecureRandom.random_number(900_000) + 100_000).to_s
  end

  def store_pin(pin)
    @channel.provider_config = @channel.provider_config.merge('verification_pin' => pin)
    # Registration already validated the credentials. Do not make another provider validation request.
    @channel.save!(validate: false)
  end
end
