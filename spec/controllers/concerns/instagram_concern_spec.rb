require 'rails_helper'

RSpec.describe InstagramConcern do
  let(:dummy_class) { Class.new { include InstagramConcern } }
  let(:dummy_instance) { dummy_class.new }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:short_lived_token) { 'short_lived_token' }
  let(:long_lived_token) { 'long_lived_token' }
  let(:access_token) { 'access_token' }

  before do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_APP_SECRET', nil).and_return(client_secret)
    allow(Rails.logger).to receive(:error)
  end

  describe '#instagram_client' do
    it 'creates an OAuth2 client with correct configuration', :aggregate_failures do
      client = dummy_instance.instagram_client

      expect(client).to be_a(OAuth2::Client)
      expect(client.id).to eq(client_id)
      expect(client.secret).to eq(client_secret)
      expect(client.site).to eq('https://api.instagram.com')
      expect(client.options[:authorize_url]).to eq('https://api.instagram.com/oauth/authorize')
      expect(client.options[:token_url]).to eq('https://api.instagram.com/oauth/access_token')
      expect(client.options[:auth_scheme]).to eq(:request_body)
      expect(client.options[:token_method]).to eq(:post)
    end
  end

  describe '#exchange_for_long_lived_token' do
    let(:response_body) { { 'access_token' => long_lived_token, 'expires_in' => 5_184_000 }.to_json }
    let(:mock_response) { instance_double(HTTParty::Response, body: response_body, success?: true) }

    before do
      allow(HTTParty).to receive(:get).and_return(mock_response)
      allow(mock_response).to receive(:inspect).and_return(response_body)
    end

    it 'exchanges short lived token for long lived token' do
      result = dummy_instance.send(:exchange_for_long_lived_token, short_lived_token)

      expect(HTTParty).to have_received(:get).with(
        'https://graph.instagram.com/access_token',
        {
          query: {
            grant_type: 'ig_exchange_token',
            client_secret: client_secret,
            access_token: short_lived_token,
            client_id: client_id
          },
          headers: { 'Accept' => 'application/json' }
        }
      )

      expect(result).to eq({ 'access_token' => long_lived_token, 'expires_in' => 5_184_000 })
    end

    context 'when the request fails' do
      let(:mock_response) { instance_double(HTTParty::Response, body: 'Error', success?: false, code: 400) }

      it 'raises an error' do
        expect do
          dummy_instance.send(:exchange_for_long_lived_token, short_lived_token)
        end.to raise_error(RuntimeError, 'Failed to exchange token: Error')
      end
    end

    context 'when the response is not valid JSON' do
      let(:mock_response) { instance_double(HTTParty::Response, body: 'Not JSON', success?: true) }

      it 'raises a JSON parse error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('Invalid JSON'))

        expect { dummy_instance.send(:exchange_for_long_lived_token, short_lived_token) }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '#fetch_instagram_user_details' do
    let(:user_details) do
      {
        'id' => '12345',
        'username' => 'test_user',
        'user_id' => '12345',
        'name' => 'Test User',
        'profile_picture_url' => 'https://example.com/profile.jpg',
        'account_type' => 'BUSINESS'
      }
    end
    let(:response_body) { user_details.to_json }
    let(:mock_response) { instance_double(HTTParty::Response, body: response_body, success?: true) }

    before do
      allow(HTTParty).to receive(:get).and_return(mock_response)
      allow(mock_response).to receive(:inspect).and_return(response_body)
    end

    it 'fetches Instagram user details' do
      result = dummy_instance.send(:fetch_instagram_user_details, access_token)

      expect(HTTParty).to have_received(:get).with(
        'https://graph.instagram.com/v22.0/me',
        {
          query: {
            fields: 'id,username,user_id,name,profile_picture_url,account_type',
            access_token: access_token
          },
          headers: { 'Accept' => 'application/json' }
        }
      )

      expect(result).to eq(user_details)
    end

    context 'when the request fails' do
      let(:mock_response) { instance_double(HTTParty::Response, body: 'Error', success?: false, code: 400) }

      it 'raises an error' do
        expect do
          dummy_instance.send(:fetch_instagram_user_details, access_token)
        end.to raise_error(RuntimeError, 'Failed to fetch Instagram user details: Error')
      end
    end

    context 'when the response is not valid JSON' do
      let(:mock_response) { instance_double(HTTParty::Response, body: 'Not JSON', success?: true) }

      it 'raises a JSON parse error' do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('Invalid JSON'))

        expect { dummy_instance.send(:fetch_instagram_user_details, access_token) }.to raise_error(JSON::ParserError)
      end
    end
  end
end
