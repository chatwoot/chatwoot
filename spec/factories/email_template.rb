FactoryBot.define do
  factory :email_template do
    name { 'MyString' }
    body { 'Email template body' }

    trait :layout do
      name { EmailTemplate::BRANDED_LAYOUT_NAME }
      template_type { :layout }
      body { '<html><body>{{ content_for_layout }}</body></html>' }
    end
  end
end
