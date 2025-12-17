class Api::V1::Accounts::Captain::ConfigController < Api::V1::Accounts::BaseController
  before_action :current_account

  def show
    render json: {
      providers: Llm::ConfigService.providers,
      models: Llm::ConfigService.models,
      features: Llm::ConfigService.all_features_config
    }
  end
end
