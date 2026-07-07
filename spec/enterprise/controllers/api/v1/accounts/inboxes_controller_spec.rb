# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Inboxes API', type: :request do
  describe 'POST /api/v1/accounts/{account.id}/inboxes' do
    let(:account) { create(:account, limits: { inboxes: 1 }) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:valid_params) { { name: 'test', channel: { type: 'web_widget', website_url: 'test.com' } } }

    before do
      create(:inbox, account: account)
    end

    it 'returns payment required without creating the channel when account inbox limit is reached' do
      expect do
        post "/api/v1/accounts/#{account.id}/inboxes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json
      end.not_to change(Channel::WebWidget, :count)

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error']).to eq('Account limit exceeded. Upgrade to a higher plan')
    end
  end
end
