FactoryBot.define do
  factory :team do
    name { 'MyString' }
    description { 'MyText' }
    allow_auto_assign { true }
    account
  end
end
