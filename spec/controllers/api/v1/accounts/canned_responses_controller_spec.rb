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

      it 'returns manageable canned responses for the agent' do
        get "/api/v1/accounts/#{account.id}/canned_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.map { |row| row['id'] }).to match_array(
          account.canned_responses.approved.global.pluck(:id)
        )
      end

      it 'returns only usable responses when usable=true' do
        pending = create(
          :canned_response,
          account: account,
          visibility: :personal,
          approval_status: :pending,
          created_by: agent,
          short_code: 'pending-one'
        )

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: { usable: true },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        ids = response.parsed_body.map { |row| row['id'] }
        expect(ids).not_to include(pending.id)
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
        expect(response.parsed_body.map { |row| row['id'] }).to eq([cr3.id, cr2.id, cr1.id])
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

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates a pending personal canned response' do
        params = { short_code: 'short', content: 'content', visibility: 'global' }

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        created = account.canned_responses.find_by(short_code: 'short')
        expect(created.visibility).to eq('personal')
        expect(created.approval_status).to eq('pending')
        expect(created.created_by_id).to eq(agent.id)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'creates an approved canned response' do
        params = { short_code: 'admin-short', content: 'content', visibility: 'global' }

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        created = account.canned_responses.find_by(short_code: 'admin-short')
        expect(created.approval_status).to eq('approved')
        expect(created.visibility).to eq('global')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/canned_responses/:id/approve' do
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:pending_response) do
      create(
        :canned_response,
        account: account,
        visibility: :personal,
        approval_status: :pending,
        created_by: agent,
        short_code: 'needs-approval'
      )
    end

    it 'allows administrator to approve for account' do
      post "/api/v1/accounts/#{account.id}/canned_responses/#{pending_response.id}/approve",
           params: { visibility: 'global' },
           headers: administrator.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(pending_response.reload.approval_status).to eq('approved')
      expect(pending_response.visibility).to eq('global')
      expect(pending_response.reviewed_by_id).to eq(administrator.id)
    end

    it 'does not allow agents to approve' do
      post "/api/v1/accounts/#{account.id}/canned_responses/#{pending_response.id}/approve",
           params: { visibility: 'personal' },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
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
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'updates an existing canned response' do
        params = { short_code: 'B' }

        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(canned_response.reload.short_code).to eq('B')
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
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'destroys the canned response' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(CannedResponse.count).to eq(0)
      end
    end
  end
end
