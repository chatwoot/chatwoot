require 'rails_helper'

RSpec.describe Openai::AudioTranscriptionService do
  let(:audio_url) { 'https://example.com/audio.ogg' }
  let(:api_key_env) { 'env-api-key-12345' }
  let(:api_key_integration) { 'integration-api-key-67890' }

  before do
    # Set environment variable
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(api_key_env)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://frontend.example.com')
  end

  describe '#initialize' do
    context 'when account is provided with enabled OpenAI integration' do
      let(:account) { create(:account) }
      let!(:integration) do
        create(:integrations_hook, :openai,
               account: account,
               settings: { 'api_key' => api_key_integration })
      end

      it 'uses API key from integration settings' do
        service = described_class.new(audio_url, account: account)
        expect(service.instance_variable_get(:@api_key)).to eq(api_key_integration)
      end

      it 'logs that integration API key is being used' do
        allow(Rails.logger).to receive(:debug)
        described_class.new(audio_url, account: account)
        expect(Rails.logger).to have_received(:debug).with("Using OpenAI API key from integration for account #{account.id}")
      end
    end

    context 'when account is provided with disabled OpenAI integration' do
      let(:account) { create(:account) }
      let!(:integration) do
        create(:integrations_hook, :openai,
               account: account,
               status: 'disabled',
               settings: { 'api_key' => api_key_integration })
      end

      it 'falls back to environment variable' do
        service = described_class.new(audio_url, account: account)
        expect(service.instance_variable_get(:@api_key)).to eq(api_key_env)
      end

      it 'logs that environment variable is being used' do
        allow(Rails.logger).to receive(:debug)
        described_class.new(audio_url, account: account)
        expect(Rails.logger).to have_received(:debug).with('Using OpenAI API key from environment variable')
      end
    end

    context 'when account is provided without OpenAI integration' do
      let(:account) { create(:account) }

      it 'falls back to environment variable' do
        service = described_class.new(audio_url, account: account)
        expect(service.instance_variable_get(:@api_key)).to eq(api_key_env)
      end

      it 'logs that environment variable is being used' do
        allow(Rails.logger).to receive(:debug)
        described_class.new(audio_url, account: account)
        expect(Rails.logger).to have_received(:debug).with('Using OpenAI API key from environment variable')
      end
    end

    context 'when account is not provided' do
      it 'uses environment variable' do
        service = described_class.new(audio_url)
        expect(service.instance_variable_get(:@api_key)).to eq(api_key_env)
      end

      it 'logs that environment variable is being used' do
        allow(Rails.logger).to receive(:debug)
        described_class.new(audio_url)
        expect(Rails.logger).to have_received(:debug).with('Using OpenAI API key from environment variable')
      end
    end

    context 'when no API key is available anywhere' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(nil)
      end

      it 'sets API key to nil' do
        service = described_class.new(audio_url)
        expect(service.instance_variable_get(:@api_key)).to be_nil
      end
    end

    context 'when integration has empty api_key' do
      let(:account) { create(:account) }
      let!(:integration) do
        create(:integrations_hook, :openai,
               account: account,
               settings: { 'api_key' => '' })
      end

      it 'falls back to environment variable' do
        service = described_class.new(audio_url, account: account)
        expect(service.instance_variable_get(:@api_key)).to eq(api_key_env)
      end
    end
  end

  describe '#process' do
    let(:service) { described_class.new(audio_url) }
    let(:tempfile) { instance_double(Tempfile, path: '/tmp/audio.ogg', close: true, unlink: true) }
    let(:transcription_response) do
      {
        'text' => 'Hello, this is a test transcription.',
        'language' => 'en',
        'duration' => 5.2
      }
    end

    context 'when API key is not configured' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(nil)
      end

      it 'returns nil and logs info message' do
        service = described_class.new(audio_url)
        allow(Rails.logger).to receive(:info)

        result = service.process

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:info).with('OpenAI API key is not configured')
      end
    end

    context 'when audio file download fails' do
      before do
        allow(Down).to receive(:download).and_raise(StandardError, 'Download failed')
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:error)
      end

      it 'returns nil and logs error' do
        result = service.process

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Error downloading audio file: Download failed/)
      end
    end

    context 'when transcription is successful' do
      before do
        allow(Down).to receive(:download).and_return(tempfile)
        allow(described_class).to receive(:post).and_return(
          double(success?: true, parsed_response: transcription_response)
        )
        allow(Rails.logger).to receive(:debug)
      end

      it 'returns transcription hash' do
        result = service.process

        expect(result).to eq({
                               text: 'Hello, this is a test transcription.',
                               language: 'en',
                               duration: 5.2
                             })
      end

      it 'logs debug messages' do
        service.process

        expect(Rails.logger).to have_received(:debug).with('Making API request to OpenAI for transcription')
        expect(Rails.logger).to have_received(:debug).with('Successfully received transcription from OpenAI')
      end

      it 'cleans up temporary file' do
        service.process

        expect(tempfile).to have_received(:close)
        expect(tempfile).to have_received(:unlink)
      end
    end

    context 'when OpenAI API returns error' do
      before do
        allow(Down).to receive(:download).and_return(tempfile)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:error)
      end

      it 'raises authentication error for 401' do
        allow(described_class).to receive(:post).and_return(
          double(success?: false, code: 401, body: 'Invalid API key')
        )

        expect { service.process }.to raise_error(Openai::Exceptions::AuthenticationError, /Authentication failed/)
      end

      it 'raises rate limit error for 429' do
        allow(described_class).to receive(:post).and_return(
          double(success?: false, code: 429, body: 'Rate limit exceeded')
        )

        expect { service.process }.to raise_error(Openai::Exceptions::RateLimitError, /Rate limit exceeded/)
      end

      it 'raises invalid file error for 400' do
        allow(described_class).to receive(:post).and_return(
          double(success?: false, code: 400, body: 'Invalid audio file')
        )

        expect { service.process }.to raise_error(Openai::Exceptions::InvalidFileError, /Invalid file/)
      end

      it 'ensures file cleanup even when error occurs' do
        allow(described_class).to receive(:post).and_return(
          double(success?: false, code: 500, body: 'Server error')
        )

        expect { service.process }.to raise_error(Openai::Exceptions::NetworkError)
        expect(tempfile).to have_received(:close)
        expect(tempfile).to have_received(:unlink)
      end
    end
  end

  describe 'backward compatibility' do
    it 'works without account parameter (legacy usage)' do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(api_key_env)

      service = described_class.new(audio_url)
      expect(service.instance_variable_get(:@api_key)).to eq(api_key_env)
    end

    it 'maintains the same public interface' do
      service = described_class.new(audio_url)
      expect(service).to respond_to(:process)
    end
  end
end
