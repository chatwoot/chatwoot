FactoryBot.define do
  factory :scheduled_message do
    account
    inbox
    conversation
    association :author, factory: :user
    content { 'Scheduled message content' }
    scheduled_at { 2.minutes.from_now }
    status { :pending }
  end
end
