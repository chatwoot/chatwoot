class Api::V1::Accounts::Integrations::TiendanubeController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook, only: [:destroy, :orders]

  def auth
    session[:tiendanube_account_id] = permitted_params[:account_id]

    render json: {
      redirect_url: tiendanube_authorize_url
    }
  end

  # def create
  #   hook = Integrations::Tiendanube::HookBuilder.new(
  #     account: Current.account,
  #     code: params[:code]
  #   ).perform

  #   render json: hook, status: :created
  # end

  def orders
    orders = Integrations::Tiendanube::OrdersBuilder
               .new(hook: @hook)
               .fetch_orders

    render json: orders
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'tiendanube')
  end

  def tiendanube_authorize_url
    app_id = GlobalConfigService.load('TIENDANUBE_CLIENT_ID', nil)

    "https://www.tiendanube.com/apps/#{app_id}/authorize"
  end

  def tiendanube_callback_url
    "#{ENV.fetch('FRONTEND_URL')}/tiendanube/callback"
  end

  def generate_tiendanube_state(account_id)
    verifier.generate({
      account_id: account_id,
      issued_at: Time.current.to_i
    })
  end

  def verifier
    Rails.application.message_verifier(:tiendanube)
  end

  def permitted_params
    params.permit(:account_id)
  end
end
