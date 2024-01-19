FactoryBot.define do
  factory :sla_policy do
    account
    name { 'sla_1' }
    first_response_time { 2000 }
    next_response_time { 1000 }
    resolution_time { 3000 }
    only_during_business_hours { false }
  end
end
