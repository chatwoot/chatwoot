FactoryBot.define do
  factory :sla_policy do
    account
    name { 'sla_1' }
    rt_threshold { 1000 }
    frt_threshold { 2000 }
    only_during_business_hours { false }
  end
end
