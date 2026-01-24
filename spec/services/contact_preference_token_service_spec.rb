# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactPreferenceTokenService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }

  describe '#generate_token' do
    it 'generates a valid JWT token' do
      service = described_class.new(payload: { contact_id: contact.id, account_id: account.id })
      token = service.generate_token

      expect(token).to be_present
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'includes contact_id and account_id in payload' do
      service = described_class.new(payload: { contact_id: contact.id, account_id: account.id })
      token = service.generate_token

      # Decode and verify
      decode_service = described_class.new(token: token)
      decoded = decode_service.decode_token

      expect(decoded[:contact_id]).to eq(contact.id)
      expect(decoded[:account_id]).to eq(account.id)
    end

    it 'sets expiration to 30 days' do
      freeze_time do
        service = described_class.new(payload: { contact_id: contact.id, account_id: account.id })
        token = service.generate_token

        decode_service = described_class.new(token: token)
        decoded = decode_service.decode_token

        expected_exp = (30.days.from_now).to_i
        expect(decoded[:exp]).to eq(expected_exp)
      end
    end
  end

  describe '#decode_token' do
    it 'decodes a valid token' do
      service = described_class.new(payload: { contact_id: contact.id, account_id: account.id })
      token = service.generate_token

      decode_service = described_class.new(token: token)
      decoded = decode_service.decode_token

      expect(decoded[:contact_id]).to eq(contact.id)
      expect(decoded[:account_id]).to eq(account.id)
    end

    it 'returns expired error for expired tokens' do
      # Generate a token that expired yesterday
      expired_token = nil
      travel_to 31.days.ago do
        expired_token = described_class.new(payload: { contact_id: contact.id, account_id: account.id }).generate_token
      end

      decode_service = described_class.new(token: expired_token)
      decoded = decode_service.decode_token

      expect(decoded[:error]).to eq(:expired)
    end

    it 'returns invalid error for malformed tokens' do
      decode_service = described_class.new(token: 'invalid_token')
      decoded = decode_service.decode_token

      expect(decoded[:error]).to eq(:invalid)
    end

    it 'returns invalid error for tokens with wrong signature' do
      # Create a token with a different secret
      wrong_token = JWT.encode(
        { contact_id: contact.id, account_id: account.id, exp: 30.days.from_now.to_i },
        'wrong_secret',
        'HS256'
      )

      decode_service = described_class.new(token: wrong_token)
      decoded = decode_service.decode_token

      expect(decoded[:error]).to eq(:invalid)
    end
  end

  describe '.generate_for_contact' do
    it 'generates a token for a contact' do
      token = described_class.generate_for_contact(contact)

      expect(token).to be_present

      decode_service = described_class.new(token: token)
      decoded = decode_service.decode_token

      expect(decoded[:contact_id]).to eq(contact.id)
      expect(decoded[:account_id]).to eq(contact.account_id)
    end
  end
end
