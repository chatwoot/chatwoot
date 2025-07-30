# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::ProvisionStripeSubscriptionJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:plan_name) { 'starter' }
  let(:account_id) { account.id }

  describe '#perform' do
    it 'enqueues the job' do
      expect do
        described_class.perform_later(account_id, plan_name)
      end.to have_enqueued_job(described_class)
        .with(account_id, plan_name)
        .on_queue('default')
    end

    context 'when account exists' do
      let(:service_double) { double('Billing::CreateCustomerService') }

      before do
        allow(Billing::CreateCustomerService).to receive(:new).and_return(service_double)
        allow(service_double).to receive(:perform).and_return({ success: true })
        # Stub logger calls that happen during billing plans loading
        allow(Rails.logger).to receive(:info)
      end

      it 'calls CreateCustomerService with trial period' do
        described_class.new.perform(account_id, plan_name)

        expect(Billing::CreateCustomerService).to have_received(:new)
          .with(account, plan_name, trial_period_days: 7)
        expect(service_double).to have_received(:perform)
      end

      it 'logs success and updates provisioning status on successful provisioning' do
        expect(Rails.logger).to receive(:info)
          .with("Starting Stripe subscription provisioning for account #{account_id} with plan #{plan_name}")
        expect(Rails.logger).to receive(:info)
          .with("Successfully provisioned Stripe subscription for account #{account_id}")

        described_class.new.perform(account_id, plan_name)

        account.reload
        expect(account.custom_attributes['billing_status']).to eq('completed')
        expect(account.custom_attributes['billing_provisioned_at']).to be_present
      end

      it 'logs error and updates status on failed provisioning' do
        allow(service_double).to receive(:perform).and_return({ success: false, error: 'Payment failed' })

        expect(Rails.logger).to receive(:info)
          .with("Starting Stripe subscription provisioning for account #{account_id} with plan #{plan_name}")
        expect(Rails.logger).to receive(:error)
          .with("Failed to provision Stripe subscription for account #{account_id}: Payment failed")
        expect(Rails.logger).to receive(:error)
          .with("Error provisioning Stripe subscription for account #{account_id}: Payment failed")

        expect do
          described_class.new.perform(account_id, plan_name)
        end.to raise_error(StandardError, 'Payment failed')

        account.reload
        expect(account.custom_attributes['billing_status']).to eq('failed')
      end

      it 'skips provisioning if account already has Stripe customer ID' do
        account.update!(custom_attributes: { 'stripe_customer_id' => 'cus_123' })

        expect(Rails.logger).to receive(:info)
          .with("Starting Stripe subscription provisioning for account #{account_id} with plan #{plan_name}")
        expect(Rails.logger).to receive(:info)
          .with("Account #{account_id} already has Stripe customer ID, skipping provisioning")

        described_class.new.perform(account_id, plan_name)

        expect(Billing::CreateCustomerService).not_to have_received(:new)
      end

      it 'handles exceptions and updates status to failed' do
        allow(service_double).to receive(:perform).and_raise(StandardError, 'Network error')

        expect(Rails.logger).to receive(:error)
          .with("Error provisioning Stripe subscription for account #{account_id}: Network error")

        expect do
          described_class.new.perform(account_id, plan_name)
        end.to raise_error(StandardError, 'Network error')

        account.reload
        expect(account.custom_attributes['billing_status']).to eq('failed')
      end
    end

    context 'when account does not exist' do
      let(:invalid_account_id) { 99_999 }

      it 'logs error and returns early' do
        expect(Rails.logger).to receive(:info)
          .with("Starting Stripe subscription provisioning for account #{invalid_account_id} with plan #{plan_name}")
        expect(Rails.logger).to receive(:error)
          .with("Account not found with ID: #{invalid_account_id}. This may indicate a race condition where the job was enqueued before the account was committed to the database.")

        described_class.new.perform(invalid_account_id, plan_name)

        expect(Billing::CreateCustomerService).not_to receive(:new)
      end
    end
  end

  describe '#get_trial_period_for_plan' do
    let(:job) { described_class.new }

    it 'returns trial period from billing config' do
      # Mock the BillingPlans module directly
      billing_class = Class.new { include BillingPlans }
      allow(billing_class).to receive(:plan_details).with('free_trial').and_return({
                                                                                     'trial_expires_in_days' => 14
                                                                                   })
      allow(Class).to receive(:new).and_return(billing_class)

      result = job.send(:get_trial_period_for_plan, 'starter')

      expect(result).to eq(14)
    end

    it 'returns default of 7 days when trial plan details are not found' do
      # Mock the BillingPlans module to return nil
      billing_class = Class.new { include BillingPlans }
      allow(billing_class).to receive(:plan_details).with('free_trial').and_return(nil)
      allow(Class).to receive(:new).and_return(billing_class)

      result = job.send(:get_trial_period_for_plan, 'starter')

      expect(result).to eq(7)
    end
  end

  describe '#update_provisioning_status' do
    let(:job) { described_class.new }

    it 'updates billing status to completed with timestamp' do
      job.send(:update_provisioning_status, account, 'completed')

      account.reload
      expect(account.custom_attributes['billing_status']).to eq('completed')
      expect(account.custom_attributes['billing_provisioned_at']).to be_present
    end

    it 'updates billing status to failed without timestamp' do
      job.send(:update_provisioning_status, account, 'failed')

      account.reload
      expect(account.custom_attributes['billing_status']).to eq('failed')
      expect(account.custom_attributes['billing_provisioned_at']).to be_nil
    end

    it 'preserves existing custom attributes' do
      account.update!(custom_attributes: { 'existing_key' => 'existing_value' })

      job.send(:update_provisioning_status, account, 'completed')

      account.reload
      expect(account.custom_attributes['existing_key']).to eq('existing_value')
      expect(account.custom_attributes['billing_status']).to eq('completed')
    end

    it 'handles errors gracefully and logs them' do
      allow(account).to receive(:update!).and_raise(StandardError, 'Database error')

      expect(Rails.logger).to receive(:error)
        .with("Failed to update provisioning status for account #{account.id}: Database error")

      expect do
        job.send(:update_provisioning_status, account, 'completed')
      end.not_to raise_error
    end
  end
end