require 'rails_helper'

RSpec.describe Captain::Tools::PdfExtractionParserJob, type: :job do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:pdf_content) do
    {
      content: 'This is sample PDF content extracted from a document. It contains useful information for FAQ generation.',
      page_number: 1,
      chunk_index: 1,
      total_chunks: 1
    }
  end

  let(:captain_limits) do
    {
      startups: { documents: 5, responses: 100 }
    }.with_indifferent_access
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
    context 'when limits are not exceeded' do
      it 'processes PDF content successfully' do
        expect do
          described_class.new.perform(
            assistant_id: assistant.id,
            pdf_content: pdf_content
          )
        end.to change(Captain::Document, :count).by(1)
      end

      it 'creates captain documents with correct attributes' do
        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content
        )

        document = Captain::Document.last
        expect(document.assistant_id).to eq(assistant.id)
        expect(document.content).to include('sample PDF content')
        expect(document.name).to eq('PDF Content')
        expect(document.status).to eq('available')
      end

      it 'generates appropriate title for single chunk' do
        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content
        )

        document = Captain::Document.last
        expect(document.name).to eq('PDF Content')
      end

      it 'generates appropriate title for multiple chunks' do
        multi_chunk_content = pdf_content.merge(
          chunk_index: 2,
          total_chunks: 3,
          page_number: 2
        )

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: multi_chunk_content
        )

        document = Captain::Document.last
        expect(document.name).to include('Page 2, Part 2/3')
      end

      it 'creates document with unique external link' do
        document_id = 123
        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content,
          document_id: document_id
        )

        document = Captain::Document.last
        expect(document.external_link).to eq("pdf_chunk_#{document_id}_page_1_chunk_1")
      end
    end

    context 'when limits are exceeded' do
      before do
        # Stub the Captain::Document.create! method to raise limit error
        # This is more specific than allow_any_instance_of
        allow(Captain::Document).to receive(:create!).and_raise(Captain::Document::LimitExceededError, 'Document limit exceeded')
      end

      it 'does not create documents when limit exceeded' do
        expect do
          described_class.new.perform(
            assistant_id: assistant.id,
            pdf_content: pdf_content
          )
        end.not_to(change(Captain::Document, :count))
      end

      it 'logs limit exceeded message' do
        expect(Rails.logger).to receive(:info).with(/Document limit exceeded/)

        described_class.new.perform(
          assistant_id: assistant.id,
          pdf_content: pdf_content
        )
      end
    end

    context 'when document_id is provided' do
      let!(:document) { create(:captain_document, assistant: assistant, status: 'in_progress') }

      it 'creates a new document with external link referencing document_id' do
        expect do
          described_class.new.perform(
            assistant_id: assistant.id,
            pdf_content: pdf_content,
            document_id: document.id
          )
        end.to change(Captain::Document, :count).by(1)

        new_document = Captain::Document.last
        expect(new_document.external_link).to include("pdf_chunk_#{document.id}")
      end
    end

    context 'when an error occurs' do
      context 'when assistant is not found' do
        it 'logs the error and does not raise' do
          expect(Rails.logger).to receive(:error).with(/Assistant not found/)

          expect do
            described_class.new.perform(
              assistant_id: 99_999,
              pdf_content: pdf_content
            )
          end.not_to change(Captain::Document, :count)
        end
      end

      context 'when document creation fails with validation error' do
        before do
          allow(Captain::Document).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Captain::Document.new))
        end

        it 'logs the validation error and does not raise' do
          expect(Rails.logger).to receive(:error).with(/Invalid document data/)

          expect do
            described_class.new.perform(
              assistant_id: assistant.id,
              pdf_content: pdf_content
            )
          end.not_to change(Captain::Document, :count)
        end
      end

      context 'when limit is exceeded during creation' do
        before do
          allow(Captain::Document).to receive(:create!).and_raise(Captain::Document::LimitExceededError.new('Limit exceeded'))
        end

        it 'logs the limit error and does not raise' do
          expect(Rails.logger).to receive(:info).with(/Document limit exceeded/)

          expect do
            described_class.new.perform(
              assistant_id: assistant.id,
              pdf_content: pdf_content
            )
          end.not_to change(Captain::Document, :count)
        end
      end
    end
  end

  describe 'private methods' do
    let(:job) { described_class.new }

    describe '#generate_title' do
      it 'uses first line as title when appropriate' do
        pdf_content = {
          content: "Introduction to Machine Learning\n\nThis document covers the basics...",
          page_number: 1,
          chunk_index: 1,
          total_chunks: 1
        }
        title = job.send(:generate_title, pdf_content)
        expect(title).to eq('Introduction to Machine Learning')
      end

      it 'uses generic title for long first lines' do
        pdf_content = {
          content: "#{('A' * 200)}\n\nThis is the rest of the content...",
          page_number: 1,
          chunk_index: 1,
          total_chunks: 1
        }
        title = job.send(:generate_title, pdf_content)
        expect(title).to eq('PDF Content')
      end

      it 'adds page information for multiple pages' do
        pdf_content = {
          content: 'Sample content',
          page_number: 3,
          chunk_index: 1,
          total_chunks: 1
        }
        title = job.send(:generate_title, pdf_content)
        expect(title).to eq('Sample content (Page 3)')
      end

      it 'adds chunk information for multiple chunks' do
        pdf_content = {
          content: 'Sample content',
          page_number: 2,
          chunk_index: 2,
          total_chunks: 4
        }
        title = job.send(:generate_title, pdf_content)
        expect(title).to eq('Sample content (Page 2, Part 2/4)')
      end

      it 'truncates long titles to database limit' do
        pdf_content = {
          content: 'A' * 300,
          page_number: 1,
          chunk_index: 1,
          total_chunks: 1
        }
        title = job.send(:generate_title, pdf_content)
        expect(title.length).to be <= 255
      end
    end

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