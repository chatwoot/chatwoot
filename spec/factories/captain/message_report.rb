FactoryBot.define do
  factory :captain_message_report, class: 'Captain::MessageReport' do
    report_reason { 'incorrect_information' }
    description { 'The generated citation is wrong.' }
    association :message
    association :user
  end
end
