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
# What every Copilot run shares: the lease a job holds while it works, the credit check and the cost. Each kind of run is
# a subclass stored in this table, and the type column names it: CopilotRun::Turn, CopilotRun::Collection or
# CopilotRun::Review.
class CopilotRun < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :copilot_thread
  # The tool call that started this run. A turn has none; it starts from the agent's message.
  belongs_to :copilot_tool_call, optional: true, inverse_of: :background_run
  # The saved set this run reads: a collection's from set, or the collection a review reads.
  belongs_to :source_run, class_name: 'CopilotRun', optional: true
  has_many :derived_runs, class_name: 'CopilotRun', foreign_key: :source_run_id, dependent: :destroy, inverse_of: :source_run

  FINISHED_STATUSES = %w[completed incomplete failed].freeze
  MAX_SELECTION = 5000
  # Conversations a review finishes per turn. The rest wait until the agent asks to continue.
  CONVERSATIONS_PER_TURN = 300

  LEASE_DURATION = 2.minutes

  # Each kind allows only some of these. Its STATUSES constant lists them.
  # awaiting_background_run: a turn parked until a background run started by one of its tool calls finishes.
  enum :status, { queued: 'queued', running: 'running', awaiting_background_run: 'awaiting_background_run', completed: 'completed',
                  incomplete: 'incomplete', failed: 'failed' }, validate: true

  # Runs a job may pick up: waiting for a worker, or held by one whose lease may have expired.
  scope :claimable, -> { where(status: %i[queued running]) }
  scope :finished, -> { where(status: FINISHED_STATUSES) }
  scope :unfinished, -> { where.not(status: FINISHED_STATUSES) }

  def finished?
    FINISHED_STATUSES.include?(status)
  end

  def claim
    with_lock do
      return if finished? || awaiting_background_run? || lease_until&.future?

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

  # Ends the worker's hold, so the next job can claim the run.
  def release!(status, **attributes)
    update!(status: status, lease_token: nil, lease_until: nil, **attributes)
  end

  # Checked before every model call, so turning the feature off or running out of credits also stops work in flight.
  def ensure_can_continue!
    account.reload
    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_workflows_disabled') unless account.feature_enabled?('copilot_workflows')
    return if account.usage_limits[:captain][:responses][:current_available].positive?

    raise Captain::Copilot::LimitExceededError, I18n.t('captain.copilot_limit')
  end

  # The turn this run belongs to. Collections and reviews are started by one of its tool calls.
  def turn
    copilot_tool_call.copilot_run
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

  # The fields every summary starts with. Collections and reviews add their own counts.
  def summary
    { run_id: id, status: status, error: error }
  end
end
