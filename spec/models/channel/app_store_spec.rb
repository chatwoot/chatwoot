# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::AppStore do
  describe 'validations' do
    it 'normalizes auth fields and stores app metadata from App Store Connect' do
      app_store_client = instance_double(AppStoreConnect::Client)
      channel = build(
        :channel_app_store,
        account: create(:account),
        app_id: ' 123456789 ',
        issuer_id: ' issuer-id ',
        key_id: ' key-id ',
        private_key: "-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----\r\n",
        app_name: nil,
        bundle_id: nil
      )

      allow(channel).to receive(:app_store_client).and_return(app_store_client)
      allow(app_store_client).to receive(:fetch_app).and_return(
        {
          'attributes' => {
            'name' => 'Chatwoot iOS',
            'bundleId' => 'com.chatwoot.app'
          }
        }
      )

      expect(channel).to be_valid
      expect(channel.app_id).to eq('123456789')
      expect(channel.issuer_id).to eq('issuer-id')
      expect(channel.key_id).to eq('key-id')
      expect(channel.private_key).to eq("-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----")
      expect(channel.app_name).to eq('Chatwoot iOS')
      expect(channel.bundle_id).to eq('com.chatwoot.app')
    end

    it 'adds an error when App Store Connect validation fails' do
      app_store_client = instance_double(AppStoreConnect::Client)
      channel = build(:channel_app_store)

      allow(channel).to receive(:app_store_client).and_return(app_store_client)
      allow(app_store_client).to receive(:fetch_app).and_raise(AppStoreConnect::Client::Error, 'invalid credentials')

      expect(channel).not_to be_valid
      expect(channel.errors[:base]).to include('invalid credentials')
    end
  end

  describe '#sync_due?' do
    it 'returns true when the channel has never synced' do
      channel = build(:channel_app_store, last_synced_at: nil)

      expect(channel.sync_due?).to be true
    end

    it 'returns false when the last sync is within the sync interval' do
      channel = build(:channel_app_store, last_synced_at: 30.minutes.ago)

      expect(channel.sync_due?).to be false
    end
  end
end
