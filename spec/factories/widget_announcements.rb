FactoryBot.define do
  factory :widget_announcement do
    account
    inbox
    title { 'Scheduled maintenance' }
    message { 'Replies may be slower than usual.' }
    level { 'warning' }
    enabled { true }
  end
end
