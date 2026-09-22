FactoryBot.define do
  factory :conversation_monitor, class: 'ConversationMonitors::Monitor' do
    account
    name { 'Refunds' }
    condition { 'All conversations mentioning refunds' }
    model { 'jev-1.13.0' }
    threshold { 0.65 }
    history_since { 7.days.ago }

    after(:create, &:create_backfill!)
  end
end
