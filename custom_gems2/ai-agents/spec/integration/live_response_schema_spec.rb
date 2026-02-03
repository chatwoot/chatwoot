# frozen_string_literal: true

require "spec_helper"
require "json"
require "ruby_llm/schema"

class PongSchema < RubyLLM::Schema
  string :answer, description: "The single word response"
end

RSpec.describe "Live response schema enforcement", :live_llm do
  include LiveLLMHelper

  let(:model) { live_model }

  before do
    configure_live_llm(model: ENV.fetch("OPENAI_MODEL", LiveLLMHelper::DEFAULT_LIVE_MODEL))
  end

  it "returns JSON that matches a simple schema" do
    agent = Agents::Agent.new(
      name: "SchemaAgent",
      instructions: "Return JSON with the key answer set to PONG and no other top-level fields.",
      model: model,
      response_schema: PongSchema,
      temperature: 0
    )

    runner = Agents::Runner.with_agents(agent)

    result = runner.run("Respond now.")

    expect(result.error).to be_nil

    parsed = result.output.is_a?(Hash) ? result.output : JSON.parse(result.output.to_s)
    answer = parsed["answer"] || parsed[:answer]
    expect(answer).to match(/pong/i)
    expect(parsed.keys.map(&:to_s)).to eq(["answer"])
  end
end
