# == Schema Information
#
# Table name: portals
#
#  id                    :bigint           not null, primary key
#  archived              :boolean          default(FALSE)
#  color                 :string
#  config                :jsonb
#  custom_domain         :string
#  header_text           :text
#  homepage_link         :string
#  name                  :string           not null
#  page_title            :string
#  slug                  :string           not null
#  ssl_settings          :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#  channel_web_widget_id :bigint
#
# Indexes
#
#  index_portals_on_channel_web_widget_id  (channel_web_widget_id)
#  index_portals_on_custom_domain          (custom_domain) UNIQUE
#  index_portals_on_slug                   (slug) UNIQUE
#
class Portal < ApplicationRecord
  include Rails.application.routes.url_helpers
  include PortalConfigSchema

  DEFAULT_COLOR = '#1f93ff'.freeze

  belongs_to :account
  has_many :categories, dependent: :destroy_async
  has_many :folders,  through: :categories
  has_many :articles, dependent: :destroy_async
  has_one_attached :logo
  has_many :inboxes, dependent: :nullify
  belongs_to :channel_web_widget, class_name: 'Channel::WebWidget', optional: true

  before_validation -> { normalize_empty_string_to_nil(%i[custom_domain homepage_link]) }
  validates :account_id, presence: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :custom_domain, uniqueness: true, allow_nil: true
  validates :color, format: { with: /\A#(?:\h{3}|\h{6})\z/ }, allow_blank: true
  before_validation :normalize_config
  validate :validate_config
  validates_with JsonSchemaValidator,
                 schema: PortalConfigSchema::CONFIG_PARAMS_SCHEMA,
                 attribute_resolver: ->(record) { record.config }

  scope :active, -> { where(archived: false) }

  # TODO: 'website_token' is an unused reserved key; remove with a migration that scrubs it from existing portals' config
  CONFIG_JSON_KEYS = %w[allowed_locales default_locale draft_locales website_token social_profiles layout locale_translations].freeze

  def file_base_data
    {
      id: logo.id,
      portal_id: id,
      file_type: logo.content_type,
      account_id: account_id,
      file_url: url_for(logo),
      blob_id: logo.blob.signed_id,
      filename: logo.filename.to_s
    }
  end

  def default_locale
    config_value('default_locale').presence || allowed_locale_codes.first || 'en'
  end

  def allowed_locale_codes
    allowed_locale_codes = normalize_locale_codes(config_value('allowed_locales'))
    return allowed_locale_codes if allowed_locale_codes.present?

    [config_value('default_locale').presence || 'en']
  end

  def draft_locale_codes
    allowed_locales = allowed_locale_codes
    drafted_locales = normalize_locale_codes(drafted_locale_values)

    allowed_locales.select { |locale| drafted_locales.include?(locale) }
  end

  def public_locale_codes
    allowed_locale_codes - draft_locale_codes
  end

  def draft_locale?(locale)
    draft_locale_codes.include?(locale)
  end

  def color
    self[:color].presence || DEFAULT_COLOR
  end

  def display_title(locale = default_locale)
    localized_value('page_title', locale).presence || localized_value('name', locale)
  end

  # Resolves a portal level field for a locale, falling back to the default
  # locale's value (its override or the base column) when the locale has no
  # override of its own.
  def localized_value(field, locale = default_locale)
    translations = config_value('locale_translations') || {}
    translations.dig(locale.to_s, field).presence ||
      translations.dig(default_locale, field).presence ||
      self[field]
  end

  def layout
    config_value('layout').presence || 'classic'
  end

  def social_profiles
    config_value('social_profiles') || {}
  end

  private

  def normalize_config
    self.config = persisted_config.merge((config || {}).deep_stringify_keys)
    config['allowed_locales'] = allowed_locale_codes
    config['default_locale'] = default_locale
    config['draft_locales'] = draft_locale_codes
  end

  def validate_config
    denied_keys = config.keys - CONFIG_JSON_KEYS
    errors.add(:config, "in portal on #{denied_keys.join(',')} is not supported.") if denied_keys.any?
    errors.add(:config, 'default locale cannot be drafted.') if draft_locale?(default_locale)
  end

  def normalize_locale_codes(locale_codes)
    Array(locale_codes).filter_map(&:presence).uniq
  end

  def persisted_config
    (attribute_in_database('config') || {}).deep_stringify_keys
  end

  def drafted_locale_values
    return config_value('draft_locales') if config_has_key?('draft_locales')

    persisted_config['draft_locales']
  end

  def config_has_key?(key)
    config.is_a?(Hash) && (config.key?(key) || config.key?(key.to_sym))
  end

  def config_value(key)
    return unless config.is_a?(Hash)

    config[key] || config[key.to_sym]
  end
end

Portal.include_mod_with('Concerns::Portal')
