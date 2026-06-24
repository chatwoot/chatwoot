require 'administrate/field/base'

class CaptainModelOverridesField < Administrate::Field::Base
  def feature_rows
    Llm::Models.feature_keys.map do |feature_key|
      route = Llm::FeatureRouter.resolve(feature: feature_key, account: resource)

      {
        key: feature_key,
        name: feature_key.humanize,
        provider: provider_label(route[:provider]),
        provider_id: route[:provider],
        model: model_label(route[:model]),
        model_id: route[:model],
        source: route[:source],
        source_label: source_label(route[:source]),
        selected_override: selected_override(feature_key),
        options: model_options(feature_key)
      }
    end
  end

  private

  def selected_override(feature_key)
    resource.captain_models&.[](feature_key).presence
  end

  def model_options(feature_key)
    Llm::Models.feature_config(feature_key)[:models].map do |model|
      [model[:display_name] || model[:id], model[:id]]
    end
  end

  def model_label(model_id)
    Llm::Models.model_config(model_id)&.dig('display_name') || model_id
  end

  def provider_label(provider_id)
    Llm::Models.providers.dig(provider_id, 'display_name') || provider_id
  end

  def source_label(source)
    source == :account_override ? 'Account override' : 'Default'
  end
end
