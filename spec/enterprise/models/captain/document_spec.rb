require 'rails_helper'

RSpec.describe Captain::Document, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe 'URL normalization' do
    it 'removes a trailing slash before validation' do
      document = create(:captain_document,
                        assistant: assistant,
                        account: account,
                        external_link: 'https://example.com/path/')

      expect(document.external_link).to eq('https://example.com/path')
    end
  end

  describe 'PDF support' do
    let(:pdf_document) do
      doc = build(:captain_document, assistant: assistant, account: account)
      doc.pdf_file.attach(
        io: StringIO.new('PDF content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      doc
    end

    describe 'validations' do
      it 'allows PDF file without external link' do
        pdf_document.external_link = nil
        expect(pdf_document).to be_valid
      end

      it 'validates PDF file size' do
        doc = build(:captain_document, assistant: assistant, account: account)
        doc.pdf_file.attach(
          io: StringIO.new('x' * 11.megabytes),
          filename: 'large.pdf',
          content_type: 'application/pdf'
        )
        doc.external_link = nil
        expect(doc).not_to be_valid
        expect(doc.errors[:pdf_file]).to include(I18n.t('captain.documents.pdf_size_error'))
      end
    end

    describe '#pdf_document?' do
      it 'returns true for attached PDF' do
        expect(pdf_document.pdf_document?).to be true
      end

      it 'returns true for .pdf external links' do
        doc = build(:captain_document, external_link: 'https://example.com/document.pdf')
        expect(doc.pdf_document?).to be true
      end

      it 'returns false for non-PDF documents' do
        doc = build(:captain_document, external_link: 'https://example.com')
        expect(doc.pdf_document?).to be false
      end
    end

    describe '#display_url' do
      it 'returns Rails blob URL for attached PDFs' do
        pdf_document.save!
        # The display_url method calls rails_blob_url which returns a URL containing 'rails/active_storage'
        url = pdf_document.display_url
        expect(url).to be_present
      end

      it 'returns external_link for web documents' do
        doc = create(:captain_document, external_link: 'https://example.com')
        expect(doc.display_url).to eq('https://example.com')
      end
    end

    describe '#store_openai_file_id' do
      it 'stores the file ID in metadata' do
        pdf_document.save!
        pdf_document.store_openai_file_id('file-abc123')

        expect(pdf_document.reload.openai_file_id).to eq('file-abc123')
      end
    end

    describe 'automatic external_link generation' do
      it 'generates unique external_link for PDFs' do
        pdf_document.external_link = nil
        pdf_document.save!

        expect(pdf_document.external_link).to start_with('PDF: test_')
      end
    end
  end

  describe 'response builder job callback' do
    before { clear_enqueued_jobs }

    describe 'non-PDF documents' do
      it 'enqueues when created with available status and content' do
        expect do
          create(:captain_document, assistant: assistant, account: account, status: :available)
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue when created available without content' do
        expect do
          create(:captain_document, assistant: assistant, account: account, status: :available, content: nil)
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'enqueues when status transitions to available with existing content' do
        document = create(:captain_document, assistant: assistant, account: account, status: :in_progress)

        expect do
          document.update!(status: :available)
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue when status transitions to available without content' do
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :in_progress,
          content: nil
        )

        expect do
          document.update!(status: :available)
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'enqueues when content is populated on an available document' do
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          content: nil
        )
        clear_enqueued_jobs

        expect do
          document.update!(content: 'Fresh content from crawl')
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'enqueues when content changes on an available document' do
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          content: 'Initial content'
        )
        clear_enqueued_jobs

        expect do
          document.update!(content: 'Updated crawl content')
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue when content is cleared on an available document' do
        document = create(
          :captain_document,
          assistant: assistant,
          account: account,
          status: :available,
          content: 'Initial content'
        )
        clear_enqueued_jobs

        expect do
          document.update!(content: nil)
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue for metadata-only updates' do
        document = create(:captain_document, assistant: assistant, account: account, status: :available)
        clear_enqueued_jobs

        expect do
          document.update!(metadata: { 'title' => 'Updated Again' })
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue while document remains in progress' do
        document = create(:captain_document, assistant: assistant, account: account, status: :in_progress)

        expect do
          document.update!(metadata: { 'title' => 'Updated' })
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end
    end

    describe 'PDF documents' do
      def build_pdf_document(status:, content:)
        build(
          :captain_document,
          assistant: assistant,
          account: account,
          status: status,
          content: content
        ).tap do |doc|
          doc.pdf_file.attach(
            io: StringIO.new('PDF content'),
            filename: 'sample.pdf',
            content_type: 'application/pdf'
          )
        end
      end

      it 'enqueues when created available without content' do
        document = build_pdf_document(status: :available, content: nil)

        expect do
          document.save!
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'enqueues when status transitions to available' do
        document = build_pdf_document(status: :in_progress, content: nil)
        document.save!
        clear_enqueued_jobs

        expect do
          document.update!(status: :available)
        end.to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end

      it 'does not enqueue when content updates without status change' do
        document = build_pdf_document(status: :available, content: nil)
        document.save!
        clear_enqueued_jobs

        expect do
          document.update!(content: 'Extracted PDF text')
        end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
      end
    end

    it 'does not enqueue when the document is destroyed' do
      document = create(:captain_document, assistant: assistant, account: account, status: :available)
      clear_enqueued_jobs

      expect do
        document.destroy!
      end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)
    end
  end
end
