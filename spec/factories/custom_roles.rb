FactoryBot.define do
  factory :custom_role do
    account
    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    permissions { CustomRole::PERMISSIONS.sample(SecureRandom.random_number(4)) }
  end
end
