# == Schema Information
#
# Table name: captain_custom_tools
#
#  id                :bigint           not null, primary key
#  auth_config       :jsonb
#  auth_type         :string           default("none")
#  description       :text
#  enabled           :boolean          default(TRUE), not null
#  endpoint_url      :text             not null
#  headers           :jsonb            not null
#  http_method       :string           default("GET"), not null
#  param_schema      :jsonb
#  request_template  :text
#  response_template :text
#  slug              :string           not null
#  source_metadata   :jsonb
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assistant_id      :bigint
#
# Indexes
#
#  index_captain_custom_tools_on_account_id             (account_id)
#  index_captain_custom_tools_on_assistant_id_and_slug  (assistant_id,slug) UNIQUE
#
class Captain::CustomTool < ApplicationRecord
  class LimitExceededError < StandardError; end

  MAX_PER_ASSISTANT = 50

  include Concerns::Toolable
  include Concerns::SafeEndpointValidatable

  self.table_name = 'captain_custom_tools'

  NAME_PREFIX = 'custom'.freeze
  NAME_SEPARATOR = '_'.freeze
  # OpenAI enforces a 64-char limit on function names. The slug is used
  # verbatim as the tool name in LLM requests, so it must fit within this limit.
  MAX_SLUG_LENGTH = 64
  COLLISION_SUFFIX_LENGTH = 7 # "_" + 6 random alphanumeric chars
  # Header rules mirror the Captain tools catalog manifest schema
  MAX_HEADERS = 16
  MAX_HEADER_VALUE_BYTES = 1.kilobyte
  # RFC 9110 field-name token
  HEADER_NAME_PATTERN = /\A[!#$%&'*+.^_`|~0-9A-Za-z-]+\z/
  # Control characters, or install-time (${{ }}) and call-time ({{ }}) placeholders
  INVALID_HEADER_VALUE_PATTERN = /[[:cntrl:]]|\{\{/
  RESERVED_HEADERS = %w[authorization host content-length content-type].freeze
  # Any name starting with x-chatwoot, dash or not, is reserved for headers Chatwoot sets
  RESERVED_HEADER_PREFIX = 'x-chatwoot'.freeze
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
  # Present only on tools installed from a public GitHub manifest
  SOURCE_METADATA_VALIDATION = {
    'type': %w[object null],
    'properties': {
      'source': { 'const': 'github' },
      'repository': { 'type': 'string', 'pattern': '^[\\w.-]+/[\\w.-]+$' },
      'path': { 'type': 'string', 'pattern': '^[\\w.-]+$' },
      'tool_id': { 'type': 'string', 'pattern': '^[a-z][a-z0-9_]*$' },
      'revision': { 'type': 'string', 'pattern': '^[0-9a-f]{40}$' },
      'version': { 'type': 'string', 'minLength': 1 },
      'manifest_digest': { 'type': 'string', 'pattern': '^sha256:[0-9a-f]{64}$' },
      'installation_id': { 'type': 'string', 'format': 'uuid' }
    },
    'required': %w[source repository path tool_id revision version manifest_digest installation_id],
    'additionalProperties': false
  }.to_json.freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'

  enum :http_method, %w[GET POST PUT PATCH DELETE].index_by(&:itself), validate: true
  enum :auth_type, %w[none bearer basic api_key].index_by(&:itself), default: :none, validate: true, prefix: :auth

  before_validation :generate_slug
  before_create :ensure_within_limit

  validates :slug, presence: true, uniqueness: { scope: :assistant_id }, length: { maximum: MAX_SLUG_LENGTH }
  validates :title, presence: true
  validates :endpoint_url, presence: true
  validates_with JsonSchemaValidator,
                 schema: PARAM_SCHEMA_VALIDATION,
                 attribute_resolver: ->(record) { record.param_schema }
  validates_with JsonSchemaValidator,
                 schema: SOURCE_METADATA_VALIDATION,
                 attribute_resolver: ->(record) { record.source_metadata }
  validate :validate_headers
  validate :validate_auth_config

  scope :enabled, -> { where(enabled: true) }
  scope :from_github, lambda { |repository, path|
    where("source_metadata->>'source' = 'github'")
      .where("source_metadata->>'repository' = ? AND source_metadata->>'path' = ?", repository, path)
  }

  def to_tool_metadata
    {
      id: slug,
      title: title,
      description: description,
      custom: true
    }
  end

  def enabled_scenarios_count
    assistant.scenarios.enabled.where('tools @> ?', [slug].to_json).count
  end

  private

  def validate_headers
    return errors.add(:headers, I18n.t('captain.custom_tool.headers.invalid')) unless headers.is_a?(Hash)
    return errors.add(:headers, I18n.t('captain.custom_tool.headers.too_many', limit: MAX_HEADERS)) if headers.size > MAX_HEADERS

    names = headers.keys.map(&:downcase)
    errors.add(:headers, I18n.t('captain.custom_tool.headers.duplicate')) if names.uniq.size != names.size
    headers.each { |name, value| validate_header(name, value) }
  end

  # Auth values become request headers, and the HTTP client rejects unsafe ones on every call
  def validate_auth_config
    config = auth_config.to_h
    validate_api_key_name(config['name']) if auth_api_key? && config['name'].is_a?(String)
    errors.add(:auth_config, :invalid) if config.values.any? { |value| value.is_a?(String) && value.match?(/[[:cntrl:]]/) }
  end

  # HttpTool sets reserved headers after auth, so they would overwrite the key. Authorization is the credential's own header.
  def validate_api_key_name(name)
    return errors.add(:auth_config, I18n.t('captain.custom_tool.headers.invalid_name', name: name)) unless HEADER_NAME_PATTERN.match?(name)
    return if name.casecmp?('authorization') || !reserved_header?(name.downcase)

    errors.add(:auth_config, I18n.t('captain.custom_tool.headers.reserved', name: name))
  end

  def validate_header(name, value)
    return errors.add(:headers, I18n.t('captain.custom_tool.headers.invalid_name', name: name)) unless HEADER_NAME_PATTERN.match?(name)
    return errors.add(:headers, I18n.t('captain.custom_tool.headers.reserved', name: name)) if reserved_header?(name.downcase)
    return if value.is_a?(String) && value.bytesize <= MAX_HEADER_VALUE_BYTES && !INVALID_HEADER_VALUE_PATTERN.match?(value)

    errors.add(:headers, I18n.t('captain.custom_tool.headers.invalid_value', name: name))
  end

  def reserved_header?(name)
    RESERVED_HEADERS.include?(name) || name.start_with?(RESERVED_HEADER_PREFIX)
  end

  def ensure_within_limit
    # Lock the assistant row to serialize concurrent creates and prevent exceeding the cap
    Captain::Assistant.lock.find(assistant_id)
    return if assistant.custom_tools.count < MAX_PER_ASSISTANT

    raise LimitExceededError, I18n.t('captain.custom_tool.limit_exceeded', limit: MAX_PER_ASSISTANT)
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
    self.class.exists?(assistant_id: assistant_id, slug: candidate)
  end
end
