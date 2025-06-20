FactoryBot.define do
  factory :application do
    name { 'MyString' }
    url { 'MyString' }
    description { 'MyText' }
    status { 'MyString' }
    account { nil }
  end
end
