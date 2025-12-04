FactoryBot.define do
  factory :user_assignment do
    advanced_email_template { nil }
    user { nil }
    active { false }
  end
end
