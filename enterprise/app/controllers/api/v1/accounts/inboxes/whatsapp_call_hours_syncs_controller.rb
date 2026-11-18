class Api::V1::Accounts::Inboxes::WhatsappCallHoursSyncsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  def create
    @inbox.channel.schedule_call_hours_sync(force: true)
    head :ok
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if retryable?(@inbox.channel)

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end

  def retryable?(channel)
    channel.is_a?(Channel::Whatsapp) && (channel.voice_enabled? || channel.call_hours_last_payload.present?)
  end
end
