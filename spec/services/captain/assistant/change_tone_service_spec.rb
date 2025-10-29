require 'rails_helper'

RSpec.describe Captain::Assistant::ChangeToneService do
  let(:text) { 'Hey! Just checking if you got my email about the project' }
  let(:tone) { 'professional' }
  let(:service) { described_class.new(text: text, tone: tone) }
  let(:agent) { instance_double(Agents::Agent) }
  let(:runner) { instance_double(Agents::Runner) }
  let(:result) do
    instance_double(Agents::RunResult,
                    output: {
                      'rewritten_text' => 'Good afternoon. I am following up regarding my previous email about the project.',
                      'tone_applied' => 'professional'
                    },
                    error: nil)
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4o-mini')
    allow(Agents::Agent).to receive(:new).and_return(agent)
    allow(Agents::Runner).to receive(:with_agents).and_return(runner)
    allow(runner).to receive(:run).with(anything, context: anything).and_return(result)
    allow(Captain::PromptRenderer).to receive(:render).and_return('tone prompt')
  end

  describe '#initialize' do
    it 'initializes with text and tone' do
      expect(service.instance_variable_get(:@text)).to eq(text)
      expect(service.instance_variable_get(:@tone)).to eq('professional')
    end

    it 'converts tone to lowercase' do
      service = described_class.new(text: text, tone: 'PROFESSIONAL')
      expect(service.instance_variable_get(:@tone)).to eq('professional')
    end

    context 'with invalid tone' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(text: text, tone: 'invalid_tone')
        end.to raise_error(ArgumentError, /Unsupported tone: invalid_tone/)
      end

      it 'includes supported tones in error message' do
        expect do
          described_class.new(text: text, tone: 'invalid')
        end.to raise_error(ArgumentError, /professional, casual, straightforward, confident, friendly/)
      end
    end
  end

  describe '#execute' do
    context 'when successful' do
      it 'renders the tone prompt with correct context' do
        expect(Captain::PromptRenderer).to receive(:render).with(
          'rewrite/tone',
          hash_including(tone: 'professional')
        )
        service.execute
      end

      it 'builds agent with correct parameters' do
        expect(Agents::Agent).to receive(:new).with(
          name: 'ToneChanger',
          instructions: 'tone prompt',
          model: 'gpt-4o-mini',
          response_schema: service.send(:response_schema)
        )
        service.execute
      end

      it 'returns success response with rewritten text' do
        response = service.execute
        expect(response[:success]).to be true
        expect(response[:rewritten_text]).to eq('Good afternoon. I am following up regarding my previous email about the project.')
        expect(response[:tone]).to eq('professional')
        expect(response[:original_text]).to eq(text)
      end
    end

    context 'with different tones' do
      %w[professional casual straightforward confident friendly].each do |test_tone|
        it "works with #{test_tone} tone" do
          service = described_class.new(text: text, tone: test_tone)
          allow(Agents::Agent).to receive(:new).and_return(agent)
          allow(Agents::Runner).to receive(:with_agents).and_return(runner)
          allow(runner).to receive(:run).with(anything, context: anything).and_return(result)

          expect(Captain::PromptRenderer).to receive(:render).with(
            'rewrite/tone',
            hash_including(tone: test_tone)
          )
          service.execute
        end
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
        expect(Rails.logger).to receive(:error).with(/ChangeToneService error: API timeout/)
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
    it 'returns ToneChanger' do
      expect(service.send(:agent_name)).to eq('ToneChanger')
    end
  end

  describe '#build_instructions' do
    it 'renders the tone template with tone context' do
      expect(Captain::PromptRenderer).to receive(:render).with(
        'rewrite/tone',
        hash_including(tone: 'professional')
      )
      service.send(:build_instructions)
    end
  end

  describe '#response_schema' do
    let(:schema) { service.send(:response_schema) }

    it 'defines object type' do
      expect(schema[:type]).to eq('object')
    end

    it 'includes rewritten_text property' do
      expect(schema[:properties][:rewritten_text]).to include(
        type: 'string',
        description: 'The rewritten text with the requested tone applied'
      )
    end

    it 'includes tone_applied property' do
      expect(schema[:properties][:tone_applied]).to include(
        type: 'string',
        description: 'The tone that was applied to the text'
      )
    end

    it 'marks both fields as required' do
      expect(schema[:required]).to match_array(%w[rewritten_text tone_applied])
    end

    it 'disallows additional properties' do
      expect(schema[:additionalProperties]).to be false
    end
  end

  describe '#build_success_response' do
    let(:output) do
      {
        'rewritten_text' => 'Rewritten content',
        'tone_applied' => 'professional'
      }
    end

    it 'extracts rewritten_text from output' do
      response = service.send(:build_success_response, output)
      expect(response[:rewritten_text]).to eq('Rewritten content')
    end

    it 'includes the requested tone' do
      response = service.send(:build_success_response, output)
      expect(response[:tone]).to eq('professional')
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

  describe 'SUPPORTED_TONES constant' do
    it 'includes all valid tones' do
      expect(described_class::SUPPORTED_TONES).to match_array(
        %w[professional casual straightforward confident friendly]
      )
    end
  end

  describe 'End-to-End Tests' do
    context 'when making real API call (stubbed at HTTP level)' do
      let(:openai_response) do
        {
          id: 'chatcmpl-123',
          object: 'chat.completion',
          created: 1_677_652_288,
          model: 'gpt-4o-mini',
          choices: [
            {
              index: 0,
              message: {
                role: 'assistant',
                content: JSON.generate({
                                         rewritten_text: 'Good afternoon. I am following up regarding my previous email about the project.',
                                         tone_applied: 'professional'
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

      it 'successfully changes tone through entire stack' do
        response = service.execute

        expect(response[:success]).to be true
        expect(response[:rewritten_text]).to eq('Good afternoon. I am following up regarding my previous email about the project.')
        expect(response[:tone]).to eq('professional')
        expect(response[:original_text]).to eq(text)
      end
    end
  end
end
