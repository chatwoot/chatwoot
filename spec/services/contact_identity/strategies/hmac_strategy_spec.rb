require 'rails_helper'

RSpec.describe ContactIdentity::Strategies::HmacStrategy do
  let(:channel) { create(:channel_widget) }
  let(:identifier) { 'contact-identifier' }
  let(:identifier_hash) { OpenSSL::HMAC.hexdigest('sha256', channel.hmac_token, identifier) }
  let(:params) { ActionController::Parameters.new(identifier_hash: identifier_hash) }
  let(:strategy) { described_class.new(channel: channel, identifier: identifier, params: params) }

  describe '#presented?' do
    it 'is true when the request carries an identifier hash' do
      expect(strategy.presented?).to be(true)
    end

    it 'is false when the identifier hash is missing' do
      strategy = described_class.new(channel: channel, identifier: identifier, params: ActionController::Parameters.new)

      expect(strategy.presented?).to be(false)
    end

    it 'is false when the identifier hash is blank' do
      strategy = described_class.new(channel: channel, identifier: identifier, params: ActionController::Parameters.new(identifier_hash: ''))

      expect(strategy.presented?).to be(false)
    end
  end

  describe '#verify' do
    it 'returns a verified proof when the hash matches the identifier' do
      expect(strategy.verify.status).to eq(ContactIdentity::Proof::VERIFIED)
    end

    it 'names the identifier it verified' do
      expect(strategy.verify.identifier).to eq('contact-identifier')
    end

    it 'returns an invalid proof when the hash was computed for another identifier' do
      strategy = described_class.new(channel: channel, identifier: 'other-identifier', params: params)

      expect(strategy.verify.status).to eq(ContactIdentity::Proof::INVALID)
    end

    it 'returns an invalid proof when the hash was computed with another secret' do
      params = ActionController::Parameters.new(identifier_hash: OpenSSL::HMAC.hexdigest('sha256', 'wrong-token', identifier))
      strategy = described_class.new(channel: channel, identifier: identifier, params: params)

      expect(strategy.verify.status).to eq(ContactIdentity::Proof::INVALID)
    end

    it 'returns an invalid proof when the hash is not a digest' do
      strategy = described_class.new(channel: channel, identifier: identifier, params: ActionController::Parameters.new(identifier_hash: 'test'))

      expect(strategy.verify.status).to eq(ContactIdentity::Proof::INVALID)
    end

    it 'verifies the hash of an empty identifier' do
      params = ActionController::Parameters.new(identifier_hash: OpenSSL::HMAC.hexdigest('sha256', channel.hmac_token, ''))
      strategy = described_class.new(channel: channel, identifier: '', params: params)

      expect(strategy.verify.status).to eq(ContactIdentity::Proof::VERIFIED)
    end

    it 'uses the secret of an API channel' do
      api_channel = create(:channel_api)
      params = ActionController::Parameters.new(identifier_hash: OpenSSL::HMAC.hexdigest('sha256', api_channel.hmac_token, identifier))
      strategy = described_class.new(channel: api_channel, identifier: identifier, params: params)

      expect(strategy.verify.status).to eq(ContactIdentity::Proof::VERIFIED)
    end
  end
end
