FactoryBot.define do
  factory :team do
    name { Faker::Name.name }
    description { 'MyText' }
    allow_auto_assign { true }
    account
  end
end
