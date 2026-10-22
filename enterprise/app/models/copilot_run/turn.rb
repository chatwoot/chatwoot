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
# Answers one message from the agent. A turn parks while a review started by one of its tool calls runs, and it carries
# the cost of everything it started.
class CopilotRun::Turn < CopilotRun
  # A turn whose proposed change was superseded by a newer message ends incomplete.
  STATUSES = %w[queued running awaiting_background_run completed incomplete failed].freeze

  belongs_to :copilot_message, optional: true
  has_many :tool_calls, class_name: 'CopilotToolCall', dependent: :delete_all, inverse_of: :copilot_run
  # conversation_id: the display ID of the conversation the agent had open. trace_carrier: the turn's trace context, which
  # later jobs join.
  store_accessor :context, :conversation_id, :trace_carrier

  validates :status, inclusion: { in: STATUSES }

  def turn
    self
  end

  # Turns run in order; a message sent while an earlier turn waits on its review is answered after that turn.
  def behind_earlier_turn?
    CopilotRun::Turn.unfinished.exists?(copilot_thread_id: copilot_thread_id, copilot_message_id: ...copilot_message_id)
  end

  # Called when a background run finishes. This run may not have parked yet; it checks the tool call under this same lock
  # before parking, so exactly one side re-queues it.
  def resume_with(tool_call, result)
    resumed = with_lock do
      tool_call.update!(status: :completed, result: result)
      awaiting_background_run? && update!(status: :queued)
    end
    Captain::Copilot::TurnJob.perform_later(id) if resumed
  end

  # A turn reviews at most CONVERSATIONS_PER_TURN conversations across all its reviews, so a later review in the same turn
  # gets only what is left. A continued review counts from where this turn took it.
  def review_budget!
    reviews = CopilotRun::Review.joins(:copilot_tool_call).where(copilot_tool_calls: { copilot_run_id: id }).to_a
    left = CONVERSATIONS_PER_TURN - reviews.sum { |review| review.processed_count - review.turn_start }
    return left if left.positive?

    raise ArgumentError, "This turn already reviewed #{CONVERSATIONS_PER_TURN} conversations. Ask the agent before reviewing more."
  end
end
