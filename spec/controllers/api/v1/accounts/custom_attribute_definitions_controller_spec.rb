require 'rails_helper'

RSpec.describe 'Custom Attribute Definitions API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/custom_attribute_definitions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:custom_attribute_definition) { create(:custom_attribute_definition, account: account) }

      it 'returns all customer attribute definitions related to the account' do
        create(:custom_attribute_definition, attribute_model: 'contact_attribute', account: account)

        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)

        expect(response_body.count).to eq(2)
        expect(response_body.first['attribute_key']).to eq(custom_attribute_definition.attribute_key)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/custom_attribute_definitions/:id' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the custom attribute definition' do
        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(custom_attribute_definition.attribute_key)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_attribute_definitions' do
    let(:payload) do
      {
        custom_attribute_definition: {
          attribute_display_name: 'Developer ID',
          attribute_key: 'developer_id',
          attribute_model: 'contact_attribute',
          attribute_display_type: 'text',
          default_value: ''
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
               params: payload
        end.to change(CustomAttributeDefinition, :count).by(0)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the filter' do
        expect do
          post "/api/v1/accounts/#{account.id}/custom_attribute_definitions", headers: user.create_new_auth_token,
                                                                              params: payload
        end.to change(CustomAttributeDefinition, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['attribute_key']).to eq 'developer_id'
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/custom_attribute_definitions/:id' do
    let(:payload) { { custom_attribute_definition: { attribute_display_name: 'Developer ID', attribute_key: 'developer_id' } } }
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
            params: payload

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the custom attribute definition' do
        patch "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json
        expect(response).to have_http_status(:success)
        expect(custom_attribute_definition.reload.attribute_display_name).to eq('Developer ID')
        expect(custom_attribute_definition.reload.attribute_key).to eq('developer_id')
        expect(custom_attribute_definition.reload.attribute_model).to eq('conversation_attribute')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/custom_attribute_definitions/:id' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'deletes custom attribute' do
        delete "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
               headers: user.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:no_content)
        expect(account.custom_attribute_definitions.count).to be 0
      end
    end
  end
end
