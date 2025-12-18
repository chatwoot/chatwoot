class Api::V1::Accounts::Captain::ConfigController < Api::V1::Accounts::BaseController
  before_action :current_account

  def show
    render json: {
      providers: Llm::ConfigService.providers,
      models: Llm::ConfigService.models,
      features: features_with_account_preferences
    }
  end

  private

  def features_with_account_preferences
    preferences = Current.account.captain_preferences
    account_features = preferences[:features] || {}
    account_models = preferences[:models] || {}

    Llm::ConfigService.all_features_config.transform_keys(&:to_s).to_h do |feature_key, feature_config|
      selected_model = account_models[feature_key] || feature_config[:default]
      [feature_key, feature_config.merge(
        enabled: account_features[feature_key] == true,
        selected: selected_model
      )]
    end
  end
end
