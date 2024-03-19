FactoryBot.define do
  factory :sla_event do
    applied_sla
    conversation
    event_type { 'frt' }
    metadata { '' }
  end
end
