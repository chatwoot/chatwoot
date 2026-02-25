require 'rails_helper'

RSpec.describe 'Profile API', type: :request do
  describe 'GET /api/v1/profile' do
    let(:account) { create(:account) }
    let!(:custom_role_account) { create(:account, name: 'Custom Role Account') }
    let!(:custom_role) { create(:custom_role, name: 'Custom Role', account: custom_role_account) }
    let!(:agent) { create(:user, account: account, custom_attributes: { test: 'test' }, role: :agent) }

    before do
      create(:account_user, account: custom_role_account, user: agent, custom_role: custom_role)
    end

    context 'when it is an authenticated user' do
      it 'returns user custom role information' do
        get '/api/v1/profile',
            headers: agent.create_new_auth_token,
            as: :json

        parsed_response = response.parsed_body
        # map accounts object and make sure custom role id and name are present
        role_account = parsed_response['accounts'].find { |account| account['id'] == custom_role_account.id }
        expect(role_account['custom_role']['id']).to eq(custom_role.id)
        expect(role_account['custom_role']['name']).to eq(custom_role.name)
      end
    end
  end
end
