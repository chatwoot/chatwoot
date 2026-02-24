FactoryBot.define do
  factory :platform_app_permissible do
    platform_app
    permissible { create(:user) }
  end
end
