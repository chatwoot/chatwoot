FactoryBot.define do
  factory :captain_message_report, class: 'Captain::MessageReport' do
    report_reason { 'incorrect_information' }
    description { 'The generated citation is wrong.' }
    association :account
    association :conversation
    association :message
    association :user
  end
end
