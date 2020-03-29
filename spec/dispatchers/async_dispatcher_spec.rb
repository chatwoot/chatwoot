require 'rails_helper'
describe AsyncDispatcher do
  subject(:dispatcher) { described_class.new }

  let!(:conversation) { create(:conversation) }
  let(:event_name) { 'conversation.created' }
  let(:timestamp) { Time.zone.now }
  let(:event_data) { { conversation: conversation } }

  describe '#dispatch' do
    it 'enqueue job to dispatch event' do
      expect(EventDispatcherJob).to receive(:perform_later).with(event_name, timestamp, event_data).once
      dispatcher.dispatch(event_name, timestamp, event_data)
    end
  end
end
