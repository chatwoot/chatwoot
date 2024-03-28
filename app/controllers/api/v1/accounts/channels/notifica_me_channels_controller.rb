
class Api::V1::Accounts::Channels::NotificaMeChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request


  def index
    url = URI("https://hub.notificame.com.br/v1/channels")
    # https = Net::HTTP.new(url.host, url.port)
    # https.use_ssl = true
    # header = "X-API-Token"
    # token = request.query_parameters["token"]

    # req = Net::HTTP::Get.new(url)
    # req[header] = token || 'f20018fa-eb17-11ee-880c-0efa6ad28f4f'
    # Rails.logger.debug("Headers #{req[header]}")
    # response = https.request(req)
    # channels = response.read_body

    response = HTTParty.get(
      url,
      headers: {
        'X-API-Token' => request.query_parameters["token"],
        'Content-Type' => 'application/json'
      }
    )
    if response.success?
      render :json => { data: { channels: response }}
    else
      channels = [
        {
          id: 'f44d13f2-4dc8-85fe-7973b296dd3a',
          name: 'Telegram Clairton',
          channel: 'telegram',
        },
      ];
      render :json => { data: { channels: channels }}

      # render :json => { error: response }, status: 422
    end
  end

  def create
    ActiveRecord::Base.transaction do
      build_inbox
      setup_webhooks
    rescue StandardError => e
      Rails.logger.error("NotificaMe channel create error #{e}, #{e.backtrace}")
      render_could_not_create_error(e.message)
      raise ActiveRecord::Rollback
    end
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def setup_webhooks
    ::NotificaMe::WebhookSetupService.new(inbox: @inbox).perform
  end

  def build_inbox
    @notifica_me_channel = Current.account.notifica_me_channels.create!(
      channel_id: permitted_params[:channel_id],
      channel_token: permitted_params[:channel_token],
      channel_type: permitted_params[:channel_type],
    )
    @inbox = Current.account.inboxes.create!(
      name: permitted_params[:name],
      channel: @notifica_me_channel
    )
  end

  def permitted_params
    params.require(:notifica_me_channel).permit(:channel_id, :channel_token, :channel_type, :name)
  end
end
