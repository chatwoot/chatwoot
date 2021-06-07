FactoryBot.define do
  factory :super_admin do
    email { "admin@#{SecureRandom.uuid}.com" }
    password { 'Password1!' }
  end
end
