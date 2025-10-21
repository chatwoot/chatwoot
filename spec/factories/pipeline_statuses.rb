FactoryBot.define do
  factory :pipeline_status do
    name { Faker::Lorem.word }
    account
  end
end
