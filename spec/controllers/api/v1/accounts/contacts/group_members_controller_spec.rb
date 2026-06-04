require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/group_members', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/group_members' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'returns active group members' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:group_member, group_contact: contact, contact: contact)
        create(:group_member, group_contact: contact, contact: create(:contact, account: account))

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq 2
      end

      it 'does not return inactive group members' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:group_member, group_contact: contact, contact: contact)
        create(:group_member, :inactive, group_contact: contact, contact: create(:contact, account: account))

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq 1
      end

      it 'does not return group members from another account' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:group_member, group_contact: contact, contact: contact)
        other_account = create(:account)
        other_group_contact = create(:contact, account: other_account, group_type: :group, identifier: 'other@g.us')
        create(:group_member, group_contact: other_group_contact, contact: create(:contact, account: other_account))

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq 1
      end

      it 'returns expected attributes in the response' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:group_member, group_contact: contact, contact: contact)

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        member = response.parsed_body['payload'].first
        source_member = GroupMember.find(member['id'])
        expect(member['id']).to eq(source_member.id)
        expect(member['role']).to eq(source_member.role)
        expect(member['is_active']).to eq(source_member.is_active)
        expect(member['group_contact_id']).to eq(contact.id)
        expect(member['contact']['id']).to eq(source_member.contact.id)
      end

      it 'returns empty payload when contact is not a group' do
        contact = create(:contact, account: account, group_type: :individual)

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to be_empty
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/:id/group_members' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
    end
    let(:inbox) { whatsapp_channel.inbox }
    let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us') }
    let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }

    before do
      create(:contact_inbox, inbox: inbox, contact: group_contact)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
      allow(baileys_service).to receive(:update_group_participants).and_return(true)
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'adds members and returns ok' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(ContactInboxWithContactBuilder).to receive(:new).and_call_original

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990001'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:update_group_participants)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990001'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Offline')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/contacts/:id/group_members/:id' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
    end
    let(:inbox) { whatsapp_channel.inbox }
    let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us') }
    let(:member_contact) { create(:contact, account: account, phone_number: '+5511999990002') }
    let!(:member) { create(:group_member, group_contact: group_contact, contact: member_contact) }
    let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }

    before do
      create(:contact_inbox, inbox: inbox, contact: group_contact)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
      allow(baileys_service).to receive(:update_group_participants).and_return(true)
    end

    context 'when user is logged in' do
      it 'deactivates the member and returns ok' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
               headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(member.reload.is_active).to be false
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:update_group_participants)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        delete "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
               headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/:id/group_members/:member_id' do
    let(:whatsapp_channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
    end
    let(:inbox) { whatsapp_channel.inbox }
    let(:group_contact) { create(:contact, account: account, group_type: :group, identifier: 'group@g.us') }
    let(:member_contact) { create(:contact, account: account, phone_number: '+5511999990003') }
    let!(:member) { create(:group_member, group_contact: group_contact, contact: member_contact, role: :member) }
    let(:baileys_service) { instance_double(Whatsapp::Providers::WhatsappBaileysService) }

    before do
      create(:contact_inbox, inbox: inbox, contact: group_contact)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(baileys_service)
      allow(baileys_service).to receive(:update_group_participants).and_return(true)
    end

    context 'when user is logged in' do
      it 'promotes member to admin' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
              params: { role: 'admin' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(member.reload.role).to eq('admin')
      end

      it 'demotes admin to member' do
        member.update!(role: :admin)
        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
              params: { role: 'member' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(member.reload.role).to eq('member')
      end

      it 'returns 422 when provider is unavailable' do
        allow(baileys_service).to receive(:update_group_participants)
          .and_raise(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Offline')

        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
              params: { role: 'admin' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
