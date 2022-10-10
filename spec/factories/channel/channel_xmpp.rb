FactoryBot.define do
  factory :channel_xmpp, class: 'Channel::Xmpp' do
    account
    jid { 'chatwoot@example.com' }
    password { 'password' }

    after(:create) do |channel_xmpp|
      create(:inbox, channel: channel_xmpp, account: channel_xmpp.account)
    end
  end
end
