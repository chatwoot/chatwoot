require 'rails_helper'

RSpec.describe Captain::ConversationTranscript do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  def create_message(**attributes)
    create(:message, account: account, conversation: conversation, inbox: conversation.inbox, **attributes)
  end

  describe '.entry' do
    it 'describes a public customer message' do
      message = create_message(message_type: :incoming, content: 'I want my money back')

      expect(described_class.entry(message, 100)).to eq(sender: 'customer', text: 'I want my money back')
    end

    it 'describes a public agent reply' do
      message = create_message(message_type: :outgoing, content: 'Let me check that for you')

      expect(described_class.entry(message, 100)).to eq(sender: 'agent', text: 'Let me check that for you')
    end

    it 'keeps only the start of the text when given a limit' do
      message = create_message(message_type: :incoming, content: 'I want my money back')

      expect(described_class.entry(message, 6)).to eq(sender: 'customer', text: 'I want')
    end

    it 'is nil for a private note' do
      message = create_message(message_type: :outgoing, private: true, content: 'Customer is on the legacy plan')

      expect(described_class.entry(message, 100)).to be_nil
    end

    it 'is nil for a message that is neither from the customer nor from an agent' do
      message = create_message(message_type: :template, content: 'Give the team a way to reach you.')

      expect(described_class.entry(message, 100)).to be_nil
    end

    it 'is nil for a deleted message' do
      message = create_message(message_type: :incoming, content: 'This message was deleted', content_attributes: { deleted: true })

      expect(described_class.entry(message, 100)).to be_nil
    end

    it 'is nil for a forwarded email' do
      message = create_message(message_type: :outgoing, content: 'Note to supplier', content_attributes: { forwarded_message_id: 1 })

      expect(described_class.entry(message, 100)).to be_nil
    end

    it 'is nil for a message without content' do
      message = create_message(message_type: :incoming, content: nil)

      expect(described_class.entry(message, 100)).to be_nil
    end
  end

  describe '#messages' do
    it 'lists only what Captain may read, oldest first' do
      create_message(message_type: :incoming, content: 'I want my money back')
      create_message(message_type: :outgoing, private: true, content: 'Customer is on the legacy plan')
      create_message(message_type: :template, content: 'Give the team a way to reach you.')
      create_message(message_type: :outgoing, content: 'Note to supplier', content_attributes: { forwarded_message_id: 1 })
      create_message(message_type: :outgoing, content: 'Let me check that for you')

      expect(described_class.new(conversation: conversation).messages).to eq(
        [
          { sender: 'customer', text: 'I want my money back' },
          { sender: 'agent', text: 'Let me check that for you' }
        ]
      )
    end
  end
end
