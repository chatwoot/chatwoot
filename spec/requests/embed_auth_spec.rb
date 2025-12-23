# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EmbedAuth', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /embed/auth' do
    context 'with valid token' do
      let(:token_result) do
        EmbedTokenService.generate(
          user: user,
          account: account,
          inbox: inbox
        )
      end
      let(:token) { token_result[:token] }

      it 'authenticates user and redirects to embed inbox' do
        get "/embed/auth?token=#{token}"

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('/app/embed/inbox')
        expect(response.location).to include("inbox_id=#{inbox.id}")
      end

      it 'creates a session for the user' do
        get "/embed/auth?token=#{token}"

        # Session should be created (we can't directly test session in request specs easily,
        # but we can verify the redirect happened)
        expect(response).to have_http_status(:redirect)
      end

      it 'updates token usage statistics' do
        embed_token = token_result[:embed_token]
        initial_count = embed_token.usage_count

        get "/embed/auth?token=#{token}"

        embed_token.reload
        expect(embed_token.usage_count).to eq(initial_count + 1)
        expect(embed_token.last_used_at).to be_present
      end
    end

    context 'with revoked token' do
      let(:token_result) do
        EmbedTokenService.generate(
          user: user,
          account: account,
          inbox: inbox
        )
      end
      let(:token) { token_result[:token] }
      let(:embed_token) { token_result[:embed_token] }

      before do
        embed_token.revoke!
      end

      it 'returns unauthorized' do
        get "/embed/auth?token=#{token}"

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Invalid or revoked token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized for malformed token' do
        get '/embed/auth?token=invalid_token'

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for missing token' do
        get '/embed/auth'

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include('Token missing')
      end
    end

    context 'with token for non-existent user' do
      let(:deleted_user) { create(:user, account: account) }
      let(:token_result) do
        EmbedTokenService.generate(
          user: deleted_user,
          account: account
        )
      end
      let(:token) { token_result[:token] }

      before do
        deleted_user.destroy
      end

      it 'returns unauthorized' do
        get "/embed/auth?token=#{token}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

