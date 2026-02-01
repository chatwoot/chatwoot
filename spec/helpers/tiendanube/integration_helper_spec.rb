require 'rails_helper'

RSpec.describe Tiendanube::IntegrationHelper do
  include described_class

  let(:account) { create(:account) }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(client_secret)
  end

  describe '#generate_tiendanube_token' do
    it 'generates a valid JWT token' do
      token = generate_tiendanube_token(account.id)
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'encodes the account ID in the token' do
      token = generate_tiendanube_token(account.id)
      decoded = JWT.decode(token, client_secret, true, { algorithm: 'HS256' })
      expect(decoded.first['sub']).to eq(account.id)
    end
  end

  describe '#verify_tiendanube_token' do
    it 'verifies and decodes a valid token' do
      token = generate_tiendanube_token(account.id)
      expect(verify_tiendanube_token(token)).to eq(account.id)
    end

    it 'returns nil for invalid token' do
      expect(verify_tiendanube_token('invalid_token')).to be_nil
    end

    it 'returns nil when token is blank' do
      expect(verify_tiendanube_token(nil)).to be_nil
      expect(verify_tiendanube_token('')).to be_nil
    end
  end
end
