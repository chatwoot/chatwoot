require 'rails_helper'

RSpec.describe Captain::Documents::ResponseBuilderJob, type: :job do
  let(:assistant) { create(:captain_assistant) }
  let(:document) { create(:captain_document, assistant: assistant) }
  let(:faq_generator) { instance_double(Captain::Llm::FaqGeneratorService) }
  let(:faqs) do
    [
      { 'question' => 'What is Ruby?', 'answer' => 'A programming language' },
      { 'question' => 'What is Rails?', 'answer' => 'A web framework' }
    ]
  end

  before do
    allow(Captain::Llm::FaqGeneratorService).to receive(:new)
      .with(document.content, document.account.locale_english_name, account_id: document.account_id)
      .and_return(faq_generator)
    allow(faq_generator).to receive(:generate).and_return(faqs)
  end

  describe '#perform' do
    context 'when processing a document' do
      it 'deletes previous responses' do
        existing_response = create(:captain_assistant_response, documentable: document)

        described_class.new.perform(document)

        expect { existing_response.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'creates new responses for each FAQ' do
        expect do
          described_class.new.perform(document)
        end.to change(Captain::AssistantResponse, :count).by(2)

        responses = document.responses.reload
        expect(responses.count).to eq(2)

        first_response = responses.first
        expect(first_response.question).to eq('What is Ruby?')
        expect(first_response.answer).to eq('A programming language')
        expect(first_response.assistant).to eq(assistant)
        expect(first_response.documentable).to eq(document)
      end
    end

    context 'with different locales' do
      let(:spanish_account) { create(:account, locale: 'pt') }
      let(:spanish_assistant) { create(:captain_assistant, account: spanish_account) }
      let(:spanish_document) { create(:captain_document, assistant: spanish_assistant, account: spanish_account) }
      let(:spanish_faq_generator) { instance_double(Captain::Llm::FaqGeneratorService) }

      before do
        allow(Captain::Llm::FaqGeneratorService).to receive(:new)
          .with(spanish_document.content, 'portuguese', account_id: spanish_document.account_id)
          .and_return(spanish_faq_generator)
        allow(spanish_faq_generator).to receive(:generate).and_return(faqs)
      end

      it 'passes the correct locale to FAQ generator' do
        described_class.new.perform(spanish_document)

        expect(Captain::Llm::FaqGeneratorService).to have_received(:new)
          .with(spanish_document.content, 'portuguese', account_id: spanish_document.account_id)
      end
    end

    context 'when processing a PDF document' do
      let(:pdf_document) do
        doc = create(:captain_document, assistant: assistant)
        allow(doc).to receive(:pdf_document?).and_return(true)
        allow(doc).to receive(:openai_file_id).and_return('file-123')
        allow(doc).to receive(:update!).and_return(true)
        allow(doc).to receive(:metadata).and_return({})
        doc
      end
      let(:paginated_service) { instance_double(Captain::Llm::PaginatedFaqGeneratorService) }
      let(:pdf_faqs) do
        [{ 'question' => 'What is in the PDF?', 'answer' => 'Important content' }]
      end

      before do
        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new)
          .with(pdf_document, anything)
          .and_return(paginated_service)
        allow(paginated_service).to receive(:generate).and_return(pdf_faqs)
        allow(paginated_service).to receive(:total_pages_processed).and_return(10)
        allow(paginated_service).to receive(:iterations_completed).and_return(1)
      end

      it 'uses paginated FAQ generator for PDFs' do
        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new).with(pdf_document, anything)

        described_class.new.perform(pdf_document)
      end

      it 'stores pagination metadata' do
        expect(pdf_document).to receive(:update!).with(hash_including(metadata: hash_including('faq_generation')))

        described_class.new.perform(pdf_document)
      end
    end
  end
end
