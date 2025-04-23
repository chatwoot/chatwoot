FactoryBot.define do
  factory :shopee_item, class: 'Shopee::Item' do
    sku { "MyString" }
    code { "MyString" }
    name { "MyString" }
    status { "MyString" }
  end
end
