# frozen_string_literal: true

FactoryBot.define do
  factory :team_member do
    user
    team

    after(:create) do |team_member|
      unless team_member.user.account_users.exists?(account: team_member.team.account)
        create(:account_user, user: team_member.user,
                              account: team_member.team.account)
      end
    end
  end
end
