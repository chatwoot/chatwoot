require 'rails_helper'

RSpec.describe 'Influencer profile search', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:discovery_service) { instance_double(InfluencersClub::DiscoveryService) }
  let(:base_filters) do
    {
      ai_search: 'home decor',
      followers: { min: 5000, max: 30_000 },
      location: ['Germany'],
      hashtags: %w[decor interior]
    }
  end
  let(:page_1_response) do
    {
      'accounts' => build_results(1..5),
      'total' => 6,
      'credits_left' => 99.5
    }
  end
  let(:page_2_response) do
    {
      'accounts' => build_results(6..6),
      'total' => 6,
      'credits_left' => 99.49
    }
  end

  before do
    allow(InfluencersClub::DiscoveryService).to receive(:new).and_return(discovery_service)
  end

  def build_results(range)
    range.map do |index|
      {
        'user_id' => index.to_s,
        'profile' => {
          'username' => "creator_#{index}",
          'full_name' => "Creator #{index}",
          'picture' => "https://images.example.com/#{index}.jpg",
          'followers' => 10_000 + index,
          'engagement_percent' => '2.1'
        }
      }
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  describe 'POST /api/v1/accounts/{account.id}/influencer_profiles/search' do
    it 'creates a registry entry and returns the first page from the API on first search' do
      expect(discovery_service).to receive(:perform).once.and_return(page_1_response)

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters,
           headers: headers,
           as: :json

      expect(response).to have_http_status(:success)

      response_body = response.parsed_body
      search = account.influencer_searches.last

      expect(response_body['payload'].pluck('username')).to eq(%w[creator_1 creator_2 creator_3 creator_4 creator_5])
      expect(response_body['meta']).to include(
        'total' => 6,
        'current_page' => 1,
        'per_page' => 5,
        'loaded_count' => 5,
        'total_pages' => 2,
        'cached' => false
      )
      expect(search.query_signature).to be_present
      expect(search.query_params).to include(
        'ai_search' => 'home decor',
        'hashtags' => %w[decor interior],
        'location' => ['Germany']
      )
      expect(search.results.size).to eq(5)
      expect(search.pages_fetched).to eq(1)
    end

    it 'serves repeated searches for the same filters from cache without calling the API again' do
      expect(discovery_service).to receive(:perform).once.and_return(page_1_response)

      2.times do
        post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
             params: base_filters,
             headers: headers,
             as: :json
      end

      response_body = response.parsed_body

      expect(account.influencer_searches.count).to eq(1)
      expect(response_body['meta']).to include(
        'current_page' => 1,
        'cached' => true,
        'imported' => 0
      )
    end

    it 'fetches the next page only when it has not been cached yet' do
      expect(discovery_service).to receive(:perform).twice.and_return(page_1_response, page_2_response)

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters,
           headers: headers,
           as: :json

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters.merge(page: 2),
           headers: headers,
           as: :json

      response_body = response.parsed_body
      search = account.influencer_searches.last

      expect(response_body['payload'].pluck('username')).to eq(['creator_6'])
      expect(response_body['meta']).to include(
        'current_page' => 2,
        'loaded_count' => 6,
        'cached' => false
      )
      expect(search.reload.results.size).to eq(6)
      expect(search.pages_fetched).to eq(2)

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters.merge(page: 2),
           headers: headers,
           as: :json

      response_body = response.parsed_body

      expect(response_body['meta']).to include(
        'current_page' => 2,
        'cached' => true,
        'imported' => 0
      )
    end

    it 'reuses the same registry entry for equivalent filters with different array ordering' do
      expect(discovery_service).to receive(:perform).once.and_return(page_1_response)

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters.merge(location: %w[Germany Poland], hashtags: %w[decor interior]),
           headers: headers,
           as: :json

      post "/api/v1/accounts/#{account.id}/influencer_profiles/search",
           params: base_filters.merge(location: %w[Poland Germany], hashtags: %w[interior decor]),
           headers: headers,
           as: :json

      expect(account.influencer_searches.count).to eq(1)
      expect(response.parsed_body.dig('meta', 'cached')).to be(true)
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
