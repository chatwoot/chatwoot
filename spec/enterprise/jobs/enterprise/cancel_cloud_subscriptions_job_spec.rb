require 'rails_helper'

RSpec.describe Enterprise::CancelCloudSubscriptionsJob, type: :job do
  subject(:job) { described_class.perform_later(account) }

  let(:account) { create(:account, custom_attributes: { 'marked_for_deletion_at' => 7.days.from_now.iso8601 }) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class).with(account).on_queue('default')
  end

  it 'executes perform' do
    cancellation_service = instance_double(Enterprise::Billing::CancelCloudSubscriptionsService, perform: true)
    allow(Enterprise::Billing::CancelCloudSubscriptionsService).to receive(:new).with(account: account).and_return(cancellation_service)

    perform_enqueued_jobs { job }

    expect(cancellation_service).to have_received(:perform)
  end

  it 'does nothing when the deletion was cancelled before the job ran' do
    account.update!(custom_attributes: {})
    allow(Enterprise::Billing::CancelCloudSubscriptionsService).to receive(:new)

    perform_enqueued_jobs { job }

    expect(Enterprise::Billing::CancelCloudSubscriptionsService).not_to have_received(:new)
  end

  it 'retries when Stripe is unavailable so the cancellation is not lost' do
    allow(Enterprise::Billing::CancelCloudSubscriptionsService).to receive(:new).and_raise(Stripe::APIError.new('stripe unavailable'))
    account

    expect { described_class.perform_now(account) }.to change(enqueued_jobs, :size).by(1)
  end
end
