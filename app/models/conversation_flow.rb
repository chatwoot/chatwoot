# frozen_string_literal: true

# [whisker] Conversation Flow — stores flow definitions for automated conversation routing
class ConversationFlow < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :flow_data, presence: true

  scope :enabled, -> { where(enabled: true) }

  # Flow data structure:
  # {
  #   nodes: [
  #     { id: "node_1", type: "trigger", data: { event: "conversation_created" } },
  #     { id: "node_2", type: "condition", data: { field: "inbox_id", operator: "equals", value: 1 } },
  #     { id: "node_3", type: "action", data: { action: "assign_agent", agent_id: 5 } },
  #     { id: "node_4", type: "ai_reply", data: { prompt: "Welcome message" } },
  #   ],
  #   edges: [
  #     { source: "node_1", target: "node_2" },
  #     { source: "node_2", target: "node_3", label: "yes" },
  #     { source: "node_2", target: "node_4", label: "no" },
  #   ]
  # }
  def execute(conversation:, message: nil)
    FlowExecutionService.new(
      flow: self,
      conversation: conversation,
      message: message
    ).perform
  end
end
