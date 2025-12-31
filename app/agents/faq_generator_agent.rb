# frozen_string_literal: true

# Agent responsible for generating FAQ entries from resolved conversations
# Analyzes successful resolutions to create knowledge base entries
#
# Usage:
#   agent = FaqGeneratorAgent.new(
#     account: account,
#     assistant: assistant,
#     conversation: conversation
#   )
#   faqs = agent.call
#
class FaqGeneratorAgent < ApplicationAgent
  MAX_FAQS_PER_CONVERSATION = 3
  EXTRACTION_MODEL = 'gemini-2.0-flash'
  MIN_MESSAGES_FOR_FAQ = 4 # Need enough context to generate useful FAQ

  def initialize(account:, assistant:, conversation:, contact: nil)
    super
    @generated_faqs = []
  end

  # Generate FAQs from the conversation
  # @return [Hash] Result with generated FAQs and metadata
  def call
    return skip_result('No conversation') if conversation.blank?
    return skip_result('Conversation not resolved') unless conversation.status == 'resolved'
    return skip_result('Not enough messages') unless sufficient_messages?

    # Get conversation transcript
    transcript = build_conversation_transcript

    return skip_result('Empty transcript') if transcript.blank?

    # Generate FAQs using LLM
    raw_faqs = generate_faqs_from_transcript(transcript)

    # Process and store FAQs
    stored_faqs = process_and_store_faqs(raw_faqs)

    {
      success: true,
      conversation_id: conversation.id,
      faqs_generated: stored_faqs.count,
      faqs: stored_faqs.map { |f| faq_summary(f) }
    }
  rescue RubyLLM::Error => e
    Rails.logger.error("[FaqGeneratorAgent] FAQ generation failed: #{e.message}")
    { success: false, error: e.message, faqs_generated: 0 }
  end

  protected

  def base_system_prompt
    <<~PROMPT
      You are a FAQ generator. Your job is to analyze resolved customer support conversations
      and create FAQ entries that can help answer similar questions in the future.

      ## Guidelines
      - Only create FAQs for questions that are likely to be asked by other customers
      - Focus on questions that were successfully answered
      - Write clear, concise questions that match how customers naturally ask
      - Write complete, accurate answers based on how the issue was resolved
      - Avoid customer-specific details in FAQs (make them generalizable)
      - Each FAQ should be self-contained and useful on its own

      ## Output Format
      Return a JSON array of FAQs. Each FAQ should have:
      - question: The question as a customer would ask it
      - answer: Clear, helpful answer
      - topics: Array of relevant topics for categorization
      - confidence: 0.0-1.0 rating of how generally applicable this FAQ is
    PROMPT
  end

  private

  def skip_result(reason)
    { success: true, conversation_id: conversation&.id, faqs_generated: 0, skipped: true, reason: reason }
  end

  def sufficient_messages?
    conversation.messages
                .where(message_type: %i[incoming outgoing])
                .where(private: false)
                .count >= MIN_MESSAGES_FOR_FAQ
  end

  def build_conversation_transcript
    messages = conversation.messages
                           .where(message_type: %i[incoming outgoing])
                           .where(private: false)
                           .order(created_at: :asc)

    return nil if messages.empty?

    messages.map do |msg|
      role = msg.message_type == 'incoming' ? 'Customer' : 'Agent'
      "#{role}: #{msg.content}"
    end.join("\n\n")
  end

  def generate_faqs_from_transcript(transcript)
    chat = build_chat(model: EXTRACTION_MODEL)

    prompt = <<~PROMPT
      Analyze this resolved customer support conversation and generate FAQ entries.

      ## Conversation
      #{transcript}

      ## Instructions
      - Generate up to #{MAX_FAQS_PER_CONVERSATION} FAQs from questions that were successfully answered
      - Skip questions that are too specific to this customer
      - Focus on questions other customers might also ask
      - Return as JSON array

      If no suitable FAQs can be generated, return an empty array [].
    PROMPT

    response = execute_with_tracing(chat, prompt, system: build_system_prompt)

    parse_faqs_response(response.content)
  end

  def parse_faqs_response(content)
    # Extract JSON from response (handle markdown code blocks)
    json_content = content.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip

    JSON.parse(json_content)
  rescue JSON::ParserError => e
    Rails.logger.error("[FaqGeneratorAgent] Failed to parse FAQs: #{e.message}")
    []
  end

  def process_and_store_faqs(raw_faqs)
    return [] if raw_faqs.blank?

    stored = []

    raw_faqs.first(MAX_FAQS_PER_CONVERSATION).each do |faq_data|
      memory = create_faq_memory(faq_data)
      stored << memory if memory
    end

    stored
  end

  def create_faq_memory(faq_data)
    question = faq_data['question'].to_s.strip
    answer = faq_data['answer'].to_s.strip

    return nil if question.blank? || answer.blank?

    # Format as Q&A content
    content = "Q: #{question}\nA: #{answer}"

    # Check for duplicate FAQ
    memory_service = Aloo::MemorySearchService.new(assistant: assistant, account: account)
    existing = memory_service.find_duplicate(content, 'faq')

    if existing
      # Update existing FAQ
      existing.increment!(:observation_count)
      existing.update!(
        confidence_score: calculate_updated_confidence(existing, faq_data),
        last_accessed_at: Time.current
      )
      return existing
    end

    # Generate embedding
    embedding_service = Aloo::EmbeddingService.new(account: account)
    embedding_vector = embedding_service.generate_embedding(content)

    # Create new FAQ memory
    assistant.memories.create!(
      account: account,
      contact: nil, # FAQs are global, not contact-specific
      memory_type: 'faq',
      content: content,
      entities: [],
      topics: Array(faq_data['topics']),
      embedding: embedding_vector,
      source_conversation_id: conversation.id,
      confidence_score: faq_data['confidence'] || 0.7,
      observation_count: 1,
      last_accessed_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[FaqGeneratorAgent] Failed to create FAQ: #{e.message}")
    nil
  end

  def calculate_updated_confidence(existing, new_data)
    # Increase confidence when we see the same FAQ pattern again
    new_confidence = new_data['confidence'] || 0.7
    avg = (existing.confidence_score + new_confidence) / 2.0

    # Boost for multiple observations
    boost = [existing.observation_count * 0.02, 0.2].min

    [avg + boost, 1.0].min
  end

  def faq_summary(memory)
    # Parse Q&A from content
    lines = memory.content.split("\n")
    question = lines.find { |l| l.start_with?('Q:') }&.sub('Q:', '')&.strip
    answer = lines.find { |l| l.start_with?('A:') }&.sub('A:', '')&.strip

    {
      id: memory.id,
      question: question&.truncate(80),
      answer: answer&.truncate(100),
      confidence: memory.confidence_score,
      is_new: memory.observation_count == 1
    }
  end
end
