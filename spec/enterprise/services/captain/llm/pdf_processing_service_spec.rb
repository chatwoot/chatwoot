require 'rails_helper'

RSpec.describe Captain::Llm::PdfProcessingService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, account: account, assistant: assistant) }
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:service) do
    # Mock the InstallationConfig for base class initialization
    allow(InstallationConfig).to receive(:find_by!).with(name: 'CAPTAIN_OPEN_AI_API_KEY')
                                                   .and_return(instance_double(InstallationConfig, value: 'test-api-key'))
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    described_class.new(document)
  end

  describe '#initialize' do
    it 'initializes with document' do
      expect(service.instance_variable_get(:@document)).to eq(document)
    end
  end

  describe '#process' do
    let(:files_api) { instance_double(OpenAI::Files) }
    let(:temp_file) { instance_double(Tempfile) }
    let(:pdf_attachment) { double('pdf_attachment') } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(openai_client).to receive(:files).and_return(files_api)
      allow(document).to receive(:pdf_file).and_return(pdf_attachment)
      allow(pdf_attachment).to receive(:download).and_return('pdf content')
      allow(Tempfile).to receive(:new).and_return(temp_file)
      allow(temp_file).to receive(:binmode)
      allow(temp_file).to receive(:write)
      allow(temp_file).to receive(:close)
      allow(temp_file).to receive(:path).and_return('/tmp/test.pdf')
      allow(temp_file).to receive(:unlink)
      allow(File).to receive(:open).with('/tmp/test.pdf', 'rb').and_yield(StringIO.new('pdf content'))
    end

    context 'when document already has openai_file_id' do
      before do
        allow(document).to receive(:openai_file_id).and_return('existing-file-id')
      end

      it 'returns success message without uploading' do
        expect(files_api).not_to receive(:upload)
        result = service.process
        expect(result).to eq('PDF ready for paginated processing')
      end
    end

    context 'when upload is successful' do
      let(:upload_response) do
        {
          'id' => 'file-abc123',
          'object' => 'file',
          'bytes' => 120_000,
          'created_at' => 1_677_610_602,
          'filename' => 'sample.pdf',
          'purpose' => 'assistants'
        }
      end

      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
        allow(files_api).to receive(:upload).and_return(upload_response)
        allow(document).to receive(:store_openai_file_id)
      end

      it 'uploads the PDF file to OpenAI' do
        expect(files_api).to receive(:upload).with(
          parameters: {
            file: anything,
            purpose: 'assistants'
          }
        )

        service.process
      end

      it 'returns success message with file ID' do
        result = service.process
        expect(result).to include('file-abc123')
        expect(result).to include('PDF ready for paginated processing')
      end

      it 'stores the file ID in document' do
        expect(document).to receive(:store_openai_file_id).with('file-abc123')
        service.process
      end
    end

    context 'when upload fails' do
      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
        allow(files_api).to receive(:upload).and_raise(StandardError, 'Upload failed')
      end

      it 'raises the error' do
        expect { service.process }.to raise_error(StandardError, 'Upload failed')
      end
    end

    context 'when file_id is missing from response' do
      let(:invalid_response) do
        {
          'object' => 'file',
          'bytes' => 120_000
        }
      end

      before do
        allow(document).to receive(:openai_file_id).and_return(nil)
        allow(files_api).to receive(:upload).and_return(invalid_response)
      end

      it 'raises an error' do
        expect { service.process }.to raise_error('Failed to upload PDF to OpenAI')
      end
    end
  end
end
