require 'rails_helper'

describe Integrations::Facebook::DeliveryStatus do
  subject(:message_builder) { described_class.new(message_deliveries, facebook_channel.inbox).perform }

  before do
    stub_request(:post, /graph\.facebook\.com/)
  end

  let!(:account) { create(:account) }
  let!(:facebook_channel) { create(:channel_facebook_page, page_id: '117172741761305') }
  let!(:message_delivery_object) { build(:message_deliveries).to_json }
  let!(:message_deliveries) { Integrations::Facebook::MessageParser.new(message_delivery_object) }

  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: facebook_channel.inbox, source_id: '3383290475046708') }
  let!(:conversation) { create(:conversation, inbox: facebook_channel.inbox, contact: contact, contact_inbox: contact_inbox) }

  let!(:message_read_object) { build(:message_reads).to_json }
  let!(:message_reads) { Integrations::Facebook::MessageParser.new(message_read_object) }
  let!(:message1) do
    create(:message, content: 'facebook message', message_type: 'outgoing', inbox: facebook_channel.inbox, conversation: conversation)
  end
  let!(:message2) do
    create(:message, content: 'facebook message', message_type: 'incoming', inbox: facebook_channel.inbox, conversation: conversation)
  end

  describe '#perform' do
    context 'when message_deliveries callback fires' do
      before do
        allow(Conversations::UpdateMessageStatusJob).to receive(:perform_later)
      end

      it 'updates all messages if the status is delivered' do
        described_class.new(params: message_deliveries).perform
        expect(Conversations::UpdateMessageStatusJob).to have_received(:perform_later).with(
          message1.conversation.id,
          Time.zone.at(message_deliveries.delivery['watermark'].to_i).to_datetime,
          :delivered
        )
      end

      it 'does not update the message status if the message is incoming' do
        described_class.new(params: message_deliveries).perform
        expect(message2.reload.status).to eq('sent')
      end

      it 'does not update the message status if the message was created after the watermark' do
        message1.update!(created_at: 1.day.from_now)
        message_deliveries.delivery['watermark'] = 1.day.ago.to_i
        described_class.new(params: message_deliveries).perform
        expect(message1.reload.status).to eq('sent')
      end
    end

    context 'when message_reads callback fires' do
      before do
        allow(Conversations::UpdateMessageStatusJob).to receive(:perform_later)
      end

      it 'updates all messages if the status is read' do
        described_class.new(params: message_reads).perform
        expect(Conversations::UpdateMessageStatusJob).to have_received(:perform_later).with(
          message1.conversation.id,
          Time.zone.at(message_reads.read['watermark'].to_i).to_datetime,
          :read
        )
      end

      it 'does not update the message status if the message is incoming' do
        described_class.new(params: message_reads).perform
        expect(message2.reload.status).to eq('sent')
      end

      it 'does not update the message status if the message was created after the watermark' do
        message1.update!(created_at: 1.day.from_now)
        message_reads.read['watermark'] = 1.day.ago.to_i
        described_class.new(params: message_reads).perform
        expect(message1.reload.status).to eq('sent')
      end
    end
  end
end
