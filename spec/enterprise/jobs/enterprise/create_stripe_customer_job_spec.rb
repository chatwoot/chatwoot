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

  it 'executes perform' do
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
