# Sends a WhatsApp inbox's call hours to Meta again, after a sync failed
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
    return if @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end
end
