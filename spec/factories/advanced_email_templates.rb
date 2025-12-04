FactoryBot.define do
  factory :advanced_email_template do
    name { 'MyString' }
    friendly_name { 'MyString' }
    description { 'MyText' }
    template_type { 'MyString' }
    html { 'MyText' }
    account { nil }
  end
end
