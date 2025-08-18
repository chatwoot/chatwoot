class Enterprise::InboxCapacityLimit < ApplicationRecord
  self.table_name = 'inbox_capacity_limits'

  belongs_to :agent_capacity_policy, class_name: 'Enterprise::AgentCapacityPolicy'
  belongs_to :inbox, class_name: '::Inbox'

  validates :conversation_limit, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :inbox_id, uniqueness: { scope: :agent_capacity_policy_id }
end
