FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.password }
    provider { 'email' }

    transient do
      allow_unconfirmed_period { Time.now.utc - Devise.allow_unconfirmed_access_for }
    end

    trait :with_nickname do
      nickname { Faker::Internet.username }
    end

    trait :confirmed do
      after(:create) { |user| user.confirm }
    end

    # confirmation period is expired
    trait :unconfirmed do
      after(:create) do |user, evaluator|
        user.update_attribute(:confirmation_sent_at, evaluator.allow_unconfirmed_period - 1.day )
      end
    end

    trait :facebook do
      uid { Faker::Number.number }
      provider { 'facebook' }
    end

    trait :locked do
      after(:create) { |user| user.lock_access! }
    end

    factory :lockable_user, class: 'LockableUser'
    factory :mang_user, class: 'Mang'
    factory :only_email_user, class: 'OnlyEmailUser'
    factory :scoped_user, class: 'ScopedUser'
    factory :confirmable_user, class: 'ConfirmableUser'
  end
end
