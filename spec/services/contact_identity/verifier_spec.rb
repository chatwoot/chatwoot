require 'rails_helper'

RSpec.describe ContactIdentity::Verifier do
  let(:channel) { create(:channel_widget) }
  let(:identifier) { 'contact-identifier' }
  let(:identifier_hash) { OpenSSL::HMAC.hexdigest('sha256', channel.hmac_token, identifier) }

  def proof_for(params)
    described_class.new(channel: channel, identifier: identifier, params: ActionController::Parameters.new(params)).perform
  end

  describe '#perform' do
    it 'returns a none proof when the request carries no proof' do
      proof = proof_for({})

      expect(proof.none?).to be(true)
      expect(proof.verified?).to be(false)
    end

    it 'returns a verified proof when the identifier hash matches' do
      proof = proof_for(identifier_hash: identifier_hash)

      expect(proof.verified?).to be(true)
      expect(proof.none?).to be(false)
    end

    it 'returns an invalid proof when the identifier hash does not match' do
      proof = proof_for(identifier_hash: 'test')

      expect(proof.verified?).to be(false)
      expect(proof.none?).to be(false)
    end
  end
end
