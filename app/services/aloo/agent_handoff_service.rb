# frozen_string_literal: true

module Aloo
  # Service to automatically handoff conversation from AI to human agent
  # when a human agent sends a message to an AI-handled conversation
  class AgentHandoffService
    def initialize(message)
      @message = message
      @conversation = message.conversation
      @sender = message.sender
    end

    def perform
      return unless should_handoff?

      handoff_to_agent
    end

    private

    def should_handoff?
      # Must be an outgoing message (from agent, not customer)
      return false unless @message.outgoing?

      # Sender must be a human user (not AI)
      return false unless @sender.is_a?(User) && !@sender.is_ai?

      # Must not be a private note
      return false if @message.private?

      # Conversation must have an active Aloo assistant
      assistant = @conversation.inbox.aloo_assistant
      return false unless assistant&.active?

      # Handoff must not already be active
      return false if @conversation.custom_attributes&.dig('aloo_handoff_active')

      # Conversation must not have a human assignee (AI is handling)
      return false if @conversation.assignee.present?

      true
    end

    def handoff_to_agent
      # Set handoff flag
      attrs = @conversation.custom_attributes.dup || {}
      attrs['aloo_handoff_active'] = true
      attrs['aloo_handoff_at'] = Time.current.iso8601
      attrs['aloo_handoff_triggered_by'] = 'agent_message'

      # Flag conversation as needing human attention (but don't reassign — AI keeps responding)
      @conversation.update!(custom_attributes: attrs)

      Rails.logger.info "[Aloo::AgentHandoffService] Flagged conversation #{@conversation.id} for human attention (triggered by agent #{@sender.id})"
    end
  end
end
