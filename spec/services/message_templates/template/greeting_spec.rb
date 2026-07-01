require 'rails_helper'

describe MessageTemplates::Template::Greeting do
  context 'when this hook is called' do
    let(:conversation) { create(:conversation) }

    it 'creates the email collect messages' do
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
    end

    it 'creates the greeting messages with template variable' do
      conversation.inbox.update!(greeting_message: 'Hey, {{contact.name}} welcome to our board.')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq("Hey, #{conversation.contact.name} welcome to our board.")
    end

    it 'creates the greeting messages with more than one variable strings' do
      conversation.inbox.update!(greeting_message: 'Hey, {{contact.name}} welcome to our board. - from {{account.name}}')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq("Hey, #{conversation.contact.name} welcome to our board. - from #{conversation.account.name}")
    end

    it 'creates the greeting messages' do
      conversation.inbox.update!(greeting_message: 'Hello welcome to our board.')
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.last.content).to eq('Hello welcome to our board.')
    end

    it 'drops locked greeting messages without reporting an exception' do
      with_modified_env 'CONVERSATION_MESSAGE_LIMIT': '1' do
        create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox)
        expect(ChatwootExceptionTracker).not_to receive(:new)

        expect { described_class.new(conversation: conversation).perform }.not_to change(Message, :count)
      end
    end
  end
end
