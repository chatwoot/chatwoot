# Replaces the URL a Z-API inbox receives its events at, for when the token in it leaked.
# See Whatsapp::Providers::WhatsappZapiService#rotate_webhook_url.
class Api::V1::Accounts::Whatsapp::ZapiWebhookController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  def rotate
    Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: @inbox.channel).rotate_webhook_url
    head :ok
  rescue Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError
    render json: { message: 'Z-API did not accept the new webhook URL' }, status: :unprocessable_entity
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    raise ActiveRecord::RecordNotFound unless @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'zapi'
  end
end
