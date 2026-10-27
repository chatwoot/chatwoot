require 'rails_helper'

describe Messages::NewMessageNotificationService do
  let(:account) { create(:account) }
  let(:assignee) { create(:user, account: account) }
  let(:inbox) { create(:channel_twilio_sms, :with_voice, account: account).inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: assignee) }
  let(:message) do
    create(:message, message_type: :incoming, content_type: :voice_call, account: account, conversation: conversation)
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(GlobalConfigService).to receive(:load) do |key, default|
      { 'APNS_VOIP_KEY' => 'p8', 'APNS_VOIP_KEY_ID' => 'KEY1', 'APNS_VOIP_TEAM_ID' => 'TEAM1' }.fetch(key, default)
    end
    create(:inbox_member, inbox: conversation.inbox, user: assignee)
    create(:call, conversation: conversation, message_id: message.id, ring_state: { 'ring_recipient_ids' => [assignee.id] })
  end

  def subscribe_phone(user)
    create(:notification_subscription, user: user, subscription_type: 'apns_voip', identifier: "apns_voip:#{user.id}",
                                       subscription_attributes: { push_token: "token-#{user.id}", device_id: "device-#{user.id}" })
  end

  it 'creates no notification for an agent the call rang, on an account that rings phones' do
    account.enable_features!('mobile_voice_push')
    subscribe_phone(assignee)

    expect(NotificationBuilder).not_to receive(:new)
    described_class.new(message: message).perform
  end

  it 'notifies under the message row lock, which the replay after a ring takes too' do
    allow(message).to receive(:with_lock).and_call_original

    described_class.new(message: message).perform

    expect(message).to have_received(:with_lock)
  end

  it 'keeps notifying for a call that never entered the ring' do
    account.enable_features!('mobile_voice_push')
    subscribe_phone(assignee)
    Call.find_by(message_id: message.id).update!(ring_state: {})

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end

  it 'notifies an agent held back before the ring once the ring reaches no phone of theirs' do
    account.enable_features!('mobile_voice_push')
    phone = subscribe_phone(assignee)
    described_class.new(message: message).perform
    phone.destroy!

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    Voice::VoipPushService.new(call: Call.find_by(message_id: message.id)).perform('ring')
  end

  it 'keeps notifying a rung agent who gets missed calls by neither push nor email' do
    account.enable_features!('mobile_voice_push')
    subscribe_phone(assignee)
    assignee.notification_settings.find_by(account_id: account.id).update!(push_voice_call_missed: false)

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end

  it 'keeps notifying while the message is not linked to its call yet' do
    account.enable_features!('mobile_voice_push')
    subscribe_phone(assignee)
    Call.find_by(message_id: message.id).update!(message_id: nil)

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end

  it 'keeps notifying an agent chosen for the ring who has no phone it can reach' do
    account.enable_features!('mobile_voice_push')

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
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

  it 'keeps holding back a rung agent once the feature is turned off during the call' do
    subscribe_phone(assignee)

    expect(NotificationBuilder).not_to receive(:new)
    described_class.new(message: message).perform
  end

  it 'keeps notifying for call messages on accounts without mobile voice push, whose calls never enter the ring' do
    subscribe_phone(assignee)
    Call.find_by(message_id: message.id).update!(ring_state: {})

    expect(NotificationBuilder).to receive(:new)
      .with(hash_including(notification_type: 'assigned_conversation_new_message', user: assignee))
      .and_call_original
    described_class.new(message: message).perform
  end
end
