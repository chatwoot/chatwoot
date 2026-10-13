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
#  index_copilot_findings_on_run_and_conversation   (copilot_run_id,conversation_id) UNIQUE
#  index_copilot_review_findings_on_copilot_run_id  (copilot_run_id)
#
class CopilotReviewFinding < ApplicationRecord
  belongs_to :copilot_run

  # screened_in waits for the review model; screened_out never reaches it.
  FINAL_STATUSES = %w[screened_out resolved error].freeze

  validates :conversation_id, uniqueness: { scope: :copilot_run_id }
  # Prefixed, because an `error` value would clash with the error column's error? and `retry` is a Ruby keyword.
  enum :status, { screened_in: 'screened_in', screened_out: 'screened_out', more_history: 'more_history', retry: 'retry',
                  resolved: 'resolved', error: 'error' }, prefix: true, validate: true

  scope :final, -> { where(status: FINAL_STATUSES) }
end
