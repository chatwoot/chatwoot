# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile Inbox Signatures API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
  end

  describe 'GET /api/v1/profile/inbox_signatures' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/profile/inbox_signatures'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all inbox signatures for the current account' do
        inbox_signature = create(:inbox_signature, user: agent, inbox: inbox)

        get '/api/v1/profile/inbox_signatures',
            params: { account_id: account.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(1)
        expect(json_response[0]['inbox_id']).to eq(inbox.id)
        expect(json_response[0]['message_signature']).to eq(inbox_signature.message_signature)
      end

      it 'does not return signatures for inboxes from other accounts' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)
        create(:inbox_signature, user: agent, inbox: other_inbox)

        get '/api/v1/profile/inbox_signatures',
            params: { account_id: account.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(0)
      end

      it 'returns unauthorized when filtering by an account the user does not belong to' do
        other_account = create(:account)

        get '/api/v1/profile/inbox_signatures',
            params: { account_id: other_account.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/profile/inbox_signatures/:inbox_id' do
    context 'when the inbox signature exists' do
      it 'returns the inbox signature' do
        inbox_signature = create(:inbox_signature, user: agent, inbox: inbox)

        get "/api/v1/profile/inbox_signatures/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inbox_id']).to eq(inbox.id)
        expect(json_response['message_signature']).to eq(inbox_signature.message_signature)
        expect(json_response['signature_position']).to eq('top')
        expect(json_response['signature_separator']).to eq('blank')
      end
    end

    context 'when the inbox signature does not exist' do
      it 'returns not found' do
        get "/api/v1/profile/inbox_signatures/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the user is not a member of the inbox' do
      let(:non_member_inbox) { create(:inbox, account: account) }

      it 'returns unauthorized' do
        get "/api/v1/profile/inbox_signatures/#{non_member_inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/profile/inbox_signatures/:inbox_id' do
    let(:signature_params) do
      {
        inbox_signature: {
          message_signature: '<p>Custom Signature</p>',
          signature_position: 'bottom',
          signature_separator: '--'
        }
      }
    end

    context 'when the inbox signature does not exist' do
      it 'creates a new inbox signature' do
        expect do
          put "/api/v1/profile/inbox_signatures/#{inbox.id}",
              params: signature_params,
              headers: agent.create_new_auth_token,
              as: :json
        end.to change(InboxSignature, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inbox_id']).to eq(inbox.id)
        expect(json_response['message_signature']).to eq('<p>Custom Signature</p>')
        expect(json_response['signature_position']).to eq('bottom')
        expect(json_response['signature_separator']).to eq('--')
      end
    end

    context 'when the inbox signature already exists' do
      it 'updates the existing inbox signature' do
        create(:inbox_signature, user: agent, inbox: inbox)

        expect do
          put "/api/v1/profile/inbox_signatures/#{inbox.id}",
              params: signature_params,
              headers: agent.create_new_auth_token,
              as: :json
        end.not_to change(InboxSignature, :count)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['message_signature']).to eq('<p>Custom Signature</p>')
        expect(json_response['signature_position']).to eq('bottom')
      end
    end

    context 'when the user is not a member of the inbox' do
      let(:non_member_inbox) { create(:inbox, account: account) }

      it 'returns unauthorized' do
        put "/api/v1/profile/inbox_signatures/#{non_member_inbox.id}",
            params: signature_params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when params are invalid' do
      let(:invalid_params) do
        {
          inbox_signature: {
            message_signature: '<p>Custom Signature</p>',
            signature_position: 'invalid'
          }
        }
      end

      it 'returns unprocessable entity and does not create a signature' do
        expect do
          put "/api/v1/profile/inbox_signatures/#{inbox.id}",
              params: invalid_params,
              headers: agent.create_new_auth_token,
              as: :json
        end.not_to change(InboxSignature, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['attributes']).to include('signature_position')
      end
    end
  end

  describe 'DELETE /api/v1/profile/inbox_signatures/:inbox_id' do
    it 'deletes the inbox signature' do
      create(:inbox_signature, user: agent, inbox: inbox)

      expect do
        delete "/api/v1/profile/inbox_signatures/#{inbox.id}",
               headers: agent.create_new_auth_token,
               as: :json
      end.to change(InboxSignature, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns no content even when signature does not exist' do
      delete "/api/v1/profile/inbox_signatures/#{inbox.id}",
             headers: agent.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:no_content)
    end

    context 'when the user is not a member of the inbox' do
      let(:non_member_inbox) { create(:inbox, account: account) }

      it 'returns unauthorized' do
        delete "/api/v1/profile/inbox_signatures/#{non_member_inbox.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
