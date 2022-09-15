FactoryBot.define do
  factory :agent_bot do
    name { 'MyString' }
    description { 'MyString' }
    outgoing_url { 'MyString' }
    bot_config { {} }
    bot_type { 'webhook' }

    trait :skip_validate do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
