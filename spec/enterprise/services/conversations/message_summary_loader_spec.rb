require 'rails_helper'

RSpec.describe Conversations::MessageSummaryLoader do
  let(:account) { create(:account) }
  let(:inbox) { create(:channel_twilio_sms, :with_voice, account: account).inbox }
  let(:agent) { create(:user, account: account) }
  let(:contact) { create(:contact, :with_phone_number, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content_type: 'voice_call') }

  def queries(&)
    statements = []
    callback = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] unless payload[:name] == 'SCHEMA' }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    statements
  end

  it 'leaves nothing to query when a voice call message is serialized' do
    call = create(:call, conversation: conversation, message: message, accepted_by_agent: agent)
    call.recording.attach(io: StringIO.new('audio'), filename: 'recording.mp3', content_type: 'audio/mpeg')
    Current.account = account
    loaded = Conversation.where(id: conversation.id).includes(:contact_inbox).to_a
    described_class.new(loaded).perform

    data = nil
    statements = queries { data = loaded.first.message_summary.last_message.push_event_data }

    expect(statements).to be_empty
    expect(data[:call]).to include(
      id: call.id, accepted_by_agent_name: agent.available_name, from_number: contact.phone_number, to_number: inbox.channel.phone_number
    )
    expect(data[:call][:recording_url]).to be_present
  end
end
