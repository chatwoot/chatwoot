# == Schema Information
#
# Table name: inbox_capacity_limits
#
#  id                       :bigint           not null, primary key
#  conversation_limit       :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  agent_capacity_policy_id :bigint           not null
#  inbox_id                 :bigint           not null
#
# Indexes
#
#  idx_on_agent_capacity_policy_id_inbox_id_71c7ec4caf      (agent_capacity_policy_id,inbox_id) UNIQUE
#  index_inbox_capacity_limits_on_agent_capacity_policy_id  (agent_capacity_policy_id)
#  index_inbox_capacity_limits_on_inbox_id                  (inbox_id)
#
class InboxCapacityLimit < ApplicationRecord
  belongs_to :agent_capacity_policy
  belongs_to :inbox

  validates :conversation_limit, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :inbox_id, uniqueness: { scope: :agent_capacity_policy_id }
end
