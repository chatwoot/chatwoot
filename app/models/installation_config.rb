# == Schema Information
#
# Table name: installation_configs
#
#  id               :bigint           not null, primary key
#  locked           :boolean          default(TRUE), not null
#  name             :string           not null
#  serialized_value :jsonb            not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_installation_configs_on_name                 (name) UNIQUE
#  index_installation_configs_on_name_and_created_at  (name,created_at) UNIQUE
#
class InstallationConfig < ApplicationRecord
  CAPTAIN_LLM_CONFIG_KEYS = %w[
    CAPTAIN_OPEN_AI_API_KEY
    CAPTAIN_OPEN_AI_ENDPOINT
    CAPTAIN_OPEN_AI_MODEL
  ].freeze

  RESTART_REQUIRED_CONFIG_KEYS = (CAPTAIN_LLM_CONFIG_KEYS + %w[
    LANGFUSE_BASE_URL
    LANGFUSE_PUBLIC_KEY
    LANGFUSE_SECRET_KEY
    OTEL_PROVIDER
  ]).freeze

  MOBILE_APP_VERSION_CONFIG_KEYS = %w[MOBILE_APP_MIN_IOS_VERSION MOBILE_APP_MIN_ANDROID_VERSION].freeze
  # MAJOR.MINOR.PATCH without leading zeros, as semantic versioning requires.
  # Valid: 4.9.12, 10.0.0. Invalid: 4.9, 4.09.1, v4.9.12, 4.9.12-beta.
  MOBILE_APP_VERSION_FORMAT = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/

  # The serialized_value column is jsonb but production data is mixed: older rows
  # were written as YAML strings by upstream's serialize :coder => YAML chain,
  # and some rows were written as native jsonb hashes. The stock YAML coder
  # raises TypeError on native-hash rows. This coder reads either shape and
  # always writes YAML strings so data converges on a single format over time.
  class SerializedValueCoder # rubocop:disable Style/OneClassPerFile
    def self.dump(value)
      hash = value.is_a?(Hash) ? value : { value: value }
      YAML.dump(hash.with_indifferent_access)
    end

    def self.load(value)
      return {}.with_indifferent_access if value.blank?

      case value
      when String
        YAML.safe_load(value, permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Symbol])
            .with_indifferent_access
      when Hash
        value.with_indifferent_access
      else
        {}.with_indifferent_access
      end
    end
  end

  serialize :serialized_value, coder: SerializedValueCoder

  before_validation :set_lock
  validates :name, presence: true
  validate :saml_sso_users_check, if: -> { name == 'ENABLE_SAML_SSO_LOGIN' }
  validate :mobile_app_version_format, if: -> { name.in?(MOBILE_APP_VERSION_CONFIG_KEYS) }
  validate :instagram_login_method, if: -> { name == 'INSTAGRAM_LOGIN_METHOD' }

  # TODO: Get rid of default scope
  # https://stackoverflow.com/a/1834250/939299
  default_scope { order(created_at: :desc) }
  scope :editable, -> { where(locked: false) }

  after_commit :clear_cache

  def value
    serialized_value[:value]
  end

  def value=(value_to_assigned)
    self.serialized_value = {
      value: value_to_assigned
    }.with_indifferent_access
  end

  private

  def instagram_login_method
    return if value.blank? || %w[instagram_login unified_login].include?(value)

    errors.add(:value, :inclusion)
  end

  def set_lock
    self.locked = true if locked.nil?
  end

  def clear_cache
    GlobalConfig.clear_cache
  end

  def saml_sso_users_check
    return unless value == false || value == 'false'
    return unless User.exists?(provider: 'saml')

    errors.add(:base, 'Cannot disable SAML SSO login while users are using SAML authentication')
  end

  def mobile_app_version_format
    return if value.blank? || value.to_s.match?(MOBILE_APP_VERSION_FORMAT)

    errors.add(:base, "#{value} is not a valid app version. Use a version like 4.10.0.")
  end
end
