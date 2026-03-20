require 'rails_helper'

RSpec.describe 'Agents API', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let!(:admin) { create(:user, custom_attributes: { test: 'test' }, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/{account.id}/agents' do
    context 'when the account has reached its agent limit' do
      params = { name: 'NewUser', email: Faker::Internet.email, role: :agent }

      before do
        account.update!(limits: { agents: 4 })
        create_list(:user, 4, account: account, role: :agent)
      end

      it 'prevents adding a new agent and returns a payment required status' do
        post "/api/v1/accounts/#{account.id}/agents", params: params, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:payment_required)
        expect(response.body).to include('Account limit exceeded. Please purchase more licenses')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agents/bulk_create' do
    let(:emails) { ['test1@example.com', 'test2@example.com', 'test3@example.com'] }
    let(:bulk_create_params) { { emails: emails } }

    context 'when exceeding agent limit' do
      it 'prevents creating agents and returns a payment required status' do
        # Set the limit to be less than the number of emails
        account.update!(limits: { agents: 2 })

        expect do
          post "/api/v1/accounts/#{account.id}/agents/bulk_create", params: bulk_create_params, headers: admin.create_new_auth_token
        end.not_to change(User, :count)

        expect(response).to have_http_status(:payment_required)
        expect(response.body).to include('Account limit exceeded. Please purchase more licenses')
      end
    end

    context 'when onboarding step is present in account custom attributes' do
      it 'removes onboarding step from account custom attributes' do
        account.update!(custom_attributes: { onboarding_step: 'completed' })

        post "/api/v1/accounts/#{account.id}/agents/bulk_create", params: bulk_create_params, headers: admin.create_new_auth_token

        expect(account.reload.custom_attributes).not_to include('onboarding_step')
      end
    end
  end
end
