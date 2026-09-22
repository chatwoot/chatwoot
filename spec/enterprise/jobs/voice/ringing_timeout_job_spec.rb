# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::RingingTimeoutJob do
  let(:account) { create(:account) }
  let(:service) { instance_double(Voice::RingingTimeoutService, perform: nil) }

  before do
    allow(Voice::RingingTimeoutService).to receive(:new).and_return(service)
  end

  it 'runs on the scheduled jobs queue' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class).on_queue('scheduled_jobs')
  end

  it 'ends every overdue ringing call and leaves the rest alone' do
    overdue = create(:call, conversation: create(:conversation, account: account), provider: :whatsapp, created_at: 2.minutes.ago)
    create(:call, conversation: create(:conversation, account: account), provider: :whatsapp, created_at: 10.seconds.ago)

    described_class.perform_now

    expect(Voice::RingingTimeoutService).to have_received(:new).once.with(call: overdue)
    expect(service).to have_received(:perform).once
  end
end
