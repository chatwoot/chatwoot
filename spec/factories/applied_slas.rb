FactoryBot.define do
  factory :applied_sla do
    sla_policy
    conversation
    sla_status { 'active' }

    after(:build) do |applied_sla|
      applied_sla.account ||= applied_sla.conversation&.account || create(:account)
    end
  end
end
