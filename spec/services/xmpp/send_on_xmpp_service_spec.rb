require 'rails_helper'

describe Xmpp::SendOnXmppService do
  let(:account) { create(:account) }
  let(:xmpp_channel) { create(:channel_xmpp, account: account) }
  let(:xmpp_inbox) { create(:inbox, channel: xmpp_channel, account: account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { jid: 'test@example.com' }) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: xmpp_inbox) }

  let(:conversation) do
    create(
      :conversation,
      contact: contact,
      inbox: xmpp_inbox,
      contact_inbox: contact_inbox,
      additional_attributes: { source: 'xmpp', type: 'chat' }
    )
  end

  describe '#perform' do
    it 'enqueues reply' do
      message = create(:message, message_type: :outgoing, inbox: xmpp_inbox, account: account, conversation: conversation)
      allow(Redis::Alfred).to receive(:lpush)
      ::Xmpp::SendOnXmppService.new(message: message).perform
      expect(Redis::Alfred).to have_received(:lpush)
    end
  end

  describe '#reprocess_in_progress' do
    context 'with two in progress' do
      it 'moves them back to outbound' do
        Redis::Alfred.rpush('xmpp_outbound_in_progress', '{}')
        Redis::Alfred.rpush('xmpp_outbound_in_progress', '{}')
        allow(Redis::Alfred).to receive(:rpoplpush)
        ::Xmpp::SendOnXmppService.new(message: nil).reprocess_in_progress
        expect(Redis::Alfred).to have_received(:rpoplpush).with('xmpp_outbound_in_progress', 'xmpp_outbound')
        expect(Redis::Alfred).to have_received(:rpoplpush).with('xmpp_outbound_in_progress', 'xmpp_outbound')
      end
    end
  end

  describe '#message_for_item' do
    context 'with basic message' do
      let(:item) do
        {
          'conversation_uuid' => 'uuid',
          'message_id' => 'mid',
          'type' => 'chat',
          'to' => 'test@example.com',
          'body' => 'hi'
        }
      end

      it 'converts' do
        m = ::Xmpp::SendOnXmppService.new(message: nil).message_for_item(item)
        expect(m.id).to eq 'chatwoot:uuid:mid'
        expect(m.type).to eq :chat
        expect(m.to).to eq 'test@example.com'
        expect(m.body).to eq "hi\n"
        expect(m.xhtml).to eq '<p>hi</p>'
        expect(m.xpath('./ns:request', ns: 'urn:xmpp:receipts').length).to eq 1
        expect(m.xpath('./ns:markable', ns: 'urn:xmpp:chat-markers:0').length).to eq 1
      end
    end

    context 'with rich message' do
      let(:item) do
        {
          'conversation_uuid' => 'uuid',
          'message_id' => 'mid',
          'type' => 'chat',
          'to' => 'test@example.com',
          'body' => '**bold** *italic* `code` [link](http://example.com)'
        }
      end

      it 'converts' do
        m = ::Xmpp::SendOnXmppService.new(message: nil).message_for_item(item)
        expect(m.body).to eq "*bold* _italic_ `code` link (http://example.com)\n"
        expect(m.xhtml).to eq '<p><strong>bold</strong> <em>italic</em> <code>code</code> <a href="http://example.com">link</a></p>'
      end
    end
  end
end
