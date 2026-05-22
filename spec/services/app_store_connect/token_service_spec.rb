# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppStoreConnect::TokenService do
  let(:private_key) { OpenSSL::PKey::EC.generate('prime256v1').to_pem }
  let(:channel) do
    instance_double(
      Channel::AppStore,
      id: 1,
      updated_at: Time.zone.at(1_700_000_000),
      issuer_id: 'issuer-id',
      key_id: 'key-id',
      private_key: private_key
    )
  end

  describe '#token' do
    it 'generates an App Store Connect JWT with the expected claims and headers' do
      travel_to Time.zone.local(2026, 5, 22, 9, 0, 0) do
        token = described_class.new(channel: channel).token
        payload, header = JWT.decode(token, nil, false)

        expect(payload).to include(
          'iss' => 'issuer-id',
          'iat' => Time.current.to_i,
          'exp' => 19.minutes.from_now.to_i,
          'aud' => 'appstoreconnect-v1'
        )
        expect(header).to include('kid' => 'key-id', 'typ' => 'JWT', 'alg' => 'ES256')
      end
    end

    it 'returns cached tokens for the channel' do
      allow(Rails.cache).to receive(:read).with('app_store_connect_token:1:1700000000').and_return('cached-token')

      expect(described_class.new(channel: channel).token).to eq('cached-token')
    end
  end
end
