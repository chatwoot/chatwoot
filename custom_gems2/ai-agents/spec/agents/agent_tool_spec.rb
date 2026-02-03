# frozen_string_literal: true

require "spec_helper"

RSpec.describe Agents::AgentTool do
  let(:test_agent) do
    Agents::Agent.new(
      name: "Test Agent",
      instructions: "You are a test agent that echoes input",
      model: "gpt-4o-mini"
    )
  end

  let(:tool_context) do
    run_context = Agents::RunContext.new({ state: { user_id: 123 } })
    Agents::ToolContext.new(run_context: run_context)
  end

  describe "#initialize" do
    it "creates an agent tool with default settings" do
      agent_tool = described_class.new(agent: test_agent)

      expect(agent_tool.wrapped_agent).to eq(test_agent)
      expect(agent_tool.name).to eq("test_agent")
      expect(agent_tool.description).to eq("Execute Test Agent agent")
      expect(agent_tool.output_extractor).to be_nil
    end

    it "creates an agent tool with custom name and description" do
      agent_tool = described_class.new(
        agent: test_agent,
        name: "custom_tool",
        description: "Custom description"
      )

      expect(agent_tool.name).to eq("custom_tool")
      expect(agent_tool.description).to eq("Custom description")
    end

    it "creates an agent tool with output extractor" do
      extractor = ->(result) { "Extracted: #{result.output}" }
      agent_tool = described_class.new(
        agent: test_agent,
        output_extractor: extractor
      )

      expect(agent_tool.output_extractor).to eq(extractor)
    end

    it "transforms agent names to snake_case" do
      agent_with_spaces = Agents::Agent.new(
        name: "My Complex Agent Name!",
        instructions: "Test",
        model: "gpt-4o-mini"
      )

      agent_tool = described_class.new(agent: agent_with_spaces)
      expect(agent_tool.name).to eq("my_complex_agent_name")
    end
  end

  describe "#perform" do
    let(:agent_tool) { described_class.new(agent: test_agent) }
    let(:mock_runner) { instance_double(Agents::Runner) }
    let(:mock_result) do
      instance_double(
        Agents::RunResult,
        output: "Test response",
        error: nil
      )
    end

    before do
      allow(Agents::Runner).to receive(:new).and_return(mock_runner)
      allow(mock_runner).to receive(:run).and_return(mock_result)
    end

    it "executes the wrapped agent with input" do
      result = agent_tool.perform(tool_context, input: "Test input")

      expect(Agents::Runner).to have_received(:new)
      expect(mock_runner).to have_received(:run).with(
        test_agent,
        "Test input",
        context: { state: { user_id: 123 } },
        registry: {},
        max_turns: 3
      )
      expect(result).to eq("Test response")
    end

    it "creates isolated context with only state" do
      rich_context = Agents::RunContext.new({
                                              state: { user_id: 123, name: "John" },
                                              conversation_history: [{ role: "user", content: "Hi" }],
                                              current_agent: "SomeAgent",
                                              turn_count: 5,
                                              other_data: "should be filtered"
                                            })
      rich_tool_context = Agents::ToolContext.new(run_context: rich_context)

      agent_tool.perform(rich_tool_context, input: "Test")

      expect(mock_runner).to have_received(:run).with(
        test_agent,
        "Test",
        context: { state: { user_id: 123, name: "John" } },
        registry: {},
        max_turns: 3
      )
    end

    it "handles empty state gracefully" do
      empty_context = Agents::RunContext.new({})
      empty_tool_context = Agents::ToolContext.new(run_context: empty_context)

      agent_tool.perform(empty_tool_context, input: "Test")

      expect(mock_runner).to have_received(:run).with(
        test_agent,
        "Test",
        context: {},
        registry: {},
        max_turns: 3
      )
    end

    it "returns error message when agent execution fails" do
      error_result = instance_double(
        Agents::RunResult,
        output: nil,
        error: StandardError.new("Something went wrong")
      )
      allow(mock_runner).to receive(:run).and_return(error_result)

      result = agent_tool.perform(tool_context, input: "Test")

      expect(result).to eq("Agent execution failed: Something went wrong")
    end

    it "returns fallback message when agent returns no output" do
      no_output_result = instance_double(
        Agents::RunResult,
        output: nil,
        error: nil
      )
      allow(mock_runner).to receive(:run).and_return(no_output_result)

      result = agent_tool.perform(tool_context, input: "Test")

      expect(result).to eq("No output from Test Agent")
    end

    it "handles runtime exceptions gracefully" do
      allow(mock_runner).to receive(:run).and_raise(StandardError.new("Runtime error"))

      result = agent_tool.perform(tool_context, input: "Test")

      expect(result).to eq("Error executing Test Agent: Runtime error")
    end

    context "with output extractor" do
      let(:extractor) { ->(result) { "Extracted: #{result.output}" } }
      let(:agent_tool) do
        described_class.new(
          agent: test_agent,
          output_extractor: extractor
        )
      end

      it "uses output extractor to transform result" do
        result = agent_tool.perform(tool_context, input: "Test")

        expect(result).to eq("Extracted: Test response")
      end
    end
  end

  describe "#transform_agent_name" do
    let(:agent_tool) { described_class.new(agent: test_agent) }

    it "converts to lowercase" do
      expect(agent_tool.send(:transform_agent_name, "UPPERCASE")).to eq("uppercase")
    end

    it "replaces spaces with underscores" do
      expect(agent_tool.send(:transform_agent_name, "Agent With Spaces")).to eq("agent_with_spaces")
    end

    it "removes special characters" do
      expect(agent_tool.send(:transform_agent_name, "Agent-Name!@#")).to eq("agentname")
    end

    it "preserves valid characters" do
      expect(agent_tool.send(:transform_agent_name, "agent_name_123")).to eq("agent_name_123")
    end
  end

  describe "#create_isolated_context" do
    let(:agent_tool) { described_class.new(agent: test_agent) }

    it "copies only state from parent context" do
      parent_context = {
        state: { user_id: 123, session: "abc" },
        conversation_history: [{ role: "user", content: "Hi" }],
        current_agent: "SomeAgent",
        turn_count: 5,
        other_field: "value"
      }

      isolated = agent_tool.send(:create_isolated_context, parent_context)

      expect(isolated).to eq({ state: { user_id: 123, session: "abc" } })
    end

    it "returns empty hash when no state exists" do
      parent_context = {
        conversation_history: [{ role: "user", content: "Hi" }],
        current_agent: "SomeAgent"
      }

      isolated = agent_tool.send(:create_isolated_context, parent_context)

      expect(isolated).to eq({})
    end

    it "handles nil state gracefully" do
      parent_context = { state: nil }

      isolated = agent_tool.send(:create_isolated_context, parent_context)

      expect(isolated).to eq({})
    end
  end

  describe "integration with RubyLLM::Tool" do
    let(:agent_tool) { described_class.new(agent: test_agent) }

    it "inherits from Agents::Tool which inherits from RubyLLM::Tool" do
      expect(agent_tool).to be_a(Agents::Tool)
      expect(agent_tool).to be_a(RubyLLM::Tool)
    end

    it "has the correct parameter definition" do
      # This tests that the param class method worked correctly
      parameters = agent_tool.class.instance_variable_get(:@parameters)
      expect(parameters).to have_key(:input)
      expect(parameters[:input].name).to eq(:input)
      expect(parameters[:input].type).to eq("string")
    end

    it "responds to execute method from parent Tool class" do
      expect(agent_tool).to respond_to(:execute)
    end
  end
end
