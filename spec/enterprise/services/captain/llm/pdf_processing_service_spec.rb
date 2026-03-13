require 'rails_helper'

RSpec.describe Captain::Llm::PdfProcessingService do
  let(:document) { create(:captain_document) }
  let(:service) { described_class.new(document) }

  before do
    # Mock OpenAI configuration
    installation_config = instance_double(InstallationConfig, value: 'test-api-key')
    allow(InstallationConfig).to receive(:find_by!)
      .with(name: 'CAPTAIN_OPEN_AI_API_KEY')
      .and_return(installation_config)
  end

  describe '#process' do
    context 'when document already has OpenAI file ID' do
      before do
        allow(document).to receive(:openai_file_id).and_return('existing-file-id')
      end

      it 'skips upload' do
        expect(document).not_to receive(:store_openai_file_id)
        service.process
      end
    end

    context 'when uploading PDF to OpenAI' do
      let(:mock_client) { instance_double(OpenAI::Client) }
      let(:pdf_content) { 'PDF content' }
      let(:blob_double) { instance_double(ActiveStorage::Blob) }
      let(:pdf_file) { instance_double(ActiveStorage::Attachment) }

      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
        allow(document).to receive(:pdf_file).and_return(pdf_file)
        allow(pdf_file).to receive(:blob).and_return(blob_double)
        allow(blob_double).to receive(:open).and_yield(StringIO.new(pdf_content))

        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        # Use a simple double for OpenAI::Files as it may not be loaded
        files_api = double('files_api') # rubocop:disable RSpec/VerifiedDoubles
        allow(files_api).to receive(:upload).and_return({ 'id' => 'file-abc123' })
        allow(mock_client).to receive(:files).and_return(files_api)
      end

      it 'uploads PDF and stores file ID' do
        expect(document).to receive(:store_openai_file_id).with('file-abc123')
        service.process
      end

      it 'raises error when upload fails' do
        allow(mock_client.files).to receive(:upload).and_return({ 'id' => nil })

        expect { service.process }.to raise_error(CustomExceptions::Pdf::UploadError)
      end
    end
  end
end
