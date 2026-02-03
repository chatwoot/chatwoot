# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Live agent handoff", :live_llm do
  include LiveLLMHelper

  let(:model) { live_model }

  before do
    configure_live_llm(model: ENV.fetch("OPENAI_MODEL", LiveLLMHelper::DEFAULT_LIVE_MODEL))
  end

  it "hands off to the target agent and continues the conversation" do
    specialist = Agents::Agent.new(
      name: "Specialist",
      instructions: "You only respond with the single word READY when a conversation is transferred to you.",
      model: model,
      temperature: 0
    )

    triage = Agents::Agent.new(
      name: "Triage",
      instructions: "Immediately call the handoff tool to transfer any request to Specialist. Do not answer yourself.",
      model: model,
      handoff_agents: [specialist],
      temperature: 0
    )

    runner = Agents::Runner.with_agents(triage, specialist)

    result = runner.run("Please assist me.")

    expect(result.error).to be_nil
    expect(result.context[:current_agent]).to eq("Specialist")
    expect(result.output).to match(/ready/i)
  end
end
