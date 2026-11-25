module Api::V1::Accounts::Concerns::BandwidthConfiguration
  extend ActiveSupport::Concern

  private

  def prepare_bandwidth_configuration
    return unless bandwidth_channel_request?

    supplied = params.dig(:channel, :provider_config)
    unless supplied.is_a?(ActionController::Parameters)
      render_could_not_create_error(I18n.t('errors.bandwidth.invalid_configuration'))
      return
    end
    config = merged_bandwidth_configuration(supplied)
    return unless validate_bandwidth_configuration(config)

    params[:channel][:provider_config] = config
  rescue CustomExceptions::Bandwidth::AuthenticationError => e
    render_could_not_create_error(e.message)
  rescue CustomExceptions::Bandwidth::TokenRequestError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  def merged_bandwidth_configuration(supplied)
    existing = action_name == 'update' ? @inbox.channel.provider_config : {}
    (existing || {}).merge(supplied.to_unsafe_h)
  end

  def bandwidth_channel_request?
    return false unless params[:channel].is_a?(ActionController::Parameters)
    return @inbox.sms? && params[:channel].key?(:provider_config) if action_name == 'update'

    params[:channel][:type] == 'sms'
  end

  def validate_bandwidth_configuration(config)
    channel = action_name == 'update' ? @inbox.channel : Current.account.sms_channels.build(phone_number: params.dig(:channel, :phone_number))
    channel.assign_attributes(provider_config: config)
    channel.validate!
    if action_name == 'create' && !channel.oauth?
      render_could_not_create_error(I18n.t('errors.bandwidth.invalid_configuration'))
      return false
    end

    Sms::BandwidthTokenService.new(config: config).token(force: true) if channel.oauth?
    true
  end
end
