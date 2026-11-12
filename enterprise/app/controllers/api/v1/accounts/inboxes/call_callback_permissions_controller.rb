# Whether WhatsApp offers a caller nobody answered to let the business call back, which Meta keeps
# for the number
class Api::V1::Accounts::Inboxes::CallCallbackPermissionsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  def update
    enabled = params[:callback_permission_enabled]
    return render_could_not_create_error(I18n.t('inbox.call_routing.invalid_callback_permission')) unless [true, false].include?(enabled)

    @inbox.channel.update_callback_permission!(enabled)
    @inbox.update_account_cache
    head :ok
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    return if @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.voice_enabled?

    render_could_not_create_error(I18n.t('inbox.voice_settings.unsupported_inbox'))
  end
end
