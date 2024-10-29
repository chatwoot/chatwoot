FactoryBot.define do
  factory :channel_telegram, class: 'Channel::Telegram' do
    bot_token { '2324234324' }
    account

    before(:create) do |channel_telegram|
      # we are skipping some of the validation methods
      channel_telegram.define_singleton_method(:ensure_valid_bot_token) { nil }
      channel_telegram.define_singleton_method(:setup_telegram_webhook) { nil }
    end

    after(:create) do |channel_telegram|
      create(:inbox, channel: channel_telegram, account: channel_telegram.account)
    end
  end
end
