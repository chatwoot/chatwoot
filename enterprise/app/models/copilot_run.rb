# == Schema Information
#
# Table name: copilot_runs
#
#  id                  :bigint           not null, primary key
#  attempts            :integer          default(0), not null
#  context             :jsonb            not null
#  error               :string
#  kind                :string           not null
#  lease_token         :string
#  lease_until         :datetime
#  provider_state      :jsonb            not null
#  status              :string           default("queued"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  copilot_message_id  :bigint
#  copilot_run_step_id :bigint
#  copilot_thread_id   :bigint           not null
#  parent_run_id       :bigint
#  user_id             :bigint           not null
#
# Indexes
#
#  index_copilot_runs_on_account_id           (account_id)
#  index_copilot_runs_on_copilot_message_id   (copilot_message_id) UNIQUE
#  index_copilot_runs_on_copilot_run_step_id  (copilot_run_step_id) UNIQUE
#  index_copilot_runs_on_copilot_thread_id    (copilot_thread_id)
#  index_copilot_runs_on_parent_run_id        (parent_run_id)
#  index_copilot_runs_on_user_id              (user_id)
#
class CopilotRun < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :copilot_thread
  belongs_to :copilot_message, optional: true
  belongs_to :copilot_run_step, optional: true, inverse_of: :background_run
  belongs_to :parent_run, class_name: 'CopilotRun', optional: true
  has_many :child_runs, class_name: 'CopilotRun', foreign_key: :parent_run_id, dependent: :destroy, inverse_of: :parent_run
  has_many :steps, class_name: 'CopilotRunStep', dependent: :delete_all
  has_many :findings, class_name: 'CopilotReviewFinding', dependent: :delete_all

  TERMINAL_STATUSES = %w[completed incomplete failed].freeze
  MAX_SELECTION = 5000
  # Conversations a review finishes per turn. The rest wait until the agent asks to continue.
  REVIEW_BUDGET = 100

  LEASE_DURATION = 2.minutes

  validates :kind, inclusion: { in: %w[chat collection review] }
  # waiting: a chat run parked until a background run started by one of its tool calls finishes.
  validates :status, inclusion: { in: %w[queued running waiting completed incomplete failed] }

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def claim
    with_lock do
      return if terminal? || status == 'waiting' || lease_until&.future?

      update!(status: 'running', lease_until: Time.current + LEASE_DURATION, lease_token: SecureRandom.uuid)
      lease_token
    end
  end

  def with_lease(token)
    with_lock do
      raise Captain::Copilot::LeaseLostError unless status == 'running' && lease_token == token

      yield
    end
  end

  def renew_lease(token)
    with_lease(token) { update!(lease_until: Time.current + LEASE_DURATION) }
  end

  # Checked before every model call, so turning the feature off or running out of credits also stops work in flight.
  def ensure_allowed!
    account.reload
    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_workflows_disabled') unless account.feature_enabled?('copilot_workflows')
    return if account.usage_limits[:captain][:responses][:current_available].positive?

    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_limit')
  end

  # Turns run in order; a message sent while an earlier turn waits on its review is answered after that turn.
  def behind_earlier_turn?
    copilot_thread.copilot_runs.where(kind: 'chat', status: %w[queued running waiting])
                  .where(CopilotRun.arel_table[:copilot_message_id].lt(copilot_message_id)).exists?
  end

  # Called when a background run finishes. This run may not have parked yet; it checks the step under this same lock
  # before parking, so exactly one side re-queues it.
  def resume_with(step, result)
    resumed = with_lock do
      step.update!(status: 'succeeded', result: result)
      status == 'waiting' && update!(status: 'queued')
    end
    Captain::Copilot::ExecutionJob.perform_later(id) if resumed
  end

  # The chat run whose turn this run belongs to. Collections and reviews are started by one of its tool calls.
  def turn
    kind == 'chat' ? self : copilot_run_step.copilot_run
  end

  def selected_ids
    context.fetch('selected_ids', [])
  end

  # A saved set is a collection from get_data or a finished review. A review's records are always conversations.
  def resource
    kind == 'collection' ? context.fetch('resource', 'conversations') : 'conversations'
  end

  # For a review, the matched conversations or every conversation it decided on, including those screened out.
  def record_ids(only_matched: true)
    return selected_ids if kind == 'collection'
    raise ArgumentError, 'The review has not finished yet' unless terminal?

    decided = only_matched ? findings.where(status: 'resolved', matched: true) : findings.where(status: %w[resolved screened_out])
    decided.order(:conversation_id).pluck(:conversation_id)
  end

  # Moves an unfinished review to the tool call that continues it, with budget for the next batch.
  def continue_review(step)
    with_lock do
      return if copilot_run_step_id == step.id
      raise ArgumentError, 'The review is still running' unless terminal?
      raise ArgumentError, 'The review has no conversations left to review' if remaining_ids.empty?
      raise ArgumentError, 'This turn already reviewed a batch. Ask the agent before continuing.' if turn.id == step.copilot_run_id

      update!(copilot_run_step: step, status: 'queued', error: nil, context: context.merge('budget' => processed_count + REVIEW_BUDGET))
    end
  end

  def budget_left
    context.fetch('budget') - processed_count
  end

  def boundary_at
    Time.iso8601(context.fetch('boundary_at'))
  end

  def criteria
    context.fetch('criteria')
  end

  def match
    context['match']
  end

  def filters
    context.fetch('filters', {})
  end

  def remaining_ids
    selected_ids - findings.where(status: CopilotReviewFinding::FINAL_STATUSES).pluck(:conversation_id)
  end

  def receipt
    counts = findings.group(:status).count
    selected = selected_ids.size
    processed = counts.values_at(*CopilotReviewFinding::FINAL_STATUSES).sum(&:to_i)
    { run_id: id, status: status, filters: filters, match: match, selected: selected, processed: processed, remaining: selected - processed,
      screened_out: counts['screened_out'].to_i, reviewed: counts['resolved'].to_i, matched: findings.where(matched: true).count,
      errors: counts['error'].to_i, selection_truncated: context['selection_truncated'], error: error }
  end

  def processed_count
    findings.where(status: CopilotReviewFinding::FINAL_STATUSES).count
  end

  def publish_progress
    progress = receipt
    return if copilot_thread.copilot_messages.assistant_thinking.last&.message&.dig('progress') == progress.as_json

    content = "Processed #{progress[:processed]} of #{progress[:selected]} conversations: #{progress[:matched]} matched, " \
              "#{progress[:screened_out]} screened out, #{progress[:errors]} errors."
    copilot_thread.copilot_messages.create!(message_type: :assistant_thinking, message: { content: content, progress: progress })
  end
end
