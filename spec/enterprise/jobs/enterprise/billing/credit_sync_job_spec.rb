require 'rails_helper'

RSpec.describe Enterprise::Billing::CreditSyncJob, type: :job do
  include ActiveJob::TestHelper

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_SECRET_KEY', nil).and_return('sk_test_123')
    allow(InstallationConfig).to receive(:find_by).and_call_original
    allow(InstallationConfig).to receive(:find_by).with(name: 'STRIPE_METER_ID')
                                                  .and_return(instance_double(InstallationConfig, value: 'mtr_test_123'))
  end

  describe '#perform' do
    context 'with no arguments' do
      let!(:account) do
        create(:account, custom_attributes: {
                 'stripe_customer_id' => 'cus_123',
                 'stripe_billing_version' => 2,
                 'captain_responses_usage' => 100,
                 'stripe_last_synced_credits' => 50
               })
      end

      it 'syncs all accounts with Stripe customer ID' do
        usage_reporter = instance_double(Enterprise::Billing::V2::UsageReporterService)
        allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new).and_return(usage_reporter)
        allow(usage_reporter).to receive(:report).with(50).and_return({ success: true, event_id: 'evt_123' })

        result = described_class.new.perform

        expect(result).to eq({ synced: 1, failed: 0 })
        expect(account.reload.custom_attributes['stripe_last_synced_credits']).to eq(100)
      end
    end

    context 'with account argument' do
      let(:account) do
        create(:account, custom_attributes: {
                 'stripe_customer_id' => 'cus_123',
                 'captain_responses_usage' => 100,
                 'stripe_last_synced_credits' => 30
               })
      end

      it 'syncs single account' do
        usage_reporter = instance_double(Enterprise::Billing::V2::UsageReporterService)
        allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new).and_return(usage_reporter)
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })

        result = described_class.new.perform(account)

        expect(result[:success]).to be true
        expect(result[:credits_reported]).to eq(70)
        expect(account.reload.custom_attributes['stripe_last_synced_credits']).to eq(100)
      end
    end
  end
end
