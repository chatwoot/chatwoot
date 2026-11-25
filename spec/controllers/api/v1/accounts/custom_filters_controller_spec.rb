require 'rails_helper'

RSpec.describe 'Custom Filters API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:custom_filter) { create(:custom_filter, user: user, account: account) }

  before do
    create(:conversation, account: account, assignee: user, status: 'open')
    create(:conversation, account: account, assignee: user, status: 'resolved')
    custom_filter.query = { payload: [
      {
        values: ['open'],
        attribute_key: 'status',
        query_operator: nil,
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        custom_attribute_type: ''
      }
    ] }
    custom_filter.save!
  end

  describe 'GET /api/v1/accounts/{account.id}/custom_filters' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_filters"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all custom_filter related to the user' do
        get "/api/v1/accounts/#{account.id}/custom_filters",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body.first['name']).to eq(custom_filter.name)
        expect(response_body.first['query']).to eq(custom_filter.query)
      end

      it 'includes global filters created by other users in the same account' do
        global_filter = create(:custom_filter, user: admin, account: account, visibility: :global, name: 'shared folder')
        create(:custom_filter, user: admin, account: account, visibility: :personal, name: 'private to admin')

        get "/api/v1/accounts/#{account.id}/custom_filters",
            headers: user.create_new_auth_token,
            as: :json

        names = response.parsed_body.pluck('name')
        expect(names).to include(custom_filter.name, global_filter.name)
        expect(names).not_to include('private to admin')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/custom_filters/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the custom filter' do
        get "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(custom_filter.name)
      end

      it 'forbids fetching a personal filter owned by another user' do
        other_filter = create(:custom_filter, user: admin, account: account, visibility: :personal)

        get "/api/v1/accounts/#{account.id}/custom_filters/#{other_filter.id}",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'forbids administrators from fetching a personal filter owned by another user' do
        get "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_filters' do
    let(:payload) do
      { custom_filter: {
        name: 'vip-customers', filter_type: 'conversation',
        query: { payload: [{
          values: ['open'], attribute_key: 'status', attribute_model: 'standard', filter_operator: 'equal_to'
        }] }
      } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/custom_filters", params: payload }.not_to change(CustomFilter, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the filter' do
        post "/api/v1/accounts/#{account.id}/custom_filters", headers: user.create_new_auth_token,
                                                              params: payload

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['name']).to eq 'vip-customers'
        expect(json_response['visibility']).to eq 'personal'
      end

      it 'forces agent-created filters to personal even when visibility=global is sent' do
        post "/api/v1/accounts/#{account.id}/custom_filters", headers: user.create_new_auth_token,
                                                              params: { custom_filter: payload[:custom_filter].merge(visibility: 'global') }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['visibility']).to eq 'personal'
      end

      it 'allows administrators to create global filters' do
        post "/api/v1/accounts/#{account.id}/custom_filters", headers: admin.create_new_auth_token,
                                                              params: { custom_filter: payload[:custom_filter].merge(visibility: 'global') }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['visibility']).to eq 'global'
      end

      it 'rejects a date condition with an invalid timezone' do
        payload[:custom_filter][:query][:payload] = [{
          values: ['2026-09-08'], attribute_key: 'created_at', attribute_model: 'standard',
          filter_operator: 'is_less_than', timezone: 'Invalid/Timezone'
        }]

        expect do
          post "/api/v1/accounts/#{account.id}/custom_filters", headers: user.create_new_auth_token,
                                                                params: payload,
                                                                as: :json
        end.not_to change(CustomFilter, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'gives the error for 1001st record' do
        CustomFilter.delete_all
        Limits::MAX_CUSTOM_FILTERS_PER_USER.times do
          create(:custom_filter, user: user, account: account)
        end

        expect do
          post "/api/v1/accounts/#{account.id}/custom_filters", headers: user.create_new_auth_token,
                                                                params: payload
        end.not_to change(CustomFilter, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['message']).to include(
          'Account Limit reached. The maximum number of allowed custom filters for a user per account is 1000.'
        )
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/custom_filters/:id' do
    let(:payload) do
      { custom_filter: {
        name: 'vip-customers', filter_type: 'conversation',
        query: { payload: [{
          values: ['resolved'], attribute_key: 'status', attribute_model: 'standard', filter_operator: 'equal_to'
        }] }
      } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
            params: payload

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the custom filter' do
        patch "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:success)
        expect(custom_filter.reload.name).to eq('vip-customers')
        expect(custom_filter.reload.filter_type).to eq('conversation')
        expect(custom_filter.reload.query['payload'][0]['values']).to eq(['resolved'])
      end

      it 'rejects a date condition with an invalid timezone' do
        payload[:custom_filter][:query][:payload] = [{
          values: [1], attribute_key: 'created_at', attribute_model: 'standard',
          filter_operator: 'days_before', timezone: 'Invalid/Timezone'
        }]

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(custom_filter.reload.query['payload'][0]['values']).to eq(['open'])
      end

      it 'prevents the update of custom filter of another user/account' do
        other_account = create(:account)
        other_user = create(:user, account: other_account)
        other_custom_filter = create(:custom_filter, user: other_user, account: other_account)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{other_custom_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'forbids agents from updating a global filter authored by an admin' do
        global_filter = create(:custom_filter, user: admin, account: account, visibility: :global)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{global_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'allows administrators to flip a personal filter to global' do
        admin_filter = create(:custom_filter, user: admin, account: account, visibility: :personal)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{admin_filter.id}",
              headers: admin.create_new_auth_token,
              params: { custom_filter: { visibility: 'global' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(admin_filter.reload.visibility).to eq('global')
      end

      it 'keeps agent-owned filters personal when agent sends visibility=global on update' do
        agent_filter = create(:custom_filter, user: user, account: account, visibility: :personal)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{agent_filter.id}",
              headers: user.create_new_auth_token,
              params: { custom_filter: { visibility: 'global' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(agent_filter.reload.visibility).to eq('personal')
      end

      it 'allows administrators to edit a global filter authored by another admin' do
        other_admin = create(:user, account: account, role: :administrator)
        global_filter = create(:custom_filter, user: other_admin, account: account, visibility: :global)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{global_filter.id}",
              headers: admin.create_new_auth_token,
              params: { custom_filter: { name: 'renamed by other admin' } },
              as: :json

        expect(response).to have_http_status(:success)
        expect(global_filter.reload.name).to eq('renamed by other admin')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/custom_filters/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes custom filter if it is attached to the current user and account' do
        delete "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
               headers: user.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:no_content)
        expect(user.custom_filters.count).to be 0
      end

      it 'forbids an agent from deleting a global filter owned by an admin' do
        global_filter = create(:custom_filter, user: admin, account: account, visibility: :global)

        delete "/api/v1/accounts/#{account.id}/custom_filters/#{global_filter.id}",
               headers: user.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(CustomFilter.exists?(global_filter.id)).to be true
      end

      it 'allows admin to delete a global filter authored by another admin' do
        other_admin = create(:user, account: account, role: :administrator)
        global_filter = create(:custom_filter, user: other_admin, account: account, visibility: :global)

        delete "/api/v1/accounts/#{account.id}/custom_filters/#{global_filter.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
