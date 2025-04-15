# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountBuilder, type: :builder do
  describe '#validate_email' do
    let(:builder) { described_class.new(email: email) }

    context 'when email domain is blocked' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with lowercase domain' do
        let(:email) { 'test@gmail.com' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with uppercase domain' do
        let(:email) { 'test@GMAIL.COM' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with mixed case domain' do
        let(:email) { 'test@Gmail.com' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
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
          expect { builder.send(:validate_email) }.not_to raise_error
        end
      end

      context 'with invalid email format' do
        let(:email) { 'invalid-email' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with disposable email' do
        let(:email) { 'test@mailinator.com' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end
    end

    context 'with actual blocked domains configuration' do
      before do
        allow(GlobalConfigService).to receive(:load).with('BLOCKED_EMAIL_DOMAINS', '').and_return("gmail.com\noutlook.com")
      end

      context 'with blocked domain' do
        let(:email) { 'test@gmail.com' }

        it 'raises InvalidEmail exception' do
          expect { builder.send(:validate_email) }.to raise_error(CustomExceptions::Account::InvalidEmail)
        end
      end

      context 'with non-blocked domain' do
        let(:email) { 'test@example.com' }

        it 'does not raise an exception' do
          expect { builder.send(:validate_email) }.not_to raise_error
        end
      end
    end
  end
end
