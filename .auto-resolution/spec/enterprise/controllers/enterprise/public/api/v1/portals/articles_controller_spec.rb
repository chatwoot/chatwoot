require 'rails_helper'

RSpec.describe 'Public Articles API', type: :request do
  let!(:portal) { create(:portal, slug: 'test-portal', config: { allowed_locales: %w[en es] }, custom_domain: 'www.example.com') }

  describe 'GET /public/api/v1/portals/:slug/articles' do
    before do
      portal.account.enable_features!(:help_center_embedding_search)
    end

    context 'with help_center_embedding_search feature' do
      it 'get all articles with searched text query using vector search if enabled' do
        allow(Article).to receive(:vector_search)
        get "/hc/#{portal.slug}/en/articles.json", params: { query: 'funny' }
        expect(Article).to have_received(:vector_search)
      end
    end
  end
end
