FactoryBot.define do
  factory :captain_copilot_thread, class: 'CopilotThread' do
    account
    user
    title { Faker::Lorem.sentence }
    uuid { SecureRandom.uuid }
  end
end
