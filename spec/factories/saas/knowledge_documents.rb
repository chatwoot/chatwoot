# frozen_string_literal: true

FactoryBot.define do
  factory :knowledge_document, class: 'Saas::KnowledgeDocument' do
    knowledge_base factory: :knowledge_base
    account { knowledge_base.account }
    sequence(:title) { |n| "Document #{n}" }
    source_type { :text }
    content { 'Sample document content for testing.' }
    status { :ready }
    chunk_count { 1 }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
    end

    trait :error do
      status { :error }
      error_message { 'Processing failed' }
    end

    trait :from_url do
      source_type { :url }
      source_url { 'https://example.com/docs' }
    end
  end
end
