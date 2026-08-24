# == Schema Information
#
# Table name: captain_tool_catalog_installations
#
#  id                  :bigint           not null, primary key
#  completed_at        :datetime
#  error_code          :string
#  expires_at          :datetime         not null
#  oauth_nonce_digest  :string
#  provider_key        :string           not null
#  resulting_tool_ids  :bigint           default([]), not null, is an Array
#  selected_templates  :jsonb            default([]), not null
#  status              :string           default("pending"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  initiated_by_id     :bigint           not null
#  integration_hook_id :bigint
#
# Indexes
#
#  idx_catalog_installations_account_status                       (account_id,status)
#  idx_catalog_installations_expires_at                           (expires_at)
#  idx_catalog_installations_oauth_nonce                          (oauth_nonce_digest) UNIQUE WHERE (oauth_nonce_digest IS NOT NULL)
#  idx_on_integration_hook_id_49fcb99f37                          (integration_hook_id)
#  index_captain_tool_catalog_installations_on_account_id         (account_id)
#  index_captain_tool_catalog_installations_on_initiated_by_id    (initiated_by_id)
#
class Captain::ToolCatalogInstallation < ApplicationRecord
  STATUSES = %w[pending awaiting_connection validating installing completed failed expired].freeze
  ACTIVE_STATUSES = %w[pending awaiting_connection validating installing].freeze
  KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/
  VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/
  NONCE_DIGEST_FORMAT = /\A[a-f0-9]{64}\z/
  ERROR_CODE_FORMAT = /\A[a-z][a-z0-9_]*\z/
  SELECTED_TEMPLATE_KEYS = %w[configuration template_key template_version].freeze

  self.table_name = 'captain_tool_catalog_installations'

  belongs_to :account
  belongs_to :initiated_by, class_name: 'User'
  belongs_to :integration_hook, class_name: 'Integrations::Hook', optional: true

  enum :status, STATUSES.index_by(&:itself), default: :pending, validate: true

  validates :provider_key, presence: true, format: { with: KEY_FORMAT }
  validates :expires_at, presence: true
  validates :oauth_nonce_digest, format: { with: NONCE_DIGEST_FORMAT }, uniqueness: true, allow_nil: true
  validates :error_code, format: { with: ERROR_CODE_FORMAT }, allow_nil: true
  validates :completed_at, presence: true, if: :completed?
  validate :validate_selected_templates
  validate :validate_resulting_tool_id_format
  validate :validate_completed_result
  validate :validate_resulting_tool_accounts
  validate :validate_integration_hook_account

  scope :active, -> { where(status: ACTIVE_STATUSES) }

  private

  def validate_selected_templates
    return errors.add(:selected_templates, 'must be a non-empty array') unless selected_templates.is_a?(Array) && selected_templates.any?

    selected_templates.each do |template|
      next if valid_selected_template?(template)

      errors.add(:selected_templates, 'must contain template keys, versions, and object configuration only')
      break
    end
  end

  def valid_selected_template?(template)
    return false unless template.is_a?(Hash)

    template = template.stringify_keys
    return false unless template.keys.sort == SELECTED_TEMPLATE_KEYS

    KEY_FORMAT.match?(template['template_key']) &&
      VERSION_FORMAT.match?(template['template_version']) &&
      template['configuration'].is_a?(Hash)
  end

  def validate_resulting_tool_id_format
    return if valid_resulting_tool_ids?

    errors.add(:resulting_tool_ids, 'must contain unique positive integer IDs only')
  end

  def validate_completed_result
    errors.add(:resulting_tool_ids, 'must be present for completed installations') if completed? && resulting_tool_ids.empty?
  end

  def validate_resulting_tool_accounts
    return unless valid_resulting_tool_ids? && resulting_tool_ids.any? && account_id.present?
    return if Captain::CustomTool.where(account_id: account_id, id: resulting_tool_ids).count == resulting_tool_ids.length

    errors.add(:resulting_tool_ids, 'must reference tools from the same account')
  end

  def valid_resulting_tool_ids?
    resulting_tool_ids.is_a?(Array) && resulting_tool_ids.uniq.length == resulting_tool_ids.length &&
      resulting_tool_ids.all? { |id| id.is_a?(Integer) && id.positive? }
  end

  def validate_integration_hook_account
    return if integration_hook.blank? || integration_hook.account_id == account_id

    errors.add(:integration_hook, 'must belong to the same account')
  end
end
