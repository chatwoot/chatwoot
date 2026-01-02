require 'rails_helper'

describe BaseTokenService do
  let(:payload) { { user_id: 1, exp: 5.minutes.from_now.to_i } }
  let(:token_service) { described_class.new(payload: payload) }

  describe '#generate_token' do
    it 'generates a JWT token with the provided payload' do
      token = token_service.generate_token
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'encodes the payload correctly' do
      token = token_service.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
      expect(decoded['user_id']).to eq(1)
    end
  end

  describe '#decode_token' do
    let(:token) { token_service.generate_token }
    let(:decoder_service) { described_class.new(token: token) }

    it 'decodes a valid JWT token' do
      decoded = decoder_service.decode_token
      expect(decoded[:user_id]).to eq(1)
    end

    it 'returns empty hash for invalid token' do
      invalid_service = described_class.new(token: 'invalid_token')
      expect(invalid_service.decode_token).to eq({})
    end

    it 'returns empty hash for expired token' do
      expired_payload = { user_id: 1, exp: 1.minute.ago.to_i }
      expired_token = JWT.encode(expired_payload, Rails.application.secret_key_base, 'HS256')
      expired_service = described_class.new(token: expired_token)
      expect(expired_service.decode_token).to eq({})
    end
  end
end
