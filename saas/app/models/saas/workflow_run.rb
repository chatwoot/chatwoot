# frozen_string_literal: true

class Saas::WorkflowRun < ApplicationRecord
  self.table_name = 'workflow_runs'

  belongs_to :ai_agent, class_name: 'Saas::AiAgent'
  belongs_to :conversation, class_name: '::Conversation'

  enum :status, { running: 0, waiting: 1, completed: 2, failed: 3, handed_off: 4 }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_agent, ->(agent_id) { where(ai_agent_id: agent_id) }

  def duration_ms
    return nil unless started_at && completed_at

    ((completed_at - started_at) * 1000).round
  end

  def total_tokens
    execution_log&.sum { |entry| entry.dig('usage', 'total_tokens').to_i } || 0
  end

  def log_node_execution(node_id:, type:, started_at:, completed_at: nil, fired_handles: [], usage: nil, error: nil)
    entry = {
      'node_id' => node_id,
      'type' => type,
      'started_at' => started_at.iso8601(3),
      'completed_at' => completed_at&.iso8601(3),
      'fired_handles' => fired_handles,
      'usage' => usage,
      'error' => error
    }.compact

    self.execution_log = (execution_log || []) + [entry]
  end
end
