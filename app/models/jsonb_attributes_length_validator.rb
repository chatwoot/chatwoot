# frozen_string_literal: true

class JsonbAttributesLengthValidator < ActiveModel::Validator
  MAX_ATTRIBUTE_LENGTH = 1000
  MAX_NESTED_DEPTH = 3

  def validate(record)
    return unless record.content_attributes.present?

    validate_structure(record)
    validate_length(record)
    validate_depth(record.content_attributes, 0, record)
  end

  private

  def validate_structure(record)
    allowed_sections = %w[conversation_context interaction_patterns resolution_context customer_satisfaction]
    
    record.content_attributes.each_key do |section|
      unless allowed_sections.include?(section.to_s)
        record.errors.add(:content_attributes, "Invalid section: #{section}")
      end
    end
  end

  def validate_length(record)
    record.content_attributes.each do |section, data|
      next unless data.is_a?(Hash)

      data.each do |key, value|
        if value.is_a?(String) && value.length > MAX_ATTRIBUTE_LENGTH
          record.errors.add(:content_attributes, "#{section}.#{key} exceeds maximum length of #{MAX_ATTRIBUTE_LENGTH}")
        end
      end
    end
  end

  def validate_depth(hash, current_depth, record)
    if current_depth > MAX_NESTED_DEPTH
      record.errors.add(:content_attributes, "Exceeds maximum nesting depth of #{MAX_NESTED_DEPTH}")
      return
    end

    hash.each_value do |value|
      validate_depth(value, current_depth + 1, record) if value.is_a?(Hash)
    end
  end
end
