require 'rails_helper'

RSpec.describe Enterprise::CreateStripeCustomerJob, type: :job do
  include ActiveJob::TestHelper
  subject(:job) { described_class.perform_later(account) }

  let(:account) { create(:account) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(account)
      .on_queue('default')
  end

  context 'when V1 billing' do
    before do
      allow(ENV).to receive(:fetch).with('STRIPE_BILLING_V2_ENABLED', 'false').and_return('false')
    end

    it 'uses V1 customer creation service' do
      create_stripe_customer_service = double
      allow(Enterprise::Billing::CreateStripeCustomerService)
        .to receive(:new)
        .with(account: account)
        .and_return(create_stripe_customer_service)
      allow(create_stripe_customer_service).to receive(:perform)

      perform_enqueued_jobs { job }

      expect(Enterprise::Billing::CreateStripeCustomerService).to have_received(:new).with(account: account)
    end
  end

  context 'when V2 billing' do
    before do
      allow(ENV).to receive(:fetch).with('STRIPE_BILLING_V2_ENABLED', 'false').and_return('true')
    end

    it 'uses V2 customer creation service' do
      v2_service = double
      allow(Enterprise::Billing::V2::CustomerCreationService)
        .to receive(:new)
        .with(account: account)
        .and_return(v2_service)
      allow(v2_service).to receive(:perform)

      perform_enqueued_jobs { job }

      expect(Enterprise::Billing::V2::CustomerCreationService).to have_received(:new).with(account: account)
    end
  end
end
