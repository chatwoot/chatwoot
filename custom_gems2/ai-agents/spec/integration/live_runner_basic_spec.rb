# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Live LLM basic runner", :live_llm do
  include LiveLLMHelper

  let(:model) { live_model }

  before do
    configure_live_llm(model: ENV.fetch("OPENAI_MODEL", LiveLLMHelper::DEFAULT_LIVE_MODEL))
  end

  it "returns a deterministic single-word reply" do
    agent = Agents::Agent.new(
      name: "PingAgent",
      instructions: "Always respond with the single word PONG and nothing else.",
      model: model,
      temperature: 0
    )

    runner = Agents::Runner.with_agents(agent)

    result = runner.run("Reply with PONG only.")

    expect(result.error).to be_nil
    expect(result.output.to_s).to match(/\bpong\b/i)
    expect(result.messages).to be_an(Array)
    expect(result.messages.map { |msg| msg[:role] }).to include(:user, :assistant)
  end
end
