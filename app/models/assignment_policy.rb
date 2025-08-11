# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_policies
#
#  id                       :bigint           not null, primary key
#  assignment_order         :integer          default("round_robin"), not null
#  conversation_priority    :integer          default("earliest_created"), not null
#  description              :text
#  enabled                  :boolean          default(TRUE), not null
#  fair_distribution_limit  :integer          default(10), not null
#  fair_distribution_window :integer          default(3600), not null
#  name                     :string(255)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_assignment_policies_on_account_id    (account_id)
#  index_assignment_policies_on_enabled       (enabled)
#  unique_assignment_policy_name_per_account  (account_id,name) UNIQUE
#

class AssignmentPolicy < ApplicationRecord
  include AccountCacheRevalidator

  # Enums
  enum assignment_order: { round_robin: 0, balanced: 1 }
  enum conversation_priority: { earliest_created: 0, longest_waiting: 1 }

  # Associations
  belongs_to :account
  has_many :inbox_assignment_policies, dependent: :destroy
  has_many :inboxes, through: :inbox_assignment_policies

  # Validations
  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :name, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :fair_distribution_limit, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :fair_distribution_window, presence: true, numericality: { greater_than: 60, less_than_or_equal_to: 86_400 }
  validates :assignment_order, inclusion: { in: assignment_orders.keys }
  validates :conversation_priority, inclusion: { in: conversation_priorities.keys }

  # Validate balanced assignment is only available for enterprise
  validate :validate_balanced_assignment_enterprise_only

  # Server-side validation to prevent bypass
  before_save :enforce_enterprise_features

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # Callbacks
  after_update_commit :clear_assignment_caches
  after_destroy :clear_assignment_caches

  def can_use_balanced_assignment?
    account.feature_enabled?(:enterprise_agent_capacity) if account.respond_to?(:feature_enabled?)
  end

  def webhook_data
    {
      id: id,
      name: name,
      description: description,
      assignment_order: assignment_order,
      conversation_priority: conversation_priority,
      fair_distribution_limit: fair_distribution_limit,
      fair_distribution_window: fair_distribution_window,
      enabled: enabled
    }
  end

  private

  def validate_balanced_assignment_enterprise_only
    return unless balanced?
    return if can_use_balanced_assignment?

    errors.add(:assignment_order, 'Balanced assignment is only available for enterprise accounts')
  end

  def enforce_enterprise_features
    # Server-side enforcement to prevent API bypass
    return unless balanced? && !can_use_balanced_assignment?

    # Force to round_robin if enterprise not available
    self.assignment_order = 'round_robin'
    Rails.logger.warn("Assignment V2: Forced assignment_order to round_robin for non-enterprise account #{account_id}")
  end

  def clear_assignment_caches
    # Clear Redis caches when policy is updated
    Rails.cache.delete("assignment_v2:policy:#{id}")
    inboxes.find_each do |inbox|
      Rails.cache.delete("assignment_v2:inbox_policy:#{inbox.id}")
    end
  end
end
