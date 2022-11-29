class ApplicationRecord < ActiveRecord::Base
  include Events::Types
  self.abstract_class = true

  # the models that exposed in email templates through liquid
  DROPPABLES = %w[Account Channel Conversation Inbox User Message].freeze

  # ModelDrop class should exist in app/drops
  def to_drop
    return unless DROPPABLES.include?(self.class.name)

    "#{self.class.name}Drop".constantize.new(self)
  end

  private

  def normalize_empty_string_to_nil(attrs = [])
    attrs.each do |attr|
      self[attr] = nil if self[attr].blank?
    end
  end
end
