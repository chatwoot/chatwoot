require 'rails_helper'
# rubocop:disable RSpec/VerifiedDoubles

describe Enterprise::Billing::V2::WebhookHandlerService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:credit_service) { instance_double(Enterprise::Billing::V2::CreditManagementService) }

  before do
    account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_billing_version' => 2))
    allow(Enterprise::Billing::V2::CreditManagementService).to receive(:new).with(account: account).and_return(credit_service)
  end

  def build_event(type:, id:, object:)
    data = double('Stripe::Event::Data', object: object)
    double('Stripe::Event', type: type, id: id, data: data)
  end

  describe '#process' do
    context 'when handling monthly credit grant' do
      it 'grants monthly credits with metadata' do
        allow(credit_service).to receive(:grant_monthly_credits).and_return(success: true)
        grant = Struct.new(:id, :amount, :expires_at).new('cg_123', 2000, Time.current)
        event = build_event(type: 'billing.credit_grant.created', id: 'evt_123', object: grant)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:grant_monthly_credits).with(2000,
                                                                             metadata: hash_including('stripe_event_id' => 'evt_123',
                                                                                                      'grant_id' => 'cg_123'))
      end
    end

    context 'when handling topup credit grant' do
      it 'adds topup credits' do
        allow(credit_service).to receive(:add_topup_credits).and_return(success: true)
        grant = Struct.new(:id, :amount, :expires_at).new('cg_456', 500, nil)
        event = build_event(type: 'billing.credit_grant.created', id: 'evt_456', object: grant)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:add_topup_credits)
          .with(500, metadata: hash_including('stripe_event_id' => 'evt_456', 'grant_id' => 'cg_456', 'source' => 'credit_grant'))
      end
    end

    context 'when invoice payment succeeded for a topup' do
      it 'adds topup credits from invoice metadata' do
        allow(credit_service).to receive(:add_topup_credits).and_return(success: true)
        invoice_metadata = ActiveSupport::HashWithIndifferentAccess.new(type: 'topup', credits: '300')
        invoice = Struct.new(:id, :metadata).new('in_123', invoice_metadata)
        event = build_event(type: 'invoice.payment_succeeded', id: 'evt_789', object: invoice)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).to have_received(:add_topup_credits)
          .with(300, metadata: hash_including('stripe_event_id' => 'evt_789', 'invoice_id' => 'in_123', 'source' => 'invoice'))
      end
    end

    context 'when event already processed' do
      it 'skips duplicate handling' do
        account.credit_transactions.create!(
          transaction_type: 'grant',
          amount: 100,
          credit_type: 'monthly',
          metadata: { 'stripe_event_id' => 'evt_dup' }
        )
        allow(credit_service).to receive(:grant_monthly_credits)
        grant = Struct.new(:id, :amount, :expires_at).new('cg_dup', 200, Time.current)
        event = build_event(type: 'billing.credit_grant.created', id: 'evt_dup', object: grant)

        result = service.process(event)

        expect(result[:success]).to be(true)
        expect(credit_service).not_to have_received(:grant_monthly_credits)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
