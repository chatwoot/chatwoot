require 'rails_helper'

RSpec.describe 'Canned Responses API', type: :request do
  let(:account) { create(:account) }

  before do
    create(:canned_response, account: account, content: 'Hey {{ contact.name }}, Thanks for reaching out', short_code: 'name-short-code')
  end

  describe 'GET /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the canned responses' do
        get "/api/v1/accounts/#{account.id}/canned_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq(
          account.canned_responses.accessible_to(agent).includes(:canned_response_scopes).as_json(include: :canned_response_scopes)
        )
      end

      it 'returns all the canned responses the user searched for' do
        cr1 = account.canned_responses.first
        create(:canned_response, account: account, content: 'Great! Looking forward', short_code: 'short-code')
        cr2 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'content-with-thanks')
        cr3 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'Thanks')

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: { search: 'thanks' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq(
          [cr3, cr2, cr1].as_json(include: :canned_response_scopes)
        )
      end

      it 'ignores null bytes in the search string' do
        matching_response = create(:canned_response, account: account, content: 'Unique response', short_code: 'unique')

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: { search: "uni\0que" },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq([matching_response].as_json)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates a new canned response' do
        params = { short_code: 'short', content: 'content' }

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.canned_responses.count).to eq(2)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates an existing canned response' do
        params = { short_code: 'B' }

        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(canned_response.reload.short_code).to eq('B')
      end

      it 'leaves a private response untouched when no scope is given' do
        admin = create(:user, account: account, role: :administrator)
        private_response = create(:canned_response, account: account, visibility: :private_response, content: 'before')
        create(:canned_response_scope, canned_response: private_response, user_ids: [agent.id])

        put "/api/v1/accounts/#{account.id}/canned_responses/#{private_response.id}",
            params: { content: 'after' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(private_response.reload.content).to eq('before')
        expect(private_response.canned_response_scopes.count).to eq(1)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'destroys the canned response' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(account.canned_responses.count).to eq(0)
      end
    end
  end
end
