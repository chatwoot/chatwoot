require 'rails_helper'

RSpec.describe StickerErrorLoggerService, type: :service do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:service) { described_class.new }

  before do
    Rails.cache.clear
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:info)
  end

  describe '.log_error' do
    it 'creates new instance and calls log_error' do
      expect_any_instance_of(described_class).to receive(:log_error).with(
        error_code: 'TEST_ERROR',
        error_message: 'Test message',
        context: { test: 'data' },
        user: user,
        account: account
      )

      described_class.log_error(
        error_code: 'TEST_ERROR',
        error_message: 'Test message',
        context: { test: 'data' },
        user: user,
        account: account
      )
    end
  end

  describe '#log_error' do
    context 'with critical error' do
      let(:error_code) { 'GIPHY_API_KEY_MISSING' }
      let(:error_message) { 'API key not configured' }
      let(:context) { { provider: 'giphy', action: 'search' } }

      it 'logs error with critical severity' do
        result = service.log_error(
          error_code: error_code,
          error_message: error_message,
          context: context,
          user: user,
          account: account
        )

        expect(result[:severity]).to eq('critical')
        expect(result[:error_code]).to eq(error_code)
        expect(result[:error_message]).to eq(error_message)
        expect(result[:user_id]).to eq(user.id)
        expect(result[:account_id]).to eq(account.id)
        expect(result[:feature]).to eq('sticker_library')
        expect(result[:timestamp]).to be_present
      end

      it 'logs to Rails logger with error level' do
        service.log_error(
          error_code: error_code,
          error_message: error_message,
          context: context,
          user: user,
          account: account
        )

        expect(Rails.logger).to have_received(:error).with(/\[STICKER_CRITICAL\]/)
      end

      it 'increments error metrics' do
        service.log_error(
          error_code: error_code,
          error_message: error_message,
          context: context,
          user: user,
          account: account
        )

        expect(Rails.cache.read('sticker_errors_total')).to eq(1)
        expect(Rails.cache.read('sticker_errors_critical')).to eq(1)
        expect(Rails.cache.read('sticker_error_giphy_api_key_missing')).to eq(1)
      end
    end

    context 'with high priority error' do
      let(:error_code) { 'GIPHY_UNAVAILABLE' }
      let(:error_message) { 'Service temporarily unavailable' }

      it 'logs error with high severity' do
        result = service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(result[:severity]).to eq('high')
      end

      it 'logs to Rails logger with warn level' do
        service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(Rails.logger).to have_received(:warn).with(/\[STICKER_HIGH\]/)
      end

      it 'increments high priority metrics' do
        service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(Rails.cache.read('sticker_errors_high')).to eq(1)
      end
    end

    context 'with medium priority error' do
      let(:error_code) { 'CUSTOM_ERROR' }
      let(:error_message) { 'Some custom error' }

      it 'logs error with medium severity' do
        result = service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(result[:severity]).to eq('medium')
      end

      it 'logs to Rails logger with info level' do
        service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(Rails.logger).to have_received(:info).with(/\[STICKER_INFO\]/)
      end

      it 'increments medium priority metrics' do
        service.log_error(
          error_code: error_code,
          error_message: error_message
        )

        expect(Rails.cache.read('sticker_errors_medium')).to eq(1)
      end
    end

    context 'context sanitization' do
      let(:sensitive_context) do
        {
          api_key: 'secret_key_123',
          token: 'auth_token_456',
          password: 'user_password',
          safe_data: 'this is safe',
          long_string: 'x' * 1500
        }
      end

      it 'removes sensitive information from context' do
        result = service.log_error(
          error_code: 'TEST_ERROR',
          error_message: 'Test',
          context: sensitive_context
        )

        sanitized_context = result[:context]
        expect(sanitized_context).not_to have_key(:api_key)
        expect(sanitized_context).not_to have_key(:token)
        expect(sanitized_context).not_to have_key(:password)
        expect(sanitized_context[:safe_data]).to eq('this is safe')
      end

      it 'truncates long strings in context' do
        result = service.log_error(
          error_code: 'TEST_ERROR',
          error_message: 'Test',
          context: sensitive_context
        )

        expect(result[:context][:long_string]).to end_with('...')
        expect(result[:context][:long_string].length).to eq(1000)
      end
    end

    context 'error metrics handling' do
      it 'handles metrics increment failures gracefully' do
        allow(Rails.cache).to receive(:increment).and_raise(StandardError.new('Cache error'))
        expect(Rails.logger).to receive(:warn).with(/Failed to increment error metrics/)

        expect do
          service.log_error(
            error_code: 'TEST_ERROR',
            error_message: 'Test'
          )
        end.not_to raise_error
      end
    end

    context 'alerting' do
      before do
        allow(service).to receive(:should_send_alerts?).and_return(true)
        allow(service).to receive(:send_critical_alert)
      end

      it 'sends alert for critical errors' do
        service.log_error(
          error_code: 'UNKNOWN_ERROR',
          error_message: 'Critical failure',
          account: account
        )

        expect(service).to have_received(:send_critical_alert)
      end

      it 'does not send alert for non-critical errors' do
        service.log_error(
          error_code: 'GIPHY_UNAVAILABLE',
          error_message: 'Service down'
        )

        expect(service).not_to have_received(:send_critical_alert)
      end

      it 'respects alert cooldown period' do
        # First alert should be sent
        service.log_error(
          error_code: 'UNKNOWN_ERROR',
          error_message: 'Critical failure',
          account: account
        )

        expect(service).to have_received(:send_critical_alert).once

        # Second alert within cooldown should not be sent
        service.log_error(
          error_code: 'UNKNOWN_ERROR',
          error_message: 'Critical failure',
          account: account
        )

        expect(service).to have_received(:send_critical_alert).once
      end

      it 'does not send alerts when disabled' do
        allow(service).to receive(:should_send_alerts?).and_return(false)

        service.log_error(
          error_code: 'UNKNOWN_ERROR',
          error_message: 'Critical failure'
        )

        expect(service).not_to have_received(:send_critical_alert)
      end
    end
  end

  describe '.error_stats' do
    before do
      # Simulate some errors
      Rails.cache.write('sticker_errors_total', 10)
      Rails.cache.write('sticker_errors_critical', 2)
      Rails.cache.write('sticker_errors_high', 5)
      Rails.cache.write('sticker_errors_medium', 3)
      Rails.cache.write('sticker_error_giphy_api_key_missing', 1)
      Rails.cache.write('sticker_error_giphy_unavailable', 3)
    end

    it 'returns comprehensive error statistics' do
      stats = described_class.error_stats

      expect(stats[:total_errors]).to eq(10)
      expect(stats[:critical_errors]).to eq(2)
      expect(stats[:high_priority_errors]).to eq(5)
      expect(stats[:medium_priority_errors]).to eq(3)
      expect(stats[:time_period]).to eq(1.hour)
    end

    it 'includes error breakdown by type' do
      stats = described_class.error_stats

      expect(stats[:error_breakdown]['GIPHY_API_KEY_MISSING']).to eq(1)
      expect(stats[:error_breakdown]['GIPHY_UNAVAILABLE']).to eq(3)
    end

    it 'excludes zero counts from breakdown' do
      stats = described_class.error_stats

      expect(stats[:error_breakdown]).not_to have_key('WHATSAPP_AUTH_ERROR')
    end

    it 'accepts custom time period' do
      stats = described_class.error_stats(time_period: 24.hours)

      expect(stats[:time_period]).to eq(24.hours)
    end
  end

  describe '.error_breakdown' do
    before do
      Rails.cache.write('sticker_error_giphy_api_key_missing', 2)
      Rails.cache.write('sticker_error_validation_error', 5)
      Rails.cache.write('sticker_error_unknown_error', 0)
    end

    it 'returns breakdown of specific error types' do
      breakdown = described_class.error_breakdown

      expect(breakdown['GIPHY_API_KEY_MISSING']).to eq(2)
      expect(breakdown['VALIDATION_ERROR']).to eq(5)
    end

    it 'excludes errors with zero count' do
      breakdown = described_class.error_breakdown

      expect(breakdown).not_to have_key('UNKNOWN_ERROR')
    end
  end

  describe '.reset_error_stats' do
    before do
      Rails.cache.write('sticker_errors_total', 10)
      Rails.cache.write('sticker_error_test', 5)
    end

    it 'clears all error statistics' do
      described_class.reset_error_stats

      expect(Rails.cache.read('sticker_errors_total')).to be_nil
      expect(Rails.cache.read('sticker_error_test')).to be_nil
    end

    it 'logs the reset action' do
      expect(Rails.logger).to receive(:info).with(/Error statistics reset/)

      described_class.reset_error_stats
    end
  end

  describe 'private methods' do
    describe '#determine_severity' do
      it 'returns critical for critical errors' do
        severity = service.send(:determine_severity, 'GIPHY_API_KEY_MISSING')
        expect(severity).to eq('critical')
      end

      it 'returns high for high priority errors' do
        severity = service.send(:determine_severity, 'GIPHY_UNAVAILABLE')
        expect(severity).to eq('high')
      end

      it 'returns medium for other errors' do
        severity = service.send(:determine_severity, 'CUSTOM_ERROR')
        expect(severity).to eq('medium')
      end
    end

    describe '#should_send_alerts?' do
      it 'returns true in production' do
        allow(Rails.env).to receive(:production?).and_return(true)
        expect(service.send(:should_send_alerts?)).to be true
      end

      it 'returns true when explicitly enabled' do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(ENV).to receive(:[]).with('STICKER_ALERTS_ENABLED').and_return('true')
        expect(service.send(:should_send_alerts?)).to be true
      end

      it 'returns false in development without explicit enable' do
        allow(Rails.env).to receive(:production?).and_return(false)
        allow(ENV).to receive(:[]).with('STICKER_ALERTS_ENABLED').and_return(nil)
        expect(service.send(:should_send_alerts?)).to be false
      end
    end

    describe '#build_alert_message' do
      let(:log_data) do
        {
          error_code: 'CRITICAL_ERROR',
          error_message: 'Something went wrong',
          account_id: 123,
          user_id: 456,
          timestamp: '2024-01-01T10:00:00Z',
          context: { test: 'data' }
        }
      end

      it 'builds properly formatted alert message' do
        message = service.send(:build_alert_message, log_data)
        parsed = JSON.parse(message)

        expect(parsed['title']).to eq('Critical Sticker Library Error')
        expect(parsed['message']).to include('CRITICAL_ERROR')
        expect(parsed['message']).to include('Something went wrong')
        expect(parsed['account_id']).to eq(123)
        expect(parsed['user_id']).to eq(456)
        expect(parsed['timestamp']).to eq('2024-01-01T10:00:00Z')
        expect(parsed['context']).to eq({ 'test' => 'data' })
      end
    end
  end
end