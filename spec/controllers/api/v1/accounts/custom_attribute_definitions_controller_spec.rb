require 'rails_helper'

RSpec.describe 'Custom Attribute Definitions API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }

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
        contact_attribute_definition = create(:custom_attribute_definition, attribute_model: 'contact_attribute', account: account)

        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body

        expect(response_body.count).to eq(2)
        expect(response_body.pluck('attribute_key')).to contain_exactly(
          custom_attribute_definition.attribute_key, contact_attribute_definition.attribute_key
        )
      end

      it 'returns the custom attribute definitions ordered by position' do
        second = create(:custom_attribute_definition, account: account)

        CustomAttributeDefinition.update_positions(
          account: account,
          positions_hash: { custom_attribute_definition.id => 20, second.id => 10 }
        )

        get "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
            headers: admin.create_new_auth_token,
            as: :json

        response_body = response.parsed_body
        expect(response_body.pluck('id')).to eq([second.id, custom_attribute_definition.id])
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
            headers: admin.create_new_auth_token,
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
        end.not_to change(CustomAttributeDefinition, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the filter' do
        expect do
          post "/api/v1/accounts/#{account.id}/custom_attribute_definitions", headers: admin.create_new_auth_token,
                                                                              params: payload
        end.to change(CustomAttributeDefinition, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['attribute_key']).to eq 'developer_id'
        expect(json_response['position']).not_to be_nil
      end

      context 'when it is an agent' do
        it 'returns forbidden and does not create the custom attribute' do
          expect do
            post "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
                 headers: agent.create_new_auth_token,
                 params: payload
          end.not_to change(CustomAttributeDefinition, :count)

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when creating with a conflicting attribute_key' do
        let(:standard_key) { CustomAttributeDefinition::STANDARD_ATTRIBUTES[:conversation].first }
        let(:conflicting_payload) do
          {
            custom_attribute_definition: {
              attribute_display_name: 'Conflicting Key',
              attribute_key: standard_key,
              attribute_model: 'conversation_attribute',
              attribute_display_type: 'text'
            }
          }
        end

        it 'returns error for conflicting key' do
          post "/api/v1/accounts/#{account.id}/custom_attribute_definitions",
               headers: admin.create_new_auth_token,
               params: conflicting_payload

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = response.parsed_body
          expect(json_response['message']).to include('The provided key is not allowed as it might conflict with default attributes.')
        end
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
              headers: admin.create_new_auth_token,
              params: payload,
              as: :json
        expect(response).to have_http_status(:success)
        expect(custom_attribute_definition.reload.attribute_display_name).to eq('Developer ID')
        expect(custom_attribute_definition.reload.attribute_key).to eq('developer_id')
        expect(custom_attribute_definition.reload.attribute_model).to eq('conversation_attribute')
        expect(response.parsed_body['position']).to eq(custom_attribute_definition.position)
      end
    end

    context 'when it is an agent' do
      it 'returns forbidden and does not update the custom attribute' do
        original_name = custom_attribute_definition.attribute_display_name
        patch "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
              headers: agent.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(custom_attribute_definition.reload.attribute_display_name).to eq(original_name)
      end
    end

    context 'when changing attribute_model via update' do
      it 'recomputes position into the destination scope without colliding with an existing record there' do
        existing_contact_cad = create(:custom_attribute_definition, attribute_model: 'contact_attribute', account: account)

        patch "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
              headers: admin.create_new_auth_token,
              params: { custom_attribute_definition: { attribute_model: 'contact_attribute' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(custom_attribute_definition.reload.attribute_model).to eq('contact_attribute')
        expect(response.parsed_body['position']).to eq(existing_contact_cad.reload.position + 10)
        expect(custom_attribute_definition.position).not_to eq(existing_contact_cad.position)
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
               headers: admin.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:no_content)
        expect(account.custom_attribute_definitions.count).to be 0
      end
    end

    context 'when it is an agent' do
      it 'returns forbidden and does not delete the custom attribute' do
        delete "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{custom_attribute_definition.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(account.custom_attribute_definitions.count).to be 1
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_attribute_definitions/reorder' do
    let!(:first_attribute) { create(:custom_attribute_definition, account: account) }
    let!(:second_attribute) { create(:custom_attribute_definition, account: account) }
    let(:payload) { { positions_hash: { first_attribute.id => 20, second_attribute.id => 10 } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/custom_attribute_definitions/reorder", params: payload
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an admin' do
      it 'updates the positions' do
        post "/api/v1/accounts/#{account.id}/custom_attribute_definitions/reorder",
             headers: admin.create_new_auth_token,
             params: payload,
             as: :json

        expect(response).to have_http_status(:success)
        expect(first_attribute.reload.position).to eq(20)
        expect(second_attribute.reload.position).to eq(10)
      end
    end

    context 'when it is an agent' do
      it 'returns forbidden and does not update the positions' do
        original_position = first_attribute.position

        post "/api/v1/accounts/#{account.id}/custom_attribute_definitions/reorder",
             headers: agent.create_new_auth_token,
             params: payload,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(first_attribute.reload.position).to eq(original_position)
      end
    end
  end
end
