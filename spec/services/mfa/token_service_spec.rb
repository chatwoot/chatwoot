require 'rails_helper'

describe Mfa::TokenService do
  before do
    skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
  end

  let(:user) { create(:user) }
  let(:token_service) { described_class.new(user: user) }

  describe '#generate_token' do
    it 'generates a JWT token with user_id' do
      token = token_service.generate_token
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'includes user_id in the payload' do
      token = token_service.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'sets expiration to 5 minutes from now' do
      allow(Time).to receive(:now).and_return(Time.zone.parse('2024-01-01 12:00:00'))
      token = token_service.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
      expected_exp = Time.zone.parse('2024-01-01 12:05:00').to_i
      expect(decoded['exp']).to eq(expected_exp)
    end
  end

  describe '#verify_token' do
    let(:valid_token) { token_service.generate_token }

    context 'with valid token' do
      it 'returns the user' do
        verifier = described_class.new(token: valid_token)
        verified_user = verifier.verify_token
        expect(verified_user).to eq(user)
      end
    end

    context 'with invalid token' do
      it 'returns nil for malformed token' do
        verifier = described_class.new(token: 'invalid_token')
        expect(verifier.verify_token).to be_nil
      end

      it 'returns nil for expired token' do
        expired_payload = { user_id: user.id, exp: 1.minute.ago.to_i }
        expired_token = JWT.encode(expired_payload, Rails.application.secret_key_base, 'HS256')
        verifier = described_class.new(token: expired_token)
        expect(verifier.verify_token).to be_nil
      end

      it 'returns nil for non-existent user' do
        payload = { user_id: 999_999, exp: 5.minutes.from_now.to_i }
        token = JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
        verifier = described_class.new(token: token)
        expect(verifier.verify_token).to be_nil
      end
    end

    context 'with blank token' do
      it 'returns nil' do
        verifier = described_class.new(token: nil)
        expect(verifier.verify_token).to be_nil
      end
    end
  end
end
