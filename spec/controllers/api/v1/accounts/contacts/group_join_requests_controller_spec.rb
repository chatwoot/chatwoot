require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/group_join_requests', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us') }
  let(:conversation) { create(:conversation, account: account, contact: group_contact, inbox: inbox, group_type: :group) }
  let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }
  let(:join_requests) { [{ 'jid' => '551199999@s.whatsapp.net', 'name' => 'Alice' }] }

  before do
    conversation
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
    allow(baileys_service).to receive(:group_join_requests).and_return(join_requests)
    allow(baileys_service).to receive(:handle_group_join_requests).and_return(true)
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/group_join_requests' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_join_requests"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'returns list of join requests' do
        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_join_requests",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['payload']).to eq(join_requests)
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:group_join_requests)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_join_requests",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Offline')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/:id/group_join_requests/handle' do
    context 'when user is logged in' do
      it 'approves join requests and returns ok' do
        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_join_requests/handle",
             params: { participants: ['551199999@s.whatsapp.net'], request_action: 'approve' },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(baileys_service).to have_received(:handle_group_join_requests)
          .with('group@g.us', ['551199999@s.whatsapp.net'], 'approve')
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:handle_group_join_requests)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_join_requests/handle",
             params: { participants: ['551199999@s.whatsapp.net'], request_action: 'approve' },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
