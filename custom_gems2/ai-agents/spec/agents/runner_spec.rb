# frozen_string_literal: true

require "webmock/rspec"
require_relative "../../lib/agents"

RSpec.describe Agents::Runner do
  include OpenAITestHelper

  before do
    setup_openai_test_config
    disable_net_connect!
  end

  after do
    allow_net_connect!
  end

  let(:agent) do
    instance_double(Agents::Agent,
                    name: "TestAgent",
                    model: "gpt-4o",
                    tools: [],
                    handoff_agents: [],
                    temperature: 0.7,
                    response_schema: nil,
                    get_system_prompt: "You are a helpful assistant",
                    headers: {})
  end

  let(:handoff_agent) do
    instance_double(Agents::Agent,
                    name: "HandoffAgent",
                    model: "gpt-4o",
                    tools: [],
                    handoff_agents: [],
                    temperature: 0.7,
                    response_schema: nil,
                    get_system_prompt: "You are a specialist",
                    headers: {})
  end

  let(:test_tool) do
    instance_double(Agents::Tool,
                    name: "test_tool",
                    description: "A test tool",
                    parameters: {},
                    call: "tool result")
  end

  describe ".with_agents" do
    it "returns an AgentRunner instance" do
      result = described_class.with_agents(agent, handoff_agent)
      expect(result).to be_a(Agents::AgentRunner)
    end

    it "passes all agents to AgentRunner constructor" do
      allow(Agents::AgentRunner).to receive(:new).with([agent, handoff_agent])
      described_class.with_agents(agent, handoff_agent)
      expect(Agents::AgentRunner).to have_received(:new).with([agent, handoff_agent])
    end
  end

  describe "#run" do
    let(:runner) { described_class.new }

    context "when simple conversation without tools" do
      before do
        stub_simple_chat("Hello! How can I help you?")
      end

      it "completes simple conversation in single turn" do
        result = runner.run(agent, "Hello")

        expect(result).to be_a(Agents::RunResult)
        expect(result.output).to eq("Hello! How can I help you?")
        expect(result.success?).to be true
        expect(result.messages).to include(
          hash_including(role: :user, content: "Hello"),
          hash_including(role: :assistant, content: "Hello! How can I help you?")
        )
      end

      it "includes context in result" do
        result = runner.run(agent, "Hello", context: { user_id: 123 })

        expect(result.context).to include(user_id: 123)
        expect(result.context).to include(:conversation_history)
        expect(result.context).to include(turn_count: 1)
        expect(result.context).to include(:last_updated)
      end
    end

    context "with custom headers" do
      it "passes runtime headers to RubyLLM chat" do
        mock_chat = instance_double(RubyLLM::Chat)
        mock_response = instance_double(RubyLLM::Message, tool_call?: false, content: "Hello with headers",
                                                          input_tokens: 10, output_tokens: 5)
        headers = { "X-Test" => "value" }

        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(mock_chat).to receive(:add_message)
        allow(Agents::Helpers::MessageExtractor).to receive(:extract_messages).and_return([])
        allow(mock_chat).to receive_messages(with_instructions: mock_chat, with_temperature: mock_chat,
                                             with_tools: mock_chat, with_schema: mock_chat, with_model: mock_chat, ask: mock_response)

        expect(mock_chat).to receive(:with_headers).with("X-Test": "value").and_return(mock_chat)

        result = runner.run(agent, "Hello", headers: headers)

        expect(result.output).to eq("Hello with headers")
      end

      it "applies agent default headers when runtime headers are absent" do
        mock_chat = instance_double(RubyLLM::Chat)
        mock_response = instance_double(RubyLLM::Message, tool_call?: false, content: "Hello with agent headers",
                                                          input_tokens: 10, output_tokens: 5)

        allow(agent).to receive(:headers).and_return({ "X-Agent" => "agent-value" })
        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(mock_chat).to receive(:add_message)
        allow(Agents::Helpers::MessageExtractor).to receive(:extract_messages).and_return([])
        allow(mock_chat).to receive_messages(with_instructions: mock_chat, with_temperature: mock_chat,
                                             with_tools: mock_chat, with_schema: mock_chat, with_model: mock_chat, ask: mock_response)

        expect(mock_chat).to receive(:with_headers).with("X-Agent": "agent-value").and_return(mock_chat)

        result = runner.run(agent, "Hello")

        expect(result.output).to eq("Hello with agent headers")
      end

      it "merges headers giving runtime precedence over agent defaults" do
        mock_chat = instance_double(RubyLLM::Chat)
        mock_response = instance_double(RubyLLM::Message, tool_call?: false, content: "Hello with merged headers",
                                                          input_tokens: 10, output_tokens: 5)
        runtime_headers = {
          "X-Shared" => "runtime",
          "X-Runtime-Only" => "runtime-only"
        }

        allow(agent).to receive(:headers).and_return({ "X-Shared" => "agent", "X-Agent-Only" => "agent-only" })
        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(mock_chat).to receive(:add_message)
        allow(Agents::Helpers::MessageExtractor).to receive(:extract_messages).and_return([])
        allow(mock_chat).to receive_messages(with_instructions: mock_chat, with_temperature: mock_chat,
                                             with_tools: mock_chat, with_schema: mock_chat, with_model: mock_chat, ask: mock_response)

        expect(mock_chat).to receive(:with_headers).with(
          "X-Shared": "runtime",
          "X-Agent-Only": "agent-only",
          "X-Runtime-Only": "runtime-only"
        ).and_return(mock_chat)

        result = runner.run(agent, "Hello", headers: runtime_headers)

        expect(result.output).to eq("Hello with merged headers")
      end
    end

    context "with conversation history" do
      let(:context_with_history) do
        {
          conversation_history: [
            { role: :user, content: "What's 2+2?" },
            { role: :assistant, content: "2+2 equals 4." }
          ]
        }
      end

      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              id: "chatcmpl-456",
              object: "chat.completion",
              created: 1_677_652_288,
              model: "gpt-4o",
              choices: [{
                index: 0,
                message: {
                  role: "assistant",
                  content: "Yes, that's correct! Is there anything else?"
                },
                finish_reason: "stop"
              }],
              usage: { prompt_tokens: 25, completion_tokens: 12, total_tokens: 37 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "restores conversation history" do
        result = runner.run(agent, "Thanks for confirming", context: context_with_history)

        expect(result.success?).to be true
        expect(result.output).to eq("Yes, that's correct! Is there anything else?")
        expect(result.messages.length).to eq(4) # 2 from history + 2 new
      end

      context "with string roles in history" do
        let(:context_with_string_roles) do
          {
            conversation_history: [
              { role: "user", content: "What's 2+2?" },
              { role: "assistant", content: "2+2 equals 4." }
            ]
          }
        end

        it "handles string roles correctly" do
          result = runner.run(agent, "Thanks for confirming", context: context_with_string_roles)

          expect(result.success?).to be true
          expect(result.output).to eq("Yes, that's correct! Is there anything else?")
          expect(result.messages.length).to eq(4) # 2 from history + 2 new
        end
      end
    end

    context "with tool message history" do
      let(:context_with_tool_history) do
        {
          conversation_history: [
            { role: :user, content: "What's the weather in SF?" },
            {
              role: :assistant,
              content: "Let me check that for you",
              tool_calls: [
                { id: "call_123", name: "get_weather", arguments: { location: "SF" } }
              ]
            },
            { role: :tool, content: "72°F, Sunny", tool_call_id: "call_123" },
            { role: :assistant, content: "It's 72°F and sunny in SF!" }
          ]
        }
      end

      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              id: "chatcmpl-789",
              object: "chat.completion",
              created: 1_677_652_300,
              model: "gpt-4o",
              choices: [{
                index: 0,
                message: {
                  role: "assistant",
                  content: "Great weather for a walk!"
                },
                finish_reason: "stop"
              }],
              usage: { prompt_tokens: 50, completion_tokens: 10, total_tokens: 60 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "restores tool messages with tool_call_id" do
        result = runner.run(agent, "Should I go outside?", context: context_with_tool_history)

        expect(result.success?).to be true
        expect(result.output).to eq("Great weather for a walk!")
        # Should have all history messages + new user message + new assistant message
        expect(result.messages.length).to eq(6)
      end

      it "preserves conversation flow with tool execution context" do
        result = runner.run(agent, "Thanks!", context: context_with_tool_history)

        expect(result.success?).to be true
        # Verify we have the complete conversation history restored
        # NOTE: tool_calls arrays are not restored on assistant messages (see runner.rb NOTE)
        # What matters is: assistant content + tool result messages preserve the conversation flow
        expect(result.messages.length).to be >= 4 # At minimum, history messages are preserved

        # Verify assistant message content is preserved
        assistant_msg = result.messages.find do |msg|
          msg[:role] == :assistant && msg[:content].include?("Let me check")
        end
        expect(assistant_msg).not_to be_nil
      end

      it "restores tool result messages with tool_call_id" do
        result = runner.run(agent, "Thanks!", context: context_with_tool_history)

        expect(result.success?).to be true
        # Verify tool result message is preserved
        tool_message = result.messages.find { |msg| msg[:role] == :tool }
        expect(tool_message).not_to be_nil
        expect(tool_message[:content]).to eq("72°F, Sunny")
        expect(tool_message[:tool_call_id]).to eq("call_123")
      end

      context "with multiple tool calls in single turn" do
        let(:context_with_multiple_tools) do
          {
            conversation_history: [
              { role: :user, content: "Compare weather in SF and LA" },
              {
                role: :assistant,
                content: "Let me check both cities",
                tool_calls: [
                  { id: "call_1", name: "get_weather", arguments: { location: "SF" } },
                  { id: "call_2", name: "get_weather", arguments: { location: "LA" } }
                ]
              },
              { role: :tool, content: "72°F, Sunny", tool_call_id: "call_1" },
              { role: :tool, content: "85°F, Partly cloudy", tool_call_id: "call_2" },
              { role: :assistant, content: "SF is 72°F and sunny, LA is 85°F and partly cloudy" }
            ]
          }
        end

        before do
          stub_request(:post, "https://api.openai.com/v1/chat/completions")
            .to_return(
              status: 200,
              body: {
                id: "chatcmpl-multi",
                object: "chat.completion",
                created: 1_677_652_400,
                model: "gpt-4o",
                choices: [{
                  index: 0,
                  message: {
                    role: "assistant",
                    content: "SF has better weather today!"
                  },
                  finish_reason: "stop"
                }],
                usage: { prompt_tokens: 80, completion_tokens: 8, total_tokens: 88 }
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "restores all tool messages in correct order" do
          result = runner.run(agent, "Which is better?", context: context_with_multiple_tools)

          expect(result.success?).to be true
          expect(result.output).to eq("SF has better weather today!")

          tool_messages = result.messages.select { |msg| msg[:role] == :tool }
          expect(tool_messages.length).to eq(2)
          expect(tool_messages[0][:tool_call_id]).to eq("call_1")
          expect(tool_messages[1][:tool_call_id]).to eq("call_2")
        end
      end

      context "with tool_calls stored using string keys" do
        let(:context_with_string_tool_calls) do
          {
            conversation_history: [
              { role: :user, content: "What's the weather in SF?" },
              {
                role: :assistant,
                content: "Let me check that for you",
                tool_calls: [
                  { "id" => "call_123", "name" => "get_weather", "arguments" => { "location" => "SF" } }
                ]
              },
              { role: :tool, content: "72°F, Sunny", tool_call_id: "call_123" },
              { role: :assistant, content: "It's 72°F and sunny in SF!" }
            ]
          }
        end

        before do
          stub_simple_chat("Clear skies ahead!")
        end

        it "restores tool_calls and tool results when tool_call ids are string keyed" do
          result = runner.run(agent, "Anything else?", context: context_with_string_tool_calls)

          expect(result.success?).to be true

          tool_message = result.messages.find { |msg| msg[:role] == :tool }
          expect(tool_message).not_to be_nil
          expect(tool_message[:tool_call_id]).to eq("call_123")

          assistant_with_tools = result.messages.find do |msg|
            msg[:role] == :assistant && msg[:tool_calls]&.any?
          end
          expect(assistant_with_tools).not_to be_nil
          expect(assistant_with_tools[:tool_calls].first[:id]).to eq("call_123")
        end
      end

      context "with empty tool result" do
        let(:context_with_empty_tool_result) do
          {
            conversation_history: [
              { role: :user, content: "Check status" },
              {
                role: :assistant,
                content: "Checking...",
                tool_calls: [{ id: "call_empty", name: "check_status", arguments: {} }]
              },
              { role: :tool, content: "", tool_call_id: "call_empty" },
              { role: :assistant, content: "Status check complete, no data returned" }
            ]
          }
        end

        before do
          stub_simple_chat("OK")
        end

        it "restores tool messages even with empty content" do
          result = runner.run(agent, "Got it", context: context_with_empty_tool_result)

          expect(result.success?).to be true
          # Empty tool results should still be restored as they're part of the conversation
          tool_message = result.messages.find { |msg| msg[:role] == :tool }
          expect(tool_message).not_to be_nil
          expect(tool_message[:content]).to eq("")
          expect(tool_message[:tool_call_id]).to eq("call_empty")
        end
      end

      context "with invalid tool message (missing tool_call_id)" do
        let(:context_with_invalid_tool) do
          {
            conversation_history: [
              { role: :user, content: "Hello" },
              { role: :tool, content: "Invalid tool result", tool_call_id: nil },
              { role: :assistant, content: "Hi there" }
            ]
          }
        end

        before do
          stub_simple_chat("How can I help?")
          # Set up a mock logger
          logger = instance_double(Logger)
          allow(logger).to receive(:warn)
          Agents.logger = logger
        end

        after do
          Agents.logger = nil
        end

        it "skips tool messages without tool_call_id" do
          result = runner.run(agent, "I need help", context: context_with_invalid_tool)

          expect(result.success?).to be true
          # Invalid tool message should be skipped
          tool_messages = result.messages.select { |msg| msg[:role] == :tool }
          expect(tool_messages).to be_empty
          expect(Agents.logger).to have_received(:warn)
            .with("Skipping tool message without tool_call_id in conversation history")
        end
      end

      context "with hash content in tool result" do
        let(:context_with_hash_content) do
          {
            conversation_history: [
              { role: :user, content: "Get data" },
              {
                role: :assistant,
                content: "Fetching...",
                tool_calls: [{ id: "call_hash", name: "get_data", arguments: {} }]
              },
              {
                role: :tool,
                content: { status: "success", data: { temperature: 72 } },
                tool_call_id: "call_hash"
              },
              { role: :assistant, content: "Data retrieved successfully" }
            ]
          }
        end

        before do
          stub_simple_chat("Anything else?")
        end

        it "restores tool messages with hash content" do
          result = runner.run(agent, "No, thanks", context: context_with_hash_content)

          expect(result.success?).to be true
          tool_message = result.messages.find { |msg| msg[:role] == :tool }
          expect(tool_message).not_to be_nil
          expect(tool_message[:content]).to eq({ status: "success", data: { temperature: 72 } })
          expect(tool_message[:tool_call_id]).to eq("call_hash")
        end
      end

      context "with assistant tool calls that have empty content" do
        let(:context_with_tool_only_assistant) do
          {
            conversation_history: [
              { role: :user, content: "Trigger a tool" },
              {
                role: :assistant,
                content: "",
                tool_calls: [{ id: "call_blank", name: "do_something", arguments: {} }]
              },
              { role: :tool, content: "Done", tool_call_id: "call_blank" }
            ]
          }
        end

        before do
          stub_simple_chat("All set")
        end

        it "restores assistant tool call messages even without text" do
          result = runner.run(agent, "Thanks", context: context_with_tool_only_assistant)

          expect(result.success?).to be true

          assistant_with_tools = result.messages.find do |msg|
            msg[:role] == :assistant && msg[:tool_calls]&.any?
          end

          expect(assistant_with_tools).not_to be_nil
          expect(assistant_with_tools[:content]).to eq("")
          expect(assistant_with_tools[:tool_calls].first[:id]).to eq("call_blank")
        end
      end

      it "restores tool_calls on assistant messages" do
        # As of commit 1cfe99e, tool_calls ARE restored on assistant messages
        # because OpenAI/Anthropic APIs require tool result messages to be
        # preceded by assistant messages with matching tool_calls.
        # See runner.rb:310-321 for implementation.

        # Track what gets added to the chat during restoration
        restored_messages = []
        mock_chat = instance_double(RubyLLM::Chat)

        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(mock_chat).to receive(:add_message) do |msg|
          restored_messages << {
            role: msg.role,
            content: msg.content.to_s,
            tool_calls: msg.tool_calls,
            tool_call: msg.respond_to?(:tool_call?) ? msg.tool_call? : nil
          }
        end

        # Mock other required methods
        allow(mock_chat).to receive_messages(
          with_instructions: mock_chat,
          with_temperature: mock_chat,
          with_tools: mock_chat,
          with_schema: mock_chat,
          with_model: mock_chat,
          messages: [],
          ask: instance_double(RubyLLM::Message,
                               tool_call?: false,
                               content: "Confirmed",
                               is_a?: false)
        )

        # Run with history containing tool_calls
        runner.run(agent, "Verify", context: context_with_tool_history)

        # Find the restored assistant message that had tool_calls in history
        assistant_msg = restored_messages.find do |m|
          m[:role] == :assistant && m[:content].include?("Let me check")
        end

        # Verify expected behavior: both content AND tool_calls are restored
        expect(assistant_msg).not_to be_nil
        expect(assistant_msg[:content]).to eq("Let me check that for you")
        expect(assistant_msg[:tool_calls]).to be_a(Hash)
        expect(assistant_msg[:tool_calls]).not_to be_empty
        expect(assistant_msg[:tool_calls]["call_123"]).not_to be_nil
        expect(assistant_msg[:tool_calls]["call_123"]).to be_a(RubyLLM::ToolCall)
        expect(assistant_msg[:tool_calls]["call_123"].id).to eq("call_123")

        # Tool messages should still be restored normally
        tool_msg = restored_messages.find { |m| m[:role] == :tool }
        expect(tool_msg).not_to be_nil
        expect(tool_msg[:content]).to eq("72°F, Sunny")
      end

      context "with tool_calls missing ids" do
        let(:context_with_missing_tool_call_id) do
          {
            conversation_history: [
              { role: :user, content: "Use a tool" },
              {
                role: :assistant,
                content: "Calling tool",
                tool_calls: [{ name: "add_numbers", arguments: { a: 1, b: 2 } }]
              },
              { role: :tool, content: "3", tool_call_id: "call_missing" }
            ]
          }
        end

        before do
          stub_simple_chat("OK")
        end

        it "skips tool_calls without ids and ignores unmatched tool messages" do
          result = runner.run(agent, "Continue", context: context_with_missing_tool_call_id)

          expect(result.success?).to be true
          assistant_msg = result.messages.find { |msg| msg[:role] == :assistant }
          expect(assistant_msg[:tool_calls]).to be_nil

          tool_messages = result.messages.select { |msg| msg[:role] == :tool }
          expect(tool_messages).to be_empty
        end
      end

      context "with out-of-order tool history" do
        let(:context_with_out_of_order_tool_history) do
          {
            conversation_history: [
              { role: :user, content: "Check status" },
              { role: :tool, content: "OK", tool_call_id: "call_early" },
              {
                role: :assistant,
                content: "Calling tool now",
                tool_calls: [{ id: "call_early", name: "check_status", arguments: {} }]
              }
            ]
          }
        end

        before do
          stub_simple_chat("Done")
        end

        it "skips tool results that appear before their tool_calls" do
          # Current behavior: drop out-of-order tool results because we only accept tool messages
          # after the matching assistant tool_call has been restored. Alternative options:
          # 1) pre-scan history to collect tool_call_ids, or
          # 2) buffer tool results until their tool_call appears later.
          result = runner.run(agent, "Continue", context: context_with_out_of_order_tool_history)

          expect(result.success?).to be true
          tool_messages = result.messages.select { |msg| msg[:role] == :tool }
          expect(tool_messages).to be_empty
        end
      end
    end

    context "when using current_agent from context" do
      let(:context_with_agent) { { current_agent: "HandoffAgent" } }

      before do
        stub_simple_chat("I'm the specialist agent")
      end

      it "stores current agent name in context" do
        registry = { "TestAgent" => agent, "HandoffAgent" => handoff_agent }
        allow(handoff_agent).to receive(:get_system_prompt)

        result = runner.run(agent, "Hello", context: context_with_agent, registry: registry)

        expect(result.success?).to be true
        expect(result.context[:current_agent]).to eq("TestAgent")
      end
    end

    context "when handoff occurs" do
      let(:agent_with_handoffs) do
        instance_double(Agents::Agent,
                        name: "TriageAgent",
                        model: "gpt-4o",
                        tools: [],
                        handoff_agents: [handoff_agent],
                        temperature: 0.7,
                        response_schema: nil,
                        get_system_prompt: "You route users to specialists",
                        headers: {})
      end

      before do
        # First request - triage agent decides to handoff
        # After handoff, the specialist agent responds
        stub_chat_sequence(
          { tool_calls: [{ name: "handoff_to_handoffagent", arguments: "{}" }] },
          "Hello, I'm the specialist. How can I help?"
        )
      end

      it "switches to handoff agent and continues conversation" do
        registry = { "TriageAgent" => agent_with_handoffs, "HandoffAgent" => handoff_agent }
        result = runner.run(agent_with_handoffs, "I need specialist help", registry: registry)

        expect(result.success?).to be true
        expect(result.output).to eq("Hello, I'm the specialist. How can I help?")
        expect(result.context[:current_agent]).to eq("HandoffAgent")
      end

      it "returns error when handoff to unregistered agent is attempted" do
        # Only register the triage agent, not the handoff target
        registry = { "TriageAgent" => agent_with_handoffs }

        # Mock only the first tool call that triggers handoff
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              id: "chatcmpl-handoff",
              object: "chat.completion",
              created: 1_677_652_288,
              model: "gpt-4o",
              choices: [{
                index: 0,
                message: {
                  role: "assistant",
                  content: nil,
                  tool_calls: [{
                    id: "call_handoff",
                    type: "function",
                    function: {
                      name: "handoff_to_handoffagent",
                      arguments: "{}"
                    }
                  }]
                },
                finish_reason: "tool_calls"
              }],
              usage: { prompt_tokens: 20, completion_tokens: 5, total_tokens: 25 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = runner.run(agent_with_handoffs, "I need specialist help", registry: registry)

        expect(result.failed?).to be true
        expect(result.error).to be_a(Agents::Runner::AgentNotFoundError)
        expect(result.error.message).to eq("Handoff failed: Agent 'HandoffAgent' not found in registry")
        expect(result.output).to be_nil
        expect(result.context[:current_agent]).to eq("TriageAgent")
        expect(result.context[:pending_handoff]).to be_nil # Should clear pending handoff
      end
    end

    context "when max_turns is exceeded" do
      it "raises MaxTurnsExceeded and returns error result" do
        # Mock chat to always return tool_call? = true, causing infinite loop
        mock_chat = instance_double(RubyLLM::Chat)
        mock_response = instance_double(RubyLLM::Message, tool_call?: true,
                                                          input_tokens: 10, output_tokens: 5)

        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(runner).to receive_messages(
          configure_chat_for_agent: mock_chat,
          restore_conversation_history: nil,
          save_conversation_state: nil
        )
        allow(mock_chat).to receive_messages(ask: mock_response, complete: mock_response)

        result = runner.run(agent, "Start infinite loop", max_turns: 2)

        expect(result.failed?).to be true
        expect(result.error).to be_a(Agents::Runner::MaxTurnsExceeded)
        expect(result.output).to include("Exceeded maximum turns: 2")
        expect(result.context).to be_a(Hash)
        expect(result.messages).to eq([])
      end
    end

    context "when standard error occurs" do
      it "handles errors gracefully and returns error result" do
        # Mock chat creation to raise an error
        allow(RubyLLM::Chat).to receive(:new).and_raise(StandardError, "Test error")

        result = runner.run(agent, "Error test")

        expect(result.failed?).to be true
        expect(result.error).to be_a(StandardError)
        expect(result.error.message).to eq("Test error")
        expect(result.output).to be_nil
        expect(result.context).to be_a(Hash)
        expect(result.messages).to eq([])
      end
    end

    context "when respects custom max_turns limit" do
      it "respects custom max_turns limit" do
        # This will pass because we're not hitting the limit
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              id: "chatcmpl-quick",
              object: "chat.completion",
              created: 1_677_652_288,
              model: "gpt-4o",
              choices: [{
                index: 0,
                message: { role: "assistant", content: "Done" },
                finish_reason: "stop"
              }],
              usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = runner.run(agent, "Quick response", max_turns: 1)

        expect(result.success?).to be true
        expect(result.output).to eq("Done")
      end
    end

    context "when halt response occurs without handoff" do
      it "returns halt content as final response" do
        # Mock chat to return a halt without pending_handoff
        mock_chat = instance_double(RubyLLM::Chat)
        mock_halt = instance_double(RubyLLM::Tool::Halt, content: "Processing complete", is_a?: true)

        allow(mock_halt).to receive(:is_a?).with(RubyLLM::Tool::Halt).and_return(true)
        allow(RubyLLM::Chat).to receive(:new).and_return(mock_chat)
        allow(runner).to receive_messages(
          configure_chat_for_agent: mock_chat,
          restore_conversation_history: nil,
          save_conversation_state: nil
        )
        allow(mock_chat).to receive(:ask).and_return(mock_halt)

        result = runner.run(agent, "Test halt")

        expect(result.success?).to be true
        expect(result.output).to eq("Processing complete")
        expect(result.context).to be_a(Hash)
      end
    end

    context "when using response_schema" do
      let(:schema) do
        {
          type: "object",
          properties: {
            answer: { type: "string" },
            confidence: { type: "number" }
          },
          required: %w[answer confidence]
        }
      end

      let(:agent_with_schema) do
        instance_double(Agents::Agent,
                        name: "StructuredAgent",
                        model: "gpt-4o",
                        tools: [],
                        handoff_agents: [],
                        temperature: 0.7,
                        response_schema: schema,
                        get_system_prompt: "You provide structured responses",
                        headers: {})
      end

      it "includes response_schema in API request" do
        # Expect the request to include response_format with our schema
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(body: hash_including({
                                       "response_format" => {
                                         "type" => "json_schema",
                                         "json_schema" => {
                                           "name" => "response",
                                           "schema" => schema,
                                           "strict" => true
                                         }
                                       }
                                     }))
          .to_return(status: 200, body: {
            id: "test", object: "chat.completion", created: Time.now.to_i, model: "gpt-4o",
            choices: [{ index: 0, message: { role: "assistant", content: "any response" }, finish_reason: "stop" }],
            usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 }
          }.to_json, headers: { "Content-Type" => "application/json" })

        runner.run(
          agent_with_schema,
          "What is the answer?",
          context: {},
          registry: { "StructuredAgent" => agent_with_schema },
          max_turns: 1
        )

        # If we get here without WebMock raising an error, the request included the schema
      end

      context "when conversation history contains Hash content from structured output" do
        it "processes messages with Hash content without raising strip errors" do
          # Set up conversation history with Hash content
          context_with_hash_content = {
            conversation_history: [
              { role: :user, content: "What is 2+2?" },
              { role: :assistant, content: { "answer" => "4", "confidence" => 1.0 }, agent_name: "StructuredAgent" }
            ],
            current_agent: "StructuredAgent"
          }

          # Stub simple OpenAI response for the new message
          stub_simple_chat('{"answer": "6", "confidence": 0.9}')

          # This should work without throwing NoMethodError on Hash#strip
          result = runner.run(
            agent_with_schema,
            "What about 3+3?",
            context: context_with_hash_content,
            registry: { "StructuredAgent" => agent_with_schema },
            max_turns: 1
          )

          expect(result.success?).to be true
          expect(result.output).to eq({ "answer" => "6", "confidence" => 0.9 })
        end
      end
    end

    context "when agent has regular tools" do
      let(:agent_with_tools) do
        instance_double(Agents::Agent,
                        name: "ToolAgent",
                        model: "gpt-4o",
                        tools: [test_tool],
                        handoff_agents: [],
                        temperature: 0.7,
                        response_schema: nil,
                        get_system_prompt: "You are an agent with tools",
                        headers: {})
      end

      it "wraps regular tools in ToolWrapper" do
        # Spy on ToolWrapper constructor
        allow(Agents::ToolWrapper).to receive(:new).and_call_original

        # Stub a simple response that doesn't use tools
        stub_simple_chat("I have tools available")

        runner.run(
          agent_with_tools,
          "Hello",
          context: {},
          registry: { "ToolAgent" => agent_with_tools },
          max_turns: 1
        )

        # Verify ToolWrapper was called with the regular tool
        expect(Agents::ToolWrapper).to have_received(:new).with(test_tool, anything)
      end
    end

    context "lifecycle callbacks" do
      let(:runner) { described_class.new }
      let(:callbacks_called) { [] }
      let(:callbacks) do
        {
          run_start: [proc { |agent, input, ctx| callbacks_called << [:run_start, agent, input, ctx.class.name] }],
          run_complete: [proc { |agent, result, ctx|
            callbacks_called << [:run_complete, agent, result.class.name, ctx.class.name]
          }],
          agent_complete: [proc { |agent, result, error, ctx|
            callbacks_called << [:agent_complete, agent, result&.class&.name, error&.class&.name, ctx.class.name]
          }],
          agent_thinking: [proc { |agent, input| callbacks_called << [:agent_thinking, agent, input] }],
          tool_start: [proc { |tool, args| callbacks_called << [:tool_start, tool, args] }],
          tool_complete: [proc { |tool, result| callbacks_called << [:tool_complete, tool, result] }],
          agent_handoff: [proc { |from, to, reason| callbacks_called << [:agent_handoff, from, to, reason] }]
        }
      end

      it "emits run_start and run_complete for successful execution" do
        stub_simple_chat("Hello!")

        result = runner.run(agent, "Test", callbacks: callbacks)

        expect(result.success?).to be true
        expect(callbacks_called).to include(
          [:run_start, "TestAgent", "Test", "Agents::RunContext"]
        )
        expect(callbacks_called).to include(
          [:run_complete, "TestAgent", "Agents::RunResult", "Agents::RunContext"]
        )
      end

      it "emits agent_complete with nil error for successful execution" do
        stub_simple_chat("Success")

        runner.run(agent, "Test", callbacks: callbacks)

        agent_complete_call = callbacks_called.find { |c| c[0] == :agent_complete }
        expect(agent_complete_call).not_to be_nil
        expect(agent_complete_call[1]).to eq("TestAgent")
        expect(agent_complete_call[2]).to eq("Agents::RunResult")
        expect(agent_complete_call[3]).to be_nil # No error
        expect(agent_complete_call[4]).to eq("Agents::RunContext")
      end

      it "emits callbacks in correct order" do
        stub_simple_chat("Response")

        runner.run(agent, "Test", callbacks: callbacks)

        # Extract just the callback types in order
        callback_types = callbacks_called.map(&:first)

        # Verify run_start comes first
        expect(callback_types.first).to eq(:run_start)

        # Verify run_complete and agent_complete come last
        expect(callback_types[-2..]).to contain_exactly(:agent_complete, :run_complete)
      end

      it "emits agent_complete and run_complete with error on failure" do
        allow(RubyLLM::Chat).to receive(:new).and_raise(StandardError, "Test error")

        result = runner.run(agent, "Test", callbacks: callbacks)

        expect(result.failed?).to be true

        # Check agent_complete was called with error
        agent_complete_call = callbacks_called.find { |c| c[0] == :agent_complete }
        expect(agent_complete_call).not_to be_nil
        expect(agent_complete_call[3]).to eq("StandardError")

        # Check run_complete was still called
        run_complete_call = callbacks_called.find { |c| c[0] == :run_complete }
        expect(run_complete_call).not_to be_nil
      end

      it "emits agent_complete before handoff" do
        agent_with_handoff = instance_double(Agents::Agent,
                                             name: "TriageAgent",
                                             model: "gpt-4o",
                                             tools: [],
                                             handoff_agents: [handoff_agent],
                                             temperature: 0.7,
                                             response_schema: nil,
                                             get_system_prompt: "You route users",
                                             headers: {})

        stub_chat_sequence(
          { tool_calls: [{ name: "handoff_to_handoffagent", arguments: "{}" }] },
          "Specialist here"
        )

        registry = { "TriageAgent" => agent_with_handoff, "HandoffAgent" => handoff_agent }
        runner.run(agent_with_handoff, "Help", registry: registry, callbacks: callbacks)

        callback_types = callbacks_called.map(&:first)

        # Find indices
        agent_complete_idx = callback_types.index(:agent_complete)
        handoff_idx = callback_types.index(:agent_handoff)

        # agent_complete should come before agent_handoff
        expect(agent_complete_idx).not_to be_nil
        expect(handoff_idx).not_to be_nil
        expect(agent_complete_idx).to be < handoff_idx
      end

      it "emits agent_complete and run_complete with error when handoff target not found" do
        agent_with_handoff = instance_double(Agents::Agent,
                                             name: "TriageAgent",
                                             model: "gpt-4o",
                                             tools: [],
                                             handoff_agents: [handoff_agent],
                                             temperature: 0.7,
                                             response_schema: nil,
                                             get_system_prompt: "You route users",
                                             headers: {})

        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: {
              id: "chatcmpl-handoff",
              object: "chat.completion",
              created: 1_677_652_288,
              model: "gpt-4o",
              choices: [{
                index: 0,
                message: {
                  role: "assistant",
                  content: nil,
                  tool_calls: [{
                    id: "call_handoff",
                    type: "function",
                    function: { name: "handoff_to_handoffagent", arguments: "{}" }
                  }]
                },
                finish_reason: "tool_calls"
              }],
              usage: { prompt_tokens: 20, completion_tokens: 5, total_tokens: 25 }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Registry only has TriageAgent, not HandoffAgent
        registry = { "TriageAgent" => agent_with_handoff }
        result = runner.run(agent_with_handoff, "Help", registry: registry, callbacks: callbacks)

        expect(result.failed?).to be true
        expect(result.error).to be_a(Agents::Runner::AgentNotFoundError)

        # Check agent_complete was called with error
        agent_complete_call = callbacks_called.find { |c| c[0] == :agent_complete }
        expect(agent_complete_call).not_to be_nil
        expect(agent_complete_call[1]).to eq("TriageAgent")
        expect(agent_complete_call[3]).to eq("Agents::Runner::AgentNotFoundError")

        # Check run_complete was called
        run_complete_call = callbacks_called.find { |c| c[0] == :run_complete }
        expect(run_complete_call).not_to be_nil
        expect(run_complete_call[1]).to eq("TriageAgent")
      end
    end
  end
end
