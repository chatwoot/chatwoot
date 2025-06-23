# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billing::CreateCustomerJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:plan_name) { 'starter' }

  describe '#perform' do
    it 'enqueues the job' do
      expect do
        described_class.perform_later(account, plan_name)
      end.to have_enqueued_job(described_class)
        .with(account, plan_name)
        .on_queue('default')
    end

    it 'calls the CreateCustomerService' do
      service_double = double('Billing::CreateCustomerService')
      allow(Billing::CreateCustomerService).to receive(:new)
        .with(account, plan_name)
        .and_return(service_double)
      allow(service_double).to receive(:perform)
        .and_return({ success: true, message: 'Success' })

      perform_enqueued_jobs do
        described_class.perform_later(account, plan_name)
      end

      expect(Billing::CreateCustomerService).to have_received(:new)
        .with(account, plan_name)
      expect(service_double).to have_received(:perform)
    end

    it 'logs success messages' do
      service_double = double('Billing::CreateCustomerService')
      allow(Billing::CreateCustomerService).to receive(:new)
        .and_return(service_double)
      allow(service_double).to receive(:perform)
        .and_return({ success: true, message: 'Customer created successfully' })

      expect(Rails.logger).to receive(:info)
        .with("Successfully created customer for account #{account.id}: Customer created successfully")

      perform_enqueued_jobs do
        described_class.perform_later(account, plan_name)
      end
    end

    it 'logs error messages' do
      service_double = double('Billing::CreateCustomerService')
      allow(Billing::CreateCustomerService).to receive(:new)
        .and_return(service_double)
      allow(service_double).to receive(:perform)
        .and_return({ success: false, error: 'Payment failed' })

      expect(Rails.logger).to receive(:error)
        .with("Failed to create customer for account #{account.id}: Payment failed")

      perform_enqueued_jobs do
        described_class.perform_later(account, plan_name)
      end
    end
  end
end