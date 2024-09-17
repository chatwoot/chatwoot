require 'rails_helper'

RSpec.describe 'Custom Roles API', type: :request do
  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:custom_role) { create(:custom_role, account: account, name: 'Manager') }

  describe 'GET #index' do
    context 'when it is an authenticated administrator' do
      it 'returns all custom roles in the account' do
        get "/api/v1/accounts/#{account.id}/custom_roles",
            headers: administrator.create_new_auth_token
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body[0]).to include('name' => custom_role.name)
      end
    end

    context 'when the user is an agent and is authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'when it is an authenticated administrator' do
      it 'returns the custom role details' do
        get "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('name' => custom_role.name)
      end
    end

    context 'when the user is an agent and is authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      { custom_role: { name: 'Support', description: 'Support role',
                       permissions: CustomRole::PERMISSIONS.sample(SecureRandom.random_number(1..4)) } }
    end

    context 'when it is an authenticated administrator' do
      it 'creates the custom role' do
        expect do
          post "/api/v1/accounts/#{account.id}/custom_roles",
               params: valid_params,
               headers: administrator.create_new_auth_token
        end.to change(CustomRole, :count).by(1)

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('name' => 'Support')
      end
    end

    context 'when the user is an agent and is authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/custom_roles",
             params: valid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/custom_roles",
             params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT #update' do
    let(:update_params) { { custom_role: { name: 'Updated Role' } } }

    context 'when it is an authenticated administrator' do
      it 'updates the custom role' do
        put "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
            params: update_params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body).to include('name' => 'Updated Role')
      end
    end

    context 'when the user is an agent and is authenticated' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
            params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when it is an authenticated administrator' do
      it 'deletes the custom role' do
        delete "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(CustomRole.count).to eq(0)
      end
    end

    context 'when the user is an agent and is authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
