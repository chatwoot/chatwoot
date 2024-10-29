FactoryBot.define do
  factory :sla_event do
    applied_sla
    conversation
    event_type { 'frt' }
    account { conversation.account }
    inbox { conversation.inbox }
    sla_policy { applied_sla.sla_policy }
  end
end
