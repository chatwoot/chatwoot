require 'rails_helper'

RSpec.describe GiphyService, type: :service do
  let(:service) { described_class.new }

  describe '#initialize' do
    it 'initializes successfully' do
      expect(service).to be_a(GiphyService)
    end
  end

  describe '#search_or_trending' do
    before do
      Rails.cache.clear
    end

    context 'when API key is blank' do
      it 'raises ApiKeyMissingError when no API key is set' do
        allow(ENV).to receive(:fetch).with('GIPHY_API_KEY', nil).and_return(nil)
        service_instance = described_class.new
        
        result = service_instance.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_API_KEY_MISSING')
        expect(result[:message]).to eq('Giphy integration not configured')
        expect(result[:stickers]).to eq([])
      end

      it 'raises ApiKeyMissingError when API key is empty string' do
        allow(ENV).to receive(:fetch).with('GIPHY_API_KEY', nil).and_return('')
        service_instance = described_class.new
        
        result = service_instance.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_API_KEY_MISSING')
      end
    end

    context 'error handling' do
      before do
        allow(ENV).to receive(:fetch).with('GIPHY_API_KEY', nil).and_return('test_key')
      end

      it 'handles rate limit errors' do
        allow(described_class).to receive(:get).and_return(
          double(code: 429, success?: false)
        )

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_RATE_LIMIT')
        expect(result[:message]).to eq('Too many requests to Giphy. Please try again later.')
      end

      it 'handles API unavailable errors' do
        allow(described_class).to receive(:get).and_return(
          double(code: 503, success?: false)
        )

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_UNAVAILABLE')
        expect(result[:message]).to eq('Giphy service is temporarily unavailable. Please try again later.')
      end

      it 'handles invalid API key errors' do
        allow(described_class).to receive(:get).and_return(
          double(code: 401, success?: false)
        )

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_API_KEY_MISSING')
        expect(result[:message]).to eq('Giphy integration not configured')
      end

      it 'handles timeout errors' do
        allow(described_class).to receive(:get).and_raise(Net::OpenTimeout.new('Request timeout'))

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_UNAVAILABLE')
        expect(result[:message]).to eq('Giphy service is temporarily unavailable. Please try again later.')
      end

      it 'handles connection errors' do
        allow(described_class).to receive(:get).and_raise(SocketError.new('Connection failed'))

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_UNAVAILABLE')
      end

      it 'handles invalid JSON responses' do
        allow(described_class).to receive(:get).and_return(
          double(code: 200, success?: true, body: 'invalid json')
        )

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_INVALID_RESPONSE')
        expect(result[:message]).to eq('Unable to load stickers. Please try again.')
      end

      it 'handles responses missing data field' do
        allow(described_class).to receive(:get).and_return(
          double(code: 200, success?: true, body: '{"meta": {}}')
        )

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_INVALID_RESPONSE')
      end

      it 'handles unexpected errors' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Unexpected error'))

        result = service.search_or_trending

        expect(result).to be_a(Hash)
        expect(result[:error]).to eq('GIPHY_UNKNOWN_ERROR')
        expect(result[:message]).to eq('Unable to load stickers. Please try again.')
      end

      it 'logs errors appropriately' do
        allow(described_class).to receive(:get).and_raise(Net::OpenTimeout.new('Request timeout'))
        expect(Rails.logger).to receive(:error).with(/GiphyService API unavailable/)

        service.search_or_trending
      end

      it 'increments error metrics' do
        allow(described_class).to receive(:get).and_raise(Net::OpenTimeout.new('Request timeout'))

        service.search_or_trending

        expect(Rails.cache.read('giphy_cache_api_unavailable')).to eq(1)
      end
    end

    context 'when API key is present' do
      it 'uses caching for requests' do
        # Test that the method uses Rails cache with proper TTL
        expect(Rails.cache).to receive(:fetch)
          .with(anything, expires_in: described_class::CACHE_TTL)
          .and_return([])

        service.search_or_trending
      end

      it 'generates consistent cache keys' do
        key1 = service.send(:generate_cache_key, 'test')
        key2 = service.send(:generate_cache_key, 'test')
        expect(key1).to eq(key2)
      end

      it 'normalizes cache keys for case-insensitive queries' do
        key1 = service.send(:generate_cache_key, 'Test Query')
        key2 = service.send(:generate_cache_key, 'test query')
        expect(key1).to eq(key2)
      end

      it 'tracks cache hits and misses' do
        allow(described_class).to receive(:get).and_return(
          double(success?: true, body: { 'data' => [] }.to_json)
        )

        # First call should be a miss
        service.search_or_trending('test')
        expect(Rails.cache.read('giphy_cache_miss')).to eq(1)

        # Second call should be a hit
        service.search_or_trending('test')
        expect(Rails.cache.read('giphy_cache_hit')).to eq(1)
      end

      it 'tracks cache errors' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
        expect(Rails.logger).to receive(:error).with('GiphyService error: Cache error')

        service.search_or_trending('test')
        expect(Rails.cache.read('giphy_cache_error')).to eq(1)
      end

      it 'handles exceptions gracefully' do
        # Mock the cache to raise an exception
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
        expect(Rails.logger).to receive(:error).with('GiphyService error: Cache error')

        result = service.search_or_trending

        expect(result).to eq([])
      end
    end

    describe 'response parsing' do
      let(:service_instance) { described_class.new }

      it 'parses valid Giphy response correctly' do
        valid_data = {
          'data' => [
            {
              'id' => 'test_id',
              'title' => 'Test Sticker',
              'images' => {
                'fixed_height' => {
                  'webp' => 'https://media.giphy.com/test.webp'
                }
              }
            }
          ]
        }

        response = double('response', success?: true, body: valid_data.to_json)
        parsed_result = service_instance.send(:parse_giphy_response, response)

        expect(parsed_result.length).to eq(1)
        expect(parsed_result.first[:id]).to eq('test_id')
        expect(parsed_result.first[:url]).to eq('https://media.giphy.com/test.webp')
        expect(parsed_result.first[:alt]).to eq('Test Sticker')
        expect(parsed_result.first[:provider]).to eq('giphy')
      end

      it 'handles missing webp URLs' do
        invalid_data = {
          'data' => [
            {
              'id' => 'test_id',
              'title' => 'Test Sticker',
              'images' => {
                'fixed_height' => {}
              }
            }
          ]
        }

        response = double('response', success?: true, body: invalid_data.to_json)
        parsed_result = service_instance.send(:parse_giphy_response, response)

        expect(parsed_result).to eq([])
      end

      it 'handles missing titles with default alt text' do
        no_title_data = {
          'data' => [
            {
              'id' => 'test_id',
              'title' => nil,
              'images' => {
                'fixed_height' => {
                  'webp' => 'https://media.giphy.com/test.webp'
                }
              }
            }
          ]
        }

        response = double('response', success?: true, body: no_title_data.to_json)
        parsed_result = service_instance.send(:parse_giphy_response, response)

        expect(parsed_result.first[:alt]).to eq('Giphy Sticker')
      end

      it 'handles failed responses' do
        response = double('response', success?: false)
        parsed_result = service_instance.send(:parse_giphy_response, response)

        expect(parsed_result).to eq([])
      end

      it 'handles JSON parsing errors' do
        response = double('response', success?: true, body: 'invalid json')
        expect(Rails.logger).to receive(:error).with(/GiphyService JSON parsing error/)

        parsed_result = service_instance.send(:parse_giphy_response, response)

        expect(parsed_result).to eq([])
      end
    end
  end

  describe '#invalidate_cache' do
    before do
      Rails.cache.clear
      allow(described_class).to receive(:get).and_return(
        double(success?: true, body: { 'data' => [] }.to_json)
      )
    end

    it 'removes cached data for specific query' do
      # Cache some data
      service.search_or_trending('test')
      cache_key = service.send(:generate_cache_key, 'test')
      expect(Rails.cache.exist?(cache_key)).to be true

      # Invalidate cache
      service.invalidate_cache('test')
      expect(Rails.cache.exist?(cache_key)).to be false
    end

    it 'removes trending cache when no query provided' do
      # Cache trending data
      service.search_or_trending
      cache_key = service.send(:generate_cache_key, nil)
      expect(Rails.cache.exist?(cache_key)).to be true

      # Invalidate trending cache
      service.invalidate_cache
      expect(Rails.cache.exist?(cache_key)).to be false
    end
  end

  describe '#warm_cache' do
    it 'pre-loads trending and popular search terms' do
      expect(service).to receive(:search_or_trending).with(nil).once
      expect(service).to receive(:search_or_trending).with('happy').once
      expect(service).to receive(:search_or_trending).with('sad').once
      expect(service).to receive(:search_or_trending).with('love').once
      expect(service).to receive(:search_or_trending).with('funny').once
      expect(service).to receive(:search_or_trending).with('cute').once
      expect(service).to receive(:search_or_trending).with('animals').once

      service.warm_cache
    end
  end
end