FactoryBot.define do
  factory :conversation_monitor, class: 'ConversationMonitors::Monitor' do
    account
    name { 'Refunds' }
    condition { 'All conversations mentioning refunds' }
    model { 'typesafe/jev-1.13' }
    threshold { 0.6 }
    history_since { 7.days.ago }

    after(:create) do |monitor|
      monitor.scans.create!(kind: 'initial', started_at: monitor.history_since, ended_at: monitor.created_at,
                            collection_version: monitor.collection_version)
    end
  end
end
