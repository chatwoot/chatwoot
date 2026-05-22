# frozen_string_literal: true

FactoryBot.define do
  factory :channel_app_store, class: 'Channel::AppStore' do
    account
    app_id { SecureRandom.random_number(1_000_000_000..9_999_999_999).to_s }
    bundle_id { 'com.example.app' }
    app_name { 'Example App' }
    issuer_id { SecureRandom.uuid }
    key_id { SecureRandom.alphanumeric(10).upcase }
    private_key do
      key = OpenSSL::PKey::EC.generate('prime256v1')
      key.to_pem
    end

    to_create { |instance| instance.save!(validate: false) }

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
