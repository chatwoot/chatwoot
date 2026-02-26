FactoryBot.define do
  factory :super_admin do
    name { Faker::Name.name }
    email { "admin@#{SecureRandom.uuid}.com" }
    password { 'Password1!' }
    type { 'SuperAdmin' }
    confirmed_at { Time.zone.now }
  end
end
