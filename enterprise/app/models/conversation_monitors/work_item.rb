# == Schema Information
#
# Table name: conversation_monitor_work_items
#
#  id                     :bigint           not null, primary key
#  activity_at            :datetime
#  attempts               :integer          default(0), not null
#  due_at                 :datetime
#  error_code             :string
#  full_history_revision  :bigint           default(0), not null
#  generation             :bigint           default(0), not null
#  lease_expires_at       :datetime
#  lease_token            :string
#  live_activity_at       :datetime
#  live_activity_revision :bigint           default(0), not null
#  processed_revision     :bigint           default(0), not null
#  requested_at           :datetime
#  revision               :bigint           default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  conversation_id        :bigint           not null
#
# Indexes
#
#  index_conversation_monitor_work_items_on_account_id       (account_id)
#  index_conversation_monitor_work_items_on_conversation_id  (conversation_id) UNIQUE
#  index_monitor_work_due                                    (due_at) WHERE (due_at IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#
class ConversationMonitors::WorkItem < ApplicationRecord
  self.table_name = 'conversation_monitor_work_items'

  belongs_to :account
  belongs_to :conversation

  scope :due, -> { where(due_at: ..Time.current).where('lease_expires_at IS NULL OR lease_expires_at < ?', Time.current) }

  def self.for_conversation(conversation)
    create_or_find_by!(conversation_id: conversation.id) { |work| work.account_id = conversation.account_id }
  end

  def request!(invalidate: false, activity_at: nil, full_history: false, live_activity_at: nil)
    with_lock do
      track_live_activity(live_activity_at, invalidate)
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

  def track_live_activity(live_activity_at, invalidate)
    if live_activity_at
      self.live_activity_revision = revision + 1
      self.live_activity_at = live_activity_at
    elsif invalidate
      self.live_activity_revision = 0
      self.live_activity_at = nil
    end
  end

  def schedule_next_attempt
    return if %w[monthly_limit budget_limit].include?(error_code) && due_at&.future?

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
