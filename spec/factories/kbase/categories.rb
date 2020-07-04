FactoryBot.define do
  factory :kbase_category, class: 'Kbase::Category' do
    account_id { 1 }
    name { 'MyString' }
    description { 'MyText' }
    position { 1 }
  end
end
