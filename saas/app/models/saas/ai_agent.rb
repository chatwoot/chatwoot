# frozen_string_literal: true

class Saas::AiAgent < ApplicationRecord
  self.table_name = 'ai_agents'

  include Avatarable

  belongs_to :account

  has_many :ai_agent_inboxes, class_name: 'Saas::AiAgentInbox', dependent: :destroy_async
  has_many :inboxes, through: :ai_agent_inboxes
  has_many :knowledge_bases, class_name: 'Saas::KnowledgeBase', dependent: :destroy_async
  has_many :agent_tools, class_name: 'Saas::AgentTool', dependent: :destroy_async

  enum :agent_type, { rag: 0, tool_calling: 1, voice: 2, hybrid: 3 }
  enum :status, { active: 0, paused: 1, archived: 2 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :agent_type, presence: true
  validates :model, presence: true

  scope :available, -> { where(status: :active) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }

  # Default LLM config values
  def temperature
    llm_config&.dig('temperature') || 0.7
  end

  def max_tokens
    llm_config&.dig('max_tokens') || 4096
  end

  def top_p
    llm_config&.dig('top_p') || 1.0
  end

  # Returns the tool definitions formatted for the LLM API
  def tool_definitions
    agent_tools.active.map(&:to_llm_tool)
  end

  # Check if this agent has any active knowledge bases with documents
  def has_knowledge? # rubocop:disable Naming/PredicateName
    knowledge_bases.active.joins(:knowledge_documents).where(knowledge_documents: { status: :ready }).exists?
  end

  # Returns the active inboxes for this agent
  def active_inboxes
    ai_agent_inboxes.active.includes(:inbox).map(&:inbox)
  end

  # --- Voice config helpers ---

  def voice_provider
    voice_config&.dig('provider') || 'openai'
  end

  def voice_id
    case voice_provider
    when 'elevenlabs'
      voice_config&.dig('elevenlabs_voice_id') || '21m00Tcm4TlvDq8ikWAM'
    else
      voice_config&.dig('voice') || 'alloy'
    end
  end

  def voice_language
    voice_config&.dig('language') || 'en'
  end

  def voice_speed
    voice_config&.dig('speed') || 1.0
  end

  def interruption_sensitivity
    voice_config&.dig('interruption_sensitivity') || 'medium'
  end

  def realtime_model
    case voice_provider
    when 'elevenlabs'
      voice_config&.dig('elevenlabs_model_id') || 'eleven_turbo_v2_5'
    else
      voice_config&.dig('realtime_model') || 'gpt-4o-realtime-preview'
    end
  end

  def voice_greeting
    voice_config&.dig('greeting') || 'Hello! How can I help you today?'
  end

  # Whether this agent supports realtime voice (WebSocket audio streaming)
  def realtime_capable?
    return false unless voice? || hybrid?
    return false if voice_config&.dig('realtime_enabled') == false

    case voice_provider
    when 'elevenlabs'
      voice_config&.dig('elevenlabs_agent_id').present?
    else
      true
    end
  end
end
