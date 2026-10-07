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

  efforts = { 'gpt-5.1' => 'none', 'gpt-5.2' => 'none' }
  %w[assistant copilot].each do |feature|
    efforts.each do |model, effort|
      it "renders #{feature} tool requests for #{model} with #{effort} reasoning" do
        options = described_class.options(model: model, temperature: 0.7, feature: feature)
        chat = context.chat(model: model, protocol: options.fetch(:protocol))
        chat.with_temperature(options[:temperature]).with_thinking(**options.fetch(:thinking)).with_tools(lookup_tool)
        chat.with_provider_options(text: { format: { type: 'json_object' } })
        chat.add_message(role: :user, content: 'Look up the answer')

        payload = chat.render

        expect(payload).to include(model: model, reasoning: include(effort: effort), text: { format: { type: 'json_object' } })
        expect(payload[:tools]).to include(include(type: 'function', name: 'lookup'))
        expect(described_class.metadata(chat, protocol: options[:protocol])).to eq(api_protocol: :responses, reasoning_effort: effort.to_sym)
        if options[:temperature]
          expect(payload[:temperature]).to eq(options[:temperature])
        else
          expect(payload).not_to have_key(:temperature)
        end
      end
    end
  end

  it 'keeps custom endpoints on their existing protocol without forced reasoning' do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://custom.example')

    expect(described_class.options(model: 'gpt-4.1', temperature: 0.7, feature: 'copilot')).to eq(temperature: 0.7)
    expect(described_class.options(model: 'gpt-5-mini', temperature: 0.7, feature: 'copilot')).to eq(temperature: nil)
  end

  it 'reports Chat Completions and omits effort when thinking is not configured' do
    context.config.openai_protocol = :chat_completions
    chat = context.chat(model: 'gpt-4.1')

    expect(described_class.metadata(chat)).to eq(api_protocol: :chat_completions)
  end

  it 'uses a saved account effort in the actual Responses request' do
    account = create(:account, captain_models: { 'copilot' => 'gpt-6-luna' }, captain_reasoning_efforts: { 'copilot' => 'high' })
    options = described_class.options(model: 'gpt-6-luna', temperature: 0.7, feature: 'copilot', account: account)
    chat = context.chat(model: 'gpt-6-luna', protocol: options[:protocol]).with_temperature(options[:temperature])
    chat.with_thinking(**options[:thinking]).add_message(role: :user, content: 'Hello')

    expect(chat.render).to include(model: 'gpt-6-luna', reasoning: include(effort: 'high'))
    expect(chat.render).not_to have_key(:temperature)
    expect(described_class.metadata(chat, protocol: options[:protocol])).to eq(api_protocol: :responses, reasoning_effort: :high)
  end

  %w[low high].each do |effort|
    it "applies configured #{effort} effort and omits temperature" do
      allow(Llm::Models).to receive(:features).and_return(Llm::Models.features.deep_merge('assistant' => { 'reasoning_effort' => effort }))
      options = described_class.options(model: 'gpt-5.2', temperature: 0.7)
      chat = context.chat(model: 'gpt-5.2', protocol: options[:protocol]).with_temperature(options[:temperature])
      chat.with_thinking(**options[:thinking])
      chat.add_message(role: :user, content: 'Hello')

      expect(chat.render).to include(reasoning: include(effort: effort))
      expect(chat.render).not_to have_key(:temperature)
      expect(described_class.metadata(chat, protocol: options[:protocol])).to eq(api_protocol: :responses, reasoning_effort: effort.to_sym)
    end
  end
end
