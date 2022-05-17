FactoryBot.define do
  factory :article, class: 'Article' do
    account_id { 1 }
    category_id { 1 }
    folder_id { 1 }
    author_id { 1 }
    title { 'MyString' }
    content { 'MyText' }
    status { 1 }
    views { 1 }
    seo_title { 'MyString' }
    seo { '' }
  end
end
