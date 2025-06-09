require 'rails_helper'

RSpec.describe 'Microsoft::CallbacksController', type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:email) { Faker::Internet.email }
  let(:cache_key) { "microsoft::#{email.downcase}" }

  before do
    Redis::Alfred.set(cache_key, account.id)
  end

  describe 'GET /microsoft/callback' do
    let(:response_body_success) do
      { id_token: JWT.encode({ email: email, name: 'test' }, false), access_token: SecureRandom.hex(10), token_type: 'Bearer',
        refresh_token: SecureRandom.hex(10) }
    end

    let(:response_body_success_without_name) do
      { id_token: JWT.encode({ email: email }, false), access_token: SecureRandom.hex(10), token_type: 'Bearer',
        refresh_token: SecureRandom.hex(10) }
    end

    it 'creates inboxes if authentication is successful' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: { 'code' => code, 'grant_type' => 'authorization_code',
                      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback" })
        .to_return(status: 200, body: response_body_success.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code }

      expect(response).to redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      inbox = account.inboxes.last
      expect(inbox.name).to eq 'test'
      expect(inbox.channel.reload.provider_config.keys).to include('access_token', 'refresh_token', 'expires_on')
      expect(inbox.channel.reload.provider_config['access_token']).to eq response_body_success[:access_token]
      expect(inbox.channel.imap_address).to eq 'outlook.office365.com'
      expect(Redis::Alfred.get(cache_key)).to be_nil
    end

    it 'creates updates inbox channel config if inbox exists and authentication is successful' do
      inbox = create(:channel_email, account: account, email: email)&.inbox
      expect(inbox.channel.provider_config).to eq({})

      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: { 'code' => code, 'grant_type' => 'authorization_code',
                      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback" })
        .to_return(status: 200, body: response_body_success.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code }

      expect(response).to redirect_to app_email_inbox_settings_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      expect(inbox.channel.reload.provider_config.keys).to include('access_token', 'refresh_token', 'expires_on')
      expect(inbox.channel.reload.provider_config['access_token']).to eq response_body_success[:access_token]
      expect(inbox.channel.imap_address).to eq 'outlook.office365.com'
      expect(Redis::Alfred.get(cache_key)).to be_nil
    end

    it 'creates inboxes with fallback_name when account name is not present in id_token' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: { 'code' => code, 'grant_type' => 'authorization_code',
                      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback" })
        .to_return(status: 200, body: response_body_success_without_name.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code }

      expect(response).to redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      inbox = account.inboxes.last
      expect(inbox.name).to eq email.split('@').first.parameterize.titleize
    end

    it 'creates inboxes with sanitized names when name contains forbidden characters' do
      response_body_with_invalid_name = {
        id_token: JWT.encode({ email: email, name: 'Test@User<Name>/\\' }, false),
        access_token: SecureRandom.hex(10),
        token_type: 'Bearer',
        refresh_token: SecureRandom.hex(10)
      }

      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: { 'code' => code, 'grant_type' => 'authorization_code',
                      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback" })
        .to_return(status: 200, body: response_body_with_invalid_name.to_json, headers: { 'Content-Type' => 'application/json' })

      get microsoft_callback_url, params: { code: code }

      expect(response).to redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: account.inboxes.last.id)
      expect(account.inboxes.count).to be 1
      inbox = account.inboxes.last
      expect(inbox.name).to eq 'TestUserName'
    end

    it 'redirects to microsoft app in case of error' do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token')
        .with(body: { 'code' => code, 'grant_type' => 'authorization_code',
                      'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/microsoft/callback" })
        .to_return(status: 401)

      get microsoft_callback_url, params: { code: code }

      expect(response).to redirect_to '/'
      expect(Redis::Alfred.get(cache_key).to_i).to eq account.id
    end

    context 'with name sanitization' do
      let(:controller) { Microsoft::CallbacksController.new }

      before do
        allow(controller).to receive(:account_id).and_return(account.id)
        allow(controller).to receive(:account).and_return(account)
      end

      it 'sanitizes names with forbidden characters' do
        allow(controller).to receive(:users_data).and_return({ 'email' => email, 'name' => 'Test@User<Name>' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'TestUserName'
      end

      it 'sanitizes names with leading and trailing symbols' do
        allow(controller).to receive(:users_data).and_return({ 'email' => email, 'name' => '@@@Test User$$$' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'Test User'
      end

      it 'sanitizes names with multiple forbidden characters' do
        allow(controller).to receive(:users_data).and_return({ 'email' => email, 'name' => 'Test/User\\Name<>' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'TestUserName'
      end

      it 'uses fallback when name becomes empty after sanitization' do
        allow(controller).to receive(:users_data).and_return({ 'email' => 'test@example.com', 'name' => '@@@//\\\\<>' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'Test'
      end

      it 'preserves valid names unchanged' do
        allow(controller).to receive(:users_data).and_return({ 'email' => email, 'name' => 'Valid User Name' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'Valid User Name'
      end

      it 'handles names with spaces and underscores' do
        allow(controller).to receive(:users_data).and_return({ 'email' => email, 'name' => 'Test_User Name 123' })
        expect(controller.send(:sanitized_inbox_name)).to eq 'Test_User Name 123'
      end

      it 'uses fallback when name is missing' do
        allow(controller).to receive(:users_data).and_return({ 'email' => 'john.doe@example.com', 'name' => nil })
        expect(controller.send(:sanitized_inbox_name)).to eq 'John Doe'
      end

      it 'handles complex email fallback with numbers and dots' do
        allow(controller).to receive(:users_data).and_return({ 'email' => 'user123.test@example.com', 'name' => nil })
        expect(controller.send(:sanitized_inbox_name)).to eq 'User123 Test'
      end
    end
  end
end
