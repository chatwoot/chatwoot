# frozen_string_literal: true

# == Schema Information
#
# Table name: template_content_blocks
#
#  id                  :bigint           not null, primary key
#  block_type          :string           not null
#  conditions          :jsonb
#  order_index         :integer          default(0), not null
#  properties          :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  message_template_id :bigint           not null
#
# Indexes
#
#  index_content_blocks_on_template_and_order            (message_template_id,order_index)
#  index_template_content_blocks_on_block_type           (block_type)
#  index_template_content_blocks_on_message_template_id  (message_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (message_template_id => message_templates.id) ON DELETE => cascade
#

class TemplateContentBlock < ApplicationRecord
  # Constants
  BLOCK_TYPES = %w[
    text
    media
    button_group
    list_picker
    time_picker
    quick_reply
    payment_request
    auth_request
    oauth
    form
    location_picker
    file_upload
    rich_link
    apple_pay
    list
    imessage_app
  ].freeze

  # Associations
  belongs_to :message_template

  # Validations
  validates :block_type, presence: true, inclusion: { in: BLOCK_TYPES }
  validates :order_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :validate_properties_format
  validate :validate_conditions_format

  # Scopes
  scope :ordered, -> { order(:order_index) }
  scope :by_type, ->(type) { where(block_type: type) if type.present? }
  scope :with_conditions, -> { where.not(conditions: {}) }
  scope :without_conditions, -> { where(conditions: {}) }

  # Instance Methods

  # Render the content block for a specific channel with parameters
  def render_for_channel(channel_type, parameters = {})
    case channel_type.to_s
    when 'apple_messages_for_business'
      render_for_apple_messages(parameters)
    when 'whatsapp'
      render_for_whatsapp(parameters)
    when 'web_widget', 'website'
      render_for_web_widget(parameters)
    else
      render_generic(parameters)
    end
  end

  # Check if conditions are met for this block to be displayed
  def conditions_met?(context = {})
    return true if conditions.blank?

    # Simple condition evaluation
    # Format: { "if": "{{variable}} == 'value'" }
    condition_string = conditions['if']
    return true if condition_string.blank?

    # Replace variables in condition with actual values
    evaluated_condition = condition_string.gsub(/\{\{(\w+)\}\}/) do |_match|
      param_name = ::Regexp.last_match(1)
      context[param_name] || context[param_name.to_sym] || ''
    end

    # Basic evaluation (this is simplified; in production, use a proper expression evaluator)
    eval_simple_condition(evaluated_condition)
  rescue StandardError
    # If condition evaluation fails, show the block
    true
  end

  # Process template variables in properties
  def process_properties(parameters = {})
    return properties if properties.blank?

    processed = properties.deep_dup

    process_hash_values(processed, parameters)
  end

  private

  def render_for_apple_messages(parameters)
    processed_props = process_properties(parameters)

    case block_type
    when 'text'
      {
        type: 'text',
        content: processed_props['content'] || processed_props['text']
      }
    when 'time_picker'
      {
        type: 'apple_time_picker',
        properties: processed_props
      }
    when 'list_picker'
      {
        type: 'apple_list_picker',
        properties: processed_props
      }
    when 'payment_request', 'apple_pay'
      {
        type: 'apple_pay',
        properties: processed_props
      }
    when 'form'
      {
        type: 'apple_form',
        properties: processed_props
      }
    else
      render_generic(parameters)
    end
  end

  def render_for_whatsapp(parameters)
    processed_props = process_properties(parameters)

    case block_type
    when 'text'
      {
        type: 'text',
        content: processed_props['content'] || processed_props['text']
      }
    when 'button_group'
      {
        type: 'interactive',
        subtype: 'button',
        properties: processed_props
      }
    when 'list_picker', 'list'
      {
        type: 'interactive',
        subtype: 'list',
        properties: processed_props
      }
    else
      render_generic(parameters)
    end
  end

  def render_for_web_widget(parameters)
    processed_props = process_properties(parameters)

    {
      type: block_type,
      properties: processed_props
    }
  end

  def render_generic(parameters)
    {
      type: block_type,
      properties: process_properties(parameters)
    }
  end

  def process_hash_values(hash, parameters)
    hash.each do |key, value|
      case value
      when String
        hash[key] = process_template_string(value, parameters)
      when Hash
        process_hash_values(value, parameters)
      when Array
        hash[key] = value.map do |item|
          if item.is_a?(Hash)
            item.deep_dup.tap { |h| process_hash_values(h, parameters) }
          elsif item.is_a?(String)
            process_template_string(item, parameters)
          else
            item
          end
        end
      end
    end

    hash
  end

  def process_template_string(string, parameters)
    string.gsub(/\{\{(\w+)\}\}/) do
      param_name = ::Regexp.last_match(1)
      value = parameters[param_name] || parameters[param_name.to_sym]

      # Handle different value types
      case value
      when Array, Hash
        value.to_json
      else
        value.to_s
      end
    end
  end

  def eval_simple_condition(condition_string)
    # Support basic comparisons: ==, !=, >, <, >=, <=
    # Format: "value operator value"
    if condition_string =~ /^(.+?)\s*(==|!=|>|<|>=|<=)\s*(.+)$/
      left = ::Regexp.last_match(1).strip.gsub(/^['"]|['"]$/, '')
      operator = ::Regexp.last_match(2)
      right = ::Regexp.last_match(3).strip.gsub(/^['"]|['"]$/, '')

      case operator
      when '=='
        left == right
      when '!='
        left != right
      when '>'
        left.to_f > right.to_f
      when '<'
        left.to_f < right.to_f
      when '>='
        left.to_f >= right.to_f
      when '<='
        left.to_f <= right.to_f
      else
        true
      end
    else
      true
    end
  end

  def validate_properties_format
    return if properties.blank?

    errors.add(:properties, 'must be a hash') unless properties.is_a?(Hash)
  end

  def validate_conditions_format
    return if conditions.blank?

    unless conditions.is_a?(Hash)
      errors.add(:conditions, 'must be a hash')
      return
    end

    # Validate condition structure
    return unless conditions['if'].present? && !conditions['if'].is_a?(String)

    errors.add(:conditions, "'if' condition must be a string")
  end
end
