require 'rails_helper'

RSpec.describe Captain::Conversation::SimpleReplyService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: create(:inbox, account: account)) }

  describe '#matching_reply_for' do
    it 'returns the matched simple reply for a customer message' do
      simple_reply = create(:captain_simple_reply, assistant: assistant, account: account, keywords: ['hello'], reply: 'hi there')

      matched = described_class.new(conversation: conversation, assistant: assistant).matching_reply_for('hello')

      expect(matched).to eq(simple_reply)
    end

    it 'returns nil when no simple reply matches' do
      create(:captain_simple_reply, assistant: assistant, account: account, keywords: ['refund'])

      expect(described_class.new(conversation: conversation, assistant: assistant).matching_reply_for('hello')).to be_nil
    end

    it 'ignores disabled simple replies' do
      create(:captain_simple_reply, assistant: assistant, account: account, keywords: ['hello'], enabled: false)

      expect(described_class.new(conversation: conversation, assistant: assistant).matching_reply_for('hello')).to be_nil
    end
  end

  describe '#perform' do
    it 'posts the reply and returns true when matched' do
      create(:captain_simple_reply, assistant: assistant, account: account, keywords: ['hello'], reply: 'hi there')
      conversation.messages.create!(message_type: :incoming, account_id: account.id, inbox_id: conversation.inbox_id, content: 'hello')

      expect { described_class.new(conversation: conversation, assistant: assistant).perform }.to change(conversation.messages, :count).by(1)
      expect(conversation.messages.outgoing.last.content).to eq('hi there')
    end

    it 'returns false and posts nothing when no reply matches' do
      conversation.messages.create!(message_type: :incoming, account_id: account.id, inbox_id: conversation.inbox_id, content: 'random')

      expect(described_class.new(conversation: conversation, assistant: assistant).perform).to be(false)
      expect(conversation.messages.outgoing).to be_empty
    end
  end
end
