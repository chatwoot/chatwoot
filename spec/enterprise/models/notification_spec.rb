require 'rails_helper'

RSpec.describe Notification do
  context 'when the notification is a missed call' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account, name: 'Priya', phone_number: '+919999999999') }
    let(:conversation) { create(:conversation, account: account, contact: contact) }
    let(:message) { create(:message, conversation: conversation, account: account, content_type: :voice_call, sender: contact) }
    let(:notification) do
      create(:notification, notification_type: 'voice_call_missed', account: account, primary_actor: conversation, secondary_actor: message)
    end

    it 'titles the push with the inbox that was called' do
      expect(notification.push_message_title).to eq("Missed call · #{conversation.inbox.name}")
    end

    it 'names the caller in the body the way a call log does' do
      expect(notification.push_message_body).to eq('Priya · +919999999999')
    end

    it 'falls back to the name alone when the contact has no number' do
      contact.update!(phone_number: nil)

      expect(notification.push_message_body).to eq('Priya')
    end
  end
end
