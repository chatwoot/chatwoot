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

  def messaging_for(payload, mid)
    {
      sender: { id: 'sender_1' },
      recipient: { id: 'page_1' },
      postback: { title: 'Option A', payload: payload, mid: mid }
    }
  end

  describe '#perform' do
    context 'when two button messages reuse the same form-local payload id' do
      let!(:older_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         content_type: 'interactive_buttons',
                         content_attributes: {
                           'body_text' => 'Pick one',
                           'buttons' => [{ 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' }]
                         })
      end

      let!(:newer_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         content_type: 'interactive_buttons',
                         content_attributes: {
                           'body_text' => 'Pick one again',
                           'buttons' => [{ 'id' => 'btn_1', 'text' => 'Option A', 'type' => 'reply' }]
                         })
      end

      it 'attributes the click to the older message when its encoded payload is clicked' do
        payload = Messages::PostbackPayloadCodec.encode(older_message.id, 'btn_1')
        described_class.new(messaging_for(payload, 'mid.click_1'), facebook_inbox).perform

        reply_message = conversation.messages.find_by(source_id: 'mid.click_1')
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(older_message.id)
        expect(reply_message.content_attributes['postback_payload']).to eq('btn_1')
      end

      it 'attributes the click to the newer message when its encoded payload is clicked' do
        payload = Messages::PostbackPayloadCodec.encode(newer_message.id, 'btn_1')
        described_class.new(messaging_for(payload, 'mid.click_2'), facebook_inbox).perform

        reply_message = conversation.messages.find_by(source_id: 'mid.click_2')
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(newer_message.id)
      end
    end

    context 'when the payload is not one of our encoded payloads (e.g. Ads Quick Reply)' do
      let!(:card_message) do
        create(:message, message_type: :outgoing, inbox: facebook_inbox, account: account, conversation: conversation,
                         content_type: 'cards',
                         content_attributes: {
                           'items' => [{ 'title' => 'Card 1', 'actions' => [{ 'type' => 'reply', 'text' => 'Go', 'payload' => 'legacy_payload' }] }]
                         })
      end

      it 'falls back to scanning recent outgoing messages by matching payload' do
        described_class.new(messaging_for('legacy_payload', 'mid.click_3'), facebook_inbox).perform

        reply_message = conversation.messages.find_by(source_id: 'mid.click_3')
        expect(reply_message.content_attributes['selected_reply']['source_message_id']).to eq(card_message.id)
      end
    end
  end
end
