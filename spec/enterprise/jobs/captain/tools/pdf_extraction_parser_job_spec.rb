require 'rails_helper'

RSpec.describe Captain::Tools::PdfExtractionParserJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let!(:main_document) { create(:captain_document, assistant: assistant, account: account, content: 'Main document content') }
  let(:pdf_content) do
    {
      content: 'This is sample PDF content extracted from a document. It contains useful information for FAQ generation.',
      page_number: 2,
      chunk_index: 1,
      total_chunks: 1
    }
  end

  before do
    # Mock usage limits
    allow(account).to receive(:usage_limits).and_return(
      captain: {
        documents: {
          current_available: 3
        }
      }
    )
  end

  describe '#perform' do
    context 'when document_id is provided and document exists' do
      it 'does not create new documents' do
        expect do
          described_class.new.perform(
            assistant_id: assistant.id,
            pdf_content: pdf_content,
            document_id: main_document.id
          )
        end.not_to change(Captain::Document, :count)
      end

      it 'enqueues ResponseBuilderJob with combined content for the main document' do
        expected_content = "Main document content\n\n--- Additional Content (Page 2) Part 1 ---\n" \
                           'This is sample PDF content extracted from a document. It contains useful information for FAQ generation.'

        expect(Captain::Documents::ResponseBuilderJob)
          .to receive(:perform_later)
          .with(main_document, expected_content)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content,
          document_id: main_document.id
        )
      end

      it 'combines main document content with chunk content' do
        chunk_content = pdf_content.merge(page_number: 3, chunk_index: 2)
        expected_content = "Main document content\n\n--- Additional Content (Page 3) Part 2 ---\n" \
                           'This is sample PDF content extracted from a document. It contains useful information for FAQ generation.'

        expect(Captain::Documents::ResponseBuilderJob)
          .to receive(:perform_later)
          .with(main_document, expected_content)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: chunk_content,
          document_id: main_document.id
        )
      end
    end

    context 'when document_id is nil' do
      it 'returns early without processing' do
        expect(Captain::Documents::ResponseBuilderJob).not_to receive(:perform_later)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content,
          document_id: nil
        )
      end
    end

    context 'when document_id is provided but document does not exist' do
      it 'logs error and returns without processing' do
        expect(Rails.logger).to receive(:error).with(/Document not found/)
        expect(Captain::Documents::ResponseBuilderJob).not_to receive(:perform_later)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content,
          document_id: 99_999
        )
      end
    end

    context 'when assistant is not found' do
      it 'logs error and returns without processing' do
        expect(Rails.logger).to receive(:error).with(/Document not found/)
        expect(Captain::Documents::ResponseBuilderJob).not_to receive(:perform_later)

        described_class.new.perform(
          assistant_id: 99_999,
          pdf_content: pdf_content,
          document_id: main_document.id
        )
      end
    end

    context 'when limits are exceeded' do
      before do
        allow(account).to receive(:usage_limits).and_return(
          captain: { documents: { current_available: 0 } }
        )
      end

      it 'does not process content when limit exceeded' do
        expect(Captain::Documents::ResponseBuilderJob).not_to receive(:perform_later)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content,
          document_id: main_document.id
        )
      end
    end
  end

  describe 'private methods' do
    let(:job) { described_class.new }

    describe '#limit_exceeded?' do
      it 'returns true when limit is zero' do
        allow(account).to receive(:usage_limits).and_return(
          captain: { documents: { current_available: 0 } }
        )
        expect(job.send(:limit_exceeded?, account)).to be true
      end

      it 'returns true when limit is negative' do
        allow(account).to receive(:usage_limits).and_return(
          captain: { documents: { current_available: -1 } }
        )
        expect(job.send(:limit_exceeded?, account)).to be true
      end

      it 'returns false when limit is positive' do
        allow(account).to receive(:usage_limits).and_return(
          captain: { documents: { current_available: 5 } }
        )
        expect(job.send(:limit_exceeded?, account)).to be false
      end
    end
  end
end