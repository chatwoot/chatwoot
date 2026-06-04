require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/group_metadata', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us', name: 'Old Name') }
  let(:conversation) { create(:conversation, account: account, contact: group_contact, inbox: inbox, group_type: :group) }
  let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }

  before do
    conversation
    allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
    allow(baileys_service).to receive(:update_group_subject).and_return(true)
    allow(baileys_service).to receive(:update_group_description).and_return(true)
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/:id/group_metadata' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'updates the group subject and contact name' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'New Group Name' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(group_contact.reload.name).to eq('New Group Name')
        expect(baileys_service).to have_received(:update_group_subject).with('group@g.us', 'New Group Name')
      end

      it 'updates the group description' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { description: 'A new description' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(group_contact.reload.additional_attributes['description']).to eq('A new description')
        expect(baileys_service).to have_received(:update_group_description).with('group@g.us', 'A new description')
      end

      it 'updates both subject and description' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'Updated Name', description: 'Updated Desc' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(group_contact.reload.name).to eq('Updated Name')
        expect(group_contact.additional_attributes['description']).to eq('Updated Desc')
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:update_group_subject)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'New Name' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Offline')
      end
    end
  end
end
