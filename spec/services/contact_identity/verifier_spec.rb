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

    context 'with an identity token' do
      let(:signing_key) { create(:contact_identity_signing_key, inbox: channel.inbox) }
      let(:identity_token) { JWT.encode({ identifier: 'token-identifier' }, signing_key.secret, 'HS256') }
      let(:token_strategies) { [ContactIdentity::Strategies::JwtStrategy, ContactIdentity::Strategies::HmacStrategy] }

      def proof_with_token_strategy(params)
        described_class.new(channel: channel, identifier: identifier, params: ActionController::Parameters.new(params),
                            strategies: token_strategies).perform
      end

      it 'ignores the identity token by default' do
        expect(proof_for(identity_token: identity_token).none?).to be(true)
      end

      it 'returns the proof of the token when the token strategy is given' do
        proof = proof_with_token_strategy(identity_token: identity_token)

        expect(proof.verified?).to be(true)
        expect(proof.identifier).to eq('token-identifier')
      end

      it 'returns an invalid proof when the request carries two kinds of proof' do
        proof = proof_with_token_strategy(identity_token: identity_token, identifier_hash: identifier_hash)

        expect(proof.verified?).to be(false)
        expect(proof.none?).to be(false)
      end
    end
  end
end
