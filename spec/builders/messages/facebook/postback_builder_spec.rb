require 'rails_helper'

describe Messages::Facebook::PostbackBuilder do
  before do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
  end

  let!(:account) { create(:account) }
  let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: facebook_inbox, source_id: 'sender_1') }
  let!(:conversation) { create(:conversation, account: account, contact: contact, inbox: facebook_inbox, contact_inbox: contact_inbox) }

  # Meta reports postback[:mid] as the id of the *outgoing* message that contained the
  # clicked button (not a click-specific id), so it is identical across every click.
  def messaging_for(payload, mid, timestamp: '1700000000000')
    {
      sender: { id: 'sender_1' },
      recipient: { id: 'page_1' },
      timestamp: timestamp,
      postback: { title: 'Option A', payload: payload, mid: mid }
    }
  end

  describe '#perform' do
    context 'when two button messages reuse the same form-local payload id' do
      let!(:older_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         source_id: 'mid.original_send',
                         content_type: 'interactive_buttons',
                         content_attributes: {
                           'body_text' => 'Pick one',
                           'buttons' => [{ 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' }]
                         })
      end

      let!(:newer_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         source_id: 'mid.original_send',
                         content_type: 'interactive_buttons',
                         content_attributes: {
                           'body_text' => 'Pick one again',
                           'buttons' => [{ 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' }]
                         })
      end

      it 'attributes the click to the older message when its encoded payload is clicked' do
        payload = Messages::PostbackPayloadCodec.encode(older_message.id, 'btn_1')
        described_class.new(messaging_for(payload, 'mid.original_send'), facebook_inbox).perform

        reply_message = conversation.messages.incoming.last
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(older_message.id)
        expect(reply_message.content_attributes['postback_payload']).to eq('btn_1')
      end

      it 'attributes the click to the newer message when its encoded payload is clicked' do
        payload = Messages::PostbackPayloadCodec.encode(newer_message.id, 'btn_1')
        described_class.new(messaging_for(payload, 'mid.original_send'), facebook_inbox).perform

        reply_message = conversation.messages.incoming.last
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(newer_message.id)
      end
    end

    context 'when the payload is not one of our encoded payloads (e.g. Ads Quick Reply)' do
      let!(:card_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         source_id: 'mid.original_send',
                         content_type: 'cards',
                         content_attributes: {
                           'items' => [{ 'title' => 'Card 1', 'actions' => [{ 'type' => 'reply', 'text' => 'Go', 'payload' => 'legacy_payload' }] }]
                         })
      end

      it 'falls back to scanning recent outgoing messages by matching payload' do
        described_class.new(messaging_for('legacy_payload', 'mid.original_send'), facebook_inbox).perform

        reply_message = conversation.messages.incoming.last
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(card_message.id)
      end
    end

    context 'when the same message mid is reused across repeated clicks (real Meta behavior)' do
      let!(:source_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         source_id: 'mid.original_send',
                         content_type: 'interactive_buttons',
                         content_attributes: {
                           'body_text' => 'Pick one',
                           'buttons' => [{ 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' }]
                         })
      end
      let(:payload) { Messages::PostbackPayloadCodec.encode(source_message.id, 'btn_1') }

      it 'creates a reply for every ordinary click, even though mid matches the outgoing message' do
        described_class.new(messaging_for(payload, 'mid.original_send', timestamp: '1700000000001'), facebook_inbox).perform

        expect(conversation.messages.incoming.count).to eq(1)
      end

      it 'processes a second distinct click on the same button' do
        described_class.new(messaging_for(payload, 'mid.original_send', timestamp: '1700000000001'), facebook_inbox).perform
        described_class.new(messaging_for(payload, 'mid.original_send', timestamp: '1700000000002'), facebook_inbox).perform

        expect(conversation.messages.incoming.count).to eq(2)
      end

      it 'dedupes a genuine duplicate webhook delivery of the same click' do
        described_class.new(messaging_for(payload, 'mid.original_send', timestamp: '1700000000001'), facebook_inbox).perform
        described_class.new(messaging_for(payload, 'mid.original_send', timestamp: '1700000000001'), facebook_inbox).perform

        expect(conversation.messages.incoming.count).to eq(1)
      end
    end
  end
end
