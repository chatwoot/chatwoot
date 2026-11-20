class Api::V1::Accounts::Inboxes::WhatsappCallHoursController < Api::V1::Accounts::BaseController
  before_action :fetch_channel

  def show
    render json: { matches_whatsapp: @channel.call_hours_match_whatsapp? }
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    @channel.with_call_settings_lock { @channel.apply_call_hours! }
    head :ok
  end

  private

  def fetch_channel
    inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize inbox, :update?
    @channel = inbox.channel
    return if @channel.is_a?(Channel::Whatsapp) && @channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end
end
