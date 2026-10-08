require 'rails_helper'

describe Messages::NewMessageNotificationService do
  let(:account) { create(:account) }
  let(:assignee) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, assignee: assignee) }
  let(:message) do
    create(:message, message_type: :incoming, content_type: :voice_call, account: account, conversation: conversation)
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    create(:call, conversation: conversation, message_id: message.id)
  end

  it 'creates no notification for an agent the call rang, on an account that rings phones' do
    account.enable_features!('mobile_voice_push')

    expect(NotificationBuilder).not_to receive(:new)
    described_class.new(message: message).perform
  end

  it 'keeps notifying an assignee who was not rung because they are busy' do
    account.enable_features!('mobile_voice_push')
    AccountUser.find_by(account: account, user: assignee).update!(availability: :busy)

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end

  it 'keeps notifying for call messages on accounts without mobile voice push' do
    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end
end
