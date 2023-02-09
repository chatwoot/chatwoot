require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Portals', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent_1) { create(:user, account: account, role: :agent) }
  let(:agent_2) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, slug: 'portal-1', name: 'test_portal', account_id: account.id) }

  before { create(:portal_member, user: agent, portal: portal) }

  describe 'GET /api/v1/accounts/{account.id}/portals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get all portals' do
        portal2 = create(:portal, name: 'test_portal_2', account_id: account.id, slug: 'portal-2')
        expect(portal2.id).not_to be_nil
        get "/api/v1/accounts/#{account.id}/portals",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].length).to be 2
        expect(json_response['payload'][0]['id']).to be portal.id
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/portals"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'get one portals' do
        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq portal.name
        expect(json_response['meta']['all_articles_count']).to eq 0
      end

      it 'returns portal articles metadata' do
        portal.update(config: { allowed_locales: %w[en es], default_locale: 'en' })
        en_cat = create(:category, locale: :en, portal_id: portal.id, slug: 'en-cat')
        es_cat = create(:category, locale: :es, portal_id: portal.id, slug: 'es-cat')
        create(:article, category_id: en_cat.id, portal_id: portal.id, author_id: agent.id)
        create(:article, category_id: en_cat.id, portal_id: portal.id, author_id: admin.id)
        create(:article, category_id: es_cat.id, portal_id: portal.id, author_id: agent.id)

        get "/api/v1/accounts/#{account.id}/portals/#{portal.slug}?locale=en",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq portal.name
        expect(json_response['meta']['all_articles_count']).to eq 2
        expect(json_response['meta']['mine_articles_count']).to eq 1
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/portals' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/portals",
             params: {},
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates portal' do
        portal_params = {
          portal: {
            name: 'test_portal',
            slug: 'test_kbase',
            custom_domain: 'https://support.chatwoot.dev'
          }
        }
        post "/api/v1/accounts/#{account.id}/portals",
             params: portal_params,
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eql('test_portal')
        expect(json_response['custom_domain']).to eql('support.chatwoot.dev')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}", params: {}

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates portal' do
        portal_params = {
          portal: {
            name: 'updated_test_portal',
            config: { 'allowed_locales' => %w[en es] }
          }
        }

        expect(portal.name).to eql('test_portal')

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            params: portal_params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eql(portal_params[:portal][:name])
        expect(json_response['config']).to eql({ 'allowed_locales' => [{ 'articles_count' => 0, 'categories_count' => 0, 'code' => 'en' },
                                                                       { 'articles_count' => 0, 'categories_count' => 0, 'code' => 'es' }] })
      end

      it 'archive portal' do
        portal_params = {
          portal: {
            archived: true
          }
        }

        expect(portal.archived).to be_falsy

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            params: portal_params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['archived']).to eql(portal_params[:portal][:archived])

        portal.reload
        expect(portal.archived).to be_truthy
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/portals/{portal.slug}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes portal' do
        delete "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
               headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        deleted_portal = Portal.find_by(id: portal.slug)
        expect(deleted_portal).to be_nil
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/portals/{portal.slug}/add_members' do
    let(:new_account) { create(:account) }
    let(:new_agent) { create(:user, account: new_account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/add_members", params: {}

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'add members to the portal' do
        portal_params = {
          portal: {
            member_ids: [agent_1.id, agent_2.id]
          }
        }
        expect(portal.members.count).to be(1)

        put "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/add_members",
            params: portal_params,
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(portal.reload.member_ids).to include(agent_1.id)
        expect(json_response['portal_members'].length).to be(3)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/portals/attach_file' do
    it 'update the portal with a logo' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

      post "/api/v1/accounts/#{account.id}/portals/attach_file",
           headers: admin.create_new_auth_token,
           params: { logo: file }

      expect(response).to have_http_status(:success)

      blob = JSON.parse(response.body)

      expect(blob['blob_key']).to be_present
      expect(blob['blob_id']).to be_present

      params = { blob_id: blob['blob_id'] }

      expect(portal.logo.attachment).not_to be_present

      patch "/api/v1/accounts/#{account.id}/portals/#{portal.slug}",
            headers: admin.create_new_auth_token,
            params: params
      portal.reload

      expect(portal.logo.presence).to be_truthy
      expect(portal.logo.attachment).to be_present
    end
  end
end
