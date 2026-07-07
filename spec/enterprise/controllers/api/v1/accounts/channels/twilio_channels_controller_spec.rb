# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enterprise Twilio Channel API', type: :request do
  describe 'POST /api/v1/accounts/{account.id}/channels/twilio_channel' do
    let(:account) { create(:account, limits: { inboxes: 1 }) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:params) do
      {
        twilio_channel: {
          account_sid: 'sid',
          auth_token: 'token',
          phone_number: '',
          messaging_service_sid: 'MGec8130512b5dd462cfe03095ec1342ed',
          name: 'SMS Channel',
          medium: 'sms'
        }
      }
    end

    before do
      create(:inbox, account: account)
    end

    it 'returns payment required before authenticating with Twilio when account inbox limit is reached' do
      expect(Twilio::REST::Client).not_to receive(:new)

      post api_v1_account_channels_twilio_channel_path(account),
           params: params,
           headers: admin.create_new_auth_token

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error']).to eq('Account limit exceeded. Upgrade to a higher plan')
    end
  end
end
