# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailValidationService, type: :service do
  describe '#validate' do
    let(:service) { described_class.new(email) }

    context 'when email domain is blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with lowercase domain' do
        let(:email) { 'test@gmail.com' }

        it 'raises InvalidEmail exception' do
          expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with uppercase domain' do
        let(:email) { 'test@GMAIL.COM' }

        it 'raises InvalidEmail exception' do
          expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with mixed case domain' do
        let(:email) { 'test@Gmail.com' }

        it 'raises InvalidEmail exception' do
          expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end
    end

    context 'when email domain is not blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return('')
      end

      context 'with valid email' do
        let(:email) { 'test@example.com' }

        it 'does not raise an exception' do
          expect { service.validate }.not_to raise_error
        end
      end

      context 'with invalid email format' do
        let(:email) { 'invalid-email' }

        it 'raises InvalidEmail exception' do
          expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with disposable email' do
        let(:email) { 'test@mailinator.com' }

        it 'raises InvalidEmail exception' do
          expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end
    end
  end

  describe '#business_email?' do
    let(:service) { described_class.new(email) }

    context 'when email domain is blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with lowercase domain' do
        let(:email) { 'test@gmail.com' }

        it 'returns false' do
          expect(service.business_email?).to be(false)
        end
      end

      context 'with uppercase domain' do
        let(:email) { 'test@GMAIL.COM' }

        it 'returns false' do
          expect(service.business_email?).to be(false)
        end
      end
    end

    context 'when email domain is not blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with non-blocked domain' do
        let(:email) { 'test@example.com' }

        it 'returns true' do
          expect(service.business_email?).to be(true)
        end
      end
    end
  end

  describe '#domain_blocked?' do
    let(:service) { described_class.new(email) }

    context 'when email domain is blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with lowercase domain' do
        let(:email) { 'test@gmail.com' }

        it 'returns true' do
          expect(service.domain_blocked?).to be(true)
        end
      end

      context 'with uppercase domain' do
        let(:email) { 'test@GMAIL.COM' }

        it 'returns true' do
          expect(service.domain_blocked?).to be(true)
        end
      end

      context 'with mixed case domain' do
        let(:email) { 'test@Gmail.com' }

        it 'returns true' do
          expect(service.domain_blocked?).to be(true)
        end
      end
    end

    context 'when email domain is not blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with non-blocked domain' do
        let(:email) { 'test@example.com' }

        it 'returns false' do
          expect(service.domain_blocked?).to be(false)
        end
      end
    end
  end
end
