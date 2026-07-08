# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise WhatsApp Authorization API', type: :request do
  describe 'POST /api/v1/accounts/{account.id}/whatsapp/authorization' do
    let(:account) { create(:account, limits: { inboxes: 1 }) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:params) { { code: 'test_code', business_id: 'test_business_id', waba_id: 'test_waba_id' } }

    before do
      create(:inbox, account: account)
    end

    it 'returns payment required before exchanging the Meta code when account inbox limit is reached' do
      expect(Whatsapp::TokenExchangeService).not_to receive(:new)

      post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
           headers: admin.create_new_auth_token,
           params: params,
           as: :json

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error']).to eq('Account limit exceeded. Upgrade to a higher plan')
    end
  end
end
