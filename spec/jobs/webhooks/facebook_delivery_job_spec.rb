require 'rails_helper'

RSpec.describe Webhooks::FacebookDeliveryJob do
  include ActiveJob::TestHelper

  let(:message) { 'test_message' }
  let(:parsed_message) { instance_double(Integrations::Facebook::MessageParser) }
  let(:delivery_status) { instance_double(Integrations::Facebook::DeliveryStatus) }

  before do
    allow(Integrations::Facebook::MessageParser).to receive(:new).with(message).and_return(parsed_message)
    allow(Integrations::Facebook::DeliveryStatus).to receive(:new).with(params: parsed_message).and_return(delivery_status)
    allow(delivery_status).to receive(:perform)
  end

  after do
    clear_enqueued_jobs
  end

  describe '#perform_later' do
    it 'enqueues the job' do
      expect do
        described_class.perform_later(message)
      end.to have_enqueued_job(described_class).with(message).on_queue('low')
    end
  end

  describe '#perform' do
    it 'calls the MessageParser with the correct argument' do
      expect(Integrations::Facebook::MessageParser).to receive(:new).with(message)
      described_class.perform_now(message)
    end

    it 'calls the DeliveryStatus with the correct argument' do
      expect(Integrations::Facebook::DeliveryStatus).to receive(:new).with(params: parsed_message)
      described_class.perform_now(message)
    end

    it 'executes perform on the DeliveryStatus instance' do
      expect(delivery_status).to receive(:perform)
      described_class.perform_now(message)
    end
  end
end
