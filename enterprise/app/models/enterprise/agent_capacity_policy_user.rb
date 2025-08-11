# frozen_string_literal: true

# == Schema Information
#
# Table name: enterprise_agent_capacity_policy_users
#
#  id                         :bigint           not null, primary key
#  agent_capacity_policy_id   :bigint           not null
#  user_id                    :bigint           not null
#  created_at                 :datetime         not null
#
# Indexes
#
#  unique_user_capacity_policy                (user_id) UNIQUE
#  idx_capacity_policy_users_policy_id        (agent_capacity_policy_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_capacity_policy_id => enterprise_agent_capacity_policies.id)
#  fk_rails_...  (user_id => users.id)
#

class Enterprise::AgentCapacityPolicyUser < ApplicationRecord
  self.table_name = 'enterprise_agent_capacity_policy_users'

  # Associations
  belongs_to :agent_capacity_policy, class_name: 'Enterprise::AgentCapacityPolicy'
  belongs_to :user, class_name: '::User'

  # Validations
  validates :user_id, uniqueness: true

  # Delegations
  delegate :account, to: :agent_capacity_policy

  # Callbacks
  after_commit :invalidate_user_cache

  private

  def invalidate_user_cache
    Rails.cache.delete_matched("assignment_v2:capacity:#{user_id}:*")
  end
end
