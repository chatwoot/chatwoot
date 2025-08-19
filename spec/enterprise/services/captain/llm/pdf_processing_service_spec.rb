require 'rails_helper'

RSpec.describe Captain::Llm::PdfProcessingService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, account: account, assistant: assistant) }
  let(:service) { described_class.new(document) }

  before do
    # Mock the base class dependencies
    installation_config = instance_double(InstallationConfig, value: 'test-api-key')
    allow(InstallationConfig).to receive(:find_by!)
      .with(name: 'CAPTAIN_OPEN_AI_API_KEY')
      .and_return(installation_config)
  end

  describe '#process' do
    context 'when document already has openai_file_id' do
      before do
        allow(document).to receive(:openai_file_id).and_return('existing-file-id')
      end

      it 'returns success message without uploading' do
        result = service.process
        expect(result).to eq('PDF ready for paginated processing')
      end
    end

    context 'when document needs upload' do
      let(:mock_client) { instance_double(OpenAI::Client) }

      before do
        allow(document).to receive(:openai_file_id).and_return(nil)

        # Create a mock for pdf_file that responds to download
        pdf_file = Struct.new(:download).new('pdf content')
        allow(document).to receive(:pdf_file).and_return(pdf_file)

        # Mock OpenAI client
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        files_api = Object.new
        files_api.define_singleton_method(:upload) { |_params| { 'id' => 'file-abc123' } }
        allow(mock_client).to receive(:files).and_return(files_api)

        allow(document).to receive(:store_openai_file_id)
      end

      it 'uploads PDF and returns success message' do
        expect(document).to receive(:store_openai_file_id).with('file-abc123')

        result = service.process

        expect(result).to include('file-abc123')
        expect(result).to include('PDF ready for paginated processing')
      end
    end
  end
end
