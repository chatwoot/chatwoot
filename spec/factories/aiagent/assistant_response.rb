FactoryBot.define do
  factory :aiagent_assistant_response, class: 'Aiagent::AssistantResponse' do
    association :assistant, factory: :aiagent_assistant
    association :account
    sequence(:question) { |n| "Test question #{n}?" }
    sequence(:answer) { |n| "Test answer #{n}" }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }

    trait :with_document do
      association :document, factory: :aiagent_document
    end
  end
end
