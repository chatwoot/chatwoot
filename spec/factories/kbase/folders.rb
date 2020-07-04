FactoryBot.define do
  factory :kbase_folder, class: 'Kbase::Folder' do
    account_id { 1 }
    name { 'MyString' }
    description { 'MyText' }
    category_id { 1 }
  end
end
