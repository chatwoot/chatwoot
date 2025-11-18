class Api::V1::Accounts::Integrations::WoocommerceController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:test_connection]

  def test_connection
    hook = build_test_hook
    client = Integrations::Woocommerce::Client.new(hook)
    result = client.test_connection

    if result[:success]
      render json: { success: true, message: 'Connection successful' }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def products
    client = Integrations::Woocommerce::Client.new(@hook)
    result = client.list_products(
      page: params[:page] || 1,
      per_page: params[:per_page] || 20,
      search: params[:search],
      category: params[:category]
    )

    render json: result
  rescue StandardError => e
    Rails.logger.error("WooCommerce products error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'woocommerce')
  end

  def build_test_hook
    Integrations::Hook.new(
      account: Current.account,
      app_id: 'woocommerce',
      settings: connection_params
    )
  end

  def connection_params
    params.require(:settings).permit(
      :store_name,
      :store_base_url,
      :consumer_key,
      :consumer_secret,
      :api_version
    ).to_h
  end
end
