require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/group_invite', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us') }
  let(:conversation) { create(:conversation, account: account, contact: group_contact, inbox: inbox, group_type: :group) }
  let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }

  before do
    conversation
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
    allow(baileys_service).to receive(:group_invite_code).and_return('ABCXYZ')
    allow(baileys_service).to receive(:revoke_group_invite).and_return('NEWCODE')
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/group_invite' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_invite"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'returns invite code and url' do
        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_invite",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['invite_code']).to eq('ABCXYZ')
        expect(response.parsed_body['invite_url']).to eq('https://chat.whatsapp.com/ABCXYZ')
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:group_invite_code)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_invite",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Offline')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/:id/group_invite/revoke' do
    context 'when user is logged in' do
      it 'revokes and returns new invite code and url' do
        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_invite/revoke",
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['invite_code']).to eq('NEWCODE')
        expect(response.parsed_body['invite_url']).to eq('https://chat.whatsapp.com/NEWCODE')
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:revoke_group_invite)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_invite/revoke",
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
