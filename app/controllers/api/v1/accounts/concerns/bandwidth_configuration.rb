module Api::V1::Accounts::Concerns::BandwidthConfiguration
  extend ActiveSupport::Concern

  CONFIG_KEYS = %w[account_id application_id api_key api_secret client_id client_secret].freeze
  OAUTH_REQUIRED_KEYS = %w[account_id application_id client_id client_secret].freeze

  private

  def prepare_bandwidth_configuration
    return unless bandwidth_channel_request?

    supplied = params.dig(:channel, :provider_config)
    config = merged_bandwidth_configuration(supplied)
    return unless config.key?('client_id') || config.key?('client_secret')
    return unless validate_bandwidth_oauth_config(config, supplied)

    params[:channel][:provider_config] = config
  rescue CustomExceptions::Bandwidth::AuthenticationError => e
    render_could_not_create_error(e.message)
  end

  def merged_bandwidth_configuration(supplied)
    raise ActionController::ParameterMissing, :provider_config unless supplied.is_a?(ActionController::Parameters)

    existing = action_name == 'update' ? @inbox.channel.provider_config : {}
    (existing || {}).merge(supplied.to_unsafe_h)
  end

  def bandwidth_channel_request?
    return false unless params[:channel].is_a?(ActionController::Parameters) && params[:channel].key?(:provider_config)
    return @inbox.sms? if action_name == 'update'

    params[:channel][:type] == 'sms'
  end

  def valid_bandwidth_config_params?(config)
    config.keys.all? do |key|
      CONFIG_KEYS.include?(key) && config[key].is_a?(String) && config[key].present?
    end
  end

  def validate_bandwidth_oauth_config(config, supplied)
    complete = OAUTH_REQUIRED_KEYS.all? { |key| config[key].is_a?(String) && config[key].present? }
    unless complete && valid_bandwidth_config_params?(supplied)
      render_could_not_create_error(I18n.t('errors.bandwidth.invalid_configuration'))
      return false
    end

    Sms::BandwidthTokenService.new(config: config).token(force: true)
    true
  end
end
