# == Schema Information
#
# Table name: conversation_monitors
#
#  id                   :bigint           not null, primary key
#  collection_version   :bigint           default(0), not null
#  condition            :text             not null
#  data_revision        :bigint           default(0), not null
#  deleted_at           :datetime
#  history_since        :datetime         not null
#  model                :string           not null
#  name                 :string           not null
#  paused_at            :datetime
#  recheck_requested_at :datetime
#  resumed_at           :datetime
#  threshold            :float            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  user_id              :bigint
#
# Indexes
#
#  index_conversation_monitors_on_account_id  (account_id)
#  index_conversation_monitors_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class ConversationMonitors::Monitor < ApplicationRecord
  self.table_name = 'conversation_monitors'
  MAX_CONDITION_LENGTH = 500

  belongs_to :account
  belongs_to :user, optional: true
  has_many :evaluations, class_name: 'ConversationMonitors::Evaluation', dependent: :delete_all, inverse_of: :monitor
  has_many :scans, class_name: 'ConversationMonitors::Scan', dependent: :delete_all, inverse_of: :monitor
  has_many :automation_rules, class_name: '::AutomationRule', dependent: :nullify, inverse_of: :monitor
  has_many :automation_deliveries, class_name: 'ConversationMonitors::AutomationDelivery', dependent: :delete_all,
                                   inverse_of: :monitor

  validates :name, presence: true, length: { maximum: 100 }
  validates :condition, presence: true
  validates :condition, length: { maximum: MAX_CONDITION_LENGTH }, if: :will_save_change_to_condition?
  validates :model, :history_since, presence: true
  validates :threshold, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  attr_readonly :model, :threshold, :history_since, :account_id

  scope :visible, -> { where(deleted_at: nil) }
  scope :active, -> { visible.where(paused_at: nil) }

  def initial_scan
    scans.find_by!(kind: 'initial')
  end

  def collecting?
    paused_at.nil? && deleted_at.nil? && ConversationMonitors::Configuration.enabled?(account)
  end

  def resumable?
    paused_at.present? && deleted_at.nil?
  end

  def disable_automations!
    automation_rules.active.find_each do |rule|
      rule.active = false
      rule.save!(validate: false)
    end
  end

  def matched_conversations
    account.conversations.where(id: evaluations.where(status: 'matched').select(:conversation_id))
  end

  def pending_work_items
    work_items = ConversationMonitors::WorkItem.joins(:conversation)
                                               .joins('LEFT JOIN conversation_monitor_evaluations monitor_evaluations ON ' \
                                                      'monitor_evaluations.conversation_id = conversation_monitor_work_items.conversation_id ' \
                                                      "AND monitor_evaluations.monitor_id = #{id}")
                                               .where(account_id: account_id, conversations: { account_id: account_id })
                                               .where.not(due_at: nil)
    work_items.where(<<~SQL.squish, collection_version, resumed_at || created_at, id, collection_version)
      (monitor_evaluations.id IS NULL OR
        (monitor_evaluations.status != 'matched' AND
         (monitor_evaluations.status != 'unmatched' OR
          monitor_evaluations.input_revision < conversation_monitor_work_items.revision)))
      AND (monitor_evaluations.requested_version = ? OR
           conversation_monitor_work_items.activity_at >= ? OR
           EXISTS (SELECT 1 FROM conversation_monitor_scans scans
                   WHERE scans.monitor_id = ? AND scans.collection_version = ?
                     AND scans.kind = 'catch_up'
                     AND scans.started_at <= conversation_monitor_work_items.activity_at
                     AND scans.ended_at > conversation_monitor_work_items.activity_at))
    SQL
  end

  def eligible_activity?(activity_at, evaluation = nil)
    return true if evaluation&.requested_version == collection_version
    return false unless activity_at
    return true if activity_at >= (resumed_at || created_at)
    return false unless resumed_at

    scans.where(collection_version: collection_version, kind: 'catch_up')
         .exists?(['started_at <= ? AND ended_at > ?', activity_at, activity_at])
  end

  def eligible_imported_activity?(conversation, activity_times)
    initial = scans.find { |scan| scan.kind == 'initial' }
    in_history = !initial.cancelled_at && (history_since...created_at).cover?(conversation.created_at)
    activity_times.any? do |activity_at|
      (activity_at >= created_at || in_history) && !skipped_import_activity?(activity_at)
    end
  end

  private

  def skipped_import_activity?(activity_at)
    scans.any? do |scan|
      scan.kind != 'initial' && (scan.kind == 'from_now' || scan.cancelled_at) && (scan.started_at...scan.ended_at).cover?(activity_at)
    end
  end
end
