FactoryBot.define do
  factory :captain_simple_reply, class: 'Captain::SimpleReply' do
    sequence(:name) { |n| "Simple Reply #{n}" }
    reply { 'This is an automated reply' }
    keywords { ['keyword'] }
    match_type { 'contains' }
    enabled { true }
    association :assistant, factory: :captain_assistant
    association :account
  end
end
