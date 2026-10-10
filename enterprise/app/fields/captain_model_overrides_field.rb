require 'administrate/field/base'

class CaptainModelOverridesField < Administrate::Field::Base
  def feature_rows
    build_feature_rows(Llm::Models.feature_keys)
  end

  def internal_feature_rows
    build_feature_rows(Llm::Models.internal_feature_keys)
  end

  private

  def build_feature_rows(feature_keys)
    feature_keys.map do |feature_key|
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
        default_option_label: default_option_label(feature_key),
        source: route[:source],
        source_label: source_label(route[:source]),
        selected_override: selected_override(feature_key),
        options: model_options(feature_key)
      }.merge(reasoning_attributes(feature_key, route))
    end
  end

  def reasoning_attributes(feature_key, route)
    return {} unless Llm::FeatureRouter::REASONING_FEATURES.include?(feature_key)

    {
      selected_effort: resource.captain_reasoning_efforts&.[](feature_key),
      effort_options: effort_options(route[:model]),
      effort_options_by_model: (Llm::Models.models_for(feature_key) + ['']).index_with do |model|
        effort_options(model.presence || default_model_id(feature_key))
      end,
      effective_effort: effective_effort_label(route),
      custom_endpoint: !Llm::FeatureRouter.standard_openai_endpoint?
    }
  end

  def effort_options(model)
    return [] unless Llm::Models.provider_for(model) == 'openai'

    RubyLLM.models.find(model).reasoning_option_values(:effort).map do |effort|
      [I18n.t("super_admin.captain_model_overrides.efforts.#{effort}", default: effort.humanize), effort]
    end
  end

  def effective_effort_label(route)
    return I18n.t('super_admin.captain_model_overrides.show.custom_endpoint') unless Llm::FeatureRouter.standard_openai_endpoint?

    effort = route[:reasoning_effort]
    return I18n.t("super_admin.captain_model_overrides.efforts.#{effort}") if effort

    I18n.t('super_admin.captain_model_overrides.show.provider_default')
  end

  def selected_override(feature_key)
    resource.captain_models&.[](feature_key).presence
  end

  def default_model_id(feature_key)
    return Llm::FeatureRouter::CAPTAIN_V2_ASSISTANT_MODEL if feature_key == 'assistant' && resource.feature_enabled?('captain_integration')

    Llm::Models.default_model_for(feature_key)
  end

  def model_options(feature_key)
    Llm::Models.feature_config(feature_key)[:models].map do |model|
      [model[:display_name] || model[:id], model[:id]]
    end
  end

  def default_option_label(feature_key)
    return internal_default_option_label(feature_key) if Llm::Models.internal_feature?(feature_key)

    model_id = default_model_id(feature_key)
    I18n.t('super_admin.captain_model_overrides.form.use_default', model: model_label(model_id), model_id: model_id)
  end

  def internal_default_option_label(feature_key)
    route = Llm::FeatureRouter.resolve(feature: feature_key)
    translation_key = route[:source] == :installation_override ? 'use_installation_model' : 'use_default'

    I18n.t(
      "super_admin.captain_model_overrides.form.#{translation_key}",
      model: model_label(route[:model]),
      model_id: route[:model]
    )
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
