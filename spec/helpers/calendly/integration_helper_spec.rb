require 'rails_helper'

RSpec.describe Calendly::IntegrationHelper do
  include described_class

  let(:account_id) { 1 }
  let(:client_secret_value) { 'test_calendly_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).with('CALENDLY_CLIENT_SECRET', nil).and_return(client_secret_value)
  end

  describe '#generate_calendly_token' do
    it 'generates a valid JWT with sub, iat, and exp claims' do
      token = generate_calendly_token(account_id)
      decoded = JWT.decode(token, client_secret_value, true, algorithm: 'HS256').first

      expect(decoded['sub']).to eq(account_id)
      expect(decoded['iat']).to be_present
      expect(decoded['exp']).to be_present
      expect(decoded['exp']).to be > decoded['iat']
    end

    context 'when client secret is not configured' do
      let(:client_secret_value) { nil }

      it 'returns nil' do
        expect(generate_calendly_token(account_id)).to be_nil
      end
    end
  end

  describe '#verify_calendly_token' do
    it 'round-trips successfully within 10 minutes' do
      token = generate_calendly_token(account_id)
      expect(verify_calendly_token(token)).to eq(account_id)
    end

    it 'rejects an expired token after 15 minutes' do
      token = generate_calendly_token(account_id)

      travel_to 15.minutes.from_now do
        expect(verify_calendly_token(token)).to be_nil
      end
    end

    it 'rejects a tampered token' do
      token = generate_calendly_token(account_id)
      tampered = token + 'x'

      expect(verify_calendly_token(tampered)).to be_nil
    end

    context 'when token is blank' do
      it 'returns nil' do
        expect(verify_calendly_token('')).to be_nil
        expect(verify_calendly_token(nil)).to be_nil
      end
    end

    context 'when client secret is not configured' do
      let(:client_secret_value) { nil }

      it 'returns nil' do
        token = JWT.encode({ sub: account_id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i }, 'some_secret', 'HS256')
        expect(verify_calendly_token(token)).to be_nil
      end
    end
  end
end
