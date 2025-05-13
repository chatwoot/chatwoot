# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseOverrides::OmniauthCallbacksController do
  describe '#validate_business_account?' do
    let(:auth_hash) do
      {
        'info' => {
          'email' => email
        }
      }
    end

    before do
      allow(controller).to receive(:auth_hash).and_return(auth_hash)
    end

    context 'when using EmailValidationService' do
      let(:email) { 'test@example.com' }
      let(:email_validation_service) { instance_double(EmailValidationService) }

      before do
        allow(EmailValidationService).to receive(:new).with(email).and_return(email_validation_service)
      end

      it 'delegates to EmailValidationService#business_email?' do
        allow(email_validation_service).to receive(:business_email?).and_return(true)
        result = controller.send(:validate_business_account?)
        expect(result).to be(true)
        expect(email_validation_service).to have_received(:business_email?)
      end

      context 'when domain is blocked' do
        let(:email) { 'test@gmail.com' }

        it 'returns false when domain is blocked' do
          allow(email_validation_service).to receive(:business_email?).and_return(false)
          result = controller.send(:validate_business_account?)
          expect(result).to be(false)
        end
      end

      context 'when domain is not blocked' do
        let(:email) { 'test@company.com' }

        it 'returns true when domain is not blocked' do
          allow(email_validation_service).to receive(:business_email?).and_return(true)
          result = controller.send(:validate_business_account?)
          expect(result).to be(true)
        end
      end
    end
  end
end
