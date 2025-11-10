FactoryBot.define do
  factory :meta_campaign_interaction do
    inbox { nil }
    account { nil }
    conversation { nil }
    message { nil }
    source_id { 'MyString' }
    source_type { 'MyString' }
    ctwa_clid { 'MyString' }
    metadata { '' }
    interaction_type { 'MyString' }
  end
end
