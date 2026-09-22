class ConversationMonitors::WorkItem < ApplicationRecord
  self.table_name = 'conversation_monitor_work_items'

  belongs_to :account
  belongs_to :conversation

  scope :due, -> { where(due_at: ..Time.current).where('lease_expires_at IS NULL OR lease_expires_at < ?', Time.current) }

  def self.for_conversation(conversation)
    create_or_find_by!(conversation_id: conversation.id) { |work| work.account_id = conversation.account_id }
  end

  def request!(invalidate: false, activity_at: nil, full_history: false)
    with_lock do
      self.revision += 1
      self.full_history_revision = revision if full_history || invalidate
      self.generation += 1 if invalidate
      schedule_next_attempt
      self.requested_at = Time.current
      self.activity_at = [self.activity_at, activity_at].compact.max if activity_at
      self.attempts = 0
      save!
      invalidate_evaluations if invalidate
    end
  end

  private

  def schedule_next_attempt
    return if error_code == 'monthly_limit' && due_at&.future?

    self.due_at = [due_at, 3.seconds.from_now].compact.min
    self.error_code = nil
  end

  def invalidate_evaluations
    evaluations = ConversationMonitors::Evaluation.where(conversation_id: conversation_id, account_id: account_id)
    evaluations.includes(:monitor).order(:monitor_id).each do |evaluation|
      evaluation.monitor.with_lock do
        evaluation.update!(status: 'pending', matched_at: nil, score: nil, error_code: nil)
        evaluation.monitor.update!(data_revision: evaluation.monitor.data_revision + 1)
      end
    end
  end
end
