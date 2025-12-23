class Api::V1::Accounts::Captain::ConfigController < Api::V1::Accounts::BaseController
  before_action :current_account

  def show
    render json: {
      providers: Llm::Models.providers,
      models: Llm::Models.models,
      features: features_with_account_preferences
    }
  end

  private

  def features_with_account_preferences
    preferences = Current.account.captain_preferences
    account_features = preferences[:features] || {}
    account_models = preferences[:models] || {}

    Llm::Models.feature_keys.index_with do |feature_key|
      config = Llm::Models.feature_config(feature_key)
      config.merge(
        enabled: account_features[feature_key] == true,
        selected: account_models[feature_key] || config[:default]
      )
    end
  end
end
