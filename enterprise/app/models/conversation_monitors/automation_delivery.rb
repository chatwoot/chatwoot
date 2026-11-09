# == Schema Information
#
# Table name: conversation_monitor_automation_deliveries
#
#  id                 :bigint           not null, primary key
#  claimed_at         :datetime
#  skip_reason        :string
#  status             :string           default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  automation_rule_id :bigint           not null
#  conversation_id    :bigint           not null
#  monitor_id         :bigint           not null
#
# Indexes
#
#  idx_on_automation_rule_id_c6ed670e50                            (automation_rule_id)
#  idx_on_conversation_id_ea2ef1d691                               (conversation_id)
#  index_conversation_monitor_automation_deliveries_on_account_id  (account_id)
#  index_conversation_monitor_automation_deliveries_on_monitor_id  (monitor_id)
#  index_monitor_automation_deliveries_sweep                       (status,updated_at)
#  index_monitor_automation_deliveries_unique                      (automation_rule_id,monitor_id,conversation_id) UNIQUE
#
class ConversationMonitors::AutomationDelivery < ApplicationRecord
  self.table_name = 'conversation_monitor_automation_deliveries'

  STALE_PROCESSING_TIMEOUT = 15.minutes
  RETENTION_WINDOW = 30.days

  belongs_to :account
  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', inverse_of: :automation_deliveries
  belongs_to :automation_rule, class_name: '::AutomationRule', inverse_of: :monitor_automation_deliveries
  belongs_to :conversation

  validates :status, inclusion: { in: %w[pending processing executing executed skipped] }
  validates :conversation_id, uniqueness: { scope: [:monitor_id, :automation_rule_id] }

  scope :sweepable, -> { where(status: 'pending').or(where(status: 'processing', updated_at: ...STALE_PROCESSING_TIMEOUT.ago)) }
  scope :retention_candidates, -> { where(status: %w[executing executed skipped]) }

  after_create_commit :enqueue

  def self.purge_terminal!
    ids = retention_candidates.where(updated_at: ...RETENTION_WINDOW.ago).order(:id).limit(1000).pluck(:id)
    where(id: ids).delete_all
  end

  private

  def enqueue
    ConversationMonitors::ProcessAutomationDeliveryJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("Conversation monitor automation delivery enqueue failed: #{e.class.name}")
  end
end
