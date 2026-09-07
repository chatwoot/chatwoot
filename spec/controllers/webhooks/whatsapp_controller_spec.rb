require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:client_secret) { 'test-whatsapp-secret' }
  let(:body) { { content: 'hello' }.to_json }

  def signature_for(body, secret = client_secret)
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
  end

  def post_whatsapp_webhook(path, body, signature: signature_for(body), env: { WHATSAPP_APP_SECRET: client_secret })
    with_modified_env env do
      post path,
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json', 'X-Hub-Signature-256' => signature }
    end
  end

  def post_unsigned_whatsapp_webhook(path, body, env: { WHATSAPP_APP_SECRET: client_secret })
    with_modified_env env do
      post path,
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json' }
    end
  end

  before do
    InstallationConfig.where(name: 'WHATSAPP_APP_SECRET').delete_all
    GlobalConfig.clear_cache
  end

  describe 'GET /webhooks/verify' do
    it 'returns 401 when valid params are not present' do
      get "/webhooks/whatsapp/#{channel.phone_number}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 when invalid params' do
      get "/webhooks/whatsapp/#{channel.phone_number}",
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'invalid' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns challenge when valid params' do
      get "/webhooks/whatsapp/#{channel.phone_number}",
          params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => channel.provider_config['webhook_verify_token'] }
      expect(response.body).to include '123456'
    end
  end

  describe 'POST /webhooks/whatsapp/{:phone_number}' do
    context 'with WhatsApp Business payloads' do
      let(:tracking_change) do
        { field: 'tracking_events', value: { events: [{ event_name: 'delivered', timestamp: 1_788_091_821 }] } }
      end
      let(:entries) { [{ changes: [tracking_change] }] }
      let(:payload) { { object: 'whatsapp_business_account', entry: entries } }
      let(:body) { payload.to_json }

      before do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      end

      it 'acknowledges tracking-only payloads without enqueueing a job' do
        post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

        expect(response).to have_http_status(:ok)
        expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
      end

      it 'skips multiple tracking changes across entries' do
        payload[:entry] = [{ changes: [tracking_change, tracking_change] }, { changes: [tracking_change] }]
        post_whatsapp_webhook('/webhooks/whatsapp/123221321', payload.to_json)

        expect(response).to have_http_status(:ok)
        expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
      end

      it 'rejects tracking-only payloads for inactive numbers' do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890')

        post_whatsapp_webhook('/webhooks/whatsapp/+1234567890', body)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Inactive WhatsApp number')
        expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
      end

      it 'rejects unsigned tracking-only payloads' do
        post_unsigned_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

        expect(response).to have_http_status(:unauthorized)
        expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
      end

      it 'rejects tracking-only payloads with an invalid signature' do
        post_whatsapp_webhook('/webhooks/whatsapp/123221321', body, signature: 'sha256=invalid-signature')

        expect(response).to have_http_status(:unauthorized)
        expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
      end

      %w[sent delivered read failed].each do |status|
        it "enqueues ordinary #{status} message-status updates" do
          payload[:entry] = [{ changes: [{ field: 'messages', value: { statuses: [{ id: 'wamid.test', status: status }] } }] }]
          post_whatsapp_webhook('/webhooks/whatsapp/123221321', payload.to_json)

          expect(response).to have_http_status(:ok)
          expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later).with(hash_including(payload.deep_stringify_keys))
        end
      end

      %w[messages smb_message_echoes calls].each do |field|
        it "preserves #{field} events in mixed payloads" do
          entries.first[:changes] << { field: field, value: {} }
          post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

          expect(response).to have_http_status(:ok)
          expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later).with(hash_including(payload.deep_stringify_keys))
        end
      end

      it 'preserves non-tracking changes in subsequent entries' do
        entries << { changes: [{ field: 'messages', value: { messages: [{ id: 'wamid.test', type: 'text', text: { body: 'Hello' } }] } }] }
        post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

        expect(response).to have_http_status(:ok)
        expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later).with(hash_including(payload.deep_stringify_keys))
      end

      context 'with no entries' do
        let(:entries) { [] }

        it 'does not classify the payload as tracking-only' do
          post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

          expect(response).to have_http_status(:ok)
          expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
        end
      end

      context 'with no changes' do
        let(:entries) { [{ changes: [] }] }

        it 'does not classify the payload as tracking-only' do
          post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)

          expect(response).to have_http_status(:ok)
          expect(Webhooks::WhatsappEventsJob).to have_received(:perform_later)
        end
      end
    end

    it 'calls the whatsapp events job with the params for a valid signature' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post_whatsapp_webhook('/webhooks/whatsapp/123221321', body)
      expect(response).to have_http_status(:success)
    end

    it 'accepts webhook payloads signed with the channel app secret' do
      channel_secret = 'channel-whatsapp-secret'
      channel.provider_config = channel.provider_config.merge('app_secret' => channel_secret)
      channel.save!

      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      channel_body = {
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              metadata: {
                display_phone_number: channel.phone_number.delete_prefix('+'),
                phone_number_id: channel.provider_config['phone_number_id']
              }
            }
          }]
        }]
      }.to_json

      post_whatsapp_webhook(
        "/webhooks/whatsapp/#{channel.phone_number}",
        channel_body,
        signature: signature_for(channel_body, channel_secret),
        env: {}
      )

      expect(response).to have_http_status(:success)
    end

    it 'skips signature validation for 360dialog channels' do
      dialog_channel = create(:channel_whatsapp, provider: 'default', sync_templates: false, validate_provider_config: false)
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      post_unsigned_whatsapp_webhook("/webhooks/whatsapp/#{dialog_channel.phone_number}", body)

      expect(response).to have_http_status(:success)
    end

    it 'skips signature validation for manual whatsapp cloud channels without an app secret' do
      channel.update!(
        provider_config: channel.provider_config.except('app_secret', 'app_secret_key', 'api_secret', 'client_secret', 'source')
      )
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      channel_body = {
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              metadata: {
                display_phone_number: channel.phone_number.delete_prefix('+'),
                phone_number_id: channel.provider_config['phone_number_id']
              }
            }
          }]
        }]
      }.to_json

      post_unsigned_whatsapp_webhook("/webhooks/whatsapp/#{channel.phone_number}", channel_body)

      expect(response).to have_http_status(:success)
    end

    it 'returns unauthorized when signature is missing' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      with_modified_env WHATSAPP_APP_SECRET: client_secret do
        post '/webhooks/whatsapp/123221321',
             params: body,
             headers: { 'CONTENT_TYPE' => 'application/json' }
      end

      expect(response).to have_http_status(:unauthorized)
      expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
    end

    it 'returns unauthorized when signature is invalid' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)

      post_whatsapp_webhook('/webhooks/whatsapp/123221321', body, signature: 'sha256=invalid-signature')

      expect(response).to have_http_status(:unauthorized)
      expect(Webhooks::WhatsappEventsJob).not_to have_received(:perform_later)
    end

    context 'when phone number is in inactive list' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890,+9876543210')
      end

      it 'returns service unavailable for inactive phone number in URL params' do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with('Rejected webhook for inactive WhatsApp number: +1234567890')

        post_whatsapp_webhook('/webhooks/whatsapp/+1234567890', body)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Inactive WhatsApp number')
      end
    end

    context 'when INACTIVE_WHATSAPP_NUMBERS config is not set' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return(nil)
      end

      it 'processes the webhook normally' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
        expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

        post_whatsapp_webhook('/webhooks/whatsapp/+1234567890', body)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
