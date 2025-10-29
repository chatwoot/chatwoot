FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    description { 'MyText' }
    allow_auto_assign { true }
    account
  end
end
