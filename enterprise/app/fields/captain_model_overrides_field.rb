require 'administrate/field/base'

class CaptainModelOverridesField < Administrate::Field::Base
  def feature_rows
    Llm::Models.feature_keys.map do |feature_key|
      route = Llm::FeatureRouter.resolve(feature: feature_key, account: resource)

      {
        key: feature_key,
        name: feature_name(feature_key),
        provider: provider_label(route[:provider]),
        provider_id: route[:provider],
        model: model_label(route[:model]),
        model_id: route[:model],
        default_model: model_label(default_model_id(feature_key)),
        default_model_id: default_model_id(feature_key),
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

  def default_model_id(feature_key)
    Llm::Models.default_model_for(feature_key)
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

  def feature_name(feature_key)
    I18n.t("super_admin.captain_model_overrides.features.#{feature_key}", default: feature_key.humanize)
  end

  def source_label(source)
    I18n.t("super_admin.captain_model_overrides.sources.#{source}")
  end
end
