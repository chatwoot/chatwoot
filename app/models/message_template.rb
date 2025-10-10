# frozen_string_literal: true

# == Schema Information
#
# Table name: message_templates
#
#  id                 :bigint           not null, primary key
#  category           :string
#  description        :text
#  metadata           :jsonb
#  name               :string           not null
#  parameters         :jsonb
#  status             :string           default("active")
#  supported_channels :text             default([]), is an Array
#  tags               :text             default([]), is an Array
#  use_cases          :text             default([]), is an Array
#  version            :integer          default(1)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  index_message_templates_on_account_id               (account_id)
#  index_message_templates_on_account_id_and_category  (account_id,category)
#  index_message_templates_on_account_id_and_status    (account_id,status)
#  index_message_templates_on_category                 (category)
#  index_message_templates_on_metadata                 (metadata) USING gin
#  index_message_templates_on_status                   (status)
#  index_message_templates_on_supported_channels       (supported_channels) USING gin
#  index_message_templates_on_tags                     (tags) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#

class MessageTemplate < ApplicationRecord
  # Constants
  STATUSES = %w[active draft deprecated].freeze
  CATEGORIES = %w[
    general payment scheduling support marketing
    feedback notification confirmation sales
  ].freeze

  # Associations
  belongs_to :account
  has_many :content_blocks, class_name: 'TemplateContentBlock', dependent: :destroy
  has_many :channel_mappings, class_name: 'TemplateChannelMapping', dependent: :destroy
  has_many :usage_logs, class_name: 'TemplateUsageLog', dependent: :destroy

  accepts_nested_attributes_for :content_blocks, allow_destroy: true
  accepts_nested_attributes_for :channel_mappings, allow_destroy: true

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id }
  validates :status, inclusion: { in: STATUSES }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :version, numericality: { only_integer: true, greater_than: 0 }

  validate :validate_parameters_format
  validate :validate_supported_channels_format

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :draft, -> { where(status: 'draft') }
  scope :deprecated, -> { where(status: 'deprecated') }

  scope :by_category, ->(category) { where(category: category) if category.present? }

  scope :compatible_with_channel, lambda { |channel_type|
    where('? = ANY(supported_channels)', channel_type) if channel_type.present?
  }

  scope :with_required_parameters, lambda { |param_names|
    return all if param_names.blank?

    param_array = Array(param_names)
    where(
      param_array.map { |_param| 'parameters ? :param' }.join(' AND '),
      param: param_array
    )
  }

  scope :tagged_with, lambda { |tag_names|
    return all if tag_names.blank?

    tag_array = Array(tag_names)
    where('tags && ARRAY[?]::text[]', tag_array)
  }

  scope :for_use_case, lambda { |use_case|
    where('? = ANY(use_cases)', use_case) if use_case.present?
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_version, ->(version) { where(version: version) if version.present? }

  # Instance Methods

  # Returns a bot-friendly summary of the template
  def bot_summary
    {
      id: id,
      name: name,
      category: category,
      description: description,
      channels: supported_channels,
      tags: tags,
      use_cases: use_cases,
      parameters: parameters_summary,
      content_blocks: content_blocks_summary,
      version: version,
      status: status
    }
  end

  # Check if the template is compatible with a specific channel
  def compatible_with?(channel_type)
    supported_channels.include?(channel_type.to_s)
  end

  # Get channel-specific mapping for a channel type
  def mapping_for_channel(channel_type)
    channel_mappings.find_by(channel_type: channel_type)
  end

  # Check if a parameter is required
  def parameter_required?(param_name)
    parameters.dig(param_name.to_s, 'required') == true
  end

  # Get default value for a parameter
  def parameter_default(param_name)
    parameters.dig(param_name.to_s, 'default')
  end

  # Validate provided parameters against template requirements
  def validate_provided_parameters(provided_params)
    errors_list = []

    parameters.each do |param_name, config|
      value = provided_params[param_name] || provided_params[param_name.to_sym]

      errors_list << "Required parameter '#{param_name}' is missing" if config['required'] && value.blank?

      next unless value.present? && config['type']

      errors_list << "Parameter '#{param_name}' has invalid type. Expected #{config['type']}" unless valid_parameter_type?(value, config['type'])
    end

    errors_list
  end

  # Create a new version of this template
  def create_new_version
    dup.tap do |new_template|
      new_template.version = version + 1
      new_template.status = 'draft'

      # Duplicate content blocks
      content_blocks.each do |block|
        new_template.content_blocks.build(block.attributes.except('id', 'message_template_id', 'created_at', 'updated_at'))
      end

      # Duplicate channel mappings
      channel_mappings.each do |mapping|
        new_template.channel_mappings.build(mapping.attributes.except('id', 'message_template_id', 'created_at', 'updated_at'))
      end
    end
  end

  # Returns detailed JSON representation for API responses
  def detailed_json(include_content_blocks: false)
    result = {
      id: id,
      name: name,
      category: category,
      description: description,
      supportedChannels: supported_channels || [],
      tags: tags || [],
      useCases: use_cases || [],
      parameters: parameters || {},
      status: status,
      version: version,
      metadata: metadata || {},
      content: build_content,  # Add assembled content
      createdAt: created_at,
      updatedAt: updated_at
    }

    if include_content_blocks
      result[:contentBlocks] = content_blocks.order(:order_index).map do |block|
        {
          id: block.id,
          blockType: block.block_type,
          properties: block.properties || {},
          conditions: block.conditions || {},
          orderIndex: block.order_index
        }
      end

      result[:channelMappings] = channel_mappings.map do |mapping|
        {
          id: mapping.id,
          channelType: mapping.channel_type,
          contentType: mapping.content_type,
          fieldMappings: mapping.field_mappings || {}
        }
      end
    end

    result
  end

  # Build content from metadata or content blocks
  def build_content
    # If metadata has apple_message_content, use that (for Apple Messages templates)
    return metadata['apple_message_content'] if metadata.present? && metadata['apple_message_content'].present?

    # Otherwise, try to build from content blocks
    return nil if content_blocks.empty?

    # For simple templates with one content block, return its properties
    if content_blocks.count == 1
      block = content_blocks.first
      # For quick_reply blocks, ensure the structure matches what the frontend expects
      if block.block_type == 'quick_reply' && block.properties.present?
        return block.properties
      end
      return block.properties if block.properties.present?
    end

    # For complex templates, return an array of blocks
    content_blocks.order(:order_index).map { |block| block.properties }
  end

  private

  def parameters_summary
    return {} if parameters.blank?

    parameters.transform_values do |config|
      {
        type: config['type'],
        required: config['required'] || false,
        description: config['description'],
        default: config['default'],
        example: config['example']
      }.compact
    end
  end

  def content_blocks_summary
    content_blocks.order(:order_index).map do |block|
      {
        type: block.block_type,
        order: block.order_index,
        has_conditions: block.conditions.present?
      }
    end
  end

  def validate_parameters_format
    return if parameters.blank?

    unless parameters.is_a?(Hash)
      errors.add(:parameters, 'must be a hash')
      return
    end

    parameters.each do |param_name, config|
      unless config.is_a?(Hash)
        errors.add(:parameters, "parameter '#{param_name}' configuration must be a hash")
        next
      end

      errors.add(:parameters, "parameter '#{param_name}' must have a type") if config['type'].blank?

      if config['required'] && !config['required'].in?([true, false])
        errors.add(:parameters, "parameter '#{param_name}' required field must be boolean")
      end
    end
  end

  def validate_supported_channels_format
    return if supported_channels.blank?

    unless supported_channels.is_a?(Array)
      errors.add(:supported_channels, 'must be an array')
      return
    end

    supported_channels.each do |channel|
      unless channel.is_a?(String)
        errors.add(:supported_channels, 'all channels must be strings')
        break
      end
    end
  end

  def valid_parameter_type?(value, expected_type)
    case expected_type.to_s
    when 'string'
      value.is_a?(String)
    when 'integer', 'number'
      value.is_a?(Integer) || value.is_a?(Numeric)
    when 'boolean'
      value.in?([true, false])
    when 'array'
      value.is_a?(Array)
    when 'object', 'hash'
      value.is_a?(Hash)
    when 'datetime'
      value.is_a?(Time) || value.is_a?(DateTime) || begin
        value.is_a?(String) && Time.zone.parse(value)
      rescue StandardError
        false
      end
    else
      true # Unknown type, allow it
    end
  end
end
