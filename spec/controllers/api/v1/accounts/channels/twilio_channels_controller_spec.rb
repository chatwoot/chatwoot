require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/channels/twilio_channel', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:twilio_client) { instance_double(::Twilio::REST::Client) }
  let(:message_double) { double }
  let(:twilio_webhook_setup_service) { instance_double(::Twilio::WebhookSetupService) }

  before do
    allow(::Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(::Twilio::WebhookSetupService).to receive(:new).and_return(twilio_webhook_setup_service)
    allow(twilio_webhook_setup_service).to receive(:perform)
  end

  describe 'POST /api/v1/accounts/{account.id}/channels/twilio_channel' do
    let(:params) do
      {
        twilio_channel: {
          account_sid: 'sid',
          auth_token: 'token',
          phone_number: '',
          messaging_service_sid: 'MGec8130512b5dd462cfe03095ec1342ed',
          name: 'SMS Channel',
          medium: 'sms'
        }
      }
    end

    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_channels_twilio_channel_path(account), params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      context 'with user as administrator' do
        it 'creates inbox and returns inbox object' do
          allow(twilio_client).to receive(:messages).and_return(message_double)
          allow(message_double).to receive(:list).and_return([])

          post api_v1_account_channels_twilio_channel_path(account),
               params: params,
               headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['name']).to eq('SMS Channel')
          expect(json_response['messaging_service_sid']).to eq('MGec8130512b5dd462cfe03095ec1342ed')
        end

        it 'creates inbox with blank phone number and returns inbox object' do
          params = {
            twilio_channel: {
              account_sid: 'sid-1',
              auth_token: 'token-1',
              phone_number: '',
              messaging_service_sid: 'MGec8130512b5dd462cfe03095ec1111ed',
              name: 'SMS Channel',
              medium: 'whatsapp'
            }
          }
          allow(twilio_client).to receive(:messages).and_return(message_double)
          allow(message_double).to receive(:list).and_return([])

          post api_v1_account_channels_twilio_channel_path(account),
               params: params,
               headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['messaging_service_sid']).to eq('MGec8130512b5dd462cfe03095ec1111ed')
        end

        context 'with a phone number' do # rubocop:disable RSpec/NestedGroups
          let(:params) do
            {
              twilio_channel: {
                account_sid: 'sid',
                auth_token: 'token',
                phone_number: '+1234567890',
                messaging_service_sid: '',
                name: 'SMS Channel',
                medium: 'sms'
              }
            }
          end

          it 'creates inbox with empty messaging service sid and returns inbox object' do
            allow(twilio_client).to receive(:messages).and_return(message_double)
            allow(message_double).to receive(:list).and_return([])

            post api_v1_account_channels_twilio_channel_path(account),
                 params: params,
                 headers: admin.create_new_auth_token

            expect(response).to have_http_status(:success)
            json_response = JSON.parse(response.body)

            expect(json_response['name']).to eq('SMS Channel')
            expect(json_response['phone_number']).to eq('+1234567890')
          end

          it 'creates one more inbox with empty messaging service sid' do
            params = {
              twilio_channel: {
                account_sid: 'sid-1',
                auth_token: 'token-1',
                phone_number: '+1224466880',
                messaging_service_sid: '',
                name: 'SMS Channel',
                medium: 'whatsapp'
              }
            }
            allow(twilio_client).to receive(:messages).and_return(message_double)
            allow(message_double).to receive(:list).and_return([])

            post api_v1_account_channels_twilio_channel_path(account),
                 params: params,
                 headers: admin.create_new_auth_token

            expect(response).to have_http_status(:success)
            json_response = JSON.parse(response.body)

            expect(json_response['phone_number']).to eq('whatsapp:+1224466880')
          end
        end

        it 'return error if Twilio tokens are incorrect' do
          allow(twilio_client).to receive(:messages).and_return(message_double)
          allow(message_double).to receive(:list).and_raise(Twilio::REST::TwilioError)

          post api_v1_account_channels_twilio_channel_path(account),
               params: params,
               headers: admin.create_new_auth_token

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with user as agent' do
        it 'returns unauthorized' do
          post api_v1_account_channels_twilio_channel_path(account),
               params: params,
               headers: agent.create_new_auth_token

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
