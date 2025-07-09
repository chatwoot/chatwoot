require 'rails_helper'

describe Whatsapp::EmbeddedSignupService do
  let(:account) { create(:account) }
  let(:code) { 'test_authorization_code' }
  let(:business_id) { 'test_business_id' }
  let(:waba_id) { 'test_waba_id' }
  let(:phone_number_id) { 'test_phone_number_id' }
  let(:access_token) { 'test_access_token' }
  let(:app_id) { 'test_app_id' }
  let(:app_secret) { 'test_app_secret' }
  let(:api_version) { 'v22.0' }

  let(:service) do
    described_class.new(
      account: account,
      code: code,
      business_id: business_id,
      waba_id: waba_id,
      phone_number_id: phone_number_id
    )
  end

  before do
    # Mock global configuration
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_ID', '').and_return(app_id)
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_APP_SECRET', '').and_return(app_secret)
    allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', 'v22.0').and_return(api_version)
    allow(GlobalConfig).to receive(:clear_cache)

    # Mock environment variables - allow any calls to ENV.fetch
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('https://app.chatwoot.com')
    allow(ENV).to receive(:fetch).with('DISABLE_ENTERPRISE', false).and_return(true)

    # Mock ChatwootApp enterprise checks
    allow(ChatwootApp).to receive(:enterprise?).and_return(false)

    # NOTE: Specific HTTP request stubs are defined in individual test contexts
  end

  describe '#perform' do
    context 'when all parameters are valid' do
      before do
        # Stub the token exchange
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the phone numbers fetch
        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: {
              data: [
                {
                  id: phone_number_id,
                  display_phone_number: '1234567890',
                  verified_name: 'Test Business',
                  code_verification_status: 'VERIFIED'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the token validation
        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: hash_including(
            'input_token' => access_token,
            'access_token' => "#{app_id}|#{app_secret}"
          ))
          .to_return(
            status: 200,
            body: {
              data: {
                granular_scopes: [
                  {
                    scope: 'whatsapp_business_management',
                    target_ids: [waba_id]
                  }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the provider validation request (WhatsApp Cloud)
        stub_request(:get, "https://graph.facebook.com/v14.0/#{waba_id}/message_templates")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the phone number registration
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/register")
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the webhook subscription
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'successfully creates a new WhatsApp channel' do
        expect { service.perform }.not_to raise_error

        channel = Channel::Whatsapp.find_by(account: account, phone_number: '+1234567890')
        expect(channel).not_to be_nil
        expect(channel.provider).to eq('whatsapp_cloud')
        expect(channel.provider_config['api_key']).to eq(access_token)
        expect(channel.provider_config['phone_number_id']).to eq(phone_number_id)
        expect(channel.provider_config['business_account_id']).to eq(waba_id)
        expect(channel.provider_config['source']).to eq('embedded_signup')
      end

      it 'creates an inbox for the channel' do
        service.perform

        channel = Channel::Whatsapp.find_by(account: account, phone_number: '+1234567890')
        inbox = Inbox.find_by(account: account, channel: channel)
        expect(inbox).not_to be_nil
        expect(inbox.name).to eq('Test Business WhatsApp')
      end

      it 'registers the phone number' do
        service.perform

        expect(WebMock).to have_requested(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/register")
          .with(
            body: {
              messaging_product: 'whatsapp',
              pin: '212834'
            }.to_json
          )
      end

      it 'sets up webhook subscription' do
        service.perform

        channel = Channel::Whatsapp.find_by(account: account, phone_number: '+1234567890')
        callback_url = "https://app.chatwoot.com/webhooks/whatsapp/#{channel.phone_number}"

        expect(WebMock).to have_requested(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .with(
            body: hash_including(
              override_callback_uri: callback_url,
              verify_token: channel.provider_config['webhook_verify_token']
            )
          )
      end
    end

    context 'when required parameters are missing' do
      it 'raises an error when code is missing' do
        service = described_class.new(
          account: account,
          code: '',
          business_id: business_id,
          waba_id: waba_id,
          phone_number_id: phone_number_id
        )

        expect { service.perform }.to raise_error(ArgumentError, /Code, business_id, waba_id, and phone_number_id are all required/)
      end

      it 'raises an error when business_id is missing' do
        service = described_class.new(
          account: account,
          code: code,
          business_id: '',
          waba_id: waba_id,
          phone_number_id: phone_number_id
        )

        expect { service.perform }.to raise_error(ArgumentError, /Code, business_id, waba_id, and phone_number_id are all required/)
      end

      it 'raises an error when waba_id is missing' do
        service = described_class.new(
          account: account,
          code: code,
          business_id: business_id,
          waba_id: '',
          phone_number_id: phone_number_id
        )

        expect { service.perform }.to raise_error(ArgumentError, /Code, business_id, waba_id, and phone_number_id are all required/)
      end

      it 'raises an error when phone_number_id is missing' do
        service = described_class.new(
          account: account,
          code: code,
          business_id: business_id,
          waba_id: waba_id,
          phone_number_id: ''
        )

        expect { service.perform }.to raise_error(ArgumentError, /Code, business_id, waba_id, and phone_number_id are all required/)
      end
    end

    context 'when channel already exists' do
      before do
        # Stub all the required requests for successful flow
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: {
              data: [
                {
                  id: phone_number_id,
                  display_phone_number: '1234567890',
                  verified_name: 'Test Business',
                  code_verification_status: 'VERIFIED'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: hash_including(
            'input_token' => access_token,
            'access_token' => "#{app_id}|#{app_secret}"
          ))
          .to_return(
            status: 200,
            body: {
              data: {
                granular_scopes: [
                  {
                    scope: 'whatsapp_business_management',
                    target_ids: [waba_id]
                  }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub 360Dialog provider validation (for existing channel creation)
        stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
          .to_return(
            status: 200,
            body: { templates: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Create existing channel
        create(:channel_whatsapp, account: account, phone_number: '+1234567890')
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Channel already exists/)
      end
    end

    context 'when token exchange fails' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(status: 400, body: { error: 'Invalid code' }.to_json)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Token exchange failed/)
      end
    end

    context 'when token has no access to WABA' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: {
              data: [
                {
                  id: phone_number_id,
                  display_phone_number: '1234567890',
                  verified_name: 'Test Business',
                  code_verification_status: 'VERIFIED'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: hash_including(
            'input_token' => access_token,
            'access_token' => "#{app_id}|#{app_secret}"
          ))
          .to_return(
            status: 200,
            body: {
              data: {
                granular_scopes: [
                  {
                    scope: 'whatsapp_business_management',
                    target_ids: ['different_waba_id']
                  }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Token does not have access to WABA/)
      end
    end

    context 'when phone numbers fetch fails' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(status: 400, body: { error: 'Phone numbers fetch failed' }.to_json)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/WABA phone numbers fetch failed/)
      end
    end

    context 'when webhook override fails' do
      before do
        # Stub all the successful requests
        stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
          .with(query: hash_including(
            'client_id' => app_id,
            'client_secret' => app_secret,
            'code' => code
          ))
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: {
              data: [
                {
                  id: phone_number_id,
                  display_phone_number: '1234567890',
                  verified_name: 'Test Business',
                  code_verification_status: 'VERIFIED'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
          .with(query: hash_including(
            'input_token' => access_token,
            'access_token' => "#{app_id}|#{app_secret}"
          ))
          .to_return(
            status: 200,
            body: {
              data: {
                granular_scopes: [
                  {
                    scope: 'whatsapp_business_management',
                    target_ids: [waba_id]
                  }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, "https://graph.facebook.com/v14.0/#{waba_id}/message_templates")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: { data: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{phone_number_id}/register")
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub the failing webhook request
        stub_request(:post, "https://graph.facebook.com/#{api_version}/#{waba_id}/subscribed_apps")
          .to_return(status: 400, body: { error: 'Webhook failed' }.to_json)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/Webhook override failed/)
      end
    end
  end

  describe 'private methods' do
    describe '#exchange_code_for_token' do
      context 'when token exchange is successful' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
            .with(query: hash_including(
              'client_id' => app_id,
              'client_secret' => app_secret,
              'code' => code
            ))
            .to_return(
              status: 200,
              body: { access_token: access_token }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'returns the access token' do
          result = service.send(:exchange_code_for_token)
          expect(result).to eq(access_token)
        end
      end

      context 'when response has no access token' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/oauth/access_token")
            .with(query: hash_including(
              'client_id' => app_id,
              'client_secret' => app_secret,
              'code' => code
            ))
            .to_return(
              status: 200,
              body: { some_other_field: 'value' }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises an error' do
          expect { service.send(:exchange_code_for_token) }.to raise_error(/No access token in response/)
        end
      end
    end

    describe '#fetch_phone_info_via_waba' do
      before do
        stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
          .with(query: hash_including('access_token' => access_token))
          .to_return(
            status: 200,
            body: {
              data: [
                {
                  id: phone_number_id,
                  display_phone_number: '1234567890',
                  verified_name: 'Test Business',
                  code_verification_status: 'VERIFIED'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns formatted phone info' do
        result = service.send(:fetch_phone_info_via_waba, waba_id, phone_number_id, access_token)
        expect(result).to eq({
                               phone_number_id: phone_number_id,
                               phone_number: '+1234567890',
                               verified: true,
                               business_name: 'Test Business'
                             })
      end

      context 'when specific phone number is not found' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
            .with(query: hash_including('access_token' => access_token))
            .to_return(
              status: 200,
              body: {
                data: [
                  {
                    id: 'different_phone_id',
                    display_phone_number: '9876543210',
                    verified_name: 'Different Business',
                    code_verification_status: 'VERIFIED'
                  }
                ]
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'uses the first available phone number' do
          result = service.send(:fetch_phone_info_via_waba, waba_id, phone_number_id, access_token)
          expect(result[:phone_number_id]).to eq('different_phone_id')
          expect(result[:phone_number]).to eq('+9876543210')
        end
      end

      context 'when no phone numbers are available' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/#{waba_id}/phone_numbers")
            .with(query: hash_including('access_token' => access_token))
            .to_return(
              status: 200,
              body: { data: [] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises an error' do
          expect do
            service.send(:fetch_phone_info_via_waba, waba_id, phone_number_id, access_token)
          end.to raise_error(/No phone numbers found for WABA/)
        end
      end
    end

    describe '#validate_token_waba_access' do
      context 'when token has access to WABA' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
            .with(query: hash_including(
              'input_token' => access_token,
              'access_token' => "#{app_id}|#{app_secret}"
            ))
            .to_return(
              status: 200,
              body: {
                data: {
                  granular_scopes: [
                    {
                      scope: 'whatsapp_business_management',
                      target_ids: [waba_id]
                    }
                  ]
                }
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'validates successfully when token has access' do
          expect { service.send(:validate_token_waba_access, access_token, waba_id) }.not_to raise_error
        end
      end

      context 'when token validation fails' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
            .with(query: hash_including(
              'input_token' => access_token,
              'access_token' => "#{app_id}|#{app_secret}"
            ))
            .to_return(status: 400, body: { error: 'Invalid token' }.to_json)
        end

        it 'raises an error' do
          expect do
            service.send(:validate_token_waba_access, access_token, waba_id)
          end.to raise_error(/Token validation failed/)
        end
      end

      context 'when token does not have access to WABA' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
            .with(query: hash_including(
              'input_token' => access_token,
              'access_token' => "#{app_id}|#{app_secret}"
            ))
            .to_return(
              status: 200,
              body: {
                data: {
                  granular_scopes: [
                    {
                      scope: 'whatsapp_business_management',
                      target_ids: ['different_waba_id']
                    }
                  ]
                }
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises an error when WABA ID is not in target_ids' do
          expect do
            service.send(:validate_token_waba_access, access_token, waba_id)
          end.to raise_error(/Token does not have access to WABA/)
        end
      end

      context 'when no WABA scope is found' do
        before do
          stub_request(:get, "https://graph.facebook.com/#{api_version}/debug_token")
            .with(query: hash_including(
              'input_token' => access_token,
              'access_token' => "#{app_id}|#{app_secret}"
            ))
            .to_return(
              status: 200,
              body: {
                data: {
                  granular_scopes: [
                    {
                      scope: 'some_other_scope',
                      target_ids: ['some_id']
                    }
                  ]
                }
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'raises an error' do
          expect do
            service.send(:validate_token_waba_access, access_token, waba_id)
          end.to raise_error(/No WABA scope found in token/)
        end
      end
    end
  end
end