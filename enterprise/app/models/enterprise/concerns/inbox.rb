module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_many :inbox_capacity_limits, dependent: :destroy
  end
end
