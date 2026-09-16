require 'rails_helper'

RSpec.describe 'Article Bulk Actions API', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:portal) { create(:portal, name: 'test_portal', account: account, config: { allowed_locales: %w[en es fr] }) }
  let!(:category_en) { create(:category, portal: portal, account: account, locale: 'en', slug: 'getting-started') }
  let!(:category_es) { create(:category, portal: portal, account: account, locale: 'es', slug: 'primeros-pasos') }
  let!(:article_one) { create(:article, category: category_en, portal: portal, account: account, author_id: admin.id) }
  let!(:article_two) { create(:article, category: category_en, portal: portal, account: account, author_id: admin.id) }

  let(:translate_url) { "/api/v1/accounts/#{account.id}/portals/#{portal.slug}/articles/bulk_actions/translate" }

  describe 'POST articles/bulk_actions/translate' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post translate_url, params: { ids: [article_one.id], locale: 'es', category_id: category_es.id }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        post translate_url,
             headers: agent.create_new_auth_token,
             params: { ids: [article_one.id], locale: 'es', category_id: category_es.id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when captain is not enabled' do
      it 'returns unprocessable entity' do
        post translate_url,
             headers: admin.create_new_auth_token,
             params: { ids: [article_one.id], locale: 'es', category_id: category_es.id },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when authenticated as admin' do
      before do
        account.enable_features!('captain_tasks')
      end

      it 'enqueues translation jobs for each article' do
        expect do
          post translate_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id, article_two.id], locale: 'es', category_id: category_es.id },
               as: :json
        end.to have_enqueued_job(Captain::Articles::TranslateJob).exactly(2).times

        expect(response).to have_http_status(:ok)
      end

      it 'enqueues job with correct arguments' do
        expect do
          post translate_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id], locale: 'es', category_id: category_es.id },
               as: :json
        end.to have_enqueued_job(Captain::Articles::TranslateJob).with(
          account, article_one.id, 'es', category_es.id, admin
        )

        expect(response).to have_http_status(:ok)
      end

      it 'returns unprocessable entity for invalid locale' do
        post translate_url,
             headers: admin.create_new_auth_token,
             params: { ids: [article_one.id], locale: 'zh', category_id: category_es.id },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity for invalid category' do
        post translate_url,
             headers: admin.create_new_auth_token,
             params: { ids: [article_one.id], locale: 'es', category_id: 0 },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity when category locale does not match requested locale' do
        post translate_url,
             headers: admin.create_new_auth_token,
             params: { ids: [article_one.id], locale: 'es', category_id: category_en.id },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'enqueues job with nil category when category_id is omitted' do
        expect do
          post translate_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id], locale: 'es' },
               as: :json
        end.to have_enqueued_job(Captain::Articles::TranslateJob).with(
          account, article_one.id, 'es', nil, admin
        )

        expect(response).to have_http_status(:ok)
      end

      it 'enqueues job with nil category when category_id is blank' do
        expect do
          post translate_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id], locale: 'es', category_id: '' },
               as: :json
        end.to have_enqueued_job(Captain::Articles::TranslateJob).with(
          account, article_one.id, 'es', nil, admin
        )

        expect(response).to have_http_status(:ok)
      end

      it 'returns unprocessable entity when no articles found' do
        post translate_url,
             headers: admin.create_new_auth_token,
             params: { ids: [0], locale: 'es', category_id: category_es.id },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      context 'when translations already exist' do
        let!(:existing_translation) do
          create(:article, portal: portal, category: category_es, account: account, author_id: admin.id,
                           locale: 'es', associated_article_id: article_one.id)
        end

        it 'returns conflict with duplicate articles' do
          post translate_url,
               headers: admin.create_new_auth_token,
               params: { ids: [article_one.id], locale: 'es', category_id: category_es.id },
               as: :json

          expect(response).to have_http_status(:conflict)
          body = response.parsed_body
          expect(body['duplicate_articles'].length).to eq(1)
          expect(body['duplicate_articles'].first['id']).to eq(existing_translation.id)
        end

        it 'does not enqueue jobs when duplicates found without force' do
          expect do
            post translate_url,
                 headers: admin.create_new_auth_token,
                 params: { ids: [article_one.id], locale: 'es', category_id: category_es.id },
                 as: :json
          end.not_to have_enqueued_job(Captain::Articles::TranslateJob)
        end

        it 'enqueues jobs when force is true' do
          expect do
            post translate_url,
                 headers: admin.create_new_auth_token,
                 params: { ids: [article_one.id], locale: 'es', category_id: category_es.id, force: true },
                 as: :json
          end.to have_enqueued_job(Captain::Articles::TranslateJob).exactly(1).times

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
