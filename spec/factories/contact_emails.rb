FactoryBot.define do
  factory :contact_email do
    account
    contact { association :contact, account: account }
    sequence(:email) { |n| "contact-email-#{n}@example.com" }
    primary { false }
  end
end
