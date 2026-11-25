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
      # The roster read resolves the inbox it would act as, like every other group route, so a
      # group that is in no inbox at all is refused rather than listed (#535). These examples are
      # about what the roster contains, so they get an inbox and go on measuring that.
      let(:whatsapp_channel) do
        create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false, account: account)
      end

      it 'returns active group members' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '120363041234567890')
        create(:group_member, group_contact: contact, contact: contact)
        create(:group_member, group_contact: contact, contact: create(:contact, account: account))

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq 2
      end

      # A native or Uazapi roster can name the connected account by LID alone, and such a
      # contact has no phone number at all. Matching on the phone only reported the inbox
      # as an ordinary member, which is what the reply box reads to decide whether an
      # announcement-only group accepts a reply.
      it 'recognises the connected account by its LID when the roster has no phone for it' do
        channel = create(:channel_whatsapp, provider: 'uazapi', account: account,
                                            validate_provider_config: false, sync_templates: false)
        channel.update!(provider_connection: { 'connection' => 'open', 'lid' => '900000100000000' })
        group_contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:contact_inbox, inbox: channel.inbox, contact: group_contact)
        own = create(:contact, account: account, phone_number: nil, identifier: '900000100000000@lid')
        own_member = create(:group_member, group_contact: group_contact, contact: own, role: 'admin')

        get "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
            headers: admin.create_new_auth_token

        # `own_member_id` is the half the panel needs: without it the account's own row
        # carries no "You" badge and is offered the demote and remove menu.
        expect(response.parsed_body['meta']).to include('is_inbox_admin' => true, 'own_member_id' => own_member.id)
      end

      it 'does not return inactive group members' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '120363041234567890')
        create(:group_member, group_contact: contact, contact: contact)
        create(:group_member, :inactive, group_contact: contact, contact: create(:contact, account: account))

        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/group_members",
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].length).to eq 1
      end

      it 'does not return group members from another account' do
        contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '120363041234567890')
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
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '120363041234567890')
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
        create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox, source_id: '5511999999999')

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

      # WhatsApp refuses participants one at a time -- a privacy setting, somebody who
      # left recently -- and answers `ok` with a row each. Writing all of them to the
      # roster shows the operator members who are not in the group.
      it 'adds only the participants the provider did not refuse' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990001' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '5511999990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990001', '+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990001')
      end

      # The refusal comes back written the way WhatsApp spells the line, which for a
      # Brazilian or Argentinian number is not necessarily the way the operator typed it.
      it 'matches a refusal written in the other ninth-digit form' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990001' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990001', '+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990001')
      end

      # A LID and a phone number are separate namespaces written in the same digits, so a
      # refusal naming a LID says nothing about the line that happens to read like it.
      it 'keeps a participant whose number reads like a refused lid' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'lid', 'id' => '5511999990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
      end

      # The same line can be submitted under both of its spellings, and the answer names
      # one row per participant asked: WhatsApp adds it under one and says nothing about
      # the other, which the provider reports as a refusal. A line it added is in the
      # group whatever the row for the other spelling says.
      it 'keeps a number a row added even when another row refused the same line' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990002' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
      end

      # A row that carries no verdict at all has not said the participant is in the group,
      # and it has not said they are out of it either.
      it 'adds the participant when the only row about them carries no verdict' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990002' }, 'status' => 'pending', 'code' => nil }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
      end

      # Submitted under both of its spellings, the line gets a verdict each, and the
      # roster is written from the number as submitted: writing the refused spelling too
      # would put the same person on it twice, once as somebody WhatsApp turned down.
      it 'writes only the spelling whose own row landed' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990002' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002', '+551199990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
      end

      # A provider that normalizes the number answers every row under its own spelling, so
      # a line submitted twice comes back as two rows nobody's submission spells exactly.
      # Both speak for both submissions, and a line WhatsApp added is in the group: the
      # refusal on the other attempt does not take it off the roster. That both spellings
      # are then written as two members is #498, which is about the roster reading a
      # number literally and is not what the provider said here.
      it 'keeps a line one row added when the rows are written in a spelling nobody sent' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to include('+5511999990002')
      end

      # Which is what this is. A Brazilian or Argentinian line has two spellings and one
      # owner, so WhatsApp accepting both does not make them two members: read literally
      # they resolved to two contacts and two rows, and the operator saw the group with one
      # member more than it has, where promoting or removing one row left the other
      # standing.
      it 'writes one row when a line is submitted under both of its spellings' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => { 'kind' => 'phone', 'id' => '5511999990002' }, 'status' => 'success', 'code' => nil },
           { 'address' => { 'kind' => 'phone', 'id' => '551199990002' }, 'status' => 'success', 'code' => nil }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002', '+551199990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        # The first spelling submitted, because nothing here knows which one the person's
        # own device answers under.
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
        # And the provider is still asked about both, which is the whole reason submitting
        # both spellings is worth doing: whichever one WhatsApp knows is the one that lands.
        expect(baileys_service).to have_received(:update_group_participants)
          .with('group@g.us', ['5511999990002@s.whatsapp.net', '551199990002@s.whatsapp.net'], 'add')
      end

      # A row is only readable where it names an address the way the contract does. A
      # provider that writes the participant as a bare JID has not been refused any less,
      # but it has not said whom in a shape this can act on either, and answering the
      # operator with a 500 helps nobody.
      it 'adds the participant when the refusal names no address it can read' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)
        allow(baileys_service).to receive(:update_group_participants).and_return(
          [{ 'address' => '5511999990002@s.whatsapp.net', 'status' => 'failed',
             'code' => 'group_participant_not_allowed' }]
        )

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990002')
      end

      # A provider that does not answer in rows has told us nothing to filter on, and the
      # Baileys one answers with whatever `each` returned.
      it 'adds every participant when the provider answers in no rows at all' do
        allow(baileys_service).to receive(:validate_provider_config?).and_return(true)

        post "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members",
             params: { participants: ['+5511999990001', '+5511999990002'] },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(GroupMember.active.where(group_contact: group_contact).joins(:contact).pluck(:phone_number))
          .to contain_exactly('+5511999990001', '+5511999990002')
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
      # A roster can name a participant WhatsApp only ever gave a LID for, and that contact
      # has no phone number: the request used to build `@s.whatsapp.net` and come back 422
      # with the member still a member.
      it 'promotes a member the roster only knows by LID' do
        member_contact.update!(phone_number: nil, identifier: '112233445566778@lid')

        patch "/api/v1/accounts/#{account.id}/contacts/#{group_contact.id}/group_members/#{member.id}",
              params: { role: 'admin' },
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(baileys_service).to have_received(:update_group_participants)
          .with('group@g.us', ['112233445566778@lid'], 'promote')
        expect(member.reload.role).to eq('admin')
      end

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
