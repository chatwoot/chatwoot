require 'rails_helper'

RSpec.describe 'Webhooks::SmsController', type: :request do
  describe 'POST /webhooks/sms/{:phone_number}' do
    let(:channel) { create(:channel_sms, phone_number: '+15550001111') }
    let(:event) { { type: 'message-received', to: channel.phone_number, message: { id: 'msg-1', from: '+15559990000', text: 'hello' } } }
    let(:credentials) { { 'HTTP_AUTHORIZATION' => basic_auth(Channel::Sms::CALLBACK_USERNAME, channel.secret) } }

    def basic_auth(username, password)
      ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    end

    def post_event(path_number, payload, headers = {})
      post "/webhooks/sms/#{path_number}", params: [payload].to_json, headers: headers.merge('CONTENT_TYPE' => 'application/json')
    end

    context 'when callback authentication is enforced' do
      it 'challenges requests without credentials' do
        expect { post_event('15550001111', event) }.not_to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to start_with('Basic')
      end

      it 'rejects requests with invalid credentials' do
        headers = { 'HTTP_AUTHORIZATION' => basic_auth(Channel::Sms::CALLBACK_USERNAME, 'wrong') }
        expect { post_event('15550001111', event, headers) }.not_to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:unauthorized)
      end

      it 'enqueues the event with valid credentials' do
        expect { post_event('15550001111', event, credentials) }
          .to have_enqueued_job(Webhooks::SmsEventsJob).with(hash_including('to' => channel.phone_number))
        expect(response).to have_http_status(:success)
      end
    end

    context 'when callback authentication is not enforced' do
      before { channel.update!(callback_auth_enforced: false) }

      it 'enqueues the event without credentials' do
        expect { post_event('15550001111', event) }.to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:success)
      end

      it 'challenges events for an enforced inbox routed through it' do
        sibling = create(:channel_sms, account: channel.account)
        expect { post_event('15550001111', event.merge(to: sibling.phone_number)) }.not_to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the event number does not match the route' do
      it 'accepts an inbox from the same account authenticated with the routed inbox credentials' do
        sibling = create(:channel_sms, account: channel.account)
        expect { post_event('15550001111', event.merge(to: sibling.phone_number), credentials) }
          .to have_enqueued_job(Webhooks::SmsEventsJob).with(hash_including('to' => sibling.phone_number))
      end

      it 'drops events for an inbox in another account' do
        other = create(:channel_sms, callback_auth_enforced: false)
        expect { post_event('15550001111', event.merge(to: other.phone_number), credentials) }.not_to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:success)
      end

      it 'drops events for an unknown number' do
        expect { post_event('15550001111', event.merge(to: '+15550002222'), credentials) }.not_to have_enqueued_job(Webhooks::SmsEventsJob)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
