require 'rails_helper'

RSpec.describe 'Conversation Group Contacts API', type: :request do
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
  let(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: inbox,
      group: true,
      group_source_id: '120363040468224422@g.us',
      group_session_admin: true
    )
  end
  let(:contact) { create(:contact, account: account, phone_number: '+5566999999999', bsuid: '123456789012345@lid') }
  let(:provider_service) { instance_double(Whatsapp::Providers::UnoapiService) }
  let!(:group_contact) do
    create(
      :group_contact,
      account: account,
      conversation: conversation,
      contact: contact,
      metadata: {
        'wa_id' => '5566999999999',
        'user_id' => '123456789012345@lid'
      }
    )
  end
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/group_contacts" }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    allow(Whatsapp::Providers::UnoapiService).to receive(:new).and_return(provider_service)
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/{conversation.id}/group_contacts' do
    it 'filters group contacts by query for mention autocomplete' do
      matching_contact = create(
        :contact,
        account: account,
        name: 'Rodrigo Costa',
        whatsapp_username: 'rodrigo',
        phone_number: '+5566996269251',
        bsuid: '94047083475061@lid'
      )
      create(
        :group_contact,
        account: account,
        conversation: conversation,
        contact: matching_contact,
        metadata: {
          'wa_id' => '5566996269251',
          'user_id' => '94047083475061@lid'
        }
      )

      get path,
          params: { query: 'rod' },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      returned_names = response.parsed_body['payload'].map { |item| item.dig('contact', 'name') }
      expect(returned_names).to contain_exactly('Rodrigo Costa')
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/{conversation.id}/group_contacts' do
    it 'forwards participant objects to the provider' do
      provider_response = instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'group_id' => conversation.group_source_id, 'added' => ['5566999999999'], 'failed' => [] }
      )
      participants = [{ 'wa_id' => '5566999999999', 'user_id' => '123456789012345@lid' }]

      allow(provider_service)
        .to receive(:add_group_participants)
        .with(group_id: conversation.group_source_id, participants: participants)
        .and_return(provider_response)

      post path,
           params: { participants: participants },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['added']).to eq(['5566999999999'])
    end

    it 'does not forward the internal contact id as provider participant id' do
      provider_response = instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'group_id' => conversation.group_source_id, 'added' => ['123456789012345'], 'failed' => [] }
      )

      allow(provider_service)
        .to receive(:add_group_participants)
        .with(group_id: conversation.group_source_id, participants: [{ 'user_id' => '123456789012345@lid' }])
        .and_return(provider_response)

      post path,
           params: { participants: [{ id: contact.id, user_id: '123456789012345@lid' }] },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/{conversation.id}/group_contacts' do
    it 'removes the local group contact when the provider confirms removal' do
      provider_response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'removed' => ['5566999999999'], 'failed' => [] })

      allow(provider_service)
        .to receive(:remove_group_participants)
        .with(group_id: conversation.group_source_id, participants: ['5566999999999'])
        .and_return(provider_response)

      delete path,
             params: { participants: ['5566999999999'] },
             headers: agent.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:no_content)
      expect(conversation.group_contacts.exists?(group_contact.id)).to be(false)
    end

    it 'keeps the local group contact when the provider reports failed participants' do
      provider_response = instance_double(
        HTTParty::Response,
        success?: true,
        parsed_response: { 'removed' => [], 'failed' => ['5566999999999'], 'error' => 'participant remove failed' }
      )

      allow(provider_service)
        .to receive(:remove_group_participants)
        .with(group_id: conversation.group_source_id, participants: ['5566999999999'])
        .and_return(provider_response)

      delete path,
             params: { participants: ['5566999999999'] },
             headers: agent.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('participant remove failed')
      expect(conversation.group_contacts.exists?(group_contact.id)).to be(true)
    end
  end
end
