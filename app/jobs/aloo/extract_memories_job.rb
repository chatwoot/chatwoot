# frozen_string_literal: true

module Aloo
  class ExtractMemoriesJob < ApplicationJob
    queue_as :low
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 2

    MEMORY_TYPES = MemoryExtractorAgent::MEMORY_TYPES.keys.freeze
    CONTACT_SCOPED_TYPES = %w[preference commitment].freeze

    def perform(conversation_id)
      @conversation = Conversation.find_by(id: conversation_id)
      return unless @conversation

      @inbox = @conversation.inbox
      @assistant = @inbox.aloo_assistant
      @account = @conversation.account
      @contact = @conversation.contact

      return unless @assistant&.active?
      return unless @assistant.feature_memory_enabled?
      return unless @conversation.resolved?
      return if already_processed?

      set_aloo_context do
        transcript = build_conversation_transcript
        return if transcript.blank?

        result = MemoryExtractorAgent.call(
          transcript: transcript,
          resolution_status: @conversation.status,
          max_memories: 10
        )

        if result.success?
          memories = result.content[:memories] || []
          stored = process_and_store_memories(memories)
          mark_processed(stored.count)

          Rails.logger.info(
            "[Aloo::ExtractMemoriesJob] Conversation #{conversation_id}: " \
            "extracted #{stored.count} memories"
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Aloo::ExtractMemoriesJob] Error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      raise
    end

    private

    def set_aloo_context
      Aloo::Current.account = @account
      Aloo::Current.assistant = @assistant
      Aloo::Current.conversation = @conversation
      Aloo::Current.contact = @contact
      yield
    ensure
      Aloo::Current.reset
    end

    def build_conversation_transcript
      messages = @conversation.messages
                              .where(message_type: %i[incoming outgoing])
                              .where(private: false)
                              .order(created_at: :asc)

      return nil if messages.empty?

      messages.map do |msg|
        role = msg.message_type == 'incoming' ? 'Customer' : 'Agent'
        timestamp = msg.created_at.strftime('%H:%M')
        "[#{timestamp}] #{role}: #{msg.content}"
      end.join("\n\n")
    end

    def process_and_store_memories(raw_memories)
      return [] if raw_memories.blank?

      stored = []
      raw_memories.first(10).each do |mem_data|
        memory = create_memory(mem_data)
        stored << memory if memory
      end
      stored
    end

    def create_memory(mem_data)
      memory_type = mem_data['type'].to_s
      content = mem_data['content'].to_s

      return nil unless MEMORY_TYPES.include?(memory_type)
      return nil if content.blank?

      memory_service = MemorySearchService.new(assistant: @assistant, account: @account)
      existing = memory_service.find_duplicate(content, memory_type, contact: @contact)

      if existing
        existing.increment!(:observation_count)
        existing.touch(:last_observed_at)
        return existing
      end

      embedding_service = EmbeddingService.new(account: @account)
      embedding_vector = embedding_service.generate_embedding(content)

      @assistant.memories.create!(
        account: @account,
        contact: determine_contact_for_memory(mem_data),
        memory_type: memory_type,
        content: content,
        entities: Array(mem_data['entities']),
        topics: Array(mem_data['topics']),
        embedding: embedding_vector,
        confidence: 0.7,
        observation_count: 1,
        last_observed_at: Time.current,
        metadata: { source_conversation_id: @conversation.id }
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[ExtractMemoriesJob] Failed to create memory: #{e.message}")
      nil
    end

    def determine_contact_for_memory(mem_data)
      is_contact_specific = mem_data['contact_specific'] == true ||
                            CONTACT_SCOPED_TYPES.include?(mem_data['type'])
      is_contact_specific ? @contact : nil
    end

    def already_processed?
      context = ConversationContext.find_by(
        conversation: @conversation,
        assistant: @assistant
      )
      return false unless context

      context.context_data['memory_extraction_completed'] == true
    end

    def mark_processed(count)
      context = ConversationContext.find_or_create_by!(
        conversation: @conversation,
        assistant: @assistant
      ) do |ctx|
        ctx.context_data = {}
        ctx.tool_history = []
      end

      context.set_context('memory_extraction_completed', true)
      context.set_context('memory_extraction_result', {
                            memories_extracted: count,
                            processed_at: Time.current.iso8601
                          })
    end
  end
end
