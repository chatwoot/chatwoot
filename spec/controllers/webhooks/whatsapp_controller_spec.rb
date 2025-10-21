require 'rails_helper'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }

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
    it 'call the whatsapp events job with the params' do
      allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)
      post '/webhooks/whatsapp/123221321', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end

    context 'when phone number is in inactive list' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('INACTIVE_WHATSAPP_NUMBERS').and_return('+1234567890,+9876543210')
      end

      it 'returns service unavailable for inactive phone number in URL params' do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with('Rejected webhook for inactive WhatsApp number: +1234567890')

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }
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

        post '/webhooks/whatsapp/+1234567890', params: { content: 'hello' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /webhooks/whatsapp (new format)' do
    let(:facebook_payload) do
      {
        object: 'whatsapp_business_account',
        entry: [
          {
            id: 'WHATSAPP_BUSINESS_ACCOUNT_ID',
            changes: [
              {
                value: {
                  messaging_product: 'whatsapp',
                  metadata: {
                    display_phone_number: '15551234567',
                    phone_number_id: '812071281985019'
                  },
                  messages: [
                    {
                      from: '1234567890',
                      id: 'wamid.ABC123',
                      timestamp: '1234567890',
                      text: { body: 'Hello World' },
                      type: 'text'
                    }
                  ]
                },
                field: 'messages'
              }
            ]
          }
        ]
      }
    end

    context 'when using Facebook WhatsApp Business API format' do
      before do
        # Create channel with phone_number_id in provider_config
        channel.provider_config['phone_number_id'] = '812071281985019'
        channel.save!
      end

      it 'extracts phone_number_id from payload and processes webhook' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
        expect(Webhooks::WhatsappEventsJob).to receive(:perform_later) do |params|
          expect(params[:phone_number_id]).to eq('812071281985019')
        end

        post '/webhooks/whatsapp', params: facebook_payload
        expect(response).to have_http_status(:success)
      end

      it 'verifies using FB_VERIFY_TOKEN for Facebook webhooks' do
        allow(ENV).to receive(:[]).with('FB_VERIFY_TOKEN').and_return('facebook_verify_token_123')

        get '/webhooks/whatsapp',
            params: {
              'hub.challenge' => '123456',
              'hub.mode' => 'subscribe',
              'hub.verify_token' => 'facebook_verify_token_123'
            }
        expect(response.body).to include '123456'
      end

      it 'falls back to channel-specific verification when FB_VERIFY_TOKEN not set' do
        allow(ENV).to receive(:[]).with('FB_VERIFY_TOKEN').and_return(nil)

        get '/webhooks/whatsapp',
            params: {
              'hub.challenge' => '123456',
              'hub.mode' => 'subscribe',
              'hub.verify_token' => channel.provider_config['webhook_verify_token'],
              :object => 'whatsapp_business_account',
              :entry => [
                {
                  changes: [
                    {
                      value: {
                        metadata: {
                          phone_number_id: '812071281985019'
                        }
                      },
                      field: 'messages'
                    }
                  ]
                }
              ]
            }
        expect(response.body).to include '123456'
      end

      it 'returns unauthorized when FB_VERIFY_TOKEN does not match' do
        allow(ENV).to receive(:[]).with('FB_VERIFY_TOKEN').and_return('facebook_verify_token_123')

        get '/webhooks/whatsapp',
            params: {
              'hub.challenge' => '123456',
              'hub.mode' => 'subscribe',
              'hub.verify_token' => 'wrong_token'
            }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when phone_number_id is not found' do
      let(:unknown_payload) do
        facebook_payload.tap do |payload|
          payload[:entry][0][:changes][0][:value][:metadata][:phone_number_id] = 'unknown_id'
        end
      end

      it 'still processes webhook for backward compatibility' do
        allow(Webhooks::WhatsappEventsJob).to receive(:perform_later)
        expect(Webhooks::WhatsappEventsJob).to receive(:perform_later)

        post '/webhooks/whatsapp', params: unknown_payload
        expect(response).to have_http_status(:success)
      end
    end
  end
end
