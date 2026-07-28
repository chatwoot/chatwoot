require 'rails_helper'

RSpec.describe 'Article Bulk Actions API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account: account, config: { allowed_locales: %w[en es] }) }
  let!(:category) { create(:category, portal: portal, account: account, locale: 'en', slug: 'getting-started') }
  let!(:article_one) { create(:article, category: category, portal: portal, account: account, author: admin, status: :draft) }
  let!(:article_two) { create(:article, category: category, portal: portal, account: account, author: admin, status: :draft) }
  let!(:article_three) { create(:article, category: category, portal: portal, account: account, author: admin, status: :published) }

  let(:base_url) { "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/bulk_actions" }

  describe 'PATCH articles/bulk_actions/update_status' do
    let(:update_status_url) { "#{base_url}/update_status" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch update_status_url, params: { ids: [article_one.id], status: 'published' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        patch update_status_url,
              headers: agent.create_new_auth_token,
              params: { ids: [article_one.id], status: 'published' },
              as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      it 'publishes multiple articles' do
        patch update_status_url,
              headers: admin.create_new_auth_token,
              params: { ids: [article_one.id, article_two.id], status: 'published' },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(article_one.reload.status).to eq('published')
        expect(article_two.reload.status).to eq('published')
      end

      it 'archives multiple articles' do
        patch update_status_url,
              headers: admin.create_new_auth_token,
              params: { ids: [article_one.id, article_three.id], status: 'archived' },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(article_one.reload.status).to eq('archived')
        expect(article_three.reload.status).to eq('archived')
      end

      it 'sets articles to draft' do
        patch update_status_url,
              headers: admin.create_new_auth_token,
              params: { ids: [article_three.id], status: 'draft' },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(article_three.reload.status).to eq('draft')
      end

      it 'does not affect articles not in the list' do
        patch update_status_url,
              headers: admin.create_new_auth_token,
              params: { ids: [article_one.id], status: 'published' },
              as: :json

        expect(article_one.reload.status).to eq('published')
        expect(article_three.reload.status).to eq('published')
      end

      it 'returns unprocessable entity when no articles found' do
        patch update_status_url,
              headers: admin.create_new_auth_token,
              params: { ids: [0], status: 'published' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE articles/bulk_actions/delete_articles' do
    let(:destroy_url) { "#{base_url}/delete_articles" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete destroy_url, params: { ids: [article_one.id] }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        delete destroy_url,
               headers: agent.create_new_auth_token,
               params: { ids: [article_one.id] },
               as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      it 'deletes multiple articles' do
        expect do
          delete destroy_url,
                 headers: admin.create_new_auth_token,
                 params: { ids: [article_one.id, article_two.id] },
                 as: :json
        end.to change(Article, :count).by(-2)

        expect(response).to have_http_status(:ok)
      end

      it 'does not delete articles not in the list' do
        delete destroy_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id] },
               as: :json

        expect(Article.exists?(article_one.id)).to be(false)
        expect(Article.exists?(article_three.id)).to be(true)
      end

      it 'returns unprocessable entity when no articles found' do
        delete destroy_url,
               headers: admin.create_new_auth_token,
               params: { ids: [0] },
               as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
