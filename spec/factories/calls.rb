FactoryBot.define do
  factory :call do
    association :conversation
    account { conversation.account }
    inbox { conversation.inbox }
    contact { conversation.contact }
    provider { :twilio }
    direction { :incoming }
    status { 'ringing' }
    sequence(:provider_call_id) { |n| "CA#{SecureRandom.hex(15)}#{n}" }
  end
end
