# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Live agent as tool", :live_llm do
  include LiveLLMHelper

  let(:model) { live_model }

  before do
    configure_live_llm(model: ENV.fetch("OPENAI_MODEL", LiveLLMHelper::DEFAULT_LIVE_MODEL))
  end

  it "delegates through agent-as-tool and returns nested output" do
    helper_agent = Agents::Agent.new(
      name: "Echo Helper",
      instructions: "Echo back exactly the text you are given. Respond with only that text.",
      model: model,
      temperature: 0
    )

    outer_agent = Agents::Agent.new(
      name: "Wrapper",
      instructions: "Use the helper tool to echo the user's request verbatim. Return only the helper's reply.",
      model: model,
      tools: [helper_agent.as_tool(name: "echo_helper")],
      temperature: 0
    )

    runner = Agents::Runner.with_agents(outer_agent)

    result = runner.run("Ask the helper to return OKAY.")

    expect(result.error).to be_nil
    expect(result.output).to match(/okay/i)
    # Tool traces may not be exposed in messages across providers; focus on end output only.
    expect(result.success?).to be true
  end
end
