# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Callbacks API', type: :request do
  describe 'POST /api/v1/accounts/{account.id}/callbacks/register_facebook_page' do
    let(:account) { create(:account, limits: { inboxes: 1 }) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:params) do
      {
        user_access_token: 'user-token',
        page_access_token: 'page-token',
        page_id: '12345',
        inbox_name: 'Facebook Inbox'
      }
    end

    before do
      create(:inbox, account: account)
    end

    it 'returns payment required before creating a Facebook channel when account inbox limit is reached' do
      expect do
        post "/api/v1/accounts/#{account.id}/callbacks/register_facebook_page",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json
      end.not_to change(Channel::FacebookPage, :count)

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error']).to eq('Account limit exceeded. Upgrade to a higher plan')
    end
  end
end
