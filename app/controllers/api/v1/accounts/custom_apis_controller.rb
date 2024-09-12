class Api::V1::Accounts::CustomApisController < Api::V1::Accounts::BaseController
  before_action :fetch_custom_apis, except: [:create]
  before_action :fetch_custom_api, only: [:show, :update, :destroy]
  before_action :set_account

  def index; end

  def show; end

  def create
    @custom_api = Current.account.custom_apis.create!(
      custom_api_params.merge(user_id: Current.user.id)
    )
  end

  def update
    @custom_api.update!(custom_api_params)
  end

  def update_all_orders
    updated = []

    @account.custom_apis.each do |custom_api|
      custom_api.import_orders
      updated << custom_api
    end

    if updated.any?
      render json: { message: "#{updated.size} Custom APIs updated successfully" }, status: :ok
    else
      render json: { errors: 'No Custom APIs were updated' }, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_api.destroy
    head :no_content
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def fetch_custom_apis
    @custom_apis = Current.account.custom_apis
  end

  def fetch_custom_api
    @custom_api = @custom_apis.find(permitted_params[:id])
  end

  def custom_api_params
    params.require(:custom_api).permit(:name, :base_url, :api_key)
  end

  def permitted_params
    params.permit(:id)
  end
end
