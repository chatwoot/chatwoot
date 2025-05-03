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

  def build_typing_event(event_name, conversation:, is_private: false)
    Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: create(:user), is_private: is_private)
  end
end
