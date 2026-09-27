require 'rails_helper'

RSpec.describe 'Giphy Integration API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:search_url) { "/api/v1/accounts/#{account.id}/integrations/giphy/search" }
  let(:giphy_response) do
    {
      data: [{
        id: 'abc123',
        title: 'Thumbs Up GIF',
        images: {
          fixed_width: { url: 'https://media.giphy.com/media/abc123/200w.gif', width: '200', height: '150' },
          downsized: { url: 'https://media.giphy.com/media/abc123/giphy-downsized.gif' }
        }
      }],
      pagination: { total_count: 50, count: 24, offset: 0 }
    }.to_json
  end

  describe 'GET /api/v1/accounts/{account.id}/integrations/giphy/search' do
    it 'returns unauthorized for unauthenticated users' do
      get search_url

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when the installation has no Giphy key' do
      it 'returns unprocessable entity' do
        get search_url, headers: agent.create_new_auth_token, params: { q: 'thanks' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when the installation has a Giphy key' do
      before { create(:installation_config, name: 'GIPHY_API_KEY', value: 'giphy-key') }

      it 'searches Giphy and returns the GIFs with the next offset' do
        stub_request(:get, 'https://api.giphy.com/v1/gifs/search')
          .with(query: { api_key: 'giphy-key', q: 'thanks', limit: 24, offset: 0, rating: 'g' })
          .to_return(status: 200, body: giphy_response, headers: { 'Content-Type' => 'application/json' })

        get search_url, headers: agent.create_new_auth_token, params: { q: 'thanks' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['gifs'].first).to include(
          'id' => 'abc123',
          'preview_url' => 'https://media.giphy.com/media/abc123/200w.gif',
          'url' => 'https://media.giphy.com/media/abc123/giphy-downsized.gif',
          'width' => 200,
          'height' => 150
        )
        expect(response.parsed_body['next_offset']).to eq(24)
      end

      it 'returns trending GIFs when there is no query' do
        stub_request(:get, 'https://api.giphy.com/v1/gifs/trending')
          .with(query: { api_key: 'giphy-key', limit: 24, offset: 0, rating: 'g' })
          .to_return(status: 200, body: giphy_response, headers: { 'Content-Type' => 'application/json' })

        get search_url, headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['gifs'].length).to eq(1)
      end

      it 'returns bad gateway when Giphy fails' do
        stub_request(:get, %r{api.giphy.com/v1/gifs/search}).to_return(status: 429)

        get search_url, headers: agent.create_new_auth_token, params: { q: 'thanks' }

        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end
end
