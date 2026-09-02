require 'rails_helper'

RSpec.describe '/api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:blob_params) do
    {
      blob: {
        filename: 'avatar.png',
        byte_size: '1234',
        checksum: 'dsjbsdhbfif3874823mnsdbf',
        content_type: 'image/png'
      }
    }
  end

  def create_direct_upload(headers)
    post api_v1_account_conversation_direct_uploads_path(account_id: account.id, conversation_id: conversation.display_id),
         params: blob_params,
         headers: headers,
         as: :json
  end

  describe 'POST /api/v1/accounts/:account_id/conversations/:conversation_id/direct_uploads' do
    context 'when it is an unauthenticated request' do
      it 'returns unauthorized without any credentials' do
        create_direct_upload({})

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized with an empty api_access_token header' do
        create_direct_upload({ api_access_token: '' })

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized with an invalid api_access_token header' do
        create_direct_upload({ api_access_token: 'invalid-token' })

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated request with an api access token' do
      it 'creates the blob for the direct upload' do
        create_direct_upload({ api_access_token: agent.access_token.token })

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end

      it 'returns unauthorized for an agent of another account' do
        other_agent = create(:user, account: create(:account), role: :agent)

        create_direct_upload({ api_access_token: other_agent.access_token.token })

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for an agent bot token' do
        agent_bot = create(:agent_bot, account: account)

        create_direct_upload({ api_access_token: agent_bot.access_token.token })

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the account api_and_webhooks feature is disabled' do
      before do
        allow(Account).to receive(:find).and_call_original
        allow(Account).to receive(:find).with(account.id.to_s).and_return(account)
        allow(account).to receive(:api_and_webhooks_enabled?).and_return(false)
      end

      it 'returns forbidden for a token-authenticated request' do
        create_direct_upload({ api_access_token: agent.access_token.token })

        expect(response).to have_http_status(:forbidden)
      end

      it 'still creates the blob for a session-authenticated request' do
        create_direct_upload(agent.create_new_auth_token)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end
    end

    context 'when it is an authenticated session request' do
      it 'creates the blob for the direct upload' do
        create_direct_upload(agent.create_new_auth_token)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end

      it 'creates the blob when the serialized api access token is empty' do
        create_direct_upload(agent.create_new_auth_token.merge('api_access_token' => ''))

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end
    end

    context 'when forgery protection is enabled' do
      around do |example|
        original = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true
        example.run
        ActionController::Base.allow_forgery_protection = original
      end

      it 'creates the blob for a token-authenticated request without a CSRF token' do
        create_direct_upload({ api_access_token: agent.access_token.token })

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['content_type']).to eq('image/png')
      end
    end
  end
end
