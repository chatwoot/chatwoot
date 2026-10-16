require 'rails_helper'

RSpec.describe SendReplyJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_twilio_sms, account: account)) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:translation) { instance_double(Captain::Conversation::AgentMessageTranslationService, perform: true) }
  let(:channel_service) { instance_double(Twilio::SendOnTwilioService, perform: true) }

  before do
    allow(Captain::Conversation::AgentMessageTranslationService).to receive(:new).and_return(translation)
    allow(Twilio::SendOnTwilioService).to receive(:new).and_return(channel_service)
  end

  it 'translates a pending reply before handing it to the channel' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing,
                               content_attributes: { translation_pending: true })

    described_class.perform_now(message.id)

    expect(Captain::Conversation::AgentMessageTranslationService).to have_received(:new).with(message: message).ordered
    expect(Twilio::SendOnTwilioService).to have_received(:new).ordered
  end

  it 'sends every other message as it is' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing)

    described_class.perform_now(message.id)

    expect(Captain::Conversation::AgentMessageTranslationService).not_to have_received(:new)
    expect(channel_service).to have_received(:perform)
  end
end
