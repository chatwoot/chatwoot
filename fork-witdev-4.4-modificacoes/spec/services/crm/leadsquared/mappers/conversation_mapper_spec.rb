require 'rails_helper'

RSpec.describe Crm::Leadsquared::Mappers::ConversationMapper do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, name: 'Test Inbox', channel_type: 'Channel') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user, name: 'John Doe') }
  let(:contact) { create(:contact, name: 'Jane Smith') }
  let(:hook) do
    create(:integrations_hook, :leadsquared, account: account, settings: {
             'access_key' => 'test_access_key',
             'secret_key' => 'test_secret_key',
             'endpoint_url' => 'https://api.leadsquared.com/v2',
             'timezone' => 'UTC'
           })
  end
  let(:hook_with_pst) do
    create(:integrations_hook, :leadsquared, account: account, settings: {
             'access_key' => 'test_access_key',
             'secret_key' => 'test_secret_key',
             'endpoint_url' => 'https://api.leadsquared.com/v2',
             'timezone' => 'America/Los_Angeles'
           })
  end
  let(:hook_without_timezone) do
    create(:integrations_hook, :leadsquared, account: account, settings: {
             'access_key' => 'test_access_key',
             'secret_key' => 'test_secret_key',
             'endpoint_url' => 'https://api.leadsquared.com/v2'
           })
  end

  before do
    account.enable_features('crm_integration')
    allow(GlobalConfig).to receive(:get).with('BRAND_NAME').and_return({ 'BRAND_NAME' => 'TestBrand' })
  end

  describe '.map_conversation_activity' do
    it 'generates conversation activity note with UTC timezone' do
      travel_to(Time.zone.parse('2024-01-01 10:00:00 UTC')) do
        result = described_class.map_conversation_activity(hook, conversation)

        expect(result).to include('New conversation started on TestBrand')
        expect(result).to include('Channel: Test Inbox')
        expect(result).to include('Created: 2024-01-01 10:00:00')
        expect(result).to include("Conversation ID: #{conversation.display_id}")
        expect(result).to include('View in TestBrand: http://')
      end
    end

    it 'formats time according to hook timezone setting' do
      travel_to(Time.zone.parse('2024-01-01 18:00:00 UTC')) do
        result = described_class.map_conversation_activity(hook_with_pst, conversation)

        # PST is UTC-8, so 18:00 UTC becomes 10:00:00 PST
        expect(result).to include('Created: 2024-01-01 10:00:00')
      end
    end

    it 'falls back to system timezone when hook has no timezone setting' do
      travel_to(Time.zone.parse('2024-01-01 10:00:00')) do
        result = described_class.map_conversation_activity(hook_without_timezone, conversation)

        expect(result).to include('Created: 2024-01-01 10:00:00')
      end
    end
  end

  describe '.map_transcript_activity' do
    context 'when conversation has no messages' do
      it 'returns no messages message' do
        result = described_class.map_transcript_activity(hook, conversation)
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
        result = described_class.map_transcript_activity(hook, conversation)

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

      it 'formats message times according to hook timezone setting' do
        travel_to(Time.zone.parse('2024-01-01 18:00:00 UTC')) do
          create(:message,
                 conversation: conversation,
                 sender: user,
                 content: 'Test message',
                 message_type: :outgoing,
                 created_at: Time.zone.parse('2024-01-01 18:00:00 UTC'))

          result = described_class.map_transcript_activity(hook_with_pst, conversation)

          # PST is UTC-8, so 18:00 UTC becomes 10:00 PST
          expect(result).to include('[2024-01-01 10:00] John Doe: Test message')
        end
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
          result = described_class.map_transcript_activity(hook, conversation)

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
          result = described_class.map_transcript_activity(hook, conversation)
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
          result = described_class.map_transcript_activity(hook, conversation)
          expect(result).to include("User #{unnamed_sender_message.sender_id}")
        end
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

        result = described_class.map_transcript_activity(hook, conversation)

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
        create(:message,
               conversation: conversation,
               sender: user,
               content: giant_content,
               message_type: :outgoing)

        result = described_class.map_transcript_activity(hook, conversation)

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
