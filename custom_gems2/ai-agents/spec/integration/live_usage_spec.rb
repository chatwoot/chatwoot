# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Live usage accounting", :live_llm do
  include LiveLLMHelper

  let(:model) { live_model }

  before do
    configure_live_llm(model: ENV.fetch("OPENAI_MODEL", LiveLLMHelper::DEFAULT_LIVE_MODEL))
  end

  it "returns prompt and completion token counts" do
    agent = Agents::Agent.new(
      name: "UsageAgent",
      instructions: "Reply with the single word READY.",
      model: model,
      temperature: 0
    )

    runner = Agents::Runner.with_agents(agent)

    result = runner.run("Reply now.")

    expect(result.error).to be_nil
    expect(result.output).to match(/ready/i)

    usage = result.usage
    puts "Usage tokens - input: #{usage.input_tokens}, output: #{usage.output_tokens}, total: #{usage.total_tokens}"
    expect(usage.input_tokens).to be_a(Integer)
    expect(usage.output_tokens).to be_a(Integer)
    expect(usage.total_tokens).to be_a(Integer)
    expect(usage.input_tokens).to be > 0
    expect(usage.output_tokens).to be > 0
    expect(usage.total_tokens).to be > 0
  end
end
