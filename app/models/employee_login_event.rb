class EmployeeLoginEvent < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :account, optional: true

  scope :recent, -> { order(created_at: :desc) }
end
