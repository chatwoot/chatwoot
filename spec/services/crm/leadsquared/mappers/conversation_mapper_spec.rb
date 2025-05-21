require 'rails_helper'

RSpec.describe Crm::Leadsquared::Mappers::ConversationMapper do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, name: 'Test Inbox', channel_type: 'Channel') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user, name: 'John Doe') }
  let(:contact) { create(:contact, name: 'Jane Smith') }

  before do
    allow(GlobalConfig).to receive(:get).with('BRAND_NAME').and_return({ 'BRAND_NAME' => 'TestBrand' })
  end

  describe '.map_conversation_activity' do
    it 'generates conversation activity note' do
      travel_to(Time.zone.parse('2024-01-01 10:00:00')) do
        result = described_class.map_conversation_activity(conversation)

        expect(result).to include('New conversation started on TestBrand')
        expect(result).to include('Channel: Test Inbox')
        expect(result).to include('Created: 2024-01-01 10:00:00')
        expect(result).to include("Conversation ID: #{conversation.display_id}")
        expect(result).to include('View in TestBrand: http://')
      end
    end
  end

  describe '.map_transcript_activity' do
    context 'when conversation has no messages' do
      it 'returns no messages message' do
        result = described_class.map_transcript_activity(conversation)
        expect(result).to eq('No messages in conversation')
      end
    end

    context 'when conversation has messages' do
      let(:message1) do
        create(:message,
               conversation: conversation,
               sender: user,
               content: 'Hello',
               message_type: :outgoing,
               created_at: Time.zone.parse('2024-01-01 10:00:00'))
      end

      let(:message2) do
        create(:message,
               conversation: conversation,
               sender: contact,
               content: 'Hi there',
               message_type: :incoming,
               created_at: Time.zone.parse('2024-01-01 10:01:00'))
      end

      let(:system_message) do
        create(:message,
               conversation: conversation,
               sender: nil,
               content: 'System Message',
               message_type: :activity,
               created_at: Time.zone.parse('2024-01-01 10:02:00'))
      end

      before do
        message1
        message2
        system_message
      end

      it 'generates transcript with messages in reverse chronological order' do
        result = described_class.map_transcript_activity(conversation)

        expect(result).to include('Conversation Transcript from TestBrand')
        expect(result).to include('Channel: Test Inbox')

        # Check that messages appear in reverse order (newest first)
        message_positions = {
          '[2024-01-01 10:00] John Doe: Hello' => result.index('[2024-01-01 10:00] John Doe: Hello'),
          '[2024-01-01 10:01] Jane Smith: Hi there' => result.index('[2024-01-01 10:01] Jane Smith: Hi there')
        }

        # Latest message (10:01) should come before older message (10:00)
        expect(message_positions['[2024-01-01 10:01] Jane Smith: Hi there']).to be < message_positions['[2024-01-01 10:00] John Doe: Hello']
      end

      context 'when message has attachments' do
        let(:message_with_attachment) do
          create(:message, :with_attachment,
                 conversation: conversation,
                 sender: user,
                 content: 'See attachment',
                 message_type: :outgoing,
                 created_at: Time.zone.parse('2024-01-01 10:03:00'))
        end

        before { message_with_attachment }

        it 'includes attachment information' do
          result = described_class.map_transcript_activity(conversation)

          expect(result).to include('See attachment')
          expect(result).to include('[Attachment: image]')
        end
      end

      context 'when message has empty content' do
        let(:empty_message) do
          create(:message,
                 conversation: conversation,
                 sender: user,
                 content: '',
                 message_type: :outgoing,
                 created_at: Time.zone.parse('2024-01-01 10:04'))
        end

        before { empty_message }

        it 'shows no content placeholder' do
          result = described_class.map_transcript_activity(conversation)
          expect(result).to include('[No content]')
        end
      end

      context 'when sender has no name' do
        let(:unnamed_sender_message) do
          create(:message,
                 conversation: conversation,
                 sender: create(:user, name: ''),
                 content: 'Message',
                 message_type: :outgoing,
                 created_at: Time.zone.parse('2024-01-01 10:05'))
        end

        before { unnamed_sender_message }

        it 'uses sender type and id' do
          result = described_class.map_transcript_activity(conversation)
          expect(result).to include("User #{unnamed_sender_message.sender_id}")
        end
      end
    end

    context 'when specific messages are provided' do
      let(:message1) { create(:message, conversation: conversation, content: 'Message 1', message_type: :outgoing) }
      let(:message2) { create(:message, conversation: conversation, content: 'Message 2', message_type: :outgoing) }
      let(:specific_messages) { [message1] }

      it 'only includes provided messages' do
        result = described_class.map_transcript_activity(conversation, specific_messages)

        expect(result).to include('Message 1')
        expect(result).not_to include('Message 2')
      end
    end

    context 'when messages exceed the ACTIVITY_NOTE_MAX_SIZE' do
      it 'truncates messages to stay within the character limit' do
        # Create a large number of messages with reasonably sized content
        long_message_content = 'A' * 200
        messages = []

        # Create 15 messages (which should exceed the 1800 character limit)
        15.times do |i|
          messages << create(:message,
                             conversation: conversation,
                             sender: user,
                             content: "#{long_message_content} #{i}",
                             message_type: :outgoing,
                             created_at: Time.zone.parse("2024-01-01 #{10 + i}:00:00"))
        end

        result = described_class.map_transcript_activity(conversation, messages)

        # Verify latest message is included (message 14)
        expect(result).to include("[2024-01-02 00:00] John Doe: #{long_message_content} 14")

        # Calculate the expected character count of the formatted messages
        messages.map do |msg|
          "[#{msg.created_at.strftime('%Y-%m-%d %H:%M')}] John Doe: #{msg.content}"
        end

        # Verify the result is within the character limit
        expect(result.length).to be <= described_class::ACTIVITY_NOTE_MAX_SIZE + 100

        # Verify that not all messages are included (some were truncated)
        expect(messages.count).to be > result.scan('John Doe:').count
      end

      it 'respects the ACTIVITY_NOTE_MAX_SIZE constant' do
        # Create a single message that would exceed the limit by itself
        giant_content = 'A' * 2000
        message = create(:message,
                         conversation: conversation,
                         sender: user,
                         content: giant_content,
                         message_type: :outgoing)

        result = described_class.map_transcript_activity(conversation, [message])

        # Extract just the formatted messages part
        id = conversation.display_id
        prefix = "Conversation Transcript from TestBrand\nChannel: Test Inbox\nConversation ID: #{id}\nView in TestBrand: "
        formatted_messages = result.sub(prefix, '').sub(%r{http://.*}, '')

        # Check that it's under the limit (with some tolerance for the message format)
        expect(formatted_messages.length).to be <= described_class::ACTIVITY_NOTE_MAX_SIZE + 100
      end
    end
  end
end
