class Api::V1::Accounts::ZaloOa::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :authorize_request

  def create
    state = SecureRandom.hex(24)
    ::Redis::Alfred.setex(cache_key(state), pending_payload.to_json, 15.minutes)

    render json: {
      redirect_url: ZaloOa::Client.permission_url(
        app_id: permitted_params[:app_id],
        redirect_uri: "#{ENV.fetch('FRONTEND_URL', nil)}/zalo_oa/callback",
        state: state
      )
    }
  end

  private

  def authorize_request
    authorize ::Inbox, :create?
  end

  def pending_payload
    {
      account_id: Current.account.id,
      app_id: permitted_params[:app_id],
      app_secret: permitted_params[:app_secret],
      oa_secret_key: permitted_params[:oa_secret_key]
    }
  end

  def cache_key(state)
    "zalo_oa:pending:#{state}"
  end

  def permitted_params
    params.permit(:app_id, :app_secret, :oa_secret_key)
  end
end
