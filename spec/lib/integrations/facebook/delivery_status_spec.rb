require 'rails_helper'

describe Integrations::Facebook::DeliveryStatus do
  subject(:message_builder) { described_class.new(message_deliveries, facebook_channel.inbox).perform }

  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let!(:facebook_channel) { create(:channel_facebook_page, page_id: '117172741761305') }
  let!(:message_object) { build(:message_deliveries).to_json }
  let!(:message_deliveries) { Integrations::Facebook::MessageParser.new(message_object) }
  let!(:message) { create(:message, content: 'facebook message', inbox: facebook_channel.inbox) }

  describe '#perform' do
    context 'when message_deliveries callback fires' do
      it 'updates all message if the status is delivered' do
        described_class.new(params: message_deliveries).perform
        expect(message.reload.status).to eq('delivered')
      end

      it 'doesnt update the message status if the message created is after the watermark' do
        message.update(created_at: 1.day.from_now)
        message_deliveries.delivery['watermark'] = 1.day.ago.to_i
        described_class.new(params: message_deliveries).perform
        expect(message.reload.status).to eq('sent')
      end
    end
  end
end
