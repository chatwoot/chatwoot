FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:domain) { |n| "company#{n}.com" }
    description { 'A sample company description' }
    account

    trait :without_domain do
      domain { nil }
    end

    trait :with_avatar do
      avatar { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    end

    trait :with_long_description do
      description { 'A' * 500 }
    end
  end
end
