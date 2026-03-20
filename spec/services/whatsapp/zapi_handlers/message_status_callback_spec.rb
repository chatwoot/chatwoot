require 'rails_helper'

describe Whatsapp::ZapiHandlers::MessageStatusCallback do
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:service) { Whatsapp::IncomingMessageZapiService.new(inbox: inbox, params: params) }

  describe '#process_message_status_callback' do
    let(:message1) { create(:message, inbox: inbox, source_id: 'msg_123') }
    let(:message2) { create(:message, inbox: inbox, source_id: 'msg_456') }
    let(:params) do
      {
        type: 'MessageStatusCallback',
        ids: [message1.source_id, message2.source_id],
        status: 'SENT'
      }
    end

    it 'updates message status to sent when Z-API status is SENT' do
      service.perform

      expect(message1.reload.status).to eq('sent')
      expect(message2.reload.status).to eq('sent')
    end

    it 'updates message status to delivered for DELIVERED status' do
      params[:status] = 'DELIVERED'

      service.perform

      expect(message1.reload.status).to eq('delivered')
      expect(message2.reload.status).to eq('delivered')
    end

    it 'updates message status to delivered for RECEIVED status' do
      params[:status] = 'RECEIVED'

      service.perform

      expect(message1.reload.status).to eq('delivered')
      expect(message2.reload.status).to eq('delivered')
    end

    it 'updates message status to read for READ status' do
      params[:status] = 'READ'

      service.perform

      expect(message1.reload.status).to eq('read')
      expect(message2.reload.status).to eq('read')
    end

    it 'updates message status to read for READ_BY_ME status' do
      params[:status] = 'READ_BY_ME'

      service.perform

      expect(message1.reload.status).to eq('read')
      expect(message2.reload.status).to eq('read')
    end

    it 'updates message status to read for PLAYED status' do
      params[:status] = 'PLAYED'

      service.perform

      expect(message1.reload.status).to eq('read')
      expect(message2.reload.status).to eq('read')
    end

    it 'does not update status on unknown status and logs warning' do
      params[:status] = 'UNKNOWN_STATUS'
      allow(Rails.logger).to receive(:warn)

      expect do
        service.perform
      end.not_to(change { [message1.reload.status, message2.reload.status] })

      expect(Rails.logger).to have_received(:warn).with('Unknown ZAPI status: UNKNOWN_STATUS')
    end

    context 'when status transition is not allowed' do
      it 'does not downgrade read message to delivered' do
        message1.update!(status: 'read')
        params[:status] = 'DELIVERED'

        expect do
          service.perform
        end.not_to(change { message1.reload.status })
      end

      it 'does not downgrade read message to sent' do
        message1.update!(status: 'read')
        params[:status] = 'SENT'

        expect do
          service.perform
        end.not_to(change { message1.reload.status })

        expect(message1.status).to eq('read')
      end

      it 'does not downgrade delivered message to sent' do
        message1.update!(status: 'delivered')
        params[:status] = 'SENT'

        expect do
          service.perform
        end.not_to(change { message1.reload.status })

        expect(message1.status).to eq('delivered')
      end

      it 'allows upgrading delivered message to read' do
        message1.update!(status: 'delivered')
        params[:status] = 'READ'

        service.perform

        expect(message1.reload.status).to eq('read')
      end

      it 'allows upgrading sent message to delivered' do
        message1.update!(status: 'sent')
        params[:status] = 'DELIVERED'

        service.perform

        expect(message1.reload.status).to eq('delivered')
      end

      it 'allows upgrading sent message to read' do
        message1.update!(status: 'sent')
        params[:status] = 'READ'

        service.perform

        expect(message1.reload.status).to eq('read')
      end

      it 'handles mixed status transitions correctly' do
        message1.update!(status: 'sent')
        message2.update!(status: 'read')
        params[:status] = 'DELIVERED'

        service.perform

        expect(message1.reload.status).to eq('delivered')
        expect(message2.reload.status).to eq('read')
      end
    end
  end
end
