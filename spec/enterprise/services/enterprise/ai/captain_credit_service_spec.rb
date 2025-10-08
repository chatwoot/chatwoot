require 'rails_helper'

describe Enterprise::Ai::CaptainCreditService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

  before do
    allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new).and_return(credit_service)
  end

  describe '#check_and_use_credits' do
    context 'when account is not on v2 billing' do
      it 'returns success without invoking credit service' do
        result = service.check_and_use_credits

        expect(result[:success]).to be(true)
        expect(Enterprise::Billing::V2::CreditManagementService).not_to have_received(:new)
      end
    end

    context 'when account uses v2 billing' do
      before do
        account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_billing_version' => 2))
        allow(credit_service).to receive(:use_credit).and_return(success: true)
      end

      it 'delegates to credit management service with metadata' do
        metadata = { 'feature' => 'ai_reply', 'conversation_id' => 123 }

        result = service.check_and_use_credits(feature: 'ai_reply', metadata: metadata)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:use_credit)
          .with(feature: 'ai_reply', amount: 1, metadata: metadata)
      end
    end
  end

  describe '#has_credits?' do
    context 'when account is not on v2 billing' do
      it 'returns true without checking credit service' do
        expect(service.has_credits?).to be(true)
        expect(Enterprise::Billing::V2::CreditManagementService).not_to have_received(:new)
      end
    end

    context 'when account is on v2 billing' do
      before do
        account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_billing_version' => 2))
        allow(credit_service).to receive(:total_credits).and_return(5)
      end

      it 'returns credit availability from credit service' do
        expect(service.has_credits?).to be(true)
        expect(credit_service).to have_received(:total_credits)
      end
    end
  end
end
