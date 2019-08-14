class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def complete_errror_message
    errors.full_messages.join(', ')
  end
end
