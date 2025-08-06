require 'rails_helper'

RSpec.describe Captain::PdfProcessingService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:pdf_file) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join('spec/fixtures/files/sample.pdf')),
      filename: 'sample.pdf',
      content_type: 'application/pdf'
    )
  end
  let(:service) { described_class.new(assistant: assistant, pdf_file: pdf_file) }

  describe '#initialize' do
    it 'initializes with assistant and pdf_file' do
      expect(service.instance_variable_get(:@assistant)).to eq(assistant)
      expect(service.instance_variable_get(:@pdf_file)).to eq(pdf_file)
    end

    it 'raises error when assistant is nil' do
      expect { described_class.new(assistant: nil, pdf_file: pdf_file) }
        .to raise_error(ArgumentError, 'Assistant is required')
    end

    it 'raises error when pdf_file is nil' do
      expect { described_class.new(assistant: assistant, pdf_file: nil) }
        .to raise_error(ArgumentError, 'PDF file is required')
    end
  end

  describe '#perform' do
    let(:openai_client) { instance_double(OpenAI::Client) }
    let(:files_api) { instance_double(OpenAI::Files) }

    before do
      allow(service).to receive(:openai_client).and_return(openai_client)
      allow(openai_client).to receive(:files).and_return(files_api)
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
        allow(files_api).to receive(:upload).and_return(upload_response)
      end

      it 'uploads the PDF file to OpenAI' do
        expect(files_api).to receive(:upload).with(
          parameters: {
            file: anything,
            purpose: 'assistants'
          }
        )

        service.perform
      end

      it 'returns the file ID' do
        result = service.perform
        expect(result).to eq('file-abc123')
      end

      it 'attaches the file to the assistant' do
        allow(service).to receive(:attach_file_to_assistant)

        expect(service).to receive(:attach_file_to_assistant).with('file-abc123')

        service.perform
      end
    end

    context 'when upload fails' do
      before do
        allow(files_api).to receive(:upload).and_raise(StandardError, 'Upload failed')
      end

      it 'raises the error' do
        expect { service.perform }.to raise_error(StandardError, 'Upload failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to upload PDF/)

        expect { service.perform }.to raise_error(StandardError)
      end
    end
  end

  describe '#attach_file_to_assistant' do
    let(:openai_client) { instance_double(OpenAI::Client) }
    let(:assistants_api) { instance_double(OpenAI::Assistants) }
    let(:file_id) { 'file-abc123' }

    before do
      allow(service).to receive(:openai_client).and_return(openai_client)
      allow(openai_client).to receive(:assistants).and_return(assistants_api)
    end

    context 'when attachment is successful' do
      let(:assistant_response) do
        {
          'id' => assistant.openai_id,
          'file_ids' => %w[file-abc123 file-xyz789]
        }
      end

      before do
        allow(assistants_api).to receive(:modify).and_return(assistant_response)
      end

      it 'attaches the file to the assistant' do
        expect(assistants_api).to receive(:modify).with(
          id: assistant.openai_id,
          parameters: {
            file_ids: array_including(file_id)
          }
        )

        service.send(:attach_file_to_assistant, file_id)
      end

      it 'preserves existing file IDs' do
        assistant.update!(file_ids: ['file-existing'])

        expect(assistants_api).to receive(:modify).with(
          id: assistant.openai_id,
          parameters: {
            file_ids: ['file-existing', file_id]
          }
        )

        service.send(:attach_file_to_assistant, file_id)
      end
    end

    context 'when attachment fails' do
      before do
        allow(assistants_api).to receive(:modify).and_raise(StandardError, 'Attachment failed')
      end

      it 'raises the error' do
        expect { service.send(:attach_file_to_assistant, file_id) }
          .to raise_error(StandardError, 'Attachment failed')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to attach file to assistant/)

        expect { service.send(:attach_file_to_assistant, file_id) }
          .to raise_error(StandardError)
      end
    end
  end

  describe '#download_pdf_content' do
    it 'downloads the PDF file content' do
      pdf_file.open do |file|
        content = service.send(:download_pdf_content)
        expect(content).to eq(file.read)
      end
    end

    it 'returns binary content' do
      content = service.send(:download_pdf_content)
      expect(content.encoding).to eq(Encoding::ASCII_8BIT)
    end
  end

  describe 'integration with OpenAI' do
    context 'when OpenAI credentials are configured' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-api-key')
      end

      it 'creates OpenAI client with correct configuration' do
        expect(OpenAI::Client).to receive(:new).with(
          access_token: 'test-api-key',
          request_timeout: 240
        )

        service.send(:openai_client)
      end
    end

    context 'when OpenAI credentials are not configured' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'raises an error' do
        expect { service.send(:openai_client) }
          .to raise_error(StandardError, 'OpenAI API key not configured')
      end
    end
  end
end
