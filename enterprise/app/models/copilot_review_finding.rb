# == Schema Information
#
# Table name: copilot_review_findings
#
#  id                   :bigint           not null, primary key
#  attempts             :integer          default(0), not null
#  category             :string
#  error                :string
#  evidence_message_ids :jsonb            not null
#  history_truncated    :boolean          default(FALSE), not null
#  matched              :boolean          default(FALSE), not null
#  reason               :text
#  reviewed_message_ids :jsonb            not null
#  screening_score      :float
#  status               :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  conversation_id      :bigint           not null
#  copilot_run_id       :bigint           not null
#
# Indexes
#
#  index_copilot_findings_on_run_and_conversation  (copilot_run_id,conversation_id) UNIQUE
#
class CopilotReviewFinding < ApplicationRecord
  belongs_to :copilot_run

  # awaiting_review waits for the review model; screened_out never reaches it.
  FINISHED_STATUSES = %w[screened_out reviewed failed].freeze

  validates :conversation_id, uniqueness: { scope: :copilot_run_id }
  enum :status, { awaiting_review: 'awaiting_review', screened_out: 'screened_out', needs_more_history: 'needs_more_history',
                  awaiting_retry: 'awaiting_retry', reviewed: 'reviewed', failed: 'failed' }, validate: true

  scope :finished, -> { where(status: FINISHED_STATUSES) }
end
