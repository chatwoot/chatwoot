require 'rails_helper'

describe Whatsapp::HealthService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp,
           account: account,
           provider: 'whatsapp_cloud',
           validate_provider_config: false,
           sync_templates: false)
  end
  let(:service) { described_class.new(channel) }
  let(:api_version) { 'v22.0' }

  let(:health_response) do
    {
      'id' => channel.provider_config['phone_number_id'],
      'display_phone_number' => '+1234567890',
      'verified_name' => 'Test Business',
      'name_status' => 'APPROVED',
      'quality_rating' => 'GREEN',
      'messaging_limit_tier' => 'TIER_1K',
      'account_mode' => 'LIVE',
      'code_verification_status' => 'VERIFIED',
      'throughput' => { 'level' => 'STANDARD' },
      'last_onboarded_time' => '2024-01-01T00:00:00+0000',
      'platform_type' => 'CLOUD_API'
    }
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return(api_version)
  end

  describe '#fetch_health_status' do
    context 'when successful' do
      before do
        phone_number_id = channel.provider_config['phone_number_id']
        access_token = channel.provider_config['api_key']
        stub_request(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}})
          .with(query: hash_including(access_token: access_token))
          .to_return(
            status: 200,
            body: health_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the health status' do
        result = service.fetch_health_status

        expect(result[:display_phone_number]).to eq('+1234567890')
        expect(result[:verified_name]).to eq('Test Business')
        expect(result[:quality_rating]).to eq('GREEN')
      end
    end

    context 'when channel is missing' do
      let(:service) { described_class.new(nil) }

      it 'raises an ArgumentError' do
        expect { service.fetch_health_status }.to raise_error(ArgumentError, 'Channel is required')
      end
    end

    context 'when API key is missing' do
      let(:channel) do
        create(:channel_whatsapp,
               account: account,
               provider: 'whatsapp_cloud',
               validate_provider_config: false,
               sync_templates: false,
               provider_config: {
                 'phone_number_id' => 'test_phone_id',
                 'business_account_id' => 'test_waba_id'
               })
      end

      it 'raises an ArgumentError' do
        expect { service.fetch_health_status }.to raise_error(ArgumentError, 'API key is missing')
      end
    end

    context 'when phone number ID is missing' do
      let(:channel) do
        create(:channel_whatsapp,
               account: account,
               provider: 'whatsapp_cloud',
               validate_provider_config: false,
               sync_templates: false,
               provider_config: {
                 'api_key' => 'test_access_token',
                 'business_account_id' => 'test_waba_id'
               })
      end

      it 'raises an ArgumentError' do
        expect { service.fetch_health_status }.to raise_error(ArgumentError, 'Phone number ID is missing')
      end
    end
  end

  describe 'caching' do
    let(:cache_key) { "whatsapp_health:channel:#{channel.id}" }

    before do
      Rails.cache.clear
      phone_number_id = channel.provider_config['phone_number_id']
      access_token = channel.provider_config['api_key']
      stub_request(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}})
        .with(query: hash_including(access_token: access_token))
        .to_return(
          status: 200,
          body: health_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    context 'when cache is empty' do
      it 'fetches data from the API' do
        service.fetch_health_status

        phone_number_id = channel.provider_config['phone_number_id']
        expect(WebMock).to have_requested(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}}).once
      end

      it 'stores the result in cache' do
        service.fetch_health_status

        expect(Rails.cache.exist?(cache_key)).to be true
      end
    end

    context 'when cache is populated' do
      before do
        # Populate the cache
        service.fetch_health_status
        WebMock.reset_executed_requests!
      end

      it 'returns cached data without making an API call' do
        service.fetch_health_status

        phone_number_id = channel.provider_config['phone_number_id']
        expect(WebMock).not_to have_requested(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}})
      end
    end

    context 'when skip_cache is true' do
      let(:service) { described_class.new(channel, skip_cache: true) }

      before do
        # Populate the cache first
        described_class.new(channel).fetch_health_status
        WebMock.reset_executed_requests!
      end

      it 'bypasses the cache and fetches fresh data' do
        service.fetch_health_status

        phone_number_id = channel.provider_config['phone_number_id']
        expect(WebMock).to have_requested(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}}).once
      end
    end
  end

  describe '.invalidate_cache' do
    let(:cache_key) { "whatsapp_health:channel:#{channel.id}" }

    before do
      Rails.cache.clear
      phone_number_id = channel.provider_config['phone_number_id']
      access_token = channel.provider_config['api_key']
      stub_request(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}})
        .with(query: hash_including(access_token: access_token))
        .to_return(
          status: 200,
          body: health_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Populate the cache
      service.fetch_health_status
    end

    it 'removes the cached data' do
      expect(Rails.cache.exist?(cache_key)).to be true

      described_class.invalidate_cache(channel.id)

      expect(Rails.cache.exist?(cache_key)).to be false
    end
  end

  describe 'API error handling' do
    context 'when the API returns an error' do
      before do
        phone_number_id = channel.provider_config['phone_number_id']
        access_token = channel.provider_config['api_key']
        stub_request(:get, %r{https://graph.facebook.com/#{api_version}/#{phone_number_id}})
          .with(query: hash_including(access_token: access_token))
          .to_return(
            status: 400,
            body: { error: { message: 'Invalid token', code: 190 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error with the API response' do
        expect { service.fetch_health_status }.to raise_error(/WhatsApp API request failed/)
      end
    end
  end
end
