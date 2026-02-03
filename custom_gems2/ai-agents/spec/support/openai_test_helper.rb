# frozen_string_literal: true

# Helper module for creating OpenAI API mocks in tests
# Provides convenient methods to stub common OpenAI response patterns
module OpenAITestHelper
  # Stub a simple chat completion with text response
  #
  # @param content [String] The assistant's response text
  # @param model [String] The model used for the response
  # @param usage [Hash] Token usage information
  def stub_simple_chat(content = "Hello! How can I help you?", model: "gpt-4o", usage: nil)
    usage ||= { prompt_tokens: 10, completion_tokens: 8, total_tokens: 18 }

    response = {
      id: "chatcmpl-#{SecureRandom.hex(8)}",
      object: "chat.completion",
      created: Time.now.to_i,
      model: model,
      choices: [{
        index: 0,
        message: {
          role: "assistant",
          content: content
        },
        finish_reason: "stop"
      }],
      usage: usage
    }

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
  end

  # Stub a chat completion that makes tool calls
  #
  # @param tool_calls [Array<Hash>] Array of tool calls to include
  # @param model [String] The model used for the response
  def stub_tool_call_chat(tool_calls:, model: "gpt-4o")
    formatted_tool_calls = tool_calls.map do |call|
      {
        id: call[:id] || "call_#{SecureRandom.hex(4)}",
        type: "function",
        function: {
          name: call[:name],
          arguments: call[:arguments].is_a?(String) ? call[:arguments] : call[:arguments].to_json
        }
      }
    end

    response = {
      id: "chatcmpl-#{SecureRandom.hex(8)}",
      object: "chat.completion",
      created: Time.now.to_i,
      model: model,
      choices: [{
        index: 0,
        message: {
          role: "assistant",
          content: nil,
          tool_calls: formatted_tool_calls
        },
        finish_reason: "tool_calls"
      }],
      usage: { prompt_tokens: 20, completion_tokens: 5, total_tokens: 25 }
    }

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
  end

  # Stub a handoff tool call (convenience method)
  #
  # @param target_agent [String] The agent to hand off to
  def stub_handoff_chat(target_agent:)
    tool_name = "handoff_to_#{target_agent.downcase.gsub(/\s+/, "")}"

    stub_tool_call_chat(
      tool_calls: [{
        name: tool_name,
        arguments: "{}"
      }]
    )
  end

  # Stub a sequence of chat responses (for multi-turn conversations)
  #
  # @param responses [Array] Array of response configurations
  #   Each can be a String (simple text) or Hash (detailed config)
  def stub_chat_sequence(*responses)
    stub_chain = nil

    responses.each do |response|
      current_stub = if response.is_a?(String)
                       build_simple_response(response)
                     elsif response[:tool_calls]
                       build_tool_call_response(response[:tool_calls])
                     else
                       build_simple_response(response[:content] || "Response", response)
                     end

      if stub_chain
        stub_chain = stub_chain.then.to_return(status: 200, body: current_stub.to_json,
                                               headers: { "Content-Type" => "application/json" })
      else
        stub_chain = stub_request(:post, "https://api.openai.com/v1/chat/completions")
                     .to_return(status: 200, body: current_stub.to_json, headers: { "Content-Type" => "application/json" })
      end
    end

    stub_chain
  end

  # Stub OpenAI configuration for tests (prevents real API calls)
  def setup_openai_test_config
    RubyLLM.configure do |config|
      config.openai_api_key = "test"
    end
  end

  # Disable network connections except for stubbed requests
  def disable_net_connect!
    WebMock.disable_net_connect!
  end

  # Re-enable network connections
  def allow_net_connect!
    WebMock.allow_net_connect!
  end

  private

  def build_simple_response(content, options = {})
    {
      id: "chatcmpl-#{SecureRandom.hex(8)}",
      object: "chat.completion",
      created: Time.now.to_i,
      model: options[:model] || "gpt-4o",
      choices: [{
        index: 0,
        message: {
          role: "assistant",
          content: content
        },
        finish_reason: "stop"
      }],
      usage: options[:usage] || { prompt_tokens: 10, completion_tokens: 8, total_tokens: 18 }
    }
  end

  def build_tool_call_response(tool_calls)
    formatted_tool_calls = tool_calls.map do |call|
      {
        id: call[:id] || "call_#{SecureRandom.hex(4)}",
        type: "function",
        function: {
          name: call[:name],
          arguments: call[:arguments].is_a?(String) ? call[:arguments] : call[:arguments].to_json
        }
      }
    end

    {
      id: "chatcmpl-#{SecureRandom.hex(8)}",
      object: "chat.completion",
      created: Time.now.to_i,
      model: "gpt-4o",
      choices: [{
        index: 0,
        message: {
          role: "assistant",
          content: nil,
          tool_calls: formatted_tool_calls
        },
        finish_reason: "tool_calls"
      }],
      usage: { prompt_tokens: 20, completion_tokens: 5, total_tokens: 25 }
    }
  end
end
