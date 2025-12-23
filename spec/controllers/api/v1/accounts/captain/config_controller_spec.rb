require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::Config', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/captain/config' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/captain/config",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns available AI model options for each feature' do
        get "/api/v1/accounts/#{account.id}/captain/config",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        %w[editor assistant copilot label_suggestion].each do |feature|
          expect(json_response.dig(:features, feature.to_sym, :models)).to be_present
          expect(json_response.dig(:features, feature.to_sym, :default)).to be_present
        end
      end
    end

    context 'when it is an admin' do
      it 'returns providers, models, and features configuration' do
        get "/api/v1/accounts/#{account.id}/captain/config",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(json_response).to have_key(:providers)
        expect(json_response).to have_key(:models)
        expect(json_response).to have_key(:features)
      end
    end
  end
end
