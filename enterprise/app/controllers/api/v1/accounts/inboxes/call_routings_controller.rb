class Api::V1::Accounts::Inboxes::CallRoutingsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  # All four settings are sent together, as the form shows them. The channel validates them, and
  # the lock keeps another voice settings save from being lost in the merge.
  def update
    channel = @inbox.channel
    channel.with_lock do
      channel.update!(provider_config: channel.provider_config.merge(
        'ring_strategy' => params[:ring_strategy], 'ring_step_seconds' => params[:ring_step_seconds],
        'prefer_free_agents' => params[:prefer_free_agents], 'call_cooldown_seconds' => params[:call_cooldown_seconds]
      ))
    end
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
end
