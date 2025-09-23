require 'rails_helper'

describe Widget::TokenService do
  let(:payload) { { source_id: 'contact_123', inbox_id: 1 } }
  let(:token_service) { described_class.new(payload: payload) }

  describe 'inheritance' do
    it 'inherits from BaseTokenService' do
      expect(described_class.superclass).to eq(BaseTokenService)
    end
  end

  describe '#generate_token' do
    it 'generates a JWT token with the provided payload' do
      token = token_service.generate_token
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'encodes the payload correctly' do
      token = token_service.generate_token
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
      expect(decoded['source_id']).to eq('contact_123')
      expect(decoded['inbox_id']).to eq(1)
    end
  end

  describe '#decode_token' do
    let(:token) { token_service.generate_token }
    let(:decoder_service) { described_class.new(token: token) }

    it 'decodes a valid JWT token' do
      decoded = decoder_service.decode_token
      expect(decoded[:source_id]).to eq('contact_123')
      expect(decoded[:inbox_id]).to eq(1)
    end

    it 'returns empty hash for invalid token' do
      invalid_service = described_class.new(token: 'invalid_token')
      expect(invalid_service.decode_token).to eq({})
    end
  end
end
