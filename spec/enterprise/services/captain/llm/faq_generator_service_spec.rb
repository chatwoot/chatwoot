require 'rails_helper'

RSpec.describe Captain::Llm::FaqGeneratorService do
  let(:content) { 'Sample content for FAQ generation' }
  let(:language) { 'english' }
  let(:service) { described_class.new(content, language) }
  let(:client) { instance_double(OpenAI::Client) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
  end

  describe '#generate' do
    let(:sample_faqs) do
      [
        { 'question' => 'What is this service?', 'answer' => 'It generates FAQs.' },
        { 'question' => 'How does it work?', 'answer' => 'Using AI technology.' }
      ]
    end

    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => { faqs: sample_faqs }.to_json
            }
          }
        ]
      }
    end

    context 'when successful' do
      before do
        allow(client).to receive(:chat).and_return(openai_response)
        allow(Captain::Llm::SystemPromptsService).to receive(:faq_generator).and_return('system prompt')
      end

      it 'returns parsed FAQs' do
        result = service.generate
        expect(result).to eq(sample_faqs)
      end

      it 'calls OpenAI client with chat parameters' do
        expect(client).to receive(:chat).with(parameters: hash_including(
          model: 'gpt-4o-mini',
          response_format: { type: 'json_object' },
          messages: array_including(
            hash_including(role: 'system'),
            hash_including(role: 'user', content: content)
          )
        ))
        service.generate
      end

      it 'calls SystemPromptsService with correct language' do
        expect(Captain::Llm::SystemPromptsService).to receive(:faq_generator).with(language)
        service.generate
      end
    end

    context 'with different language' do
      let(:language) { 'spanish' }

      before do
        allow(client).to receive(:chat).and_return(openai_response)
      end

      it 'passes the correct language to SystemPromptsService' do
        expect(Captain::Llm::SystemPromptsService).to receive(:faq_generator).with('spanish')
        service.generate
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(client).to receive(:chat).and_raise(OpenAI::Error.new('API Error'))
      end

      it 'handles the error and returns empty array' do
        expect(Rails.logger).to receive(:error).with('OpenAI API Error: API Error')
        expect(service.generate).to eq([])
      end
    end
  end
end
