module AccountSettingsSchema
  extend ActiveSupport::Concern

  CAPTAIN_MODEL_PROPERTIES = Llm::Models.model_feature_keys.index_with { { 'type': %w[string null] } }.freeze
  CAPTAIN_FEATURE_PROPERTIES = Llm::Models.feature_keys.index_with { { 'type': %w[boolean null] } }.freeze

  SETTINGS_PARAMS_SCHEMA = {
    'type': 'object',
    'properties':
      {
        'auto_resolve_after': { 'type': %w[integer null], 'maximum': 1_439_856 },
        'auto_resolve_message': { 'type': %w[string null] },
        'auto_resolve_ignore_waiting': { 'type': %w[boolean null] },
        'audio_transcriptions': { 'type': %w[boolean null] },
        'auto_translate': { 'type': %w[boolean null] },
        'translation_provider': { 'type': %w[string null], 'enum': ['captain', 'google_translate', nil] },
        'auto_resolve_label': { 'type': %w[string null] },
        'enforce_mfa': { 'type': %w[boolean null] },
        'keep_pending_on_bot_failure': { 'type': %w[boolean null] },
        'hide_agent_unassigned_tab': { 'type': %w[boolean null] },
        'hide_agent_all_tab': { 'type': %w[boolean null] },
        'disable_agent_message_deletion': { 'type': %w[boolean null] },
        'whatsapp_native_disabled': { 'type': %w[boolean null] },
        'whatsapp_uazapi_disabled': { 'type': %w[boolean null] },
        'captain_auto_resolve_mode': { 'type': %w[string null], 'enum': ['evaluated', 'legacy', 'disabled', nil] },
        'brand_name': { 'type': %w[string null], 'maxLength': 255 },
        'brand_url': { 'type': %w[string null], 'maxLength': 2000 },
        'brand_color': { 'type': %w[string null], 'pattern': '^(#(\\h{3}|\\h{6}))?$' },
        'conversation_required_attributes': {
          'type': %w[array null],
          'items': { 'type': 'string' }
        },
        'captain_models': {
          'type': %w[object null],
          'properties': CAPTAIN_MODEL_PROPERTIES,
          'additionalProperties': false
        },
        'captain_features': {
          'type': %w[object null],
          'properties': CAPTAIN_FEATURE_PROPERTIES,
          'additionalProperties': false
        }
      },
    'required': [],
    'additionalProperties': true
  }.to_json.freeze
end
