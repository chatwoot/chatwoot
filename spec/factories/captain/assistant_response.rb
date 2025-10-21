FactoryBot.define do
  factory :captain_assistant_response, class: 'Captain::AssistantResponse' do
    association :assistant, factory: :captain_assistant
    association :account
    sequence(:question) { |n| "Test question #{n}?" }
    sequence(:answer) { |n| "Test answer #{n}" }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }

    trait :with_document do
      association :document, factory: :captain_document
    end
  end
end
