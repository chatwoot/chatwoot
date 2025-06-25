require 'rails_helper'

RSpec.describe 'Dyte Integration API', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, conversation: conversation, account: account, inbox: conversation.inbox) }
  let(:integration_message) do
    create(:message, content_type: 'integrations',
                     content_attributes: { type: 'dyte', data: { meeting_id: 'm_id' } },
                     conversation: conversation, account: account, inbox: conversation.inbox)
  end
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:unauthorized_agent) { create(:user, account: account, role: :agent) }

  before do
    create(:integrations_hook, :dyte, account: account)
    create(:inbox_member, user: agent, inbox: conversation.inbox)
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/dyte/create_a_meeting' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post create_a_meeting_api_v1_account_integrations_dyte_url(account)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the agent does not have access to the inbox' do
      it 'returns unauthorized' do
        post create_a_meeting_api_v1_account_integrations_dyte_url(account),
             params: { conversation_id: conversation.display_id },
             headers: unauthorized_agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent with inbox access and the Dyte API is a success' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meeting')
          .to_return(
            status: 200,
            body: { success: true, data: { meeting: { id: 'meeting_id', roomName: 'room_name' } } }.to_json,
            headers: headers
          )
      end

      it 'returns valid message payload' do
        post create_a_meeting_api_v1_account_integrations_dyte_url(account),
             params: { conversation_id: conversation.display_id },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        last_message = conversation.reload.messages.last
        expect(conversation.display_id).to eq(response_body['conversation_id'])
        expect(last_message.id).to eq(response_body['id'])
      end
    end

    context 'when it is an agent with inbox access and the Dyte API is errored' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meeting')
          .to_return(
            status: 422,
            body: { success: false, data: { message: 'Title is required' } }.to_json,
            headers: headers
          )
      end

      it 'returns error payload' do
        post create_a_meeting_api_v1_account_integrations_dyte_url(account),
             params: { conversation_id: conversation.display_id },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = response.parsed_body
        expect(response_body['error']).to eq({ 'data' => { 'message' => 'Title is required' }, 'success' => false })
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/dyte/add_participant_to_meeting' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post add_participant_to_meeting_api_v1_account_integrations_dyte_url(account)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the agent does not have access to the inbox' do
      it 'returns unauthorized' do
        post add_participant_to_meeting_api_v1_account_integrations_dyte_url(account),
             params: { message_id: message.id },
             headers: unauthorized_agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent with inbox access and message_type is not integrations' do
      it 'returns error' do
        post add_participant_to_meeting_api_v1_account_integrations_dyte_url(account),
             params: { message_id: message.id },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when it is an agent with inbox access and message_type is integrations' do
      before do
        stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meetings/m_id/participant')
          .to_return(
            status: 200,
            body: { success: true, data: { authResponse: { userAdded: true, id: 'random_uuid', auth_token: 'json-web-token' } } }.to_json,
            headers: headers
          )
      end

      it 'returns authResponse' do
        post add_participant_to_meeting_api_v1_account_integrations_dyte_url(account),
             params: { message_id: integration_message.id },
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['authResponse']).to eq(
          {
            'userAdded' => true, 'id' => 'random_uuid', 'auth_token' => 'json-web-token'
          }
        )
      end
    end
  end
end
