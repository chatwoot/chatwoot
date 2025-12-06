require 'rails_helper'

RSpec.describe CustomExceptions::Evolution do
  describe 'Base exception class' do
    subject(:exception) { CustomExceptions::Evolution::Base.new(test_data: 'test') }

    it 'inherits from CustomExceptions::Base' do
      expect(exception).to be_a(CustomExceptions::Base)
    end

    it 'has default error code' do
      expect(exception.error_code).to eq('EVOLUTION_UNKNOWN_ERROR')
    end

    it 'includes error code in hash representation' do
      hash = exception.to_hash
      expect(hash).to include(
        error_code: 'EVOLUTION_UNKNOWN_ERROR',
        http_status: 403
      )
      expect(hash).to have_key(:message)
      expect(hash).to have_key(:timestamp)
    end

    it 'includes timestamp in ISO8601 format' do
      hash = exception.to_hash
      expect { DateTime.iso8601(hash[:timestamp]) }.not_to raise_error
    end
  end

  describe 'ServiceUnavailable' do
    subject(:exception) { CustomExceptions::Evolution::ServiceUnavailable.new({}) }

    it 'has correct HTTP status' do
      expect(exception.http_status).to eq(503)
    end

    it 'has correct error code' do
      expect(exception.error_code).to eq('EVOLUTION_SERVICE_UNAVAILABLE')
    end

    it 'has localized message' do
      expect(exception.message).to eq(I18n.t('errors.evolution.service_unavailable'))
    end
  end

  describe 'AuthenticationError' do
    subject(:exception) { CustomExceptions::Evolution::AuthenticationError.new({}) }

    it 'has correct HTTP status' do
      expect(exception.http_status).to eq(401)
    end

    it 'has correct error code' do
      expect(exception.error_code).to eq('EVOLUTION_AUTH_FAILED')
    end

    it 'has localized message' do
      expect(exception.message).to eq(I18n.t('errors.evolution.authentication_failed'))
    end
  end

  describe 'NetworkTimeout' do
    subject(:exception) { CustomExceptions::Evolution::NetworkTimeout.new({}) }

    it 'has correct HTTP status' do
      expect(exception.http_status).to eq(504)
    end

    it 'has correct error code' do
      expect(exception.error_code).to eq('EVOLUTION_NETWORK_TIMEOUT')
    end

    it 'has localized message' do
      expect(exception.message).to eq(I18n.t('errors.evolution.network_timeout'))
    end
  end

  describe 'InstanceConflict' do
    context 'with instance name' do
      subject(:exception) { CustomExceptions::Evolution::InstanceConflict.new(instance_name: 'test-instance') }

      it 'has correct HTTP status' do
        expect(exception.http_status).to eq(409)
      end

      it 'has correct error code' do
        expect(exception.error_code).to eq('EVOLUTION_INSTANCE_EXISTS')
      end

      it 'includes instance name in message' do
        expect(exception.message).to eq(I18n.t('errors.evolution.instance_exists', instance_name: 'test-instance'))
      end
    end

    context 'without instance name' do
      subject(:exception) { CustomExceptions::Evolution::InstanceConflict.new({}) }

      it 'uses default instance name' do
        expect(exception.message).to eq(I18n.t('errors.evolution.instance_exists', instance_name: 'Unknown'))
      end
    end
  end

  describe 'InvalidConfiguration' do
    context 'with details' do
      subject(:exception) { CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Missing API key') }

      it 'has correct HTTP status' do
        expect(exception.http_status).to eq(400)
      end

      it 'has correct error code' do
        expect(exception.error_code).to eq('EVOLUTION_INVALID_CONFIG')
      end

      it 'includes details in message' do
        expect(exception.message).to eq(I18n.t('errors.evolution.invalid_configuration', details: 'Missing API key'))
      end
    end

    context 'without details' do
      subject(:exception) { CustomExceptions::Evolution::InvalidConfiguration.new({}) }

      it 'uses default error message' do
        expect(exception.message).to eq(I18n.t('errors.evolution.invalid_configuration', details: 'Unknown error'))
      end
    end
  end

  describe 'InstanceCreationFailed' do
    context 'with reason' do
      subject(:exception) { CustomExceptions::Evolution::InstanceCreationFailed.new(reason: 'Invalid payload') }

      it 'has correct HTTP status' do
        expect(exception.http_status).to eq(422)
      end

      it 'has correct error code' do
        expect(exception.error_code).to eq('EVOLUTION_INSTANCE_CREATION_FAILED')
      end

      it 'includes reason in message' do
        expect(exception.message).to eq(I18n.t('errors.evolution.instance_creation_failed', reason: 'Invalid payload'))
      end
    end

    context 'without reason' do
      subject(:exception) { CustomExceptions::Evolution::InstanceCreationFailed.new({}) }

      it 'uses default reason' do
        expect(exception.message).to eq(I18n.t('errors.evolution.instance_creation_failed', reason: 'Unknown reason'))
      end
    end
  end

  describe 'ConnectionRefused' do
    subject(:exception) { CustomExceptions::Evolution::ConnectionRefused.new({}) }

    it 'has correct HTTP status' do
      expect(exception.http_status).to eq(503)
    end

    it 'has correct error code' do
      expect(exception.error_code).to eq('EVOLUTION_CONNECTION_REFUSED')
    end

    it 'has localized message' do
      expect(exception.message).to eq(I18n.t('errors.evolution.connection_refused'))
    end
  end

  describe '.from_http_error' do
    let(:context) { { instance_name: 'test-instance' } }

    it 'maps Net::ReadTimeout to NetworkTimeout' do
      error = Net::ReadTimeout.new
      exception = described_class.from_http_error(error, context)
      expect(exception).to be_a(CustomExceptions::Evolution::NetworkTimeout)
    end

    it 'maps Net::OpenTimeout to NetworkTimeout' do
      error = Net::OpenTimeout.new
      exception = described_class.from_http_error(error, context)
      expect(exception).to be_a(CustomExceptions::Evolution::NetworkTimeout)
    end

    it 'maps Errno::ECONNREFUSED to ConnectionRefused' do
      error = Errno::ECONNREFUSED.new
      exception = described_class.from_http_error(error, context)
      expect(exception).to be_a(CustomExceptions::Evolution::ConnectionRefused)
    end

    it 'maps SocketError to ConnectionRefused' do
      error = SocketError.new
      exception = described_class.from_http_error(error, context)
      expect(exception).to be_a(CustomExceptions::Evolution::ConnectionRefused)
    end

    context 'with HTTParty::ResponseError' do
      let(:response) { double('response', code: status_code, body: 'Error body') }
      let(:error) { HTTParty::ResponseError.new(response) }

      context 'with 401 status code' do
        let(:status_code) { 401 }

        it 'maps to AuthenticationError' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::AuthenticationError)
        end
      end

      context 'with 403 status code' do
        let(:status_code) { 403 }

        it 'maps to AuthenticationError' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::AuthenticationError)
        end
      end

      context 'with 409 status code' do
        let(:status_code) { 409 }

        it 'maps to InstanceConflict' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::InstanceConflict)
        end
      end

      context 'with 422 status code' do
        let(:status_code) { 422 }

        it 'maps to InstanceCreationFailed' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::InstanceCreationFailed)
        end
      end

      context 'with 503 status code' do
        let(:status_code) { 503 }

        it 'maps to ServiceUnavailable' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::ServiceUnavailable)
        end
      end

      context 'with unknown status code' do
        let(:status_code) { 500 }

        it 'maps to InvalidConfiguration' do
          exception = described_class.from_http_error(error, context)
          expect(exception).to be_a(CustomExceptions::Evolution::InvalidConfiguration)
        end
      end
    end
  end

  describe '.map_http_response_error' do
    let(:context) { { instance_name: 'test-instance' } }

    it 'is a private method' do
      expect(described_class.private_methods).to include(:map_http_response_error)
    end

    context 'with unknown error type' do
      let(:error) { StandardError.new('Unknown error') }

      it 'maps to InvalidConfiguration' do
        exception = described_class.from_http_error(error, context)
        expect(exception).to be_a(CustomExceptions::Evolution::InvalidConfiguration)
        expect(exception.instance_variable_get(:@data)[:details]).to eq('Unknown error')
      end
    end
  end
end
