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
#  http_method       :string           default("GET"), not null
#  param_schema      :jsonb
#  request_template  :text
#  response_template :text
#  slug              :string           not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_captain_custom_tools_on_account_id           (account_id)
#  index_captain_custom_tools_on_account_id_and_slug  (account_id,slug) UNIQUE
#
class Captain::CustomTool < ApplicationRecord
  include Concerns::Toolable
  include Concerns::SafeEndpointValidatable

  self.table_name = 'captain_custom_tools'

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

  enum :http_method, %w[GET POST].index_by(&:itself), validate: true
  enum :auth_type, %w[none bearer basic api_key].index_by(&:itself), default: :none, validate: true, prefix: :auth

  before_validation :generate_slug

  validates :slug, presence: true, uniqueness: { scope: :account_id }
  validates :title, presence: true
  validates :endpoint_url, presence: true
  validates_with JsonSchemaValidator,
                 schema: PARAM_SCHEMA_VALIDATION,
                 attribute_resolver: ->(record) { record.param_schema }

  scope :enabled, -> { where(enabled: true) }

  def to_tool_metadata
    {
      id: slug,
      title: title,
      description: description,
      custom: true
    }
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = title.present? ? "custom_#{title.parameterize}" : "custom_#{SecureRandom.uuid}"
    self.slug = find_unique_slug(base_slug)
  end

  def find_unique_slug(base_slug, counter = 0)
    slug_candidate = counter.zero? ? base_slug : "#{base_slug}-#{counter}"
    return find_unique_slug(base_slug, counter + 1) if slug_exists?(slug_candidate)

    slug_candidate
  end

  def slug_exists?(candidate)
    self.class.exists?(account_id: account_id, slug: candidate)
  end
end
