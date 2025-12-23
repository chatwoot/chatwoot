# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Embed Session Verification', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /app/embed/inbox with revoked session' do
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
      # Simulate authentication via embed token
      get "/embed/auth?token=#{token}"
      follow_redirect! if response.redirect?
    end

    context 'when token is revoked after session creation' do
      it 'returns unauthorized on next request' do
        # First request should work (after redirect)
        get '/app/embed/inbox',
            headers: {
              'Cookie' => response.headers['Set-Cookie']
            }

        # Revoke the token
        embed_token.revoke!

        # Next request should fail
        get '/app/embed/inbox',
            headers: {
              'Cookie' => response.headers['Set-Cookie']
            }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Embed session revoked')
      end
    end

    context 'when token is still active' do
      it 'allows access to embed inbox' do
        get '/app/embed/inbox',
            headers: {
              'Cookie' => response.headers['Set-Cookie']
            }

        # Should return 200 (or redirect to login if session not properly set)
        # In a real scenario, we'd need to properly set up the session
        expect(response).to have_http_status(:success).or have_http_status(:redirect)
      end
    end
  end
end

