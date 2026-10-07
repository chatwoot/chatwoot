require 'rails_helper'

describe Whatsapp::WebhookSetupService do
  # Created with source: 'embedded_signup' so the model's after_commit auto-setup callback
  # (which would race with this spec's explicit `service.perform` calls) stays skipped, then
  # mutated in-memory to a manual (non-embedded) channel — the object under test never persists
  # this change, it just needs WebhookSetupService to see a non-embedded_signup source.
  let(:channel) do
    whatsapp_channel = create(:channel_whatsapp,
                              phone_number: '+1234567890',
                              provider_config: {
                                'phone_number_id' => '123456789',
                                'webhook_verify_token' => 'test_verify_token',
                                'source' => 'embedded_signup'
                              },
                              provider: 'whatsapp_cloud',
                              sync_templates: false,
                              validate_provider_config: false)
    whatsapp_channel.provider_config = whatsapp_channel.provider_config.merge('source' => 'manual')
    whatsapp_channel
  end
  let(:waba_id) { 'test_waba_id' }
  let(:access_token) { 'test_access_token' }
  let(:service) { described_class.new(channel, waba_id, access_token) }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }
  let(:health_service) { instance_double(Whatsapp::HealthService) }

  before do
    # Stub webhook teardown to prevent HTTP calls during cleanup
    stub_request(:delete, /graph.facebook.com/).to_return(status: 200, body: '{}', headers: {})

    # Clean up any existing channels to avoid phone number conflicts
    Channel::Whatsapp.destroy_all
    allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
    allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)

    # Default stubs for phone_number_verified? and health service
    allow(api_client).to receive(:phone_number_verified?).and_return(false)
    allow(health_service).to receive(:fetch_health_status).and_return({
                                                                        platform_type: 'APPLICABLE',
                                                                        throughput_level: 'APPLICABLE'
                                                                      })
  end

  describe '#perform' do
    context 'when phone number is NOT verified (should register)' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).with('123456789', 223_456)
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers the phone number and sets up webhook' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service.perform
        end
      end
    end

    context 'when the frontend signals a coexistence finish event (should NOT register)' do
      let(:embedded_channel) do
        create(:channel_whatsapp,
               phone_number: '+1234567891',
               provider_config: {
                 'phone_number_id' => '123456789',
                 'webhook_verify_token' => 'test_verify_token',
                 'source' => 'embedded_signup'
               },
               provider: 'whatsapp_cloud',
               sync_templates: false,
               validate_provider_config: false)
      end
      let(:embedded_service) { described_class.new(embedded_channel, waba_id, access_token, is_coexistence: true) }

      before do
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
      end

      it 'skips the health check entirely and does not register the phone number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(health_service).not_to receive(:fetch_health_status)
          expect(api_client).not_to receive(:phone_number_verified?)
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567891', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          embedded_service.perform
        end
      end
    end

    context 'when health data still reports is_on_biz_app without an explicit coexistence flag (fallback path, should NOT register)' do
      let(:embedded_channel) do
        create(:channel_whatsapp,
               phone_number: '+1234567891',
               provider_config: {
                 'phone_number_id' => '123456789',
                 'webhook_verify_token' => 'test_verify_token',
                 'source' => 'embedded_signup'
               },
               provider: 'whatsapp_cloud',
               sync_templates: false,
               validate_provider_config: false)
      end
      let(:embedded_service) { described_class.new(embedded_channel, waba_id, access_token) }

      before do
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            is_on_biz_app: true,
                                                                            platform_type: 'CLOUD_API'
                                                                          })
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
      end

      it 'does not check verification and does not register the phone number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:phone_number_verified?)
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567891', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          embedded_service.perform
        end
      end
    end

    context 'when channel is embedded signup sourced but NOT coexisting (should still register if unverified/pending)' do
      let(:embedded_channel) do
        create(:channel_whatsapp,
               phone_number: '+1234567891',
               provider_config: {
                 'phone_number_id' => '123456789',
                 'webhook_verify_token' => 'test_verify_token',
                 'source' => 'embedded_signup'
               },
               provider: 'whatsapp_cloud',
               sync_templates: false,
               validate_provider_config: false)
      end
      let(:embedded_service) { described_class.new(embedded_channel, waba_id, access_token) }

      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            is_on_biz_app: false,
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).with('123456789', 223_456)
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
        allow(embedded_channel).to receive(:save!)
      end

      it 'registers the phone number like any other unverified number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567891', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          embedded_service.perform
        end
      end
    end

    context 'when phone number IS verified AND fully provisioned (should NOT register)' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
      end

      it 'does NOT register phone, but sets up webhook' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service.perform
        end
      end
    end

    context 'when phone number IS verified BUT needs registration (pending provisioning)' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'NOT_APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).with('123456789', 223_456)
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers the phone number due to pending provisioning state' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service.perform
        end
      end
    end

    context 'when phone number needs registration due to throughput level' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'NOT_APPLICABLE'
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).with('123456789', 223_456)
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers the phone number due to throughput not applicable' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'test_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service.perform
        end
      end
    end

    context 'when phone_number_verified? raises error' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_raise('API down')
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'tries to register phone (due to verification error) and proceeds with webhook setup' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
          expect { service.perform }.not_to raise_error
        end
      end
    end

    context 'when health service raises error' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_raise('Health API down')
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
      end

      it 'does not register phone (conservative approach) and proceeds with webhook setup' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
          expect { service.perform }.not_to raise_error
        end
      end
    end

    context 'when phone registration fails (not blocking)' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).and_raise('Registration failed')
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'continues with webhook setup even if registration fails' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
          expect { service.perform }.not_to raise_error
        end
      end
    end

    context 'when webhook setup fails (should raise)' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_raise('Webhook failed')
      end

      it 'raises an error' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
          expect { service.perform }.to raise_error(/Webhook setup failed/)
        end
      end
    end

    context 'when required parameters are missing' do
      it 'raises error when channel is nil' do
        service_invalid = described_class.new(nil, waba_id, access_token)
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'Channel is required')
      end

      it 'raises error when waba_id is blank' do
        service_invalid = described_class.new(channel, '', access_token)
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'WABA ID is required')
      end

      it 'raises error when access_token is blank' do
        service_invalid = described_class.new(channel, waba_id, '')
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'Access token is required')
      end
    end

    context 'when PIN already exists' do
      before do
        channel.provider_config['verification_pin'] = 123_456
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'reuses existing PIN' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 123_456)
          expect(SecureRandom).not_to receive(:random_number)
          service.perform
        end
      end
    end

    context 'when webhook setup fails and should trigger reauthorization' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_raise('Invalid access token')
      end

      it 'raises error with webhook setup failure message' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect { service.perform }.to raise_error(/Webhook setup failed: Invalid access token/)
        end
      end

      it 'logs the webhook setup failure' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(Rails.logger).to receive(:error).with('[WHATSAPP] Webhook setup failed: Invalid access token')
          expect { service.perform }.to raise_error(/Webhook setup failed/)
        end
      end
    end

    context 'when used during reauthorization flow' do
      let(:existing_channel) do
        create(:channel_whatsapp,
               phone_number: '+1234567890',
               provider_config: {
                 'phone_number_id' => '123456789',
                 'webhook_verify_token' => 'existing_verify_token',
                 'business_id' => 'existing_business_id',
                 'waba_id' => 'existing_waba_id',
                 'source' => 'embedded_signup'
               },
               provider: 'whatsapp_cloud',
               sync_templates: false,
               validate_provider_config: false)
      end
      let(:new_access_token) { 'new_access_token' }
      let(:service_reauth) { described_class.new(existing_channel, waba_id, new_access_token) }

      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'existing_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
      end

      it 'successfully reauthorizes with new access token' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'existing_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service_reauth.perform
        end
      end

      it 'uses the existing webhook verify token during reauthorization' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:subscribe_phone_number_webhook)
            .with(waba_id, '123456789', anything, 'existing_verify_token',
                  subscribed_fields: %w[messages smb_message_echoes])
          service_reauth.perform
        end
      end
    end

    context 'when webhook setup is successful in creation flow' do
      before do
        allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(api_client).to receive(:subscribe_phone_number_webhook)
          .with(waba_id, '123456789', anything, 'test_verify_token',
                subscribed_fields: %w[messages smb_message_echoes]).and_return({ 'success' => true })
      end

      it 'completes successfully without errors' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect { service.perform }.not_to raise_error
        end
      end

      it 'does not log any errors' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(Rails.logger).not_to receive(:error)
          service.perform
        end
      end
    end
  end
end
