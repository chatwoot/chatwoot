require 'rails_helper'

RSpec.describe Whatsapp::WebhookUrlService do
  # Stub HTTP requests made during WhatsApp channel creation/validation for different providers
  subject(:service) { described_class.new }

  before do
    # 360Dialog provider requests
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: '{"waba_templates": []}', headers: { 'Content-Type' => 'application/json' })

    # WHAPI provider requests
    stub_request(:get, 'https://gate.whapi.cloud/health')
      .to_return(status: 200, body: '{"status": "ok"}', headers: { 'Content-Type' => 'application/json' })

    # WhatsApp Cloud provider requests (Facebook Graph API)
    stub_request(:get, %r{graph\.facebook\.com.*/message_templates})
      .to_return(status: 200, body: '{"data": []}', headers: { 'Content-Type' => 'application/json' })
  end

  let(:phone_number) { '+1234567890' }
  let(:frontend_url) { 'https://test.app.chatscommerce.com' }

  # Helper method to stub ENV more safely
  def stub_env_variables(frontend_url: nil, local_tunnel: nil)
    # Allow all other ENV access to work normally
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original

    # Stub both variables using ENV.fetch (matching what the service actually calls)
    allow(ENV).to receive(:fetch).with('LOCAL_URL_TUNNEL', nil).and_return(local_tunnel)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return(frontend_url)
  end

  describe '#generate_webhook_url' do
    context 'when using FRONTEND_URL' do
      before do
        stub_env_variables(frontend_url: frontend_url, local_tunnel: nil)
      end

      context 'with phone number' do
        it 'generates correct webhook URL' do
          result = service.generate_webhook_url(phone_number: phone_number)
          expect(result).to eq("#{frontend_url}/webhooks/whatsapp/#{phone_number}")
        end

        it 'follows the same pattern as Inbox#callback_webhook_url' do
          # Create a WhatsApp inbox to compare with
          account = create(:account)
          channel = build(:channel_whatsapp, account: account, phone_number: phone_number, validate_provider_config: false, sync_templates: false)
          allow(channel).to receive(:sync_templates)
          channel.save!(validate: false)
          inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
          inbox.save!(validate: false)

          service_url = service.generate_webhook_url(phone_number: phone_number)
          inbox_url = inbox.callback_webhook_url

          # Both should generate URLs with the same structure
          expect(service_url).to include('/webhooks/whatsapp/')
          expect(inbox_url).to include('/webhooks/whatsapp/')
          expect(service_url).to include(phone_number)
          expect(inbox_url).to include(phone_number)
        end

        it 'works correctly with WHAPI provider channels' do
          # Create a WHAPI channel specifically
          account = create(:account)
          channel = build(:channel_whatsapp,
                           account: account,
                           phone_number: phone_number,
                           provider: 'whapi',
                           provider_config: {
                             'api_key' => 'test_whapi_token',
                             'whapi_channel_id' => 'test_channel_id'
                           },
                           validate_provider_config: false,
                           sync_templates: false)
          allow(channel).to receive(:sync_templates)
          channel.save!(validate: false)
          inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
          inbox.save!(validate: false)

          service_url = service.generate_webhook_url(phone_number: phone_number)
          inbox_url = inbox.callback_webhook_url

          # URLs should match for WHAPI channels too
          expect(service_url).to eq("#{frontend_url}/webhooks/whatsapp/#{phone_number}")
          expect(inbox_url).to include('/webhooks/whatsapp/')
          expect(inbox_url).to include(phone_number)
        end
      end

      context 'without phone number' do
        it 'generates correct WHAPI endpoint URL' do
          result = service.generate_webhook_url
          expect(result).to eq("#{frontend_url}/webhooks/whapi")
        end
      end

      context 'with blank phone number' do
        it 'generates WHAPI endpoint URL' do
          result = service.generate_webhook_url(phone_number: '')
          expect(result).to eq("#{frontend_url}/webhooks/whapi")
        end
      end
    end

    context 'when using LOCAL_URL_TUNNEL override' do
      let(:tunnel_url) { 'https://abc123.ngrok-free.app' }

      before do
        stub_env_variables(frontend_url: frontend_url, local_tunnel: tunnel_url)
      end

      it 'prioritizes LOCAL_URL_TUNNEL over FRONTEND_URL' do
        result = service.generate_webhook_url(phone_number: phone_number)
        expect(result).to eq("#{tunnel_url}/webhooks/whatsapp/#{phone_number}")
        expect(result).not_to include(frontend_url)
      end

      context 'with tunnel URL without protocol' do
        before do
          stub_env_variables(frontend_url: frontend_url, local_tunnel: 'abc123.ngrok-free.app')
        end

        it 'adds https protocol automatically' do
          result = service.generate_webhook_url(phone_number: phone_number)
          expect(result).to eq("https://abc123.ngrok-free.app/webhooks/whatsapp/#{phone_number}")
        end
      end

      context 'with tunnel URL with http protocol' do
        before do
          stub_env_variables(frontend_url: frontend_url, local_tunnel: 'http://abc123.ngrok-free.app')
        end

        it 'preserves existing protocol' do
          result = service.generate_webhook_url(phone_number: phone_number)
          expect(result).to eq("http://abc123.ngrok-free.app/webhooks/whatsapp/#{phone_number}")
        end
      end
    end

    context 'when environment variables are missing' do
      before do
        stub_env_variables(frontend_url: nil, local_tunnel: nil)
      end

      it 'raises an error with clear message' do
        expect { service.generate_webhook_url(phone_number: phone_number) }
          .to raise_error(ArgumentError, 'FRONTEND_URL environment variable must be set')
      end
    end
  end

  describe '#should_update_webhook_url?' do
    let(:current_url) { "#{frontend_url}/webhooks/whapi" }

    before do
      stub_env_variables(frontend_url: frontend_url, local_tunnel: nil)
    end

    context 'when phone number is provided' do
      it 'returns true if URL needs update' do
        result = service.should_update_webhook_url?(current_url, phone_number)
        expect(result).to be(true)
      end

      it 'returns false if URL is already correct' do
        correct_url = "#{frontend_url}/webhooks/whatsapp/#{phone_number}"
        result = service.should_update_webhook_url?(correct_url, phone_number)
        expect(result).to be(false)
      end
    end

    context 'when phone number is blank' do
      it 'returns false' do
        result = service.should_update_webhook_url?(current_url, nil)
        expect(result).to be(false)

        result = service.should_update_webhook_url?(current_url, '')
        expect(result).to be(false)
      end
    end
  end

  describe 'webhook path consistency' do
    # This test ensures that if webhook paths change in the app,
    # this service needs to be updated too
    context 'when comparing with routes.rb patterns' do
      it 'generates paths that match existing route patterns' do
        # Test with phone number - should match: post 'webhooks/whatsapp/:phone_number'
        url_with_phone = service.send(:determine_webhook_path, phone_number: phone_number)
        expect(url_with_phone).to eq("/webhooks/whatsapp/#{phone_number}")

        # Test without phone number - should match: post 'webhooks/whapi'
        url_without_phone = service.send(:determine_webhook_path, phone_number: nil)
        expect(url_without_phone).to eq('/webhooks/whapi')
      end
    end

    context 'when comparing with Inbox model patterns' do
      before do
        stub_env_variables(frontend_url: frontend_url, local_tunnel: nil)
      end

      it 'generates URLs with same base structure as Inbox#callback_webhook_url' do
        # Create test data
        account = create(:account)
        channel = build(:channel_whatsapp, account: account, phone_number: phone_number, validate_provider_config: false, sync_templates: false)
        allow(channel).to receive(:sync_templates)
        channel.save!(validate: false)
        inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
        inbox.save!(validate: false)

        # Generate URLs
        service_url = service.generate_webhook_url(phone_number: phone_number)
        inbox_url = inbox.callback_webhook_url

        # Parse URLs to compare structure
        service_uri = URI.parse(service_url)
        inbox_uri = URI.parse(inbox_url)

        # Should have same path pattern
        expect(service_uri.path).to eq(inbox_uri.path)
        expect(service_uri.path).to include('/webhooks/whatsapp/')
        expect(service_uri.path).to include(phone_number)
      end

      it 'generates URLs with same structure for WHAPI channels' do
        # Create WHAPI channel specifically to test provider independence
        account = create(:account)
        channel = build(:channel_whatsapp,
                         account: account,
                         phone_number: phone_number,
                         provider: 'whapi',
                         provider_config: {
                           'api_key' => 'test_whapi_token',
                           'whapi_channel_id' => 'test_channel_id'
                         },
                         validate_provider_config: false,
                         sync_templates: false)
        allow(channel).to receive(:sync_templates)
        channel.save!(validate: false)
        inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
        inbox.save!(validate: false)

        # Generate URLs
        service_url = service.generate_webhook_url(phone_number: phone_number)
        inbox_url = inbox.callback_webhook_url

        # Parse URLs to compare structure
        service_uri = URI.parse(service_url)
        inbox_uri = URI.parse(inbox_url)

        # Should have same path pattern regardless of provider
        expect(service_uri.path).to eq(inbox_uri.path)
        expect(service_uri.path).to include('/webhooks/whatsapp/')
        expect(service_uri.path).to include(phone_number)
      end
    end
  end

  describe 'regression protection' do
    # These tests help catch breaking changes to webhook URL patterns
    let(:expected_patterns) do
      {
        with_phone: "/webhooks/whatsapp/#{phone_number}",
        without_phone: '/webhooks/whapi'
      }
    end

    before do
      stub_env_variables(frontend_url: frontend_url, local_tunnel: nil)
    end

    it 'maintains expected URL patterns' do
      # If these tests fail, it means webhook URL patterns have changed
      # and may break existing integrations

      url_with_phone = service.generate_webhook_url(phone_number: phone_number)
      expect(url_with_phone).to eq("#{frontend_url}#{expected_patterns[:with_phone]}")

      url_without_phone = service.generate_webhook_url
      expect(url_without_phone).to eq("#{frontend_url}#{expected_patterns[:without_phone]}")
    end

    it 'generates URLs that end with expected patterns' do
      url_with_phone = service.generate_webhook_url(phone_number: phone_number)
      expect(url_with_phone).to end_with(expected_patterns[:with_phone])

      url_without_phone = service.generate_webhook_url
      expect(url_without_phone).to end_with(expected_patterns[:without_phone])
    end
  end

  describe 'environment configuration scenarios' do
    # Test different environment setups that teams might use

    context 'development environment with custom domain' do
      let(:dev_url) { 'https://dev.app.chatscommerce.com' }

      before do
        stub_env_variables(frontend_url: dev_url, local_tunnel: nil)
      end

      it 'generates correct development URLs' do
        result = service.generate_webhook_url(phone_number: phone_number)
        expect(result).to eq("#{dev_url}/webhooks/whatsapp/#{phone_number}")
      end
    end

    context 'production environment with custom domain' do
      let(:prod_url) { 'https://prod.app.chatscommerce.com' }

      before do
        stub_env_variables(frontend_url: prod_url, local_tunnel: nil)
      end

      it 'generates correct production URLs' do
        result = service.generate_webhook_url(phone_number: phone_number)
        expect(result).to eq("#{prod_url}/webhooks/whatsapp/#{phone_number}")
      end
    end

    context 'local development with ngrok tunnel' do
      let(:ngrok_url) { 'https://xyz789.ngrok-free.app' }

      before do
        stub_env_variables(frontend_url: frontend_url, local_tunnel: ngrok_url)
      end

      it 'prioritizes tunnel URL for local development' do
        result = service.generate_webhook_url(phone_number: phone_number)
        expect(result).to start_with(ngrok_url)
        expect(result).not_to include(frontend_url)
      end
    end
  end

  describe 'provider compatibility' do
    # Test that webhook URL generation works with different WhatsApp providers
    before do
      stub_env_variables(frontend_url: frontend_url, local_tunnel: nil)
    end

    context 'with 360Dialog provider (default)' do
      it 'generates correct URLs for default provider channels' do
        account = create(:account)
        channel = build(:channel_whatsapp,
                         account: account,
                         phone_number: phone_number,
                         provider: 'default',
                         validate_provider_config: false,
                         sync_templates: false)
        allow(channel).to receive(:sync_templates)
        channel.save!(validate: false)
        inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
        inbox.save!(validate: false)

        service_url = service.generate_webhook_url(phone_number: phone_number)
        expect(service_url).to eq("#{frontend_url}/webhooks/whatsapp/#{phone_number}")
        expect(inbox.callback_webhook_url).to include('/webhooks/whatsapp/')
      end
    end

    context 'with WHAPI provider' do
      it 'generates correct URLs for WHAPI provider channels' do
        account = create(:account)
        channel = build(:channel_whatsapp,
                         account: account,
                         phone_number: phone_number,
                         provider: 'whapi',
                         provider_config: {
                           'api_key' => 'test_whapi_token',
                           'whapi_channel_id' => 'test_channel_id',
                           'connection_status' => 'connected'
                         },
                         validate_provider_config: false,
                         sync_templates: false)
        allow(channel).to receive(:sync_templates)
        channel.save!(validate: false)
        inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
        inbox.save!(validate: false)

        service_url = service.generate_webhook_url(phone_number: phone_number)
        expect(service_url).to eq("#{frontend_url}/webhooks/whatsapp/#{phone_number}")
        expect(inbox.callback_webhook_url).to include('/webhooks/whatsapp/')
      end
    end

    context 'with WhatsApp Cloud provider' do
      it 'generates correct URLs for WhatsApp Cloud provider channels' do
        account = create(:account)
        channel = build(:channel_whatsapp,
                         account: account,
                         phone_number: phone_number,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'api_key' => 'test_cloud_token',
                           'phone_number_id' => 'test_phone_id'
                         },
                         validate_provider_config: false,
                         sync_templates: false)
        allow(channel).to receive(:sync_templates)
        channel.save!(validate: false)
        inbox = Inbox.new(name: 'Test Inbox', account: account, channel: channel)
        inbox.save!(validate: false)

        service_url = service.generate_webhook_url(phone_number: phone_number)
        expect(service_url).to eq("#{frontend_url}/webhooks/whatsapp/#{phone_number}")
        expect(inbox.callback_webhook_url).to include('/webhooks/whatsapp/')
      end
    end
  end
end
