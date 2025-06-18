require 'rails_helper'

RSpec.describe LlmFormatter::ConversationLlmFormatter do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:formatter) { described_class.new(conversation) }

  describe '#format' do
    context 'when conversation has no messages' do
      it 'returns basic conversation info with no messages' do
        expected_output = [
          "Conversation ID: ##{conversation.display_id}",
          "Channel: #{conversation.inbox.channel.name}",
          'Message History:',
          'No messages in this conversation'
        ].join("\n")

        expect(formatter.format).to eq(expected_output)
      end
    end

    context 'when conversation has messages' do
      it 'formats messages in chronological order with sender labels' do
        create(
          :message,
          conversation: conversation,
          message_type: 'incoming',
          content: 'Hello, I need help'
        )

        create(
          :message,
          conversation: conversation,
          message_type: 'outgoing',
          content: 'How can I assist you today?'
        )

        expected_output = [
          "Conversation ID: ##{conversation.display_id}",
          "Channel: #{conversation.inbox.channel.name}",
          'Message History:',
          'User: Hello, I need help',
          'Support agent: How can I assist you today?',
          ''
        ].join("\n")

        expect(formatter.format).to eq(expected_output)
      end
    end

    context 'when include_contact_details is true' do
      it 'includes contact details' do
        expected_output = [
          "Conversation ID: ##{conversation.display_id}",
          "Channel: #{conversation.inbox.channel.name}",
          'Message History:',
          'No messages in this conversation',
          "Contact Details: #{conversation.contact.to_llm_text}"
        ].join("\n")

        expect(formatter.format(include_contact_details: true)).to eq(expected_output)
      end
    end
  end
end
