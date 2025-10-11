require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles

describe Enterprise::Billing::V2::WebhookHandlerService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

  before do
    account.update!(custom_attributes: { 'stripe_billing_version' => 2 })
    allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new).with(account: account).and_return(credit_service)
  end

  def build_event(type:, object:)
    data = double('Stripe::Event::Data', object: object)
    double('Stripe::Event', type: type, data: data)
  end

  describe '#process' do
    context 'when handling monthly credit grant' do
      it 'syncs monthly credits from Stripe' do
        allow(credit_service).to receive(:sync_monthly_credits)
        grant = OpenStruct.new(
          amount: { 'custom_pricing_unit' => { 'value' => '2000' } },
          expires_at: Time.current
        )
        event = build_event(type: 'billing.credit_grant.created', object: grant)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:sync_monthly_credits).with(2000)
      end
    end

    context 'when handling topup credit grant' do
      it 'adds topup credits' do
        allow(credit_service).to receive(:add_topup_credits)
        grant = OpenStruct.new(
          amount: { 'custom_pricing_unit' => { 'value' => '500' } },
          expires_at: nil
        )
        event = build_event(type: 'billing.credit_grant.created', object: grant)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:add_topup_credits).with(500)
      end
    end

    context 'when handling credit expiration' do
      it 'expires monthly credits' do
        allow(credit_service).to receive(:expire_monthly_credits).and_return(100)
        event = build_event(type: 'billing.credit_grant.expired', object: {})

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:expire_monthly_credits)
      end
    end

    context 'when handling unknown event' do
      it 'returns success' do
        event = build_event(type: 'unknown.event', object: {})

        result = service.process(event)

        expect(result[:success]).to be(true)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
