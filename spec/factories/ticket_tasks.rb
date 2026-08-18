FactoryBot.define do
  factory :ticket_task do
    association :ticket
    account { ticket.account }
    sequence(:title) { |n| "Task #{n}" }
    status { :open }
  end
end
