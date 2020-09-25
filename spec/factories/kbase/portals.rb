FactoryBot.define do
  factory :kbase_portal, class: 'Kbase::Portal' do
    account
    name { Faker::Book.name }
    slug { SecureRandom.hex }
  end
end
