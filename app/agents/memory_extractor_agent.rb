# frozen_string_literal: true

# Agent responsible for extracting learnings and memories from resolved conversations
# Runs asynchronously after a conversation is resolved to improve future responses
#
# Usage:
#   agent = MemoryExtractorAgent.new(
#     account: account,
#     assistant: assistant,
#     conversation: conversation,
#     contact: contact
#   )
#   memories = agent.call
#
class MemoryExtractorAgent < ApplicationAgent
  MAX_MEMORIES_PER_CONVERSATION = 10
  EXTRACTION_MODEL = 'gemini-2.0-flash' # Fast model for extraction

  # Memory types we can extract
  MEMORY_TYPES = {
    'preference' => 'Customer preferences (communication style, product preferences, etc.)',
    'commitment' => 'Promises or commitments made to the customer',
    'decision' => 'Decisions made during the conversation',
    'correction' => 'Corrections to previous misunderstandings or errors',
    'procedure' => 'Procedures or processes learned that apply generally',
    'faq' => 'Frequently asked questions and their answers',
    'insight' => 'General insights about customer needs or patterns',
    'gap' => 'Knowledge gaps identified (things we should know but don\'t)'
  }.freeze

  def initialize(account:, assistant:, conversation:, contact: nil)
    super
    @extracted_memories = []
  end

  # Extract memories from the conversation
  # @return [Hash] Result with extracted memories and metadata
  def call
    return empty_result if conversation.blank?

    # Get conversation transcript
    transcript = build_conversation_transcript

    return empty_result if transcript.blank?

    # Extract memories using LLM
    raw_memories = extract_memories_from_transcript(transcript)

    # Process and store memories
    stored_memories = process_and_store_memories(raw_memories)

    {
      success: true,
      conversation_id: conversation.id,
      memories_extracted: stored_memories.count,
      memories: stored_memories.map { |m| memory_summary(m) }
    }
  rescue RubyLLM::Error => e
    Rails.logger.error("[MemoryExtractorAgent] Extraction failed: #{e.message}")
    { success: false, error: e.message, memories_extracted: 0 }
  end

  protected

  def base_system_prompt
    <<~PROMPT
      You are a memory extraction agent. Your job is to analyze customer support conversations
      and extract valuable learnings that can improve future interactions.

      ## Memory Types
      #{format_memory_types}

      ## Guidelines
      - Only extract genuinely useful information, not obvious or trivial details
      - Be specific and actionable in your extractions
      - For customer preferences/commitments, note the specific customer context
      - For procedures/insights, ensure they're generalizable
      - Identify knowledge gaps when the agent couldn't answer something

      ## Output Format
      Return a JSON array of memories. Each memory should have:
      - type: One of the memory types listed above
      - content: Clear, concise description of the learning
      - entities: Array of relevant entity names (people, products, features)
      - topics: Array of relevant topics
      - contact_specific: true if this applies only to this customer, false if general
    PROMPT
  end

  private

  def empty_result
    { success: true, conversation_id: conversation&.id, memories_extracted: 0, memories: [] }
  end

  def format_memory_types
    MEMORY_TYPES.map { |type, desc| "- #{type}: #{desc}" }.join("\n")
  end

  def build_conversation_transcript
    messages = conversation.messages
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

  def extract_memories_from_transcript(transcript)
    chat = build_chat(model: EXTRACTION_MODEL)

    prompt = <<~PROMPT
      Analyze this customer support conversation and extract valuable learnings.

      ## Conversation
      #{transcript}

      ## Resolution Status
      This conversation was #{conversation.status}. #{resolution_context}

      Extract up to #{MAX_MEMORIES_PER_CONVERSATION} memories. Return as JSON array.
    PROMPT

    response = execute_with_tracing(chat, prompt, system: build_system_prompt)

    parse_memories_response(response.content)
  end

  def resolution_context
    case conversation.status
    when 'resolved'
      'Focus on successful patterns and learnings.'
    when 'open'
      'Note any unresolved issues or knowledge gaps.'
    else
      ''
    end
  end

  def parse_memories_response(content)
    # Extract JSON from response (handle markdown code blocks)
    json_content = content.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip

    JSON.parse(json_content)
  rescue JSON::ParserError => e
    Rails.logger.error("[MemoryExtractorAgent] Failed to parse memories: #{e.message}")
    []
  end

  def process_and_store_memories(raw_memories)
    return [] if raw_memories.blank?

    stored = []

    raw_memories.first(MAX_MEMORIES_PER_CONVERSATION).each do |mem_data|
      memory = create_memory(mem_data)
      stored << memory if memory
    end

    stored
  end

  def create_memory(mem_data)
    memory_type = mem_data['type'].to_s
    content = mem_data['content'].to_s

    # Validate memory type
    return nil unless MEMORY_TYPES.key?(memory_type)
    return nil if content.blank?

    # Check for duplicates
    memory_service = Aloo::MemorySearchService.new(assistant: assistant, account: account)
    existing = memory_service.find_duplicate(content, memory_type, contact: contact)

    if existing
      # Update existing memory instead of creating duplicate
      existing.increment!(:observation_count)
      existing.touch(:last_accessed_at)
      return existing
    end

    # Generate embedding for the memory
    embedding_service = Aloo::EmbeddingService.new(account: account)
    embedding_vector = embedding_service.generate_embedding(content)

    # Create new memory
    assistant.memories.create!(
      account: account,
      contact: determine_contact_for_memory(mem_data),
      memory_type: memory_type,
      content: content,
      entities: Array(mem_data['entities']),
      topics: Array(mem_data['topics']),
      embedding: embedding_vector,
      source_conversation_id: conversation.id,
      confidence_score: 0.7, # Initial confidence
      observation_count: 1,
      last_accessed_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[MemoryExtractorAgent] Failed to create memory: #{e.message}")
    nil
  end

  def determine_contact_for_memory(mem_data)
    # Contact-scoped types should be associated with the contact
    is_contact_specific = mem_data['contact_specific'] == true ||
                          Aloo::CONTACT_SCOPED_TYPES.include?(mem_data['type'])

    is_contact_specific ? contact : nil
  end

  def memory_summary(memory)
    {
      id: memory.id,
      type: memory.memory_type,
      content: memory.content.truncate(100),
      is_new: memory.observation_count == 1
    }
  end
end
