require 'rails_helper'

describe Whatsapp::IncomingMessageZapiService do
  describe '#perform' do
    let!(:whatsapp_channel) do
      create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false, received_messages: false)
    end
    let(:inbox) { whatsapp_channel.inbox }

    context 'when type is blank' do
      it 'does nothing' do
        params = { type: '' }

        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.not_to change(Message, :count)
      end

      it 'does nothing when type is nil' do
        params = {}

        expect do
          described_class.new(inbox: inbox, params: params).perform
        end.not_to change(Message, :count)
      end
    end

    context 'when event type is unsupported' do
      it 'logs a warning message' do
        params = { type: 'unsupported_event' }
        allow(Rails.logger).to receive(:warn)

        described_class.new(inbox: inbox, params: params).perform

        expect(Rails.logger).to have_received(:warn).with(/Z-API unsupported event/)
      end
    end

    it 'dispatches the provider.event_received event' do
      params = { type: 'some_event' }
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      described_class.new(inbox: inbox, params: params).perform

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
        Events::Types::PROVIDER_EVENT_RECEIVED,
        kind_of(Time),
        inbox: inbox,
        event: params[:type],
        payload: params
      )
    end
  end
end
