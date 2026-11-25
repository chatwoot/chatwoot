class ApplicationRecord < ActiveRecord::Base
  MAX_STRING_COLUMN_LENGTH = 255
  MAX_TEXT_COLUMN_LENGTH = 20_000

  include Events::Types
  self.abstract_class = true

  # A polymorphic type column can name a class only enterprise/ defines: a message a Captain
  # assistant sent, a conversation assigned to one. On an install that runs without it the row
  # is kept as it is, since it is right again the day Enterprise is back, and reads as pointing
  # at nothing, the way a blank type does: the association answers nil and preloading skips it.
  # With enterprise/ loaded every such class exists, so a name that does not resolve is still
  # an error.
  def self.polymorphic_class_for(name)
    super
  rescue NameError
    raise unless missing_polymorphic_classes_tolerated?

    nil
  end

  def self.missing_polymorphic_classes_tolerated?
    !ChatwootApp.enterprise?
  end

  before_validation :validates_column_content_length

  # the models that exposed in email templates through liquid
  def droppables
    %w[Account Channel Conversation Inbox User Message]
  end

  # ModelDrop class should exist in app/drops
  # Walks the STI hierarchy so subclasses (e.g. SuperAdmin < User) resolve to the matching Drop
  def to_drop
    drop_class = self.class.ancestors.find { |k| k.is_a?(Class) && droppables.include?(k.name) }
    return unless drop_class

    "#{drop_class.name}Drop".constantize.new(self)
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
    max_length = column.type == :text ? MAX_TEXT_COLUMN_LENGTH : MAX_STRING_COLUMN_LENGTH
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
