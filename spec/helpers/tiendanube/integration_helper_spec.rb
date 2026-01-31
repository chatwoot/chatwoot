require 'rails_helper'

RSpec.describe Tiendanube::IntegrationHelper, type: :helper do
  let(:account) { create(:account) }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(client_secret)
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

    it 'returns nil when client secret is blank' do
      allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(nil)
      token = helper.generate_tiendanube_token(account.id)
      expect(token).to be_nil
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

    it 'returns nil when client secret is blank' do
      allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(nil)
      account_id = helper.verify_tiendanube_token('some_token')
      expect(account_id).to be_nil
    end
  end
end
