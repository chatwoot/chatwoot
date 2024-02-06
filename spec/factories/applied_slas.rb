FactoryBot.define do
  factory :applied_sla do
    account
    sla_policy
    conversation
    sla_status { 'active' }
  end
end
