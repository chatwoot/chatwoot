require 'rails_helper'

describe Messages::DeleteOnChannelService do
  let(:message) { create(:message) }
  let(:channel_service_class) do
    Class.new do
      self::DELETE_WINDOW = 1.hour

      pattr_initialize [:message!]

      def perform; end
    end
  end

  describe '#perform' do
    let(:channel_service) { instance_double(channel_service_class, perform: nil) }

    before do
      allow(channel_service_class).to receive(:new).with(message: message).and_return(channel_service)
    end

    it 'deletes the message with the service registered for its channel' do
      stub_const("#{described_class}::CHANNEL_SERVICES", { message.inbox.channel_type => channel_service_class })

      described_class.new(message: message).perform

      expect(channel_service).to have_received(:perform)
    end

    it 'does nothing for channels without a registered service' do
      stub_const("#{described_class}::CHANNEL_SERVICES", { 'Channel::Unsupported' => channel_service_class })

      described_class.new(message: message).perform

      expect(channel_service_class).not_to have_received(:new)
    end
  end

  describe '.delete_window' do
    it 'returns the delete window of the service registered for the channel' do
      stub_const("#{described_class}::CHANNEL_SERVICES", { message.inbox.channel_type => channel_service_class })

      expect(described_class.delete_window(message.inbox)).to eq(1.hour)
    end

    it 'returns nil for channels without a registered service' do
      stub_const("#{described_class}::CHANNEL_SERVICES", { 'Channel::Unsupported' => channel_service_class })

      expect(described_class.delete_window(message.inbox)).to be_nil
    end
  end
end
