class CopilotRun < ApplicationRecord
  ACTIVE_STATUSES = %w[queued running needs_clarification].freeze
  STATUSES = (ACTIVE_STATUSES + %w[incomplete completed failed cancelled]).freeze

  belongs_to :copilot_thread
  belongs_to :triggering_message, class_name: 'CopilotMessage'
  belongs_to :response_message, class_name: 'CopilotMessage', optional: true
  has_many :copilot_run_items, dependent: :delete_all
  has_many :copilot_messages, dependent: :nullify
  delegate :account, :user, to: :copilot_thread
  validates :status, inclusion: { in: STATUSES }
  validates :triggering_message_id, uniqueness: true
  scope :active, -> { where(status: ACTIVE_STATUSES) }

  def claim! # rubocop:disable Metrics/AbcSize
    account.with_lock do
      running = self.class.where(copilot_thread_id: account.copilot_threads.select(:id), status: 'running')
                    .where(self.class.arel_table[:lease_expires_at].gt(Time.current)).count
      next if running >= Copilot::V2::Limits::ACCOUNT_CONCURRENCY

      with_lock do
        next unless status == 'queued' || (status == 'running' && lease_expires_at && lease_expires_at <= Time.current)

        update!(status: 'running', claim_generation: claim_generation + 1,
                lease_expires_at: Copilot::V2::Limits::LEASE_SECONDS.seconds.from_now)
        claim_generation
      end
    end
  end

  def fenced!(generation)
    with_lock do
      raise Copilot::V2::Runner::StaleClaim unless status == 'running' && claim_generation == generation && lease_expires_at > Time.current

      yield
    end
  end

  def structured_result
    summary = result_summary
    summary = summary.merge(Copilot::V2::Results.new(self).saved_summary(reason: reason)) if %w[queued running].include?(status)
    summary.merge('version' => 1, 'run_id' => id, 'status' => status, 'reason' => reason,
                  'datasets' => datasets, 'usage' => budget)
  end
end
