# == Schema Information
#
# Table name: copilot_runs
#
#  id                   :bigint           not null, primary key
#  attempts             :integer          default(0), not null
#  context              :jsonb            not null
#  cost_complete        :boolean          default(TRUE), not null
#  error                :string
#  kind                 :string           not null
#  lease_token          :string
#  lease_until          :datetime
#  status               :string           default("queued"), not null
#  total_cost_usd       :decimal(16, 10)   default(0.0), not null
#  transcript           :jsonb            not null
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
class CopilotRun < ApplicationRecord
  include Concerns::CopilotRunApprovable

  belongs_to :account
  belongs_to :user
  belongs_to :copilot_thread
  belongs_to :copilot_message, optional: true
  # The tool call that started this run. A turn has none; it starts from the agent's message.
  belongs_to :copilot_tool_call, optional: true, inverse_of: :background_run
  # The saved set this run reads: a collection's from set, the collection a review reads, or the set an action changes.
  belongs_to :source_run, class_name: 'CopilotRun', optional: true
  has_many :derived_runs, class_name: 'CopilotRun', foreign_key: :source_run_id, dependent: :destroy, inverse_of: :source_run
  has_many :tool_calls, class_name: 'CopilotToolCall', dependent: :delete_all
  has_many :findings, class_name: 'CopilotReviewFinding', dependent: :delete_all
  has_many :action_items, class_name: 'CopilotActionItem', dependent: :delete_all

  FINISHED_STATUSES = %w[completed incomplete failed rejected expired].freeze
  MAX_SELECTION = 5000
  # Conversations a review finishes per turn. The rest wait until the agent asks to continue.
  CONVERSATIONS_PER_TURN = 100

  LEASE_DURATION = 2.minutes

  enum :kind, { turn: 'turn', collection: 'collection', review: 'review', action: 'action' }, validate: true
  # awaiting_background_run: a turn parked until a background run started by one of its tool calls finishes.
  # awaiting_approval: an action run that writes nothing until the agent approves it.
  enum :status, { queued: 'queued', running: 'running', awaiting_background_run: 'awaiting_background_run', awaiting_approval: 'awaiting_approval',
                  completed: 'completed', incomplete: 'incomplete', failed: 'failed', rejected: 'rejected', expired: 'expired' }, validate: true

  # Runs a job may pick up: waiting for a worker, or held by one whose lease may have expired.
  scope :claimable, -> { where(status: %i[queued running]) }
  scope :finished, -> { where(status: FINISHED_STATUSES) }
  scope :unfinished, -> { where.not(status: FINISHED_STATUSES) }

  def finished?
    FINISHED_STATUSES.include?(status)
  end

  def claim
    with_lock do
      return if finished? || awaiting_background_run? || awaiting_approval? || lease_until&.future?

      update!(status: :running, lease_until: Time.current + LEASE_DURATION, lease_token: SecureRandom.uuid)
      lease_token
    end
  end

  def with_lease(token)
    with_lock do
      raise Captain::Copilot::LeaseLostError unless running? && lease_token == token

      yield
    end
  end

  def renew_lease(token)
    with_lease(token) { update!(lease_until: Time.current + LEASE_DURATION) }
  end

  # Checked before every model call and batch of changes, so turning the feature off or running out of credits also
  # stops work in flight. Changes make no model call, so they skip the credit check.
  def ensure_can_continue!(credits: true)
    account.reload
    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_workflows_disabled') unless account.feature_enabled?('copilot_workflows')
    return if !credits || account.usage_limits[:captain][:responses][:current_available].positive?

    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_limit')
  end

  # Turns run in order; a message sent while an earlier turn waits on its review is answered after that turn.
  def behind_earlier_turn?
    copilot_thread.copilot_runs.turn.unfinished.where(CopilotRun.arel_table[:copilot_message_id].lt(copilot_message_id)).exists?
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

  def action
    Captain::Copilot::Actions.build(context.fetch('action'), account: account, user: user, arguments: context.fetch('arguments'))
  end

  def target_ids
    context.fetch('target_ids', [])
  end

  # The turn this run belongs to. Collections, reviews and actions are started by one of its tool calls.
  def turn
    turn? ? self : copilot_tool_call.copilot_run
  end

  # Provider costs are stored on the user turn, including calls made by its background review.
  # This keeps account and turn-level reporting simple without double-counting child runs.
  def record_cost!(amount)
    target = turn
    target.with_lock do
      if amount.nil?
        target.update!(cost_complete: false)
      else
        target.update!(total_cost_usd: target.total_cost_usd + BigDecimal(amount.to_s))
      end
    end
  end

  def selected_ids
    context.fetch('selected_ids', [])
  end

  # A saved set is a collection from get_data or a finished review. A review's records are always conversations.
  def resource
    collection? ? context.fetch('resource', 'conversations') : 'conversations'
  end

  # For a review, the matched conversations or every conversation it decided on, including those screened out.
  def record_ids(only_matched: true)
    return selected_ids if collection?
    raise ArgumentError, 'The review has not finished yet' unless finished?

    decided = only_matched ? findings.reviewed.where(matched: true) : findings.where(status: %i[reviewed screened_out])
    decided.order(:conversation_id).pluck(:conversation_id)
  end

  # Moves an unfinished review to the tool call that continues it, with room for the next batch.
  def continue_review(tool_call)
    with_lock do
      return if copilot_tool_call_id == tool_call.id
      raise ArgumentError, 'The review is still running' unless finished?
      raise ArgumentError, 'The review has no conversations left to review' if remaining_ids.empty?
      raise ArgumentError, 'This turn already reviewed a batch. Ask the agent before continuing.' if turn.id == tool_call.copilot_run_id

      update!(copilot_tool_call: tool_call, status: :queued, error: nil,
              context: context.merge('turn_limit' => processed_count + CONVERSATIONS_PER_TURN))
    end
  end

  def left_this_turn
    context.fetch('turn_limit') - processed_count
  end

  def as_of
    Time.iso8601(context.fetch('as_of'))
  end

  def criteria
    context.fetch('criteria')
  end

  def question
    context['question']
  end

  def filters
    context.fetch('filters', {})
  end

  def remaining_ids
    return target_ids - action_items.finished.pluck(:record_id) if action?

    selected_ids - findings.finished.pluck(:conversation_id)
  end

  def summary
    details = if action?
                action_summary
              elsif collection?
                collection_summary
              else
                review_summary
              end
    { run_id: id, status: status, error: error }.merge(details)
  end

  def processed_count
    findings.finished.count
  end

  def publish_progress
    progress = summary
    return if copilot_thread.copilot_messages.assistant_thinking.last&.message&.dig('progress') == progress.as_json

    copilot_thread.copilot_messages.create!(message_type: :assistant_thinking, message: { content: progress_text(progress), progress: progress })
  end

  private

  # A collection is a saved selection, so it has no review counts.
  def collection_summary
    { resource: resource, filters: filters, selected: selected_ids.size, selection_truncated: context['selection_truncated'] }
  end

  def review_summary
    counts = findings.group(:status).count
    selected = selected_ids.size
    processed = counts.values_at(*CopilotReviewFinding::FINISHED_STATUSES).sum(&:to_i)
    { filters: filters, question: question, selected: selected, processed: processed, remaining: selected - processed,
      screened_out: counts['screened_out'].to_i, reviewed: counts['reviewed'].to_i, matched: findings.where(matched: true).count,
      failed: counts['failed'].to_i, selection_truncated: context['selection_truncated'] }
  end

  def action_summary
    counts = action_items.group(:status).count
    { action: context['action'], arguments: context['arguments'], targets: target_ids.size, applied: counts['applied'].to_i,
      skipped: counts['skipped'].to_i, failed: counts['failed'].to_i, not_processed: not_processed(counts),
      decision_reason: context['decision_reason'] }.compact
  end

  # Targets an approved change never reached, such as when workflows were turned off partway through.
  def not_processed(counts)
    return unless completed? || incomplete?

    missing = target_ids.size - counts.values_at('applied', 'skipped', 'failed').sum(&:to_i)
    missing if missing.positive?
  end

  def progress_text(progress)
    if action?
      return "Applied #{progress[:applied]} of #{progress[:targets]} changes: #{progress[:skipped]} already done, #{progress[:failed]} failed."
    end

    "Processed #{progress[:processed]} of #{progress[:selected]} conversations: #{progress[:matched]} matched, " \
      "#{progress[:screened_out]} screened out, #{progress[:failed]} failed."
  end
end
