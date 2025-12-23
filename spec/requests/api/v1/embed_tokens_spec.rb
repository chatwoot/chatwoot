# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::EmbedTokens', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/:account_id/embed_tokens' do
    context 'when authenticated as administrator' do
      before do
        sign_in(administrator)
      end

      it 'creates an embed token successfully' do
        post "/api/v1/accounts/#{account.id}/embed_tokens",
             params: {
               user_id: user.id,
               inbox_id: inbox.id,
               note: 'Test embed token'
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['embed_token']).to be_present
        expect(json_response['embed_url']).to be_present
        expect(json_response['embed_url']).to include('/embed/auth?token=')
      end

      it 'creates an embed token without inbox_id' do
        post "/api/v1/accounts/#{account.id}/embed_tokens",
             params: {
               user_id: user.id,
               note: 'Test embed token without inbox'
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['embed_token']).to be_present
        expect(json_response['embed_token']['inbox_id']).to be_nil
      end

      it 'returns error when user_id is missing' do
        post "/api/v1/accounts/#{account.id}/embed_tokens",
             params: {
               inbox_id: inbox.id
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authenticated as agent' do
      before do
        sign_in(agent)
      end

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/embed_tokens",
             params: {
               user_id: user.id
             },
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/embed_tokens/:id/revoke' do
    let(:embed_token) do
      result = EmbedTokenService.generate(
        user: user,
        account: account,
        inbox: inbox,
        created_by: administrator
      )
      result[:embed_token]
    end

    context 'when authenticated as administrator' do
      before do
        sign_in(administrator)
      end

      it 'revokes the embed token successfully' do
        post "/api/v1/accounts/#{account.id}/embed_tokens/#{embed_token.id}/revoke",
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(embed_token.reload.revoked?).to be true
      end
    end

    context 'when authenticated as agent' do
      before do
        sign_in(agent)
      end

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/embed_tokens/#{embed_token.id}/revoke",
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

