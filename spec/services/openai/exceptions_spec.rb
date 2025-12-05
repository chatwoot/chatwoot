require 'rails_helper'

RSpec.describe 'Openai::Exceptions' do
  describe 'exception hierarchy' do
    it 'TranscriptionError is a StandardError' do
      expect(Openai::Exceptions::TranscriptionError.new).to be_a(StandardError)
    end

    it 'RateLimitError inherits from TranscriptionError' do
      expect(Openai::Exceptions::RateLimitError.new).to be_a(Openai::Exceptions::TranscriptionError)
    end

    it 'NetworkError inherits from TranscriptionError' do
      expect(Openai::Exceptions::NetworkError.new).to be_a(Openai::Exceptions::TranscriptionError)
    end

    it 'InvalidFileError inherits from TranscriptionError' do
      expect(Openai::Exceptions::InvalidFileError.new).to be_a(Openai::Exceptions::TranscriptionError)
    end

    it 'AuthenticationError inherits from TranscriptionError' do
      expect(Openai::Exceptions::AuthenticationError.new).to be_a(Openai::Exceptions::TranscriptionError)
    end
  end

  describe 'raising and rescuing exceptions' do
    it 'can raise and rescue RateLimitError' do
      expect do
        raise Openai::Exceptions::RateLimitError, 'Rate limit exceeded'
      rescue Openai::Exceptions::RateLimitError => e
        expect(e.message).to eq('Rate limit exceeded')
        raise
      end.to raise_error(Openai::Exceptions::RateLimitError)
    end

    it 'can raise and rescue NetworkError' do
      expect do
        raise Openai::Exceptions::NetworkError, 'Network error'
      rescue Openai::Exceptions::NetworkError => e
        expect(e.message).to eq('Network error')
        raise
      end.to raise_error(Openai::Exceptions::NetworkError)
    end

    it 'can raise and rescue InvalidFileError' do
      expect do
        raise Openai::Exceptions::InvalidFileError, 'Invalid file'
      rescue Openai::Exceptions::InvalidFileError => e
        expect(e.message).to eq('Invalid file')
        raise
      end.to raise_error(Openai::Exceptions::InvalidFileError)
    end

    it 'can raise and rescue AuthenticationError' do
      expect do
        raise Openai::Exceptions::AuthenticationError, 'Auth failed'
      rescue Openai::Exceptions::AuthenticationError => e
        expect(e.message).to eq('Auth failed')
        raise
      end.to raise_error(Openai::Exceptions::AuthenticationError)
    end

    it 'can catch all transcription errors with base class' do
      expect do
        raise Openai::Exceptions::RateLimitError, 'Some error'
      rescue Openai::Exceptions::TranscriptionError => e
        expect(e.message).to eq('Some error')
        raise
      end.to raise_error(Openai::Exceptions::RateLimitError)
    end
  end
end
