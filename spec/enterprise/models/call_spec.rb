require 'rails_helper'

RSpec.describe Call do
  describe '#push_event_data' do
    let(:account) { create(:account) }
    let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
    let(:inbox) { channel.inbox }
    let(:contact) { create(:contact, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:call) { create(:call, account: account, inbox: inbox, conversation: conversation, contact: contact) }

    it 'renders without raising for a call whose contact no longer exists' do
      call
      contact.delete

      data = call.reload.push_event_data
      expect(data[:from_number]).to be_nil
    end
  end
end
