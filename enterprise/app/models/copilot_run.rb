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
  belongs_to :copilot_run_step, optional: true
  belongs_to :parent_run, class_name: 'CopilotRun', optional: true
  has_many :child_runs, class_name: 'CopilotRun', foreign_key: :parent_run_id, dependent: :destroy, inverse_of: :parent_run
  has_many :steps, class_name: 'CopilotRunStep', dependent: :delete_all
  has_many :findings, class_name: 'CopilotReviewFinding', dependent: :delete_all

  TERMINAL_STATUSES = %w[completed incomplete cancelled failed].freeze
  MAX_SELECTION = 5000

  LEASE_DURATION = 2.minutes

  validates :kind, inclusion: { in: %w[chat collection review] }
  validates :status, inclusion: { in: %w[queued running waiting_for_approval completed incomplete cancelled failed] }

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def claim
    with_lock do
      return if terminal? || status == 'waiting_for_approval' || lease_until&.future?

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

  def selected_ids
    context.fetch('selected_ids', [])
  end

  def boundary_at
    Time.iso8601(context.fetch('boundary_at'))
  end

  def criteria
    context.fetch('criteria')
  end

  def filters
    context.fetch('filters', {})
  end

  def remaining_ids
    selected_ids - findings.where(status: %w[resolved error]).pluck(:conversation_id)
  end

  def receipt
    resolved = findings.where(status: 'resolved').count
    errors = findings.where(status: 'error').count
    { run_id: id, status: status, filters: filters, selected: selected_ids.size, reviewed: resolved, errors: errors,
      processed: resolved + errors, selection_truncated: context['selection_truncated'], error: error }
  end

  def publish_progress
    progress = receipt
    copilot_thread.copilot_messages.create!(message_type: :assistant_thinking,
                                            message: { content: "Reviewed #{progress[:reviewed]} of #{selected_ids.size} conversations. " \
                                                                "Errors: #{progress[:errors]}. Status: #{status}.",
                                                       progress: progress })
  end
end
