# frozen_string_literal: true

module Aloo
  class FaqGeneratorJob < ApplicationJob
    queue_as :low
    retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 2

    MAX_FAQS = 3
    MIN_MESSAGES_FOR_FAQ = 4
    DUPLICATE_THRESHOLD = 0.15

    def perform(conversation_id)
      @conversation = Conversation.find_by(id: conversation_id)
      return unless @conversation

      @inbox = @conversation.inbox
      @assistant = @inbox.aloo_assistant
      @account = @conversation.account
      @contact = @conversation.contact

      return unless @assistant&.active?
      return unless @assistant.feature_faq_enabled?
      return unless @conversation.resolved?
      return if already_processed?
      return skip_result('Not enough messages') unless sufficient_messages?

      set_aloo_context do
        transcript = build_conversation_transcript
        return skip_result('Empty transcript') if transcript.blank?

        result = FaqGeneratorAgent.call(
          transcript: transcript,
          max_faqs: MAX_FAQS
        )

        if result.success?
          faqs = result.content[:faqs] || []
          stored = process_and_store_faqs(faqs)
          mark_processed(stored.count)

          Rails.logger.info(
            "[Aloo::FaqGeneratorJob] Conversation #{conversation_id}: " \
            "generated #{stored.count} FAQs"
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Aloo::FaqGeneratorJob] Error: #{e.message}")
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

    def sufficient_messages?
      @conversation.messages
                   .where(message_type: %i[incoming outgoing])
                   .where(private: false)
                   .count >= MIN_MESSAGES_FOR_FAQ
    end

    def build_conversation_transcript
      messages = @conversation.messages
                              .where(message_type: %i[incoming outgoing])
                              .where(private: false)
                              .order(created_at: :asc)

      return nil if messages.empty?

      messages.map do |msg|
        role = msg.message_type == 'incoming' ? 'Customer' : 'Agent'
        "#{role}: #{msg.content}"
      end.join("\n\n")
    end

    def process_and_store_faqs(raw_faqs)
      return [] if raw_faqs.blank?

      stored = []
      raw_faqs.first(MAX_FAQS).each do |faq_data|
        memory = create_faq_memory(faq_data)
        stored << memory if memory
      end
      stored
    end

    def create_faq_memory(faq_data)
      question = faq_data['question'].to_s.strip
      answer = faq_data['answer'].to_s.strip

      return nil if question.blank? || answer.blank?

      content = "Q: #{question}\nA: #{answer}"

      memory_service = MemorySearchService.new(assistant: @assistant, account: @account)
      existing = memory_service.find_duplicate(content, 'faq')

      if existing
        existing.increment!(:observation_count)
        existing.update!(
          confidence: calculate_updated_confidence(existing, faq_data),
          last_observed_at: Time.current
        )
        return existing
      end

      embedding_service = EmbeddingService.new(account: @account)
      embedding_vector = embedding_service.generate_embedding(content)

      @assistant.memories.create!(
        account: @account,
        contact: nil,
        memory_type: 'faq',
        content: content,
        entities: [],
        topics: Array(faq_data['topics']),
        embedding: embedding_vector,
        confidence: faq_data['confidence'] || 0.7,
        observation_count: 1,
        last_observed_at: Time.current,
        metadata: { source_conversation_id: @conversation.id }
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[FaqGeneratorJob] Failed to create FAQ: #{e.message}")
      nil
    end

    def calculate_updated_confidence(existing, new_data)
      new_confidence = new_data['confidence'] || 0.7
      avg = (existing.confidence + new_confidence) / 2.0
      boost = [existing.observation_count * 0.02, 0.2].min
      [avg + boost, 1.0].min
    end

    def skip_result(reason)
      mark_processed(0, skipped: true, reason: reason)
      Rails.logger.info("[Aloo::FaqGeneratorJob] Conversation #{@conversation.id}: skipped - #{reason}")
    end

    def already_processed?
      @conversation.custom_attributes&.dig('aloo_faq_generation_completed') == true
    end

    def mark_processed(count, skipped: false, reason: nil)
      @conversation.update!(
        custom_attributes: @conversation.custom_attributes.merge(
          'aloo_faq_generation_completed' => true,
          'aloo_faq_generation_result' => {
            'faqs_generated' => count,
            'skipped' => skipped,
            'reason' => reason,
            'processed_at' => Time.current.iso8601
          }
        )
      )
    end
  end
end
