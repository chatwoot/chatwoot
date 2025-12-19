require 'rails_helper'

RSpec.describe 'Label API', type: :request do
  let!(:account) { create(:account) }
  let!(:label) { create(:label, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/labels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/labels"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :administrator) }

      it 'returns all the labels in account' do
        get "/api/v1/accounts/#{account.id}/labels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(label.title)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/labels/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/labels/#{label.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the label' do
        get "/api/v1/accounts/#{account.id}/labels/#{label.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(label.title)
        json_response = response.parsed_body
        expect(json_response).to have_key('parent_id')
        expect(json_response).to have_key('depth')
        expect(json_response).to have_key('children_count')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/labels' do
    let(:valid_params) { { label: { title: 'test' } } }
    let(:parent_label) { create(:label, account: account, title: 'parent') }
    let(:params_with_parent) { { label: { title: 'child', parent_id: parent_label.id } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/labels", params: valid_params }.not_to change(Label, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates the label' do
        expect do
          post "/api/v1/accounts/#{account.id}/labels", headers: admin.create_new_auth_token,
                                                        params: valid_params
        end.to change(Label, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'creates label with parent' do
        parent_label # ensure parent is created before counting

        expect do
          post "/api/v1/accounts/#{account.id}/labels", headers: admin.create_new_auth_token,
                                                        params: params_with_parent
        end.to change(Label, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['parent_id']).to eq(parent_label.id)
        expect(json_response['depth']).to eq(1)
      end

      it 'prevents creating label exceeding max depth' do
        level1 = create(:label, account: account, title: 'level1')
        level2 = create(:label, account: account, parent: level1, title: 'level2')
        level3 = create(:label, account: account, parent: level2, title: 'level3')
        level4 = create(:label, account: account, parent: level3, title: 'level4')
        level5 = create(:label, account: account, parent: level4, title: 'level5')
        level6 = create(:label, account: account, parent: level5, title: 'level6')

        invalid_params = { label: { title: 'level7', parent_id: level6.id } }

        post "/api/v1/accounts/#{account.id}/labels", headers: admin.create_new_auth_token,
                                                      params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'prevents creating label with parent from different account' do
        other_account = create(:account)
        other_label = create(:label, account: other_account, title: 'other_account_label')
        invalid_params = { label: { title: 'cross_account_child', parent_id: other_label.id } }

        expect do
          post "/api/v1/accounts/#{account.id}/labels", headers: admin.create_new_auth_token,
                                                        params: invalid_params
        end.not_to change(Label, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/labels/:id' do
    let(:valid_params) { { title: 'Test_2' }  }
    let(:parent_label) { create(:label, account: account, title: 'parent') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/labels/#{label.id}",
            params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the label' do
        patch "/api/v1/accounts/#{account.id}/labels/#{label.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(label.reload.title).to eq('test_2')
      end

      it 'updates label parent' do
        params_with_parent = { parent_id: parent_label.id }
        patch "/api/v1/accounts/#{account.id}/labels/#{label.id}",
              headers: admin.create_new_auth_token,
              params: params_with_parent,
              as: :json

        expect(response).to have_http_status(:success)
        expect(label.reload.parent_id).to eq(parent_label.id)
        expect(label.reload.depth).to eq(1)
      end

      it 'prevents circular reference on update' do
        child_label = create(:label, account: account, parent: label, title: 'child')
        invalid_params = { parent_id: child_label.id }

        patch "/api/v1/accounts/#{account.id}/labels/#{label.id}",
              headers: admin.create_new_auth_token,
              params: invalid_params,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'prevents updating parent to label from different account' do
        other_account = create(:account)
        other_label = create(:label, account: other_account, title: 'other_account_label')
        invalid_params = { parent_id: other_label.id }

        patch "/api/v1/accounts/#{account.id}/labels/#{label.id}",
              headers: admin.create_new_auth_token,
              params: invalid_params,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(label.reload.parent_id).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/labels with hierarchy' do
    context 'when labels have hierarchy' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:parent) { create(:label, account: account, title: 'parent') }
      let(:child) { create(:label, account: account, parent: parent, title: 'child') }

      it 'returns labels with hierarchy information' do
        parent
        child

        get "/api/v1/accounts/#{account.id}/labels",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body['payload']

        parent_label = json_response.find { |l| l['id'] == parent.id }
        child_label = json_response.find { |l| l['id'] == child.id }

        expect(parent_label['parent_id']).to be_nil
        expect(parent_label['depth']).to eq(0)
        expect(parent_label['children_count']).to eq(1)

        expect(child_label['parent_id']).to eq(parent.id)
        expect(child_label['depth']).to eq(1)
        expect(child_label['children_count']).to eq(0)
      end
    end

    context 'when labels have NULL values for depth and children_count' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:label_with_nulls) { create(:label, account: account, title: 'null_label') }

      before do
        # Force NULL values in database - using update_columns is acceptable in tests
        # rubocop:disable Rails/SkipsModelValidations
        label_with_nulls.update_columns(depth: nil, children_count: nil)
        # rubocop:enable Rails/SkipsModelValidations
        label_with_nulls.reload
      end

      it 'returns 0 for NULL depth and children_count in API response' do
        get "/api/v1/accounts/#{account.id}/labels",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body['payload']

        null_label = json_response.find { |l| l['id'] == label_with_nulls.id }

        # API should return 0, not NULL
        expect(null_label['depth']).to eq(0)
        expect(null_label['children_count']).to eq(0)
        expect(null_label['parent_id']).to be_nil
      end
    end
  end
end
