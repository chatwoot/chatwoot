FactoryBot.define do
  factory :canned_response_scope do
    canned_response
    user_ids { [] }
    team_ids { [] }
    inbox_ids { [] }

    trait :user_scope do
      user_ids { [create(:user).id] }
    end

    trait :team_scope do
      team_ids { [create(:team).id] }
    end

    trait :inbox_scope do
      inbox_ids { [create(:inbox).id] }
    end
  end
end
