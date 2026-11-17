class Api::V1::Accounts::Inboxes::CallRoutingsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  # Who rings and what happens outside business hours are sent together, as the form shows them,
  # for a Twilio voice inbox or a WhatsApp inbox with calling on. The lock keeps another voice
  # settings save from being lost in the merge. Saved without the channel's other validations, as
  # the other call settings are, so WhatsApp's remote credential check can't reject the save.
  def update
    channel = @inbox.channel
    channel.with_lock do
      channel.provider_config = channel.provider_config.merge(
        'ring_strategy' => params[:ring_strategy], 'ring_step_seconds' => params[:ring_step_seconds],
        'assignee_rings_first' => params[:assignee_rings_first], 'call_cooldown_seconds' => params[:call_cooldown_seconds],
        'business_hours_calls_enabled' => params[:business_hours_calls_enabled]
      )
      validate_settings!(channel)
      channel.save!(validate: false)
    end
    # WhatsApp itself turns away calls outside business hours once Meta has them
    channel.schedule_call_hours_sync if channel.is_a?(Channel::Whatsapp)
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  # The routing settings, and for WhatsApp, that business hours applied to calls leave an open day
  def validate_settings!(channel)
    channel.call_routing_settings_valid
    channel.call_hours_schedule_valid if channel.is_a?(Channel::Whatsapp)
    raise ActiveRecord::RecordInvalid, channel if channel.errors.any?
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    channel = @inbox.channel
    return if channel.respond_to?(:call_routing_settings_valid) && channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end
end
