module PortalConfigSchema
  extend ActiveSupport::Concern

  # Per-locale overrides for portal level fields. Any locale present in
  # `allowed_locales` may carry its own `name`, `page_title` and `header_text`.
  # Missing values fall back to the default locale and finally to the base column.
  LOCALE_TRANSLATION_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'name' => { 'type' => %w[string null] },
      'page_title' => { 'type' => %w[string null] },
      'header_text' => { 'type' => %w[string null] }
    },
    'additionalProperties' => false
  }.freeze

  CONFIG_PARAMS_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'allowed_locales' => { 'type' => %w[array null], 'items' => { 'type' => 'string' } },
      'default_locale' => { 'type' => %w[string null] },
      'draft_locales' => { 'type' => %w[array null], 'items' => { 'type' => 'string' } },
      'layout' => { 'type' => %w[string null], 'enum' => ['classic', 'documentation', nil] },
      # TODO: unused reserved key; remove with a migration that scrubs it from existing portals' config
      'website_token' => { 'type' => %w[string null] },
      'social_profiles' => { 'type' => %w[object null] },
      'locale_translations' => {
        'type' => %w[object null],
        'additionalProperties' => LOCALE_TRANSLATION_SCHEMA
      }
    },
    'required' => [],
    'additionalProperties' => true
  }.to_json.freeze
end
