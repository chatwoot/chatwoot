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
#  fair_distribution_limit  :integer          default(100), not null
#  fair_distribution_window :integer          default(3600), not null
#  name                     :string(255)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#
# Indexes
#
#  index_assignment_policies_on_account_id           (account_id)
#  index_assignment_policies_on_account_id_and_name  (account_id,name) UNIQUE
#  index_assignment_policies_on_enabled              (enabled)
#

class AssignmentPolicy < ApplicationRecord
  # Enums
  enum assignment_order: { round_robin: 0 }
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

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  # Callbacks
  after_update_commit :clear_assignment_caches
  after_destroy :clear_assignment_caches

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

  def clear_assignment_caches
    # Clear Redis caches when policy is updated
    Rails.cache.delete("assignment_v2:policy:#{id}")
    inboxes.find_each do |inbox|
      Rails.cache.delete("assignment_v2:inbox_policy:#{inbox.id}")
    end
  end
end

AssignmentPolicy.prepend_mod_with('AssignmentPolicy')
