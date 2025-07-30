# frozen_string_literal: true

# == Schema Information
#
# Table name: enterprise_agent_capacity_policies
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  name            :string(255)      not null
#  description     :text
#  exclusion_rules :jsonb            default: {}
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_enterprise_agent_capacity_policies_on_account_id          (account_id)
#  unique_capacity_policy_name_per_account                         (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

module Enterprise
  class AgentCapacityPolicy < ApplicationRecord
    include AccountCacheRevalidator

    self.table_name = 'enterprise_agent_capacity_policies'

    # Associations
    belongs_to :account
    has_many :account_users, dependent: :nullify, foreign_key: :agent_capacity_policy_id
    has_many :users, through: :account_users
    has_many :inbox_capacity_limits, dependent: :destroy, class_name: 'Enterprise::InboxCapacityLimit'
    has_many :inboxes, through: :inbox_capacity_limits

    # Validations
    validates :name, presence: true, uniqueness: { scope: :account_id }
    validates :name, length: { maximum: 255 }
    validates :description, length: { maximum: 1000 }
    validates :exclusion_rules, json: { schema: exclusion_rules_schema }

    # Callbacks
    before_save :validate_inbox_access
    after_update_commit :invalidate_capacity_caches
    after_destroy :invalidate_capacity_caches

    # Scopes
    scope :with_users, -> { joins(:account_users) }
    scope :for_inbox, ->(inbox) { joins(:inbox_capacity_limits).where(enterprise_inbox_capacity_limits: { inbox: inbox }) }

    def add_user(user)
      # Find the account_user for this account and user
      account_user = account.account_users.find_by!(user: user)
      
      # Update the capacity policy reference
      account_user.update!(agent_capacity_policy_id: id)
      invalidate_user_capacity_cache(user)
    end

    def remove_user(user)
      account_user = account.account_users.find_by(user: user)
      account_user&.update!(agent_capacity_policy_id: nil)
      invalidate_user_capacity_cache(user)
    end

    def set_inbox_limit(inbox, limit)
      inbox_capacity_limit = inbox_capacity_limits.find_or_initialize_by(inbox: inbox)
      inbox_capacity_limit.conversation_limit = limit
      inbox_capacity_limit.save!
      
      invalidate_inbox_capacity_cache(inbox)
    end

    def remove_inbox_limit(inbox)
      inbox_capacity_limits.where(inbox: inbox).destroy_all
      invalidate_inbox_capacity_cache(inbox)
    end

    def get_inbox_limit(inbox)
      inbox_capacity_limits.find_by(inbox: inbox)&.conversation_limit
    end

    def webhook_data
      {
        id: id,
        name: name,
        description: description,
        exclusion_rules: exclusion_rules,
        users_count: users.count,
        inboxes_count: inboxes.count
      }
    end

    private

    def validate_inbox_access
      # Ensure all specified inboxes belong to the same account
      invalid_inboxes = inbox_capacity_limits.joins(:inbox)
                                           .where.not(inboxes: { account_id: account_id })

      if invalid_inboxes.exists?
        errors.add(:inbox_capacity_limits, 'contains inboxes from different accounts')
        throw :abort
      end
    end

    def invalidate_capacity_caches
      users.find_each { |user| invalidate_user_capacity_cache(user) }
      inboxes.find_each { |inbox| invalidate_inbox_capacity_cache(inbox) }
    end

    def invalidate_user_capacity_cache(user)
      Rails.cache.delete_matched("assignment_v2:capacity:#{user.id}:*")
    end

    def invalidate_inbox_capacity_cache(inbox)
      Rails.cache.delete_matched("assignment_v2:capacity:*:#{inbox.id}")
    end

    def self.exclusion_rules_schema
      {
        type: 'object',
        properties: {
          labels: { type: 'array', items: { type: 'string' } },
          hours_threshold: { type: 'integer', minimum: 1, maximum: 168 }
        },
        additionalProperties: false
      }.to_json
    end
  end
end