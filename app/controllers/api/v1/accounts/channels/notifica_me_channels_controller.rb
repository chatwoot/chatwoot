
class Api::V1::Accounts::Channels::NotificaMeChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request


  def index
    unless request.query_parameters["token"]
      return render :json => { error: "Put the NotificaMe Token" }, status: 422
    end
    url = URI("https://hub.notificame.com.br/v1/channels")
    response = HTTParty.get(
      url,
      headers: {
        'X-API-Token' => request.query_parameters["token"],
        'Content-Type' => 'application/json'
      },
      format: :json
    )
    if response.success?
      render :json => { data: { channels: response.parsed_response }}, status: 200
    else
      render :json => { error: response.parsed_response }, status: 422
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
      notifica_me_id: permitted_params[:notifica_me_id],
      notifica_me_token: permitted_params[:notifica_me_token],
      notifica_me_type: permitted_params[:notifica_me_type],
    )
    @inbox = Current.account.inboxes.create!(
      name: permitted_params[:name],
      channel: @notifica_me_channel
    )
  end

  def permitted_params
    params.require(:notifica_me_channel).permit(:notifica_me_id, :notifica_me_token, :notifica_me_type, :name)
  end
end
