require 'rails_helper'

RSpec.describe Messages::WidgetAudioTranscriptionService, type: :service do
  let(:audio_file) do
    Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.mp3'), 'audio/mpeg')
  end
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:audio_api) { double }

  around do |example|
    with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_API_KEY: 'test-api-key') { example.run }
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    allow(openai_client).to receive(:audio).and_return(audio_api)
    allow(audio_api).to receive(:transcribe).and_return({ 'text' => '  Hello world  ' })
  end

  describe '#perform' do
    subject(:service) { described_class.new(audio_file) }

    it 'returns the transcribed text' do
      expect(service.perform).to eq({ success: true, transcription: 'Hello world' })
    end

    context 'when no OpenAI key is configured' do
      around do |example|
        with_modified_env(WIDGET_TRANSCRIPTION_OPENAI_API_KEY: nil) { example.run }
      end

      it 'returns an error and does not call the API' do
        expect(audio_api).not_to receive(:transcribe)
        expect(service.perform).to eq({ error: 'Audio transcription is not configured' })
      end
    end

    context 'when the audio exceeds the byte limit' do
      before { allow(audio_file).to receive(:size).and_return(described_class::TRANSCRIPTION_BYTE_LIMIT + 1) }

      it 'returns an error without calling the API' do
        expect(audio_api).not_to receive(:transcribe)
        expect(service.perform).to eq({ error: 'Audio too large for transcription' })
      end
    end

    context 'when OpenAI rejects the request' do
      before { allow(audio_api).to receive(:transcribe).and_raise(Faraday::UnauthorizedError) }

      it 'returns a friendly error' do
        expect(service.perform).to eq({ error: 'Transcription service is unavailable' })
      end
    end
  end

  describe '#stage_audio_file' do
    subject(:service) { described_class.new(audio_file) }

    context 'when the upload has no filename extension' do
      let(:audio_file) do
        Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.mp3'), 'audio/ogg', original_filename: 'speech')
      end

      it 'derives the extension from the content type' do
        temp_file_path = service.send(:stage_audio_file)
        expect(File.extname(temp_file_path)).to eq('.ogg')
      ensure
        FileUtils.rm_f(temp_file_path) if temp_file_path.present?
      end
    end

    it 'removes the temporary file after transcription' do
      removed_paths = []
      allow(FileUtils).to receive(:rm_f).and_wrap_original do |method, path|
        removed_paths << path
        method.call(path)
      end

      service.perform

      expect(removed_paths).to be_present
      expect(removed_paths).to all(satisfy { |path| !File.exist?(path) })
    end
  end
end
