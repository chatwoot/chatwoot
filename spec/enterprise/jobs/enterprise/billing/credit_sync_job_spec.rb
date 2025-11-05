require 'rails_helper'

RSpec.describe Enterprise::Billing::CreditSyncJob, type: :job do
  include ActiveJob::TestHelper

  let(:stripe_customer_id) { 'cus_12345678' }
  let(:meter_id) { 'mtr_test_123' }
  let(:stripe_secret_key) { 'sk_test_123' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_BILLING_V2_ENABLED', 'false').and_return('true')
    allow(ENV).to receive(:fetch).with('STRIPE_SECRET_KEY', nil).and_return(stripe_secret_key)
    allow(InstallationConfig).to receive(:find_by).and_call_original
    allow(InstallationConfig).to receive(:find_by).with(name: 'STRIPE_METER_ID')
                                                  .and_return(instance_double(InstallationConfig, value: meter_id))
  end

  describe '#perform' do
    describe 'syncing all accounts' do
      let!(:account_with_stripe) do
        create(:account, custom_attributes: {
                 'stripe_customer_id' => stripe_customer_id,
                 'captain_responses_usage' => 100,
                 'stripe_last_synced_credits' => 50
               })
      end

      let!(:account_without_stripe) do
        create(:account, custom_attributes: {
                 'captain_responses_usage' => 50
               })
      end

      let(:usage_reporter) { instance_double(Enterprise::Billing::V2::UsageReporterService) }

      before do
        allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new).and_return(usage_reporter)
      end

      it 'queues the job on low priority' do
        expect { described_class.perform_later }.to have_enqueued_job(described_class).on_queue('low')
      end

      it 'processes only accounts with Stripe customer ID' do
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })

        described_class.new.perform

        expect(Enterprise::Billing::V2::UsageReporterService).to have_received(:new)
          .with(account: account_with_stripe).once
        expect(Enterprise::Billing::V2::UsageReporterService).not_to have_received(:new)
          .with(account: account_without_stripe)
      end

      it 'reports the difference in credits using UsageReporterService' do
        expected_credits = 50 # 100 consumed - 50 last synced

        expect(usage_reporter).to receive(:report).with(expected_credits)
                                                  .and_return({ success: true, event_id: 'evt_123' })

        described_class.new.perform
      end

      it 'updates last synced credits after successful sync' do
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })

        described_class.new.perform
        account_with_stripe.reload

        expect(account_with_stripe.custom_attributes['stripe_last_synced_credits']).to eq(100)
      end

      it 'returns sync summary' do
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })

        result = described_class.new.perform

        expect(result).to eq({ synced: 1, failed: 0 })
      end

      context 'when credits are already in sync' do
        before do
          Account.delete_all
          synced_account # Ensure account is created before perform
        end

        let(:synced_account) do
          create(:account, custom_attributes: {
                   'stripe_customer_id' => 'cus_synced',
                   'captain_responses_usage' => 100,
                   'stripe_last_synced_credits' => 100
                 })
        end

        it 'does not call UsageReporterService' do
          described_class.new.perform

          expect(Enterprise::Billing::V2::UsageReporterService).not_to have_received(:new)
        end
      end

      context 'when usage has decreased' do
        before do
          Account.delete_all
        end

        let!(:decreased_account) do
          create(:account, custom_attributes: {
                   'stripe_customer_id' => 'cus_decreased',
                   'captain_responses_usage' => 50,
                   'stripe_last_synced_credits' => 100
                 })
        end

        it 'logs a warning and resets sync point' do
          expect(Rails.logger).to receive(:warn).with(
            /Account #{decreased_account.id} has negative difference: -50/
          )

          described_class.new.perform
          decreased_account.reload

          # Sync point should be reset to current usage
          expect(decreased_account.custom_attributes['stripe_last_synced_credits']).to eq(50)
        end
      end

      context 'when UsageReporterService returns an error' do
        before do
          allow(usage_reporter).to receive(:report)
            .and_return({ success: false, message: 'V2 billing not enabled' })
        end

        it 'logs the error and continues processing' do
          expect(Rails.logger).to receive(:error).at_least(:once)

          described_class.new.perform
        end

        it 'does not update last synced credits on failure' do
          original_value = account_with_stripe.custom_attributes['stripe_last_synced_credits']

          described_class.new.perform
          account_with_stripe.reload

          expect(account_with_stripe.custom_attributes['stripe_last_synced_credits']).to eq(original_value)
        end

        it 'counts the failure in summary' do
          result = described_class.new.perform

          expect(result).to eq({ synced: 0, failed: 1 })
        end
      end
    end

    describe 'syncing single account' do
      let(:account) do
        create(:account, custom_attributes: {
                 'stripe_customer_id' => stripe_customer_id,
                 'captain_responses_usage' => 100,
                 'stripe_last_synced_credits' => 30
               })
      end

      let(:usage_reporter) { instance_double(Enterprise::Billing::V2::UsageReporterService) }

      before do
        allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new)
          .with(account: account)
          .and_return(usage_reporter)
      end

      it 'syncs only the specified account' do
        expected_credits = 70 # 100 consumed - 30 last synced

        expect(usage_reporter).to receive(:report).with(expected_credits)
                                                  .and_return({ success: true, event_id: 'evt_123' })

        result = described_class.new.perform(account)

        expect(result[:success]).to be true
        expect(result[:credits_reported]).to eq(70)
      end

      it 'updates last synced credits for the account' do
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })

        described_class.new.perform(account)
        account.reload

        expect(account.custom_attributes['stripe_last_synced_credits']).to eq(100)
      end

      it 'returns error result when sync fails' do
        allow(usage_reporter).to receive(:report)
          .and_return({ success: false, message: 'Missing Stripe configuration' })

        result = described_class.new.perform(account)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Missing Stripe configuration')
      end

      context 'when account has no usage' do
        let(:zero_usage_account) do
          create(:account, custom_attributes: {
                   'stripe_customer_id' => 'cus_zero',
                   'captain_responses_usage' => 0
                 })
        end

        it 'does not call UsageReporterService' do
          result = described_class.new.perform(zero_usage_account)

          expect(Enterprise::Billing::V2::UsageReporterService).not_to have_received(:new)
          expect(result[:success]).to be true
          expect(result[:credits_reported]).to eq(0)
        end
      end

      context 'when account has no stripe_last_synced_credits' do
        let(:new_account) do
          create(:account, custom_attributes: {
                   'stripe_customer_id' => 'cus_new',
                   'captain_responses_usage' => 100
                 })
        end

        before do
          allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new)
            .with(account: new_account)
            .and_return(usage_reporter)
        end

        it 'treats last synced as 0 and reports all credits' do
          expect(usage_reporter).to receive(:report).with(100)
                                                    .and_return({ success: true, event_id: 'evt_new' })

          result = described_class.new.perform(new_account)

          expect(result[:credits_reported]).to eq(100)
        end

        it 'sets stripe_last_synced_credits after first sync' do
          allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_new' })

          described_class.new.perform(new_account)
          new_account.reload

          expect(new_account.custom_attributes['stripe_last_synced_credits']).to eq(100)
        end
      end
    end

    describe 'error handling' do
      let(:account) do
        create(:account, custom_attributes: {
                 'stripe_customer_id' => stripe_customer_id,
                 'captain_responses_usage' => 100
               })
      end

      let(:usage_reporter) { instance_double(Enterprise::Billing::V2::UsageReporterService) }

      before do
        allow(Enterprise::Billing::V2::UsageReporterService).to receive(:new).and_return(usage_reporter)
        allow(usage_reporter).to receive(:report).and_return({ success: true, event_id: 'evt_123' })
      end

      it 'handles and logs exceptions' do
        allow(account).to receive(:with_lock).and_raise(StandardError.new('Database error'))

        expect(Rails.logger).to receive(:error).with(/Error syncing account/)
        expect(Rails.logger).to receive(:error).at_least(:once) # For backtrace logging

        result = described_class.new.perform(account)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Database error')
      end
    end
  end
end
