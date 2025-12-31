# frozen_string_literal: true

# Base class for all Aloo AI agents
# Provides common functionality for model configuration, error handling, and tracing
#
# Usage:
#   class MyAgent < ApplicationAgent
#     def call
#       chat = build_chat(model: 'gemini-2.0-flash')
#       chat.ask(prompt)
#     end
#   end
#
class ApplicationAgent
  DEFAULT_MODEL = 'gemini-2.0-flash'
  FALLBACK_MODEL = 'gpt-4o-mini'

  attr_reader :account, :assistant, :conversation, :contact

  def initialize(account:, assistant:, conversation: nil, contact: nil)
    @account = account
    @assistant = assistant
    @conversation = conversation
    @contact = contact
    validate_params!
  end

  # Override in subclasses to implement agent logic
  def call
    raise NotImplementedError, 'Subclasses must implement #call'
  end

  protected

  # Build a chat instance with the specified model
  # @param model [String] The model to use
  # @param tools [Array<Class>] Tool classes to enable
  # @return [RubyLLM::Chat] Configured chat instance
  def build_chat(model: nil, tools: [])
    model ||= assistant_model
    chat = RubyLLM.chat(model: model)
    chat.with_tools(tools) if tools.any?
    chat
  end

  # Execute a chat with tracing and error handling
  # @param chat [RubyLLM::Chat] The chat instance
  # @param message [String] The message to send
  # @param system [String] Optional system prompt
  # @return [RubyLLM::Response] The response
  def execute_with_tracing(chat, message, system: nil)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = nil
    success = true
    error_message = nil

    begin
      set_current_context do
        response = chat.ask(message, system: system)
      end
    rescue RubyLLM::Error => e
      success = false
      error_message = e.message
      Rails.logger.error("[#{self.class.name}] LLM error: #{e.message}")
      raise
    ensure
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      record_trace(
        response: response,
        duration_ms: duration_ms,
        success: success,
        error_message: error_message
      )
    end

    response
  end

  # Build the system prompt for the agent
  # Override in subclasses for custom prompts
  def build_system_prompt
    parts = []
    parts << base_system_prompt
    parts << personality_prompt if assistant
    parts << language_instructions if assistant&.language_instruction.present?
    parts.compact.join("\n\n")
  end

  # Get the base system prompt - override in subclasses
  def base_system_prompt
    'You are a helpful AI assistant.'
  end

  # Get personality prompt from assistant settings
  def personality_prompt
    return nil unless assistant

    Aloo::PersonalityBuilder.new(assistant).build
  end

  # Get language instructions
  def language_instructions
    return nil unless assistant&.language_instruction.present?

    "## Language Instructions\n#{assistant.language_instruction}"
  end

  # Get context from knowledge base and memories
  # @param query [String] The query to search for
  # @return [String] Combined context string
  def gather_context(query)
    parts = []

    # Knowledge base context
    knowledge_context = search_knowledge_base(query)
    parts << "## Relevant Information\n#{knowledge_context}" if knowledge_context.present?

    # Memory context
    memory_context = search_memories(query)
    parts << "## Customer Context\n#{memory_context}" if memory_context.present?

    parts.join("\n\n")
  end

  # Search knowledge base for relevant content
  def search_knowledge_base(query)
    return nil unless assistant

    service = Aloo::VectorSearchService.new(assistant: assistant, account: account)
    service.search_for_context(query)
  rescue StandardError => e
    Rails.logger.error("[#{self.class.name}] Knowledge search failed: #{e.message}")
    nil
  end

  # Search memories for relevant content
  def search_memories(query)
    return nil unless assistant

    service = Aloo::MemorySearchService.new(assistant: assistant, account: account)
    service.search_for_context(query, contact: contact)
  rescue StandardError => e
    Rails.logger.error("[#{self.class.name}] Memory search failed: #{e.message}")
    nil
  end

  private

  def validate_params!
    raise ArgumentError, 'Account required' unless account
    raise ArgumentError, 'Assistant required' unless assistant
    raise ArgumentError, 'Account mismatch' unless assistant.account_id == account.id
  end

  def assistant_model
    assistant&.model_name.presence || DEFAULT_MODEL
  end

  def set_current_context
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
    Aloo::Current.request_id ||= SecureRandom.uuid
    yield
  ensure
    Aloo::Current.reset
  end

  def record_trace(response:, duration_ms:, success:, error_message:)
    Aloo::Trace.record(
      trace_type: 'agent_call',
      account: account,
      assistant: assistant,
      conversation: conversation,
      input_data: {
        agent: self.class.name,
        model: assistant_model
      },
      output_data: response ? extract_response_data(response) : {},
      input_tokens: response&.input_tokens,
      output_tokens: response&.output_tokens,
      duration_ms: duration_ms,
      success: success,
      error_message: error_message
    )
  end

  def extract_response_data(response)
    {
      content_length: response.content&.length,
      tool_calls: response.tool_calls&.map(&:name),
      finish_reason: response.finish_reason
    }
  end
end
