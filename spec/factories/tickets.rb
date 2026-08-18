FactoryBot.define do
  factory :ticket do
    association :conversation
    account { conversation.account }
    sequence(:subject) { |n| "Case #{n}" }
    ticket_type { 'question' }
    waiting_on { :none }
  end
end
