class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  DROPPABLES = %w[Account User].freeze

  def to_drop
    return unless DROPPABLES.include?(self.class.name)

    "#{self.class.name}Drop".constantize.new(self)
  end
end
