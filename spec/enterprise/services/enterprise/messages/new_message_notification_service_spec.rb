require 'rails_helper'

describe Messages::NewMessageNotificationService do
  let(:account) { create(:account) }
  let(:assignee) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, assignee: assignee) }
  let(:message) do
    create(:message, message_type: :incoming, content_type: :voice_call, account: account, conversation: conversation)
  end

  it 'creates no notification for a call message on an account that rings phones and records missed calls' do
    account.enable_features!('mobile_voice_push')

    expect(NotificationBuilder).not_to receive(:new)
    described_class.new(message: message).perform
  end

  it 'keeps notifying for call messages on accounts without mobile voice push' do
    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end
end
