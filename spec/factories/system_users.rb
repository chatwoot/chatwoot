FactoryBot.define do
  factory :system_user do
    name { Faker::Name.name }
    email { "admin@#{SecureRandom.uuid}.com" }
    password { 'Password1!' }
    type { 'SystemUser' }
    confirmed_at { Time.zone.now }
  end
end
