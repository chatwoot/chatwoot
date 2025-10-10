# frozen_string_literal: true

# == Schema Information
#
# Table name: template_channel_mappings
#
#  id                  :bigint           not null, primary key
#  channel_type        :string           not null
#  content_type        :string
#  field_mappings      :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  message_template_id :bigint           not null
#
# Indexes
#
#  index_channel_mappings_on_template_and_channel          (message_template_id,channel_type) UNIQUE
#  index_template_channel_mappings_on_channel_type         (channel_type)
#  index_template_channel_mappings_on_message_template_id  (message_template_id)
#
# Foreign Keys
#
#  fk_rails_...  (message_template_id => message_templates.id) ON DELETE => cascade
#

class TemplateChannelMapping < ApplicationRecord
  # Constants
  CHANNEL_TYPES = %w[
    apple_messages_for_business
    whatsapp
    sms
    email
    web_widget
    website
    telegram
    line
    twitter
    facebook
  ].freeze

  # Associations
  belongs_to :message_template

  # Validations
  validates :channel_type, presence: true, inclusion: { in: CHANNEL_TYPES }
  validates :channel_type, uniqueness: { scope: :message_template_id }

  validate :validate_field_mappings_format

  # Scopes
  scope :for_channel, ->(channel_type) { where(channel_type: channel_type) if channel_type.present? }
  scope :with_content_type, ->(content_type) { where(content_type: content_type) if content_type.present? }

  # Instance Methods

  # Apply field mappings to transform template data to channel-specific format
  def apply_mappings(template_data)
    return template_data if field_mappings.blank?

    result = {}

    field_mappings.each do |target_path, source_path|
      value = extract_value(template_data, source_path)
      set_nested_value(result, target_path, value) if value.present?
    end

    result
  end

  # Get a specific field mapping
  def get_mapping(field_name)
    field_mappings[field_name]
  end

  # Check if a field has a mapping
  def mapping?(field_name)
    field_mappings.key?(field_name)
  end

  private

  def extract_value(data, path)
    # Handle template variable syntax: {{variable_name}}
    if path.match?(/^\{\{(.+)\}\}$/)
      variable_name = path.match(/^\{\{(.+)\}\}$/)[1]
      return data[variable_name] || data[variable_name.to_sym]
    end

    # Handle nested path: "properties.title"
    parts = path.split('.')
    parts.reduce(data) do |current, part|
      break nil if current.nil?

      current[part] || current[part.to_sym] if current.is_a?(Hash)
    end
  end

  def set_nested_value(hash, path, value)
    parts = path.split('.')
    last_part = parts.pop

    # Navigate to the parent hash
    parent = parts.reduce(hash) do |current, part|
      current[part] ||= {}
      current[part]
    end

    # Set the value
    parent[last_part] = value
  end

  def validate_field_mappings_format
    return if field_mappings.blank?

    unless field_mappings.is_a?(Hash)
      errors.add(:field_mappings, 'must be a hash')
      return
    end

    field_mappings.each do |key, value|
      unless key.is_a?(String) || key.is_a?(Symbol)
        errors.add(:field_mappings, 'keys must be strings or symbols')
        break
      end

      unless value.is_a?(String)
        errors.add(:field_mappings, 'values must be strings')
        break
      end
    end
  end
end
