require 'rails_helper'

RSpec.describe Captain::Llm::PaginatedFaqGeneratorService do
  let(:document) { create(:captain_document) }
  let(:service) { described_class.new(document, pages_per_chunk: 5) }
  let(:llm_service) { instance_double(Captain::LlmService) }

  before do
    allow(Captain::LlmService).to receive(:new).and_return(llm_service)
  end

  describe '#generate' do
    context 'when document lacks OpenAI file ID' do
      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
      end

      it 'raises an error' do
        expect { service.generate }.to raise_error('Missing OpenAI File ID')
      end
    end

    context 'when generating FAQs from PDF pages' do
      let(:faq_response) do
        {
          output: {
            'faqs' => [
              { 'question' => 'What is this document about?', 'answer' => 'It explains key concepts.' }
            ],
            'has_content' => true
          }.to_json
        }
      end

      let(:empty_response) do
        {
          output: {
            'faqs' => [],
            'has_content' => false
          }.to_json
        }
      end

      before do
        allow(document).to receive(:openai_file_id).and_return('file-123')
      end

      it 'generates FAQs from paginated content' do
        allow(llm_service).to receive(:call).and_return(faq_response, empty_response)

        faqs = service.generate

        expect(faqs.size).to eq(1)
        expect(faqs.first['question']).to eq('What is this document about?')
      end

      it 'stops when no more content' do
        allow(llm_service).to receive(:call).and_return(empty_response)

        faqs = service.generate

        expect(faqs).to be_empty
      end

      it 'respects max iterations limit' do
        allow(llm_service).to receive(:call).and_return(faq_response)

        service.generate

        # Verify the service was called (it will stop at max iterations)
        expect(llm_service).to have_received(:call).exactly(20).times
      end
    end
  end
end
