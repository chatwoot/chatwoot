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
  validate :config_json_format

  scope :active, -> { where(archived: false) }

  CONFIG_JSON_KEYS = %w[allowed_locales default_locale draft_locales website_token].freeze

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

  def display_title
    page_title.presence || name
  end

  private

  def config_json_format
    self.config = (config || {}).deep_stringify_keys
    config['allowed_locales'] = allowed_locale_codes
    config['default_locale'] = default_locale
    config['draft_locales'] = draft_locale_codes
    denied_keys = config.keys - CONFIG_JSON_KEYS
    errors.add(:cofig, "in portal on #{denied_keys.join(',')} is not supported.") if denied_keys.any?
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
