# frozen_string_literal: true

# == Schema Information
#
# Table name: inbox_assignment_policies
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  assignment_policy_id :bigint           not null
#  inbox_id             :bigint           not null
#
# Indexes
#
#  index_inbox_assignment_policies_on_assignment_policy_id  (assignment_policy_id)
#  index_inbox_assignment_policies_on_inbox_id              (inbox_id)
#

class InboxAssignmentPolicy < ApplicationRecord
  # Associations
  belongs_to :inbox
  belongs_to :assignment_policy

  # Validations
  validate :inbox_belongs_to_same_account

  # Delegations
  delegate :account, to: :inbox
  delegate :name, :description, :assignment_order, :conversation_priority,
           :fair_distribution_limit, :fair_distribution_window, :enabled?,
           to: :assignment_policy, prefix: :policy

  # Callbacks
  after_commit :clear_inbox_cache

  # Scopes
  scope :enabled, -> { joins(:assignment_policy).where(assignment_policies: { enabled: true }) }
  scope :disabled, -> { joins(:assignment_policy).where(assignment_policies: { enabled: false }) }

  def webhook_data
    {
      id: id,
      inbox_id: inbox_id,
      assignment_policy_id: assignment_policy_id,
      policy: assignment_policy.webhook_data
    }
  end

  private

  def inbox_belongs_to_same_account
    return unless inbox && assignment_policy

    return if inbox.account_id == assignment_policy.account_id

    errors.add(:inbox, 'must belong to the same account as the assignment policy')
  end

  def clear_inbox_cache
    Rails.cache.delete("assignment_v2:inbox_policy:#{inbox_id}")
    update_account_cache
  end
end
