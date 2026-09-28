class Api::V1::Accounts::Captain::PreferencesController < Api::V1::Accounts::BaseController
  before_action :authorize_account_update, only: [:update]

  def show
    render json: preferences_payload
  end

  def update
    params_to_update = captain_params
    @current_account.captain_models = params_to_update[:captain_models] if params_to_update.key?(:captain_models)
    @current_account.captain_features = params_to_update[:captain_features] if params_to_update.key?(:captain_features)
    @current_account.copilot_assistant_id = params_to_update[:copilot_assistant_id] if params_to_update.key?(:copilot_assistant_id)
    if params_to_update.keys == [:copilot_assistant_id]
      # Older model overrides must not block an unrelated Copilot choice.
      # rubocop:disable Rails/SkipsModelValidations
      @current_account.update_columns(settings: @current_account.settings, updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    else
      @current_account.save!
    end

    render json: preferences_payload
  end

  private

  def preferences_payload
    {
      providers: Llm::Models.providers,
      models: Llm::Models.models,
      features: features_with_account_preferences,
      copilot_assistant_id: Current.account.copilot_assistant_id,
      copilot_tools: copilot_tools
    }
  end

  def authorize_account_update
    authorize @current_account, :update?
  end

  def captain_params
    permitted = {}
    permitted[:captain_models] = merged_captain_models if params[:captain_models].present?
    permitted[:captain_features] = merged_captain_features if params[:captain_features].present?
    if params.key?(:copilot_assistant_id)
      assistant_id = params[:copilot_assistant_id].presence
      Current.account.captain_assistants.find(assistant_id) if assistant_id
      permitted[:copilot_assistant_id] = assistant_id&.to_i
    end
    permitted
  end

  def copilot_tools
    return [] unless defined?(Captain::Copilot::ChatService)

    assistant = Current.account.captain_assistants.find_by(id: Current.account.copilot_assistant_id) ||
                Current.account.captain_assistants.first
    return [] unless assistant

    Captain::Copilot::ChatService.tool_inventory(assistant: assistant, user: Current.user).map do |tool|
      { name: tool.class.name.demodulize.underscore, available: tool.active? }
    end
  end

  def merged_captain_models
    existing_models = @current_account.captain_models || {}
    existing_models.merge(permitted_captain_models).compact_blank.presence
  end

  def merged_captain_features
    existing_features = @current_account.captain_features || {}
    existing_features.merge(permitted_captain_features)
  end

  def permitted_captain_models
    params.require(:captain_models).permit(*captain_feature_keys).to_h.stringify_keys
  end

  def permitted_captain_features
    params.require(:captain_features).permit(*captain_feature_keys).to_h.stringify_keys
  end

  def captain_feature_keys
    Llm::Models.feature_keys.map(&:to_sym)
  end

  def features_with_account_preferences
    preferences = Current.account.captain_preferences
    account_features = preferences[:features] || {}

    Llm::Models.feature_keys.index_with do |feature_key|
      config = Llm::Models.feature_config(feature_key)
      route = Llm::FeatureRouter.resolve(feature: feature_key, account: Current.account)
      config.merge(
        default: default_model_for(feature_key),
        enabled: account_features[feature_key] == true,
        model: route[:model],
        selected: route[:model],
        provider: route[:provider],
        source: route[:source]
      )
    end
  end

  def default_model_for(feature_key)
    return Llm::FeatureRouter::CAPTAIN_V2_ASSISTANT_MODEL if feature_key == 'assistant' && Current.account.feature_enabled?('captain_integration')

    Llm::Models.default_model_for(feature_key)
  end
end
