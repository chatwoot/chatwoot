class Api::V1::Accounts::Inboxes::CallRoutingsController < Api::V1::Accounts::BaseController
  # The bounds the routing form offers
  RING_STEP_SECONDS = (10..60)
  COOLDOWN_SECONDS = (0..600)

  before_action :fetch_inbox
  before_action :validate_settings

  # All four settings are sent together, as the form shows them
  def update
    channel = @inbox.channel
    channel.update!(provider_config: channel.provider_config.merge(
      'ring_strategy' => params[:ring_strategy], 'ring_step_seconds' => params[:ring_step_seconds],
      'prefer_free_agents' => params[:prefer_free_agents], 'call_cooldown_seconds' => params[:call_cooldown_seconds]
    ))
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if @inbox.twilio? && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end

  def validate_settings
    return if Channel::TwilioSms::RING_STRATEGIES.include?(params[:ring_strategy]) && [true, false].include?(params[:prefer_free_agents]) &&
              within?(params[:ring_step_seconds], RING_STEP_SECONDS) && within?(params[:call_cooldown_seconds], COOLDOWN_SECONDS)

    render_could_not_create_error(I18n.t('inbox.call_routing.invalid_settings', step_min: RING_STEP_SECONDS.min, step_max: RING_STEP_SECONDS.max,
                                                                                cooldown_max: COOLDOWN_SECONDS.max))
  end

  def within?(value, range) = value.is_a?(Integer) && range.cover?(value)
end
