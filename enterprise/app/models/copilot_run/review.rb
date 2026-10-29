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
  # A review that hits errors still hands its findings to the turn, so it ends incomplete rather than failed.
  STATUSES = %w[queued running completed incomplete].freeze

  has_many :findings, class_name: 'CopilotReviewFinding', dependent: :delete_all, inverse_of: :copilot_run
  # request: the agent's message the review follows. turn_start and turn_limit: where the current turn took the review,
  # and how far it may go. reference: the material every conversation is judged against, when the turn gave it.
  store_accessor :context, :request, :criteria, :question, :turn_start, :turn_limit, :turn_start_matched, :turn_start_failed,
                 :progress_message_id, :reference

  validates :status, inclusion: { in: STATUSES }
  validates :source_run_id, :criteria, :turn_start, :turn_limit, presence: true
  validate :text_within_limits

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

  # Moves an unfinished review to the tool call that continues it, with room for what is left of that turn's limit. The
  # new turn gets its own progress card, so the earlier turn's card keeps its counts.
  def continue_review(tool_call)
    with_lock do
      return if copilot_tool_call_id == tool_call.id
      raise ArgumentError, 'The review is still running' unless finished?
      raise ArgumentError, 'The review has no conversations left to review' if remaining_ids.empty?
      raise ArgumentError, 'This turn already reviewed a batch. Ask the agent before continuing.' if turn.id == tool_call.copilot_run_id

      # The same counts turn_progress subtracts from, so a continued turn's card starts at 0.
      base = summary
      update!(copilot_tool_call: tool_call, status: :queued, error: nil, progress_message_id: nil, turn_start: base[:processed],
              turn_start_matched: base[:matched], turn_start_failed: base[:failed],
              turn_limit: base[:processed] + tool_call.copilot_run.review_budget!)
    end
  end

  def publish_progress
    progress = turn_progress.as_json
    card = copilot_thread.copilot_messages.find_by(id: progress_message_id)
    return if card&.message&.dig('progress') == progress
    return card.update!(message: card.message.merge('progress' => progress)) if card

    card = copilot_thread.copilot_messages.create!(message_type: :assistant_progress, message: { run_id: id, progress: progress })
    update!(progress_message_id: card.id)
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

  # Reviews started before the progress card saved no matched or failed baseline, and their first turn started at 0.
  def turn_progress
    progress = summary
    { finished: finished?, done: progress[:processed] - turn_start, total: [turn_limit, progress[:selected]].min - turn_start,
      matched: progress[:matched] - turn_start_matched.to_i, failed: progress[:failed] - turn_start_failed.to_i }
  end

  # The text the turn writes for the reviewer. question and reference may be left out, but text that is given must be a
  # nonempty string within its limit.
  def text_within_limits
    { criteria: 4000, question: 500, reference: 20_000 }.each do |name, limit|
      value = public_send(name)
      next if value.nil? || (value.is_a?(String) && value.present? && value.size <= limit)

      errors.add(name, "must be a nonempty string of at most #{limit} characters")
    end
  end
end
