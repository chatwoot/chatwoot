require 'rails_helper'

RSpec.describe Captain::Assistant::FixGrammarService do
  let(:text) { 'their going too the store tommorow and there bringing they\'re friends' }
  let(:service) { described_class.new(text: text) }
  let(:agent) { instance_double(Agents::Agent) }
  let(:runner) { instance_double(Agents::Runner) }
  let(:result) do
    instance_double(Agents::RunResult,
                    output: {
                      'corrected_text' => 'They\'re going to the store tomorrow and they\'re bringing their friends.',
                      'corrections_made' => [
                        'Changed "their" to "They\'re"',
                        'Changed "too" to "to"',
                        'Fixed spelling: "tommorow" to "tomorrow"',
                        'Changed "there" to "they\'re"',
                        'Changed "they\'re" to "their"'
                      ]
                    },
                    error: nil)
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4o-mini')
    allow(Agents::Agent).to receive(:new).and_return(agent)
    allow(Agents::Runner).to receive(:with_agents).and_return(runner)
    allow(runner).to receive(:run).with(anything, context: anything).and_return(result)
    allow(Captain::PromptRenderer).to receive(:render).and_return('grammar prompt')
  end

  describe '#initialize' do
    it 'initializes with text only' do
      expect(service.instance_variable_get(:@text)).to eq(text)
    end
  end

  describe '#execute' do
    context 'when successful' do
      it 'renders the grammar prompt' do
        expect(Captain::PromptRenderer).to receive(:render).with('rewrite/grammar', {})
        service.execute
      end

      it 'builds agent with correct parameters' do
        expect(Agents::Agent).to receive(:new).with(
          name: 'GrammarFixer',
          instructions: 'grammar prompt',
          model: 'gpt-4o-mini',
          response_schema: service.send(:response_schema)
        )
        service.execute
      end

      it 'returns success response with corrected text' do
        response = service.execute
        expect(response[:success]).to be true
        expect(response[:corrected_text]).to eq('They\'re going to the store tomorrow and they\'re bringing their friends.')
        expect(response[:original_text]).to eq(text)
      end

      it 'includes corrections made' do
        response = service.execute
        expect(response[:corrections_made]).to be_an(Array)
        expect(response[:corrections_made]).to include('Changed "their" to "They\'re"')
      end
    end

    context 'when output does not include corrections_made' do
      let(:result) do
        instance_double(Agents::RunResult,
                        output: {
                          'corrected_text' => 'Corrected text without corrections list'
                        },
                        error: nil)
      end

      it 'returns empty array for corrections_made' do
        response = service.execute
        expect(response[:success]).to be true
        expect(response[:corrections_made]).to eq([])
      end
    end

    context 'when agent returns an error' do
      let(:result) { instance_double(Agents::RunResult, output: { error: 'Model error' }, error: nil) }

      it 'returns error response' do
        response = service.execute
        expect(response[:success]).to be false
        expect(response[:error]).to eq('Model error')
        expect(response[:original_text]).to eq(text)
      end
    end

    context 'when exception is raised' do
      before do
        allow(runner).to receive(:run).with(anything, context: anything).and_raise(StandardError.new('API timeout'))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/FixGrammarService error: API timeout/)
        expect(Rails.logger).to receive(:error).with(anything)
        service.execute
      end

      it 'returns error response' do
        response = service.execute
        expect(response[:success]).to be false
        expect(response[:error]).to eq('API timeout')
      end
    end
  end

  describe '#agent_name' do
    it 'returns GrammarFixer' do
      expect(service.send(:agent_name)).to eq('GrammarFixer')
    end
  end

  describe '#build_instructions' do
    it 'renders the grammar template with empty context' do
      expect(Captain::PromptRenderer).to receive(:render).with('rewrite/grammar', {})
      service.send(:build_instructions)
    end
  end

  describe '#response_schema' do
    let(:schema) { service.send(:response_schema) }

    it 'defines object type' do
      expect(schema[:type]).to eq('object')
    end

    it 'includes corrected_text property' do
      expect(schema[:properties][:corrected_text]).to include(
        type: 'string',
        description: 'The text with corrected grammar, spelling, and punctuation'
      )
    end

    it 'includes corrections_made property' do
      expect(schema[:properties][:corrections_made]).to include(
        type: 'array',
        description: 'List of corrections that were made'
      )
    end

    it 'marks corrected_text as required' do
      expect(schema[:required]).to include('corrected_text')
    end

    it 'disallows additional properties' do
      expect(schema[:additionalProperties]).to be false
    end
  end

  describe '#build_success_response' do
    let(:output) do
      {
        'corrected_text' => 'Corrected content',
        'corrections_made' => ['Fix 1', 'Fix 2']
      }
    end

    it 'extracts corrected_text from output' do
      response = service.send(:build_success_response, output)
      expect(response[:corrected_text]).to eq('Corrected content')
    end

    it 'includes corrections made' do
      response = service.send(:build_success_response, output)
      expect(response[:corrections_made]).to eq(['Fix 1', 'Fix 2'])
    end

    it 'includes original text' do
      response = service.send(:build_success_response, output)
      expect(response[:original_text]).to eq(text)
    end

    it 'marks response as successful' do
      response = service.send(:build_success_response, output)
      expect(response[:success]).to be true
    end
  end

  describe '#extract_corrections' do
    it 'returns array when output has corrections_made as symbol key' do
      output = { corrections_made: ['Fix 1'] }
      expect(service.send(:extract_corrections, output)).to eq(['Fix 1'])
    end

    it 'returns array when output has corrections_made as string key' do
      output = { 'corrections_made' => ['Fix 1'] }
      expect(service.send(:extract_corrections, output)).to eq(['Fix 1'])
    end

    it 'returns empty array when output is not a hash' do
      expect(service.send(:extract_corrections, 'string')).to eq([])
    end

    it 'returns empty array when corrections_made is missing' do
      expect(service.send(:extract_corrections, {})).to eq([])
    end
  end

  describe 'End-to-End Tests' do
    context 'when making real API call (stubbed at HTTP level)' do
      let(:openai_response) do
        {
          id: 'chatcmpl-456',
          object: 'chat.completion',
          created: 1_677_652_300,
          model: 'gpt-4o-mini',
          choices: [
            {
              index: 0,
              message: {
                role: 'assistant',
                content: JSON.generate({
                                         corrected_text: 'They\'re going to the store tomorrow and they\'re bringing their friends.',
                                         corrections_made: [
                                           'Changed "their" to "They\'re"',
                                           'Changed "too" to "to"',
                                           'Fixed spelling: "tommorow" to "tomorrow"'
                                         ]
                                       })
              },
              finish_reason: 'stop'
            }
          ]
        }
      end

      before do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .to_return(status: 200, body: openai_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'successfully fixes grammar through entire stack' do
        response = service.execute

        expect(response[:success]).to be true
        expect(response[:corrected_text]).to eq('They\'re going to the store tomorrow and they\'re bringing their friends.')
        expect(response[:corrections_made]).to include('Changed "their" to "They\'re"')
        expect(response[:original_text]).to eq(text)
      end
    end
  end
end
