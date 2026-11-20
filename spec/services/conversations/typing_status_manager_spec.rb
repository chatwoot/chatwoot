require 'rails_helper'

describe Conversations::TypingStatusManager do
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:account) { inbox.account }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:user) { create(:user, account: account) }
  let(:provider) { instance_double(Whatsapp::Providers::WhatsappCloudService, send_typing_indicator: true) }

  def toggle(params)
    described_class.new(conversation, user, ActionController::Parameters.new(params)).toggle_typing_status
  end

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider)
  end

  context 'when the request asks to notify the provider' do
    before do
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, source_id: 'wamid.old')
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :outgoing, source_id: 'wamid.sent')
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, source_id: 'wamid.last')
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, source_id: nil)
    end

    it 'sends the typing indicator for the last incoming message that has a wamid' do
      toggle(typing_status: 'on', notify_provider: true)

      expect(provider).to have_received(:send_typing_indicator).with('wamid.last')
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), hash_including(conversation: conversation, user: user))
    end

    it 'accepts the flag as a string, as a manual curl would send it' do
      toggle(typing_status: 'on', notify_provider: 'true')

      expect(provider).to have_received(:send_typing_indicator).with('wamid.last')
    end

    it 'does nothing on the provider for private notes' do
      toggle(typing_status: 'on', notify_provider: true, is_private: true)

      expect(provider).not_to have_received(:send_typing_indicator)
    end

    it 'does nothing on the provider for typing off' do
      toggle(typing_status: 'off', notify_provider: true)

      expect(provider).not_to have_received(:send_typing_indicator)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(Conversation::CONVERSATION_TYPING_OFF, kind_of(Time), anything)
    end
  end

  context 'when the request does not ask to notify the provider (dashboard keystrokes)' do
    it 'only dispatches the event, as before' do
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, source_id: 'wamid.last')

      toggle(typing_status: 'on', is_private: false)

      expect(provider).not_to have_received(:send_typing_indicator)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), anything)
    end
  end

  context 'when there is no incoming message with a wamid' do
    it 'does nothing on the provider' do
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :outgoing, source_id: 'wamid.sent')

      toggle(typing_status: 'on', notify_provider: true)

      expect(provider).not_to have_received(:send_typing_indicator)
    end
  end

  context 'when the inbox is not a WhatsApp Cloud inbox' do
    let(:inbox) { create(:inbox, account: create(:account)) }
    let(:account) { inbox.account }

    it 'does nothing on the provider' do
      create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, source_id: 'ext.1')

      toggle(typing_status: 'on', notify_provider: true)

      expect(provider).not_to have_received(:send_typing_indicator)
    end
  end
end
