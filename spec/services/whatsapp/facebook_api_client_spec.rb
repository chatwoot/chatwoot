require 'rails_helper'

describe Whatsapp::FacebookApiClient do
  let(:access_token) { 'test_access_token' }
  let(:api_client) { described_class.new(access_token) }
  let(:api_version) { 'v22.0' }
  let(:app_id) { 'test_app_id' }
  let(:app_secret) { 'test_app_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return(api_version)
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return(app_id)
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_SECRET', '').and_return(app_secret)
  end

  describe '#app_secret_matches?' do
    let(:proof) { OpenSSL::HMAC.hexdigest('SHA256', 'customer_secret', access_token) }
    let(:me_url) { "https://graph.facebook.com/#{api_version}/me" }

    it 'sends a proof made from the secret and the token, and takes a 200 as a match' do
      stub_request(:get, me_url).with(query: { fields: 'id', appsecret_proof: proof }).to_return(status: 200, body: { id: '1' }.to_json)

      expect(api_client.app_secret_matches?('customer_secret')).to be(true)
    end

    it 'takes a refused proof as a mismatch' do
      stub_request(:get, me_url).with(query: hash_including('appsecret_proof' => proof))
                                .to_return(status: 400, body: { error: { message: 'Invalid appsecret_proof provided in the API argument',
                                                                         code: 100 } }.to_json)

      expect(api_client.app_secret_matches?('customer_secret')).to be(false)
    end

    # Anything else says nothing about the secret, and must not be read as a wrong one.
    it 'raises on any other failure' do
      stub_request(:get, me_url).with(query: hash_including('appsecret_proof' => proof))
                                .to_return(status: 401, body: { error: { message: 'Invalid OAuth access token', code: 190 } }.to_json)

      expect { api_client.app_secret_matches?('customer_secret') }.to raise_error(Whatsapp::ApiError)
    end
  end

  describe '#exchange_code_for_token' do
    let(:code) { 'test_code' }

    context 'when successful' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: { client_id: app_id, client_secret: app_secret, code: code })
          .to_return(
            status: 200,
            body: { access_token: 'new_token' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the response data' do
        result = api_client.exchange_code_for_token(code)
        expect(result['access_token']).to eq('new_token')
      end
    end

    context 'when failed' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: { client_id: app_id, client_secret: app_secret, code: code })
          .to_return(status: 400, body: { error: 'Invalid code' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.exchange_code_for_token(code) }.to raise_error(/Token exchange failed/)
      end
    end
  end

  describe '#fetch_phone_numbers' do
    let(:waba_id) { 'test_waba_id' }

    context 'when successful' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: { access_token: access_token })
          .to_return(
            status: 200,
            body: { data: [{ id: '123', display_phone_number: '1234567890' }] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the phone numbers data' do
        result = api_client.fetch_phone_numbers(waba_id)
        expect(result['data']).to be_an(Array)
        expect(result['data'].first['id']).to eq('123')
      end
    end

    context 'when failed' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: { access_token: access_token })
          .to_return(status: 403, body: { error: 'Access denied' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.fetch_phone_numbers(waba_id) }.to raise_error(/WABA phone numbers fetch failed/)
      end
    end
  end

  describe '#debug_token' do
    let(:input_token) { 'test_input_token' }
    let(:app_access_token) { "#{app_id}|#{app_secret}" }

    context 'when successful' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: { input_token: input_token, access_token: app_access_token })
          .to_return(
            status: 200,
            body: { data: { app_id: app_id, is_valid: true } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the debug token data' do
        result = api_client.debug_token(input_token)
        expect(result['data']['is_valid']).to be(true)
      end
    end

    context 'when failed' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: { input_token: input_token, access_token: app_access_token })
          .to_return(status: 400, body: { error: 'Invalid token' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.debug_token(input_token) }.to raise_error(/Token validation failed/)
      end
    end
  end

  describe '#register_phone_number' do
    let(:phone_number_id) { 'test_phone_id' }
    let(:pin) { '123456' }

    context 'when successful' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/register")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { messaging_product: 'whatsapp', pin: pin }.to_json
          )
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response' do
        result = api_client.register_phone_number(phone_number_id, pin)
        expect(result['success']).to be(true)
      end
    end

    context 'when failed' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/register")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { messaging_product: 'whatsapp', pin: pin }.to_json
          )
          .to_return(status: 400, body: { error: 'Registration failed' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.register_phone_number(phone_number_id, pin) }.to raise_error(/Phone registration failed/)
      end
    end
  end

  describe '#deregister_phone_number' do
    let(:phone_number_id) { 'test_phone_id' }

    context 'when successful' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/deregister")
          .with(headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns success response' do
        result = api_client.deregister_phone_number(phone_number_id)
        expect(result['success']).to be(true)
      end
    end

    context 'when failed' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/deregister")
          .to_return(status: 400, body: { error: 'Deregistration failed' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.deregister_phone_number(phone_number_id) }.to raise_error(/Phone deregistration failed/)
      end
    end
  end

  describe '#subscribe_phone_number_webhook' do
    let(:waba_id) { 'test_waba_id' }
    let(:phone_number_id) { 'test_phone_id' }
    let(:callback_url) { 'https://example.com/webhook' }
    let(:verify_token) { 'test_verify_token' }

    context 'when successful' do
      before do
        # Step 1: Subscribe app to WABA with the default field list (`calls` is added only when voice is enabled).
        # Pinning the body guards against regressions that drop a field and break delivery.
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { subscribed_fields: %w[messages smb_message_echoes] }.to_json
          )
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Step 2: Override callback at phone number level
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { webhook_configuration: { override_callback_uri: callback_url, verify_token: verify_token } }.to_json
          )
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'answers that the per-number routing landed' do
        result = api_client.subscribe_phone_number_webhook(waba_id, phone_number_id, callback_url, verify_token)
        expect(result).to be(true)
      end
    end

    context 'when app subscription fails' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
          )
          .to_return(status: 400, body: { error: 'App subscription to WABA failed' }.to_json)
      end

      it 'raises an error' do
        expect do
          api_client.subscribe_phone_number_webhook(waba_id, phone_number_id, callback_url, verify_token)
        end.to raise_error(/App subscription to WABA failed/)
      end
    end

    # The override is the half a channel can live without: the WABA subscription is what makes
    # Meta deliver at all, and the override only re-routes one number of a shared WABA. Meta
    # refuses it for a whole class of accounts that receive perfectly well without it, and under
    # a shared rescue that refusal marked the channel for reauthorization and cost it every
    # inbound webhook.
    context 'when phone number callback override fails' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .with(headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
        allow(Rails.logger).to receive(:warn)
      end

      # Three shapes of the same refusal, because a fix that reads the status or the message
      # covers one of them and leaves the other two killing the channel.
      [
        ['a permissions error',
         ->(stub) { stub.to_return(status: 403, body: { error: { message: '(#200) Permissions error', code: 200 } }.to_json) }],
        ['a plain server error',
         ->(stub) { stub.to_return(status: 500, body: { error: { message: 'Internal server error' } }.to_json) }],
        ['a connection that answers nothing', ->(stub) { stub.to_raise(Errno::ECONNRESET) }]
      ].each do |shape, refuse|
        context "when Meta answers with #{shape}" do
          before { refuse.call(stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")) }

          it 'does not raise, and answers that the routing was not applied' do
            result = api_client.subscribe_phone_number_webhook(waba_id, phone_number_id, callback_url, verify_token)

            expect(result).to be(false)
          end

          it 'says in the log which call was refused and for which number' do
            api_client.subscribe_phone_number_webhook(waba_id, phone_number_id, callback_url, verify_token)

            expect(Rails.logger).to have_received(:warn).with(/override failed but continuing.*#{phone_number_id}/)
          end
        end
      end
    end

    # Still attempted whenever it can work: dropping the call altogether would take the routing
    # away from every installation that shares a WABA between numbers.
    context 'when both calls succeed' do
      it 'sends the override with the callback url and the verify token' do
        subscription = stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
                       .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
        override = stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
                   .with(body: { webhook_configuration: { override_callback_uri: callback_url, verify_token: verify_token } }.to_json)
                   .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })

        api_client.subscribe_phone_number_webhook(waba_id, phone_number_id, callback_url, verify_token)

        expect(subscription).to have_been_requested
        expect(override).to have_been_requested
      end
    end
  end

  describe '#clear_phone_number_callback_override' do
    let(:phone_number_id) { 'test_phone_id' }

    context 'when successful' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { webhook_configuration: { override_callback_uri: '' } }.to_json
          )
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response' do
        result = api_client.clear_phone_number_callback_override(phone_number_id)
        expect(result['success']).to be(true)
      end
    end

    context 'when failed' do
      before do
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
          .with(
            headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
            body: { webhook_configuration: { override_callback_uri: '' } }.to_json
          )
          .to_return(status: 400, body: { error: 'Phone number webhook callback clear failed' }.to_json)
      end

      it 'raises an error' do
        expect { api_client.clear_phone_number_callback_override(phone_number_id) }.to raise_error(/Phone number webhook callback clear failed/)
      end
    end
  end

  describe 'the ceiling on every Graph call' do
    # Meta accepting the connection and then staying quiet is the arrangement this is about, and
    # webmock cannot show it: it answers instantly, so a missing ceiling passes every stub in this
    # file. What the ceiling is made of is therefore asserted on the call itself.
    it 'passes the wait ceiling and switches the retry off, on a read' do
      allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: true, parsed_response: {}))

      api_client.fetch_phone_numbers('test_waba_id')

      expect(HTTParty).to have_received(:get).with(anything, hash_including(timeout: 10, max_retries: 0))
    end

    it 'passes the same ceiling on a write' do
      allow(HTTParty).to receive(:post).and_return(instance_double(HTTParty::Response, success?: true, parsed_response: {}))

      api_client.subscribe_app_to_waba('test_waba_id')

      expect(HTTParty).to have_received(:post).with(anything, hash_including(timeout: 10, max_retries: 0))
    end
  end

  describe '#phone_number_verification_status' do
    let(:phone_number_id) { '123456789' }
    let(:status_query) { { fields: 'status,code_verification_status' } }

    it "answers Meta's status and code verification status verbatim" do
      stub_request(:get, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
        .with(query: status_query)
        .to_return(status: 200, body: { status: 'CONNECTED', code_verification_status: 'NOT_VERIFIED', id: phone_number_id }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(api_client.phone_number_verification_status(phone_number_id))
        .to eq({ 'status' => 'CONNECTED', 'code_verification_status' => 'NOT_VERIFIED' })
    end

    it 'answers an empty hash when neither field is present, instead of deciding it means not verified' do
      # A 200 that does not carry the fields is not the same fact as Meta saying NOT_VERIFIED, and
      # the caller writes to Meta on the difference (#590).
      stub_request(:get, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
        .with(query: status_query)
        .to_return(status: 200, body: { id: phone_number_id }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(api_client.phone_number_verification_status(phone_number_id)).to eq({})
    end

    it 'raises when the read failed, so the caller can tell that apart from an answer' do
      stub_request(:get, "https://graph.facebook.com/#{api_version}/#{phone_number_id}")
        .with(query: status_query)
        .to_return(status: 500, body: { error: 'boom' }.to_json)

      expect { api_client.phone_number_verification_status(phone_number_id) }
        .to raise_error(/Phone status check failed/)
    end
  end
end
