# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe '#reopen_conversation' do
    let(:conversation) { create(:conversation) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation) }

    it 'reopens resolved conversation when the message is from a contact' do
      conversation.resolved!
      message.save!
      expect(message.conversation.open?).to eq true
    end

    it 'reopens snoozed conversation when the message is from a contact' do
      conversation.snoozed!
      message.save!
      expect(message.conversation.open?).to eq true
    end

    it 'will not reopen if the conversation is muted' do
      conversation.resolved!
      conversation.mute!
      message.save!
      expect(message.conversation.open?).to eq false
    end
  end

  context 'when message is created' do
    let(:message) { build(:message, account: create(:account)) }

    it 'updates conversation last_activity_at when created' do
      message.save!
      expect(message.created_at).to eq message.conversation.last_activity_at
    end

    it 'updates contact last_activity_at when created' do
      expect { message.save! }.to(change { message.sender.last_activity_at })
    end

    it 'triggers ::MessageTemplates::HookExecutionService' do
      hook_execution_service = double
      allow(::MessageTemplates::HookExecutionService).to receive(:new).and_return(hook_execution_service)
      allow(hook_execution_service).to receive(:perform).and_return(true)

      message.save!

      expect(::MessageTemplates::HookExecutionService).to have_received(:new).with(message: message)
      expect(hook_execution_service).to have_received(:perform)
    end

    it 'calls notify email method on after save for outgoing messages' do
      allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
      message.message_type = 'outgoing'
      message.save!
      expect(ConversationReplyEmailWorker).to have_received(:perform_in)
    end

    it 'wont call notify email method for private notes' do
      message.private = true
      allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
      message.save!
      expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
    end

    it 'calls EmailReply worker if the channel is email' do
      message.inbox = create(:inbox, account: message.account, channel: build(:channel_email, account: message.account))
      allow(EmailReplyWorker).to receive(:perform_in).and_return(true)
      message.message_type = 'outgoing'
      message.save!
      expect(EmailReplyWorker).to have_received(:perform_in).with(1.second, message.id)
    end

    it 'wont call notify email method unless its website or email channel' do
      message.inbox = create(:inbox, account: message.account, channel: build(:channel_api, account: message.account))
      allow(ConversationReplyEmailWorker).to receive(:perform_in).and_return(true)
      message.save!
      expect(ConversationReplyEmailWorker).not_to have_received(:perform_in)
    end
  end

  context 'when content_type is blank' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'sets content_type as text' do
      message.save!
      expect(message.content_type).to eq 'text'
    end
  end
end
