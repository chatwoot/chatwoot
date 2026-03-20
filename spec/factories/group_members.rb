FactoryBot.define do
  factory :group_member do
    group_contact { association :contact, group_type: :group }
    contact { association :contact, account: group_contact.account }

    trait :admin do
      role { :admin }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
