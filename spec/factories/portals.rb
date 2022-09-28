FactoryBot.define do
  factory :portal, class: 'Portal' do
    account
    name { Faker::Book.name }
    slug { SecureRandom.hex }
  end
end
