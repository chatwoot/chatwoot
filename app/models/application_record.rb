class ApplicationRecord < ActiveRecord::Base
  MAX_STRING_COLUMN_LENGTH = 255
  MIN_TEXT_COLUMN_LENGTH = 20_000

  include Events::Types
  self.abstract_class = true

  before_validation :validates_column_content_length

  # the models that exposed in email templates through liquid
  def droppables
    %w[Account Channel Conversation Inbox User Message]
  end

  # ModelDrop class should exist in app/drops
  def to_drop
    return unless droppables.include?(self.class.name)

    "#{self.class.name}Drop".constantize.new(self)
  end

  private

  # Generic validation for all columns of type string and text
  # Validates the length of the column to prevent DOS via large payloads
  # if a custom length validation is already present, skip the validation
  def validates_column_content_length
    self.class.columns.each do |column|
      check_and_validate_content_length(column) if column_of_type_string_or_text?(column)
    end
  end

  def column_of_type_string_or_text?(column)
    %i[string text].include?(column.type)
  end

  def check_and_validate_content_length(column)
    length_validator = self.class.validators_on(column.name).find { |v| v.kind == :length }
    validate_content_length(column) if length_validator.blank?
  end

  def max_text_column_length
    raw_value = ENV['MAX_TEXT_COLUMN_LENGTH']
    return MIN_TEXT_COLUMN_LENGTH if raw_value.nil?

    valid = raw_value.match?(/\A\d+\z/) && raw_value.to_i >= MIN_TEXT_COLUMN_LENGTH
    return raw_value.to_i if valid

    raise ArgumentError,
          "MAX_TEXT_COLUMN_LENGTH must be a positive integer of at least #{MIN_TEXT_COLUMN_LENGTH}"
  end

  def validate_content_length(column)
    max_length = column.type == :text ? max_text_column_length : MAX_STRING_COLUMN_LENGTH
    return if self[column.name].nil? || self[column.name].length <= max_length

    errors.add(column.name.to_sym, "is too long (maximum is #{max_length} characters)")
  end

  def normalize_empty_string_to_nil(attrs = [])
    attrs.each do |attr|
      self[attr] = nil if self[attr].blank?
    end
  end
end

ApplicationRecord.prepend_mod_with('ApplicationRecord')
