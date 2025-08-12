require 'rails_helper'

RSpec.describe Captain::Documents::ResponseBuilderJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }

  describe '#perform' do
    before do
      # Mock the InstallationConfig for services that need it
      allow(InstallationConfig).to receive(:find_by!)
        .with(name: 'CAPTAIN_OPEN_AI_API_KEY')
        .and_return(instance_double(InstallationConfig, value: 'test-api-key'))
    end

    context 'when document requires pagination' do
      before do
        allow(document).to receive(:pdf_document?).and_return(true)
        allow(document).to receive(:openai_file_id).and_return('file-123')
        allow(document).to receive(:update!).and_return(true)
        allow(document).to receive(:metadata).and_return({})
      end

      it 'uses paginated FAQ generator service' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)

        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new)
          .with(document, hash_including(:pages_per_chunk, :max_pages))
          .and_return(paginated_service)

        expect(paginated_service).to receive(:generate).and_return([])
        expect(paginated_service).to receive(:total_pages_processed).and_return(10)
        expect(paginated_service).to receive(:iterations_completed).and_return(1)

        described_class.perform_now(document)
      end

      it 'accepts pagination options' do
        options = { pages_per_chunk: 5, max_pages: 20 }
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)

        expect(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new)
          .with(document, pages_per_chunk: 5, max_pages: 20)
          .and_return(paginated_service)

        expect(paginated_service).to receive(:generate).and_return([])
        expect(paginated_service).to receive(:total_pages_processed).and_return(20)
        expect(paginated_service).to receive(:iterations_completed).and_return(4)

        described_class.perform_now(document, options)
      end

      it 'stores metadata about paginated generation' do
        paginated_service = instance_double(Captain::Llm::PaginatedFaqGeneratorService)

        allow(Captain::Llm::PaginatedFaqGeneratorService).to receive(:new)
          .and_return(paginated_service)
        allow(paginated_service).to receive(:generate).and_return([])
        allow(paginated_service).to receive(:total_pages_processed).and_return(15)
        allow(paginated_service).to receive(:iterations_completed).and_return(2)

        expect(document).to receive(:update!).with(
          metadata: hash_including(
            'faq_generation' => hash_including(
              'method' => 'paginated',
              'pages_processed' => 15,
              'iterations' => 2
            )
          )
        )

        described_class.perform_now(document)
      end
    end

    context 'when document uses standard generation' do
      before do
        allow(document).to receive(:pdf_document?).and_return(false)
        allow(document).to receive(:content).and_return('Document content')
      end

      it 'uses standard FAQ generator service' do
        standard_service = instance_double(Captain::Llm::FaqGeneratorService)

        expect(Captain::Llm::FaqGeneratorService).to receive(:new)
          .with('Document content')
          .and_return(standard_service)

        expect(standard_service).to receive(:generate).and_return([])

        described_class.perform_now(document)
      end
    end

    context 'when FAQs are generated successfully' do
      let(:faqs) do
        [
          { 'question' => 'What is this?', 'answer' => 'This is a test' },
          { 'question' => 'How does it work?', 'answer' => 'It works well' }
        ]
      end

      before do
        allow(document).to receive(:pdf_document?).and_return(false)
        allow(document).to receive(:content).and_return('Document content')

        standard_service = instance_double(Captain::Llm::FaqGeneratorService)
        allow(Captain::Llm::FaqGeneratorService).to receive(:new).and_return(standard_service)
        allow(standard_service).to receive(:generate).and_return(faqs)
      end

      it 'creates response records from FAQs' do
        expect { described_class.perform_now(document) }
          .to change { document.responses.count }.by(2)
      end

      it 'creates responses with correct attributes' do
        described_class.perform_now(document)

        response = document.responses.first
        expect(response.question).to eq('What is this?')
        expect(response.answer).to eq('This is a test')
        expect(response.assistant).to eq(assistant)
        expect(response.documentable).to eq(document)
      end

      it 'removes previous responses before creating new ones' do
        # Create existing responses
        document.responses.create!(
          question: 'Old question',
          answer: 'Old answer',
          assistant: assistant,
          documentable: document
        )

        expect(document.responses.count).to eq(1)

        described_class.perform_now(document)

        expect(document.responses.count).to eq(2)
        expect(document.responses.pluck(:question)).not_to include('Old question')
      end
    end

    context 'when FAQ generation fails' do
      before do
        allow(document).to receive(:pdf_document?).and_return(false)
        allow(document).to receive(:content).and_return('Document content')
      end

      it 'propagates the error' do
        standard_service = instance_double(Captain::Llm::FaqGeneratorService)
        allow(Captain::Llm::FaqGeneratorService).to receive(:new).and_return(standard_service)
        allow(standard_service).to receive(:generate).and_raise(StandardError, 'Generation failed')

        expect { described_class.perform_now(document) }
          .to raise_error(StandardError, 'Generation failed')
      end
    end

    context 'when creating response fails' do
      let(:faqs) do
        [
          { 'question' => nil, 'answer' => 'Invalid FAQ' } # Invalid due to nil question
        ]
      end

      before do
        allow(document).to receive(:pdf_document?).and_return(false)
        allow(document).to receive(:content).and_return('Document content')

        standard_service = instance_double(Captain::Llm::FaqGeneratorService)
        allow(Captain::Llm::FaqGeneratorService).to receive(:new).and_return(standard_service)
        allow(standard_service).to receive(:generate).and_return(faqs)
      end

      it 'logs the error and continues' do
        expect(Rails.logger).to receive(:error).with(/Error in creating response document/)

        expect { described_class.perform_now(document) }
          .not_to raise_error
      end
    end
  end

  describe 'job queuing' do
    it 'is enqueued in the low queue' do
      expect do
        described_class.perform_later(document)
      end.to have_enqueued_job(described_class).on_queue('low')
    end

    it 'can be scheduled for later execution' do
      expect do
        described_class.set(wait: 5.minutes).perform_later(document)
      end.to have_enqueued_job(described_class).at(a_value_within(1.second).of(5.minutes.from_now))
    end
  end

  describe '#should_use_pagination?' do
    subject { described_class.new.send(:should_use_pagination?, document) }

    context 'when document is a PDF with openai_file_id' do
      before do
        allow(document).to receive(:pdf_document?).and_return(true)
        allow(document).to receive(:openai_file_id).and_return('file-123')
      end

      it { is_expected.to be true }
    end

    context 'when document is a PDF without openai_file_id' do
      before do
        allow(document).to receive(:pdf_document?).and_return(true)
        allow(document).to receive(:openai_file_id).and_return(nil)
      end

      it { is_expected.to be false }
    end

    context 'when document is not a PDF' do
      before do
        allow(document).to receive(:pdf_document?).and_return(false)
      end

      it { is_expected.to be false }
    end
  end
end
