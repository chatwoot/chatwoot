# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::SignUpEmailValidationService, type: :service do
  let(:service) { described_class.new(email) }
  let(:blocked_domains) { "gmail.com\noutlook.com" }

  before do
    allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return(blocked_domains)
  end

  describe '#validate' do
    context 'with blocked domain' do
      let(:email) { 'test@gmail.com' }

      it 'raises InvalidEmail exception' do
        expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
      end
    end

    context 'with case insensitive matching' do
      let(:email) { 'test@GMAIL.COM' }

      it 'raises InvalidEmail exception' do
        expect { service.validate }.to raise_error(CustomExceptions::Account::InvalidEmail)
      end
    end

    context 'with valid non-blocked email' do
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

  describe '#business_email?' do
    context 'with blocked domain' do
      let(:email) { 'test@gmail.com' }

      it 'returns false' do
        expect(service.business_email?).to be(false)
      end
    end

    context 'with non-blocked domain' do
      let(:email) { 'test@example.com' }

      it 'returns true' do
        expect(service.business_email?).to be(true)
      end
    end
  end

  describe '#domain_blocked?' do
    context 'with blocked domain (case insensitive)' do
      let(:email) { 'test@Gmail.com' }

      it 'returns true' do
        expect(service.domain_blocked?).to be(true)
      end
    end

    context 'with non-blocked domain' do
      let(:email) { 'test@example.com' }

      it 'returns false' do
        expect(service.domain_blocked?).to be(false)
      end
    end
  end
end
