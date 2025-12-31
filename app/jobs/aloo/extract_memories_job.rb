# frozen_string_literal: true

module Aloo
  class ExtractMemoriesJob < ApplicationJob
    queue_as :low
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 2

    # Extract memories from a resolved conversation
    # @param conversation_id [Integer] The conversation ID to process
    def perform(conversation_id)
      @conversation = Conversation.find_by(id: conversation_id)
      return unless @conversation

      @inbox = @conversation.inbox
      @assistant = @inbox.aloo_assistant
      return unless @assistant&.active?
      return unless @assistant.feature_memory_enabled?

      # Only extract on resolution
      return unless @conversation.resolved?

      # Check if already processed
      return if already_processed?

      # Run memory extraction
      agent = MemoryExtractorAgent.new(
        account: @conversation.account,
        assistant: @assistant,
        conversation: @conversation,
        contact: @conversation.contact
      )

      result = agent.call

      # Mark as processed
      mark_processed(result)

      Rails.logger.info(
        "[Aloo::ExtractMemoriesJob] Conversation #{conversation_id}: " \
        "extracted #{result[:memories_extracted]} memories"
      )
    rescue StandardError => e
      Rails.logger.error("[Aloo::ExtractMemoriesJob] Error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      raise
    end

    private

    def already_processed?
      context = ConversationContext.find_by(
        conversation: @conversation,
        assistant: @assistant
      )

      return false unless context

      context.context_data['memory_extraction_completed'] == true
    end

    def mark_processed(result)
      context = ConversationContext.find_or_create_by!(
        conversation: @conversation,
        assistant: @assistant
      ) do |ctx|
        ctx.context_data = {}
        ctx.tool_history = []
      end

      context.set_context('memory_extraction_completed', true)
      context.set_context('memory_extraction_result', {
        memories_extracted: result[:memories_extracted],
        processed_at: Time.current.iso8601
      })
    end
  end
end
