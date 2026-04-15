# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::HubTokenValidator do
  describe '.validate' do
    let(:jwks_url) { 'https://hub.example.com/.well-known/jwks.json' }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HUB_JWKS_URL', anything).and_return(jwks_url)
    end

    it 'rejects nil token' do
      result = described_class.validate(nil)
      expect(result).to be_nil
    end

    it 'rejects empty string token' do
      result = described_class.validate('')
      expect(result).to be_nil
    end

    it 'rejects malformed JWT (not 3 parts)' do
      result = described_class.validate('not-a-jwt')
      expect(result).to be_nil
    end

    it 'rejects JWT with invalid header encoding' do
      result = described_class.validate('!!!.payload.signature')
      expect(result).to be_nil
    end

    it 'does not raise on any invalid input' do
      invalid_tokens = [
        nil, '', 'x', 'a.b', 'a.b.c', '{}', 'null',
        '<script>alert(1)</script>',
        "'; DROP TABLE users; --",
        'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwIn0.',
      ]

      invalid_tokens.each do |token|
        expect { described_class.validate(token) }.not_to raise_error
      end
    end
  end
end
