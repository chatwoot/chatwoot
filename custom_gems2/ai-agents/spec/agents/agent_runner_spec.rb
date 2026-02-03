# frozen_string_literal: true

require "webmock/rspec"
require_relative "../../lib/agents"

RSpec.describe Agents::AgentRunner do
  include OpenAITestHelper

  before do
    setup_openai_test_config
    disable_net_connect!
  end

  after do
    allow_net_connect!
  end

  let(:triage_agent) do
    instance_double(Agents::Agent,
                    name: "Triage Agent",
                    model: "gpt-4o",
                    tools: [],
                    handoff_agents: [],
                    get_system_prompt: "You are a triage agent")
  end

  let(:billing_agent) do
    instance_double(Agents::Agent,
                    name: "Billing Agent",
                    model: "gpt-4o",
                    tools: [],
                    handoff_agents: [],
                    get_system_prompt: "You are a billing agent")
  end

  let(:support_agent) do
    instance_double(Agents::Agent,
                    name: "Support Agent",
                    model: "gpt-4o",
                    tools: [],
                    handoff_agents: [],
                    get_system_prompt: "You are a support agent")
  end

  # Helper method for mock result
  let(:mock_result) do
    instance_double(Agents::RunResult,
                    output: "Test response",
                    context: {},
                    usage: {})
  end

  describe "#initialize" do
    context "with valid agents" do
      it "creates an agent runner with provided agents" do
        runner = described_class.new([triage_agent, billing_agent, support_agent])
        expect(runner).to be_a(described_class)
      end

      it "sets the first agent as the default" do
        runner = described_class.new([triage_agent, billing_agent, support_agent])

        # Access the default agent through the private method for testing
        default_agent = runner.send(:determine_conversation_agent, {})
        expect(default_agent).to eq(triage_agent)
      end

      it "builds registry from provided agents" do
        runner = described_class.new([triage_agent, billing_agent, support_agent])

        # Access the registry through the private method for testing
        registry = runner.instance_variable_get(:@registry)
        expect(registry).to include(
          "Triage Agent" => triage_agent,
          "Billing Agent" => billing_agent,
          "Support Agent" => support_agent
        )
      end

      it "freezes the agents array for thread safety" do
        agents = [triage_agent, billing_agent]
        runner = described_class.new(agents)

        frozen_agents = runner.instance_variable_get(:@agents)
        expect(frozen_agents).to be_frozen
      end

      it "freezes the registry for thread safety" do
        runner = described_class.new([triage_agent, billing_agent])

        registry = runner.instance_variable_get(:@registry)
        expect(registry).to be_frozen
      end
    end

    context "with invalid input" do
      it "raises ArgumentError when no agents provided" do
        expect { described_class.new([]) }.to raise_error(ArgumentError, "At least one agent must be provided")
      end

      it "raises ArgumentError when nil provided" do
        expect { described_class.new(nil) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#run" do
    let(:runner) { described_class.new([triage_agent, billing_agent, support_agent]) }
    let(:mock_runner_instance) { instance_double(Agents::Runner) }
    let(:mock_result) do
      instance_double(Agents::RunResult,
                      output: "Hello! How can I help?",
                      context: { conversation_history: [], current_agent: "Triage Agent" },
                      usage: {})
    end

    before do
      allow(Agents::Runner).to receive(:new).and_return(mock_runner_instance)
      allow(mock_runner_instance).to receive(:run).and_return(mock_result)
    end

    context "when starting a new conversation with empty context" do
      it "uses the default agent (first in list)" do
        runner.run("Hello")

        expect(mock_runner_instance).to have_received(:run).with(
          triage_agent,
          "Hello",
          context: {},
          registry: hash_including("Triage Agent" => triage_agent),
          max_turns: Agents::Runner::DEFAULT_MAX_TURNS,
          headers: nil,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end

      it "passes through max_turns parameter" do
        runner.run("Hello", max_turns: 5)

        expect(mock_runner_instance).to have_received(:run).with(
          triage_agent,
          "Hello",
          context: {},
          registry: anything,
          max_turns: 5,
          headers: nil,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end

      it "passes custom headers to the runner" do
        headers = { "X-Test" => "value" }

        runner.run("Hello", headers: headers)

        expect(mock_runner_instance).to have_received(:run).with(
          triage_agent,
          "Hello",
          context: {},
          registry: anything,
          max_turns: Agents::Runner::DEFAULT_MAX_TURNS,
          headers: headers,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end
    end

    context "when continuing conversation with history" do
      let(:context_with_history) do
        {
          conversation_history: [
            { role: :user, content: "I need billing help" },
            { role: :assistant, content: "I can help with billing", agent_name: "Billing Agent" },
            { role: :user, content: "What's my balance?" }
          ]
        }
      end

      it "determines agent from conversation history" do
        runner.run("More billing questions", context: context_with_history)

        expect(mock_runner_instance).to have_received(:run).with(
          billing_agent, # Should use Billing Agent based on history
          "More billing questions",
          context: context_with_history,
          registry: anything,
          max_turns: Agents::Runner::DEFAULT_MAX_TURNS,
          headers: nil,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end
    end

    context "when history contains unknown agent" do
      let(:context_with_unknown_agent) do
        {
          conversation_history: [
            { role: :user, content: "Hello" },
            { role: :assistant, content: "Hi there", agent_name: "Unknown Agent" }
          ]
        }
      end

      it "falls back to default agent when agent not in registry" do
        runner.run("Continue conversation", context: context_with_unknown_agent)

        expect(mock_runner_instance).to have_received(:run).with(
          triage_agent, # Should fall back to default
          "Continue conversation",
          context: context_with_unknown_agent,
          registry: anything,
          max_turns: Agents::Runner::DEFAULT_MAX_TURNS,
          headers: nil,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end
    end

    context "when history lacks agent attribution" do
      let(:context_without_attribution) do
        {
          conversation_history: [
            { role: :user, content: "Hello" },
            { role: :assistant, content: "Hi there" } # No agent_name
          ]
        }
      end

      it "falls back to default agent when no agent attribution found" do
        runner.run("Continue", context: context_without_attribution)

        expect(mock_runner_instance).to have_received(:run).with(
          triage_agent, # Should fall back to default
          "Continue",
          context: context_without_attribution,
          registry: anything,
          max_turns: Agents::Runner::DEFAULT_MAX_TURNS,
          headers: nil,
          callbacks: hash_including(
            run_start: [],
            run_complete: [],
            agent_complete: [],
            tool_start: [],
            tool_complete: [],
            agent_thinking: [],
            agent_handoff: []
          )
        )
      end
    end

    it "returns the result from the underlying runner" do
      result = runner.run("Test message")
      expect(result).to eq(mock_result)
    end
  end

  describe "private methods" do
    let(:runner) { described_class.new([triage_agent, billing_agent, support_agent]) }

    describe "#build_registry" do
      it "creates a hash mapping agent names to agents" do
        registry = runner.send(:build_registry, [triage_agent, billing_agent])

        expect(registry).to eq({
                                 "Triage Agent" => triage_agent,
                                 "Billing Agent" => billing_agent
                               })
      end

      it "handles duplicate agent names by using the last occurrence" do
        duplicate_agent = instance_double(Agents::Agent, name: "Triage Agent")
        registry = runner.send(:build_registry, [triage_agent, duplicate_agent])

        expect(registry["Triage Agent"]).to eq(duplicate_agent)
      end
    end

    describe "#determine_conversation_agent" do
      context "with empty context" do
        it "returns the default agent" do
          agent = runner.send(:determine_conversation_agent, {})
          expect(agent).to eq(triage_agent)
        end
      end

      context "with empty conversation history" do
        it "returns the default agent" do
          agent = runner.send(:determine_conversation_agent, { conversation_history: [] })
          expect(agent).to eq(triage_agent)
        end
      end

      context "with conversation history" do
        it "finds the last assistant message with agent attribution" do
          context = {
            conversation_history: [
              { role: :user, content: "Hello" },
              { role: :assistant, content: "Hi", agent_name: "Triage Agent" },
              { role: :user, content: "I need billing help" },
              { role: :assistant, content: "Sure thing", agent_name: "Billing Agent" },
              { role: :user, content: "What's my balance?" }
            ]
          }

          agent = runner.send(:determine_conversation_agent, context)
          expect(agent).to eq(billing_agent)
        end

        it "ignores assistant messages without agent attribution" do
          context = {
            conversation_history: [
              { role: :user, content: "Hello" },
              { role: :assistant, content: "Hi", agent_name: "Billing Agent" },
              { role: :assistant, content: "Additional info" }, # No agent_name
              { role: :user, content: "Continue" }
            ]
          }

          agent = runner.send(:determine_conversation_agent, context)
          expect(agent).to eq(billing_agent) # Should use the attributed message
        end

        it "falls back to default when agent not found in registry" do
          context = {
            conversation_history: [
              { role: :user, content: "Hello" },
              { role: :assistant, content: "Hi", agent_name: "Nonexistent Agent" }
            ]
          }

          agent = runner.send(:determine_conversation_agent, context)
          expect(agent).to eq(triage_agent)
        end

        it "handles missing agent_name gracefully" do
          context = {
            conversation_history: [
              { role: :user, content: "Hello" },
              { role: :assistant, content: "Hi", agent_name: nil }
            ]
          }

          agent = runner.send(:determine_conversation_agent, context)
          expect(agent).to eq(triage_agent)
        end
      end
    end
  end

  describe "thread safety" do
    let(:runner) { described_class.new([triage_agent, billing_agent, support_agent]) }

    it "can be safely used from multiple threads" do
      # Mock the underlying runner to avoid actual LLM calls
      allow(Agents::Runner).to receive(:new).and_return(
        instance_double(Agents::Runner, run: mock_result)
      )

      # Run multiple threads concurrently
      threads = 5.times.map do |i|
        Thread.new do
          runner.run("Message #{i}")
        end
      end

      # Wait for all threads to complete
      results = threads.map(&:value)

      # All threads should complete successfully
      expect(results).to all(eq(mock_result))
      expect(threads).to all(satisfy { |t| !t.alive? })
    end

    it "maintains immutable state across concurrent access" do
      original_registry = runner.instance_variable_get(:@registry)
      original_agents = runner.instance_variable_get(:@agents)

      # Simulate concurrent access
      threads = 3.times.map do
        Thread.new do
          # Access the private methods (simulating internal usage)
          runner.send(:determine_conversation_agent, {})
          runner.send(:build_registry, [triage_agent])
        end
      end

      threads.each(&:join)

      # State should remain unchanged
      expect(runner.instance_variable_get(:@registry)).to eq(original_registry)
      expect(runner.instance_variable_get(:@agents)).to eq(original_agents)
    end
  end

  describe "integration with Agents::Runner.with_agents" do
    it "is returned by the class method" do
      runner = Agents::Runner.with_agents(triage_agent, billing_agent)
      expect(runner).to be_a(described_class)
    end

    it "works with the factory method" do
      allow(Agents::Runner).to receive(:new).and_return(
        instance_double(Agents::Runner, run: mock_result)
      )

      runner = Agents::Runner.with_agents(triage_agent, billing_agent)
      result = runner.run("Test message")

      expect(result).to eq(mock_result)
    end
  end

  describe "callback system" do
    let(:runner) { described_class.new([triage_agent, billing_agent]) }
    let(:mock_runner_instance) { instance_double(Agents::Runner) }

    before do
      allow(Agents::Runner).to receive(:new).and_return(mock_runner_instance)
      allow(mock_runner_instance).to receive(:run).and_return(mock_result)
    end

    describe "callback registration" do
      it "registers tool_start callbacks" do
        callback = proc { |tool_name, _args| "tool started: #{tool_name}" }
        result_runner = runner.on_tool_start(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:tool_start]).to include(callback)
      end

      it "registers tool_complete callbacks" do
        callback = proc { |tool_name, _result| "tool completed: #{tool_name}" }
        result_runner = runner.on_tool_complete(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:tool_complete]).to include(callback)
      end

      it "registers agent_thinking callbacks" do
        callback = proc { |agent_name, _input| "agent thinking: #{agent_name}" }
        result_runner = runner.on_agent_thinking(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:agent_thinking]).to include(callback)
      end

      it "registers agent_handoff callbacks" do
        callback = proc { |from, to, _reason| "handoff: #{from} -> #{to}" }
        result_runner = runner.on_agent_handoff(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:agent_handoff]).to include(callback)
      end

      it "registers run_start callbacks" do
        callback = proc { |agent, input, _context| "run started: #{agent} - #{input}" }
        result_runner = runner.on_run_start(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:run_start]).to include(callback)
      end

      it "registers run_complete callbacks" do
        callback = proc { |agent, _result, _context| "run completed: #{agent}" }
        result_runner = runner.on_run_complete(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:run_complete]).to include(callback)
      end

      it "registers agent_complete callbacks" do
        callback = proc { |agent, _result, _error, _context| "agent completed: #{agent}" }
        result_runner = runner.on_agent_complete(&callback)

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:agent_complete]).to include(callback)
      end

      it "supports method chaining" do
        result_runner = runner
                        .on_tool_start { |_tool, _args| puts "Tool started" }
                        .on_tool_complete { |_tool, _result| puts "Tool completed" }
                        .on_agent_thinking { |_agent, _input| puts "Agent thinking" }
                        .on_agent_handoff { |_from, _to, _reason| puts "Handoff" }

        expect(result_runner).to eq(runner)
        expect(runner.instance_variable_get(:@callbacks)[:tool_start]).not_to be_empty
        expect(runner.instance_variable_get(:@callbacks)[:tool_complete]).not_to be_empty
        expect(runner.instance_variable_get(:@callbacks)[:agent_thinking]).not_to be_empty
        expect(runner.instance_variable_get(:@callbacks)[:agent_handoff]).not_to be_empty
      end

      it "accumulates multiple callbacks for the same event" do
        callback1 = proc { |_tool, _args| puts "Callback 1" }
        callback2 = proc { |_tool, _args| puts "Callback 2" }

        runner.on_tool_start(&callback1)
        runner.on_tool_start(&callback2)

        expect(runner.instance_variable_get(:@callbacks)[:tool_start]).to include(callback1, callback2)
      end
    end

    describe "callback passing to runner" do
      it "passes registered callbacks to the underlying runner" do
        tool_callback = proc { |_tool, _args| puts "Tool callback" }
        agent_callback = proc { |_agent, _input| puts "Agent callback" }

        runner.on_tool_start(&tool_callback)
        runner.on_agent_thinking(&agent_callback)
        runner.run("Test message")

        expect(mock_runner_instance).to have_received(:run).with(
          anything,
          anything,
          hash_including(
            callbacks: hash_including(
              tool_start: [tool_callback],
              agent_thinking: [agent_callback],
              tool_complete: [],
              agent_handoff: [],
              run_start: [],
              run_complete: [],
              agent_complete: []
            )
          )
        )
      end

      it "passes empty callback arrays when no callbacks registered" do
        runner.run("Test message")

        expect(mock_runner_instance).to have_received(:run).with(
          anything,
          anything,
          hash_including(
            callbacks: {
              run_start: [],
              run_complete: [],
              agent_complete: [],
              tool_start: [],
              tool_complete: [],
              agent_thinking: [],
              agent_handoff: []
            }
          )
        )
      end
    end

    describe "thread safety with callbacks" do
      it "maintains callback isolation between threads" do
        results = {}
        runners = []

        threads = 3.times.map do |i|
          Thread.new do
            local_runner = described_class.new([triage_agent])
            local_runner.on_tool_start { |_tool, _args| results[i] = "Thread #{i}" }
            runners[i] = local_runner
            i
          end
        end

        thread_results = threads.map(&:value)

        expect(thread_results).to contain_exactly(0, 1, 2)
        expect(runners.length).to eq(3)

        # Verify each runner has its own callback storage
        runners.each_with_index do |runner, _i|
          callbacks = runner.instance_variable_get(:@callbacks)[:tool_start]
          expect(callbacks.length).to eq(1)
        end
      end

      it "safely handles concurrent callback registration on same runner" do
        runner = described_class.new([triage_agent])
        registered_callbacks = []

        # 10 threads concurrently registering callbacks on the same runner
        threads = 10.times.map do |i|
          Thread.new do
            callback = proc { |_tool, _args| "Callback #{i}" }
            runner.on_tool_start(&callback)
            registered_callbacks << callback
          end
        end

        threads.each(&:join)

        # All callbacks should be registered without data corruption
        final_callbacks = runner.instance_variable_get(:@callbacks)[:tool_start]
        expect(final_callbacks.length).to eq(10)
        expect(registered_callbacks.length).to eq(10)
      end
    end
  end
end
