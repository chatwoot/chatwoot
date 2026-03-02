# frozen_string_literal: true

class Saas::AiAgentInbox < ApplicationRecord
  self.table_name = 'ai_agent_inboxes'

  belongs_to :ai_agent, class_name: 'Saas::AiAgent'
  belongs_to :inbox

  enum :status, { active: 0, paused: 1 }

  validates :ai_agent_id, uniqueness: { scope: :inbox_id, message: 'is already linked to this inbox' }

  scope :active, -> { where(status: :active) }
  scope :for_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }

  # Convenience: find the active AI agent for a given inbox
  def self.active_agent_for(inbox)
    active.find_by(inbox: inbox)&.ai_agent
  end
end
