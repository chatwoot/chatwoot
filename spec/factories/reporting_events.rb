FactoryBot.define do
  factory :reporting_event do
    name { 'first_response' }
    value { 1.5 }
    value_in_business_hours { 1 }
    account
    inbox { association :inbox, account: account }
    user { association :user, account: account }
    conversation { association :conversation, account: account, inbox: inbox }
    event_start_time { 2.hours.ago }
    event_end_time { 1.hour.ago }
  end
end
