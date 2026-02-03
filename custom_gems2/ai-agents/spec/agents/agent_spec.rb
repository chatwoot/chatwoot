# frozen_string_literal: true

require_relative "../../lib/agents"

RSpec.describe Agents::Agent do
  let(:test_tool) { instance_double(Agents::Tool, "TestTool") }
  let(:other_agent) { instance_double(described_class, name: "Other Agent") }
  let(:context) { {} }

  describe "#initialize" do
    it "creates agent with required name parameter" do
      agent = described_class.new(name: "Test Agent")

      expect(agent.name).to eq("Test Agent")
      expect(agent.instructions).to be_nil
      expect(agent.model).to eq("gpt-4.1-mini")
      expect(agent.tools).to eq([])
      expect(agent.handoff_agents).to eq([])
      expect(agent.temperature).to eq(0.7)
      expect(agent.headers).to eq({})
      expect(agent.headers).to be_frozen
    end

    it "creates agent with all parameters" do
      instructions = "You are a test agent"
      tools = [test_tool]
      handoff_agents = [other_agent]
      headers = { "X-Test" => "value" }

      agent = described_class.new(
        name: "Test Agent",
        instructions: instructions,
        model: "gpt-4o",
        tools: tools,
        handoff_agents: handoff_agents,
        temperature: 0.9,
        headers: headers
      )

      expect(agent.name).to eq("Test Agent")
      expect(agent.instructions).to eq(instructions)
      expect(agent.model).to eq("gpt-4o")
      expect(agent.tools).to eq(tools)
      expect(agent.handoff_agents).to include(other_agent)
      expect(agent.temperature).to eq(0.9)
      expect(agent.headers).to eq("X-Test": "value")
      expect(agent.headers).not_to be(headers)
      expect(agent.headers).to be_frozen
    end

    it "creates agent with Proc instructions" do
      instructions_proc = proc { |_ctx| "Dynamic instructions" }

      agent = described_class.new(
        name: "Test Agent",
        instructions: instructions_proc
      )

      expect(agent.instructions).to eq(instructions_proc)
    end

    it "duplicates tools array to prevent mutation" do
      tools = [test_tool]
      agent = described_class.new(name: "Test", tools: tools)

      tools << instance_double(Agents::Tool, "AnotherTool")

      expect(agent.tools.size).to eq(1)
    end

    it "creates agent with custom temperature" do
      agent = described_class.new(name: "Test", temperature: 0.2)

      expect(agent.temperature).to eq(0.2)
    end

    it "creates agent with response_schema" do
      schema = {
        type: "object",
        properties: {
          answer: { type: "string" }
        },
        required: ["answer"]
      }
      agent = described_class.new(name: "Test", response_schema: schema)

      expect(agent.response_schema).to eq(schema)
    end

    it "defaults response_schema to nil" do
      agent = described_class.new(name: "Test")

      expect(agent.response_schema).to be_nil
    end

    it "normalizes nil headers to empty hash" do
      agent = described_class.new(name: "Test", headers: nil)

      expect(agent.headers).to eq({})
    end
  end

  describe "#register_handoffs" do
    let(:agent) { described_class.new(name: "Test Agent") }
    let(:handoff_agent) { instance_double(described_class, "Agent1") }
    let(:extra_handoff_agent) { instance_double(described_class, "Agent2") }

    it "registers single handoff agent" do
      result = agent.register_handoffs(handoff_agent)

      expect(agent.handoff_agents).to include(handoff_agent)
      expect(result).to eq(agent)
    end

    it "registers multiple handoff agents" do
      agent.register_handoffs(handoff_agent, extra_handoff_agent)

      expect(agent.handoff_agents).to include(handoff_agent, extra_handoff_agent)
    end

    it "prevents duplicate handoff agents" do
      agent.register_handoffs(handoff_agent, handoff_agent)

      expect(agent.handoff_agents.count(handoff_agent)).to eq(1)
    end

    it "is thread-safe with concurrent registrations" do
      agents = 10.times.map { instance_double(described_class, "Agent#{_1}") }

      threads = agents.map do |test_agent|
        Thread.new { agent.register_handoffs(test_agent) }
      end
      threads.each(&:join)

      expect(agent.handoff_agents.size).to eq(10)
    end

    it "returns self for method chaining" do
      result = agent.register_handoffs(handoff_agent)

      expect(result).to be(agent)
    end
  end

  describe "#all_tools" do
    let(:agent) { described_class.new(name: "Test Agent", tools: [test_tool]) }
    let(:handoff_agent) { instance_double(described_class, name: "Handoff Agent") }

    it "returns regular tools when no handoffs registered" do
      expect(agent.all_tools).to eq([test_tool])
    end

    it "returns tools plus handoff tools" do
      agent.register_handoffs(handoff_agent)
      all_tools = agent.all_tools

      expect(all_tools).to include(test_tool)
      expect(all_tools.size).to eq(2)
      expect(all_tools.last).to be_a(Agents::HandoffTool)
    end

    it "is thread-safe" do
      threads = []
      5.times do |i|
        threads << Thread.new do
          agent.register_handoffs(instance_double(described_class, name: "Agent#{i}"))
          agent.all_tools
        end
      end
      threads.each(&:join)

      expect(agent.all_tools.size).to eq(6) # 1 regular + 5 handoff tools
    end
  end

  describe "#clone" do
    let(:original_agent) do
      described_class.new(
        name: "Original",
        instructions: "Original instructions",
        model: "gpt-4",
        tools: [test_tool],
        handoff_agents: [other_agent],
        temperature: 0.7,
        headers: { "X-Test" => "value" }
      )
    end

    it "creates new agent with same attributes when no changes provided" do
      cloned = original_agent.clone

      expect(cloned).not_to be(original_agent)
      expect(cloned.name).to eq("Original")
      expect(cloned.instructions).to eq("Original instructions")
      expect(cloned.model).to eq("gpt-4")
      expect(cloned.tools).to eq([test_tool])
      expect(cloned.handoff_agents).to eq([other_agent])
      expect(cloned.headers).to eq("X-Test": "value")
      expect(cloned.headers).to be_frozen
    end

    it "overrides specific attributes" do
      cloned = original_agent.clone(
        name: "Cloned",
        model: "gpt-3.5-turbo"
      )

      expect(cloned.name).to eq("Cloned")
      expect(cloned.model).to eq("gpt-3.5-turbo")
      expect(cloned.instructions).to eq("Original instructions")
      expect(cloned.tools).to eq([test_tool])
      expect(cloned.temperature).to eq(0.7)
      expect(cloned.headers).to eq("X-Test": "value")
    end

    it "duplicates tools array to prevent mutation" do
      cloned = original_agent.clone
      cloned.tools << instance_double(Agents::Tool, "NewTool")

      expect(original_agent.tools.size).to eq(1)
    end

    it "overrides temperature in clone" do
      cloned = original_agent.clone(temperature: 0.1)

      expect(cloned.temperature).to eq(0.1)
      expect(original_agent.temperature).to eq(0.7)
    end

    it "preserves response_schema when cloning" do
      schema = { type: "object", properties: { result: { type: "string" } } }
      agent_with_schema = described_class.new(name: "Test", response_schema: schema)
      cloned = agent_with_schema.clone(name: "ClonedAgent")

      expect(cloned.response_schema).to eq(schema)
      expect(cloned.name).to eq("ClonedAgent")
    end

    it "allows changing response_schema when cloning" do
      original_schema = { type: "object", properties: { result: { type: "string" } } }
      new_schema = { type: "object", properties: { answer: { type: "string" } } }
      agent = described_class.new(name: "Test", response_schema: original_schema)
      cloned = agent.clone(response_schema: new_schema)

      expect(cloned.response_schema).to eq(new_schema)
      expect(agent.response_schema).to eq(original_schema)
    end

    it "allows overriding headers when cloning" do
      new_headers = { "X-New" => "new" }
      cloned = original_agent.clone(headers: new_headers)

      expect(cloned.headers).to eq("X-New": "new")
      expect(original_agent.headers).to eq("X-Test": "value")
    end
  end

  describe "#get_system_prompt" do
    it "returns static string instructions" do
      agent = described_class.new(
        name: "Test",
        instructions: "You are a test agent"
      )

      result = agent.get_system_prompt(context)
      expect(result).to eq("You are a test agent")
    end

    it "executes Proc instructions with context" do
      instructions_proc = proc { |ctx| "Dynamic: #{ctx}" }
      agent = described_class.new(
        name: "Test",
        instructions: instructions_proc
      )

      result = agent.get_system_prompt(context)
      expect(result).to eq("Dynamic: #{context}")
    end

    it "returns nil when no instructions provided" do
      agent = described_class.new(name: "Test")

      result = agent.get_system_prompt(context)
      expect(result).to be_nil
    end

    it "returns instructions without modification regardless of handoffs" do
      agent = described_class.new(
        name: "Test",
        instructions: "Base instructions"
      )
      agent.register_handoffs(other_agent)

      result = agent.get_system_prompt(context)
      expect(result).to eq("Base instructions")
    end

    it "returns instructions when no handoffs" do
      agent = described_class.new(
        name: "Test",
        instructions: "Base instructions"
      )

      result = agent.get_system_prompt(context)
      expect(result).to eq("Base instructions")
    end
  end

  describe "#as_tool" do
    let(:agent) do
      described_class.new(
        name: "Research Agent",
        instructions: "You research topics",
        model: "gpt-4o-mini"
      )
    end

    it "creates an AgentTool with default settings" do
      tool = agent.as_tool

      expect(tool).to be_a(Agents::AgentTool)
      expect(tool.wrapped_agent).to eq(agent)
      expect(tool.name).to eq("research_agent")
      expect(tool.description).to eq("Execute Research Agent agent")
      expect(tool.output_extractor).to be_nil
    end

    it "creates an AgentTool with custom name and description" do
      tool = agent.as_tool(
        name: "custom_research",
        description: "Custom research functionality"
      )

      expect(tool.name).to eq("custom_research")
      expect(tool.description).to eq("Custom research functionality")
    end

    it "creates an AgentTool with output extractor" do
      extractor = ->(result) { "Summary: #{result.output}" }
      tool = agent.as_tool(output_extractor: extractor)

      expect(tool.output_extractor).to eq(extractor)
    end

    it "passes through all parameters to AgentTool" do
      extractor = ->(result) { result.output.upcase }

      tool = agent.as_tool(
        name: "search_tool",
        description: "Search functionality",
        output_extractor: extractor
      )

      expect(tool.name).to eq("search_tool")
      expect(tool.description).to eq("Search functionality")
      expect(tool.output_extractor).to eq(extractor)
    end

    it "returns different AgentTool instances for multiple calls" do
      tool1 = agent.as_tool
      tool2 = agent.as_tool

      expect(tool1).not_to be(tool2)
      expect(tool1.wrapped_agent).to eq(tool2.wrapped_agent)
    end

    context "with complex agent names" do
      let(:complex_agent) do
        described_class.new(
          name: "Complex Agent Name With Spaces!",
          instructions: "Test",
          model: "gpt-4o-mini"
        )
      end

      it "transforms complex names correctly" do
        tool = complex_agent.as_tool

        expect(tool.name).to eq("complex_agent_name_with_spaces")
        expect(tool.description).to eq("Execute Complex Agent Name With Spaces! agent")
      end
    end

    context "integration test" do
      let(:test_agent) do
        described_class.new(
          name: "Echo Agent",
          instructions: "Echo back the input you receive",
          model: "gpt-4o-mini"
        )
      end

      let(:tool_context) do
        run_context = Agents::RunContext.new({ state: { test: true } })
        Agents::ToolContext.new(run_context: run_context)
      end

      it "creates a functional tool that can be executed" do
        tool = test_agent.as_tool(name: "echo_tool")

        expect(tool).to respond_to(:perform)
        expect(tool).to respond_to(:execute)
        expect(tool.name).to eq("echo_tool")

        # Mock the underlying runner to avoid actual LLM calls
        mock_runner = instance_double(Agents::Runner)
        mock_result = instance_double(
          Agents::RunResult,
          output: "Echoed: test input",
          error: nil
        )

        allow(Agents::Runner).to receive(:new).and_return(mock_runner)
        allow(mock_runner).to receive(:run).and_return(mock_result)

        result = tool.perform(tool_context, input: "test input")

        expect(result).to eq("Echoed: test input")
        expect(mock_runner).to have_received(:run).with(
          test_agent,
          "test input",
          context: { state: { test: true } },
          registry: {},
          max_turns: 3
        )
      end
    end
  end
end
