# == Schema Information
#
# Table name: captain_custom_tools
#
#  id                  :bigint           not null, primary key
#  auth_config         :jsonb            not null
#  auth_type           :string           default("none")
#  category_key        :string
#  configuration       :jsonb            not null
#  definition          :jsonb            not null
#  definition_digest   :string
#  description         :text
#  enabled             :boolean          default(TRUE), not null
#  endpoint_url        :text
#  http_method         :string           default("GET"), not null
#  input_schema        :jsonb            not null
#  output_schema       :jsonb            not null
#  param_schema        :jsonb
#  provider_key        :string
#  request_template    :text
#  response_template   :text
#  risk_class          :string
#  slug                :string           not null
#  source_kind         :string           default("custom"), not null
#  template_key        :string
#  template_version    :string
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  integration_hook_id :bigint
#
# Indexes
#
#  idx_captain_tools_account_provider                 (account_id,provider_key) WHERE (provider_key IS NOT NULL)
#  idx_captain_tools_account_source                   (account_id,source_kind)
#  idx_captain_tools_catalog_template                 (account_id,provider_key,template_key) UNIQUE WHERE ((source_kind)::text = 'catalog'::text)
#  idx_captain_tools_integration_hook                 (integration_hook_id)
#  index_captain_custom_tools_on_account_id           (account_id)
#  index_captain_custom_tools_on_account_id_and_slug  (account_id,slug) UNIQUE
#
class Captain::CustomTool < ApplicationRecord
  class LimitExceededError < StandardError; end

  MAX_PER_ACCOUNT = 15
  CATALOG_MAX_PER_ACCOUNT = 50
  CATALOG_FEATURE = 'captain_tool_catalog'.freeze
  SOURCE_KINDS = %w[custom generated catalog].freeze
  RISK_CLASSES = %w[read low_impact_write approval_required].freeze
  KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/
  VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/
  DIGEST_FORMAT = /\Asha256:[a-f0-9]{64}\z/

  include Concerns::Toolable
  include Concerns::SafeEndpointValidatable

  self.table_name = 'captain_custom_tools'

  NAME_PREFIX = 'custom'.freeze
  NAME_SEPARATOR = '_'.freeze
  # OpenAI enforces a 64-char limit on function names. The slug is used
  # verbatim as the tool name in LLM requests, so it must fit within this limit.
  MAX_SLUG_LENGTH = 64
  COLLISION_SUFFIX_LENGTH = 7 # "_" + 6 random alphanumeric chars
  PARAM_SCHEMA_VALIDATION = {
    'type': 'array',
    'items': {
      'type': 'object',
      'properties': {
        'name': { 'type': 'string' },
        'type': { 'type': 'string' },
        'description': { 'type': 'string' },
        'required': { 'type': 'boolean' }
      },
      'required': %w[name type description],
      'additionalProperties': false
    }
  }.to_json.freeze

  belongs_to :account
  belongs_to :integration_hook, class_name: 'Integrations::Hook', optional: true

  enum :http_method, %w[GET POST].index_by(&:itself), validate: true
  enum :auth_type, %w[none bearer basic api_key].index_by(&:itself), default: :none, validate: true, prefix: :auth
  enum :source_kind, SOURCE_KINDS.index_by(&:itself), default: :custom, validate: true, prefix: :source
  enum :risk_class, RISK_CLASSES.index_by(&:itself), validate: { allow_nil: true }, prefix: :risk

  before_validation :generate_slug
  before_create :ensure_within_limit

  validates :slug, presence: true, uniqueness: { scope: :account_id }, length: { maximum: MAX_SLUG_LENGTH }
  validates :title, presence: true
  validates :endpoint_url, presence: true, unless: :source_catalog?
  validates :provider_key, :category_key, :template_key, format: { with: KEY_FORMAT }, allow_nil: true
  validates :template_version, format: { with: VERSION_FORMAT }, allow_nil: true
  validates :definition_digest, format: { with: DIGEST_FORMAT }, allow_nil: true
  validates :template_key, uniqueness: { scope: [:account_id, :provider_key] }, if: :source_catalog?
  validates_with JsonSchemaValidator,
                 schema: PARAM_SCHEMA_VALIDATION,
                 attribute_resolver: ->(record) { record.param_schema },
                 unless: :source_catalog?
  validate :validate_catalog_definition, if: :source_catalog?
  validate :validate_integration_hook_account

  scope :enabled, -> { where(enabled: true) }
  scope :catalog, -> { where(source_kind: 'catalog') }

  def self.limit_for(account)
    account.feature_enabled?(CATALOG_FEATURE) ? CATALOG_MAX_PER_ACCOUNT : MAX_PER_ACCOUNT
  end

  def to_tool_metadata
    {
      id: slug,
      title: title,
      description: description,
      custom: true
    }
  end

  def model_visible?
    return enabled? unless source_catalog?

    enabled? && Captain::ToolCatalog::RuntimeEligibility.new(self).eligible?
  end

  private

  def ensure_within_limit
    # Lock the account row to serialize concurrent creates and prevent exceeding the cap
    Account.lock.find(account_id)
    limit = self.class.limit_for(account)
    return if account.captain_custom_tools.count < limit

    raise LimitExceededError, I18n.t('captain.custom_tool.limit_exceeded', limit: limit)
  end

  def validate_catalog_definition
    validate_catalog_identifiers
    errors.add(:risk_class, :blank) if risk_class.blank?
    errors.add(:definition, :blank) if definition.blank?
    errors.add(:input_schema, :blank) if input_schema.blank?
    errors.add(:output_schema, :blank) if output_schema.blank?
    errors.add(:auth_type, 'must be none for catalog tools') unless auth_none?
    errors.add(:auth_config, 'must be empty for catalog tools') if auth_config.present?
  end

  def validate_catalog_identifiers
    %i[provider_key category_key template_key template_version definition_digest].each do |attribute|
      errors.add(attribute, :blank) if public_send(attribute).blank?
    end
  end

  def validate_integration_hook_account
    return if integration_hook.blank? || integration_hook.account_id == account_id

    errors.add(:integration_hook, 'must belong to the same account')
  end

  def generate_slug
    return if slug.present?
    return if title.blank?

    parameterized_title = title.parameterize(separator: NAME_SEPARATOR)
    base_slug = "#{NAME_PREFIX}#{NAME_SEPARATOR}#{parameterized_title}".truncate(MAX_SLUG_LENGTH, omission: '')
    self.slug = find_unique_slug(base_slug)
  end

  def find_unique_slug(base_slug)
    return base_slug unless slug_exists?(base_slug)

    truncated = base_slug.truncate(MAX_SLUG_LENGTH - COLLISION_SUFFIX_LENGTH, omission: '')
    5.times do
      slug_candidate = "#{truncated}#{NAME_SEPARATOR}#{SecureRandom.alphanumeric(6).downcase}"
      return slug_candidate unless slug_exists?(slug_candidate)
    end

    raise ActiveRecord::RecordNotUnique, I18n.t('captain.custom_tool.slug_generation_failed')
  end

  def slug_exists?(candidate)
    self.class.exists?(account_id: account_id, slug: candidate)
  end
end
