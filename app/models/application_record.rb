class ApplicationRecord < ActiveRecord::Base
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

  def validate_content_length(column)
    max_length = column.type == :text ? 20_000 : 255
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
