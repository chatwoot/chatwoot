require 'rails_helper'

describe Integrations::Facebook::DeliveryStatus do
  subject(:message_builder) { described_class.new(message_deliveries, facebook_channel.inbox).perform }

  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let!(:facebook_channel) { create(:channel_facebook_page, page_id: '117172741761305') }
  let!(:message_delivery_object) { build(:message_deliveries).to_json }
  let!(:message_deliveries) { Integrations::Facebook::MessageParser.new(message_delivery_object) }

  let!(:message_read_object) { build(:message_reads).to_json }
  let!(:message_reads) { Integrations::Facebook::MessageParser.new(message_read_object) }
  let!(:message1) { create(:message, content: 'facebook message', message_type: 'outgoing', inbox: facebook_channel.inbox) }
  let!(:message2) { create(:message, content: 'facebook message', message_type: 'incoming', inbox: facebook_channel.inbox) }

  describe '#perform' do
    context 'when message_deliveries callback fires' do
      it 'updates all message if the status is delivered' do
        described_class.new(params: message_deliveries).perform
        expect(message1.reload.status).to eq('delivered')
      end

      it 'doesnt update the message status if the message is incoming' do
        described_class.new(params: message_deliveries).perform
        expect(message2.reload.status).to eq('sent')
      end

      it 'doesnt update the message status if the message created is after the watermark' do
        message1.update(created_at: 1.day.from_now)
        message_deliveries.delivery['watermark'] = 1.day.ago.to_i
        described_class.new(params: message_deliveries).perform
        expect(message1.reload.status).to eq('sent')
      end
    end

    context 'when message_reads callback fires' do
      it 'updates all message if the status is read' do
        described_class.new(params: message_reads).perform
        expect(message1.reload.status).to eq('read')
      end

      it 'doesnt update the message status if the message is incoming' do
        described_class.new(params: message_reads).perform
        expect(message2.reload.status).to eq('sent')
      end

      it 'doesnt update the message status if the message created is after the watermark' do
        message1.update(created_at: 1.day.from_now)
        message_reads.read['watermark'] = 1.day.ago.to_i
        described_class.new(params: message_reads).perform
        expect(message1.reload.status).to eq('sent')
      end
    end
  end
end
