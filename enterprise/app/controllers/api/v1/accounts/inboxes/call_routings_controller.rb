class Api::V1::Accounts::Inboxes::CallRoutingsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  # Who rings and what happens outside business hours are sent together, as the form shows them.
  # The channel validates them, and the lock keeps another voice settings save from being lost in
  # the merge.
  def update
    channel = @inbox.channel
    channel.with_call_settings_lock do
      hours_were_applied = call_hours_applied?(channel)
      channel.provider_config = channel.provider_config.merge(
        'ring_strategy' => params[:ring_strategy], 'ring_step_seconds' => params[:ring_step_seconds],
        'assignee_rings_first' => params[:assignee_rings_first], 'call_cooldown_seconds' => params[:call_cooldown_seconds],
        'business_hours_calls_enabled' => params[:business_hours_calls_enabled]
      )
      channel.call_routing_settings_valid
      raise ActiveRecord::RecordInvalid, channel if channel.errors.any?

      channel.apply_call_hours! if call_hours_applied?(channel) != hours_were_applied
      channel.save!(validate: false)
    end
    @inbox.update_account_cache
    render 'api/v1/accounts/inboxes/show'
  end

  private

  def call_hours_applied?(channel)
    channel.is_a?(Channel::Whatsapp) && channel.apply_call_hours?
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    channel = @inbox.channel
    return if channel.respond_to?(:call_routing_settings_valid) && channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end
end
