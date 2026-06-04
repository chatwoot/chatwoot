require 'rails_helper'

RSpec.describe 'Conversation Groups API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:whatsapp_channel) do
    create(
      :channel_whatsapp,
      account: account,
      phone_number: "+1555#{SecureRandom.random_number(1_000_000_000).to_s.rjust(9, '0')}",
      provider: 'unoapi',
      sync_templates: false,
      validate_provider_config: false
    )
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:provider_service) { instance_double(Whatsapp::Providers::UnoapiService) }
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/groups" }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Whatsapp::Providers::UnoapiService).to receive(:new).and_return(provider_service)
  end

  it 'creates a provider group and local group conversation' do
    participants = [{ wa_id: '5566999999999', user_id: '123456789012345@lid' }]
    provider_response = instance_double(
      HTTParty::Response,
      success?: true,
      parsed_response: {
        'id' => '120363040468224422@g.us',
        'subject' => 'Equipe Comercial',
        'description' => 'Canal comercial',
        'picture' => 'https://cdn.example.com/group.jpg',
        'invite_link' => 'https://chat.whatsapp.com/example',
        'participants' => [{ 'wa_id' => '5566999999999', 'user_id' => '123456789012345@lid', 'status' => 'invited' }]
      }
    )

    allow(provider_service)
      .to receive(:create_group)
      .with(subject: 'Equipe Comercial', description: 'Canal comercial', participants: participants, join_approval_mode: 'on')
      .and_return(provider_response)

    post path,
         params: {
           inbox_id: inbox.id,
           subject: 'Equipe Comercial',
           description: 'Canal comercial',
           join_approval_mode: 'on',
           participants: participants
         },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:ok)
    conversation = inbox.conversations.find_by!(group_source_id: '120363040468224422@g.us')
    expect(conversation).to be_group
    expect(conversation.group_title).to eq('Equipe Comercial')
    expect(conversation.group_description).to eq('Canal comercial')
    expect(conversation.group_invite_link).to eq('https://chat.whatsapp.com/example')
    expect(conversation.additional_attributes['group_picture']).to eq('https://cdn.example.com/group.jpg')
    expect(conversation.contact.email).to eq('120363040468224422@g.us')
  end

  it 'does not forward internal contact ids or lid values as wa_id to the provider' do
    provider_response = instance_double(
      HTTParty::Response,
      success?: true,
      parsed_response: {
        'id' => '120363040468224422@g.us',
        'subject' => 'Equipe Comercial',
        'participants' => [{ 'user_id' => '123456789012345@lid', 'status' => 'invited' }]
      }
    )

    allow(provider_service)
      .to receive(:create_group)
      .with(subject: 'Equipe Comercial', description: nil, participants: [{ user_id: '123456789012345@lid' }], join_approval_mode: nil)
      .and_return(provider_response)

    post path,
         params: {
           inbox_id: inbox.id,
           subject: 'Equipe Comercial',
           participants: [{ wa_id: '123456789012345@lid' }]
         },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:ok)
  end

  it 'allows a non-admin group member to fetch the invite link' do
    group_contact = create(:contact, account: account, email: '120363040468224422@g.us')
    group_contact_inbox = create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363040468224422@g.us')
    conversation = create(
      :conversation,
      account: account,
      inbox: inbox,
      contact: group_contact,
      contact_inbox: group_contact_inbox,
      group: true,
      group_source_id: '120363040468224422@g.us',
      group_session_admin: false
    )
    provider_response = instance_double(
      HTTParty::Response,
      success?: true,
      parsed_response: { 'inviteLink' => 'https://chat.whatsapp.com/example' }
    )

    allow(provider_service)
      .to receive(:group_invite_link)
      .with('120363040468224422@g.us')
      .and_return(provider_response)

    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/group/invite_link",
        headers: agent.create_new_auth_token,
        as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['invite_link']).to eq('https://chat.whatsapp.com/example')
    expect(conversation.reload.group_invite_link).to eq('https://chat.whatsapp.com/example')
  end
end
