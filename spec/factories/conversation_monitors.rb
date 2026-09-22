FactoryBot.define do
  factory :conversation_monitor, class: 'ConversationMonitors::Monitor' do
    account
    name { 'Refunds' }
    condition { 'All conversations mentioning refunds' }
    model { 'typesafe/jev-1.13' }
    threshold { 0.6 }
    history_since { 7.days.ago }

    after(:create, &:create_backfill!)
  end
end
