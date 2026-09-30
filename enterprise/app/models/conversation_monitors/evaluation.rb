class ConversationMonitors::Evaluation < ApplicationRecord
  self.table_name = 'conversation_monitor_evaluations'

  belongs_to :account
  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', inverse_of: :evaluations
  belongs_to :conversation

  validates :conversation_id, uniqueness: { scope: :monitor_id }
  validates :status, inclusion: { in: %w[pending matched unmatched error skipped] }
  validate :same_account

  private

  def same_account
    return if account_id == monitor&.account_id && account_id == conversation&.account_id

    errors.add(:account, 'must own the monitor and conversation')
  end
end
