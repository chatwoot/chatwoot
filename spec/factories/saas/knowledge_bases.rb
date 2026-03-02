# frozen_string_literal: true

FactoryBot.define do
  factory :knowledge_base, class: 'Saas::KnowledgeBase' do
    account { ai_agent.account }
    ai_agent factory: :ai_agent
    sequence(:name) { |n| "Knowledge Base #{n}" }
    description { 'A test knowledge base' }
    status { :active }

    trait :processing do
      status { :processing }
    end

    trait :error do
      status { :error }
    end
  end
end
