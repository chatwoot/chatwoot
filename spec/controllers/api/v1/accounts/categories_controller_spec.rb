require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Categories', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account_id: account.id, config: { allowed_locales: %w[en es] }) }
  let!(:category) { create(:category, name: 'category', portal: portal, account_id: account.id, slug: 'category_slug', position: 1) }
  let!(:category_to_associate) do
    create(:category, name: 'associated category', portal: portal, account_id: account.id, slug: 'associated_category_slug', position: 2)
  end
  let!(:related_category_1) do
    create(:category, name: 'related category 1', portal: portal, account_id: account.id, slug: 'category_slug_1', position: 3)
  end
  let!(:related_category_2) do
    create(:category, name: 'related category 2', portal: portal, account_id: account.id, slug: 'category_slug_2', position: 4)
  end

  before { create(:portal_member, user: agent, portal: portal) }

  describe 'POST /api/v1/accounts/{account.id}/portals/{portal.slug}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:category_params) do
        {
          category: {
            name: 'test_category',
            description: 'test_description',
            position: 5,
            locale: 'es',
            slug: 'test_category_1',
            parent_category_id: category.id,
            associated_category_id: category_to_associate.id,
            related_category_ids: [related_category_1.id, related_category_2.id]
          }
        }
      end

      let!(:category_params_2) do
        {
          category: {
            name: 'test_category_2',
            description: 'test_description_2',
            position: 6,
            locale: 'es',
            slug: 'test_category_2',
            parent_category_id: category.id,
            associated_category_id: category_to_associate.id,
            related_category_ids: [related_category_1.id, related_category_2.id]
          }
        }
      end

      it 'creates category' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)

        json_response = response.parsed_body

        expect(json_response['payload']['related_categories'][0]['id']).to eql(related_category_1.id)
        expect(json_response['payload']['related_categories'][1]['id']).to eql(related_category_2.id)
        expect(json_response['payload']['parent_category']['id']).to eql(category.id)
        expect(json_response['payload']['root_category']['id']).to eql(category_to_associate.id)
        expect(category.reload.sub_category_ids).to eql([Category.last.id])
        expect(category_to_associate.reload.associated_category_ids).to eql([Category.last.id])
      end

      it 'creates multiple sub_categories under one parent_category' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params_2,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(category.reload.sub_category_ids).to eql(Category.last(2).pluck(:id))
      end

      it 'creates multiple associated_categories with one category' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params_2,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(category_to_associate.reload.associated_category_ids).to eql(Category.last(2).pluck(:id))
      end

      it 'will throw an error on locale, category_id uniqueness' do
        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['message']).to eql('Locale should be unique in the category and portal')
      end

      it 'will throw an error slug presence' do
        category_params = {
          category: {
            name: 'test_category',
            description: 'test_description',
            position: 1,
            locale: 'es'
          }
        }

        post "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
             params: category_params,
             headers: agent.create_new_auth_token
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body

        expect(json_response['message']).to eql("Slug can't be blank")
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates category' do
        category_params = {
          category: {
            name: 'test_category_2',
            description: 'test_description',
            position: 1,
            related_category_ids: [related_category_1.id],
            parent_category_id: related_category_2.id
          }
        }

        expect(category.name).not_to eql(category_params[:category][:name])
        expect(category.related_categories).to be_empty
        expect(category.parent_category).to be_nil

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
            params: category_params,
            headers: agent.create_new_auth_token

        json_response = response.parsed_body

        expect(json_response['payload']['name']).to eql(category_params[:category][:name])
        expect(json_response['payload']['related_categories'][0]['id']).to eql(related_category_1.id)
        expect(json_response['payload']['parent_category']['id']).to eql(related_category_2.id)
        expect(related_category_2.reload.sub_category_ids).to eql([category.id])
      end

      it 'updates related categories' do
        category_params = {
          category: {
            related_category_ids: [related_category_1.id]
          }
        }
        category.related_categories << related_category_2
        category.save!

        expect(category.related_category_ids).to eq([related_category_2.id])

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
            params: category_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)

        json_response = response.parsed_body

        expect(json_response['payload']['name']).to eql(category.name)
        expect(json_response['payload']['related_categories'][0]['id']).to eql(related_category_1.id)
        expect(category.reload.related_category_ids).to eq([related_category_1.id])
        expect(related_category_1.reload.related_category_ids).to be_empty
        expect(json_response['payload']['position']).to eql(category.position)
      end

      # [category_1, category_2] !== [category_2, category_1]
      it 'update reverse associations for related categories' do
        category.related_categories << related_category_2
        category.save!

        expect(category.related_category_ids).to eq([related_category_2.id])

        category_params = {
          category: {
            related_category_ids: [category.id]
          }
        }

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{related_category_2.id}",
            params: category_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)

        expect(category.reload.related_category_ids).to eq([related_category_2.id])
        expect(related_category_2.reload.related_category_ids).to eq([category.id])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}/categories/{category.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes category' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories/#{category.id}",
               headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_category = Category.find_by(id: category.id)
        expect(deleted_category).to be_nil
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}/categories' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all categories in portal' do
        category_count = Category.all.count

        category2 = create(:category, name: 'test_category_2', portal: portal, locale: 'es', slug: 'category_slug_2')

        expect(category2.id).not_to be_nil

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/categories",
            headers: agent.create_new_auth_token
        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].count).to be(category_count + 1)
      end
    end
  end
end
