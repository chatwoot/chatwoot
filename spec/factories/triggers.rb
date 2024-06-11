FactoryBot.define do
  factory :trigger do
    companyId { Faker::Number.number(digits: 1) }
  end
end
