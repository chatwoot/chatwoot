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

      # An emptied field used to be indistinguishable from an absent one: `present?` skipped
      # the update, the response came back 200 with the old text intact, and the operator
      # was told the save worked. Neither provider can remove a description (measured on
      # 10/09/2026), so the honest answer is to say no rather than to report a success that
      # did not happen.
      it 'refuses to clear a description instead of reporting a save that did not happen' do
        group_contact.update!(additional_attributes: group_contact.additional_attributes.merge('description' => 'antes'))

        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { description: '' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/description/i)
        expect(group_contact.reload.additional_attributes['description']).to eq('antes')
        expect(baileys_service).not_to have_received(:update_group_description)
      end

      # A request that never mentions the description is not asking for anything, and has
      # to keep working: the subject panel saves on its own.
      it 'still updates the subject when the description was not part of the request' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'Só o nome' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(group_contact.reload.name).to eq('Só o nome')
      end

      it 'updates both subject and description' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'Updated Name', description: 'Updated Desc' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(group_contact.reload.name).to eq('Updated Name')
        expect(group_contact.additional_attributes['description']).to eq('Updated Desc')
      end

      # Turning groups off strips the capability and hides the panel, but this endpoint
      # stays routable, and the refusal it now raises has to render as the same JSON
      # error the rest of the group API returns rather than as a 500.
      it 'returns 422 when the provider cannot do what was asked' do
        allow(baileys_service).to receive(:update_group_subject)
          .and_raise(Whatsapp::Session::Errors::NotSupported, 'groups are disabled on this installation')

        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_metadata",
              params: { subject: 'New Name' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('groups are disabled')
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
