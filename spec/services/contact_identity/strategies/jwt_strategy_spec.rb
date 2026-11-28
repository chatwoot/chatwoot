require 'rails_helper'

RSpec.describe ContactIdentity::Strategies::JwtStrategy do
  let(:channel) { create(:channel_widget) }
  let(:signing_key) { create(:contact_identity_signing_key, inbox: channel.inbox) }
  let(:claims) { { identifier: 'contact-identifier' } }

  def token_for(claims, secret: signing_key.secret, algorithm: 'HS256')
    JWT.encode(claims, secret, algorithm)
  end

  def strategy_for(token)
    described_class.new(channel: channel, identifier: nil, params: ActionController::Parameters.new(identity_token: token))
  end

  describe '#presented?' do
    it 'is true when the request carries an identity token' do
      expect(strategy_for(token_for(claims)).presented?).to be(true)
    end

    it 'is false when the identity token is blank' do
      expect(strategy_for('').presented?).to be(false)
    end

    it 'is false when the identity token is missing' do
      strategy = described_class.new(channel: channel, identifier: nil, params: ActionController::Parameters.new)

      expect(strategy.presented?).to be(false)
    end
  end

  describe '#verify' do
    it 'returns a verified proof with the identifier the token carries' do
      proof = strategy_for(token_for(claims)).verify

      expect(proof.verified?).to be(true)
      expect(proof.identifier).to eq('contact-identifier')
    end

    it 'returns the contact details the token carries and drops other claims' do
      details = { name: 'Priya', email: 'priya@example.com', phone_number: '+919999888877', avatar_url: 'https://example.com/priya.png',
                  custom_attributes: { plan: 'pro' } }
      proof = strategy_for(token_for(claims.merge(details).merge(role: 'admin', account_id: 1))).verify

      expect(proof.attributes).to eq(details.deep_stringify_keys)
    end

    it 'turns a numeric identifier into a string' do
      proof = strategy_for(token_for({ identifier: 42 })).verify

      expect(proof.identifier).to eq('42')
    end

    it 'verifies a token signed with either key of the inbox' do
      signing_key
      second_key = create(:contact_identity_signing_key, inbox: channel.inbox)
      proof = strategy_for(token_for(claims, secret: second_key.secret)).verify

      expect(proof.verified?).to be(true)
    end

    context 'with an expiry' do
      it 'verifies a token that has not expired' do
        expect(strategy_for(token_for(claims.merge(exp: 5.minutes.from_now.to_i))).verify.verified?).to be(true)
      end

      it 'returns an invalid proof when the token has expired' do
        proof = strategy_for(token_for(claims.merge(exp: 1.minute.ago.to_i))).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end
    end

    context 'with a signature that does not hold' do
      it 'returns an invalid proof when the token was signed with another secret' do
        proof = strategy_for(token_for(claims, secret: 'a' * 64)).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof for an unsigned token' do
        proof = strategy_for(token_for(claims, secret: nil, algorithm: 'none')).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the token uses another algorithm' do
        proof = strategy_for(token_for(claims, algorithm: 'HS512')).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof for a string that is not a token' do
        expect(strategy_for('not-a-token').verify.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the identity token is not a string' do
        expect(strategy_for({ nested: 'value' }).verify.status).to eq(ContactIdentity::Proof::INVALID)
      end
    end

    context 'with a key the inbox does not have' do
      it 'returns an invalid proof when the key belongs to another inbox' do
        signing_key
        other_key = create(:contact_identity_signing_key)
        proof = strategy_for(token_for(claims, secret: other_key.secret)).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the inbox has no signing keys' do
        proof = strategy_for(token_for(claims, secret: 'a' * 64)).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof for an unsigned token when the inbox has no signing keys' do
        proof = strategy_for(token_for(claims, secret: nil, algorithm: 'none')).verify

        expect(proof.status).to eq(ContactIdentity::Proof::INVALID)
      end
    end

    context 'without a usable identifier' do
      it 'returns an invalid proof when the token carries no identifier' do
        expect(strategy_for(token_for({ name: 'Priya' })).verify.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the identifier is blank' do
        expect(strategy_for(token_for({ identifier: '' })).verify.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the identifier is not a string or a number' do
        expect(strategy_for(token_for({ identifier: { id: 1 } })).verify.status).to eq(ContactIdentity::Proof::INVALID)
      end

      it 'returns an invalid proof when the claims are not an object' do
        expect(strategy_for(token_for(['contact-identifier'])).verify.status).to eq(ContactIdentity::Proof::INVALID)
      end
    end
  end
end
