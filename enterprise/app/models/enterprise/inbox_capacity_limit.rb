# frozen_string_literal: true

# == Schema Information
#
# Table name: enterprise_inbox_capacity_limits
#
#  id                        :bigint           not null, primary key
#  agent_capacity_policy_id  :bigint           not null
#  inbox_id                  :bigint           not null
#  conversation_limit        :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_inbox_limits_on_capacity_policy                            (agent_capacity_policy_id)
#  index_enterprise_inbox_capacity_limits_on_inbox_id               (inbox_id)
#  unique_policy_inbox_limit                                        (agent_capacity_policy_id,inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (agent_capacity_policy_id => enterprise_agent_capacity_policies.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#

module Enterprise
  class InboxCapacityLimit < ::ApplicationRecord
    include AccountCacheRevalidator

    self.table_name = 'enterprise_inbox_capacity_limits'

    # Associations
    belongs_to :agent_capacity_policy, class_name: 'Enterprise::AgentCapacityPolicy'
    belongs_to :inbox, class_name: '::Inbox'

    # Validations
    validates :agent_capacity_policy_id, uniqueness: { scope: :inbox_id }
    validates :conversation_limit, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1000 }

    # Delegations
    delegate :account, to: :agent_capacity_policy
    delegate :name, :description, :exclusion_rules, to: :agent_capacity_policy, prefix: :policy

    # Callbacks
    after_create_commit :invalidate_inbox_cache
    after_update_commit :invalidate_inbox_cache
    after_destroy_commit :invalidate_inbox_cache

    # Scopes
    scope :for_inbox, ->(inbox) { where(inbox: inbox) }
    scope :for_policy, ->(policy) { where(agent_capacity_policy: policy) }

    def webhook_data
      {
        id: id,
        inbox_id: inbox_id,
        agent_capacity_policy_id: agent_capacity_policy_id,
        conversation_limit: conversation_limit,
        policy: agent_capacity_policy.webhook_data
      }
    end

    private

    def invalidate_inbox_cache
      Rails.cache.delete_matched("assignment_v2:capacity:*:#{inbox_id}")
      update_account_cache
    end
  end
end
