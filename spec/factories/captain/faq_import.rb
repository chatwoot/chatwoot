FactoryBot.define do
  factory :captain_faq_import, class: 'Captain::FaqImport' do
    association :assistant, factory: :captain_assistant
    account { assistant.account }
    user { association :user, account: account }
    original_filename { 'faqs.csv' }
    rows { [] }
  end
end
