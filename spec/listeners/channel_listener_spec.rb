require 'rails_helper'
describe ChannelListener do
  let(:listener) { described_class.instance }

  context 'when handling typing events' do
    let(:channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
    let(:conversation) { create(:conversation, inbox: create(:inbox, channel: channel)) }

    it 'skips the event if is_private is true' do
      allow(channel).to receive(:toggle_typing_status)

      listener.conversation_typing_on(build_typing_event(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation, is_private: true))

      expect(channel).not_to have_received(:toggle_typing_status)
    end

    it 'skips the event if channel does not respond to toggle_typing_status' do
      channel = create(:channel_api)
      conversation = create(:conversation, inbox: create(:inbox, channel: channel))

      expect do
        listener.conversation_typing_on(build_typing_event(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation))
      end.not_to raise_error
    end

    describe '#conversation_typing_on' do
      let(:event_name) { Events::Types::CONVERSATION_TYPING_ON }

      it 'calls toggle_typing_status on the channel' do
        allow(channel).to receive(:toggle_typing_status).with(event_name, conversation: conversation)

        listener.conversation_typing_on(build_typing_event(event_name, conversation: conversation))

        expect(channel).to have_received(:toggle_typing_status)
      end
    end

    describe '#conversation_recording' do
      let(:event_name) { Events::Types::CONVERSATION_RECORDING }

      it 'calls toggle_typing_status on the channel' do
        allow(channel).to receive(:toggle_typing_status).with(event_name, conversation: conversation)

        listener.conversation_recording(build_typing_event(event_name, conversation: conversation))

        expect(channel).to have_received(:toggle_typing_status)
      end
    end

    describe '#conversation_typing_off' do
      let(:event_name) { Events::Types::CONVERSATION_TYPING_OFF }

      it 'calls toggle_typing_status on the channel' do
        allow(channel).to receive(:toggle_typing_status).with(event_name, conversation: conversation)

        listener.conversation_typing_off(build_typing_event(event_name, conversation: conversation))

        expect(channel).to have_received(:toggle_typing_status)
      end
    end
  end

  describe '#conversation_unread' do
    let(:channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
    let(:conversation) { create(:conversation, inbox: create(:inbox, channel: channel)) }
    let(:event) { Events::Base.new(Events::Types::CONVERSATION_UNREAD, Time.zone.now, conversation: conversation) }

    it 'calls unread_conversation on the channel' do
      allow(channel).to receive(:unread_conversation).with(conversation)

      listener.conversation_unread(event)

      expect(channel).to have_received(:unread_conversation)
    end
  end

  describe '#account_presence_updated' do
    let(:account_user) { create(:account_user) }
    let(:inbox) { create(:inbox, account: account_user.account) }
    let(:channel) { create(:channel_whatsapp, inbox: inbox, sync_templates: false, validate_provider_config: false) }
    let(:event) do
      Events::Base.new(Events::Types::ACCOUNT_PRESENCE_UPDATED, Time.zone.now, account_id: account_user.account.id, user_id: account_user.user.id,
                                                                               status: 'online')
    end

    before do
      inbox.inbox_members.create!(user: account_user.user)
    end

    it 'updates the presence of the channel' do
      allow(channel).to receive(:update_presence).with('online')
      allow_any_instance_of(Inbox).to receive(:channel).and_return(channel) # rubocop:disable RSpec/AnyInstance

      listener.account_presence_updated(event)

      expect(inbox.channel).to have_received(:update_presence)
    end

    it 'skips the event if the channel does not respond to update_presence' do
      create(:channel_api, inbox: inbox)

      expect do
        listener.account_presence_updated(event)
      end.not_to raise_error
    end
  end

  describe '#messages_read' do
    let(:channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
    let(:conversation) { create(:conversation, inbox: create(:inbox, channel: channel)) }
    let(:last_seen_at) { 1.day.ago }
    let(:event) { Events::Base.new(Events::Types::MESSAGES_READ, Time.zone.now, conversation: conversation, last_seen_at: last_seen_at) }

    it 'sends read messages to the channel' do
      create(:message, conversation: conversation, message_type: :incoming, status: :read)
      sent_message = create(:message, conversation: conversation, message_type: :incoming, status: :sent)

      allow(channel).to receive(:read_messages).with([sent_message], conversation: conversation)

      listener.messages_read(event)

      expect(channel).to have_received(:read_messages)
    end

    it 'skips the event if the channel does not respond to send_read_messages' do
      create(:channel_api, inbox: conversation.inbox)

      expect do
        listener.messages_read(event)
      end.not_to raise_error
    end

    it 'skips the event if there are no unread messages' do
      create(:message, conversation: conversation, message_type: :incoming, status: :read)

      allow(channel).to receive(:read_messages)

      listener.messages_read(event)

      expect(channel).not_to have_received(:read_messages)
    end

    it 'filters messages ignoring last_seen_at' do
      old_message = create(:message, conversation: conversation, message_type: :incoming, status: :sent, updated_at: last_seen_at - 1.day)
      recent_message = create(:message, conversation: conversation, message_type: :incoming, status: :sent, updated_at: Time.zone.now)

      allow(channel).to receive(:read_messages).with([old_message, recent_message], conversation: conversation)

      listener.messages_read(Events::Base.new(Events::Types::MESSAGES_READ, Time.zone.now, conversation: conversation, last_seen_at: nil))

      expect(channel).to have_received(:read_messages)
    end

    it 'filters messages based on last_seen_at' do
      create(:message, conversation: conversation, message_type: :incoming, status: :sent, updated_at: last_seen_at - 1.day)
      recent_message = create(:message, conversation: conversation, message_type: :incoming, status: :sent, updated_at: Time.zone.now)

      allow(channel).to receive(:read_messages).with([recent_message], conversation: conversation)

      listener.messages_read(event)

      expect(channel).to have_received(:read_messages)
    end
  end

  def build_typing_event(event_name, conversation:, is_private: false)
    Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: create(:user), is_private: is_private)
  end
end
