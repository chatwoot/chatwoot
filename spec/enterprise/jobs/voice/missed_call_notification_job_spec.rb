# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::MissedCallNotificationJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:outsider) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) { create(:call, conversation: conversation, provider: :whatsapp, status: 'no_answer') }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: other_agent)
    call.update!(message: Voice::CallMessageBuilder.new(call).perform!)
  end

  def missed_calls_for(user)
    user.notifications.where(notification_type: 'voice_call_missed')
  end

  it 'records a missed call for every agent the call rang' do
    described_class.perform_now(call.id)

    expect(missed_calls_for(agent).count).to eq(1)
    expect(missed_calls_for(other_agent).count).to eq(1)
    expect(missed_calls_for(outsider).count).to eq(0)
    notification = missed_calls_for(agent).first
    expect(notification.primary_actor).to eq(conversation)
    expect(notification.secondary_actor).to eq(call.message)
  end

  it 'records it only for the assignee when the conversation is assigned' do
    conversation.update!(assignee: other_agent)

    described_class.perform_now(call.id)

    expect(missed_calls_for(agent).count).to eq(0)
    expect(missed_calls_for(other_agent).count).to eq(1)
  end

  it 'records it for the agents whose phones rang even after the conversation was reassigned' do
    call.update!(meta: { 'ring_recipient_ids' => [agent.id] })
    conversation.update!(assignee: other_agent)

    described_class.perform_now(call.id)

    expect(missed_calls_for(agent).count).to eq(1)
    expect(missed_calls_for(other_agent).count).to eq(0)
  end

  it 'does not record the same missed call twice' do
    described_class.perform_now(call.id)
    described_class.perform_now(call.id)

    expect(missed_calls_for(agent).count).to eq(1)
  end

  it 'ignores calls that were answered, declined or placed by an agent' do
    call.update!(status: 'rejected')
    described_class.perform_now(call.id)
    call.update!(status: 'no_answer', direction: :outgoing)
    described_class.perform_now(call.id)

    expect(Notification.where(notification_type: 'voice_call_missed')).to be_empty
  end
end
