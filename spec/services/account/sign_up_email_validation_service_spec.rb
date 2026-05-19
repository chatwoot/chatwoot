# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::SignUpEmailValidationService, type: :service do
  let(:service) { described_class.new(email) }
  let(:blocked_domains) { "gmail.com\noutlook.com" }
  let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false, deny_listed?: false) }
  let(:free_provider_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false, deny_listed?: true) }
  let(:disposable_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: true) }
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
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.invalid_email'))
        end
      end
    end

    context 'when domain is blocked' do
      let(:email) { 'test@gmail.com' }

      it 'raises InvalidEmail with blocked domain message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.blocked_domain'))
        end
      end
    end

    context 'when domain is blocked (case insensitive)' do
      let(:email) { 'test@GMAIL.COM' }

      it 'raises InvalidEmail with blocked domain message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.blocked_domain'))
        end
      end
    end

    context 'when email is from disposable provider' do
      let(:email) { 'test@mailinator.com' }

      it 'raises InvalidEmail with disposable message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(disposable_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.disposable_email'))
        end
      end
    end

    context 'when email is from a free provider' do
      let(:email) { 'test@example.com' }

      it 'raises InvalidEmail with free email provider message' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(free_provider_email_address)
        expect { service.perform }.to raise_error do |error|
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.free_email_provider'))
        end
      end
    end

    context 'when email is valid business email' do
      let(:email) { 'test@chatwoot.com' }

      it 'returns true' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end
  end

  # Exercises the real ValidEmail2 + config/deny_listed_email_domains.yml
  # integration without stubbing ValidEmail2::Address. Guards against the YAML
  # file going missing, the path drifting, or upstream API renames.
  describe '#perform with the real deny list' do
    before do
      allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return('')
    end

    %w[user@gmail.com user@outlook.com user@hotmail.com user@yahoo.com user@protonmail.com user@icloud.com].each do |email|
      it "rejects #{email} with the free_email_provider message" do
        expect { described_class.new(email).perform }.to raise_error do |error|
          expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
          expect(error.message).to eq(I18n.t('errors.signup.free_email_provider'))
        end
      end
    end

    it 'rejects a subdomain of a free provider via ValidEmail2 depth walking' do
      expect { described_class.new('user@mail.gmail.com').perform }.to raise_error do |error|
        expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
        expect(error.message).to eq(I18n.t('errors.signup.free_email_provider'))
      end
    end

    it 'allows a real business domain' do
      expect(described_class.new('hello@chatwoot.com').perform).to be(true)
    end

    it 'still rejects a disposable email with the disposable message, not the free_email message' do
      expect { described_class.new('user@mailinator.com').perform }.to raise_error do |error|
        expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
        expect(error.message).to eq(I18n.t('errors.signup.disposable_email'))
      end
    end

    it 'allows free email providers when allow_free_email_provider is true' do
      expect(described_class.new('admin@gmail.com', allow_free_email_provider: true).perform).to be(true)
    end

    it 'still rejects disposable emails even when allow_free_email_provider is true' do
      expect { described_class.new('user@mailinator.com', allow_free_email_provider: true).perform }.to raise_error do |error|
        expect(error.class.name).to eq('CustomExceptions::Account::InvalidEmail')
        expect(error.message).to eq(I18n.t('errors.signup.disposable_email'))
      end
    end
  end
end
