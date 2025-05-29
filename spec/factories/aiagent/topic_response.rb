FactoryBot.define do
  factory :aiagent_topic_response, class: 'Aiagent::TopicResponse' do
    association :topic, factory: :aiagent_topic
    association :account
    sequence(:question) { |n| "Test question #{n}?" }
    sequence(:answer) { |n| "Test answer #{n}" }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }

    trait :with_document do
      association :document, factory: :aiagent_document
    end
  end
end
