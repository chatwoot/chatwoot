# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountBuilder, type: :builder do
  describe '#validate_email' do
    let(:builder) { described_class.new(email: email) }
    let(:email_validation_service) { instance_double(Account::SignUpEmailValidationService) }

    before do
      allow(Account::SignUpEmailValidationService).to receive(:new).with(email).and_return(email_validation_service)
    end

    context 'when email is valid' do
      let(:email) { 'valid@example.com' }

      before do
        allow(email_validation_service).to receive(:validate).and_return(true)
      end

      it 'calls Account::SignUpEmailValidationService#validate' do
        builder.send(:validate_email)
        expect(email_validation_service).to have_received(:validate)
      end
    end

    context 'when email is invalid' do
      let(:email) { 'invalid-email' }

      before do
        allow(email_validation_service).to receive(:validate).and_raise(CustomExceptions::Account::InvalidEmail.new({ valid: false }))
      end

      it 'raises InvalidEmail exception' do
        expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
      end
    end

    context 'when email domain is blocked' do
      let(:email) { 'test@gmail.com' }

      before do
        allow(email_validation_service).to receive(:validate).and_raise(CustomExceptions::Account::InvalidEmail.new({ domain_blocked: true }))
      end

      it 'raises InvalidEmail exception with domain_blocked' do
        expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
      end
    end

    context 'when email is disposable' do
      let(:email) { 'test@mailinator.com' }

      before do
        allow(email_validation_service).to receive(:validate)
          .and_raise(CustomExceptions::Account::InvalidEmail.new({ valid: true, disposable: true }))
      end

      it 'raises InvalidEmail exception with disposable' do
        expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
      end
    end
  end
end
