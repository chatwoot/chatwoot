FactoryBot.define do
  factory :trigger do
    processedAt { nil }
    companyId { Faker::Number.number(digits: 1) }
  end
end
