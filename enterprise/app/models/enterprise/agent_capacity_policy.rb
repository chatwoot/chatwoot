class Enterprise::AgentCapacityPolicy < ApplicationRecord
  self.table_name = 'agent_capacity_policies'

  MAX_NAME_LENGTH = 255

  belongs_to :account, class_name: '::Account'
  has_many :inbox_capacity_limits, class_name: 'Enterprise::InboxCapacityLimit', dependent: :destroy
  has_many :inboxes, through: :inbox_capacity_limits, class_name: '::Inbox'
  has_many :account_users, class_name: '::AccountUser', dependent: :nullify

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :account, presence: true
end
