require 'rails_helper'

RSpec.describe Captain::Llm::FaqGeneratorService do
  let(:content) { 'Sample content for FAQ generation' }
  let(:language) { 'english' }
  let(:service) { described_class.new(content, language) }
  let(:llm_service) { instance_double(Captain::LlmService) }

  before do
    allow(Captain::LlmService).to receive(:new).and_return(llm_service)
  end

  describe '#generate' do
    let(:sample_faqs) do
      [
        { 'question' => 'What is this service?', 'answer' => 'It generates FAQs.' },
        { 'question' => 'How does it work?', 'answer' => 'Using AI technology.' }
      ]
    end

    let(:llm_response) do
      { output: { 'faqs' => sample_faqs }.to_json }
    end

    context 'when successful' do
      before do
        allow(llm_service).to receive(:call).and_return(llm_response)
        allow(Captain::Llm::SystemPromptsService).to receive(:faq_generator).and_return('system prompt')
      end

      it 'returns parsed FAQs' do
        result = service.generate
        expect(result).to eq(sample_faqs)
      end

      it 'calls LLM service with correct messages' do
        expect(llm_service).to receive(:call).with(
          array_including(
            hash_including(role: 'system', content: 'system prompt'),
            hash_including(role: 'user', content: content)
          ),
          [],
          json_mode: true
        )
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
        allow(llm_service).to receive(:call).and_return(llm_response)
      end

      it 'passes the correct language to SystemPromptsService' do
        expect(Captain::Llm::SystemPromptsService).to receive(:faq_generator).with('spanish')
        service.generate
      end
    end

    context 'when LLM call fails' do
      before do
        allow(llm_service).to receive(:call).and_raise(StandardError.new('API Error'))
      end

      it 'handles the error and returns empty array' do
        expect(Rails.logger).to receive(:error).with('FaqGeneratorService Error: API Error')
        expect(service.generate).to eq([])
      end
    end
  end
end
