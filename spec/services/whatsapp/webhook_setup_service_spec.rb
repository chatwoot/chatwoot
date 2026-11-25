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

    # Default stubs for the code verification read and the health service
    allow(api_client).to receive(:phone_number_verification_status).and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
    allow(health_service).to receive(:fetch_health_status).and_return({
                                                                        platform_type: 'APPLICABLE',
                                                                        throughput_level: 'APPLICABLE'
                                                                      })
  end

  describe '#perform' do
    context 'when phone number is NOT verified (should register)' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
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
          expect(api_client).not_to receive(:phone_number_verification_status)
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
          expect(api_client).not_to receive(:phone_number_verification_status)
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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

    context 'when the pending state comes only from throughput, in the shape HealthService produces' do
      # HealthService keeps Meta's `throughput` object verbatim, so its keys are strings, and it
      # derives `:throughput_level` alongside. A spec that stubs `throughput: { level: ... }` with
      # symbols is testing a payload the app never sees.
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput: { 'level' => 'NOT_APPLICABLE' },
                                                                            throughput_level: 'NOT_APPLICABLE'
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers the number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end

      it 'registers it on the unknown-verification path too, which is where it now matters' do
        # This is the path the change created: an unread verification used to register regardless,
        # and now it defers to health. If health misses the throughput half, the number is silently
        # left unregistered.
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_raise('API down')

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end
    end

    context 'when phone number needs registration due to throughput level' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput: { 'level' => 'NOT_APPLICABLE' },
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

    # This context used to assert the opposite, that a failed read registers the number, and it was
    # green: the behaviour was written down as intended rather than arrived at by accident. #590 is
    # the argument that it should not be, and the flip is the whole point of the change, so the
    # example is rewritten here rather than deleted.
    context 'when the code verification read does not come back' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_raise('API down')
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput_level: 'APPLICABLE'
                                                                          })
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'does not register the number, because a read that did not answer is not a "no"' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_phone_number_webhook)
          expect { service.perform }.not_to raise_error
        end
      end

      it 'still asks health, so the number is registered when health names the pending state' do
        # The old `||` short-circuited here: a read that failed counted as "not verified" and the
        # health call never happened. Now the second axis gets to answer on its own.
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'NOT_APPLICABLE',
                                                                            throughput: { level: 'APPLICABLE' }
                                                                          })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(health_service).to receive(:fetch_health_status)
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end

      # The decision has two outcomes, so `:unknown` and `:verified` produce the same one and no
      # mutation of the decision can be caught here. This line is the whole surface of the third
      # state: without it asserted, a cleanup can put the app back in a two-state world where "could
      # not tell" is indistinguishable from "verified", and nothing turns red.
      it 'says the read did not answer, which is the only place that state is visible' do
        allow(Rails.logger).to receive(:error)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).to have_received(:error)
          .with('[WHATSAPP] Could not read the code verification status for 123456789; ' \
                'not deciding registration from it: API down')
      end

      it 'does not raise, because the caller turns any raise into a reauthorization prompt' do
        # Channel::Whatsapp#setup_webhooks rescues everything out of #perform and calls
        # prompt_reauthorization!, and WhatsappEventsJob then discards every inbound webhook for
        # the channel. Answering "could not tell" by raising would be worse than the bug (#568).
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect { service.perform }.not_to raise_error
        end
      end
    end

    context 'when the code verification read answers an empty value' do
      # Absent, null and empty string are the same fact: the read did not answer the question. The
      # client hands them over verbatim now, so it is here that they have to mean the same thing.
      %w[nil empty].each do |shape|
        it "treats #{shape} as an answer that answers nothing" do
          allow(api_client).to receive(:phone_number_verification_status)
            .with('123456789').and_return(shape == 'nil' ? nil : '')
          allow(health_service).to receive(:fetch_health_status).and_return({
                                                                              platform_type: 'APPLICABLE',
                                                                              throughput: { level: 'APPLICABLE' }
                                                                            })
          allow(api_client).to receive(:register_phone_number)
          allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })

          with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
            expect(api_client).not_to receive(:register_phone_number)
            service.perform
          end
        end

        it "says so, because #{shape} decides nothing and the log is where that shows" do
          allow(api_client).to receive(:phone_number_verification_status)
            .with('123456789').and_return(shape == 'nil' ? nil : '')
          allow(health_service).to receive(:fetch_health_status).and_return({
                                                                              platform_type: 'APPLICABLE',
                                                                              throughput: { level: 'APPLICABLE' }
                                                                            })
          allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
          allow(Rails.logger).to receive(:error)

          with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
            service.perform
          end

          expect(Rails.logger).to have_received(:error)
            .with('[WHATSAPP] Phone number 123456789 answered neither status nor code verification status; ' \
                  'not deciding registration from it')
        end
      end
    end

    # Upstream's rule, kept through the rewrite: a number Meta reports CONNECTED is registered
    # even after its one-time code verification expired, so an EXPIRED code alone must not
    # send a second /register.
    context 'when the number is CONNECTED with an expired code verification' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789')
                                                                       .and_return({ 'status' => 'CONNECTED',
                                                                                     'code_verification_status' => 'EXPIRED' })
        allow(health_service).to receive(:fetch_health_status).and_return({ platform_type: 'APPLICABLE', throughput_level: 'APPLICABLE' })
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
      end

      it 'does not register the number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          service.perform
        end
      end
    end

    context 'when the code verification read answers something that is not VERIFIED' do
      # EXPIRED is a documented Meta value and is a definite "no", not a silence.
      %w[NOT_VERIFIED PENDING EXPIRED].each do |status|
        it "registers on #{status}, because Meta answered" do
          allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => status })
          allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
          allow(api_client).to receive(:register_phone_number)
          allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })

          with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
            expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
            service.perform
          end
        end
      end
    end

    context 'when the code verification read answers without the field' do
      before do
        # A perfectly good 200 that does not carry `code_verification_status`. This never reached a
        # rescue: it turned into `false` inside the client, one layer below where anyone was looking.
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({})
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'APPLICABLE',
                                                                            throughput: { level: 'APPLICABLE' }
                                                                          })
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'does not register the number either, because an answer without the field answers nothing' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          service.perform
        end
      end
    end

    context 'when health service raises error' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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

      # Same hole on the other axis: `:unknown` and `:not_pending` lead to the same decision, so the
      # line is the only thing that separates "health said no" from "health did not say".
      it 'says the health read did not answer' do
        allow(Rails.logger).to receive(:error)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).to have_received(:error)
          .with('[WHATSAPP] Could not read the health status; not deciding registration from it: Health API down')
      end
    end

    context 'when phone registration fails (not blocking)' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
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

    context 'when the registration write does not come back' do
      let(:provider_config) { super().merge('verification_pin' => nil) }

      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(api_client).to receive(:register_phone_number).and_raise(Net::ReadTimeout)
        allow(api_client).to receive(:subscribe_phone_number_webhook).and_return({ 'success' => true })
      end

      it 'keeps the PIN it sent, because Meta may be holding that one' do
        # The PIN used to be stored only after the call returned, so an attempt whose outcome nobody
        # saw left nothing behind and the next one drew a different number. Then the app could not
        # name what might already be valid on Meta's side (#590).
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(channel.reload.provider_config['verification_pin']).to eq(223_456)
      end

      it 'leaves the PIN unconfirmed, so the three states stay readable' do
        # No PIN means Meta holds none. A confirmed PIN means Meta holds this one. An unconfirmed
        # PIN means nobody knows, and that is the state this endpoint could not write down before.
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        config = channel.reload.provider_config
        expect(config['verification_pin']).to eq(223_456)
        expect(config).not_to have_key('verification_pin_confirmed')
      end

      it 'keeps the PIN even when Meta refused, because a refusal establishes nothing about it' do
        # A 5xx, a rate limit, a body this code could not parse and a failure to save the
        # confirmation after a registration Meta ACCEPTED all arrive here as the same exception.
        # Dropping the PIN on any of them loses one that may be live and sends a different one next
        # time, which is the disagreement this change exists to prevent.
        allow(api_client).to receive(:register_phone_number).and_raise('Phone registration failed: {"error":"bad pin"}')

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(channel.reload.provider_config['verification_pin']).to eq(223_456)
      end

      it 'keeps a PIN Meta already confirmed when saving the confirmation itself fails' do
        # The worst case of dropping on failure: the registration landed, and the exception comes
        # from the write that records it.
        allow(api_client).to receive(:register_phone_number).and_return({ 'success' => true })
        allow(channel).to receive(:save!).with(validate: false).and_call_original
        call = 0
        allow(channel).to receive(:save!).with(validate: false) do
          call += 1
          raise ActiveRecord::RecordInvalid if call > 1

          true
        end

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect { service.perform }.not_to raise_error
        end
      end

      it 'confirms the PIN when the call came back, because then Meta holds this one' do
        allow(api_client).to receive(:register_phone_number).and_return({ 'success' => true })

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        config = channel.reload.provider_config
        expect(config['verification_pin']).to eq(223_456)
        expect(config['verification_pin_confirmed']).to be(true)
      end

      it 'says the outcome is unknown, not that Meta refused' do
        # A refusal and a silence used to share this line verbatim. One is something the app knows.
        allow(Rails.logger).to receive(:warn)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).to have_received(:warn).with(/outcome unknown/)
        expect(Rails.logger).not_to have_received(:warn).with(/refused/)
      end

      it 'never puts the PIN in the log, because it is a credential' do
        # Direct interpolation into the logger bypasses Rails parameter filtering, and on a timeout
        # this is very likely the PIN Meta is holding.
        allow(Rails.logger).to receive(:warn)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).not_to have_received(:warn).with(/223456|223_456/)
      end

      it 'writes the PIN without re-validating the credentials against Meta' do
        # A plain save! runs validate_provider_config, which is another Graph call, on the exact
        # path where Meta is already misbehaving. If that call failed, save! would raise, the rescue
        # around the registration would swallow it, and the POST /register would never leave.
        allow(channel).to receive(:save!)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(channel).to have_received(:save!).with(validate: false)
      end

      it 'still sends the registration when the channel validation would have failed' do
        allow(channel).to receive(:save!).with(validate: false).and_return(true)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end

      # This used to assert the opposite, and it was the clearest statement of the old boundary: a bare
      # `RuntimeError` is not an answer from Meta, and calling it a refusal is the app making a claim
      # about a system it never heard from.
      it 'does not call it a refusal when the error is not an answer from Meta' do
        allow(api_client).to receive(:register_phone_number).and_raise('Phone registration failed: {"error":"bad pin"}')
        allow(Rails.logger).to receive(:warn)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).not_to have_received(:warn).with(/refused/)
        expect(Rails.logger).to have_received(:warn).with(/outcome unknown/)
      end
    end

    # Every example above answers through a double of the client, so none of them exercises the
    # client's own `handle_response`, and the class it raises is exactly what this service reads to
    # tell a refusal from a silence. That class changed under this branch (#595 replaced the bare
    # `raise "message"` with `Whatsapp::ApiError`) and the examples above stayed green, because a
    # stub that raises a class of its own agrees with whatever the code does. These two go through
    # the real client, so the naming and the reauthorization contract are pinned to what Meta's
    # answer actually becomes.
    context 'with the real Graph client' do
      let(:register_url) { %r{graph\.facebook\.com/[^/]+/123456789/register} }
      let(:status_url) { %r{graph\.facebook\.com/[^/]+/123456789(\?.*)?\z} }
      let(:waba_subscribe_url) { %r{graph\.facebook\.com/[^/]+/test_waba_id/subscribed_apps} }
      let(:json_headers) { { 'Content-Type' => 'application/json' } }

      before do
        allow(Whatsapp::FacebookApiClient).to receive(:new).and_call_original
        stub_request(:get, status_url)
          .to_return(status: 200, body: { code_verification_status: 'NOT_VERIFIED' }.to_json, headers: json_headers)
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)
      end

      # Every example below drives the real client over stubbed HTTP, because the question is what the
      # error that reaches `registration_outcome` carries, and a double raising a hand-built exception
      # agrees with whatever the code does. The two webhook calls answer 200 throughout, so the only
      # failure in play is the registration.
      def register_answering(status:, body:, headers: { 'Content-Type' => 'application/json' })
        stub_request(:post, register_url).to_return(status: status, body: body, headers: headers)
        stub_request(:post, waba_subscribe_url).to_return(status: 200, body: '{}', headers: json_headers)
        stub_request(:post, status_url).to_return(status: 200, body: '{}', headers: json_headers)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end
      end

      def warn_lines
        messages = []
        expect(Rails.logger).to have_received(:warn).at_least(:once) do |line|
          messages << line
        end
        messages.grep(/Phone registration/)
      end

      it 'says Meta refused when the refusal is the one the client raised' do
        stub_request(:post, register_url)
          .to_return(status: 400, body: { error: { message: 'Invalid PIN', code: 100 } }.to_json, headers: json_headers)
        stub_request(:post, waba_subscribe_url).to_return(status: 200, body: '{}', headers: json_headers)
        stub_request(:post, status_url).to_return(status: 200, body: '{}', headers: json_headers)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        end

        expect(Rails.logger).to have_received(:warn).with(/refused/)
        expect(Rails.logger).not_to have_received(:warn).with(/outcome unknown/)
      end

      # The read of the verification status now swallows its own failure to keep a silence from
      # deciding the registration, and a dead token fails that read too. What must survive is Meta's
      # answer about the credentials: it reaches `Channel::Whatsapp#credentials_refused?` through the
      # required half of the webhook setup, which is the only call here that still raises. Asserted in
      # that method's own vocabulary (down `cause`, `authorization_error?`) so a later change making
      # the setup best effort too shows up here instead of in a channel that nobody reauthorizes.
      it 'still carries Meta answer about the credentials out of perform' do
        body = { error: { message: 'Session has expired', code: 190 } }.to_json
        stub_request(:post, register_url).to_return(status: 401, body: body, headers: json_headers)
        stub_request(:get, status_url).to_return(status: 401, body: body, headers: json_headers)
        stub_request(:post, waba_subscribe_url).to_return(status: 401, body: body, headers: json_headers)

        raised = nil
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          service.perform
        rescue StandardError => e
          raised = e
        end

        expect(raised).to be_present

        chain = []
        error = raised
        while error
          chain << error
          error = error.cause
        end
        expect(chain.any? { |e| e.is_a?(Whatsapp::ApiError) && e.authorization_error? }).to be(true)
      end

      # The word for the outcome is a claim, and the claim has to be backed by an answer. "Refused"
      # says Meta holds no PIN of ours, and only an answer from Meta can say that.
      context 'when the registration fails without Meta having answered no' do
        it 'does not call a 500 a refusal, because an internal error can be raised after the write landed' do
          register_answering(status: 500, body: { error: { message: 'An unknown error occurred', code: 1 } }.to_json)

          expect(warn_lines.size).to eq(1)
          expect(warn_lines.first).to include('outcome unknown').and include('phone_number_id 123456789')
          expect(warn_lines.first).not_to include('refused')
        end

        # Something in front of Meta answering instead of Meta. No code, no verdict.
        it 'does not call a 5xx that is not even in Meta shape a refusal' do
          register_answering(status: 502, body: '<html><body>Bad Gateway</body></html>',
                             headers: { 'Content-Type' => 'text/html' })

          expect(warn_lines.first).to include('outcome unknown')
          expect(warn_lines.first).not_to include('refused')
        end

        it 'does not call an answer this code could not read a refusal' do
          register_answering(status: 200, body: 'this is not json at all')

          expect(warn_lines.first).not_to include('refused')
        end

        # Our own error, raised on our side: Meta was never heard from, so nothing can be said about it.
        # The original message stays in the line, which is what shows the operator the fault is ours.
        [ArgumentError, NoMethodError].each do |klass|
          it "does not turn a #{klass} of our own into a statement about Meta" do
            allow_any_instance_of(Whatsapp::FacebookApiClient) # rubocop:disable RSpec/AnyInstance
              .to receive(:register_phone_number).and_raise(klass, 'algo nosso quebrou')
            register_answering(status: 200, body: '{"success":true}')

            expect(warn_lines.size).to eq(1)
            expect(warn_lines.first).to include('outcome unknown').and include('algo nosso quebrou')
            expect(warn_lines.first).not_to include('refused')
          end
        end

        # The strongest form: Meta accepted, and the write of our own marker is what failed. Calling
        # that a refusal states the opposite of what happened.
        it 'does not call it a refusal when Meta accepted and only our confirmation failed' do
          # The first write is the PIN, before the call; the second is the confirmation marker, after
          # Meta accepted. Only the second fails.
          writes = 0
          allow(channel).to receive(:save!).with(validate: false) do
            writes += 1
            raise ActiveRecord::RecordInvalid, channel if writes > 1

            true
          end
          register_answering(status: 200, body: '{"success":true}')

          expect(warn_lines.first).not_to include('refused')
          expect(channel.provider_config['verification_pin']).to eq(223_456)
        end
      end

      context 'when Meta did answer no' do
        it 'calls a 400 about the PIN a refusal' do
          register_answering(status: 400, body: { error: { message: 'Invalid PIN', code: 100 } }.to_json)

          expect(warn_lines.first).to include('refused')
        end

        # Not a credential verdict, but Meta did answer, and the write did not land.
        it 'calls a 403 permissions error a refusal' do
          register_answering(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json)

          expect(warn_lines.first).to include('refused')
        end

        # The only 4xx where the two honest readings diverge. The boundary here is the status class:
        # Meta answered and this attempt did not land, which is the same fact the operator acts on.
        it 'calls a 429 rate limit a refusal' do
          register_answering(status: 429, body: { error: { message: '(#80007) Rate limit hit', code: 80_007 } }.to_json)

          expect(warn_lines.first).to include('refused')
        end
      end

      # Naming the outcome is a log line and nothing else. A registration that fails must not reach
      # the reauthorization marker, which no human clears and which makes the inbound job discard
      # every webhook.
      it 'never marks the channel for reauthorization from a failed registration' do
        register_answering(status: 500, body: { error: { message: 'An unknown error occurred', code: 1 } }.to_json)

        expect(channel.reload.reauthorization_required?).to be(false)
      end
    end

    context 'when webhook setup fails (should raise)' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'NOT_VERIFIED' })
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

      it 'reuses it even when it was never confirmed, which is the whole reason to keep it' do
        # An unconfirmed PIN is the one a write left behind when nobody saw its outcome. Meta may be
        # holding exactly that number, so the retry has to send the same one; drawing a new one is
        # how the app used to guarantee it could never agree with Meta again (#590).
        channel.provider_config.delete('verification_pin_confirmed')

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 123_456)
          expect(SecureRandom).not_to receive(:random_number)
          service.perform
        end
      end

      it 'draws a new one after a refusal, because then the old one is not held anywhere' do
        channel.provider_config.delete('verification_pin')
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)

        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end
    end

    context 'when webhook setup fails and should trigger reauthorization' do
      before do
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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
        allow(api_client).to receive(:phone_number_verification_status).with('123456789').and_return({ 'code_verification_status' => 'VERIFIED' })
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
