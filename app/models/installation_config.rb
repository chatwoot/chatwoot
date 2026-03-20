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
  # The serialized_value column is jsonb but contains YAML strings (legacy data).
  # We need a custom coder that handles both YAML strings and native JSON objects.
  class SerializedValueCoder # rubocop:disable Style/OneClassPerFile
    def self.dump(value)
      return value.with_indifferent_access if value.is_a?(Hash)

      { value: value }.with_indifferent_access
    end

    def self.load(value)
      return {}.with_indifferent_access if value.blank?

      # Handle YAML strings stored in jsonb column (legacy data)
      if value.is_a?(String)
        YAML.safe_load(value, permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Symbol])
            .with_indifferent_access
      elsif value.is_a?(Hash)
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

  # TODO: Get rid of default scope
  # https://stackoverflow.com/a/1834250/939299
  default_scope { order(created_at: :desc) }
  scope :editable, -> { where(locked: false) }

  after_commit :clear_cache

  def value
    # This is an extra hack again cause of the YAML serialization, in case of new object initialization in super admin
    # It was throwing error as the default value of column '{}' was failing in deserialization.
    return {}.with_indifferent_access if new_record? && @attributes['serialized_value']&.value_before_type_cast == '{}'

    serialized_value[:value]
  end

  def value=(value_to_assigned)
    self.serialized_value = {
      value: value_to_assigned
    }.with_indifferent_access
  end

  private

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
end
