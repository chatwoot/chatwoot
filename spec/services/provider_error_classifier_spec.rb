require 'rails_helper'

RSpec.describe ProviderErrorClassifier do
  describe '.classify' do
    context 'when the error is a rate-limit / slow-down' do
      it 'classifies Net::SMTPServerBusy as :throttle' do
        expect(described_class.classify(Net::SMTPServerBusy.new('421 4.7.0 Try again later'))).to eq(:throttle)
      end

      it 'classifies an HTTP 429 as :throttle' do
        expect(described_class.classify(StandardError.new('429 Too Many Requests'))).to eq(:throttle)
      end

      it 'classifies a 454 SMTPAuthenticationError (Gmail "too many login attempts") as :throttle' do
        error = Net::SMTPAuthenticationError.new('454 4.7.0 Too many login attempts, please try again later')
        expect(described_class.classify(error)).to eq(:throttle)
      end
    end

    context 'when the error is a network blip' do
      it 'classifies Net::ReadTimeout as :transient' do
        expect(described_class.classify(Net::ReadTimeout.new)).to eq(:transient)
      end

      it 'classifies Errno::ECONNRESET as :transient' do
        expect(described_class.classify(Errno::ECONNRESET.new)).to eq(:transient)
      end

      it 'classifies SocketError as :transient' do
        expect(described_class.classify(SocketError.new('getaddrinfo failed'))).to eq(:transient)
      end

      it 'classifies an SSL error as :transient' do
        expect(described_class.classify(OpenSSL::SSL::SSLError.new('SSL_connect failed'))).to eq(:transient)
      end
    end

    context 'when the error is credentials / permission related' do
      it 'classifies a 535 SMTPAuthenticationError as :auth' do
        error = Net::SMTPAuthenticationError.new('535-5.7.8 Username and Password not accepted')
        expect(described_class.classify(error)).to eq(:auth)
      end

      it 'classifies an OAuth invalid_grant as :auth' do
        expect(described_class.classify(StandardError.new('invalid_grant: Token has been expired or revoked'))).to eq(:auth)
      end

      it 'does not read an HTTP status code in an OAuth error as an SMTP reply code' do
        expect(described_class.classify(StandardError.new('400 invalid_grant: Token expired'))).to eq(:auth)
      end

      it 'classifies O365 SmtpClientAuthentication disabled as :auth' do
        error = Net::SMTPAuthenticationError.new('535 5.7.139 SmtpClientAuthentication is disabled for the Tenant')
        expect(described_class.classify(error)).to eq(:auth)
      end

      it 'matches multi-word auth messages that do not carry an SMTP class or code' do
        expect(described_class.classify(StandardError.new('authentication failed'))).to eq(:auth)
      end
    end

    context 'when the error is permanent' do
      it 'classifies Net::SMTPFatalError (5xx) as :permanent' do
        expect(described_class.classify(Net::SMTPFatalError.new('550 5.1.1 Recipient address rejected'))).to eq(:permanent)
      end

      it 'classifies Net::SMTPSyntaxError as :permanent' do
        expect(described_class.classify(Net::SMTPSyntaxError.new('501 Syntax error'))).to eq(:permanent)
      end

      it 'matches multi-word recipient-rejection messages without an SMTP class or code' do
        expect(described_class.classify(StandardError.new('Recipient address rejected: user unknown'))).to eq(:permanent)
      end
    end

    context 'when the error is unknown or nil' do
      it 'classifies nil as :unknown without raising' do
        expect(described_class.classify(nil)).to eq(:unknown)
      end

      it 'classifies an unrecognised error as :unknown' do
        expect(described_class.classify(StandardError.new('something odd happened'))).to eq(:unknown)
      end

      it 'does not treat a generic HTTP 500 as a permanent SMTP error' do
        expect(described_class.classify(StandardError.new('500 Internal Server Error'))).to eq(:unknown)
      end
    end
  end
end
