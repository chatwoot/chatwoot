require 'rails_helper'

RSpec.describe Linear::IntegrationHelper do
  include described_class

  describe '#generate_linear_token' do
    let(:account_id) { 1 }
    let(:client_secret) { 'test_secret' }
    let(:current_time) { Time.current }

    before do
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
      allow(Time).to receive(:current).and_return(current_time)
    end

    it 'generates a valid JWT token with correct payload' do
      token = generate_linear_token(account_id)
      decoded_token = JWT.decode(token, client_secret, true, algorithm: 'HS256').first

      expect(decoded_token['sub']).to eq(account_id)
      expect(decoded_token['iat']).to eq(current_time.to_i)
      expect(decoded_token['exp']).to eq((current_time + 10.minutes).to_i)
      expect(decoded_token['aud']).to eq('linear_oauth')
    end

    context 'when client secret is not configured' do
      let(:client_secret) { nil }

      it 'returns nil' do
        expect(generate_linear_token(account_id)).to be_nil
      end
    end

    context 'when an error occurs' do
      before do
        allow(JWT).to receive(:encode).and_raise(StandardError.new('Test error'))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with('Failed to generate Linear token: Test error')
        expect(generate_linear_token(account_id)).to be_nil
      end
    end
  end

  describe '#verify_linear_token' do
    let(:account_id) { 1 }
    let(:client_secret) { 'test_secret' }
    let(:valid_token) do
      JWT.encode(
        { sub: account_id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i, aud: 'linear_oauth' },
        client_secret,
        'HS256'
      )
    end

    before do
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
    end

    it 'successfully verifies and returns account_id from valid token' do
      expect(verify_linear_token(valid_token)).to eq(account_id)
    end

    it 'returns catalog claims without allowing them to replace base claims' do
      token = generate_linear_token(
        account_id,
        claims: { installation_id: 19, nonce: 'nonce-value', sub: 999, aud: 'attacker' }
      )

      expect(verify_linear_state(token)).to include(
        'sub' => account_id,
        'aud' => 'linear_oauth',
        'installation_id' => 19,
        'nonce' => 'nonce-value'
      )
    end

    context 'when token is blank' do
      it 'returns nil' do
        expect(verify_linear_token('')).to be_nil
        expect(verify_linear_token(nil)).to be_nil
      end
    end

    context 'when client secret is not configured' do
      let(:client_secret) { nil }
      let(:valid_token) { 'any-token' }

      it 'returns nil' do
        expect(verify_linear_token(valid_token)).to be_nil
      end
    end

    context 'when token is invalid' do
      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Unexpected error verifying Linear token:/)
        expect(verify_linear_token('invalid_token')).to be_nil
      end
    end

    context 'when the token is expired or has the wrong audience' do
      it 'returns nil' do
        expired = JWT.encode(
          { sub: account_id, exp: 1.minute.ago.to_i, aud: 'linear_oauth' },
          client_secret,
          'HS256'
        )
        wrong_audience = JWT.encode(
          { sub: account_id, exp: 10.minutes.from_now.to_i, aud: 'another_integration' },
          client_secret,
          'HS256'
        )

        expect(verify_linear_token(expired)).to be_nil
        expect(verify_linear_token(wrong_audience)).to be_nil
      end
    end
  end
end
