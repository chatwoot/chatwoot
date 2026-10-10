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
  STATUSES = %w[screened_in screened_out more_history retry resolved error].freeze
  FINAL_STATUSES = %w[screened_out resolved error].freeze

  validates :conversation_id, uniqueness: { scope: :copilot_run_id }
  validates :status, inclusion: { in: STATUSES }
end
