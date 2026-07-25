require 'rails_helper'

RSpec.describe Whatsapp::HealthService do
  subject(:service) { described_class.new(channel) }

  let(:provider_config) do
    {
      'api_key' => 'test_access_token',
      'phone_number_id' => 'test_phone_number_id',
      'business_account_id' => 'test_waba_id',
      'source' => 'embedded_signup'
    }
  end
  let(:previous_health) { {} }
  let(:channel) do
    create(
      :channel_whatsapp,
      phone_number: '+15550001111',
      provider: 'whatsapp_cloud',
      sync_templates: false,
      validate_provider_config: false
    ).tap do |record|
      record.provider_config = provider_config
      record.phone_number_health = previous_health
      record.save!
    end
  end
  let(:phone_health_response) do
    {
      'id' => 'test_phone_number_id',
      'display_phone_number' => '+1 555-000-1111',
      'verified_name' => 'Example Store',
      'name_status' => 'APPROVED',
      'quality_rating' => 'GREEN',
      'whatsapp_business_manager_messaging_limit' => 'TIER_250',
      'status' => 'CONNECTED',
      'account_mode' => 'LIVE',
      'code_verification_status' => 'VERIFIED',
      'webhook_configuration' => {
        'phone_number' => 'https://example.test/webhooks/whatsapp/+15550001111',
        'application' => 'https://example.test/webhooks/whatsapp/+15550001111'
      },
      'throughput' => { 'level' => 'STANDARD' },
      'last_onboarded_time' => '2026-07-01T08:30:00+0000',
      'is_on_biz_app' => true,
      'platform_type' => 'CLOUD_API'
    }
  end
  let(:business_account_response) do
    {
      'id' => 'test_waba_id',
      'name' => 'Example WABA',
      'owner_business_info' => {
        'id' => 'test_business_portfolio_id',
        'name' => 'Example Business Portfolio'
      }
    }
  end

  before do
    stub_request(:get, %r{graph\.facebook\.com/v24\.0/test_phone_number_id})
      .to_return(status: 200, body: phone_health_response.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, %r{graph\.facebook\.com/v24\.0/test_waba_id})
      .to_return(status: 200, body: business_account_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#fetch_health_status' do
    it 'fetches and formats phone, WABA, portfolio, webhook, and coexistence health' do
      result = nil

      with_modified_env FRONTEND_URL: 'https://example.test' do
        result = service.fetch_health_status
      end

      expect(result).to include(
        id: 'test_phone_number_id',
        display_phone_number: '+1 555-000-1111',
        verified_name: 'Example Store',
        quality_rating: 'GREEN',
        messaging_limit_tier: 'TIER_250',
        status: 'CONNECTED',
        throughput: { 'level' => 'STANDARD' },
        throughput_level: 'STANDARD',
        is_on_biz_app: true,
        platform_type: 'CLOUD_API',
        business_account_id: 'test_waba_id',
        business_account_name: 'Example WABA',
        business_portfolio_id: 'test_business_portfolio_id',
        business_portfolio_name: 'Example Business Portfolio',
        expected_webhook_url: 'https://example.test/webhooks/whatsapp/+15550001111'
      )
    end

    it 'requests the current messaging capacity field with the minimum supported API version' do
      service.fetch_health_status

      expect(
        a_request(:get, %r{graph\.facebook\.com/v24\.0/test_phone_number_id}).with do |request|
          fields = CGI.parse(request.uri.query)['fields']&.first.to_s.split(',')
          fields.include?('whatsapp_business_manager_messaging_limit') && fields.exclude?('messaging_limit_tier')
        end
      ).to have_been_made.once
    end

    it 'uses a newer configured API version' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return('v25.0')
      stub_request(:get, %r{graph\.facebook\.com/v25\.0/test_phone_number_id})
        .to_return(status: 200, body: phone_health_response.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r{graph\.facebook\.com/v25\.0/test_waba_id})
        .to_return(status: 200, body: business_account_response.to_json, headers: { 'Content-Type' => 'application/json' })

      service.fetch_health_status

      expect(a_request(:get, %r{graph\.facebook\.com/v25\.0/test_phone_number_id})).to have_been_made.once
    end
  end

  describe '#sync_health_status!' do
    it 'persists the latest successful snapshot and clears an earlier error' do
      channel.phone_number_health_error = 'Previous failure'
      channel.save!

      travel_to(Time.zone.parse('2026-07-21 10:00:00')) do
        result = service.sync_health_status!
        channel.reload

        expect(result[:health_checked_at]).to eq(Time.current)
        expect(channel.phone_number_health).to include(
          'quality_rating' => 'GREEN',
          'messaging_limit_tier' => 'TIER_250',
          'throughput_level' => 'STANDARD',
          'is_on_biz_app' => true,
          'platform_type' => 'CLOUD_API',
          'business_account_id' => 'test_waba_id',
          'business_portfolio_id' => 'test_business_portfolio_id'
        )
        expect(channel.phone_number_health).not_to have_key('webhook_configuration')
        expect(channel.phone_number_health_checked_at).to eq(Time.current)
        expect(channel.phone_number_health_error).to be_nil
      end
    end

    context 'when Meta rejects the access token' do
      let(:previous_health) { { quality_rating: 'GREEN', status: 'CONNECTED' } }

      before do
        stub_request(:get, %r{graph\.facebook\.com/v24\.0/test_phone_number_id})
          .to_return(
            status: 400,
            body: {
              error: {
                message: 'The access token cannot authorize this request.',
                type: 'OAuthException',
                code: 190,
                error_subcode: 464
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a structured authorization error' do
        expect { service.sync_health_status! }.to raise_error(described_class::ApiError) do |error|
          expect(error.http_status).to eq(400)
          expect(error.code).to eq(190)
          expect(error.subcode).to eq(464)
          expect(error).to be_authorization_error
        end
      end

      it 'preserves the successful snapshot and records the failed attempt' do
        travel_to(Time.zone.parse('2026-07-21 11:00:00')) do
          expect { service.sync_health_status! }.to raise_error(described_class::ApiError)
          channel.reload
          expect(channel.phone_number_health).to eq('quality_rating' => 'GREEN', 'status' => 'CONNECTED')
          expect(channel.phone_number_health_checked_at).to eq(Time.current)
          expect(channel.phone_number_health_error).to eq('The access token cannot authorize this request.')
        end
      end
    end

    context 'when a newer health check finishes first' do
      let(:previous_health) { { quality_rating: 'GREEN', status: 'CONNECTED' } }
      let(:newer_health) { { quality_rating: 'GREEN', status: 'CONNECTED' } }
      let(:phone_health_response) { super().merge('quality_rating' => 'YELLOW') }

      it 'does not overwrite the newer successful snapshot' do
        attempted_at = Time.zone.parse('2026-07-21 12:00:00')
        newer_attempted_at = attempted_at + 1.minute
        expect(Rails.logger).not_to receive(:warn)
        stub_request(:get, %r{graph\.facebook\.com/v24\.0/test_phone_number_id}).to_return do
          channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
            phone_number_health: newer_health,
            phone_number_health_checked_at: newer_attempted_at,
            phone_number_health_error: nil
          )
          { status: 200, body: phone_health_response.to_json, headers: { 'Content-Type' => 'application/json' } }
        end

        travel_to(attempted_at) { service.sync_health_status! }
        channel.reload

        expect(channel.phone_number_health).to eq('quality_rating' => 'GREEN', 'status' => 'CONNECTED')
        expect(channel.phone_number_health_checked_at).to eq(newer_attempted_at)
        expect(channel.phone_number_health_error).to be_nil
      end

      it 'does not replace the newer successful snapshot with an older error' do
        attempted_at = Time.zone.parse('2026-07-21 12:00:00')
        newer_attempted_at = attempted_at + 1.minute
        stub_request(:get, %r{graph\.facebook\.com/v24\.0/test_phone_number_id}).to_return do
          channel.update_columns( # rubocop:disable Rails/SkipsModelValidations
            phone_number_health: newer_health,
            phone_number_health_checked_at: newer_attempted_at,
            phone_number_health_error: nil
          )
          {
            status: 400,
            body: { error: { message: 'Older request failed' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        end

        travel_to(attempted_at) do
          expect { service.sync_health_status! }.to raise_error(described_class::ApiError, 'Older request failed')
        end
        channel.reload

        expect(channel.phone_number_health).to eq('quality_rating' => 'GREEN', 'status' => 'CONNECTED')
        expect(channel.phone_number_health_checked_at).to eq(newer_attempted_at)
        expect(channel.phone_number_health_error).to be_nil
      end
    end

    context 'when health first becomes risky' do
      let(:previous_health) { { quality_rating: 'GREEN', status: 'CONNECTED', messaging_limit_tier: 'TIER_250' } }
      let(:phone_health_response) { super().merge('quality_rating' => 'YELLOW') }

      it 'logs the risky transition once it is persisted' do
        expect(Rails.logger).to receive(:warn).with(/risky_phone_number.*quality_rating=YELLOW/)

        service.sync_health_status!
      end
    end

    context 'when only messaging capacity changes for an already risky number' do
      let(:previous_health) { { quality_rating: 'YELLOW', status: 'CONNECTED', messaging_limit_tier: 'TIER_250' } }
      let(:phone_health_response) do
        super().merge(
          'quality_rating' => 'YELLOW',
          'whatsapp_business_manager_messaging_limit' => 'TIER_2K'
        )
      end

      it 'does not log another risky transition' do
        expect(Rails.logger).not_to receive(:warn)

        service.sync_health_status!
      end
    end
  end
end
