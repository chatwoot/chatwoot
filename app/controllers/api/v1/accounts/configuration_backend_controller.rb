# app/controllers/api/v1/accounts/configuration_backend_controller.rb
class Api::V1::Accounts::ConfigurationBackendController < Api::V1::Accounts::BaseController
  def create
    Rails.logger.debug '=== ConfigurationBackendController#create called ==='
    store_id = Current.account.custom_attributes['store_id']

    return render json: { error: 'Store not configured for this account' }, status: :unprocessable_entity if store_id.blank?

    result = AiBackendService::SetupService.save_configuration(
      store_id,
      permitted_params[:key],
      permitted_params[:data]
    )

    render json: result
  rescue AiBackendService::SetupService::SetupError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.require(:configuration).permit(:key, data: {})
  end
end
