require 'rails_helper'

RSpec.describe 'Facebook Indicators API', type: :request do
  let(:account) { create(:account) }
  let(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: facebook_channel) }
  let(:contact) { create(:contact, account: account) }
  let(:valid_params) { { contact_id: contact.id, inbox_id: inbox.id } }

  before do
    allow(Facebook::Messenger::Bot).to receive(:deliver).and_return(true)
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
  end

  describe 'POST /api/v1/accounts/{account.id}/facebook_indicators/mark_seen' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/facebook_indicators/mark_seen"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'marks a payload as seen' do
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(
          { recipient: { id: contact_inbox.source_id }, sender_action: 'mark_seen' },
          access_token: inbox.channel.page_access_token
        )

        post "/api/v1/accounts/#{account.id}/facebook_indicators/mark_seen",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'rescues an error' do
        create(:contact_inbox, contact: contact, inbox: inbox)

        allow(Facebook::Messenger::Bot).to receive(:deliver).and_raise(Facebook::Messenger::Error)

        post "/api/v1/accounts/#{account.id}/facebook_indicators/mark_seen",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/facebook_indicators/typing_on' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_on"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'marks a payload as typing_on' do
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(
          { recipient: { id: contact_inbox.source_id }, sender_action: 'typing_on' },
          access_token: inbox.channel.page_access_token
        )

        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_on",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'rescues an error' do
        create(:contact_inbox, contact: contact, inbox: inbox)

        allow(Facebook::Messenger::Bot).to receive(:deliver).and_raise(Facebook::Messenger::Error)

        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_on",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/facebook_indicators/typing_off' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_off"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'marks a payload as typing_off' do
        contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)

        expect(Facebook::Messenger::Bot).to receive(:deliver).with(
          { recipient: { id: contact_inbox.source_id }, sender_action: 'typing_off' },
          access_token: inbox.channel.page_access_token
        )

        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_off",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'rescues an error' do
        create(:contact_inbox, contact: contact, inbox: inbox)

        allow(Facebook::Messenger::Bot).to receive(:deliver).and_raise(Facebook::Messenger::Error)

        post "/api/v1/accounts/#{account.id}/facebook_indicators/typing_off",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
