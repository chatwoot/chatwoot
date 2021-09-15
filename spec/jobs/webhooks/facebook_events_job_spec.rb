require 'rails_helper'

RSpec.describe Webhooks::FacebookEventsJob, type: :job do
  subject(:job) { described_class.perform_later(params) }

  let!(:params) { { test: 'test' } }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('default')
  end

  context 'when called with params' do
    it 'calls MessagePArsed and do message create' do
      parser = double
      creator = double
      allow(::Integrations::Facebook::MessageParser).to receive(:new).and_return(parser)
      allow(::Integrations::Facebook::MessageCreator).to receive(:new).and_return(creator)
      allow(creator).to receive(:perform).and_return(true)
      expect(::Integrations::Facebook::MessageParser).to receive(:new).with(params)
      expect(::Integrations::Facebook::MessageCreator).to receive(:new).with(parser)
      expect(creator).to receive(:perform)
      described_class.perform_now(params)
    end
  end
end
