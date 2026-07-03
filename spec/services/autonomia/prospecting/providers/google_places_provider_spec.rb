require 'rails_helper'

RSpec.describe Autonomia::Prospecting::Providers::GooglePlacesProvider do
  it 'maps Google Places text search results to prospecting lead attributes' do
    stub_request(:post, 'https://places.googleapis.com/v1/places:searchText')
      .to_return(
        status: 200,
        body: {
          places: [
            {
              id: 'places/abc123',
              displayName: { text: 'Alpha Restaurante' },
              formattedAddress: 'Rua das Flores, 123, Sao Paulo - SP, Brasil',
              internationalPhoneNumber: '+55 11 99999-8888',
              websiteUri: 'https://alpha.example.com',
              location: { latitude: -23.55, longitude: -46.63 },
              rating: 4.7,
              userRatingCount: 231,
              types: ['restaurant']
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    results = described_class.new(
      query: 'restaurante',
      location: 'Sao Paulo',
      radius: 5000,
      limit: 1,
      api_key: 'test-key'
    ).search

    expect(results.first).to include(
      provider: 'google_places',
      provider_place_id: 'places/abc123',
      name: 'Alpha Restaurante',
      phone: '+55 11 99999-8888',
      website: 'https://alpha.example.com',
      city: 'Sao Paulo',
      state: 'SP',
      category: 'restaurant'
    )
  end

  it 'raises provider errors with Google message' do
    stub_request(:post, 'https://places.googleapis.com/v1/places:searchText')
      .to_return(status: 403, body: { error: { message: 'API key invalid' } }.to_json)

    provider = described_class.new(query: 'restaurante', location: 'Sao Paulo', radius: 5000, limit: 1, api_key: 'bad-key')

    expect { provider.search }.to raise_error(Autonomia::Prospecting::SearchRunner::ProviderError, /API key invalid/)
  end
end
