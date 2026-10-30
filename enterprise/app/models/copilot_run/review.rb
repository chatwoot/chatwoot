# == Schema Information
#
# Table name: copilot_runs
#
#  id                   :bigint           not null, primary key
#  attempts             :integer          default(0), not null
#  context              :jsonb            not null
#  cost_complete        :boolean          default(TRUE), not null
#  error                :string
#  lease_token          :string
#  lease_until          :datetime
#  status               :string           default("queued"), not null
#  total_cost_usd       :decimal(16, 10)  default(0.0), not null
#  transcript           :jsonb            not null
#  type                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  copilot_message_id   :bigint
#  copilot_thread_id    :bigint           not null
#  copilot_tool_call_id :bigint
#  source_run_id        :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_copilot_runs_on_account_id            (account_id)
#  index_copilot_runs_on_copilot_message_id    (copilot_message_id) UNIQUE
#  index_copilot_runs_on_copilot_thread_id     (copilot_thread_id)
#  index_copilot_runs_on_copilot_tool_call_id  (copilot_tool_call_id) UNIQUE
#  index_copilot_runs_on_source_run_id         (source_run_id)
#  index_copilot_runs_on_user_id               (user_id)
#
# Reads the conversations of a collection in batches and saves a finding for each. A turn reviews at most
# CONVERSATIONS_PER_TURN of them, and the agent asks to continue for the rest.
class CopilotRun::Review < CopilotRun
  include Concerns::CopilotRunProgress

  # A review that hits errors still hands its findings to the turn, so it ends incomplete rather than failed.
  STATUSES = %w[queued running completed incomplete].freeze

  has_many :findings, class_name: 'CopilotReviewFinding', dependent: :delete_all, inverse_of: :copilot_run
  # request: the agent's message the review follows. turn_start and turn_limit: where the current turn took the review,
  # and how far it may go.
  store_accessor :context, :request, :criteria, :question, :turn_start, :turn_limit

  validates :status, inclusion: { in: STATUSES }
  validates :source_run_id, :criteria, :turn_start, :turn_limit, presence: true

  # A review reads the selection saved on the collection it reviews instead of keeping its own copy.
  delegate :selected_ids, :as_of, :filters, :selection_truncated?, to: :source_run

  # A review's records are always conversations.
  def resource
    'conversations'
  end

  # The matched conversations, or every conversation it decided on, including those screened out.
  def record_ids(only_matched: true)
    raise ArgumentError, 'The review has not finished yet' unless finished?

    decided = only_matched ? findings.reviewed.where(matched: true) : findings.where(status: %i[reviewed screened_out])
    decided.order(:conversation_id).pluck(:conversation_id)
  end

  # Moves an unfinished review to the tool call that continues it, with room for what is left of that turn's limit.
  def continue_review(tool_call)
    with_lock do
      return if copilot_tool_call_id == tool_call.id
      raise ArgumentError, 'The review is still running' unless finished?
      raise ArgumentError, 'The review has no conversations left to review' if remaining_ids.empty?
      raise ArgumentError, 'This turn already reviewed a batch. Ask the agent before continuing.' if turn.id == tool_call.copilot_run_id

      start = processed_count
      update!(copilot_tool_call: tool_call, status: :queued, error: nil,
              turn_start: start, turn_limit: start + tool_call.copilot_run.review_budget!)
    end
  end

  def left_this_turn
    turn_limit - processed_count
  end

  def remaining_ids
    selected_ids - findings.finished.pluck(:conversation_id)
  end

  def processed_count
    findings.finished.count
  end

  def summary
    counts = findings.group(:status).count
    selected = selected_ids.size
    processed = counts.values_at(*CopilotReviewFinding::FINISHED_STATUSES).sum(&:to_i)
    super.merge(filters: filters, question: question, selected: selected, processed: processed, remaining: selected - processed,
                screened_out: counts['screened_out'].to_i, reviewed: counts['reviewed'].to_i, matched: findings.where(matched: true).count,
                failed: counts['failed'].to_i, selection_truncated: selection_truncated?)
  end

  private

  def progress_text(progress)
    not_matched = progress[:screened_out] + progress[:reviewed] - progress[:matched]
    "Processed #{progress[:processed]} of #{progress[:selected]} conversations: #{progress[:matched]} matched, " \
      "#{not_matched} didn't match, #{progress[:failed]} couldn't be reviewed."
  end
end
