# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::SignUpEmailValidationService, type: :service do
  let(:service) { described_class.new(email) }
  let(:blocked_domains) { "gmail.com\noutlook.com" }
  let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable?: false) }
  let(:disposable_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable?: true) }
  let(:invalid_email_address) { instance_double(ValidEmail2::Address, valid?: false) }

  before do
    allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return(blocked_domains)
  end

  describe '#perform' do
    context 'when email is invalid format' do
      let(:email) { 'invalid-email' }

      it 'raises InvalidEmail with invalid message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(invalid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.invalid_email'))
        end
      end
    end

    context 'when domain is blocked' do
      let(:email) { 'test@gmail.com' }

      it 'raises InvalidEmail with blocked domain message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.blocked_domain'))
        end
      end
    end

    context 'when domain is blocked (case insensitive)' do
      let(:email) { 'test@GMAIL.COM' }

      it 'raises InvalidEmail with blocked domain message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.blocked_domain'))
        end
      end
    end

    context 'when email is from disposable provider' do
      let(:email) { 'test@mailinator.com' }

      it 'raises InvalidEmail with disposable message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(disposable_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error).to be_a(CustomExceptions::Account::InvalidEmail)
          expect(error.message).to eq(I18n.t('errors.signup.disposable_email'))
        end
      end
    end

    context 'when email is valid business email' do
      let(:email) { 'test@example.com' }

      it 'returns true' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end
  end
end
