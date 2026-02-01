require 'rails_helper'

RSpec.describe Tiendanube::IntegrationHelper, type: :helper do
  let(:account) { create(:account) }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }

  before do
    stub_client_id = client_id
    stub_client_secret_val = client_secret
    allow(GlobalConfigService).to receive(:load) do |key, default_val|
      case key
      when 'TIENDANUBE_CLIENT_ID' then stub_client_id
      when 'TIENDANUBE_CLIENT_SECRET' then stub_client_secret_val
      else default_val
      end
    end
    helper.instance_variable_set(:@client_id, nil)
    helper.instance_variable_set(:@client_secret, nil)
  end

  describe '#generate_tiendanube_token' do
    it 'generates a valid JWT token' do
      token = helper.generate_tiendanube_token(account.id)
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'encodes the account ID in the token' do
      token = helper.generate_tiendanube_token(account.id)
      decoded = JWT.decode(token, client_secret, true, { algorithm: 'HS256' })
      expect(decoded.first['sub']).to eq(account.id)
    end

    context 'when client secret is blank' do
      let(:client_secret) { nil }

      it 'returns nil' do
        helper.instance_variable_set(:@client_secret, nil)
        token = helper.generate_tiendanube_token(account.id)
        expect(token).to be_nil
      end
    end
  end

  describe '#verify_tiendanube_token' do
    it 'verifies and decodes a valid token' do
      token = helper.generate_tiendanube_token(account.id)
      account_id = helper.verify_tiendanube_token(token)
      expect(account_id).to eq(account.id)
    end

    it 'returns nil for invalid token' do
      account_id = helper.verify_tiendanube_token('invalid_token')
      expect(account_id).to be_nil
    end

    it 'returns nil when token is blank' do
      account_id = helper.verify_tiendanube_token(nil)
      expect(account_id).to be_nil
    end

    context 'when client secret is blank' do
      let(:client_secret) { nil }

      it 'returns nil' do
        helper.instance_variable_set(:@client_secret, nil)
        account_id = helper.verify_tiendanube_token('some_token')
        expect(account_id).to be_nil
      end
    end
  end
end
