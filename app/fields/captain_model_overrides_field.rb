require 'administrate/field/base'

class CaptainModelOverridesField < Administrate::Field::Base
  def feature_rows
    Llm::FeatureRouter.feature_keys.map do |feature_key|
      route = Llm::FeatureRouter.resolve(feature: feature_key, account: resource)

      {
        key: feature_key,
        name: feature_name(feature_key),
        provider: route[:provider],
        provider_id: route[:provider],
        model: route[:model],
        model_id: route[:model],
        default_model: route[:model],
        default_model_id: route[:model],
        source: route[:source],
        source_label: source_label(route[:source]),
        selected_override: selected_override(feature_key),
        options: []
      }
    end
  end

  private

  def selected_override(feature_key)
    resource.captain_models&.[](feature_key).presence
  end

  def feature_name(feature_key)
    I18n.t("super_admin.captain_model_overrides.features.#{feature_key}", default: feature_key.humanize)
  end

  def source_label(source)
    I18n.t("super_admin.captain_model_overrides.sources.#{source}")
  end
end
