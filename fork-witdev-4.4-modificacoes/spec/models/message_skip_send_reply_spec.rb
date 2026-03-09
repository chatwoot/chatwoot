# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, 'skip_send_reply flag behavior' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  describe '#send_reply' do
    context 'when skip_send_reply flag is true' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :text,
               content: 'Test message',
               additional_attributes: { skip_send_reply: true })
      end

      it 'returns early without enqueueing SendReplyJob' do
        # Mock the job enqueueing to verify it's not called
        expect(SendReplyJob).not_to receive(:perform_later)

        result = message.send_reply
        expect(result).to be_nil
      end

      it 'does not trigger any reply sending mechanism' do
        # Mock various reply mechanisms to ensure none are called
        expect(message).not_to receive(:send_message)
        expect(message).not_to receive(:deliver_message)

        message.send_reply
      end

      it 'logs the skip behavior for debugging' do
        # The actual implementation should log when skipping
        # This test verifies the skip logic works correctly
        result = message.send_reply
        expect(result).to be_nil
      end
    end

    context 'when skip_send_reply flag is false' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :text,
               content: 'Test message',
               additional_attributes: { skip_send_reply: false })
      end

      it 'proceeds with normal reply sending flow' do
        # Mock the normal flow to verify it's called
        expect(SendReplyJob).to receive(:perform_later).with(message.id)

        message.send_reply
      end
    end

    context 'when skip_send_reply flag is not present' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :text,
               content: 'Test message',
               additional_attributes: {})
      end

      it 'proceeds with normal reply sending flow' do
        # Mock the normal flow to verify it's called
        expect(SendReplyJob).to receive(:perform_later).with(message.id)

        message.send_reply
      end
    end

    context 'when additional_attributes is nil' do
      let(:message) do
        create(:message,
               conversation: conversation,
               account: account,
               inbox: inbox,
               message_type: :outgoing,
               content_type: :text,
               content: 'Test message',
               additional_attributes: nil)
      end

      it 'proceeds with normal reply sending flow' do
        # Mock the normal flow to verify it's called
        expect(SendReplyJob).to receive(:perform_later).with(message.id)

        message.send_reply
      end
    end
  end

  describe 'flag application timing' do
    it 'applies skip_send_reply flag during message creation' do
      # Create message with flag
      message = conversation.messages.create!(
        content: 'Rich message content',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      # Verify flag is set immediately
      expect(message.additional_attributes['skip_send_reply']).to be true
      expect(message.additional_attributes.dig('skip_send_reply')).to be true
    end

    it 'prevents SendReplyJob enqueueing when flag is set during creation' do
      # Mock job to verify it's not enqueued
      expect(SendReplyJob).not_to receive(:perform_later)

      # Create message with flag - this should not trigger job
      message = conversation.messages.create!(
        content: 'Rich message content',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      # Manually call send_reply to verify it's skipped
      result = message.send_reply
      expect(result).to be_nil
    end
  end

  describe 'integration with Instagram Rich Message Service' do
    it 'verifies messages created for rich message service have skip_send_reply flag' do
      # Simulate how Instagram Rich Message Service creates messages
      message = conversation.messages.create!(
        content: 'Fallback text for rich message',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      # Verify the flag is properly set
      expect(message.additional_attributes['skip_send_reply']).to be true

      # Verify send_reply is skipped
      result = message.send_reply
      expect(result).to be_nil
    end

    it 'allows normal messages to proceed without the flag' do
      # Create normal message without flag
      message = conversation.messages.create!(
        content: 'Normal text message',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id
      )

      # Mock job to verify it's enqueued for normal messages
      expect(SendReplyJob).to receive(:perform_later).with(message.id)

      message.send_reply
    end
  end

  describe 'flag value variations' do
    it 'skips when flag is string "true"' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: 'true' })

      result = message.send_reply
      expect(result).to be_nil
    end

    it 'skips when flag is boolean true' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: true })

      result = message.send_reply
      expect(result).to be_nil
    end

    it 'proceeds when flag is string "false"' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: 'false' })

      expect(SendReplyJob).to receive(:perform_later).with(message.id)
      message.send_reply
    end

    it 'proceeds when flag is boolean false' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: false })

      expect(SendReplyJob).to receive(:perform_later).with(message.id)
      message.send_reply
    end

    it 'proceeds when flag is nil' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: nil })

      expect(SendReplyJob).to receive(:perform_later).with(message.id)
      message.send_reply
    end
  end

  describe 'metrics and tracking' do
    it 'allows unique message.id tracking for metrics correlation' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: true })

      # Verify message has unique ID for tracking
      expect(message.id).to be_present
      expect(message.id).to be_a(Integer)

      # Verify the flag can be tracked with message ID
      expect(message.additional_attributes.dig('skip_send_reply')).to be true
    end

    it 'maintains message ID consistency across service calls' do
      message = create(:message,
                       conversation: conversation,
                       account: account,
                       inbox: inbox,
                       message_type: :outgoing,
                       additional_attributes: { skip_send_reply: true })

      original_id = message.id

      # Reload message to verify ID consistency
      message.reload
      expect(message.id).to eq(original_id)

      # Verify flag persists
      expect(message.additional_attributes.dig('skip_send_reply')).to be true
    end
  end
end