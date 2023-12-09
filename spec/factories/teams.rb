FactoryBot.define do
  factory :team do
    name { Faker::Team.name }
    description { Faker::Lorem.sentence }
    allow_auto_assign { true }
    account
  end
end
