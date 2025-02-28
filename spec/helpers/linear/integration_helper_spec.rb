require 'rails_helper'

RSpec.describe Linear::IntegrationHelper do
  include described_class

  describe '#generate_linear_token' do
    let(:account_id) { 1 }
    let(:client_secret) { 'test_secret' }
    let(:current_time) { Time.current }

    before do
      allow(ENV).to receive(:fetch).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
      allow(Time).to receive(:current).and_return(current_time)
    end

    it 'generates a valid JWT token with correct payload' do
      token = generate_linear_token(account_id)
      decoded_token = JWT.decode(token, client_secret, true, algorithm: 'HS256').first

      expect(decoded_token['sub']).to eq(account_id)
      expect(decoded_token['iat']).to eq(current_time.to_i)
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
      JWT.encode({ sub: account_id, iat: Time.current.to_i }, client_secret, 'HS256')
    end

    before do
      allow(ENV).to receive(:fetch).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
    end

    it 'successfully verifies and returns account_id from valid token' do
      expect(verify_linear_token(valid_token)).to eq(account_id)
    end

    context 'when token is blank' do
      it 'returns nil' do
        expect(verify_linear_token('')).to be_nil
        expect(verify_linear_token(nil)).to be_nil
      end
    end

    context 'when client secret is not configured' do
      let(:client_secret) { nil }

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
  end
end
