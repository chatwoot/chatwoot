FactoryBot.define do
  factory :folder, class: 'Folder' do
    account_id { 1 }
    name { 'MyString' }
    description { 'MyText' }
    category_id { 1 }
  end
end
