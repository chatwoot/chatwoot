# frozen_string_literal: true

module Aloo
  module RubyLLMMock
    # Stub RubyLLM.embed to return a mock embedding
    # @param vectors [Array<Float>] Optional custom vectors (defaults to random 1536-dim vector)
    # @return [Object] The mock embedding result
    def stub_ruby_llm_embed(vectors: nil)
      vectors ||= Array.new(1536) { rand(-1.0..1.0) }
      result = instance_double('RubyLLM::Embedding', vectors: vectors)
      allow(RubyLLM).to receive(:embed).and_return(result)
      result
    end

    # Stub RubyLLM.embed to raise an error
    # @param error_message [String] The error message
    def stub_ruby_llm_embed_failure(error_message = 'API error')
      allow(RubyLLM).to receive(:embed).and_raise(RubyLLM::Error.new(error_message))
    end

    # Stub an agent class call to return a mock result
    # @param agent_class [Class] The agent class to stub
    # @param success [Boolean] Whether the call should succeed
    # @param content [Object] The response content
    # @param input_tokens [Integer] Input token count
    # @param output_tokens [Integer] Output token count
    # @param tool_calls [Array] Array of tool calls
    # @return [Object] The mock result
    def stub_agent_call(agent_class, success: true, content: nil, input_tokens: 100, output_tokens: 50, tool_calls: [])
      content ||= default_content_for(agent_class)

      result = instance_double(
        'RubyLLM::Agents::Result',
        success?: success,
        content: content,
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        tool_calls: tool_calls
      )
      allow(agent_class).to receive(:call).and_return(result)
      result
    end

    # Stub an agent class call to raise an error
    # @param agent_class [Class] The agent class to stub
    # @param error_message [String] The error message
    def stub_agent_call_failure(agent_class, error_message = 'Agent error')
      allow(agent_class).to receive(:call).and_raise(RubyLLM::Error.new(error_message))
    end

    # Create a mock tool call
    # @param name [String] Tool name
    # @param arguments [Hash] Tool arguments
    # @return [Object] Mock tool call
    def mock_tool_call(name:, arguments: {})
      instance_double('RubyLLM::ToolCall', name: name, arguments: arguments)
    end

    private

    def default_content_for(agent_class)
      case agent_class.name
      when 'ConversationAgent'
        'Hello, how can I help you today?'
      when 'MemoryExtractorAgent'
        { memories: [] }
      when 'FaqGeneratorAgent'
        { faqs: [] }
      when 'ConversationTriageAgent'
        { label_id: nil, team_id: nil }
      else
        'Default response'
      end
    end
  end
end

RSpec.configure do |config|
  config.include Aloo::RubyLLMMock, type: :job
  config.include Aloo::RubyLLMMock, type: :service
  config.include Aloo::RubyLLMMock, aloo: true
end
