FactoryBot.define do
  factory :kbase_portal, class: 'Kbase::Portal' do
    account_id { 1 }
    name { 'MyString' }
    subdomain { 'MyString' }
    custom_domain { 'MyString' }
    logo { 'MyString' }
    favicon { 'MyString' }
    footer_title { 'MyString' }
    footer_url { 'MyString' }
    header_image { 'MyString' }
    header_text { 'MyString' }
    homepage_link { 'MyString' }
    page_title { 'MyString' }
    social_media_image { 'MyString' }
  end
end
