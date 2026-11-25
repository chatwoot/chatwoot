require 'rails_helper'

RSpec.describe Notification::PushNotificationJob do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:internal_chat_channel, :dm, account: account) }
  let(:message) { create(:internal_chat_message, account: account, channel: channel, sender: create(:user, account: account)) }
  let(:notification) do
    create(:notification, account: account, user: agent, notification_type: 'internal_chat_new_message',
                          primary_actor: channel, secondary_actor: message)
  end
  let(:service) { instance_double(Notification::PushNotificationService, perform: true) }

  before { allow(Notification::PushNotificationService).to receive(:new).and_return(service) }

  it 'delivers an internal chat push to a member who still has access' do
    described_class.perform_now(notification)

    expect(service).to have_received(:perform)
  end

  it 'drops it when the access was revoked after it was enqueued' do
    notification
    stub_const('FeatureAccess::CAPABILITIES', { 'internal_chat.access' => { agent_default: false } })

    described_class.perform_now(notification)

    expect(service).not_to have_received(:perform)
  end
end
