FactoryBot.define do
  factory :super_admin do
    email { "admin@#{SecureRandom.uuid}.com" }
    password { 'password' }
  end
end
