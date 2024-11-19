FactoryBot.define do
  factory :sla_policy do
    account
    name { 'sla_1' }
    first_response_time_threshold { 2000 }
    description { 'SLA policy for enterprise customers' }
    next_response_time_threshold { 1000 }
    resolution_time_threshold { 3000 }
    only_during_business_hours { false }
  end
end
