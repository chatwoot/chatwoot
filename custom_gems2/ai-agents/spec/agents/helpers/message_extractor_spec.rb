# frozen_string_literal: true

require "spec_helper"

RSpec.describe Agents::Helpers::MessageExtractor do
  let(:current_agent) { instance_double(Agents::Agent, name: "TestAgent") }

  describe ".extract_messages" do
    context "when chat has no messages method" do
      let(:chat) { double("chat without messages") }

      it "returns empty array" do
        expect(described_class.extract_messages(chat, current_agent)).to eq([])
      end
    end

    context "when chat has messages with Hash content" do
      let(:hash_message) do
        instance_double(RubyLLM::Message,
                        role: :assistant,
                        content: { "answer" => "42", "confidence" => 0.95 },
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:string_message) do
        instance_double(RubyLLM::Message,
                        role: :user,
                        content: "What is the answer?",
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:empty_hash_message) do
        instance_double(RubyLLM::Message,
                        role: :assistant,
                        content: {},
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:chat) { instance_double(RubyLLM::Chat, messages: [string_message, hash_message, empty_hash_message]) }

      it "handles Hash content without calling strip" do
        result = described_class.extract_messages(chat, current_agent)

        expect(result).to include(
          hash_including(
            role: :user,
            content: "What is the answer?"
          )
        )

        expect(result).to include(
          hash_including(
            role: :assistant,
            content: { "answer" => "42", "confidence" => 0.95 },
            agent_name: "TestAgent"
          )
        )

        # Empty hash should be filtered out
        expect(result).not_to include(
          hash_including(content: {})
        )
      end
    end

    context "when chat has messages with empty or whitespace-only string content" do
      let(:empty_string_message) do
        instance_double(RubyLLM::Message,
                        role: :user,
                        content: "",
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:whitespace_message) do
        instance_double(RubyLLM::Message,
                        role: :user,
                        content: "   \n\t  ",
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:valid_message) do
        instance_double(RubyLLM::Message,
                        role: :user,
                        content: "Valid content",
                        tool_call?: false,
                        tool_calls: nil)
      end

      let(:chat) { instance_double(RubyLLM::Chat, messages: [empty_string_message, whitespace_message, valid_message]) }

      it "filters out empty and whitespace-only content" do
        result = described_class.extract_messages(chat, current_agent)

        expect(result).to eq([
                               {
                                 role: :user,
                                 content: "Valid content"
                               }
                             ])
      end
    end

    context "when chat has tool messages" do
      let(:tool_message) do
        instance_double(RubyLLM::Message,
                        role: :tool,
                        content: "Tool result",
                        tool_result?: true,
                        tool_call_id: "call_123")
      end

      let(:chat) { instance_double(RubyLLM::Chat, messages: [tool_message]) }

      it "extracts tool messages correctly" do
        result = described_class.extract_messages(chat, current_agent)

        expect(result).to eq([
                               {
                                 role: :tool,
                                 content: "Tool result",
                                 tool_call_id: "call_123"
                               }
                             ])
      end
    end

    context "when chat has assistant messages with tool calls" do
      let(:tool_call) do
        instance_double(RubyLLM::ToolCall,
                        to_h: {
                          id: "call_123",
                          name: "test_tool",
                          arguments: { param: "value" }
                        })
      end

      let(:assistant_with_tools) do
        instance_double(RubyLLM::Message,
                        role: :assistant,
                        content: "Let me use a tool",
                        tool_call?: true,
                        tool_calls: { "call_123" => tool_call })
      end

      let(:chat) { instance_double(RubyLLM::Chat, messages: [assistant_with_tools]) }

      it "includes tool calls in assistant messages" do
        result = described_class.extract_messages(chat, current_agent)

        expect(result).to eq([
                               {
                                 role: :assistant,
                                 content: "Let me use a tool",
                                 agent_name: "TestAgent",
                                 tool_calls: [
                                   {
                                     id: "call_123",
                                     name: "test_tool",
                                     arguments: { param: "value" }
                                   }
                                 ]
                               }
                             ])
      end
    end

    context "when assistant tool calls have no text content" do
      let(:tool_call) do
        instance_double(RubyLLM::ToolCall,
                        to_h: {
                          id: "call_456",
                          name: "test_tool",
                          arguments: { foo: "bar" }
                        })
      end

      let(:assistant_with_tool_only) do
        instance_double(RubyLLM::Message,
                        role: :assistant,
                        content: nil,
                        tool_call?: true,
                        tool_calls: { "call_456" => tool_call })
      end

      let(:chat) { instance_double(RubyLLM::Chat, messages: [assistant_with_tool_only]) }

      it "preserves the message and tool calls with empty string content" do
        result = described_class.extract_messages(chat, current_agent)

        expect(result).to eq([
                               {
                                 role: :assistant,
                                 content: "",
                                 agent_name: "TestAgent",
                                 tool_calls: [
                                   {
                                     id: "call_456",
                                     name: "test_tool",
                                     arguments: { foo: "bar" }
                                   }
                                 ]
                               }
                             ])
      end
    end
  end

  describe ".content_empty?" do
    it "returns true for empty string" do
      expect(described_class.content_empty?("")).to be true
    end

    it "returns true for whitespace-only string" do
      expect(described_class.content_empty?("   \n\t  ")).to be true
    end

    it "returns false for non-empty string" do
      expect(described_class.content_empty?("Hello")).to be false
    end

    it "returns true for empty hash" do
      expect(described_class.content_empty?({})).to be true
    end

    it "returns false for non-empty hash" do
      expect(described_class.content_empty?({ "key" => "value" })).to be false
    end

    it "returns true for nil" do
      expect(described_class.content_empty?(nil)).to be true
    end

    it "returns false for other non-string, non-hash values" do
      expect(described_class.content_empty?(false)).to be false
      expect(described_class.content_empty?(0)).to be false
      expect(described_class.content_empty?([])).to be false
    end
  end

end
