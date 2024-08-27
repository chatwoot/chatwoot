FactoryBot.define do
  factory :conversation_handled_by_tag do
    association :conversation
    association :user
    handled_by { 'human_agent' }
  end
end
