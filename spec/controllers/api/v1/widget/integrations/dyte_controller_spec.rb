require 'rails_helper'

RSpec.describe '/api/v1/widget/integrations/dyte', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }
  let(:message) { create(:message, conversation: conversation, account: account, inbox: conversation.inbox) }
  let!(:integration_message) do
    create(:message, content_type: 'integrations',
                     content_attributes: { type: 'dyte', data: { meeting_id: 'm_id' } },
                     conversation: conversation, account: account, inbox: conversation.inbox)
  end

  before do
    create(:integrations_hook, :dyte, account: account)
  end

  describe 'POST /api/v1/widget/integrations/dyte/add_participant_to_meeting' do
    context 'when token is invalid' do
      it 'returns error' do
        post add_participant_to_meeting_api_v1_widget_integrations_dyte_url,
             params: { website_token: web_widget.website_token },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when token is valid' do
      context 'when message is not an integration message' do
        it 'returns error' do
          post add_participant_to_meeting_api_v1_widget_integrations_dyte_url,
               headers: { 'X-Auth-Token' => token },
               params: { website_token: web_widget.website_token, message_id: message.id },
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          response_body = JSON.parse(response.body)
          expect(response_body['error']).to eq('Invalid message type. Action not permitted')
        end
      end

      context 'when message is an integration message' do
        before do
          stub_request(:post, 'https://api.cluster.dyte.in/v1/organizations/org_id/meetings/m_id/participant')
            .to_return(
              status: 200,
              body: { success: true, data: { authResponse: { userAdded: true, id: 'random_uuid', auth_token: 'json-web-token' } } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'returns authResponse' do
          post add_participant_to_meeting_api_v1_widget_integrations_dyte_url,
               headers: { 'X-Auth-Token' => token },
               params: { website_token: web_widget.website_token, message_id: integration_message.id },
               as: :json

          expect(response).to have_http_status(:success)
          response_body = JSON.parse(response.body)
          expect(response_body['authResponse']).to eq(
            {
              'userAdded' => true, 'id' => 'random_uuid', 'auth_token' => 'json-web-token'
            }
          )
        end
      end
    end
  end
end
