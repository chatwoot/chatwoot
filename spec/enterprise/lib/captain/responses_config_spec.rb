require 'rails_helper'

RSpec.describe Captain::ResponsesConfig do
  let(:lookup_tool) do
    stub_const('LookupTool', Class.new(RubyLLM::Tool) do
      description 'Look up an answer'
      parameter :query, type: 'string'

      def execute(query:)
        query
      end
    end)
  end

  let(:context) { RubyLLM.context { |config| config.openai_api_key = 'test-key' } }

  gpt_6_efforts = { 'gpt-6-astra' => 'low', 'gpt-6-sol' => 'none', 'gpt-6-luna' => 'none', 'gpt-6.1-sol' => 'low' }
  %w[assistant copilot].each do |feature|
    gpt_6_efforts.each do |model, effort|
      it "renders #{feature} tool requests for #{model} with #{effort} reasoning" do
        options = described_class.options(model: model, temperature: 0.7, feature: feature)
        chat = context.chat(model: model, protocol: options.fetch(:protocol))
        chat.with_temperature(options[:temperature]).with_thinking(**options.fetch(:thinking)).with_tools(lookup_tool)
        chat.with_provider_options(text: { format: { type: 'json_object' } })
        chat.add_message(role: :user, content: 'Look up the answer')

        payload = chat.render

        expect(payload).to include(model: model, reasoning: include(effort: effort), text: { format: { type: 'json_object' } })
        expect(payload[:tools]).to include(include(type: 'function', name: 'lookup'))
        if effort == 'none'
          expect(payload[:temperature]).to eq(0.7)
        else
          expect(payload).not_to have_key(:temperature)
        end
      end
    end
  end

  it 'keeps custom endpoints on their existing protocol without forced reasoning' do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://custom.example')

    expect(described_class.options(model: 'gpt-6.1-sol', temperature: 0.7, feature: 'copilot')).to eq(temperature: 0.7)
  end
end
